CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewmfinvestmaneworking (company,schemename,foliono,transactionrefno,transactiondate,transactiontype,amount,units,balanceunits,rate,sttamt,purchasetype,transactioncharge,realizedcharge,unrealizedcharge,asondate) AS
SELECT pkgreturncursor.fncgetdescription(MFSC_COMPANY_CODE,1)                 AS Company,
    MFSC_SCHEME_NAVNAME                                                         AS SchemeName,
    MFSC_FOLIO_NUMBER                                                           AS FolioNo,
    MFTR_REFERENCE_NUMBER                                                       AS transactionrefno,
    MFTR_TRANSACTION_DATE                                                       AS TransDate,
    pkgreturncursor.fncgetdescription(MFTR_TRANSACTION_TYPE,1)                  AS TransactionType,
    -1* MFTR_TRANSACTION_AMOUNT                                                 AS Amount,
    MFTR_TRANSACTION_QUANTITY                                                   AS Units,
    pkgForexProcess.fncGetOutstanding(mftr_nav_code,0,19,1,mftr_reference_date) AS BalanceUnits,--check
    MFTR_TRANSACTION_PRICE                                                      AS Rate,
    'NA'                                                                        AS STTAmt,
    'Reinvest'                                                                  AS PurchaseType,
    'NA'                                                                        AS TransCharge,
    '0'                                                                         AS RealizedProfit,
    0                                                                           AS UnRealizedProfit,
    (SELECT Fromdate FROM TRSYSTEM981
    ) AS ToDate
  FROM trtran048,
    trmaster404
  WHERE MFTR_SCHEME_CODE=MFSC_SCHEME_CODE
    --and MFTR_PROCESS_COMPLETE !=12400001 or mftr_complete_date <=(SELECT Fromdate FROM TRSYSTEM981)
  AND mftr_REFERENCE_DATE <=
    (SELECT Fromdate FROM TRSYSTEM981
    )
  AND MFTR_RECORD_STATUS NOT IN(10200005,10200006)
  UNION
  SELECT pkgreturncursor.fncgetdescription(MIN(MFSC_COMPANY_CODE),1)              AS Company,
    MIN( MFSC_SCHEME_NAVNAME)                                                     AS SchemeName,
    MIN(MFSC_FOLIO_NUMBER)                                                        AS FolioNo,
    REDM_REDEMPTION_REFERENCE                                                     AS transactionrefno,
    REDM_TRANSACTION_DATE                                                         AS TransDate,
    'Sold'                                                                        AS TransactionType,
    SUM(ROUND(REDM_REDEEM_NAV*REDM_NOOF_UNITS,2))                                 AS Amount,
    SUM(REDM_NOOF_UNITS)                                                          AS Units,
    pkgForexProcess.fncGetOutstanding(mftr_nav_code,0,19,1,REDM_TRANSACTION_DATE) AS BalanceUnits,--check
    MIN(REDM_REDEEM_NAV)                                                          AS Rate,
    'NA'                                                                          AS STTAmt,
    'NA'                                                                          AS PurchaseType,
    'NA'                                                                          AS TransCharge,
    '0'                                                                           AS RealizedProfit,
    0                                                                             AS UnRealizedProfit,
    (SELECT Fromdate FROM TRSYSTEM981
    ) AS ToDate
  FROM trtran049A,
    trmaster404,
    trtran048
  WHERE MFtr_SCHEME_CODE    =MFSC_SCHEME_CODE
  AND REDM_INVEST_REFERENCE =MFTR_REFERENCE_NUMBER
  AND mftr_reference_date  <=
    (SELECT Fromdate FROM TRSYSTEM981
    )
  AND REDM_TRANSACTION_DATE <=
    (SELECT Fromdate FROM TRSYSTEM981
    )
  AND mftr_record_status NOT IN (10200005,10200006)
    -- and MFCL_PROCESS_COMPLETE !=12400001
  AND REDM_RECORD_STATUS NOT IN(10200005,10200006)
  GROUP BY mftr_nav_code,
    REDM_REDEMPTION_REFERENCE,
    REDM_TRANSACTION_DATE
  UNION
  SELECT pkgreturncursor.fncgetdescription(MFSC_COMPANY_CODE,1) AS Company,
    MFSC_SCHEME_NAVNAME                                         AS SchemeName,
    MFSC_FOLIO_NUMBER                                           AS FolioNo,
    NULL                                                        AS transactionrefno,
    (SELECT Fromdate
    FROM TRSYSTEM981
    )                  AS TransDate,
    'Current Position' AS TransactionType,
    ROUND( pkgfixeddepositproject.fncgetnav(MFSC_SCHEME_CODE ,
    (SELECT Fromdate FROM TRSYSTEM981
    ),2)*pkgForexProcess.fncGetOutstanding(MFSC_NAV_CODE,0,19,1,
    (SELECT Fromdate FROM TRSYSTEM981
    )) ,2) AS Amount,
    NULL   AS Units,
    pkgForexProcess.fncGetOutstanding(MFSC_NAV_CODE,0,19,1,
    (SELECT Fromdate FROM TRSYSTEM981
    )) AS BalanceUnits,--check
    pkgfixeddepositproject.fncgetnav(MFSC_SCHEME_CODE ,
    (SELECT Fromdate FROM TRSYSTEM981
    ),2)       AS Rate,
    'NA'       AS STTAmt,
    'Reinvest' AS PurchaseType,
    'NA'       AS TransCharge,
    'XIRR'     AS RealizedProfit,
    pkgfixeddepositproject.fncReturnXIRR(MFSC_SCHEME_CODE,to_date('01/01/2010' ,'dd/mm/yyyy') ,
    (SELECT Fromdate FROM TRSYSTEM981
    )) AS UnRealizedProfit,
    (SELECT Fromdate FROM TRSYSTEM981
    ) AS ToDate
  FROM trmaster404
  WHERE MFSC_SCHEME_CODE IN
    (SELECT a.mftr_scheme_code
    FROM trtran048 a
    WHERE MFSC_SCHEME_CODE     =a.mftr_scheme_code
    AND a.mftr_reference_date <=
      (SELECT Fromdate FROM TRSYSTEM981
      )
    AND a.mftr_record_status NOT IN (10200005,10200006)
    )
  AND MFsc_RECORD_STATUS NOT IN(10200005,10200006)
    -- and MFSC_ADD_DATE<=(SELECT Fromdate FROM TRSYSTEM981)
  ORDER BY 5
 
 
 
 
 
 
 
 
 
 ;