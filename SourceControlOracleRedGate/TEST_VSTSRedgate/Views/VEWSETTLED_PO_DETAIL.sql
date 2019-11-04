CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewsettled_po_detail (company,"CATEGORY",subcategory,referencedate,contract_no,vendor,bank,bankref,duedate,currency,contractamount,benchmarkrate,forwardcontract,executedate,currencypair,forwardcontractbank,dealtype,baseamount,exchangerate,deliverydate,deliverdamount,deliverdrate,ed_pisa,edbenifit,documentno,asondate,"Todate",importexport,importexporttype) AS
SELECT pkgreturncursor.fncgetdescription(trad_company_code,1) AS Company,
    pkgreturncursor.fncgetdescription(trad_product_category,2)  AS Category,
    pkgreturncursor.fncgetdescription(trad_subproduct_code,2)   AS SubCategory,
    trad_Reference_date "ReferenceDate",
    NVL(trad_contract_no,trad_trade_reference)               AS Contract_No,
    pkgreturncursor.fncgetdescription(trad_buyer_seller,2)   AS Vendor,
    pkgreturncursor.fncgetdescription(trad_local_bank,2)     AS Bank,
    trad_user_reference                                      AS BankRef,
    trad_maturity_date                                       AS DueDate ,
    pkgreturncursor.fncgetdescription(trad_trade_currency,2) AS Currency,
    trad_trade_fcy                                           AS ContractAmount,
    trad_trade_rate                                          AS BenchMarkRate,
    Deal_deal_number                                         AS ForwardContract,
    deal_execute_date "ExecuteDate",
    pkgreturncursor.fncgetdescription(Deal_Base_currency,2)
    || '/'
    || pkgreturncursor.fncgetdescription(Deal_Other_currency,2) AS CurrencyPair,
    pkgreturncursor.fncgetdescription(deal_Counter_party,2)     AS ForwardContractBank,
    DECODE(deal_deal_type,25400001,'Cash','Forward')            AS DealType,
    Deal_base_amount BaseAmount,
    Deal_exchange_rate ExchangeRate,
    cdel_cancel_date DeliveryDate,
    cdel_cancel_amount AS DeliverdAmount,
    cdel_cancel_Rate   AS DeliverdRate,
    CASE
      WHEN cdel_cancel_type = 27000002
      THEN (deal_exchange_rate-cdel_cancel_rate)
    END ED_Pisa,
    CASE
      WHEN cdel_cancel_type = 27000002
      THEN cdel_profit_loss
    END EDBenifit,
    TRAD_PRODUCT_DESCRIPTION DocumentNo,
    (SELECT FROMDATE FROM trsystem981
    ) AsonDate,
    (SELECT Todate FROM Trsystem981
    ) Todate,
    pkgreturncursor.fncgetdescription(trad_import_export,2) ImportExport,
    trad_import_export ImportExporttype
  FROM trtran002 Con
  INNER JOIN trtran006 Cdel
  ON trad_trade_reference= cdel_trade_reference
  INNER JOIN trtran001 deal
  ON cdel_deal_number           = deal_deal_number
  WHERE trad_record_Status NOT IN (10200006)
  AND cdel_record_Status NOT   IN (10200005,10200006)
  AND deal_record_Status NOT   IN (10200005,10200006)
  AND cdel_cancel_date BETWEEN
    (SELECT FROMDATE FROM trsystem981
    )
  AND (SELECT TODATE FROM trsystem981)
  UNION ALL
  SELECT pkgreturncursor.fncgetdescription(trad_company_code,1) AS Company,
    pkgreturncursor.fncgetdescription(trad_product_category,2)  AS Category,
    pkgreturncursor.fncgetdescription(trad_subproduct_code,2)   AS SubCategory,
    trad_Reference_date "ReferenceDate",
    NVL(trad_contract_no,trad_trade_reference)               AS Contract_No,
    pkgreturncursor.fncgetdescription(trad_buyer_seller,2)   AS Vendor,
    pkgreturncursor.fncgetdescription(trad_local_bank,2)     AS Bank,
    trad_user_reference                                      AS BankRef,
    trad_maturity_date                                       AS DueDate ,
    pkgreturncursor.fncgetdescription(trad_trade_currency,2) AS Currency,
    trad_trade_fcy                                           AS ContractAmount,
    trad_trade_rate                                          AS BenchMarkRate,
    NULL                                                     AS ForwardContract,
    NULL                                                     AS "ExecuteDate",
    NULL                                                     AS CurrencyPair,
    NULL                                                     AS ForwardContractBank,
    NULL                                                     AS DealType,
    0 BaseAmount,
    0 ExchangeRate,
    BREL_ENTRY_DATE DeliveryDate,
    LOLN_ADJUSTED_FCY AS DeliverdAmount,
    BCRD_SPOT_RATE    AS DeliverdRate,
    0 ED_Pisa,
    0 EDBenifit,
    TRAD_PRODUCT_DESCRIPTION DocumentNo,
    (SELECT FROMDATE FROM trsystem981
    ) AsonDate,
    (SELECT TODATE FROM trsystem981
    ) Todate,
    'BuyersCredit' ImportExport,
    25900073 ImportExporttype
  FROM trtran002,
    trtran003,
    trtran010,
    TRTRAN045
  WHERE trad_trade_reference  = brel_trade_reference
  AND brel_trade_reference    = loln_trade_reference
  AND BCRD_BUYERS_CREDIT      = LOLN_LOAN_NUMBER
  AND BCRD_RECORD_STATUS NOT IN(10200006)
  AND trad_record_status NOT IN(10200006)
  AND brel_record_status NOT IN(10200006)
  AND LOLN_RECORD_STATUS BETWEEN 10200001 AND 10200004
  AND BREL_ENTRY_DATE BETWEEN
    (SELECT FROMDATE FROM trsystem981
    )
  AND (SELECT TODATE FROM trsystem981)
  UNION ALL
  SELECT pkgreturncursor.fncgetdescription(BCRD_COMPANY_CODE,1) AS Company,
    pkgreturncursor.fncgetdescription(33300003,2)               AS CATEGORY,
    pkgreturncursor.fncgetdescription(33800003,2)               AS SubCategory,
    BCRD_SANCTION_DATE "ReferenceDate",
    BCRD_BUYERS_CREDIT                                      AS Contract_No,
    pkgreturncursor.fncgetdescription(BCRD_AGENT_CODE,2)    AS Vendor,
    pkgreturncursor.fncgetdescription(BCRD_LOCAL_BANK,2)    AS Bank,
    BCRD_SANCTION_REFERENCE                                 AS BankRef,
    BCRD_DUE_DATE                                           AS DueDate ,
    pkgreturncursor.fncgetdescription(BCRD_CURRENCY_CODE,2) AS Currency,
    BCRD_SANCTIONED_FCY                                     AS ContractAmount,
    BCRD_CONVERSION_RATE                                    AS BenchMarkRate,
    Deal_deal_number                                        AS ForwardContract,
    deal_execute_date "ExecuteDate",
    pkgreturncursor.fncgetdescription(Deal_Base_currency,2)
    || '/'
    || pkgreturncursor.fncgetdescription(Deal_Other_currency,2) AS CurrencyPair,
    pkgreturncursor.fncgetdescription(deal_Counter_party,2)     AS ForwardContractBank,
    DECODE(deal_deal_type,25400001,'Cash','Forward')            AS DealType,
    Deal_base_amount BaseAmount,
    Deal_exchange_rate ExchangeRate,
    cdel_cancel_date DeliveryDate,
    cdel_cancel_amount AS DeliverdAmount,
    cdel_cancel_Rate   AS DeliverdRate,
    CASE
      WHEN cdel_cancel_type = 27000002
      THEN (deal_exchange_rate-cdel_cancel_rate)
    END ED_Pisa,
    CASE
      WHEN cdel_cancel_type = 27000002
      THEN cdel_profit_loss
    END EDBenifit,
    NULL DocumentNo,
    (SELECT FROMDATE FROM trsystem981
    ) AsonDate,
    (SELECT Todate FROM Trsystem981
    ) Todate,
    'BuyersCredit' ImportExport,
    25900073 ImportExporttype
  FROM trtran045 Con
  INNER JOIN trtran006 Cdel
  ON BCRD_BUYERS_CREDIT= cdel_trade_reference
  INNER JOIN trtran001 deal
  ON cdel_deal_number           = deal_deal_number
  WHERE BCRD_RECORD_STATUS NOT IN (10200006)
  AND cdel_record_Status NOT   IN (10200005,10200006)
  AND deal_record_Status NOT   IN (10200005,10200006)
  AND cdel_cancel_date BETWEEN
    (SELECT FROMDATE FROM trsystem981
    )
  AND (SELECT Todate FROM Trsystem981)
  ORDER BY 4;