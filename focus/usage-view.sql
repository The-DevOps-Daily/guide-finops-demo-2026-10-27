-- One environment column for every provider: accept the key spellings
-- found in the data, and map the values onto a fixed list.
CREATE OR REPLACE VIEW usage AS
SELECT *,
       CASE lower(trim(coalesce(
              json_extract_string(Tags, '$.environment'),
              json_extract_string(Tags, '$.Environment'),
              json_extract_string(Tags, '$.env'),
              json_extract_string(Tags, '$.ENV'))))
         WHEN 'prod' THEN 'prod'
         WHEN 'production' THEN 'prod'
         WHEN 'dev' THEN 'dev'
         WHEN 'development' THEN 'dev'
       END AS env
FROM focus
WHERE ChargeCategory = 'Usage';
