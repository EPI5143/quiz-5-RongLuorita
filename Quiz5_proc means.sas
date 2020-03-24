libname epi "/folders/myfolders/EPI5143data";
libname ex "/folders/myfolders/EPI5143data/exercise";

proc contents data=epi.nhrabstracts varnum;
run;

proc contents data=epi.nhrdiagnosis varnum;
run;

**Q1:create spine dataset: admission from 2003-2004 from abstracts table;

data ex.abspine;
set epi.nhrabstracts;
if year(datepart(hraadmdtm)) <2003 or year(datepart(hraadmdtm))>2004 then delete;
run;

**check no duplicates in spine dataset;
proc sort data=ex.abspine nodupkey;
by hraencwid;
run;

**Q2:identification diabetes diagnosis codes and create indicator variable; 
data ex.diag;
set epi.nhrdiagnosis;
run;

**Q3:create dm dataset with a flag for diabetes diagnoses;
data dm;
set ex.diag;
dm=0;
if hdgcd in:('250' 'E11' 'E10') then dm=1;
run;

**create flat file  with respect to each unique encounter ID;
proc means data=dm noprint;
class hdghraencwid;
types hdghraencwid;
var dm;
output out=dmflat max(dm)=dm n(dm)=count sum(dm)=dm_count;
run;

proc freq data=dmflat;
tables dm_count dm count;
run;

**Q4:link spine dataset with diabetes diagnosis dataset-left join;
proc sort data=dmflat;
by hdghraencwid;
run;

data final;
merge ex.abspine (in=a) dmflat(in=b rename=hdghraencwid=hraencwid);
by hraencwid;
if a;
if dm=. then dm=0;**if hraencwid is not represented in the dmflat dataset then it will have missing values for the flags;
if count=. then count=0;**so set those missing to be included in the denominator;
if dm_count=. then dm_count=0;
run;

proc freq data=final;
tables dm count dm_count;
run;



