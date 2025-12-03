include {
    boxplot;
} from '../modules/visualization.nf'

workflow summary_plot {
    take:
    cv_results
    script_boxplot_r2
    script_boxplot_auc
    main:
    if (params.task == "classification"){
        boxplot(cv_results, script_boxplot_auc)
    }
    else {
        boxplot(cv_results, script_boxplot_r2)
    }
}