-- The five largest usage charges by provider, service and service category.
SELECT ProviderName AS provider,
       ServiceName AS service,
       ServiceCategory AS category,
       round(sum(BilledCost), 2) AS billed_usd
FROM focus
WHERE lower(ChargeCategory) = 'usage'
GROUP BY ALL
ORDER BY billed_usd DESC
LIMIT 5;
