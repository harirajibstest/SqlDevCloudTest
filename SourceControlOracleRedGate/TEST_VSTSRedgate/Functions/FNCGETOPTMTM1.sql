CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate".fncgetOPTMTM1
(frmDate IN DATE,currency in number,companycode in number,businessunit in number)
    RETURN NUMBER
  AS
    numPandL NUMBER(15,2) := 0;
  BEGIN
    SELECT sum(OPTV_PL_CCY2) into numPandL
      FROM TRTRAN074A
    WHERE to_date(OPTV_ENTRY_DATE)  = to_date(frmDate)
    AND OPTV_COMPANY_CODE = companycode
    AND OPTV_BUSINESS_UNIT = businessunit;
  RETURN numPandL;
Exception
	when others then
    numPandL := 0;                   
    return numPandL;    
END fncgetOPTMTM1;
/