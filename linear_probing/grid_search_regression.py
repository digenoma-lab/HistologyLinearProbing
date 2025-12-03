import sys
import pandas as pd
from sklearn.model_selection import GridSearchCV, train_test_split
from sklearn.linear_model import Ridge, Lasso, LinearRegression, ElasticNet
from sklearn.pipeline import Pipeline
from sklearn.decomposition import PCA
from sklearn.metrics import (
    mean_squared_error,
    r2_score,
    mean_absolute_error,
    root_mean_squared_error,
)
import h5py
import numpy as np

def eval_test_metrics(y_true, y_pred):
    """Return test metrics as a single-row DataFrame."""
    return pd.DataFrame(
        {
            "r2": [r2_score(y_true, y_pred)],
            "mse": [mean_squared_error(y_true, y_pred)],
            "mae": [mean_absolute_error(y_true, y_pred)],
            "rmse": [root_mean_squared_error(y_true, y_pred)],
        }
    )
def iqr(X, y):
    """
    Remove outliers in y using the IQR rule and keep X aligned.
    X: numpy array of shape (n_samples, n_features)
    y: 1D numpy array of shape (n_samples,)
    """
    y = np.asarray(y)
    X = np.asarray(X)

    y_q1 = np.quantile(y, 0.25)
    y_q3 = np.quantile(y, 0.75)
    iqr_factor = 1.5 * (y_q3 - y_q1)
    y_min = y_q1 - iqr_factor
    y_max = y_q3 + iqr_factor

    mask = (y >= y_min) & (y <= y_max)
    return X[mask], y[mask]

# Arguments: dataset.h5 cv_results.csv test_metrics.csv
dataset_path = sys.argv[1]
model = sys.argv[2]
feature_extractor = sys.argv[3]

with h5py.File(dataset_path, "r") as f:
    X_features = f["features"][:]
    y = f["target"][:]

X_features, y = iqr(X_features, y)

X_train, X_test, y_train, y_test = train_test_split(
    X_features, y, test_size=0.2, random_state=42
)

if model == "ridge":
    param_grid = {
        "pca__n_components": [0.8, 0.9],
        "ridge__alpha": [1e-1, 1],
    }

    pipeline = Pipeline(
        [
            ("pca", PCA()),
            ("ridge", Ridge()),
        ]
    )
elif model == "lasso":
    param_grid = {
        "pca__n_components": [0.8, 0.9],
        "lasso__alpha": [1e-1, 1],
    }
    pipeline = Pipeline(
        [
            ("pca", PCA()),
            ("lasso", Lasso()),
        ]
    )
elif model == "linear":
    param_grid = {
        "pca__n_components": [0.8, 0.9],
    }
    pipeline = Pipeline(
        [
            ("pca", PCA()),
            ("linear", LinearRegression()),
        ]
    )
else:
    raise ValueError(f"Invalid model: {model}")

grid_search = GridSearchCV(
    estimator=pipeline,
    param_grid=param_grid,
    cv=5,
    scoring=["r2", "neg_mean_squared_error"],
    verbose=3,
    n_jobs=16,
    return_train_score=True,
    refit="r2",
)
grid_search.fit(X_train, y_train)

cv_results = pd.DataFrame(grid_search.cv_results_)
cv_results.to_csv(f"{feature_extractor}.{model}.cv_result.csv", index=False)

best_model = grid_search.best_estimator_
best_model.fit(X_train, y_train)
y_test_pred = best_model.predict(X_test)

test_metrics = eval_test_metrics(y_test, y_test_pred)
test_metrics.to_csv(f"{feature_extractor}.{model}.test_metrics.csv", index=False)

y = pd.DataFrame({"y_true": y_test, "y_pred": y_test_pred})
y.to_csv(f"{feature_extractor}.{model}.test_predictions.csv", index=False)
