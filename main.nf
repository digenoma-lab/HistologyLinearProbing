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
    dataset = Channel.value(file('/mnt/beegfs/labs/DiGenomaLab/Machine_Learning/cancer_histology/data/tcga_gdc/tasks/Gene_expr_MKI67_ESR1.csv'))
    features = Channel.fromPath("features.csv")
        .splitCsv(header: true, sep: ',')
        .map { row ->
            tuple(
                row.feature_extractor,
                file(row.features_dir)
            )
        }

    target_column = "MKI67"

    script_import_features = Channel.value(file("./linear_probing/import_features.py"))
    script_grid_search = Channel.value(file("./linear_probing/grid_search.py"))
    script_scatterplot = Channel.value(file("./linear_probing/scatter.R"))
    script_boxplot = Channel.value(file("./linear_probing/boxplot.R"))

    import_features(dataset, target_column, features, script_import_features)
    grid_search_workflow(import_features.out.dataset, script_grid_search, script_scatterplot)
    boxplot(grid_search_workflow.out.cv_results.collect(), script_boxplot)

}