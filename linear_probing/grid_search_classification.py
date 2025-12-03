import sys

import h5py
import numpy as np
import pandas as pd
from sklearn.decomposition import PCA
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score
)
from sklearn.model_selection import GridSearchCV, train_test_split
from sklearn.pipeline import Pipeline


def eval_test_metrics(y_true, y_pred, y_score):
    """Return binary classification metrics as a single-row DataFrame."""
    return pd.DataFrame(
        {
            "accuracy": [accuracy_score(y_true, y_pred)],
            "precision": [precision_score(y_true, y_pred)],
            "recall": [recall_score(y_true, y_pred)],
            "f1": [f1_score(y_true, y_pred)],
            "roc_auc": [roc_auc_score(y_true, y_score)]
        }
    )

# Arguments: dataset.h5 model feature_extractor
dataset_path = sys.argv[1]
model = sys.argv[2]
feature_extractor = sys.argv[3]

with h5py.File(dataset_path, "r") as f:
    X_features = f["features"][:]
    y = f["target"][:]


X_train, X_test, y_train, y_test = train_test_split(
    X_features, y, test_size=0.2, random_state=42, stratify=y
)

if model == "ridge":
    # Logistic regression with L2 penalty (ridge-like)
    param_grid = {
        "pca__n_components": [0.8, 0.9],
        "logreg__C": [0.1, 1.0, 10.0],
    }

    pipeline = Pipeline(
        [
            ("pca", PCA()),
            (
                "logreg",
                LogisticRegression(
                    penalty="l2",
                    solver="liblinear",
                    max_iter=1000,
                ),
            ),
        ]
    )
elif model == "lasso":
    # Logistic regression with L1 penalty (lasso-like)
    param_grid = {
        "pca__n_components": [0.8, 0.9],
        "logreg__C": [0.1, 1.0, 10.0],
    }
    pipeline = Pipeline(
        [
            ("pca", PCA()),
            (
                "logreg",
                LogisticRegression(
                    penalty="l1",
                    solver="liblinear",
                    max_iter=1000,
                ),
            ),
        ]
    )
elif model == "linear":
    # Unregularized logistic regression (no penalty)
    param_grid = {
        "pca__n_components": [0.8, 0.9],
    }
    pipeline = Pipeline(
        [
            ("pca", PCA()),
            (
                "logreg",
                LogisticRegression(
                    solver="lbfgs",
                    max_iter=1000,
                ),
            ),
        ]
    )
else:
    raise ValueError(f"Invalid model: {model}")

grid_search = GridSearchCV(
    estimator=pipeline,
    param_grid=param_grid,
    cv=5,
    scoring=["accuracy", "roc_auc", "f1", "precision", "recall"],
    verbose=3,
    # Use single core to avoid loky resource_tracker issues inside containers
    n_jobs=1,
    return_train_score=True,
    refit="roc_auc",
)
grid_search.fit(X_train, y_train)

cv_results = pd.DataFrame(grid_search.cv_results_)
cv_results.to_csv(f"{feature_extractor}.{model}.cv_result.csv", index=False)

best_model = grid_search.best_estimator_
best_model.fit(X_train, y_train)
y_test_pred = best_model.predict(X_test)

if hasattr(best_model, "predict_proba"):
    y_score = best_model.predict_proba(X_test)[:, 1]
elif hasattr(best_model, "decision_function"):
    y_score = best_model.decision_function(X_test)
else:
    # Fallback: use predicted labels as scores (not ideal, but avoids crashes)
    y_score = y_test_pred

test_metrics = eval_test_metrics(y_test, y_test_pred, y_score)
test_metrics.to_csv(f"{feature_extractor}.{model}.test_metrics.csv", index=False)

y = pd.DataFrame({"y_true": y_test, "y_pred": y_score})
y.to_csv(f"{feature_extractor}.{model}.test_predictions.csv", index=False)
