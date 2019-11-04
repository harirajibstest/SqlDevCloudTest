CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewloans (invoicenumber,referencedate,bankreference,sanctiondate,buyercode,currencycode,bankcode,amountfcy,rate,amountinr,liborrate,spread,interestrate,duedate,remarks,loantype,companycode,ibsreference) AS
SELECT Inln_Invoice_Number Invoicenumber,
    Inln_Reference_Date Referencedate,
    Inln_Bank_Reference Bankreference,
    Inln_Sanction_Date Sanctiondate,
    --Pkgreturncursor.Fncgetdescription(inln_invoice_number,2)Buyercode,
    NULL Buyercode,--Need to check for this field
    --pkgtreasury.fncGetBuyerCode(inln_invoice_number) BuyerCode,
    (
    SELECT Pkgreturncursor.Fncgetdescription(bnkc_currency_code,2)
      --pkgtreasury.fncgetPickTreasuryCode(bnkc_currency_code)
    FROM tftran021
    WHERE bnkc_invoice_number   =inln_invoice_number
    AND Bnkc_Record_Status NOT IN(10200005,10200006)
    ) Currencycode,
    (SELECT Pkgreturncursor.Fncgetdescription(bnkc_local_bank,2)
      --pkgtreasury.fncgetPickTreasuryCode(bnkc_local_bank)
    FROM tftran021
    WHERE bnkc_invoice_number   =inln_invoice_number
    AND Bnkc_Record_Status NOT IN(10200005,10200006)
    ) Bankcode,
    Pkgreturnreport.Fncreturnbalanceamnt(Inln_Invoice_Number,Inln_Psloan_Number,23600005,Sysdate,1) AS Amountfcy, --PSCFC
    --Inln_Sanctioned_Fcy AS Amountfcy,---Once Query Final using  Above code for Outstanding Amount
    Inln_Card_Rate Cardrate,
    Inln_Sanctioned_Inr Amountinr,
    Inln_Libor_Rate Liborrate,
    Inln_Interest_Spread Spread,
    Inln_Interest_Rate Interestrate,
    Inln_Due_Date Duedate,
    Inln_User_Remarks Remarks,
    Inln_Loan_Type Loantype, --If Loan type = 23600005 then  PSCFC and Type = 23600003  PSL-RF
    Inln_Company_Code CompanyCode,
    Inln_Invoice_Number IBSReference
  FROM tftran022
  WHERE inln_loan_type        IN (23600005,23600003)
  AND (inln_process_complete   =12400002
  OR (inln_process_complete    =12400001
  AND inln_completion_date     >'01-jul-2014'))
  AND inln_record_status NOT  IN(10200005,10200006)
  AND inln_invoice_number NOT IN
    (SELECT ICRY_INVOICE_NUMBER
    FROM Tftran022a
    WHERE Icry_Record_Status NOT IN(10200005,10200006)
    )
  UNION ALL/*-------------PCFC-------------------------------------------*/
  SELECT pkcr_pkgcredit_number ReferenceNumber,
    Pkcr_Sanction_Date Referencedate,
    Pkcr_Bank_Reference Bankreference,
    Pkcr_Sanction_Date Sanctiondate,
    NULL Buyercode,
    --pkgtreasury.fncgetPickTreasuryCode(pkcr_currency_code) CurrencyCode,
    Pkgreturncursor.Fncgetdescription(Pkcr_Currency_Code,2) Currencycode,
    Pkgreturncursor.Fncgetdescription(Pkcr_Local_Bank,2) Bankcode,
    pkgReturnreport.fncReturnBalanceAmnt(pkcr_pkgcredit_number,0,23600002,Sysdate,1) AS Amountfcy, --PCFC loan type
    --PKCR_SANCTIONED_FCY AS Amountfcy, --Need to change logic
    Pkcr_Conversion_Rate Rate,
    pkcr_sanctioned_inr AmountInr,
    Pkcr_Libor_Rate Liborrate,
    Pkcr_Interest_Spread Spread,
    pkcr_interest_rate interestrate,
    Pkcr_Due_Date Duedate,
    pkcr_loan_remarks remarks,
    23600002 Loantype, --PCFC
    Pkcr_Company_Code CompanyCode,
    pkcr_pkgcredit_number IBSReference
  FROM tftran025
  WHERE pkcr_process_complete =12400002
  AND pkcr_record_status NOT IN(10200005,10200006)
  UNION ALL/*------------------------BuyersCredit------------------------------*/
  SELECT BCRD_BUYERS_CREDIT ReferenceNumber,
    Bcrd_Request_Date Referencedate,
    Bcrd_Sanction_Reference Bankreference,
    Bcrd_Sanction_Date Sanctiondate,
    NULL Buyercode,
    Pkgreturncursor.Fncgetdescription(Bcrd_Currency_Code,2) Currencycode,
    Pkgreturncursor.Fncgetdescription(Bcrd_Local_Bank,2) Bankcode,
    Pkgmastermaintenance.Fncreturnbalance(Bcrd_Buyers_Credit,0, 23600006,Sysdate,1) AS Amountfcy, -- BuyersCredit
    --BCRD_SANCTIONED_FCY AS AmountFCY,--nEED TO CHANGE
    Bcrd_Conversion_Rate Rate,
    BCRD_SANCTIONED_INR AmountInr,
    Bcrd_Libor_Rate Liborrate,
    BCRD_INTEREST_SPREAD spread,
    BCRD_INTEREST_RATE interestrate,
    Bcrd_Due_Date Duedate,
    Bcrd_Loan_Remarks Remarks,
    23600006 Loantype, --Buyers  Credit
    Bcrd_Company_Code CompanyCode,
    BCRD_BUYERS_CREDIT IBSReference
  FROM tftran046
  WHERE Bcrd_Process_Complete =12400002
  AND BCRD_RECORD_STATUS NOT IN(10200005,10200006)
 
 
 
 
 
 
 ;