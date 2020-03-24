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

**Q2&Q3:identification diabetes diagnosis codes and create indicator variable; 
data ex.diag;
set epi.nhrdiagnosis;
run;
**make sure diagnosis table sorted by hdghraencwid;
proc sort data=ex.diag out=procs;
by hdgHraEncWID;
run;
**use first. and last., retain statement and output statement to create diabetes(dm)flags 
and flatten the diabetes dataset with respect to encounter ID hdghraencwid;
data diabetes;
set procs;
by hdgHraEncWID;
if first.hdgHraEncWID=1 then do;
dm=0; **reset flags for each new hraencwid;
count=0;
end;
if hdgcd  in:('250' 'E11' 'E10') then do;
dm=1; 
count=count+1;**set diabetes flag and increment the counter if there is a diabetes code 
               recorded for the current row;
end;
if last.hdgHraEncWID then output;
retain dm count;
run;

proc freq data=diabetes;
tables dm count;
run;

**Q4:left join to merge the diabetes dataset to spine dataset;
data diabmerge;
merge ex.abspine (in=a) diabetes(in=b rename=hdgHraEncWID=hraencwid);
by hraencwid;
if a;
if b=0 then do; **hraencwid not reprented in the diabetes dataset will have missing vlues 
for the flags, so to set missing values to 0 to ensure them are included in the denominator;
if dm=. then dm=0; 
if count=. then count=0;
end;
run;

proc freq data=diabmerge;
table dm count;
run; 


