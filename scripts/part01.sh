# Part 1: a first look at billing data in the FOCUS format.
cap p01-download "curl -fsSLO $FOCUS_URL"
cap p01-sha256 "echo '$FOCUS_SHA256  focus_sample_100000.csv.gz' | sha256sum -c"
cap p01-duckdb-version 'duckdb --version'
cap p01-load 'duckdb focus.duckdb -f focus/load.sql'
