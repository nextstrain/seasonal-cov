"""
This part of the workflow constructs the phylogenetic tree.

This part of the workflow expects a single aligned FASTA file.
If constructing a time-resolved tree, it will also require a metadata file
that includes a sample date for each sequence.

This will produce a Newick tree and a branch lengths JSON file.
"""

rule tree:
    input:
        alignment = "results/{virus}/aligned.fasta"
    output:
        tree = "results/{virus}/tree_raw.nwk"
    shell:
        """
        augur tree \
            --alignment {input.alignment} \
            --output {output.tree}
        """

rule refine:
    input:
        tree = "results/{virus}/tree_raw.nwk"
        alignment = "results/{virus}/aligned.fasta",
        metadata = lambda wildcards:config[wildcards.virus]["metadata"]
    output:
        tree = "results/{virus}/tree.nwk",
        node_data = "results/{virus}/branch_lengths.json"
    params:
        clock_rate = lambda wildcards:config[wildcards.virus]["construct_phylogeny"]["clock_rate"],
        clock_std_dev = lambda wildcards:config[wildcards.virus]["construct_phylogeny"]["clock_std_dev"],
        coalescent = lambda wildcards:config[wildcards.virus]["construct_phylogeny"]["coalescent"],
        date_inference = lambda wildcards:config[wildcards.virus]["construct_phylogeny"]["date_inference"],
        clock_filter_iqd= lambda wildcards:config[wildcards.virus]["construct_phylogeny"]["clock_filter_iqd"]
    shell:
        """
        if [ "{wildcards.virus}" == "229e" ] || [ "{wildcards.virus}" == "oc43" ]; then
            echo "Estimating clock rate for {wildcards.virus}"
            clock_rate=""
            clock_std_dev=""
        else
            echo "Setting clock rate at {params.clock_rate} with std dev {params.clock_std_dev} for {wildcards.virus}"
            clock_rate="--clock-rate {params.clock_rate}"
            clock_std_dev="--clock-std-dev {params.clock_std_dev}"
        fi

        augur refine \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --metadata {input.metadata} \
            --output-tree {output.tree} \
            --output-node-data {output.node_data} \
            --timetree \
            $clock_rate \
            $clock_std_dev \
            --coalescent {params.coalescent} \
            --date-confidence \
            --date-inference {params.date_inference} \
            --clock-filter-iqd {params.clock_filter_iqd}
        """
