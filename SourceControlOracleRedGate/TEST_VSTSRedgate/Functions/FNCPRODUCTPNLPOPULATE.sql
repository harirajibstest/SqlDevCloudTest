CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate".fncProductPnlPopulate
    ( ASONDATE IN DATE,
      varUserID in varchar2,checkData in char default 'Y',MTMRate in char default 'Y' ) 
      return number
     is
      
    PRAGMA AUTONOMOUS_TRANSACTION;
    numError number;
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    datMTD              Date;
    datYTD              Date;
    FrmDate             Date;
    Begin
    
    numError :=  pkgforexprocess.FNCPOSITIONGENERATE(varUserID,ASONDATE);commit;
    varMessage := 'Generating Treasury Numbers For: ' || AsonDate;
    numError := 0;

    if (to_char(ASONDATE,'MM') <=4) then
      FrmDate:= '01-apr-' || to_char(to_number(to_char(ASONDATE,'YYYY'))-1);
--      dattemp1:= '31-MAR-' ||to_char(frmDate,'YYYY');
--      temp:= 'FY'|| to_char(to_number(to_char(frmDate,'YY'))-1) || '-' || to_char(frmDate,'YY');
    else
      FrmDate:= '01-apr-' || to_char(ASONDATE,'YYYY');
--      dattemp1:= '31-MAR-' || to_char(to_number(to_char(frmDate,'YYYY'))+1);
--      temp:= 'FY'|| to_char(frmDate,'YY') || '-' || to_char(to_number(to_char(frmDate,'YY'))+1);
    end if;
    --FrmDate := '01-JAN-'||to_char(AsonDate,'yyyy'); ---For Olam Financial year start from 01-JAN

    varOperation := 'Deleting Old records for the date';         
--    delete from trsystem983 
--    where ason_date = AsonDate;

    varOperation := 'Selecting  Inserting unique values for codes'; 

    insert into trsystem983 (userId,Deal_type,ason_date,HedgeTrade,CompanyCode,Trader,
                            dealnumber,maturitydate,CURRENCYCODE,COUNTERPARTY,EXECUTEDATE,
                            EXCHANGERATE,DEALBASEAMOUNT,DEALREMARKS,USERREFERENCE,
                            SPOTRATE,FORWARDRATE,MARGINRATE,LOCATIONCODE,BUYSELLCODE,
                            DEALSERIAL,DEALSUBSERIAL,DESCRIPTION,RECORDER,ProcessComplete,
                            FORCURRENCY,EXPIRYDATE,BROKERCODE,PREMIUMSTATUS,PREMIUMAMOUNT,OPTIONTYPE,CANCELPNLSPOT,
                            Deltavalue,OUTSTANDINGAMOUNT,RECORDSTATUS,CONFIRMDATE,DEALTIMESTAMP,
                            DEALERNMAE,COUNTERDEALER,EXCHANGECODE,PREMIUMVALUEDATE,ENTERDBY,PREMIUMDOLLERAMT,TransactionType,
                            BUYCALL,SELLCALL,SELLPUT,BUYPUT,RBIREFRATE,DAYONEFRWD,PREMIUMINRATEINSEPTION)
    Select Pkgreturncursor.Fncgetdescription(NVL(POSN_SUBPRODUCT_CODE,33899999),1),
      NVL(POSN_PRODUCT_CODE,33399999),ASONDATE,26099999,POSN_COMPANY_CODE,NVL(POSN_SUBPRODUCT_CODE,33899999),
      POSN_REFERENCE_NUMBER,POSN_DUE_DATE,POSN_CURRENCY_CODE,POSN_COUNTER_PARTY,POSN_REFERENCE_DATE,
      POSN_FCY_RATE,DEAL_BASE_AMOUNT,POSN_USER_REFERENCE,POSN_USER_REFERENCE,
      DEAL_SPOT_RATE,DEAL_FORWARD_RATE,DEAL_MARGIN_RATE,POSN_LOCATION_CODE,
      --case when posn_account_code  in(25900011,25900012,25900018,25900019,25900020,25900021,25900022,25900023) then 25300001 else 25300002 end,
      DEAL_BUY_SELL,1,1,
      'Forward',2,12400002,POSN_FOR_CURRENCY,POSN_MATURITY_FROM,POSN_BROKER_CODE,POSN_PREMIUM_STATUS,POSN_PREMIUM_AMOUNT,POSN_OPTION_TYPE,
      fncgetPandLRate(POSN_REFERENCE_NUMBER,1,ASONDATE,2),0,
      ABS(POSN_TRANSACTION_AMOUNT),
--      CASE WHEN DEAL_BASE_CURRENCY = 30400004 THEN
--      ABS(POSN_TRANSACTION_AMOUNT)
--      WHEN DEAL_OTHER_CURRENCY = 30400004 THEN
--      ABS(round(POSN_TRANSACTION_AMOUNT * DEAL_EXCHANGE_RATE,2)) 
--      WHEN DEAL_BASE_CURRENCY != 30400004 AND DEAL_OTHER_CURRENCY != 30400004 THEN
--      ABS(round(POSN_TRANSACTION_AMOUNT * 
--      pkgforexprocess.fncGetRate(posn_currency_CODE,30400004,POSN_REFERENCE_DATE,DEAL_BUY_SELL,0,posn_due_date),2)) END,
      DEAL_RECORD_STATUS,DEAL_CONFIRM_DATE,DEAL_TIME_STAMP,
      DEAL_DEALER_NAME,DEAL_COUNTER_DEALER,0,NULL,DEAL_USER_ID,0,DEAL_SWAP_OUTRIGHT,0,0,0,0,
      fncGetRBIRefRate(ASONDATE,POSN_CURRENCY_CODE),0,0
      from TRSYSTEM997,TRTRAN001
      where DEAL_DEAL_NUMBER = POSN_REFERENCE_NUMBER 
      AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
      AND DEAL_DEAL_TYPE NOT IN(25400001)
    UNION ALL
    Select Pkgreturncursor.Fncgetdescription(NVL(POSN_SUBPRODUCT_CODE,33899999),1),
      NVL(POSN_PRODUCT_CODE,33399999),ASONDATE,26099999,POSN_COMPANY_CODE,NVL(POSN_SUBPRODUCT_CODE,33899999),
      POSN_REFERENCE_NUMBER,POSN_DUE_DATE,POSN_CURRENCY_CODE,CFUT_COUNTER_PARTY,POSN_REFERENCE_DATE,
      POSN_FCY_RATE,CFUT_BASE_AMOUNT,POSN_USER_REFERENCE,POSN_USER_REFERENCE,
      CFUT_SPOT_RATE,CFUT_FORWARD_RATE,CFUT_BANK_MARGIN,POSN_LOCATION_CODE,
      CFUT_BUY_SELL,1,1,
      'Future ',1,12400002,POSN_FOR_CURRENCY,POSN_MATURITY_FROM,CFUT_COUNTER_PARTY,POSN_PREMIUM_STATUS,POSN_PREMIUM_AMOUNT,POSN_OPTION_TYPE,
      fncgetPandLRate(POSN_REFERENCE_NUMBER,1,ASONDATE,2),0,
      ABS(POSN_TRANSACTION_AMOUNT),
--      CASE WHEN CFUT_BASE_CURRENCY = 30400004 THEN
--       ABS(POSN_TRANSACTION_AMOUNT)
--      WHEN CFUT_OTHER_CURRENCY = 30400004 THEN
--       ABS(round(POSN_TRANSACTION_AMOUNT * CFUT_EXCHANGE_RATE,2)) 
--      WHEN CFUT_BASE_CURRENCY != 30400004 AND CFUT_OTHER_CURRENCY != 30400004 THEN
--       ABS(round(POSN_TRANSACTION_AMOUNT * 
--      pkgforexprocess.fncGetRate(posn_currency_CODE,30400004,POSN_REFERENCE_DATE,CFUT_BUY_SELL,0,posn_due_date),2)) END,
      CFUT_RECORD_STATUS,CFUT_CONFIRM_DATE,CFUT_TIME_STAMP,
      CFUT_DEALER_NAME,CFUT_COUNTER_DEALER,CFUT_EXCHANGE_CODE,NULL,CFUT_USER_ID,0,NULL,0,0,0,0,
      fncGetRBIRefRate(ASONDATE,POSN_CURRENCY_CODE),0,0
      from TRSYSTEM997,TRTRAN061
      where CFUT_DEAL_NUMBER = POSN_REFERENCE_NUMBER 
      AND posn_account_code in(25900018,25900019,25900078,25900079)
      AND CFUT_RECORD_STATUS NOT IN(10200005,10200006)      
      UNION ALL
    Select Pkgreturncursor.Fncgetdescription(NVL(POSN_SUBPRODUCT_CODE,33899999),1),
      NVL(POSN_PRODUCT_CODE,33399999),ASONDATE,26099999,POSN_COMPANY_CODE,NVL(POSN_SUBPRODUCT_CODE,33899999),
      POSN_REFERENCE_NUMBER,POSN_DUE_DATE,POSN_CURRENCY_CODE,
      case when COPT_CONTRACT_TYPE = 32800001 then copt_broker_code else copt_counter_party end,
      POSN_REFERENCE_DATE,
      POSN_FCY_RATE,COPT_BASE_AMOUNT,POSN_USER_REFERENCE,POSN_USER_REFERENCE,
      0,0,0,POSN_LOCATION_CODE,
      cosu_buy_sell,1,1,
      'Options-OTC',5,12400002,POSN_FOR_CURRENCY,POSN_MATURITY_FROM,
      case when COPT_CONTRACT_TYPE = 32800001 then copt_broker_code else copt_counter_party end,COPT_PREMIUM_STATUS,
      CASE WHEN NVL(COPT_PREMIUM_DOLLERAMOUNT,0) != 0 THEN
        ROUND(decode(COPT_PREMIUM_STATUS,33200001,ABS(COPT_PREMIUM_DOLLERAMOUNT),33200002,-1*ABS(COPT_PREMIUM_DOLLERAMOUNT)) * fncgetPandLRate(COPT_DEAL_NUMBER,1,AsonDate,2),2)
      ELSE      
        decode(COPT_PREMIUM_STATUS,33200001,ABS(COPT_PREMIUM_AMOUNT),33200002,-1*(ABS(COPT_PREMIUM_AMOUNT))) END,
      COSU_OPTION_TYPE,
      fncgetPandLRate(POSN_REFERENCE_NUMBER,1,ASONDATE,2),fncgetDeltaValue(POSN_REFERENCE_NUMBER,ASONDATE),
      ABS(POSN_TRANSACTION_AMOUNT),
--      CASE WHEN COPT_BASE_CURRENCY = 30400004 THEN
--      ABS(POSN_TRANSACTION_AMOUNT)
--      WHEN COPT_OTHER_CURRENCY = 30400004 THEN
--      ABS(round(POSN_TRANSACTION_AMOUNT * COSU_STRIKE_RATE,2)) 
--      WHEN COPT_BASE_CURRENCY != 30400004 AND COPT_OTHER_CURRENCY != 30400004 THEN
--      ABS(round(POSN_TRANSACTION_AMOUNT * 
--      pkgforexprocess.fncGetRate(posn_currency_CODE,30400004,POSN_REFERENCE_DATE,COSU_BUY_SELL,0,posn_due_date),2)) END,
      COPT_RECORD_STATUS,COPT_CONFIRM_DATE,COPT_TIME_STAMP,
      COPT_DEALER_NAME,COPT_COUNTER_DEALER,
      CASE WHEN COPT_CONTRACT_TYPE = 32800001 THEN COPT_EXCHANGE_CODE ELSE 0 END ,
      COPT_PREMIUM_VALUEDATE,COPT_USER_ID,COPT_PREMIUM_DOLLERAMOUNT,NULL,
      fncGetOptionRate(COPT_DEAL_NUMBER,32400001,25300001)BuyCall,
      fncGetOptionRate(COPT_DEAL_NUMBER,32400001,25300002)SellCall,
      fncGetOptionRate(COPT_DEAL_NUMBER,32400002,25300002)SellPut,
      fncGetOptionRate(COPT_DEAL_NUMBER,32400002,25300001)BuyPut,
      fncGetRBIRefRate(ASONDATE,POSN_CURRENCY_CODE),
      fncGetDayoneFrwd(POSN_REFERENCE_NUMBER,ASONDATE,POSN_CURRENCY_CODE),
      decode(COPT_PREMIUM_STATUS,33200001,COPT_PREMIUM_RATE,33200002,-1*COPT_PREMIUM_RATE)      
      from TRSYSTEM997,TRTRAN071,TRTRAN072  where 
      COPT_DEAL_NUMBER = POSN_REFERENCE_NUMBER 
      AND COPT_DEAL_NUMBER = COSU_DEAL_NUMBER
      AND COPT_CONTRACT_TYPE = 32800002
      AND POSN_TRANSACTION_AMOUNT != 0
      AND COSU_SERIAL_NUMBER = POSN_REFERENCE_SERIAL        
      AND COPT_RECORD_STATUS NOT IN(10200005,10200006)
      AND COSU_RECORD_STATUS NOT IN(10200005,10200006)
    UNION ALL
    Select Pkgreturncursor.Fncgetdescription(NVL(POSN_SUBPRODUCT_CODE,33899999),1),
      NVL(POSN_PRODUCT_CODE,33399999),ASONDATE,26099999,POSN_COMPANY_CODE,NVL(POSN_SUBPRODUCT_CODE,33899999),
      POSN_REFERENCE_NUMBER,POSN_DUE_DATE,POSN_CURRENCY_CODE,
      case when COPT_CONTRACT_TYPE = 32800001 then copt_broker_code else copt_counter_party end,
      POSN_REFERENCE_DATE,
      POSN_FCY_RATE,COPT_BASE_AMOUNT,POSN_USER_REFERENCE,POSN_USER_REFERENCE,
      0,0,0,POSN_LOCATION_CODE,cosu_buy_sell,1,1,
      'Options-Exchange',4,12400002,POSN_FOR_CURRENCY,POSN_MATURITY_FROM,
      case when COPT_CONTRACT_TYPE = 32800001 then copt_broker_code else copt_counter_party end,COPT_PREMIUM_STATUS,
      CASE WHEN NVL(COPT_PREMIUM_DOLLERAMOUNT,0) != 0 THEN
        ROUND(decode(COPT_PREMIUM_STATUS,33200001,ABS(COPT_PREMIUM_DOLLERAMOUNT),33200002,-1*ABS(COPT_PREMIUM_DOLLERAMOUNT)) * fncgetPandLRate(COPT_DEAL_NUMBER,1,AsonDate,2),2)
      ELSE      
        decode(COPT_PREMIUM_STATUS,33200001,ABS(COPT_PREMIUM_AMOUNT),33200002,-1*(ABS(COPT_PREMIUM_AMOUNT))) END,
      COSU_OPTION_TYPE,
      fncgetPandLRate(POSN_REFERENCE_NUMBER,1,ASONDATE,2),fncgetDeltaValue(POSN_REFERENCE_NUMBER,ASONDATE),
      ABS(POSN_TRANSACTION_AMOUNT),
--      CASE WHEN COPT_BASE_CURRENCY = 30400004 THEN
--      ABS(POSN_TRANSACTION_AMOUNT)
--      WHEN COPT_OTHER_CURRENCY = 30400004 THEN
--      ABS(round(POSN_TRANSACTION_AMOUNT * COSU_STRIKE_RATE,2)) 
--      WHEN COPT_BASE_CURRENCY != 30400004 AND COPT_OTHER_CURRENCY != 30400004 THEN
--      ABS(round(POSN_TRANSACTION_AMOUNT * 
--      pkgforexprocess.fncGetRate(posn_currency_CODE,30400004,POSN_REFERENCE_DATE,COSU_BUY_SELL,0,posn_due_date),2)) END,
      COPT_RECORD_STATUS,COPT_CONFIRM_DATE,COPT_TIME_STAMP,
      COPT_DEALER_NAME,COPT_COUNTER_DEALER,CASE WHEN COPT_CONTRACT_TYPE = 32800001 THEN COPT_EXCHANGE_CODE ELSE 0 END,
      COPT_PREMIUM_VALUEDATE,COPT_USER_ID,COPT_PREMIUM_DOLLERAMOUNT,NULL ,
      fncGetOptionRate(COPT_DEAL_NUMBER,32400001,25300001)BuyCall,
      fncGetOptionRate(COPT_DEAL_NUMBER,32400001,25300002)SellCall,
      fncGetOptionRate(COPT_DEAL_NUMBER,32400002,25300002)SellPut,
      fncGetOptionRate(COPT_DEAL_NUMBER,32400002,25300001)BuyPut,
      fncGetRBIRefRate(ASONDATE,POSN_CURRENCY_CODE),
      fncGetDayoneFrwd(POSN_REFERENCE_NUMBER,ASONDATE,POSN_CURRENCY_CODE),
      decode(COPT_PREMIUM_STATUS,33200001,COPT_PREMIUM_RATE,33200002,-1*COPT_PREMIUM_RATE)    
      from TRSYSTEM997,TRTRAN071,TRTRAN072  where 
      COPT_DEAL_NUMBER = POSN_REFERENCE_NUMBER 
      AND COPT_DEAL_NUMBER = COSU_DEAL_NUMBER
      AND COPT_CONTRACT_TYPE = 32800001
      AND POSN_TRANSACTION_AMOUNT != 0
      AND COSU_SERIAL_NUMBER = POSN_REFERENCE_SERIAL        
      AND COPT_RECORD_STATUS NOT IN(10200005,10200006)
      AND COSU_RECORD_STATUS NOT IN(10200005,10200006);

    varOperation := 'All canceled data insert';
    insert into trsystem983 (userId,Deal_type,ason_date,HedgeTrade,CompanyCode,Trader,
                            dealnumber,maturitydate,CURRENCYCODE,COUNTERPARTY,EXECUTEDATE,
                            EXCHANGERATE,DEALBASEAMOUNT,DEALREMARKS,USERREFERENCE,
                            SPOTRATE,FORWARDRATE,MARGINRATE,LOCATIONCODE,BUYSELLCODE,
                            DEALSERIAL,DEALSUBSERIAL,DESCRIPTION,RECORDER,ProcessComplete,
                            FORCURRENCY,EXPIRYDATE, PROFITLOSS,CANCELAMOUNT,CANCELRATE,canceldate,
                            CANCELSPOT,CANCELFORWARD,CANCELMARGIN,BROKERCODE,CANCELPNLSPOT,
                            OUTSTANDINGAMOUNT,RECORDSTATUS,CONFIRMDATE,DEALTIMESTAMP,
                            DEALERNMAE,COUNTERDEALER,EXCHANGECODE,PREMIUMVALUEDATE,
                            CCONFIRMDATE,CRECORDSTATUS,CDEALERNAME,CCOUNTERDEALER,CEDCCHARGE,CCASHFLOWDATE,
                            CPREMIUMSTATUS, CPREMIUMAMOUNT,EXERCISETYPE,ENTERDBY,CENTERDBY,PREMIUMAMOUNT,PREMIUMSTATUS,
                            EXCERSISETYPE,OPTIONTYPE,PREMIUMDOLLERAMT,TransactionType,
                            BUYCALL,SELLCALL,SELLPUT,BUYPUT,RBIREFRATE,PREMIUMINRATEINSEPTION,PREMIUMINRATECANCEL)
    Select Pkgreturncursor.Fncgetdescription(NVL(Deal_Init_Code,33899999),1),
      NVL(DEAL_BACKUP_DEAL,33399999),ASONDATE,deal_hedge_trade,DEAL_COMPANY_CODE,NVL(Deal_Init_Code,33899999),
      deal_deal_number,deal_maturity_date,deal_base_currency,deal_counter_party,DEAL_EXECUTE_DATE,
      deal_exchange_rate,DEAL_BASE_AMOUNT,
      DEAL_DEALER_REMARKS,DEAL_USER_REFERENCE,
      deal_spot_rate,deal_forward_rate,deal_margin_rate,deal_location_code,deal_buy_sell,CDEL_REVERSE_SERIAL,1,
      'Forward',2,12400001,deal_other_currency,deal_maturity_from,
      CDEL_PROFIT_LOSS,CDEL_CANCEL_AMOUNT,
--      CASE WHEN DEAL_BASE_CURRENCY = 30400004 THEN
--      CDEL_CANCEL_AMOUNT
--      WHEN DEAL_OTHER_CURRENCY = 30400004 THEN
--      round(CDEL_CANCEL_AMOUNT * CDEL_CANCEL_RATE,2) 
--      WHEN DEAL_BASE_CURRENCY != 30400004 AND DEAL_OTHER_CURRENCY != 30400004 THEN
--      round(CDEL_CANCEL_AMOUNT * 
--      pkgforexprocess.fncGetRate(DEAL_BASE_CURRENCY,30400004,CDEL_CANCEL_DATE,DEAL_BUY_SELL,0,DEAL_MATURITY_DATE),2) END,
      CDEL_CANCEL_RATE,CDEL_CANCEL_DATE,
      trtran006.CDEL_SPOT_RATE,trtran006.CDEL_FORWARD_RATE,trtran006.CDEL_MARGIN_RATE,DEAL_COUNTER_PARTY,
      fncgetPandLRate(cdel_deal_number,CDEL_REVERSE_SERIAL,ASONDATE,1),0,
      DEAL_RECORD_STATUS,DEAL_CONFIRM_DATE,DEAL_TIME_STAMP,
      DEAL_DEALER_NAME,DEAL_COUNTER_DEALER,0,NULL,
      CDEL_CONFIRM_DATE,CDEL_RECORD_STATUS,CDEL_DEALER_NAME,CDEL_COUNTER_DEALER,
      CDEL_EDC_CHARGE,CDEL_CASHFLOW_DATE,0,0,0,DEAL_USER_ID,CDEL_USER_ID,0,0,CDEL_CANCEL_TYPE,0,0,DEAL_SWAP_OUTRIGHT,
      0,0,0,0,fncGetRBIRefRate(cdel_cancel_date,deal_base_currency),0,0
      from trtran006,trtran001
        where deal_deal_number=cdel_deal_number
        and cdel_cancel_date between frmdate and ASONDATE
        and cdel_record_status not in (10200005,10200006)
        and deal_record_status not in (10200005,10200006)
        AND DEAL_DEAL_TYPE NOT IN(25400001)
     UNION ALL
      Select Pkgreturncursor.Fncgetdescription(NVL(Cfut_Init_Code,33899999),1),
        NVL(CFUT_BACKUP_DEAL,33399999),ASONDATE,cfut_hedge_trade,CFUT_COMPANY_CODE,NVL(Cfut_Init_Code,33899999),
        cfut_deal_number,cfut_maturity_date,cfut_base_currency,cfut_counter_party,cfut_EXECUTE_DATE,
        cfut_exchange_rate, CFUT_BASE_AMOUNT,
        cfut_DEALER_REMARK,cfut_USER_REFERENCE,
        cfut_spot_rate,cfut_forward_rate,cfut_bank_margin,cfut_location_code,cfut_buy_sell,CFRV_REVERSE_SERIAL,1,
        'Future ',1,12400001,cfut_other_currency,CFUT_MATURITY_FROM,
        CFRV_PROFIT_LOSS,CFRV_CANCEL_AMOUNT,
--        CASE WHEN CFUT_BASE_CURRENCY = 30400004 THEN
--        CFRV_CANCEL_AMOUNT
--        WHEN CFUT_OTHER_CURRENCY = 30400004 THEN
--        round(CFRV_CANCEL_AMOUNT * CFRV_EXCHANGE_RATE,2) 
--        WHEN CFUT_BASE_CURRENCY != 30400004 AND CFUT_OTHER_CURRENCY != 30400004 THEN
--        round(CFRV_CANCEL_AMOUNT * 
--        pkgforexprocess.fncGetRate(CFUT_BASE_CURRENCY,30400004,cfrv_execute_date,CFUT_BUY_SELL,0,cfut_maturity_date),2) END,        
        CFRV_LOT_PRICE,CFRV_EXECUTE_DATE,
        CFRV_SPOT_RATE,NVL(CFRV_FORWARD_RATE,0),NVL(CFRV_BANK_MARGIN,0),cfut_counter_party,
        fncgetPandLRate(cfut_deal_number,1,ASONDATE,2),0,
        CFUT_RECORD_STATUS,CFUT_CONFIRM_DATE,CFUT_TIME_STAMP,
        CFUT_DEALER_NAME,CFUT_COUNTER_DEALER,CFUT_EXCHANGE_CODE,NULL,
        CFRV_CONFIRM_DATE,CFRV_RECORD_STATUS,CFRV_DEALER_NAME,CFRV_COUNTER_DEALER,0,NULL,0,0,0,
        CFUT_USER_ID,CFRV_USER_ID,0,0,27000001,0,0,NULL,
        0,0,0,0,fncGetRBIRefRate(cfrv_execute_date,cfut_base_currency),0,0
        from trtran063,trtran061
        where cfut_deal_number = cfrv_deal_number
        and cfrv_execute_date between frmdate and ASONDATE
        and cfrv_record_status not in (10200005,10200006)
        and cfut_record_status not in (10200005,10200006)
        UNION ALL
      Select Pkgreturncursor.Fncgetdescription(NVL(Copt_Init_Code,33899999),1),
        NVL(COPT_BACKUP_DEAL,33399999),ASONDATE ,copt_hedge_trade,COPT_COMPANY_CODE,NVL(Copt_Init_Code,33899999),
        copt_deal_number,cosm_maturity_date,copt_base_currency,
        case when COPT_CONTRACT_TYPE = 32800001 then copt_broker_code else copt_counter_party end,
        copt_EXECUTE_DATE,
        cosu_strike_rate, COPT_BASE_AMOUNT,copt_DEALER_REMARK,copt_USER_REFERENCE,
        cosu_strike_rate,0,0,copt_location_code,cosu_buy_sell,CORV_REVERSE_SERIAL,COSM_SUBSERIAL_NUMBER,
        'Options-OTC',5,12400001,copt_other_currency,COSM_SETTLEMENT_DATE,
        PKGFOREXPROCESS.Fncgetprofitlossoptnetpandl(CORV_DEAL_NUMBER, CORV_REVERSE_SERIAL,ASONDATE), 
        CORV_BASE_AMOUNT,
--        CASE WHEN COPT_BASE_CURRENCY = 30400004 THEN
--        CORV_BASE_AMOUNT
--        WHEN COPT_OTHER_CURRENCY = 30400004 THEN
--        round(CORV_BASE_AMOUNT * COSU_STRIKE_RATE,2) 
--        WHEN COPT_BASE_CURRENCY != 30400004 AND COPT_OTHER_CURRENCY != 30400004 THEN
--        round(CORV_BASE_AMOUNT * 
--        pkgforexprocess.fncGetRate(COPT_BASE_CURRENCY,30400004,corv_exercise_date,COSU_BUY_SELL,0,cosm_maturity_date),2) END,
        CORV_EXERCISE_RATE,CORV_EXERCISE_DATE,CORV_RBI_REFRATE,0,CORV_MARGIN_RATE,
        case when COPT_CONTRACT_TYPE = 32800001 then copt_broker_code else copt_counter_party end,
        fncgetPandLRate(COPT_DEAL_NUMBER,CORV_REVERSE_SERIAL,ASONDATE,3),0,COPT_RECORD_STATUS,COPT_CONFIRM_DATE,COPT_TIME_STAMP,
        COPT_DEALER_NAME,COPT_COUNTER_DEALER,
        CASE WHEN COPT_CONTRACT_TYPE = 32800001 THEN COPT_EXCHANGE_CODE ELSE 0 END,
        COPT_PREMIUM_VALUEDATE,
        CORV_CONFIRM_DATE,CORV_RECORD_STATUS,CORV_DEALER_NAME,CORV_COUNTER_DEALER,0,
        CASE WHEN CORV_EXERCISE_TYPE IN(33000001,33000003) THEN CORV_SETTLEMENT_DATE END,
        CORV_PREMIUM_STATUS,
        decode(corv_premium_status,33200001,1,33200002,-1,1)* corv_profit_loss,
        CORV_EXERCISE_TYPE,COPT_USER_ID,CORV_USER_ID,
        CASE WHEN NVL(COPT_PREMIUM_DOLLERAMOUNT,0) != 0 THEN
          ROUND(decode(COPT_PREMIUM_STATUS,33200001,ABS(COPT_PREMIUM_DOLLERAMOUNT),33200002,-1*ABS(COPT_PREMIUM_DOLLERAMOUNT)) * fncgetPandLRate(COPT_DEAL_NUMBER,1,AsonDate,2),2)
        ELSE      
        decode(COPT_PREMIUM_STATUS,33200001,ABS(COPT_PREMIUM_AMOUNT),33200002,-1*(ABS(COPT_PREMIUM_AMOUNT))) END,
        COPT_PREMIUM_STATUS,CORV_EXERCISE_TYPE,COSU_OPTION_TYPE,COPT_PREMIUM_DOLLERAMOUNT,NULL,
        fncGetOptionRate(COPT_DEAL_NUMBER,32400001,25300001)BuyCall,
        fncGetOptionRate(COPT_DEAL_NUMBER,32400001,25300002)SellCall,
        fncGetOptionRate(COPT_DEAL_NUMBER,32400002,25300002)SellPut,
        fncGetOptionRate(COPT_DEAL_NUMBER,32400002,25300001)BuyPut,
        fncGetRBIRefRate(corv_exercise_date,copt_base_currency),
        decode(COPT_PREMIUM_STATUS,33200001,COPT_PREMIUM_RATE,33200002,-1*COPT_PREMIUM_RATE),
        decode(corv_premium_status,33200001,CORV_PREMIUM_RATE,33200002,-1*CORV_PREMIUM_RATE)        
        From  trtran071
        JOIN TRTRAN072A 
        ON COPT_DEAL_NUMBER         = COSM_DEAL_NUMBER
        AND COSM_SERIAL_NUMBER = 1
        AND COSM_RECORD_STATUS NOT IN(10200005,10200006)
        JOIN TRTRAN072
        ON COSU_DEAL_NUMBER         = COSM_DEAL_NUMBER
        AND COSU_SERIAL_NUMBER      = COSM_SERIAL_NUMBER
        AND COSU_RECORD_STATUS NOT IN(10200005,10200006)
        AND COSU_SERIAL_NUMBER = 1
        JOIN TRTRAN073
        ON copt_deal_number = corv_deal_number 
        AND Corv_Record_Status Not In (10200005,10200006)
        AND corv_exercise_date BETWEEN frmdate and ASONDATE
        WHERE copt_record_status between 10200001 and 10200004
        AND COPT_CONTRACT_TYPE = 32800002
      union all  
      Select Pkgreturncursor.Fncgetdescription(NVL(Copt_Init_Code,33899999),1),
        NVL(COPT_BACKUP_DEAL,33399999),ASONDATE ,copt_hedge_trade,COPT_COMPANY_CODE,NVL(Copt_Init_Code,33899999),
        copt_deal_number,cosm_maturity_date,copt_base_currency,
        case when COPT_CONTRACT_TYPE = 32800001 then copt_broker_code else copt_counter_party end,copt_EXECUTE_DATE,
        cosu_strike_rate,COPT_BASE_AMOUNT,copt_DEALER_REMARK,copt_USER_REFERENCE,
        cosu_strike_rate,0,0,copt_location_code,cosu_buy_sell,CORV_REVERSE_SERIAL,COSM_SUBSERIAL_NUMBER,
        'Options-Exchange',4,12400001,copt_other_currency,COSM_SETTLEMENT_DATE,
        PKGFOREXPROCESS.Fncgetprofitlossoptnetpandl(CORV_DEAL_NUMBER, CORV_REVERSE_SERIAL,ASONDATE), 
        CORV_BASE_AMOUNT,
--        CASE WHEN COPT_BASE_CURRENCY = 30400004 THEN
--        CORV_BASE_AMOUNT
--        WHEN COPT_OTHER_CURRENCY = 30400004 THEN
--        round(CORV_BASE_AMOUNT * COSU_STRIKE_RATE,2) 
--        WHEN COPT_BASE_CURRENCY != 30400004 AND COPT_OTHER_CURRENCY != 30400004 THEN
--        round(CORV_BASE_AMOUNT * 
--        pkgforexprocess.fncGetRate(COPT_BASE_CURRENCY,30400004,corv_exercise_date,COSU_BUY_SELL,0,cosm_maturity_date),2) END,
        CORV_EXERCISE_RATE,CORV_EXERCISE_DATE,CORV_RBI_REFRATE,0,CORV_MARGIN_RATE,
        case WHEN COPT_CONTRACT_TYPE = 32800001 then copt_broker_code else copt_counter_party end,
        fncgetPandLRate(COPT_DEAL_NUMBER,CORV_REVERSE_SERIAL,ASONDATE,3),0,
        COPT_RECORD_STATUS,COPT_CONFIRM_DATE,COPT_TIME_STAMP,
        COPT_DEALER_NAME,COPT_COUNTER_DEALER,
        CASE WHEN COPT_CONTRACT_TYPE = 32800001 THEN COPT_EXCHANGE_CODE ELSE 0 END,
        COPT_PREMIUM_VALUEDATE,
        CORV_CONFIRM_DATE,CORV_RECORD_STATUS,CORV_DEALER_NAME,CORV_COUNTER_DEALER,0,
        CASE WHEN CORV_EXERCISE_TYPE IN(33000001,33000003) THEN CORV_SETTLEMENT_DATE END,
        CORV_PREMIUM_STATUS,
        decode(corv_premium_status,33200001,1,33200002,-1,1)* corv_profit_loss,
        CORV_EXERCISE_TYPE,COPT_USER_ID,CORV_USER_ID,
        CASE WHEN NVL(COPT_PREMIUM_DOLLERAMOUNT,0) != 0 THEN
          ROUND(decode(COPT_PREMIUM_STATUS,33200001,ABS(COPT_PREMIUM_DOLLERAMOUNT),33200002,-1*ABS(COPT_PREMIUM_DOLLERAMOUNT)) * fncgetPandLRate(COPT_DEAL_NUMBER,1,AsonDate,2),2)
        ELSE      
        decode(COPT_PREMIUM_STATUS,33200001,ABS(COPT_PREMIUM_AMOUNT),33200002,-1*(ABS(COPT_PREMIUM_AMOUNT))) END,
        COPT_PREMIUM_STATUS,CORV_EXERCISE_TYPE,COSU_OPTION_TYPE,COPT_PREMIUM_DOLLERAMOUNT,NULL,
        fncGetOptionRate(COPT_DEAL_NUMBER,32400001,25300001)BuyCall,
        fncGetOptionRate(COPT_DEAL_NUMBER,32400001,25300002)SellCall,
        fncGetOptionRate(COPT_DEAL_NUMBER,32400002,25300002)SellPut,
        fncGetOptionRate(COPT_DEAL_NUMBER,32400002,25300001)BuyPut,
        fncGetRBIRefRate(corv_exercise_date,copt_base_currency),
        decode(COPT_PREMIUM_STATUS,33200001,COPT_PREMIUM_RATE,33200002,-1*COPT_PREMIUM_RATE),
        decode(corv_premium_status,33200001,CORV_PREMIUM_RATE,33200002,-1*CORV_PREMIUM_RATE)        
        From  trtran071
        JOIN TRTRAN072A 
        ON COPT_DEAL_NUMBER         = COSM_DEAL_NUMBER
        AND COSM_SERIAL_NUMBER = 1
        AND COSM_RECORD_STATUS NOT IN(10200005,10200006)
        JOIN TRTRAN072
        ON COSU_DEAL_NUMBER         = COSM_DEAL_NUMBER
        AND COSU_SERIAL_NUMBER      = COSM_SERIAL_NUMBER
        AND COSU_SERIAL_NUMBER = 1
        AND COSU_RECORD_STATUS NOT IN(10200005,10200006)
        JOIN TRTRAN073
        ON copt_deal_number = corv_deal_number 
        AND Corv_Record_Status Not In (10200005,10200006)
        AND corv_exercise_date BETWEEN frmdate and ASONDATE
        WHERE copt_record_status between 10200001 and 10200004
        AND COPT_CONTRACT_TYPE = 32800001;
      commit;
      if MTMRate = 'Y' THEN      
        varOperation := 'Updating MTM values for Forwards';
        update trsystem983 
        set FRWMTM = 
        (select sum(pkgreturnreport.fncgetprofitloss(pkgForexProcess.fncGetOutstanding(deal_deal_number,
          deal_serial_number,GConst.UTILTRADEDEAL,GConst.AMOUNTFCY,asondate),
          (CASE WHEN DEAL_BUY_SELL = 25300001 THEN(
          pkgforexprocess.fncGetRate(deal_base_currency,deal_other_currency,
          asondate,deal_buy_sell,(pkgForexProcess.fncAllotMonth(deal_counter_party,
          asondate,deal_maturity_date)),
          deal_maturity_date)) ELSE
          (pkgforexprocess.fncGetRate(deal_base_currency,deal_other_currency,
          asondate,deal_buy_sell,(pkgForexProcess.fncAllotMonth(deal_counter_party,
          asondate,deal_maturity_date)),
          deal_maturity_date))END), DEAL_EXCHANGE_RATE, deal_buy_sell) *
          decode(deal_other_currency,30400003,1, pkgforexprocess.fncGetRate(deal_other_currency,30400003,
          asondate,deal_buy_sell,pkgForexProcess.fncAllotMonth(deal_counter_party,
          asondate,deal_maturity_date),deal_maturity_date)))
          From  Trtran001
          Where  ((Deal_Process_Complete = 12400001  and DEAL_COMPLETE_DATE > AsonDate )or Deal_Process_Complete = 12400002) 
          And Deal_Record_Status Not In (10200005,10200006)
         and deal_execute_date <= AsonDate
          --And Pkgreturncursor.Fncgetdescription(Deal_Init_Code,2) = Userid
          and DEAl_company_code In 
          (Select Usco_Company_Code 
            From Trsystem022a 
            Where Usco_User_Id =varUserID) 
          and DEAL_BACKUP_DEAL = Deal_type
          --And Deal_Hedge_Trade = Hedgetrade
          and deal_deal_number = dealnumber
          And Companycode = Deal_Company_Code
          and Trader = deal_Init_Code) 
        where ason_date = AsonDate
        and RECORDER in(2,3)
        and PROCESSCOMPLETE = 12400002;
  
  --     update trsystem983 
  --      set MTMRATE = 
  --      (select (CASE WHEN DEAL_BUY_SELL = 25300001 THEN(
  --        pkgforexprocess.fncGetRate(deal_base_currency,deal_other_currency,
  --        asondate,deal_buy_sell,(pkgForexProcess.fncAllotMonth(deal_counter_party,
  --        asondate,deal_maturity_date)),
  --        deal_maturity_date)) ELSE
  --        (pkgforexprocess.fncGetRate(deal_base_currency,deal_other_currency,
  --        asondate,deal_buy_sell,(pkgForexProcess.fncAllotMonth(deal_counter_party,
  --        asondate,deal_maturity_date)),
  --        deal_maturity_date))END)
  --        From  Trtran001
  --        Where  ((Deal_Process_Complete = 12400001  and DEAL_COMPLETE_DATE > AsonDate )or Deal_Process_Complete = 12400002) 
  --        And Deal_Record_Status Not In (10200005,10200006)
  --       and deal_execute_date <= AsonDate
  --        --And Pkgreturncursor.Fncgetdescription(Deal_Init_Code,2) = Userid
  --        and DEAl_company_code In 
  --        (Select Usco_Company_Code 
  --          From Trsystem022a 
  --          Where Usco_User_Id =varUserID) 
  --        and DEAL_BACKUP_DEAL = Deal_type
  --        --And Deal_Hedge_Trade = Hedgetrade
  --        and deal_deal_number = dealnumber
  --        And Companycode = Deal_Company_Code
  --        and Trader = deal_Init_Code) 
  --      where ason_date = AsonDate
  --      and RECORDER in(2,3)
  --      and PROCESSCOMPLETE = 12400002;
    varOperation := 'Updating MTM rate for Forwards';      
       update trsystem983 
        set MTMRATE = 
        (select (CASE WHEN DEAL_BUY_SELL = 25300001 THEN(
          pkgforexprocess.fncGetRate(deal_base_currency,deal_other_currency,
          asondate,deal_buy_sell,(pkgForexProcess.fncAllotMonth(deal_counter_party,
          asondate,deal_maturity_date)),
          deal_maturity_date)) ELSE
          (pkgforexprocess.fncGetRate(deal_base_currency,deal_other_currency,
          asondate,deal_buy_sell,(pkgForexProcess.fncAllotMonth(deal_counter_party,
          asondate,deal_maturity_date)),
          deal_maturity_date))END)
          From  Trtran001
          Where  ((Deal_Process_Complete = 12400001  and DEAL_COMPLETE_DATE > AsonDate )or Deal_Process_Complete = 12400002) 
          And Deal_Record_Status Not In (10200005,10200006)
         and deal_execute_date <= AsonDate
          --And Pkgreturncursor.Fncgetdescription(Deal_Init_Code,2) = Userid
          and DEAl_company_code In 
          (Select Usco_Company_Code 
            From Trsystem022a 
            Where Usco_User_Id =varUserID) 
          and DEAL_BACKUP_DEAL = Deal_type
          --And Deal_Hedge_Trade = Hedgetrade
          and deal_deal_number = dealnumber
          And Companycode = Deal_Company_Code
          and Trader = deal_Init_Code) 
        where ason_date = AsonDate
        and RECORDER in(2,3)
        and PROCESSCOMPLETE = 12400002;     
    varOperation := 'Updating MTM spot for Forwards';     
       update trsystem983 
        set MTMSPOT = 
        (select (CASE WHEN DEAL_BUY_SELL = 25300001 THEN(
          pkgforexprocess.fncGetRate(deal_base_currency,deal_other_currency,
          asondate,deal_buy_sell,0,asondate)) ELSE
          (pkgforexprocess.fncGetRate(deal_base_currency,deal_other_currency,
          asondate,deal_buy_sell,0,asondate))END)
          From  Trtran001
          Where  ((Deal_Process_Complete = 12400001  and DEAL_COMPLETE_DATE > AsonDate )or Deal_Process_Complete = 12400002) 
          And Deal_Record_Status Not In (10200005,10200006)
         and deal_execute_date <= AsonDate
          --And Pkgreturncursor.Fncgetdescription(Deal_Init_Code,2) = Userid
          and DEAl_company_code In 
          (Select Usco_Company_Code 
            From Trsystem022a 
            Where Usco_User_Id =varUserID) 
          and DEAL_BACKUP_DEAL = Deal_type
          --And Deal_Hedge_Trade = Hedgetrade
          and deal_deal_number = dealnumber
          And Companycode = Deal_Company_Code
          and Trader = deal_Init_Code) 
        where ason_date = AsonDate
        and RECORDER in(2,3)
        and PROCESSCOMPLETE = 12400002;
        
          varOperation := 'Updating Spot USD rate for Forwards';      
--        update trsystem983 
--        set SPOTUSDRATE = 
--        (select (CASE WHEN DEAL_BUY_SELL = 25300001 THEN(
--          decode(deal_other_currency,30400003,1,pkgForexProcess.fncGetRate(FORCURRENCY,30400003,ASONDATE,25300001,0,NULL))
--          ELSE
--          decode(deal_other_currency,30400003,1,pkgForexProcess.fncGetRate(FORCURRENCY,30400003,ASONDATE,25300002,0,NULL))END))
--          From  Trtran001
--          Where  ((Deal_Process_Complete = 12400001  and DEAL_COMPLETE_DATE > AsonDate )or Deal_Process_Complete = 12400002) 
--          And Deal_Record_Status Not In (10200005,10200006)
--         and deal_execute_date <= AsonDate
--          --And Pkgreturncursor.Fncgetdescription(Deal_Init_Code,2) = Userid
--          and DEAl_company_code In 
--          (Select Usco_Company_Code 
--            From Trsystem022a 
--            Where Usco_User_Id =varUserID) 
--          and DEAL_BACKUP_DEAL = Deal_type
--          --And Deal_Hedge_Trade = Hedgetrade
--          and deal_deal_number = dealnumber
--          And Companycode = Deal_Company_Code
--          and Trader = deal_Init_Code) 
--        where ason_date = AsonDate
--        and RECORDER in(2,3)
--        and PROCESSCOMPLETE = 12400002;   
        
              update trsystem983 
      set SPOTUSDRATE = 
      (select (CASE WHEN DEAL_BUY_SELL = 25300001 THEN(
        decode(deal_other_currency,30400003,1,pkgForexProcess.fncGetRate(FORCURRENCY,30400003,ASONDATE,25300001,0,NULL))) ELSE
         decode(deal_other_currency,30400003,1,pkgForexProcess.fncGetRate(FORCURRENCY,30400003,ASONDATE,25300002,0,NULL))END)
        From  Trtran001
        Where  ((Deal_Process_Complete = 12400001  and DEAL_COMPLETE_DATE > AsonDate )or Deal_Process_Complete = 12400002) 
        And Deal_Record_Status Not In (10200005,10200006)
       and deal_execute_date <= AsonDate
        --And Pkgreturncursor.Fncgetdescription(Deal_Init_Code,2) = Userid
        and DEAl_company_code In 
        (Select Usco_Company_Code 
          From Trsystem022a 
          Where Usco_User_Id =varUserID) 
        and DEAL_BACKUP_DEAL = Deal_type
        --And Deal_Hedge_Trade = Hedgetrade
        and deal_deal_number = dealnumber
        And Companycode = Deal_Company_Code
        and Trader = deal_Init_Code) 
      where ason_date = AsonDate
      and RECORDER in(2,3)
      and PROCESSCOMPLETE = 12400002; 
  
        varOperation := 'Updating MTM values for Futures';
        Update Trsystem983 Set FRWMTM = 
        (Select  sum(Pkgforexprocess.Fncgetprofitloss((Pkgforexprocess.Fncgetoutstanding(Cfut_Deal_Number, 0,14,1,asondate )*1000),
          (CASE WHEN CFUT_BUY_SELL = 25300001 THEN
          (Pkgforexprocess.Fncfuturemtmrate(Cfut_Maturity_Date,Cfut_Exchange_Code,Cfut_Base_Currency,Cfut_Other_Currency,
          asondate)- CFUT_BANK_MARGIN) ELSE 
          (Pkgforexprocess.Fncfuturemtmrate(Cfut_Maturity_Date,Cfut_Exchange_Code,Cfut_Base_Currency,Cfut_Other_Currency,
          asondate)+ CFUT_BANK_MARGIN) END),
          Cfut_Exchange_Rate,Cfut_Buy_Sell) *
          Decode(Cfut_Other_Currency,30400003,1,Pkgforexprocess.Fncfuturemtmrate(Cfut_Maturity_Date,Cfut_Exchange_Code,
          CFUT_BASE_CURRENCY,CFUT_OTHER_CURRENCY, asondate)))
          From Trtran061                
          Where((cfut_Process_Complete = 12400001  and cfut_COMPLETE_DATE > AsonDate )or cfut_Process_Complete = 12400002) 
          --And Pkgreturncursor.Fncgetdescription(Cfut_Init_Code,2) =Userid
          and  Cfut_Record_Status Not In (10200005,10200006)
          And Cfut_Backup_Deal=Deal_Type
          --And Cfut_Hedge_Trade=Hedgetrade
          And Companycode=Cfut_Company_Code
          And Trader = Cfut_Init_Code
          and Cfut_Deal_Number = dealnumber
          And Cfut_Execute_Date <= Asondate
          And Cfut_Company_Code In 
          (Select Usco_Company_Code 
            From Trsystem022a 
            Where Usco_User_Id =Varuserid) 
          group by Userid,Deal_Type) 
        where ason_date = AsonDate 
        and RECORDER = 1
        and PROCESSCOMPLETE = 12400002;
  
        varOperation := 'Updating MTM values for Futures';
        Update Trsystem983 Set MTMRATE = 
        (Select  
          (CASE WHEN CFUT_BUY_SELL = 25300001 THEN
          (Pkgforexprocess.Fncfuturemtmrate(Cfut_Maturity_Date,Cfut_Exchange_Code,Cfut_Base_Currency,Cfut_Other_Currency,
          asondate)- CFUT_BANK_MARGIN) ELSE 
          (Pkgforexprocess.Fncfuturemtmrate(Cfut_Maturity_Date,Cfut_Exchange_Code,Cfut_Base_Currency,Cfut_Other_Currency,
          asondate)+ CFUT_BANK_MARGIN) END)
          From Trtran061                
          Where((cfut_Process_Complete = 12400001  and cfut_COMPLETE_DATE > AsonDate )or cfut_Process_Complete = 12400002) 
          --And Pkgreturncursor.Fncgetdescription(Cfut_Init_Code,2) =Userid
          and  Cfut_Record_Status Not In (10200005,10200006)
          And Cfut_Backup_Deal=Deal_Type
          --And Cfut_Hedge_Trade=Hedgetrade
          And Companycode=Cfut_Company_Code
          And Trader = Cfut_Init_Code
          and Cfut_Deal_Number = dealnumber
          And Cfut_Execute_Date <= Asondate
          And Cfut_Company_Code In 
          (Select Usco_Company_Code 
            From Trsystem022a 
            Where Usco_User_Id =Varuserid)) 
        where ason_date = AsonDate 
        and RECORDER = 1
        and PROCESSCOMPLETE = 12400002;
        
        Update Trsystem983 Set MTMSPOT = 
        (Select  
          (CASE WHEN CFUT_BUY_SELL = 25300001 THEN
          (Pkgforexprocess.Fncfuturemtmrate(asondate,Cfut_Exchange_Code,Cfut_Base_Currency,Cfut_Other_Currency,
          asondate)- CFUT_BANK_MARGIN) ELSE 
          (Pkgforexprocess.Fncfuturemtmrate(asondate,Cfut_Exchange_Code,Cfut_Base_Currency,Cfut_Other_Currency,
          asondate)+ CFUT_BANK_MARGIN) END)
          From Trtran061                
          Where((cfut_Process_Complete = 12400001  and cfut_COMPLETE_DATE > AsonDate )or cfut_Process_Complete = 12400002) 
          --And Pkgreturncursor.Fncgetdescription(Cfut_Init_Code,2) =Userid
          and  Cfut_Record_Status Not In (10200005,10200006)
          And Cfut_Backup_Deal=Deal_Type
          --And Cfut_Hedge_Trade=Hedgetrade
          And Companycode=Cfut_Company_Code
          And Trader = Cfut_Init_Code
          and Cfut_Deal_Number = dealnumber
          And Cfut_Execute_Date <= Asondate
          And Cfut_Company_Code In 
          (Select Usco_Company_Code 
            From Trsystem022a 
            Where Usco_User_Id =Varuserid)) 
        where ason_date = AsonDate 
        and RECORDER = 1
        and PROCESSCOMPLETE = 12400002;      
  
        varOperation := 'Updating the transaction date';
        update trsystem983  
          set ason_date = AsonDate
          WHERE ASON_DATE IS NULL;
  
        varOperation := 'Updating the Value for option MTM'; 
        UPDATE TRSYSTEM983
          SET FRWMTM =(SELECT sum(PKGFOREXPROCESS.FNCGETOPTIONMTM(COPT_DEAL_NUMBER,asondate,checkData))
                     FROM TRTRAN071
                     WHERE  ((COPT_PROCESS_COMPLETE = 12400001  AND COPT_COMPLETE_DATE > ASONDATE )OR COPT_PROCESS_COMPLETE = 12400002) 
                      --AND PKGRETURNCURSOR.FNCGETDESCRIPTION(COPT_INIT_CODE,2) =USERID
                      AND  Copt_RECORD_STATUS NOT IN (10200005,10200006)
                      AND COPT_BACKUP_DEAL=DEAL_TYPE
                      --AND COPT_HEDGE_TRADE=HEDGETRADE
                      AND COMPANYCODE=COPT_COMPANY_CODE
                      And Trader = Copt_Init_Code
                      and COPT_DEAL_NUMBER = dealnumber
                      And Copt_Execute_Date <= Asondate
                      And Copt_Company_Code In 
                      (Select Usco_Company_Code 
                        FROM TRSYSTEM022A 
                        WHERE USCO_USER_ID =VARUSERID) )
                    --  group by Userid,Deal_Type) 
                   where ason_date = AsonDate
                   and RECORDER in(5,4,6)
                   and PROCESSCOMPLETE = 12400002; 
  
        varOperation := 'INR Primium update for All deals taking from bloomberg';            
        update trsystem983 set OPTVPLINR = fncgetUploadPrimiumValue(dealnumber,AsonDate,2)
          where RECORDER in(4,5,6) and PROCESSCOMPLETE = 12400002
          and ason_date = AsonDate;
  
        varOperation := 'USD Primium update for All deals taking from bloomberg';            
        update trsystem983 set OPTVPLUSD = fncgetUploadPrimiumValue(dealnumber,AsonDate,1) 
          where RECORDER in(4,5,6) and PROCESSCOMPLETE = 12400002
          and ason_date = AsonDate;
  
        update trsystem983 set PRESENTVALUEINR = fncgetUploadPrimiumValue(dealnumber,AsonDate,3) 
          where RECORDER in(4,5,6) and PROCESSCOMPLETE = 12400002
          and ason_date = AsonDate;
  
        update trsystem983 set PRESENTVALUEUSD = fncgetUploadPrimiumValue(dealnumber,AsonDate,4) 
          where RECORDER in(4,5,6) and PROCESSCOMPLETE = 12400002
          and ason_date = AsonDate;
          
          UPDATE TRSYSTEM983 SET FRWDFINALMTM = (CASE WHEN FORCURRENCY != 30400003 THEN ROUND(FRWMTM * SPOTUSDRATE,2)ELSE FRWMTM END)
          WHERE RECORDER in(2,3) and PROCESSCOMPLETE = 12400002
          and ason_date = AsonDate;
          
          UPDATE TRSYSTEM983 SET MTMPREMIUM = MTMRATE - MTMSPOT;
  --      varOperation:= 'Day one forward calculation'; 
  --      update trsystem983 set DAYONEFRWD = fncGetDayoneFrwd(dealnumber,asonDate,CurrencyCode)
  --        where RECORDER in(4,5,6) and PROCESSCOMPLETE = 12400002
  --        and ason_date = AsonDate;  
    END IF;

     commit;   
     return numError;
Exception
    When no_data_found then
      varError := '';
      numError := 0;
    When others then
      numError := SQLCODE;
      varError := SQLERRM ;
      varError := GConst.fncReturnError('TreasuryNumber', numError, varMessage, 
                      varOperation, varError);
      ROLLBACK;                      
      raise_application_error(-20101, varError);                      
      RETURN NUMERROR;
END fncProductPnlPopulate;
/