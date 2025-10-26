# 🏏 Cricket Match Outcome Prediction using Machine Learning

This project presents an end-to-end pipeline that predicts the outcomes of professional cricket matches using machine learning.  
The goal was to design a **reproducible, interpretable, and data-driven system** that learns from historical records and forecasts match winners based on performance trends, toss outcomes, and head-to-head statistics.

## 🎯 Project Summary

Cricket is one of the most data-rich sports, producing detailed match records that can be used to identify patterns and competitive advantages.  
This project applies modern machine learning methods to uncover those insights and build a predictive framework that can assist analysts, commentators, and fans in understanding match dynamics before play begins.

The system combines **data engineering, predictive modelling, and visualization** to offer a full analytical view of how team performance indicators influence outcomes.

## ⚙️ System Workflow

The overall workflow follows a modular pipeline architecture:

CricSheet YAML Data → Python Preprocessing (YAML → CSV)
→ SQL Feature Engineering
→ Machine Learning Models (LR, RF, XGBoost, SVM)
→ Power BI Visualization
→ Optional Flask API for Deployment

Each module in this workflow performs a clear function — transforming raw data into usable formats, extracting informative features, training models, and visualizing key insights for easier interpretation.

## 🧩 Data & Features

The dataset was obtained from **CricSheet.org**, a public cricket data repository offering structured match information in YAML format.  
After conversion to CSV, SQL scripts were used to generate **aggregate match-level features** such as:

- Powerplay runs (overs 1–6)  
- Death overs runs (overs 16–20)  
- Toss advantage indicators  
- Head-to-head win percentages  

These engineered features summarize each team’s momentum and strategy across multiple matches, allowing predictive models to learn general performance trends.

## 🧠 Model Development

The modelling stage explored multiple algorithms - **Logistic Regression**, **Random Forest**, **XGBoost**, and **Support Vector Machine (SVM)** - using identical features and evaluation procedures.  
This allowed fair comparison of classical and ensemble learning methods for binary outcome prediction (Team 1 Win vs. Team 2 Win).

Model performance was assessed through a **chronological train/test split**, ensuring time-aware evaluation that reflects real-world prediction conditions.

## 📊 Visualization & Insights

A **Power BI dashboard** was developed to communicate results visually.  
It includes:
- Model comparison panels  
- Accuracy and precision indicators  
- Confusion matrices  
- Team-wise performance charts  
- Best-model highlight (SVM)  

This dashboard serves as the analytical front-end for stakeholders to interpret model predictions intuitively.

## 🌐 Deployment (Flask API)

To make the predictive model accessible for integration, a lightweight **Flask API** was implemented.  
It loads the trained SVM model and exposes a `/predict` endpoint that accepts team statistics and returns the predicted winner and probability.  
This demonstrates the project’s readiness for production-style applications and web integration.

## 📈 Results Summary

The machine learning pipeline designed for cricket match outcome prediction produced consistent and interpretable results across multiple algorithms.  
Each model was trained using a chronological split, ensuring that earlier seasons were used for training while later seasons were reserved for testing.  
This approach reflects a realistic forecasting scenario and prevents data leakage from future matches.

The following table summarises the comparative performance of all four models evaluated:

| Machine Learning Model | Accuracy | Precision | Recall | F1-Score |
|--------------------------|:---------:|:----------:|:--------:|:---------:|
| Logistic Regression | 0.62 | 0.65 | 0.59 | 0.61 |
| Random Forest | 0.65 | 0.68 | 0.61 | 0.64 |
| XGBoost | 0.67 | 0.70 | 0.63 | 0.66 |
| **Support Vector Machine (SVM)** | **0.68** | **0.71** | **0.64** | **0.68** |

The **SVM model** achieved the best overall performance, demonstrating balanced precision and recall with the highest F1-score.  

A Power BI dashboard was developed to visualise these outcomes, featuring:
- A model comparison panel for quick metric insights  
- Confusion matrices showing prediction distribution  
- Feature importance charts highlighting key match drivers  
- Per-team accuracy breakdowns for interpretability  

## 🧮 Tech Stack

| Layer | Tools / Libraries |
|-------|-------------------|
| Data Source | CricSheet (YAML) |
| Data Processing | Python (pandas, numpy, yaml) |
| Feature Engineering | SQL (PostgreSQL) |
| Machine Learning | scikit-learn, XGBoost |
| Visualization | Power BI |
| Deployment | Flask API |
| Development Environment | Google Colab, Visual Studio Code |
