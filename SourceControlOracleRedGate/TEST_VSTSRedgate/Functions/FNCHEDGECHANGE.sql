CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCHEDGECHANGE" ( datWorkDate in Date default '06-jun-08' ) RETURN NUMBER AS
  numHedgeAmt       number(15,2);
  numReversalAmt    number(15,2);
  numTradeAmt       number(15,2);
  numLossRate       number(15,2);
  numLossPercent    number(15,2);
  numLoss           number(15,2);
  varriskReference  varchar2(25);
  numriskType       number(8);
  numactionTaken    number(8);
  numlimitPercent   number(4);
  numHBaseCurrency  number(8);
  numHOtherCurrency number(8);
  varstackHolder    varchar(50);
  varmobileNo       varchar(12);
  varemailID        varchar(50);
  numVaryRate       number(15,6);
  numlimitLocal     number(10,6);
  numrateTemp       number(15,6);
  numserialno       number(4);
  numtemp           number(15,6);
  numtemp1          number(15,6);
BEGIN  

 delete from trsystem996 where crsk_risk_type=21000017;

for curfields in 
--           (select a.Company,a.tradereference,a.traderate,a.importExport,
--                  a.tradecurrency,a.maturitydate,a.totamount,a.M2MRate, ((a.M2MRate*numlimitPercent )/100) VaryRate
--           from (
           (SELECT trad_company_code Company,trad_import_export impexp, trad_trade_reference tradereference,trad_trade_rate as traderate,trad_import_export as importExport,
                        trad_trade_currency AS tradecurrency, trad_maturity_date AS maturitydate,
                        trad_trade_fcy  AS totamount,trad_trade_inr as TotInr,trad_entry_date as entrydate,trad_local_bank as counterparty,
                        pkgforexprocess.fncgetrate(trad_trade_currency,   30400003,  datWorkDate,   (case when(trad_import_export < 25900050) then     25300001 else  25300002 end)) as M2MRate
                  FROM trtran002
                  WHERE trad_record_status not in (10200005,10200006)
                  and trad_process_complete=12400002)
--                  ) a
--           Where abs(a.traderate - a.M2MRate) >((a.M2MRate * numlimitPercent)/100))            
loop

      begin
        select risk_risk_reference, risk_risk_type, risk_action_taken, risk_limit_percent,
               risk_limit_local,user_user_id, user_mobile_phone, user_email_id 
          into varriskReference, numriskType, numactionTaken, numlimitPercent,
               numlimitLocal,varstackHolder,varmobileNo,varemailID
          from trsystem012, trsystem022 
         where risk_risk_type = GConst.RISKHEDGESTOPLOSS
           and risk_currency_code=curfields.tradecurrency
           and user_user_id = risk_stake_holder;
        exception
          when no_data_found then
           select risk_risk_reference, risk_risk_type, risk_action_taken, risk_limit_percent,
               risk_limit_local,user_user_id, user_mobile_phone, user_email_id 
          into varriskReference, numriskType, numactionTaken, numlimitPercent,
               numlimitLocal,varstackHolder,varmobileNo,varemailID
          from trsystem012, trsystem022 
         where risk_risk_type = GConst.RISKHEDGESTOPLOSS
           and risk_currency_code=30400000
           and user_user_id = risk_stake_holder;
      end ;
      
      numVaryRate:=(curfields.M2MRate * numlimitPercent)/100;
        
    
    
       
          
      numTradeAmt :=curfields.totamount;
      
      
      begin
            select sum(brel_reversal_fcy) into numReversalAmt
            from trtran003
            where brel_trade_reference=curfields.tradereference
            and brel_record_status not in(10200005,10200006)
            group by brel_trade_reference ;
      exception
        when no_data_found then
           numReversalAmt :=0;
      end; 
         numTradeAmt := numTradeAmt-numReversalAmt;
      --Calculation of Hedged Amount 
      begin
           SELECT deal_base_currency AS basecurrency,deal_other_currency as othercurrency,
                  (sum(hedg_hedged_fcy) - sum(nvl(cdel_cancel_amount,    0))) AS amountfcy 
                  into numHBaseCurrency,numHOtherCurrency,numHedgeAmt
           FROM trtran001,trtran004,trtran006
           WHERE hedg_deal_number = cdel_deal_number(+)
           AND deal_deal_number = hedg_deal_number
           AND hedg_record_status NOT IN(10200005,    10200006)
           and hedg_trade_reference=curfields.tradereference
           AND nvl(cdel_record_status,    10200001) NOT IN(10200005,    10200006)  
           group by hedg_trade_reference,deal_base_currency,deal_other_currency;
      exception
        when no_data_found then
          numHedgeAmt:=0;
      end;
      
     --calculating un hedge amount 
      numTradeAmt := numTradeAmt-numHedgeAmt;
          
     --calculating loss Percentage by taking varyrate
      numLossPercent :=   numTradeAmt * abs(curfields.traderate-curfields.M2MRate);
     
        
      numLossRate  := numTradeAmt *  numlimitLocal;
      
      numtemp :=  numTradeAmt * curfields.traderate;
      numtemp1 := numTradeAmt * curfields.M2MRate;
          
    
--        numloss := (numloss /  pkgforexprocess.fncgetrate(curfields.tradecurrency,   30400003,  datWorkDate,   (case when(curfields.impexp < 25900050) then     25300001 else  25300002 end)));
--    
--        numLossRate := (numLossRate /  pkgforexprocess.fncgetrate(curfields.tradecurrency,   30400003,  datWorkDate,   (case when(curfields.impexp < 25900050) then     25300001 else  25300002 end)));
--        
--        numLossPercent :=(numLossPercent/ pkgforexprocess.fncgetrate(curfields.tradecurrency,   30400003,  datWorkDate,   (case when(curfields.impexp < 25900050) then     25300001 else  25300002 end)));
  
    begin
        select count(*) into numserialno
        from trtran011 
        where rdel_company_code=curfields.Company
        and rdel_risk_reference=varriskReference
        and rdel_deal_number=curfields.tradereference
        group by rdel_risk_reference;
    exception
       when no_data_found then
          numserialno:=0;
    end;
    
   
    
    
     if curfields.importExport < 25900050 then
       if ((abs(curfields.traderate-curfields.M2MRate) < numVaryRate) or (numLossPercent < abs(numtemp-numtemp1))) then
          goto  SkipInsert;
       end if;     
    else
       if ((abs(curfields.traderate-curfields.M2MRate) > numVaryRate) or (numLossPercent < abs(numtemp-numtemp1)))then
           goto SkipInsert;
       end if;
    end if;

    if (numLossPercent > abs(numtemp-numtemp1)) then
        numloss:=numLossPercent;
    else
        numloss:=abs(numtemp-numtemp1);
    end if;
    
    numloss := (numloss /  pkgforexprocess.fncgetrate(curfields.tradecurrency,   30400003,  datWorkDate,   (case when(curfields.impexp < 25900050) then     25300001 else  25300002 end)));
    
    if numserialno !=0 then
       goto SkipInsert; 
    end if;
   insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,rdel_serial_number,
                          rdel_risk_date, rdel_risk_type,rdel_amount_limit, rdel_amount_excess,
                          rdel_action_taken, rdel_stake_holder, rdel_mobile_number, rdel_email_id,rdel_message_text) 
                  values (curfields.Company,varriskReference,curfields.tradereference,numserialno, datWorkDate,numriskType,
                          numlimitPercent,numloss,numactionTaken, varstackHolder, varmobileNo, varemailID,
                          'Hedge Spot Loss Limit Violation No: ' || curfields.tradereference || ' Currency: ' || 
                          pkgReturnCursor.fncGetDescription(curfields.tradecurrency, GConst.PICKUPSHORT) || ' Limit : ' || to_char(numLossPercent) || '  Loss: ' || to_char(numloss));
      
  <<SkipInsert>> 
  
   insert into trsystem996 (crsk_ason_date,crsk_risk_type,crsk_deal_number,crsk_deal_date,crsk_buy_sell,
                             crsk_currency_code,crsk_counter_party,crsk_maturity_date,crsk_position_fcy,crsk_inr_amount,crsk_rate_usd,crsk_position_usd,crsk_position_inr,crsk_allowed_usd,crsk_limit_usd,crsk_violation_usd) 
                values (datWorkDate,gconst.RISKHEDGESTOPLOSS,curfields.tradereference,curfields.entrydate,curfields.importExport,curfields.tradecurrency,
                            curfields.counterparty,curfields.maturitydate,curfields.totamount,curfields.TotInr,curfields.M2MRate,numTradeAmt,numlimitLocal,numLossRate,abs(curfields.traderate-curfields.M2MRate),numloss);
    
   numloss :=0;
end loop;

  RETURN NULL;
  
END FNCHEDGECHANGE;
/