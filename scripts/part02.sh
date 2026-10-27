# Part 2: inconsistent tags in the sample.
state_focus
cap p02-tag-keys 'duckdb focus.duckdb -f focus/tag-keys.sql'
cap p02-usage-view 'duckdb focus.duckdb -f focus/usage-view.sql'
cap p02-tag-coverage 'duckdb focus.duckdb -f focus/tag-coverage.sql'
