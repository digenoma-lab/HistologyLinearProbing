include {
    import_features;
} from './modules/grid_search.nf'
include {
    grid_search_workflow
} from './workflows/grid_search.nf'
include {
    summary_plot
} from './workflows/visualization.nf'

workflow {
    dataset = Channel.value(file(params.dataset))
    features = Channel.fromPath(params.features)
        .splitCsv(header: true, sep: ',')
        .map { row ->
            tuple(
                row.feature_extractor,
                file(row.features_dir)
            )
        }
    script_import_features = Channel.value(file("./linear_probing/import_features.py"))
    script_grid_search_classification = Channel.value(file("./linear_probing/grid_search_classification.py"))
    script_grid_search_regression = Channel.value(file("./linear_probing/grid_search_regression.py"))
    script_scatterplot = Channel.value(file("./linear_probing/scatter.R"))
    script_roc_auc_curve = Channel.value(file("./linear_probing/roc_curve.R"))
    script_boxplot_r2 = Channel.value(file("./linear_probing/boxplot_r2.R"))
    script_boxplot_auc = Channel.value(file("./linear_probing/boxplot_auc.R"))

    import_features(dataset, params.target, features, script_import_features)
    grid_search_workflow(import_features.out.dataset,
        script_grid_search_classification, script_grid_search_regression,
        script_scatterplot, script_roc_auc_curve)
    summary_plot(grid_search_workflow.out.cv_results.collect(),
        script_boxplot_r2, script_boxplot_auc)
}