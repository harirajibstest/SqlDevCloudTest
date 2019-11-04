CREATE OR REPLACE PROCEDURE "TEST_VSTSRedgate"."PRCCALCULATEGAPEXPOSURE" ( datDateAsOn in date, GapCalType in number )
as
begin
-- GAPCalTYPE 1 outstanding
-- GAPCalTYPE 2 Canceled
-- GAPCalTYPE 3 Both
-- GAPCalTYPE 4 USDEquivalent
 
 if ((GapCalType= 1) or (GapCalType= 3)) then 
     
     delete from TRSYSTEM970 
     where HEDG_CALCULATION_TYPE='OUTSTANDING' 
       and HEDG_DATE_ASON=datDateAsOn;
     
     INSERT INTO TRSYSTEM970  (HEDG_CALCULATION_TYPE,HEDG_DATE_ASON, HEDG_COMPANY_CODE,
                               HEDG_CURRENCY_CODE,HEDG_PRODUCT_CODE,
                               HEDG_SUBPRODUCT_CODE,HEDG_EXPOSURE_TYPE,
                            HEDG_MON_FORWARD1,HEDG_BENCHMARK_RATE1,HEDG_MTM_RATE1,
                            HEDG_MON_FORWARD2,HEDG_BENCHMARK_RATE2,HEDG_MTM_RATE2,
                            HEDG_MON_FORWARD3,HEDG_BENCHMARK_RATE3,HEDG_MTM_RATE3,
                            HEDG_MON_FORWARD4,HEDG_BENCHMARK_RATE4,HEDG_MTM_RATE4,
                            HEDG_MON_FORWARD5,HEDG_BENCHMARK_RATE5,HEDG_MTM_RATE5,
                            HEDG_MON_FORWARD6,HEDG_BENCHMARK_RATE6,HEDG_MTM_RATE6,
                            HEDG_MON_FORWARD7,HEDG_BENCHMARK_RATE7,HEDG_MTM_RATE7,
                            HEDG_MON_FORWARD8,HEDG_BENCHMARK_RATE8,HEDG_MTM_RATE8,
                            HEDG_MON_FORWARD9,HEDG_BENCHMARK_RATE9,HEDG_MTM_RATE9,
                            HEDG_MON_FORWARD10,HEDG_BENCHMARK_RATE10,HEDG_MTM_RATE10,
                            HEDG_MON_FORWARD11,HEDG_BENCHMARK_RATE11,HEDG_MTM_RATE11,
                            HEDG_MON_FORWARD12,HEDG_BENCHMARK_RATE12,HEDG_MTM_RATE12) 
                            
                            select 'OUTSTANDING',datDateAsOn, CompanyCode,
                                    CurrencyCode,ProductCode,
                                    Subproduct, ExposureType,
                                    AmountFCY0,Amountlocal0/ decode(AmountFCY0,0,1,AmountFCY0),
                                    AmountMTMLocal0/ decode(AmountFCY0,0,1,AmountFCY0),
                                    AmountFCY1,Amountlocal1/ decode(AmountFCY1,0,1,AmountFCY1),
                                    AmountMTMLocal1/ decode(AmountFCY1,0,1,AmountFCY1),
                                    AmountFCY2,Amountlocal2/ decode(AmountFCY2,0,1,AmountFCY2),
                                    AmountMTMLocal2/ decode(AmountFCY2,0,1,AmountFCY2),
                                    AmountFCY3,Amountlocal3/ decode(AmountFCY3,0,1,AmountFCY3),
                                    AmountMTMLocal3/ decode(AmountFCY3,0,1,AmountFCY3),
                                    AmountFCY4,Amountlocal4/ decode(AmountFCY4,0,1,AmountFCY4),
                                    AmountMTMLocal4/ decode(AmountFCY4,0,1,AmountFCY4),
                                    AmountFCY5,Amountlocal5/ decode(AmountFCY5,0,1,AmountFCY5),
                                    AmountMTMLocal5/ decode(AmountFCY5,0,1,AmountFCY5),
                                    AmountFCY6,Amountlocal6/ decode(AmountFCY6,0,1,AmountFCY6),
                                    AmountMTMLocal6/ decode(AmountFCY6,0,1,AmountFCY6),
                                    AmountFCY7,Amountlocal7/ decode(AmountFCY7,0,1,AmountFCY7),
                                    AmountMTMLocal7/ decode(AmountFCY7,0,1,AmountFCY7),
                                    AmountFCY8,Amountlocal8/ decode(AmountFCY8,0,1,AmountFCY8),
                                    AmountMTMLocal8/ decode(AmountFCY8,0,1,AmountFCY8),
                                    AmountFCY9,Amountlocal9/ decode(AmountFCY9,0,1,AmountFCY9),
                                    AmountMTMLocal9/ decode(AmountFCY9,0,1,AmountFCY9),
                                    AmountFCY10,Amountlocal10/ decode(AmountFCY10,0,1,AmountFCY10),
                                    AmountMTMLocal10/ decode(AmountFCY10,0,1,AmountFCY10),
                                    AmountFCY11,Amountlocal11/ decode(AmountFCY11,0,1,AmountFCY11),
                                    AmountMTMLocal11/ decode(AmountFCY11,0,1,AmountFCY11)
                                    from
                                    (
                            select 'OUTSTANDING',datDateAsOn, CompanyCode,
                                    CurrencyCode,ProductCode,
                                    Subproduct, ExposureType,
          (sum(decode( DueDays,0,AmountFCY,0))) AmountFCY0,
          round(sum(decode( DueDays,0,AmountLocal,0)),6) Amountlocal0,
          round(sum(decode( DueDays,0,AmountMTMLocal,0)),6) AmountMTMLocal0,
          (sum(decode( DueDays,1,AmountFCY,0))) AmountFCY1,
          round(sum(decode( DueDays,1,AmountLocal,0)),6)Amountlocal1,
          round(sum(decode( DueDays,1,AmountMTMLocal,0)),6) AmountMTMLocal1,
          (sum(decode( DueDays,2,AmountFCY,0))) AmountFCY2,
          round(sum(decode( DueDays,2,AmountLocal,0)),6)Amountlocal2,
          round(sum(decode( DueDays,2,AmountMTMLocal,0)),6) AmountMTMLocal2,
          (sum(decode( DueDays,3,AmountFCY,0))) AmountFCY3,
          round(sum(decode( DueDays,3,AmountLocal,0)),6) Amountlocal3,
          round(sum(decode( DueDays,3,AmountMTMLocal,0)),6) AmountMTMLocal3,
          (sum(decode( DueDays,4,AmountFCY,0))) AmountFCY4,
          round(sum(decode( DueDays,4,AmountLocal,0)) ,6) Amountlocal4,
          round(sum(decode( DueDays,4,AmountMTMLocal,0)),6) AmountMTMLocal4,
          (sum(decode( DueDays,5,AmountFCY,0))) AmountFCY5,
          round(sum(decode( DueDays,5,AmountLocal,0)),6) Amountlocal5,
          round(sum(decode( DueDays,5,AmountMTMLocal,0)),6) AmountMTMLocal5,
          (sum(decode( DueDays,6,AmountFCY,0))) AmountFCY6,
          round(sum(decode( DueDays,6,AmountLocal,0)),6) Amountlocal6,
          round(sum(decode( DueDays,6,AmountMTMLocal,0)),6) AmountMTMLocal6,
          (sum(decode( DueDays,7,AmountFCY,0))) AmountFCY7,
          round(sum(decode( DueDays,7,AmountLocal,0)),6) Amountlocal7,
          round(sum(decode( DueDays,7,AmountMTMLocal,0)),6)  AmountMTMLocal7,
          (sum(decode( DueDays,8,AmountFCY,0))) AmountFCY8,
          round(sum(decode( DueDays,8,AmountLocal,0)),6) Amountlocal8,
          round(sum(decode( DueDays,8,AmountMTMLocal,0)),6) AmountMTMLocal8,
          (sum(decode( DueDays,9,AmountFCY,0))) AmountFCY9,
          round(sum(decode( DueDays,9,AmountLocal,0)),6) Amountlocal9,
          round(sum(decode( DueDays,9,AmountMTMLocal,0)),6) AmountMTMLocal9,
          (sum(decode( DueDays,10,AmountFCY,0))) AmountFCY10,
          round(sum(decode( DueDays,10,AmountLocal,0)),6) Amountlocal10,
          round(sum(decode( DueDays,10,AmountMTMLocal,0)),6) AmountMTMLocal10,
          (sum(decode( DueDays,11,AmountFCY,0))) AmountFCY11,
          round(sum(decode( DueDays,11,AmountLocal,0)),6) Amountlocal11,
          round(sum(decode( DueDays,11,AmountMTMLocal,0)),6) AmountMTMLocal11
          
     --     (sum(decode( DueDays,12,AmountFCY,0)))/1000,
   --       round(sum(decode( DueDays,12,AmountLocal,0))/ sum(decode( DueDays,12,AmountFCY,1)),6) ,
   --       round(sum(decode( DueDays,12,AmountMTMLocal,0))/ sum(decode( DueDays,12,AmountFCY,1)),6) 
        from (select posn_company_code CompanyCode,posn_currency_code CurrencyCode,
        POSN_PRODUCT_CODE ProductCode,POSN_SUBPRODUCT_CODE SubProduct,
             posn_account_code AccountCode,
             sum(posn_transaction_amount) AmountFCY,
            sum((posn_transaction_amount*posn_fcy_rate)) AmountLocal,
           nvl(sum(posn_M2M_INRRATE*Posn_transaction_amount),0) AmountMTMLocal,
            (case when (to_number(to_char(posn_due_date,'mm')) - to_number(to_chaR(to_date(datDateAsOn),'mm'))) >=0 then
                         to_number(to_char(posn_due_date,'mm')) - to_number(to_chaR(to_date(datDateAsOn),'mm'))
                      else
                        (12- (to_number(to_chaR(to_date(datDateAsOn),'mm')) -to_number(to_char(posn_due_date,'mm'))))  end ) DueDays,
             (case when posn_account_code in (25900001,25900002,25900003,25900004,25900005,25900013,25900017,25900024) then 'Export'
               when posn_account_code in (25900018,25900019,25900020,25900021,25900022,25900023,
                                          25900014,25900015,25900011,25900012) then 'Hedge Buy'
               when posn_account_code in (25900051,25900052,25900053,25900071,25900072,25900073,25900077,25900086) then 'Import'
               when posn_account_code in (25900061,25900062,25900078,25900079,25900082,25900083,25900084,
                                          25900085,25900074,25900075) then 'Hedge Sell' end) ExposureType
      from trsystem997
      where posn_transaction_amount!=0
      and posn_fcy_rate !=0
      
      group by posn_company_code,posn_currency_code,POSN_PRODUCT_CODE,
               POSN_SUBPRODUCT_CODE,posn_account_code,(case when (to_number(to_char(posn_due_date,'mm')) - to_number(to_chaR(to_date(datDateAsOn),'mm'))) >=0 then
                         to_number(to_char(posn_due_date,'mm')) - to_number(to_chaR(to_date(datDateAsOn),'mm'))
                      else
                        (12- (to_number(to_chaR(to_date(datDateAsOn),'mm')) -to_number(to_char(posn_due_date,'mm'))))  end ))
      group by CompanyCode,CurrencyCode,ProductCode,SubProduct,ExposureType
      );
end if; 


if ((GapCalType= 2) or (GapCalType= 3))  then 
     
     delete from TRSYSTEM970 
     where HEDG_CALCULATION_TYPE='CANCELLED' 
       and HEDG_DATE_ASON=datDateAsOn;


   INSERT INTO TRSYSTEM970 (HEDG_CALCULATION_TYPE,HEDG_DATE_ASON, HEDG_COMPANY_CODE,
                               HEDG_CURRENCY_CODE,HEDG_PRODUCT_CODE,
                               HEDG_SUBPRODUCT_CODE,HEDG_EXPOSURE_TYPE,
                            HEDG_MON_FORWARD1,HEDG_BENCHMARK_RATE1,HEDG_MTM_RATE1,
                            HEDG_MON_FORWARD2,HEDG_BENCHMARK_RATE2,HEDG_MTM_RATE2,
                            HEDG_MON_FORWARD3,HEDG_BENCHMARK_RATE3,HEDG_MTM_RATE3,
                            HEDG_MON_FORWARD4,HEDG_BENCHMARK_RATE4,HEDG_MTM_RATE4,
                            HEDG_MON_FORWARD5,HEDG_BENCHMARK_RATE5,HEDG_MTM_RATE5,
                            HEDG_MON_FORWARD6,HEDG_BENCHMARK_RATE6,HEDG_MTM_RATE6,
                            HEDG_MON_FORWARD7,HEDG_BENCHMARK_RATE7,HEDG_MTM_RATE7,
                            HEDG_MON_FORWARD8,HEDG_BENCHMARK_RATE8,HEDG_MTM_RATE8,
                            HEDG_MON_FORWARD9,HEDG_BENCHMARK_RATE9,HEDG_MTM_RATE9,
                            HEDG_MON_FORWARD10,HEDG_BENCHMARK_RATE10,HEDG_MTM_RATE10,
                            HEDG_MON_FORWARD11,HEDG_BENCHMARK_RATE11,HEDG_MTM_RATE11,
                            HEDG_MON_FORWARD12,HEDG_BENCHMARK_RATE12,HEDG_MTM_RATE12) 
                            select 'CANCELLED',datDateAsOn, CompanyCode,
                                    CurrencyCode,ProductCode,
                                    SubproductCode, ExposureType,
                                    AmountFCY0,Amountlocal0/ decode(AmountFCY0,0,1,AmountFCY0),
                                    AmountMTMLocal0/ decode(AmountFCY0,0,1,AmountFCY0),
                                    AmountFCY1,Amountlocal1/ decode(AmountFCY1,0,1,AmountFCY1),
                                    AmountMTMLocal1/ decode(AmountFCY1,0,1,AmountFCY1),
                                    AmountFCY2,Amountlocal2/ decode(AmountFCY2,0,1,AmountFCY2),
                                    AmountMTMLocal2/ decode(AmountFCY2,0,1,AmountFCY2),
                                    AmountFCY3,Amountlocal3/ decode(AmountFCY3,0,1,AmountFCY3),
                                    AmountMTMLocal3/ decode(AmountFCY3,0,1,AmountFCY3),
                                    AmountFCY4,Amountlocal4/ decode(AmountFCY4,0,1,AmountFCY4),
                                    AmountMTMLocal4/ decode(AmountFCY4,0,1,AmountFCY4),
                                    AmountFCY5,Amountlocal5/ decode(AmountFCY5,0,1,AmountFCY5),
                                    AmountMTMLocal5/ decode(AmountFCY5,0,1,AmountFCY5),
                                    AmountFCY0,Amountlocal6/ decode(AmountFCY6,0,1,AmountFCY6),
                                    AmountMTMLocal6/ decode(AmountFCY6,0,1,AmountFCY6),
                                    AmountFCY7,Amountlocal7/ decode(AmountFCY7,0,1,AmountFCY7),
                                    AmountMTMLocal7/ decode(AmountFCY7,0,1,AmountFCY7),
                                    AmountFCY8,Amountlocal8/ decode(AmountFCY8,0,1,AmountFCY8),
                                    AmountMTMLocal8/ decode(AmountFCY8,0,1,AmountFCY8),
                                    AmountFCY9,Amountlocal9/ decode(AmountFCY9,0,1,AmountFCY9),
                                    AmountMTMLocal9/ decode(AmountFCY9,0,1,AmountFCY9),
                                    AmountFCY10,Amountlocal10/ decode(AmountFCY10,0,1,AmountFCY10),
                                    AmountMTMLocal10/ decode(AmountFCY10,0,1,AmountFCY10),
                                    AmountFCY11,Amountlocal11/ decode(AmountFCY11,0,1,AmountFCY11),
                                    AmountMTMLocal11/ decode(AmountFCY11,0,1,AmountFCY11)
                                    from
                                    (
                            select 'CANCELLED',datDateAsOn, CompanyCode,
                                    CurrencyCode,ProductCode,
                                    SubproductCode, ExposureType,
          (sum(decode( DueDays,0,AmountFCY,0))) AmountFCY0,
          round(sum(decode( DueDays,0,AmountLocal,0)),6) Amountlocal0,
          round(sum(decode( DueDays,0,AmountMTMLocal,0)),6) AmountMTMLocal0,
          (sum(decode( DueDays,1,AmountFCY,0))) AmountFCY1,
          round(sum(decode( DueDays,1,AmountLocal,0)),6)Amountlocal1,
          round(sum(decode( DueDays,1,AmountMTMLocal,0)),6) AmountMTMLocal1,
          (sum(decode( DueDays,2,AmountFCY,0))) AmountFCY2,
          round(sum(decode( DueDays,2,AmountLocal,0)),6)Amountlocal2,
          round(sum(decode( DueDays,2,AmountMTMLocal,0)),6) AmountMTMLocal2,
          (sum(decode( DueDays,3,AmountFCY,0))) AmountFCY3,
          round(sum(decode( DueDays,3,AmountLocal,0)),6) Amountlocal3,
          round(sum(decode( DueDays,3,AmountMTMLocal,0)),6) AmountMTMLocal3,
          (sum(decode( DueDays,4,AmountFCY,0))) AmountFCY4,
          round(sum(decode( DueDays,4,AmountLocal,0)) ,6) Amountlocal4,
          round(sum(decode( DueDays,4,AmountMTMLocal,0)),6) AmountMTMLocal4,
          (sum(decode( DueDays,5,AmountFCY,0))) AmountFCY5,
          round(sum(decode( DueDays,5,AmountLocal,0)),6) Amountlocal5,
          round(sum(decode( DueDays,5,AmountMTMLocal,0)),6) AmountMTMLocal5,
          (sum(decode( DueDays,6,AmountFCY,0))) AmountFCY6,
          round(sum(decode( DueDays,6,AmountLocal,0)),6) Amountlocal6,
          round(sum(decode( DueDays,6,AmountMTMLocal,0)),6) AmountMTMLocal6,
          (sum(decode( DueDays,7,AmountFCY,0))) AmountFCY7,
          round(sum(decode( DueDays,7,AmountLocal,0)),6) Amountlocal7,
          round(sum(decode( DueDays,7,AmountMTMLocal,0)),6)  AmountMTMLocal7,
          (sum(decode( DueDays,8,AmountFCY,0))) AmountFCY8,
          round(sum(decode( DueDays,8,AmountLocal,0)),6) Amountlocal8,
          round(sum(decode( DueDays,8,AmountMTMLocal,0)),6) AmountMTMLocal8,
          (sum(decode( DueDays,9,AmountFCY,0))) AmountFCY9,
          round(sum(decode( DueDays,9,AmountLocal,0)),6) Amountlocal9,
          round(sum(decode( DueDays,9,AmountMTMLocal,0)),6) AmountMTMLocal9,
          (sum(decode( DueDays,10,AmountFCY,0))) AmountFCY10,
          round(sum(decode( DueDays,10,AmountLocal,0)),6) Amountlocal10,
          round(sum(decode( DueDays,10,AmountMTMLocal,0)),6) AmountMTMLocal10,
          (sum(decode( DueDays,11,AmountFCY,0))) AmountFCY11,
          round(sum(decode( DueDays,11,AmountLocal,0)),6) Amountlocal11,
          round(sum(decode( DueDays,11,AmountMTMLocal,0)),6) AmountMTMLocal11
        from (  
        
        
      select deal_company_code CompanyCode,deal_base_currency CurrencyCode,
      deal_backup_deal ProductCode, deal_init_code SubProductCode,
      decode(deal_buy_sell,25300001,25900012,25300002,25900062) AccountCode,
      sum(deal_base_amount) AmountFcy, sum(deal_base_amount* Deal_exchange_rate) AmountLocal,
      0  AmountMTMLocal,
      (case when (to_number(to_char(deal_maturity_date,'mm')) - to_number(to_chaR(to_date('01-apr-2013'),'mm'))) >=0 
      then
      to_number(to_char(deal_maturity_date,'mm')) - to_number(to_chaR(to_date('01-apr-2013'),'mm'))
      else
      (12- (to_number(to_chaR(to_date('01-apr-2013'),'mm')) -to_number(to_char(deal_maturity_date,'mm')))) 
      end ) DueDays,
      decode
      (deal_buy_sell,25300001,'Hedge Buy',25300002,'Hedge Sell') ExposureType
        from trtran001, trtran006
       where deal_deal_number= cdel_deal_number
        and deal_execute_date >='01-apr-2012'
        and deal_record_status not in(12400005,12400006)
        and cdel_record_status not in (12400005,12400006)
      group by deal_company_code ,deal_base_currency,deal_backup_deal ,deal_init_code,
      decode(deal_buy_sell,25300001,25900012,25300002,25900062),
      (case when (to_number(to_char(deal_maturity_date,'mm')) - to_number(to_chaR(to_date('01-apr-2013'),'mm'))) >=0 
      then
       to_number(to_char(deal_maturity_date,'mm')) - to_number(to_chaR(to_date('01-apr-2013'),'mm'))
      else
      (12- (to_number(to_chaR(to_date('01-apr-2013'),'mm')) -to_number(to_char(deal_maturity_date,'mm')))) 
      end),
      decode(deal_buy_sell,25300001,'Hedge Buy',25300002,'Hedge Sell')
    
      union all
     
     select  trad_company_code  CompanyCode,
     trtran002.TRAD_TRADE_CURRENCY CurrencyCode,
     trtran002.trad_product_code ProductCode,
     trtran002.TRAD_SUBPRODUCT_CODE SubProductCode, 
     trtran002.trad_import_export AccountCode,
      sum(trtran006.cdel_cancel_amount) AmountFcy ,
      sum(trtran006.cdel_cancel_amount*trtran006.cdel_cancel_rate) AmountLocal,
          0 AmountMTMLocal,
          
      (case when (to_number(to_char(trtran002.trad_maturity_date,'mm')) - to_number(to_chaR(to_date('01-apr-2013'),'mm'))) >=0 
      then
      to_number(to_char(trtran002.trad_maturity_date,'mm')) - to_number(to_chaR(to_date('01-apr-2013'),'mm'))
      else
      (12- (to_number(to_chaR(to_date('01-apr-2013'),'mm')) -to_number(to_char(trtran002.trad_maturity_date,'mm')))) 
      end ) DueDays,
      (case when trad_import_export < 25900050 then 'export' else 'import' end) ExposureType
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
     group by trad_company_code, trad_trade_currency, trad_product_code,TRAD_SUBPRODUCT_CODE,
     trad_import_export,
     (case when (to_number(to_char(trad_maturity_date,'mm')) - to_number(to_chaR(to_date('01-apr-2013'),'mm'))) >=0 
      then
      to_number(to_char(trad_maturity_date,'mm')) - to_number(to_chaR(to_date('01-apr-2013'),'mm'))
      else
      (12- (to_number(to_chaR(to_date('01-apr-2013'),'mm')) -to_number(to_char(trad_maturity_date,'mm')))) 
      end ),
      (case when trad_import_export < 25900050 then 'export' else 'import' end))
      
      
    group by CompanyCode,CurrencyCode,ProductCode,SubProductCode,ExposureType
    );
  end if; 
--commit;
  
  
  
  if ((GapCalType= 4) ) then 
     
     delete from TRSYSTEM970 
     where HEDG_CALCULATION_TYPE='USDEquivalent' 
       and HEDG_DATE_ASON=datDateAsOn;
     
     INSERT INTO TRSYSTEM970  (HEDG_CALCULATION_TYPE,HEDG_DATE_ASON, HEDG_COMPANY_CODE,
                               HEDG_CURRENCY_CODE,HEDG_PRODUCT_CODE,
--                               HEDG_SUBPRODUCT_CODE,
                               HEDG_EXPOSURE_TYPE,
                            HEDG_MON_FORWARD1,HEDG_BENCHMARK_RATE1,HEDG_MTM_RATE1,
                            HEDG_MON_FORWARD2,HEDG_BENCHMARK_RATE2,HEDG_MTM_RATE2,
                            HEDG_MON_FORWARD3,HEDG_BENCHMARK_RATE3,HEDG_MTM_RATE3,
                            HEDG_MON_FORWARD4,HEDG_BENCHMARK_RATE4,HEDG_MTM_RATE4,
                            HEDG_MON_FORWARD5,HEDG_BENCHMARK_RATE5,HEDG_MTM_RATE5,
                            HEDG_MON_FORWARD6,HEDG_BENCHMARK_RATE6,HEDG_MTM_RATE6,
                            HEDG_MON_FORWARD7,HEDG_BENCHMARK_RATE7,HEDG_MTM_RATE7,
                            HEDG_MON_FORWARD8,HEDG_BENCHMARK_RATE8,HEDG_MTM_RATE8,
                            HEDG_MON_FORWARD9,HEDG_BENCHMARK_RATE9,HEDG_MTM_RATE9,
                            HEDG_MON_FORWARD10,HEDG_BENCHMARK_RATE10,HEDG_MTM_RATE10,
                            HEDG_MON_FORWARD11,HEDG_BENCHMARK_RATE11,HEDG_MTM_RATE11,
                            HEDG_MON_FORWARD12,HEDG_BENCHMARK_RATE12,HEDG_MTM_RATE12) 
                            
                            select 'USDEquivalent',datDateAsOn, CompanyCode,
                                    CurrencyCode,ProductCode,
--                                    Subproduct,
                                    ExposureType,
                                    AmountFCY0,Amountlocal0/ decode(AmountFCY0,0,1,AmountFCY0),
                                    AmountMTMLocal0/ decode(AmountFCY0,0,1,AmountFCY0),
                                    AmountFCY1,Amountlocal1/ decode(AmountFCY1,0,1,AmountFCY1),
                                    AmountMTMLocal1/ decode(AmountFCY1,0,1,AmountFCY1),
                                    AmountFCY2,Amountlocal2/ decode(AmountFCY2,0,1,AmountFCY2),
                                    AmountMTMLocal2/ decode(AmountFCY2,0,1,AmountFCY2),
                                    AmountFCY3,Amountlocal3/ decode(AmountFCY3,0,1,AmountFCY3),
                                    AmountMTMLocal3/ decode(AmountFCY3,0,1,AmountFCY3),
                                    AmountFCY4,Amountlocal4/ decode(AmountFCY4,0,1,AmountFCY4),
                                    AmountMTMLocal4/ decode(AmountFCY4,0,1,AmountFCY4),
                                    AmountFCY5,Amountlocal5/ decode(AmountFCY5,0,1,AmountFCY5),
                                    AmountMTMLocal5/ decode(AmountFCY5,0,1,AmountFCY5),
                                    AmountFCY6,Amountlocal6/ decode(AmountFCY6,0,1,AmountFCY6),
                                    AmountMTMLocal6/ decode(AmountFCY6,0,1,AmountFCY6),
                                    AmountFCY7,Amountlocal7/ decode(AmountFCY7,0,1,AmountFCY7),
                                    AmountMTMLocal7/ decode(AmountFCY7,0,1,AmountFCY7),
                                    AmountFCY8,Amountlocal8/ decode(AmountFCY8,0,1,AmountFCY8),
                                    AmountMTMLocal8/ decode(AmountFCY8,0,1,AmountFCY8),
                                    AmountFCY9,Amountlocal9/ decode(AmountFCY9,0,1,AmountFCY9),
                                    AmountMTMLocal9/ decode(AmountFCY9,0,1,AmountFCY9),
                                    AmountFCY10,Amountlocal10/ decode(AmountFCY10,0,1,AmountFCY10),
                                    AmountMTMLocal10/ decode(AmountFCY10,0,1,AmountFCY10),
                                    AmountFCY11,Amountlocal11/ decode(AmountFCY11,0,1,AmountFCY11),
                                    AmountMTMLocal11/ decode(AmountFCY11,0,1,AmountFCY11)
                                    from
                                    (
                            select 'USDEquivalent',datDateAsOn, CompanyCode,
                                    CurrencyCode,ProductCode,
--                                    Subproduct, 
                                      ExposureType,
          (sum(decode( DueDays,0,AmountFCY,0))) AmountFCY0,
          round(sum(decode( DueDays,0,AmountLocal,0)),6) Amountlocal0,
          round(sum(decode( DueDays,0,AmountMTMLocal,0)),6) AmountMTMLocal0,
          (sum(decode( DueDays,1,AmountFCY,0))) AmountFCY1,
          round(sum(decode( DueDays,1,AmountLocal,0)),6)Amountlocal1,
          round(sum(decode( DueDays,1,AmountMTMLocal,0)),6) AmountMTMLocal1,
          (sum(decode( DueDays,2,AmountFCY,0))) AmountFCY2,
          round(sum(decode( DueDays,2,AmountLocal,0)),6)Amountlocal2,
          round(sum(decode( DueDays,2,AmountMTMLocal,0)),6) AmountMTMLocal2,
          (sum(decode( DueDays,3,AmountFCY,0))) AmountFCY3,
          round(sum(decode( DueDays,3,AmountLocal,0)),6) Amountlocal3,
          round(sum(decode( DueDays,3,AmountMTMLocal,0)),6) AmountMTMLocal3,
          (sum(decode( DueDays,4,AmountFCY,0))) AmountFCY4,
          round(sum(decode( DueDays,4,AmountLocal,0)) ,6) Amountlocal4,
          round(sum(decode( DueDays,4,AmountMTMLocal,0)),6) AmountMTMLocal4,
          (sum(decode( DueDays,5,AmountFCY,0))) AmountFCY5,
          round(sum(decode( DueDays,5,AmountLocal,0)),6) Amountlocal5,
          round(sum(decode( DueDays,5,AmountMTMLocal,0)),6) AmountMTMLocal5,
          (sum(decode( DueDays,6,AmountFCY,0))) AmountFCY6,
          round(sum(decode( DueDays,6,AmountLocal,0)),6) Amountlocal6,
          round(sum(decode( DueDays,6,AmountMTMLocal,0)),6) AmountMTMLocal6,
          (sum(decode( DueDays,7,AmountFCY,0))) AmountFCY7,
          round(sum(decode( DueDays,7,AmountLocal,0)),6) Amountlocal7,
          round(sum(decode( DueDays,7,AmountMTMLocal,0)),6)  AmountMTMLocal7,
          (sum(decode( DueDays,8,AmountFCY,0))) AmountFCY8,
          round(sum(decode( DueDays,8,AmountLocal,0)),6) Amountlocal8,
          round(sum(decode( DueDays,8,AmountMTMLocal,0)),6) AmountMTMLocal8,
          (sum(decode( DueDays,9,AmountFCY,0))) AmountFCY9,
          round(sum(decode( DueDays,9,AmountLocal,0)),6) Amountlocal9,
          round(sum(decode( DueDays,9,AmountMTMLocal,0)),6) AmountMTMLocal9,
          (sum(decode( DueDays,10,AmountFCY,0))) AmountFCY10,
          round(sum(decode( DueDays,10,AmountLocal,0)),6) Amountlocal10,
          round(sum(decode( DueDays,10,AmountMTMLocal,0)),6) AmountMTMLocal10,
          (sum(decode( DueDays,11,AmountFCY,0))) AmountFCY11,
          round(sum(decode( DueDays,11,AmountLocal,0)),6) Amountlocal11,
          round(sum(decode( DueDays,11,AmountMTMLocal,0)),6) AmountMTMLocal11
          
     --     (sum(decode( DueDays,12,AmountFCY,0)))/1000,
   --       round(sum(decode( DueDays,12,AmountLocal,0))/ sum(decode( DueDays,12,AmountFCY,1)),6) ,
   --       round(sum(decode( DueDays,12,AmountMTMLocal,0))/ sum(decode( DueDays,12,AmountFCY,1)),6) 
        from (select posn_company_code CompanyCode,30400004 CurrencyCode,
        POSN_PRODUCT_CODE ProductCode,
--        POSN_SUBPRODUCT_CODE SubProduct,
             posn_account_code AccountCode,
             sum((case when posn_account_code in (25900001,25900002,25900003,25900004,25900005,25900013,25900017,25900024) then -1 * POSN_REVALUE_USD
               when posn_account_code in (25900018,25900019,25900020,25900021,25900022,25900023,
                                          25900014,25900015,25900011,25900012) then -1* POSN_REVALUE_USD
               when posn_account_code in (25900051,25900052,25900053,25900071,25900072,25900073,25900077,25900086) then POSN_REVALUE_USD
               when posn_account_code in (25900061,25900062,25900078,25900079,25900082,25900083,25900084,
                                          25900085,25900074,25900075) then POSN_REVALUE_USD end)
                                          ) AmountFCY,
            sum((POSN_REVALUE_USD*posn_fcy_rate)) AmountLocal,
           nvl(sum(posn_M2M_INRRATE*POSN_REVALUE_USD),0) AmountMTMLocal,
            (case when (to_number(to_char(posn_due_date,'mm')) - to_number(to_chaR(to_date(datDateAsOn),'mm'))) >=0 then
                         to_number(to_char(posn_due_date,'mm')) - to_number(to_chaR(to_date(datDateAsOn),'mm'))
                      else
                        (12- (to_number(to_chaR(to_date(datDateAsOn),'mm')) -to_number(to_char(posn_due_date,'mm'))))  end ) DueDays,
             (case when posn_account_code in (25900001,25900002,25900003,25900004,25900005,25900013,25900017,25900024,
                                              25900051,25900052,25900053,25900071,25900072,25900073,25900077,25900086) then 'Import'
               when posn_account_code in (25900018,25900019,25900020,25900021,25900022,25900023,
                                          25900014,25900015,25900011,25900012, 25900061,25900062,25900078,25900079,25900082,25900083,25900084,
                                          25900085,25900074,25900075 ) then 'Hedged' end) ExposureType
              -- when posn_account_code in (25900051,25900052,25900053,25900071,25900072,25900073,25900077,25900086) then 'Import'
              -- when posn_account_code in (25900061,25900062,25900078,25900079,25900082,25900083,25900084,
               --                           25900085,25900074,25900075) then 'Hedge Sell' end) ExposureType
      from trsystem997
      where POSN_REVALUE_USD!=0
      and posn_fcy_rate !=0
      
      group by posn_company_code,30400004,POSN_PRODUCT_CODE,
--               POSN_SUBPRODUCT_CODE,
               posn_account_code,(case when (to_number(to_char(posn_due_date,'mm')) - to_number(to_chaR(to_date(datDateAsOn),'mm'))) >=0 then
                         to_number(to_char(posn_due_date,'mm')) - to_number(to_chaR(to_date(datDateAsOn),'mm'))
                      else
                        (12- (to_number(to_chaR(to_date(datDateAsOn),'mm')) -to_number(to_char(posn_due_date,'mm'))))  end ))
      group by CompanyCode,CurrencyCode,ProductCode,
--               SubProduct,
               ExposureType
      );
end if; 
       commit;
        end prcCalculateGapExposure;
/