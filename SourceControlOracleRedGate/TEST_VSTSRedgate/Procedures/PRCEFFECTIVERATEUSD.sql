CREATE OR REPLACE PROCEDURE "TEST_VSTSRedgate"."PRCEFFECTIVERATEUSD" 
(FrmDate  Date ,Todate Date,Condition  varchar,SerialNo number)
as
    
    ----USD-----------------------------
    CostOpenHedgeFCY          number(15,2) := 0; --
    CostOpenUnhedgeFCY        number(15,2) := 0;--
    CostOpenHedgeINR          number(15,2) := 0;--
    CostOpenUnhedgeINR        number(15,2) := 0;--
    EffectOpenHedgedINR       NUMBER(15,2) := 0;--
    EffectOpenUnhedgedINR     NUMBER(15,2) := 0;--
    FC_Cancellation           NUMBER(15,2) := 0;--
    OpenHedged_MTM            NUMBER(15,2) := 0;--
    Future_MTM                NUMBER(15,2) := 0;--
    Option_MTM                NUMBER(15,2) := 0;--
    Option_Realize            Number(15,2) := 0;--
    Frwd_ContractFcy          NUMBER(15,2) := 0;--
    Ftr_ContractFCY           NUMBER(15,2) := 0;
    Frwd_ContractINR          NUMBER(15,2) := 0;--
    Ftr_ContractINR           NUMBER(15,2) := 0;
    FcDelivery_Fcy            NUMBER(15,2) := 0;
    FcdeliveryCost_Inr        NUMBER(15,2) := 0;
    FcDeliveryEffect_Inr      NUMBER(15,2) := 0;
    tradereference            varchar(30 byte);
    CashSettle_Fcy            NUMBER(15,2) := 0;
    CashSettleCost_Inr        NUMBER(15,2) := 0;
    CashSettleEffect_Inr      NUMBER(15,2) := 0;
    BCFcy                     NUMBER(15,2) := 0;
    BCCostInr                 NUMBER(15,2) := 0;
    BCEffectInr               NUMBER(15,2) := 0;
    CFBuy                     NUMBER(15,2) :=0;
    CFSell                    NUMBER(15,2) :=0;
    CFBuyINR                  Number(15,2) :=0;
    CFSellINR                 Number(15,2) :=0;
    CfuMTMPLV                 Number(15,2) :=0;
    CoptMTMV                  Number(15,2) :=0;
    CoptRELV                  Number(15,2) :=0;
    FuturPandL                Number(15,2) :=0;
    varTemp                   varchar (1000 Byte);
    ------OtherCurrency
    
    CostOpenUnhedgeFCY_Other  Number(15,2) :=0;
    CostOpenUnhedgeINR_Other  Number(15,2) :=0;
    EffectOpenUnhedgedINR_Other Number(15,2) :=0;
    BCFcy_Other               Number(15,2) :=0;
    BCCostInr_Other           Number(15,2) :=0;
    BCEffectInr_Other         Number(15,2) :=0;
    FcDelivery_Fcy_Other      Number(15,2) :=0;
    FcdeliveryCost_Inr_Other  Number(15,2) :=0;
    FcDeliveryEffect_Inr_Other Number(15,2) :=0;
    CashSettle_Fcy_Other      number(15,2) :=0;
    CashSettleEffect_Inr_Other number(15,2):=0;
    CashSettleCost_Inr_Other  number(15,2):=0;
    Frwd_ContractFcy_Other    number(15,2):=0;
    Frwd_ContractINR_Other    number(15,2):=0;
    CFSell_Other              number(15,2):=0;
    CFSellINR_Other           number(15,2):=0;
    CFBuy_Other               number(15,2):=0;
    CFBuyINR_Other            number(15,2):=0;
    wtavgfutur                number(15,6):= 0;
    ToatlAmountFutu           number(15,2):=0;
    
    -------------------
    Slno                      Number(2);
    Frm_date                  date;
    To_date                   date;
    Company_code              number(8);
    Currency_Code             number(8);
begin
    Slno                := SerialNo;
    Frm_date            := FrmDate;
    To_date             := Todate;
    Company_code        := substr(Condition,1,8);
    Currency_Code       := 30400004;
------------------Costing And Effective rate openHedge

       begin 
        
        Select 
          nvl(Sum(Hedg_Hedged_Fcy),0) HedgedamtfcyCosting,
          case Currency_Code when 30400004 then    
          nvl(sum(Hedg_Other_Fcy),0) 
          else 
            nvl(sum(HEDG_HEDGED_INR),0) 
          end as ProductinrCosting,
          nvl(Sum(Pkgforexprocess.Fncgetrate(Currency_Code,30400003,To_date,0,0,Trad_Maturity_Date)*nvl(Hedg_Hedged_Fcy,0)),0) Productinreffective
          into CostOpenHedgeFCY,CostOpenHedgeINR,EffectOpenHedgedINR
        FROM Trtran004,Trtran002
          WHERE Trad_Trade_Reference = Hedg_Trade_Reference
          And Trad_Process_Complete  = 12400002
          And Hedg_Record_Status    In(10200001,10200002,10200003,10200004) 
          and TRAD_REFERENCE_DATE <= To_date
          and Hedg_Company_Code = Company_code
          and TRAD_TRADE_CURRENCY = Currency_Code
        group by Hedg_Company_Code;
 --        Select 
 --        sum(pkgForexProcess.fncGetOutstanding(deal_deal_number, deal_serial_number,1,1,Frm_date)) HedgedamtfcyCosting,
 --        sum(DEAL_OTHER_AMOUNT) ProductinrCosting,
 --        sum((Pkgforexprocess.Fncgetrate(DEAL_BASE_CURRENCY,DEAL_OTHER_CURRENCY,To_date,0,0,DEAL_MATURITY_DATE)*pkgForexProcess.fncGetOutstanding(deal_deal_number, deal_serial_number,1,1,Frm_date)))Productinreffective
 --        --sum(DEAL_OTHER_AMOUNT) / sum(pkgForexProcess.fncGetOutstanding(deal_deal_number, deal_serial_number,1,1,Frm_date)) Productinreffective
 --        into CostOpenHedgeFCY,CostOpenHedgeINR,EffectOpenHedgedINR
 --        from trtran001 where
 --         DEAL_RECORD_STATUS not in(10200005,10200006) and DEAL_MATURITY_DATE >= Frm_date and DEAL_EXECUTE_DATE <= Frm_date 
 --     AND ((DEAL_PROCESS_COMPLETE = 12400001  and DEAL_complete_date > Frm_date) or DEAL_PROCESS_COMPLETE = 12400002)
 --     and DEAL_COMPANY_CODE = Company_code
 --     and DEAL_BASE_CURRENCY = 30400004
 --       group by DEAL_COMPANY_CODE;
         
        
  
       exception
       when no_data_found then
         CostOpenHedgeFCY := 0;
         CostOpenHedgeINR :=0;
         EffectOpenHedgedINR := 0;
       end;
----------------------------------------Costiing And Effective Unhedge-----
       begin 
        Select 
          Sum((Pkgforexprocess.Fncgetoutstanding(Trad_Trade_Reference,0,0,1,To_date)- nvl((SELECT NVL(SUM(HEDG_HEDGED_FCY),0) FROM trtran004
        WHERE HEDG_TRADE_REFERENCE = trad_trade_reference and Hedg_Record_Status not in (10200005,10200006,10200012) ),0))) HedgedamtfcyCosting,
          sum((Pkgforexprocess.Fncgetoutstanding(Trad_Trade_Reference,0,0,1,To_date)- (SELECT NVL(SUM(HEDG_HEDGED_FCY),0) FROM trtran004
        WHERE HEDG_TRADE_REFERENCE = trad_trade_reference and Hedg_Record_Status not in (10200005,10200006,10200012) )) * TRAD_TRADE_RATE) As ProductinrCosting,
          Sum(Pkgforexprocess.Fncgetrate(Currency_Code,30400003,To_date,0,0,Trad_Maturity_Date) * (Pkgforexprocess.Fncgetoutstanding(Trad_Trade_Reference,0,0,1,To_date)- (SELECT NVL(SUM(HEDG_HEDGED_FCY),0) FROM trtran004
        WHERE HEDG_TRADE_REFERENCE = trad_trade_reference and Hedg_Record_Status not in (10200005,10200006,10200012) ))) ProductInrEffective
        into CostOpenUnhedgeFCY,CostOpenUnhedgeINR,EffectOpenUnhedgedINR
        FROM Trtran002 where
        TRAD_RECORD_STATUS not in(10200005,10200006,10200012) and
                        ((TRAD_PROCESS_COMPLETE = 12400001  and trad_complete_date > To_date) or TRAD_PROCESS_COMPLETE = 12400002)
        and Trad_Company_Code = Company_code
        and TRAD_TRADE_CURRENCY = 30400004
        and trad_entry_date <= To_date
        Group by Trad_Company_Code;
        
--              delete from temp;commit;
--       insert into temp values (CostOpenUnhedgeFCY,'Chandra');

 
       exception
       when no_data_found then
         CostOpenUnhedgeFCY:=0;
         CostOpenUnhedgeINR :=0;
         EffectOpenUnhedgedINR :=0;
       end;
       
       begin
          Select 
          Sum((Pkgforexprocess.Fncgetoutstanding(Trad_Trade_Reference,0,0,1,To_date)- nvl((SELECT NVL(SUM(HEDG_HEDGED_FCY),0) FROM trtran004
          WHERE HEDG_TRADE_REFERENCE = trad_trade_reference and Hedg_Record_Status not in (10200005,10200006,10200012) ),0)) * 
          Pkgforexprocess.Fncgetrate(TRAD_TRADE_CURRENCY,30400004,TRAD_REFERENCE_DATE,0,0,TRAD_REFERENCE_DATE)) HedgedamtfcyCosting,
  --          sum((Pkgforexprocess.Fncgetoutstanding(Trad_Trade_Reference,0,0,1,To_date)- (SELECT NVL(SUM(HEDG_HEDGED_FCY),0) FROM trtran004
  --        WHERE HEDG_TRADE_REFERENCE = trad_trade_reference and Hedg_Record_Status not in (10200005,10200006,10200012) )) * TRAD_TRADE_RATE) As ProductinrCosting,
                    Sum(((Pkgforexprocess.Fncgetoutstanding(Trad_Trade_Reference,0,0,1,To_date)- nvl((SELECT NVL(SUM(HEDG_HEDGED_FCY),0) FROM trtran004
          WHERE HEDG_TRADE_REFERENCE = trad_trade_reference and Hedg_Record_Status not in (10200005,10200006,10200012) ),0)) * 
          Pkgforexprocess.Fncgetrate(TRAD_TRADE_CURRENCY,30400004,TRAD_REFERENCE_DATE,0,0,TRAD_REFERENCE_DATE)) *
          Pkgforexprocess.Fncgetrate(30400004,30400003,TRAD_REFERENCE_DATE,0,0,TRAD_REFERENCE_DATE))As ProductinrCosting,
            Sum(Pkgforexprocess.Fncgetrate(30400004,30400003,To_date,0,0,Trad_Maturity_Date) * ((Pkgforexprocess.Fncgetoutstanding(Trad_Trade_Reference,0,0,1,To_date)- nvl((SELECT NVL(SUM(HEDG_HEDGED_FCY),0) FROM trtran004
          WHERE HEDG_TRADE_REFERENCE = trad_trade_reference and Hedg_Record_Status not in (10200005,10200006,10200012) ),0)) * 
          Pkgforexprocess.Fncgetrate(TRAD_TRADE_CURRENCY,30400004,TRAD_REFERENCE_DATE,0,0,TRAD_REFERENCE_DATE))) ProductInrEffective
          into CostOpenUnhedgeFCY_Other,CostOpenUnhedgeINR_Other,EffectOpenUnhedgedINR_Other
          FROM Trtran002 where
          TRAD_RECORD_STATUS not in(10200005,10200006,10200012) and
                          ((TRAD_PROCESS_COMPLETE = 12400001  and trad_complete_date > To_date) or TRAD_PROCESS_COMPLETE = 12400002)
          and Trad_Company_Code = Company_code
          and TRAD_TRADE_CURRENCY not in(30400004)
          Group by Trad_Company_Code;
          exception
           when no_data_found then
             CostOpenUnhedgeFCY_Other:=0;
             CostOpenUnhedgeINR_Other :=0;
             EffectOpenUnhedgedINR_Other :=0;
           end;
        
       
       
       begin
       select nvl(sum(BCRD_SANCTIONED_FCY),0) as fcy,nvl(sum(BCRD_SANCTIONED_FCY * BCRD_CONVERSION_RATE),0) as Costing,
       nvl(sum((Pkgforexprocess.Fncgetrate(Currency_Code,30400003,To_date,0,0,BCRD_DUE_DATE) * BCRD_SANCTIONED_FCY)),0) as effect
       into BCFcy,BCCostInr,BCEffectInr
       from trtran045 where BCRD_PROCESS_COMPLETE = 12400002 and BCRD_RECORD_STATUS between 10200001 and 10200004
       and BCRD_COMPANY_CODE = Company_code and BCRD_CURRENCY_CODE = 30400004
       and bcrd_record_status between 10200001 and 10200004
       and BCRD_SANCTION_DATE <=To_date;
       exception
       when no_data_found then
         BCFcy:=0;
         BCCostInr :=0;
         BCEffectInr :=0;
       end;
       
       begin
       
       select nvl(sum(BCRD_SANCTIONED_FCY * Pkgforexprocess.Fncgetrate(BCRD_CURRENCY_CODE,30400004,BCRD_SANCTION_DATE,0,0,BCRD_SANCTION_DATE)),0) as fcy,
        nvl(sum((BCRD_SANCTIONED_FCY * Pkgforexprocess.Fncgetrate(BCRD_CURRENCY_CODE,30400004,BCRD_SANCTION_DATE,0,0,BCRD_SANCTION_DATE)) *
        Pkgforexprocess.Fncgetrate(30400004,30400003,BCRD_SANCTION_DATE,0,0,BCRD_SANCTION_DATE)),0)Costing,
        nvl(sum((BCRD_SANCTIONED_FCY * Pkgforexprocess.Fncgetrate(BCRD_CURRENCY_CODE,30400004,BCRD_SANCTION_DATE,0,0,BCRD_SANCTION_DATE)) *
        Pkgforexprocess.Fncgetrate(30400004,30400003,To_date,0,0,BCRD_DUE_DATE)),0)effect
        into BCFcy_Other,BCCostInr_Other,BCEffectInr_Other
        from trtran045 where BCRD_PROCESS_COMPLETE = 12400002 and BCRD_RECORD_STATUS between 10200001 and 10200004
        and BCRD_COMPANY_CODE = Company_code and BCRD_CURRENCY_CODE not in(30400004)
        and bcrd_record_status between 10200001 and 10200004
        and BCRD_SANCTION_DATE <=To_date;
       
       exception
       when no_data_found then
         BCFcy_Other:=0;
         BCCostInr_Other :=0;
         BCEffectInr_Other :=0;
       end;
       
       CostOpenUnhedgeFCY := CostOpenUnhedgeFCY + CostOpenUnhedgeFCY_Other+ BCFcy + BCFcy_Other;
       CostOpenUnhedgeINR := CostOpenUnhedgeINR +CostOpenUnhedgeINR_Other+ BCCostInr + BCCostInr_Other;
       EffectOpenUnhedgedINR := EffectOpenUnhedgedINR + EffectOpenUnhedgedINR_Other+BCEffectInr + BCEffectInr_Other;
       
    
---------FC Delivery--------------------------------------------
      begin 
      select sum(CDEL_CANCEL_AMOUNT) Fcyamount,sum((CDEL_CANCEL_AMOUNT* TRAD_TRADE_RATE)) CostingInr,
      sum((CDEL_CANCEL_AMOUNT* CDEL_CANCEL_RATE))as EffectiveInr
      into FcDelivery_Fcy , FcdeliveryCost_Inr ,FcDeliveryEffect_Inr 
      from trtran006,trtran002,trtran001
      where trtran006.CDEL_TRADE_REFERENCE = trtran002.TRAD_TRADE_REFERENCE
      and trtran002.TRAD_TRADE_CURRENCY = 30400004
      and cdel_deal_number = deal_deal_number
      and Trad_Company_Code = Company_code
      And Cdel_Company_Code = Company_Code
      and cdel_cancel_date between Frm_date and To_date
       and cdel_record_status  between 10200001 and 10200004
      and deal_record_status  between 10200001 and 10200004
      and trad_record_status  between 10200001 and 10200004     
      --and trtran006.CDEL_CANCEL_DATE <= To_date
      and trtran001.DEAL_DEAL_TYPE not in(25400001)
      --and trtran006.CDEL_DEAL_NUMBER not like '%CSH%'
      Group by Trad_Company_Code,cdel_company_code;

      exception
       when no_data_found then
       FcDelivery_Fcy :=0;
       FcdeliveryCost_Inr :=0;
       FcDeliveryEffect_Inr :=0;
       end;
       
       begin
       SELECT SUM(CDEL_CANCEL_AMOUNT * Pkgforexprocess.Fncgetrate(TRAD_TRADE_CURRENCY,30400004,TRAD_REFERENCE_DATE,0,0,TRAD_REFERENCE_DATE)) Fcyamount,
          SUM(((CDEL_CANCEL_AMOUNT * Pkgforexprocess.Fncgetrate(TRAD_TRADE_CURRENCY,30400004,TRAD_REFERENCE_DATE,0,0,TRAD_REFERENCE_DATE))* Pkgforexprocess.Fncgetrate(30400004,30400003,TRAD_REFERENCE_DATE,0,0,TRAD_REFERENCE_DATE))) CostingInr,
          SUM(((CDEL_CANCEL_AMOUNT * Pkgforexprocess.Fncgetrate(TRAD_TRADE_CURRENCY,30400004,TRAD_REFERENCE_DATE,0,0,TRAD_REFERENCE_DATE))* Pkgforexprocess.Fncgetrate(30400004,30400003,DEAL_MATURITY_DATE,0,0,DEAL_MATURITY_DATE)))AS EffectiveInr
          into FcDelivery_Fcy_Other , FcdeliveryCost_Inr_Other ,FcDeliveryEffect_Inr_Other
        FROM trtran006,
          trtran002,
          trtran001
        WHERE CDEL_TRADE_REFERENCE   = TRAD_TRADE_REFERENCE
        AND TRAD_TRADE_CURRENCY NOT IN(30400004)
        AND cdel_deal_number         = deal_deal_number
        AND Trad_Company_Code        = 30100002
        AND Cdel_Company_Code        = 30100002
        AND cdel_cancel_date BETWEEN Frm_date and To_date
        and cdel_record_status  between 10200001 and 10200004
        and deal_record_status  between 10200001 and 10200004
        and trad_record_status  between 10200001 and 10200004        
        AND DEAL_DEAL_TYPE NOT IN(25400001)
        GROUP BY Trad_Company_Code,
                  cdel_company_code;
       exception
       when no_data_found then
         FcDelivery_Fcy_Other :=0;
         FcdeliveryCost_Inr_Other :=0;
         FcDeliveryEffect_Inr_Other :=0;          
        end;          
        FcDelivery_Fcy := FcDelivery_Fcy + FcDelivery_Fcy_Other;
        FcdeliveryCost_Inr := FcdeliveryCost_Inr + FcdeliveryCost_Inr_Other;
        FcDeliveryEffect_Inr := FcDeliveryEffect_Inr + FcDeliveryEffect_Inr_Other;
        
--CASHSETTLEFCY
--CASSETTLECOSTINR
--CASSETTLEEFFECTINR
-------------Cash settle---------------------------------------
    begin 

      select sum(CDEL_CANCEL_AMOUNT),
       sum(CDEL_CANCEL_AMOUNT*CDEL_CANCEL_RATE) as Costing,
      sum(CDEL_CANCEL_AMOUNT* TRAD_TRADE_RATE)
      into  CashSettle_Fcy , CashSettleEffect_Inr, CashSettleCost_Inr
      from trtran006,trtran002,trtran001
      where CDEL_TRADE_REFERENCE = TRAD_TRADE_REFERENCE
      and CDEL_DEAL_NUMBER = DEAL_DEAL_NUMBER
      and cdel_record_status  between 10200001 and 10200004
      and deal_record_status  between 10200001 and 10200004
      and trad_record_status  between 10200001 and 10200004      
      and DEAL_DEAL_TYPE = 25400001 and TRAD_TRADE_CURRENCY = 30400004
      and Trad_Company_Code = Company_code
      And Cdel_Company_Code = Company_Code
      and CDEL_CANCEL_DATE between Frm_date and To_date
      Group by Trad_Company_Code,cdel_company_code,deal_company_code;

      exception
       when no_data_found then
       tradereference := 0;
       CashSettle_Fcy := 0;
       CashSettleEffect_Inr  := 0;
       CashSettleCost_Inr := 0;
       end;
    Begin   
      select SUM(CDEL_CANCEL_AMOUNT * Pkgforexprocess.Fncgetrate(TRAD_TRADE_CURRENCY,30400004,TRAD_REFERENCE_DATE,0,0,TRAD_REFERENCE_DATE)) Fcyamount,
      SUM(((CDEL_CANCEL_AMOUNT * Pkgforexprocess.Fncgetrate(TRAD_TRADE_CURRENCY,30400004,TRAD_REFERENCE_DATE,0,0,TRAD_REFERENCE_DATE))* Pkgforexprocess.Fncgetrate(30400004,30400003,TRAD_REFERENCE_DATE,0,0,TRAD_REFERENCE_DATE))) CostingInr,
      SUM(((CDEL_CANCEL_AMOUNT * Pkgforexprocess.Fncgetrate(TRAD_TRADE_CURRENCY,30400004,TRAD_REFERENCE_DATE,0,0,TRAD_REFERENCE_DATE))* Pkgforexprocess.Fncgetrate(30400004,30400003,DEAL_MATURITY_DATE,0,0,DEAL_MATURITY_DATE)))AS EffectiveInr
      into CashSettle_Fcy_Other,CashSettleEffect_Inr_Other,CashSettleCost_Inr_Other
        from trtran006,trtran002,trtran001
      where CDEL_TRADE_REFERENCE = TRAD_TRADE_REFERENCE
      and CDEL_DEAL_NUMBER = DEAL_DEAL_NUMBER
      and DEAL_DEAL_TYPE = 25400001 
      and cdel_record_status  between 10200001 and 10200004
      and deal_record_status  between 10200001 and 10200004
      and trad_record_status  between 10200001 and 10200004
      and TRAD_TRADE_CURRENCY not in(30400004)
      and Trad_Company_Code = Company_code
      And Cdel_Company_Code = Company_code
      and CDEL_CANCEL_DATE between Frm_date and To_date
      Group by Trad_Company_Code,cdel_company_code,deal_company_code;
      
    exception
       when no_data_found then
       tradereference := 0;
       CashSettle_Fcy_Other := 0;
       CashSettleEffect_Inr_Other  := 0;
       CashSettleCost_Inr_Other := 0;
       end;
      CashSettle_Fcy := CashSettle_Fcy + CashSettle_Fcy_Other;
      CashSettleEffect_Inr := CashSettleEffect_Inr + CashSettleEffect_Inr_Other;
      CashSettleCost_Inr := CashSettleCost_Inr + CashSettleCost_Inr_Other;
-------------------------------------------FcCancellation------
       begin 
--        Select  Sum(PANDLFCY) FccancellationFrw into FC_Cancellation
--        from vewReportForward  where Canceldate is not null 
--        --and dealdate <= To_date
--        and canceldate between Frm_date and To_date
--        and companycode = Company_code and hedgeCode = 26000001
--        and CURRENCYCODE = Currency_Code
--        group by companycode ;
         select sum(CDEL_PROFIT_LOSS) FccancellationFrw into FC_Cancellation
          from trtran006,trtran001
          where CDEL_CANCEL_DATE between Frm_date and To_date
          and cdel_deal_number = deal_deal_number
          and DEAL_HEDGE_TRADE = 26000001
          and CDEL_COMPANY_CODE = Company_code
          and cdel_record_status  between 10200001 and 10200004
          and deal_company_code = Company_code
          --and DEAL_BASE_CURRENCY = Currency_Code
          group by CDEL_COMPANY_CODE;               
          
    
  
       exception
       when no_data_found then
         FC_Cancellation:=0;
       end;
---------------------------------OpenHedgeMTM---------------
       begin 
        Select 
         Sum(MTMPANDLINR) as MTMHedgeFrw
        into OpenHedged_MTM
        from vewReportForward  where status = 12400002 
        and dealdate <= To_date 
        and companycode = Company_code and hedgeCode = 26000001
        --and CURRENCYCODE = Currency_Code
        group by companycode ;
  
       exception
       when no_data_found then
         OpenHedged_MTM :=0;
       end;
       
      begin 
        Select 
         sum(balancefcy) as FC,
         sum(balancefcy * exrate)as  FCINR
        into Frwd_ContractFcy,Frwd_ContractINR
        from vewReportForward  where status = 12400002 
        and dealdate <= To_date 
        and companycode = Company_code and hedgeCode = 26000001
        and CURRENCYCODE = 30400004
        group by companycode ;
  
       exception
       when no_data_found then
         Frwd_ContractFcy :=0;
         Frwd_ContractINR :=0;
       end;
       
      begin 
        Select 
         sum(balancefcy * Pkgforexprocess.Fncgetrate(CURRENCYCODE,30400004,dealdate,0,0,dealdate)) as FC,
         sum((balancefcy * Pkgforexprocess.Fncgetrate(CURRENCYCODE,30400004,dealdate,0,0,dealdate)) 
         * Pkgforexprocess.Fncgetrate(30400004,30400003,dealdate,0,0,dealdate))as  FCINR
        into Frwd_ContractFcy_Other,Frwd_ContractINR_Other
        from vewReportForward  where status = 12400002 
        and dealdate <= To_date 
        and companycode = Company_code and hedgeCode = 26000001
        and CURRENCYCODE not in(30400004)
        group by companycode ;
  
       exception
       when no_data_found then
         Frwd_ContractFcy_Other :=0;
         Frwd_ContractINR_Other :=0;
       end;
       Frwd_ContractFcy := Frwd_ContractFcy + Frwd_ContractFcy_Other;
       Frwd_ContractINR := Frwd_ContractINR + Frwd_ContractINR_Other;
    ---------------------------'Currency Futures (Realised + MTM)' ---------------------------------
       begin 
        Select SUM(nvl(MTMPANDL,0)) FutureMTMPANL
   
        into Future_MTM
        from vewReportFuture  where 
        --dealdate between Frm_date and To_date
        dealdate <= To_date 
        and companycode = Company_code --and hedgeCode = 26000001
        --and CURRENCYCODE = Currency_Code
        group by Companycode;
               exception
       when no_data_found then
         Future_MTM :=0;
       end;
     begin   
        Select Sum(nvl(PANDLFCY,0))
         into FuturPandL
        from vewReportFuture  where 
        canceldate between Frm_date and To_date
        --dealdate <= To_date 
        and companycode = Company_code --and hedgeCode = 26000001
        --and CURRENCYCODE = Currency_Code
        group by Companycode;
               exception
       when no_data_found then
         FuturPandL :=0;
       end;
       Future_MTM := Future_MTM + FuturPandL;
-----------------------------------       
    if company_code = 30100017 then ---Vinayaga Furure----
      begin
            Select Sum(nvl(MTMPANDL,0)) FutureMTMPANL
            into CfuMTMPLV
            from vewReportFuture  where 
           -- dealdate between Frm_date and To_date
            dealdate <= To_date 
            and companycode = 30100018 --and hedgeCode = 26000001
            and CURRENCYCODE = Currency_Code
            group by Companycode;
              exception
       when no_data_found then
         CfuMTMPLV :=0;
       end;  
            FuturPandL := 0;       
            begin
            Select Sum(nvl(PANDLFCY,0)) 
            into FuturPandL
            from vewReportFuture  where 
            canceldate between Frm_date and To_date
            --dealdate <= To_date 
            and companycode = 30100018 --and hedgeCode = 26000001
            and CURRENCYCODE = Currency_Code
            group by Companycode;
              exception
       when no_data_found then
         FuturPandL :=0;
       end;  
       Future_MTM := Future_MTM + CfuMTMPLV + FuturPandL;
    end if;


    
   begin       
       Select        
        Sum(balancefcy) Buy,
        sum(balancefcy*exrate)  as BuyINR
        into  CFBuy,CFBuyINR
        from vewReportFuture  where 
        dealdate <= To_date 
        and companycode = Company_code --and hedgeCode = 26000001
        and CURRENCYCODE = 30400004 
        and BUYSELL = 'Buy'
        and((Status = 12400001  and Completedate > To_date) or Status = 12400002)
        --and Completedate > Frm_date 
        group by Companycode;
        
       exception
       when no_data_found then
         CFBuy :=0;
         CFBuyINR := 0;
       end;
       
      begin       
       Select        
        Sum(balancefcy * Pkgforexprocess.Fncgetrate(CURRENCYCODE,30400004,dealdate,0,0,dealdate)) Buy,
        sum((balancefcy * Pkgforexprocess.Fncgetrate(CURRENCYCODE,30400004,dealdate,0,0,dealdate))*Pkgforexprocess.Fncgetrate(30400004,30400003,dealdate,0,0,dealdate))  as BuyINR
        into  CFBuy_Other,CFBuyINR_Other
        from vewReportFuture  where 
        dealdate <= To_date 
        and companycode = Company_code --and hedgeCode = 26000001
        and CURRENCYCODE not in(30400004)
        and BUYSELL = 'Buy'
        and((Status = 12400001  and Completedate > To_date) or Status = 12400002)
        --and Completedate > Frm_date 
        group by Companycode;
        
       exception
       when no_data_found then
         CFBuy_Other :=0;
         CFBuyINR_Other := 0;
       end;
       CFBuy := CFBuy + CFBuy_Other;
       CFBuyINR := CFBuyINR + CFBuyINR_Other;
 
 begin 
        Select
        sum(balancefcy)  as Sell,          
        sum(balancefcy*exrate) as SellINR 
        into CFSell,CFSellINR
        from vewReportFuture  where 
        dealdate <= To_date 
        and companycode = Company_code --and hedgeCode = 26000001
        and CURRENCYCODE = 30400004 
        and BUYSELL = 'Sell'
        and((Status = 12400001  and Completedate > To_date) or Status = 12400002)
        group by Companycode;
      exception
       when no_data_found then
         CFSell :=0;
         CFSellINR :=0;
       end;
       
        begin 
        Select
          Sum(balancefcy * Pkgforexprocess.Fncgetrate(CURRENCYCODE,30400004,dealdate,0,0,dealdate)) Sell,
          sum((balancefcy * Pkgforexprocess.Fncgetrate(CURRENCYCODE,30400004,dealdate,0,0,dealdate))*Pkgforexprocess.Fncgetrate(30400004,30400003,dealdate,0,0,dealdate))  as SellINR
        into CFSell_Other,CFSellINR_Other
        from vewReportFuture  where 
        dealdate <= To_date 
        and companycode = Company_code --and hedgeCode = 26000001
        and CURRENCYCODE not in(30400004) 
        and BUYSELL = 'Sell'
        and((Status = 12400001  and Completedate > To_date) or Status = 12400002)
        group by Companycode;
      exception
       when no_data_found then
         CFSell_Other :=0;
         CFSellINR_Other :=0;
       end;
       CFSell := CFSell + CFSell_Other;
       CFSellINR := CFSellINR + CFSellINR_Other;
       
        wtavgfutur := round((CFBuyINR + CFSellINR)/(CFBuy + CFSell),2);
    
         
        Ftr_ContractFCY := CFBuy - CFSell;
        --Ftr_ContractINR := CFBuyINR - CFSellINR;
        Ftr_ContractINR := Ftr_ContractFCY * wtavgfutur;
        if Ftr_ContractFCY = 0 then
          Ftr_ContractINR := 0;
        end if;

    ------------------'Currency Options MTM'-------------------
       begin 
        select Sum(pkgForexProcess.fncGetOptionMTM(copt_deal_number,To_date,'N'))MTMAmtOpt into Option_MTM
        from trtran071 where COPT_EXECUTE_DATE <= To_date 
        and ((copt_PROCESS_COMPLETE = 12400001  and copt_COMPLETE_DATE >To_date) or copt_PROCESS_COMPLETE = 12400002)
        and COPT_RECORD_STATUS in(10200001,10200002,10200003,10200004)
        and copt_Company_code = Company_code --and COPT_HEDGE_TRADE = 26000001
        --and COPT_BASE_CURRENCY = Currency_Code
        group by copt_Company_code;
  
       exception
       when no_data_found then
         Option_MTM :=0;
       end;
      if company_code = 30100017 then -- For Vinayaga Added this
       begin
           select Sum(pkgForexProcess.fncGetOptionMTM(copt_deal_number,To_date,'N'))MTMAmtOpt into CoptMTMV
          from trtran071 where 
          COPT_EXECUTE_DATE <= To_date 
          and ((copt_PROCESS_COMPLETE = 12400001  and copt_COMPLETE_DATE >To_date) or copt_PROCESS_COMPLETE = 12400002)
          and COPT_RECORD_STATUS in(10200001,10200002,10200003,10200004)
          and copt_Company_code = 30100018 --and COPT_HEDGE_TRADE = 26000001
          and COPT_BASE_CURRENCY = Currency_Code
          group by copt_Company_code;
         exception
       when no_data_found then
         CoptMTMV :=0;
       end;
       Option_MTM := Option_MTM + CoptMTMV;
      end if;
    ----------------------------Currency Options Realised --------
       begin 
        select Sum(nvl( Pkgforexprocess.Fncgetprofitlossoptnetpandl(CORV_DEAL_NUMBER,CORV_SERIAL_NUMBER),0)) as NetPandLOpt into Option_Realize
        from trtran073,trtran071 
        where 
        corv_exercise_date  between Frm_date and To_date
        --CORV_EXERCISE_DATE <= To_date 
        and CORV_company_code = Company_code
        and copt_deal_number = CORV_DEAL_NUMBER --and COPT_HEDGE_TRADE = 26000001
        and CORV_RECORD_STATUS in(10200001,10200002,10200003,10200004)
        --and trtran071.COPT_BASE_CURRENCY = Currency_Code
        group by CORV_company_code;
  
       exception
       when no_data_found then
         Option_Realize :=0;
       end;
       if company_code = 30100017 then -- For Vinayaga Added this
        begin
          select Sum(nvl( Pkgforexprocess.Fncgetprofitlossoptnetpandl(CORV_DEAL_NUMBER,CORV_SERIAL_NUMBER),0)) as NetPandLOpt into CoptRELV
          from trtran073,trtran071 
          where 
          --CORV_EXERCISE_DATE <= To_date
          corv_exercise_date  between Frm_date and To_date
          and CORV_company_code = 30100018
          and copt_deal_number = CORV_DEAL_NUMBER --and COPT_HEDGE_TRADE = 26000001
          and CORV_RECORD_STATUS in(10200001,10200002,10200003,10200004)
          and trtran071.COPT_BASE_CURRENCY = Currency_Code
          group by CORV_company_code;
                 exception
       when no_data_found then
         CoptRELV :=0;
        end;
       Option_Realize := Option_Realize + CoptRELV;
       end if;
       
-----------------------------
    Insert into trsystem979
    (COMPANYCODE ,    OpenHedgedFCY_Cost ,    OpenUnHedgedFCY_Cost,    OpenHedgedINR_Cost ,    OpenUnhedgedINR_Cost ,
      OpenHedgedINR_Effect ,    OpenUnhedgedINR_Effect ,    FCCancellation ,    OpenHedgedMTM ,    FutureMTM ,    OptionMTM ,
      FrwdContractFcy ,    FtrContractFCY ,    FrwdContractINR ,    FtrContractINR,    REFDATE,
      FCDELIVERYFCY,FCDELIVERYCOSTINR,FCDELIVERYEFFECTINR,CASHSETTLEFCY,CASSETTLECOSTINR,CASSETTLEEFFECTINR)
    Values
    (Company_code,  nvl(CostOpenHedgeFCY,0), nvl(CostOpenUnhedgeFCY,0), nvl(CostOpenHedgeINR,0),nvl(CostOpenUnhedgeINR,0),
      nvl(EffectOpenHedgedINR,0) ,nvl(EffectOpenUnhedgedINR,0),nvl(FC_Cancellation,0),nvl(OpenHedged_MTM,0),nvl(Future_MTM,0),
      nvl(Option_MTM,0)  + nvl(Option_Realize,0),nvl(Frwd_ContractFcy,0),nvl(Ftr_ContractFCY,0),nvl(Frwd_ContractINR,0),
      nvl(Ftr_ContractINR,0),To_date,FcDelivery_Fcy , FcdeliveryCost_Inr ,FcDeliveryEffect_Inr,CashSettle_Fcy , CashSettleCost_Inr,
      CashSettleEffect_Inr 
      
      );
end PrcEffectiveRateUsd;
 
 
 
 
 
 
 
 
 
/