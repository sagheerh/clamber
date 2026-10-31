"""Read-only rational analysis of NATIVE V26 sparse369 rows, ZERO ticks.
All fractions describe exact binary64 input coefficients, not unrounded geometry.
Enumerated KKT faces prove a genuine rank-exchange requirement, not a new world.
"""
import json, fractions, itertools
F=fractions.Fraction
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
annotations=json.loads((ROOT/'.review/physics_fix/v26-hopper369-sparse-native-annotations.json').read_text())
src={}
for item in annotations:
 text=item['message']
 if text.startswith('Hopper369 manifold') and ': {' in text:
  key,raw=text.split(': ',1);src[key]=json.loads(raw)
assert src['Hopper369 manifold diagnostic']['published']=={}
assert src['Hopper369 manifold diagnostic']['calls'][1]['failed'] is True
r=src['Hopper369 manifold rows1'];v=src['Hopper369 manifold rhs1'];W=list(map(F,r['weights']));D=len(W)
def dense(row):
 x=[F(0)]*D
 for i,a in row:x[i]=F(a)
 return x
H=[dense(row)for row in r['equalities']];rhs=list(map(F,v['rhs']));ineq=[(dense(x['row']),F(x['rhs']))for x in v['inequalities']]
def solve(rows,vals):
 A=[[sum(a*w*b for a,w,b in zip(x,W,y))for y in rows]+[z]for x,z in zip(rows,vals)];n=len(A)
 for k in range(n):
  if A[k][k]==0:raise ValueError('singular')
  for i in range(k+1,n):
   rat=A[i][k]/A[k][k]
   for j in range(k+1,n+1):A[i][j]-=rat*A[k][j]
   A[i][k]=F(0)
 m=[F(0)]*n
 for i in range(n-1,-1,-1):m[i]=(A[i][-1]-sum(A[i][j]*m[j]for j in range(i+1,n)))/A[i][i]
 d=[w*sum(row[k]*lam for row,lam in zip(rows,m))for k,w in enumerate(W)]
 return d,m
for k in range(5):
 for active in itertools.combinations(range(4),k):
  try:d,m=solve(H+[ineq[i][0]for i in active],rhs+[ineq[i][1]for i in active])
  except ValueError:print('singular',active);continue
  gaps=[sum(a*b for a,b in zip(row,d))-bound for row,bound in ineq];neg=[i for i in range(k)if m[len(H)+i]<0];viol=[i for i in range(4)if i not in active and gaps[i]<0]
  print(active,'lambda',[float(x)for x in m[len(H):]],'gaps',[float(x)for x in gaps],'negative',neg,'violated',viol, 'PASS'if not neg and not viol else '')
