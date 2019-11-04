CREATE OR REPLACE PROCEDURE "TEST_VSTSRedgate"."PRCDERIVATIVESPORTFOLIO" 
(Fromdate date,Todate date)
as
  unhedgeamt  number (15,2);
  hedgeamt    number (15,2);
  frwdrate    number (15,6);
  sptbookrate number (15,6);
  
  numError number(15,2);
  slno     number(8);
  recno    number(8) := 0; 
  ncount number(8) :=0;
  
begin
delete from TRSYSTEM977;
---Import Section - Recno - 1
---Invoice --slno - 1
    -- counting records from trtran002 for invoice
      SELECT count(*) into ncount FROM TRTRAN002 
                        where ((TRAD_PROCESS_COMPLETE = 12400001  and TRAD_COMPLETE_DATE > Fromdate ) or TRAD_PROCESS_COMPLETE = 12400002)and TRAD_IMPORT_EXPORT > 25900050;
      
      if ncount != 0 then
            insert into TRSYSTEM977
      (OPENAMOUNT,HEDGEAMOUNT,INVOICEAMOUNT,FORWARDRATE,INVOICERATE,SPOTBOOKING,SPOTRATE,TRADECURRENCY,
       COMPANYCODE,LOCALBANK,IMPORTEXPORT,REFERENCENO,Matdate,ExecDate,Rec_no,SLno,Open_balance)
      (SELECT pkgforexprocess.fncGetOutstanding(TRAD_TRADE_REFERENCE,0,0,1,Fromdate),0,TRAD_TRADE_FCY,0,TRAD_TRADE_RATE,0,
       TRAD_SPOT_RATE,TRAD_TRADE_CURRENCY,TRAD_COMPANY_CODE, TRAD_LOCAL_BANK,  TRAD_IMPORT_EXPORT, TRAD_TRADE_REFERENCE,TRAD_MATURITY_DATE,TRAD_ENTRY_DATE,1,1,pkgforexprocess.fncGetOutstanding(TRAD_TRADE_REFERENCE,0,0,1,Fromdate)
      FROM TRTRAN002 where ((TRAD_PROCESS_COMPLETE = 12400001  and TRAD_COMPLETE_DATE > Fromdate ) or TRAD_PROCESS_COMPLETE = 12400002)and TRAD_IMPORT_EXPORT > 25900050)  ;
      else
            -- for currency code = 30400002 -usd
            insert into TRSYSTEM977
        (OPENAMOUNT,HEDGEAMOUNT,INVOICEAMOUNT,FORWARDRATE,INVOICERATE,SPOTBOOKING,SPOTRATE,TRADECURRENCY,
       COMPANYCODE,LOCALBANK,IMPORTEXPORT,REFERENCENO,Matdate,ExecDate,Rec_no,SLno)
      values (0,0,0,0,0,0,
       0,30400002,0, 0,0, 0,'','',1,1);
            -- for currency code = 30400004 -euro
               insert into TRSYSTEM977
        (OPENAMOUNT,HEDGEAMOUNT,INVOICEAMOUNT,FORWARDRATE,INVOICERATE,SPOTBOOKING,SPOTRATE,TRADECURRENCY,
       COMPANYCODE,LOCALBANK,IMPORTEXPORT,REFERENCENO,Matdate,ExecDate,Rec_no,SLno)
      values (0,0,0,0,0,0,
       0,30400004,0, 0,0, 0,'','',1,1);
      end if;
      ncount :=0;
--Deals - slno - 2 - Buying
    select count(*) into ncount from trtran001 where  ((DEAL_PROCESS_COMPLETE = 12400001  and DEAL_COMPLETE_DATE > Fromdate ) or DEAL_PROCESS_COMPLETE = 12400002)and DEAL_BUY_SELL = 25300001;
 --   if ncount != 0 then
            insert into TRSYSTEM977
              (OPENAMOUNT,HEDGEAMOUNT,INVOICEAMOUNT,FORWARDRATE,INVOICERATE,SPOTBOOKING,SPOTRATE,TRADECURRENCY,
               COMPANYCODE,LOCALBANK,IMPORTEXPORT,REFERENCENO,Matdate,ExecDate,HEDGSALE,Rec_no,SLno,Open_balance)
              (SELECT pkgForexProcess.fncGetOutstanding(deal_deal_number, deal_serial_number,1,1,Fromdate),DEAL_BASE_AMOUNT,0,DEAL_EXCHANGE_RATE,0,DEAL_SPOT_RATE,
               0,DEAL_BASE_CURRENCY,DEAL_COMPANY_CODE, DEAL_COUNTER_PARTY,  0, DEAL_DEAL_NUMBER,DEAL_MATURITY_DATE,DEAL_EXECUTE_DATE,DEAL_BUY_SELL,1,2,(pkgForexProcess.fncGetOutstanding(deal_deal_number, deal_serial_number,1,1,Fromdate) *-1)
              FROM TRTRAN001 where ((DEAL_PROCESS_COMPLETE = 12400001  and DEAL_COMPLETE_DATE > Fromdate ) or DEAL_PROCESS_COMPLETE = 12400002)and DEAL_BUY_SELL = 25300001) ;
 --     else
             --for currency = 30400002 usd
                 insert into TRSYSTEM977
              (OPENAMOUNT,HEDGEAMOUNT,INVOICEAMOUNT,FORWARDRATE,INVOICERATE,SPOTBOOKING,SPOTRATE,TRADECURRENCY,
               COMPANYCODE,LOCALBANK,IMPORTEXPORT,REFERENCENO,Matdate,ExecDate,HEDGSALE,Rec_no,SLno)
              values (0,0,0,0,0,0,
               0,30400002,0, 0,  0, 0,'','',25300001,1,2) ; 
               --for currency = 30400004 euro
                  insert into TRSYSTEM977
              (OPENAMOUNT,HEDGEAMOUNT,INVOICEAMOUNT,FORWARDRATE,INVOICERATE,SPOTBOOKING,SPOTRATE,TRADECURRENCY,
               COMPANYCODE,LOCALBANK,IMPORTEXPORT,REFERENCENO,Matdate,ExecDate,HEDGSALE,Rec_no,SLno)
              values (0,0,0,0,0,0,
               0,30400004,0, 0,  0, 0,'','',25300001,1,2) ; 
 --      end if;
--Buyers Credit slno- 3--merging it with orders sr 1
    ncount :=0;
    
    select count(*) into ncount from trtran045 where  ((BCRD_PROCESS_COMPLETE = 12400001  and BCRD_COMPLETION_DATE > Fromdate ) or BCRD_PROCESS_COMPLETE = 12400002);
    if ncount!=0 then
    insert into TRSYSTEM977
      (OPENAMOUNT,HEDGEAMOUNT,INVOICEAMOUNT,FORWARDRATE,INVOICERATE,SPOTBOOKING,SPOTRATE,TRADECURRENCY,
       COMPANYCODE,LOCALBANK,IMPORTEXPORT,REFERENCENO,Matdate,ExecDate,Rec_no,SLno,Open_balance)
      (SELECT pkgforexprocess.fncGetOutstanding(BCRD_SANCTIONED_FCY,0,0,1,Fromdate),0,BCRD_SANCTIONED_FCY,0,BCRD_CONVERSION_RATE,0,
       0,BCRD_CURRENCY_CODE,BCRD_COMPANY_CODE, BCRD_LOCAL_BANK,  0, BCRD_BUYERS_CREDIT,BCRD_DUE_DATE,BCRD_SANCTION_DATE,1,1,pkgforexprocess.fncGetOutstanding(BCRD_SANCTIONED_FCY,0,0,1,Fromdate)
      FROM TRTRAN045 where ((BCRD_PROCESS_COMPLETE = 12400001  and BCRD_COMPLETION_DATE > Fromdate ) or BCRD_PROCESS_COMPLETE = 12400002));
      else
      --for currency = 30400002 usd
      insert into trsystem977
      (OPENAMOUNT,HEDGEAMOUNT,INVOICEAMOUNT,FORWARDRATE,INVOICERATE,SPOTBOOKING,SPOTRATE,TRADECURRENCY,
       COMPANYCODE,LOCALBANK,IMPORTEXPORT,REFERENCENO,Matdate,ExecDate,Rec_no,SLno)
       Values (0,0,0,0,0,0,
               0,30400002,0, 0,  0, 0,'','',1,1);
      -- for currency = 30400004 euro
               insert into trsystem977
      (OPENAMOUNT,HEDGEAMOUNT,INVOICEAMOUNT,FORWARDRATE,INVOICERATE,SPOTBOOKING,SPOTRATE,TRADECURRENCY,
       COMPANYCODE,LOCALBANK,IMPORTEXPORT,REFERENCENO,Matdate,ExecDate,Rec_no,SLno)
       Values (0,0,0,0,0,0,
               0,30400004,0, 0,  0, 0,'','',1,1);
      end if;
      
      ncount := 0;
--Export Section - Recn no - 2      
---Invoice --slno - 4
    select count(*) into ncount from trtran002 where  ((TRAD_PROCESS_COMPLETE = 12400001  and TRAD_COMPLETE_DATE > Fromdate ) or TRAD_PROCESS_COMPLETE = 12400002)and TRAD_IMPORT_EXPORT < 25900050;
    
    if ncount != 0 then
                    insert into TRSYSTEM977
                      (OPENAMOUNT,HEDGEAMOUNT,INVOICEAMOUNT,FORWARDRATE,INVOICERATE,SPOTBOOKING,SPOTRATE,TRADECURRENCY,
                       COMPANYCODE,LOCALBANK,IMPORTEXPORT,REFERENCENO,Matdate,ExecDate,Rec_no,SLno,Open_balance)
                      (SELECT pkgforexprocess.fncGetOutstanding(TRAD_TRADE_REFERENCE,0,0,1,Fromdate),0,TRAD_TRADE_FCY,0,TRAD_TRADE_RATE,0,
                       TRAD_SPOT_RATE,TRAD_TRADE_CURRENCY,TRAD_COMPANY_CODE, TRAD_LOCAL_BANK,  TRAD_IMPORT_EXPORT, TRAD_TRADE_REFERENCE,TRAD_MATURITY_DATE,TRAD_ENTRY_DATE,2,4,pkgforexprocess.fncGetOutstanding(TRAD_TRADE_REFERENCE,0,0,1,Fromdate)
                      FROM TRTRAN002 where ((TRAD_PROCESS_COMPLETE = 12400001  and TRAD_COMPLETE_DATE > Fromdate ) or TRAD_PROCESS_COMPLETE = 12400002)and TRAD_IMPORT_EXPORT < 25900050)  ;
      else
                    -- for currency usd
                    insert into TRSYSTEM977
                   (OPENAMOUNT,HEDGEAMOUNT,INVOICEAMOUNT,FORWARDRATE,INVOICERATE,SPOTBOOKING,SPOTRATE,TRADECURRENCY,
                   COMPANYCODE,LOCALBANK,IMPORTEXPORT,REFERENCENO,Matdate,ExecDate,Rec_no,SLno)
                   Values (0,0,0,0,0,0,
                           0,30400002,0, 0,  0, 0,'','',2,4);
                   -- for currency euro
                   insert into TRSYSTEM977
                   (OPENAMOUNT,HEDGEAMOUNT,INVOICEAMOUNT,FORWARDRATE,INVOICERATE,SPOTBOOKING,SPOTRATE,TRADECURRENCY,
                   COMPANYCODE,LOCALBANK,IMPORTEXPORT,REFERENCENO,Matdate,ExecDate,Rec_no,SLno)
                   Values (0,0,0,0,0,0,
                           0,30400002,0, 0,  0, 0,'','',2,4);
      end if ; 
      
      ncount := 0;
--Deals - slno - 5 - Selling
    select count(*) into ncount from trtran001 where  ((DEAL_PROCESS_COMPLETE = 12400001  and DEAL_COMPLETE_DATE > Fromdate ) or DEAL_PROCESS_COMPLETE = 12400002)and DEAL_BUY_SELL = 25300002;
    
 --   if ncount !=0 then
    insert into TRSYSTEM977
      (OPENAMOUNT,HEDGEAMOUNT,INVOICEAMOUNT,FORWARDRATE,INVOICERATE,SPOTBOOKING,SPOTRATE,TRADECURRENCY,
       COMPANYCODE,LOCALBANK,IMPORTEXPORT,REFERENCENO,Matdate,ExecDate,HEDGSALE,Rec_no,SLno,Open_balance)
      (SELECT pkgForexProcess.fncGetOutstanding(deal_deal_number, deal_serial_number,1,1,Fromdate),DEAL_BASE_AMOUNT,0,DEAL_EXCHANGE_RATE,0,DEAL_SPOT_RATE,
       0,DEAL_BASE_CURRENCY,DEAL_COMPANY_CODE, DEAL_COUNTER_PARTY,  0, DEAL_DEAL_NUMBER,DEAL_MATURITY_DATE,DEAL_EXECUTE_DATE,DEAL_BUY_SELL,2,5,(pkgForexProcess.fncGetOutstanding(deal_deal_number, deal_serial_number,1,1,Fromdate) *-1)
      FROM TRTRAN001 where ((DEAL_PROCESS_COMPLETE = 12400001  and DEAL_COMPLETE_DATE > Fromdate ) or DEAL_PROCESS_COMPLETE = 12400002)and DEAL_BUY_SELL = 25300002) ;
  --  else
                -- for currency usd
              insert into TRSYSTEM977
                   (OPENAMOUNT,HEDGEAMOUNT,INVOICEAMOUNT,FORWARDRATE,INVOICERATE,SPOTBOOKING,SPOTRATE,TRADECURRENCY,
                   COMPANYCODE,LOCALBANK,IMPORTEXPORT,REFERENCENO,Matdate,ExecDate,Rec_no,SLno,HEDGSALE)
                   Values (0,0,0,0,0,0,
                           0,30400002,0, 0,  0, 0,'','',2,5,25300002); 
                  -- for currency euro
              insert into TRSYSTEM977
                   (OPENAMOUNT,HEDGEAMOUNT,INVOICEAMOUNT,FORWARDRATE,INVOICERATE,SPOTBOOKING,SPOTRATE,TRADECURRENCY,
                   COMPANYCODE,LOCALBANK,IMPORTEXPORT,REFERENCENO,Matdate,ExecDate,Rec_no,SLno,HEDGSALE)
                   Values (0,0,0,0,0,0,
                           0,30400004,0, 0,  0, 0,'','',2,5,25300002); 
    -- end if;
     ncount:=0;
--Loan slno 3      
        select count(*) into ncount from trtran005 where ((FCLN_PROCESS_COMPLETE = 12400001  and FCLN_COMPLETE_DATE > Fromdate ) or FCLN_PROCESS_COMPLETE = 12400002);
     
if ncount !=0 then
    insert into TRSYSTEM977
      (OPENAMOUNT,HEDGEAMOUNT,INVOICEAMOUNT,FORWARDRATE,INVOICERATE,SPOTBOOKING,SPOTRATE,TRADECURRENCY,
       COMPANYCODE,LOCALBANK,IMPORTEXPORT,REFERENCENO,Matdate,ExecDate,Rec_no,SLno,Open_balance)
      (SELECT PKGFOREXPROCESS.FNCGETOUTSTANDING(FCLN_LOAN_NUMBER, 0,5,1,Fromdate) ,0,FCLN_SANCTIONED_FCY,0,FCLN_CONVERSION_RATE,0,
       0,FCLN_CURRENCY_CODE, FCLN_COMPANY_CODE, FCLN_LOCAL_BANK, FCLN_LOAN_TYPE, FCLN_LOAN_NUMBER,FCLN_MATURITY_TO,FCLN_SANCTION_DATE,2,6,(PKGFOREXPROCESS.FNCGETOUTSTANDING(FCLN_LOAN_NUMBER, 0,5,1,Fromdate)*-1)
      FROM TRTRAN005 where ((FCLN_PROCESS_COMPLETE = 12400001  and FCLN_COMPLETE_DATE > Fromdate ) or FCLN_PROCESS_COMPLETE = 12400002));
else
                    -- for currency usd
                     insert into TRSYSTEM977
                   (OPENAMOUNT,HEDGEAMOUNT,INVOICEAMOUNT,FORWARDRATE,INVOICERATE,SPOTBOOKING,SPOTRATE,TRADECURRENCY,
                   COMPANYCODE,LOCALBANK,IMPORTEXPORT,REFERENCENO,Matdate,ExecDate,Rec_no,SLno)
                   Values (0,0,0,0,0,0,
                           0,30400002,0, 0,  0, 0,'','',2,6);
                   -- for currency euro
                   insert into TRSYSTEM977
                   (OPENAMOUNT,HEDGEAMOUNT,INVOICEAMOUNT,FORWARDRATE,INVOICERATE,SPOTBOOKING,SPOTRATE,TRADECURRENCY,
                   COMPANYCODE,LOCALBANK,IMPORTEXPORT,REFERENCENO,Matdate,ExecDate,Rec_no,SLno)
                   Values (0,0,0,0,0,0,
                           0,30400004,0, 0,  0, 0,'','',2,6);
end if;
      

END prcDerivativesPortfolio;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
/