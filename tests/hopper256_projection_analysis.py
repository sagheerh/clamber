"""Read-only dyadic physical-energy audit. No engine, new ticks or acceptance verdict.
Alternative formulations printed are diagnosis ONLY, not all adopted.
The final NORMONLY computation uses legacy RHS (no stable-RHS change).
"""
import json,sys,base64,math,copy
from fractions import Fraction as F
sys.path.insert(0,'tests');from godot_capture_variant import decode
archive=sys.argv[1] if len(sys.argv)>1 else '67b167a30543'
assert archive in ['c49fcc66ee9f','67b167a30543']
f=json.load(open('tests/fixtures/m1_articulated_execution/'+archive+'/length-Hopper-failure.json'));full=decode(base64.b64decode(f['full_state_variant_base64']));b=decode(base64.b64decode(full['awake_trace']['full_work_variant_base64']));old=full['before']['accumulator']['solver']['rig']['physical']['bodies'];parents=[x['parent']for x in full['before']['identity']['creature']['parts']];N=len(b);D=N*3

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
for l in full['awake_trace']['rigid_connectors']:
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
rhs=[-dot(r,v)for r in H];d,m=solve(H+[norm[2]],rhs+[targets[2]-dot(norm[2],v)])
# Native audit says first active2 and chosen material rows part3,part6.
rows=H+[tang[0],tang[2],norm[2]];values=rhs+[-dot(tang[0],v),-dot(tang[2],v),targets[2]-dot(norm[2],v)]
d,m=solve(rows,values)
def publish(delta):
 out=copy.deepcopy(b)
 for i,x in enumerate(out):
  dx,dy,sq,w=frames[i];vx=v[3*i]+delta[3*i];vy=v[3*i+1]+delta[3*i+1];w+=delta[3*i+2]
  x['a']['velocity_x']=vx+w*dy/2;x['a']['velocity_y']=vy-w*dx/2;x['b']['velocity_x']=vx-w*dy/2;x['b']['velocity_y']=vy+w*dx/2
 return out

def energy(bs,exact=False):
 if exact:return sum(F(x['mass'])*sum(F(x[e]['velocity_'+a])**2 for e in ['a','b']for a in ['x','y'])/4 for x in bs)
 result=0.
 for x in bs:result+=x['mass']*(x['a']['velocity_x']**2+x['a']['velocity_y']**2+x['b']['velocity_x']**2+x['b']['velocity_y']**2)/4.
 return result
out=publish(d)
print('native-match energy',energy(b),energy(out),energy(out)-energy(b),'exactgain',float(energy(out,True)-energy(b,True)))
LEGACY_D=d.copy()
LEGACY_PIN=[out[1]["a"]["velocity_"+ax]for ax in ["x","y"]]
# Recompute free-root conditional in admissible mode for actual moving pin.
x=b[0];dx,dy,sq,w=frames[0];pin=[out[1]['a']['velocity_'+ax]for ax in ['x','y']];M=1/W[0];I=1/W[2];mx=dy/2;my=-dx/2
omega=(M*(mx*(v[0]-pin[0])+my*(v[1]-pin[1]))+I*v[2])/(M*(mx*mx+my*my)+I)
d2=d.copy();d2[0]=pin[0]+mx*omega-v[0];d2[1]=pin[1]+my*omega-v[1];d2[2]=omega-v[2]
p2=publish(d2);print('headCOM-free',energy(p2)-energy(b),float(energy(p2,True)-energy(b,True)))
omega=((x['a']['velocity_x']-pin[0])*dy-(x['a']['velocity_y']-pin[1])*dx)/sq
d2[0]=pin[0]+mx*omega-v[0];d2[1]=pin[1]+my*omega-v[1];d2[2]=omega-v[2]
p2=publish(d2);print('headendpoint-free',energy(p2)-energy(b),float(energy(p2,True)-energy(b,True)))
# A direct final endpoint projection, scalar exact conditional least squares.
p3=copy.deepcopy(out);rad=((x['a']['velocity_x']-pin[0])*dx+(x['a']['velocity_y']-pin[1])*dy)/sq
p3[0]['a']['velocity_x']=x['a']['velocity_x']-rad*dx;p3[0]['a']['velocity_y']=x['a']['velocity_y']-rad*dy
p3[0]['b']['velocity_x']=pin[0];p3[0]['b']['velocity_y']=pin[1]
print('headendpoint-radial',energy(p3)-energy(b),float(energy(p3,True)-energy(b,True)))
# Orthogonalize root free tangent from entire RHS/pin choices: project full M using QR?
def cpvel(i,endpoint):
 x=b[i];dx,dy,sq,w=frames[i];q=((x['b']['velocity_x']-x['a']['velocity_x'])*dx+(x['b']['velocity_y']-x['a']['velocity_y'])*dy)/sq/2
 sg=1 if endpoint=='a'else -1
 return [x[endpoint]['velocity_x']+sg*q*dx,x[endpoint]['velocity_y']+sg*q*dy]
for c in range(1,N):
 p=parents[c];pa=cpvel(p,'b');ca=cpvel(c,'a');rhs[2*(c-1)]=pa[0]-ca[0];rhs[2*(c-1)+1]=pa[1]-ca[1]
values=rhs+[-dot(tang[0],v),-dot(tang[2],v),targets[2]-dot(norm[2],v)];d,m=solve(rows,values);out=publish(d);pin=[out[1]['a']['velocity_'+ax]for ax in ['x','y']];x=b[0];dx,dy,sq,w=frames[0];mx=dy/2;my=-dx/2;M=1/W[0];I=1/W[2];omega=(M*(mx*(v[0]-pin[0])+my*(v[1]-pin[1]))+I*v[2])/(M*(mx*mx+my*my)+I);d[0]=pin[0]+mx*omega-v[0];d[1]=pin[1]+my*omega-v[1];d[2]=omega-v[2];out=publish(d);print('stable rhs',energy(out)-energy(b),float(energy(out,True)-energy(b,True)),pin)
p3=copy.deepcopy(out);rad=((x['a']['velocity_x']-pin[0])*dx+(x['a']['velocity_y']-pin[1])*dy)/sq
p3[0]['a']['velocity_x']=x['a']['velocity_x']-rad*dx;p3[0]['a']['velocity_y']=x['a']['velocity_y']-rad*dy;p3[0]['b']['velocity_x']=pin[0];p3[0]['b']['velocity_y']=pin[1]
print('stable rhs + direct',energy(p3)-energy(b),float(energy(p3,True)-energy(b,True)),rad)
# Exact physical-metric counterpart of the same active rows, for diagnosis only.
VF=[];WF=[]
for x,fr in zip(b,frames):
 dx,dy=map(F,fr[:2]);sq=dx*dx+dy*dy;m=F(x['mass']);avx,avy,bvx,bvy=[F(x[e]['velocity_'+a])for e in['a','b']for a in ['x','y']];VF.extend([(avx+bvx)/2,(avy+bvy)/2,(dx*(bvy-avy)-dy*(bvx-avx))/sq]);WF.extend([1/m,1/m,4/(m*sq)])
RF=[[F(q)for q in r]for r in rows];B=[F(0)]*len(H)+[F(0),F(0),F(targets[2])];Q=[[sum(a[k]*WF[k]*z[k]for k in range(D))for z in RF]+[B[i]-sum(a[k]*VF[k]for k in range(D))]for i,a in enumerate(RF)]
for i in range(len(Q)):
 pivot=Q[i][i];Q[i]=[q/pivot for q in Q[i]]
 for j in range(i+1,len(Q)):
  c=Q[j][i]
  if c:Q[j]=[a-c*z for a,z in zip(Q[j],Q[i])]
LF=[F(0)]*len(Q)
for i in reversed(range(len(Q))):LF[i]=Q[i][-1]-sum(Q[i][j]*LF[j]for j in range(i+1,len(Q)))
OF=[VF[k]+WF[k]*sum(RF[i][k]*LF[i]for i in range(len(RF)))for k in range(D)];E=F(0)
for i,x in enumerate(b):
 dx,dy=map(F,frames[i][:2]);cx,cy,om=OF[3*i:3*i+3];E+=F(x['mass'])*((cx+om*dy/2)**2+(cy-om*dx/2)**2+(cx-om*dy/2)**2+(cy+om*dx/2)**2)/4
print('EXACT physical active projection gain',float(E-energy(b,True)))
EX=copy.deepcopy(b)
for i,x in enumerate(b):
 dx,dy=map(F,frames[i][:2]);cx,cy,om=OF[3*i:3*i+3]
 for e,vals in [('a',[cx+om*dy/2,cy-om*dx/2]),('b',[cx-om*dy/2,cy+om*dx/2])]:
  for a,val in zip(['x','y'],vals):EX[i][e]['velocity_'+a]=float(val)
print('rounded exact gain',energy(EX)-energy(b),float(energy(EX,True)-energy(b,True)))
print('exact in-out head',[(a, b[0]['a']['velocity_'+a],EX[0]['a']['velocity_'+a],float(F(EX[0]['a']['velocity_'+a])-F(b[0]['a']['velocity_'+a])))for a in ['x','y']]);print('exactpin',EX[0]['b']['velocity_x'],EX[0]['b']['velocity_y'])
for name in ['norm-dot','scaled-dot','givens']:
 P=copy.deepcopy(out);dx,dy,sq,w=frames[0];L=math.sqrt(sq)
 if name=='norm-dot':tx=dy/L;ty=-dx/L
 elif name=='scaled-dot':t=dx/dy;c=1/math.sqrt(1+t*t);tx=c;ty=-t*c
 else:t=dx/dy;ty=-t/math.sqrt(1+t*t);tx=math.sqrt(1-ty*ty)
 scalar=tx*(b[0]['a']['velocity_x']-pin[0])+ty*(b[0]['a']['velocity_y']-pin[1]);P[0]['a']['velocity_x']=pin[0]+tx*scalar;P[0]['a']['velocity_y']=pin[1]+ty*scalar;P[0]['b']['velocity_x']=pin[0];P[0]['b']['velocity_y']=pin[1];print(name,'t²',tx*tx+ty*ty,'gain',energy(P)-energy(b),float(energy(P,True)-energy(b,True)))
L=math.sqrt(sq);tx=dy/L;ty=-dx/L;scalar=tx*(b[0]['a']['velocity_x']-pin[0])+ty*(b[0]['a']['velocity_y']-pin[1]);om=scalar/L
d[0]=pin[0]+dy/2*om-v[0];d[1]=pin[1]-dx/2*om-v[1];d[2]=om-v[2];P=publish(d);print('norm scalar original publisher',energy(P)-energy(b),float(energy(P,True)-energy(b,True)))
d=LEGACY_D.copy();pin=LEGACY_PIN;dx,dy,sq,w=frames[0];L=math.sqrt(sq);tx=dy/L;ty=-dx/L;scalar=tx*(b[0]["a"]["velocity_x"]-pin[0])+ty*(b[0]["a"]["velocity_y"]-pin[1]);om=scalar/L
d[0]=pin[0]+dy/2*om-v[0];d[1]=pin[1]-dx/2*om-v[1];d[2]=om-v[2];P=publish(d);print("NORMONLY original strict gain",energy(P)-energy(b),float(energy(P,True)-energy(b,True)))
assert energy(P)<=energy(b) and energy(P,True)<=energy(b,True)
