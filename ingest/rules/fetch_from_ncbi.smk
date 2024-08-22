"""
This part of the workflow handles fetching sequences and metadata from NCBI
and outputs them as a single NDJSON file that can be directly fed into the
curation pipeline.
"""


rule fetch_ncbi_dataset_package:
    params:
        ncbi_taxon_id=lambda wildcards: config[wildcards.virus]["ncbi_taxon_id"],
    output:
        dataset_package=temp("data/{virus}/ncbi_dataset.zip"),
    # Allow retries in case of network errors
    retries: 5
    log:
        "logs/{virus}/fetch_ncbi_dataset_package.txt",
    benchmark:
        "benchmarks/{virus}/fetch_ncbi_dataset_package.txt"
    shell:
        r"""
        datasets download virus genome taxon {params.ncbi_taxon_id:q} \
            --no-progressbar \
            --filename {output.dataset_package:q} \
          2> {log:q}
        """


rule extract_ncbi_dataset_sequences:
    input:
        dataset_package="data/{virus}/ncbi_dataset.zip",
    output:
        ncbi_dataset_sequences=temp("data/{virus}/ncbi_dataset_sequences.fasta"),
    log:
        "logs/{virus}/extract_ncbi_dataset_sequences.txt",
    benchmark:
        "benchmarks/{virus}/extract_ncbi_dataset_sequences.txt"
    shell:
        r"""
        unzip -jp {input.dataset_package:q} \
            ncbi_dataset/data/genomic.fna \
          > {output.ncbi_dataset_sequences:q} \
         2> {log:q}
        """


def _get_ncbi_dataset_field_mnemonics(provided_fields: list) -> str:
    """
    Return list of NCBI Dataset report field mnemonics for fields that we want
    to parse out of the dataset report. The column names in the output TSV
    are different from the mnemonics.

    Additional *provided_fields* will be appended to the end of the list.

    See NCBI Dataset docs for full list of available fields and their column
    names in the output:
    https://www.ncbi.nlm.nih.gov/datasets/docs/v2/reference-docs/command-line/dataformat/tsv/dataformat_tsv_virus-genome/#fields
    """
    fields = [
        "accession",
        "sourcedb",
        "sra-accs",
        "isolate-lineage",
        "geo-region",
        "geo-location",
        "isolate-collection-date",
        "release-date",
        "update-date",
        "length",
        "host-name",
        "isolate-lineage-source",
        "biosample-acc",
        "submitter-names",
        "submitter-affiliation",
        "submitter-country",
    ]
    return ",".join(fields + provided_fields)


rule format_ncbi_dataset_report:
    input:
        dataset_package="data/{virus}/ncbi_dataset.zip",
    output:
        ncbi_dataset_tsv=temp("data/{virus}/ncbi_dataset_report.tsv"),
    params:
        fields_to_include=_get_ncbi_dataset_field_mnemonics(config["ncbi_dataset_fields"]),
    log:
        "logs/{virus}/format_ncbi_dataset_report.txt",
    benchmark:
        "benchmarks/{virus}/format_ncbi_dataset_report.txt"
    shell:
        r"""
        dataformat tsv virus-genome \
            --package {input.dataset_package:q} \
            --fields {params.fields_to_include:q} \
          > {output.ncbi_dataset_tsv:q} \
         2> {log:q}
        """


# Technically you can bypass this step and directly provide FASTA and TSV files
# as input files for the curate pipeline.
# We do the formatting here to have a uniform NDJSON file format for the raw
# data that we host on data.nextstrain.org
rule format_ncbi_datasets_ndjson:
    input:
        ncbi_dataset_sequences="data/{virus}/ncbi_dataset_sequences.fasta",
        ncbi_dataset_tsv="data/{virus}/ncbi_dataset_report.tsv",
    output:
        ndjson="data/{virus}/ncbi.ndjson",
    log:
        "logs/{virus}/format_ncbi_datasets_ndjson.txt",
    benchmark:
        "benchmarks/{virus}/format_ncbi_datasets_ndjson.txt"
    shell:
        r"""
        augur curate passthru \
            --metadata {input.ncbi_dataset_tsv:q} \
            --fasta {input.ncbi_dataset_sequences:q} \
            --seq-id-column Accession \
            --seq-field sequence \
            --unmatched-reporting warn \
            --duplicate-reporting warn \
          > {output.ndjson:q} \
         2> {log:q}
        """
