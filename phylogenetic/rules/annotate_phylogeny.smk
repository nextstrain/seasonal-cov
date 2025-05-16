"""
This part of the workflow runs ancestral reconstruction and
creates additional annotations for the phylogenetic tree. It expects a
single Newick tree and any additional files needed to create the
annotations such as the aligned FASTA and metadata file.

This will produce one or more node data JSONs.
"""


rule ancestral:
    input:
        tree="results/{virus}/tree.nwk",
        alignment="results/{virus}/aligned.fasta",
    output:
        node_data="results/{virus}/nt_muts.json",
    log:
        "logs/{virus}/ancestral.txt",
    benchmark:
        "benchmarks/{virus}/ancestral.txt"
    params:
        inference=lambda wildcards: config[wildcards.virus]["annotate_phylogeny"]["inference"],
    shell:
        r"""
        exec &> >(tee {log:q})

        augur ancestral \
            --tree {input.tree:q} \
            --alignment {input.alignment:q} \
            --output-node-data {output.node_data:q} \
            --inference {params.inference}
        """


rule translate:
    input:
        tree="results/{virus}/tree.nwk",
        node_data="results/{virus}/nt_muts.json",
        genemap=lambda wildcards: config[wildcards.virus]["genemap"],
    output:
        node_data="results/{virus}/aa_muts.json",
    log:
        "logs/{virus}/translate.txt",
    benchmark:
        "benchmarks/{virus}/translate.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur translate \
            --tree {input.tree:q} \
            --ancestral-sequences {input.node_data:q} \
            --reference-sequence {input.genemap:q} \
            --output {output.node_data:q}
        """
