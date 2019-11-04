CREATE OR REPLACE PROCEDURE "TEST_VSTSRedgate".prcMISReport
(FromDate  DATE ,Todate DATE)
AS
    varmsg              varchar2(2000);
    tempDate            date;
    dattemp1            date;
    temp                date;
    SpotRate            number(15,6);
    SpotRate1           number(15,6);            
    dattemp2            DATE;
    varOperation        VARCHAR2(100);
    numError            NUMBER;
    varMessage          VARCHAR2(100);
    varError      varchar2(4000);
BEGIN

DELETE FROM trsystem975;
varOperation  := 'Inserting Import and Export-Projected data';
INSERT INTO TRSYSTEM975
  (MISR_COMPANY_CODE,MISR_LOCATION_CODE,MISR_COUNTER_PARTY,MISR_CURRENCY_CODE,MISR_FOR_CURRENCY,
  MISR_TRANSACTION_TYPE,MISR_BUY_SELL,MISR_TRANSACTION_AMOUNT,MISR_OUSTSNDING_AMOUNT,MISR_REALISED_AMOUNT,
  MISR_EXCHANGE_RATE,MISR_EFFECTIVE_RATE,MISR_INTEREST_RATE,MISR_ASON_DATE,MISR_REFERENCE_DATE,
  MISR_MATURITY_DATE,MISR_REFERENCE_NUMBER,MISR_BANK_REFERENCE,MISR_REMRKS,MISR_ACTUAL_PROJECTED,
  MISR_PORT_FOLIO,MISR_SUBPORT_FOLIO,MISR_EXPAIRY_QUARTER,MISR_EXPAIRY_MONTH,MISR_MONTH_ORDER,
  MISR_SPOT_RATE,MISR_FORWARD_RATE,MISR_MARGIN_RATE,MISR_DEAL_TYPE,MISR_MAIN_ORDER,MISR_SUB_ORDER,
  MISR_DESCRIPTION,MISR_LOCAL_AMOUNT)
--SELECT 
--  posn_company_code,posn_location_code,posn_counter_party, posn_currency_code,posn_for_currency,
--  posn_account_code,(CASE WHEN posn_account_code > 25900050 THEN 25300001 ELSE 25300002 END),
--  posn_transaction_amount,posn_transaction_amount,0,
--  posn_fcy_rate,posn_m2m_inrrate,0,Todate,posn_reference_date,
--  posn_due_date,posn_reference_number,null,'Imports&Export','Projeceted',
--  posn_product_code,posn_subproduct_code,
--    CASE 
--        WHEN to_number(to_char(posn_due_date,'mm')) BETWEEN 4  AND 6  THEN 'Q1 ' || FNCGETFINANCIALYEAR(posn_due_date,posn_due_date,2)
--        WHEN to_number(to_char(posn_due_date,'mm')) BETWEEN 7  AND 9  THEN 'Q2 ' || FNCGETFINANCIALYEAR(posn_due_date,posn_due_date,2)
--        WHEN to_number(to_char(posn_due_date,'mm')) BETWEEN 10  AND 12  THEN 'Q3 ' || FNCGETFINANCIALYEAR(posn_due_date,posn_due_date,2)
--        WHEN to_number(to_char(posn_due_date,'mm')) BETWEEN 1 AND 3 THEN 'Q4 ' || FNCGETFINANCIALYEAR(posn_due_date,posn_due_date,2)
--    END,
--  to_char(posn_due_date,'MON YYYY'), to_char(posn_due_date,'YYYYMM'),
--  posn_fcy_rate,0,0,25400006,1,(CASE WHEN posn_account_code < 25900050 THEN 1 ELSE 2 END),
--  (CASE WHEN posn_account_code > 25900050 THEN 'Import' ELSE 'Export' END),posn_inr_value
--FROM TRSYSTEM997 WHERE 
--  posn_account_code NOT IN(25900011,25900012,25900014,25900015,25900018,
--                          25900019,25900020,25900021,25900022,25900023,
--                          25900061,25900062,25900078,25900079,25900082,
--                          25900083,25900084,25900085,25900074,25900075);

SELECT 
  trad_company_code,trad_location_code,trad_local_bank,trad_trade_currency,trad_local_currency,
  trad_import_export,(CASE WHEN trad_import_export > 25900050 THEN 25300001 ELSE 25300002 END),
  trad_trade_fcy,trad_trade_fcy,0,
  trad_trade_rate,0,0,Todate,trad_reference_date,
  trad_maturity_date,trad_trade_reference,null,'Imports&Export','Projeceted',
  trad_product_category,trad_subproduct_code,
    CASE 
        WHEN to_number(to_char(trad_maturity_date,'mm')) BETWEEN 4  AND 6  THEN 'Q1 ' || FNCGETFINANCIALYEAR(trad_maturity_date,trad_maturity_date,2)
        WHEN to_number(to_char(trad_maturity_date,'mm')) BETWEEN 7  AND 9  THEN 'Q2 ' || FNCGETFINANCIALYEAR(trad_maturity_date,trad_maturity_date,2)
        WHEN to_number(to_char(trad_maturity_date,'mm')) BETWEEN 10  AND 12  THEN 'Q3 ' || FNCGETFINANCIALYEAR(trad_maturity_date,trad_maturity_date,2)
        WHEN to_number(to_char(trad_maturity_date,'mm')) BETWEEN 1 AND 3 THEN 'Q4 ' || FNCGETFINANCIALYEAR(trad_maturity_date,trad_maturity_date,2)
    END,
  to_char(trad_maturity_date,'MON YYYY'), to_char(trad_maturity_date,'YYYYMM'),
  trad_trade_rate,0,0,25400006,1,(CASE WHEN trad_import_export < 25900050 THEN 1 ELSE 2 END),
  (CASE WHEN trad_import_export > 25900050 THEN 'Import' ELSE 'Export' END),trad_trade_inr
FROM trtran002 WHERE TRAD_RECORD_STATUS BETWEEN 10200001 AND 10200004;

varOperation  := 'Inserting Forward,Future,Option contracts-Projected data';
INSERT INTO TRSYSTEM975
  (MISR_COMPANY_CODE,MISR_LOCATION_CODE,MISR_COUNTER_PARTY,MISR_CURRENCY_CODE,MISR_FOR_CURRENCY,
  MISR_TRANSACTION_TYPE,MISR_BUY_SELL,MISR_TRANSACTION_AMOUNT,MISR_OUSTSNDING_AMOUNT,MISR_REALISED_AMOUNT,
  MISR_EXCHANGE_RATE,MISR_EFFECTIVE_RATE,MISR_INTEREST_RATE,MISR_ASON_DATE,MISR_REFERENCE_DATE,
  MISR_MATURITY_DATE,MISR_REFERENCE_NUMBER,MISR_BANK_REFERENCE,MISR_REMRKS,MISR_ACTUAL_PROJECTED,
  MISR_PORT_FOLIO,MISR_SUBPORT_FOLIO,MISR_EXPAIRY_QUARTER,MISR_EXPAIRY_MONTH,MISR_MONTH_ORDER,
  MISR_SPOT_RATE,MISR_FORWARD_RATE,MISR_MARGIN_RATE,MISR_DEAL_TYPE,MISR_MAIN_ORDER,MISR_SUB_ORDER,
  MISR_DESCRIPTION,MISR_LOCAL_AMOUNT)
--SELECT 
--  posn_company_code,posn_location_code,posn_counter_party, posn_currency_code,posn_for_currency,
--  posn_account_code,(CASE WHEN posn_account_code > 25900050 THEN 25300001 ELSE 25300002 END),
--  posn_transaction_amount,posn_transaction_amount,0,
--  posn_fcy_rate,posn_m2m_inrrate,0,Todate,posn_reference_date,
--  posn_due_date,posn_reference_number,POSN_USER_REFERENCE,
--  'HedgeBuy & HedgeSell','Projeceted',
--  posn_product_code,posn_subproduct_code,
--      CASE 
--        WHEN to_number(to_char(posn_due_date,'mm')) BETWEEN 4  AND 6  THEN 'Q1 ' || FNCGETFINANCIALYEAR(posn_due_date,posn_due_date,2)
--        WHEN to_number(to_char(posn_due_date,'mm')) BETWEEN 7  AND 9  THEN 'Q2 ' || FNCGETFINANCIALYEAR(posn_due_date,posn_due_date,2)
--        WHEN to_number(to_char(posn_due_date,'mm')) BETWEEN 10  AND 12  THEN 'Q3 ' || FNCGETFINANCIALYEAR(posn_due_date,posn_due_date,2)
--        WHEN to_number(to_char(posn_due_date,'mm')) BETWEEN 1 AND 3 THEN 'Q4 ' || FNCGETFINANCIALYEAR(posn_due_date,posn_due_date,2)
--    END,
--  to_char(posn_due_date,'MON YYYY'), to_char(posn_due_date,'YYYYMM'),
--  posn_fcy_rate,0,0,25400006,2,(CASE WHEN posn_account_code < 25900050 THEN 1 ELSE 2 END),
--  (CASE WHEN posn_account_code < 25900050 THEN 'HedgeBuy' ELSE 'HedgeSell' END),posn_inr_value
--FROM TRSYSTEM997 WHERE 
--  posn_account_code  IN(25900011,25900012,25900014,25900015,25900018,
--                          25900019,25900020,25900021,25900022,25900023,
--                          25900061,25900062,25900078,25900079,25900082,
--                          25900083,25900084,25900085,25900074,25900075); 

SELECT 
  deal_company_code,deal_location_code,deal_counter_party, deal_base_currency,deal_other_currency,
  deal_buy_sell,deal_buy_sell,
  deal_base_amount,deal_base_amount,0,
  deal_exchange_rate,0,0,ToDate,deal_execute_date,
  deal_maturity_date,deal_deal_number,deal_USER_REFERENCE,
  'HedgeBuy & HedgeSell','Projeceted',
  deal_backup_deal,deal_init_code,
      CASE 
        WHEN to_number(to_char(deal_maturity_date,'mm')) BETWEEN 4  AND 6  THEN 'Q1 ' || FNCGETFINANCIALYEAR(deal_maturity_date,deal_maturity_date,2)
        WHEN to_number(to_char(deal_maturity_date,'mm')) BETWEEN 7  AND 9  THEN 'Q2 ' || FNCGETFINANCIALYEAR(deal_maturity_date,deal_maturity_date,2)
        WHEN to_number(to_char(deal_maturity_date,'mm')) BETWEEN 10  AND 12  THEN 'Q3 ' || FNCGETFINANCIALYEAR(deal_maturity_date,deal_maturity_date,2)
        WHEN to_number(to_char(deal_maturity_date,'mm')) BETWEEN 1 AND 3 THEN 'Q4 ' || FNCGETFINANCIALYEAR(deal_maturity_date,deal_maturity_date,2)
    END,
  to_char(deal_maturity_date,'MON YYYY'), to_char(deal_maturity_date,'YYYYMM'),
  deal_exchange_rate,0,0,deal_deal_type,2,CASE WHEN deal_buy_sell = 25300002 THEN 1 ELSE 2 END,
  CASE WHEN deal_buy_sell = 25300001 THEN 'HedgeBuy' ELSE 'HedgeSell' END,deal_amount_local
FROM TRTRAN001 WHERE DEAL_RECORD_STATUS BETWEEN 10200001 AND 10200004
AND deal_deal_type NOT IN(25400001);
                          
varOperation  := 'Inserting Settlement Details - Forward Settled data';                          
                          
INSERT INTO TRSYSTEM975
  (MISR_COMPANY_CODE,MISR_LOCATION_CODE,MISR_COUNTER_PARTY,MISR_CURRENCY_CODE,MISR_FOR_CURRENCY,
  MISR_TRANSACTION_TYPE,MISR_BUY_SELL,MISR_TRANSACTION_AMOUNT,MISR_OUSTSNDING_AMOUNT,MISR_REALISED_AMOUNT,
  MISR_EXCHANGE_RATE,MISR_EFFECTIVE_RATE,MISR_INTEREST_RATE,MISR_ASON_DATE,MISR_REFERENCE_DATE,
  MISR_MATURITY_DATE,MISR_REFERENCE_NUMBER,MISR_BANK_REFERENCE,MISR_REMRKS,MISR_ACTUAL_PROJECTED,
  MISR_PORT_FOLIO,MISR_SUBPORT_FOLIO,MISR_EXPAIRY_QUARTER,MISR_EXPAIRY_MONTH,MISR_MONTH_ORDER,
  MISR_SPOT_RATE,MISR_FORWARD_RATE,MISR_MARGIN_RATE,MISR_DEAL_TYPE,MISR_MAIN_ORDER,MISR_SUB_ORDER,
  MISR_DESCRIPTION,MISR_SETTLEMENT_TYPE,MISR_LOCAL_AMOUNT)
SELECT 
  TRAD_COMPANY_CODE,TRAD_LOCATION_CODE,TRAD_LOCAL_BANK, TRAD_TRADE_CURRENCY,TRAD_LOCAL_CURRENCY,
  trad_import_export,DEAL_BUY_SELL,
  cdel_cancel_amount,cdel_cancel_amount,cdel_cancel_amount,
  trad_trade_rate,cdel_cancel_rate,0,Todate,trad_reference_date,
  cdel_cancel_date,trad_trade_reference,NULL,
  'Settled Amount Fwd','Actuals',
  trad_product_category,trad_subproduct_code,
    CASE 
        WHEN to_number(to_char(cdel_cancel_date,'mm')) BETWEEN 4  AND 6  THEN 'Q1 ' || FNCGETFINANCIALYEAR(cdel_cancel_date,cdel_cancel_date,2)
        WHEN to_number(to_char(cdel_cancel_date,'mm')) BETWEEN 7  AND 9  THEN 'Q2 ' || FNCGETFINANCIALYEAR(cdel_cancel_date,cdel_cancel_date,2)
        WHEN to_number(to_char(cdel_cancel_date,'mm')) BETWEEN 10  AND 12  THEN 'Q3 ' || FNCGETFINANCIALYEAR(cdel_cancel_date,cdel_cancel_date,2)
        WHEN to_number(to_char(cdel_cancel_date,'mm')) BETWEEN 1 AND 3 THEN 'Q4 ' || FNCGETFINANCIALYEAR(cdel_cancel_date,cdel_cancel_date,2)
    END,
  to_char(cdel_cancel_date,'MON YYYY'), to_char(cdel_cancel_date,'YYYYMM'),
  deal_exchange_rate,0,0,DEAL_DEAL_TYPE,4,1,
  'Settled Amount Forward',cdel_cancel_type,Round(CDEL_CANCEL_AMOUNT * CDEL_CANCEL_RATE,2)
FROM 
  trtran006,trtran002,trtran001
  WHERE CDEL_TRADE_REFERENCE = TRAD_TRADE_REFERENCE
  AND cdel_deal_number = deal_deal_number
  AND cdel_cancel_date BETWEEN FromDate AND Todate
  and cdel_record_status  between 10200001 and 10200004
  and deal_record_status  between 10200001 and 10200004
  and trad_record_status  between 10200001 and 10200004      
  AND DEAL_DEAL_TYPE NOT IN(25400001)
UNION ALL
SELECT 
  BCRD_COMPANY_CODE,BCRD_LOCATION_CODE,BCRD_LOCAL_BANK, BCRD_CURRENCY_CODE,30400003,
  25900073,DEAL_BUY_SELL,
  cdel_cancel_amount,cdel_cancel_amount,cdel_cancel_amount,
  BCRD_CONVERSION_RATE,cdel_cancel_rate,0,SYSDATE,BCRD_SANCTION_DATE,
  cdel_cancel_date,BCRD_BUYERS_CREDIT,NULL,
  'Settled Amount Fwd','Actuals',
  BCRD_PRODUCT_CATEGORY,BCRD_SUBPRODUCT_CODE,
    CASE 
        WHEN to_number(to_char(cdel_cancel_date,'mm')) BETWEEN 4  AND 6  THEN 'Q1 ' || FNCGETFINANCIALYEAR(cdel_cancel_date,cdel_cancel_date,2)
        WHEN to_number(to_char(cdel_cancel_date,'mm')) BETWEEN 7  AND 9  THEN 'Q2 ' || FNCGETFINANCIALYEAR(cdel_cancel_date,cdel_cancel_date,2)
        WHEN to_number(to_char(cdel_cancel_date,'mm')) BETWEEN 10  AND 12  THEN 'Q3 ' || FNCGETFINANCIALYEAR(cdel_cancel_date,cdel_cancel_date,2)
        WHEN to_number(to_char(cdel_cancel_date,'mm')) BETWEEN 1 AND 3 THEN 'Q4 ' || FNCGETFINANCIALYEAR(cdel_cancel_date,cdel_cancel_date,2)
    END,
  to_char(cdel_cancel_date,'MON YYYY'), to_char(cdel_cancel_date,'YYYYMM'),
  deal_exchange_rate,0,0,DEAL_DEAL_TYPE,4,1,
  'Settled Amount Forward',cdel_cancel_type,Round(CDEL_CANCEL_AMOUNT * CDEL_CANCEL_RATE,2)
FROM 
  trtran006,trtran045,trtran001
  WHERE CDEL_TRADE_REFERENCE = BCRD_BUYERS_CREDIT
  AND cdel_deal_number = deal_deal_number
  AND cdel_cancel_date BETWEEN FromDate AND Todate
  and cdel_record_status  between 10200001 and 10200004
  AND deal_record_status  BETWEEN 10200001 AND 10200004
  AND BCRD_RECORD_STATUS  BETWEEN 10200001 AND 10200004      
  AND DEAL_DEAL_TYPE NOT IN(25400001);
 
varOperation  := 'Inserting Settlement Details - Spot Settled data';  

INSERT INTO TRSYSTEM975
  (MISR_COMPANY_CODE,MISR_LOCATION_CODE,MISR_COUNTER_PARTY,MISR_CURRENCY_CODE,MISR_FOR_CURRENCY,
  MISR_TRANSACTION_TYPE,MISR_BUY_SELL,MISR_TRANSACTION_AMOUNT,MISR_OUSTSNDING_AMOUNT,MISR_REALISED_AMOUNT,
  MISR_EXCHANGE_RATE,MISR_EFFECTIVE_RATE,MISR_INTEREST_RATE,MISR_ASON_DATE,MISR_REFERENCE_DATE,
  MISR_MATURITY_DATE,MISR_REFERENCE_NUMBER,MISR_BANK_REFERENCE,MISR_REMRKS,MISR_ACTUAL_PROJECTED,
  MISR_PORT_FOLIO,MISR_SUBPORT_FOLIO,MISR_EXPAIRY_QUARTER,MISR_EXPAIRY_MONTH,MISR_MONTH_ORDER,
  MISR_SPOT_RATE,MISR_FORWARD_RATE,MISR_MARGIN_RATE,MISR_DEAL_TYPE,MISR_MAIN_ORDER,MISR_SUB_ORDER,
  MISR_DESCRIPTION,MISR_SETTLEMENT_TYPE,MISR_LOCAL_AMOUNT)
SELECT 
  TRAD_COMPANY_CODE,TRAD_LOCATION_CODE,TRAD_LOCAL_BANK, TRAD_TRADE_CURRENCY,TRAD_LOCAL_CURRENCY,
  trad_import_export,DEAL_BUY_SELL,
  cdel_cancel_amount,cdel_cancel_amount,cdel_cancel_amount,
  trad_trade_rate,cdel_cancel_rate,0,Todate,trad_reference_date,
  cdel_cancel_date,trad_trade_reference,NULL,
  'Settled Amount Spot','Actuals',
  trad_product_category,trad_subproduct_code,
    CASE 
        WHEN to_number(to_char(cdel_cancel_date,'mm')) BETWEEN 4  AND 6  THEN 'Q1 ' || FNCGETFINANCIALYEAR(cdel_cancel_date,cdel_cancel_date,2)
        WHEN to_number(to_char(cdel_cancel_date,'mm')) BETWEEN 7  AND 9  THEN 'Q2 ' || FNCGETFINANCIALYEAR(cdel_cancel_date,cdel_cancel_date,2)
        WHEN to_number(to_char(cdel_cancel_date,'mm')) BETWEEN 10  AND 12  THEN 'Q3 ' || FNCGETFINANCIALYEAR(cdel_cancel_date,cdel_cancel_date,2)
        WHEN to_number(to_char(cdel_cancel_date,'mm')) BETWEEN 1 AND 3 THEN 'Q4 ' || FNCGETFINANCIALYEAR(cdel_cancel_date,cdel_cancel_date,2)
    END,
  to_char(cdel_cancel_date,'MON YYYY'), to_char(cdel_cancel_date,'YYYYMM'),
  deal_exchange_rate,0,0,DEAL_DEAL_TYPE,3,1,
  'Settled Amount Spot',cdel_cancel_type,Round(CDEL_CANCEL_AMOUNT * CDEL_CANCEL_RATE,2)
FROM 
  trtran006,trtran002,trtran001
  WHERE CDEL_TRADE_REFERENCE = TRAD_TRADE_REFERENCE
  AND cdel_deal_number = deal_deal_number
  AND cdel_cancel_date BETWEEN FromDate AND Todate
  and cdel_record_status  between 10200001 and 10200004
  and deal_record_status  between 10200001 and 10200004
  and trad_record_status  between 10200001 and 10200004      
  AND DEAL_DEAL_TYPE IN(25400001)
UNION ALL
SELECT 
  BCRD_COMPANY_CODE,BCRD_LOCATION_CODE,BCRD_LOCAL_BANK, BCRD_CURRENCY_CODE,30400003,
  25900073,DEAL_BUY_SELL,
  cdel_cancel_amount,cdel_cancel_amount,cdel_cancel_amount,
  BCRD_CONVERSION_RATE,cdel_cancel_rate,0,Todate,BCRD_SANCTION_DATE,
  cdel_cancel_date,BCRD_BUYERS_CREDIT,NULL,
  'Settled Amount Spot','Actuals',
  BCRD_PRODUCT_CATEGORY,BCRD_SUBPRODUCT_CODE,
    CASE 
        WHEN to_number(to_char(cdel_cancel_date,'mm')) BETWEEN 4  AND 6  THEN 'Q1 ' || FNCGETFINANCIALYEAR(cdel_cancel_date,cdel_cancel_date,2)
        WHEN to_number(to_char(cdel_cancel_date,'mm')) BETWEEN 7  AND 9  THEN 'Q2 ' || FNCGETFINANCIALYEAR(cdel_cancel_date,cdel_cancel_date,2)
        WHEN to_number(to_char(cdel_cancel_date,'mm')) BETWEEN 10  AND 12  THEN 'Q3 ' || FNCGETFINANCIALYEAR(cdel_cancel_date,cdel_cancel_date,2)
        WHEN to_number(to_char(cdel_cancel_date,'mm')) BETWEEN 1 AND 3 THEN 'Q4 ' || FNCGETFINANCIALYEAR(cdel_cancel_date,cdel_cancel_date,2)
    END,
  to_char(cdel_cancel_date,'MON YYYY'), to_char(cdel_cancel_date,'YYYYMM'),
  deal_exchange_rate,0,0,DEAL_DEAL_TYPE,3,1,
  'Settled Amount Spot',cdel_cancel_type,Round(CDEL_CANCEL_AMOUNT * CDEL_CANCEL_RATE,2)
FROM 
  trtran006,trtran045,trtran001
  WHERE CDEL_TRADE_REFERENCE = BCRD_BUYERS_CREDIT
  AND cdel_deal_number = deal_deal_number
  AND cdel_cancel_date BETWEEN FromDate AND Todate
  and cdel_record_status  between 10200001 and 10200004
  AND deal_record_status  BETWEEN 10200001 AND 10200004
  AND BCRD_RECORD_STATUS  BETWEEN 10200001 AND 10200004      
  AND DEAL_DEAL_TYPE IN(25400001);
 
---------------------------------------------FC CNCEL---------------
--    INSERT INTO TRSYSTEM976 
--      (EFFE_COMPANY_CODE,EFFE_AMOUNT_FCY,EFFE_AMOUNT_MTMPL,EFFE_REF_DATE,EFFE_CURRENCY_CODE,EFFE_FOR_CURRENCY,
--      EFFE_CLOSE_DATE,EFFE_ASON_DATE,EFFE_COST_RATE,EFFE_EFFE_RATE,EFFE_TRADE_REFRENCE,EFFE_DEAL_NUMBER, 
--      EFFE_BALANCE_FCY,EFFE_DESCRIPTION,EFFE_CROSS_RATE,EFFE_BUY_SELL,EFFE_BANK_REFERENCE)
--    SELECT DEAL_COMPANY_CODE,CDEL_CANCEL_AMOUNT,CDEL_PROFIT_LOSS,DEAL_EXECUTE_DATE,DEAL_BASE_CURRENCY,DEAL_OTHER_CURRENCY,
--           CDEL_CANCEL_DATE,TO_DATE,DEAL_EXCHANGE_RATE,CDEL_CANCEL_RATE,NULL,DEAL_DEAL_NUMBER,
--           0,'FC CNCEL',0,DEAL_BUY_SELL,DEAL_USER_REFERENCE
--    FROM trtran006,trtran001
--    WHERE CDEL_CANCEL_DATE BETWEEN Frm_date AND To_date
--    AND cdel_deal_number = deal_deal_number
--    and cdel_record_status  between 10200001 and 10200004
--    and deal_record_status  between 10200001 and 10200004
--    --and cdel_cancel_type = 27000001
--    AND DEAL_HEDGE_TRADE = 26000001;
-----------------------------------HEDGE MTM---------------
--    INSERT INTO TRSYSTEM976 
--      (EFFE_COMPANY_CODE,EFFE_AMOUNT_FCY,EFFE_AMOUNT_MTMPL,EFFE_REF_DATE,EFFE_CURRENCY_CODE,EFFE_FOR_CURRENCY,
--      EFFE_CLOSE_DATE,EFFE_ASON_DATE,EFFE_COST_RATE,EFFE_EFFE_RATE,EFFE_TRADE_REFRENCE,EFFE_DEAL_NUMBER, 
--      EFFE_BALANCE_FCY,EFFE_DESCRIPTION,EFFE_CROSS_RATE,EFFE_BUY_SELL,EFFE_BANK_REFERENCE)
--    SELECT COMPANYCODE,balancefcy,MTMPANDLINR,DEALDATE,CURRENCYCODE,OTHERCODE,MATURITY,TO_DATE,EXRATE,M2MRATE,
--        NULL,DEALNUMBER,balancefcy,'CURRENCY FORWARD',0,BUYSELLCODE,Null
--    FROM vewReportForward  WHERE  
--    ((status = 12400001 AND completedate > To_date) or status = 12400002)
--    AND dealdate <= To_date 
--    AND hedgeCode = 26000001;
--    ---------------------------'CURRENCY FUTURE' ---------------------------------
--    INSERT INTO TRSYSTEM976 
--      (EFFE_COMPANY_CODE,EFFE_AMOUNT_FCY,EFFE_AMOUNT_MTMPL,EFFE_REF_DATE,EFFE_CURRENCY_CODE,EFFE_FOR_CURRENCY,
--      EFFE_CLOSE_DATE,EFFE_ASON_DATE,EFFE_COST_RATE,EFFE_EFFE_RATE,EFFE_TRADE_REFRENCE,EFFE_DEAL_NUMBER, 
--      EFFE_BALANCE_FCY,EFFE_DESCRIPTION,EFFE_CROSS_RATE,EFFE_BUY_SELL,EFFE_BANK_REFERENCE)
--    SELECT COMPANYCODE,balancefcy,MTMPANDL,DEALDATE,CURRENCYCODE,OTHERCODE,MATURITY,TO_DATE,EXRATE,M2MRATE,
--        NULL,DEALNUMBER,balancefcy,'CURRENCY FUTURE',0,BUYSELLCODE,Null
--    FROM vewReportFuture  WHERE 
--    ((status = 12400001 AND completedate > To_date) or status = 12400002) AND
--     dealdate <= To_date 
--    UNION
--    SELECT COMPANYCODE,CANCELAMOUNT,PANDLFCY,DEALDATE,CURRENCYCODE,OTHERCODE,MATURITY,TO_DATE,EXRATE,ROUND(CANCELRATE,4),
--        NULL,DEALNUMBER,0,'REALIZED FUTURE',0,BUYSELLCODE,Null
--    FROM vewReportFuture  WHERE 
--    canceldate BETWEEN Frm_date AND To_date;
--    ------------------'CURRENCY OPTION'-------------------
--    INSERT INTO TRSYSTEM976 
--      (EFFE_COMPANY_CODE,EFFE_AMOUNT_FCY,EFFE_AMOUNT_MTMPL,EFFE_REF_DATE,EFFE_CURRENCY_CODE,EFFE_FOR_CURRENCY,
--      EFFE_CLOSE_DATE,EFFE_ASON_DATE,EFFE_COST_RATE,EFFE_EFFE_RATE,EFFE_TRADE_REFRENCE,EFFE_DEAL_NUMBER, 
--      EFFE_BALANCE_FCY,EFFE_DESCRIPTION,EFFE_CROSS_RATE,EFFE_BUY_SELL,EFFE_BANK_REFERENCE)
--    SELECT COPT_COMPANY_CODE,COPT_BASE_AMOUNT,pkgForexProcess.fncGetOptionMTM(copt_deal_number,To_date,'N'),
--        COPT_EXECUTE_DATE,COPT_BASE_CURRENCY,COPT_OTHER_CURRENCY,COPT_MATURITY_DATE,TO_DATE,COPT_LOT_PRICE,0,NULL,COPT_DEAL_NUMBER,
--        COPT_BASE_AMOUNT,'CURRENCY OPTION',0,0,COPT_BANK_REFERENCE
--    FROM trtran071 WHERE COPT_EXECUTE_DATE <= To_date 
--    AND ((copt_PROCESS_COMPLETE = 12400001  AND copt_COMPLETE_DATE >To_date) or copt_PROCESS_COMPLETE = 12400002)
--    AND COPT_RECORD_STATUS IN(10200001,10200002,10200003,10200004)
--    UNION  
--    SELECT COPT_COMPANY_CODE,COPT_BASE_AMOUNT,nvl( Pkgforexprocess.FncgetprofitlossoptnetpANDl(CORV_DEAL_NUMBER,CORV_SERIAL_NUMBER),0),
--        COPT_EXECUTE_DATE,COPT_BASE_CURRENCY,COPT_OTHER_CURRENCY,COPT_MATURITY_DATE,TO_DATE,COPT_LOT_PRICE,0,NULL,COPT_DEAL_NUMBER,
--        COPT_BASE_AMOUNT,'REALIZE OPTION',0,0,COPT_BANK_REFERENCE
--    FROM trtran073,trtran071 
--    WHERE 
--    corv_exercise_date  BETWEEN Frm_date AND To_date
--    AND copt_deal_number = CORV_DEAL_NUMBER --AND COPT_HEDGE_TRADE = 26000001
--    AND CORV_RECORD_STATUS IN(10200001,10200002,10200003,10200004);
--    
--    Update trsystem976 set EFFE_AMOUNT_MTMPL = EFFE_AMOUNT_FCY * (EFFE_COST_RATE - EFFE_EFFE_RATE) WHERE 
--    EFFE_DESCRIPTION IN('OPEN UNHEDGE','FC DELIVERY','CASH SETTLE');
--
--------------------Order Cancelation------------------------------------
--
--      INSERT INTO TRSYSTEM976 
--      (EFFE_COMPANY_CODE,EFFE_AMOUNT_FCY,EFFE_AMOUNT_MTMPL,EFFE_REF_DATE,EFFE_CURRENCY_CODE,EFFE_FOR_CURRENCY,
--      EFFE_CLOSE_DATE,EFFE_ASON_DATE,EFFE_COST_RATE,EFFE_EFFE_RATE,EFFE_TRADE_REFRENCE,EFFE_DEAL_NUMBER, 
--      EFFE_BALANCE_FCY,EFFE_DESCRIPTION,EFFE_CROSS_RATE,EFFE_BUY_SELL,EFFE_BANK_REFERENCE)
--       SELECT 
--        Trad_Company_Code,BREL_REVERSAL_FCY,
--	(BREL_REVERSAL_FCY * TRAD_TRADE_RATE) - (BREL_REVERSAL_FCY * BREL_REVERSAL_RATE),
--	TRAD_REFERENCE_DATE,TRAD_TRADE_CURRENCY,30400003,
--        TRAD_MATURITY_DATE,TO_DATE,TRAD_TRADE_RATE,BREL_REVERSAL_RATE,TRAD_TRADE_REFERENCE,TRAD_TRADE_REFERENCE,
--        0,'ORDER CANCEL',0,
--        CASE WHEN trad_import_export > 25900050 THEN
--          25300001
--        ELSE
--          25300002
--        END,Trad_User_Reference
--        
--        FROM trtran003,
--          trtran002
--        WHERE Brel_Reversal_Type = 25800053
--        AND Brel_Trade_Reference = Trad_Trade_Reference
--        AND Brel_Entry_Date BETWEEN Frm_date AND To_date
--        AND Brel_record_status BETWEEN 10200001 AND 10200004
--        AND trad_record_status BETWEEN 10200001 AND 10200004;
--------------------------------------------------------------------------

commit;
exception 
when others then
    numError := SQLCODE;
    varError := SQLERRM;
    varError := 'NOPData: ' || varMessage || varOperation || varError;
    ROLLBACK;
    raise_application_error(-20101, varError);
rollback;
raise_application_error(-200001,varmsg);
end prcMISReport;
 
 
 
 
/