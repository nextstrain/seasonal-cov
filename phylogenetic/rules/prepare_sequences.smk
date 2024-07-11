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
        exclude="defaults/{virus}/dropped_strains.txt",
    output:
        sequences="results/{virus}/filtered.fasta",
    log:
        "logs/{virus}/filter.txt",
    benchmark:
        "benchmarks/{virus}/filter.txt"
    params:
        group_by=lambda wildcards: config[wildcards.virus]["prepare_sequences"]["group_by"],
        subsample_max_sequences=lambda wildcards: config[wildcards.virus]["prepare_sequences"]["subsample_max_sequences"],
        min_length=lambda wildcards: config[wildcards.virus]["prepare_sequences"]["min_length"],
    shell:
        """
        augur filter \
            --sequences {input.sequences:q} \
            --metadata {input.metadata:q} \
            --exclude {input.exclude:q} \
            --exclude-where "host!=Homo sapiens" \
            --output {output.sequences:q} \
            --group-by {params.group_by:q} \
            --subsample-max-sequences {params.subsample_max_sequences:q} \
            --min-length {params.min_length:q} \
          2>{log:q}
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
              --input-ref {input.reference:q} \
              --input-annotation {input.genemap:q} \
              --output-fasta - \
              --output-tsv {output.insertions:q} \
              {input.sequences:q} \
          | seqkit seq -i > {output.alignment:q} \
        ) 2>{log:q}
        """
