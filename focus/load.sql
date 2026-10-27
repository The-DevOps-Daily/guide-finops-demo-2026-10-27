-- Load the FOCUS sample into a table. sample_size = -1 makes DuckDB scan
-- every row before it picks the column types: SubAccountId holds numbers
-- for AWS and text for Oracle, so a partial scan guesses wrong.
CREATE OR REPLACE TABLE focus AS
SELECT *
FROM read_csv('focus_sample_100000.csv.gz', nullstr = 'NULL', sample_size = -1);

SELECT ProviderName AS provider,
       ChargeCategory AS charge,
       count(*) AS rows,
       round(sum(BilledCost), 2) AS billed_usd
FROM focus
GROUP BY ALL
ORDER BY provider, charge;
