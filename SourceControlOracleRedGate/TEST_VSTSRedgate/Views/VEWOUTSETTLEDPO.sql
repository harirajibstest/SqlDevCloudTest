CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewoutsettledpo (company,"CATEGORY",subcategory,agreement,vendor,bank,bankref,duedate,currency,frwdcontractno,amount,settledamt,cashfcy,cashrate,cashininr,frwdfcy,frwdrate,frwdamtinr,edinpaisa,edininr,netrate,netinr,asondate,todate,documentno,category1) AS
SELECT pkgreturncursor.fncgetdescription(trad_company_code,1) AS Company,
    pkgreturncursor.fncgetdescription(trad_product_category,2)  AS CATEGORY,
    pkgreturncursor.fncgetdescription(trad_subproduct_code,2)   AS SubCategory,
    trad_contract_no                                            AS Agreement,
    pkgreturncursor.fncgetdescription(trad_buyer_seller,2)      AS Vendor,
    pkgreturncursor.fncgetdescription(trad_local_bank,2)        AS Bank,
    trad_user_reference                                         AS BankRef,
    trad_maturity_date                                          AS Duedate,
    pkgreturncursor.fncgetdescription(trad_trade_currency,2)    AS Currency,
    trad_contract_no                                            AS FwdContractNo,--rearranged
    trad_trade_fcy                                              AS Amount,
    (b.CashAmount+b.ForwardAmount)                              AS SettledAmt,
    ROUND(b.CashAmount,2)                                       AS CashFCY,--new
    ROUND(b.cashrate,4)                                         AS CashRate,
    --ROUND(b.CashAmount*((b.CashAmount*b.Cashrate)+(b.ForwardAmount*b.Forwardrate)+(b.EdBenifit))/(b.CashAmount+b.ForwardAmount),4) AS CashinINR,
    CASE
      WHEN b.CashAmount <> 0
      THEN ROUND((b.CashAmount * b.cashrate),2)
      ELSE 0
    END                      AS CashinINR,
    ROUND(b.ForwardAmount,2) AS FwdAmt,
    --round(((b.CashAmount*b.Cashrate)+(b.ForwardAmount*b.Forwardrate)+(b.EdBenifit))/(b.CashAmount+b.ForwardAmount),4) as FwdRate,
    CASE
      WHEN b.ForwardAmount <> 0
      THEN ROUND(((b.ForwardAmount*b.Forwardrate))/(b.ForwardAmount),4)
      ELSE 0
    END AS FwdRate,
    --round((((b.CashAmount*b.Cashrate)+(b.ForwardAmount*b.Forwardrate)+(b.EdBenifit))/(b.CashAmount+b.ForwardAmount))*(b.CashAmount+b.ForwardAmount),2) as AmtinINR,
    --DECODE(b.ForwardAmount,0,0,ROUND((((b.ForwardAmount*b.Forwardrate)+(b.EdBenifit))/(b.ForwardAmount))*(b.ForwardAmount),2)) AS AmtinINR,
    DECODE(b.ForwardAmount,0,0,ROUND((((b.ForwardAmount*b.Forwardrate))/(b.ForwardAmount))*(b.ForwardAmount),2)) AS AmtinINR,
    ROUND(b.Edpisa,4)                                                                                            AS EDinPaisa,
    ROUND(b.EdBenifit,2)                                                                                         AS EDINR,
    -- round(b.Edpisa*b.Cancelamt,2) as EdINR,
    --ROUND(b.forwardrate,4)                 AS NetRate,
    CASE
      WHEN b.CashAmount  <> 0
      OR b.ForwardAmount <> 0
      THEN ROUND(((b.forwardrate * b.ForwardAmount) + (b.CashAmount * b.cashrate))/(b.ForwardAmount + b.CashAmount),4)
    END AS NetRate,
    --ROUND(b.forwardrate*b.ForwardAmount,2) AS NetINR,
    ROUND((b.forwardrate * b.ForwardAmount) + (b.CashAmount * b.cashrate),2) AS NetINR,
    b.CancelDate                                                             AS AsonDate,
    (SELECT TODATE FROM trsystem981
    )                        AS TODATE,
    TRAD_PRODUCT_DESCRIPTION AS DOCUMENTNO,
    trad_product_category    AS CATEGORY1
  FROM trtran002 a,
    (SELECT cdel_trade_reference,
      SUM(DECODE(deal_deal_type,25400001,cdel_cancel_amount,0)) CashAmount,
      (SUM(DECODE(deal_deal_type,25400001,cdel_cancel_amount,0)* cdel_cancel_rate) / SUM(DECODE(deal_deal_type,25400001,cdel_cancel_amount,1))) Cashrate,
      SUM((
      CASE
        WHEN deal_deal_type!=25400001
        THEN cdel_cancel_amount
        ELSE 0
      END)) ForwardAmount,
      (SUM( (
      CASE
        WHEN deal_deal_type!=25400001
        THEN cdel_cancel_amount
        ELSE 0
      END)* cdel_cancel_rate) / SUM( (
      CASE
        WHEN deal_deal_type!=25400001
        THEN cdel_cancel_amount
        ELSE 1
      END))) Forwardrate,
      CASE
        WHEN cdel_cancel_type = 27000002
        THEN SUM(CDEL_PROFIT_LOSS)
      END EdBenifit,
      CASE
        WHEN cdel_cancel_type = 27000002
        THEN AVG(deal_exchange_rate-cdel_cancel_rate)
      END Edpisa,
      MAX(CDEL_CANCEL_DATE) AS CancelDate
    FROM trtran001,
      trtran006
    WHERE deal_deal_number      = cdel_deal_number
    AND deal_record_status NOT IN (10200005,10200006)
    AND cdel_record_status NOT IN(10200005,10200006)
    AND CDEL_CANCEL_DATE BETWEEN
      (SELECT FROMDATE FROM trsystem981
      )
    AND (SELECT TODATE FROM trsystem981)
    GROUP BY cdel_trade_reference,
      cdel_cancel_type
    ) b
  WHERE a.trad_trade_reference  = b.cdel_trade_reference
  AND a.trad_record_status NOT IN(10200006)
  AND A.trad_import_export NOT IN(25900025)
  UNION ALL
  SELECT pkgreturncursor.fncgetdescription(BCRD_COMPANY_CODE,1) AS Company,
    pkgreturncursor.fncgetdescription(33300003,2)               AS CATEGORY,
    pkgreturncursor.fncgetdescription(33800003,2)               AS SubCategory,
    (SELECT DISTINCT TRAD_CONTRACT_NO
    FROM TRTRAN010,
      TRTRAN002
    WHERE BCRD_BUYERS_CREDIT = LOLN_LOAN_NUMBER
    AND LOLN_TRADE_REFERENCE = TRAD_TRADE_REFERENCE
    and rownum = 1
    )                                                       AS Agreement,
    pkgreturncursor.fncgetdescription(BCRD_AGENT_CODE,2)    AS Vendor,
    pkgreturncursor.fncgetdescription(BCRD_LOCAL_BANK,2)    AS Bank,
    BCRD_SANCTION_REFERENCE                                 AS BankRef,
    BCRD_DUE_DATE                                           AS Duedate,
    pkgreturncursor.fncgetdescription(BCRD_CURRENCY_CODE,2) AS Currency,
    NULL                                                    AS FwdContractNo,--rearranged
    BCRD_SANCTIONED_FCY                                     AS Amount,
    (b.CashAmount+b.ForwardAmount)                          AS SettledAmt,
    ROUND(b.CashAmount,2)                                   AS CashFCY,--new
    ROUND(b.cashrate,4)                                     AS CashRate,
    CASE
      WHEN b.CashAmount <> 0
      THEN ROUND((b.CashAmount * b.cashrate),2)
      ELSE 0
    END                      AS CashinINR,
    ROUND(b.ForwardAmount,2) AS FwdAmt,
    CASE
      WHEN b.ForwardAmount <> 0
      THEN ROUND(((b.ForwardAmount*b.Forwardrate))/(b.ForwardAmount),4)
      ELSE 0
    END                                                                                                          AS FwdRate,
    DECODE(b.ForwardAmount,0,0,ROUND((((b.ForwardAmount*b.Forwardrate))/(b.ForwardAmount))*(b.ForwardAmount),2)) AS AmtinINR,
    ROUND(b.Edpisa,4)                                                                                            AS EDinPaisa,
    ROUND(b.EdBenifit,2)                                                                                         AS EDINR,
    CASE
      WHEN b.CashAmount  <> 0
      OR b.ForwardAmount <> 0
      THEN ROUND(((b.forwardrate * b.ForwardAmount) + (b.CashAmount * b.cashrate))/(b.ForwardAmount + b.CashAmount),4)
    END                                                                      AS NetRate,
    ROUND((b.forwardrate * b.ForwardAmount) + (b.CashAmount * b.cashrate),2) AS NetINR,
    b.CancelDate                                                             AS AsonDate,
    (SELECT TODATE FROM trsystem981
    )        AS TODATE,
    NULL     AS DOCUMENTNO,
    33300003 AS CATEGORY1
  FROM trtran045 a,
    (SELECT cdel_trade_reference,
      SUM(DECODE(deal_deal_type,25400001,cdel_cancel_amount,0)) CashAmount,
      (SUM(DECODE(deal_deal_type,25400001,cdel_cancel_amount,0)* cdel_cancel_rate) / SUM(DECODE(deal_deal_type,25400001,cdel_cancel_amount,1))) Cashrate,
      SUM((
      CASE
        WHEN deal_deal_type!=25400001
        THEN cdel_cancel_amount
        ELSE 0
      END)) ForwardAmount,
      (SUM( (
      CASE
        WHEN deal_deal_type!=25400001
        THEN cdel_cancel_amount
        ELSE 0
      END)* cdel_cancel_rate) / SUM( (
      CASE
        WHEN deal_deal_type!=25400001
        THEN cdel_cancel_amount
        ELSE 1
      END))) Forwardrate,
      CASE
        WHEN cdel_cancel_type = 27000002
        THEN SUM(CDEL_PROFIT_LOSS)
      END EdBenifit,
      CASE
        WHEN cdel_cancel_type = 27000002
        THEN AVG(deal_exchange_rate-cdel_cancel_rate)
      END Edpisa,
      MAX(CDEL_CANCEL_DATE) AS CancelDate
    FROM trtran001,
      trtran006
    WHERE deal_deal_number      = cdel_deal_number
    AND deal_record_status NOT IN (10200005,10200006)
    AND cdel_record_status NOT IN(10200005,10200006)
    AND CDEL_CANCEL_DATE BETWEEN
      (SELECT FROMDATE FROM trsystem981
      )
    AND (SELECT TODATE FROM trsystem981)
    GROUP BY cdel_trade_reference,
      cdel_cancel_type
    ) b
  WHERE a.BCRD_BUYERS_CREDIT    = b.cdel_trade_reference
  AND A.BCRD_RECORD_STATUS NOT IN(10200006)
  UNION ALL
  SELECT pkgreturncursor.fncgetdescription(trad_company_code,1) AS Company,
    pkgreturncursor.fncgetdescription(trad_product_category,2)  AS CATEGORY,
    pkgreturncursor.fncgetdescription(trad_subproduct_code,2)   AS SubCategory,
    trad_contract_no                                            AS Agreement,
    pkgreturncursor.fncgetdescription(trad_buyer_seller,2)      AS Vendor,
    pkgreturncursor.fncgetdescription(trad_local_bank,2)        AS Bank,
    trad_user_reference                                         AS BankRef,
    trad_maturity_date                                          AS Duedate,
    pkgreturncursor.fncgetdescription(trad_trade_currency,2)    AS Currency,
    NULL                                                        AS FwdContractNo,--rearranged
    trad_trade_fcy                                              AS Amount,
    LOLN_ADJUSTED_FCY                                           AS SettledAmt,
    0                                                           AS CashFCY,--new
    0                                                           AS CashRate,
    0                                                           AS CashinINR,
    0                                                           AS FwdAmt,
    0                                                           AS FwdRate,
    0                                                           AS AmtinINR,
    0                                                           AS EDinPaisa,
    0                                                           AS EDINR,
    BCRD_SPOT_RATE                                              AS NetRate,
    LOLN_ADJUSTED_FCY * BCRD_SPOT_RATE                          AS NetINR,
    loln_adjusted_date                                          AS AsonDate,
    (SELECT TODATE FROM trsystem981
    )                     AS TODATE,
    TRAD_PRODUCT_DESCRIPTION  AS DOCUMENTNO,
    trad_product_category AS CATEGORY1
  FROM trtran002,
    trtran003,
    trtran010,
    TRTRAN045
  WHERE trad_trade_reference  = brel_trade_reference
  AND brel_trade_reference    = loln_trade_reference
  AND trad_record_status NOT IN(10200006)
  AND trad_import_export NOT IN(25900025)
  AND brel_record_status NOT IN(10200006)
  AND LOLN_RECORD_STATUS BETWEEN 10200001 AND 10200004
  AND LOLN_LOAN_NUMBER = BCRD_BUYERS_CREDIT
  AND BCRD_RECORD_STATUS BETWEEN 10200001 AND 10200004
  AND BREL_ENTRY_DATE BETWEEN
    (SELECT FROMDATE FROM trsystem981
    )
  AND (SELECT TODATE FROM trsystem981)
  ORDER BY 26;