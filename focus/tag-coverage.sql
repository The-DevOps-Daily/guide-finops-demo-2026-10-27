-- Share of usage cost with a usable environment tag: first with the one
-- key the schema asks for, then with the env column from usage-view.sql.
SELECT ProviderName AS provider,
       round(sum(BilledCost), 2) AS usage_usd,
       round(100 * coalesce(sum(BilledCost) FILTER (
         WHERE json_extract_string(Tags, '$.environment') IS NOT NULL), 0) / sum(BilledCost), 1) AS schema_key_pct,
       round(100 * coalesce(sum(BilledCost) FILTER (WHERE env IS NOT NULL), 0) / sum(BilledCost), 1) AS cleaned_pct
FROM usage
GROUP BY ALL
ORDER BY usage_usd DESC;
