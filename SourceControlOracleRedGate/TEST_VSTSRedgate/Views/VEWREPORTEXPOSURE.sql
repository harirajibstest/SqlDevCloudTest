CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewreportexposure (buyerseller,outstanding,unhedgeamount,referencedate,duedatelc,duedatebc,spotrate,fwdprimium,totalrate,mtmrate,frwdprimmtm,localbank,userreference,currencycode,companycode,processcomplete,completedate,recordstatus,tradereference,dealdate,effecttraderate,tradeamount) AS
SELECT pkgreturncursor.fncgetdescription(TRAD_BUYER_SELLER,2) AS BuyerSeller,
    pkgforexprocess.fncGetOutstanding(TRAD_TRADE_REFERENCE,0,0,1,
    (SELECT TODATE
    FROM trsystem981
    )) outstanding,
    (pkgforexprocess.fncGetOutstanding(TRAD_TRADE_REFERENCE,0,0,1,
    (SELECT TODATE FROM trsystem981
    )) - NVL(
    (SELECT NVL(SUM(HEDG_HEDGED_FCY),0)
    FROM trtran004
    WHERE TRAD_TRADE_REFERENCE  = HEDG_TRADE_REFERENCE
    AND hedg_record_status NOT IN(10200006,10200005,10200012)
    ),0)) AS UnhedgeAmount,
    --pkgforexprocess.fncGetOutstanding(TRAD_TRADE_REFERENCE,0,0,1,(select TODATE from trsystem981))  as UnhedgeAmount,
    TRAD_REFERENCE_DATE    AS ReferenceDate,
    TRAD_MATURITY_FROM     AS DuedateLC,
    TRAD_MATURITY_DATE     AS DuedateBC,
    NVL(trad_spot_rate,0)  AS SpotRate,
    TRAD_FORWARD_RATE      AS FWDPrimium,
    NVL(trad_trade_rate,0) AS Totalrate,
    (pkgforexprocess.fncGetRate(30400004,30400003,
    (SELECT TODATE FROM trsystem981
    ),(
    CASE
      WHEN TRAD_IMPORT_EXPORT > 25900050
      THEN 25300001
      ELSE 25300002
    END),0,NULL,0) + (pkgforexprocess.fncGetRate(30400004,30400003,
    (SELECT TODATE FROM trsystem981
    ),(
    CASE
      WHEN TRAD_IMPORT_EXPORT > 25900050
      THEN 25300001
      ELSE 25300002
    END) ,0, TRAD_MATURITY_DATE,0))) - pkgforexprocess.fncGetRate(30400004,30400003,
    (SELECT TODATE FROM trsystem981
    ),(
    CASE
      WHEN TRAD_IMPORT_EXPORT > 25900050
      THEN 25300001
      ELSE 25300002
    END),0,NULL,0)mtmRate,
    --      pkgforexprocess.fncGetRate(30400004,30400003,(select TODATE from trsystem981),
    --      (case when TRAD_IMPORT_EXPORT > 25900050 then 25300001 else 25300002 end),0,null,0) as mtmRate,
    --     (pkgforexprocess.fncGetRate(30400004,30400003,(select TODATE from trsystem981),
    --     (case when TRAD_IMPORT_EXPORT > 25900050 then 25300001 else 25300002 end),0,TRAD_MATURITY_DATE,0) -
    --     pkgforexprocess.fncGetRate(30400004,30400003,(select TODATE from trsystem981),
    --     (case when TRAD_IMPORT_EXPORT > 25900050 then 25300001 else 25300002 end),0,null,0)) FrwdPrimMtm,
    0 FrwdPrimMtm,
    TRAD_LOCAL_BANK LocalBank,
    TRAD_USER_REFERENCE UserReference,
    TRAD_TRADE_CURRENCY CurrencyCode,
    TRAD_COMPANY_CODE CompanyCode,
    12400002 ProcessComplete,
    TRAD_COMPLETE_DATE CompleteDate,
    TRAD_RECORD_STATUS RecordStatus,
    TRAD_TRADE_REFERENCE tradeReference,
    TRAD_REFERENCE_DATE AS DEALDATE,
    ROUND(
    (SELECT SUM((cdel_cancel_rate) * CDEL_CANCEL_AMOUNT)/SUM(CDEL_CANCEL_AMOUNT)
    FROM trtran006
    WHERE trad_trade_reference = cdel_trade_reference
    ),2)EffectTradeRate,
    trad_trade_fcy TradeAmount
  FROM trtran002
  WHERE TRAD_RECORD_STATUS NOT IN(10200005,10200006,10200012)
  AND ((TRAD_PROCESS_COMPLETE   = 12400001
  AND trad_complete_date        >
    (SELECT TODATE FROM trsystem981
    ))
  OR TRAD_PROCESS_COMPLETE = 12400002)
  --and (pkgforexprocess.fncGetOutstanding(TRAD_TRADE_REFERENCE,0,0,1,(select TODATE from trsystem981)) - nvl((select nvl(sum(HEDG_HEDGED_FCY),0) from trtran004 where TRAD_TRADE_REFERENCE = HEDG_TRADE_REFERENCE and hedg_record_status not in(10200006,10200005,10200012)),0)) > 0
  UNION ALL
  SELECT NULL AS BuyerSeller,
    --pkgforexprocess.fncGetOutstanding(FCLN_LOAN_NUMBER,0,0,1,(select TODATE from trsystem981))
    FCLN_SANCTIONED_FCY outstanding,
    FCLN_SANCTIONED_FCY AS UnhedgeAmount,
    --pkgforexprocess.fncGetOutstanding(TRAD_TRADE_REFERENCE,0,0,1,(select TODATE from trsystem981))  as UnhedgeAmount,
    FCLN_SANCTION_DATE          AS ReferenceDate,
    FCLN_MATURITY_FROM          AS DuedateLC,
    FCLN_MATURITY_TO            AS DuedateBC,
    NVL(FCLN_CONVERSION_RATE,0) AS SpotRate,
    0                           AS FWDPrimium,
    NVL(FCLN_CONVERSION_RATE,0) AS Totalrate,
    Pkgforexprocess.Fncgetrate(30400004,30400003,
    (SELECT TODATE FROM trsystem981
    ),25300001,0,FCLN_MATURITY_FROM) AS mtmRate,
    0 FrwdPrimMtm,
    FCLN_LOCAL_BANK LocalBank,
    NULL UserReference,
    FCLN_CURRENCY_CODE CurrencyCode,
    FCLN_COMPANY_CODE CompanyCode,
    12400002 ProcessComplete,
    NULL CompleteDate,
    FCLN_RECORD_STATUS RecordStatus,
    FCLN_LOAN_NUMBER tradeReference,
    FCLN_SANCTION_DATE AS DEALDATE,
    0 EffectTradeRate,
    FCLN_SANCTIONED_FCY TradeAmount
  FROM trtran005
  UNION ALL
  SELECT pkgreturncursor.fncgetdescription(TRAD_BUYER_SELLER,2) AS BuyerSeller,
    pkgforexprocess.fncGetOutstanding(TRAD_TRADE_REFERENCE,0,0,1,
    (SELECT TODATE FROM trsystem981
    )) outstanding,
    Trad_trade_fcy AS UnhedgeAmount,
    --pkgforexprocess.fncGetOutstanding(TRAD_TRADE_REFERENCE,0,0,1,(select TODATE from trsystem981))  as UnhedgeAmount,
    TRAD_REFERENCE_DATE    AS ReferenceDate,
    TRAD_MATURITY_FROM     AS DuedateLC,
    TRAD_MATURITY_DATE     AS DuedateBC,
    NVL(trad_spot_rate,0)  AS SpotRate,
    TRAD_FORWARD_RATE      AS FWDPrimium,
    NVL(trad_trade_rate,0) AS Totalrate,
    --      pkgforexprocess.fncGetRate(30400004,30400003,(select TODATE from trsystem981),
    --      (case when TRAD_IMPORT_EXPORT > 25900050 then 25300001 else 25300002 end),0,null,0) as mtmRate,
    (pkgforexprocess.fncGetRate(30400004,30400003,
    (SELECT TODATE FROM trsystem981
    ),(
    CASE
      WHEN TRAD_IMPORT_EXPORT > 25900050
      THEN 25300001
      ELSE 25300002
    END),0,NULL,0) + (pkgforexprocess.fncGetRate(30400004,30400003,
    (SELECT TODATE FROM trsystem981
    ),(
    CASE
      WHEN TRAD_IMPORT_EXPORT > 25900050
      THEN 25300001
      ELSE 25300002
    END) ,0, TRAD_MATURITY_DATE,0))) - pkgforexprocess.fncGetRate(30400004,30400003,
    (SELECT TODATE FROM trsystem981
    ),(
    CASE
      WHEN TRAD_IMPORT_EXPORT > 25900050
      THEN 25300001
      ELSE 25300002
    END),0,NULL,0)mtmRate,
    --     (pkgforexprocess.fncGetRate(30400004,30400003,(select TODATE from trsystem981),
    --     (case when TRAD_IMPORT_EXPORT > 25900050 then 25300001 else 25300002 end),0,TRAD_MATURITY_DATE,0) -
    --     pkgforexprocess.fncGetRate(30400004,30400003,(select TODATE from trsystem981),
    --     (case when TRAD_IMPORT_EXPORT > 25900050 then 25300001 else 25300002 end),0,null,0)) FrwdPrimMtm,
    0 FrwdPrimMtm,
    TRAD_LOCAL_BANK LocalBank,
    TRAD_USER_REFERENCE UserReference,
    TRAD_TRADE_CURRENCY CurrencyCode,
    TRAD_COMPANY_CODE CompanyCode,
    12400001 ProcessComplete,
    TRAD_COMPLETE_DATE CompleteDate,
    TRAD_RECORD_STATUS RecordStatus,
    TRAD_TRADE_REFERENCE tradeReference,
    TRAD_REFERENCE_DATE AS DEALDATE,
    ROUND(
    (SELECT SUM((cdel_cancel_rate) * CDEL_CANCEL_AMOUNT)/SUM(CDEL_CANCEL_AMOUNT)
    FROM trtran006
    WHERE trad_trade_reference = cdel_trade_reference
    ),2)EffectTradeRate,
    trad_trade_fcy TradeAmount
  FROM trtran002
  WHERE TRAD_RECORD_STATUS NOT IN(10200005,10200006)
  AND (TRAD_PROCESS_COMPLETE    = 12400001
  AND trad_complete_date        <
    (SELECT TODATE FROM trsystem981
    ))
  AND TRAD_REVERSE_REFERENCE IS NULL
    --and (pkgforexprocess.fncGetOutstanding(TRAD_TRADE_REFERENCE,0,0,1,(select TODATE from trsystem981)) - nvl((select nvl(sum(HEDG_HEDGED_FCY),0) from trtran004 where TRAD_TRADE_REFERENCE = HEDG_TRADE_REFERENCE and hedg_record_status not in(10200006,10200005,10200012)),0)) > 0
  ORDER BY 6
 
 
 
 
 
 
 
 ;