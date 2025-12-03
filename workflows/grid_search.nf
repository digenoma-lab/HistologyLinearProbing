include {
    grid_search;
    import_features;
} from '../modules/grid_search.nf'
include {
    scatterplot;
} from '../modules/visualization.nf'
workflow grid_search_workflow {
    take:
    dataset
    script_grid_search
    script_scatterplot
    main:
    algorithms = ["ridge", "lasso", "linear_regression"]
    grid_search(dataset, script_grid_search, algorithms)
    scatterplot(grid_search.out.test_predictions, script_scatterplot)
    emit:
    cv_results = grid_search.out.cv_results
}