from match_audio import root,features,np
import json,re
chapters=json.loads((root/'assets/cevsen.json').read_text(encoding='utf-8'))
template=features(1)[310:442]
all_rows=[]
for first in range(1,101,10):
 f=features(first);cost=1-template@f.T
 prev=np.zeros(len(f));prev2=np.zeros(len(f))
 for i in range(len(template)):
  a=np.r_[np.inf,prev[:-1]]
  b=np.r_[np.inf,np.inf,prev[:-2]]+.08
  c=np.r_[np.inf,prev2[:-1]]+.08 if i>0 else np.full(len(f),np.inf)
  current=cost[i]+np.minimum(np.minimum(a,b),c)
  prev2,prev=prev,current
 score=prev/len(template)
 tail=features(1)[415:460]
 tail_windows=np.lib.stride_tricks.sliding_window_view(f,45,axis=0).reshape(-1,45*20)
 tail_score=1-tail_windows@tail.T.reshape(-1)/45
 tail_aligned=np.r_[np.ones(44),tail_score]
 score=.3*score+.7*tail_aligned
 # Select ten ordered repetitions; constrain gaps to plausible bab lengths.
 n=len(f);dp=np.full((10,n),np.inf);back=np.zeros((10,n),dtype=int)
 syllables=[len(re.findall('[aeıioöuüâîû]',' '.join(r['tr'].lower() for r in b['rows']))) for b in chapters[first-1:first+9]]
 expected=np.array([17+.32*s for s in syllables]);expected*=n/10/expected.sum()
 dp[0,250:850]=score[250:850]+.0007*(np.arange(250,min(850,n))/10-expected[0])**2
 for k in range(1,10):
  for j in range(250,n):
   low=max(0,j-950);high=j-250
   if high<=low:continue
   values=dp[k-1,low:high]+.0007*((j-np.arange(low,high))/10-expected[k])**2
   arg=low+int(np.argmin(values))
   dp[k,j]=values[arg-low]+score[j];back[k,j]=arg
 end=n-150+int(np.argmin(dp[9,n-150:]));ends=[end]
 for k in range(9,0,-1):ends.append(int(back[k,ends[-1]]))
 ends.reverse()
 print(first,[(round(e/10,1),round(float(score[e]),3)) for e in ends],flush=True)
 all_rows.append({'first':first,'ends':[e/10 for e in ends],'costs':[float(score[e]) for e in ends]})
(root/'assets/raw/alignment.json').write_text(json.dumps(all_rows,indent=2))
