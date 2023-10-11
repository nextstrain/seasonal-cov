"""
This part of the workflow constructs the phylogenetic tree.

This part of the workflow expects a single aligned FASTA file.
If constructing a time-resolved tree, it will also require a metadata file
that includes a sample date for each sequence.

This will produce a Newick tree and a branch lengths JSON file.
"""

rule tree:
    message: "Building tree"
    input:
        alignment = "results/aligned.fasta"
    output:
        tree = "results/tree_raw.nwk"
    shell:
        """
        augur tree \
            --alignment {input.alignment} \
            --output {output.tree}
        """

rule refine:
    message:
        """
        Refining tree
        """
    input:
        tree = rules.tree.output.tree,
        alignment = "results/aligned.fasta",
        metadata = config["metadata"]
    output:
        tree = "results/tree.nwk",
        node_data = "results/branch_lengths.json"
    params:
        coalescent = config["construct_phylogeny"]["coalescent"],
        date_inference = config["construct_phylogeny"]["date_inference"],
        clock_filter_iqd= config["construct_phylogeny"]["clock_filter_iqd"]
    shell:
        """
        augur refine \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --metadata {input.metadata} \
            --output-tree {output.tree} \
            --output-node-data {output.node_data} \
            --timetree \
            --coalescent {params.coalescent} \
            --date-confidence \
            --date-inference {params.date_inference} \
            --clock-filter-iqd {params.clock_filter_iqd}
        """
