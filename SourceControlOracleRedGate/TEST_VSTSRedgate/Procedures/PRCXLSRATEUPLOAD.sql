CREATE OR REPLACE PROCEDURE "TEST_VSTSRedgate"."PRCXLSRATEUPLOAD" 
as
  datTemp             date;
  numError            number;
  varOperation        GConst.gvarOperation%Type;
  varMessage          GConst.gvarMessage%Type;
  varError            GConst.gvarError%Type;
  datnavupto          date;
  numSerial            number;
begin
  datTemp := to_date(sysdate,'DD-MM-YY');
  begin
    select nvl(max(DRAT_SERIAL_NUMBER),0) into numSerial from trtran012 where drat_effective_date = to_date(sysdate,'DD-MM-YY');
  
      Exception
          When others then
        numSerial := 0;
  end;
  numSerial := numSerial + 1;
  INSERT INTO TRTRAN012
  (DRAT_CURRENCY_CODE,DRAT_FOR_CURRENCY,DRAT_EFFECTIVE_DATE,DRAT_SERIAL_NUMBER,DRAT_RATE_TIME,DRAT_TIME_STAMP,DRAT_RATE_DESCRIPTION,
  DRAT_SPOT_BID,DRAT_SPOT_ASK,DRAT_MONTH1_BID,DRAT_MONTH2_BID,DRAT_MONTH3_BID,DRAT_MONTH4_BID,DRAT_MONTH5_BID,DRAT_MONTH6_BID,
  DRAT_MONTH7_BID,DRAT_MONTH8_BID,DRAT_MONTH9_BID,DRAT_MONTH10_BID,DRAT_MONTH11_BID,DRAT_MONTH12_BID,DRAT_MONTH1_ASK,
  DRAT_MONTH2_ASK,DRAT_MONTH3_ASK,DRAT_MONTH4_ASK,DRAT_MONTH5_ASK,DRAT_MONTH6_ASK,DRAT_MONTH7_ASK,DRAT_MONTH8_ASK,DRAT_MONTH9_ASK,
  DRAT_MONTH10_ASK,DRAT_MONTH11_ASK,DRAT_MONTH12_ASK,DRAT_CREATE_DATE,DRAT_ADD_DATE,DRAT_ENTRY_DETAIL,DRAT_RECORD_STATUS)
  SELECT 
       CurrencyCode,ForCurrencyCode,to_date(sysdate,'DD-MM-YY'),numSerial,
       sysdate,sysdate,'Rates For :- ' || desceription ||' As on :- ' || sysdate,sum(Bid),Sum(Ask),
       SUM(NVL(Month1Bid,0))+ sum(Bid) Month1Bid,SUM(NVL(Month2Bid,0)) + sum(Bid) Month2Bid, 
       SUM(NVL(Month3Bid,0))+ sum(Bid)  Month3Bid,SUM(NVL(Month4Bid,0))+ sum(Bid) Month4Bid,
       SUM(NVL(Month5Bid,0))+ sum(Bid)  Month5Bid,SUM(NVL(Month6Bid,0))+ sum(Bid) Month6Bid, 
       SUM(NVL(Month7Bid,0))+ sum(Bid)  Month7Bid,SUM(NVL(Month8Bid,0))+ sum(Bid) Month8Bid,
       SUM(NVL(Month9Bid,0))+ sum(Bid)  Month9Bid,SUM(NVL(Month10Bid,0))+ sum(Bid) Month10Bid, 
       SUM(NVL(Month11Bid,0)) + sum(Bid) Month11Bid,SUM(NVL(Month12Bid,0))+ sum(Bid) Month12Bid,
       SUM(NVL(Month1Ask,0))+ sum(Ask)  Month1Ask,SUM(NVL(Month2Ask,0))+ sum(Ask) Month2Ask, 
       SUM(NVL(Month3Ask,0))+ sum(Ask)  Month3Ask,SUM(NVL(Month4Ask,0))+ sum(Ask) Month4Ask,
       SUM(NVL(Month5Ask,0))+ sum(Ask)  Month5Ask,SUM(NVL(Month6Ask,0))+ sum(Ask) Month6Ask, 
       SUM(NVL(Month7Ask,0))+ sum(Ask)  Month7Ask,SUM(NVL(Month8Ask,0))+ sum(Ask) Month8Ask,
       SUM(NVL(Month9Ask,0))+ sum(Ask)  Month9Ask,SUM(NVL(Month10Ask,0))+ sum(Ask) Month10Ask, 
       SUM(NVL(Month11Ask,0))+ sum(Ask)  Month11Ask,SUM(NVL(Month12Ask,0))+ sum(Ask) Month12Ask,
       sysdate,sysdate,null,10200001
       FROM(
              select 
              --substr(desceription,8,3),
              decode(substr(desceription,8,3),'01M',SUM(bid)/10000) Month1Bid,
              decode(substr(desceription,8,3),'02M',SUM(bid)/10000) Month2Bid,
              decode(substr(desceription,8,3),'03M',SUM(bid)/10000) Month3Bid,
              decode(substr(desceription,8,3),'04M',SUM(bid)/10000) Month4Bid,
              decode(substr(desceription,8,3),'05M',SUM(bid)/10000) Month5Bid,
              decode(substr(desceription,8,3),'06M',SUM(bid)/10000) Month6Bid,
              decode(substr(desceription,8,3),'07M',SUM(bid)/10000) Month7Bid,
              decode(substr(desceription,8,3),'08M',SUM(bid)/10000) Month8Bid,
              decode(substr(desceription,8,3),'09M',SUM(bid)/10000) Month9Bid,
              decode(substr(desceription,8,3),'10M',SUM(bid)/10000) Month10Bid,
              decode(substr(desceription,8,3),'11M',SUM(bid)/10000) Month11Bid,
              decode(substr(desceription,8,3),'12M',SUM(bid)/10000) Month12Bid,
              decode(substr(desceription,8,3),'01M',SUM(ask)/10000) Month1Ask,
              decode(substr(desceription,8,3),'02M',SUM(ask)/10000) Month2Ask,
              decode(substr(desceription,8,3),'03M',SUM(ask)/10000) Month3Ask,
              decode(substr(desceription,8,3),'04M',SUM(ask)/10000) Month4Ask,
              decode(substr(desceription,8,3),'05M',SUM(ask)/10000) Month5Ask,
              decode(substr(desceription,8,3),'06M',SUM(ask)/10000) Month6Ask,
              decode(substr(desceription,8,3),'07M',SUM(ask)/10000) Month7Ask,
              decode(substr(desceription,8,3),'08M',SUM(ask)/10000) Month8Ask,
              decode(substr(desceription,8,3),'09M',SUM(ask)/10000) Month9Ask,
              decode(substr(desceription,8,3),'10M',SUM(ask)/10000) Month10Ask,
              decode(substr(desceription,8,3),'11M',SUM(ask)/10000) Month11Ask,
              decode(substr(desceription,8,3),'12M',SUM(ask)/10000) Month12Ask,
              substr(desceription,1,6)desceription,
              case when length(desceription) <= 6 then SUM(ask) end Ask,
              case when length(desceription) <= 6 then SUM(bid) end Bid,
              case when length(desceription) <= 6 then SUM(LTP) end LTP,
              (select cncy_pick_code from trmaster304 where cncy_short_description = substr(desceription,1,3)) as CurrencyCode,
              (select cncy_pick_code from trmaster304 where cncy_short_description = substr(desceription,4,3)) as ForCurrencyCode
              --bid/10000,ask/10000 
              from TRSTAGING008 
              GROUP BY desceription,substr(desceription,8,3)) a
        group by desceription, CurrencyCode,ForCurrencyCode,numSerial;
    commit;
    Exception
          When others then
            numError := SQLCODE;
            varError := SQLERRM;
            varError := GConst.fncReturnError('prcXlsRateUpLoad', numError, varMessage,
                            varOperation, varError);
            raise_application_error(-20101, varError);

end prcXlsRateUpLoad;
/