import pandas as pd

# Load dataset
data = pd.read_csv("Gene_expr_MKI67_ESR1.csv")

# Ensure ESR1 and MKI67 are numeric (coerce non-numeric to NaN)
for col in ["ESR1", "MKI67"]:
    data[col] = pd.to_numeric(data[col], errors="coerce")

# Binarize each gene around its mean (ignoring NaNs)
for col in ["ESR1", "MKI67"]:
    mean_val = data[col].mean()
    mask_high = data[col] > mean_val
    data[col] = 0
    data.loc[mask_high, col] = 1

data.to_csv("classified_MKI67_ESR1.csv", index=False)