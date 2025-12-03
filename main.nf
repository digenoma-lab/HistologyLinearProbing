include {
    import_features;
} from './modules/grid_search.nf'
include {
    boxplot
} from './modules/visualization.nf'
include {
    grid_search_workflow
} from './workflows/grid_search.nf'

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
    script_grid_search = Channel.value(file("./linear_probing/grid_search.py"))
    script_scatterplot = Channel.value(file("./linear_probing/scatter.R"))
    script_boxplot = Channel.value(file("./linear_probing/boxplot.R"))

    import_features(dataset, params.target, features, script_import_features)
    grid_search_workflow(import_features.out.dataset, script_grid_search, script_scatterplot)
    boxplot(grid_search_workflow.out.cv_results.collect(), script_boxplot)
}