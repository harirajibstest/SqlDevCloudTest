CREATE OR REPLACE function "TEST_VSTSRedgate".fncGetRBIRefRate(frmDate Date,currencyCode in number)
return number
as
numRate Number(15,6);
begin

  SELECT nvl(lrat_rbi_usd,0) into numRate
  FROM TRSYSTEM017
  WHERE lrat_effective_date = frmDate
--    (SELECT MAX(lrat_effective_date)
--    FROM TRSYSTEM017 A
--    WHERE A.lrat_record_status NOT IN(10200005,10200006)
--    AND lrat_effective_date        <= frmDate
--    AND A.lrat_currency_code        = lrat_currency_code)
  AND lrat_record_status NOT IN(10200005,10200006)
  AND lrat_currency_code      = currencyCode;  
  RETURN numRate;
Exception
    When no_data_found then
      numRate := 1;
      RETURN numRate;
END fncGetRBIRefRate;
/