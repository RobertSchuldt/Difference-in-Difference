/**************************************************************************************************************************************
This is a difference in difference analysis to determine if the Homoe Health Value Based Purchasing program effects the expenditures
of home health agencies. I will be using 2013 and 2014 PUF data as my pre term and 2016 as post with 2015 acting as a year for 
agencies to prepare for the changes to policy. 

Seven states were included in the HHBVP program :  MA AZ MD NC FL WA IA NE TN

@author: Robert Schuldt
@email : rschuldt@uams.edu

**************************************************************************************************************************************/

libname did 'E:\HHBVP DiD\Data';
libname outputs 'E:\HHBVP DiD\Project Outputs';
libname docs 'E:\HHBVP DiD\Documents';
libname pos 'X:\Data\POS\2015\Data';
option symbolgen;
/*Calling in old import macro to bring the files I need to further analysis*/
%include "E:\SAS Macros\infile macros\proc import.sas";
%include "E:\SAS Macros\infile macros\sort.sas";

%import(E:\HHBVP DiD\Data\2013_hhbvp , xlsx , puf2013);
%import(E:\HHBVP DiD\Data\2014_hhbvp , xlsx , puf2014);
%import(E:\HHBVP DiD\Data\2016 hhbvp , xlsx , puf2016);

data all_year;
	set puf2016
	 puf2014
	 puf2013;
		
	 	percent_female = ((Distinct_Beneficiaries__non_LUPA - Male_Beneficiaries)/Distinct_Beneficiaries__non_LUPA)*100;
		percent_dual = (Dual_Beneficiaries/Distinct_Beneficiaries__non_LUPA)*100;
		percent_non_white = ( ( Distinct_Beneficiaries__non_LUPA - White_Beneficiaries)/Distinct_Beneficiaries__non_LUPA)*100;
		episodes_per_bene =  Distinct_Beneficiaries__non_LUPA/VAR4;
		
		length provider_num $ 6; 
		Provider_Num = Provider_ID;
		Provider_Num = put(input(Provider_Num, 6.),z6.);

run;
/*Using PROC SQL to identify the states that are part of the new HHBVP program*/
proc sql;
create table prepped as
select *, case 
		when state in ( 'MA', 'AZ' ,'MD' ,'NC', 'FL', 'WA', 'IA' , 'NE', 'TN') then hhbvp = 1
			else hhbvp = 0
			end 
		
	
 from all_year ;
quit;

data cleaned_data;
	set prepped;
	drop _TEMA001;
	if _TEMA001 = 0 then hhbvp = 1;

	if  year = 2016 then time = 1;
	else time = 0;

	did = time*hhbvp;

	run;

data pos;
	set pos.pos_2015;
	where PRVDR_CTGRY_CD = "05";
	keep PRVDR_NUM GNRL_CNTL_TYPE_CD FIPS_STATE_CD FIPS_CNTY_CD nfp fp gov other;
	rename prvdr_num = Provider_Num;

	if GNRL_CNTL_TYPE_CD = '01' or '02' or '03' then nfp = 1;
		else nfp = 0;
	if GNRL_CNTL_TYPE_CD = '04' then fp = 1;
		else fp = 0;
	if GNRL_CNTL_TYPE_CD = '05' or '06' or '07' then gov = 1;
		gov = 0;
	if GNRL_CNTL_TYPE_CD = '08' or '09' or '10' then other = 4;
		other = 0;
		
run;
%sort(pos, Provider_Num)
%sort(cleaned_data, Provider_Num)

data pos_owner;
merge cleaned_data (in = a) pos (in = b);
by Provider_Num;
if a;
if b;
run;




