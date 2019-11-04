CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."RATESCANCALC" (AsonDate in date,numCurrencyCode in number,numForCurrency in number,numSerial in number) RETURN VARCHAR2 
    is

    numError            number;
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;

Begin
    varMessage := 'Calculating Rates for : ' || AsonDate;
    numError := 1;
    varOperation := 'Extracting Input Parameters';

--for curfields in(select distinct rate_effective_date effectivedate, rate_serial_number serialnumber from trsystem009)    
--loop

    varOperation := 'Deleting the existing Rates';
    Delete from trtran012
    where drat_effective_date = AsonDate
    and drat_serial_number = numSerial;
    
    varOperation := 'Inserting Rates for USD / INR';
    insert into trtran012(drat_currency_code,drat_for_currency,drat_effective_date, 
      drat_serial_number,drat_rate_time,drat_time_stamp,drat_rate_description, 
      drat_spot_bid,drat_spot_ask, drat_month1_bid,  drat_month1_ask,
      drat_month2_bid,drat_month2_ask,drat_month3_bid,drat_month3_ask, 
      drat_month4_bid,drat_month4_ask,drat_month5_bid,drat_month5_ask,
      drat_month6_bid,drat_month6_ask,drat_month7_bid,drat_month7_ask,
      drat_month8_bid,drat_month8_ask, drat_month9_bid,drat_month9_ask,
      drat_month10_bid,drat_month10_ask, drat_month11_bid,drat_month11_ask,
      drat_month12_bid,drat_month12_ask,
      drat_create_date,drat_add_date,drat_entry_detail,drat_record_status)    
      select rate_currency_code BaseCurrency, rate_for_currency OtherCurrency, rate_effective_date,
      numSerial, rate_rate_time, rate_time_stamp, rate_rate_description,
      round(rate_spot_bid,4) BidSpot, round(rate_spot_ask,4) AskSpot,
      round(rate_spot_bid + rate_month1_bid,4), round(rate_spot_ask + rate_month1_ask,4),
      round(rate_spot_bid + rate_month2_bid,4), round(rate_spot_ask + rate_month2_ask,4),
      round(rate_spot_bid + rate_month3_bid,4), round(rate_spot_ask + rate_month3_ask,4),
      round(rate_spot_bid + rate_month4_bid,4), round(rate_spot_ask + rate_month4_ask,4),
      round(rate_spot_bid + rate_month5_bid,4), round(rate_spot_ask + rate_month5_ask,4),
      round(rate_spot_bid + rate_month6_bid,4), round(rate_spot_ask + rate_month6_ask,4),
      round(rate_spot_bid + rate_month7_bid,4), round(rate_spot_ask + rate_month7_ask,4),
      round(rate_spot_bid + rate_month8_bid,4), round(rate_spot_ask + rate_month8_ask,4),
      round(rate_spot_bid + rate_month9_bid,4), round(rate_spot_ask + rate_month9_ask,4),
      round(rate_spot_bid + rate_month10_bid,4), round(rate_spot_ask + rate_month10_ask,4),
      round(rate_spot_bid + rate_month11_bid,4), round(rate_spot_ask + rate_month11_ask,4),
      round(rate_spot_bid + rate_month12_bid,4), round(rate_spot_ask + rate_month12_ask,4),
      sysdate, sysdate, rate_entry_detail, rate_record_status
      from trsystem009
      where rate_effective_date = AsonDate --curfields.effectivedate
      and rate_serial_number =  numSerial  --
      and rate_currency_code = GConst.USDOLLAR
      and rate_for_currency = GConst.INDIANRUPEE;
      
    varOperation := 'Inserting Rate for Usd against USD';
    insert into trtran012(drat_currency_code,drat_for_currency,drat_effective_date, 
      drat_serial_number,drat_rate_time,drat_time_stamp,drat_rate_description, 
      drat_spot_bid,drat_spot_ask, drat_month1_bid,  drat_month1_ask,
      drat_month2_bid,drat_month2_ask,drat_month3_bid,drat_month3_ask, 
      drat_month4_bid,drat_month4_ask,drat_month5_bid,drat_month5_ask,
      drat_month6_bid,drat_month6_ask,drat_month7_bid,drat_month7_ask,
      drat_month8_bid,drat_month8_ask, drat_month9_bid,drat_month9_ask,
      drat_month10_bid,drat_month10_ask, drat_month11_bid,drat_month11_ask,
      drat_month12_bid,drat_month12_ask,
      drat_create_date,drat_add_date,drat_entry_detail,drat_record_status)    
    select GConst.USDOLLAR,  GConst.USDOLLAR,  AsonDate, numSerial,   
      rate_rate_time, rate_time_stamp, rate_rate_description, 
      1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
      sysdate, sysdate, rate_entry_detail, rate_record_status
      from trsystem009
      where rate_effective_date = AsonDate
      and rate_serial_number = numSerial
      and rate_currency_code = GConst.USDOLLAR
      and rate_for_currency = GConst.INDIANRUPEE;

    varOperation := 'Calculating Rates against Local Currency - Stage 1';
    insert into trtran012(drat_currency_code,drat_for_currency,drat_effective_date, 
      drat_serial_number,drat_rate_time,drat_time_stamp,drat_rate_description, 
      drat_spot_bid,drat_spot_ask, drat_month1_bid,  drat_month1_ask,
      drat_month2_bid,drat_month2_ask,drat_month3_bid,drat_month3_ask, 
      drat_month4_bid,drat_month4_ask,drat_month5_bid,drat_month5_ask,
      drat_month6_bid,drat_month6_ask,drat_month7_bid,drat_month7_ask,
      drat_month8_bid,drat_month8_ask, drat_month9_bid,drat_month9_ask,
      drat_month10_bid,drat_month10_ask, drat_month11_bid,drat_month11_ask,
      drat_month12_bid,drat_month12_ask,
      drat_create_date,drat_add_date,drat_entry_detail,drat_record_status)    
    select a.rate_currency_code, 30400003,a.rate_effective_date,
      a.rate_serial_number,a.rate_rate_time,a.rate_time_stamp,a.rate_rate_description, 
      round(a.rate_usd_rate * b.drat_spot_bid,4),
      round(a.rate_usd_rate * b.drat_spot_ask,4),
      round(a.rate_usd_rate * b.drat_month1_bid,4),
      round(a.rate_usd_rate * b.drat_month1_ask,4),
      round(a.rate_usd_rate * b.drat_month2_bid,4),
      round(a.rate_usd_rate * b.drat_month2_ask,4),
      round(a.rate_usd_rate * b.drat_month3_bid,4),
      round(a.rate_usd_rate * b.drat_month3_ask,4),
      round(a.rate_usd_rate * b.drat_month4_bid,4),
      round(a.rate_usd_rate * b.drat_month4_ask,4),
      round(a.rate_usd_rate * b.drat_month5_bid,4),
      round(a.rate_usd_rate * b.drat_month5_ask,4),
      round(a.rate_usd_rate * b.drat_month6_bid,4),
      round(a.rate_usd_rate * b.drat_month6_ask,4),
      round(a.rate_usd_rate * b.drat_month7_bid,4),
      round(a.rate_usd_rate * b.drat_month7_ask,4),
      round(a.rate_usd_rate * b.drat_month8_bid,4),
      round(a.rate_usd_rate * b.drat_month8_ask,4),
      round(a.rate_usd_rate * b.drat_month9_bid,4),
      round(a.rate_usd_rate * b.drat_month9_ask,4),
      round(a.rate_usd_rate * b.drat_month10_bid,4),
      round(a.rate_usd_rate * b.drat_month10_ask,4),
      round(a.rate_usd_rate * b.drat_month11_bid,4),
      round(a.rate_usd_rate * b.drat_month11_ask,4),
      round(a.rate_usd_rate * b.drat_month12_bid,4),
      round(a.rate_usd_rate * b.drat_month12_ask,4),
      sysdate,sysdate, a.rate_entry_detail, a.rate_record_status
      from trsystem009 a, trtran012 b
      where a.rate_effective_date = b.drat_effective_date
      and a.rate_effective_date = AsonDate
      and a.rate_serial_number = numSerial
      and a.rate_currency_code in 
      (select cncy_pick_code
        from trmaster304
        where cncy_principal_yn = GConst.OPTIONYES
        and cncy_pick_code != GConst.USDOLLAR)
      and b.drat_currency_code = GConst.USDOLLAR
      and b.drat_for_currency = GConst.INDIANRUPEE
      and b.drat_serial_number =  numSerial;


    varOperation := 'Calculating Rates against USD - Stage 2';
    insert into trtran012(drat_currency_code,drat_for_currency,drat_effective_date, 
      drat_serial_number,drat_rate_time,drat_time_stamp,drat_rate_description, 
      drat_spot_bid,drat_spot_ask, drat_month1_bid,  drat_month1_ask,
      drat_month2_bid,drat_month2_ask,drat_month3_bid,drat_month3_ask, 
      drat_month4_bid,drat_month4_ask,drat_month5_bid,drat_month5_ask,
      drat_month6_bid,drat_month6_ask,drat_month7_bid,drat_month7_ask,
      drat_month8_bid,drat_month8_ask, drat_month9_bid,drat_month9_ask,
      drat_month10_bid,drat_month10_ask, drat_month11_bid,drat_month11_ask,
      drat_month12_bid,drat_month12_ask,
      drat_create_date,drat_add_date,drat_entry_detail,drat_record_status)    
    select a.drat_currency_code, 30400004,a.drat_effective_date,
      a.drat_serial_number,a.drat_rate_time,a.drat_time_stamp,a.drat_rate_description, 
      round(a.drat_spot_bid / b.drat_spot_bid,4),
      round(a.drat_spot_ask / b.drat_spot_ask,4),
      round(a.drat_month1_bid / b.drat_spot_bid,4),
      round(a.drat_month1_ask / b.drat_spot_ask,4),
      round(a.drat_month2_bid / b.drat_spot_bid,4),
      round(a.drat_month2_ask / b.drat_spot_ask,4),
      round(a.drat_month3_bid / b.drat_spot_bid,4),
      round(a.drat_month3_ask / b.drat_spot_ask,4),
      round(a.drat_month4_bid / b.drat_spot_bid,4),
      round(a.drat_month4_ask / b.drat_spot_ask,4),
      round(a.drat_month5_bid / b.drat_spot_bid,4),
      round(a.drat_month5_ask / b.drat_spot_ask,4),
      round(a.drat_month6_bid / b.drat_spot_bid,4),
      round(a.drat_month6_ask / b.drat_spot_ask,4),
      round(a.drat_month7_bid / b.drat_spot_bid,4),
      round(a.drat_month7_ask / b.drat_spot_ask,4),
      round(a.drat_month8_bid / b.drat_spot_bid,4),
      round(a.drat_month8_ask / b.drat_spot_ask,4),
      round(a.drat_month9_bid / b.drat_spot_bid,4),
      round(a.drat_month9_ask / b.drat_spot_ask,4),
      round(a.drat_month10_bid / b.drat_spot_bid,4),
      round(a.drat_month10_ask / b.drat_spot_ask,4),
      round(a.drat_month11_bid / b.drat_spot_bid,4),
      round(a.drat_month11_ask / b.drat_spot_ask,4),
      round(a.drat_month12_bid / b.drat_spot_bid,4),
      round(a.drat_month12_ask / b.drat_spot_ask,4),
      sysdate,sysdate, a.drat_entry_detail, a.drat_record_status
      from trtran012 a, trtran012 b
      where a.drat_effective_date = b.drat_effective_date
      and a.drat_effective_date =AsonDate
      and a.drat_serial_number =  numSerial
      and a.drat_currency_code in 
      (select cncy_pick_code
        from trmaster304
        where cncy_principal_yn = GConst.OPTIONYES
        and cncy_pick_code != GConst.USDOLLAR)
      and b.drat_currency_code = GConst.USDOLLAR
      and b.drat_for_currency = GConst.INDIANRUPEE
      and b.drat_serial_number =  numSerial;


    varOperation := 'Calculating Rates against Local Currency - Stage 3';
    insert into trtran012(drat_currency_code,drat_for_currency,drat_effective_date, 
      drat_serial_number,drat_rate_time,drat_time_stamp,drat_rate_description, 
      drat_spot_bid,drat_spot_ask, drat_month1_bid,  drat_month1_ask,
      drat_month2_bid,drat_month2_ask,drat_month3_bid,drat_month3_ask, 
      drat_month4_bid,drat_month4_ask,drat_month5_bid,drat_month5_ask,
      drat_month6_bid,drat_month6_ask,drat_month7_bid,drat_month7_ask,
      drat_month8_bid,drat_month8_ask, drat_month9_bid,drat_month9_ask,
      drat_month10_bid,drat_month10_ask, drat_month11_bid,drat_month11_ask,
      drat_month12_bid,drat_month12_ask,
      drat_create_date,drat_add_date,drat_entry_detail,drat_record_status)    
    select a.rate_for_currency, 30400003,a.rate_effective_date,
      a.rate_serial_number,a.rate_rate_time,a.rate_time_stamp,a.rate_rate_description, 
      round( b.drat_spot_bid / a.rate_usd_rate,4),
      round(b.drat_spot_ask / a.rate_usd_rate,4),
      round(b.drat_month1_bid / a.rate_usd_rate,4),
      round(b.drat_month1_ask / a.rate_usd_rate,4),
      round(b.drat_month2_bid / a.rate_usd_rate,4),
      round(b.drat_month2_ask / a.rate_usd_rate,4),
      round(b.drat_month3_bid / a.rate_usd_rate,4),
      round(b.drat_month3_ask / a.rate_usd_rate,4),
      round(b.drat_month4_bid / a.rate_usd_rate,4),
      round(b.drat_month4_ask / a.rate_usd_rate,4),
      round(b.drat_month5_bid / a.rate_usd_rate,4),
      round(b.drat_month5_ask / a.rate_usd_rate,4),
      round(b.drat_month6_bid / a.rate_usd_rate,4),
      round(b.drat_month6_ask / a.rate_usd_rate,4),
      round(b.drat_month7_bid / a.rate_usd_rate,4),
      round(b.drat_month7_ask / a.rate_usd_rate,4),
      round(b.drat_month8_bid / a.rate_usd_rate,4),
      round(b.drat_month8_ask / a.rate_usd_rate,4),
      round(b.drat_month9_bid / a.rate_usd_rate,4),
      round(b.drat_month9_ask / a.rate_usd_rate,4),
      round(b.drat_month10_bid / a.rate_usd_rate,4),
      round(b.drat_month10_ask / a.rate_usd_rate,4),
      round(b.drat_month11_bid / a.rate_usd_rate,4),
      round(b.drat_month11_ask / a.rate_usd_rate,4),
      round(b.drat_month12_bid / a.rate_usd_rate,4),
      round(b.drat_month12_ask / a.rate_usd_rate,4),
      sysdate,sysdate, a.rate_entry_detail, a.rate_record_status
      from trsystem009 a, trtran012 b
      where a.rate_effective_date = b.drat_effective_date
      and a.rate_effective_date = AsonDate
      and a.rate_serial_number = numSerial
      and a.rate_for_currency in 
      (select cncy_pick_code
        from trmaster304
        where cncy_principal_yn = GConst.OPTIONNO
        and cncy_pick_code != GConst.INDIANRUPEE)
      and b.drat_currency_code = GConst.USDOLLAR
      and b.drat_for_currency = GConst.INDIANRUPEE
      and b.drat_serial_number = numSerial;

    varOperation := 'Calculating Rates against USD - Stage 4';
    insert into trtran012(drat_currency_code,drat_for_currency,drat_effective_date, 
      drat_serial_number,drat_rate_time,drat_time_stamp,drat_rate_description, 
      drat_spot_bid,drat_spot_ask, drat_month1_bid,  drat_month1_ask,
      drat_month2_bid,drat_month2_ask,drat_month3_bid,drat_month3_ask, 
      drat_month4_bid,drat_month4_ask,drat_month5_bid,drat_month5_ask,
      drat_month6_bid,drat_month6_ask,drat_month7_bid,drat_month7_ask,
      drat_month8_bid,drat_month8_ask, drat_month9_bid,drat_month9_ask,
      drat_month10_bid,drat_month10_ask, drat_month11_bid,drat_month11_ask,
      drat_month12_bid,drat_month12_ask,
      drat_create_date,drat_add_date,drat_entry_detail,drat_record_status)    
    select 30400004, a.drat_currency_code,a.drat_effective_date,
      a.drat_serial_number,a.drat_rate_time,a.drat_time_stamp,a.drat_rate_description, 
      round(b.drat_spot_bid / a.drat_spot_bid,4),
      round(b.drat_spot_ask / a.drat_spot_ask,4),
      round(b.drat_spot_bid /a.drat_month1_bid,4),
      round(b.drat_spot_ask / a.drat_month1_ask ,4),
      round(b.drat_spot_bid / a.drat_month2_bid,4),
      round(b.drat_spot_ask / a.drat_month2_ask,4),
      round(b.drat_spot_bid / a.drat_month3_bid,4),
      round(b.drat_spot_ask / a.drat_month3_ask,4),
      round(b.drat_spot_bid / a.drat_month4_bid,4),
      round(b.drat_spot_ask / a.drat_month4_ask,4),
      round(b.drat_spot_bid / a.drat_month5_bid,4),
      round(b.drat_spot_ask / a.drat_month5_ask,4),
      round(b.drat_spot_bid / a.drat_month6_bid,4),
      round(b.drat_spot_ask / a.drat_month6_ask,4),
      round(b.drat_spot_bid / a.drat_month7_bid,4),
      round(b.drat_spot_ask / a.drat_month7_ask,4),
      round(b.drat_spot_bid / a.drat_month8_bid,4),
      round(b.drat_spot_ask / a.drat_month8_ask,4),
      round(b.drat_spot_bid / a.drat_month9_bid,4),
      round(b.drat_spot_ask / a.drat_month9_ask,4),
      round(b.drat_spot_bid / a.drat_month10_bid,4),
      round(b.drat_spot_ask / a.drat_month10_ask,4),
      round(b.drat_spot_bid / a.drat_month11_bid,4),
      round(b.drat_spot_ask / a.drat_month11_ask,4),
      round(b.drat_spot_bid / a.drat_month12_bid,4),
      round(b.drat_spot_ask / a.drat_month12_ask,4),
      sysdate,sysdate, a.drat_entry_detail, a.drat_record_status
      from trtran012 a, trtran012 b
      where a.drat_effective_date = b.drat_effective_date
      and a.drat_effective_date = AsonDate
      and a.drat_serial_number = numSerial
      and a.drat_currency_code in 
      (select cncy_pick_code
        from trmaster304
        where cncy_principal_yn = GConst.OPTIONNO
        and cncy_pick_code != GConst.INDIANRUPEE)
      and b.drat_currency_code = GConst.USDOLLAR
      and b.drat_for_currency = GConst.INDIANRUPEE
      and b.drat_serial_number = numSerial;
--end loop;
    return numError;
Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('CalcRate', numError, varMessage, 
                      varOperation, varError);
      raise_application_error(-20101, varError);                      
      return numError;
    
END RATESCANCALC;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
/