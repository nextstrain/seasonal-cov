#!/usr/bin/env python3
"""
Finds samples where the "country" is listed as "country: city",
which is a common formatting issue that is not caught by previous steps of the curate pipeline.
"""
import argparse
import json
from sys import stderr, stdin, stdout


def tidy_countries(record: dict) -> dict:
    country_field = "country"
    # if there is a ':' in the country, take only what is before it
    # default value blank
    new_country = ''
    new_country = record[country_field].split(':')[0]

    record[country_field] = new_country

    return record


if __name__ == '__main__':
    # parser = argparse.ArgumentParser(
    #     description=__doc__,
    #     formatter_class=argparse.ArgumentDefaultsHelpFormatter
    # )
    # parser.add_argument("--country-field", default="country",
    #     help="The field the country where sequence was sampled.")
    #
    # args = parser.parse_args()

    for record in stdin:
        record = json.loads(record)

        tidy_countries(record)

        json.dump(record, stdout, allow_nan=False, indent=None, separators=',:')
        print()
