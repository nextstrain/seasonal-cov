#!/usr/bin/env python3
"""
Finds samples where the "country" is listed as "country: city",
which is a common formatting issue that is not caught by previous
steps of the curate pipeline.
"""

import json
from sys import stdin, stdout

COUNTRY_FIELD = "country"
def tidy_countries(record: dict) -> dict:
    """
    Inspects the value of the country_field key in `record` and if
    a colon is detected, truncates to only the string preceeding the
    colon. Returns the record whether or not it is modified.
    """
    # default to the empty string
    new_country = record.get(COUNTRY_FIELD,"").split(':')[0]

    record[COUNTRY_FIELD] = new_country

    return record


if __name__ == '__main__':
    for record in stdin:
        record = json.loads(record)

        tidy_countries(record)

        json.dump(record, stdout, allow_nan=False, indent=None, separators=',:')
        print()
