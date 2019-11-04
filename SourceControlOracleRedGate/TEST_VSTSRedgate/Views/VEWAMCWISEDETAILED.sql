CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewamcwisedetailed (company,navname,transactiontype,transactionrefno,transactiodate,rate,units,trasactionamt,navdate,latestnav,balanceunits,presentvalue,notionalpandl,profitbooked,ageindays,simannualreturn,xirr,asondate) AS
SELECT pkgreturncursor.fncgetdescription(MFTR_COMPANY_CODE,1) AS Company,
    MFSC_SCHEME_NAVNAME                                         AS NAVName,
    pkgreturncursor.fncgetdescription(MFTR_TRANSACTION_TYPE,1)  AS TransactionType,
    mftr_reference_number                                       AS transactionrefno,
    MFTR_reference_DATE                                         AS TransactionDate,
    MFTR_TRANSACTION_PRICE                                      AS Rate,
    MFTR_TRANSACTION_QUANTITY                                   AS Units,
    -1* MFTR_TRANSACTION_AMOUNT                                 AS TransAMt,
    (SELECT MAX(MFMM_REFERENCE_DATE)
    FROM trtran050
    WHERE MFmm_NAV_CODE     =mftr_nav_code
    AND mfmm_record_status IN (10200003 ,10200004)
    AND MFMM_REFERENCE_DATE<=
      (SELECT Fromdate FROM TRSYSTEM981
      )
    ) AS NAVDate,
    pkgfixeddepositproject.fncgetnav(mftr_scheme_code ,
    (SELECT Fromdate FROM TRSYSTEM981
    ),3) AS LatestNAV, --check
    pkgForexProcess.fncGetOutstanding(mftr_reference_number,0,20,1,
    (SELECT Fromdate
    FROM TRSYSTEM981
    )) AS BalancedUnits,--check
    ROUND((pkgfixeddepositproject.fncgetnav(mftr_scheme_code ,
    (SELECT Fromdate FROM TRSYSTEM981
    ),3) * pkgForexProcess.fncGetOutstanding(mftr_reference_number,0,20,1,
    (SELECT Fromdate FROM TRSYSTEM981
    ))),2) AS PresentValue,
    DECODE(pkgForexProcess.fncGetOutstanding(mftr_reference_number,0,20,1,
    (SELECT Fromdate
    FROM TRSYSTEM981
    )),0,0, (ROUND((pkgfixeddepositproject.fncgetnav(mftr_scheme_code ,
    (SELECT Fromdate FROM TRSYSTEM981
    ),3)* pkgForexProcess.fncGetOutstanding(mftr_reference_number,0,20,1,
    (SELECT Fromdate FROM TRSYSTEM981
    ))),2) - pkgForexProcess.fncGetOutstanding(mftr_reference_number,0,20,2,
    (SELECT Fromdate FROM TRSYSTEM981
    ))
    /*MFTR_TRANSACTION_AMOUNT*/
    )) AS NotionalPandL,
    --  pkgfixeddepositproject.fncgetmfgainloss(mftr_reference_number ,(SELECT Fromdate FROM TRSYSTEM981)) as ProfitBooked,
    0 AS ProfitBooked,
    DECODE( pkgForexProcess.fncGetOutstanding(mftr_reference_number,0,20,1,
    (SELECT Fromdate FROM TRSYSTEM981
    )),0 ,0,(
    (SELECT MAX(MFMM_REFERENCE_DATE)
    FROM trtran050
    WHERE MFmm_NAV_CODE     =MFSC_NAV_CODE
    AND MFMM_REFERENCE_DATE<=
      (SELECT Fromdate
      FROM TRSYSTEM981
      )
    ) - MFTR_TRANSACTION_DATE)) AS AgeinDays,
    ROUND((((DECODE(pkgForexProcess.fncGetOutstanding(mftr_reference_number,0,20,2,
    (SELECT Fromdate
    FROM TRSYSTEM981
    )),0,0, --if balance is zero
    (ROUND((pkgfixeddepositproject.fncgetnav(mftr_scheme_code ,
    (SELECT Fromdate FROM TRSYSTEM981
    ),3)* pkgForexProcess.fncGetOutstanding(mftr_reference_number,0,20,1,
    (SELECT Fromdate FROM TRSYSTEM981
    ))),2) - pkgForexProcess.fncGetOutstanding(mftr_reference_number,0,20,2,
    (SELECT Fromdate FROM TRSYSTEM981
    ))
    /*MFTR_TRANSACTION_AMOUNT */
    )) / DECODE(pkgForexProcess.fncGetOutstanding(mftr_reference_number,0,20,2,
    (SELECT Fromdate FROM TRSYSTEM981
    )),0,1, pkgForexProcess.fncGetOutstanding(mftr_reference_number,0,20,2,
    (SELECT Fromdate FROM TRSYSTEM981
    )))
    /*MFTR_TRANSACTION_AMOUNT */
    ) *36500)/DECODE((
    (SELECT MAX(MFMM_REFERENCE_DATE) FROM trtran050 WHERE MFmm_NAV_CODE=MFSC_NAV_CODE
    AND MFMM_REFERENCE_DATE                                           <=
      (SELECT Fromdate FROM TRSYSTEM981
      )
    ) - MFTR_TRANSACTION_DATE),0,1,
    (SELECT MAX(MFMM_REFERENCE_DATE)
    FROM trtran050
    WHERE MFmm_NAV_CODE     =MFSC_NAV_CODE
    AND MFMM_REFERENCE_DATE<=
      (SELECT Fromdate FROM TRSYSTEM981
      )
    ) - MFTR_TRANSACTION_DATE)),2) AS SimAnnualReturn,
    DECODE(pkgForexProcess.fncGetOutstanding(mftr_reference_number,0,20,1,
    (SELECT Fromdate FROM TRSYSTEM981
    )),0,0,pkgfixeddepositproject.fncReturnXIRR(MFTR_SCHEME_CODE,MFTR_REFERENCE_DATE ,
    (SELECT Fromdate FROM TRSYSTEM981
    ) ,mftr_reference_number)) AS XIRR,
    --(SELECT Fromdate FROM TRSYSTEM981) as AsonDate,
    (
    SELECT Fromdate
    FROM TRSYSTEM981
    ) AS Todate --,
  FROM trtran048,
    trmaster404
  WHERE MFTR_SCHEME_CODE=MFSC_SCHEME_CODE
    -- and mftr_nav_code='103340'
    --and MFTR_PROCESS_COMPLETE !=12400001 or mftr_complete_date <=(SELECT Fromdate FROM TRSYSTEM981)
  AND mftr_REFERENCE_DATE <=
    (SELECT Fromdate FROM TRSYSTEM981
    )
  AND MFTR_RECORD_STATUS NOT IN(10200005,10200006)
  UNION
  SELECT pkgreturncursor.fncgetdescription(MFtr_COMPANY_CODE,1) AS Company,
    MFSC_SCHEME_NAVNAME,
    'Sold'                                   AS TransactionType,
    REDM_INVEST_REFERENCE                    AS transactionrefno,
    REDM_TRANSACTION_DATE                    AS TransactionDate,
    REDM_REDEEM_NAV                          AS Rate,
    REDM_NOOF_UNITS                          AS Units,
    ROUND(REDM_REDEEM_NAV*REDM_NOOF_UNITS,2) AS TransAMt,
    NULL                                     AS NAVDate,
    NULL                                     AS LatestNAV,    --check
    NULL                                     AS BalancedUnits,--check
    NULL                                     AS PresentValue,
    NULL                                     AS NotionalPandL,
    --pkgfixeddepositproject.fncgetmfgainloss(MFCL_reference_number ,(SELECT Fromdate FROM TRSYSTEM981)) as ProfitBooked,
    REDM_REDEEM_PANDL                                                                                                                                                                                                         AS ProfitBooked,
    REDM_TRANSACTION_DATE                                            -MFTR_REFERENCE_DATE                                                                                                                                     AS AgeinDays,
    DECODE(TRUNC(redm_invest_amount), 0, 0,ROUND(((REDM_REDEEM_PANDL *36500)/((REDM_TRANSACTION_DATE -MFTR_REFERENCE_DATE) * ROUND(REDM_REDEEM_NAV*REDM_NOOF_UNITS,2))),2))                                                   AS SimAnnualReturn,
    DECODE(pkgForexProcess.fncGetOutstanding(mftr_reference_number,0,20,1,REDM_TRANSACTION_DATE),0,pkgfixeddepositproject.fncReturnXIRR(MFTR_SCHEME_CODE,MFTR_REFERENCE_DATE ,REDM_TRANSACTION_DATE,REDM_INVEST_REFERENCE),0) AS XIRR,
    --(SELECT Fromdate FROM TRSYSTEM981) as AsonDate,
    (
    SELECT Fromdate
    FROM TRSYSTEM981
    ) AS Todate--,
  FROM trtran049A,
    trmaster404,
    trtran048
  WHERE MFtr_SCHEME_CODE=MFSC_SCHEME_CODE
    -- and mftr_nav_code='103340'
  AND REDM_INVEST_REFERENCE=MFTR_REFERENCE_NUMBER
    -- and MFCL_PROCESS_COMPLETE !=12400001
  AND REDM_TRANSACTION_DATE <=
    (SELECT Fromdate FROM TRSYSTEM981
    )
  AND REDM_RECORD_STATUS NOT IN(10200005,10200006)
  ORDER BY 5,4
 
 
 
 
 
 
 
 
 
 ;