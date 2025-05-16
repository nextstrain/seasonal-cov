"""
This part of the workflow collects the phylogenetic tree and
annotations to export a Nextstrain dataset. It expects a single Newick
tree and at least one node data JSON.

"""


rule export:
    input:
        tree="results/{virus}/tree.nwk",
        metadata="data/{virus}/metadata.tsv",
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
        r"""
        exec &> >(tee {log:q})

        augur export v2 \
          --tree {input.tree:q} \
          --metadata {input.metadata:q} \
          --node-data {input.branch_lengths:q} {input.nt_muts:q} {input.aa_muts:q}  \
          --include-root-sequence \
          --description {input.description:q} \
          --auspice-config {input.auspice_config:q} \
          --title {params.auspice_title:q} \
          --include-root-sequence \
          --output {output.auspice_json:q}
        """

rule tip_frequencies:
    """
    Estimating KDE frequencies for tips
    """
    input:
        tree = "results/{virus}/tree.nwk",
        metadata = "data/{virus}/metadata.tsv",
    output:
        tip_freq = "auspice/seasonal-cov_{virus}_tip-frequencies.json"
    params:
        strain_id = config["strain_id_field"],
        min_date = config["tip_frequencies"]["min_date"],
        max_date = config["tip_frequencies"]["max_date"],
        narrow_bandwidth =config["tip_frequencies"]["narrow_bandwidth"],
        wide_bandwidth = config["tip_frequencies"]["wide_bandwidth"],
    log:
        "logs/{virus}/tip_frequencies.txt",
    benchmark:
        "benchmarks/{virus}/tip_frequencies.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur frequencies \
            --method kde \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --min-date {params.min_date} \
            --max-date {params.max_date} \
            --narrow-bandwidth {params.narrow_bandwidth} \
            --wide-bandwidth {params.wide_bandwidth} \
            --output {output.tip_freq}
        """
