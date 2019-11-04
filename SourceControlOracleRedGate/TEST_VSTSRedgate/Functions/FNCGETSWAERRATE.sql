CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate".fncgetSwaerRate
(currency IN number,frmDate IN DATE)
    RETURN NUMBER
  AS
    ExpiryDate date;
    panlSpotRate number(15,6) := 0;
    numRate NUMBER(15,6) := 0;
    
  BEGIN
    SELECT LRAT_SWAER_RATE
    INTO numRate
    FROM TRSYSTEM017
    WHERE LRAT_CURRENCY_CODE = currency
    AND LRAT_EFFECTIVE_DATE  =
      (SELECT MAX(LRAT_EFFECTIVE_DATE)
      FROM TRSYSTEM017 A
      WHERE A.LRAT_CURRENCY_CODE = LRAT_CURRENCY_CODE
      AND A.LRAT_EFFECTIVE_DATE <= frmDate);
    RETURN numRate;
Exception
	when others then
    numRate := 0;                   
    return numRate;    
END fncgetSwaerRate;
/