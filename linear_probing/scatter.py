import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import sys
from sklearn.metrics import r2_score

def scatterplot(df):
    plt.figure(figsize=(10, 10))
    sns.scatterplot(x="y_true", y="y_pred", data=df)
    max_value = df["y_true"].max() + 1
    min_value = df["y_true"].min() - 1
    plt.plot([min_value, max_value], [min_value, max_value], color="red", linestyle="--")
    plt.xlabel("True Value")
    plt.ylabel("Predicted Value")
    plt.title(f"Scatter Plot of True vs Predicted Values (R2 Score: {r2_score(df['y_true'], df['y_pred']):.2f})")
    plt.legend(["Predicted vs True", "Perfect Prediction"])
    plt.savefig("scatterplot.png")

if __name__ == "__main__":
    test_predictions = sys.argv[1]
    df = pd.read_csv(test_predictions)
    scatterplot(df)