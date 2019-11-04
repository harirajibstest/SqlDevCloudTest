CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate".fncGetOptionRate
(Dealnumber IN varchar2,Optiontype number,BuySell in number)
    RETURN NUMBER
  AS
    numRate NUMBER(15,6) := 0;
  BEGIN
    SELECT NVL(COSU_STRIKE_RATE,0) INTO numRate FROM TRTRAN072
      WHERE COSU_DEAL_NUMBER = Dealnumber 
      AND COSU_RECORD_STATUS NOT IN(10200005,10200006)
      AND cosu_option_type = Optiontype
      AND COSU_BUY_SELL = BuySell;
    RETURN numRate;
Exception
	when others then
    numRate := 0;                   
    return numRate;    
END fncGetOptionRate;
/