CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewdailyentry (companycode,dealnumber,cmpshortdesc,counterparty,currency,baseamount,buysell,exchangerate,valuedate,washrate,status,remarks,companyname,systemdate,backupdeal,tradereffrence,profitloss,executedate) AS
SELECT DEAL_COMPANY_CODE,
    deal_deal_number                                        AS DealNumber,
    pkgreturncursor.fncgetdescription(DEAL_COMPANY_CODE,2)  AS cmpshortdesc,
    pkgreturncursor.fncgetdescription(DEAL_COUNTER_PARTY,2) AS CounterParty,
    pkgreturncursor.fncgetdescription(DEAL_BASE_CURRENCY,2)
    || '/'
    || pkgreturncursor.fncgetdescription(DEAL_OTHER_CURRENCY,2) AS Currency,
    DEAL_BASE_AMOUNT                                            AS BaseAmount,
    pkgreturncursor.fncgetdescription(DEAL_BUY_SELL,2)          AS Buysell,
    DEAL_EXCHANGE_RATE                                          AS ExchangeRate,
    deal_maturity_date                                          AS ValueDate,
    DECODE(DEAL_OTHER_CURRENCY,30400003,1,DEAL_LOCAL_RATE)      AS WashRate,
    'NEW DEALS'                                                 AS Status,
    deal_dealer_remarks                                         AS Remarks,
    pkgreturnreport.getCompanyName('')                            AS CompanyName,
    pkgreturnreport.GetSystemDate()                             AS SystemDate,
    pkgreturncursor.fncgetdescription(DEAL_BACKUP_DEAL,2)       AS Backupdeal,
    ''                                                          AS TradeReffrence,
    0                                                           AS Profitloss,
    DEAL_EXECUTE_DATE                                           AS ExecuteDate
  FROM trtran001
  WHERE DEAL_record_status NOT IN(10200006,10200005)
  AND DEAL_EXECUTE_DATE BETWEEN
    (SELECT FROMDATE FROM trsystem981
    )
  AND (SELECT TODATE FROM trsystem981)
  UNION ALL
  SELECT CDEL_COMPANY_CODE,
    cdel_deal_number                                       AS DealNumber,
    pkgreturncursor.fncgetdescription(CDEL_COMPANY_CODE,2) AS cmpshortdesc,
    pkgreturncursor.fncgetdescription(deal_counter_party,2)AS CounterParty,
    pkgreturncursor.fncgetdescription(deal_base_currency,2)AS Currency,
    CDEL_CANCEL_AMOUNT                                     AS BaseAmount,
    pkgreturncursor.fncgetdescription(deal_buy_sell,2)     AS Buysell,
    deal_exchange_Rate                                     AS ExchangeRate,
    NULL                                                   AS ValueDate,
    cdel_cancel_rate                                       AS WashRate,
    'DEAL CANCEL/DELIVER'                                  AS Status,
    CDEL_DEALER_REMARK                                     AS Remarks,
    pkgreturnreport.getCompanyName('')                       AS CompanyName,
    pkgreturnreport.GetSystemDate()                        AS SystemDate ,
    NULL                                                   AS Backupdeal,
    ''                                                     AS TradeReffrence,
    CDEL_PROFIT_LOSS                                       AS Profitloss,
    cdel_cancel_date                                       AS ExecuteDate
  FROM TRTRAN006,
    TRTRAN001
  WHERE CDEL_RECORD_STATUS NOT IN(10200006,10200005)
  AND DEAL_RECORD_STATUS NOT   IN(10200005,10200006)
  AND cdel_deal_number          = deal_deal_number
  AND DEAL_DEAL_TYPE NOT       IN(25400001)
    --  AND cdel_cancel_type = 27000001
  AND cdel_cancel_date BETWEEN
    (SELECT FROMDATE FROM trsystem981
    )
  AND (SELECT TODATE FROM trsystem981)
  UNION ALL
  SELECT TRAD_COMPANY_CODE,
    TRAD_TRADE_REFERENCE                                     AS DealNumber,
    pkgreturncursor.fncgetdescription(TRAD_COMPANY_CODE,2)   AS cmpshortdesc,
    pkgreturncursor.fncgetdescription(TRAD_LOCAL_BANK,2)     AS CounterParty,
    pkgreturncursor.fncgetdescription(TRAD_TRADE_CURRENCY,2) AS Currency,
    TRAD_TRADE_FCY                                           AS BaseAmount,
    NULL                                                     AS Buysell,
    TRAD_TRADE_RATE                                          AS ExchangeRate,
    TRAD_MATURITY_DATE                                       AS ValueDate,
    NULL                                                     AS WashRate,
    'NEW ORDERS'                                             AS Status,
    TRAD_TRADE_REMARKS                                       AS Remarks,
    pkgreturnreport.getCompanyName('')                         AS CompanyName,
    pkgreturnreport.GetSystemDate()                          AS SystemDate ,
    NULL                                                     AS Backupdeal,
    ''                                                       AS TradeReffrence,
    0                                                        AS Profitloss,
    TRAD_ENTRY_DATE                                          AS ExecuteDate
  FROM trtran002
  WHERE TRAD_RECORD_STATUS NOT IN(10200006,10200005)
  AND TRAD_ENTRY_DATE BETWEEN
    (SELECT FROMDATE FROM trsystem981
    )
  AND (SELECT TODATE FROM trsystem981)
  UNION ALL
  SELECT trad_company_code,
    deal_deal_number                                          AS DealNumber,
    pkgreturncursor.fncgetdescription(deal_company_code,2)    AS cmpshortdesc,
    pkgreturncursor.fncgetdescription(trad_local_bank,2)      AS CounterParty,
    pkgreturncursor.fncgetdescription(trad_trade_currency,2)  AS Currency,
    cdel_cancel_amount                                        AS BaseAmount,
    pkgreturncursor.fncgetdescription(deal_buy_sell,2)        AS Buysell,
    TRAD_TRADE_RATE                                           AS ExchangeRate,
    trad_maturity_date                                        AS ValueDate,
    cdel_cancel_rate                                          AS WashRate,
    'FC DELIVERY'                                             AS Status,
    NULL                                                      AS Remarks,
    pkgreturnreport.getCompanyName('')                          AS CompanyName,
    pkgreturnreport.GetSystemDate()                           AS SystemDate ,
    NULL                                                      AS Backupdeal,
    TRAD_TRADE_REFERENCE                                      AS TradeReffrence,
    cdel_cancel_amount * (TRAD_TRADE_RATE - cdel_cancel_rate) AS Profitloss,
    cdel_cancel_date                                          AS ExecuteDate
  FROM TRTRAN006,
    TRTRAN002,
    TRTRAN001
  WHERE CDEL_TRADE_REFERENCE = TRAD_TRADE_REFERENCE
  AND cdel_deal_number       = deal_deal_number
  AND cdel_cancel_date BETWEEN
    (SELECT FROMDATE FROM trsystem981
    )
  AND (SELECT TODATE FROM trsystem981)
  AND DEAL_DEAL_TYPE NOT     IN(25400001)
  AND CDEL_RECORD_STATUS NOT IN(10200005,10200006)
  AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
  AND TRAD_RECORD_STATUS NOT IN(10200005,10200006)
  UNION ALL
  SELECT trad_company_code,
    deal_deal_number                                          AS DealNumber,
    pkgreturncursor.fncgetdescription(deal_company_code,2)    AS cmpshortdesc,
    pkgreturncursor.fncgetdescription(trad_local_bank,2)      AS CounterParty,
    pkgreturncursor.fncgetdescription(trad_trade_currency,2)  AS Currency,
    cdel_cancel_amount                                        AS BaseAmount,
    pkgreturncursor.fncgetdescription(deal_buy_sell,2)        AS Buysell,
    TRAD_TRADE_RATE                                           AS ExchangeRate,
    trad_maturity_date                                        AS ValueDate,
    cdel_cancel_rate                                          AS WashRate,
    'CASH SETTLE'                                             AS Status,
    NULL                                                      AS Remarks,
    pkgreturnreport.getCompanyName('')                          AS CompanyName,
    pkgreturnreport.GetSystemDate()                           AS SystemDate ,
    NULL                                                      AS Backupdeal,
    TRAD_TRADE_REFERENCE                                      AS TradeReffrence,
    cdel_cancel_amount * (TRAD_TRADE_RATE - cdel_cancel_rate) AS Profitloss,
    cdel_cancel_date                                          AS ExecuteDate
  FROM trtran006,
    trtran002,
    trtran001
  WHERE CDEL_TRADE_REFERENCE = TRAD_TRADE_REFERENCE
  AND CDEL_DEAL_NUMBER       = DEAL_DEAL_NUMBER
  AND DEAL_DEAL_TYPE         = 25400001
  AND CDEL_CANCEL_DATE BETWEEN
    (SELECT FROMDATE FROM trsystem981
    )
  AND (SELECT TODATE FROM trsystem981)
  AND CDEL_RECORD_STATUS NOT IN(10200005,10200006)
  AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
  AND TRAD_RECORD_STATUS NOT IN(10200005,10200006)
  UNION ALL
  SELECT HEDG_COMPANY_CODE,
    hedg_deal_number                                       AS DealNumber,
    pkgreturncursor.fncgetdescription(HEDG_COMPANY_CODE,2) AS cmpshortdesc,
    NULL                                                   AS CounterParty,
    NULL                                                   AS Currency,
    HEDG_HEDGED_FCY                                        AS BaseAmount,
    NULL                                                   AS Buysell,
    NULL                                                   AS ExchangeRate,
    NULL                                                   AS ValueDate,
    NULL                                                   AS WashRate,
    'DEAL LINK'                                            AS Status,
    NULL                                                   AS Remarks,
    pkgreturnreport.getCompanyName('')                       AS CompanyName,
    pkgreturnreport.GetSystemDate()                        AS SystemDate ,
    NULL                                                   AS Backupdeal,
    HEDG_TRADE_REFERENCE                                   AS TradeReffrence,
    0                                                      AS Profitloss,
    HEDG_CREATE_DATE                                       AS ExecuteDate
  FROM trtran004
  WHERE HEDG_RECORD_STATUS NOT IN(10200006,10200005)
  AND HEDG_CREATE_DATE BETWEEN
    (SELECT FROMDATE FROM trsystem981
    )
  AND (SELECT TODATE FROM trsystem981)
 
 
 
 
 
 
 ;