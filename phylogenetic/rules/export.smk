"""
This part of the workflow collects the phylogenetic tree and annotations to
export a Nextstrain dataset.

This part of the workflow expects a single Newick tree and at least one
node data JSON.
"""

rule export:
    message: "Exporting data files for for auspice"
    input:
        tree = "results/229e/tree.nwk",
        metadata = config["metadata"],
        branch_lengths = "results/229e/branch_lengths.json",
        nt_muts = "results/229e/nt_muts.json",
        aa_muts = "results/229e/aa_muts.json",
        auspice_config = config["export"]["auspice_config"]
    output:
        auspice_json = "auspice/229e.json"
    shell:
        """
        export AUGUR_RECURSION_LIMIT=10000;
        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --node-data {input.branch_lengths} {input.nt_muts} {input.aa_muts}  \
            --include-root-sequence \
            --auspice-config {input.auspice_config} \
            --include-root-sequence \
            --output {output.auspice_json}
        """
