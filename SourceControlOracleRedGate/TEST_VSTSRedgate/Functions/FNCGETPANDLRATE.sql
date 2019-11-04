CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate".fncgetPandLRate
(dealnumber IN varchar,numSerial in number,Asondate IN DATE,numInstrument in number)
    RETURN NUMBER
  AS
    numRate NUMBER(15,6) := 0;
  BEGIN
  if numInstrument = 1 then ---Forward Cancel Deal
      SELECT 
        CASE WHEN deal_maturity_from <= Asondate AND cdel_pandl_spot != 0  THEN
          cdel_pandl_spot
        WHEN deal_maturity_from < Asondate AND cdel_pandl_spot = 0 THEN
          fncgetSwaerRate(DEAL_BASE_CURRENCY,Asondate)
        WHEN deal_maturity_from > Asondate THEN  
          fncgetSwaerRate(DEAL_BASE_CURRENCY,Asondate)
        WHEN cdel_pandl_spot = 0 THEN  
          fncgetSwaerRate(DEAL_BASE_CURRENCY,Asondate)
        END AS SwareRate
        into numRate
      FROM trtran006,trtran001
      WHERE DEAL_DEAL_NUMBER = dealnumber
      AND cdel_deal_number = deal_deal_number
      AND CDEL_REVERSE_SERIAL = numSerial
      AND deal_record_status not in(10200005,10200006)
      AND CDEL_RECORD_STATUS not in(10200005,10200006);
   elsif numInstrument IN(2) then ---Forward/Future/Option Outstanding Deal
      numRate := fncgetSwaerRate(30400004,Asondate);
   elsif numInstrument = 3 then --Option Cancel Deal
      SELECT CASE WHEN COPT_EXPIRY_DATE <= Asondate AND CORV_PANDL_SPOT != 0  THEN
            CORV_PANDL_SPOT
          WHEN COPT_EXPIRY_DATE < Asondate AND CORV_PANDL_SPOT = 0 THEN
            fncgetSwaerRate(COPT_BASE_CURRENCY,Asondate)
          WHEN COPT_EXPIRY_DATE > Asondate THEN  
            fncgetSwaerRate(COPT_BASE_CURRENCY,Asondate)
          WHEN CORV_PANDL_SPOT = 0 THEN  
            fncgetSwaerRate(COPT_BASE_CURRENCY,Asondate)
          END AS SwareRate
          into numRate FROM TRTRAN073,TRTRAN071 
      WHERE COPT_DEAL_NUMBER = dealnumber
      AND CORV_DEAL_NUMBER = COPT_DEAL_NUMBER
      AND CORV_REVERSE_SERIAL = numSerial
      AND COPT_RECORD_STATUS NOT IN(10200005,10200006)
      AND CORV_RECORD_STATUS NOT IN(10200005,10200006);   
   end if;
    
  RETURN numRate;
Exception
	when others then
    numRate := 0;                   
    return numRate;    
END fncgetPandLRate;
/