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
    message:
        """
        Filtering to
          - {params.sequences_per_group} sequence(s) per {params.group_by!s}
          - minimum genome length of {params.min_length}
        """
    input:
        sequences = config["prepare_sequences"]["sequences"],
        metadata = config["metadata"],
        exclude = config["prepare_sequences"]["dropped_strains"]
    output:
        sequences = "results/filtered.fasta"
    params:
        group_by = config["prepare_sequences"]["group_by"],
        sequences_per_group = config["prepare_sequences"]["sequences_per_group"],
        min_length = config["prepare_sequences"]["min_length"]
    shell:
        """
        augur filter \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --exclude {input.exclude} \
            --exclude-where 'host!=Homo sapiens' \
            --output {output.sequences} \
            --group-by {params.group_by} \
            --sequences-per-group {params.sequences_per_group} \
            --min-length {params.min_length}
        """

rule align:
    message:
        """
        Aligning sequences to {input.reference}
          - filling gaps with N
        """
    input:
        sequences = rules.filter.output.sequences,
        reference = config["reference"]
    output:
        alignment = "results/aligned.fasta"
    shell:
        """
        augur align \
            --sequences {input.sequences} \
            --reference-sequence {input.reference} \
            --output {output.alignment} \
            --remove-reference \
            --fill-gaps
        """
