CREATE OR REPLACE function "TEST_VSTSRedgate".fncOptionForwardPnL
(varReference in varchar,
datSpotRate in number)
return number
as
 numStrike          number(15,6);
 numNotional        number(15,2);
 numBC              number(15,6);
 numBP              number(15,6);
 numSC              number(15,6);
 numSP              number(15,6);
 numDay1ForwardRate number(15,6);
 NUMERROR            NUMBER(10);
 numPremium         number(15,6);
 numPremiumAmt      number(15,2);
 numPnL             number(15,2);
  VAROPERATION        GCONST.GVAROPERATION%TYPE;
  VARMESSAGE          GCONST.GVARMESSAGE%TYPE;
  VARERROR            GCONST.GVARERROR%TYPE;
begin
      select (COPT_BASE_AMOUNT) BaseAmount,
                    round((select avg(cosu_strike_rate) from trtran072 
                     where cosu_deal_number=copt_deal_number
                       and cosu_buy_sell= 25300001 --'||Gconst.PURCHASEDEAL||'
                       and cosu_option_type=32400001),4) "BC",
                   round((select avg(cosu_strike_rate) from trtran072 
                     where cosu_deal_number=copt_deal_number
                       and cosu_buy_sell=25300001 --'||Gconst.PURCHASEDEAL||'
                       and cosu_option_type=32400002),4) "BP",
                   round((select avg(cosu_strike_rate) from trtran072 
                     where cosu_deal_number=copt_deal_number
                       and cosu_buy_sell= 25300002 --'||Gconst.SALEDEAL||'
                       and cosu_option_type=32400002),4) "SP",
                   round((select avg(cosu_strike_rate) from trtran072 
                     where cosu_deal_number=copt_deal_number
                       and cosu_buy_sell=25300002 --'||Gconst.SALEDEAL||'
                       and cosu_option_type=32400001),4) "SC",
              COPT_PREMIUM_RATE,COPT_PREMIUM_AMOUNT
          into numNotional,numBC,numBP,
                numSC,numSP,numPremium,NumPremiumAmt
    from trtran071
    where copt_record_Status not in (10200005,10200006)
     and copt_Deal_number=varReference;
    
    VAROPERATION := 'Day 1 Forward Rate =Buy Call Rate';
    numDay1ForwardRate:= numBC;
    VAROPERATION:=' Current Spot Between Buy Call and Sell Call ';
    
--    1. Current Spot Between Buy Call and Sell Call
--          - Premium* Amount
--    2. Current Spot above Sell Call (67)
--          [Day1 Forward Rate- (Current Rate - (Sell Call-Buy Call)+Premium)]*Amount
--    3. Current Spot between Sell Put and Buy Call (64)
--          [Day1 Forward Rate- (Current Rate + Premium)]*Amount
--    4. Current Spot below Sell Put
--          [Day1 Forward Rate- (Sell Put+Premium)]*Amount


    select  (case when datSpotRate between numBC and numSC then 
                      numPremium*numNotional
                 when datSpotRate > numSC then
                      (numDay1ForwardRate-(datSpotRate-(numSC-NumBC)+numPremium))*numNotional
                 when datSpotRate between numSC and numBC then
                      (numDay1ForwardRate-(datSpotRate+numPremium))*numNotional
                 when datSpotRate < numSp then
                      (numDay1ForwardRate-(numSP+numPremium))*numNotional
                 end)
            into numPnL 
       from dual;
   return nvl(numPnL,0);
  exception
 
  when others then
      NUMERROR := SQLCODE;
      VARERROR := SQLERRM;
      VARERROR := GCONST.FNCRETURNERROR('fncOptionForwardPnL', NUMERROR, VARMESSAGE, 
                      VAROPERATION, VARERROR);


      
      RAISE_APPLICATION_ERROR(-20101, VARERROR);  
    
end fncOptionForwardPnL;
/