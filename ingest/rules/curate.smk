"""
This part of the workflow handles the curation of metadata for sequences
from NCBI and outputs the clean data as two separate files:

    - results/subset_metadata.tsv
    - results/sequences.fasta
"""


def format_field_map(field_map: dict[str, str]) -> str:
    """
    Format entries to the format expected by `augur curate --field-map`.

    When used in a Snakemake shell block, the list is automatically expanded and
    spaces are handled by quoted interpolation.
    """
    return [f'{key}={value}' for key, value in field_map.items()]


# This curate pipeline is based on existing pipelines for pathogen repos using NCBI data.
# You may want to add and/or remove steps from the pipeline for custom metadata
# curation for your pathogen. Note that the curate pipeline is streaming NDJSON
# records between scripts, so any custom scripts added to the pipeline should expect
# the input as NDJSON records from stdin and output NDJSON records to stdout.
# The final step of the pipeline should convert the NDJSON records to two
# separate files: a metadata TSV and a sequences FASTA.
rule curate:
    input:
        sequences_ndjson="data/{virus}/ncbi.ndjson",
        local_geolocation_rules=config["curate"]["local_geolocation_rules"],
        annotations="defaults/{virus}/annotations.tsv",
    output:
        metadata="results/{virus}/all_metadata.tsv",
        sequences="results/{virus}/sequences.fasta",
    log:
        "logs/{virus}/curate.txt",
    benchmark:
        "benchmarks/{virus}/curate.txt"
    params:
        field_map=format_field_map(config["curate"]["field_map"]),
        date_fields=config["curate"]["date_fields"],
        expected_date_formats=config["curate"]["expected_date_formats"],
        genbank_location_field=config["curate"]["genbank_location_field"],
        articles=config["curate"]["titlecase"]["articles"],
        abbreviations=config["curate"]["titlecase"]["abbreviations"],
        titlecase_fields=config["curate"]["titlecase"]["fields"],
        authors_field=config["curate"]["authors_field"],
        authors_default_value=config["curate"]["authors_default_value"],
        abbr_authors_field=config["curate"]["abbr_authors_field"],
        annotations_id=config["curate"]["annotations_id"],
        id_field=config["curate"]["output_id_field"],
        sequence_field=config["curate"]["output_sequence_field"],
    shell:
        # note: params.field_map intentionally not quoted
        r"""
        exec &> >(tee {log:q})

        cat {input.sequences_ndjson:q} \
          | augur curate rename \
              --field-map {params.field_map:q} \
          | augur curate normalize-strings \
          | augur curate format-dates \
              --date-fields {params.date_fields:q} \
              --expected-date-formats {params.expected_date_formats:q} \
          | augur curate parse-genbank-location \
              --location-field {params.genbank_location_field:q} \
          | augur curate titlecase \
              --titlecase-fields {params.titlecase_fields:q} \
              --articles {params.articles:q} \
              --abbreviations {params.abbreviations:q} \
          | augur curate abbreviate-authors \
              --authors-field {params.authors_field:q} \
              --default-value {params.authors_default_value:q} \
              --abbr-authors-field {params.abbr_authors_field:q} \
          | augur curate apply-geolocation-rules \
              --geolocation-rules {input.local_geolocation_rules:q} \
          | augur curate apply-record-annotations \
              --annotations {input.annotations:q} \
              --id-field {params.annotations_id:q} \
              --output-metadata {output.metadata:q} \
              --output-fasta {output.sequences:q} \
              --output-id-field {params.id_field:q} \
              --output-seq-field {params.sequence_field}
        """


rule subset_metadata:
    input:
        metadata="results/{virus}/all_metadata.tsv",
    output:
        subset_metadata="results/{virus}/subset_metadata.tsv",
    params:
        metadata_fields=",".join(config["curate"]["metadata_columns"]),
    log:
        "logs/{virus}/subset_metadata.txt",
    benchmark:
        "benchmarks/{virus}/subset_metadata.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        csvtk cut -t \
            -f {params.metadata_fields:q} \
            {input.metadata:q} \
        > {output.subset_metadata:q}
        """
