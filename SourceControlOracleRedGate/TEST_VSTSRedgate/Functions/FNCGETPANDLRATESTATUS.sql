CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate".fncgetPandLRateStatus
(dealnumber IN varchar,numSerial in number,Asondate IN DATE,numInstrument in number)
    RETURN VARCHAR
  AS
    status varchar2(50 byte);
  BEGIN
  if numInstrument = 1 then ---Forward Cancel Deal
      SELECT 
        CASE WHEN deal_maturity_from <= Asondate AND cdel_pandl_spot != 0  THEN
          'Settlement Rate'
        WHEN deal_maturity_from < Asondate AND cdel_pandl_spot = 0 THEN
          'Sware Rate'
        WHEN deal_maturity_from > Asondate THEN  
          'Sware Rate'
        WHEN cdel_pandl_spot = 0 THEN  
          'Sware Rate'
        END AS RateStatus
        into status
      FROM trtran006,trtran001
      WHERE DEAL_DEAL_NUMBER = dealnumber
      AND cdel_deal_number = deal_deal_number
      AND CDEL_REVERSE_SERIAL = numSerial
      AND deal_record_status not in(10200005,10200006)
      AND CDEL_RECORD_STATUS not in(10200005,10200006);
   elsif numInstrument IN(2) then ---Forward/Future/Option Outstanding Deal
      status := 'Sware Rate';
   elsif numInstrument = 3 then --Option Cancel Deal
      SELECT CASE WHEN COPT_EXPIRY_DATE <= Asondate AND CORV_PANDL_SPOT != 0  THEN
            'Settlement Rate'
          WHEN COPT_EXPIRY_DATE < Asondate AND CORV_PANDL_SPOT = 0 THEN
            'Sware Rate'
          WHEN COPT_EXPIRY_DATE > Asondate THEN  
            'Sware Rate'
          WHEN CORV_PANDL_SPOT = 0 THEN  
            'Sware Rate'
          END AS SwareRate
          into status FROM TRTRAN073,TRTRAN071 
      WHERE COPT_DEAL_NUMBER = dealnumber
      AND CORV_DEAL_NUMBER = COPT_DEAL_NUMBER
      AND CORV_REVERSE_SERIAL = numSerial
      AND COPT_RECORD_STATUS NOT IN(10200005,10200006)
      AND CORV_RECORD_STATUS NOT IN(10200005,10200006);   
   end if;
    
  RETURN status;
Exception
	when others then
    status := '';                   
    return status;    
END fncgetPandLRateStatus;
/