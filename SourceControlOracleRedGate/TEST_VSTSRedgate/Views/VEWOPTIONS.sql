CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewoptions (dealnumber,dealref,companycode,companyname,bankcode,bankname,dealdate,dealamount,currency,premium,maturity,settlement,premiumdate,strikerate,canceldate,cancelrate,pandlfcy,status,recordstatus,completedate,transcode,trans,hedgetrade,userid,initcode,outstanding,bankmargin,spot,cspot,cforward,cmargin,cfinalrte,locationcode,bankref,dealtype,optiontype,buysell,premiumrate,cancelamount,premiumlocal,premiumstatus,cpremiumstatus,cpremiumamount,premiumexrate,confirmdate,confirmtime,boremarks,ourdealername,thierdealername,deliverytype,cashflowdate,courdealername,ctheirdealername,ccomfirmdate,ccomfirmtime,cboremark,cpremiumexrate,cpremiumlocal,mtmpandl,reverseserial,gainloss) AS
select copt_deal_number DealNumber, copt_dealer_remark DealRef,
        copt_company_code CompanyCode, a.pick_short_description CompanyName,
        copt_counter_party BankCode, b.pick_short_description BankName,
        copt_execute_date DealDate, copt_base_amount DealAmount,
        c.pick_short_description || '/' || d.pick_short_description Currency,
        CASE WHEN NVL(COPT_PREMIUM_DOLLERAMOUNT,0) != 0 THEN
          ROUND(decode(COPT_PREMIUM_STATUS,33200001,ABS(COPT_PREMIUM_DOLLERAMOUNT),33200002,-1*ABS(COPT_PREMIUM_DOLLERAMOUNT)) * fncgetPandLRate(COPT_DEAL_NUMBER,1,Fncasondate(),2),2)
        ELSE      
          decode(COPT_PREMIUM_STATUS,33200001,ABS(COPT_PREMIUM_AMOUNT),33200002,-1*(ABS(COPT_PREMIUM_AMOUNT))) END,        
        --PKGFOREXPROCESS.Fncgetprofitlossoptnetpandl(COPT_DEAL_NUMBER, 1,Fncasondate()) Premium,
        cosm_maturity_date Maturity, 
        cosm_settlement_date Settlement, copt_premium_valueDate PremiumDate,
        cosu_strike_rate StrikeRate,
        corv_exercise_date CancelDate, corv_exercise_rate CancelRate, 
        corv_pandl_usd PandLFcy, copt_process_complete Status,COPT_RECORD_STATUS as RecordStatus,
        copt_complete_date CompleteDate, 
        copt_backup_deal TransCode, e.pick_short_description Trans,
        copt_hedge_trade HedgeTrade, copt_user_id UserID, copt_init_code InitCode,
        pkgForexProcess.fncGetOutstanding(COSM_DEAL_NUMBER,COSM_SERIAL_NUMBER,15,1,Fncasondate(),null,COSM_SUBSERIAL_NUMBER) Outstanding,
        copt_margin_rate BankMargin,
        '' Spot,
        CORV_PREMIUM_RATE Cspot,
        '' CForward,
        Corv_margin_rate CMargin,
        CORV_PREMIUM_RATE CFinalRte,
        COPT_LOCATION_CODE LocationCode,
        COPT_USER_REFERENCE BankRef,
        COPT_DEAL_TYPE DealType,
        cosu_option_type OptionType,
        cosu_buy_sell BuySell,
        COPT_PREMIUM_RATE PremiumRate,
        CORV_BASE_AMOUNT CancelAmount,
        case when nvl(COPT_PREMIUM_DOLLERAMOUNT,0) != 0 then
          ROUND(decode(COPT_PREMIUM_STATUS,33200001,ABS(COPT_PREMIUM_DOLLERAMOUNT),33200002,-1*ABS(COPT_PREMIUM_DOLLERAMOUNT)) * fncgetPandLRate(COPT_DEAL_NUMBER,1,Fncasondate(),2),2)
        else  
        COPT_PREMIUM_LOCAL end PremiumLocal,
        COPT_PREMIUM_STATUS PremiumStatus,
        CORV_PREMIUM_STATUS CpremiumStatus,
        decode(corv_premium_status,33200001,1,33200002,-1,1)* corv_profit_loss CPremiumAmount,
        --CORV_PREMIUM_AMOUNT CPremiumAmount,
        COPT_PREMIUM_EXRATE PremiumExRate,
        COPT_CONFIRM_DATE ConfirmDate,
        COPT_CONFIRM_TIME ConfirmTime,
        COPT_BO_REMARK BORemarks,
        COPT_DEALER_NAME OurDealerName,
        COPT_COUNTER_DEALER ThierDealerName,
        COPT_DELIVERY_TYPE DeliveryType,
        CORV_SETTLEMENT_DATE CashFlowDate,
        CORV_DEALER_NAME COurDealerName,
        CORV_COUNTER_DEALER CTheirDealerName,
        CORV_CONFIRM_DATE CComfirmDate,
        CORV_CONFIRM_TIME CComfirmTime,
        CORV_BO_REMARK CBORemark,
        CORV_PREMIUM_EXRATE CPremiumExRate,
        CORV_PREMIUM_LOCAL  CPremiumLocal,
        PKGFOREXPROCESS.FNCGETOPTIONMTM(COPT_DEAL_NUMBER,Fncasondate(),'Y') MTMPandL,
        CORV_REVERSE_SERIAL ReverseSerial,
        PKGFOREXPROCESS.Fncgetprofitlossoptnetpandl(CORV_DEAL_NUMBER, CORV_REVERSE_SERIAL,Fncasondate())GainLoss
        from trtran071
        JOIN TRTRAN072A ON
         COPT_DEAL_NUMBER = COSM_DEAL_NUMBER
         AND copt_serial_number = COSM_SERIAL_NUMBER
         AND COSM_RECORD_STATUS NOT IN(10200005,10200006)         
        left outer join trtran073
          on copt_deal_number = corv_deal_number
          and corv_record_status between 10200001 and 10200004
        JOIN TRTRAN072 ON
          COSU_DEAL_NUMBER = COSM_DEAL_NUMBER
        AND COSU_SERIAL_NUMBER = 1
        AND COSU_RECORD_STATUS NOT IN(10200005,10200006)           
        join trmaster001 a
          on copt_company_code = a.pick_key_value
        join trmaster001 b
          on copt_counter_party = b.pick_key_value
        join trmaster001 c
          on copt_base_currency = c.pick_key_value
        join trmaster001 d
          on copt_other_currency = d.pick_key_value
        join trmaster001 e
          on NVL(copt_backup_deal,12400001) = e.pick_key_value
          where copt_record_status not in(10200005,10200006);