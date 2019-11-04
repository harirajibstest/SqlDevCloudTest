CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".effectiverate (companycode,refdate,currencycode,traders) AS
SELECT COMP_COMPANY_CODE,
    '01-01-1999',
    0,0
  FROM trmaster301
  WHERE COMP_COMPANY_CODE NOT IN(30100000)
  UNION
  SELECT 0,'01-01-1999',cncy_pick_code,0 FROM trmaster304
  UNION
  SELECT 0,
    '01-01-1999',
    0,
    PICK_KEY_VALUE
  FROM trmaster001
  WHERE pick_key_group    = 338
  AND PICK_KEY_VALUE NOT IN(33800000)
 
 
 
 
 
 
 ;