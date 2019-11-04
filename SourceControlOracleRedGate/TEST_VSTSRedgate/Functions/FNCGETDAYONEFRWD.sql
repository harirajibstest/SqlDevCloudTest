CREATE OR REPLACE function "TEST_VSTSRedgate".fncGetDayoneFrwd(refno IN varchar2,asonDate IN date,CurrencyCode IN number)
return number
as
numRbiRefRate number(15,6):=0;
numBuyCall    number(15,6):=0;
numSellPut    number(15,6):=0;
numPremium    number(15,2):=0;
numOutstanding number(15,2):=0;
numBuyDiff     number(15,6):=0;
numSellDiff   number(15,6):=0;
numFrwd Number(15,2):=0;
begin
  numRbiRefRate := fncGetRBIRefRate(TO_DATE(asonDate),CurrencyCode);
  
    SELECT fncGetOptionRate(POSN_REFERENCE_NUMBER,32400001,25300001),
        fncGetOptionRate(POSN_REFERENCE_NUMBER,32400002,25300002),
        ABS(POSN_TRANSACTION_AMOUNT),
        CASE WHEN NVL(COPT_PREMIUM_DOLLERAMOUNT,0) != 0 THEN
          ROUND(decode(COPT_PREMIUM_STATUS,33200001,ABS(COPT_PREMIUM_DOLLERAMOUNT),33200002,-1*ABS(COPT_PREMIUM_DOLLERAMOUNT)) * fncgetPandLRate(COPT_DEAL_NUMBER,1,AsonDate,2),2)
        ELSE      
          decode(COPT_PREMIUM_STATUS,33200001,ABS(COPT_PREMIUM_AMOUNT),33200002,-1*(ABS(COPT_PREMIUM_AMOUNT))) END 
      INTO numBuyCall,numSellPut,numOutstanding,numPremium
      from TRSYSTEM997,TRTRAN071,TRTRAN072
      WHERE POSN_REFERENCE_NUMBER = refno
      AND COPT_DEAL_NUMBER = POSN_REFERENCE_NUMBER 
      AND COPT_DEAL_NUMBER = COSU_DEAL_NUMBER
      AND COPT_CONTRACT_TYPE = 32800002
      AND POSN_TRANSACTION_AMOUNT != 0
      AND COSU_SERIAL_NUMBER = POSN_REFERENCE_SERIAL        
      AND COPT_RECORD_STATUS NOT IN(10200005,10200006)
      AND COSU_RECORD_STATUS NOT IN(10200005,10200006);    
    
  IF (numRbiRefRate - numBuyCall) < 0 THEN
    numBuyDiff := 0;
  ELSE
    numBuyDiff := (numRbiRefRate - numBuyCall);
  END IF;
  IF (numSellPut - numRbiRefRate) < 0 THEN
    numSellDiff := 0;
  ELSE
    numSellDiff := (numSellPut - numRbiRefRate);    
  END IF;
  
  numFrwd := (numBuyCall + (numBuyDiff - numSellDiff)-numRbiRefRate-(numPremium/numOutstanding))*numOutstanding;
  
  RETURN numFrwd;
Exception
    When no_data_found then
      numFrwd := 0;
      RETURN numFrwd;
END fncGetDayoneFrwd;
/