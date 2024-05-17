"""
This part of the workflow prepares sequences for constructing the phylogenetic tree.
This usually includes the following steps:

    - filtering
    - subsampling
    - aligning

This part of the workflow expects a metadata TSV and FASTA file as inputs
and will produce an aligned FASTA file of subsampled sequences as an output.
"""


rule filter:
    input:
        sequences=lambda wildcards: config[wildcards.virus]["prepare_sequences"]["sequences"],
        metadata=lambda wildcards: config[wildcards.virus]["metadata"],
        exclude="config/{virus}/dropped_strains.txt",
    output:
        sequences="results/{virus}/filtered.fasta",
    log:
        "logs/{virus}/filter.txt",
    benchmark:
        "benchmarks/{virus}/filter.txt"
    params:
        group_by=lambda wildcards: config[wildcards.virus]["prepare_sequences"]["group_by"],
        sequences_per_group=lambda wildcards: config[wildcards.virus]["prepare_sequences"]["sequences_per_group"],
        min_length=lambda wildcards: config[wildcards.virus]["prepare_sequences"]["min_length"],
    shell:
        """
        augur filter \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --exclude {input.exclude} \
            --exclude-where "host!=Homo sapiens" \
            --output {output.sequences} \
            --group-by {params.group_by} \
            --sequences-per-group {params.sequences_per_group} \
            --min-length {params.min_length} 2>{log}
        """


rule align:
    input:
        sequences="results/{virus}/filtered.fasta",
        reference=lambda wildcards: config[wildcards.virus]["reference"],
        genemap=lambda wildcards: config[wildcards.virus]["genemap"],
    output:
        alignment="results/{virus}/aligned.fasta",
        insertions="results/{virus}/insertions.tsv",
    log:
        "logs/{virus}/align.txt",
    benchmark:
        "benchmarks/{virus}/align.txt"
    shell:
        """
        (
          nextclade run \
              --input-ref {input.reference} \
              --input-annotation {input.genemap} \
              --output-fasta - \
              --output-tsv {output.insertions} \
              {input.sequences} | seqkit seq -i > {output.alignment}
        ) 2>{log}
        """
