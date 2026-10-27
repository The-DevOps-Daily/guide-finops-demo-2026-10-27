-- Every tag key that means "environment", with its values and the usage
-- cost behind each. The quotes make stray spaces in a key visible.
SELECT ProviderName AS provider,
       '"' || tag_key || '"' AS tag_key,
       json_extract_string(Tags, '$."' || tag_key || '"') AS tag_value,
       round(sum(BilledCost), 2) AS usage_usd
FROM (
  SELECT ProviderName, Tags, BilledCost, unnest(json_keys(Tags)) AS tag_key
  FROM focus
  WHERE lower(ChargeCategory) = 'usage'
)
WHERE lower(trim(tag_key)) IN ('env', 'environment')
GROUP BY ALL
ORDER BY provider, tag_key, tag_value;
