# scripts/cohort_report.py
from pathlib import Path
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

# ---- ABSOLUTE PATHS (edit only if your folder name changes) ----
ROOT = Path("/Users/caliboi/Desktop/Resumes/Github/Project 1")
DATA = ROOT / "transactions_sample.csv"
OUT  = ROOT / "outputs"
OUT.mkdir(parents=True, exist_ok=True)

print(f"[1] DATA: {DATA}")
print(f"[1] OUT : {OUT}")

# Load data
df = pd.read_csv(DATA)

# Create cohort table
cohort = df.groupby(['signup_month', 'event_month'])['user_id'].nunique().unstack(fill_value=0)
cohort_sizes = cohort.iloc[:, 0]
retention = cohort.divide(cohort_sizes, axis=0)

# Plot retention heatmap
plt.figure(figsize=(10, 6))
sns.heatmap(retention, annot=True, fmt=".0%", cmap="YlGnBu")
plt.title("User Retention by Signup Cohort")
plt.ylabel("Signup Month")
plt.xlabel("Event Month")
plt.tight_layout()

# Save Plot
plt.savefig(OUT / "cohort_retention_heatmap.png", bbox_inches="tight")
plt.close()

# plt.show()   # <-- only use this in interactive runs