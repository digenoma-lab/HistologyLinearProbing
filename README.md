## HistologyLinearProbing

**Linear probing pipeline** for histopathology to evaluate different **feature extractors** (foundation models) using simple linear models (ridge, lasso and linear regression) on genes of interest (for example, *MKI67* and *ESR1*).

The workflow is implemented in **Nextflow DSL2** and uses containers (Wave/Singularity) to run both the Python part (feature import and grid search) and the R part (visualizations).

---

### Pipeline overview

- **`main.nf`**  
  Orchestrates the pipeline:
  - Reads the clinical/gene-expression dataset (`params.dataset`).
  - Reads the list of `feature_extractor` and their paths (`params.features`).
  - Launches:
    - `import_features`: builds `.h5` files with features + target.
    - `grid_search_workflow`: trains linear models per feature extractor.
    - `boxplot`: generates a boxplot comparing model performance.

- **`modules/grid_search.nf`**
  - `process import_features`: runs `linear_probing/import_features.py`.
  - `process grid_search`: runs `linear_probing/grid_search.py` for each `feature_extractor × model (ridge, lasso, linear_regression)` combination and publishes:
    - `*.cv_result.csv`
    - `*.test_metrics.csv`
    - `*.test_predictions.csv`

- **`workflows/grid_search.nf`**
  - Defines the `grid_search_workflow` workflow, which:
    - Runs `grid_search` for the models: `ridge`, `lasso`, `linear_regression`.
    - Generates scatterplots for each prediction file with `scatter.R`.

- **`modules/visualization.nf`**
  - `process scatterplot`: generates `y_true` vs `y_pred` scatterplots.
  - `process boxplot`: generates a global R² boxplot per extractor/algorithm.

- **`linear_probing/`**
  - `import_features.py`: loads the clinical/expression CSV, collects features by `slide_id`, and writes one `.h5` per extractor.
  - `grid_search.py`: applies IQR filtering, runs `GridSearchCV` with PCA + linear model, and saves results and predictions.
  - `boxplot.R`: reads all `*cv_result.csv` and generates `boxplot.png`.
  - `scatter.R`: reads each `*test_predictions.csv` and generates `*.scatterplot.png`.

---

### Inputs

- **Expression/metadata file** (`params.dataset` in `params/params.yml`)
  - CSV with at least:
    - A `slide_id` column to link samples with feature files.
    - Columns with genes of interest (for example `MKI67`, `ESR1`).

- **Feature list** (`params.features` in `params/params.yml`)
  - CSV with columns:
    - `feature_extractor`: model name (e.g. `mean-uni_v1`, `mean-virchow2`).
    - `features_dir`: path to the directory containing per-slide feature files (one `.h5` per `slide_id`).

- **Pipeline parameters** (`params/params.yml`)
  - Example:
    ```yaml
    dataset: './params/Gene_expr_MKI67_ESR1.csv'
    features: "./params/features.csv"
    outdir: "./results_esr1/"
    target: "ESR1"
    ```
  - By changing `outdir` and `target` you can run the pipeline for different genes (for example, `results_mki67/` with `target: "MKI67"`).

---

### Outputs

All outputs are written under `params.outdir` (configured in `params/params.yml`):

- **Grid search results**
  - `cv_result/`
    - `feature_extractor.model.cv_result.csv`
  - `test_metrics/`
    - `feature_extractor.model.test_metrics.csv`
  - `test_predictions/`
    - `feature_extractor.model.test_predictions.csv`

- **Plots**
  - `plots/boxplot.png`  
    Distribution of R² by `feature_extractor` and `algorithm`.
  - `plots/*.scatterplot.png`  
    One scatterplot per `*test_predictions.csv` file (y_true vs y_pred, with R² in the title).

- **Pipeline information**
  - `pipeline_info/` (timeline, report, trace, DAG HTML) generated automatically by Nextflow.

---

### Requirements

- **Nextflow** ≥ 22.x
- Access to Singularity/Wave containers (configured in `nextflow.config`).
- Cluster with **SLURM** if using the `kutral` profile (default in this repo).

> Note: you do **not** need to manually install the Python/R dependencies: they are provided through the containers declared in `nextflow.config`.

---

### Basic usage

1. Load the environment where Nextflow and Singularity are available.
2. Edit `params/params.yml` (dataset, features, target, outdir).
3. Run the pipeline, for example:

```bash
nextflow run main.nf -profile kutral -params-file params/params.yml
```

For local execution (without SLURM), you can use the `local` profile defined in `nextflow.config`:

```bash
nextflow run main.nf -profile local -params-file params/params.yml
```

---

### Contact

Author: **Gabriel Cabas**  
For questions or suggestions, please open an *issue* or *pull request* in this repository. 