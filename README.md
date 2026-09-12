
# Customer Churn & Retention Intelligence

A data analytics and machine learning project that identifies customers at risk of churn, analyzes key churn drivers, and estimates revenue at risk to support retention decisions.

## Tech Stack

- Python: Pandas, NumPy, Scikit-learn, SciPy, Statsmodels
- ML: Logistic Regression, Random Forest, XGBoost
- Survival Analysis: Lifelines
- SQL: MySQL
- Visualization: Power BI, Matplotlib

## Key Analysis

- Exploratory Data Analysis
- Churn & revenue KPIs
- Statistical inference
- Kaplan-Meier & Cox survival analysis
- Predictive churn modeling
- Customer risk scoring
- Revenue-at-risk analysis

## Key Results

- **6,000** customers analyzed
- **21.8%** overall churn rate
- **$107,252** MRR lost
- **861** active customers classified as High Risk
- **~$147K** expected MRR at risk
- Best model: **Logistic Regression**
- ROC-AUC: **0.779**
- Churn Recall: **69.1%**

## Key Insights

Failed payments, low product usage, low CSAT, month-to-month contracts, high support activity, and low feature adoption were the strongest churn signals.

The project combines **churn probability + revenue exposure** to prioritize customers for retention.

## Project Files

- `customer_churn_retention_intelligence.ipynb` — Complete analysis
- `stage4_sql_analysis.sql` — SQL analysis
- `customer_churn_powerbi.csv` — Power BI dataset
