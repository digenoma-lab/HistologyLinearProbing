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
    publishDir "${params.outdir}/${feature_extractor}/${model}", mode: 'copy'
    input:
        tuple path(dataset), val(feature_extractor)
        path(script)
        val(model)
    output:
        tuple path("cv_result.csv"), path("test_metrics.csv"), path("test_predictions.csv"), emit: results
    script:
        """
        python -u ${script} $dataset $model
        """
    stub:
        """
        touch cv_result.csv
        touch test_metrics.csv
        touch test_predictions.csv
        """
    }