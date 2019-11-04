CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate".fncgetBLRate
(Asondate IN DATE,CurrencyCode in number)
    RETURN NUMBER
  AS
    numRate NUMBER(15,6) := 0;
  BEGIN    
    SELECT lrat_rbi_usd INTO numRate
    FROM TRSYSTEM017
    WHERE lrat_effective_date =
      (SELECT MAX(lrat_effective_date)
      FROM TRSYSTEM017 A
      WHERE A.lrat_record_status NOT IN(10200005,10200006)
      AND lrat_effective_date        <= Asondate
      AND A.lrat_currency_code        = lrat_currency_code)
      AND LRAT_SERIAL_NUMBER =
      (SELECT MAX(LRAT_SERIAL_NUMBER)
      FROM TRSYSTEM017 B
      WHERE B.lrat_record_status NOT IN(10200005,10200006)
      AND B.lrat_effective_date        <= Asondate
      AND B.lrat_currency_code        = lrat_currency_code)  
    AND lrat_record_status NOT IN(10200005,10200006)
    AND lrat_currency_code      = CurrencyCode;
    
  RETURN numRate;
Exception
	when others then
    numRate := 0;                   
    return numRate;    
END fncgetBLRate;    
/