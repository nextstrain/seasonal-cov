"""
This part of the workflow collects the phylogenetic tree and
annotations to export a Nextstrain dataset. It expects a single Newick
tree and at least one node data JSON.

"""


rule export:
    input:
        tree="results/{virus}/tree.nwk",
        metadata=lambda wildcards: config[wildcards.virus]["metadata"],
        branch_lengths="results/{virus}/branch_lengths.json",
        nt_muts="results/{virus}/nt_muts.json",
        aa_muts="results/{virus}/aa_muts.json",
        description="defaults/description.md",
        auspice_config="defaults/auspice_config.json",
    output:
        auspice_json="auspice/seasonal-cov_{virus}.json",
    params:
        auspice_title=lambda wildcards: f"Genomic epidemiology of seasonal coronavirus {wildcards.virus.upper()}",
    log:
        "logs/{virus}/export.txt",
    benchmark:
        "benchmarks/{virus}/export.txt"
    shell:
        """
        augur export v2 \
          --tree {input.tree:q} \
          --metadata {input.metadata:q} \
          --node-data {input.branch_lengths:q} {input.nt_muts:q} {input.aa_muts:q}  \
          --include-root-sequence \
          --description {input.description:q} \
          --auspice-config {input.auspice_config:q} \
          --title {params.auspice_title:q} \
          --include-root-sequence \
          --output {output.auspice_json:q} \
        2>{log:q}
        """
