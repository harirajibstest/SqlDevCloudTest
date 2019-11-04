CREATE OR REPLACE PROCEDURE "TEST_VSTSRedgate"."PRCGENERATESTOPLOSSHEDGE" 
(varUserID varchar,companyCode number, CurrencyCode number, datAsOn date)
as
  numError number(15,2);
begin
   
   numError :=  pkgforexprocess.FNCPOSITIONGENERATE(varUserID,datAsOn);commit; 
   
   delete from TRSYSTEM972;
   
   insert into TRSYSTEM972 (Monthno,MonthName,Years,Currency,Company,asondate)
   values(0,to_char(datAsOn,'mon'),to_char(datAsOn,'YYYY'),CurrencyCode,companyCode,datAsOn);
   insert into TRSYSTEM972 (Monthno,MonthName,Years,Currency,Company,asondate)
   values(1,to_char(add_months(datAsOn,1),'mon'),to_char(add_months(datAsOn,1),'YYYY'),CurrencyCode,companyCode,datAsOn);
   insert into TRSYSTEM972 (Monthno,MonthName,Years,Currency,Company,asondate)
   values(2,to_char(add_months(datAsOn,2),'mon'),to_char(add_months(datAsOn,2),'YYYY'),CurrencyCode,companyCode,datAsOn);
   insert into TRSYSTEM972 (Monthno,MonthName,Years,Currency,Company,asondate)
   values(3,to_char(add_months(datAsOn,3),'mon'),to_char(add_months(datAsOn,3),'YYYY'),CurrencyCode,companyCode,datAsOn);
   insert into TRSYSTEM972 (Monthno,MonthName,Years,Currency,Company,asondate)
   values(4,to_char(add_months(datAsOn,4),'mon'),to_char(add_months(datAsOn,4),'YYYY'),CurrencyCode,companyCode,datAsOn);
   insert into TRSYSTEM972 (Monthno,MonthName,Years,Currency,Company,asondate)
   values(5,to_char(add_months(datAsOn,5),'mon'),to_char(add_months(datAsOn,5),'YYYY'),CurrencyCode,companyCode,datAsOn);
   insert into TRSYSTEM972 (Monthno,MonthName,Years,Currency,Company,asondate)
   values(6,to_char(add_months(datAsOn,6),'mon'),to_char(add_months(datAsOn,6),'YYYY'),CurrencyCode,companyCode,datAsOn);
   insert into TRSYSTEM972 (Monthno,MonthName,Years,Currency,Company,asondate)
   values(7,to_char(add_months(datAsOn,7),'mon'),to_char(add_months(datAsOn,7),'YYYY'),CurrencyCode,companyCode,datAsOn);
   insert into TRSYSTEM972 (Monthno,MonthName,Years,Currency,Company,asondate)
   values(8,to_char(add_months(datAsOn,8),'mon'),to_char(add_months(datAsOn,8),'YYYY'),CurrencyCode,companyCode,datAsOn);
   insert into TRSYSTEM972 (Monthno,MonthName,Years,Currency,Company,asondate)
   values(9,to_char(add_months(datAsOn,9),'mon'),to_char(add_months(datAsOn,9),'YYYY'),CurrencyCode,companyCode,datAsOn);
   insert into TRSYSTEM972 (Monthno,MonthName,Years,Currency,Company,asondate)
   values(10,to_char(add_months(datAsOn,10),'mon'),to_char(add_months(datAsOn,10),'YYYY'),CurrencyCode,companyCode,datAsOn);
   insert into TRSYSTEM972 (Monthno,MonthName,Years,Currency,Company,asondate)
   values(11,to_char(add_months(datAsOn,11),'mon'),to_char(add_months(datAsOn,11),'YYYY'),CurrencyCode,companyCode,datAsOn);
   insert into TRSYSTEM972 (Monthno,MonthName,Years,Currency,Company,asondate)
   values(12,to_char(add_months(datAsOn,12),'mon'),to_char(add_months(datAsOn,12),'YYYY'),CurrencyCode,companyCode,datAsOn);
   
-- Import/Export Forward contract
   insert into TRSYSTEM972(FRWCONTRACT,IMPEXP,PRODUCTCODE,CURRENCY,ASONDATE)
   (select sum(posn_transaction_amount) Fcy,1,25900011,30400004,datAsOn from trsystem997 where posn_account_code in(25900011,25900012)
   and posn_due_date <= datAsOn);
   insert into TRSYSTEM972(FRWCONTRACT,IMPEXP,PRODUCTCODE,CURRENCY,ASONDATE)
   (select sum(posn_transaction_amount) Fcy,2,25900061,30400004,datAsOn from trsystem997 where posn_account_code in(25900061,25900062)
   and posn_due_date <= datAsOn);
-- Import/Export Future   
   insert into TRSYSTEM972(FRWCONTRACT,IMPEXP,PRODUCTCODE,CURRENCY,ASONDATE)
   (select sum(posn_transaction_amount) Fcy,1,25900018,30400004,datAsOn from trsystem997 where posn_account_code in(25900018,25900019)
   and posn_due_date <= datAsOn);
   insert into TRSYSTEM972(FRWCONTRACT,IMPEXP,PRODUCTCODE,CURRENCY,ASONDATE)
   (select sum(posn_transaction_amount) Fcy,2,25900078 ,30400004,datAsOn from trsystem997 where posn_account_code in(25900078,25900079)
   and posn_due_date <= datAsOn);
-- Import/Export Option
   insert into TRSYSTEM972(FRWCONTRACT,IMPEXP,PRODUCTCODE,CURRENCY,ASONDATE)
   (select sum(posn_transaction_amount) Fcy,1,25900020,30400004,datAsOn from trsystem997 where posn_account_code in(25900020,25900021,25900022,25900023)
   and posn_due_date <= datAsOn);
   insert into TRSYSTEM972(FRWCONTRACT,IMPEXP,PRODUCTCODE,CURRENCY,ASONDATE)
   (select sum(posn_transaction_amount) Fcy,2,25900082,30400004,datAsOn from trsystem997 where posn_account_code in(25900082,25900083,25900084,25900085)
   and posn_due_date <= datAsOn);
--BC Loan
   insert into TRSYSTEM972(FRWCONTRACT,IMPEXP,PRODUCTCODE,CURRENCY,ASONDATE)
   (select sum(posn_transaction_amount) Fcy,2,25900073,30400004,datAsOn from trsystem997 where posn_account_code in(25900073)
   and posn_due_date <= datAsOn);
--Confirmed Order in hands
   insert into TRSYSTEM972(FRWCONTRACT,IMPEXP,PRODUCTCODE,CURRENCY,ASONDATE)
   (select sum(posn_transaction_amount) Fcy,1,25900001,30400004,datAsOn from trsystem997 where posn_account_code in(25900001,25900002,25900003,25900004,25900005,25900013,25900014,25900015,25900016,25900017)
   and posn_due_date <= datAsOn);
   insert into TRSYSTEM972(FRWCONTRACT,IMPEXP,PRODUCTCODE,CURRENCY,ASONDATE)
   (select sum(posn_transaction_amount) Fcy,2,25900051,30400004,datAsOn from trsystem997 where posn_account_code in(25900051,25900052,25900053,25900074,25900075,25900076,25900077)
   and posn_due_date <= datAsOn);

       --and posn_account_code <=25900050
--       and posn_currency_code =(case when CurrencyCode=30499999 then posn_currency_code 
--                                     else to_number(Currency)  end)
--       and posn_company_code =(case when CompanyCode=30199999 then posn_company_code
--                                    else to_number(CompanyCode) end)    
 --      and MonthName=to_char(posn_due_date,'mon')
 --      and Years=to_char(posn_due_date,'yyyy')
 


   update TRSYSTEM972 set(Imports,impAvgBookRate,ImportsINR,mtmrateimp)=
   (  select sum(posn_transaction_amount) Fcy,
             sum(posn_transaction_amount * posn_fcy_rate)/ sum(posn_transaction_amount) Inr,
             sum(posn_transaction_amount * posn_fcy_rate),
             sum(posn_transaction_amount*POSN_M2M_INRRATE)/sum(posn_transaction_amount)
       from trsystem997
      where posn_account_code not in(25900061,25900062)
       and posn_account_code >= 25900050
       and posn_currency_code =(case when CurrencyCode=30499999 then posn_currency_code 
                                     else to_number(Currency)  end)
       and posn_company_code =(case when CompanyCode=30199999 then posn_company_code
                                    else to_number(CompanyCode) end)  
       and MonthName=to_char(posn_due_date,'mon')
       and Years=to_char(posn_due_date,'yyyy')
  group by  to_char(posn_due_date,'MM'), to_char(posn_due_date,'yyyy'));
   
   update TRSYSTEM972 set(ImpForwards,impAvgDealRate,ImpForwardsINR,mtmrateimp)=
   (  select sum(posn_transaction_amount) Fcy,
             sum(posn_transaction_amount * posn_fcy_rate)/ sum(posn_transaction_amount) Inr,
             sum(posn_transaction_amount * posn_fcy_rate),
             sum(posn_transaction_amount*POSN_M2M_INRRATE)/sum(posn_transaction_amount)
       from trsystem997
      where posn_account_code in(25900011,25900012)
       --and posn_account_code <=25900050
       and posn_currency_code =(case when CurrencyCode=30499999 then posn_currency_code 
                                     else to_number(Currency)  end)
       and posn_company_code =(case when CompanyCode=30199999 then posn_company_code
                                    else to_number(CompanyCode) end)         and MonthName=to_char(posn_due_date,'mon')
       and Years=to_char(posn_due_date,'yyyy')
  group by  to_char(posn_due_date,'MM'), to_char(posn_due_date,'yyyy'));
   
   update TRSYSTEM972 set(Exports,expAvgBookRate,ExportsINR,mtmrateexp)=
   (  select sum(posn_transaction_amount) Fcy,
             sum(posn_transaction_amount * posn_fcy_rate)/ sum(posn_transaction_amount) Inr,
             sum(posn_transaction_amount * posn_fcy_rate),
             sum(posn_transaction_amount*POSN_M2M_INRRATE)/sum(posn_transaction_amount)
       from trsystem997
      where posn_account_code not in(25900011,25900012)
       and posn_account_code < 25900050
       and posn_currency_code =(case when CurrencyCode=30499999 then posn_currency_code 
                                     else to_number(Currency)  end)
       and posn_company_code =(case when CompanyCode=30199999 then posn_company_code
                                    else to_number(CompanyCode) end)  
       and MonthName=to_char(posn_due_date,'mon')
       and Years=to_char(posn_due_date,'yyyy')
  group by  to_char(posn_due_date,'MM'), to_char(posn_due_date,'yyyy'));
  
   update TRSYSTEM972 set(ExpForwards,expAvgDealRate,ExpForwardsINR,mtmrateexp)=
   (  select sum(posn_transaction_amount) Fcy,
             sum(posn_transaction_amount * posn_fcy_rate)/ sum(posn_transaction_amount) Inr,
             sum(posn_transaction_amount * posn_fcy_rate),
             sum(posn_transaction_amount*POSN_M2M_INRRATE)/sum(posn_transaction_amount)
       from trsystem997
      where posn_account_code in(25900061,25900062)
       --and posn_account_code <=25900050
       and posn_currency_code =(case when CurrencyCode=30499999 then posn_currency_code 
                                     else to_number(Currency)  end)
       and posn_company_code =(case when CompanyCode=30199999 then posn_company_code
                                    else to_number(CompanyCode) end)    
       and MonthName=to_char(posn_due_date,'mon')
       and Years=to_char(posn_due_date,'yyyy')
  group by  to_char(posn_due_date,'MM'), to_char(posn_due_date,'yyyy'));
  -- Import forword contract----
           
  commit;
  
end prcGenerateStopLossHedge;
 
 
 
 
 
 
 
 
 
 
/