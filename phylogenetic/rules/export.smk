"""
This part of the workflow collects the phylogenetic tree and annotations to
export a Nextstrain dataset.

This part of the workflow expects a single Newick tree and at least one
node data JSON.
"""

rule export:
    message: "Exporting data files for for auspice"
    input:
        tree = "results/{virus}/tree.nwk",
        metadata = lambda wildcards:config[wildcards.virus]["metadata"],
        branch_lengths = "results/{virus}/branch_lengths.json",
        nt_muts = "results/{virus}/nt_muts.json",
        aa_muts = "results/{virus}/aa_muts.json",
        auspice_config = "config/{virus}/auspice_config.json"
    output:
        auspice_json = "auspice/{virus}.json"
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
