-- Usage charges with one environment column for every provider. The
-- category is compared in lower case (Google Cloud writes "usage"), the
-- key spellings found in the data are accepted, and the values are
-- mapped onto a fixed list.
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
WHERE lower(ChargeCategory) = 'usage';
