CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate".fncgetIRSMTMValue
(dealNumber IN varchar,frmDate IN DATE)
    RETURN NUMBER
  AS
    MTMAmount NUMBER(15,2) := 0;
  BEGIN
    SELECT IIRM_MTM_AMOUNT INTO MTMAmount FROM TRTRAN091F 
      WHERE IIRM_MTM_DATE = frmDate
      AND IIRM_RECORD_STATUS NOT IN(10200005,10200006);
  RETURN MTMAmount;
Exception
	when others then
    MTMAmount := 0;                   
    return MTMAmount;    
END fncgetIRSMTMValue;
/