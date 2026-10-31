"""Read-only native-matched active-set diagnosis; no new creature ticks or verdict."""
import json,sys,base64,math,copy
from fractions import Fraction as F
sys.path.insert(0,'tests');from godot_capture_variant import decode
saved=json.load(open('tests/fixtures/m1_candidate_runtime/00f33495a75c/summary.json'));x=decode(base64.b64decode(saved['failure_variant_base64']));trace=x['physics_failure']['failed']['awake_trace'];before=x['physics_failure']['before_frame'];b=decode(base64.b64decode(trace['full_work_variant_base64']));old=before['accumulator']['solver']['rig']['physical']['bodies'];parents=[x['parent']for x in before['identity']['creature']['parts']];N=len(b);D=3*N

def frame(x):
 dx=x['b']['x']-x['a']['x'];dy=x['b']['y']-x['a']['y'];sq=dx*dx+dy*dy
 w=(dx*(x['b']['velocity_y']-x['a']['velocity_y'])-dy*(x['b']['velocity_x']-x['a']['velocity_x']))/sq
 return dx,dy,sq,w
frames=[frame(x)for x in b];W=[];v=[];H=[]
for x,fr in zip(b,frames):
 W.extend([1/x['mass'],1/x['mass'],(x['a']['inverse_mass']+x['b']['inverse_mass'])/fr[2]])
 v.extend([(x['a']['velocity_x']+x['b']['velocity_x'])/2,(x['a']['velocity_y']+x['b']['velocity_y'])/2,fr[3]])
for c in range(1,N):
 p=parents[c];rx=[0.]*D;ry=[0.]*D;rx[3*p]=-1.;rx[3*c]=1.;rx[3*p+2]=frames[p][1]/2;rx[3*c+2]=frames[c][1]/2;ry[3*p+1]=-1.;ry[3*c+1]=1.;ry[3*p+2]=-frames[p][0]/2;ry[3*c+2]=-frames[c][0]/2;H.extend([rx,ry])
for l in trace['rigid_connectors']:
 r=[0.]*D;r[3*l['parent']+2]=-1.;r[3*l['child']+2]=1.;H.append(r)
def dot(a,c):
 s=0.
 for i in range(len(a)):s+=a[i]*c[i]
 return s

def solve(rows,rhs):
 L=[]
 for i in range(len(rows)):
  r=[0.]*len(rows)
  for j in range(i+1):
   val=0.
   for d in range(D):val+=rows[i][d]*W[d]*rows[j][d]
   for k in range(j):val-=r[k]*L[j][k]if i!=j else r[k]*r[k]
   if i==j and val<=0:raise ValueError('singular')
   r[j]=math.sqrt(val)if i==j else val/L[j][j]
  L.append(r)
 m=rhs.copy()
 for i in range(len(m)):
  for j in range(i):m[i]-=L[i][j]*m[j]
  m[i]/=L[i][i]
 for i in range(len(m)-1,-1,-1):
  for j in range(i+1,len(m)):m[i]-=L[j][i]*m[j]
  m[i]/=L[i][i]
 delta=[0.]*D
 for d in range(D):
  for i in range(len(rows)):delta[d]+=W[d]*rows[i][d]*m[i]
 return delta,m
norm=[];tang=[];targets=[]
for part in [3,5,6,7]:
 dx,dy,_,_=frames[part];rx=.5*dx;ry=.5*dy-b[part]['radius'];nr=[0.]*D;tr=[0.]*D;nr[3*part+1]=1.;nr[3*part+2]=rx;tr[3*part]=-1.;tr[3*part+2]=ry;norm.append(nr);tang.append(tr);targets.append(-.02*min(0,old[part]['b']['velocity_y']))

def active_solve(rows,rhs,drop_first=False):
 active=[];seen=set()
 while True:
  if tuple(active) in seen:print('CYCLE',active);return
  seen.add(tuple(active))
  try:d,m=solve(rows+[norm[i]for i in active],rhs+[targets[i]-dot(norm[i],v)for i in active])
  except ValueError:print('RANKFAIL',active);return
  violated=[i for i in range(4)if i not in active and dot(norm[i],d)<targets[i]-dot(norm[i],v)]
  negative=[i for i in range(len(active))if m[len(rows)+i]<0]
  print('ACTIVE',active,'lambda',m[len(rows):],'violated',violated,'neg',negative)
  if drop_first and negative:active.pop(negative[0]);continue
  if violated:active.append(violated[0]);continue
  if negative:active.pop(negative[0]);continue
  return d,m,active
rhs=[-dot(r,v)for r in H]
print('FIRST');first=active_solve(H,rhs)
if first:
 after=[v[i]+first[0][i]for i in range(D)]
 inds=[0,2];targs=[(1-(1 if abs(dot(tang[i],v))<.15 else .9))*dot(tang[i],after)for i in inds]
 print('TANGENT',targs,[dot(tang[i],v)for i in inds])
 print('SECOND');active_solve(H+[tang[i]for i in inds],rhs+[t-dot(tang[i],v)for i,t in zip(inds,targs)])
 print('DUAL-FIRST SECOND');active_solve(H+[tang[i]for i in inds],rhs+[t-dot(tang[i],v)for i,t in zip(inds,targs)],True)
