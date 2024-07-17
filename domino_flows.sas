/******************************************************************************
*  ____                  _
* |  _ \  ___  _ __ ___ (_)_ __   ___
* | | | |/ _ \| '_ ` _ \| | '_ \ / _ \
* | |_| | (_) | | | | | | | | | | (_) |
* |____/ \___/|_| |_| |_|_|_| |_|\___/
* ____________________________________________________________________________
* Sponsor              : Domino
* Compund              : -
* Study                : -
* Analysis             : -
* Program              : domino_flows.sas
* ____________________________________________________________________________
* DESCRIPTION 
*
* This is the Domino SAS setup file when you execute your study programs as part of a Flow and contains definitions that
* are used across the reporting effort. 
*
* DO NOT EDIT THIS FILE WITHOUT PRIOR APPROVAL 
*
* Program description:
* 0. Read environment variables
* 1. Set global pathname macro variables
* 2. Define standard libraries
*                                                                   
* Input files:
* - none
* 
* Input Environment Variables:
* - DOMINO_PROJECT_NAME
* - DOMINO_WORKING_DIR
* - DCUTDTC
*
* Outputs:                                                   
* - global variables defined
* - SAS Libnames defined
* - sasautos path set for shared macros
*
* Macros: 
* - none
*
* Assumptions: 
* - Must be run on the Domino platform (assumes Domino environment vars)
* ____________________________________________________________________________
* PROGRAM HISTORY                                                         
*  2022-06-06  | Stuart.Malcolm  | Program created
*  2022-09-28  | Stuart.Malcolm  | Ported code to TFL_Standard_Repo 
*  2022-10-03  | Stuart.Malcolm  | Moved into study /share directory
*  2022-10-20  | Stuart.Malcolm  | support ADAM/TFL combined projects
*  2023-05-09  | Tom.Ratford     | Support new project structure
*  2023-05-09  | Tom.Ratford     | Output log in batch
*  2023-05-18  | Megan.Harries   | Include metadata libname for RE Interim
*  2023-05-18  | Ross.Sharp      | Convert paths to work with Flows architecture
* ----------------------------------------------------------------------------
*  YYYYMMDD  |  username        | ..description of change..         
*****************************************************************************/
 
%macro __setup();
 
* global constants - USER CONFIGURABLE. Change these here if needed;
 
* Location of Domino Datasets folders that are defined in this project;
* Dependent on whether project is DFS or Git hosted;
%global __localdata_path;
* Location of mounted shared Domino Datasets;
%global __sharedata_path;
* Location of imported code repositories;
%global __imported_git_path;

* globals read in from env vars; 
%global __WORKING_DIR  ; * path to root of working directory ;
%global __PROJECT_NAME ; * project name <PROTOCOL>_<TYPE> ;
%global __DCUTDTC      ; * cutoff date in ISO8901 format ;
 
* globals derived from env vars;
%global __PROTOCOL;      * Protocol identifier e.g H2QMCLZZT; 
%global __PROJECT_TYPE ; * project type: SDTM | ADAM | TFL ;
 
* other globals exported by setup;
%global __prog_path;     * full path to the program being run;
%global __prog_name;     * filename (without extension) of program;
%global __prog_ext;      * extension of program (usuall sas);
%global __results_path;  * path to output file (e.g. for TFL write);
%global __full_path;     * full path and filename of program;
%global __runmode;       * INTERACTIVE or BATCH (or UNKNOWN);
 
* ==================================================================;
* grab the environment varaibles that we need to create pathnames;
* ==================================================================;
%let __WORKING_DIR  = %sysget(DOMINO_WORKING_DIR);
%let __PROJECT_NAME = %sysget(DOMINO_PROJECT_NAME);
%let __DCUTDTC      = %sysget(DCUTDTC);
* runtime check that e.g. DCUTDTC is not missing;
%if &__DCUTDTC. eq %str() %then %put %str(ER)ROR: Envoronment Variable DCUTDTC not set;
 
* ==================================================================;
* extract the protocol and project type from the project name;
* ==================================================================;
%if %sysfunc(find(&__PROJECT_NAME.,_)) ge 1 %then %do;
  %* found an underscrore, so assume project name is <PROTOCOL>_<TYPE> ;
  %let __PROTOCOL     = %scan(&__PROJECT_NAME.,1,'_');
  %* project type is everything after the protocol in the project name ;
  %let __PROJECT_TYPE = %sysfunc(tranwrd(&__PROJECT_NAME.,&__PROTOCOL._, %str()));
  %end;
%else %do;
  %put %str(ER)ROR: Project Name (DOMINO_PROJECT_NAME) ill-formed. Expecting <PROTOCOL>_<TYPE> ;
%end;
 
* ==================================================================;
* work out if the project is git or domino based
* ==================================================================;
* !!ALERT!! DOMINO_IS_GIT_BASED is an undocumented environment variable;
%let __is_git_project = %sysget(DOMINO_IS_GIT_BASED);
%if %upcase(&__is_git_project) eq %str(TRUE) %then %do;
  * local & imported dataset location;
  %let __localdata_path = /mnt/data;
  %let __sharedata_path = /mnt/imported/data;
  * imported code location;
  %let __imported_git_path = /mnt/imported/code;
  * set  directory  where outputs (TFL) are written to;
  %let __results_path=/mnt/artifacts/results;
%end; %else %do;
  %let __localdata_path = /domino/datasets/local;
  %let __sharedata_path = /domino/datasets;
  * Imported code repository location;
  %let __imported_git_path = /repos;
  * set  directory  where outputs (TFL) are written to;
  %let __results_path=&__WORKING_DIR./results;
%end;

* ==================================================================;
* define library locations - these are dependent on the project type;
* ==================================================================;
 
* SDTM ;
* ------------------------------------------------------------------;
%if %sysfunc(find(%upcase(&__PROJECT_TYPE.),SDTM)) ge 1 %then %do;
  * Local read/write access to SDTM and QC folders ;
  libname SDTMUNBD   "&__localdata_path./SDTMUNBLIND";
  libname SDTMBLND "&__localdata_path./SDTMBLIND";
  * Imported SDTM projects; 
  libname RAW "&__sharedata_path./RAW" access=readonly;
  libname UNBLIND "&__sharedata_path./UNBLIND" access=readonly;
  libname BLIND "&__sharedata_path./BLIND" access=readonly;
  * Metadata;
  libname METADATA "&__localdata_path./METADATA";
%end;

* Reporting Effort (RE) project ;
* ------------------------------------------------------------------;
%if %sysfunc(find(%upcase(&__PROJECT_TYPE.),RE)) ge 1 %then %do;
  * imported read-only SDTM data, using the data cutoff date.. ;
  * .. and sdtm variable to identify the correct snapshot to use ;
  %let __SDTM_DATASET = %sysget(SDTM_DATASET);
  %if &__SDTM_DATASET. eq %str() %then %put %str(ER)ROR: Environment Variable SDTM_DATASET not set;
  libname SDTM "/workflow/inputs/sdtm_data_path" access=readonly;
  * local read/write acces to ADaM and QC folders;
  options dlcreatedir;
  libname inputs "/workflow/inputs"; /* All inputs live in this directory at workflow/inputs/<NAME OF INPUT> */ 
  libname outputs "/workflow/outputs"; /* All outputs must go to this directory at workflow/inputs/<NAME OF OUTPUT>y */ 
  * Metadata;
  libname METADATA "&__localdata_path./METADATA/JUL102024";
%end;
 
* ==================================================================;
* Set SASAUTOS to search for shared macros ;
* ==================================================================;
options
  MAUTOSOURCE
  MAUTOLOCDISPLAY 
  sasautos=(
    "&__WORKING_DIR./share/macros"
    ,"&__imported_git_path./SCE_STANDARD_LIB/macros"
    ,SASAUTOS) ;
 
* ==================================================================;
* Determine if we are running Interactive or Batch ;
* ==================================================================;
 
* default position is that we dont know how program is running;
%let __runmode=UNKNOWN;
 
%* ------------------------------------------------------------------;
%* Are we running in INTERACTIVE mode? ;
%* Check for macro var _SASPROGRAMFILE. only present in SAS Studio ;
%* ------------------------------------------------------------------;
   %if %symexist(_SASPROGRAMFILE) %then %do;
      %let __full_path = %str(&_SASPROGRAMFILE.);
      %let __runmode=INTERACTIVE;
      %put %str(TR)ACE: (domino.sas) Running in SAS Studio.;
   %end;
 
%* ------------------------------------------------------------------;
%* Are we running in BATCH mode? ;
%* Check for Operating System parameter SYSIN. This parameter indicates batch execution ;
%* ------------------------------------------------------------------;
   %else %if %quote(%sysfunc(getoption(sysin))) ne %str() %then %do;
      %let __full_path = %quote(%sysfunc(getoption(sysin)));
      %let __runmode=BATCH;
      %put %str(TR)ACE: (domino.sas) Running in BATCH SAS.;
   %end;
 
%* Runtime check that we can identify runtime mode;
%if &__full_path eq %str() %then %put %str(WAR)NING: Cannot determine program name;
 
* ------------------------------------------------------------------;
* get program name, path and extension ;
* ------------------------------------------------------------------;
%local filename;
%* scan from right to left for first backslash. ;
%* everything to the right of that slash is filename with extension. ;
%let filename = %scan(&__full_path, -1, /);
 
%* find the numeric position of the filename. ;
%* everything to up to that point (minus 1) is the folder. ;
%let __prog_path= %substr(&__full_path., 1, %index(&__full_path., &filename.) - 1);
 
%* isolate filename as everything up to but not including the period. ;
%let __prog_name = %scan(&filename, 1, .);
 
%* everything after the period is the extension. ;
%let __prog_ext = %scan(&filename, 2, .);
 
* ==================================================================;
* Redirect log files (BATCH MODE ONLY);
* ==================================================================;
%if &__runmode eq %str(BATCH) %then %do;
  * Redirect SAS LOG files when in batch mode;
  PROC PRINTTO LOG="&__results_path./&__prog_name..log" NEW;
%end;
 
%mend __setup;
* invoke the setup macro - so user program only needs to include this file;
%__setup;
 
* ==================================================================;
* write to log for traceability ;
* this is done outside the setup macro to ensure global vars are defined;
* ==================================================================;
%put TRACE: (domino.sas) [__WORKING_DIR = &__WORKING_DIR.] ;
%put TRACE: (domino.sas) [__PROJECT_NAME = &__PROJECT_NAME.];
%put TRACE: (domino.sas) [__DCUTDTC = &__DCUTDTC.];
%put TRACE: (domino.sas) [__PROTOCOL = &__PROTOCOL.];
%put TRACE: (domino.sas) [__PROJECT_TYPE = &__PROJECT_TYPE.];
%put TRACE: (domino.sas) [__localdata_path = &__localdata_path.];
%put TRACE: (domino.sas) [__prog_path = &__prog_path.];
%put TRACE: (domino.sas) [__prog_name = &__prog_name.];
%put TRACE: (domino.sas) [__prog_ext = &__prog_ext.];
%put TRACE: (domino.sas) [__results_path = &__results_path.];
%put TRACE: (domino.sas) [__runmode = &__runmode.];
 
* List all the libraries that are currently defined;
libname _all_ list;
 
*EOF;
