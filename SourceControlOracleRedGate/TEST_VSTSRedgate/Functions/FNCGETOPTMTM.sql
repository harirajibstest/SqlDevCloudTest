CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate".fncgetOPTMTM
(dealNumber IN varchar,frmDate IN DATE,currency in number)
    RETURN NUMBER
  AS
    numPandL NUMBER(15,2) := 0;
    numSpot NUMBER(15,4) := 0;
    numStrike NUMBER(15,4) := 0;
    numBase NUMBER(15,2) := 0;
  BEGIN
    SELECT COSU_STRIKE_RATE,COPT_BASE_AMOUNT
    INTO numStrike,numBase
    FROM TRTRAN071,TRTRAN072
    WHERE COPT_DEAL_NUMBER      = dealNumber
    AND COPT_DEAL_NUMBER        = COSU_DEAL_NUMBER
    AND COPT_RECORD_STATUS NOT IN(10200005,10200006)
    AND COSU_RECORD_STATUS NOT IN(10200005,10200006);
    numSpot := Pkgforexprocess.Fncgetrate(currency,30400003,frmDate,0,0,null);
    numPandL := (numStrike-numSpot)*numBase;
  RETURN numPandL;
Exception
	when others then
    numPandL := 0;                   
    return numPandL;    
END fncgetOPTMTM;
/