process import_features {
    input:
        path(dataset)
        val(target_column)
        tuple val(feature_extractor), path(features_dir)
        path(script)
    output:
        tuple path("${feature_extractor}.h5"), val(feature_extractor), emit: dataset
    script:
        """
        python -u ${script} $dataset $target_column $features_dir ${feature_extractor}
        """
    stub:
        """
        touch dataset.h5
        """
}

process grid_search {
    publishDir "${params.outdir}/cv_result/", mode: 'copy', pattern: "*.cv_result.csv"
    publishDir "${params.outdir}/test_metrics/", mode: 'copy', pattern: "*.test_metrics.csv"
    publishDir "${params.outdir}/test_predictions/", mode: 'copy', pattern: "*.test_predictions.csv"
    input:
        tuple path(dataset), val(feature_extractor)
        path(script)
        each model
    output:
        path("${feature_extractor}.${model}.cv_result.csv"), emit: cv_results
        path("${feature_extractor}.${model}.test_metrics.csv"), emit: test_metrics
        path("${feature_extractor}.${model}.test_predictions.csv"), emit: test_predictions
    script:
        """
        python -u ${script} $dataset $model $feature_extractor
        """
    stub:
        """
        touch ${feature_extractor}.${model}.cv_result.csv
        touch ${feature_extractor}.${model}.test_metrics.csv
        touch ${feature_extractor}.${model}.test_predictions.csv
        """
}