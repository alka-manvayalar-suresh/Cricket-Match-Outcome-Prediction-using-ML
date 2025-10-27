# Data

This folder contains the structured datasets used in the project **“Cricket Match Outcome Prediction using Machine Learning.”**  
All data has been preprocessed and prepared for model development, feature engineering, and evaluation.

## 📂 Files Included

| File | Description |
|------|-------------|
| **deliveries.csv** | Ball-by-ball dataset containing delivery-level information such as runs scored, wickets, and overs. |
| **matches.csv** | Match-level dataset with team names, venues, toss details, and final outcomes. |
| **match_features.csv** | Engineered feature table created from aggregated match and delivery data (e.g., powerplay runs, death-over averages, toss effect, and venue win rate). |
| **train.csv** | Training split of the processed dataset used for machine learning model training. |
| **test.csv** | Testing split used for model evaluation and validation. |

## 🧩 Data Description

The original cricket match data was available in **YAML format** and was parsed into CSV files for efficient handling and integration with the machine learning pipeline.  
The datasets include publicly available historical match statistics and contain **no personal or sensitive information**.

All data cleaning and transformations were performed using **Python (Pandas)** and **SQL scripts**, ensuring consistency and reproducibility across the workflow.

Note:
Only sample datasets are included in this repository for demonstration purposes to comply with file-size and data-sharing guidelines.

