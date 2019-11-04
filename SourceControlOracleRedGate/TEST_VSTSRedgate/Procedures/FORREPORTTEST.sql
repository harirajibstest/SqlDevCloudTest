CREATE OR REPLACE PROCEDURE "TEST_VSTSRedgate"."FORREPORTTEST" (ASONDATE in DATE,RSTATUS in NUMBER)
 AS
 BEGIN
 IF (RSTATUS= 1) THEN
 DELETE FROM REPORTTEST;
 INSERT INTO REPORTTEST(STATUS,TYPEOFTRANS,COMPANYCODE,BACKUPDEAL,PRODUCTCODE,MATURITYMONTH,BASEAMOUNT,EXCHANGERATE,BASECURRENCY,OtherCurrency,FinancialYear,GAINLOSS,
     WTDAVGRATE,BASEAMOUNTINR,FORCASTEDEXPO,HEDGED,PERCENTHEDGED,HEDGEDPOLICY,HEDGERATEMONTH,ADDITIONALCOV,UNHEDGEDEXPO,FORWARDRATE)
  (select Status,TypeofTrans,
                      CompanyCode,
                      BackUpDeal,
                      productCode,
                      MaturityMonth,
                      BaseAmount,
                      round(ExchangeRate,2)ExchangeRate,
                      BaseCurrency,
                      OtherCurrency,
                      FinancialYear,
                      GAINLOSS,
                      WTDAVGRATE,        
                      BASEAMOUNTINR,     
                      FORCASTEDEXPO,     
                      HEDGED,            
                      PERCENTHEDGED,     
                      HEDGEDPOLICY,       
                      HEDGERATEMONTH,     
                      ADDITIONALCOV,      
                      UNHEDGEDEXPO,       
                      FORWARDRATE 
               from (
               select 'OPENED' status,'Deals' TypeOfTrans,deal_company_code
              CompanyCode,deal_backup_deal BackupDeal,
                      deal_init_code
              ProductCode,to_char(deal_maturity_date,'MON-yy') MaturityMonth,
                      sum(deal_base_amount)
              BaseAmount,
              Round(sum(deal_base_amount*deal_exchange_rate)/sum(deal_base_amount),2) ExchangeRate,
                      deal_base_currency BaseCurrency,Deal_other_currency OtherCurrency,
                      (case when to_char(deal_maturity_date,'mm')<=3 then
                           ((to_number( to_char(deal_maturity_date,'yy'))-1) || '-'
              || to_char(deal_maturity_date,'yy'))
                           else
                           (to_char(deal_maturity_date,'yy') ||'-' ||(to_number(
              to_char(deal_maturity_date,'yy'))+1))
                           end) FinancialYear,0 GAINLOSS,0 WTDAVGRATE,0 BASEAMOUNTINR,0 FORCASTEDEXPO,0 HEDGED,0 PERCENTHEDGED,
                           0 HEDGEDPOLICY,0 HEDGERATEMONTH,0 ADDITIONALCOV,0 UNHEDGEDEXPO,0 FORWARDRATE
                 from trtran001
                where ((deal_process_complete=12400002)
                    or (deal_complete_date <=sysdate and deal_process_complete=12400001))
                  and deal_execute_date >='01-apr-2012'
                  and deal_record_status not in(12400005,12400006)
               group by deal_company_code ,deal_backup_deal ,deal_init_code,
                        to_char(deal_maturity_date,'MON-yy') ,deal_base_currency
              ,Deal_other_currency,
                        (case when to_char(deal_maturity_date,'mm')<=3 then
                           ((to_number( to_char(deal_maturity_date,'yy'))-1) || '-'
              || to_char(deal_maturity_date,'yy'))
                           else
                           (to_char(deal_maturity_date,'yy') ||'-' ||(to_number(
              to_char(deal_maturity_date,'yy'))+1))
                           end))) ;
                           
                           
         END IF;
                           
      IF (RSTATUS= 2) THEN                     
         DELETE FROM REPORTTEST;                  
      INSERT INTO REPORTTEST(STATUS,TYPEOFTRANS,COMPANYCODE,BACKUPDEAL,PRODUCTCODE,MATURITYMONTH,BASEAMOUNT,EXCHANGERATE,BASECURRENCY,OtherCurrency,FinancialYear,GAINLOSS,
     WTDAVGRATE,BASEAMOUNTINR,FORCASTEDEXPO,HEDGED,PERCENTHEDGED,HEDGEDPOLICY,HEDGERATEMONTH,ADDITIONALCOV,UNHEDGEDEXPO,FORWARDRATE)
  (select Status,TypeofTrans,
                      CompanyCode,
                      BackUpDeal,
                      productCode,
                      MaturityMonth,
                      BaseAmount,
                      round(ExchangeRate,2)ExchangeRate,
                      BaseCurrency,
                      OtherCurrency,
                      FinancialYear,
                      GAINLOSS,
                      WTDAVGRATE,        
                      BASEAMOUNTINR,     
                      FORCASTEDEXPO,     
                      HEDGED,            
                      PERCENTHEDGED,     
                      HEDGEDPOLICY,       
                      HEDGERATEMONTH,     
                      ADDITIONALCOV,      
                      UNHEDGEDEXPO,       
                      FORWARDRATE 
               from (
              
               select 'CANCELLED' status,'Deals' TypeOfTrans,deal_company_code
              CompanyCode,deal_backup_deal BackupDeal,
                      deal_init_code
              ProductCode,to_char(deal_maturity_date,'MON-yy') MaturityMonth,
                      sum(cdel_cancel_amount)
              BaseAmount,Round(sum(cdel_cancel_amount*cdel_cancel_rate)/sum(cdel_cancel_amount),2)
              ExchangeRate,
                      deal_base_currency BaseCurrency,Deal_other_currency OtherCurrency,
                      
                      (case when to_char(deal_maturity_date,'mm')<=3 then
                           ((to_number( to_char(deal_maturity_date,'yy'))-1) || '-'
              || to_char(deal_maturity_date,'yy'))
                           else
                           (to_char(deal_maturity_date,'yy') ||'-' ||(to_number(
              to_char(deal_maturity_date,'yy'))+1))
                           end) FinancialYear,CDEL_PROFIT_LOSS GAINLOSS,0 WTDAVGRATE,0 BASEAMOUNTINR,0 FORCASTEDEXPO,0 HEDGED,0 PERCENTHEDGED,
                           0 HEDGEDPOLICY,0 HEDGERATEMONTH,0 ADDITIONALCOV,0 UNHEDGEDEXPO,0 FORWARDRATE
                           
                           
                           
                 from trtran001, trtran006
                where deal_deal_number= cdel_deal_number
                 and deal_execute_date >='01-apr-2012'
                 and deal_record_status not in(12400005,12400006)
                 and cdel_record_status not in (12400005,12400006)
               group by deal_company_code ,deal_backup_deal ,deal_init_code,
                        to_char(deal_maturity_date,'MON-yy') ,deal_base_currency
              ,Deal_other_currency,
                        (case when to_char(deal_maturity_date,'mm')<=3 then
                           ((to_number( to_char(deal_maturity_date,'yy'))-1) || '-'
              || to_char(deal_maturity_date,'yy'))
                           else
                           (to_char(deal_maturity_date,'yy') ||'-' ||(to_number(
              to_char(deal_maturity_date,'yy'))+1))
                           end)));
                           
            END IF;               
                           
      IF (RSTATUS= 3) THEN                     
         DELETE FROM REPORTTEST;                  
      INSERT INTO REPORTTEST(STATUS,TYPEOFTRANS,COMPANYCODE,BACKUPDEAL,PRODUCTCODE,MATURITYMONTH,BASEAMOUNT,EXCHANGERATE,BASECURRENCY,OtherCurrency,FinancialYear,GAINLOSS,
     WTDAVGRATE,BASEAMOUNTINR,FORCASTEDEXPO,HEDGED,PERCENTHEDGED,HEDGEDPOLICY,HEDGERATEMONTH,ADDITIONALCOV,UNHEDGEDEXPO,FORWARDRATE)
  (select Status,TypeofTrans,
                      CompanyCode,
                      BackUpDeal,
                      productCode,
                      MaturityMonth,
                      BaseAmount,
                      round(ExchangeRate,2)ExchangeRate,
                      BaseCurrency,
                      OtherCurrency,
                      FinancialYear,
                      GAINLOSS,
                      WTDAVGRATE,        
                      BASEAMOUNTINR,     
                      FORCASTEDEXPO,     
                      HEDGED,            
                      PERCENTHEDGED,     
                      HEDGEDPOLICY,       
                      HEDGERATEMONTH,     
                      ADDITIONALCOV,      
                      UNHEDGEDEXPO,       
                      FORWARDRATE 
               from (
             select 'OPENED' Status,'Exposure' TypeOfTrans, trad_company_code
              CompanyCode,null BackupDeal,
                     trad_product_code
              ProductCode,to_char(trad_maturity_date,'MON-yy') MaturityMonth,
                     sum(trad_trade_fcy) BaseAmount,
                     Round(sum(trad_trade_fcy*trad_trade_rate)/sum(trad_trade_fcy),2)
              ExchangeRate,
                     trad_trade_currency BaseCurrency,30400003 OtherCurrency,
                     (case when to_char(trad_maturity_date,'mm')<=3 then
                           ((to_number( to_char(trad_maturity_date,'yy'))-1) || '-'
              || to_char(trad_maturity_date,'yy'))
                           else
                           (to_char(trad_maturity_date,'yy') ||'-' ||(to_number(
              to_char(trad_maturity_date,'yy'))+1))
                           end) FinancialYear,0 GAINLOSS,0 WTDAVGRATE,0 BASEAMOUNTINR,0 FORCASTEDEXPO,0 HEDGED,0 PERCENTHEDGED,
                           0 HEDGEDPOLICY,0 HEDGERATEMONTH,0 ADDITIONALCOV,0 UNHEDGEDEXPO,0 FORWARDRATE
                     from trtran002
                     where ((trad_process_complete=12400002)
                           or (trad_complete_date <=sysdate and
              trad_process_complete=12400001))
                          and trad_entry_date >='01-apr-2012'
                          and trad_record_status not in (10200005,10200006)
              group by trad_company_code, trad_product_code
              ,to_char(trad_maturity_date,'MON-yy'),
                       trad_trade_currency,(case when to_char(trad_maturity_date,'mm')<=3 then
                           ((to_number( to_char(trad_maturity_date,'yy'))-1) || '-'
              || to_char(trad_maturity_date,'yy'))
                           else
                           (to_char(trad_maturity_date,'yy') ||'-' ||(to_number(
              to_char(trad_maturity_date,'yy'))+1))
                           end)));
                           
                           
             END IF;              
                           
          IF (RSTATUS= 4) THEN                     
         DELETE FROM REPORTTEST;                  
         INSERT INTO REPORTTEST(STATUS,TYPEOFTRANS,COMPANYCODE,BACKUPDEAL,PRODUCTCODE,MATURITYMONTH,BASEAMOUNT,EXCHANGERATE,BASECURRENCY,OtherCurrency,FinancialYear,GAINLOSS,
     WTDAVGRATE,BASEAMOUNTINR,FORCASTEDEXPO,HEDGED,PERCENTHEDGED,HEDGEDPOLICY,HEDGERATEMONTH,ADDITIONALCOV,UNHEDGEDEXPO,FORWARDRATE)
  (select Status,TypeofTrans,
                      CompanyCode,
                      BackUpDeal,
                      productCode,
                      MaturityMonth,
                      BaseAmount,
                      round(ExchangeRate,2)ExchangeRate,
                      BaseCurrency,
                      OtherCurrency,
                      FinancialYear,
                      GAINLOSS,
                      WTDAVGRATE,        
                      BASEAMOUNTINR,     
                      FORCASTEDEXPO,     
                      HEDGED,            
                      PERCENTHEDGED,     
                      HEDGEDPOLICY,       
                      HEDGERATEMONTH,     
                      ADDITIONALCOV,      
                      UNHEDGEDEXPO,       
                      FORWARDRATE 
               from ( select 'CANCELLED' Status,'Exposure' TypeOfTrans, trad_company_code
              CompanyCode,null BackupDeal,
                     trad_product_code
              ProductCode,to_char(cdel_cancel_date,'MON-yy') MaturityMonth,
                     sum(cdel_cancel_amount) BaseAmount ,
                     Round(sum(cdel_cancel_amount*cdel_cancel_rate)/sum(cdel_cancel_amount),2)
              ExchangeRate,
                     trad_trade_currency BaseCurrency,30400003 OtherCurrency,
                     (case when to_char(cdel_cancel_date,'mm')<=3 then
                           ((to_number( to_char(cdel_cancel_date,'yy'))-1) || '-' ||
              to_char(cdel_cancel_date,'yy'))
                           else
                           (to_char(cdel_cancel_date,'yy') ||'-' ||(to_number(
              to_char(cdel_cancel_date,'yy'))+1))
                           end) FinancialYear,0 GAINLOSS,0 WTDAVGRATE,0 BASEAMOUNTINR,0 FORCASTEDEXPO,0 HEDGED,0 PERCENTHEDGED,
                           0 HEDGEDPOLICY,0 HEDGERATEMONTH,0 ADDITIONALCOV,0 UNHEDGEDEXPO,0 FORWARDRATE
                     from trtran003, trtran002,trtran006
                     where brel_trade_reference=trad_trade_reference
                          and cdel_trade_reference= brel_trade_reference
                          and ((trad_process_complete=12400002)
              
                           or (trad_complete_date <=sysdate and
              trad_process_complete=12400001))
                          and brel_entry_date >='01-apr-2012'
                          and trad_record_status not in (10200005,10200006)
                          and brel_record_status not in (10200005,10200006)
                          and cdel_record_Status not in (10200005,10200006)
              group by trad_company_code, trad_product_code
              ,to_char(cdel_cancel_date,'MON-yy'),
                       trad_trade_currency,(case when to_char(cdel_cancel_date,'mm')<=3 then
                           ((to_number( to_char(cdel_cancel_date,'yy'))-1) || '-' ||
              to_char(cdel_cancel_date,'yy'))
                           else
                           (to_char(cdel_cancel_date,'yy') ||'-' ||(to_number(
              to_char(cdel_cancel_date,'yy'))+1))
                           end)));
         END IF;
         
         --- order by to_date('01-' || MaturityMonth )) ;                      
      COMMIT; 
      END forreporttest;
/