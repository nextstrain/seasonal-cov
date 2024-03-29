"""
This part of the workflow handles the curation of metadata for sequences
from NCBI and outputs the clean data as two separate files:

    - results/subset_metadata.tsv
    - results/sequences.fasta
"""


# The following two rules can be ignored if you choose not to use the
# generalized geolocation rules that are shared across pathogens.
# The Nextstrain team will try to maintain a generalized set of geolocation
# rules that can then be overridden by local geolocation rules per pathogen repo.
rule fetch_general_geolocation_rules:
    output:
        general_geolocation_rules="data/{virus}/general-geolocation-rules.tsv",
    params:
        geolocation_rules_url=config["curate"]["geolocation_rules_url"],
    shell:
        """
        curl {params.geolocation_rules_url} > {output.general_geolocation_rules}
        """


rule concat_geolocation_rules:
    input:
        general_geolocation_rules="data/{virus}/general-geolocation-rules.tsv",
        local_geolocation_rules=config["curate"]["local_geolocation_rules"],
    output:
        all_geolocation_rules="data/{virus}/all-geolocation-rules.tsv",
    shell:
        """
        cat {input.general_geolocation_rules} {input.local_geolocation_rules} >> {output.all_geolocation_rules}
        """


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
        # Change the geolocation_rules input path if you are removing the above two rules
        all_geolocation_rules="data/{virus}/all-geolocation-rules.tsv",
        annotations= lambda wildcards:config[wildcards.virus]["annotations"],
    output:
        metadata="results/{virus}/all_metadata.tsv",
        sequences="results/{virus}/sequences.fasta",
    log:
        "logs/{virus}/curate.txt",
    benchmark:
        "benchmarks/{virus}/curate.txt"
    params:
        field_map=config["curate"]["field_map"],
        date_fields=config["curate"]["date_fields"],
        expected_date_formats=config["curate"]["expected_date_formats"],
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
        """
        (cat {input.sequences_ndjson} \
            | ./vendored/transform-field-names \
                --field-map {params.field_map} \
            | augur curate normalize-strings \
            | augur curate format-dates \
                --date-fields {params.date_fields} \
                --expected-date-formats {params.expected_date_formats} \
            | ./vendored/transform-genbank-location \
            | augur curate titlecase \
                --titlecase-fields {params.titlecase_fields} \
                --articles {params.articles} \
                --abbreviations {params.abbreviations} \
            | ./vendored/transform-authors \
                --authors-field {params.authors_field} \
                --default-value {params.authors_default_value} \
                --abbr-authors-field {params.abbr_authors_field} \
            | ./scripts/tidy_countries.py \
            | ./vendored/apply-geolocation-rules \
                --geolocation-rules {input.all_geolocation_rules} \
            | ./vendored/merge-user-metadata \
                --annotations {input.annotations} \
                --id-field {params.annotations_id} \
            | augur curate passthru \
                --output-metadata {output.metadata} \
                --output-fasta {output.sequences} \
                --output-id-field {params.id_field} \
                --output-seq-field {params.sequence_field} ) 2>> {log}
        """


rule subset_metadata:
    input:
        metadata="results/{virus}/all_metadata.tsv",
    output:
        subset_metadata="results/{virus}/subset_metadata.tsv",
    params:
        metadata_fields=",".join(config["curate"]["metadata_columns"]),
    shell:
        """
        tsv-select -H -f {params.metadata_fields} \
            {input.metadata} > {output.subset_metadata}
        """
