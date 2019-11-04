CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewexposuresettlement (company,"CATEGORY",subcategory,referencedate,contract_no,vendor,bank,bankref,duedate,currency,contractamount,benchmarkrate,forwardcontract,executedate,currencypair,forwardcontractbank,dealtype,baseamount,exchangerate,deliverydate,deliverdamount,deliverdrate,ed_pisa,edbenifit,documentno,asondate,"Todate",locationcode) AS
SELECT pkgreturncursor.fncgetdescription(DEAL_COMPANY_CODE,1) AS Company,
    pkgreturncursor.fncgetdescription(DEAL_BACKUP_DEAL,2)  AS Category,
    pkgreturncursor.fncgetdescription(DEAL_INIT_CODE,2)   AS SubCategory,
    DEAL_EXECUTE_DATE "ReferenceDate",
    (SELECT bnkc_invoice_numbers FROM himatsingkatf_prod.tftran021 
      where bnkc_invoice_number = cdel_trade_reference 
     and bnkc_record_status between 10200001 and 10200004)AS Contract_No,
        (SELECT himatsingkatf_prod.PKGRETURNCURSOR.FNCGETDESCRIPTION(bnkc_buyer_code,1) 
        FROM himatsingkatf_prod.tftran021 
      where bnkc_invoice_number = cdel_trade_reference 
     and bnkc_record_status between 10200001 and 10200004)AS Vendor,         
    pkgreturncursor.fncgetdescription(DEAL_COUNTER_PARTY,2)     AS Bank,
    DEAL_USER_REFERENCE                                      AS BankRef,
    DEAL_MATURITY_DATE                                       AS DueDate ,
    pkgreturncursor.fncgetdescription(DEAL_BASE_CURRENCY,2) AS Currency,
    (SELECT bnkc_invoice_fcy FROM himatsingkatf_prod.tftran021 
    where bnkc_invoice_number = cdel_trade_reference 
    and bnkc_record_status between 10200001 and 10200004)     AS ContractAmount,
    DEAL_EXCHANGE_RATE                                          AS BenchMarkRate,
    Deal_deal_number                                         AS ForwardContract,
    deal_execute_date "ExecuteDate",
    pkgreturncursor.fncgetdescription(Deal_Base_currency,2)
    || '/'
    || pkgreturncursor.fncgetdescription(Deal_Other_currency,2) AS CurrencyPair,
    pkgreturncursor.fncgetdescription(deal_Counter_party,2)     AS ForwardContractBank,
    DECODE(deal_deal_type,25400001,'Spot','Forward')            AS DealType,
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
    DEAL_USER_REFERENCE DocumentNo,
    (SELECT FROMDATE FROM trsystem981
    ) AsonDate,
    (SELECT TODATE FROM trsystem981
    ) Todate,
    pkgreturncursor.fncgetdescription(deal_location_code,2)LocationCode
  FROM trtran001
  INNER JOIN trtran006 Cdel
  ON cdel_deal_number           = deal_deal_number
  WHERE cdel_record_Status NOT   IN (10200005,10200006)
  AND deal_record_Status NOT   IN (10200005,10200006)
  AND CDEL_CANCEL_TYPE = 27000002
  ORDER BY DEAL_EXECUTE_DATE
 
 
 
 ;