"""
This part of the workflow constructs the phylogenetic tree. It
expects a single aligned FASTA file. If constructing a time-resolved
tree, it will also require a metadata file that includes a sample date
for each sequence.

This will produce a Newick tree and a branch lengths JSON file.
"""


rule tree:
    input:
        alignment="results/{virus}/aligned.fasta",
    output:
        tree="results/{virus}/tree_raw.nwk",
    log:
        "logs/{virus}/tree.txt",
    benchmark:
        "benchmarks/{virus}/tree.txt"
    shell:
        """
        augur tree \
            --alignment {input.alignment:q} \
            --output {output.tree:q} \
          2>{log:q}
        """


rule refine:
    input:
        tree="results/{virus}/tree_raw.nwk",
        alignment="results/{virus}/aligned.fasta",
        metadata="data/{virus}/metadata.tsv",
    output:
        tree="results/{virus}/tree.nwk",
        node_data="results/{virus}/branch_lengths.json",
    log:
        "logs/{virus}/refine.txt",
    benchmark:
        "benchmarks/{virus}/refine.txt"
    params:
        clock_rate=lambda wildcards: config[wildcards.virus]["construct_phylogeny"]["clock_rate"],
        clock_std_dev=lambda wildcards: config[wildcards.virus]["construct_phylogeny"]["clock_std_dev"],
        coalescent=lambda wildcards: config[wildcards.virus]["construct_phylogeny"]["coalescent"],
        date_inference=lambda wildcards: config[wildcards.virus]["construct_phylogeny"]["date_inference"],
        clock_filter_iqd=lambda wildcards: config[wildcards.virus]["construct_phylogeny"]["clock_filter_iqd"],
    shell:
        # TODO move this conditional logic up into the params lambda (?)
        """
        (
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
              --tree {input.tree:q} \
              --alignment {input.alignment:q} \
              --metadata {input.metadata:q} \
              --output-tree {output.tree:q} \
              --output-node-data {output.node_data:q} \
              --timetree \
              $clock_rate \
              $clock_std_dev \
              --coalescent {params.coalescent:q} \
              --date-confidence \
              --date-inference {params.date_inference:q} \
              --clock-filter-iqd {params.clock_filter_iqd:q}
        ) 2>{log:q}
        """
