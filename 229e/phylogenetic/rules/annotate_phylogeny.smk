"""
This part of the workflow runs ancestral reconstruction and creates additonal
annotations for the phylogenetic tree.

This part of the workflow expects a single Newick tree and any additional files
needed to create the annotations such as the aligned FASTA and metadata file.

This will produce one or more node data JSONs.
"""

rule ancestral:
    message: "Reconstructing ancestral sequences and mutations"
    input:
        tree = "results/tree.nwk",
        alignment = "results/aligned.fasta"
    output:
        node_data = "results/nt_muts.json"
    params:
        inference = config["annotate_phylogeny"]["inference"]
    shell:
        """
        augur ancestral \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --output-node-data {output.node_data} \
            --inference {params.inference}
        """

rule translate:
    message: "Translating amino acid sequences"
    input:
        tree = "results/tree.nwk",
        node_data = rules.ancestral.output.node_data,
        reference = config["reference"]
    output:
        node_data = "results/aa_muts.json"
    shell:
        """
        augur translate \
            --tree {input.tree} \
            --ancestral-sequences {input.node_data} \
            --reference-sequence {input.reference} \
            --output {output.node_data} \
        """


rule traits:
    message: "Inferring ancestral traits for host, so coloring will include nodes"
    input:
        tree = "results/tree.nwk",
        metadata = config["metadata"]
    output:
        node_data = "results/traits.json",
    params:
        columns = config["annotate_phylogeny"]["columns"]
    shell:
        """
        augur traits \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --output-node-data {output.node_data} \
            --columns {params.columns} \
            --confidence
        """
