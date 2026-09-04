# SAS Credit Risk Scoring & Automated Decision Engine

A quantitative credit risk pipeline developed in SAS Studio. This project combines a rule engine with statistical modeling to evaluate creditworthiness, mitigate small-sample bias, and automate risk-tier classification.

## Features

* **Inference Engine:** Rules-based evaluation for screening applicants against risk criteria (`PROC REPORT`).
* **Statistical Risk Modeling:**
* **Penalized Logistic Regression:** Implemented Firth’s penalized likelihood approach (`PROC LOGISTIC / firth`) to address small-sample bias, eliminate separation issues, and make default probabilities.
* **Rule Finding via Decision Trees:** Used `PROC HPSPLIT` with hyperparameter controls (`prune none`, `assignmissing=popular`) to show non-linear variable splits and class boundaries.
* **Automated Macro Engine:** Developed a parameterized SAS Macro (`%ExecuteCreditScorer`) to segment candidates into risk bands (Low, Moderate, High) based on adjustable score thresholds.
* **Audit & Compliance Reporting:** Automated cross-tabulations (`PROC FREQ`) and rule audit summaries for portfolio risk management.

## Technical Stack

* **Language:** SAS
* **Procedures:** `PROC LOGISTIC`, `PROC HPSPLIT`, `PROC REPORT`, `PROC FREQ`, `PROC MEANS`
* **Techniques:** Firth's Penalized Likelihood Estimation, Decision Trees, Macro Automation, Missing Data Imputation
