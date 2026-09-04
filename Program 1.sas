/* STAGE 1: SYSTEM SETUP & DATA INGESTION                                       */
options nodate nonumber ps=60 ls=80 validvarname=v7;
title "Credit Screening Analysis & Risk Engine";

/* 1.1 Ingest Logic-Based Knowledge Base (Dataset 1: Credit Screening) */
data work.kb_persons;
    length ID $5 Gender $6 Marital_Status $10 Region $11 Purchase_Item $12;
    input ID $ Gender $ Marital_Status $ Region $ Purchase_Item $ 
          Age Deposit Monthly_Payment Numb_Months Years_In_Company Target_Credit;
    datalines;
s1  female unmarried normal pc 18 20 2 15 1 1
s2  female unmarried normal pc 20 10 2 20 2 1
s3  female married problematic pc 25 5 4 12 0 0
s4  female married normal pc 40 5 7 12 2 1
s5  female unmarried problematic pc 50 5 4 12 25 1
s6  male unmarried normal pc 18 10 5 8 1 1
s7  male unmarried normal pc 22 10 3 8 4 1
s8  male married normal pc 28 15 4 10 5 1
s9  male married normal pc 40 20 2 20 15 1
s10 male married normal pc 50 5 4 12 0 0
s11 female unmarried normal car 18 50 8 20 1 1
s12 female married normal car 20 50 10 20 2 0
s13 female unmarried normal car 25 50 5 20 5 0
s14 female unmarried normal car 38 150 10 20 15 1
s15 female married normal car 50 50 15 20 . 1
s16 male unmarried normal car 19 50 7 20 2 0
s17 male married normal car 21 150 3 20 3 1
s18 male unmarried normal car 25 150 10 20 2 1
s19 male married normal car 38 100 10 20 15 1
s20 male married normal car 50 50 10 30 2 0
s23 female married problematic stereo 55 30 10 8 0 0
s30 female unmarried problematic stereo 68 2 7 8 0 0
s48 male unmarried problematic jewel 40 9 9 10 1 0
s56 female married normal jewel 43 10 2 20 0 1
s60 male unmarried problematic jewel 33 100 2 5 0 0
s68 male unmarried problematic medinstru 37 300 50 10 1 0
s82 male unmarried problematic medinstru 67 400 15 5 0 0
s84 male unmarried problematic jewel 37 200 50 10 25 1
s85 female married normal stereo 52 100 5 5 0 1
s105 male unmarried problematic bike 35 10 10 10 2 0
s106 male unmarried normal bike 18 15 1 10 1 1
s115 female married normal bike 25 10 5 10 5 0
s116 female married normal furniture 40 50 5 20 20 1
s125 male married normal furniture 25 20 7 20 1 0
;
run;

/* 1.2 Ingest Attribute-based Anonymous Dataset (Dataset 2: Credit Approval) */
data work.uci_credit;
    length A1 $1 A4 $1 A5 $2 A6 $2 A7 $2 A9 $1 A10 $1 A12 $1 A13 $1 Target_Approval $1;
    infile datalines dlm=',' dsd missover;
    input A1 $ A2 A3 A4 $ A5 $ A6 $ A7 $ A8 A9 $ A10 $ A11 A12 $ A13 $ A14 A15 Target_Approval $;
    datalines;
b,30.83,0,u,g,w,v,1.25,t,t,01,f,g,00202,0,+
a,58.67,4.46,u,g,q,h,3.04,t,t,06,f,g,00043,560,+
a,24.50,0.5,u,g,q,h,1.5,t,f,0,f,g,00280,824,+
b,27.83,1.54,u,g,w,v,3.75,t,t,05,t,g,00100,3,+
b,20.17,5.625,u,g,w,v,1.71,t,f,0,f,s,00120,0,+
b,32.08,4,u,g,m,v,2.5,t,f,0,t,g,00360,0,+
b,33.17,1.04,u,g,r,h,6.5,t,f,0,t,g,00164,31285,+
a,22.92,11.585,u,g,cc,v,0.04,t,f,0,f,g,00080,1349,+
b,54.42,0.5,y,p,k,h,3.96,t,f,0,f,g,00180,314,+
b,42.50,4.915,y,p,w,v,3.165,t,f,0,t,g,00052,1442,+
b,32.33,7.5,u,g,e,bb,1.585,t,f,0,t,s,00420,0,-
b,34.83,4,u,g,d,bb,12.5,t,f,0,t,g,.,0,-
a,38.58,5,u,g,cc,v,13.5,t,f,0,t,g,00980,0,-
b,44.25,0.5,u,g,m,v,10.75,t,f,0,f,s,00400,0,-
b,44.83,7,y,p,c,v,1.625,f,f,0,f,g,00160,2,-
;
run;

/* STAGE 2: KNOWLEDGE BASE RULE INFERENCE ENGINE                                */

data work.kb_rules_evaluated;
    set work.kb_persons;

    /* Metrics */
    Total_Loan_Cost = Monthly_Payment * Numb_Months;
    Jobless_Flag = (Years_In_Company = 0);

    /* Rule Evaluation Logic */
    /* Rule 1: Jobless Male Reject */
    r_jobless_male_reject = (Jobless_Flag = 1 and Gender = 'male');

    /* Rule 2: Jobless Unmarried Female Reject */
    r_jobless_unmarried_fem_reject = (Jobless_Flag = 1 and Gender = 'female' and Marital_Status = 'unmarried');

    /* Rule 3: Unmatched Female Condition */
    unmatch_fem = 0;
    if Gender = 'female' then do;
        if Purchase_Item = 'bike' or Total_Loan_Cost > Deposit then unmatch_fem = 1;
    end;

    /* Rule 4: Jobless Unmatched Female Reject */
    r_jobless_unmatch_fem_reject = (Jobless_Flag = 1 and Gender = 'female' and Marital_Status ne 'unmarried' and unmatch_fem = 1);

    /* Rule 5: Discredit Bad Region */
    r_discredit_bad_region = (Region = 'problematic' and Years_In_Company <= 10);

    /* Rule 6: Reject Aged Unstable Work */
    r_reject_aged_unstable_work = (Age > 59 and Years_In_Company < 3);

    /* Rule Aggregation */
    if r_jobless_male_reject or 
       r_jobless_unmarried_fem_reject or 
       r_jobless_unmatch_fem_reject or 
       r_discredit_bad_region or 
       r_reject_aged_unstable_work then Rule_Bad_Credit = 1;
    else Rule_Bad_Credit = 0;

    Rule_OK_Credit = (Rule_Bad_Credit = 0);
run;

/* STAGE 3: DATA PREPROCESSING & FEATURE ENGINEERING                            */

/* Calculate Summary Statistics for Imputation */
proc means data=work.uci_credit median mean noprint;
    var A2 A8 A11 A14 A15;
    output out=work.uci_stats 
        median(A2)=med_A2 
        mean(A8)=mean_A8 
        mean(A11)=mean_A11 
        mean(A14)=mean_A14 
        mean(A15)=mean_A15;
run;

/* Impute missing values while retaining all original variables */
data work.uci_transformed;
    if _N_ = 1 then set work.uci_stats;
    set work.uci_credit;
    
    if missing(A2)  then A2  = med_A2;
    if missing(A8)  then A8  = mean_A8;
    if missing(A11) then A11 = mean_A11;
    if missing(A14) then A14 = mean_A14;
    if missing(A15) then A15 = mean_A15;

    /* Binary Target Flag */
    if Target_Approval = '+' then Target_Binary = 1;
    else if Target_Approval = '-' then Target_Binary = 0;

    /* Feature Interactions & Ratios */
    Debt_To_Income_Proxy = A3 / (A8 + 0.001);
    Log_A15 = log(A15 + 1);
    
    drop _TYPE_ _FREQ_ med_A2 mean_A8 mean_A11 mean_A14 mean_A15;
run;

/* STAGE 4: STATISTICAL MODELING                                       */

/* 4.1 Parsimonious Logistic Model for Small Samples */
proc logistic data=work.uci_transformed plots=roc;
    model Target_Binary(event='1') = A3 A8 Log_A15
        / firth lackfit expb ridging=none;
    output out=work.logistic_scores p=pred_prob;
run;

/* 4.2 Decision Tree Model for Knowledge Rule Finding */
filename treerule "%sysfunc(pathname(work))/tree_rules.sas";
proc hpsplit data=work.uci_transformed maxdepth=4 cvmethod=none assignmissing=popular;
    class A1 A4 A5 A6 A7 A9 A10 A12 A13 Target_Approval;
    model Target_Approval = A1 A2 A3 A4 A5 A6 A7 A8 A9 A10 A11 A12 A13 A14 A15;
    grow entropy;
    prune none; /* Prevents tree from collapsing to Node 0 */
    code file=treerule;
run;

/* STAGE 5: MACRO FOR CREDIT RISK SCORING                      */

%macro ExecuteCreditScorer(InDataset=, OutDataset=, Threshold=0.50);
    %put NOTE: Starting Credit Decision Macro at &SYSDATE &SYSTIME...;

    data &OutDataset;
        set &InDataset;
        
        /* Decision Logic */
        if pred_prob >= &Threshold then do;
            Final_Decision = "APPROVED";
            Credit_Score_Band = "Low Risk";
        end;
        else do;
            Final_Decision = "REJECTED";
            if pred_prob < 0.25 then Credit_Score_Band = "High Risk";
            else Credit_Score_Band = "Moderate Risk";
        end;
        
        format pred_prob percent8.2;
    run;

    proc freq data=&OutDataset;
        tables Final_Decision * Credit_Score_Band / chisq;
        title "Decision Distribution for Threshold = &Threshold";
    run;
%mend ExecuteCreditScorer;

%ExecuteCreditScorer(InDataset=work.logistic_scores, OutDataset=work.final_decisions, Threshold=0.45);

/* STAGE 6: REPORTING & RISK AUDIT                                              */

proc report data=work.kb_rules_evaluated nowd;
    column ID Gender Age Jobless_Flag Region Purchase_Item Total_Loan_Cost Deposit Rule_Bad_Credit;
    define ID / display "Applicant ID";
    define Gender / display "Gender";
    define Age / analysis mean "Mean Age";
    define Jobless_Flag / display "Jobless?";
    define Region / display "Region Type";
    define Purchase_Item / display "Item";
    define Total_Loan_Cost / analysis sum "Total Loan";
    define Deposit / analysis sum "Deposit";
    define Rule_Bad_Credit / display "Rule Reject Flag";
    rbreak after / summarize;
    title "Expert System Rule Evaluation Summary";
run;
