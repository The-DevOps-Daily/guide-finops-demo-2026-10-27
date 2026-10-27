-- Showback by environment. Usage without a usable environment tag is
-- shared out in proportion to each environment's tagged cost, so the
-- report still adds up to the bill.
WITH direct AS (
  SELECT coalesce(env, 'untagged') AS environment,
         sum(BilledCost) AS cost
  FROM usage
  GROUP BY ALL
),
untagged AS (
  SELECT coalesce(sum(cost), 0) AS cost FROM direct WHERE environment = 'untagged'
)
SELECT d.environment,
       round(d.cost, 2) AS direct_usd,
       round(u.cost * d.cost / sum(d.cost) OVER (), 2) AS shared_usd,
       round(d.cost + u.cost * d.cost / sum(d.cost) OVER (), 2) AS showback_usd
FROM direct d, untagged u
WHERE d.environment <> 'untagged'
ORDER BY showback_usd DESC;
