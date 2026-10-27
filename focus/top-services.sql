-- The five services with the highest usage charges, across every provider.
SELECT ProviderName AS provider,
       ServiceName AS service,
       ServiceCategory AS category,
       round(sum(BilledCost), 2) AS billed_usd
FROM focus
WHERE ChargeCategory = 'Usage'
GROUP BY ALL
ORDER BY billed_usd DESC
LIMIT 5;
