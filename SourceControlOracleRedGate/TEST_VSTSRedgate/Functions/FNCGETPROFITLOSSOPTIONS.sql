CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCGETPROFITLOSSOPTIONS" 
  (varReference in varchar,
   refRate in number,
   datEffectDate in date)
   return number
 is
   numDealType number(15);
   numLeg1 number(15);
   numLeg2 number(15);
   numBaseAmount number(15);
   numSerial  number(15);
   numPLFCY   number(15);
   numPLLocal   number(15);
   varRemarks   varchar(50 byte);
   numOptionType number(15);
   numBuySell number(15);
   numStrikeRate number(15,6);
   
 begin
  
    select copt_deal_type,copt_base_amount
      into numdealtype,numBaseAmount
      from trtran071
     where copt_deal_number= varReference
       and copt_record_status not in (Gconst.StatusinActive,Gconst.STATUSDELETED);
    
    if numDealType = Gconst.PlainVenela then
       for C1 in ( select cosu_serial_number,cosu_option_type OptionType,cosu_buy_sell buysell,
                          cosu_strike_rate StrikeRate
                     from trtran072
                     where cosu_deal_number=varReference
                     and cosu_record_status not in(10200005,10200006))
        loop
           if C1.buysell= Gconst.PURCHASEDEAL then
                if c1.OptionType =Gconst.OptionCall then
                     if refrate > C1.strikeRate then
                        numPLFCY:= (refrate-C1.StrikeRate)*numBaseAmount;
                        varRemarks:='Option Exercise';
                        return numPLFCY;
                     elsif refrate < C1.strikeRate then
                        numPLFCY:= (refRate-C1.StrikeRate)*numBaseAmount;
                        varRemarks:='No Exercise';
                     end if;
                elsif C1.OptionType =Gconst.OptionPut then            
                     if refrate < C1.strikeRate then
                        numPLFCY:= (refrate-C1.StrikeRate)*numBaseAmount;
                        varRemarks:='Option Exercise';
                        return numPLFCY;
                     elsif refrate > C1.StrikeRate then
                        numPLFCY:= (refrate-C1.StrikeRate)*numBaseAmount;
                        varRemarks:='No Exercise';
                     end if;
                end if;
             elsif C1.buysell= Gconst.SALEDEAL then
                if C1.OptionType =Gconst.OptionCall then
                     if refrate > C1.strikeRate then
                        numPLFCY:= (refrate-C1.StrikeRate)*numBaseAmount;
                        varRemarks:='Option Exercise';
                        return numPLFCY;
                     elsif refrate < C1.strikeRate then
                        numPLFCY:= (refrate-C1.StrikeRate)*numBaseAmount;
                        varRemarks:='No Exercise';
                     end if;
                elsif C1.OptionType =Gconst.OptionPut then            
                     if C1.strikeRate > refrate then
                        numPLFCY:= (refrate-C1.StrikeRate)*numBaseAmount;
                        varRemarks:='Option Exercise';
                        return numPLFCY;
                     elsif refrate < C1.strikeRate then
                        numPLFCY:= (refrate-C1.StrikeRate)*numBaseAmount;
                        varRemarks:='No Exercise';
                     end if;
                end if;
             end if;
          
        end loop;
    elsif numDealType = Gconst.Stragles then
    --Checking first Leg
       begin 
        select cosu_serial_number,cosu_option_type,cosu_buy_sell,
                cosu_strike_rate
          into numserial,numoptionType,numbuysell,numStrikeRate
          from trtran072
         where cosu_deal_number=varReference
           and cosu_option_type =Gconst.OptionCall;
          -- and cosu_strike_rate>refRate;
          if numbuysell= Gconst.PURCHASEDEAL then  
             if numstrikeRate< refrate then
                numPLFCY:= (refrate-numStrikeRate)*numBaseAmount;
                varRemarks:='Option Exercise';
                goto Result_return;
             else
                  varRemarks:='NO Exercise';
             end if;
          elsif numbuysell= Gconst.SALEDEAL then
             if numstrikeRate< refrate then
                numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
                varRemarks:='Option Exercise';
                goto Result_return;
             else
                  varRemarks:='No Exercise';
             end if;
          end if;
   
       exception
       when others then
            numserial:=0;--,numoptionType,numbuysell,numStrikeRate
       end;
     -- --Checking first Second Leg        
       begin 
        select cosu_serial_number,cosu_option_type,cosu_buy_sell,
               cosu_strike_rate
          into numserial,numoptionType,numbuysell,numStrikeRate
          from trtran072
         where cosu_deal_number=varReference
           and cosu_option_type =Gconst.OptionPut;
          -- and cosu_strike_rate<refRate;
           
          if numbuysell= Gconst.PURCHASEDEAL then  
             if numstrikeRate> refrate then
                numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
                varRemarks:='Option Exercise';
                goto Result_return;
             else
                  varRemarks:='No Exercise';
             end if;
          elsif numbuysell= Gconst.SALEDEAL then
             if numstrikeRate< refrate then
                numPLFCY:= (refrate-numStrikeRate)*numBaseAmount;
                varRemarks:='Option Exercise';
                goto Result_return;
             else
                  varRemarks:='NO Exercise';
             end if;
          end if;
       exception
       when others then
            numserial:=0;--,numoptionType,numbuysell,numStrikeRate
       end;  
       
    end if;
  <<Result_return>>  
      if varRemarks='No Exercise' then
        numPLFCY:=0;
      end if;
      numPLLocal:= numPLFCY * refRate;
   return numPLFCY;
 end fncGetprofitLossOptions;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
/