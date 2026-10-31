"""Independent read-only Hopper285 rank trap, ZERO new creature ticks.

Reconstruct the four native-confirmed flat support points and the two selected
static tangents. Fraction eliminates the SAME binary64 rows/weights/RHS exactly;
this is NOT an exact model of unrounded geometry or a whole-world replay.
Native comparator: dc008dfa/run41220291795, saved annotations in .review.
"""
import json,sys,base64,math,copy
from fractions import Fraction as F
sys.path.insert(0,'tests');from godot_capture_variant import decode
saved=json.load(open('tests/fixtures/m1_articulated_execution/9343fb06296f/length-Hopper-failure.json'));x=decode(base64.b64decode(saved['full_state_variant_base64']));full=x;trace=full['awake_trace'];before=full['before'];b=decode(base64.b64decode(trace['full_work_variant_base64']));old=before['accumulator']['solver']['rig']['physical']['bodies'];parents=[x['parent']for x in before['identity']['creature']['parts']];N=len(b);D=3*N

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
print('FIRST');first=active_solve(H,rhs,True)
if first:
 after=[v[i]+first[0][i]for i in range(D)]
 inds=[0,2];targs=[(1-(1 if abs(dot(tang[i],v))<.15 else .9))*dot(tang[i],after)for i in inds]
 print('TANGENT',targs,[dot(tang[i],v)for i in inds])
 print('SECOND');active_solve(H+[tang[i]for i in inds],rhs+[t-dot(tang[i],v)for i,t in zip(inds,targs)])
 print('DUAL-FIRST SECOND');active_solve(H+[tang[i]for i in inds],rhs+[t-dot(tang[i],v)for i,t in zip(inds,targs)],True)
print('TARGETS',targets)
rows=H+[tang[i]for i in inds];vals=rhs+[t-dot(tang[i],v)for i,t in zip(inds,targs)]
for active in [[0,1,2],[0,1,3],[0,2,3],[1,2,3]]:
 try:d,m=solve(rows+[norm[i]for i in active],vals+[targets[i]-dot(norm[i],v)for i in active])
 except ValueError:print('singular',active);continue
 print('alternative',active,'lambda',m[len(rows):], 'gaps',[dot(norm[i],d)-(targets[i]-dot(norm[i],v))for i in range(4)])
def exact_solve(rows,vals):
 # Exact rational elimination, not a numerical tolerance or native replay.
 A=[[sum(F(a)*F(w)*F(c) for a,w,c in zip(r,W,s))for s in rows]+[F(t)]for r,t in zip(rows,vals)]
 n=len(rows)
 for k in range(n):
  if A[k][k]==0: raise ValueError('exact singular')
  for i in range(k+1,n):
   r=A[i][k]/A[k][k]
   for j in range(k+1,n+1): A[i][j]-=r*A[k][j]
   A[i][k]=F(0)
 m=[F(0)]*n
 for i in range(n-1,-1,-1):m[i]=(A[i][-1]-sum(A[i][j]*m[j]for j in range(i+1,n)))/A[i][i]
 d=[F(w)*sum(F(r[k])*mult for r,mult in zip(rows,m))for k,w in enumerate(W)]
 return d,m
all_four_singular=False
for active in [[0,1,2],[1,2,3],[0,1,2,3]]:
 try:d,m=exact_solve(rows+[norm[i]for i in active],vals+[targets[i]-dot(norm[i],v)for i in active])
 except ValueError:
  all_four_singular=active==[0,1,2,3]
  print('EXACT SINGULAR',active);continue
 print('EXACT',active,'lambda',[float(x)for x in m[len(rows):]],'gaps',[float(sum(F(a)*x for a,x in zip(norm[i],d))-F(targets[i]-dot(norm[i],v)))for i in range(4)])

print(json.dumps({'scope':'Read-only SAME-input rational rank diagnosis; ZERO ticks; NOT acceptance', 'source':'9343fb06296f4325e2c67516e711ac6f57ab3808', 'native_diagnostic_run':'41220291795', 'failure_phase':trace['stage_order'][-1], 'rollback_state_equal':before==full['after'], 'normal_rows':len(norm), 'material_equalities':len(rows), 'exact_all_four_singular':all_four_singular}))
