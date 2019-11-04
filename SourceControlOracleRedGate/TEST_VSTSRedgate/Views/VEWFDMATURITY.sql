CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewfdmaturity (company,fdno,srno,netamt,currentdate,principalamt,interestamt,tdsamt,netinterest,checker,roi,additionalint,tenureindays,opendate,closuredate,maturitydate,bank,remarks,creditacno,ratebooked,closuretype,asondate,todate) AS
SELECT pkgreturncursor.fncgetdescription(FDCL_COMPANY_CODE,1)                                                                                                        AS Company,
    FDCL_BANK_REFERENCE                                                                                                                                                AS FDNo,
    FDCL_FD_NUMBER                                                                                                                                                     AS SrNo,
    (FDCL_DEPOSIT_AMOUNT+fdcl_int_paidamt )                                                                                                                            AS NetAmt,
    FDCL_TRANSACTION_DATE                                                                                                                                              AS CurrentDate,
    FDCL_DEPOSIT_AMOUNT                                                                                                                                                AS PrincipalAmt,
    FDCL_INTEREST_AMOUNT                                                                                                                                               AS InterestAmt,
    (FDCL_INTEREST_AMOUNT-FDCL_INT_PAIDAMT)                                                                                                                            AS TDSAmt,
    FDCL_INT_PAIDAMT                                                                                                                                                   AS NetinterestAmt,
    (DECODE(SIGN((FDCL_INTEREST_AMOUNT-FDCL_INT_PAIDAMT) -(FDCL_INTEREST_AMOUNT *0.1)) , 1,(FDCL_INTEREST_AMOUNT-FDCL_INT_PAIDAMT) -(FDCL_INTEREST_AMOUNT *0.1) , 0) ) AS checker,
    FDCL_INTEREST_RATE                                                                                                                                                 AS RateofInterest,
    FDCL_PENAL_INTEREST           +FDCL_ADDTIONAL_INTEREST                                                                                                                       AS AdditionalInterest,
    DECODE(SIGN(FDCL_MATURITY_DATE-FDCL_CLOSURE_DATE),-1,(FDCL_CLOSURE_DATE- FDCL_REFERENCE_DATE),(FDCL_MATURITY_DATE-FDCL_REFERENCE_DATE))                                      AS Days,
    FDCL_REFERENCE_DATE                                                                                                                                                          AS OpenDate , --ValueDate
    FDCL_CLOSURE_DATE                                                                                                                                                            AS ClosureDate,
    FDRF_MATURITY_DATE                                                                                                                                                           AS MaturityDate,
    pkgreturncursor.fncgetdescription(FDCL_LOCAL_BANK,2)                                                                                                                         AS Bank,
    FDCL_USER_REMARKS                                                                                                                                                            AS Remarks,
    FDRF_CREDIT_ACNO                                                                                                                                                             AS CreditACNo,
    FDRF_INTEREST_RATE                                                                                                                                                           AS Ratebooked ,
    pkgreturncursor.fncgetdescription(Fdcl_Closure_Type,1)                                                                                                                       AS ClosureType,
    (SELECT Fromdate FROM TRSYSTEM981
    ) AS AsonDate,
    (SELECT Fromdate FROM TRSYSTEM981
    ) AS Todate
  FROM trtran047,
    trtran047a
  WHERE FDRF_FD_NUMBER=FDCL_FD_NUMBER
    -- -- and FDCL_PROCESS_COMPLETE in(12400001)
  AND FDCL_CLOSURE_DATE BETWEEN
    (SELECT Fromdate FROM TRSYSTEM981
    )
  AND (SELECT ToDate FROM TRSYSTEM981)
  AND FDRF_RECORD_STATUS NOT IN(10200005,10200006)
  AND FDCL_RECORD_STATUS NOT IN(10200005,10200006)
  ORDER BY FDCL_FD_NUMBER,
    FDCL_CLOSURE_DATE
 
 
 
 
 
 
 
 
 
 ;