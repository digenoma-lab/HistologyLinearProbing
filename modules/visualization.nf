process boxplot {
    publishDir "${params.outdir}/plots/", mode: "copy"
    input:
    path(cv_results)
    path(script_boxplot)
    output:
    path("boxplot.png")
    script:
    """
    Rscript ${script_boxplot} ./
    """
    stub:
    """
    touch boxplot.png
    """
}

process scatterplot {
    publishDir "${params.outdir}/plots/", mode: 'copy'
    input:
    path(test_predictions)
    path(script)
    output:
    path("${test_predictions}.scatterplot.png"), emit: scatterplot
    script:
    """
    Rscript ${script} $test_predictions
    cp scatterplot.png ${test_predictions}.scatterplot.png
    """
    stub:
    """
    touch ${test_predictions}.scatterplot.png
    """
}