CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate".fncgetUploadPrimiumValue
(dealNumber IN varchar,frmDate IN DATE,numType number)
    RETURN NUMBER
  AS
    numPrimium NUMBER(15,2) := 0;
  BEGIN
  if numType = 1 then --USD
    SELECT OPTV_PL_CCY1
    INTO numPrimium
    FROM TRTRAN074A
    WHERE OPTV_EXTERNAL_ID = dealNumber
    AND OPTV_ENTRY_DATE    = frmDate;
  elsIF  numType = 2 then   --INR
    SELECT OPTV_PL_CCY2
    INTO numPrimium
    FROM TRTRAN074A
    WHERE OPTV_EXTERNAL_ID = dealNumber
    AND OPTV_ENTRY_DATE    = frmDate; 
  elsIF  numType = 3 then   --INR
    SELECT OPTV_VALUE_CCY2
    INTO numPrimium
    FROM TRTRAN074A
    WHERE OPTV_EXTERNAL_ID = dealNumber
    AND OPTV_ENTRY_DATE    = frmDate; 
  elsIF  numType = 4 then   --USD
    SELECT OPTV_VALUE_CCY1
    INTO numPrimium
    FROM TRTRAN074A
    WHERE OPTV_EXTERNAL_ID = dealNumber
    AND OPTV_ENTRY_DATE    = frmDate; 
--  elsIF  numType = 5 then   --INR
--    SELECT OPTV_PL_CCY2
--    INTO numPrimium
--    FROM TRTRAN074A
--    WHERE to_date(OPTV_ENTRY_DATE) = to_date(frmDate)
--    AND TO_CHAR(OPTV_EXPIRY_DATE,'YYYYMM') = matmonth;     
  end if;  
  RETURN numPrimium;
Exception
	when others then
    numPrimium := 0;                   
    return numPrimium;    
END fncgetUploadPrimiumValue;
/