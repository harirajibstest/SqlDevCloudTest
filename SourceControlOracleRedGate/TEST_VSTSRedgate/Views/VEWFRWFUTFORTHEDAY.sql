CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewfrwfutfortheday (userid,remark,dealtype,status,executedate,dealnumber,companycode,counterparty,basecurrency,buysell1,baseamount,amtinr,maturitydate,rate,bookingrate,backupdeal,systemdate,othercurrency,deal_record_status,deal_hedge_trade,deal_company_code,deal_counter_party,deal_base_currency,buysell,washrate,usercode,initcode,pandl,hedgetrade,statusorder,deal_init_code,deal_backup_deal) AS
SELECT UserId,
  Remark,
  DealType,
  status,
  deal_execute_date   AS ExecuteDate,
  deal_deal_number    AS DealNumber,
  deal_COMPANY_CODE1  AS CompanyCode,
  deal_COUNTER_PARTY1 AS CounterParty,
  deal_BASE_CURRENCY1 AS BaseCurrency,
  DEAL_BUY_SELL1      AS BuySell1,
  BaseAmount,
  AmtInr,
  deal_maturity_date AS MaturityDate,
  Rate,
  BookingRate,
  BacKupDeal,
  SystemDate,
  DEAL_OTHER_CURRENCY1 AS OtherCurrency,
  DEAL_RECORD_STATUS,
  DEAL_HEDGE_TRADE,
  DEAL_COMPANY_CODE,
  DEAL_COUNTER_PARTY,
  DEAL_BASE_CURRENCY,
  pkgreturncursor.fncgetdescription(DEAL_BUY_SELL,2)  AS BuySell,
  CDEL_LOCAL_RATE                                     AS WashRate,
  DEAL_INIT_CODE1                                     AS UserCode,
  pkgreturncursor.fncgetdescription(DEAL_INIT_CODE,2) AS initcode,
  PandL,
  Hedgetrade,
  Statusorder,
  Deal_Init_Code,
  DEAL_BACKUP_DEAL
FROM
  (SELECT 'Future ' dealType,
    'booked' status,
    1                                                        AS statusorder,
    CFUT_USER_ID                                             AS UserId,
    CFUT_DEALER_REMARK                                       AS Remark,
    cfut_execute_date                                        AS deal_execute_date,
    cfut_deal_number                                         AS deal_deal_number,
    pkgreturncursor.fncgetdescription(CFUT_COMPANY_CODE,2)   AS deal_COMPANY_CODE1,
    pkgreturncursor.fncgetdescription(CFUT_COUNTER_PARTY,2)  AS deal_COUNTER_PARTY1,
    pkgreturncursor.fncgetdescription(CFUT_BASE_CURRENCY,2)  AS deal_BASE_CURRENCY1,
    pkgreturncursor.fncgetdescription(CFUT_OTHER_CURRENCY,2) AS DEAL_OTHER_CURRENCY1,
    pkgreturncursor.fncgetdescription(CFUT_BUY_SELL,2)       AS DEAL_BUY_SELL1,
    CFUT_BASE_AMOUNT                                         AS BaseAmount,
    CFUT_BASE_AMOUNT*cfut_lot_price                          AS AmtInr,
    cfut_maturity_date                                       AS deal_maturity_date,
    CFUT_EXCHANGE_RATE                                       AS Rate,
    CFUT_EXCHANGE_RATE                                       AS BookingRate,
    CFUT_HEDGE_TRADE                                         AS DEAL_HEDGE_TRADE,
    pkgreturncursor.fncgetdescription(CFUT_BACKUP_DEAL,2) BacKupDeal,
    pkgreturnreport.GetSystemDate()                    AS SystemDate,
    cfut_RECORD_STATUS                                 AS DEAL_RECORD_STATUS,
    CFUT_COMPANY_CODE                                  AS DEAL_COMPANY_CODE,
    CFUT_COUNTER_PARTY                                 AS DEAL_COUNTER_PARTY,
    CFUT_BASE_CURRENCY                                 AS DEAL_BASE_CURRENCY,
    CFUT_BUY_SELL                                      AS DEAL_BUY_SELL,
    pkgreturncursor.fncgetdescription(CFUT_INIT_CODE,2)AS DEAL_INIT_CODE1,
    CFUT_INIT_CODE                                     AS DEAL_INIT_CODE,
    DECODE(cfut_hedge_trade, 26000001, 'Hedge Deal', 26000002,'Trade Deal',26000003,'FT Deal') HedgeTrade,
    CFUT_BACKUP_DEAL AS DEAL_BACKUP_DEAL,
    1                AS Cdel_Local_Rate,
    0                AS PandL
  FROM trtran061
  WHERE cfut_record_status NOT IN (10200005,10200006)
  UNION ALL
  SELECT 'Future ' dealType,
    'canceled' status,
    2                                                        AS statusorder,
    CFUT_USER_ID                                             AS UserId,
    CFUT_DEALER_REMARK                                       AS Remark,
    CFRV_EXECUTE_DATE                                        AS deal_execute_date,
    cfut_deal_number                                         AS deal_deal_number,
    pkgreturncursor.fncgetdescription(CFUT_COMPANY_CODE,2)   AS deal_COMPANY_CODE1,
    pkgreturncursor.fncgetdescription(CFUT_COUNTER_PARTY,2)  AS deal_COUNTER_PARTY1,
    pkgreturncursor.fncgetdescription(CFUT_BASE_CURRENCY,2)  AS deal_BASE_CURRENCY1,
    pkgreturncursor.fncgetdescription(CFUT_OTHER_CURRENCY,2) AS DEAL_OTHER_CURRENCY1,
    DECODE (CFUT_BUY_SELL,25300001,'Sell','Buy')             AS DEAL_BUY_SELL1,
    (CFRV_REVERSE_LOT*1000)                                  AS BaseAmount,
    (CFUT_BASE_AMOUNT*1000)*CFRV_LOT_PRICE                   AS AmtInr,
    cfut_maturity_date                                       AS deal_maturity_date,
    CFRV_LOT_PRICE                                           AS Rate,
    CFUT_EXCHANGE_RATE                                       AS BookingRate,
    CFUT_HEDGE_TRADE                                         AS DEAL_HEDGE_TRADE,
    pkgreturncursor.fncgetdescription(CFUT_BACKUP_DEAL,2) BacKupDeal,
    pkgreturnreport.GetSystemDate()                    AS SystemDate,
    cfut_RECORD_STATUS                                 AS DEAL_RECORD_STATUS,
    CFUT_COMPANY_CODE                                  AS DEAL_COMPANY_CODE,
    CFUT_COUNTER_PARTY                                 AS DEAL_COUNTER_PARTY,
    CFUT_BASE_CURRENCY                                 AS DEAL_BASE_CURRENCY,
    CFUT_BUY_SELL                                      AS DEAL_BUY_SELL, --0 as CDEL_LOCAL_RATE,
    pkgreturncursor.fncgetdescription(CFUT_INIT_CODE,2)AS DEAL_INIT_CODE1,
    CFUT_INIT_CODE                                     AS DEAL_INIT_CODE,
    DECODE(cfut_hedge_trade, 26000001, 'Hedge Deal', 26000002,'Trade Deal',26000003,'FT Deal') HedgeTrade,
    CFUT_BACKUP_DEAL AS DEAL_BACKUP_DEAL,
    1 CDEL_LOCAL_RATE,
    cfrv_profit_loss PandL
   FROM trtran061,
    trtran063
  WHERE cfut_deal_number      =CFRV_DEAL_NUMBER
  AND cfrv_RECORD_STATUS NOT IN (10200005,10200006)
  AND cfut_record_status NOT IN (10200005,10200006)
  UNION ALL
  SELECT 'Forward ' dealType,
    'booked' status,
    1                                                        AS statusorder,
    DEAL_USER_ID                                             AS UserId,
    DEAL_DEALER_REMARKS                                      AS Remark,
    DEAL_EXECUTE_DATE                                        AS DEAL_EXECUTE_DATE,
    DEAL_DEAL_NUMBER                                         AS DEAL_DEAL_NUMBER,
    pkgreturncursor.fncgetdescription(DEAL_COMPANY_CODE,2)   AS DEAL_COMPANY_CODE1,
    pkgreturncursor.fncgetdescription(DEAL_COUNTER_PARTY,2)  AS DEAL_COUNTER_PARTY1,
    pkgreturncursor.fncgetdescription(DEAL_BASE_CURRENCY,2)  AS DEAL_BASE_CURRENCY1,
    pkgreturncursor.fncgetdescription(DEAL_OTHER_CURRENCY,2) AS DEAL_OTHER_CURRENCY1,
    pkgreturncursor.fncgetdescription(DEAL_BUY_SELL,2)       AS DEAL_BUY_SELL1,
    DEAL_BASE_AMOUNT                                         AS BaseAmount,
    DEAL_BASE_AMOUNT*DEAL_EXCHANGE_RATE                      AS AmtInr,
    DEAL_MATURITY_DATE                                       AS DEAL_MATURITY_DATE,
    DEAL_EXCHANGE_RATE                                       AS Rate,
    DEAL_EXCHANGE_RATE                                       AS BookingRate,
    DEAL_HEDGE_TRADE                                         AS DEAL_HEDGE_TRADE,
    pkgreturncursor.fncgetdescription(DEAL_BACKUP_DEAL,2) BacKupDeal,
    pkgreturnreport.GetSystemDate()                    AS SystemDate,
    DEAL_RECORD_STATUS                                 AS DEAL_RECORD_STATUS,
    DEAL_COMPANY_CODE                                  AS DEAL_COMPANY_CODE,
    DEAL_COUNTER_PARTY                                 AS DEAL_COUNTER_PARTY,
    DEAL_BASE_CURRENCY                                 AS DEAL_BASE_CURRENCY,
    DEAL_BUY_SELL                                      AS DEAL_BUY_SELL ,
    pkgreturncursor.fncgetdescription(DEAL_INIT_CODE,2)AS DEAL_INIT_CODE1,
    DEAL_INIT_CODE                                     AS DEAL_INIT_CODE,
    DECODE(deal_hedge_trade, 26000001, 'Hedge Deal', 26000002,'Trade Deal',26000003,'FT Deal') HedgeTrade,
    DEAL_BACKUP_DEAL AS DEAL_BACKUP_DEAL,
    1                AS CDEL_LOCAL_RATE,
    0 PandL
  FROM trtran001
  WHERE deal_record_status NOT IN (10200005,10200006)
  UNION ALL
  SELECT 'Forward' dealType,
    CASE CDEL_CANCEL_TYPE
      WHEN 27000001
      THEN'Cancelled'
      WHEN 27000002
      THEN 'Delivery'
    END                                                      AS status,
    2                                                        AS statusorder,
    DEAL_USER_ID                                             AS UserId,
    DEAL_DEALER_REMARKS                                      AS Remark,
    CDEL_CANCEL_DATE                                         AS DEAL_EXECUTE_DATE,
    DEAL_DEAL_NUMBER                                         AS DEAL_DEAL_NUMBER,
    pkgreturncursor.fncgetdescription(DEAL_COMPANY_CODE,2)   AS DEAL_COMPANY_CODE1,
    pkgreturncursor.fncgetdescription(DEAL_COUNTER_PARTY,2)  AS DEAL_COUNTER_PARTY1,
    pkgreturncursor.fncgetdescription(DEAL_BASE_CURRENCY,2)  AS DEAL_BASE_CURRENCY1,
    pkgreturncursor.fncgetdescription(DEAL_OTHER_CURRENCY,2) AS DEAL_OTHER_CURRENCY1,
    DECODE (deal_BUY_SELL,25300001,'Sell','Buy')             AS DEAL_BUY_SELL1,
    CDEL_CANCEL_AMOUNT                                       AS BaseAmount,
    CDEL_CANCEL_AMOUNT*CDEL_CANCEL_RATE                      AS AmtInr,
    DEAL_MATURITY_DATE                                       AS DEAL_MATURITY_DATE,
    CDEL_CANCEL_RATE                                         AS Rate,
    DEAL_EXCHANGE_RATE                                       AS BookingRate,
    DEAL_HEDGE_TRADE                                         AS DEAL_HEDGE_TRADE,
    pkgreturncursor.fncgetdescription(DEAL_BACKUP_DEAL,2) BacKupDeal,
    pkgreturnreport.GetSystemDate()                    AS SystemDate,
    DEAL_RECORD_STATUS                                 AS DEAL_RECORD_STATUS,
    DEAL_COMPANY_CODE                                  AS DEAL_COMPANY_CODE,
    DEAL_COUNTER_PARTY                                 AS DEAL_COUNTER_PARTY,
    DEAL_BASE_CURRENCY                                 AS DEAL_BASE_CURRENCY,
    DEAL_BUY_SELL                                      AS DEAL_BUY_SELL ,
    pkgreturncursor.fncgetdescription(DEAL_INIT_CODE,2)AS DEAL_INIT_CODE1,
    DEAL_INIT_CODE                                     AS DEAL_INIT_CODE,
    DECODE(deal_hedge_trade, 26000001, 'Hedge Deal', 26000002,'Trade Deal',26000003,'FT Deal') HedgeTrade,
    DEAL_BACKUP_DEAL AS DEAL_BACKUP_DEAL,
    CDEL_LOCAL_RATE  AS CDEL_LOCAL_RATE,
    cdel_profit_loss PandL
  FROM trtran001,
    trtran006
  WHERE deal_deal_number      =cdel_deal_number
  AND CDEL_RECORD_STATUS NOT IN (10200005,10200006)
  )
WHERE DEAL_RECORD_STATUS NOT IN (10200005,10200006)
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 ;