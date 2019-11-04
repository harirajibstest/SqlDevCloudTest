CREATE OR REPLACE Procedure "TEST_VSTSRedgate".prcDealerPostion 
  (WorkDate in date,
   VarCompanyCode in varchar,
   DealerID in varchar,
   varBackUpdeal in varchar,
   varInitCode in varchar)
as
  --PRAGMA AUTONOMOUS_TRANSACTION;
  varMessage          varchar2(100);
  varOperation        varchar2(100);
  varError	          varchar2(2048);
	numError            number;
  numReturn           number;
  numHedgeSell        number(15,2) := 0;
  numHedgeBuy         number(15,2) := 0;
  numOpenBal          number(15,2) := 0;
  numClosingBal       number(15,2) := 0;
  datTemp             date;
  DealerIDTemp       varchar(50);
  DatWorkDate        date;
  datQTD             Date;
  datMTD              Date;
  datYTD              Date;
begin
  DatWorkDate:=trunc(WorkDate);
     datMTD := '01-' || to_char(DatWorkDate,'Mon') || '-' || to_char(DatWorkDate,'yyyy');
    
--    if to_char(asonDate,'MM') > 3 then
--      datYTD := '01-apr-' || to_char(asonDate,'yyyy');
--    else
--      datYTD := '01-apr-' || (to_char(asonDate,'yyyy') -1);
--    end if;
       
       
  if  to_char(DatWorkDate,'mm') <= 3 then 
    datYTD:=to_date('01-APR-' || to_char(to_number(to_char(DatWorkDate,'YYYY'))-1));
  else 
    datYTD :=to_date('01-APR-' || to_char(DatWorkDate,'YYYY'));
  end if; 
  
  if (to_number (to_char(DatWorkDate,'mm')) >=1 and  to_number (to_char(DatWorkDate,'mm')) <= 3) then 
    datQTD:=to_date('01-Jan-' || to_char(DatWorkDate,'YYYY'));
  elsif (to_number (to_char(DatWorkDate,'mm')) >=4 and  to_number (to_char(DatWorkDate,'mm')) <= 6) then 
    datQTD:=to_date('01-Jun-' || to_char(DatWorkDate,'YYYY'));
  elsif (to_number (to_char(DatWorkDate,'mm')) >=7 and  to_number (to_char(DatWorkDate,'mm')) <= 9) then 
    datQTD:=to_date('01-Sep-' || to_char(DatWorkDate,'YYYY'));
  elsif (to_number (to_char(DatWorkDate,'mm')) >=10 and  to_number (to_char(DatWorkDate,'mm')) <= 12) then 
    datQTD:=to_date('01-Oct-' || to_char(DatWorkDate,'YYYY'));
  end if; 
  
  if  to_char(DatWorkDate,'mm') <= 3 then 
    datYTD:=to_date('01-APR-' || to_char(to_number(to_char(DatWorkDate,'YYYY'))-1));
  else 
    datYTD :=to_date('01-APR-' || to_char(DatWorkDate,'YYYY'));
  end if; 
  datMTD:= trunc(datMTD);
  datQTD:= trunc(datQTD);
  datYTD:= trunc(datYTD);

  
  
  select (case when user_group_code in(14200001,14200003,14200006) then null
           else DealerID end)
    into DealerIDTemp
    from trsystem022
   where user_user_id =DealerID
     and user_record_status not in(10200005,10200006);
       
  delete from TRSYSTEM997_DELEARPOSITION;
  
  varOperation:= 'Insert Forward Trade Data';
  INSERT INTO TRSYSTEM997_DELEARPOSITION
  (DEPN_company_code,DEPN_CURRENCY_CODE,DEPN_OTHER_CURRENCY,DEPN_DEALER_NAME,DEPN_BASE_AMOUNT,
  DEPN_HOLDING_RATE,DEPN_OPEN_POSITION,DEPN_TOTAL_BUY,DEPN_TOTAL_SELL,
  DEPN_MTMPANDL_INR,
  DEPN_INSTRUMENT,DEPN_INIT_CODE,DEPN_BACKUP_DEAL)

with DealDetail as(
  select deal_company_code, deal_deal_number,deal_serial_number,deal_buy_sell,deal_exchange_rate,
        DEAL_BASE_CURRENCY,DEAL_OTHER_CURRENCY,DEAL_DEALER_NAME,
        DEAL_EXECUTE_DATE,deal_counter_party,deal_maturity_date,
      (pkgForexProcess.fncGetOutstanding(deal_deal_number,
            deal_serial_number,1,1,DatWorkDate)) OutstandingAmount ,
            DEAL_INIT_CODE,DEAL_BACKUP_DEAL
    from trtran001
   where  DEAL_RECORD_STATUS NOT IN(10200005,10200006)
      AND ((DEAL_PROCESS_COMPLETE = 12400001  and DEAL_COMPLETE_DATE >'15-oct-18')
                                  or DEAL_PROCESS_COMPLETE = 12400002)
      and instr(VarBackUpdeal,DEAL_BACKUP_DEAL)>0
      and instr(VarInitCode,DEAL_INIT_CODE)>0
      and DEAL_DEALER_NAME = (case when (DealerIDTemp is  null) then DEAL_DEALER_NAME else DealerIDTemp end)
      and instr(VarCompanyCode,deal_company_code)>0)
  
  select deal_company_code,DEAL_BASE_CURRENCY,DEAL_OTHER_CURRENCY,DEAL_DEALER_NAME, sum(OutstandingAmount),
         round(sum(OutstandingAmount*DEAL_EXCHANGE_RATE)/sum(OutstandingAmount),6) HoldingRate,
         sum(OutstandingAmount),
           SUM(Case When (DEAL_EXECUTE_DATE = DatWorkDate And DEAL_BUY_SELL= 25300001) 
              then OutstandingAmount Else 0 End) TOTALBUY,
           SUM(Case When (DEAL_EXECUTE_DATE = DatWorkDate And DEAL_BUY_SELL= 25300002) 
                          then OutstandingAmount Else 0 End )TOTALSELL,
        ROUND(sum(pkgreturnreport.fncgetprofitloss(OutstandingAmount,
            pkgforexprocess.fncGetRate(deal_base_currency,deal_other_currency,
            DatWorkDate,deal_buy_sell,(pkgForexProcess.fncAllotMonth(deal_counter_party,
            DatWorkDate,deal_maturity_date)),
            deal_maturity_date),
             DEAL_EXCHANGE_RATE, deal_buy_sell) *
            decode(deal_other_currency,30400003,1, pkgforexprocess.fncGetRate(deal_other_currency,30400003,
            DatWorkDate,deal_buy_sell,pkgForexProcess.fncAllotMonth(deal_counter_party,
            DatWorkDate,deal_maturity_date),deal_maturity_date))),2) MTMINR,
            'FORWARD',DEAL_INIT_CODE,DEAL_BACKUP_DEAL
    from DealDetail
    group by DEAL_BASE_CURRENCY,DEAL_OTHER_CURRENCY,DEAL_DEALER_NAME,
    DEAL_INIT_CODE,DEAL_BACKUP_DEAL,deal_company_code;
    commit;
    VarOperation:= ' Update the PnL Positions for Forwards';
    
    Update TRSYSTEM997_DELEARPOSITION set (DEPN_DTD,DEPN_MTD ,DEPN_QTD,DEPN_YTD)= 

        (select nvl(DTD,1),MTD,QTD,YTD from
              (select deal_company_code, DEAL_BASE_CURRENCY BaseCurrency,DEAL_OTHER_CURRENCY OtherCurrency,DEAL_DEALER_NAME DealerName,
                DEAL_INIT_CODE InitCode,DEAL_BACKUP_DEAL BackupDeal ,
                sum(case when Cdel_cancel_date =DatWorkDate then  CDEL_PROFIT_LOSS else 0 end) DTD,
                sum(case when Cdel_cancel_date between datMTD and DatWorkDate then  CDEL_PROFIT_LOSS else 0 end) MTD,
                sum(case when Cdel_cancel_date between datQTD and DatWorkDate then  CDEL_PROFIT_LOSS else 0 end) QTD,
                sum(case when Cdel_cancel_date between datYTD and DatWorkDate then  CDEL_PROFIT_LOSS else 0 end) YTD
        from  TRTRAN001 inner join TRTRAN006 
          on DEAL_DEAL_NUMBER = CDEL_DEAL_NUMBER
         AND CDEL_CANCEL_DATE BETWEEN datYTD AND DatWorkDate
         AND CDEL_RECORD_STATUS NOT IN(10200005,10200006)
         AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
         group by deal_company_code,DEAL_BASE_CURRENCY,DEAL_OTHER_CURRENCY,DEAL_DEALER_NAME,
                DEAL_INIT_CODE,DEAL_BACKUP_DEAL)
        where DEPN_CURRENCY_CODE=BaseCurrency
        and DEPN_OTHER_CURRENCY=OtherCurrency
        and DEPN_DEALER_NAME=DealerName
        and depn_company_code =deal_company_code
        and DEPN_INIT_CODE=InitCode
        and DEPN_BACKUP_DEAL=BackupDeal)
     where  DEPN_INSTRUMENT='FORWARD';
     
    
     varOperation:= 'Insert Future Trade Data';    
      INSERT INTO TRSYSTEM997_DELEARPOSITION
      (DEPN_COMPANY_CODE,DEPN_CURRENCY_CODE,DEPN_OTHER_CURRENCY,DEPN_DEALER_NAME,DEPN_BASE_AMOUNT,
      DEPN_HOLDING_RATE,DEPN_OPEN_POSITION,DEPN_TOTAL_BUY,DEPN_TOTAL_SELL,
      DEPN_TOTAL_POSITION,DEPN_PROFITLOSS_YTD,DEPN_MTMPANDL_INR,
      DEPN_INSTRUMENT,DEPN_INIT_CODE,DEPN_BACKUP_DEAL)
    
    with DealDetail as(
      select cfut_company_code, cfut_deal_number,1,cfut_buy_sell,CFUT_EXCHANGE_RATE,
            cfut_BASE_CURRENCY,cfut_OTHER_CURRENCY,Cfut_DEALER_NAME,Cfut_Exchange_Code,
            CFUT_EXECUTE_DATE,CFUT_maturity_date,
            Pkgforexprocess.Fncgetoutstanding(Cfut_Deal_Number, 0,14,1,DatWorkDate ) *1000 OutstandingAmount , -- because the Amount will be in lots
                CFUT_BACKUP_DEAL,CFUT_INIT_CODE
        FROM TRTRAN061
      WHERE CFUT_EXECUTE_DATE <= DatWorkDate
        AND ((CFUT_PROCESS_COMPLETE = 12400001  and CFUT_COMPLETE_DATE >DatWorkDate)
                                or CFUT_PROCESS_COMPLETE = 12400002)
        AND CFUT_RECORD_STATUS NOT IN(10200005,10200006)
        AND CFUT_RECORD_STATUS NOT IN(10200005,10200006)
        and instr(varBackUpdeal,CFUT_BACKUP_DEAL)>0
        and instr(varInitCode,CFUT_INIT_CODE)>0
        and CFUT_DEALER_NAME = (case when (DealerIDTemp is  null) then CFUT_DEALER_NAME else DealerIDTemp end)
        and instr(VarCompanyCode,CFUT_company_code)>0)
          
      SELECT cfut_company_code,CFUT_BASE_CURRENCY,CFUT_OTHER_CURRENCY,CFUT_DEALER_NAME,SUM(OutstandingAmount),
      ROUND(SUM(OutstandingAmount * CFUT_EXCHANGE_RATE)/SUM(OutstandingAmount),6),
      SUM(OutstandingAmount),
      SUM(Case When (CFUT_EXECUTE_DATE = DatWorkDate And CFUT_BUY_SELL= 25300001) 
                  then OutstandingAmount Else 0 End) TOTALBUY,
      SUM(Case When (CFUT_EXECUTE_DATE = DatWorkDate And CFUT_BUY_SELL= 25300002) 
                  then OutstandingAmount Else 0 End )TOTALSELL,
                0,0,
      ROUND(sum(Pkgforexprocess.Fncgetprofitloss(OutstandingAmount,
                Pkgforexprocess.Fncfuturemtmrate(Cfut_Maturity_Date,Cfut_Exchange_Code,Cfut_Base_Currency,Cfut_Other_Currency,DatWorkDate),
                Cfut_Exchange_Rate,Cfut_Buy_Sell) *
                Decode(Cfut_Other_Currency,30400003,1,Pkgforexprocess.Fncfuturemtmrate(Cfut_Maturity_Date,Cfut_Exchange_Code,
                CFUT_BASE_CURRENCY,CFUT_OTHER_CURRENCY, DatWorkDate))),2)MTMINR,
                'FUTURES', CFUT_INIT_CODE,CFUT_BACKUP_DEAL
      FROM DealDetail
      group by cfut_company_code,CFUT_BASE_CURRENCY,CFUT_OTHER_CURRENCY,CFUT_DEALER_NAME,
      CFUT_BACKUP_DEAL, CFUT_INIT_CODE;
     
      varOperation:= 'Update the Pnl Number for Futures';    
     
      Update TRSYSTEM997_DELEARPOSITION set (DEPN_DTD,DEPN_MTD ,DEPN_QTD,DEPN_YTD)= 
        (select DTD,MTD,QTD,YTD from
              (select cfut_company_code CompanyCode, CFUT_BASE_CURRENCY BaseCurrency,
                     CFUT_OTHER_CURRENCY OtherCurrency,CFUT_DEALER_NAME DealerName,
                CFUT_INIT_CODE InitCode,CFUT_BACKUP_DEAL BackupDeal ,
                sum(case when CFRV_EXECUTE_DATE =DatWorkDate then  CFRV_PROFIT_LOSS else 0 end) DTD,
                sum(case when CFRV_EXECUTE_DATE between datMTD and DatWorkDate then  CFRV_PROFIT_LOSS else 0 end) MTD,
                sum(case when CFRV_EXECUTE_DATE between datQTD and DatWorkDate then  CFRV_PROFIT_LOSS else 0 end) QTD,
                sum(case when CFRV_EXECUTE_DATE between datYTD and DatWorkDate then  CFRV_PROFIT_LOSS else 0 end) YTD
        from  TRTRAN061 inner join TRTRAN063 
          on CFUT_DEAL_NUMBER = CFRV_DEAL_NUMBER
         AND CFRV_EXECUTE_DATE BETWEEN datYTD AND DatWorkDate
         AND CFRV_RECORD_STATUS NOT IN(10200005,10200006)
         AND CFUT_RECORD_STATUS NOT IN(10200005,10200006)
--         where instr(VarBackUpdeal,CFUT_BACKUP_DEAL)>0
--            and instr(VarInitCode,CFUT_INIT_CODE)>0
--            and CFUT_DEALER_NAME = (case when (DealerIDTemp is  null) then CFUT_DEALER_NAME else DealerIDTemp end)
--            and instr(VarCompanyCode,CFUT_company_code)>0
         group by cfut_company_code, CFUT_BASE_CURRENCY,CFUT_OTHER_CURRENCY,CFUT_DEALER_NAME,
                CFUT_INIT_CODE,CFUT_BACKUP_DEAL)
        where DEPN_CURRENCY_CODE=BaseCurrency
        and DEPN_OTHER_CURRENCY=OtherCurrency
        and DEPN_DEALER_NAME=DealerName
        and DEPN_COMPANY_CODE=CompanyCode
        and DEPN_INIT_CODE=InitCode
        and DEPN_BACKUP_DEAL=BackupDeal)
     where  DEPN_INSTRUMENT='FUTURES';
     
           varOperation:= 'Insert Option Deals';    
  INSERT INTO TRSYSTEM997_DELEARPOSITION
  (DEPN_COMPANY_CODE,DEPN_CURRENCY_CODE,DEPN_OTHER_CURRENCY,DEPN_DEALER_NAME,DEPN_BASE_AMOUNT,
  DEPN_HOLDING_RATE,DEPN_OPEN_POSITION,DEPN_TOTAL_BUY,DEPN_TOTAL_SELL,
  DEPN_TOTAL_POSITION,DEPN_MTMPANDL_INR,
  DEPN_INSTRUMENT,DEPN_INIT_CODE,DEPN_BACKUP_DEAL)

 with OptDelta as 
   (select copt_company_code, COPT_BASE_CURRENCY, COPT_OTHER_CURRENCY,COPT_DEALER_NAME,
           Copt_Deal_Number DealNumber, COSU_SERIAL_NUMBER SerialNumber,
           (case when fncgetDeltaValue(Copt_Deal_Number,workDate)=0  then COSU_BASE_AMOUNT
                else fncgetDeltaValue(Copt_Deal_Number,workDate) end) Deltavalue,Copt_Deal_Number,
           COSU_BUY_SELL,COPT_EXECUTE_DATE,COSU_STRIKE_RATE,
           COPT_BACKUP_DEAL, COPT_INIT_CODE  
    from Trtran071,Trtran072
          Where Copt_Deal_Number = Cosu_Deal_Number
          and  Copt_Process_Complete =12400002
          and Copt_Record_Status Not In (10200005,10200006)
          and Cosu_Record_Status Not In (10200005,10200006)
         -- and Cosu_Buy_Sell=25300002
          and instr(VarCompanyCode,Copt_Company_Code)>0
          and instr(VarBackUpdeal,COPT_BACKUP_DEAL)>0
          and instr(VarInitCode,COPT_INIT_CODE)>0
          and COPT_DEALER_NAME = (case when (DealerIDTemp is  null) then COPT_DEALER_NAME else DealerIDTemp end))
 
    select copt_company_Code, COPT_BASE_CURRENCY, COPT_OTHER_CURRENCY,COPT_DEALER_NAME,
         SUM(Deltavalue),  round(sum(nvl(Deltavalue,0)*nvl(COSU_STRIKE_RATE,0))/sum(decode(nvl(Deltavalue,0),0,1,Deltavalue)),6),
         SUM(Deltavalue),
         SUM(Case When (COPT_EXECUTE_DATE = DatWorkDate And COSU_BUY_SELL= 25300001) 
              then Deltavalue Else 0 End) TOTALBUY,   
         SUM(Case When (COPT_EXECUTE_DATE = DatWorkDate And COSU_BUY_SELL= 25300002) 
              then Deltavalue Else 0 End) TOTALSELL,   SUM(Deltavalue),
         sum(fncgetUploadPrimiumValue(Copt_Deal_Number,workdate,2)) MTM,
         'OPTIONS', COPT_INIT_CODE    ,COPT_BACKUP_DEAL   
         From OptDelta
         group by copt_company_code, COPT_BASE_CURRENCY, COPT_OTHER_CURRENCY,COPT_DEALER_NAME,
         COPT_BACKUP_DEAL, COPT_INIT_CODE;
         
         
    varOperation:=' Update the Option Pnl Numbers';    
        
        update TRSYSTEM997_DELEARPOSITION 
        set (DEPN_DTD,DEPN_MTD ,DEPN_QTD,DEPN_YTD)= 
        (select DTD,MTD,QTD,YTD from
        
                           (select copt_company_code CompanyCode, COPT_BASE_CURRENCY BaseCurrency,
                                  COPT_OTHER_CURRENCY OtherCurrency,COPT_DEALER_NAME DealerName,
                                  COPT_INIT_CODE InitCode,COPT_BACKUP_DEAL BackupDeal ,
                            sum(case when CORV_EXERCISE_DATE =DatWorkDate then
                                (case when COPT_PREMIUM_STATUS =33200002 then -1 * copt_Premium_amount --33200002 Paid
                                     else 0 end) + CORV_PROFIT_LOSS else 0 end) DTD,
                            sum(case when CORV_EXERCISE_DATE between datMTD and DatWorkDate then 
                            (case when COPT_PREMIUM_STATUS =33200002 then -1 * copt_Premium_amount
                                     else 0 end) + CORV_PROFIT_LOSS else 0 end) MTD,
                            sum(case when CORV_EXERCISE_DATE between datQTD and DatWorkDate then
                            (case when COPT_PREMIUM_STATUS =33200002 then -1 * copt_Premium_amount
                                     else 0 end) + CORV_PROFIT_LOSS else 0 end) QTD,
                            sum(case when CORV_EXERCISE_DATE between datYTD and DatWorkDate then 
                            (case when COPT_PREMIUM_STATUS =33200002 then -1 * copt_Premium_amount
                                     else 0 end) +CORV_PROFIT_LOSS else 0 end) YTD
                            
                       FROM TRTRAN071 inner join trtran072
                       on COSU_DEAL_NUMBER=COPT_DEAL_NUMBER
                       inner join TRTRAN073 
                       on CORV_DEAL_NUMBER=COPT_DEAL_NUMBER
                       and CORV_SERIAL_NUMBER=COPT_SERIAL_NUMBER
                       where COPT_RECORD_STATUS not in (10200005,10200006)
                        and cosu_record_Status not in (10200005,10200006)
                        and corv_record_Status not in (10200005,10200006)
                        AND CORV_EXERCISE_DATE BETWEEN datYTD AND DatWorkDate
--                        and instr(VarBackUpdeal,COPT_BACKUP_DEAL)>0
--                        and instr(VarInitCode,COPT_INIT_CODE)>0
--                        and COPT_DEALER_NAME = (case when (DealerIDTemp is  null) then COPT_DEALER_NAME else DealerIDTemp end)
--                        and instr(VarCompanyCode,COPT_company_code)>0
                        GROUP BY copt_company_code, COPT_BASE_CURRENCY, COPT_OTHER_CURRENCY,COPT_DEALER_NAME,
                            COPT_BACKUP_DEAL, COPT_INIT_CODE) Unwind
                    where DEPN_CURRENCY_CODE=BaseCurrency
                    and DEPN_OTHER_CURRENCY=OtherCurrency
                    and DEPN_DEALER_NAME=DealerName
                    and DEPN_COMPANY_CODE=CompanyCode
                    and DEPN_INIT_CODE=InitCode
                    and DEPN_BACKUP_DEAL=BackupDeal)
                 where  DEPN_INSTRUMENT='OPTIONS';
                     









--         
--         
--          on Copt_Deal_Number=OptDelta.DealNumber 
--          and cosu_serial_number=optDlta.SerialNumber
--          where Copt_Process_Complete =12400002
--          and Copt_Record_Status Not In (10200005,10200006)
--          and Cosu_Record_Status Not In (10200005,10200006)
--         -- and Cosu_Buy_Sell=25300002
--          and Copt_Company_Code =Decode(Numcode,30199999,Copt_Company_Code,Numcode)
--          and copt_Company_Code in( select usco_company_code from trsystem022a
--                                        where usco_user_id =vartemp)
--         -- and Copt_Hedge_Trade=26000002
--          and copt_user_id =(case when (vartemp1 is  null) then copt_user_id else vartemp1 end)
--        group by COPT_BASE_CURRENCY,COPT_OTHER_CURRENCY,COPT_DEALER_NAME,copt_company_name,
--        COPT_BACKUP_DEAL, COPT_INIT_CODE;
--        
--    varOperation:=' Update the Option Pnl Numbers';    
--        
--        update TRSYSTEM997_DELEARPOSITION set  DEPN_PROFITLOSS_YTD = ( 
--                   select PnL from
--                     select copt_company_code, COPT_BASE_CURRENCY, COPT_OTHER_CURRENCY,
--                           COPT_DEALER_NAME, COPT_BACKUP_DEAL, COPT_INIT_CODE,
--                            sum(CORV_PROFIT_LOSS) PnL
--                       FROM TRTRAN071 inner join tftran072
--                       on COSU_DEAL_NUMBER=COPT_DEAL_NUMBER
--                       inner join TRTRAN073 
--                       on CORV_DEAL_NUMBER=COPT_DEAL_NUMBER
--                       and CORV_SERIAL_NUMBER=COPT_SERIAL_NUMBER
--                       where COPT_RECORD_STATUS not in (10200005,10200006)
--                        and cosu_record_Status not in (10200005,10200006)
--                        and corv_record_Status not in (10200005,10200006)
--                        AND CORV_EXERCISE_DATE BETWEEN datTemp AND DatWorkDate
--                        and instr(varCompany,copt_company_code)>0
--                        and copt_DEALER_NAME = (case when (DealerIDTemp is  null) then copt_DEALER_NAME else DealerIDTemp end)
--                        GROUP BY copt_company_code, COPT_BASE_CURRENCY, COPT_OTHER_CURRENCY,COPT_DEALER_NAME,
--                            COPT_BACKUP_DEAL, COPT_INIT_CODE) Unwind
--                   where DEPN_CURRENCY_CODE =COPT_BASE_CURRENCY 
--                     and DEPN_OTHER_CURRENCY=COPT_OTHER_CURRENCY
--                     and DEPN_DEALER_NAME=COPT_DEALER_NAME
--                     and DEPN_BACKUP_DEAL=COPT_BACKUP_DEAL
--                     and DEPN_INIT_CODE=COPT_INIT_CODE
--                     and depn_company_code= copt_company_code;
--                     
--                     
--   
----    update TRSYSTEM997_DELEARPOSITION set  DEPN_PROFITLOSS_YTD = ( 
----    (SELECT SUM(CFRV_PROFIT_LOSS)ProfitLoss,CFUT_BASE_CURRENCY BaseCurrency,
----           CFUT_OTHER_CURRENCY OtherCurrency,CFUT_DEALER_NAME DealerName ,
----           CFUT_BACKUP_DEAL BackUpDeal, CFUT_INIT_CODE INITCode
----       FROM TRTRAN061,TRTRAN063 
----         WHERE CFUT_DEAL_NUMBER = CFRV_DEAL_NUMBER
----         AND CFUT_RECORD_STATUS NOT IN(10200005,10200006)
----         AND CFRV_RECORD_STATUS NOT IN(10200005,10200006)
----         AND CFRV_EXECUTE_DATE BETWEEN datTemp AND DatWorkDate
----         and CFUT_DEALER_NAME = (case when (DealerIDTemp is  null) then CFUT_DEALER_NAME else DealerIDTemp end)
----         GROUP BY CFUT_BASE_CURRENCY,CFUT_OTHER_CURRENCY,CFUT_DEALER_NAME,
----         CFUT_BACKUP_DEAL,CFUT_INIT_CODE)CancelData
--         
--
--    
--    
--    
--    
--        
--                
--      and DEAL_DEALER_NAME = (case when (DealerIDTemp is  null) then DEAL_DEALER_NAME else DealerIDTemp end)
--      GROUP BY DEAL_BASE_CURRENCY,DEAL_OTHER_CURRENCY, DEAL_DEALER_NAME,
--      DEAL_INIT_CODE,DEAL_BACKUP_DEAL)
--    
--  SELECT DEAL_BASE_CURRENCY,DEAL_OTHER_CURRENCY,DEAL_DEALER_NAME,SUM(DEAL_BASE_AMOUNT),
--  ROUND(SUM(pkgForexProcess.fncGetOutstanding(deal_deal_number,
--            deal_serial_number,1,1,DatWorkDate) * DEAL_EXCHANGE_RATE)/SUM(pkgForexProcess.fncGetOutstanding(deal_deal_number,
--            deal_serial_number,1,1,DatWorkDate)),6),
--  SUM(pkgForexProcess.fncGetOutstanding(deal_deal_number,deal_serial_number,1,1,DatWorkDate)),
--  SUM(Case When (DEAL_EXECUTE_DATE = DatWorkDate And DEAL_BUY_SELL= 25300001) 
--              then pkgForexProcess.fncGetOutstanding(deal_deal_number,
--            deal_serial_number,1,1,DatWorkDate) Else 0 End) TOTALBUY,
--  SUM(Case When (DEAL_EXECUTE_DATE = DatWorkDate And DEAL_BUY_SELL= 25300002) 
--              then pkgForexProcess.fncGetOutstanding(deal_deal_number,
--            deal_serial_number,1,1,DatWorkDate) Else 0 End )TOTALSELL,
--            0,CancelData.ProfitLoss,
--  ROUND(sum(pkgreturnreport.fncgetprofitloss(pkgForexProcess.fncGetOutstanding(deal_deal_number,
--            deal_serial_number,1,1,DatWorkDate),
--            pkgforexprocess.fncGetRate(deal_base_currency,deal_other_currency,
--            DatWorkDate,deal_buy_sell,(pkgForexProcess.fncAllotMonth(deal_counter_party,
--            DatWorkDate,deal_maturity_date)),
--            deal_maturity_date),
--             DEAL_EXCHANGE_RATE, deal_buy_sell) *
--            decode(deal_other_currency,30400003,1, pkgforexprocess.fncGetRate(deal_other_currency,30400003,
--            DatWorkDate,deal_buy_sell,pkgForexProcess.fncAllotMonth(deal_counter_party,
--            DatWorkDate,deal_maturity_date),deal_maturity_date))),2)MTMINR,
--            'FORWARD',DEAL_INIT_CODE,DEAL_BACKUP_DEAL
--  FROM TRTRAN001,  
--  (SELECT SUM(CDEL_PROFIT_LOSS)ProfitLoss,DEAL_BASE_CURRENCY BaseCurrency,
--          DEAL_OTHER_CURRENCY OtherCurrency, DEAL_DEALER_NAME DealerName ,
--          DEAL_INIT_CODE INITCode,DEAL_BACKUP_DEAL BackUpDeal
--     FROM TRTRAN001,TRTRAN006 
--      WHERE DEAL_DEAL_NUMBER = CDEL_DEAL_NUMBER
--      AND CDEL_CANCEL_DATE BETWEEN datTemp AND DatWorkDate
--      AND CDEL_RECORD_STATUS NOT IN(10200005,10200006)
--      AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
--      and DEAL_DEALER_NAME = (case when (DealerIDTemp is  null) then DEAL_DEALER_NAME else DealerIDTemp end)
--      GROUP BY DEAL_BASE_CURRENCY,DEAL_OTHER_CURRENCY, DEAL_DEALER_NAME,
--      DEAL_INIT_CODE,DEAL_BACKUP_DEAL) CancelData
--  WHERE DEAL_EXECUTE_DATE <= DatWorkDate
--  AND ((DEAL_PROCESS_COMPLETE = 12400001  and DEAL_COMPLETE_DATE >DatWorkDate)
--                            or DEAL_PROCESS_COMPLETE = 12400002)
--  AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
--  AND DEAL_BASE_CURRENCY = CancelData.BaseCurrency
--  AND DEAL_OTHER_CURRENCY = CancelData.OtherCurrency
--  AND DEAL_DEALER_NAME = CancelData.DealerName
--  and DEAL_INIT_CODE= cancelData.INITCode
--  and DEAL_BACKUP_DEAL= cancelData.BackUpDeal
--  and instr(VarBackUpdeal,DEAL_BACKUP_DEAL)>0
--  and instr(VarInitCode,DEAL_INIT_CODE)>0
--  and DEAL_DEALER_NAME = (case when (DealerIDTemp is  null) then DEAL_DEALER_NAME else DealerIDTemp end)
--  GROUP BY DEAL_BASE_CURRENCY,DEAL_OTHER_CURRENCY,DEAL_DEALER_NAME,
--      CancelData.ProfitLoss,DEAL_INIT_CODE,DEAL_BACKUP_DEAL;
--      
--  varOperation:= 'Insert Future Trade Data';    
--  INSERT INTO TRSYSTEM997_DELEARPOSITION
--  (DEPN_CURRENCY_CODE,DEPN_OTHER_CURRENCY,DEPN_DEALER_NAME,DEPN_BASE_AMOUNT,
--  DEPN_HOLDING_RATE,DEPN_OPEN_POSITION,DEPN_TOTAL_BUY,DEPN_TOTAL_SELL,
--  DEPN_TOTAL_POSITION,DEPN_PROFITLOSS_YTD,DEPN_MTMPANDL_INR,
--  DEPN_INSTRUMENT,DEPN_INIT_CODE,DEPN_BACKUP_DEAL)
--
--  SELECT CFUT_BASE_CURRENCY,CFUT_OTHER_CURRENCY,CFUT_DEALER_NAME,SUM(CFUT_BASE_AMOUNT),
--  ROUND(SUM((Pkgforexprocess.Fncgetoutstanding(Cfut_Deal_Number, 0,14,1,DatWorkDate )*1000) * CFUT_EXCHANGE_RATE)/SUM((Pkgforexprocess.Fncgetoutstanding(Cfut_Deal_Number, 0,14,1,DatWorkDate )*1000)),6),
--  SUM((Pkgforexprocess.Fncgetoutstanding(Cfut_Deal_Number, 0,14,1,DatWorkDate )*1000)),
--  SUM(Case When (CFUT_EXECUTE_DATE = DatWorkDate And CFUT_BUY_SELL= 25300001) 
--              then (Pkgforexprocess.Fncgetoutstanding(Cfut_Deal_Number, 0,14,1,DatWorkDate )*1000) Else 0 End) TOTALBUY,
--  SUM(Case When (CFUT_EXECUTE_DATE = DatWorkDate And CFUT_BUY_SELL= 25300002) 
--              then (Pkgforexprocess.Fncgetoutstanding(Cfut_Deal_Number, 0,14,1,DatWorkDate )*1000) Else 0 End )TOTALSELL,
--            0,CancelData.ProfitLoss,
--  ROUND(sum(Pkgforexprocess.Fncgetprofitloss((Pkgforexprocess.Fncgetoutstanding(Cfut_Deal_Number, 0,14,1,DatWorkDate )*1000),
--            Pkgforexprocess.Fncfuturemtmrate(Cfut_Maturity_Date,Cfut_Exchange_Code,Cfut_Base_Currency,Cfut_Other_Currency,DatWorkDate),
--            Cfut_Exchange_Rate,Cfut_Buy_Sell) *
--            Decode(Cfut_Other_Currency,30400003,1,Pkgforexprocess.Fncfuturemtmrate(Cfut_Maturity_Date,Cfut_Exchange_Code,
--            CFUT_BASE_CURRENCY,CFUT_OTHER_CURRENCY, DatWorkDate))),2)MTMINR,
--            'FUTURES',CFUT_BACKUP_DEAL, CFUT_INIT_CODE
--  FROM TRTRAN061
--  WHERE CFUT_EXECUTE_DATE <= DatWorkDate
--  AND ((CFUT_PROCESS_COMPLETE = 12400001  and CFUT_COMPLETE_DATE >DatWorkDate)
--                            or CFUT_PROCESS_COMPLETE = 12400002)
--                            AND CFUT_RECORD_STATUS NOT IN(10200005,10200006)
--  AND CFUT_RECORD_STATUS NOT IN(10200005,10200006)
--  AND CFUT_BASE_CURRENCY = CancelData.BaseCurrency
--  AND CFUT_OTHER_CURRENCY = CancelData.OtherCurrency
--  AND CFUT_DEALER_NAME = CancelData.DealerName       
--  and CFUT_BACKUP_DEAL= canceldata.Backupdeal
--  and cfut_init_code= cancelData.VarInitCode
--  and CFUT_DEALER_NAME = (case when (DealerIDTemp is  null) then CFUT_DEALER_NAME else DealerIDTemp end)
--  GROUP BY CFUT_BASE_CURRENCY,CFUT_OTHER_CURRENCY,CFUT_DEALER_NAME,CancelData.ProfitLoss,
--  CFUT_BACKUP_DEAL, CFUT_INIT_CODE;
--   
--   
----    update TRSYSTEM997_DELEARPOSITION set  DEPN_PROFITLOSS_YTD = ( 
----    (SELECT SUM(CFRV_PROFIT_LOSS)ProfitLoss,CFUT_BASE_CURRENCY BaseCurrency,
----           CFUT_OTHER_CURRENCY OtherCurrency,CFUT_DEALER_NAME DealerName ,
----           CFUT_BACKUP_DEAL BackUpDeal, CFUT_INIT_CODE INITCode
----       FROM TRTRAN061,TRTRAN063 
----         WHERE CFUT_DEAL_NUMBER = CFRV_DEAL_NUMBER
----         AND CFUT_RECORD_STATUS NOT IN(10200005,10200006)
----         AND CFRV_RECORD_STATUS NOT IN(10200005,10200006)
----         AND CFRV_EXECUTE_DATE BETWEEN datTemp AND DatWorkDate
----         and CFUT_DEALER_NAME = (case when (DealerIDTemp is  null) then CFUT_DEALER_NAME else DealerIDTemp end)
----         GROUP BY CFUT_BASE_CURRENCY,CFUT_OTHER_CURRENCY,CFUT_DEALER_NAME,
----         CFUT_BACKUP_DEAL,CFUT_INIT_CODE)CancelData
--         
--         
--   varOperation:='Insert Option Postion'; 
--   
-- INSERT INTO TRSYSTEM997_DELEARPOSITION
--  (DEPN_CURRENCY_CODE,DEPN_OTHER_CURRENCY,DEPN_DEALER_NAME,DEPN_BASE_AMOUNT,
--  DEPN_HOLDING_RATE,DEPN_OPEN_POSITION,DEPN_TOTAL_BUY,DEPN_TOTAL_SELL,
--  DEPN_TOTAL_POSITION,DEPN_PROFITLOSS_YTD,DEPN_MTMPANDL_INR,
--  DEPN_INSTRUMENT,DEPN_INIT_CODE,DEPN_BACKUP_DEAL)
--
-- with OptDelta as 
--   (select Copt_Deal_Number DealNumber, COSU_SERIAL_NUMBER SerialNumber,
--           pkgForexProcess.fncgetDeltaValue(Copt_Deal_Number,workDate) Deltavalue
--    from Trtran071,Trtran072
--          Where Copt_Deal_Number = Cosu_Deal_Number
--          and  Copt_Process_Complete =12400002
--          and Copt_Record_Status Not In (10200005,10200006)
--          and Cosu_Record_Status Not In (10200005,10200006)
--         -- and Cosu_Buy_Sell=25300002
--          and instr(VarCompanyCode,Copt_Company_Code)>0
--          and copt_Company_Code in( select usco_company_code from trsystem022a
--                                        where usco_user_id =vartemp)
--          and copt_user_id =(case when (vartemp1 is  null) then copt_user_id else vartemp1 end))
--  
--    select copt_company_name, COPT_BASE_CURRENCY, COPT_OTHER_CURRENCY,COPT_DEALER_NAME,
--         SUM(Deltavalue),COSU_STRIKE_RATE, round(sum(Deltavalue*COSU_STRIKE_RATE)/sum(Deltavalue),6),
--         SUM(Case When (COPT_EXECUTE_DATE = DatWorkDate And COSU_BUY_SELL= 25300001) 
--              then Deltavalue Else 0 End) TOTALBUY,   
--         SUM(Case When (COPT_EXECUTE_DATE = DatWorkDate And COSU_BUY_SELL= 25300002) 
--              then Deltavalue Else 0 End) TOTALSELL,   
--         fncgetUploadPrimiumValue(Copt_Deal_Number,workdate,2) MTM,
--         'Options',COPT_BACKUP_DEAL, COPT_INIT_CODE       
--         From Trtran071 inner join Trtran072
--          on  Copt_Deal_Number = Cosu_Deal_Number
--          inner join OptDelta
--          on Copt_Deal_Number=OptDelta.DealNumber 
--          and cosu_serial_number=optDlta.SerialNumber
--          where Copt_Process_Complete =12400002
--          and Copt_Record_Status Not In (10200005,10200006)
--          and Cosu_Record_Status Not In (10200005,10200006)
--         -- and Cosu_Buy_Sell=25300002
--          and Copt_Company_Code =Decode(Numcode,30199999,Copt_Company_Code,Numcode)
--          and copt_Company_Code in( select usco_company_code from trsystem022a
--                                        where usco_user_id =vartemp)
--         -- and Copt_Hedge_Trade=26000002
--          and copt_user_id =(case when (vartemp1 is  null) then copt_user_id else vartemp1 end)
--        group by COPT_BASE_CURRENCY,COPT_OTHER_CURRENCY,COPT_DEALER_NAME,copt_company_name,
--        COPT_BACKUP_DEAL, COPT_INIT_CODE;
--        
--    varOperation:=' Update the Option Pnl Numbers';    
--        
--        update TRSYSTEM997_DELEARPOSITION set  DEPN_PROFITLOSS_YTD = ( 
--                   select PnL from
--                     select copt_company_code, COPT_BASE_CURRENCY, COPT_OTHER_CURRENCY,
--                           COPT_DEALER_NAME, COPT_BACKUP_DEAL, COPT_INIT_CODE,
--                            sum(CORV_PROFIT_LOSS) PnL
--                       FROM TRTRAN071 inner join tftran072
--                       on COSU_DEAL_NUMBER=COPT_DEAL_NUMBER
--                       inner join TRTRAN073 
--                       on CORV_DEAL_NUMBER=COPT_DEAL_NUMBER
--                       and CORV_SERIAL_NUMBER=COPT_SERIAL_NUMBER
--                       where COPT_RECORD_STATUS not in (10200005,10200006)
--                        and cosu_record_Status not in (10200005,10200006)
--                        and corv_record_Status not in (10200005,10200006)
--                        AND CORV_EXERCISE_DATE BETWEEN datTemp AND DatWorkDate
--                        and instr(varCompany,copt_company_code)>0
--                        and copt_DEALER_NAME = (case when (DealerIDTemp is  null) then copt_DEALER_NAME else DealerIDTemp end)
--                        GROUP BY copt_company_code, COPT_BASE_CURRENCY, COPT_OTHER_CURRENCY,COPT_DEALER_NAME,
--                            COPT_BACKUP_DEAL, COPT_INIT_CODE) Unwind
--                   where DEPN_CURRENCY_CODE =COPT_BASE_CURRENCY 
--                     and DEPN_OTHER_CURRENCY=COPT_OTHER_CURRENCY
--                     and DEPN_DEALER_NAME=COPT_DEALER_NAME
--                     and DEPN_BACKUP_DEAL=COPT_BACKUP_DEAL
--                     and DEPN_INIT_CODE=COPT_INIT_CODE
--                     and depn_company_code= copt_company_code;
--                     
--                  
--      
--      

  delete TRSYSTEM997_DELEARPOSITION where DEPN_DEALER_NAME='Pawan';
  
  varOperation:= 'Update Total Position';  
  update TRSYSTEM997_DELEARPOSITION set DEPN_TOTAL_POSITION= DEPN_OPEN_POSITION+DEPN_TOTAL_SELL-DEPN_TOTAL_BUY;
 
   varOperation:= 'Update Dealer Budget';  
  update TRSYSTEM997_DELEARPOSITION set DEPN_Dealer_budget = (select BUDG_BUDGET_USD from trsystem016 where BUDG_DEALER_ID= DEPN_DEALER_NAME
      and BUDG_record_Status not in (10200005,10200006));
   varOperation:= 'Update Postion Conversion Rate';
     update TRSYSTEM997_DELEARPOSITION set DEPN_Dealer_budget = (select BUDG_BUDGET_USD from trsystem016 where BUDG_DEALER_ID= DEPN_DEALER_NAME
      and BUDG_record_Status not in (10200005,10200006));
      
   varOperation:= 'Update Position in USD ';      
  update TRSYSTEM997_DELEARPOSITION set depn_Postion_USD = DEPN_TOTAL_POSITION * 
      decode(DEPN_CURRENCY_CODE,30400004,1, pkgforexprocess.fncGetRate(DEPN_CURRENCY_CODE,30400004,
            DatWorkDate,25399999,1));
            
  update TRSYSTEM997_DELEARPOSITION set depn_Position_RATE=1;
  
--  FOR CUR_IN IN(SELECT * FROM TRSYSTEM997_DELEARPOSITION)
--    LOOP
--      numHedgeSell  := CUR_IN.DEPN_TOTAL_SELL;
--      numHedgeBuy   := CUR_IN.DEPN_TOTAL_BUY;
--      numOpenBal    := CUR_IN.DEPN_OPEN_POSITION;
--      
--      numClosingBal := NVL(numOpenBal,0) +(NVL(numHedgeSell,0) - NVL(numHedgeBuy,0));
--      UPDATE TRSYSTEM997_DELEARPOSITION SET  DEPN_TOTAL_POSITION = NVL(numClosingBal,0) 
--                                        WHERE DEPN_CURRENCY_CODE = CUR_IN.DEPN_CURRENCY_CODE
--                                        AND DEPN_OTHER_CURRENCY = CUR_IN.DEPN_OTHER_CURRENCY
--                                        AND DEPN_DEALER_NAME = CUR_IN.DEPN_DEALER_NAME
--                                        AND DEPN_INSTRUMENT = CUR_IN.DEPN_INSTRUMENT;
--  END LOOP;
  
  varOperation:= 'Update Total Position';  
  
    INSERT INTO TRSYSTEM997_DELEARPOSITION
      (DEPN_CURRENCY_CODE,DEPN_OTHER_CURRENCY,DEPN_DEALER_NAME,DEPN_BASE_AMOUNT,
      DEPN_HOLDING_RATE,DEPN_OPEN_POSITION,DEPN_TOTAL_BUY,DEPN_TOTAL_SELL,
      DEPN_TOTAL_POSITION,DEPN_PROFITLOSS_YTD,DEPN_MTMPANDL_INR,
      DEPN_INSTRUMENT,DEPN_INIT_CODE,DEPN_BACKUP_DEAL,DEPN_YTD)
      SELECT DEPN_CURRENCY_CODE,DEPN_OTHER_CURRENCY,
            'ALL',SUM(DEPN_BASE_AMOUNT),ROUND(SUM(nvl(DEPN_OPEN_POSITION,0) * nvl(DEPN_HOLDING_RATE,0))/SUM(decode(nvl(DEPN_OPEN_POSITION,0),0,1,DEPN_OPEN_POSITION)),6),
             SUM(DEPN_OPEN_POSITION),SUM(DEPN_TOTAL_BUY),SUM(DEPN_TOTAL_SELL),SUM(DEPN_TOTAL_POSITION),
             SUM(nvl(DEPN_PROFITLOSS_YTD,0)),SUM(nvl(DEPN_MTMPANDL_INR,0)),DEPN_INSTRUMENT ,
             DEPN_INIT_CODE,DEPN_BACKUP_DEAL,
             SUM(nvl(DEPN_YTD,0))
      FROM TRSYSTEM997_DELEARPOSITION 
      GROUP BY DEPN_CURRENCY_CODE,DEPN_OTHER_CURRENCY,DEPN_INSTRUMENT,
      DEPN_INIT_CODE,DEPN_BACKUP_DEAL;

  COMMIT;
  
Exception
	when others then
      numError := SQLCODE;
      varError := SQLERRM ;
      varError := GConst.fncReturnError('Dealer Position', numError, varMessage, 
                      varOperation, varError);
      ROLLBACK;                      
      raise_application_error(-20101, varError); 
End prcDealerPostion;
/