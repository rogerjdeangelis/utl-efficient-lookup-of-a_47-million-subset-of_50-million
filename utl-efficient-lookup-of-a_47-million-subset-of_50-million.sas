Efficient lookup of a 47(370mb) million subset of 54 million(13gb);

  Thanks for the question, it opened my eyes.

  Laptop Dell I7 2760QM with 16gb ram (supports 4 esata SSDs with docking station and RAID 0)

  Timings ( 5 Solutions - There may be some caching going on)

        Seconds

     1.   55    Theorectical minimum  (read 57 million if _n_<= 47000000 then output)
                (partitioning or modifying the 54 million or 8 HASHES might be faster)
                (data is too small to set up these more copmplex solutions)

     2.   65    HASH  (most flexible even with unsorted scattered keys)

                These solutions are less flexible and may depend of locality of the keys

     3.  607    Vanilla SQL
     4.  398    SQL Magic=103 (HASH)
     5.   98    Index Sort Merge (27,6, 65)

github
https://tinyurl.com/y7m92nke
https://github.com/rogerjdeangelis/utl-efficient-lookup-of-a_47-million-subset-of_50-million


SAS-L original posting.
https://listserv.uga.edu/cgi-bin/wa?A2=SAS-L;67099904.1901b


INPUT
=====

* MAKE DATA;

libname cwk "c:/wrk";
libname dwk "d:/wrk";
libname ewk "e:/wrk";

data cwk.d47(bufno=110000 bufsize=128k);
  do rec=1 to 47e6;
     output;
  end;
run;quit;

data dwk.d54(bufno=320 bufsize=128k);
 array chrs[22] $3 c1-c22 (22*"DAT");
 array nums[22] 8 n1-n22 (22*99);
 do rec=1 to 54e6;
    output;
 end;
run;quit;

INPUT TABLES
------------

CWK.D47 total obs=47,000,000  lookup keys
-----------------------------------------

      REC

         1
         2
         3
         4
         5
       ...
  46999998
  46999999
  47000000



DWK.D54 Middle Observation(27000000 ) of dwk.d54 - Total Obs 54,000,000
-----------------------------------------------------------------------

 -- CHARACTER --

Var  Type      Value

C1     C3       DAT
C2     C3       DAT
C3     C3       DAT
....
C20    C3       DAT
C21    C3       DAT
C22    C3       DAT

 -- NUMERIC --

REC    N8       99   Key

N1     N8       99
N2     N8       99
N3     N8       99
...
N20    N8       99
N21    N8       99
N22    N8       99



EXAMPLE OUTPUT  (47 million subset of 54 million)
-------------------------------------------------

Middle Observation(23,500,000) of ewk.want47 - Total Obs 47,000,000

 -- CHARACTER --

Var  Type      Value

C1     C3       DAT
C2     C3       DAT
C3     C3       DAT
....
C20    C3       DAT
C21    C3       DAT
C22    C3       DAT

 -- NUMERIC --

REC    N8       99   Key

N1     N8       99
N2     N8       99
N3     N8       99
...
N20    N8       99
N21    N8       99
N22    N8       99


PROCESS
=======

    Seconds

1.   55    Theorectical minimum  (read 57 million if _n_<= 47000000 then output)
           (partitioning or modifying the 54 million or 8 HASHES might be faster)
----------------------------------------------------------------------------------


libname cwk "c:/wrk";  /* op sys drive */
libname dwk "d:/wrk";  /* drive in cdrom slot */
libname ewk "e:/wrk";  /* esata port drive */

data cwk.out47;
  set dwk.d54; * 13GB 45 variables and 54 million rows;
  if _n_<= 47000000 then output;
run;quit;

NOTE: The data set CWK.OUT47 has 47000000 observations and 45 variables.
NOTE: DATA statement used (Total process time):
      real time           54.60 seconds
      cpu time            22.82 seconds



2.   65    HASH  (most flexible even with unsorted scattered keys)
-------------------------------------------------------------------

 data ewk.want47;
   declare hash H(dataset:("cwk.d47"),hashexp:20);
   h.defineKey("rec");
   h.defineDone();
   do until(eof);
     set dwk.d54 end = eof;
     if h.check() = 0 then output;
   end;
   stop;
 run;

 NOTE: There were 47000000 observations read from the data set CWK.D47.
 NOTE: There were 54000000 observations read from the data set DWK.D54.
 NOTE: The data set EWK.WANT47 has 47000000 observations and 45 variables.
 NOTE: DATA statement used (Total process time):
       real time           1:04.83
       cpu time            44.82 seconds



3.  607    Vanilla SQL
----------------------

 Proc sql;
  create
     table ewk.want47 as
  select
     r.*
  from
     cwk.d47 as l , dwk.d54 as r
  where
     l.rec = r.rec
;quit;

 OTE: PROCEDURE SQL used (Total process time):
      real time          10:11.58
      cpu time            3:06.82



4.  398    SQL Magic=103 (HASH)
--------------------------------

Proc sql magic=103;
 create
    table ewk.want47 as
 select
    r.*
 from
    cwk.d47 as l , dwk.d54 as r
 where
    l.rec = r.rec
;quit;

NOTE: PROC SQL planner chooses merge join.
NOTE: A merge join has been transformed to a hash join.
NOTE: Table EWK.WANT47 created, with 47000000 rows and 45 columns.

116 !  quit;
NOTE: PROCEDURE SQL used (Total process time):
      real time           6:38.01
      cpu time            2:55.26



5.  198    Index Sort Merge
----------------------------


* Create Index;
proc sql;
  create unique index rec on dwk.d54
;quit;

/*
NOTE: Simple index rec has been defined.
719 !  quit;
NOTE: PROCEDURE SQL used (Total process time):
      real time           16.69 seconds
      cpu time            27.86 seconds
*/

* Sort 47 million;
proc sort data=cwk.d47 force;
by rec;
run;quit;

/*
NOTE: There were 47000000 observations read from the data set CWK.D47.
NOTE: The data set CWK.D47 has 47000000 observations and 1 variables.
NOTE: PROCEDURE SORT used (Total process time):
      real time           6.01 seconds
      cpu time            16.16 seconds
*/

131   data ewk.want;
132    merge dwk.d54(in=a) cwk.d47(in=b);
133    by rec;
134    if a and b;
135   run;

NOTE: There were 54000000 observations read from the data set DWK.D54.
NOTE: There were 47000000 observations read from the data set CWK.D47.
NOTE: The data set EWK.WANT has 47000000 observations and 45 variables.
NOTE: DATA statement used (Total process time):
      real time           1:05.66
      cpu time            43.00 seconds






