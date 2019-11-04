CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCGETFINANCIALYEAR" (
    frmDate    IN DATE,
    CancelDate IN DATE,
    Srno       IN NUMBER)
  RETURN VARCHAR
AS
  FYear    VARCHAR2(20 byte);
  tempDate DATE;
  dattemp1 DATE;
BEGIN
  IF Srno                        = 1 THEN
    IF (TO_CHAR(CancelDate,'MM') < 4) THEN
      tempDate                  := '01-apr-' || TO_CHAR(to_number(TO_CHAR(CancelDate,'YYYY'))-1);
      dattemp1                  := '31-MAR-' ||TO_CHAR(frmDate,'YYYY');
      --temp                   := 'FY'|| TO_CHAR(to_number(TO_CHAR(frmDate,'YY'))-1) || '-' || TO_CHAR(frmDate,'YY');
      FYear := 'FY'|| TO_CHAR(to_number(TO_CHAR(CancelDate,'YY'))-1) || '-' || TO_CHAR(CancelDate,'YY');
    ELSE
      tempDate:= '01-apr-' || TO_CHAR(frmDate,'YYYY');
      dattemp1:= '31-MAR-' || TO_CHAR(to_number(TO_CHAR(frmDate,'YYYY')) +1);
      --temp    := 'FY'|| TO_CHAR(frmDate,'YY') || '-' || TO_CHAR(to_number(TO_CHAR(frmDate,'YY'))+1);
      FYear := 'FY'|| TO_CHAR(CancelDate,'YY') || '-' || TO_CHAR(to_number(TO_CHAR(CancelDate,'YY'))+1);
    END IF;
  ELSE
    IF (TO_CHAR(CancelDate,'MM') < 4) THEN
      tempDate                  := '01-apr-' || TO_CHAR(to_number(TO_CHAR(CancelDate,'YYYY'))-1);
      dattemp1                  := '31-MAR-' ||TO_CHAR(frmDate,'YYYY');
      --temp                   := 'FY'|| TO_CHAR(to_number(TO_CHAR(frmDate,'YY'))-1) || '-' || TO_CHAR(frmDate,'YY');
      FYear := TO_CHAR(to_number(TO_CHAR(CancelDate,'YY'))-1)|| '-' || TO_CHAR(CancelDate,'YY');
    ELSE
      tempDate:= '01-apr-' || TO_CHAR(frmDate,'YYYY');
      dattemp1:= '31-MAR-' || TO_CHAR(to_number(TO_CHAR(frmDate,'YYYY')) +1);
      --temp    := 'FY'|| TO_CHAR(frmDate,'YY') || '-' || TO_CHAR(to_number(TO_CHAR(frmDate,'YY'))+1);
      FYear := TO_CHAR(CancelDate,'YY') || '-'|| TO_CHAR(to_number(TO_CHAR(CancelDate,'YY'))+1);
    END IF;
  END IF;  
    RETURN FYear;
  END fncGetFinancialYear;
 
 
 
 
 
 
 
 
 
/