-- How AWS compute usage was priced: on-demand (Standard), covered by a
-- commitment (Committed) or Spot (Dynamic). ListCost is the public price.
SELECT PricingCategory AS pricing,
       round(sum(ListCost), 2) AS list_usd,
       round(sum(BilledCost), 2) AS billed_usd,
       round(100 * sum(ListCost) / sum(sum(ListCost)) OVER (), 1) AS share_pct
FROM focus
WHERE ProviderName = 'AWS'
  AND lower(ChargeCategory) = 'usage'
  AND ServiceCategory = 'Compute'
GROUP BY ALL
ORDER BY list_usd DESC;
