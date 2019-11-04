CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate".fncgetDeltaValue
(dealNumber IN varchar,frmDate IN DATE)
    RETURN NUMBER
  AS
    numAmount NUMBER(15,2) := 0;
  BEGIN
    SELECT OPTV_DELTA_USD
    INTO numAmount
    FROM TRTRAN074A
    WHERE OPTV_EXTERNAL_ID = dealNumber
    AND OPTV_ENTRY_DATE    = frmDate;
  RETURN numAmount;
Exception
	when others then
    numAmount := 0;                   
    return numAmount;    
END fncgetDeltaValue;
/