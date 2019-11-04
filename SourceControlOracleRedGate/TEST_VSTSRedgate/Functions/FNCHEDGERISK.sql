CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCHEDGERISK" ( datWorkDate in Date default '06-jun-08' ) RETURN NUMBER AS
  numHedgeAmt       number(15,2);
  numTradeAmt       number(15,2);
  numLossRate       number(15,2);
  numLossPercent    number(15,2);
  numrateTemp       number(15,2);
  numLoss           number(15,2);
  varriskReference  varchar2(25);
  numriskType       number(8);
  numactionTaken    number(8);
  numlimitPercent   number(4);         
  varstackHolder    varchar(50);
  varmobileNo       varchar(12);
  varemailID        varchar(50);
BEGIN  

select risk_risk_reference,risk_risk_type,risk_action_taken,risk_limit_percent,
       user_user_id,user_mobile_phone,user_email_id into 
       varriskReference,numriskType,numactionTaken,numlimitPercent,varstackHolder,varmobileNo,varemailID
from trsystem012,trsystem022 where risk_risk_type=21000010 and user_user_id=risk_stake_holder;


for curfields in 
      (SELECT trade.Company,hedge.dealnumber, hedge.basecurrency, hedge.othercurrency, hedge.amountfcy,
            trade.tradereference, trade.totamount, trade.tradecurrency,(trade.totamount -nvl(hedge.amountfcy,   0)) unhedgeamt,
            trade.traderate,trade.M2MRate,trade.maturitydate,
            ((trade.M2MRate*numlimitPercent )/100) VaryRate,(trade.traderate -((trade.traderate*numlimitPercent)/100)),trade.importExport
       FROM
-- calculation of hedge Deals
          (SELECT hedg_deal_number AS dealnumber, deal_base_currency AS basecurrency,
                  deal_other_currency as othercurrency,(hedg_hedged_fcy -nvl(cdel_cancel_amount,    0)) AS amountfcy,
                  hedg_trade_reference AS tradereference
           FROM trtran001,trtran004,trtran006
           WHERE hedg_deal_number = cdel_deal_number(+)
           AND deal_deal_number = hedg_deal_number
           AND hedg_record_status NOT IN(10200005,    10200006)
           AND nvl(cdel_record_status,    10200001) NOT IN(10200005,    10200006)) hedge,
--Calculation Of Trade Deals 
           (SELECT trad_company_code Company,trad_trade_reference tradereference,trad_trade_rate as traderate,trad_import_export as importExport,
                   trad_trade_currency AS tradecurrency, trad_maturity_date AS maturitydate,
                   (trad_trade_fcy -nvl(brel_reversal_fcy,    0)) AS totamount,
                   pkgforexprocess.fncgetrate(trad_trade_currency,   30400003,  datWorkDate,   (case when(trad_import_export < 25900050) then     25300001 else  25300002 end)) as M2MRate
            FROM trtran002,trtran003
            WHERE trad_trade_reference = brel_trade_reference(+)) trade
       WHERE hedge.tradereference(+) = trade.tradereference
       and abs(trade.traderate -trade.M2MRate) >((trade.M2MRate*numlimitPercent)/100)) 
loop


  if curfields.importExport < 25900050 then
     if ((curfields.traderate-curfields.M2MRate) > curfields.VaryRate) then
          numLossPercent :=   curfields.unhedgeamt * curfields.VaryRate;
          select decode(curfields.tradecurrency,30400004,1,30400002,1.5,30400006,1.25) into numratetemp from dual;
          numLossRate  := curfields.unhedgeamt *  numratetemp;
     else
        goto  SkipInsert;
     end if;     
  else
     if ((curfields.traderate-curfields.M2MRate) < curfields.VaryRate) then
          numLossPercent :=   curfields.unhedgeamt * curfields.VaryRate;
          select decode(curfields.tradecurrency,30400004,1,30400002,1.5,30400006,1.25) into numratetemp from dual;
          numLossRate := curfields.unhedgeamt *  numratetemp;
     else
        goto SkipInsert;
     end if;
  end if;
  
    if (numLossPercent < numLossRate) then
        numloss:=numLossPercent;
    else
        numloss:=numLossRate;
    end if;

   insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,rdel_serial_number,
                          rdel_risk_date, rdel_risk_type,rdel_amount_limit, rdel_amount_excess,
                          rdel_action_taken, rdel_stake_holder, rdel_mobile_number, rdel_email_id,rdel_message_text) 
                  values (curfields.Company,varriskReference,curfields.tradereference,1, datWorkDate,numriskType,
                          numlimitPercent,numloss,numactionTaken, varstackHolder, varmobileNo, varemailID,
                          'Spot Loss Limit Violation No: ' || curfields.tradereference || ' Currency: ' || 
                          pkgReturnCursor.fncGetDescription(curfields.tradecurrency, GConst.PICKUPSHORT) || ' Limit : 2%   Loss: ' || numloss);
      
  <<SkipInsert>>  
   numloss :=0;
end loop;

  RETURN NULL;
  
END FNCHEDGERISK;
/