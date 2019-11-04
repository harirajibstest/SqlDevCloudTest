CREATE OR REPLACE PROCEDURE "TEST_VSTSRedgate".prcOptionMaturity
(SettlementStart  Date ,MaturityDate  Date,Settlement Date,Tenor  number,AmountFcy  number,
  DealCount in number,DeliveryType in number,BuySell in Number,OptionType in Number)
as
    datTemp         Date;
    numAmount          number(15,2);
    datTemp1        Date;
    datTemp2        Date;
    numCount        number := 1;
    numTenor        number(5);
    
begin
-- Comment By Majunath 
 --if DealCount <= 1 then
  delete from trsystem966;
  commit;
 --end if;
 numTenor := Tenor;
 datTemp := SettlementStart;
 if numTenor > 0 then
   numAmount := AmountFcy;
 -- numAmount := AmountFcy/numTenor;
 else 
    numAmount := AmountFcy;
    numTenor := 1;
 end if;
-- delete from trsystem966;
--while datTemp <= Settlement
 FOR i IN 1..numTenor LOOP
  --if Settlement <= datTemp then
    if DeliveryType = 32900008 then
      datTemp := Settlement;
      datTemp1 := Settlement;
      datTemp2  := MaturityDate;
      numCount := 1;
    else
      datTemp1:= fncGetSpotDate_Option(30699999,datTemp,1);---Settlement Date
      datTemp2:= fncGetSpotDate_Option(30699999,datTemp,0);---Expiration Date
      IF datTemp1 > Settlement THEN
        datTemp1 := Settlement;
        datTemp2 := MaturityDate;
      END IF;
    end if;
    INSERT INTO trsystem966
      ( opmt_SERIAL_NUMBER, opmt_SUBSERIAL_NUMBER,
        opmt_MATURITY_DATE, opmt_SETTLEMENT_DATE, opmt_AMOUNT_FCY,OPMT_BUY_SELL,OPMT_OPTION_TYPE)
      VALUES
      (DealCount,numCount,datTemp2,datTemp1,numAmount,BuySell,OptionType);
 
  --end if;
    numCount := numCount + 1;
    if DeliveryType = 32900004 then
      datTemp := Add_months(datTemp,1);
    elsif DeliveryType = 32900005 then
      datTemp := Add_months(datTemp,3);
    elsif DeliveryType = 32900006 then
      datTemp := Add_months(datTemp,6);
    elsif DeliveryType = 32900007 then
      datTemp := Add_months(datTemp,12);
    elsif DeliveryType = 32900002 then
      datTemp := datTemp + 7;
    elsif DeliveryType = 32900003 then
      datTemp := datTemp + 14; 
    elsif DeliveryType = 32900001 then
      datTemp := datTemp + 1;      
    end if;
  end loop;
  --COMMIT;
end prcOptionMaturity;
/