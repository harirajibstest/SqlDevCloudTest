CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCUSERPNLPOPULATE" 
    ( ASONDATE IN DATE,
      varUserID in varchar2,checkData in char default 'Y' ) 
      return number
     is
      
    PRAGMA AUTONOMOUS_TRANSACTION;
    numError number;
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    datMTD              Date;
    datYTD              Date;
    Begin
    
    varMessage := 'Generating Treasury Numbers For: ' || AsonDate;
    numError := 0;
    
    datMTD := '01-' || to_char(AsonDate,'Mon') || '-' || to_char(AsonDate,'yyyy');
    
    if to_char(asonDate,'MM') > 3 then
      datYTD := '01-apr-' || to_char(asonDate,'yyyy');
    else
      datYTD := '01-apr-' || (to_char(asonDate,'yyyy') -1);
    end if;
       
    varOperation := 'Deleting Old records for the date';         
    delete from trsystem983 
      where ason_date = AsonDate;
    
    varOperation := 'Selecting  Inserting unique values for codes';   
    insert into trsystem983 (userId,Deal_type,ason_date,HedgeTrade,CompanyCode,Trader)
    Select Distinct Pkgreturncursor.Fncgetdescription(Deal_Init_Code,2),
      DEAL_BACKUP_DEAL,asondate,deal_hedge_trade,DEAL_COMPANY_CODE,Deal_Init_Code
      from trtran001 
      Where Deal_Execute_Date >= Datytd
      and deal_record_status between 10200001 and 10200004
      and DEAl_company_code In 
      (Select Usco_Company_Code 
        From Trsystem022a 
        Where Usco_User_Id =varUserID) 
      union
      Select Distinct Pkgreturncursor.Fncgetdescription(Cfut_Init_Code,2),
        CFUT_BACKUP_DEAL,asondate,cfut_hedge_trade,CFUT_COMPANY_CODE,Cfut_Init_Code
        from trtran061 
        Where Cfut_Execute_Date>=Datytd
        and cfut_record_status between 10200001 and 10200004
        and cfut_company_code In 
        (Select Usco_Company_Code 
          From Trsystem022a 
          Where Usco_User_Id = varUserID) 
      Union
      Select Distinct Pkgreturncursor.Fncgetdescription(Copt_Init_Code,2),
        COPT_BACKUP_DEAL,asondate ,copt_hedge_trade,COPT_COMPANY_CODE,Copt_Init_Code
        From Trtran071 
        Where Copt_Execute_Date>=Datytd
        and copt_record_status between 10200001 and 10200004
       and copt_company_code In 
        (Select Usco_Company_Code 
          From Trsystem022a Where Usco_User_Id = varUserID) ;
      
      varOperation := 'Updating DTD values for Forwards';      
      update trsystem983 
      set FRWDTD =
      (select Sum(CDEL_PROFIT_LOSS)
        from trtran006,trtran001
        where deal_deal_number=cdel_deal_number
        and cdel_cancel_date = AsonDate
        and cdel_record_status not in (10200005,10200006)
        and deal_record_status not in (10200005,10200006)
        And Pkgreturncursor.Fncgetdescription(Deal_Init_Code,2) = Userid
        and cdel_company_code In 
        (Select Usco_Company_Code 
          From Trsystem022a 
          Where Usco_User_Id = varUserID) 
        and DEAL_BACKUP_DEAL = Deal_type 
        And Hedgetrade = Deal_Hedge_Trade
        And Companycode = Deal_Company_Code
        and Trader = Deal_Init_Code)
      where ason_date = AsonDate;
        
       varOperation := 'Updating MTD values for Forwards';
       update trsystem983 
        set FRWMTD = 
         (select Sum(CDEL_PROFIT_LOSS)
          from trtran006, trtran001
          where deal_deal_number = cdel_deal_number
          and cdel_cancel_date between datMTD and AsonDate
          and cdel_record_status not in (10200005,10200006)
          and deal_record_status not in (10200005,10200006)
          And Pkgreturncursor.Fncgetdescription(Deal_Init_Code,2) = Userid
          and cdel_company_code In 
          (Select Usco_Company_Code 
            From Trsystem022a 
            Where Usco_User_Id = varUserID) 
          and DEAL_BACKUP_DEAL = Deal_type
          And Hedgetrade = Deal_Hedge_Trade
          And Companycode = Deal_Company_Code
          and Trader = Deal_Init_Code)
        where ason_date = asondate ;    
       
       varOperation := 'Updating YTD values for Forwards';
       update trsystem983 
       set FRWYTD =
       (select Sum(CDEL_PROFIT_LOSS)
        from trtran006,trtran001
        where deal_deal_number = cdel_deal_number
        and cdel_cancel_date between datYTD and asondate
        and cdel_record_status not in (10200005,10200006)
        and deal_record_status not in (10200005,10200006)
        And Pkgreturncursor.Fncgetdescription(Deal_Init_Code,2) = Userid
        and cdel_company_code In 
        (Select Usco_Company_Code 
          From Trsystem022a 
          Where Usco_User_Id =varUserID) 
        and DEAL_BACKUP_DEAL = Deal_type
        And Hedgetrade = Deal_Hedge_Trade
        And Companycode = Deal_Company_Code
        and Trader =Deal_Init_Code) 
      where ason_date=asondate;                                    

      varOperation := 'Updating DTD values for futures'; 
      update trsystem983 
      set FURDTD =
      (select Sum(Cfrv_PROFIT_LOSS)
        from trtran063,trtran061
        where cfut_deal_number = cfrv_deal_number
        and cfrv_execute_date = asondate
        and cfrv_record_status not in (10200005,10200006)
        and cfut_record_status not in (10200005,10200006)
        And Pkgreturncursor.Fncgetdescription(Cfut_Init_Code,2) = Userid
        and cfrv_company_code In 
        (Select Usco_Company_Code 
          From Trsystem022a 
          Where Usco_User_Id = varUserID ) 
        and Cfut_BACKUP_DEAL = Deal_type
        And Hedgetrade= Cfut_Hedge_Trade
        And Companycode = Cfut_Company_Code
        and Trader = cfut_Init_Code) 
      where ason_date=asondate;

      varOperation := 'Updating MTD values for Futures';
      update trsystem983 
      set FURMTD = 
      (select Sum(Cfrv_PROFIT_LOSS)
        from trtran063, trtran061
        where cfut_deal_number = cfrv_deal_number
        and cfrv_execute_date between datMTD and AsonDate
        and cfrv_record_status not in (10200005,10200006)
        and cfut_record_status not in (10200005,10200006)
        And  Pkgreturncursor.Fncgetdescription(Cfut_Init_Code,2) = Userid
        and cfrv_company_code In 
        (Select Usco_Company_Code 
        From Trsystem022a 
        Where Usco_User_Id =varUserID ) 
        and Cfut_BACKUP_DEAL = Deal_type
        And Hedgetrade = Cfut_Hedge_Trade
        And Companycode = Cfut_Company_Code
        and Trader = cfut_Init_Code)
      where ason_date = AsonDate;  
      
      varOperation := 'Updating YTD values for Futures';    
      update trsystem983 
      set FURYTD =
      (select Sum(Cfrv_PROFIT_LOSS)
        from trtran063,trtran061
        where cfut_deal_number = cfrv_deal_number
        and cfrv_execute_date between datYTD and asondate
        and cfrv_record_status not in (10200005,10200006)
        and cfut_record_status not in (10200005,10200006)
        And Pkgreturncursor.Fncgetdescription(Cfut_Init_Code,2) = Userid
        and cfrv_company_code In 
        (Select Usco_Company_Code 
          From Trsystem022a 
          Where Usco_User_Id =varUserID) 
        and Cfut_BACKUP_DEAL = Deal_type
        And Hedgetrade = Cfut_Hedge_Trade
        And Companycode = Cfut_Company_Code
        and Trader = cfut_Init_Code) 
      where ason_date = AsonDate ;

      varOperation := 'Updating DTD values for Options';
      update trsystem983 
        set OPTDTD = 
        (select sum( PnL) from    
        ((select  COPT_BACKUP_DEAL,Copt_hedge_trade,copt_user_id,
          sum( decode(copt_premium_status,33200001,-1,33200002,1,0)* copt_premium_local ) PnL
          from trtran071  
          where copt_execute_date = AsonDate
          And Copt_Record_Status Not In (10200005,10200006)
          and copt_company_code In (Select Usco_Company_Code From Trsystem022a Where Usco_User_Id =varUserID ) 
          group by copt_user_id,COPT_BACKUP_DEAL,copt_hedge_trade)
          union all
          (select COPT_BACKUP_DEAL,Copt_hedge_trade,copt_user_id,
          sum( decode(corv_premium_status,33200001,-1,33200002,1,0)* corv_profit_loss) PnL
          from trtran071, trtran073 
          where copt_deal_number=corv_deal_number 
          and corv_exercise_date = AsonDate
          and copt_record_status not in (10200005,10200006)
          And Corv_Record_Status Not In (10200005,10200006)
          and copt_company_code In 
          (Select Usco_Company_Code 
            From Trsystem022a 
            Where Usco_User_Id =varUserID) 
          group by copt_user_id ,COPT_BACKUP_DEAL,copt_hedge_trade ))
        Where Copt_User_Id = Userid
        and copt_hedge_trade = hedgetrade
        and COPT_BACKUP_DEAL = Deal_type) 
      where ason_date = AsonDate ;
      
 --updating option mtd 
      varOperation := 'Updating MTD values for Options';
      update trsystem983 
        set OPTMTD =
        (select sum( PnL) from    
        ((select  COPT_BACKUP_DEAL,Copt_hedge_trade,copt_user_id,
          sum( decode(copt_premium_status,33200001,-1,33200002,1,0)* copt_premium_local ) PnL
          from trtran071  
          where copt_execute_date >= datMTD
          And Copt_Record_Status Not In (10200005,10200006)
          and copt_company_code In (Select Usco_Company_Code From Trsystem022a Where Usco_User_Id =varUserID ) 
          group by copt_user_id,COPT_BACKUP_DEAL,copt_hedge_trade)
          union all
          (select COPT_BACKUP_DEAL,Copt_hedge_trade,copt_user_id,
          sum( decode(corv_premium_status,33200001,-1,33200002,1,0)* corv_profit_loss) PnL
          from trtran071, trtran073 
          where copt_deal_number = corv_deal_number 
          and corv_exercise_date between datMTD and AsonDate
          and copt_record_status not in (10200005,10200006)
          And Corv_Record_Status Not In (10200005,10200006)
          and copt_company_code In 
          (Select Usco_Company_Code 
            From Trsystem022a 
            Where Usco_User_Id = varUserID) 
          group by copt_user_id ,COPT_BACKUP_DEAL,copt_hedge_trade))
        Where Copt_User_Id = Userid
        and copt_hedge_trade = hedgetrade
        and COPT_BACKUP_DEAL = Deal_type) 
      where ason_date = AsonDate ;
 
      varOperation := 'Updating YTD values for Options';
      Update Trsystem983 
      Set Optytd =
      (Select Sum(Pkgforexprocess.Fncgetprofitlossoptnetpandl(Copt_Deal_Number,Corv_Serial_Number)) "Pnl"
        From Trtran073, Trtran071
        where Copt_Deal_Number=Corv_Deal_Number
        and  Copt_Record_Status Not In (10200005,10200006)
        and corv_record_status not in (10200005,10200006)
        and Corv_Exercise_Date between datYTD and asondate
        And Pkgreturncursor.Fncgetdescription(Copt_Init_Code,2)=Userid
        And  Copt_Hedge_Trade=Hedgetrade
        And Copt_Backup_Deal=Deal_Type
        And Copt_Company_Code=Companycode
        And Copt_Init_Code=Trader)
      where ason_date=asondate;

      varOperation := 'Updating MTM values for Forwards';
      update trsystem983 
      set FRWMTM = 
      (select sum(pkgreturnreport.fncgetprofitloss(pkgForexProcess.fncGetOutstanding(deal_deal_number,
        deal_serial_number,GConst.UTILTRADEDEAL,GConst.AMOUNTFCY,asondate),
        pkgforexprocess.fncGetRate(deal_base_currency,deal_other_currency,
        asondate,deal_buy_sell,(pkgForexProcess.fncAllotMonth(deal_counter_party,
        asondate,deal_maturity_date)),
        deal_maturity_date), DEAL_EXCHANGE_RATE, deal_buy_sell) *
        decode(deal_other_currency,30400003,1, pkgforexprocess.fncGetRate(deal_other_currency,30400003,
        asondate,deal_buy_sell,pkgForexProcess.fncAllotMonth(deal_counter_party,
        asondate,deal_maturity_date),deal_maturity_date)))
        From  Trtran001
        Where  ((Deal_Process_Complete = 12400001  and DEAL_COMPLETE_DATE > AsonDate )or Deal_Process_Complete = 12400002) 
        And Deal_Record_Status Not In (10200005,10200006)
       and deal_execute_date <= AsonDate
        And Pkgreturncursor.Fncgetdescription(Deal_Init_Code,2) = Userid
        and DEAl_company_code In 
        (Select Usco_Company_Code 
          From Trsystem022a 
          Where Usco_User_Id =varUserID) 
        and DEAL_BACKUP_DEAL = Deal_type
        And Deal_Hedge_Trade = Hedgetrade
        And Companycode = Deal_Company_Code
        and Trader = deal_Init_Code) 
      where ason_date = AsonDate;

  
      varOperation := 'Updating MTM values for Futures';
      Update Trsystem983 Set Furmtm = 
      (Select  sum(Pkgforexprocess.Fncgetprofitloss((Pkgforexprocess.Fncgetoutstanding(Cfut_Deal_Number, 0,14,1,asondate )*1000),
        Pkgforexprocess.Fncfuturemtmrate(Cfut_Maturity_Date,Cfut_Exchange_Code,Cfut_Base_Currency,Cfut_Other_Currency,
        asondate),Cfut_Exchange_Rate,Cfut_Buy_Sell) *
        Decode(Cfut_Other_Currency,30400003,1,Pkgforexprocess.Fncfuturemtmrate(Cfut_Maturity_Date,Cfut_Exchange_Code,
        CFUT_BASE_CURRENCY,CFUT_OTHER_CURRENCY, asondate)))
        From Trtran061                
        Where((cfut_Process_Complete = 12400001  and cfut_COMPLETE_DATE > AsonDate )or cfut_Process_Complete = 12400002) 
        And Pkgreturncursor.Fncgetdescription(Cfut_Init_Code,2) =Userid
        and  Cfut_Record_Status Not In (10200005,10200006)
        And Cfut_Backup_Deal=Deal_Type
        And Cfut_Hedge_Trade=Hedgetrade
        And Companycode=Cfut_Company_Code
        And Trader = Cfut_Init_Code
        And Cfut_Execute_Date <= Asondate
        And Cfut_Company_Code In 
        (Select Usco_Company_Code 
          From Trsystem022a 
          Where Usco_User_Id =Varuserid) 
        group by Userid,Deal_Type) 
      where ason_date = AsonDate ;  
      
      varOperation := 'Updating the transaction date';
      update trsystem983  
        set ason_date = AsonDate
        WHERE ASON_DATE IS NULL;
        
      varOperation := 'Updating the Value for option MTM'; 
      UPDATE TRSYSTEM983
        SET OPTMTM =(SELECT sum(PKGFOREXPROCESS.FNCGETOPTIONMTM(COPT_DEAL_NUMBER,asondate,checkData))
                   FROM TRTRAN071
                   WHERE  ((COPT_PROCESS_COMPLETE = 12400001  AND COPT_COMPLETE_DATE > ASONDATE )OR COPT_PROCESS_COMPLETE = 12400002) 
                    AND PKGRETURNCURSOR.FNCGETDESCRIPTION(COPT_INIT_CODE,2) =USERID
                    AND  Copt_RECORD_STATUS NOT IN (10200005,10200006)
                    AND COPT_BACKUP_DEAL=DEAL_TYPE
                    AND COPT_HEDGE_TRADE=HEDGETRADE
                    AND COMPANYCODE=COPT_COMPANY_CODE
                    And Trader = Copt_Init_Code
                    And Copt_Execute_Date <= Asondate
                    And Copt_Company_Code In 
                    (Select Usco_Company_Code 
                      FROM TRSYSTEM022A 
                      WHERE USCO_USER_ID =VARUSERID) )
                  --  group by Userid,Deal_Type) 
                 where ason_date = AsonDate;        
     commit;   
     return numError;
Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM ;
      varError := GConst.fncReturnError('TreasuryNumber', numError, varMessage, 
                      varOperation, varError);
      ROLLBACK;                      
      raise_application_error(-20101, varError);                      
      RETURN NUMERROR;
END FNCUSERPNLPOPULATE;
 
 
/