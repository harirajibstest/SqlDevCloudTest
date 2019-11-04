CREATE OR REPLACE PACKAGE BODY "TEST_VSTSRedgate"."PKGFOREXPROCESS" as
--  Created on 23/04/2008

Function fncInsertDeals
    ( AsonDate in Date)
    return number
    is
--  Created on 10/04/08
    numError            number;
    numType             number(8) := 0;
    numCurrency         number(8) := 0;
    numPCount           number(4) := 0;
    numPFCY             number(15,6) := 0;
    numPINR             number(15,2) := 0;
    numSCount           number(4) := 0;
    numSFCY             number(15,6) := 0;
    numSINR             number(15,2) := 0;
    numCode             number(8) := 0;
    numPosFcy           number(20,6) := 0;
    numPosInr           number(20,2) := 0;
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
Begin
    varMessage := 'Inserting Deals Details for the day end: ' || AsonDate;
    numError := 0;

    varOperation := 'Deleting Deals for the Day';
--    delete from trsystem032
--      where dpos_company_code = 30199999
--      and dpos_position_date = AsonDate;

    varOperation := 'Inserting INR Deals';
    numPCount := 0;
    numPfcy := 0;
    numPinr := 0;
    numSCount := 0;
    numSfcy := 0;
    numSinr := 0;

    for curDeals in
    (With DayDeals as
    (select deal_base_currency Currency, deal_hedge_trade DType,
      NVL(sum(decode(deal_buy_sell, 25300001, 1,0)),0) Pno,
      NVL(sum(decode(deal_buy_sell, 25300001, deal_base_amount,0)),0) Pfcy,
      NVL(sum(decode(deal_buy_sell, 25300001, deal_other_amount,0)),0) Pinr,
      NVL(sum(decode(deal_buy_sell, 25300002, 1,0)),0) Sno,
      NVL(sum(decode(deal_buy_sell, 25300002, deal_base_amount,0)),0) Sfcy,
      NVL(sum(decode(deal_buy_sell, 25300002, deal_other_amount,0)),0) Sinr
      from trtran001 a
      where deal_execute_date = AsonDate
      and deal_record_status in (10200001, 10200003, 10200004)
      group by deal_base_currency, deal_hedge_trade
    union
--  Cross currency deals
    select deal_other_currency Currency, deal_hedge_trade DType,
      NVL(sum(decode(deal_buy_sell, 25300002, 1,0)),0) Pno,
      NVL(sum(decode(deal_buy_sell, 25300002, deal_other_amount,0)),0) Pfcy,
      NVL(sum(decode(deal_buy_sell, 25300002, deal_amount_local,0)),0) Pinr,
      NVL(sum(decode(deal_buy_sell, 25300001, 1,0)),0) Sno,
      NVL(sum(decode(deal_buy_sell, 25300001, deal_other_amount,0)),0) sfcy,
      NVL(sum(decode(deal_buy_sell, 25300001, deal_amount_local,0)),0) sinr
      from trtran001
      where deal_execute_date = AsonDate
      and deal_record_status in (10200001, 10200003, 10200004)
      and deal_other_currency != 30400003
      group by deal_other_currency, deal_hedge_trade)
      select currency, dtype, sum(pno) Pno, sum(pfcy) Pfcy, sum(pinr) Pinr ,
        sum(sno) Sno, sum(sfcy) Sfcy, sum(sinr) Sinr
        from DayDeals
        group by currency, dtype)
    Loop

      numType := curDeals.DType;
      numCurrency := curDeals.Currency;
      numPCount := curDeals.Pno;
      numPfcy := curDeals.Pfcy;
      numPinr := curDeals.Pinr;
      numSCount := curDeals.Sno;
      numSfcy := curDeals.Sfcy;
      numSinr := curDeals.Sinr;

      Begin
      select dpos_position_code, dpos_day_position, dpos_position_inr
        into numCode, numPosFcy, numPosInr
        from trsystem032
        where dpos_company_code = 30199999
        and dpos_currency_code = numCurrency
        and dpos_position_type = numType
        -- added by reddy on24-07-08
        and dpos_user_id ='0'
        and dpos_position_date =
        (select max(dpos_position_date)
          from trsystem032
          where dpos_company_code = 30199999
          and dpos_currency_code = numCurrency
          and dpos_position_type = numType
        -- added by reddy on24-07-08
          and dpos_user_id ='0'
          and dpos_position_date < AsonDate);
      Exception
        when no_data_found then
          numCode := 12400001;
          numPosFcy := 0;
          numPosInr := 0;
      End;

      if  numCode = 12400002 then
        numPosFcy := numPosFcy * -1;
      end if;

      numPosFcy := (numPosFcy + numPfcy) - numSFcy;

      if numPosFcy >= 0 then
        numCode := 12400001;
      else
        numPosFcy := numPosFcy *-1;
        numCode := 12400002;
      end if;

      numPosInr := (numPosInr + numPinr) - numSinr;

      varOperation := 'Updating Records';
      update trsystem032
        set dpos_purchase_number = numPCount,
        dpos_purchase_amount = numPfcy,
        dpos_purchase_inr = numPinr,
        dpos_sale_number = numScount,
        dpos_sale_amount = numSfcy,
        dpos_sale_inr = numSinr,
        dpos_position_code = numCode,
        dpos_day_position = numPosFcy,
        dpos_position_inr = numPosinr
        where dpos_company_code = 30199999
        and dpos_position_date = AsonDate
        and dpos_currency_code = numCurrency
        and dpos_position_type = numType;


--      insert into trsystem032(dpos_company_code, dpos_position_date,
--      dpos_currency_code, dpos_position_type, dpos_purchase_number,
--      dpos_purchase_amount, dpos_purchase_inr, dpos_sale_number,
--      dpos_sale_amount, dpos_sale_inr, dpos_position_code,
--      dpos_day_position, dpos_position_inr)
--      values(30199999, AsonDate, numCurrency, numType,
--      numPCount, numPfcy, numPinr,
--      numSCount, numSfcy, numSinr,
--      numCode, numPosFcy, numPosInr);
    End Loop;


    return numError;
Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('InsDeal', numError, varMessage,
                      varOperation, varError);
      raise_application_error(-20101, varError);
      return numError;
End fncInsertDeals;

Function fncInsertDeals
    ( AsonDate in Date,userid in varchar)
    return number
    is
--  Created on 10/04/08
    numError            number;
    numType             number(8) := 0;
    numCurrency         number(8) := 0;
    numPCount           number(4) := 0;
    numPFCY             number(15,6) := 0;
    numPINR             number(15,2) := 0;
    numSCount           number(4) := 0;
    numSFCY             number(15,6) := 0;
    numSINR             number(15,2) := 0;
    numCode             number(8) := 0;
    numPosFcy           number(20,6) := 0;
    numPosInr           number(20,2) := 0;
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
Begin
    varMessage := 'Inserting Deals Details for the day end: ' || AsonDate;
    numError := 0;


    varOperation := 'Inserting INR Deals';
    numPCount := 0;
    numPfcy := 0;
    numPinr := 0;
    numSCount := 0;
    numSfcy := 0;
    numSinr := 0;

    for curDeals in
    (With DayDeals as
    (select deal_base_currency Currency, deal_hedge_trade DType,
      NVL(sum(decode(deal_buy_sell, 25300001, 1,0)),0) Pno,
      NVL(sum(decode(deal_buy_sell, 25300001, deal_base_amount,0)),0) Pfcy,
      NVL(sum(decode(deal_buy_sell, 25300001, deal_other_amount,0)),0) Pinr,
      NVL(sum(decode(deal_buy_sell, 25300002, 1,0)),0) Sno,
      NVL(sum(decode(deal_buy_sell, 25300002, deal_base_amount,0)),0) Sfcy,
      NVL(sum(decode(deal_buy_sell, 25300002, deal_other_amount,0)),0) Sinr
      from trtran001 a
      where deal_execute_date = AsonDate
      and deal_user_id=userid
      and deal_record_status in (10200001, 10200003, 10200004)
      group by deal_base_currency, deal_hedge_trade
    union
--  Cross currency deals
    select deal_other_currency Currency, deal_hedge_trade DType,
      NVL(sum(decode(deal_buy_sell, 25300002, 1,0)),0) Pno,
      NVL(sum(decode(deal_buy_sell, 25300002, deal_other_amount,0)),0) Pfcy,
      NVL(sum(decode(deal_buy_sell, 25300002, deal_amount_local,0)),0) Pinr,
      NVL(sum(decode(deal_buy_sell, 25300001, 1,0)),0) Sno,
      NVL(sum(decode(deal_buy_sell, 25300001, deal_other_amount,0)),0) sfcy,
      NVL(sum(decode(deal_buy_sell, 25300001, deal_amount_local,0)),0) sinr
      from trtran001
      where deal_execute_date = AsonDate
      and deal_user_id=userid
      and deal_record_status in (10200001, 10200003, 10200004)
      and deal_other_currency != 30400003
      group by deal_other_currency, deal_hedge_trade)
      select currency, dtype, sum(pno) Pno, sum(pfcy) Pfcy, sum(pinr) Pinr ,
        sum(sno) Sno, sum(sfcy) Sfcy, sum(sinr) Sinr
        from DayDeals
        group by currency, dtype)
    Loop

      numType := curDeals.DType;
      numCurrency := curDeals.Currency;
      numPCount := curDeals.Pno;
      numPfcy := curDeals.Pfcy;
      numPinr := curDeals.Pinr;
      numSCount := curDeals.Sno;
      numSfcy := curDeals.Sfcy;
      numSinr := curDeals.Sinr;

      Begin
      select dpos_position_code, dpos_day_position, dpos_position_inr
        into numCode, numPosFcy, numPosInr
        from trsystem032
        where dpos_company_code = 30199999
        and dpos_currency_code = numCurrency
        and dpos_position_type = numType
        and dpos_user_id=userid
        and dpos_position_date =
        (select max(dpos_position_date)
          from trsystem032
          where dpos_company_code = 30199999
          and dpos_currency_code = numCurrency
          and dpos_position_type = numType
          and dpos_user_id=userid
          and dpos_position_date < AsonDate);
      Exception
        when no_data_found then
          numCode := 12400001;
          numPosFcy := 0;
          numPosInr := 0;
      End;

      if  numCode = 12400002 then
        numPosFcy := numPosFcy * -1;
      end if;

      numPosFcy := (numPosFcy + numPfcy) - numSFcy;

      if numPosFcy >= 0 then
        numCode := 12400001;
      else
        numPosFcy := numPosFcy *-1;
        numCode := 12400002;
      end if;

      numPosInr := (numPosInr + numPinr) - numSinr;

      varOperation := 'Updating Records';
      update trsystem032
        set dpos_purchase_number = numPCount,
        dpos_purchase_amount = numPfcy,
        dpos_purchase_inr = numPinr,
        dpos_sale_number = numScount,
        dpos_sale_amount = numSfcy,
        dpos_sale_inr = numSinr,
        dpos_position_code = numCode,
        dpos_day_position = numPosFcy,
        dpos_position_inr = numPosinr
        where dpos_company_code = 30199999
        and dpos_position_date = AsonDate
        and dpos_currency_code = numCurrency
        and dpos_position_type = numType
        and dpos_user_id=userid;
    End Loop;

    return numError;
Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('InsDeal', numError, varMessage,
                      varOperation, varError);
      raise_application_error(-20101, varError);
      return numError;
End fncInsertDeals;


-- Function fncGetRate
--    ( CurrencyCode in Number,
--      ForCurrency in Number,
--      AsonDate in Date,
--      BidAsk in Number,
--      RateType in number := 0,
--      DueDate in Date := null,
--      RateSerial in Number := 0)
--      Return Number
--      is
----  Created on 11/04/08 -- Modifield on 09/10/08
----  The Assumption is that the for currency will be either USD or INR
--    RATEEXISTS          CONSTANT number(1) := 1;
--    RATEDONOTEXIST      CONSTANT number(1) := 2;
--    PRAGMA AUTONOMOUS_TRANSACTION;
--    numError            number;
--    numFlag             number(1);
--    numRecords          number(2);
--    numMonth            number(2);
--    numSerial           number(5);
--    numSerial1          number(5);
--    numRate             number(15,6);
--    numRate1            number(15,6);
--    numBase             number(8);
--    numBase1            number(8);
--    numBidAsk           number(8);
--    varType             varchar2(50);
--    varType1            varchar2(50);
--    varType2            varchar2(50);
--    varType3            varchar2(50);
--    numSpot             number(15,6);
--    numPrem             number(15,6);
--    numPrem1            number(15,6);
--    numPrem2            number(15,6);
--    varQuery            varchar2(4000);
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    datAsOn             date;
--    datAsOn1            date;
--    datTemp             date;
----    datTemp1             date;
--
--    datStart            date;
--    datLast             date;
--    datSpot             date;
--    numTotalDays        number(5);
--    numActualDays       number(5);
--    numRateType         Number(5);
--Begin
--    numError := 0;
--    numRate := 0;
--    numRecords := 0;
--    numBidAsk := BidAsk;
---- The following condition is kept for older version of the code
---- where if duedate is not null mean rates are picked up
--
----    if DueDate is null then
----      numBidAsk := 0;
----    End if;
--
--    varMessage := 'Getting Rate ' || CurrencyCode || ' For: ' || ForCurrency ||
--      ' Date: ' || AsonDate;
--
--    varOperation := 'Getting Rate Type for Base Currency';
--    select NVL(cncy_principal_yn, GConst.OPTIONNO)
--      into numBase
--      from trmaster304
--      where cncy_pick_code = CurrencyCode;
--
--    varOperation := 'Getting Rate Type for Other Currency';
--    select NVL(cncy_principal_yn, GConst.OPTIONNO)
--      into numBase1
--      from trmaster304
--      where cncy_pick_code = ForCurrency;
----  If effective date is null, check for the latest date;
--
--    if AsonDate is null then
--      varOperation := 'Getting the Latest Date for Exchange rate';
--      if ForCurrency = GConst.USDOLLAR then
--        select max(drat_effective_date)
--          into datAsOn
--          from trtran012
--          where drat_currency_code =
--          decode(numBase, GConst.OPTIONYES, CurrencyCode, GConst.USDOLLAR)
--          and drat_for_currency =
--            decode(numBase, GConst.OPTIONYES, GConst.USDOLLAR, CurrencyCode)
--          and drat_record_status in
--            (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--      elsif ForCurrency = GConst.INDIANRUPEE then
--         select max(drat_effective_date)
--          into datAsOn
--          from trtran012
--          where drat_currency_code = CurrencyCode
--          and drat_for_currency = ForCurrency
--          and drat_record_status in
--            (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--      else
--        select max(drat_effective_date)
--          into datAson
--          from trtran012
--          where drat_currency_code = CurrencyCode
--          and drat_for_currency = GConst.USDOLLAR;
--
--        select max(drat_effective_date)
--          into datAson1
--          from trtran012
--          where drat_currency_code = ForCurrency
--          and drat_for_currency = GConst.USDOLLAR;
--      end if;
--
--    else
--      datAsOn := AsonDate;
--    End if;
--
--    varOperation := 'Checking whether  rate exists for the date';
--    numRecords := 0;
--    select count(*)
--      into numRecords
--      from trtran012
--      where drat_currency_code =
--      decode(numBase, GConst.OPTIONYES, CurrencyCode, GConst.USDOLLAR)
--      and drat_for_currency =
--        decode(numBase, GConst.OPTIONYES, GConst.USDOLLAR, CurrencyCode)
--      and drat_effective_date = datAsOn
--      and drat_record_status in
--        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--    if numRecords = 0 then
--      varError := 'No Exchange Rates for Currency: ' || CurrencyCode || ' for the date: ' || datAsOn;
--      numError := -20101;
--      raise_application_error(numError, varError);
--
--
--    End if;
--
--    if RateSerial = 0 then
--
--      if ForCurrency = GConst.USDOLLAR then
--        select NVL(max(drat_serial_number),0)
--          into numSerial
--          from trtran012
--          where drat_currency_code =
--          decode(numBase, GConst.OPTIONYES, CurrencyCode, GConst.USDOLLAR)
--          and drat_for_currency =
--            decode(numBase, GConst.OPTIONYES, GConst.USDOLLAR, CurrencyCode)
--          and drat_effective_date = datAsOn
--          and drat_record_status in
--            (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--      elsif ForCurrency = GConst.INDIANRUPEE then
--         select NVL(max(drat_serial_number),0)
--          into numSerial
--          from trtran012
--          where drat_currency_code = CurrencyCode
--          and drat_for_currency = ForCurrency
--          and drat_effective_date = datAsOn
--          and drat_record_status in
--            (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--      else
--        select NVL(max(drat_serial_number),0)
--          into numSerial
--          from trtran012
--          where drat_currency_code = CurrencyCode
--          and drat_for_currency = GConst.USDOLLAR
--          and drat_effective_date = datAsOn;
--
--        select NVL(max(drat_serial_number),0)
--          into numSerial1
--          from trtran012
--          where drat_currency_code = ForCurrency
--          and drat_for_currency = GConst.USDOLLAR
--          and drat_effective_date = datAsOn1;
--      end if;
--
--    else
--      numSerial := RateSerial;
--      numSerial1 := RateSerial;
--    End if;
--
--    varOperation := 'Checking whether Rate Exists'||numBase ||CurrencyCode||datAsOn ||numSerial ;
--    numRecords := 0;
--    select count(*)
--      into numRecords
--      from trtran012
--      where drat_currency_code =
--        decode(numBase, GConst.OPTIONYES, CurrencyCode, GConst.USDOLLAR)
--      and drat_for_currency =
--        decode(numBase, GConst.OPTIONYES, GConst.USDOLLAR, CurrencyCode)
--      and drat_record_status in
--        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED)
--      and drat_effective_date = datAsOn
--      and drat_serial_number = numSerial;
--
--
--
--    if numRecords = 0 then
--      varError := 'No Exchange Rates for Currency: ' || numBase || CurrencyCode || ' for date: ' || datAsOn;
--      numError := -20101;
--      raise_application_error(numError, varError);
--    end if;
--    numRateType:=0;
--     datSpot:= fncgetcurrspotdate(CurrencyCode,ForCurrency, asondate);
--
--    if DueDate is null then
--      numRateType := 0;
--    else
--      if DueDate <= datSpot then
--         numRateType:=0;
--      else
--
--      for numsub in 1..12
--      Loop
--        numRateType := numRateType + 1;
--        if (currencycode=30400004) and (forcurrency=30400003) then
--            if numsub=1 then
--              datTemp :=last_day(datSpot);
--            else
--              datTemp := last_day(add_months(datspot,numsub-1));
--            end if;
--        else
--          datTemp := add_months(datSpot, numSub);
--        end if;
--        if datTemp >= DueDate then
--          exit;
--        end if;
--
--      End Loop;
--  --        numRateType:=numRateType-1;
--    end if;
--    end if;
--
--
--
--   if ForCurrency in (GConst.USDOLLAR, GConst.INDIANRUPEE) then
--     if numBidAsk = GConst.PURCHASEDEAL then
--        select 'drat_spot_bid',
--          decode(numRateType,
--           0, ',drat_spot_bid', 1, ',drat_month1_bid',2, ',drat_month2_bid',3, ',drat_month3_bid',
--           4, ',drat_month4_bid',5, ',drat_month5_bid', 6, ',drat_month6_bid', 7, ',drat_month7_bid',
--           8, ',drat_month8_bid',9, ',drat_month9_bid', 10, ',drat_month10_bid',
--           11, ',drat_month11_bid',12, ',drat_month12_bid'), --First Discount
--          decode(numRateType,
--           0, ',drat_spot_bid', 1, ',drat_spot_bid',2, ',drat_month1_bid',3, ',drat_month2_bid',
--           4, ',drat_month3_bid',5, ',drat_month4_bid', 6, ',drat_month5_bid', 7, ',drat_month6_bid',
--           8, ',drat_month7_bid',9, ',drat_month8_bid', 10, ',drat_month9_bid',
--           11, ',drat_month10_bid',12, ',drat_month11_bid'), --Second Discount
--          decode(numRateType,
--            0, ',drat_spot_bid', 1, ',drat_spot_bid',2, ',drat_spot_bid',3, ',drat_month1_bid',
--            4, ',drat_month2_bid',5, ',drat_month3_bid', 6, ',drat_month4_bid', 7, ',drat_month5_bid',
--            8, ',drat_month6_bid',9, ',drat_month7_bid', 10, ',drat_month8_bid',
--            11, ',drat_month9_bid',12, ',drat_month10_bid')  --Thired DisCount
--
--          into varType,varType1,varType2,VarType3
--          from dual;
--      elsif numBidAsk = GConst.SALEDEAL then
--        select 'drat_spot_ask',
--          decode(numRateType,
--           0, ',drat_spot_ask', 1, ',drat_month1_ask',2, ',drat_month2_ask', 3, ',drat_month3_ask',
--           4, ',drat_month4_ask', 5, ',drat_month5_ask', 6, ',drat_month6_ask',7, ',drat_month7_ask',
--           8, ',drat_month8_ask', 9, ',drat_month9_ask',10, ',drat_month10_ask',
--           11, ',drat_month11_ask',12, ',drat_month12_ask'),  --First Preamum
--         decode(numRateType,
--           0, ',drat_spot_ask', 1, ',drat_spot_ask',2, ',drat_month1_ask', 3, ',drat_month2_ask',
--           4, ',drat_month3_ask', 5, ',drat_month4_ask', 6, ',drat_month5_ask',7, ',drat_month6_ask',
--           8, ',drat_month7_ask', 9, ',drat_month8_ask',10, ',drat_month9_ask',
--           11, ',drat_month10_ask',12, ',drat_month11_ask') ,  --Second Preamum
--         decode(numRateType,
--           0, ',drat_spot_ask', 1, ',drat_spot_ask',2, ',drat_spot_ask', 3, ',drat_month1_ask',
--           4, ',drat_month2_ask', 5, ',drat_month3_ask', 6, ',drat_month4_ask',7, ',drat_month5_ask',
--           8, ',drat_month6_ask', 9, ',drat_month7_ask',10, ',drat_month8_ask',
--           11, ',drat_month9_ask',12, ',drat_month10_ask')   --Thired Preamum
--         into varType,varType1,varType2,VarType3
--         from dual;
--      else
--        select decode(numRateType,
--          0, 'round((drat_spot_bid + drat_spot_ask)/2,4)',
--          1, 'round((drat_month1_bid + drat_month1_ask)/2,4)',
--          2, 'round((drat_month2_bid + drat_month2_ask)/2,4)',
--          3, 'round((drat_month3_bid + drat_month3_ask)/2,4)',
--          4, 'round((drat_month4_bid + drat_month4_ask)/2,4)',
--          5, 'round((drat_month5_bid + drat_month5_ask)/2,4)',
--          6, 'round((drat_month6_bid + drat_month6_ask)/2,4)',
--          7, 'round((drat_month7_bid + drat_month7_ask)/2,4)',
--          8, 'round((drat_month8_bid + drat_month8_ask)/2,4)',
--          9, 'round((drat_month9_bid + drat_month9_ask)/2,4)',
--          10, 'round((drat_month10_bid + drat_month10_ask)/2,4)',
--          11, 'round((drat_month11_bid + drat_month11_ask)/2,4)',
--          12, 'round((drat_month12_bid + drat_month12_ask)/2,4)')
----         decode(RateType,
----          0, ',round((drat_spot_bid + drat_spot_ask)/2,4)',
----          1, ',round((drat_spot_bid + drat_spot_ask)/2,4)',
----          2, ',round((drat_month1_bid + drat_month1_ask)/2,4)',
----          3, ',round((drat_month2_bid + drat_month2_ask)/2,4)',
----          4, ',round((drat_month3_bid + drat_month3_ask)/2,4)',
----          5, ',round((drat_month4_bid + drat_month4_ask)/2,4)',
----          6, ',round((drat_month5_bid + drat_month5_ask)/2,4)',
----          7, ',round((drat_month6_bid + drat_month6_ask)/2,4)',
----          8, ',round((drat_month7_bid + drat_month7_ask)/2,4)',
----          9, ',round((drat_month8_bid + drat_month8_ask)/2,4)',
----          10, ',round((drat_month9_bid + drat_month9_ask)/2,4)',
----          11, ',round((drat_month10_bid + drat_month10_ask)/2,4)',
----          12, ',round((drat_month11_bid + drat_month11_ask)/2,4)')
--          into varType
--          from dual;
--      end if;
--
--
--    varOperation := 'Building query to get rate';
----    insert into temp values (varQuery,varQuery);
----    commit;
--    varQuery := 'select ' || varType || varType1 || varType2 || VarType3 ;
--
--    if ForCurrency = GConst.USDOLLAR then
--
--      if numBase = GConst.OPTIONYES then
--        varQuery := varQuery || ' from trtran012 where';
--        varQuery := varQuery || ' drat_currency_code = ' || CurrencyCode;
--        varQuery := varQuery || ' and drat_for_currency = ' || ForCurrency;
--        varQuery := varQuery || ' and drat_effective_date = ' || '''' || datAsOn || '''';
--        varQuery := varQuery || ' and drat_serial_number = ' || numSerial;
--      else
--        varQuery := varQuery || ' from trtran012 where drat_for_currency = ' || CurrencyCode;
--        varQuery := varQuery || ' and drat_currency_code = ' || ForCurrency;
--        varQuery := varQuery || ' and drat_effective_date = ' || '''' || datAsOn || '''';
--        varQuery := varQuery || ' and drat_serial_number = ' || numSerial;
--      end if;
--
--    elsif ForCurrency = GConst.INDIANRUPEE then
--        varQuery := varQuery || ' from trtran012 where drat_currency_code = ' || CurrencyCode;
--        varQuery := varQuery || ' and drat_for_currency = ' || ForCurrency;
--        varQuery := varQuery || ' and drat_effective_date = ' || '''' || datAsOn || '''';
--        varQuery := varQuery || ' and drat_serial_number = ' || numSerial;
--    else
--        varQuery := varQuery || ' from trtran012 where drat_currency_code = ' || CurrencyCode;
--        varQuery := varQuery || ' and drat_for_currency = ' || ForCurrency;
--        varQuery := varQuery || ' and drat_effective_date = ' || '''' || AsonDate || '''';
--        varQuery := varQuery || ' and drat_serial_number = ' || numSerial;
--    End if;
--        Goto Process_End;
--
--  else
--    numRate := fncGetRate(CurrencyCode, GConst.USDOLLAR, datAsOn,
--                  numBidAsk, RateType, DueDate, numSerial);
--    numRate1 := fncGetRate(ForCurrency, GConst.USDOLLAR, datAsOn,
--                  numBidAsk, RateType, DueDate, numSerial1);
--
----    if numBase1 = GConst.OPTIONYES  then
----      numRate := round(numRate / numRate1, 4);
----    else
----      numRate := round(numRate * numRate1, 4);
----    end if;
--    if  ((numBase1 =GConst.OPTIONYES  ) and (numBase =GConst.OPTIONYES  ) )then
--        numRate := round(numRate / numRate1, 4);
--    else
--      if numBase1 = GConst.OPTIONYES  then
--        numRate := round(numRate / numRate1, 4);
--      else
--        numRate := round(numRate / numRate1, 4);
--      end if;
--    end if;
--
--    return numRate;
--  End if;
--
--<<Process_End>>
--
---- Modified By Manjunath Reddy on 10-nov-2008
--
--   if numBidAsk =0 then
--      Execute immediate varQuery into numRate;
--      return numRate;
--   end if;
--
--     varOperation := 'Executing query to get rate';
--      Execute immediate varQuery into numSpot,numPrem2,numPrem1,numPrem;
--
--          declare
--            numLastDay number(6);
--            numtemp number(15,6);
--            numMaturity number(6);
--            numStart number(6);
--
--          begin
--
---- For USD Forward Rates we have to take Month Ending As Last date
---- For All Other Currencies We Have to Take Spot Date to One Month as Last Date
--               numTotalDays:=1;
--               numActualDays:=1;
--                if ((CurrencyCode = GConst.USDOLLAR) and (ForCurrency =GConst.INDIANRUPEE)) then
--                  if numRateType=1 then
--                    --numStart := to_number(to_char(datSpot,'DD'));
--                    datStart :=datSpot;
--                    datLast := Last_day(add_months(datSpot,numRateType-1));
--                    numTotalDays :=datStart-datLast;
--                    numActualDays:=datStart-DueDate;
--                  elsif numRateType > 1 then
--                    --datStart :=add_months(datSpot,numRateType-1);
--                    --datLast := Last_day(add_months(datSpot,numRateType));
--                    numTotalDays :=to_number(to_char(last_day(DueDate),'DD'));
--                    numActualDays:=to_number(to_char(DueDate,'DD'));
--                  end if;
--                else
--                  if numRateType=1 then
--                    datStart :=datSpot;
--                    datLast := add_months(datSpot,numRateType);
--                    numTotalDays :=datStart-datLast;
--                    numActualDays:=datStart-DueDate;
--                  elsif numRateType > 1 then
--                    datStart :=add_months(datSpot,numRateType-1);
--                    datLast := add_months(datSpot,numRateType);
--                    numTotalDays :=datStart-datLast;
--                    numActualDays:=datStart-DueDate;
--                  end if;
--
--                end if;
--                varOperation := 'Calculating rate';
--                --numRate := numSpot + ((numPrem1-numPrem)+((((numPrem2-numPrem1)-(numPrem1-numPrem))/numTotalDays)*numActualDays));
--               -- numtemp := ((((numPrem2-numPrem1)-(numPrem1-numPrem))/numTotalDays)*numActualDays);
--                 numtemp := (((numPrem2-numPrem1)/numTotalDays)*numActualDays);
--               -- numRate := numPrem2 + ((numPrem1-numPrem)+numtemp);
--                  numRate := numPrem1 +numtemp;
--          exception
--          when others then
--      --      numRate:=numRate;
--            numError := SQLCODE;
--            varError := SQLERRM;
--            varError := GConst.fncReturnError('GetRate', numError, varMessage,
--                            varOperation, varError);
--            raise_application_error(-20101, varError);
--            numRate := 0.00;
--          end;
--
--
--      if numBase = GConst.OPTIONNO and ForCurrency = GConst.USDOLLAR then
--        numRate := round(1 / numRate, 4);
--      end if;
--    return numRate;
--Exception
--    When others then
--      numError := SQLCODE;
--      varError := SQLERRM;
--      varError := GConst.fncReturnError('GetRate', numError, varMessage,
--                      varOperation, varError);
--      raise_application_error(-20101, varError);
--      numRate := 0.00;
--      return numRate;
--End fncGetRate;
FUNCTION Fncmintrate
  (Asondate In Date,Basecurrency In Number,Forcurrency In Number) 
    return number 
    As
    Mintrate     Number(15,6);
    
begin

  SELECT (Drat_Spot_Bid+Drat_Spot_Ask)/2
  INTO Mintrate
  FROM Trtran012
  WHERE Drat_Currency_Code = Basecurrency
  AND Drat_For_Currency    = Forcurrency
  AND Drat_Effective_Date  = Asondate
  AND Drat_Serial_Number   =
    (SELECT MAX(Drat_Serial_Number)
    FROM Trtran012 a
    WHERE A.Drat_Currency_Code = Drat_Currency_Code
    AND A.Drat_For_Currency    = Drat_For_Currency
    AND A.Drat_Effective_Date  = Asondate);

Return Mintrate;

End Fncmintrate;

   Function fncGetRate
     ( CurrencyCode in Number,
      ForCurrency in Number,
      AsonDate in Date,
      BidAsk in Number,
      RateType in number := 0,
      DueDate in Date := null,
      RateSerial in Number := 0)
      Return Number
      is
--  Created on 11/04/08 -- Modifield on 09/10/08
--  The Assumption is that the for currency will be either USD or INR
    RATEEXISTS          CONSTANT number(1) := 1;
    RATEDONOTEXIST      CONSTANT number(1) := 2;
    PRAGMA AUTONOMOUS_TRANSACTION;
    numError            number;
    numFlag             number(1);
    numRecords          number(2);
    numMonth            number(2);
    numSerial           number(5);
    numSerial1          number(5);
    numRate             number(15,8);
    numRate1            number(15,8);
    numBase             number(8);
    numBase1            number(8);
    NUMBIDASK           NUMBER(8);
    VARTYPE             VARCHAR2(500);
    VARTYPE1            VARCHAR2(500);
    VARTYPE2            VARCHAR2(500);
    varType3            varchar2(500);
    numSpot             number(15,6);
    numPrem             number(15,6);
    numPrem1            number(15,6);
    numPrem2            number(15,6); 
    varQuery            varchar2(4000);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    datAsOn             date;
    datAsOn1            date;
    datTemp             date;
--    datTemp1             date;
    
    datStart            date;
    datLast             date;
    datSpot             date;
    numTotalDays        number(5);
    numActualDays       number(5);
    NUMRATETYPE         NUMBER(5);
    noofmonths          number(3);
Begin    
    numError := 0;
    numRate := 0;
    numRecords := 0;
    numBidAsk := BidAsk;
-- The following condition is kept for older version of the code
-- where if duedate is not null mean rates are picked up

--    if DueDate is null then
--      numBidAsk := 0;
--    End if;      
    
    varMessage := 'Getting Rate ' || CurrencyCode || ' For: ' || ForCurrency ||
      ' Date: ' || AsonDate;
      
    varOperation := 'Getting Rate Type for Base Currency';
    select NVL(cncy_principal_yn, GConst.OPTIONNO)
      into numBase
      from trmaster304
      where cncy_pick_code = CurrencyCode;

    varOperation := 'Getting Rate Type for Other Currency';
    select NVL(cncy_principal_yn, GConst.OPTIONNO)
      into numBase1
      from trmaster304
      where cncy_pick_code = ForCurrency;
--  If effective date is null, check for the latest date;

    if AsonDate is null then  
      varOperation := 'Getting the Latest Date for Exchange rate';
      if ForCurrency = GConst.USDOLLAR then
        select max(drat_effective_date)
          into datAsOn
          from trtran012
          where drat_currency_code = 
          decode(numBase, GConst.OPTIONYES, CurrencyCode, GConst.USDOLLAR)
          and drat_for_currency = 
            decode(numBase, GConst.OPTIONYES, GConst.USDOLLAR, CurrencyCode)
          and drat_record_status in          
            (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
      elsif ForCurrency = GConst.INDIANRUPEE then
         select max(drat_effective_date)
          into datAsOn
          from trtran012
          where drat_currency_code = CurrencyCode
          and drat_for_currency = ForCurrency 
          and drat_record_status in          
            (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
      else
        select max(drat_effective_date)
          into datAson
          from trtran012
          where drat_currency_code = CurrencyCode
          and drat_for_currency = GConst.USDOLLAR;
          
        select max(drat_effective_date)
          into datAson1
          from trtran012
          where drat_currency_code = ForCurrency
          and drat_for_currency = GConst.USDOLLAR;
      end if;
    
    else
      datAsOn := AsonDate;
    End if;
    
        varOperation := 'Checking whether  rate exists for the date';
    numRecords := 0;
    select count(*)
      into numRecords
      from trtran012
      where drat_currency_code =  CurrencyCode
      and drat_for_currency = forcurrency
      and drat_effective_date = datAsOn
      and drat_record_status in          
        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
     IF numRecords=0 THEN     
          select count(*)
            into numRecords
            from trtran012
            where drat_currency_code = 
            decode(numBase, GConst.OPTIONYES, CurrencyCode, GConst.USDOLLAR)
            and drat_for_currency = 
              decode(numBase, GConst.OPTIONYES, GConst.USDOLLAR, CurrencyCode)
            and drat_effective_date = datAsOn
            and drat_record_status in          
              (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
          if numRecords = 0 then
            varError := 'No Exchange Rates for Currency: ' || CurrencyCode || ' for the date: ' || datAsOn || ' Base ' || numBase;
            numError := -20101;
            raise_application_error(numError, varError);
           End if;
      END IF;
    if RateSerial = 0 then
    
      if ForCurrency = GConst.USDOLLAR then
        select NVL(max(drat_serial_number),0)
          into numSerial
          from trtran012
          where drat_currency_code = 
          decode(numBase, GConst.OPTIONYES, CurrencyCode, GConst.USDOLLAR)
          and drat_for_currency = 
            decode(numBase, GConst.OPTIONYES, GConst.USDOLLAR, CurrencyCode)
          and drat_effective_date = datAsOn
          and drat_record_status in          
            (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
      elsif ForCurrency = GConst.INDIANRUPEE then
         select NVL(max(drat_serial_number),0)
          into numSerial
          from trtran012
          where drat_currency_code = CurrencyCode
          and drat_for_currency = ForCurrency 
          and drat_effective_date = datAsOn
          and drat_record_status in          
            (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
      else
        select NVL(max(drat_serial_number),0)
          into numSerial
          from trtran012
          where drat_currency_code = CurrencyCode
          and drat_for_currency = GConst.USDOLLAR
          and drat_effective_date = datAsOn;
          
        select NVL(max(drat_serial_number),0)
          into numSerial1
          from trtran012
          where drat_currency_code = ForCurrency
          and drat_for_currency = GConst.USDOLLAR
          and drat_effective_date = datAsOn1;
      end if;
    
    else
      numSerial := RateSerial;
      numSerial1 := RateSerial;
    End if;
    varOperation := 'Checking whether Rate Exists'||numBase ||CurrencyCode||datAsOn ||numSerial ;    
    numRecords := 0;
    select count(*)
      into numRecords
      from trtran012
      where drat_currency_code =  CurrencyCode
      and drat_for_currency = forcurrency
      and drat_effective_date = datAsOn
      and drat_record_status in          
        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
     IF numRecords=0 THEN     
          select count(*)
            into numRecords
            from trtran012
            where drat_currency_code = 
            decode(numBase, GConst.OPTIONYES, CurrencyCode, GConst.USDOLLAR)
            and drat_for_currency = 
              decode(numBase, GConst.OPTIONYES, GConst.USDOLLAR, CurrencyCode)
            and drat_effective_date = datAsOn
            and drat_record_status in          
              (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
          if numRecords = 0 then
            varError := 'No Exchange Rates for Currency: ' || numBase || CurrencyCode || ' for date: ' || datAsOn;
            numError := -20101;
            raise_application_error(numError, varError);
           End if;
      END IF;


--    numRecords := 0;
--    select count(*)
--      into numRecords
--      from trtran012
--      where drat_currency_code =
--        decode(numBase, GConst.OPTIONYES, CurrencyCode, GConst.USDOLLAR)
--      and drat_for_currency = 
--        decode(numBase, GConst.OPTIONYES, GConst.USDOLLAR, CurrencyCode)
--      and drat_record_status in          
--        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED)
--      and drat_effective_date = datAsOn;
--    --  and drat_serial_number = numSerial;
--
--     
--     
--    if numRecords = 0 then
--      varError := 'No Exchange Rates for Currency: ' || numBase || CurrencyCode || ' for date: ' || datAsOn;
--      numError := -20101;
--      raise_application_error(numError, varError);
--    end if;
    NUMRATETYPE:=0;
     datSpot:= pkgforexprocess.fncgetcurrspotdate(CurrencyCode,ForCurrency, asondate);
    
    if DueDate is null then
      numRateType := 0;
    else      
      if DueDate <= datSpot then
         VarOperation:= 'Checking whether the DueDate is ToM';
         if ((duedate > asondate) and (DueDate < datSpot)) then
            numRateType:=-1; -- this for Tom
        elsif duedate = asondate then
            numRateType:=-2; -- this for Cash
        else
            numRateType:=0;
        end if;
      ELSE
    --  SELECT MONTHS_BETWEEN(DUEDATE ,DATSPOT) +2 INTO NOOFMONTHS FROM DUAL;
      
      for numsub in 1..50
      Loop
        numRateType := numRateType + 1;
        if (currencycode=30400004) and (forcurrency=30400003) then
--            if numsub=1 then
--              datTemp :=last_day(datSpot);
--            ELSE
--              datTemp := last_day(add_months(last_day(datspot),numsub-1));
--            end if;
            if numsub=1 then
                if last_day(datSpot)= datSpot then
                    datTemp:=last_day(datSpot+1);
                else
                    datTemp :=last_day(datSpot);
                end if;
            ELSE
             -- datTemp := last_day(add_months(last_day(datspot),numsub-1));
                if last_day(datSpot)= datSpot then
                    datTemp := last_day(add_months(last_day(datspot+1),numsub-1));
                else
                    datTemp := last_day(add_months(last_day(datspot),numsub-1));
                end if;
            end if;
        else
          datTemp := add_months(datSpot, numSub);
        end if;
        if datTemp >= DueDate then
          exit;
        end if;
        
      End Loop;
  --        numRateType:=numRateType-1;
    end if;
    end if;
    
  -- insert into temp values (datSpot,numRateType);
 
   if ForCurrency in (GConst.USDOLLAR, GConst.INDIANRUPEE) then
     IF NUMBIDASK = GCONST.PURCHASEDEAL THEN
     
--        select 'drat_spot_bid',
--          decode(numRateType,-2,',DRAT_CASH_BID',-1,',DRAT_TOM_BID',
--           0, ',drat_spot_bid', 1, ',drat_month1_bid',2, ',drat_month2_bid',3, ',drat_month3_bid',
--           4, ',drat_month4_bid',5, ',drat_month5_bid', 6, ',drat_month6_bid', 7, ',drat_month7_bid',
--           8, ',drat_month8_bid',9, ',drat_month9_bid', 10, ',drat_month10_bid',
--           11, ',drat_month11_bid',12, ',drat_month12_bid', ',drat_month12_bid + ((drat_month12_bid - drat_month11_bid)*(' || numRateType||'-12))' ), --First Discount
--          decode(numRateType,-2,',DRAT_CASH_BID',-1,',DRAT_TOM_BID',
--           0, ',drat_spot_bid', 1, ',drat_spot_bid',2, ',drat_month1_bid',3, ',drat_month2_bid',
--           4, ',drat_month3_bid',5, ',drat_month4_bid', 6, ',drat_month5_bid', 7, ',drat_month6_bid',
--           8, ',drat_month7_bid',9, ',drat_month8_bid', 10, ',drat_month9_bid',
--           11, ',drat_month10_bid',12, ',drat_month11_bid', ',drat_month11_bid+((drat_month12_bid - drat_month11_bid)*(' || numRateType||'-12))'), --Second Discount 
--          decode(numRateType,-2,',DRAT_CASH_BID',-1,',DRAT_TOM_BID',
--            0, ',drat_spot_bid', 1, ',drat_spot_bid',2, ',drat_spot_bid',3, ',drat_month1_bid',
--            4, ',drat_month2_bid',5, ',drat_month3_bid', 6, ',drat_month4_bid', 7, ',drat_month5_bid',
--            8, ',drat_month6_bid',9, ',drat_month7_bid', 10, ',drat_month8_bid',
--            11, ',drat_month9_bid',12, ',drat_month10_bid',',drat_month10_bid+((drat_month12_bid-drat_month11_bid)*(' || numRateType||'-12))' )  --Thired DisCount
--          into varType,varType1,varType2,VarType3
--          FROM DUAL;
          
        select 'drat_spot_ask',
          decode(numRateType,-2,',DRAT_CASH_ask',-1,',DRAT_TOM_ask',
           0, ',drat_spot_ask', 1, ',drat_month1_ask',2, ',drat_month2_ask', 3, ',drat_month3_ask',
           4, ',drat_month4_ask', 5, ',drat_month5_ask', 6, ',drat_month6_ask',7, ',drat_month7_ask',
           8, ',drat_month8_ask', 9, ',drat_month9_ask',10, ',drat_month10_ask',
           11, ',drat_month11_ask',12, ',drat_month12_ask',',drat_month12_ask' ||'+' ||'((' ||'drat_month12_ask' ||'-' ||'drat_month11_ask'||')'||'*' ||'(' || numRateType||'-'|| 12 ||'))'),  --First Preamum
         decode(numRateType,-2,',DRAT_CASH_ask',-1,',DRAT_TOM_ask',
           0, ',drat_spot_ask', 1, ',drat_spot_ask',2, ',drat_month1_ask', 3, ',drat_month2_ask',
           4, ',drat_month3_ask', 5, ',drat_month4_ask', 6, ',drat_month5_ask',7, ',drat_month6_ask',
           8, ',drat_month7_ask', 9, ',drat_month8_ask',10, ',drat_month9_ask',
           11, ',drat_month10_ask',12, ',drat_month11_ask',',drat_month11_ask' ||'+' ||'((' ||'drat_month12_ask' ||'-' ||'drat_month11_ask'||')'||'*' ||'(' || numRateType||'-'|| 12 ||'))') ,  --Second Preamum
         decode(numRateType,-2,',DRAT_CASH_ask',-1,',DRAT_TOM_ask',
           0, ',drat_spot_ask', 1, ',drat_spot_ask',2, ',drat_spot_ask', 3, ',drat_month1_ask',
           4, ',drat_month2_ask', 5, ',drat_month3_ask', 6, ',drat_month4_ask',7, ',drat_month5_ask',
           8, ',drat_month6_ask', 9, ',drat_month7_ask',10, ',drat_month8_ask',
           11, ',drat_month9_ask',12, ',drat_month10_ask',',drat_month10_ask' ||'+' ||'((' ||'drat_month12_ask' ||'-' ||'drat_month11_ask'||')'||'*' ||'(' || numRateType||'-'|| 12 ||'))')   --Thired Preamum           
         into varType,varType1,varType2,VarType3
         FROM DUAL;          
           
      elsif numBidAsk = GConst.SALEDEAL then
--        select 'drat_spot_ask',
--          decode(numRateType,-2,',DRAT_CASH_ask',-1,',DRAT_TOM_ask',
--           0, ',drat_spot_ask', 1, ',drat_month1_ask',2, ',drat_month2_ask', 3, ',drat_month3_ask',
--           4, ',drat_month4_ask', 5, ',drat_month5_ask', 6, ',drat_month6_ask',7, ',drat_month7_ask',
--           8, ',drat_month8_ask', 9, ',drat_month9_ask',10, ',drat_month10_ask',
--           11, ',drat_month11_ask',12, ',drat_month12_ask',',drat_month12_ask' ||'+' ||'((' ||'drat_month12_ask' ||'-' ||'drat_month11_ask'||')'||'*' ||'(' || numRateType||'-'|| 12 ||'))'),  --First Preamum
--         decode(numRateType,-2,',DRAT_CASH_ask',-1,',DRAT_TOM_ask',
--           0, ',drat_spot_ask', 1, ',drat_spot_ask',2, ',drat_month1_ask', 3, ',drat_month2_ask',
--           4, ',drat_month3_ask', 5, ',drat_month4_ask', 6, ',drat_month5_ask',7, ',drat_month6_ask',
--           8, ',drat_month7_ask', 9, ',drat_month8_ask',10, ',drat_month9_ask',
--           11, ',drat_month10_ask',12, ',drat_month11_ask',',drat_month11_ask' ||'+' ||'((' ||'drat_month12_ask' ||'-' ||'drat_month11_ask'||')'||'*' ||'(' || numRateType||'-'|| 12 ||'))') ,  --Second Preamum
--         decode(numRateType,-2,',DRAT_CASH_ask',-1,',DRAT_TOM_ask',
--           0, ',drat_spot_ask', 1, ',drat_spot_ask',2, ',drat_spot_ask', 3, ',drat_month1_ask',
--           4, ',drat_month2_ask', 5, ',drat_month3_ask', 6, ',drat_month4_ask',7, ',drat_month5_ask',
--           8, ',drat_month6_ask', 9, ',drat_month7_ask',10, ',drat_month8_ask',
--           11, ',drat_month9_ask',12, ',drat_month10_ask',',drat_month10_ask' ||'+' ||'((' ||'drat_month12_ask' ||'-' ||'drat_month11_ask'||')'||'*' ||'(' || numRateType||'-'|| 12 ||'))')   --Thired Preamum           
--         into varType,varType1,varType2,VarType3
--         FROM DUAL;
         
        select 'drat_spot_bid',
          decode(numRateType,-2,',DRAT_CASH_BID',-1,',DRAT_TOM_BID',
           0, ',drat_spot_bid', 1, ',drat_month1_bid',2, ',drat_month2_bid',3, ',drat_month3_bid',
           4, ',drat_month4_bid',5, ',drat_month5_bid', 6, ',drat_month6_bid', 7, ',drat_month7_bid',
           8, ',drat_month8_bid',9, ',drat_month9_bid', 10, ',drat_month10_bid',
           11, ',drat_month11_bid',12, ',drat_month12_bid', ',drat_month12_bid + ((drat_month12_bid - drat_month11_bid)*(' || numRateType||'-12))' ), --First Discount
          decode(numRateType,-2,',DRAT_CASH_BID',-1,',DRAT_TOM_BID',
           0, ',drat_spot_bid', 1, ',drat_spot_bid',2, ',drat_month1_bid',3, ',drat_month2_bid',
           4, ',drat_month3_bid',5, ',drat_month4_bid', 6, ',drat_month5_bid', 7, ',drat_month6_bid',
           8, ',drat_month7_bid',9, ',drat_month8_bid', 10, ',drat_month9_bid',
           11, ',drat_month10_bid',12, ',drat_month11_bid', ',drat_month11_bid+((drat_month12_bid - drat_month11_bid)*(' || numRateType||'-12))'), --Second Discount 
          decode(numRateType,-2,',DRAT_CASH_BID',-1,',DRAT_TOM_BID',
            0, ',drat_spot_bid', 1, ',drat_spot_bid',2, ',drat_spot_bid',3, ',drat_month1_bid',
            4, ',drat_month2_bid',5, ',drat_month3_bid', 6, ',drat_month4_bid', 7, ',drat_month5_bid',
            8, ',drat_month6_bid',9, ',drat_month7_bid', 10, ',drat_month8_bid',
            11, ',drat_month9_bid',12, ',drat_month10_bid',',drat_month10_bid+((drat_month12_bid-drat_month11_bid)*(' || numRateType||'-12))' )  --Thired DisCount
          into varType,varType1,varType2,VarType3
          FROM DUAL;         

      ELSE
        select 'round((drat_spot_bid + drat_spot_ask)/2,6) , ',
           decode(numRateType,
          -2,'round((DRAT_CASH_ask+DRAT_Cash_bid/2,6)',
           -1,'round((DRAT_TOM_ask+DRAT_TOM_bid/2,6)',
          0, 'round((drat_spot_bid + drat_spot_ask)/2,6)',
          1, 'round((drat_month1_bid + drat_month1_ask)/2,6)',
          2, 'round((drat_month2_bid + drat_month2_ask)/2,6)',
          3, 'round((drat_month3_bid + drat_month3_ask)/2,6)',
          4, 'round((drat_month4_bid + drat_month4_ask)/2,6)',
          5, 'round((drat_month5_bid + drat_month5_ask)/2,6)',
          6, 'round((drat_month6_bid + drat_month6_ask)/2,6)',
          7, 'round((drat_month7_bid + drat_month7_ask)/2,6)',
          8, 'round((drat_month8_bid + drat_month8_ask)/2,6)',
          9, 'round((drat_month9_bid + drat_month9_ask)/2,6)',
          10, 'round((drat_month10_bid + drat_month10_ask)/2,6)',
          11, 'round((drat_month11_bid + drat_month11_ask)/2,6)',
          12, 'round((drat_month12_bid + drat_month12_ask)/2,6)',
              'round((drat_month12_bid +((drat_month12_bid-drat_month11_bid) * (numRateType-12)) + drat_month12_ask +((drat_month12_ask-drat_month11_ask) * (numRateType-12)))/2,6)'),
          -- Added  by Manjunath reddy on 19092018 
          decode(numRateType,-2,',round((DRAT_CASH_ask+DRAT_Cash_bid/2,6)',-1,',round((DRAT_TOM_ask+DRAT_TOM_bid/2,6)',
           0, ',round((drat_spot_bid + drat_spot_ask)/2,6)', 
           1, ',round((drat_spot_bid + drat_spot_ask)/2,6)',
           2, ',round((drat_month1_bid + drat_month1_ask)/2,6)',
           3, ',round((drat_month2_bid + drat_month2_ask)/2,6)',
           4, ',round((drat_month3_bid + drat_month3_ask)/2,6)',
           5, ',round((drat_month4_bid + drat_month4_ask)/2,6)',
           6, ',round((drat_month5_bid + drat_month5_ask)/2,6)',
           7, ',round((drat_month6_bid + drat_month6_ask)/2,6)',
           8, ',round((drat_month7_bid + drat_month7_ask)/2,6)',
           9, ',round((drat_month8_bid + drat_month8_ask)/2,6)', 
           10, ',round((drat_month9_bid + drat_month9_ask)/2,6)',
           11, ',round((drat_month10_bid + drat_month10_ask)/2,6)',
           12, ',round((drat_month11_bid + drat_month11_ask)/2,6)',
           ',round((drat_month11_bid + drat_month11_ask)/2,6)+((round((drat_month12_bid + drat_month12_ask)/2,6) - round((drat_month11_bid + drat_month11_ask)/2,6))*(' || numRateType||'-12))'), --Second Discount 
          decode(numRateType,-2,',round((DRAT_CASH_ask+DRAT_Cash_bid/2,6)',-1,',round((DRAT_TOM_ask+DRAT_TOM_bid/2,6)',
            0, ',round((drat_spot_bid + drat_spot_ask)/2,6)', 
            1, ',round((drat_spot_bid + drat_spot_ask)/2,6)',
            2, ',round((drat_spot_bid + drat_spot_ask)/2,6)',
            3, ',round((drat_month1_bid + drat_month1_ask)/2,6)',
            4, ',round((drat_month2_bid + drat_month2_ask)/2,6)',
            5, ',round((drat_month3_bid + drat_month3_ask)/2,6)',
            6, ',round((drat_month4_bid + drat_month4_ask)/2,6)', 
            7, ',round((drat_month5_bid + drat_month5_ask)/2,6)',
            8, ',round((drat_month6_bid + drat_month6_ask)/2,6)',
            9, ',round((drat_month7_bid + drat_month7_ask)/2,6)',
            10, ',round((drat_month8_bid + drat_month8_ask)/2,6)',
            11, ',round((drat_month9_bid + drat_month9_ask)/2,6)',
            12, ',round((drat_month10_bid + drat_month10_ask)/2,6)',
            ',round((drat_month10_bid + drat_month10_ask)/2,6+((round((drat_month12_bid + drat_month12_ask)/2,6)-round((drat_month11_bid + drat_month11_ask)/2,6))*(' || NUMRATETYPE||'-12))' )  --Thired DisCount

--         decode(RateType,
--          0, ',round((drat_spot_bid + drat_spot_ask)/2,4)',
--          1, ',round((drat_spot_bid + drat_spot_ask)/2,4)',
--          2, ',round((drat_month1_bid + drat_month1_ask)/2,4)',
--          3, ',round((drat_month2_bid + drat_month2_ask)/2,4)',
--          4, ',round((drat_month3_bid + drat_month3_ask)/2,4)',
--          5, ',round((drat_month4_bid + drat_month4_ask)/2,4)',
--          6, ',round((drat_month5_bid + drat_month5_ask)/2,4)',
--          7, ',round((drat_month6_bid + drat_month6_ask)/2,4)',
--          8, ',round((drat_month7_bid + drat_month7_ask)/2,4)',
--          9, ',round((drat_month8_bid + drat_month8_ask)/2,4)',
--          10, ',round((drat_month9_bid + drat_month9_ask)/2,4)',
--          11, ',round((drat_month10_bid + drat_month10_ask)/2,4)',
--          12, ',round((drat_month11_bid + drat_month11_ask)/2,4)')
          into varType,varType1,varType2,VarType3
          from dual;
      end if;
      
  
    VAROPERATION := 'Building query to get rate';
   insert into temp values (varQuery,varQuery);
   commit;
    varQuery := 'select ' || varType || varType1 || varType2 || VarType3 ; 
    
    if ForCurrency = GConst.USDOLLAR then 
    
      if numBase = GConst.OPTIONYES then
        varQuery := varQuery || ' from trtran012 where';
        varQuery := varQuery || ' drat_currency_code = ' || CurrencyCode;
        varQuery := varQuery || ' and drat_for_currency = ' || ForCurrency;
        varQuery := varQuery || ' and drat_effective_date = ' || '''' || datAsOn || '''';
        varQuery := varQuery || ' and drat_serial_number = ' || numSerial;
      else
        varQuery := varQuery || ' from trtran012 where drat_for_currency = ' || CurrencyCode;
        varQuery := varQuery || ' and drat_currency_code = ' || ForCurrency;
        varQuery := varQuery || ' and drat_effective_date = ' || '''' || datAsOn || '''';
        varQuery := varQuery || ' and drat_serial_number = ' || numSerial;
      end if;
      
    elsif ForCurrency = GConst.INDIANRUPEE then
        varQuery := varQuery || ' from trtran012 where drat_currency_code = ' || CurrencyCode;
        varQuery := varQuery || ' and drat_for_currency = ' || ForCurrency;
        varQuery := varQuery || ' and drat_effective_date = ' || '''' || datAsOn || '''';
        varQuery := varQuery || ' and drat_serial_number = ' || numSerial;
    else
        varQuery := varQuery || ' from trtran012 where drat_currency_code = ' || CurrencyCode;
        varQuery := varQuery || ' and drat_for_currency = ' || ForCurrency;
        varQuery := varQuery || ' and drat_effective_date = ' || '''' || AsonDate || '''';
        varQuery := varQuery || ' and drat_serial_number = ' || numSerial;
    END IF;
     INSERT INTO TEMP VALUES (varQuery,varQuery);
   COMMIT;
        Goto Process_End;    
  
  ELSE
  
    numRate := fncGetRate(CurrencyCode, GConst.USDOLLAR, datAsOn,
                  NUMBIDASK, RATETYPE, DUEDATE, NUMSERIAL);
    numRate1 := fncGetRate(ForCurrency, GConst.USDOLLAR, datAsOn,
                  numBidAsk, RateType, DueDate, numSerial1);

--    if numBase1 = GConst.OPTIONYES  then
--      numRate := round(numRate / numRate1, 4);
--    else
--      numRate := round(numRate * numRate1, 4);      
--    end if;
    if  ((numBase1 =GConst.OPTIONYES  ) and (numBase =GConst.OPTIONYES  ) )then
        numRate := round(numRate / numRate1, 8);
    else
      if numBase1 = GConst.OPTIONYES  then
        numRate := round(numRate / numRate1, 8);
      else
        numRate := round(numRate / numRate1, 8);
      end if;
    end if;
    
    return numRate;
  End if;

<<Process_End>>

-- Modified By Manjunath Reddy on 10-nov-2008

   if numBidAsk =0 then
      Execute immediate varQuery into numRate;
      return numRate;
   END IF;
   -- DELETE FROM TEMP;
 --   INSERT INTO TEMP values (VARQUERY,VARQUERY);
 --   COMMIT;

     varOperation := 'Executing query to get rate';
      EXECUTE IMMEDIATE VARQUERY INTO NUMSPOT,NUMPREM2,NUMPREM1,NUMPREM;    
      declare 
            numLastDay number(6);
            numtemp number(15,6);
            numMaturity number(6);
            numStart number(6);
            
       begin
           
-- For USD Forward Rates we have to take Month Ending As Last date 
-- For All Other Currencies We Have to Take Spot Date to One Month as Last Date
--               numTotalDays:=1;
--               numActualDays:=1;
--                if ((CurrencyCode = GConst.USDOLLAR) and (ForCurrency =GConst.INDIANRUPEE)) then
--                  if numRateType=1 then 
--                    --numStart := to_number(to_char(datSpot,'DD'));
--                    datStart :=datSpot;
--                    datLast := Last_day(add_months(datSpot,numRateType-1));
--                    numTotalDays :=datStart-datLast;
--                    numActualDays:=datStart-DueDate;
--                  elsif numRateType > 1 then 
--                    --datStart :=add_months(datSpot,numRateType-1);
--                    --datLast := Last_day(add_months(datSpot,numRateType));
--                    numTotalDays :=to_number(to_char(last_day(DueDate),'DD'));
--                    numActualDays:=to_number(to_char(DueDate,'DD'));
--                  end if;
--                else
--                  if numRateType=1 then 
--                    datStart :=datSpot;
--                    datLast := add_months(datSpot,numRateType);
--                    numTotalDays :=datStart-datLast;
--                    numActualDays:=datStart-DueDate;
--                  elsif numRateType > 1 then
--                    datStart :=add_months(datSpot,numRateType-1);
--                    datLast := add_months(datSpot,numRateType);
--                    numTotalDays :=datStart-datLast;
--                    numActualDays:=datStart-DueDate;
--                  end if;
--                   
--                end if;
--                varOperation := 'Calculating rate';
--                --numRate := numSpot + ((numPrem1-numPrem)+((((numPrem2-numPrem1)-(numPrem1-numPrem))/numTotalDays)*numActualDays));
--               -- numtemp := ((((numPrem2-numPrem1)-(numPrem1-numPrem))/numTotalDays)*numActualDays);
--                 numtemp := (((numPrem2-numPrem1)/numTotalDays)*numActualDays);
--               -- numRate := numPrem2 + ((numPrem1-numPrem)+numtemp);
--               delete from temp;
--               insert into temp values (numPrem2,numPrem1);
--               insert into temp values (numTotalDays,numActualDays);
--               insert into temp values (numtemp,'tempRate');
--               commit;
--                  numRate := numPrem1 +numtemp;

                numTotalDays:=1;
                numActualDays:=1;
                if ((CurrencyCode = GConst.USDOLLAR) and (ForCurrency =GConst.INDIANRUPEE)) then
                  if numRateType=1 then 
--                    --numStart := to_number(to_char(datSpot,'DD'));
--                    datStart :=datSpot;
--                   --datLast := Last_day(add_months(datSpot,numRateType-1));
--                   datLast := fncLastWorkingDate_Month(CurrencyCode,ForCurrency,datSpot);
                   
                                       --numStart := to_number(to_char(datSpot,'DD'));
                   -- if (last_day(datSpot)!=datSpot) then
--                       datStart :=datSpot-1;
--                       datLast := fncLastWorkingDate_Month(CurrencyCode,ForCurrency,datSpot);
--                    else
                       datStart :=datSpot;
                       if last_day(datSpot)= datSpot then
                           datLast := fncLastWorkingDate_Month(CurrencyCode,ForCurrency,datSpot+1);
                       else
                           datLast := fncLastWorkingDate_Month(CurrencyCode,ForCurrency,datSpot);
                       end if;
                       
                --    end if;


                   numTotalDays :=datStart-datLast;
                   numActualDays:=datStart-DueDate;
                 elsif numRateType > 1 then 
                    datStart :=fncLastWorkingDate_Month(CurrencyCode,ForCurrency,add_months(DueDate,-1));
                    datLast := fncLastWorkingDate_Month(CurrencyCode,ForCurrency,DueDate);
                    --numTotalDays :=to_number(to_char(last_day(DueDate),'DD'));
                    --numActualDays:=to_number(to_char(DueDate,'DD'));
                    numTotalDays := datLast-datStart;
                    numActualDays:=DueDate-datStart;
                  end if;
                else
                  if numRateType=1 then 
                    datStart :=datSpot;
                    datLast := add_months(datSpot,numRateType);
                    numTotalDays :=datStart-datLast;
                    numActualDays:=datStart-DueDate;
                  elsif numRateType > 1 then
                    datStart :=add_months(datSpot,numRateType-1);
                    datLast := add_months(datSpot,numRateType);
                    numTotalDays :=datStart-datLast;
                    numActualDays:=datStart-DueDate;
                  end if;
                   
                end if;
                varOperation := 'Calculating rate';
                --numRate := numSpot + ((numPrem1-numPrem)+((((numPrem2-numPrem1)-(numPrem1-numPrem))/numTotalDays)*numActualDays));
               -- numtemp := ((((numPrem2-numPrem1)-(numPrem1-numPrem))/numTotalDays)*numActualDays);
                if numTotalDays=0 then 
                  numTotalDays:=1;
                end if;
                 numtemp := (((numPrem2-numPrem1)/numTotalDays)*numActualDays);
               -- numRate := numPrem2 + ((numPrem1-numPrem)+numtemp);
--               delete from temp;
--               insert into temp values (numPrem2,numPrem1);
--               insert into temp values (numTotalDays,numActualDays);
--               insert into temp values (datLast,datStart);
--                insert into temp values (DueDate,numRateType);
--               insert into temp values (numtemp,'tempRate');
--               commit;
                  numRate := numPrem1 +numtemp;
          exception
          when others then
      --      numRate:=numRate;
            numError := SQLCODE;
            varError := SQLERRM;
            varError := GConst.fncReturnError('GetRate', numError, varMessage, 
                            varOperation, varError);
            raise_application_error(-20101, varError);    
            numRate := 0.00;
          end;
    
    
      if numBase = GConst.OPTIONNO and ForCurrency = GConst.USDOLLAR then
        numRate := round(1 / numRate, 8);
      end if;
    return numRate;
Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('GetRate', numError, varMessage, 
                      varOperation, varError);
      raise_application_error(-20101, varError);    
      numRate := 0.00;
      RETURN NUMRATE;
END fncGetRate;


FUNCTION fncLastWorkingDate_Month
            ( CurrencyCode IN Number,
              ForCurrency IN Number,
              DateAson IN Date)
              RETURN Date 
is
datCurrency date;
datForCurrency Date;
numLocation number(8);
numForlocation number(8); 
NumberOfDays1 number;
datLastWorkingDate Date; 
BEGIN
--  if NumberOfDays = 1 then
--    NumberOfDays1 := NumberOfDays;
--  else
--    NumberOfDays1 :=3;
--  end if;
  Select cncy_location_code into numlocation 
   from trmaster304
  where cncy_pick_code= CurrencyCode;
  
  Select cncy_location_code into numForlocation 
   from trmaster304
  where cncy_pick_code= ForCurrency;
  
--  Select datCur into datCurrency
--  from (select  Rownum RowNo, Datcur  
--   from(
--   
   select max(hday_calendar_Date) datCur 
    into datCurrency
          from trsystem001
         Where Hday_Location_Code= Numlocation
           and hday_calendar_date <= last_day(dateason)
           and hday_day_status not in 
              (Gconst.Dayholiday, Gconst.Dayweeklyoff1, Gconst.Dayweeklyoff2)
      order by hday_calendar_date;

  
  select max(hday_calendar_Date) DatForCurrency 
    into datCurrency
          from trsystem001
         Where Hday_Location_Code= Numlocation
           and hday_calendar_date <= last_day(dateason)
           and hday_day_status not in 
              (Gconst.Dayholiday, Gconst.Dayweeklyoff1, Gconst.Dayweeklyoff2)
      order by hday_calendar_date;
   
   

  if datCurrency < DatForCurrency then
    datLastWorkingDate:= datForCurrency;
  else
    datLastWorkingDate:= datCurrency;
  end if;
  RETURN datLastWorkingDate;
END fncLastWorkingDate_Month;

FUNCTION fncGetCurrSpotDate
            ( CurrencyCode IN Number,
              ForCurrency IN Number,
              DateAson IN Date,
              NumberOfDays in Number Default 4)
              RETURN Date 
is
datCurrency date;
datForCurrency Date;
numLocation number(8);
numForlocation number(8); 
NumberOfDays1 number;
datSpot Date; 
BEGIN
  if NumberOfDays = 1 then
    NumberOfDays1 := NumberOfDays;
  else
    NumberOfDays1 :=3;
  end if;
  Select cncy_location_code into numlocation 
   from trmaster304
  where cncy_pick_code= CurrencyCode;
  
  Select cncy_location_code into numForlocation 
   from trmaster304
  where cncy_pick_code= ForCurrency;
  
  Select datCur into datCurrency
  from (select  Rownum RowNo, Datcur  
   from(select to_date(hday_calendar_Date) datCur 
          from trsystem001
         Where Hday_Location_Code= Numlocation
           and hday_calendar_date >= dateason
           and hday_day_status not in 
              (Gconst.Dayholiday, Gconst.Dayweeklyoff1, Gconst.Dayweeklyoff2)
      order by hday_calendar_date ))
   Where rowno=Numberofdays1;
  
  Select datCur into Datforcurrency
  from (select  Rownum RowNo, Datcur  
   from(select to_date(hday_calendar_Date) datCur 
          from trsystem001
         Where Hday_Location_Code= numForlocation
           and hday_calendar_date >= dateason
           and hday_day_status not in 
              (Gconst.Dayholiday, Gconst.Dayweeklyoff1, Gconst.Dayweeklyoff2)
      order by hday_calendar_date ))
   Where rowno=Numberofdays1;
   
   

  if datCurrency < DatForCurrency then
    datSpot:= datForCurrency;
  else
    datSpot:= datCurrency;
  end if;
  RETURN datSpot;
END fncGetCurrSpotDate;

--Function fncHoldingRate
--    ( CurrencyCode in Number,
--      AsonDate in Date,
--      ErrorNumber in out nocopy number,
--      UserID in varchar2 := NULL)
--    return number
--    is
----  Created on 27/03/2008
--    numError            number;
--    numCode             number;
--    numSerial           number(5);
--    numPosition         number(8);
--    numbuycount         number(5) :=0;
--    numsalcount         number(5) :=0;
--    numRate             number(15,6) := 0;
--    numPosFCY           number(20,6) := 0;
--    numPosINR           number(20,2) := 0;
--    numBuyFCY           number(15,6) := 0;
--    numSalFCY           number(15,6) := 0;
--    numBuyINR           number(15,2) := 0;
--    numSalINR           number(15,2) := 0;
--    numBuyFCYTot        number(15,6) := 0;
--    numSalFCYTot        number(15,6) := 0;
--    numBuyINRTot        number(15,2) := 0;
--    numSalINRTot        number(15,2) := 0;
--    datToday            date;
--    varUserID           varchar2(50);
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    tsDeal              timestamp;
--Begin
--    varMessage := 'Holding Rate Calculation';
--    numError := 0;
--    numRate := 0.00;
--
--    if UserID is null then
--      varUserID := '0';
--    else
--      varUserID := UserID;
--    end if;
--
--    --Modified BY Manjunath reddy BCZ its getting error when no data found for that currency
--    varOperation := 'Extracting the previous Date';
--
--    select nvl(max(drat_effective_date),AsonDate)
--        into datToday
--        from trtran012
--        where drat_currency_code = CurrencyCode
--        and drat_for_currency = GConst.INDIANRUPEE
--        and drat_effective_date < AsonDate;
--
--    select max(drat_serial_number)
--      into numSerial
--        from trtran012
--        where drat_currency_code = CurrencyCode
--        and drat_for_currency = GConst.INDIANRUPEE
--        and drat_effective_date = datToday;
--
--
--    varOperation := 'Extracting Previous Holding Rate';
--    select round((drat_spot_bid + drat_spot_ask) / 2,4)
--      into numRate
--      from trtran012
--      where drat_currency_code = CurrencyCode
--      and drat_for_currency = GConst.INDIANRUPEE
--      and drat_effective_date = datToday
--      and drat_serial_number = numSerial;
--
--
--    varOperation := 'Getting Opening day position';
--    Begin
--      select NVL(dpos_position_code,0), NVL(dpos_day_position,0)
--        into numPosition, numPosFcy
--        from trsystem032 a
--        where dpos_company_code = 30199999
--        and dpos_currency_code = CurrencyCode
--        and dpos_position_type = GConst.TRADEDEAL
--        and dpos_user_id = varUserID
--        and dpos_position_date =
--        (select max(dpos_position_date)
--          from trsystem032 b
--          where a.dpos_company_code = b.dpos_company_code
--          and a.dpos_currency_code = b.dpos_currency_code
--          and a.dpos_position_type = b.dpos_position_type
--          and a.dpos_user_id = b.dpos_user_id
--          and b.dpos_position_date < AsonDate);
--
--    Exception
--      when no_data_found then
--      numPosition := 0;
--      numPosFcy := 0;
--    End;
--
--    if numPosition = 0 then
--      numPosInr := 0;
--      numPosition := GConst.OPTIONYES;
--    else
--      numPosInr := Round(numPosFcy * numRate,0);
--    end if;
--
--    if numPosition = GConst.OPTIONNO then
--      numPosFcy := numPosFcy * -1;
--      numPosInr := numPosInr * -1;
--    end if;
--
--dbms_output.put_line('Open : ' || numPosFcy || ' Re: ' || numPosInr);
--
--    varOperation := 'Calculating Holding Rate';
--    for curHoldingRate in
--    (select 1 DealType, to_timestamp(deal_time_stamp,'DD-Mon-RR HH24:MI:SS:FF3'),
--      deal_deal_number DealNumber, deal_serial_number DealSerial,
--      nvl(decode(deal_buy_sell, GConst.PURCHASEDEAL, deal_base_amount,0),0) BuyFCY,
--      nvl(decode(deal_buy_sell, GConst.SALEDEAL,deal_base_amount, 0),0)  SaleFCY,
--      nvl(decode(deal_buy_sell, GConst.PURCHASEDEAL,
--        decode(deal_other_currency,GConst.INDIANRUPEE,deal_other_amount,deal_amount_local),0),0) BuyINR,
--      nvl(decode(deal_buy_sell, GConst.SALEDEAL,
--        decode(deal_other_currency,GConst.INDIANRUPEE,deal_other_amount,deal_amount_local),0),0) SaleINR
--      from trtran001
--      where deal_base_currency = CurrencyCode
--      and deal_hedge_trade = GConst.TRADEDEAL
--      and deal_execute_date = AsonDate
--      and deal_user_id like decode(varUserID, '0', '%', varUserID)
--      and deal_record_status not in (10200006)
--    union
----  Cross Currency Deals
--    select 2 DealType, to_timestamp(deal_time_stamp,'DD-Mon-RR HH24:MI:SS:FF3'),
--      deal_deal_number DealNumber, deal_serial_number DealSerial,
--      nvl(decode(deal_buy_sell, GConst.SALEDEAL, deal_other_amount, 0),0)  BuyFCY,
--      nvl(decode(deal_buy_sell, GConst.PURCHASEDEAL, deal_other_amount,0),0) SaleFCY,
--      nvl(decode(deal_buy_sell, GConst.SALEDEAL, deal_amount_local, 0),0) BuyINR,
--      nvl(decode(deal_buy_sell, GConst.PURCHASEDEAL, deal_amount_local,0),0) SaleINR
--      from trtran001
--      where deal_other_currency = CurrencyCode
--      and deal_hedge_trade = GConst.TRADEDEAL
--      and deal_execute_date = AsonDate
--      and deal_user_id like decode(varUserID, '0', '%', varUserID)
--      and deal_record_status not in (10200006)
--    union
----  Cancel Deal
----  modified by reddy replace with deal_base_amount to CDEL_CANCEL_AMOUNT
--    select 3 DealType, to_timestamp(cdel_time_stamp,'DD-Mon-RR HH24:MI:SS:FF3'),
--      cdel_deal_number DealNumber, cdel_deal_serial DealSerial,
--      nvl(decode(deal_buy_sell, GConst.SALEDEAL, cdel_cancel_amount, 0),0)  BuyFCY,
--      nvl(decode(deal_buy_sell, GConst.PURCHASEDEAL, cdel_cancel_amount,0),0) SaleFCY,
--      nvl(decode(deal_buy_sell, GConst.SALEDEAL,decode(deal_other_currency,GConst.INDIANRUPEE,cdel_other_amount,cdel_cancel_inr),0),0) BuyINR,
--      nvl(decode(deal_buy_sell, GConst.PURCHASEDEAL,decode(deal_other_currency,GConst.INDIANRUPEE,cdel_other_amount,cdel_cancel_inr),0),0) SaleINR
--      from trtran001, trtran006
--      where deal_deal_number = cdel_deal_number
--      and deal_serial_number = cdel_deal_serial
--      and deal_base_currency = CurrencyCode
--      and deal_hedge_trade = GConst.TRADEDEAL
--      and cdel_cancel_date = AsonDate
--      and deal_user_id like decode(varUserID, '0', '%', varUserID)
--      and cdel_record_status in (10200001, 10200003,10200004)
--    union
----  Cancel Cross Currency
----  modified by reddy replace with deal_other_amount to CDEL_OTHER_AMOUNT
--    select 4 DealType, to_timestamp(cdel_time_stamp,'DD-Mon-RR HH24:MI:SS:FF3'),
--      cdel_deal_number DealNumber, cdel_deal_serial DealSerial,
--      nvl(decode(deal_buy_sell, GConst.SALEDEAL, cdel_other_amount, 0),0)  BuyFCY,
--      nvl(decode(deal_buy_sell, GConst.PURCHASEDEAL, cdel_other_amount,0),0) SaleFCY,
--      nvl(decode(deal_buy_sell, GConst.SALEDEAL, cdel_cancel_inr, 0),0) BuyINR,
--      nvl(decode(deal_buy_sell, GConst.PURCHASEDEAL, cdel_cancel_inr,0),0) SaleINR
--      from trtran001, trtran006
--      where deal_deal_number = cdel_deal_number
--      and deal_serial_number = cdel_deal_serial
--      and deal_other_currency = CurrencyCode
--      and deal_hedge_trade = GConst.TRADEDEAL
--      and cdel_cancel_date = AsonDate
--      and deal_user_id like decode(varUserID, '0', '%', varUserID)
--      and cdel_record_status in (10200001, 10200003,10200004)
--    order by 2)
--
--    Loop
--      numCode := curHoldingRate.DealType;
--      numBuyFCY := curHoldingRate.BuyFCY;
--      numSalFCY := curHoldingRate.SaleFCY;
--      numBuyINR := curHoldingRate.BuyINR;
--      numSalINR := curHoldingRate.SaleINR;
--
--      numPosFCY := (numPosFCY + numBuyFCY) - numSalFCY;
--      numPosInr := (numPosINR + numBuyINR) - numSalINR;
--   --added by reddy 24-07-08
--   if (numcode=1)or(numcode=2) then
--      if numBuyFCY >0 then
--        numbuycount :=numbuycount+1;
--      elsif numSalFCY >0 then
--        numsalcount :=numsalcount+1;
--      end if;
--        numBuyFCYTot := numBuyFCYTot+numBuyFCY;
--        numSalFCYTot := numSalFCYTot+numSalFCY;
--        numBuyINRTot := numBuyINRTot+numBuyINR;
--        numSalINRTot := numSalINRTot + numSalINR;
--
--   else
--        numBuyFCYTot := numBuyFCYTot-numSalFCY;
--        numSalFCYTot := numSalFCYTot-numBuyFCY;
--        numBuyINRTot := numBuyINRTot-numSalINR;
--        numSalINRTot := numSalINRTot -numBuyINR;
--   end if;
--   ----------
--      if abs(numPosFCY) = 0 then
--        numrate :=0;
--      else
--        numRate := round(abs(numPosInr) / abs(numPosFCY),4);
--      end if;
--dbms_output.put_line('Typ : ' || numCode || ' FCY: ' || numPosFcy || ' Inr: ' || numPosInr || ' Rat: ' || numRate);
--
--      if varUserID = '0' then
--        if numCode = 1 then
--          update trtran001
--            set deal_holding_rate = numRate
--            where deal_deal_number = curHoldingRate.DealNumber
--            and deal_serial_number = curHoldingRate.DealSerial;
--        elsif numCode = 2 then
--          update trtran001
--            set deal_holding_rate1 = numRate
--            where deal_deal_number = curHoldingRate.DealNumber
--            and deal_serial_number = curHoldingRate.DealSerial;
--        elsif numCode = 3   then
--          update trtran006
--            set cdel_holding_rate = numRate
--            where cdel_deal_number = curHoldingRate.DealNumber
--            and cdel_deal_serial = curHoldingRate.DealSerial;
--        elsif numCode = 4 then
--          update trtran006
--            set cdel_holding_rate1 = numRate
--            where cdel_deal_number = curHoldingRate.DealNumber
--            and cdel_deal_serial = curHoldingRate.DealSerial;
--        end if;
--      else
--         if numCode = 1 then
--          update trtran001
--            set deal_dealer_holding = numRate
--            where deal_deal_number = curHoldingRate.DealNumber
--            and deal_serial_number = curHoldingRate.DealSerial;
--        elsif numCode = 2 then
--          update trtran001
--            set deal_dealer_holding1 = numRate
--            where deal_deal_number = curHoldingRate.DealNumber
--            and deal_serial_number = curHoldingRate.DealSerial;
--        elsif numCode = 3   then
--          update trtran006
--            set cdel_dealer_holding = numRate
--            where cdel_deal_number = curHoldingRate.DealNumber
--            and cdel_deal_serial = curHoldingRate.DealSerial;
--        elsif numCode = 4 then
--          update trtran006
--            set cdel_dealer_holding1 = numRate
--            where cdel_deal_number = curHoldingRate.DealNumber
--            and cdel_deal_serial = curHoldingRate.DealSerial;
--        end if;
--
--      end if;
--    End Loop;
--
--    if numPosFcy >= 0 then
--      numCode := 12400001;
--    else
--      numCode := 12400002;
--      numPosFcy := abs(numPosFcy);
--      numPosInr := abs(numPosInr);
--    end if;
--
--
----    if UserId is null then
----      varUserID := '0';
----    else
----      varUserID := UserID;
----    end if;
--
--  --updated by reddy for inserting
--    varOperation := 'Updating Currency Wise Position';
--
--    update trsystem032
--      set dpos_purchase_number=numbuycount,
--      dpos_purchase_amount=numBuyFCYTot,
--      dpos_purchase_inr=numBuyINRTot,
--      dpos_sale_number=numsalcount,
--      dpos_sale_amount=numSalFCYTot,
--      dpos_sale_inr=numSalINRTot,
--      dpos_holding_rate = numRate,
--      dpos_position_code = numCode,
--      dpos_day_position = numPosFcy,
--      dpos_position_inr = numPosInr
--      where dpos_currency_code = CurrencyCode
--      and dpos_position_date = AsonDate
--      and dpos_position_type = GConst.TRADEDEAL
--      and dpos_user_id = varUserID;
--
--    numError := SQl%ROWCOUNT;
--
--    if numError = 0 then
--      varOperation := 'Inserting Currency Wise Position';
--      insert into trsystem032(dpos_company_code, dpos_position_date,
--        dpos_currency_code, dpos_position_type, dpos_purchase_number,
--        dpos_purchase_amount, dpos_purchase_inr, dpos_sale_number,
--        dpos_sale_amount, dpos_sale_inr, dpos_position_code,
--        dpos_day_position, dpos_position_inr,
--        dpos_holding_rate, dpos_user_id)
--        values(30199999, AsonDate, CurrencyCode,GConst.TRADEDEAL,
--        numbuycount,numBuyFCYTot,numBuyINRTot,numsalcount,numSalFCYTot,numSalINRTot
--        ,numCode, numPosFcy, numPosInr, numRate, varUserID);
--    end if;
--
--
--    return numRate;
--Exception
--    When others then
--      numError := SQLCODE;
--      varError := SQLERRM;
--      varError := GConst.fncReturnError('HoldingRate', numError, varMessage,
--                      varOperation, varError);
--      raise_application_error(-20101, varError);
--      return numRate;
--End fncHoldingRate;


-- The Following function will take care of populating trtran002
-- for the rates uploaed through Windows Services - TMM 19/10/12
--Function fncCalculateRate
--    ( RateDate  Date,
--      BaseCurrency in Number,
--      ForCurrency in Number,
--      SerialNumber in Number)
--    Return number
--    is
---- Created on 19/10/2012 for the Windows Services Program
--    numError            number;
--    numSerial           number(5);
--    numCurrencyCode     number(8);
--    numForCurrency      number(8);
--    numType             number(8);
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    AsonDate            Date;
--    clbTemp             clob;
--    xmlTemp             xmltype;
--Begin
--    varMessage := 'Calculating Rates for : ' || RateDate || ':' ||
--      BaseCurrency || ':' || ForCurrency;
--
--    AsonDate := RateDate;
--    numCurrencyCode := BaseCurrency;
--    numForCurrency := ForCurrency;
--    numSerial := SerialNumber;
--
--
--    varOperation := 'Deleting the existing Rates';
--    Delete from trtran012
--      where drat_effective_date = AsonDate
--      and drat_serial_number = numSerial
--      and drat_currency_code = numCurrencyCode
--      and drat_for_currency = numForCurrency;
--
--    varOperation := 'Inserting Exchange Rates for USD / Other Currencies';
--    insert into trtran012(drat_currency_code,drat_for_currency,drat_effective_date,
--      drat_serial_number,drat_rate_time,drat_time_stamp,drat_rate_description,
--      drat_spot_bid,drat_spot_ask, drat_month1_bid,  drat_month1_ask,
--      drat_month2_bid,drat_month2_ask,drat_month3_bid,drat_month3_ask,
--      drat_month4_bid,drat_month4_ask,drat_month5_bid,drat_month5_ask,
--      drat_month6_bid,drat_month6_ask,drat_month7_bid,drat_month7_ask,
--      drat_month8_bid,drat_month8_ask, drat_month9_bid,drat_month9_ask,
--      drat_month10_bid,drat_month10_ask, drat_month11_bid,drat_month11_ask,
--      drat_month12_bid,drat_month12_ask,
--      drat_create_date,drat_add_date,drat_entry_detail,drat_record_status)
--      select rate_currency_code BaseCurrency, rate_for_currency OtherCurrency, rate_effective_date,
--      numSerial, rate_rate_time, rate_time_stamp, rate_rate_description,
--      round(rate_spot_bid,4) BidSpot, round(rate_spot_ask,4) AskSpot,
--      round(rate_spot_bid + rate_month1_bid,4), round(rate_spot_ask + rate_month1_ask,4),
--      round(rate_spot_bid + rate_month2_bid,4), round(rate_spot_ask + rate_month2_ask,4),
--      round(rate_spot_bid + rate_month3_bid,4), round(rate_spot_ask + rate_month3_ask,4),
--      round(rate_spot_bid + rate_month4_bid,4), round(rate_spot_ask + rate_month4_ask,4),
--      round(rate_spot_bid + rate_month5_bid,4), round(rate_spot_ask + rate_month5_ask,4),
--      round(rate_spot_bid + rate_month6_bid,4), round(rate_spot_ask + rate_month6_ask,4),
--      round(rate_spot_bid + rate_month7_bid,4), round(rate_spot_ask + rate_month7_ask,4),
--      round(rate_spot_bid + rate_month8_bid,4), round(rate_spot_ask + rate_month8_ask,4),
--      round(rate_spot_bid + rate_month9_bid,4), round(rate_spot_ask + rate_month9_ask,4),
--      round(rate_spot_bid + rate_month10_bid,4), round(rate_spot_ask + rate_month10_ask,4),
--      round(rate_spot_bid + rate_month11_bid,4), round(rate_spot_ask + rate_month11_ask,4),
--      round(rate_spot_bid + rate_month12_bid,4), round(rate_spot_ask + rate_month12_ask,4),
--      sysdate, sysdate, rate_entry_detail, rate_record_status
--      from trsystem009
--      where rate_effective_date = AsonDate
--      and rate_serial_number = numSerial
--      and rate_currency_code = numCurrencyCode
--      and rate_for_currency = numForCurrency;
--
--    if numCurrencyCode = GConst.USDOLLAR and numForCurrency = GConst.INDIANRUPEE then
--
--      Delete from trtran012
--      where drat_effective_date = AsonDate
--      and drat_serial_number = numSerial
--      and drat_currency_code = GConst.USDOLLAR
--      and drat_for_currency = GConst.USDOLLAR;
--
--      varOperation := 'Inserting Rate for USD against USD';
--      insert into trtran012(drat_currency_code,drat_for_currency,drat_effective_date,
--        drat_serial_number,drat_rate_time,drat_time_stamp,drat_rate_description,
--        drat_spot_bid,drat_spot_ask, drat_month1_bid,  drat_month1_ask,
--        drat_month2_bid,drat_month2_ask,drat_month3_bid,drat_month3_ask,
--        drat_month4_bid,drat_month4_ask,drat_month5_bid,drat_month5_ask,
--        drat_month6_bid,drat_month6_ask,drat_month7_bid,drat_month7_ask,
--        drat_month8_bid,drat_month8_ask, drat_month9_bid,drat_month9_ask,
--        drat_month10_bid,drat_month10_ask, drat_month11_bid,drat_month11_ask,
--        drat_month12_bid,drat_month12_ask,
--        drat_create_date,drat_add_date,drat_entry_detail,drat_record_status)
--      select GConst.USDOLLAR,  GConst.USDOLLAR,  AsonDate, numSerial,
--        rate_rate_time, rate_time_stamp, rate_rate_description,
--        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
--        sysdate, sysdate, rate_entry_detail, rate_record_status
--        from trsystem009
--        where rate_effective_date = AsonDate
--        and rate_serial_number = numSerial
--        and rate_currency_code = GConst.USDOLLAR
--        and rate_for_currency = GConst.INDIANRUPEE;
--
--      return numError;
--    End if;
--
--    varOperation := 'Checking currency type';
--    select cncy_principal_yn
--      into numType
--      from trmaster304
--      where cncy_pick_code =
--      decode(numForCurrency, GConst.USDOLLAR, numCurrencyCode, numForCurrency);
--
--    varOperation := 'Deleting old record';
--    Delete from trtran012
--      where drat_effective_date = AsonDate
--      and drat_serial_number = numSerial
--      and drat_currency_code =
--      decode(numForCurrency, GConst.USDOLLAR, numCurrencyCode, numForCurrency)
--      and drat_for_currency = GConst.INDIANRUPEE;
--
--    if numType = GConst.OPTIONYES then
--      varOperation := 'Calculating Rates against Local Currency - Stage 1';
--      insert into trtran012(drat_currency_code,drat_for_currency,drat_effective_date,
--        drat_serial_number,drat_rate_time,drat_time_stamp,drat_rate_description,
--        drat_spot_bid,drat_spot_ask, drat_month1_bid,  drat_month1_ask,
--        drat_month2_bid,drat_month2_ask,drat_month3_bid,drat_month3_ask,
--        drat_month4_bid,drat_month4_ask,drat_month5_bid,drat_month5_ask,
--        drat_month6_bid,drat_month6_ask,drat_month7_bid,drat_month7_ask,
--        drat_month8_bid,drat_month8_ask, drat_month9_bid,drat_month9_ask,
--        drat_month10_bid,drat_month10_ask, drat_month11_bid,drat_month11_ask,
--        drat_month12_bid,drat_month12_ask,
--        drat_create_date,drat_add_date,drat_entry_detail,drat_record_status)
--      select a.drat_currency_code, 30400003,a.drat_effective_date,
--        a.drat_serial_number,a.drat_rate_time,a.drat_time_stamp,a.drat_rate_description,
--        round(a.drat_spot_bid * b.drat_spot_bid,4),
--        round(a.drat_spot_ask * b.drat_spot_ask,4),
--        round(a.drat_month1_bid * b.drat_month1_bid,4),
--        round(a.drat_month1_ask * b.drat_month1_ask,4),
--        round(a.drat_month2_bid * b.drat_month2_bid,4),
--        round(a.drat_month2_ask * b.drat_month2_ask,4),
--        round(a.drat_month3_bid * b.drat_month3_bid,4),
--        round(a.drat_month3_ask * b.drat_month3_ask,4),
--        round(a.drat_month4_bid * b.drat_month4_bid,4),
--        round(a.drat_month4_ask * b.drat_month4_ask,4),
--        round(a.drat_month5_bid * b.drat_month5_bid,4),
--        round(a.drat_month5_ask * b.drat_month5_ask,4),
--        round(a.drat_month6_bid * b.drat_month6_bid,4),
--        round(a.drat_month6_ask * b.drat_month6_ask,4),
--        round(a.drat_month7_bid * b.drat_month7_bid,4),
--        round(a.drat_month7_ask * b.drat_month7_ask,4),
--        round(a.drat_month8_bid * b.drat_month8_bid,4),
--        round(a.drat_month8_ask * b.drat_month8_ask,4),
--        round(a.drat_month9_bid * b.drat_month9_bid,4),
--        round(a.drat_month9_ask * b.drat_month9_ask,4),
--        round(a.drat_month10_bid * b.drat_month10_bid,4),
--        round(a.drat_month10_ask * b.drat_month10_ask,4),
--        round(a.drat_month11_bid * b.drat_month11_bid,4),
--        round(a.drat_month11_ask * b.drat_month11_ask,4),
--        round(a.drat_month12_bid * b.drat_month12_bid,4),
--        round(a.drat_month12_ask * b.drat_month12_ask,4),
--        sysdate,sysdate, a.drat_entry_detail, a.drat_record_status
--        from trtran012 a, trtran012 b
--        where a.drat_effective_date = b.drat_effective_date
--        and a.drat_serial_number = b.drat_serial_number
--        and a.drat_effective_date = AsonDate
--        and a.drat_serial_number = numSerial
--        and a.drat_currency_code = numCurrencyCode
--        and a.drat_for_currency = GConst.USDOLLAR
--        and b.drat_currency_code = GConst.USDOLLAR
--        and b.drat_for_currency = GConst.INDIANRUPEE;
--    end if;
--
--
--Begin
--    if numType = GConst.OPTIONNO then
--      varOperation := 'Calculating Rates against Local Currency - Stage 2';
--      insert into trtran012(drat_currency_code,drat_for_currency,drat_effective_date,
--        drat_serial_number,drat_rate_time,drat_time_stamp,drat_rate_description,
--        drat_spot_bid,drat_spot_ask, drat_month1_bid,  drat_month1_ask,
--        drat_month2_bid,drat_month2_ask,drat_month3_bid,drat_month3_ask,
--        drat_month4_bid,drat_month4_ask,drat_month5_bid,drat_month5_ask,
--        drat_month6_bid,drat_month6_ask,drat_month7_bid,drat_month7_ask,
--        drat_month8_bid,drat_month8_ask, drat_month9_bid,drat_month9_ask,
--        drat_month10_bid,drat_month10_ask, drat_month11_bid,drat_month11_ask,
--        drat_month12_bid,drat_month12_ask,
--        drat_create_date,drat_add_date,drat_entry_detail,drat_record_status)
--      select a.drat_for_currency, 30400003,a.drat_effective_date,
--        a.drat_serial_number,a.drat_rate_time,a.drat_time_stamp,a.drat_rate_description,
--        round( b.drat_spot_bid / a.drat_spot_bid,4),
--        round(b.drat_spot_ask / a.drat_spot_ask,4),
--        round(b.drat_month1_bid / a.drat_month1_bid,4),
--        round(b.drat_month1_ask / a.drat_month1_ask,4),
--        round(b.drat_month2_bid / a.drat_month2_bid,4),
--        round(b.drat_month2_ask / a.drat_month2_ask,4),
--        round(b.drat_month3_bid / a.drat_month3_bid,4),
--        round(b.drat_month3_ask / a.drat_month3_ask,4),
--        round(b.drat_month4_bid / a.drat_month4_bid,4),
--        round(b.drat_month4_ask / a.drat_month4_ask,4),
--        round(b.drat_month5_bid / a.drat_month5_bid,4),
--        round(b.drat_month5_ask / a.drat_month5_ask,4),
--        round(b.drat_month6_bid / a.drat_month6_bid,4),
--        round(b.drat_month6_ask / a.drat_month6_ask,4),
--        round(b.drat_month7_bid / a.drat_month7_bid,4),
--        round(b.drat_month7_ask / a.drat_month7_ask,4),
--        round(b.drat_month8_bid / a.drat_month8_bid,4),
--        round(b.drat_month8_ask / a.drat_month8_ask,4),
--        round(b.drat_month9_bid / a.drat_month9_bid,4),
--        round(b.drat_month9_ask / a.drat_month9_ask,4),
--        round(b.drat_month10_bid / a.drat_month10_bid,4),
--        round(b.drat_month10_ask / a.drat_month10_ask,4),
--        round(b.drat_month11_bid / a.drat_month11_bid,4),
--        round(b.drat_month11_ask / a.drat_month11_ask,4),
--        round(b.drat_month12_bid / a.drat_month12_bid,4),
--        round(b.drat_month12_ask / a.drat_month12_ask,4),
--        sysdate,sysdate, a.drat_entry_detail, a.drat_record_status
--        from trtran012 a, trtran012 b
--        where a.drat_effective_date = b.drat_effective_date
--        and a.drat_serial_number = b.drat_serial_number
--        and a.drat_effective_date = AsonDate
--        and a.drat_serial_number = numSerial
--        and a.drat_currency_code = GConst.USDOLLAR
--        and a.drat_for_currency = numForCurrency
--        and b.drat_currency_code = GConst.USDOLLAR
--        and b.drat_for_currency = GConst.INDIANRUPEE;
--    End if;
--Exception
--When Others then
--  NULL;
--End;
--
--    return numError;
--Exception
--    When others then
--      numError := SQLCODE;
--      varError := SQLERRM;
--      varError := GConst.fncReturnError('CalcRate1', numError, varMessage,
--                      varOperation, varError);
--      raise_application_error(-20101, varError);
--      return numError;
--
--End fncCalculateRate;

Function fncCalculateRate
    ( RateDate  Date,
      BaseCurrency in Number,
      ForCurrency in Number,
      SerialNumber in Number)
    Return number
    is
-- Created on 19/10/2012 for the Windows Services Program
    numError            number;
    numSerial           number(5);
    numCurrencyCode     number(8);
    numForCurrency      number(8);
    numType             number(8);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    AsonDate            Date;
    clbTemp             clob;
    xmlTemp             xmltype;
Begin
    varMessage := 'Calculating Rates for : ' || RateDate || ':' ||
      BaseCurrency || ':' || ForCurrency;

    AsonDate := RateDate;
    numCurrencyCode := BaseCurrency;
    numForCurrency := ForCurrency;
    numSerial := SerialNumber;


    varOperation := 'Deleting the existing Rates';
    Delete from trtran012
      where drat_effective_date = AsonDate
      and drat_serial_number = numSerial
      and drat_currency_code = numCurrencyCode
      and drat_for_currency = numForCurrency;

    varOperation := 'Inserting Exchange Rates for USD / Other Currencies';
    insert into trtran012(drat_currency_code,drat_for_currency,drat_effective_date,
      drat_serial_number,drat_rate_time,drat_time_stamp,drat_rate_description,
      drat_spot_bid,drat_spot_ask, drat_month1_bid,  drat_month1_ask,
      drat_month2_bid,drat_month2_ask,drat_month3_bid,drat_month3_ask,
      drat_month4_bid,drat_month4_ask,drat_month5_bid,drat_month5_ask,
      drat_month6_bid,drat_month6_ask,drat_month7_bid,drat_month7_ask,
      drat_month8_bid,drat_month8_ask, drat_month9_bid,drat_month9_ask,
      drat_month10_bid,drat_month10_ask, drat_month11_bid,drat_month11_ask,
      drat_month12_bid,drat_month12_ask,
      drat_create_date,drat_add_date,drat_entry_detail,drat_record_status,
      DRAT_CASH_ASK,DRAT_CASH_BID,DRAT_TOM_ASK,DRAT_TOM_BID)
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
      sysdate, sysdate, rate_entry_detail, rate_record_status,
      round(rate_spot_ask,4), round(rate_spot_bid,4),
      round(rate_spot_ask,4), round(rate_spot_bid,4) 
      from trsystem009
      where rate_effective_date = AsonDate
      and rate_serial_number = numSerial
      and rate_currency_code = numCurrencyCode
      and rate_for_currency = numForCurrency;

    if numCurrencyCode = GConst.USDOLLAR and numForCurrency = GConst.INDIANRUPEE then

      Delete from trtran012
      where drat_effective_date = AsonDate
      and drat_serial_number = numSerial
      and drat_currency_code = GConst.USDOLLAR
      and drat_for_currency = GConst.USDOLLAR;

      varOperation := 'Inserting Rate for USD against USD';
      insert into trtran012(drat_currency_code,drat_for_currency,drat_effective_date,
        drat_serial_number,drat_rate_time,drat_time_stamp,drat_rate_description,
        drat_spot_bid,drat_spot_ask, drat_month1_bid,  drat_month1_ask,
        drat_month2_bid,drat_month2_ask,drat_month3_bid,drat_month3_ask,
        drat_month4_bid,drat_month4_ask,drat_month5_bid,drat_month5_ask,
        drat_month6_bid,drat_month6_ask,drat_month7_bid,drat_month7_ask,
        drat_month8_bid,drat_month8_ask, drat_month9_bid,drat_month9_ask,
        drat_month10_bid,drat_month10_ask, drat_month11_bid,drat_month11_ask,
        drat_month12_bid,drat_month12_ask,
        drat_create_date,drat_add_date,drat_entry_detail,drat_record_status,
        DRAT_CASH_ASK,DRAT_CASH_BID,DRAT_TOM_ASK,DRAT_TOM_BID)
      select GConst.USDOLLAR,  GConst.USDOLLAR,  AsonDate, numSerial,
        rate_rate_time, rate_time_stamp, rate_rate_description,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        sysdate, sysdate, rate_entry_detail, rate_record_status,1,1,1,1
        from trsystem009
        where rate_effective_date = AsonDate
        and rate_serial_number = numSerial
        and rate_currency_code = GConst.USDOLLAR
        and rate_for_currency = GConst.INDIANRUPEE;

      return numError;
    End if;

    varOperation := 'Checking currency type';
    select cncy_principal_yn
      into numType
      from trmaster304
      where cncy_pick_code =
      decode(numForCurrency, GConst.USDOLLAR, numCurrencyCode, numForCurrency);

    varOperation := 'Deleting old record';
    Delete from trtran012
      where drat_effective_date = AsonDate
      and drat_serial_number = numSerial
      and drat_currency_code =
      decode(numForCurrency, GConst.USDOLLAR, numCurrencyCode, numForCurrency)
      and drat_for_currency = GConst.INDIANRUPEE;

    if numType = GConst.OPTIONYES then
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
        drat_create_date,drat_add_date,drat_entry_detail,drat_record_status,
        DRAT_CASH_ASK,DRAT_CASH_BID,DRAT_TOM_ASK,DRAT_TOM_BID)
      select a.drat_currency_code, 30400003,a.drat_effective_date,
        a.drat_serial_number,a.drat_rate_time,a.drat_time_stamp,a.drat_rate_description,
        round(a.drat_spot_bid * b.drat_spot_bid,4),
        round(a.drat_spot_ask * b.drat_spot_ask,4),
        round(a.drat_month1_bid * b.drat_month1_bid,4),
        round(a.drat_month1_ask * b.drat_month1_ask,4),
        round(a.drat_month2_bid * b.drat_month2_bid,4),
        round(a.drat_month2_ask * b.drat_month2_ask,4),
        round(a.drat_month3_bid * b.drat_month3_bid,4),
        round(a.drat_month3_ask * b.drat_month3_ask,4),
        round(a.drat_month4_bid * b.drat_month4_bid,4),
        round(a.drat_month4_ask * b.drat_month4_ask,4),
        round(a.drat_month5_bid * b.drat_month5_bid,4),
        round(a.drat_month5_ask * b.drat_month5_ask,4),
        round(a.drat_month6_bid * b.drat_month6_bid,4),
        round(a.drat_month6_ask * b.drat_month6_ask,4),
        round(a.drat_month7_bid * b.drat_month7_bid,4),
        round(a.drat_month7_ask * b.drat_month7_ask,4),
        round(a.drat_month8_bid * b.drat_month8_bid,4),
        round(a.drat_month8_ask * b.drat_month8_ask,4),
        round(a.drat_month9_bid * b.drat_month9_bid,4),
        round(a.drat_month9_ask * b.drat_month9_ask,4),
        round(a.drat_month10_bid * b.drat_month10_bid,4),
        round(a.drat_month10_ask * b.drat_month10_ask,4),
        round(a.drat_month11_bid * b.drat_month11_bid,4),
        round(a.drat_month11_ask * b.drat_month11_ask,4),
        round(a.drat_month12_bid * b.drat_month12_bid,4),
        round(a.drat_month12_ask * b.drat_month12_ask,4),
        sysdate,sysdate, a.drat_entry_detail, a.drat_record_status,
        round(a.drat_spot_ask * b.drat_spot_ask,4), 
        round(a.drat_spot_bid * b.drat_spot_bid,4),
        round(a.drat_spot_ask * b.drat_spot_ask,4), 
        round(a.drat_spot_bid * b.drat_spot_bid,4)
        from trtran012 a, trtran012 b
        where a.drat_effective_date = b.drat_effective_date
        and a.drat_serial_number = b.drat_serial_number
        and a.drat_effective_date = AsonDate
        and a.drat_serial_number = numSerial
        and a.drat_currency_code = numCurrencyCode
        and a.drat_for_currency = GConst.USDOLLAR
        and b.drat_currency_code = GConst.USDOLLAR
        and b.drat_for_currency = GConst.INDIANRUPEE;
    end if;


Begin
    if numType = GConst.OPTIONNO then
      varOperation := 'Calculating Rates against Local Currency - Stage 2';
      insert into trtran012(drat_currency_code,drat_for_currency,drat_effective_date,
        drat_serial_number,drat_rate_time,drat_time_stamp,drat_rate_description,
        drat_spot_bid,drat_spot_ask, drat_month1_bid,  drat_month1_ask,
        drat_month2_bid,drat_month2_ask,drat_month3_bid,drat_month3_ask,
        drat_month4_bid,drat_month4_ask,drat_month5_bid,drat_month5_ask,
        drat_month6_bid,drat_month6_ask,drat_month7_bid,drat_month7_ask,
        drat_month8_bid,drat_month8_ask, drat_month9_bid,drat_month9_ask,
        drat_month10_bid,drat_month10_ask, drat_month11_bid,drat_month11_ask,
        drat_month12_bid,drat_month12_ask,
        drat_create_date,drat_add_date,drat_entry_detail,drat_record_status,
        DRAT_CASH_ASK,DRAT_CASH_BID,DRAT_TOM_ASK,DRAT_TOM_BID)
      select a.drat_for_currency, 30400003,a.drat_effective_date,
        a.drat_serial_number,a.drat_rate_time,a.drat_time_stamp,a.drat_rate_description,
        round( b.drat_spot_bid / a.drat_spot_bid,4),
        round(b.drat_spot_ask / a.drat_spot_ask,4),
        round(b.drat_month1_bid / a.drat_month1_bid,4),
        round(b.drat_month1_ask / a.drat_month1_ask,4),
        round(b.drat_month2_bid / a.drat_month2_bid,4),
        round(b.drat_month2_ask / a.drat_month2_ask,4),
        round(b.drat_month3_bid / a.drat_month3_bid,4),
        round(b.drat_month3_ask / a.drat_month3_ask,4),
        round(b.drat_month4_bid / a.drat_month4_bid,4),
        round(b.drat_month4_ask / a.drat_month4_ask,4),
        round(b.drat_month5_bid / a.drat_month5_bid,4),
        round(b.drat_month5_ask / a.drat_month5_ask,4),
        round(b.drat_month6_bid / a.drat_month6_bid,4),
        round(b.drat_month6_ask / a.drat_month6_ask,4),
        round(b.drat_month7_bid / a.drat_month7_bid,4),
        round(b.drat_month7_ask / a.drat_month7_ask,4),
        round(b.drat_month8_bid / a.drat_month8_bid,4),
        round(b.drat_month8_ask / a.drat_month8_ask,4),
        round(b.drat_month9_bid / a.drat_month9_bid,4),
        round(b.drat_month9_ask / a.drat_month9_ask,4),
        round(b.drat_month10_bid / a.drat_month10_bid,4),
        round(b.drat_month10_ask / a.drat_month10_ask,4),
        round(b.drat_month11_bid / a.drat_month11_bid,4),
        round(b.drat_month11_ask / a.drat_month11_ask,4),
        round(b.drat_month12_bid / a.drat_month12_bid,4),
        round(b.drat_month12_ask / a.drat_month12_ask,4),
        sysdate,sysdate, a.drat_entry_detail, a.drat_record_status,
        round(b.drat_spot_ask / a.drat_spot_ask,4),
        round( b.drat_spot_bid / a.drat_spot_bid,4),
        round(b.drat_spot_ask / a.drat_spot_ask,4),       
        round( b.drat_spot_bid / a.drat_spot_bid,4)
        from trtran012 a, trtran012 b
        where a.drat_effective_date = b.drat_effective_date
        and a.drat_serial_number = b.drat_serial_number
        and a.drat_effective_date = AsonDate
        and a.drat_serial_number = numSerial
        and a.drat_currency_code = GConst.USDOLLAR
        and a.drat_for_currency = numForCurrency
        and b.drat_currency_code = GConst.USDOLLAR
        and b.drat_for_currency = GConst.INDIANRUPEE;
    End if;
Exception
When Others then
  NULL;
End;

    return numError;
Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('CalcRate1', numError, varMessage,
                      varOperation, varError);
      raise_application_error(-20101, varError);
      return numError;

End fncCalculateRate;

Function fncCalculateRate
    ( RateDetail in clob)
    return number
    is
--  Created on 27/03/2008
    numError            number;
    numSerial           number(5);
    numCurrencyCode     number(8);
    numForCurrency      number(8);
    numType             number(8);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    AsonDate            Date;
    clbTemp             clob;
    xmlTemp             xmltype;
Begin
    varMessage := 'Calculating Rates for : ' || AsonDate;
    dbms_lob.createTemporary (clbTemp,  TRUE);
    clbTemp := RateDetail;

    numError := 1;
    varOperation := 'Extracting Input Parameters';
    xmlTemp := xmlType(RateDetail);

    AsonDate := GConst.fncXMLExtract(xmlTemp, 'RATE_EFFECTIVE_DATE', AsonDate);
    numCurrencyCode := GConst.fncXMLExtract(xmlTemp, 'RATE_CURRENCY_CODE', numCurrencyCode);
    numForCurrency := GConst.fncXMLExtract(xmlTemp, 'RATE_FOR_CURRENCY', numForCurrency);
    numSerial := GConst.fncXMLExtract(xmlTemp, 'RATE_SERIAL_NUMBER', numSerial);

--    if RateSerial = 0 then
--      varOperation := 'Extracting the maximum Serial';
--      select NVL(max(rate_serial_number),0)
--        into numSerial
--        from trsystem009
--        where rate_effective_date = AsonDate
--        and rate_record_status in
--        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--    else
--      numSerial := RateSerial;
--    end if;
--
--    if numSerial = 0 then
--      varError := 'Rates not fed for the date : ' || AsonDate || ' Cannot continue';
--      numError := -20101;
--      Raise_application_error(numError, varError);
--      return numError;
--    end if;

    varOperation := 'Deleting the existing Rates';
    Delete from trtran012
      where drat_effective_date = AsonDate
      and drat_serial_number = numSerial
      and drat_currency_code = numCurrencyCode
      and drat_for_currency = numForCurrency;

    varOperation := 'Inserting Exchange Rates for USD / Other Currencies';
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
      where rate_effective_date = AsonDate
      and rate_serial_number = numSerial
      and rate_currency_code = numCurrencyCode
      and rate_for_currency = numForCurrency;

    if numCurrencyCode = GConst.USDOLLAR and numForCurrency = GConst.INDIANRUPEE then

      Delete from trtran012
      where drat_effective_date = AsonDate
      and drat_serial_number = numSerial
      and drat_currency_code = GConst.USDOLLAR
      and drat_for_currency = GConst.USDOLLAR;

      varOperation := 'Inserting Rate for USD against USD';
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

      return numError;
    End if;

    varOperation := 'Checking currency type';
    select cncy_principal_yn
      into numType
      from trmaster304
      where cncy_pick_code =
      decode(numForCurrency, GConst.USDOLLAR, numCurrencyCode, numForCurrency);

    varOperation := 'Deleting old record';
    Delete from trtran012
      where drat_effective_date = AsonDate
      and drat_serial_number = numSerial
      and drat_currency_code =
      decode(numForCurrency, GConst.USDOLLAR, numCurrencyCode, numForCurrency)
      and drat_for_currency = GConst.INDIANRUPEE;

    if numType = GConst.OPTIONYES then
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
      select a.drat_currency_code, 30400003,a.drat_effective_date,
        a.drat_serial_number,a.drat_rate_time,a.drat_time_stamp,a.drat_rate_description,
        round(a.drat_spot_bid * b.drat_spot_bid,4),
        round(a.drat_spot_ask * b.drat_spot_ask,4),
        round(a.drat_month1_bid * b.drat_month1_bid,4),
        round(a.drat_month1_ask * b.drat_month1_ask,4),
        round(a.drat_month2_bid * b.drat_month2_bid,4),
        round(a.drat_month2_ask * b.drat_month2_ask,4),
        round(a.drat_month3_bid * b.drat_month3_bid,4),
        round(a.drat_month3_ask * b.drat_month3_ask,4),
        round(a.drat_month4_bid * b.drat_month4_bid,4),
        round(a.drat_month4_ask * b.drat_month4_ask,4),
        round(a.drat_month5_bid * b.drat_month5_bid,4),
        round(a.drat_month5_ask * b.drat_month5_ask,4),
        round(a.drat_month6_bid * b.drat_month6_bid,4),
        round(a.drat_month6_ask * b.drat_month6_ask,4),
        round(a.drat_month7_bid * b.drat_month7_bid,4),
        round(a.drat_month7_ask * b.drat_month7_ask,4),
        round(a.drat_month8_bid * b.drat_month8_bid,4),
        round(a.drat_month8_ask * b.drat_month8_ask,4),
        round(a.drat_month9_bid * b.drat_month9_bid,4),
        round(a.drat_month9_ask * b.drat_month9_ask,4),
        round(a.drat_month10_bid * b.drat_month10_bid,4),
        round(a.drat_month10_ask * b.drat_month10_ask,4),
        round(a.drat_month11_bid * b.drat_month11_bid,4),
        round(a.drat_month11_ask * b.drat_month11_ask,4),
        round(a.drat_month12_bid * b.drat_month12_bid,4),
        round(a.drat_month12_ask * b.drat_month12_ask,4),
        sysdate,sysdate, a.drat_entry_detail, a.drat_record_status
        from trtran012 a, trtran012 b
        where a.drat_effective_date = b.drat_effective_date
        and a.drat_serial_number = b.drat_serial_number
        and a.drat_effective_date = AsonDate
        and a.drat_serial_number = numSerial
        and a.drat_currency_code = numCurrencyCode
        and a.drat_for_currency = GConst.USDOLLAR
        and b.drat_currency_code = GConst.USDOLLAR
        and b.drat_for_currency = GConst.INDIANRUPEE;
    end if;

--    varOperation := 'Calculating Rates against USD - Stage 2';
--    insert into trtran012(drat_currency_code,drat_for_currency,drat_effective_date,
--      drat_serial_number,drat_rate_time,drat_time_stamp,drat_rate_description,
--      drat_spot_bid,drat_spot_ask, drat_month1_bid,  drat_month1_ask,
--      drat_month2_bid,drat_month2_ask,drat_month3_bid,drat_month3_ask,
--      drat_month4_bid,drat_month4_ask,drat_month5_bid,drat_month5_ask,
--      drat_month6_bid,drat_month6_ask,drat_month7_bid,drat_month7_ask,
--      drat_month8_bid,drat_month8_ask, drat_month9_bid,drat_month9_ask,
--      drat_month10_bid,drat_month10_ask, drat_month11_bid,drat_month11_ask,
--      drat_month12_bid,drat_month12_ask,
--      drat_create_date,drat_add_date,drat_entry_detail,drat_record_status)
--    select a.drat_currency_code, 30400004,a.drat_effective_date,
--      a.drat_serial_number,a.drat_rate_time,a.drat_time_stamp,a.drat_rate_description,
--      round(a.drat_spot_bid / b.drat_spot_bid,4),
--      round(a.drat_spot_ask / b.drat_spot_ask,4),
--      round(a.drat_month1_bid / b.drat_spot_bid,4),
--      round(a.drat_month1_ask / b.drat_spot_ask,4),
--      round(a.drat_month2_bid / b.drat_spot_bid,4),
--      round(a.drat_month2_ask / b.drat_spot_ask,4),
--      round(a.drat_month3_bid / b.drat_spot_bid,4),
--      round(a.drat_month3_ask / b.drat_spot_ask,4),
--      round(a.drat_month4_bid / b.drat_spot_bid,4),
--      round(a.drat_month4_ask / b.drat_spot_ask,4),
--      round(a.drat_month5_bid / b.drat_spot_bid,4),
--      round(a.drat_month5_ask / b.drat_spot_ask,4),
--      round(a.drat_month6_bid / b.drat_spot_bid,4),
--      round(a.drat_month6_ask / b.drat_spot_ask,4),
--      round(a.drat_month7_bid / b.drat_spot_bid,4),
--      round(a.drat_month7_ask / b.drat_spot_ask,4),
--      round(a.drat_month8_bid / b.drat_spot_bid,4),
--      round(a.drat_month8_ask / b.drat_spot_ask,4),
--      round(a.drat_month9_bid / b.drat_spot_bid,4),
--      round(a.drat_month9_ask / b.drat_spot_ask,4),
--      round(a.drat_month10_bid / b.drat_spot_bid,4),
--      round(a.drat_month10_ask / b.drat_spot_ask,4),
--      round(a.drat_month11_bid / b.drat_spot_bid,4),
--      round(a.drat_month11_ask / b.drat_spot_ask,4),
--      round(a.drat_month12_bid / b.drat_spot_bid,4),
--      round(a.drat_month12_ask / b.drat_spot_ask,4),
--      sysdate,sysdate, a.drat_entry_detail, a.drat_record_status
--      from trtran012 a, trtran012 b
--      where a.drat_effective_date = b.drat_effective_date
--      and a.drat_effective_date = AsonDate
--      and a.drat_serial_number = numSerial
--      and a.drat_for_currency = numCurrencyCode
--      and a.drat_currency_code in
--      (select cncy_pick_code
--        from trmaster304
--        where cncy_principal_yn = GConst.OPTIONYES
--        and cncy_pick_code != GConst.USDOLLAR)
--      and b.drat_currency_code = GConst.USDOLLAR
--      and b.drat_for_currency = GConst.INDIANRUPEE
--      and b.drat_serial_number = numSerial;


    if numType = GConst.OPTIONNO then
      varOperation := 'Calculating Rates against Local Currency - Stage 2';
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
      select a.drat_for_currency, 30400003,a.drat_effective_date,
        a.drat_serial_number,a.drat_rate_time,a.drat_time_stamp,a.drat_rate_description,
        round( b.drat_spot_bid / a.drat_spot_bid,4),
        round(b.drat_spot_ask / a.drat_spot_ask,4),
        round(b.drat_month1_bid / a.drat_month1_bid,4),
        round(b.drat_month1_ask / a.drat_month1_ask,4),
        round(b.drat_month2_bid / a.drat_month2_bid,4),
        round(b.drat_month2_ask / a.drat_month2_ask,4),
        round(b.drat_month3_bid / a.drat_month3_bid,4),
        round(b.drat_month3_ask / a.drat_month3_ask,4),
        round(b.drat_month4_bid / a.drat_month4_bid,4),
        round(b.drat_month4_ask / a.drat_month4_ask,4),
        round(b.drat_month5_bid / a.drat_month5_bid,4),
        round(b.drat_month5_ask / a.drat_month5_ask,4),
        round(b.drat_month6_bid / a.drat_month6_bid,4),
        round(b.drat_month6_ask / a.drat_month6_ask,4),
        round(b.drat_month7_bid / a.drat_month7_bid,4),
        round(b.drat_month7_ask / a.drat_month7_ask,4),
        round(b.drat_month8_bid / a.drat_month8_bid,4),
        round(b.drat_month8_ask / a.drat_month8_ask,4),
        round(b.drat_month9_bid / a.drat_month9_bid,4),
        round(b.drat_month9_ask / a.drat_month9_ask,4),
        round(b.drat_month10_bid / a.drat_month10_bid,4),
        round(b.drat_month10_ask / a.drat_month10_ask,4),
        round(b.drat_month11_bid / a.drat_month11_bid,4),
        round(b.drat_month11_ask / a.drat_month11_ask,4),
        round(b.drat_month12_bid / a.drat_month12_bid,4),
        round(b.drat_month12_ask / a.drat_month12_ask,4),
        sysdate,sysdate, a.drat_entry_detail, a.drat_record_status
        from trtran012 a, trtran012 b
        where a.drat_effective_date = b.drat_effective_date
        and a.drat_serial_number = b.drat_serial_number
        and a.drat_effective_date = AsonDate
        and a.drat_serial_number = numSerial
        and a.drat_currency_code = GConst.USDOLLAR
        and a.drat_for_currency = numForCurrency
        and b.drat_currency_code = GConst.USDOLLAR
        and b.drat_for_currency = GConst.INDIANRUPEE;
    End if;

--    varOperation := 'Calculating Rates against USD - Stage 4';
--    insert into trtran012(drat_currency_code,drat_for_currency,drat_effective_date,
--      drat_serial_number,drat_rate_time,drat_time_stamp,drat_rate_description,
--      drat_spot_bid,drat_spot_ask, drat_month1_bid,  drat_month1_ask,
--      drat_month2_bid,drat_month2_ask,drat_month3_bid,drat_month3_ask,
--      drat_month4_bid,drat_month4_ask,drat_month5_bid,drat_month5_ask,
--      drat_month6_bid,drat_month6_ask,drat_month7_bid,drat_month7_ask,
--      drat_month8_bid,drat_month8_ask, drat_month9_bid,drat_month9_ask,
--      drat_month10_bid,drat_month10_ask, drat_month11_bid,drat_month11_ask,
--      drat_month12_bid,drat_month12_ask,
--      drat_create_date,drat_add_date,drat_entry_detail,drat_record_status)
--    select 30400004, a.drat_currency_code,a.drat_effective_date,
--      a.drat_serial_number,a.drat_rate_time,a.drat_time_stamp,a.drat_rate_description,
--      round(b.drat_spot_bid / a.drat_spot_bid,4),
--      round(b.drat_spot_ask / a.drat_spot_ask,4),
--      round(b.drat_spot_bid /a.drat_month1_bid,4),
--      round(b.drat_spot_ask / a.drat_month1_ask ,4),
--      round(b.drat_spot_bid / a.drat_month2_bid,4),
--      round(b.drat_spot_ask / a.drat_month2_ask,4),
--      round(b.drat_spot_bid / a.drat_month3_bid,4),
--      round(b.drat_spot_ask / a.drat_month3_ask,4),
--      round(b.drat_spot_bid / a.drat_month4_bid,4),
--      round(b.drat_spot_ask / a.drat_month4_ask,4),
--      round(b.drat_spot_bid / a.drat_month5_bid,4),
--      round(b.drat_spot_ask / a.drat_month5_ask,4),
--      round(b.drat_spot_bid / a.drat_month6_bid,4),
--      round(b.drat_spot_ask / a.drat_month6_ask,4),
--      round(b.drat_spot_bid / a.drat_month7_bid,4),
--      round(b.drat_spot_ask / a.drat_month7_ask,4),
--      round(b.drat_spot_bid / a.drat_month8_bid,4),
--      round(b.drat_spot_ask / a.drat_month8_ask,4),
--      round(b.drat_spot_bid / a.drat_month9_bid,4),
--      round(b.drat_spot_ask / a.drat_month9_ask,4),
--      round(b.drat_spot_bid / a.drat_month10_bid,4),
--      round(b.drat_spot_ask / a.drat_month10_ask,4),
--      round(b.drat_spot_bid / a.drat_month11_bid,4),
--      round(b.drat_spot_ask / a.drat_month11_ask,4),
--      round(b.drat_spot_bid / a.drat_month12_bid,4),
--      round(b.drat_spot_ask / a.drat_month12_ask,4),
--      sysdate,sysdate, a.drat_entry_detail, a.drat_record_status
--      from trtran012 a, trtran012 b
--      where a.drat_effective_date = b.drat_effective_date
--      and a.drat_effective_date = AsonDate
--      and a.drat_serial_number = numSerial
--      and a.drat_currency_code in
--      (select cncy_pick_code
--        from trmaster304
--        where cncy_principal_yn = GConst.OPTIONNO
--        and cncy_pick_code != GConst.INDIANRUPEE)
--      and b.drat_currency_code = GConst.USDOLLAR
--      and b.drat_for_currency = GConst.INDIANRUPEE
--      and b.drat_serial_number = numSerial;

    return numError;
Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('CalcRate', numError, varMessage,
                      varOperation, varError);
      raise_application_error(-20101, varError);
      return numError;

End fncCalculateRate;


--Function fncCalculateRate
--    ( AsonDate in Date,
--      RateSerial in number := 0)
--    return number
--    is
----  Created on 27/03/2008
--    numError            number;
--    numSerial           number(5);
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--
--Begin
--    varMessage := 'Calculating Rates for : ' || AsonDate;
--
--    if RateSerial = 0 then
--      varOperation := 'Extracting the maximum Serial';
--      select NVL(max(rate_serial_number),0)
--        into numSerial
--        from trsystem009
--        where rate_effective_date = AsonDate
--        and rate_record_status in
--        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--    else
--      numSerial := RateSerial;
--    end if;
--
--    if numSerial = 0 then
--      varError := 'Rates not fed for the date : ' || AsonDate || ' Cannot continue';
--      numError := -20101;
--      Raise_application_error(numError, varError);
--      return numError;
--    end if;
--
--    varOperation := 'Deleting the existing Rates';
--    Delete from trtran012
--    where drat_effective_date = AsonDate
--    and drat_serial_number = numSerial;
--
--    varOperation := 'Inserting Rates for Currencies Against USD';
--    insert into trtran012(drat_currency_code,drat_for_currency,drat_effective_date,
--      drat_serial_number,drat_rate_time,drat_time_stamp,drat_rate_description,
--      drat_spot_bid,drat_spot_ask,drat_month1_bid,drat_month1_ask,
--      drat_month2_bid,drat_month2_ask,drat_month3_bid,drat_month3_ask,
--      drat_month6_bid,drat_month6_ask,drat_month9_bid,drat_month9_ask,
--      drat_month12_bid,drat_month12_ask,
--      drat_create_date,drat_add_date,drat_entry_detail,drat_record_status)
--      select rate_currency_code BaseCurrency, rate_for_currency OtherCurrency, rate_effective_date,
--      numSerial, rate_rate_time, rate_time_stamp, rate_rate_description,
--      round(rate_spot_bid,4) BidSpot, round(rate_spot_ask,4) AskSpot,
--      round(rate_spot_bid + rate_month1_bid,4), round(rate_spot_ask + rate_month1_ask,4),
--      round(rate_spot_bid + rate_month2_bid,4), round(rate_spot_ask + rate_month2_ask,4),
--      round(rate_spot_bid + rate_month3_bid,4), round(rate_spot_ask + rate_month3_ask,4),
--      round(rate_spot_bid + rate_month6_bid,4), round(rate_spot_ask + rate_month6_ask,4),
--      round(rate_spot_bid + rate_month9_bid,4), round(rate_spot_ask + rate_month9_ask,4),
--      round(rate_spot_bid + rate_month12_bid,4), round(rate_spot_ask + rate_month12_ask,4),
--      sysdate, sysdate, rate_entry_detail, rate_record_status
--      from trsystem009
--      where rate_effective_date = AsonDate
--      and rate_serial_number = numSerial;
--
--    varOperation := 'Calculating Rates against Local Currency - Stage 1';
--    insert into trtran012(drat_currency_code,drat_for_currency,drat_effective_date,
--      drat_serial_number,drat_rate_time,drat_time_stamp,drat_rate_description,
--      drat_spot_bid,drat_spot_ask,drat_month1_bid,drat_month1_ask,
--      drat_month2_bid,drat_month2_ask,drat_month3_bid,drat_month3_ask,
--      drat_month6_bid,drat_month6_ask,drat_month9_bid,drat_month9_ask,
--      drat_month12_bid,drat_month12_ask,
--      drat_create_date,drat_add_date,drat_entry_detail,drat_record_status)
--    select a.drat_currency_code, 30400003,a.drat_EFFECTIVE_DATE,
--      a.drat_serial_number,a.drat_rate_time,a.drat_time_stamp,a.drat_rate_description,
--      round(a.drat_SPOT_BID * b.drat_SPOT_BID,4),
--      round(a.drat_SPOT_ASK * b.drat_SPOT_ASK,4),
--      round(a.drat_MONTH1_BID * b.drat_MONTH1_BID,4),
--      round(a.drat_MONTH1_ASK * b.drat_MONTH1_ASK,4),
--      round(a.drat_MONTH2_BID * b.drat_MONTH2_BID,4),
--      round(a.drat_MONTH2_ASK * b.drat_MONTH2_ASK,4),
--      round(a.drat_MONTH3_BID * b.drat_MONTH3_BID,4),
--      round(a.drat_MONTH3_ASK * b.drat_MONTH3_ASK,4),
--      round(a.drat_MONTH6_BID * b.drat_MONTH6_BID,4),
--      round(a.drat_MONTH6_ASK * b.drat_MONTH6_ASK,4),
--      round(a.drat_MONTH9_BID * b.drat_MONTH9_BID,4),
--      round(a.drat_MONTH9_ASK * b.drat_MONTH9_ASK,4),
--      round(a.drat_MONTH12_BID * b.drat_MONTH12_BID,4),
--      round(a.drat_MONTH12_ASK * b.drat_MONTH12_ASK,4),
--      sysdate,sysdate, a.drat_entry_detail, a.drat_record_status
--      from trtran012 a, trtran012 b
--      where a.drat_effective_date = b.drat_effective_date
--      and a.drat_effective_date = AsonDate
--      and a.drat_serial_number = numSerial
--      and a.drat_currency_code in
--      (select cncy_pick_code
--        from trmaster304
--        where cncy_principal_yn = GConst.OPTIONYES
--        and cncy_pick_code != GConst.USDOLLAR)
--      and b.drat_for_currency = GConst.INDIANRUPEE;
--
--
--    varOperation := 'Calculating Rates against Local Currency - Stage 2';
--
--    insert into trtran012(drat_currency_code,drat_for_currency,drat_effective_date,
--      drat_serial_number,drat_rate_time,drat_time_stamp,drat_rate_description,
--      drat_spot_bid,drat_spot_ask,drat_month1_bid,drat_month1_ask,
--      drat_month2_bid,drat_month2_ask,drat_month3_bid,drat_month3_ask,
--      drat_month6_bid,drat_month6_ask,drat_month9_bid,drat_month9_ask,
--      drat_month12_bid,drat_month12_ask,
--      drat_create_date,drat_add_date,drat_entry_detail,drat_record_status)
--    select a.drat_for_currency, 30400003, a.drat_EFFECTIVE_DATE,
--      a.drat_serial_number,a.drat_rate_time,a.drat_time_stamp,a.drat_rate_description,
--      round(b.drat_spot_bid / a.DRAT_SPOT_BID,4),
--      round(b.DRAT_SPOT_ASK / a.DRAT_SPOT_ASK,4),
--      round(b.DRAT_MONTH1_BID / a.DRAT_MONTH1_BID,4),
--      round(b.DRAT_MONTH1_ASK / a.DRAT_MONTH1_ASK,4),
--      round(b.DRAT_MONTH2_BID / a.DRAT_MONTH2_BID,4),
--      round(b.DRAT_MONTH2_ASK / a.DRAT_MONTH2_ASK,4),
--      round(b.DRAT_MONTH3_BID / a.DRAT_MONTH3_BID,4),
--      round(b.DRAT_MONTH3_ASK / a.DRAT_MONTH3_ASK,4),
--      round(b.DRAT_MONTH6_BID / a.DRAT_MONTH6_BID,4),
--      round(b.DRAT_MONTH6_ASK / a.DRAT_MONTH6_ASK,4),
--      round(b.DRAT_MONTH9_BID / a.DRAT_MONTH9_BID,4),
--      round(b.DRAT_MONTH9_ASK / a.DRAT_MONTH9_ASK,4),
--      round(b.DRAT_MONTH12_BID / a.DRAT_MONTH12_BID,4),
--      round(b.DRAT_MONTH12_ASK / a.DRAT_MONTH12_ASK,4),
--      sysdate, sysdate,a.drat_entry_detail, a.drat_record_status
--      from trtran012 a, trtran012 b
--      where a.drat_effective_date = b.drat_effective_date
--      and a.drat_effective_date = AsonDate
--      and a.drat_serial_number = numSerial
--      and a.drat_currency_code not in
--      (select cncy_pick_code
--        from trmaster304
--        where cncy_principal_yn = GConst.OPTIONYES
--        and cncy_pick_code != GConst.USDOLLAR)
--      and a.drat_for_currency not in (GConst.INDIANRUPEE, GConst.USDOLLAR)
--      and b.drat_currency_code = GConst.USDOLLAR
--      and b.drat_for_currency = GConst.INDIANRUPEE;
--
--    return numError;
--Exception
--    When others then
--      numError := SQLCODE;
--      varError := SQLERRM;
--      varError := GConst.fncReturnError('CalcRate', numError, varMessage,
--                      varOperation, varError);
--      raise_application_error(-20101, varError);
--      return numError;
--
--End fncCalculateRate;

Function fncGetOutstanding
    ( TradeReference in varchar2,
      TradeSerial in number,
      ReversalType in number,
      AmountType in number,
      AsonDate in Date,
  --    DealReference in varchar2 := NULL)
    DealReference in varchar2,
    subSerial in number default 0)
      return Number
      is
--  Created on 28/05/08
    numError        number;
    numCode         number(8);
    numFcy          number(15,4);
    numUtilFcy      number(15,4);
    numOutFcy       number(15,4);
    numInr          number(15,2);
    numUtilInr      number(15,2);
    numOutInr       number(15,2);
    numAmount       number(15,4);
    OrderTemp       varchar(25);
    numTemp         number(15,2);
    numTemp1         number(15,2);
    varOperation    gconst.gvaroperation%type;
    varMessage      gconst.gvarmessage%type;
    varError        gconst.gvarerror%type;
Begin
    varMessage := 'Arriving outstanding for ' || TradeReference;
    numOutFcy := 0.00;
    numOutInr := 0.00;
    numAmount := 0.00;
    numError := 0.00;
    numFcy :=0.00;
    numUtilFcy :=0.00;
    numInr :=0.00;
    numUtilInr := 0.00;
-- Sum is used in the following queries to get the trade / deal amount
-- and avoid raising data_not_found error if the instrument has come into
-- existance after the as on date
    if  ReversalType = GConst.UTILTRADEDEAL then
      varOperation := 'Extracting Deal Amount for trade deal';
      Begin
          select deal_other_currency, deal_base_amount,(deal_base_amount*deal_exchange_rate)
          
--            decode(deal_other_currency, GConst.INDIANRUPEE,
--              deal_other_amount, deal_amount_local)
            into numCode, numFcy, numInr
            from trtran001
            where deal_deal_number = TradeReference
            and deal_serial_number = TradeSerial
            and deal_execute_date <= AsonDate;
      Exception
        when no_data_found then
          Goto Process_End;
      End;

      varOperation := 'Extracting Trade Deal Delivery Amount';
      select nvl(sum(cdel_cancel_amount),0),sum(cdel_cancel_amount*Cdel_cancel_rate)
       -- nvl(sum(decode(numCode, GConst.INDIANRUPEE, cdel_other_amount,cdel_cancel_inr)),0)
        into numUtilFcy, numUtilInr
        from trtran006
        where cdel_deal_number = TradeReference
      --  and cdel_deal_serial = TradeSerial
        and cdel_cancel_date <= AsonDate
        And Cdel_Record_Status In
        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED); --Updated From Cygnet
-- here reversal type  OUTSTHEDGEDEAL is for geting actual hedge deal outstanding
-- with out considering hedge amount

-- here reversal type  UTILHEDGEDEAL is for geting hedge deal outstanding
-- with considering hedge amount and cancel amount

  elsif  ReversalType = GConst.UTILHEDGEDEAL then
      varOperation := 'Extracting Deal Amount for Hedge deal';
      Begin
        if (DealReference is NULL)  then
           select otherCurrency,OutStandingAmount,(ExchangeRate*OutStandingAmount)
           into numCode, numFcy, numInr
           from (select deal_other_currency otherCurrency,(deal_base_amount- nvl((select sum(hedg_hedged_fcy)
               from trtran004
              where hedg_deal_number=deal_deal_number
              and  hedg_record_status not in (Gconst.statusInactive,Gconst.StatusDeleted)
              group by hedg_deal_number),0))OutStandingAmount,
            deal_exchange_rate ExchangeRate
            from trtran001
            where deal_deal_number = TradeReference
            and deal_serial_number = TradeSerial
            and deal_execute_date <= AsonDate)a;
       else
          select deal_other_currency, hedg_hedged_fcy, hedg_hedged_inr
            into numCode, numFcy, numInr
            from trtran001, trtran004
            where deal_deal_number = hedg_deal_number
            and deal_serial_number = hedg_deal_serial
            and deal_deal_number = TradeReference
            and deal_serial_number = TradeSerial
            and hedg_trade_reference = DealReference
            and deal_execute_date <= AsonDate;
        end if;
      Exception
        when no_data_found then
          Goto Process_End;
      End;

      varOperation := 'Extracting Hedge Deal Delivery Amount';
      select nvl(sum(cdel_cancel_amount),0),
        nvl(sum(decode(numCode, GConst.INDIANRUPEE, cdel_other_amount,cdel_cancel_inr)),0)
        into numUtilFcy, numUtilInr
        from trtran006
        where cdel_deal_number = TradeReference
        and cdel_deal_serial = TradeSerial
        and cdel_cancel_date <= AsonDate
        and cdel_trade_reference = DealReference
        And Cdel_Record_Status In
        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED); -- Updated from Cygnet
--(GConst.UTILTRADECROSS, GConst.UTILHEDGECROSS)

    elsif ReversalType = GConst.UTILTRADECROSS then

      varOperation := 'Extracting Cross Currency Trade Deal Amount';
      select nvl(sum(deal_other_amount), 0), nvl(sum(deal_amount_local),0)
        into numFcy, numInr
        from trtran001
        where deal_deal_number = TradeReference
        and deal_serial_number = TradeSerial
        and deal_execute_date <= AsonDate;

      if numFcy = 0 then
        Goto Process_End;
      End if;

      varOperation := 'Extracting Utilization of Cross Currency Deal';
      select nvl(sum(cdel_other_amount),0), nvl(sum(cdel_cancel_inr),0)
        into numUtilFcy, numUtilInr
        from trtran006
        where cdel_deal_number = TradeReference
        and cdel_deal_serial = TradeSerial
        and cdel_cancel_date <= AsonDate
        And Cdel_Record_Status In
        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED); -- Updated From Cygnet

    elsif ReversalType = GConst.UTILHEDGECROSS then
      varOperation := 'Extracting Cross Currency Hedge Deal Amount';
     if (DealReference is null) then
        select deal_other_currency, deal_other_amount,deal_amount_local
            into numCode, numFcy, numInr
            from trtran001
            where deal_deal_number = TradeReference
            and deal_serial_number = TradeSerial
            and deal_execute_date <= AsonDate;
     else
        select deal_other_currency, hedg_other_fcy, hedg_hedged_inr
          into numCode, numFcy, numInr
          from trtran001, trtran004
          where deal_deal_number = hedg_deal_number
          and deal_serial_number = hedg_deal_serial
          and deal_deal_number = TradeReference
          and deal_serial_number = TradeSerial
          and deal_execute_date <= AsonDate;
      end if;
      if numFcy = 0 then
        Goto Process_End;
      End if;

      varOperation := 'Extracting Utilization of Hedge Cross Currency Deal';
      select nvl(sum(cdel_other_amount),0), nvl(sum(cdel_cancel_inr),0)
        into numUtilFcy, numUtilInr
        from trtran006
        where cdel_deal_number = TradeReference
        and cdel_deal_serial = TradeSerial
        and cdel_trade_reference = DealReference
        and cdel_cancel_date <= AsonDate
        And Cdel_Record_Status In
        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED); --Updated from cygnet


    elsif ReversalType = GConst.UTILCOVEREDORDERS then
      varOperation := 'Getting the Trade Amount';
      select trad_trade_fcy
        into numFcy
        from trtran002
        where trad_trade_reference = DealReference;

      varOperation := 'Extracting hedged amount';
      for curTradeOS in
      (Select hedg_hedged_fcy, hedg_deal_number, hedg_hedging_with
        from trtran004
        where hedg_trade_reference = DealReference
        and hedg_record_status between 10200001 and 10200004)
        Loop

          if curTradeOS.hedg_hedging_with = 32200001 then
            numUtilFcy := numUtilFcy + NVL(pkgforexprocess.fncGetOutstanding(curTradeOS.hedg_deal_number, 1,
              GConst.UTILHEDGEDEAL, GConst.AMOUNTFCY, AsonDate),0);
          elsif curTradeOS.hedg_hedging_with = 32200003 then
            numUtilFcy := numUtilFcy + NVL(pkgforexprocess.fncGetOutstanding(curTradeOS.hedg_deal_number, 1,
              Gconst.UTILOPTIONHEDGEDEAL, GConst.AMOUNTFCY, AsonDate),0);
          end if;

        End Loop;

        numAmount := numUtilFcy;
        Goto Process_End;
--- For Checking the Covered Amount of Orders  Manjunath Reddy on 20-may-2009
 --   OrderTemp:=DealReference;
      --OrderTemp:=DealReference;
--    numFCY:=0;
--    numUtilFcy:=0;
--<<FirstStep>>
--       varOperation := 'Extracting Utilization of Hedge Against Orders';
--
--        select nvl(sum(hedg_hedged_fcy),0)
--          into numTemp
--          from trtran004
--          where hedg_trade_reference=OrderTemp
--           and hedg_record_status not in(Gconst.StatusDeleted,Gconst.StatusINActive);
--
--       numFCY:=numFCY+numTemp;
-- --      varOperation := 'Extracting  Hedge Deal Delivared Against Orders ' || OrderTemp;
----      begin
----
----        select nvl(sum(cdel_cancel_amount),0)
----          into numTemp
----          from trtran006
----          where cdel_trade_reference=OrderTemp
----          and cdel_record_status not in(Gconst.StatusDeleted,Gconst.StatusINActive);
----      exception
----        when OTHERS then
----          numtemp :=0;
-- --     end;
---- Added by TMM on 01/09/2011 for Suraj. This will ignore the above two statements
----      begin
----        select nvl(sum(cdel_cancel_amount),0)
----          into numTemp
----          from trtran006, trtran004
----          where cdel_deal_number = hedg_deal_number
----          and hedg_trade_reference = OrderTemp
----          and cdel_record_status not in(Gconst.StatusDeleted,Gconst.StatusINActive);
----      exception
----        when OTHERS then
----          numtemp :=0;
----      End;
----
----      begin
----        numTemp1 := 0;
----        select nvl(sum(corv_base_amount),0)
----          into numTemp1
----          from trtran073, trtran004
----          where corv_deal_number = hedg_deal_number
----          and hedg_trade_reference = OrderTemp
----          and corv_record_status not in(Gconst.StatusDeleted,Gconst.StatusINActive);
----      exception
----        when OTHERS then
----          numtemp1 :=0;
----      end;
----
----       numTemp := numTemp + numTemp1;
------------
--   --    numUtilFcy:= numUtilFcy + numTemp;
--     begin
--       select nvl(trad_reverse_reference, '0')
--         into OrderTemp
--         from trtran002
--        where trad_trade_reference=OrderTemp
--             and trad_record_status not in(Gconst.StatusDeleted,Gconst.StatusINActive);
--    exception
--       when OTHERS then
--        OrderTemp :='0';
--      end;
--       if OrderTemp !='0' then
--         goto FirstStep;
--       end if;

    elsif ReversalType = GConst.UTILFCYLOAN then
      varOperation := 'Extracting Loan Amount';
      select nvl(sum(fcln_sanctioned_fcy),0), nvl(sum(fcln_sanctioned_inr),0)
        into numFcy, numInr
        from trtran005
        where fcln_loan_number = TradeReference
        and fcln_sanction_date <= AsonDate;

      if numFcy = 0 then
        Goto Process_End;
      End if;

      varOperation := 'Extracting Loan Amount';
      select nvl(sum(trln_adjusted_fcy),0), nvl(sum(trln_adjusted_inr),0)
        into numUtilFcy, numUtilInr
        from trtran007
        where trln_Loan_number = TradeReference
        and trln_adjusted_date <= AsonDate
        and trln_serial_number > 0
        and trln_record_status in
        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
        ---kumar.h updates 0n 12/05/09  for buyers credit
      elsif ReversalType = GConst.UTILBCRLOAN then
           varOperation := 'Extracting Buyers Credit ount';
          select nvl(sum(bcrd_sanctioned_fcy),0), nvl(sum(bcrd_sanctioned_inr),0)
            into numFcy, numInr
            from BuyersCredit
            where bcrd_buyers_credit = TradeReference
            and bcrd_sanction_date <= AsonDate;

          if numFcy = 0 then
            Goto Process_End;
          End if;

      select nvl(sum(CDEL_CANCEL_AMOUNT),0), nvl(sum(CDEL_OTHER_AMOUNT),0)
        into numUtilFcy, numUtilInr
        from trtran006
        where CDEL_TRADE_REFERENCE = TradeReference
        and CDEL_CANCEL_DATE <= AsonDate
        and CDEL_RECORD_STATUS in
        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);


--          varOperation := 'Extracting Loan Amount';
--          select nvl(sum(trln_adjusted_fcy),0), nvl(sum(trln_adjusted_inr),0)
--            into numFcy, numInr
--            from trtran007
--            where trln_Loan_number = TradeReference
--            and trln_adjusted_date <= AsonDate
--            and trln_serial_number > 0
--            and trln_record_status in
--            (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);

        ---kumar.h updates 0n 12/05/09  for buyers credit
--Commodity Deal Oustanding

    elsif ReversalType = GConst.UTILCOMMODITYDEAL then

      varOperation := 'Extracting Commodity Deal Oustanding Qty :::';
       select cmdl_lot_numbers
         into numFcy
         from trtran051
         where cmdl_deal_number=TradeReference
         and cmdl_execute_date <=AsonDate;

       select nvl(sum(crev_reverse_lot),0)
         into numUtilFcy
         from trtran053
         where ((crev_reverse_deal=TradeReference)
         or(crev_deal_number=TradeReference))
        and crev_execute_date <=AsonDate;
--- CurrencyFuture Deal


elsif ReversalType = GConst.UTILFUTUREDEAL then

      varOperation := 'Extracting Currency Future Deal Oustanding Qty ';
       select nvl(sum(cfut_lot_numbers),0), nvl(sum(cfut_other_amount),0)
         into numFcy,numInr
         from trtran061
         where cfut_deal_number=TradeReference
         and cfut_execute_date <=AsonDate;

     begin
       select nvl(sum(CFRV_REVERSE_LOT ),0),
          nvl(sum(CFRV_REVERSE_LOT* CFUT_EXCHANGE_RATE),0)
         into numUtilFcy,numUtilInr
         from trtran063,trtran061
         where cfrv_deal_number=TradeReference
        and cfrv_execute_date <=AsonDate
        and cfrv_deal_number=cfut_deal_number
        and cfrv_record_Status not in (1020005,10200006)
        and cfut_record_status not in(10200005,10200006);
     exception
      when others then
          numUtilFcy:=0;
          numUtilInr:=0;
      end;
   elsif ReversalType = Gconst.UTILOPTIONHEDGEDEAL then
     VarOperation :='getting option hedge deal base amount';
     begin
      select COSM_AMOUNT_FCY
        into numFcy
        from trtran072A
        where COSM_DEAL_NUMBER= TradeReference
        and COSM_SERIAL_NUMBER =TradeSerial
        AND COSM_SUBSERIAL_NUMBER = subSerial
        and COSM_RECORD_STATUS not in(Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
     exception
     when no_data_found then
       numFcy:=0;
     end;
     VarOperation :='getting option hedge deal utlization amount';
     begin
      select nvl(sum(corv_base_amount),0)
        into numUtilFcy
        from trtran073
        where corv_deal_number= TradeReference
          and corv_exercise_date <= AsonDate
        and corv_serial_number =TradeSerial
        and CORV_SUBSERIAL_NUMBER = subSerial
        and corv_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
      exception
      when no_data_found then
         numUtilFcy:=0;
      end;
  elsif ReversalType = GConst.UTILCONTRACTOS then
      varOperation := 'Extracting Merchant Transaction';
      select nvl(sum(trad_trade_fcy),0), nvl(sum(trad_trade_inr),0)
        into numFcy, numInr
        from trtran002
        where trad_trade_reference = TradeReference
        and trad_entry_date <= AsonDate
        and trad_record_status not in(10200005,10200006);

      if numFcy = 0 then
        Goto Process_End;
      End if;        
    
      varOperation := 'Extracting Merchant Utilization';
      
      select nvl(sum(brel_reversal_fcy),0), nvl(sum(brel_reversal_inr),0)
        into numUtilFcy, numUtilInr
        from trtran003, trtran002 a, trtran002 b
        where brel_trade_reference = a.trad_trade_reference
        and b.trad_trade_reference = TradeReference
        and a.trad_contract_no = b.trad_contract_no
        and brel_entry_date <= AsonDate
        and a.trad_record_status = 10200005
        and brel_record_status between 10200001 and 10200004;
        
    varOperation := 'Extracting Cancelled Contracts';
     begin 
     
      select nvl(sum(brel_reversal_fcy),0), nvl(sum(brel_reversal_inr),0)
        into numTemp, numTemp1
        from trtran003, trtran002 a
        where brel_trade_reference = a.trad_trade_reference
        and a.trad_trade_reference = TradeReference
        and a.trad_contract_no = a.trad_contract_no
        and brel_entry_date <= AsonDate
        and Brel_reversal_type in(25800006,25800053)
        and brel_record_status between 10200001 and 10200004;
      exception
       when no_data_found then
        numTemp:=0;
        numTemp1:=0;
      end;
       numUtilFcy:=numUtilFcy+Numtemp; 
       numUtilInr := numUtilInr +numTemp1;

      
 elsif ReversalType = GConst.UTILMFSCHEME then
      varOperation := 'Getting MF Investments for the scheme';
      select NVL(sum(mftr_transaction_quantity),0), NVL(sum(mftr_transaction_amount),0)
        into numFcy, numInr
        from trtran048
        where mftr_NAV_CODE = TradeReference
        and mftr_transaction_date <= AsonDate
        and mftr_record_status between 10200001 and 10200004;
      varOperation := 'Getting MF Redemptions for the scheme';
      select NVL(sum(mfcl_transaction_quantity),0), NVL(sum(mfcl_transaction_amount),0)
        into numUtilFcy, numUtilInr
        from trtran049
        where mfcl_nav_code = TradeReference
        and mfcl_transaction_date <= AsonDate
        and mfcl_record_status between 10200001 and 10200004;
      if round(numFcy) = round(numUtilFcy) then
        numFcy := 0;
        numUtilFcy := 0;
        numInr := 0;
        numUtilInr := 0;
      End if;
    elsif ReversalType = GConst.UTILMFTRANSACTION then
      varOperation := 'Getting MF Investment for the transaction';
      select NVL(sum(mftr_transaction_quantity),0), NVL(sum(mftr_transaction_amount),0)
        into numFcy, numInr
        from trtran048
        where mftr_reference_number = TradeReference
        and mftr_transaction_date <= AsonDate
        and mftr_record_status between 10200001 and 10200004;
      varOperation := 'Getting MF Redemptions for the Transaction';
      select NVL(sum(redm_noof_units),0), NVL(sum(redm_invest_amount),0)
        into numUtilFcy, numUtilInr
        from trtran049A
        where redm_invest_reference = TradeReference
        and redm_transaction_date <= AsonDate
        and redm_record_status between 10200001 and 10200004;
    else
      varOperation := 'Extracting Merchant Transaction';
      select nvl(sum(trad_trade_fcy),0), nvl(sum(trad_trade_inr),0)
        into numFcy, numInr
        from trtran002
        where trad_trade_reference = TradeReference
        and trad_entry_date <= AsonDate
        and trad_record_status not in(10200005,10200006);

      if numFcy = 0 then
        Goto Process_End;
      End if;

      varOperation := 'Extracting Merchant Utilization';
      select nvl(sum(brel_reversal_fcy),0), nvl(sum(brel_reversal_inr),0)
        into numUtilFcy, numUtilInr
        from trtran003
        where brel_trade_reference = TradeReference
        and brel_entry_date <= AsonDate
        and brel_record_status in
        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--       varOperation := 'Extracting Merchant Utilization';
--        select nvl(sum(HEDG_HEDGED_FCY),0), nvl(sum(HEDG_HEDGED_INR),0)
--        into numUtilFcy, numUtilInr
--        from trtran004
--        where HEDG_TRADE_REFERENCE = TradeReference
--       -- and brel_entry_date <= AsonDate
--        and HEDG_RECORD_STATUS in
--        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);

    End if;

    numOutFcy := numFcy - numUtilFcy;
    numOutInr := numInr - numUtilInr;
   -- numOutFcy :=5.0;
    if AmountType = GConst.AMOUNTFCY then
      numAmount := numOutFcy;
    elsif AmountType = GConst.AMOUNTINR then
      if ReversalType = GConst.UTILCOMMODITYDEAL then
        select ((numOutFcy * fncCommDealRate(tradeReference,AsonDate)) * (cmdl_product_quantity/cmdl_lot_numbers))
         into numOutInr
         from trtran051
         where cmdl_deal_number=TradeReference;
      end if;
      if ReversalType = GConst.UTILTRADEDEAL then
        if numFcy !=0 then
          numAmount := (numFcy - numUtilFcy) * (numInr/numFcy);
        else
          numAmount:=0;
        end if;
      else
         numAmount := numOutInr;
      end if;
    else
      numAmount := 0.00;
    end if;
<<Process_End>>
    return numAmount;
Exception
    when others then
      varerror := 'Outstanding: ' || varmessage || varoperation || varerror;
      raise_application_error(-20101,   varerror);
      return numAmount;
End fncGetOutstanding;



Function fncGetSpotDate
    ( CounterParty in number,
      AsonDate in Date,
      AddDays in number := 0)
      return Date
      is
--  Created on 28/05/08
    numError      number;
    numFlag       number(1);
    datReturn     date;
    datTemp       date;
    varOperation  gconst.gvaroperation%type;
    varMessage    gconst.gvarmessage%type;
    varError      gconst.gvarerror%type;
Begin
    varMessage := 'Returning Spot Date for ' || AsonDate;
    datReturn := null;

    if AddDays = 0 then
      datTemp := AsonDate + 2;
    else
      datTemp := AsonDate + AddDays;
    end if;

    numFlag := 0;

    varOperation := 'Extracting Holidays for the counter Party';
    for curHoliday in
    (select distinct hday_calendar_date
      from trsystem001
      where hday_location_code in
      (select nvl(lbnk_bank_location, 0)
        from trmaster306
        where lbnk_pick_code = Counterparty
        and hday_day_status in
        (GConst.DAYHOLIDAY, GConst.DAYWEEKLYOFF1, GConst.DAYWEEKLYOFF2)
       union
       select nvl(lbnk_corr_location,0)
        from trmaster306
        where lbnk_pick_code = CounterParty
        and hday_day_status in
        (GConst.DAYHOLIDAY, GConst.DAYWEEKLYOFF1, GConst.DAYWEEKLYOFF2))
      and hday_calendar_date >= AsonDate + 2
      order by hday_calendar_date)
    Loop
      numFlag := 1;

      if  curHoliday.hday_calendar_date > datTemp then
        datReturn := datTemp;
        exit;
      else
        datTemp := datTemp + 1;
      end if;

    End Loop;

    if numFlag = 0 then -- No Holiday records after the date
      select decode(trim(to_char(AsonDate + 2, 'DAY')),
        'SATURDAY', AsonDate + 4,
        'SUNDAY', AsonDate + 3,
        AsonDate + 2)
        into datReturn
        from dual;
    End if;

    return datReturn;
Exception
    when others then
      varerror := 'SpotDate: ' || varmessage || varoperation || varerror;
      raise_application_error(-20101,   varerror);
      return datReturn;
End fncGetSpotDate;

Function fncAllotMonth
    (   CounterParty in number,
        AsonDate in Date,
        MaturityDate in Date)
    Return Number
    is
--  Created on 10/07/08
    numReturn number;
    numSub number;
    datTemp date;
    datSpot date;
    varOperation gconst.gvaroperation%type;
    varMessage gconst.gvarmessage%type;
    varError gconst.gvarerror%type;
Begin

    numReturn := 0;
    varMessage := 'Slotting the maturity date';
    datSpot := fncGetSpotDate(CounterParty, AsonDate);
    datSpot := datSpot + 1;

    if MaturityDate < datSpot then
      return numReturn;
    end if;

    for numsub in 1..12
    Loop
      numReturn := numReturn + 1;
      datTemp := add_months(datSpot, numSub);

      if datTemp > MaturityDate then
        exit;
      end if;

    End Loop;

    return numReturn;

Exception
    when others then
      varerror := 'AllotMonth: ' || varmessage || varoperation || varerror;
      raise_application_error(-20101,   varerror);
      Rollback;
      return -1;

End fncAllotMonth;
--------
Function fncCommAllotMonth
    (   AsonDate in Date,
        MaturityDate in Date)
    Return Number
    is
--  Created on 10/07/08
    numReturn number;
    numSub number;
    dattemp date;
    datResult date;
    varOperation gconst.gvaroperation%type;
    varMessage gconst.gvarmessage%type;
    varError gconst.gvarerror%type;
Begin

    numReturn := 0;
    varMessage := 'Slotting the maturity date';


     dattemp := AsonDate +11;
      select max(hday_calendar_date)
        into datResult
        from trsystem001
        where hday_day_status not in(Gconst.DAYHOLIDAY,Gconst.DAYWEEKLYOFF2)
        and hday_calendar_date <=dattemp
        and hday_location_code= 30299999;

    if MaturityDate < datResult then
      return numReturn;
    end if;

    for numsub in 1..12
    Loop
      numReturn := numReturn + 1;
      datTemp := add_months(datResult, numSub);

      if datTemp > MaturityDate then
        exit;
      end if;

    End Loop;

    return numReturn;

Exception
    when others then
      varerror := 'AllotMonth: ' || varmessage || varoperation || varerror;
      raise_application_error(-20101,   varerror);
      Rollback;
      return -1;

End fncCommAllotMonth;

Function fncAllotMonth
    (AsonDate in Date,
     MaturityDate in Date)
     return number
     is
--  Created on 19/03/08
    numReturn number;
    numSub number;
    datTemp date;
    datSpot date;
    varOperation gconst.gvaroperation%type;
    varMessage gconst.gvarmessage%type;
    varError gconst.gvarerror%type;
--    Type dateRange IS VARRAY(12) OF DATE;
--    dealDate dateRange;
Begin
    numReturn := 0;
    varMessage := 'Slotting the maturity date';
    select decode(trim(to_char(AsonDate + 2, 'DAY')),
      'SATURDAY', AsonDate + 4,
      'SUNDAY', AsonDate + 3,
      AsonDate + 2)
      into datSpot
      from dual;
 -- Logic to check holidays to be inserted here
    datSpot := datSpot + 1;

--    if MaturityDate < datSpot then
--      return numReturn;
--    end if;
--
--    for numsub in 1..12
--    Loop
--      numReturn := numReturn + 1;
--      datTemp := add_months(datSpot, numSub);
--
--      if datTemp > MaturityDate then
--        exit;
--      end if;
--
--    End Loop;
--
--    return numReturn-1;

    if MaturityDate < datSpot then
      return numReturn;
    end if;

    for numsub in 1..12
    Loop
      numReturn := numReturn + 1;
      datTemp := add_months(datSpot, numSub);

      if datTemp > MaturityDate then
        exit;
      end if;

    End Loop;

    -- commented on 28-july-09 if it falls on 1 st month then also it returns 0
    --return numReturn-1;

    return numReturn;

Exception
    when others then
      varerror := 'AllotMonth: ' || varmessage || varoperation || varerror;
      raise_application_error(-20101,   varerror);
      Rollback;
      return -1;

End fncAllotMonth;

Function fncRiskLimit
    ( AsonDate in Date,
      RiskType in number,
      CrossCurrency in number := 12400000)
      return number
      is
      numError      number;
      numLimit      number(15,2);
      varTemp       varChar(25);
      varOperation  GConst.gvarOperation%type;
      varMessage    gconst.gvarMessage%type;
      varError      gconst.gvarError%type;

Begin
      varMessage := 'Extracting Limit for ' || RiskType;
      numLimit := 0.00;

    if RiskType < 21000200 then
      varOperation  := 'Extracting Risk Limit';

      Begin
        select risk_limit_usd
          into numLimit
          from trsystem012
          where risk_risk_type = RiskType
          and risk_cross_currency = CrossCurrency
          and risk_effective_date =
          (select max(risk_effective_date)
            from trsystem012
            where risk_risk_type = RiskType
            and risk_cross_currency = CrossCurrency
            and risk_effective_date <= AsonDate);
      Exception
        when no_data_found then
          numLimit := 0.00;
      End;
    elsif RiskType > 21000200 then
      Begin
        select crsk_limit_local
          into numLimit
          from trsystem019
          where crsk_crsk_type = RiskType
          and crsk_effective_date =
          (select max(crsk_effective_date)
            from trsystem019
            where crsk_crsk_type = RiskType
            and crsk_effective_date <= AsonDate);
      Exception
        when no_data_found then
          numLimit := 0.00;
      End;
    end if;

      return numLimit;
Exception
    when others then
      varerror := 'AllotMonth: ' || varmessage || varoperation || varerror;
      raise_application_error(-20101,   varerror);
      Rollback;
      return numLimit;
End fncRiskLimit;

Function fncRiskGenerate
    ( AsonDate in date,
      DealType in number)
      return number
    is

    PRAGMA AUTONOMOUS_TRANSACTION;
--  Created on 18/03/08
    datToday      date;
    datTemp       date;
    numError      number;
    numAction     number(8);
    numType       number(8);
    numGrossNet   number(8);
    numLimit      number(15,2);
    numLimitLocal number(15,2);
    numTemp       number(15,6);
    numRate       number(15,6);
    varTemp       varchar(25);
    varMobile     varchar2(15);
    varReference  varchar2(15);
    varUserID     varchar2(256);
    varEmailID    varchar2(500);
    varOperation  GConst.gvarOperation%type;
    varMessage    gconst.gvarMessage%type;
    varError      gconst.gvarError%type;
Begin
    numError := 0;
    varMessage := 'Generating Risk Figures for date: ' || AsonDate;
    datToday := AsonDate;

    varOperation := 'Inserting outstanding deals';
    numError := fncRiskPopulate(AsonDate, DealType);
    dbms_output.put_line('Risk over, status: ' || numError);

    if numError != 0 then
      return numError;
    end if;

    varOperation := 'Checking Individual Deal Limit';
    select risk_risk_reference, risk_limit_usd, risk_stake_holder,
      risk_action_taken
      into varReference, numLimit, varUserID, numAction
      from trsystem012 a
      where risk_risk_type = GConst.RISKDEALLIMIT
      and risk_effective_date =
      (select max(risk_effective_date)
        from trsystem012 b
        where a.risk_company_code = b.risk_company_code
        and a.risk_risk_type = b.risk_risk_type
        and risk_effective_date <= AsonDate);

    if numAction in (GConst.RISKACTSMS, GConst.RISKACTEMAIL) then
      select  user_mobile_phone, user_email_id
        into varMobile, varEmailID
        from trsystem022
        where user_user_id = varUserID;
    else
      varMobile := '';
      varEmailID := '';
    end if;

    varOperation := 'Inserting Individual Deal Limit Violation';
--    varReference := varReference || GConst.fncGenerateSerial(GConst.SERIALRISKSERIAL);
    insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
      rdel_serial_number, rdel_risk_date, rdel_risk_type,
      RDEL_LIMIT_USD, rdel_amount_excess,
      rdel_action_taken, rdel_stake_holder, rdel_mobile_number, rdel_email_id,
      rdel_message_text)
      select deal_company_code,
      varReference  || GConst.fncGenerateSerial(GConst.SERIALRISKSERIAL) ,
      deal_deal_number,
      deal_serial_number, AsonDate, GConst.RISKDEALLIMIT,
      numLimit, crsk_position_usd - numLimit,
      numAction, varUserID, varMobile, varEmailID,
      'Deal Limit Violation No: ' || deal_deal_number || ' Currency: ' ||
      pkgReturnCursor.fncGetDescription(deal_base_currency, GConst.PICKUPSHORT) || '/' ||
      pkgReturnCursor.fncGetDescription(deal_other_currency, GConst.PICKUPSHORT) ||
      ' Deal Amount: ' || to_number(deal_base_amount) ||
      ' Limit: ' || to_char(numLimit) || ' Excess: ' || to_char(crsk_position_usd - numLimit)
      from trsystem996 , trtran001
      where crsk_deal_number = deal_deal_number
      and crsk_serial_number = deal_serial_number
      and crsk_ason_date = datToday
      and crsk_risk_type = 0
      and crsk_position_usd > numLimit
      and deal_deal_number not in
      (select rdel_deal_number
        from trtran011
        where rdel_deal_number = deal_deal_number
        and rdel_risk_reference = varReference);
commit;
dbms_output.put_Line('Inserted');
--    varOperation := 'Checking Day Light Limit for all deals';
--    select risk_risk_reference, risk_limit_usd, risk_stake_holder,
--      risk_action_taken, rprm_gross_net
--      into varReference, numLimit, varUserID, numAction, numGrossNet
--      from trsystem012 a, trsystem011
--      where rprm_risk_type = risk_risk_type
--      and risk_risk_type = GConst.RISKDAYLIGHT
--      and risk_cross_currency = GConst.OPTIONNO
--      and risk_effective_date =
--      (select max(risk_effective_date)
--        from trsystem012 b
--        where a.risk_company_code = b.risk_company_code
--        and a.risk_risk_type = b.risk_risk_type
--        and a.risk_effective_date <= AsonDate);
--
--    if numAction in (GConst.RISKACTSMS, GConst.RISKACTEMAIL) then
--      select  user_mobile_phone, user_email_id
--        into varMobile, varEmailID
--        from trsystem022
--        where user_user_id = varUserID;
--    else
--      varMobile := '';
--      varEmailID := '';
--    end if;
--
--    varOperation := 'Getting Actual Daylight Deal Limit';
--    select NVL(sum(abs(crsk_allowed_usd)),0)
--      into numTemp
--      from trsystem996
--      where crsk_ason_date = datToday
--      and crsk_risk_type = GConst.RISKDAYLIGHT
--      and crsk_serial_number = 1;
--
--    if numTemp > numLimit then
--      varOperation := 'Inserting Daylight Limit Violation';
--      insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
--        rdel_serial_number, rdel_risk_date, rdel_risk_type,
--        RDEL_LIMIT_USD, rdel_amount_excess, rdel_action_taken,
--        rdel_stake_holder, rdel_mobile_number, rdel_email_id,
--        rdel_message_text)
--        select deal_company_code, varReference, deal_deal_number,
--        deal_serial_number, AsonDate, GConst.RISKDAYLIGHT,
--        numLimit, crsk_position_usd - numLimit,
--        numAction, varUserID, varMobile, varEmailID,
--        'Daylight Limit Violation No: ' || deal_deal_number || ' Currency: ' ||
--        pkgReturnCursor.fncGetDescription(deal_base_currency, GConst.PICKUPSHORT) || '/' ||
--        pkgReturnCursor.fncGetDescription(deal_other_currency, GConst.PICKUPSHORT) ||
--        ' Limit: ' || to_char(numLimit) || ' Excess: ' || to_char(crsk_position_usd - numLimit)
--        from trsystem996 , trtran001 a
--        where deal_deal_number =
--        (select deal_deal_number
--          from trtran001
--          where deal_execute_date = AsonDate
--          and to_timestamp(deal_time_stamp,'DD-Mon-RR HH24:MI:SS:FF3') =
--          (select max(to_timestamp(deal_time_stamp,'DD-Mon-RR HH24:MI:SS:FF3'))
--            from trtran001 b
--            where deal_execute_date = AsonDate))
--        and crsk_risk_type = GConst.RISKDAYLIGHT
--        and crsk_serial_number = 1
--        and crsk_ason_date = datToday
--        and crsk_user_id is null
--        and a.deal_deal_number not in
--        (select rdel_deal_number
--          from trtran011
--          where rdel_deal_number = a.deal_deal_number
--          and rdel_risk_reference = varReference);
--    end if;
--
--
--    varOperation := 'Checking Day Light Limit for cross currency deals';
--    select risk_risk_reference, risk_limit_usd, risk_stake_holder,
--      risk_action_taken, rprm_gross_net
--      into varReference, numLimit, varUserID, numAction, numGrossNet
--      from trsystem012 a, trsystem011
--      where rprm_risk_type = risk_risk_type
--      and risk_risk_type = GConst.RISKDAYLIGHT
--      and risk_cross_currency = GConst.OPTIONYES
--      and risk_effective_date =
--      (select max(risk_effective_date)
--        from trsystem012 b
--        where a.risk_company_code = b.risk_company_code
--        and a.risk_risk_type = b.risk_risk_type
--        and a.risk_effective_date <= AsonDate);
--
--    if numAction in (GConst.RISKACTSMS, GConst.RISKACTEMAIL) then
--      select  user_mobile_phone, user_email_id
--        into varMobile, varEmailID
--        from trsystem022
--        where user_user_id = varUserID;
--    else
--      varMobile := '';
--      varEmailID := '';
--    end if;
--
--    varOperation := 'Getting Actual Cross Currency Daylight Deal Limit';
--    select NVL(sum(abs(crsk_allowed_usd)),0)
--      into numTemp
--      from trsystem996
--      where crsk_ason_date = datToday
--      and crsk_risk_type = GConst.RISKDAYLIGHT
--      and crsk_serial_number = 2;
--
--    if numTemp > numLimit then
--      varOperation := 'Inserting Cross Currency Daylight Limit Violation';
--      insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
--        rdel_serial_number, rdel_risk_date, rdel_risk_type,
--        RDEL_LIMIT_USD, rdel_amount_excess, rdel_action_taken,
--        rdel_stake_holder, rdel_mobile_number, rdel_email_id,
--        rdel_message_text)
--        select deal_company_code, varReference, deal_deal_number,
--        deal_serial_number, AsonDate, GConst.RISKDAYLIGHT,
--        numLimit, crsk_position_usd - numLimit,
--        numAction, varUserID, varMobile, varEmailID,
--        'Daylight Limit Violation No: ' || deal_deal_number || ' Currency: ' ||
--        pkgReturnCursor.fncGetDescription(deal_base_currency, GConst.PICKUPSHORT) || '/' ||
--        pkgReturnCursor.fncGetDescription(deal_other_currency, GConst.PICKUPSHORT) ||
--        ' Limit: ' || numLimit || ' Excess: ' || (crsk_position_usd - numLimit)
--        from trsystem996 , trtran001 a
--        where deal_deal_number =
--        (select deal_deal_number
--          from trtran001 b
--          where deal_execute_date = AsonDate
--          and deal_other_currency != GConst.INDIANRUPEE
--          and to_timestamp(deal_time_stamp,'DD-Mon-RR HH24:MI:SS:FF3') =
--          (select max(to_timestamp(deal_time_stamp,'DD-Mon-RR HH24:MI:SS:FF3'))
--            from trtran001 c
--            where deal_execute_date = AsonDate
--            and deal_other_currency != GConst.INDIANRUPEE))
--        and crsk_risk_type = GConst.RISKDAYLIGHT
--        and crsk_serial_number = 2
--        and crsk_ason_date = datToday
--        and crsk_user_id is null
--        and a.deal_deal_number not in
--        (select rdel_deal_number
--          from trtran011
--          where rdel_deal_number = a.deal_deal_number
--          and rdel_risk_reference = varReference);
--    end if;

--
--    varOperation := 'Checking Daily Stop Loss Limit';
--    select risk_risk_reference, risk_limit_usd,risk_limit_local, risk_stake_holder,
--      risk_action_taken, rprm_gross_net
--      into varReference, numLimit,numlimitlocal, varUserID, numAction, numGrossNet
--      from trsystem012 a, trsystem011
--      where rprm_risk_type = risk_risk_type
--      and risk_risk_type = GConst.RISKSTOPLOSSDAILY
--      and risk_effective_date =
--      (select max(risk_effective_date)
--        from trsystem012 b
--        where a.risk_company_code = b.risk_company_code
--        and a.risk_risk_type = b.risk_risk_type
--        and a.risk_effective_date <= AsonDate);
--
----    if numAction in (GConst.RISKACTSMS, GConst.RISKACTEMAIL) then
----      select  user_mobile_phone, user_email_id
----        into varMobile, varEmailID
----        from trsystem022
----        where user_user_id = varUserID;
----    else
----      varMobile := '';
----      varEmailID := '';
----    end if;
--
--    varOperation := 'Summing up Losses for cancelled and outstanding deals';
--    select abs(sum(crsk_profit_loss))
--      into numTemp
--      from trsystem996
--      where crsk_ason_date = datToday
--      and crsk_risk_type = GConst.RISKSTOPLOSSDAILY;
--
--
--     varEmailID:= fncUserDetails(varUserID);
--
--
--    if numTemp > numlimitlocal then
----      varTemp := 'RISK/' || fncGenerateSerial(SERIALRISKSERIAL);
--     varTemp := 'RISK/' || Gconst.fncGenerateSerial(Gconst.SERIALRISKSERIAL);
--      insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
--        rdel_serial_number, rdel_risk_date, rdel_risk_type,
--        RDEL_LIMIT_USD, rdel_amount_excess, rdel_action_taken,
--        rdel_stake_holder, rdel_mobile_number, rdel_email_id,
--        rdel_message_text,rdel_sent_status,rdel_record_status)
--      values(10399999, varTemp, '-', 0, datToday,
--      GConst.RISKSTOPLOSSDAILY, numlimitlocal, numTemp - numlimitlocal,
--      numAction,varEmailID  , varMobile, varEmailID,
--      ' Daily Stoploss Limit Violation: REF No  ' || varTemp || to_char(13) ||
--      '   Limit  :   ' || pkgreturnReport.fncConvRs(numlimitlocal) || to_char(13) ||
--      '   Loss   :   ' || pkgreturnReport.fncConvRs(numTemp) || to_char(13) ||
--      '   Excess :   ' || pkgreturnReport.fncConvRs((numTemp - numlimitlocal)),27300001,10200001);
--
--    End if;

--    varOperation := 'Checking Deal Stop Loss Limit';
--    select risk_risk_reference, risk_limit_usd,risk_limit_local, risk_stake_holder,
--      risk_action_taken, rprm_gross_net
--      into varReference, numLimit,numlimitlocal, varUserID, numAction, numGrossNet
--      from trsystem012 a, trsystem011
--      where rprm_risk_type = risk_risk_type
--      and risk_risk_type = GConst.RISKSTOPLOSSDEAL
--      and risk_effective_date =
--      (select max(risk_effective_date)
--        from trsystem012 b
--        where a.risk_company_code = b.risk_company_code
--        and a.risk_risk_type = b.risk_risk_type
--        and a.risk_effective_date <= AsonDate);

--    if numAction in (GConst.RISKACTSMS, GConst.RISKACTEMAIL) then
--      select  user_mobile_phone, user_email_id
--        into varMobile, varEmailID
--        from trsystem022
--        where user_user_id = varUserID;
--    else
--      varMobile := '';
--      varEmailID := '';
--    end if;

 --   varOperation := 'Summing up Losses for cancelled and outstanding deals';


--     varEmailID:= fncUserDetails(varUserID);


--    if numTemp > numlimitlocal then
--      varTemp := 'RISK/' || fncGenerateSerial(SERIALRISKSERIAL);
--      insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
--        rdel_serial_number, rdel_risk_date, rdel_risk_type,
--        RDEL_LIMIT_USD, rdel_amount_excess, rdel_action_taken,
--        rdel_stake_holder, rdel_mobile_number, rdel_email_id,
--        rdel_message_text,rdel_sent_status,rdel_record_status)
--        select 10399999, 'RISK/' || Gconst.fncGenerateSerial(Gconst.SERIALRISKSERIAL),
--        '-',0,datToday,
--        GConst.RISKSTOPLOSSDEAL,numlimitlocal, numlimitlocal,
--        numAction,varEmailID  , varMobile, varEmailID,
--        ' Deal Stoploss Limit Violation: REF No  ' || CRSK_DEAL_NUMBER ||  chr(13) || chr(13) ||
--        '   Deal Amount     :  ' || pkgreturnReport.fncConvRs(CRSK_POSITION_FCY) || chr(13) ||
--        '   Currency Pair   : ' || pkgreturncursor.fncgetdescription(CRSK_CURRENCY_CODE,2) || '/' ||
--         pkgreturncursor.fncgetdescription(CRSK_FOR_CURRENCY,2) || chr(13) ||
--        '   Deal Rate        :  ' || CRSK_DEAL_RATE || chr(13) ||
--        '   M2M Rate         :  ' || CRSK_MTM_RATE  || chr(13) ||
--        '   Wash Rate        :  ' || CRSK_WASH_RATE || chr(13) ||
--        '   Limit            :   ' || pkgreturnReport.fncConvRs(numlimitlocal) || chr(13) ||
--        '   Loss             :   ' || pkgreturnReport.fncConvRs(CRSK_PROFIT_LOSS) ||  chr(13) ||
--        '   Excess           :   ' || pkgreturnReport.fncConvRs((CRSK_PROFIT_LOSS + numlimitlocal)) || chr(13) || chr(13) || chr(13) ||
--        '   Mail Has been send by Nagreek Treasury Software '  ,27300001,10200001
--        from trsystem996
--        where crsk_ason_date = datToday
--        and crsk_risk_type = 0
--        and crsk_profit_loss < numlimitlocal*-1 ;

--    End if;
--    varOperation := 'Checking Monthy Stop Loss Limit';
--    select risk_risk_reference, risk_limit_usd, risk_stake_holder,
--      risk_action_taken, rprm_gross_net
--      into varReference, numLimit, varUserID, numAction, numGrossNet
--      from trsystem012 a, trsystem011
--      where rprm_risk_type = risk_risk_type
--      and risk_risk_type = GConst.RISKSTOPLOSSMTHLY
--      and risk_effective_date =
--      (select max(risk_effective_date)
--        from trsystem012 b
--        where a.risk_company_code = b.risk_company_code
--        and a.risk_risk_type = b.risk_risk_type
--        and a.risk_effective_date <= AsonDate);
--
--    if numAction in (GConst.RISKACTSMS, GConst.RISKACTEMAIL) then
--      select  user_mobile_phone, user_email_id
--        into varMobile, varEmailID
--        from trsystem022
--        where user_user_id = varUserID;
--    else
--      varMobile := '';
--      varEmailID := '';
--    end if;
--
--    varOperation := 'Summing up Losses for cancelled and outstanding deals';
--    select sum(crsk_allowed_usd)
--      into numTemp
--      from trsystem996
--      where crsk_ason_date = datToday
--      and crsk_risk_type = GConst.RISKSTOPLOSSMTHLY;
--
--
--    if numTemp > numLimit then
--      insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
--        rdel_serial_number, rdel_risk_date, rdel_risk_type,
--        RDEL_LIMIT_USD, rdel_amount_excess, rdel_action_taken,
--        rdel_stake_holder, rdel_mobile_number, rdel_email_id,
--        rdel_message_text)
--      values(10399999, varReference, null, 0, datToday,
--      GConst.RISKSTOPLOSSMTHLY, numLimit, numTemp - numLimit,
--      numAction,  varUserID, varMobile, varEmailID,
--      'Monthly Stoploss Limit Violation: ' ||
--      ' Limit: ' || to_char(numLimit) || ' Excess: ' || to_char((numTemp - numLimit)));
--    End if;
--
--    varOperation := 'Checking Quarterly Stop Loss Limit';
--    select risk_risk_reference, risk_limit_usd, risk_stake_holder,
--      risk_action_taken, rprm_gross_net
--      into varReference, numLimit, varUserID, numAction, numGrossNet
--      from trsystem012 a, trsystem011
--      where rprm_risk_type = risk_risk_type
--      and risk_risk_type = GConst.RISKSTOPLOSSQTRLY
--      and risk_effective_date =
--      (select max(risk_effective_date)
--        from trsystem012 b
--        where a.risk_company_code = b.risk_company_code
--        and a.risk_risk_type = b.risk_risk_type
--        and a.risk_effective_date <= AsonDate);
--
--    if numAction in (GConst.RISKACTSMS, GConst.RISKACTEMAIL) then
--      select  user_mobile_phone, user_email_id
--        into varMobile, varEmailID
--        from trsystem022
--        where user_user_id = varUserID;
--    else
--      varMobile := '';
--      varEmailID := '';
--    end if;
--
--    varOperation := 'Summing up Losses for cancelled and outstanding deals';
--    select sum(crsk_allowed_usd)
--      into numTemp
--      from trsystem996
--      where crsk_ason_date = datToday
--      and crsk_risk_type = GConst.RISKSTOPLOSSQTRLY;
--
--    if numTemp > numLimit then
--      insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
--        rdel_serial_number, rdel_risk_date, rdel_risk_type,
--        RDEL_LIMIT_USD, rdel_amount_excess, rdel_action_taken,
--        rdel_stake_holder, rdel_mobile_number, rdel_email_id,
--        rdel_message_text)
--      values(10399999, varReference, null, 0, datToday,
--      GConst.RISKSTOPLOSSQTRLY, numLimit, numTemp - numLimit,
--      numAction,  varUserID, varMobile, varEmailID,
--      'Quarterly Stoploss Limit Violation: ' ||
--      ' Limit: ' || to_char(numLimit) || ' Excess: ' || to_char((numTemp - numLimit)));
--    End if;
--
--    varOperation := 'Checking Yearly Stop Loss Limit';
--    select risk_risk_reference, risk_limit_usd, risk_stake_holder,
--      risk_action_taken, rprm_gross_net
--      into varReference, numLimit, varUserID, numAction, numGrossNet
--      from trsystem012 a, trsystem011
--      where rprm_risk_type = risk_risk_type
--      and risk_risk_type = GConst.RISKSTOPLOSSYERLY
--      and risk_effective_date =
--      (select max(risk_effective_date)
--        from trsystem012 b
--        where a.risk_company_code = b.risk_company_code
--        and a.risk_risk_type = b.risk_risk_type
--        and a.risk_effective_date <= AsonDate);
--
--    if numAction in (GConst.RISKACTSMS, GConst.RISKACTEMAIL) then
--      select  user_mobile_phone, user_email_id
--        into varMobile, varEmailID
--        from trsystem022
--        where user_user_id = varUserID;
--    else
--      varMobile := '';
--      varEmailID := '';
--    end if;
--
--    varOperation := 'Summing up Losses for cancelled and outstanding deals';
--    select sum(crsk_allowed_usd)
--      into numTemp
--      from trsystem996
--      where crsk_ason_date = datToday
--      and crsk_risk_type = GConst.RISKSTOPLOSSYERLY;
--
--    if numTemp > numLimit then
--      insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
--        rdel_serial_number, rdel_risk_date, rdel_risk_type,
--        RDEL_LIMIT_USD, rdel_amount_excess, rdel_action_taken,
--        rdel_stake_holder, rdel_mobile_number, rdel_email_id,
--        rdel_message_text)
--      values(10399999, varReference, null, 0, datToday,
--      GConst.RISKSTOPLOSSYERLY, numLimit, numTemp - numLimit,
--      numAction,  varUserID, varMobile, varEmailID,
--      'Yearly Stoploss Limit Violation: ' ||
--      ' Limit: ' || to_char(numLimit) || ' Excess: ' || (numTemp - numLimit));
--    End if;
---------------------------- Commodity Module Done by manjunath reddy on 16-apr-2009
--
--    varOperation := 'Checking Individual Commodity Deal Limit';
--    select crsk_crsk_reference, crsk_limit_local, crsk_stake_holder,
--      crsk_action_taken
--      into varReference, numLimit, varUserID, numAction
--      from trsystem019 a
--      where crsk_crsk_type = GConst.CRISKDEALLIMIT
--      and crsk_effective_date =
--      (select max(crsk_effective_date)
--        from trsystem019 b
--        where a.crsk_company_code = b.crsk_company_code
--        and a.crsk_crsk_type = b.crsk_crsk_type
--        and crsk_effective_date <= AsonDate);
--
--
--
--    varOperation := 'Inserting Individual Commodity Deal Limit Violation';
--    insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
--      rdel_serial_number,rdel_risk_date, rdel_risk_type,
--      RDEL_LIMIT_USD, rdel_amount_excess,
--      rdel_action_taken, rdel_stake_holder, rdel_mobile_number, rdel_email_id,
--      rdel_message_text)
--      select 30199999, varReference, crsk_deal_number,
--      1,AsonDate, GConst.RISKDEALLIMIT,
--      numLimit, crsk_position_inr - numLimit,
--      numAction, varUserID, varMobile, varEmailID,
--      'Deal Limit Violation No: ' || crsk_deal_number || ' Currency: ' ||
--      pkgReturnCursor.fncGetDescription(crsk_other_currency, GConst.PICKUPSHORT) || '/' ||
--      ' Limit: ' || to_char(numLimit) || ' Excess: ' || to_char(crsk_position_usd - numLimit)
--      from trsystem996
--      where crsk_ason_date = datToday
--      and crsk_risk_type = 200
--      and crsk_position_inr > numLimit
--      and crsk_deal_number not in
--      (select rdel_deal_number
--        from trtran011
--        where rdel_deal_number = crsk_deal_number
--        and rdel_risk_reference = varReference);
--
--
--    varOperation := 'Checking Commodity Deal Daily Stop Loss Limit';
--    select crsk_crsk_reference, crsk_limit_local, crsk_stake_holder,
--      crsk_action_taken
--      --, crsk_gross_net
--      into varReference, numLimit, varUserID, numAction
--      --, numGrossNet
--      from trsystem019 a, trsystem018
--      where crpm_crsk_type = crsk_crsk_type
--      and crsk_crsk_type = GConst.CRISKSTOPLOSSDAILY
--      and crsk_effective_date =
--      (select max(crsk_effective_date)
--        from trsystem019 b
--        where a.crsk_company_code = b.crsk_company_code
--        and a.crsk_crsk_type = b.crsk_crsk_type
--        and a.crsk_effective_date <= AsonDate);
--
--    if numAction in (GConst.RISKACTSMS, GConst.RISKACTEMAIL) then
--      select  user_mobile_phone, user_email_id
--        into varMobile, varEmailID
--        from trsystem022
--        where user_user_id = varUserID;
--    else
--      varMobile := '';
--      varEmailID := '';
--    end if;
--
--    varOperation := 'Summing up Losses for cancelled and outstanding Commodity deals : Daily Stop Loss';
--    select sum(crsk_position_inr)
--      into numTemp
--      from trsystem996
--      where crsk_ason_date = datToday
--      and crsk_risk_type = GConst.CRISKSTOPLOSSDAILY;
--
--
--    if numTemp > numLimit then
--      insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
--        rdel_serial_number, rdel_risk_date, rdel_risk_type,
--        RDEL_LIMIT_USD, rdel_amount_excess, rdel_action_taken,
--        rdel_stake_holder, rdel_mobile_number, rdel_email_id,
--        rdel_message_text)
--      values(10399999, varReference, varReference, 0, datToday,
--      GConst.RISKSTOPLOSSDAILY, numLimit, numTemp - numLimit,
--      numAction,  varUserID, varMobile, varEmailID,
--      'Daily Stoploss Limit Violation: ' ||
--      ' Limit: ' || to_char(numLimit) || ' Excess: ' || to_char((numTemp - numLimit)));
--    End if;
--
--    varOperation := 'Checking Commodity Deal Monthly Stop Loss Limit';
--    select crsk_crsk_reference, crsk_limit_local, crsk_stake_holder,
--      crsk_action_taken
--
--      into varReference, numLimit, varUserID, numAction
--      from trsystem019 a, trsystem018
--      where crpm_crsk_type = crsk_crsk_type
--      and crsk_crsk_type = GConst.CRISKSTOPLOSSMTHLY
--      and crsk_effective_date =
--      (select max(crsk_effective_date)
--        from trsystem019 b
--        where a.crsk_company_code = b.crsk_company_code
--        and a.crsk_crsk_type = b.crsk_crsk_type
--        and a.crsk_effective_date <= AsonDate);
--
--    if numAction in (GConst.RISKACTSMS, GConst.RISKACTEMAIL) then
--      select  user_mobile_phone, user_email_id
--        into varMobile, varEmailID
--        from trsystem022
--        where user_user_id = varUserID;
--    else
--      varMobile := '';
--      varEmailID := '';
--    end if;
--
--    varOperation := 'Summing up Losses for cancelled and outstanding deals Monthly Stop Loss';
--    select sum(crsk_position_inr)
--      into numTemp
--      from trsystem996
--      where crsk_risk_type = GConst.CRISKSTOPLOSSMTHLY;
--
--
--    if numTemp > numLimit then
--      insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
--        rdel_serial_number, rdel_risk_date, rdel_risk_type,
--        RDEL_LIMIT_USD, rdel_amount_excess, rdel_action_taken,
--        rdel_stake_holder, rdel_mobile_number, rdel_email_id,
--        rdel_message_text)
--      values(10399999, varReference, varReference, 0, datToday,
--      GConst.CRISKSTOPLOSSMTHLY, numLimit, numTemp - numLimit,
--      numAction,  varUserID, varMobile, varEmailID,
--      'Monthly Stoploss Limit Violation: ' ||
--      ' Limit: ' || to_char(numLimit) || ' Excess: ' || to_char((numTemp - numLimit)));
--    End if;
--
--
--
--
--    varOperation := 'Checking Commodity Deal Quarterly Stop Loss Limit';
--   select crsk_crsk_reference, crsk_limit_local, crsk_stake_holder,
--      crsk_action_taken
--      into varReference, numLimit, varUserID, numAction
--      from trsystem019 a, trsystem018
--      where crpm_crsk_type = crsk_crsk_type
--      and crsk_crsk_type = GConst.CRISKSTOPLOSSQTRLY
--      and crsk_effective_date =
--      (select max(crsk_effective_date)
--        from trsystem019 b
--        where a.crsk_company_code = b.crsk_company_code
--        and a.crsk_crsk_type = b.crsk_crsk_type
--        and a.crsk_effective_date <= AsonDate);
--
--    if numAction in (GConst.RISKACTSMS, GConst.RISKACTEMAIL) then
--      select  user_mobile_phone, user_email_id
--        into varMobile, varEmailID
--        from trsystem022
--        where user_user_id = varUserID;
--    else
--      varMobile := '';
--      varEmailID := '';
--    end if;
--
--    varOperation := 'Summing up Losses for cancelled and outstanding deals Quarterly Stop Loss';
--    select sum(crsk_position_inr)
--      into numTemp
--      from trsystem996
--      where crsk_risk_type = GConst.CRISKSTOPLOSSQTRLY;
--
--    if numTemp > numLimit then
--      insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
--        rdel_serial_number, rdel_risk_date, rdel_risk_type,
--        RDEL_LIMIT_USD, rdel_amount_excess, rdel_action_taken,
--        rdel_stake_holder, rdel_mobile_number, rdel_email_id,
--        rdel_message_text)
--      values(10399999, varReference, varReference, 0, datToday,
--      GConst.CRISKSTOPLOSSQTRLY, numLimit, numTemp - numLimit,
--      numAction,  varUserID, varMobile, varEmailID,
--      'Quarterly Stoploss Limit Violation: ' ||
--      ' Limit: ' || to_char(numLimit) || ' Excess: ' || to_char((numTemp - numLimit)));
--    End if;
--
--    varOperation := 'Checking Yearly Stop Loss Limit';
--   select crsk_crsk_reference, crsk_limit_local, crsk_stake_holder,
--      crsk_action_taken
--      into varReference, numLimit, varUserID, numAction
--      from trsystem019 a, trsystem018
--      where crpm_crsk_type = crsk_crsk_type
--      and crsk_crsk_type = GConst.CRISKSTOPLOSSYERLY
--      and crsk_effective_date =
--      (select max(crsk_effective_date)
--        from trsystem019 b
--        where a.crsk_company_code = b.crsk_company_code
--        and a.crsk_crsk_type = b.crsk_crsk_type
--        and a.crsk_effective_date <= AsonDate);
--
--    if numAction in (GConst.RISKACTSMS, GConst.RISKACTEMAIL) then
--      select  user_mobile_phone, user_email_id
--        into varMobile, varEmailID
--        from trsystem022
--        where user_user_id = varUserID;
--    else
--      varMobile := '';
--      varEmailID := '';
--    end if;
--
--    varOperation := 'Summing up Losses for cancelled and outstanding deals yearly  Stop Loss';
--    select sum(crsk_position_inr)
--      into numTemp
--      from trsystem996
--      where crsk_risk_type = GConst.CRISKSTOPLOSSYERLY;
--
--    if numTemp > numLimit then
--      insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
--        rdel_serial_number, rdel_risk_date, rdel_risk_type,
--        RDEL_LIMIT_USD, rdel_amount_excess, rdel_action_taken,
--        rdel_stake_holder, rdel_mobile_number, rdel_email_id,
--        rdel_message_text)
--      values(10399999, varReference, varReference, 0, datToday,
--      GConst.CRISKSTOPLOSSYERLY, numLimit, numTemp - numLimit,
--      numAction,  varUserID, varMobile, varEmailID,
--      'Yearly Stoploss Limit Violation: ' ||
--      ' Limit: ' || to_char(numLimit) || ' Excess: ' || (numTemp - numLimit));
--    End if;



    commit;
    return numError;
Exception
    when others then
      varError := SQLERRM;
      varerror := 'RiskGen: ' || varmessage || varoperation || varerror;
      raise_application_error(-20101,   varerror);
      Rollback;
      return -1;
End fncRiskGenerate;
--function getUserMail_PhoneDetails
--    (varUserIds in varchar,
--    varMail out varchar,
--    varSmS  out varchar)
--    return varchar
--    is
--      varEmail varchar(300);
--      varSms varchar(300);
--    begin
--    for 1..10 loop
--
--      select * from tftran
--
--end;

Function fncRiskPopulate
    (AsonDate in date,
    DealType in number)
    return number
    is

    PRAGMA AUTONOMOUS_TRANSACTION;
--  Created on 20/07/08
    datToday      date;
    datTemp       date;
    numError      number;
    numAction     number(8);
    numType       number(8);
    numGrossNet   number(8);
    numFlag       number(1);
    numSerial     number(5);
    numLimit      number(15,2);
    numTemp       number(15,6);
    numTemp1      number(15,6);
    numRate       number(15,6);
    varMobile     varchar2(15);
    varReference  varchar2(15);
    varUserID     varchar2(50);
    varEmailID    varchar2(50);
    varQuuery     varchar2(256);
    varOperation  GConst.gvarOperation%type;
    varMessage    gconst.gvarMessage%type;
    varError      gconst.gvarError%type;
    type          Type_Risk is table of trsystem012%RowType;
    typRisk       Type_Risk;
    cursor curRisk is
      select *
        from trsystem012
        where risk_record_status between 10200001 and 10200004;
Begin
    numError := 0;
    varMessage := 'Generating Risk Figures for date: ' || AsonDate;
    datToday := AsonDate;

    delete from trsystem996;
    dbms_snapshot.refresh('mvewRiskDeals');
--    execute dbms_snapshot.refresh('mvewRiskDeals');
      --where crsk_ason_date = datToday;

    varOperation := 'Inserting outstanding deals (RiskPopulate)';
    insert into trsystem996(crsk_risk_type, crsk_currency_code, crsk_buy_sell,
      crsk_deal_date,crsk_deal_rate ,crsk_position_fcy, crsk_inr_amount, crsk_rate_usd,
      crsk_position_usd,crsk_rate_inr,crsk_position_inr,
      crsk_counter_party, crsk_user_id, crsk_maturity_month,
      crsk_deal_number, crsk_serial_number, crsk_maturity_date, crsk_ason_date,
      crsk_for_currency, crsk_other_currency)
    select 0, CurrencyCode, BuyCode, ExecuteDate, ExchangeRate, BalanceFcy,
      BalanceInr, USDRate, USDEq, INRRate, INREq, BankCode, UserID,
      DealMonth, DealNumber, DealSerial, DealMaturity, Today,
      OtherCode, OtherAmount
      from mvewRiskDeals;
--    insert into trsystem996(crsk_risk_type, crsk_currency_code, crsk_buy_sell,
--      crsk_deal_date,crsk_deal_rate ,crsk_position_fcy, crsk_inr_amount, crsk_rate_usd,
--      crsk_position_usd,crsk_rate_inr,crsk_position_inr,
--      crsk_counter_party, crsk_user_id, crsk_maturity_month,
--      crsk_deal_number, crsk_serial_number, crsk_maturity_date, crsk_ason_date,
--      crsk_for_currency, crsk_other_currency)
--    select 0, deal_base_currency, deal_buy_sell, deal_execute_date,deal_exchange_rate,
----  Deal Amount outstanding
--      fncGetOutstanding(deal_deal_number, deal_serial_number,
--        decode(DealType,
--          GConst.TRADEDEAL, GConst.UTILTRADEDEAL,
--          GConst.HEDGEDEAL, GConst.UTILHEDGEDEAL),
--        GConst.AMOUNTFCY, AsonDate),
---- Deal INR Outstanding
--      fncGetOutstanding(deal_deal_number, deal_serial_number,
--        decode(DealType,
--          GConst.TRADEDEAL, GConst.UTILTRADEDEAL,
--          GConst.HEDGEDEAL, GConst.UTILHEDGEDEAL),
--        GConst.AMOUNTINR, AsonDate),
----  USD Rate
--     pkgforexprocess.fncGetRate(deal_base_currency, 30400004, datToday, deal_buy_sell,
--        fncAllotMonth(deal_counter_party, datToday, deal_maturity_date)) USDRate,
----  USD Equivalent
--      round(fncGetOutstanding(deal_deal_number, deal_serial_number,
--                decode(DealType,
--                  GConst.TRADEDEAL, GConst.UTILTRADEDEAL,
--                  GConst.HEDGEDEAL, GConst.UTILHEDGEDEAL),
--                GConst.AMOUNTFCY, AsonDate) *
--        pkgforexprocess.fncGetRate(deal_base_currency, 30400004, datToday, deal_buy_sell,
--          fncAllotMonth(deal_counter_party, datToday, deal_maturity_date)), 2) UsdEq,
----  INR Rate
--     pkgforexprocess.fncGetRate(deal_base_currency, 30400003, datToday, deal_buy_sell,
--        fncAllotMonth(deal_counter_party, datToday, deal_maturity_date)) INRRate,
----  INR Equivalent
--      round(fncGetOutstanding(deal_deal_number, deal_serial_number,
--        decode(DealType,
--          GConst.TRADEDEAL, GConst.UTILTRADEDEAL,
--          GConst.HEDGEDEAL, GConst.UTILHEDGEDEAL),
--          GConst.AMOUNTFCY, AsonDate) *
--        pkgforexprocess.fncGetRate(deal_base_currency, 30400003, datToday, deal_buy_sell,
--          fncAllotMonth(deal_counter_party, datToday, deal_maturity_date)), 0) inrEq,
----  Other Fields
--      deal_counter_party, deal_user_id,
--      fncAllotMonth(deal_counter_party, datToday, deal_maturity_date),
--      deal_deal_number, deal_serial_number, deal_maturity_date, datToday,
--      deal_other_currency, deal_other_amount
--      from trtran001
--      where deal_hedge_trade = DealType
--      and deal_execute_date <= AsonDate
--      and (deal_complete_date is null or deal_complete_date > AsonDate)
--      and deal_record_status in
--        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED)
--   union
----  Cross Currency Deals
--   select 0, deal_other_currency, decode(deal_buy_sell,25300001, 25300002, 25300001),
--      	deal_execute_date, deal_exchange_rate,
----  Deal Amount outstanding
--      fncGetOutstanding(deal_deal_number, deal_serial_number,
--        decode(DealType,
--          GConst.TRADEDEAL, GConst.UTILTRADECROSS,
--          GConst.HEDGEDEAL, GConst.UTILHEDGECROSS),
--          GConst.AMOUNTFCY, AsonDate),
----  Deal INR outstanding
--      fncGetOutstanding(deal_deal_number, deal_serial_number,
--        decode(DealType,
--          GConst.TRADEDEAL, GConst.UTILTRADECROSS,
--          GConst.HEDGEDEAL, GConst.UTILHEDGECROSS),
--          GConst.AMOUNTINR, AsonDate),
----  USD Rate
--    	pkgforexprocess.fncGetRate(deal_other_currency, 30400004, datToday,
--        decode(deal_buy_sell,25300001,25300002, 25300001),
--        fncAllotMonth(deal_counter_party, datToday, deal_maturity_date)) USDRate,
----  USD Equivalent
--      round(fncGetOutstanding(deal_deal_number, deal_serial_number,
--        decode(DealType,
--          GConst.TRADEDEAL, GConst.UTILTRADECROSS,
--          GConst.HEDGEDEAL, GConst.UTILHEDGECROSS),
--          GConst.AMOUNTFCY, AsonDate) *
--       pkgforexprocess.fncGetRate(deal_other_currency,30400004,datToday,
--          decode(deal_buy_sell,25300001, 25300002, 25300001),
--          fncAllotMonth(deal_counter_party, datToday, deal_maturity_date)),2) UsdEq,
----  INR Rate
--      pkgforexprocess.fncGetRate(deal_other_currency, 30400003, datToday,
--        decode(deal_buy_sell,25300001, 25300002, 25300001),
--        fncAllotMonth(deal_counter_party, datToday, deal_maturity_date)) INRRate,
----  INR Equivalent
--      round(fncGetOutstanding(deal_deal_number, deal_serial_number,
--        decode(DealType,
--          GConst.TRADEDEAL, GConst.UTILTRADECROSS,
--          GConst.HEDGEDEAL, GConst.UTILHEDGECROSS),
--          GConst.AMOUNTFCY, AsonDate) *
--        pkgforexprocess.fncGetRate(deal_other_currency,30400003,datToday,
--          decode(deal_buy_sell,25300001, 25300002, 25300001),
--          fncAllotMonth(deal_counter_party, datToday, deal_maturity_date)), 0) inrEq,
----  Other Fields
--      deal_counter_party, deal_user_id,
--      fncAllotMonth(deal_counter_party, datToday, deal_maturity_date),
--      deal_deal_number, deal_serial_number, deal_maturity_date, datToday,
--      deal_base_currency, deal_base_amount
--      from trtran001
--      where  deal_hedge_trade = DealType
--      and deal_other_currency != GConst.INDIANRUPEE
--      and deal_execute_date <= AsonDate
--      and (deal_complete_date is null or deal_complete_date > AsonDate)
--      and deal_record_status in
--        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--    varOperation := 'Calculating Profit / Loss';
----- Changed on 08/08/08----------------------------------------------------
----    update trsystem996
----      set crsk_allowed_inr =
----      decode(crsk_buy_sell, 25300001, crsk_position_inr - crsk_inr_amount,
----        25300002, crsk_inr_amount - crsk_position_inr)
----      where crsk_ason_date = datToday;
--
--
--    update trsystem996
--      set crsk_mtm_rate =
--     fncGetRate(crsk_currency_code, crsk_for_currency, datToday, crsk_buy_sell,
--        pkgForexProcess.fncAllotMonth(crsk_counter_party,datToday,crsk_maturity_date),crsk_maturity_date),
--      crsk_mtm_currency = Round(crsk_position_fcy  *
--      fncGetRate(crsk_currency_code, crsk_for_currency, datToday, crsk_buy_sell,
--        crsk_maturity_month), 2),
--      crsk_wash_rate = decode(crsk_for_currency, 30400003, 1,
--        fncGetRate(crsk_for_currency, 30400003, datToday, crsk_buy_sell,
--          0, crsk_maturity_date)),
--       crsk_profit_loss=pkgreturnreport.fncgetprofitloss(crsk_position_fcy,
--      fncGetRate(crsk_currency_code, crsk_for_currency, datToday, crsk_buy_sell,
--        pkgForexProcess.fncAllotMonth(crsk_counter_party,datToday,crsk_maturity_date),crsk_maturity_date),
--        crsk_deal_rate,crsk_buy_sell)*decode(crsk_for_currency, 30400003, 1,
--        fncGetRate(crsk_for_currency, 30400003, datToday, crsk_buy_sell,
--          0, crsk_maturity_date))
--      where crsk_ason_date = datToday
--      and crsk_risk_type = 0
--      and exists
--      (select 'x'
--        from trtran001
--        where deal_deal_number = crsk_deal_number
--        and deal_serial_number = crsk_serial_number
--        and deal_base_currency = crsk_currency_code);

    update trsystem996
      set crsk_allowed_inr =
      decode(crsk_for_currency, 30400003,
        decode(crsk_buy_sell, 25300001,
          crsk_mtm_currency - crsk_other_currency,
          crsk_other_currency - crsk_mtm_currency),
        decode(crsk_buy_sell, 25300001,
          crsk_mtm_currency - crsk_other_currency,
          crsk_other_currency - crsk_mtm_currency) * crsk_wash_rate)
      where crsk_ason_date = datToday
      and crsk_risk_type = 0;

    varOperation := 'Updating USD Position for Profit/Loss';
    update trsystem996
      set crsk_allowed_usd =
      round(abs(crsk_allowed_inr) / pkgforexprocess.fncGetRate(30400004, 30400003, datToday,
        decode(crsk_buy_sell,25300001,25300002, 25300001),
        0, crsk_maturity_date) * decode(sign(crsk_allowed_inr), -1, -1, 1),2)
      where crsk_ason_date = datToday;

----------------------------------------------------------


    varOperation := 'Calculating Position for each currency';
    insert into trsystem996(crsk_risk_type, crsk_currency_code, crsk_ason_date,
    crsk_position_fcy, crsk_position_usd,crsk_position_inr)
    select 1, crsk_currency_code, datToday,
      sum(decode(crsk_buy_sell, 25300001, crsk_position_fcy, 0)) -
      sum(decode(crsk_buy_sell, 25300002, crsk_position_fcy, 0)),
      sum(decode(crsk_buy_sell, 25300001, crsk_position_usd, 0)) -
      sum(decode(crsk_buy_sell, 25300002, crsk_position_usd, 0)),
      sum(decode(crsk_buy_sell, 25300001, crsk_position_inr, 0)) -
      sum(decode(crsk_buy_sell, 25300002, crsk_position_inr, 0))
      from trsystem996
      where crsk_ason_date = datToday
      group by 1, crsk_currency_code, datToday;

    varOperation := 'Calculating Position for User and Currency wise';
    insert into trsystem996(crsk_risk_type, crsk_currency_code, crsk_ason_date,
    crsk_user_id, crsk_position_fcy, crsk_position_usd,crsk_position_inr)
    select 2, crsk_currency_code, datToday, crsk_user_id,
      sum(decode(crsk_buy_sell, 25300001, crsk_position_fcy, 0)) -
      sum(decode(crsk_buy_sell, 25300002, crsk_position_fcy, 0)),
      sum(decode(crsk_buy_sell, 25300001, crsk_position_usd, 0)) -
      sum(decode(crsk_buy_sell, 25300002, crsk_position_usd, 0)),
      sum(decode(crsk_buy_sell, 25300001, crsk_position_inr, 0)) -
      sum(decode(crsk_buy_sell, 25300002, crsk_position_inr, 0))
      from trsystem996
      where crsk_risk_type = 0
      and crsk_ason_date = datToday
      group by 2, crsk_user_id, crsk_currency_code, datToday ;

--  Gross Currency Exposure - Following codes are being used
--  1 - Day Light Limit
--  2 - Day Light Limit for Cross Currencies
--  3 -
--    open curRisk;
--    fetch curRisk bulk collect into typRisk;
--    numFlag := 0;
--
--    for numSerial in typRisk.First .. typRisk.Last
--    Loop
--      if typRisk(numSerial).risk_risk_type = GConst.RISKGROSSCURRENCY then
--        numFlag := 1;
--      End if;
--    End Loop;


    varOperation := 'Calculating Gross Currency Exposure';
    insert into trsystem996(crsk_risk_type, crsk_ason_date,
      crsk_position_usd, crsk_position_inr)
    select GConst.RISKGROSSCURRENCY, datToday,
      sum(decode(sign(crsk_position_fcy), -1, crsk_position_usd * -1, crsk_position_usd)),
      sum(decode(sign(crsk_position_fcy), -1, crsk_position_inr * -1, crsk_position_inr))
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = 1
      group by GConst.RISKGROSSCURRENCY, datToday;


    varOperation := 'Inserting Record for Combined Day Light Limit';
    insert into trsystem996(crsk_risk_type, crsk_ason_date,
      crsk_position_usd, crsk_position_inr, crsk_serial_number, crsk_limit_usd)
    select GConst.RISKDAYLIGHT, datToday, crsk_position_usd, crsk_position_inr,
      1, fncRiskLimit(datToday, GConst.RISKDAYLIGHT, GConst.OPTIONNO)
      from trsystem996
      where crsk_risk_type = GConst.RISKGROSSCURRENCY
      and crsk_ason_date = datToday;

    varOperation := 'Calculating Gross Currency Exposure for Cross Currency';
    insert into trsystem996(crsk_risk_type, crsk_ason_date, crsk_serial_number,
      crsk_position_usd, crsk_position_inr, crsk_limit_usd)
    select  GConst.RISKDAYLIGHT, datToday, 2,
      sum(decode(sign(crsk_position_fcy), -1, crsk_position_usd * -1, crsk_position_usd)),
      sum(decode(sign(crsk_position_fcy), -1, crsk_position_inr * -1, crsk_position_inr)),
      fncRiskLimit(datToday, GConst.RISKDAYLIGHT, GConst.OPTIONYES)
      from trsystem996, trtran001
      where crsk_ason_date = datToday
      and crsk_deal_number = deal_deal_number
      and deal_other_currency != GConst.INDIANRUPEE
      and crsk_risk_type = 0
      group by GConst.RISKDAYLIGHT, 2, datToday;

    varOperation := 'Inserting Record for Combined Overnight Limit';
    insert into trsystem996(crsk_risk_type, crsk_ason_date,
      crsk_position_usd, crsk_position_inr, crsk_serial_number, crsk_limit_usd)
    select GConst.RISKOVERNIGHT, datToday, crsk_position_usd, crsk_position_inr,
      1, fncRiskLimit(datToday, GConst.RISKOVERNIGHT, GConst.OPTIONNO)
      from trsystem996
      where crsk_risk_type = GConst.RISKGROSSCURRENCY
      and crsk_ason_date = datToday;

    varOperation := 'Inserting Record for Combined Overnight Cross Currency';
    insert into trsystem996(crsk_risk_type, crsk_ason_date, crsk_serial_number,
      crsk_position_usd, crsk_position_inr, crsk_limit_usd)
    select  GConst.RISKOVERNIGHT, datToday, 2,
      sum(decode(sign(crsk_position_fcy), -1, crsk_position_usd * -1, crsk_position_usd)),
      sum(decode(sign(crsk_position_fcy), -1, crsk_position_inr * -1, crsk_position_inr)),
      fncRiskLimit(datToday, GConst.RISKOVERNIGHT, GConst.OPTIONYES)
      from trsystem996, trtran001
      where crsk_ason_date = datToday
      and crsk_deal_number = deal_deal_number
      and deal_other_currency != GConst.INDIANRUPEE
      and crsk_risk_type = 0
      group by GConst.RISKOVERNIGHT, datToday, 20;

    varOperation := 'Calculating Net Currency Exposure';
    insert into trsystem996(crsk_risk_type, crsk_ason_date,
      crsk_position_usd, crsk_position_inr)
    select GConst.RISKNETCURRENCY, datToday,
      sum(crsk_position_usd ), sum(crsk_position_inr)
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = 1
      group by GConst.RISKNETCURRENCY, datToday;

    varOperation := 'Calculating Gross User Exposure';
    insert into trsystem996(crsk_risk_type, crsk_ason_date,
      crsk_position_usd, crsk_position_inr, crsk_user_id)
    select GConst.RISKGROSSCURRENCY, datToday,
      sum(decode(sign(crsk_position_fcy), -1, crsk_position_usd * -1, crsk_position_usd)),
      sum(decode(sign(crsk_position_fcy), -1, crsk_position_inr * -1, crsk_position_inr)),
      crsk_user_id
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = 2
      group by GConst.RISKGROSSCURRENCY, datToday, crsk_user_id;

    varOperation := 'Calculating Net User Exposure';
    insert into trsystem996(crsk_risk_type, crsk_ason_date,
      crsk_position_usd, crsk_position_inr, crsk_user_id)
    select GConst.RISKNETCURRENCY, datToday,
      sum(crsk_position_usd ), sum(crsk_position_inr), crsk_user_id
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = 2
      group by GConst.RISKNETCURRENCY, datToday, crsk_user_id;

    varOperation := 'Calculating Counter Party Exposure';
    insert into trsystem996(crsk_risk_type,  crsk_ason_date,
      crsk_position_usd, crsk_position_inr, crsk_counter_party)
    select GConst.RISKCOUNTERPARTY, datToday,
      sum(crsk_position_usd), sum(crsk_position_inr), crsk_counter_party
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = 0
      group by GConst.RISKCOUNTERPARTY, datToday, crsk_counter_party;

    varOperation := 'Calculating Gap Exposures';
    insert into trsystem996(crsk_risk_type, crsk_currency_code, crsk_buy_sell,
      crsk_ason_date, crsk_position_fcy, crsk_position_usd, crsk_position_inr)
    select decode(crsk_maturity_month, 0, GConst.RISKGAPSPOT,
        1, GConst.RISKGAPFORWARD1, 2, GConst.RISKGAPFORWARD2, 3, GConst.RISKGAPFORWARD3,
        4, GConst.RISKGAPFORWARD4, 5, GConst.RISKGAPFORWARD5, 6, GConst.RISKGAPFORWARD6,
        7, GConst.RISKGAPFORWARD7, 8, GConst.RISKGAPFORWARD8, 9, GConst.RISKGAPFORWARD9,
        10, GConst.RISKGAPFORWARD10, 11, GConst.RISKGAPFORWARD11, 12, GConst.RISKGAPFORWARD12),
      crsk_currency_code, 0, datToday,
        sum(decode(crsk_buy_sell, 25300001, crsk_position_fcy, 0)) -
        sum(decode(crsk_buy_sell, 25300002, crsk_position_fcy, 0)) Gap,
        sum(decode(crsk_buy_sell, 25300001, crsk_position_usd, 0)) -
        sum(decode(crsk_buy_sell, 25300002, crsk_position_usd, 0)) GapUsd,
        sum(decode(crsk_buy_sell, 25300001, crsk_position_inr, 0)) -
        sum(decode(crsk_buy_sell, 25300002, crsk_position_inr, 0)) GapInr
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = 0
      group by crsk_maturity_month, crsk_currency_code, 0, datToday
      order by crsk_currency_code, crsk_maturity_month;

    varOperation := 'Getting Mean Spot Rate';
    select round((drat_spot_bid + drat_spot_ask)/2,4)
      into numRate
      from trtran012
      where drat_currency_code = GConst.USDOLLAR
      and drat_for_currency = GConst.INDIANRUPEE
      and drat_effective_date = datToday
      and drat_serial_number =
      (select max(drat_serial_number)
        from trtran012
        where drat_currency_code = GConst.USDOLLAR
        and drat_for_currency = GConst.INDIANRUPEE
        and drat_effective_date = datToday);

--Now the losses are being netted against properties. If the user wants
--not to net it, only loss figures needs to be seleted

    varOperation := 'Calculating Stop Losses - Intra Day';
    select NVL(sum(cdel_profit_loss),0)
      into numTemp
      from trtran006, trtran001
      where cdel_deal_number = deal_deal_number
      and cdel_deal_serial = deal_serial_number
      and deal_execute_date = datToday
      and cdel_cancel_date = datToday
      and cdel_record_status not in(Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);

    if numTemp > 0 then
      insert into trsystem996(crsk_risk_type, crsk_ason_date,
        crsk_serial_number, crsk_position_usd, crsk_position_inr, crsk_limit_usd)
      values(GConst.RISKSTOPLOSSDAY, datToday, 1,
        round(numTemp / numRate,2), numTemp,
        fncRiskLimit(datToday, GConst.RISKSTOPLOSSDAY));
    End if;

    varOperation := 'Calculating Stop Losses - Daily';
    select NVL(sum(cdel_profit_loss),0)
      into numTemp
      from trtran006
      where cdel_cancel_date = datToday
      and cdel_record_status not in(10200005,10200006);

    if numTemp != 0 then
      insert into trsystem996(crsk_risk_type, crsk_ason_date,
        crsk_serial_number, crsk_position_usd, crsk_position_inr,
        crsk_limit_usd,crsk_profit_loss)
      values(GConst.RISKSTOPLOSSDAILY, datToday, 1,
        round(numTemp / numRate,2), numTemp,
        fncRiskLimit(datToday, GConst.RISKSTOPLOSSDAILY),numtemp);
    End if;

    insert into trsystem996(crsk_risk_type, crsk_ason_date,
      crsk_serial_number, crsk_position_usd, crsk_position_inr, crsk_limit_usd,crsk_profit_loss)
    select GConst.RISKSTOPLOSSDAILY, datToday, 2,
      NVL(sum(crsk_allowed_usd),0), NVL(sum(crsk_allowed_inr),0),
      fncRiskLimit(datToday, GConst.RISKSTOPLOSSDAILY),sum(crsk_profit_loss)
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = 0
      group by GConst.RISKSTOPLOSSDAILY, datToday, 2;

    varOperation := 'Calculating Stop Loss - Monthly';
    datTemp := Trunc(datToday, 'MM');
    select NVL(sum(cdel_profit_loss),0)
      into numTemp
      from trtran006
      where cdel_cancel_date between datTemp and datToday
      and cdel_record_status not in(Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);


    if numTemp > 0 then
      insert into trsystem996(crsk_risk_type, crsk_ason_date,
        crsk_serial_number, crsk_position_usd, crsk_position_inr,
        crsk_limit_usd)
      values(GConst.RISKSTOPLOSSMTHLY, datToday, 1,
        round(numTemp / numRate,2), numTemp,
        fncRiskLimit(datToday, GConst.RISKSTOPLOSSMTHLY));
    End if;

    insert into trsystem996(crsk_risk_type, crsk_ason_date,
      crsk_serial_number, crsk_position_usd, crsk_position_inr, crsk_limit_usd)
    select GConst.RISKSTOPLOSSMTHLY, datToday, 2,
      NVL(sum(crsk_allowed_usd),0), NVL(sum(crsk_allowed_inr),0),
      fncRiskLimit(datToday, GConst.RISKSTOPLOSSMTHLY)
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = 0
      group by GConst.RISKSTOPLOSSMTHLY, datToday, 2;

    varOperation := 'Calculating Stop Loss - Quarterly';
    datTemp := Trunc(datToday, 'Q');
    select NVL(sum(cdel_profit_loss),0)
      into numTemp
      from trtran006
      where cdel_cancel_date between datTemp and datToday
      and cdel_record_status not in(Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);


    if numTemp > 0 then
      insert into trsystem996(crsk_risk_type, crsk_ason_date,
        crsk_serial_number, crsk_position_usd, crsk_position_inr, crsk_limit_usd)
      values(GConst.RISKSTOPLOSSQTRLY, datToday, 1,
        round(numTemp / numRate,2), numTemp,
        fncRiskLimit(datToday, GConst.RISKSTOPLOSSQTRLY));
    End if;

    insert into trsystem996(crsk_risk_type, crsk_ason_date,
      crsk_serial_number, crsk_position_usd, crsk_position_inr, crsk_limit_usd)
    select GConst.RISKSTOPLOSSQTRLY, datToday, 2,
      NVL(sum(crsk_allowed_usd),0), NVL(sum(crsk_allowed_inr),0),
      fncRiskLimit(datToday, GConst.RISKSTOPLOSSQTRLY)
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = 0
      group by GConst.RISKSTOPLOSSQTRLY, datToday, 2;

    varOperation := 'Calculating Stop Losses - Yearly';
    select to_date('01-Mar-' || decode(sign(4 - to_number(to_char(datToday,'MM'))), 1,
      to_char(datToday, 'YYYY') -1 , to_char(datToday, 'YYYY')))
      into datTemp
      from dual;
    select NVL(sum(cdel_profit_loss),0)
      into numTemp
      from trtran006
      where cdel_cancel_date between datTemp and datToday
      and cdel_record_status not in(Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);


    if numTemp > 0 then
      insert into trsystem996(crsk_risk_type, crsk_ason_date,
        crsk_serial_number, crsk_position_usd, crsk_position_inr,
        crsk_limit_usd)
      values(GConst.RISKSTOPLOSSYERLY, datToday, 1,
        round(numTemp / numRate,2), numTemp,
        fncRiskLimit(datToday, GConst.RISKSTOPLOSSYERLY));
    End if;

    insert into trsystem996(crsk_risk_type, crsk_ason_date,
      crsk_serial_number, crsk_position_usd, crsk_position_inr, crsk_limit_usd)
    select GConst.RISKSTOPLOSSYERLY, datToday, 2,
      NVL(sum(crsk_allowed_usd),0), NVL(sum(crsk_allowed_inr),0),
      fncRiskLimit(datToday, GConst.RISKSTOPLOSSYERLY)
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = 0
      group by GConst.RISKSTOPLOSSYERLY, datToday, 2;

----------------------------------Commodity Risk Manjunath Reddy 15-Apr-2009
----Description For Fileds
----crsk_position_fcy   --No Of Lots
----crsk_position_usd   --Lot Price
----crsk_position_inr   --Traded Amount
----crsk_rate_usd       --product quantity
----crsk_for_currency   -- Exchange Code
----crsk_other_currency -- Product Code
--
--
--    varOperation := 'Inserting outstanding Commodity deals';
--    insert into trsystem996(crsk_risk_type, crsk_currency_code, crsk_buy_sell,
--      crsk_deal_date, crsk_position_fcy, crsk_position_inr, crsk_position_usd,
--      crsk_rate_usd, crsk_counter_party, crsk_user_id,
--      crsk_deal_number, crsk_maturity_date, crsk_ason_date,
--      crsk_for_currency,crsk_other_currency,crsk_maturity_month)
--      (select 200, cmdl_currency_code,cmdl_buy_sell,
--      cmdl_execute_date,
--      fncgetoutstanding(cmdl_deal_number,1,GConst.UTILCOMMODITYDEAL,Gconst.AmountFCY,datToday),
--      fncgetoutstanding(cmdl_deal_number,1,GConst.UTILCOMMODITYDEAL,Gconst.AmountINR,datToday),
--      fncCommDealRate(cmdl_deal_number),
--      --cmdl_lot_price,
--      cmdl_product_quantity,cmdl_counter_party,null,
--      cmdl_deal_number,cmdl_maturity_date,datToday,
--      cmdl_exchange_code,cmdl_product_code,
--      fncCommAllotMonth(datToday,cmdl_maturity_date)
--      from trtran051
--      where cmdl_process_complete= Gconst.OPTIONNO);
--
--
--    update trsystem996
--      set crsk_mtm_rate =
--      fncCommodityMTMRate(crsk_maturity_date, crsk_for_currency, crsk_other_currency,datToday)
--      where crsk_ason_date = datToday
--      and crsk_risk_type = 200;
----      and exists
----      (select 'x'
----        from trtran001
----        where deal_deal_number = crsk_deal_number
----        and deal_serial_number = crsk_serial_number
----        and deal_base_currency = crsk_currency_code);
--
--    update trsystem996
--      set crsk_allowed_inr =
--        decode(crsk_buy_sell, 25300001,
--          ((crsk_mtm_rate*crsk_rate_usd) - crsk_position_inr),
--          ( crsk_position_inr-(crsk_mtm_rate*crsk_rate_usd)))
--      where crsk_ason_date = datToday
--      and crsk_risk_type = 200;
--
----    varOperation := 'Updating USD Position for Profit/Loss';
----    update trsystem996
----      set crsk_allowed_usd =
----      round(abs(crsk_allowed_inr) / pkgforexprocess.fncGetRate(30400004, 30400003, datToday,
----        decode(crsk_buy_sell,25300001,25300002, 25300001),
----        0, crsk_maturity_date) * decode(sign(crsk_allowed_inr), -1, -1, 1),2)
----      where crsk_ason_date = datToday;
----
--
--    varOperation := 'Calculating Commodity Gross Currency Exposure';
--    insert into trsystem996(crsk_risk_type, crsk_ason_date,
--      crsk_position_inr)
--    select GConst.CRISKGROSSCURRENCY, datToday,
--      sum(crsk_position_inr)
--      from trsystem996
--      where crsk_ason_date = datToday
--      and crsk_risk_type = 200
--      group by GConst.CRISKGROSSCURRENCY, datToday;
--
--
--    varOperation := 'Calculating Commodity  Net Currency Exposure';
--    insert into trsystem996(crsk_risk_type, crsk_ason_date,
--      crsk_position_inr)
--    select GConst.CRISKNETCURRENCY, datToday,
--      sum(decode(crsk_buy_sell,Gconst.SALEDEAL, -1*crsk_position_inr,crsk_position_inr))
--      from trsystem996
--      where crsk_ason_date = datToday
--      and crsk_risk_type = 200
--      group by GConst.CRISKNETCURRENCY, datToday;
--
--
--    varOperation := 'Calculating Commodity Gap Exposures';
--    insert into trsystem996(crsk_risk_type,crsk_buy_sell,
--      crsk_ason_date, crsk_position_inr)
--    select decode(crsk_maturity_month, 0, GConst.CRISKGAPSPOT,
--        1, GConst.CRISKGAPFORWARD1, 2, GConst.CRISKGAPFORWARD2, 3, GConst.CRISKGAPFORWARD3,
--        4, GConst.CRISKGAPFORWARD4, 5, GConst.CRISKGAPFORWARD5, 6, GConst.CRISKGAPFORWARD6,
--        7, GConst.CRISKGAPFORWARD7, 8, GConst.CRISKGAPFORWARD8, 9, GConst.CRISKGAPFORWARD9,
--        10, GConst.CRISKGAPFORWARD10, 11, GConst.CRISKGAPFORWARD11, 12, GConst.CRISKGAPFORWARD12),
--        0, datToday,
--        sum(decode(crsk_buy_sell, Gconst.PURCHASEDEAL, crsk_position_inr, 0)) -
--        sum(decode(crsk_buy_sell, Gconst.SALEDEAL, crsk_position_inr, 0)) Gap
--      from trsystem996
--      where crsk_ason_date = datToday
--      and crsk_risk_type = 200
--      group by crsk_maturity_month,datToday
--      order by crsk_maturity_month,datToday;
--
--    varOperation := 'Calculating Commodity Stop Losses - Daily';
--    select NVL(sum(crev_profit_loss),0)
--      into numTemp
--      from trtran053
--      where crev_execute_date = datToday
--      and crev_record_status not in(Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
--
--    if numTemp > 0 then
--      insert into trsystem996(crsk_risk_type, crsk_ason_date,
--        crsk_serial_number,  crsk_position_inr,
--        crsk_limit_usd)
--      values(GConst.CRISKSTOPLOSSDAILY, datToday, 1,
--        numTemp,
--        fncRiskLimit(datToday, GConst.CRISKSTOPLOSSDAILY));
--    End if;
--
--    insert into trsystem996(crsk_risk_type, crsk_ason_date,
--      crsk_serial_number, crsk_position_inr, crsk_limit_inr)
--    select GConst.CRISKSTOPLOSSDAILY, datToday, 2,
--      NVL(sum(crsk_allowed_inr),0),
--      fncRiskLimit(datToday, GConst.CRISKSTOPLOSSDAILY)
--      from trsystem996
--      where crsk_ason_date = datToday
--      and crsk_risk_type = 200
--      group by GConst.CRISKSTOPLOSSDAILY, datToday, 2;
--
--    varOperation := 'Calculating Commodity Stop Loss - Monthly';
--    datTemp := Trunc(datToday, 'MM');
--    select NVL(sum(crev_profit_loss),0)
--      into numTemp
--      from trtran053
--      where crev_execute_date between datTemp and datToday
--      and crev_record_status not in(Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
--
--    select NVL(sum(cmtr_profit_loss),0)
--      into numTemp1
--      from trtran052
--      where cmtr_mtm_date between datTemp and datToday
--      and cmtr_record_status not in(Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
--
--    numtemp := numtemp+numtemp1;
--
--    if numTemp < 0 then
--      insert into trsystem996(crsk_risk_type, crsk_ason_date,
--        crsk_serial_number,  crsk_position_inr,
--        crsk_limit_inr)
--      values(GConst.CRISKSTOPLOSSMTHLY, datToday, 1,
--        numTemp,
--        fncRiskLimit(datToday, GConst.CRISKSTOPLOSSMTHLY));
--    End if;
--
--    insert into trsystem996(crsk_risk_type, crsk_ason_date,
--      crsk_serial_number,  crsk_position_inr, crsk_limit_inr)
--    select GConst.CRISKSTOPLOSSMTHLY, datToday, 2,
--       NVL(sum(crsk_allowed_inr),0),
--      fncRiskLimit(datToday, GConst.CRISKSTOPLOSSMTHLY)
--      from trsystem996
--      where crsk_ason_date = datToday
--      and crsk_risk_type = 200
--      group by GConst.RISKSTOPLOSSMTHLY, datToday, 2;
--
--    varOperation := 'Calculating Commodity Stop Loss - Quarterly';
--    datTemp := Trunc(datToday, 'Q');
--    select NVL(sum(crev_profit_loss),0)
--      into numTemp
--      from trtran053
--      where crev_execute_date between datTemp and datToday
--      and crev_record_status not in(Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
--
--    select NVL(sum(cmtr_profit_loss),0)
--      into numTemp1
--      from trtran052
--      where cmtr_mtm_date between datTemp and datToday
--      and cmtr_record_status not in(Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
--
--    numtemp := numtemp+numtemp1;
--
--    if numTemp > 0 then
--      insert into trsystem996(crsk_risk_type, crsk_ason_date,
--        crsk_serial_number,  crsk_position_inr, crsk_limit_inr)
--      values(GConst.CRISKSTOPLOSSQTRLY, datToday, 1,
--        numTemp,
--        fncRiskLimit(datToday, GConst.CRISKSTOPLOSSQTRLY));
--    End if;
--
--    insert into trsystem996(crsk_risk_type, crsk_ason_date,
--      crsk_serial_number,  crsk_position_inr, crsk_limit_inr)
--    select GConst.CRISKSTOPLOSSQTRLY, datToday, 2,
--      NVL(sum(crsk_allowed_inr),0),
--      fncRiskLimit(datToday, GConst.CRISKSTOPLOSSQTRLY)
--      from trsystem996
--      where crsk_ason_date = datToday
--      and crsk_risk_type = 200
--      group by GConst.RISKSTOPLOSSQTRLY, datToday, 2;
--
--    varOperation := 'Calculating Stop Losses - Yearly';
--    select to_date('01-Mar-' || decode(sign(4 - to_number(to_char(datToday,'MM'))), 1,
--      to_char(datToday, 'YYYY') -1 , to_char(datToday, 'YYYY')))
--      into datTemp
--      from dual;
--
--    select NVL(sum(crev_profit_loss),0)
--      into numTemp
--      from trtran053
--      where crev_execute_date between datTemp and datToday
--      and crev_record_status not in(Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
--
--    select NVL(sum(cmtr_profit_loss),0)
--      into numTemp1
--      from trtran052
--      where cmtr_mtm_date between datTemp and datToday
--      and cmtr_record_status not in(Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
--
--    numtemp := numtemp+numtemp1;
--
--    if numTemp < 0 then
--      insert into trsystem996(crsk_risk_type, crsk_ason_date,
--        crsk_serial_number,  crsk_position_inr,
--        crsk_limit_usd)
--      values(GConst.CRISKSTOPLOSSYERLY, datToday, 1,
--         numTemp,
--        fncRiskLimit(datToday, GConst.CRISKSTOPLOSSYERLY));
--    End if;
--
--    insert into trsystem996(crsk_risk_type, crsk_ason_date,
--      crsk_serial_number,  crsk_position_inr, crsk_limit_inr)
--    select GConst.CRISKSTOPLOSSYERLY, datToday, 2,
--      NVL(sum(crsk_allowed_inr),0),
--      fncRiskLimit(datToday, GConst.CRISKSTOPLOSSYERLY)
--      from trsystem996
--      where crsk_ason_date = datToday
--      and crsk_risk_type = 200
--      group by GConst.CRISKSTOPLOSSYERLY, datToday, 2;
--

    commit;
    return numError;
Exception
    when others then
      varError := SQLERRM;
      varerror := 'RiskPop: ' || varmessage || varoperation || varerror;
      raise_application_error(-20101,   varerror);
      Rollback;
      return -1;
End fncRiskPopulate;

FUNCTION GETCOUNTERPARTY(REFNO IN VARCHAR)
RETURN VARCHAR2
IS

DEALNO      VARCHAR2(30 BYTE);
COUNTPARTY  VARCHAR2(15 BYTE);

begin

SELECT COPT_COUNTER_PARTY into  COUNTPARTY
  FROM TRTRAN071,TRTRAN004
  WHERE COPT_DEAL_NUMBER = HEDG_DEAL_NUMBER
    AND HEDG_TRADE_REFERENCE = REFNO
    and copt_execute_date =
    (SELECT MAX(COPT_EXECUTE_DATE)
    FROM TRTRAN071 A
    WHERE a.copt_deal_number = HEDG_DEAL_NUMBER and  ROWNUM = 1)AND ROWNUM = 1;


RETURN COUNTPARTY;

Exception
    When others then
         SELECT nvl(DEAL_COUNTER_PARTY,0) into  COUNTPARTY
      FROM TRTRAN001,TRTRAN004
      WHERE DEAL_DEAL_NUMBER = HEDG_DEAL_NUMBER
      AND HEDG_TRADE_REFERENCE = REFNO AND ROWNUM = 1;
      return COUNTPARTY;

END GETCOUNTERPARTY;

FUNCTION fncHedgeRisk ( WorkDate in Date) RETURN NUMBER iS
  numHedgeAmt       number(15,2);
  numReversalAmt    number(15,2);
  numTradeAmt       number(15,2);
  numOrderValue     number(15,2);
  numLossRate       number(15,2);
  numLossPercent    number(15,2);
  numLossLevel      number(15,2);
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
  varOperation  GConst.gvarOperation%type;
  varMessage    gconst.gvarMessage%type;
  varError      gconst.gvarError%type;
BEGIN

 delete from trsystem994 ;
 varOperation := 'Calculating Hedge Risk';
for curfields in
           (SELECT trad_company_code Company,trad_import_export impexp, trad_trade_reference tradereference,trad_trade_rate as traderate,trad_import_export as importExport,
                        trad_trade_currency AS tradecurrency, trad_maturity_date AS maturitydate,
                        trad_trade_fcy  AS totamount,trad_trade_inr as TotInr,trad_entry_date as entrydate,trad_local_bank as counterparty,
                        pkgforexprocess.fncgetrate(trad_trade_currency,   30400003,  WorkDate,   (case when(trad_import_export < 25900050) then     25300001 else  25300002 end)) as M2MRate
                  FROM trtran002
                  WHERE trad_record_status not in (10200005,10200006)
                  and trad_process_complete=12400002)
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

      numVaryRate:=(curfields.traderate * numlimitPercent)/100;

     varOperation := 'Calculation reversal Amount For a Particular LC' ||curfields.tradereference;
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
     numTradeAmt := curfields.totamount-numReversalAmt;
     numOrderValue:= numTradeAmt;
     varOperation := 'Calculation of Hedged Amount ' ||curfields.tradereference;
      begin
           SELECT deal_base_currency AS basecurrency,deal_other_currency as othercurrency,
                  (sum(hedg_hedged_fcy) - sum(nvl(cdel_cancel_amount,    0))) AS amountfcy
                  into numHBaseCurrency,numHOtherCurrency,numHedgeAmt
           FROM trtran001,trtran004,trtran006
           WHERE hedg_deal_number = cdel_deal_number(+)
           and deal_process_complete=gconst.optionNo
           AND deal_deal_number = hedg_deal_number
           AND hedg_record_status NOT IN(10200005,    10200006)
           and hedg_trade_reference=curfields.tradereference
           AND nvl(cdel_record_status,    10200001) NOT IN(10200005,    10200006)
           group by hedg_trade_reference,deal_base_currency,deal_other_currency;
      exception
        when no_data_found then
          numHedgeAmt:=0;
      end;

      varOperation := 'calculating un hedge amount ';
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
   varOperation := 'Geting the Serial number of '|| curfields.tradereference;
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

    if (numLossPercent > abs(numtemp-numtemp1)) then
        numloss:=numLossPercent;
    else
        numloss:=abs(numtemp-numtemp1);
    end if;

    numloss := (numloss /  pkgforexprocess.fncgetrate(curfields.tradecurrency,   30400003,  WorkDate,   (case when(curfields.impexp < 25900050) then     25300001 else  25300002 end)));



     if curfields.importExport < 25900050 then
       if (curfields.traderate < curfields.M2MRate) then
          numloss := numloss *-1;
       end if;
       if ((abs(curfields.traderate-curfields.M2MRate) < numVaryRate) or (numLossPercent < abs(numtemp-numtemp1))) then
          goto  SkipInsert;
       end if;
    else
       if (curfields.traderate > curfields.M2MRate) then
          numloss := numloss *-1;
       end if;

       if ((abs(curfields.traderate-curfields.M2MRate) > numVaryRate) or (numLossPercent < abs(numtemp-numtemp1)))then
           goto SkipInsert;
       end if;
    end if;
   -- bms_output.put_line('Open : ' || numPosFcy || ' Re: ' || numPosInr);
     if (numTradeAmt !=0) then
        numLossLevel := (((curfields.traderate-curfields.M2MRate)*100)/curfields.traderate);
     else
        numLossLevel :=0;
     end if;
    if numserialno !=0 then
       goto SkipInsert;
    end if;
   insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,rdel_serial_number,
                          rdel_risk_date, rdel_risk_type,RDEL_LIMIT_USD, rdel_amount_excess,
                          rdel_action_taken, rdel_stake_holder, rdel_mobile_number, rdel_email_id,rdel_message_text)
                  values (curfields.Company,varriskReference,curfields.tradereference,numserialno, WorkDate,numriskType,
                          numlimitPercent,numloss,numactionTaken, varstackHolder, varmobileNo, varemailID,
                          'Hedge Spot Loss Limit Violation No: ' || curfields.tradereference || ' UnHedge Amount : ' || to_char(numTradeAmt) || ' Trade Order Rate : ' || to_char(curfields.traderate) || ' M2M Rate : ' || to_char(curfields.M2MRate) || ' Loss(INR): ' || to_char(numloss));

  <<SkipInsert>>

   insert into trsystem994 (stop_ason_date,stop_oder_number,stop_order_date,stop_buy_sell,
                            stop_currency_code,stop_counter_party,stop_maturity_date,stop_order_value,
                            stop_order_inr,stop_order_rate,stop_hedge_portion,stop_unhedge_portion,
                            stop_unhedge_percent,stop_loss_rate,stop_m2m_rate,stop_loss_percent,stop_loss_inr)
                    values (WorkDate,curfields.tradereference,curfields.entrydate,curfields.importExport,
                            curfields.tradecurrency,curfields.counterparty,curfields.maturitydate,numOrderValue,
                            numOrderValue * curfields.traderate ,curfields.traderate,(numOrderValue-numTradeAmt),numTradeAmt,
                            round(((numTradeAmt/numOrderValue) * 100),2),round((curfields.traderate-numVaryRate),4),round(curfields.M2MRate,4), numLossLevel, numloss);

   numloss :=0;
end loop;

  RETURN 0;
  Exception

  when others then
      varError := SQLERRM;
      varerror := 'PositionGen: ' || varmessage || varoperation || varerror;
      raise_application_error(-20101,   varerror);
      Rollback;

      return -1;

END fncHedgeRisk;

---commented by aakash 11-jun-13 12:32 pm
--Function fncPositionGenerate
--    ( UserID in varchar2,
--      AsonDate in date)
--    return number
--    is
--
--    PRAGMA AUTONOMOUS_TRANSACTION;
----  Created on 19/03/08
--    datToday        date;
--    datTemp         date;
--    numError        number;
--    varOperation    GConst.gvarOperation%type;
--    varMessage      GConst.gvarMessage%type;
--    varError        GConst.gvarError%type;
----    Type tpPosition is ref cursor return trsystem997%ROWTYPE;
----    curTermLoan     tpPosition;
----    recPosition     trsystem997%ROWTYPE;
--Begin
--    numError := 0;
--    varMessage := 'Generating Position Figures for date: ' || AsonDate;
--    datToday := AsonDate;
--
--    delete from trsystem997;
--    varOperation := 'Inserting records for Trade Details';
--    insert into trsystem997
--    (posn_company_code, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month)
--    select trad_company_code, trad_trade_currency, trad_import_export,
--      trad_trade_reference, 0, trad_entry_date,
--      fncGetOutstanding(trad_trade_reference,0,GConst.UTILEXPORTS,
--        GConst.AMOUNTFCY, AsonDate) tradefcy,trad_trade_rate,0,
--      fncGetOutstanding(trad_trade_reference,0,GConst.UTILEXPORTS,
--        GConst.AMOUNTINR, AsonDate) tradeinr, 0, UserID, null,TRAD_LOCAL_BANK,
--      trad_maturity_date,fncAllotMonth(AsonDate, trad_maturity_date)
--      from trtran002
--      where (trad_complete_date is null or trad_complete_date > AsonDate)
--      and trad_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and trad_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--      numError := SQl%ROWCOUNT;
--
--
--    varOperation := 'Inserting records for Trade Contracts';
--    insert into trsystem997
--    (posn_company_code, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month)
--    select deal_company_code CompanyCode, deal_base_currency,
--      decode(fncAllotMonth(deal_counter_party, AsonDate, deal_maturity_date), 0,
--        decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADEBUYSPOT,
--            GConst.SALEDEAL, GConst.TRADESALESPOT),
--        decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADEBUYFORWARD,
--            GConst.SALEDEAL, GConst.TRADESALEFORWARD)) AccountCode,
--      deal_deal_number, deal_serial_number, deal_execute_date,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADEDEAL,
--        GConst.AMOUNTFCY, AsonDate) tradefcy,
--      decode(deal_other_currency, GConst.INDIANRUPEE, deal_exchange_rate, deal_local_rate)
--        deal_exchange_rate,0,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADEDEAL,
--        GConst.AMOUNTINR, AsonDate) tradeinr,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate, deal_maturity_date)
--      from trtran001
--      where ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_hedge_trade = GConst.TRADEDEAL
--      and deal_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED)
--    union
----  Cross Currency Deals
--    select deal_company_code CompanyCode, deal_other_currency,
--      decode(fncAllotMonth(deal_counter_party, AsonDate, deal_maturity_date), 0,
--         decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADESALESPOT,
--            GConst.SALEDEAL, GConst.TRADEBUYSPOT),
--         decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADESALEFORWARD ,
--            GConst.SALEDEAL, GConst.TRADEBUYFORWARD)) AccountCode,
--      deal_deal_number, deal_serial_number, deal_execute_date,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADECROSS,
--        GConst.AMOUNTFCY, AsonDate) tradefcy, round(deal_amount_local / deal_other_amount,4),0,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADECROSS,
--        GConst.AMOUNTINR, AsonDate) tradeinr,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate, deal_maturity_date)
--      from trtran001
--      where deal_other_currency != GConst.INDIANRUPEE
--      and deal_hedge_trade = GConst.TRADEDEAL
--      and deal_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--
----
--       varOperation := 'Inserting records for Hedge which are all not at linked and partially linked Contracts';
--    insert into trsystem997
--    (posn_company_code, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month)
--    select deal_company_code CompanyCode, deal_base_currency,
--      decode(fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number)), 0,
--        decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADEBUYSPOT,
--            GConst.SALEDEAL, GConst.TRADESALESPOT),
--        decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADEBUYFORWARD,
--            GConst.SALEDEAL, GConst.TRADESALEFORWARD)) AccountCode,
--      deal_deal_number, 0 , deal_execute_date,
--     fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGEDEAL,
--        GConst.AMOUNTFCY, AsonDate) tradefcy, deal_exchange_rate,
--      --decode(deal_other_currency, GConst.INDIANRUPEE, deal_exchange_rate, deal_local_rate),
--        0,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGEDEAL,
--        GConst.AMOUNTINR, AsonDate) tradeinr,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number))
--      from trtran001
--      where ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_execute_date <= AsonDate
--      and deal_hedge_trade in (GConst.HEDGEDEAL, GCONST.FTDEAL)
--      and deal_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGEDEAL,
--        GConst.AMOUNTFCY, AsonDate) >0
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--
--   -- union
----  Cross Currency Deals
--    insert into trsystem997
--    (posn_company_code, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month)
--    select deal_company_code, deal_other_currency,
--      decode(fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number)), 0,
--         decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADESALESPOT,
--            GConst.SALEDEAL, GConst.TRADEBUYSPOT),
--         decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADESALEFORWARD ,
--            GConst.SALEDEAL, GConst.TRADEBUYFORWARD)) AccountCode,
--      deal_deal_number, deal_serial_number, deal_execute_date,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGECROSS,
--        GConst.AMOUNTFCY, AsonDate) tradefcy,
--      round(deal_amount_local / deal_other_amount,4),0,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGECROSS,
--        GConst.AMOUNTINR, AsonDate) tradeinr,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number))
--      from trtran001
--      where  deal_other_currency != GConst.INDIANRUPEE
--      and deal_hedge_trade in (GConst.HEDGEDEAL, GConst.FTDEAL)
--      and deal_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_execute_date <= AsonDate
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
----    varOperation := 'Inserting records for Hedge Contracts';
----    insert into trsystem997
----    (posn_company_code, posn_currency_code, posn_account_code,
----     posn_reference_number, posn_reference_serial, posn_reference_date,
----     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
----     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
----     posn_counter_party, posn_due_date, posn_maturity_month)
----    select hedg_company_code CompanyCode, deal_base_currency,
----      decode(fncAllotMonth(deal_counter_party, AsonDate,
----        pkgReturnCursor.fncRollover(deal_deal_number)), 0,
----        decode(deal_buy_sell,
----            GConst.PURCHASEDEAL, GConst.TRADEBUYSPOT,
----            GConst.SALEDEAL, GConst.TRADESALESPOT),
----        decode(deal_buy_sell,
----            GConst.PURCHASEDEAL, GConst.TRADEBUYFORWARD,
----            GConst.SALEDEAL, GConst.TRADESALEFORWARD)) AccountCode,
----      deal_deal_number, rownum, deal_execute_date,
----      fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
----        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference) tradefcy,
----      decode(deal_other_currency, GConst.INDIANRUPEE, deal_exchange_rate, deal_local_rate),
----        0, decode(deal_other_currency,30400003,(fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
----        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference)* deal_exchange_rate),
----        (fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
----        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference)* deal_local_rate))
------      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGEDEAL,
------        GConst.AMOUNTINR, AsonDate, hedg_trade_reference) tradeinr
----        ,0,
----      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
----      fncAllotMonth(deal_counter_party, AsonDate,
----        pkgReturnCursor.fncRollover(deal_deal_number))
----      from trtran001, trtran004
----      where deal_deal_number = hedg_deal_number
----      and deal_serial_number = hedg_deal_serial
----      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
----      and deal_execute_date <= AsonDate
----      and deal_hedge_trade = GConst.HEDGEDEAL
----      and deal_record_status in
----      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED)
----      and pkgforexprocess.fncGetOutstanding(deal_deal_number, deal_serial_number,2,1, AsonDate) =0;
-- varOperation := 'Inserting records for Hedge Contracts';
--    insert into trsystem997
--    (posn_company_code, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month)
--    select hedg_company_code CompanyCode, deal_base_currency,
--      decode(fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number)), 0,
--        decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADEBUYSPOT,
--            GConst.SALEDEAL, GConst.TRADESALESPOT),
--        decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADEBUYFORWARD,
--            GConst.SALEDEAL, GConst.TRADESALEFORWARD)) AccountCode,
--      deal_deal_number, rownum+100, deal_execute_date,
--      fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
--        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference) tradefcy,
--      decode(deal_other_currency, GConst.INDIANRUPEE, deal_exchange_rate, deal_local_rate),
--        0, decode(deal_other_currency,30400003,(fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
--        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference)* deal_exchange_rate),
--        (fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
--        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference)* deal_local_rate))
----      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGEDEAL,
----        GConst.AMOUNTINR, AsonDate, hedg_trade_reference) tradeinr
--        ,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number))
--      from trtran001, trtran004
--      where deal_deal_number = hedg_deal_number
--      and deal_serial_number = hedg_deal_serial
--      and deal_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_execute_date <= AsonDate
--      and deal_hedge_trade in (GConst.HEDGEDEAL, GConst.FTDEAL)
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
----    union
----  Cross Currency Deals
----abhijit commented on 05/07/2012
--  varOperation := 'Inserting Cross Currency Hedge Contracts';
--    insert into trsystem997
--    (posn_company_code, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month)
--    select hedg_company_code, deal_other_currency,
--      decode(fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number)), 0,
--         decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADESALESPOT,
--            GConst.SALEDEAL, GConst.TRADEBUYSPOT),
--         decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADESALEFORWARD ,
--            GConst.SALEDEAL, GConst.TRADEBUYFORWARD)) AccountCode,
--      deal_deal_number,rownum , deal_execute_date,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGECROSS,
--        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference) tradefcy,
--        deal_exchange_Rate,0,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGECROSS,
--        GConst.AMOUNTINR, AsonDate, hedg_trade_reference) tradeinr,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number))
--      from trtran001, trtran004
--      where deal_deal_number = hedg_deal_number
--      and deal_serial_number = hedg_deal_serial
--      and deal_other_currency != GConst.INDIANRUPEE
--      and deal_hedge_trade in (GConst.HEDGEDEAL, GConst.FTDEAL)
--      and deal_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_execute_date <= AsonDate
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--    varOperation := 'Inserting records for FCY Loans';
--    insert into trsystem997
--    (posn_company_code, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month)
--    select fcln_company_code, fcln_currency_code,
--      decode(fcln_loan_type, GConst.LOANBUYERSCREDIT, GConst.TRADEBUYERCREDIT,
--      GConst.LOANPCFC, GConst.TRADEPCFC, GConst.LOANPSCFC, GConst.TRADEPSCFC),
--      fcln_loan_number, 0, fcln_sanction_date,
--      fncGetOutstanding(fcln_loan_number, 0,GConst.UTILFCYLOAN,
--        GConst.AMOUNTFCY, AsonDate) fcln_sanctioned_fcy,fcln_conversion_rate,0,
--      fncGetOutstanding(fcln_loan_number, 0,GConst.UTILFCYLOAN,
--        GConst.AMOUNTINR, AsonDate) fcln_sanctioned_inr,0,
--      UserID, null, fcln_local_bank, fcln_maturity_to,
--      fncAllotMonth(AsonDate, fcln_maturity_to)
--      from trtran005
--      where ((fcln_complete_date is null) or (fcln_complete_date > AsonDate))
--      and fcln_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and fcln_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--  --    and fcln_loan_type not in (GConst.LOANBUYERSCREDIT);
-- ---kumar.h updates 0n 12/05/09  for buyers credit
--     varOperation := 'Inserting records for Buyers Credit';
--    insert into trsystem997
--    (posn_company_code, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month)
--    select bcrd_company_code, bcrd_currency_code,
--           GConst.TRADEBUYERCREDIT,
--           bcrd_buyers_credit, 0, bcrd_sanction_date,
--      fncGetOutstanding(bcrd_buyers_credit, 0,GConst.UTILBCRLOAN,
--        GConst.AMOUNTFCY, AsonDate) bcrd_sanctioned_fcy,bcrd_conversion_rate,0,
--      fncGetOutstanding(bcrd_buyers_credit, 0,GConst.UTILBCRLOAN,
--        GConst.AMOUNTINR, AsonDate) bcrd_sanctioned_inr,0,
--      UserID, null, bcrd_local_bank, bcrd_due_date,
--      fncAllotMonth(AsonDate, bcrd_due_date)
--      from BuyersCredit
--      where ((bcrd_completion_date is null) or (bcrd_completion_date > AsonDate))
--      and bcrd_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and bcrd_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--     ---kumar.h updates 0n 12/05/09  for buyers credit
----------------------------------------------------Money Module Added by Manjunath Reddy  on 09-04-2009----------------------------------
----24900011		Short Term Borrowing
--  varOperation := 'Insert Money Module Date in to Assests ';
--    insert into trsystem997
--     (posn_company_code, posn_currency_code, posn_account_code,
--      posn_reference_number, posn_reference_serial, posn_reference_date,
--      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--      posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--      posn_counter_party, posn_due_date, posn_maturity_month,posn_product_code)
--     select mdel_company_code, mdel_currency_code,
--      decode( mdel_account_head,24900011,Gconst.MONEYBORROWING,Gconst.TRADEBUYERCREDIT),
--      mdel_deal_number, 0, mdel_execute_date,
--      mdel_deal_amount,mdel_exchange_rate,mdel_exchange_rate,
--      mdel_amount_local,0,UserID, null,
--      mdel_counter_party, mdel_due_date,1,mdel_account_head
--      from trtran031
--      where
--      --((mdel_complete_date is null) or (mdel_complete_date > AsonDate))
--      mdel_process_complete= Gconst.optionNO
--      and mdel_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and mdel_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--
--    varOperation := 'Calculating M2M Rates';
--    update trsystem997
--      set posn_m2m_inrrate =  fncGetRate
--      (posn_currency_code,30400003, AsonDate, 0, posn_maturity_month, posn_due_date),
--      posn_usd_rate = fncGetRate
--      (30400004, 30400003, AsonDate, 0, posn_maturity_month, posn_due_date);
--
--    update trsystem997
--      set posn_revalue_inr =
--        round(posn_transaction_amount * posn_m2m_inrrate,0),
--        posn_revalue_usd =
--        round((posn_transaction_amount * posn_m2m_inrrate) / posn_usd_rate,2),
--        posn_position_inr =
--        decode(sign(25900050 - posn_account_code), 1,
--        round(posn_transaction_amount * posn_m2m_inrrate,0) - posn_inr_value,
--        -1, posn_inr_value - round(posn_transaction_amount * posn_m2m_inrrate,0));
--
--
--
------------------------------------------------------Commodity Added by Manjunath Reddy  on 09-04-2009----------------------------------
--varOperation := 'Insert Commodity Module in to Assests ';
---- posn_transaction_amount     No of LOts
---- posn_fcy_rate               Lot Price
---- posn_usd_rate               Lot Size
---- posn_inr_value              Transaction Amount
---- posn_m2m_inrrate            M2M Lot Price
---- posn_revalue_inr            Tansaction Amount For M2m Rate
---- posn_position_inr           Profit LOSS
--
--    insert into trsystem997
--     (posn_company_code, posn_currency_code, posn_account_code,
--      posn_reference_number, posn_reference_serial, posn_reference_date,
--      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--      posn_user_id, posn_dealer_id,
--      posn_counter_party, posn_due_date, posn_maturity_month, posn_product_code,
--      posn_m2m_inrrate)
--     select cmdl_company_code, cmdl_currency_code,
--      decode(cmdl_hedge_trade,gconst.HEDGEDEAL,decode(cmdl_buy_sell,Gconst.PURCHASEDEAL,Gconst.COMMODITYHEDGEBUY,
--             Gconst.SALEDEAL,Gconst.COMMODITYHEDGESALE),gconst.TRADEDEAL,
--            decode(cmdl_buy_sell,Gconst.PURCHASEDEAL,Gconst.COMMODITYTRADEBUY,Gconst.SALEDEAL,Gconst.COMMODITYTRADESALE)),
--      cmdl_deal_number, 0, cmdl_execute_date,
--      fncGetOutstanding(cmdl_deal_number, 0,GConst.UTILCOMMODITYDEAL,
--      GConst.AMOUNTFCY, AsonDate),fncCommDealRate(cmdl_deal_number),(cmdl_product_quantity/cmdl_lot_numbers) ,
--      UserID, null, cmdl_exchange_code, cmdl_maturity_date,1,cmdl_product_code,
--      pkgforexprocess.fncCommodityMTMRate(cmdl_maturity_date,cmdl_exchange_code,cmdl_product_code,AsonDate)
--      from trtran051
--      where ((cmdl_complete_date is null) or (cmdl_complete_date > AsonDate))
--      and cmdl_process_complete= Gconst.optionNO
--      and cmdl_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and cmdl_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--    begin
--      VarOperation :='Calling Tf';
--    --  numError  := trfinance.fncReturnTlGap(AsonDate);
--    Exception
--      when others then
--        NULL;
--    end;
----    fetch curTermLoan bulk collect into recPosition;
----
----    Loop
------      Fetch curTermLoan bulinto recPosition;
----      Exit when curTermLoan%NOTFOUND;
----
----     insert into trsystem997
----       (posn_company_code, posn_currency_code, posn_account_code,
----        posn_reference_number, posn_reference_serial, posn_reference_date,
----        posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
----        posn_user_id, posn_dealer_id,
----        posn_counter_party, posn_due_date, posn_maturity_month, posn_product_code,
----        posn_m2m_inrrate)
----    values
----       (recPosition.posn_company_code, recPosition.posn_currency_code,
----        recPosition.posn_account_code, recPosition.posn_reference_number,
----        recPosition.posn_reference_serial, recPosition.posn_reference_date,
----        recPosition.posn_transaction_amount, recPosition.posn_fcy_rate,
----        recPosition.posn_usd_rate, recPosition.posn_user_id,
----        recPosition.posn_dealer_id, recPosition.posn_counter_party,
----        recPosition.posn_due_date, recPosition.posn_maturity_month,
----        recPosition.posn_product_code,recPosition.posn_m2m_inrrate);
----    End Loop;
----    loop
----    end loop;
----
--
--
------------------------------------------------------Currency Futures Added by Manjunath Reddy  on 10-06-2011----------------------------------
--varOperation := 'Insert Currency Future Module in to Assests ';
----
----    insert into trsystem997
----     (posn_company_code, posn_currency_code, posn_account_code,
----      posn_reference_number, posn_reference_serial, posn_reference_date,
----      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
----      posn_user_id, posn_dealer_id,
----      posn_counter_party, posn_due_date, posn_maturity_month, posn_product_code,
----      posn_m2m_inrrate)
----     select cfut_company_code, cfut_base_currency,
----      decode(cfut_hedge_trade,gconst.HEDGEDEAL,decode(cfut_buy_sell,Gconst.PURCHASEDEAL,Gconst.CFHEDGEBUY,
----             Gconst.SALEDEAL,Gconst.CFHEDGESALE),gconst.TRADEDEAL,
----            decode(cfut_buy_sell,Gconst.PURCHASEDEAL,Gconst.CFTRADEBUY,Gconst.SALEDEAL,Gconst.CFTRADESALE)),
----      cfut_deal_number, 0, cfut_execute_date,
----      cfut_base_amount,fncFutureDealRate(cfut_deal_number),(cfut_lot_quantity/cfut_lot_numbers) ,
----      UserID, null, cfut_exchange_code, cfut_maturity_date,1,decode(cfut_hedge_trade,gconst.HEDGEDEAL,decode(cfut_buy_sell,Gconst.PURCHASEDEAL,Gconst.CFHEDGEBUY,
----             Gconst.SALEDEAL,Gconst.CFHEDGESALE),gconst.TRADEDEAL,
----            decode(cfut_buy_sell,Gconst.PURCHASEDEAL,Gconst.CFTRADEBUY,Gconst.SALEDEAL,Gconst.CFTRADESALE)),
----      pkgforexprocess.fncCommodityMTMRate(cfut_maturity_date,cfut_exchange_code,cfut_product_code,AsonDate)
----      from trtran061
----      where ((cfut_complete_date is null) or (cfut_complete_date > AsonDate))
----      and cfut_process_complete= Gconst.optionNO
----      and cfut_record_status in
----      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
----
----    begin
----      VarOperation :='Calling Tf';
----    --  numError  := trfinance.fncReturnTlGap(AsonDate);
----    Exception
----      when others then
----        NULL;
----    end;
--
--
--
------------------------------------------------------Currency Options Added by Manjunath Reddy  on 18-06-2011----------------------------------
--varOperation := 'Insert Currency Options Module in to Assests ';
--
--    insert into trsystem997
--     (posn_company_code, posn_currency_code, posn_account_code,
--      posn_reference_number, posn_reference_serial, posn_reference_date,
--      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--      posn_user_id, posn_dealer_id,
--      posn_counter_party, posn_due_date, posn_maturity_month, posn_product_code,posn_m2m_inrrate)
--     select copt_company_code, copt_base_currency,
--      decode(copt_hedge_trade,gconst.HEDGEDEAL,decode(cosu_option_type,Gconst.OptionCall,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLHEDGEBUY,
--             Gconst.SALEDEAL,Gconst.COCALLHEDGESALE),Gconst.OptionPut,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTHEDGEBUY,
--             Gconst.SALEDEAL,Gconst.COPUTHEDGESALE)),gconst.TRADEDEAL,
--             decode(cosu_option_type,Gconst.OptionCall,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLTRADEBUY,
--             Gconst.SALEDEAL,Gconst.COCALLTRADESALE),Gconst.OptionPut,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTTRADEBUY,
--             Gconst.SALEDEAL,Gconst.COPUTTRADESALE))),
--      copt_deal_number, cosu_serial_number, copt_execute_date,
--      copt_base_amount,cosu_strike_rate,0,
--      --(copt_lot_quantity/copt_lot_numbers),
--
--      --fncFutureDealRate(cfut_deal_number),(cfut_lot_quantity/cfut_lot_numbers) ,
--      UserID, null, copt_counter_party, copt_maturity_date,1,      decode(copt_hedge_trade,gconst.HEDGEDEAL,decode(cosu_option_type,Gconst.OptionCall,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLHEDGEBUY,
--             Gconst.SALEDEAL,Gconst.COCALLHEDGESALE),Gconst.OptionPut,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTHEDGEBUY,
--             Gconst.SALEDEAL,Gconst.COPUTHEDGESALE)),gconst.TRADEDEAL,
--             decode(cosu_option_type,Gconst.OptionCall,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLTRADEBUY,
--             Gconst.SALEDEAL,Gconst.COCALLTRADESALE),Gconst.OptionPut,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTTRADEBUY,
--             Gconst.SALEDEAL,Gconst.COPUTTRADESALE))),0
--             --,
--             --,
--     -- pkgforexprocess.fncCommodityMTMRate(cfut_maturity_date,cfut_exchange_code,cfut_product_code,AsonDate)
--      --copt_strike_rate
--      from trtran071 right outer join trtran072
--      on copt_deal_number=cosu_deal_number
--     where ((copt_complete_date is null) or (copt_complete_date > AsonDate))
--      and copt_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and copt_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--
--
--    varOperation := 'Calculate Total Tansaction amount  Transaction amount';
--
--    update trsystem997
--      set posn_inr_value=posn_transaction_amount * posn_fcy_rate * posn_usd_rate,
--      posn_revalue_inr= posn_transaction_amount * posn_usd_rate * posn_m2m_inrrate
--      where posn_product_code is not null;
--
--    varOperation := 'Calculate Profit  According to M2m Rate';
--
--    update trsystem997
--      set posn_position_inr=decode(sign(25900050 - posn_account_code), 1,
--      posn_inr_value-posn_revalue_inr,-1, posn_revalue_inr-posn_inr_value)
--      where posn_product_code is not null;
--
--    update trsystem997
--      set posn_position_usd = round(posn_position_inr / posn_usd_rate,2),
--      posn_product_code= posn_account_code
--      where posn_product_code is  null;
--
--
--    commit;
--    return numError;
--Exception
--
--  when others then
--      varError := SQLERRM;
--      varerror := 'PositionGen: ' || varmessage || varoperation || varerror;
--      raise_application_error(-20101,   varerror);
--      Rollback;
--
--      return -1;
--End fncPositionGenerate;
---end function fncPositionGenerate 11-jun-13

-----updated by aakash/ishwar 11-jun-13 12:37 pm
--------------------------------------------Body-----------------------------------------

--Function fncPositionGenerate
--    (USERID IN VARCHAR2,
--     ASONDATE IN DATE,
--     VARCOMPCODE VARCHAR2 DEFAULT '30199999' ,
--     varcurcode varchar2 default '30499999' ,
--     varprodcode varchar2 default '33399999' ,
--     varsubprodcode varchar2 default '33899999',
--     varLocationcode varchar2 default '30299999',
--     ConvertToCurrency in number := 30400004 ,
--     ConvertToLocalCurrency in number := 30400003)
--   return number
--    is
--
--    PRAGMA AUTONOMOUS_TRANSACTION;
----  Created on 19/03/08
--    datPositionWorkDate date;
--    datToday        date;
--    datTemp         date;
--    numError        number;
--    varOperation    GConst.gvarOperation%type;
--    varMessage      GConst.gvarMessage%type;
--    varError        GConst.gvarError%type;
--    numdaystatus number(8);
----    Type tpPosition is ref cursor return trsystem997%ROWTYPE;
----    curTermLoan     tpPosition;
----    recPosition     trsystem997%ROWTYPE;
--Begin
--    numError := 0;
--    varMessage := 'Generating Position Figures for date: ' || AsonDate;
--    datToday := AsonDate;
--    datPositionWorkDate := AsonDate;
--    
--    varOperation := 'Deleting Old Records from A  File';
--    delete from trsystem997;
--
--    varOperation := 'Select the day status from database';
--    SELECT HDAY_DAY_STATUS INTO numdaystatus FROM TRSYSTEM001
--      WHERE HDAY_CALENDAR_DATE =ASONDATE
--        AND HDAY_LOCATION_CODE =30299999 ;
--
--   if numdaystatus <> 26400002 then
--     varOperation := 'Inserting records from trsystem997d to trsystem997';
--      insert into trsystem997( POSN_COMPANY_CODE,POSN_LOCATION_CODE, POSN_CURRENCY_CODE, 
--                    POSN_ACCOUNT_CODE, POSN_USER_ID,
--                    POSN_REFERENCE_NUMBER, POSN_REFERENCE_SERIAL, POSN_REFERENCE_DATE, POSN_DEALER_ID,
--                    POSN_COUNTER_PARTY, POSN_TRANSACTION_AMOUNT, POSN_FCY_RATE, POSN_USD_RATE,
--                    POSN_INR_VALUE, POSN_USD_VALUE, POSN_M2M_USDRATE, POSN_M2M_INRRATE,
--                    POSN_REVALUE_USD, POSN_REVALUE_INR, POSN_POSITION_USD, POSN_POSITION_INR,
--                    POSN_DUE_DATE, POSN_MATURITY_MONTH, POSN_PRODUCT_CODE, POSN_HEDGE_TRADE,
--                    POSN_ASSET_LIABILITY, POSN_FOR_CURRENCY, POSN_SUBPRODUCT_CODE )
--      select  POSN_COMPANY_CODE, POSN_CURRENCY_CODE,POSN_LOCATION_CODE,
--                    POSN_ACCOUNT_CODE, POSN_USER_ID,
--                    POSN_REFERENCE_NUMBER, POSN_REFERENCE_SERIAL, POSN_REFERENCE_DATE, POSN_DEALER_ID,
--                    POSN_COUNTER_PARTY, POSN_TRANSACTION_AMOUNT, POSN_FCY_RATE, POSN_USD_RATE,
--                    POSN_INR_VALUE, POSN_USD_VALUE, POSN_MtM_fcyRATE, POSN_MtM_fcyRATE*POSN_MTM_LocalRATE,
--                    POSN_REVALUE_USD, POSN_REVALUE_INR, POSN_POSITION_USD, POSN_POSITION_INR,
--                    POSN_DUE_DATE, POSN_MATURITY_MONTH, POSN_PRODUCT_CODE, POSN_HEDGE_TRADE,
--                    POSN_ASSET_LIABILITY, POSN_FOR_CURRENCY, POSN_SUBPRODUCT_CODE
--     from trsystem997d
--     WHERE POSN_MTM_DATE=ASONDATE
--
--       and posn_process_complete=12400002  ;
--       numError := SQl%ROWCOUNT;
--       if numError > 0 then
--           commit;
--           return numError;
--       end if;
--
--   end if;
--
-------------- Underlyings in Trtran002 ------------------------
--    varOperation := 'Inserting records for Underlying Details';
--    insert into trsystem997
--    (posn_company_code,POSN_LOCATION_CODE, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month,
--     posn_hedge_trade, posn_asset_liability, posn_for_currency,
--     posn_product_code,posn_subproduct_code)
--    select trad_company_code,trad_location_code, trad_trade_currency, trad_import_export,
--      trad_trade_reference, 0, trad_entry_date,
--      fncGetOutstanding(trad_trade_reference,0,GConst.UTILEXPORTS,
--        GConst.AMOUNTFCY, AsonDate) -  nvl((Select 
--         sum(brel_reversal_fcy)
--        From Trtran002 a ,Trtran003 b
--        Where a.Trad_Trade_Reference=b.brel_Trade_Reference
--        And a.Trad_Contract_No=m.Trad_Contract_No
--        and b.brel_entry_date <=AsonDate
--        and to_char(b.brel_entry_date,'yyyymm')= to_char(m.trad_maturity_date,'yyyymm')
--        And a.Trad_Record_Status In (10200005,10200006)
--        And b.Brel_Record_Status Not In (10200005,10200006)),0)
--        tradefcy,trad_trade_rate,0,
--      fncGetOutstanding(trad_trade_reference,0,GConst.UTILEXPORTS,
--        GConst.AMOUNTINR, AsonDate) tradeinr, 0, UserID, null,TRAD_LOCAL_BANK,  
--      trad_maturity_date,fncAllotMonth(AsonDate, trad_maturity_date),
--      'H', decode(sign(25900050 - trad_import_export),-1,'L','A'), 30400003,
--      trad_product_category, decode(trad_subproduct_code,33800062,33800003,trad_subproduct_code)
--      from trtran002 m
--      where (trad_complete_date is null or trad_complete_date > AsonDate)
--	    and (TRAD_COMPANY_CODE = DECODE(VARCOMPCODE,'30199999' ,TRAD_COMPANY_CODE) OR
--            INSTR(VARCOMPCODE ,TRAD_COMPANY_CODE) >0)
--      AND (trad_trade_currency = DECODE(varcurcode,'30499999' ,trad_trade_currency) OR
--            INSTR(VARCURCODE ,TRAD_TRADE_CURRENCY) >0) 
--      AND   (NVL(TRAD_product_category,0) = DECODE(varprodcode,'33399999' ,NVL(TRAD_product_category,0)) OR
--            INSTR(varprodcode ,NVL(TRAD_PRODUCT_CATEGORY,0)) >0) 
--      AND   (NVL(TRAD_subproduct_CODE,0) = DECODE(varsubprodcode,'33899999' ,NVL(TRAD_subproduct_CODE,0)) OR
--            INSTR(varsubprodcode ,NVL(TRAD_subproduct_CODE,0)) >0)		
--      AND   (NVL(TRAD_Location_CODE,0) = DECODE(varLocationcode,'30299999' ,NVL(TRAD_Location_CODE,0)) OR
--            INSTR(varLocationcode ,NVL(TRAD_Location_CODE,0)) >0)		
--      and trad_company_code in 
--      (select usco_company_code 
--        from trsystem022a 
--        where usco_user_id =UserID)
--      and trad_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--
--      numError := SQl%ROWCOUNT;
--
-------- Trade Deals in trtran001 -----------------------------
--    varOperation := 'Inserting records for Trade Forward Deals';
--    insert into trsystem997
--    (posn_company_code, POSN_LOCATION_CODE,posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month,
--     posn_hedge_trade, posn_asset_liability, posn_for_currency,
--     posn_product_code,posn_subproduct_code)
--    select deal_company_code CompanyCode,deal_location_code, deal_base_currency,
--        decode(deal_buy_sell, GConst.PURCHASEDEAL, GConst.FORWARDTRADEBUY,
--            GConst.SALEDEAL, GConst.FORWARDTRADESALE) AccountCode,
--      deal_deal_number, deal_serial_number, deal_execute_date,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADEDEAL,
--        GConst.AMOUNTFCY, AsonDate) tradefcy,
--      decode(deal_other_currency, GConst.INDIANRUPEE, deal_exchange_rate, deal_local_rate)
--        deal_exchange_rate,0,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADEDEAL,
--        GConst.AMOUNTINR, AsonDate) tradeinr,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate, deal_maturity_date),
--      'T', decode(deal_buy_sell, GConst.PURCHASEDEAL, 'A','L'), deal_other_currency,
--      deal_backup_deal, decode(deal_init_code,33800062,33800003,deal_init_code)
--      from trtran001
--      where  (deal_company_code = DECODE(VARCOMPCODE,'30199999' ,deal_company_code) OR
--            INSTR(VARCOMPCODE ,deal_company_code) >0)
--        AND (deal_base_currency = DECODE(varcurcode,'30499999' ,deal_base_currency) OR
--            INSTR(VARCURCODE ,deal_base_currency) >0)
--        AND (NVL(deal_backup_deal,0) = DECODE(varprodcode,'33399999' ,NVL(deal_backup_deal,0)) OR
--            INSTR(varprodcode ,NVL(deal_backup_deal,0)) >0)
--        AND (NVL(DEAL_INIT_CODE,0) = DECODE(varsubprodcode,'33899999' ,NVL(DEAL_INIT_CODE,0)) OR
--            INSTR(varsubprodcode ,NVL(deal_init_code,0)) >0)
--        AND (NVL(Deal_Location_CODE,0) = DECODE(varLocationcode,'30299999' ,NVL(deal_Location_CODE,0)) OR
--            INSTR(varLocationcode ,NVL(deal_Location_CODE,0)) >0)	
--	AND ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_hedge_trade = GConst.TRADEDEAL
--      and deal_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED)
--    union
----  Cross Currency Trade Deals in Trtran001
--    select deal_company_code CompanyCode, deal_location_code,  deal_other_currency,
--       decode(deal_buy_sell, GConst.PURCHASEDEAL, GConst.FORWARDTRADESALE,
--            GConst.SALEDEAL, GConst.FORWARDTRADEBUY) AccountCode,
--      deal_deal_number, deal_serial_number, deal_execute_date,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADECROSS,
--        GConst.AMOUNTFCY, AsonDate) tradefcy, round(deal_amount_local / deal_other_amount,4),0,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADECROSS,
--        GConst.AMOUNTINR, AsonDate) tradeinr,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate, deal_maturity_date),
--      'T', decode(deal_buy_sell, GConst.PURCHASEDEAL, 'L','A') ,deal_base_currency,
--       deal_backup_deal,decode(deal_init_code,33800062,33800003,deal_init_code)
--      from trtran001
--      where  (deal_company_code = DECODE(VARCOMPCODE,'30199999' ,deal_company_code) OR
--            INSTR(VARCOMPCODE ,deal_company_code) >0)
--       AND (deal_base_currency = DECODE(varcurcode,'30499999' ,deal_base_currency) OR
--            INSTR(VARCURCODE ,deal_base_currency) >0)
--       AND  (NVL(deal_backup_deal,0) = DECODE(varprodcode,'33399999' ,NVL(deal_backup_deal,0)) OR
--            INSTR(varprodcode ,NVL(deal_backup_deal,0)) >0)
--       AND  (NVL(DEAL_INIT_CODE,0) = DECODE(varsubprodcode,'33899999' ,NVL(DEAL_INIT_CODE,0)) OR
--            INSTR(varsubprodcode ,NVL(deal_init_code,0)) >0)
--       AND  (NVL(Deal_Location_CODE,0) = DECODE(varLocationcode,'30299999' ,NVL(deal_Location_CODE,0)) OR
--            INSTR(varLocationcode ,NVL(deal_Location_CODE,0)) >0)	
--      AND deal_other_currency != GConst.INDIANRUPEE
--      and deal_hedge_trade = GConst.TRADEDEAL
--      and deal_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--
----
--    varOperation := 'Inserting Hedge Deals for Forwards';
--    insert into trsystem997
--    (posn_company_code,POSN_LOCATION_CODE, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month,
--     posn_hedge_trade, posn_asset_liability, posn_for_currency,
--     posn_product_code,posn_subproduct_code)
--    select deal_company_code CompanyCode, deal_location_code, deal_base_currency,
--       decode(deal_buy_sell, GConst.PURCHASEDEAL, GConst.FORWARDHEDGEBUY,
--            GConst.SALEDEAL, GConst.FORWARDHEDGESALE) AccountCode,
--      deal_deal_number, 0 , deal_execute_date,
--     fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADEDEAL,
--        GConst.AMOUNTFCY, AsonDate) tradefcy, deal_exchange_rate,
--      --decode(deal_other_currency, GConst.INDIANRUPEE, deal_exchange_rate, deal_local_rate),
--        0,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADEDEAL,
--        GConst.AMOUNTINR, AsonDate) tradeinr,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number)),
--      'H', decode(deal_buy_sell, GConst.PURCHASEDEAL, 'A','L'),deal_other_currency,
--       deal_backup_deal,decode(deal_init_code,33800062,33800003,deal_init_code)
--
--      from trtran001
--        WHERE (deal_company_code = DECODE(VARCOMPCODE,'30199999' ,deal_company_code) OR
--            INSTR(VARCOMPCODE ,deal_company_code) >0)
--        AND (deal_base_currency = DECODE(varcurcode,'30499999' ,deal_base_currency) OR
--            INSTR(VARCURCODE ,deal_base_currency) >0)
--        AND   (NVL(deal_backup_deal,0) = DECODE(varProdcode,'33399999' ,NVL(deal_backup_deal,0)) OR
--            INSTR(varProdCode ,NVL(deal_backup_deal,0)) >0)
--        AND   (NVL(DEAL_INIT_CODE,0) = DECODE(varsubProdcode,'33899999' ,NVL(DEAL_INIT_CODE,0)) OR
--            INSTR(varsubProdcode ,NVL(deal_init_code,0)) >0) 
--        AND  (NVL(Deal_Location_CODE,0) = DECODE(varLocationcode,'30299999' ,NVL(deal_Location_CODE,0)) OR
--            INSTR(varLocationcode ,NVL(deal_Location_CODE,0)) >0)	    
--        AND ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_execute_date <= AsonDate
--      and deal_hedge_trade in (GConst.HEDGEDEAL, GCONST.FTDEAL)
--      and deal_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      /*and fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGEDEAL,
--        GConst.AMOUNTFCY, AsonDate) >0*/
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--    varOperation := 'Inserting Cross Currency Hedge Deals for Forwards';
--    insert into trsystem997
--    (posn_company_code, POSN_LOCATION_CODE,posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month,
--     posn_hedge_trade, posn_asset_liability, posn_for_currency,
--     posn_product_code,posn_subproduct_code)
--    select deal_company_code,deal_location_code, deal_other_currency,
--      decode(deal_buy_sell, GConst.PURCHASEDEAL, GConst.FORWARDHEDGESALE,
--            GConst.SALEDEAL, GConst.FORWARDHEDGEBUY) AccountCode,
--      deal_deal_number, deal_serial_number, deal_execute_date,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADECROSS,
--        GConst.AMOUNTFCY, AsonDate) tradefcy,
--      round(deal_amount_local / deal_other_amount,4),0,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADECROSS,
--        GConst.AMOUNTINR, AsonDate) tradeinr,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number)),
--      'H', decode(deal_buy_sell, GConst.PURCHASEDEAL, 'L', 'A'),deal_base_currency,
--       deal_backup_deal,decode(deal_init_code,33800062,33800003,deal_init_code)
--      from trtran001
--      where  (deal_company_code = DECODE(VARCOMPCODE,'30199999' ,deal_company_code) OR
--            INSTR(VARCOMPCODE ,deal_company_code) >0)
--      AND (deal_base_currency = DECODE(varcurcode,'30499999' ,deal_base_currency) OR
--            INSTR(VARCURCODE ,deal_base_currency) >0)
--      AND   (NVL(deal_backup_deal,0) = DECODE(varProdcode,'33399999' ,NVL(deal_backup_deal,0)) OR
--            INSTR(varProdcode ,NVL(deal_backup_deal,0)) >0)
--      AND   (NVL(DEAL_INIT_CODE,0) = DECODE(varsubProdcode,'33899999' ,NVL(DEAL_INIT_CODE,0)) OR
--            INSTR(varsubProdcode ,NVL(deal_init_code,0)) >0)
--      AND  (NVL(Deal_Location_CODE,0) = DECODE(varLocationcode,'30299999' ,NVL(deal_Location_CODE,0)) OR
--            INSTR(varLocationcode ,NVL(deal_Location_CODE,0)) >0)	
--	AND deal_other_currency != GConst.INDIANRUPEE
--      and deal_hedge_trade in (GConst.HEDGEDEAL, GConst.FTDEAL)
--      and deal_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_execute_date <= AsonDate
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
---- varOperation := 'Inserting records for Hedge Contracts';
----    insert into trsystem997
----    (posn_company_code, posn_currency_code, posn_account_code,
----     posn_reference_number, posn_reference_serial, posn_reference_date,
----     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
----     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
----     posn_counter_party, posn_due_date, posn_maturity_month)
----    select hedg_company_code CompanyCode, deal_base_currency,
----       decode(deal_buy_sell, GConst.PURCHASEDEAL, GConst.FORWARDHEDGEBUY,
----            GConst.SALEDEAL, GConst.FORWARDHEDGESALE) AccountCode,
----      deal_deal_number, rownum+100, deal_execute_date,
----      fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
----        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference) tradefcy,
----      decode(deal_other_currency, GConst.INDIANRUPEE, deal_exchange_rate, deal_local_rate),
----        0, decode(deal_other_currency,30400003,(fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
----        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference)* deal_exchange_rate),
----        (fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
----        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference)* deal_local_rate)),0,
----      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
----      fncAllotMonth(deal_counter_party, AsonDate,
----        pkgReturnCursor.fncRollover(deal_deal_number))
----      from trtran001, trtran004
----      where deal_deal_number = hedg_deal_number
----      and deal_serial_number = hedg_deal_serial
----      and deal_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
----      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
----      and deal_execute_date <= AsonDate
----      and deal_hedge_trade in (GConst.HEDGEDEAL, GConst.FTDEAL)
----      and deal_record_status in
----      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
------------------------------------------------------
--------modified by ishwar as on 24/05/2013---
------------------------------------------------------
----  varOperation := 'Inserting Cross Currency Hedge Contracts';
----    insert into trsystem997
----    (posn_company_code, posn_currency_code, posn_account_code,
----     posn_reference_number, posn_reference_serial, posn_reference_date,
----     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
----     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
----     posn_counter_party, posn_due_date, posn_maturity_month)
----    select hedg_company_code, deal_other_currency,
----     decode(deal_buy_sell, GConst.PURCHASEDEAL, GConst.FORWARDHEDGESALE,
----            GConst.SALEDEAL, GConst.FORWARDHEDGEBUY) AccountCode,
----      deal_deal_number,rownum+100 , deal_execute_date,
----      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGECROSS,
----        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference) tradefcy,
----        deal_exchange_Rate,0,
----      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGECROSS,
----        GConst.AMOUNTINR, AsonDate, hedg_trade_reference) tradeinr,0,
----      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
----      fncAllotMonth(deal_counter_party, AsonDate,
----        pkgReturnCursor.fncRollover(deal_deal_number))
----      from trtran001, trtran004
----      where deal_deal_number = hedg_deal_number
----      and deal_serial_number = hedg_deal_serial
----      and deal_other_currency != GConst.INDIANRUPEE
----      and deal_hedge_trade in (GConst.HEDGEDEAL, GConst.FTDEAL)
----      and deal_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
----      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
----      and deal_execute_date <= AsonDate
----      and deal_record_status in
----      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--    varOperation := 'Inserting records for FCY Loans';
--    insert into trsystem997
--    (posn_company_code,POSN_LOCATION_CODE, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month,
--     posn_hedge_trade, posn_asset_liability, posn_for_currency,
--     posn_product_code,posn_subproduct_code)
--    select fcln_company_code,fcln_Location_CODE, fcln_currency_code,
--      decode(fcln_loan_type, GConst.LOANBUYERSCREDIT, GConst.TRADEBUYERCREDIT,
--      GConst.LOANPCFC, GConst.TRADEPCFC, GConst.LOANPSCFC, GConst.TRADEPSCFC),
--      fcln_loan_number, 0, fcln_sanction_date,
--      fncGetOutstanding(fcln_loan_number, 0,GConst.UTILFCYLOAN,
--        GConst.AMOUNTFCY, AsonDate) fcln_sanctioned_fcy,fcln_conversion_rate,0,
--      fncGetOutstanding(fcln_loan_number, 0,GConst.UTILFCYLOAN,
--        GConst.AMOUNTINR, AsonDate) fcln_sanctioned_inr,0,
--      UserID, null, fcln_local_bank, fcln_maturity_to,
--      fncAllotMonth(AsonDate, fcln_maturity_to),'H','L',30400003,
--      FCLN_PRODUCT_CATEGORY,FCLN_SUBPRODUCT_CODE
--      from trtran005
--      where (fcln_company_code = DECODE(VARCOMPCODE,'30199999' ,fcln_company_code) OR
--            INSTR(VARCOMPCODE ,fcln_company_code) >0)
--        AND (fcln_currency_code = DECODE(varcurcode,'30499999' ,fcln_currency_code) OR
--            INSTR(VARCURCODE ,fcln_currency_code) >0)
--        AND  (NVL(fcln_Location_CODE,0) = DECODE(varLocationcode,'30299999' ,NVL(fcln_Location_CODE,0)) OR
--            INSTR(varLocationcode ,NVL(fcln_Location_CODE,0)) >0)	
--        AND ((fcln_complete_date is null) or (fcln_complete_date > AsonDate))
--      and fcln_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and fcln_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED)
--      and fcln_loan_type not in (GConst.LOANBUYERSCREDIT);
--      
--      
-- ---kumar.h updates 0n 12/05/09  for buyers credit
--     varOperation := 'Inserting records for Buyers Credit';
--    insert into trsystem997
--    (posn_company_code,POSN_LOCATION_CODE, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month,
--     posn_hedge_trade, posn_asset_liability, posn_for_currency,
--     posn_product_code,posn_subproduct_code)
--    select bcrd_company_code,bcrd_location_code, bcrd_currency_code,
--           GConst.TRADEBUYERCREDIT,
--           bcrd_buyers_credit, 0, bcrd_sanction_date,
--      fncGetOutstanding(bcrd_buyers_credit, 0,GConst.UTILBCRLOAN,
--        GConst.AMOUNTFCY, AsonDate) bcrd_sanctioned_fcy,bcrd_conversion_rate,0,
--      fncGetOutstanding(bcrd_buyers_credit, 0,GConst.UTILBCRLOAN,
--        GConst.AMOUNTINR, AsonDate) bcrd_sanctioned_inr,0,
--      UserID, null, bcrd_local_bank, bcrd_due_date,
--      fncAllotMonth(AsonDate, bcrd_due_date), 'H','L',30400003,
--      33300003,33800003
--      from BuyersCredit
--      where (bcrd_company_code = DECODE(VARCOMPCODE,'30199999' ,bcrd_company_code) OR
--            INSTR(VARCOMPCODE ,bcrd_company_code) >0)
--        AND (bcrd_currency_code = DECODE(VARCURCODE,'30499999' ,bcrd_currency_code) OR
--            INSTR(VARCURCODE ,bcrd_currency_code) >0)
--        AND  (NVL(bcrd_Location_CODE,0) = DECODE(varLocationcode,'30299999' ,NVL(bcrd_Location_CODE,0)) OR
--            INSTR(varLocationcode ,NVL(bcrd_Location_CODE,0)) >0)	       
--        AND ((bcrd_completion_date is null) or (bcrd_completion_date > AsonDate))
--      and bcrd_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and bcrd_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--     ---kumar.h updates 0n 12/05/09  for buyers credit
----------------------------------------------------Money Module Added by Manjunath Reddy  on 09-04-2009----------------------------------
----24900011		Short Term Borrowing
--  varOperation := 'Insert Money Module Data in to Assests ';
----    insert into trsystem997
----     (posn_company_code, posn_currency_code, posn_account_code,
----      posn_reference_number, posn_reference_serial, posn_reference_date,
----      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
----      posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
----      posn_counter_party, posn_due_date, posn_maturity_month,
----      posn_product_code)
----     select mdel_company_code, mdel_currency_code,
----      decode( 24900011,24900011,Gconst.MONEYBORROWING,Gconst.TRADEBUYERCREDIT),
----      mdel_deal_number, 0, mdel_execute_date,
----      mdel_deal_amount,mdel_exchange_rate,mdel_exchange_rate,
----      mdel_amount_local,0,UserID, null,
----      mdel_counter_party, mdel_due_date,1,0
----      from trtran031
----      where
----      --((mdel_complete_date is null) or (mdel_complete_date > AsonDate))
----      (mdel_company_code = DECODE(VARCOMPCODE,'30199999' ,mdel_company_code) OR
----            INSTR(VARCOMPCODE ,mdel_company_code) >0)
----     AND (mdel_currency_code = DECODE(VARCURCODE,'30499999' ,mdel_currency_code) OR
----            INSTR(VARCURCODE ,mdel_currency_code) >0)
----     and mdel_process_complete= Gconst.optionNO
----      and mdel_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
----      and mdel_record_status in
----      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--
--
------------------------------------------------------Commodity Added by Manjunath Reddy  on 09-04-2009----------------------------------
--varOperation := 'Insert Commodity Module in to Assests ';
---- posn_transaction_amount     No of LOts
---- posn_fcy_rate               Lot Price
---- posn_usd_rate               Lot Size
---- posn_inr_value              Transaction Amount
---- posn_m2m_inrrate            M2M Lot Price
---- posn_revalue_inr            Tansaction Amount For M2m Rate
---- posn_position_inr           Profit LOSS
--
----    insert into trsystem997
----     (posn_company_code, posn_currency_code, posn_account_code,
----      posn_reference_number, posn_reference_serial, posn_reference_date,
----      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
----      posn_user_id, posn_dealer_id,
----      posn_counter_party, posn_due_date, posn_maturity_month, posn_product_code,
----      posn_m2m_inrrate)
----     select cmdl_company_code, cmdl_currency_code,
----      decode(cmdl_hedge_trade,gconst.HEDGEDEAL,decode(cmdl_buy_sell,Gconst.PURCHASEDEAL,Gconst.COMMODITYHEDGEBUY,
----             Gconst.SALEDEAL,Gconst.COMMODITYHEDGESALE),gconst.TRADEDEAL,
----            decode(cmdl_buy_sell,Gconst.PURCHASEDEAL,Gconst.COMMODITYTRADEBUY,Gconst.SALEDEAL,Gconst.COMMODITYTRADESALE)),
----      cmdl_deal_number, 0, cmdl_execute_date,
----      fncGetOutstanding(cmdl_deal_number, 0,GConst.UTILCOMMODITYDEAL,
----      GConst.AMOUNTFCY, AsonDate),fncCommDealRate(cmdl_deal_number),(cmdl_product_quantity/cmdl_lot_numbers) ,
----      UserID, null, cmdl_exchange_code, cmdl_maturity_date,1,cmdl_product_code,
----      pkgforexprocess.fncCommodityMTMRate(cmdl_maturity_date,cmdl_exchange_code,cmdl_product_code,AsonDate)
----      from trtran051
----      where (cmdl_company_code = DECODE(VARCOMPCODE,'30199999' ,cmdl_company_code) OR
----            INSTR(VARCOMPCODE ,cmdl_company_code) >0)
----     AND (cmdl_currency_code = DECODE(VARCURCODE,'30499999' ,cmdl_currency_code) OR
----            INSTR(VARCURCODE ,cmdl_currency_code) >0)
----     and ((cmdl_complete_date is null) or (cmdl_complete_date > AsonDate))
----      and cmdl_process_complete= Gconst.optionNO
----      and cmdl_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
----      and cmdl_record_status in
----      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
------------------------------------------------------Currency Futures Added by Manjunath Reddy  on 10-06-2011----------------------------------
--    varOperation := 'Inserting Currency Futures';
--    insert into trsystem997
--     (posn_company_code,POSN_LOCATION_CODE, posn_currency_code, posn_account_code,
--      posn_reference_number, posn_reference_serial, posn_reference_date,
--      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--      posn_user_id, posn_dealer_id,
--      posn_counter_party, posn_due_date, posn_maturity_month, posn_product_code,
--      posn_m2m_inrrate,posn_hedge_trade, posn_asset_liability, posn_for_currency)
--     select cfut_company_code,cfut_location_code, cfut_base_currency,
--      decode(cfut_hedge_trade,gconst.HEDGEDEAL,decode(cfut_buy_sell,Gconst.PURCHASEDEAL,Gconst.CFHEDGEBUY,
--             Gconst.SALEDEAL,Gconst.CFHEDGESALE),gconst.TRADEDEAL,
--             DECODE(CFUT_BUY_SELL,GCONST.PURCHASEDEAL,GCONST.CFTRADEBUY,GCONST.SALEDEAL,GCONST.CFTRADESALE),GCONST.FTDEAL ,
--           DECODE(CFUT_BUY_SELL,GCONST.PURCHASEDEAL,GCONST.CFHEDGEBUY,Gconst.SALEDEAL,Gconst.CFHEDGESALE)),
--      cfut_deal_number, 0, cfut_execute_date,
--      fncGetOutstanding(cfut_deal_number, 0,GConst.UTILFUTUREDEAL, GConst.AMOUNTFCY, AsonDate) * 1000,
--      cfut_exchange_rate, decode(cfut_base_currency, 30400004, fncFutureDealRate(cfut_deal_number),
--      fncGetRate(30400004,30400003,AsonDate,cfut_buy_sell, 0, cfut_maturity_date)),
--      UserID, cfut_user_id, cfut_exchange_code, cfut_maturity_date,
--      fncAllotMonth(AsonDate, cfut_maturity_date),
--      decode(cfut_hedge_trade,gconst.HEDGEDEAL,decode(cfut_buy_sell,Gconst.PURCHASEDEAL,Gconst.CFHEDGEBUY,
--             Gconst.SALEDEAL,Gconst.CFHEDGESALE),gconst.TRADEDEAL,
--            decode(cfut_buy_sell,Gconst.PURCHASEDEAL,Gconst.CFTRADEBUY,Gconst.SALEDEAL,Gconst.CFTRADESALE)),
--      fncFutureDealRate(cfut_deal_number), decode(cfut_hedge_trade,GConst.TRADEDEAL,'T','H'),
--      decode(cfut_buy_sell, Gconst.PURCHASEDEAL, 'A','L'),cfut_other_currency
--      from trtran061
--      where (cfut_company_code = DECODE(VARCOMPCODE,'30199999' ,cfut_company_code) OR
--            INSTR(VARCOMPCODE ,cfut_company_code) >0)
--       AND (cfut_base_currency = DECODE(VARCURCODE,'30499999' ,cfut_base_currency) OR
--            INSTR(VARCURCODE ,CFUT_BASE_CURRENCY) >0)
--       AND   (NVL(CFUT_BACKUP_DEAL,0) = DECODE(varProdcode,'33399999' ,NVL(CFUT_BACKUP_DEAL,0)) OR
--            INSTR(varProdcode ,NVL(CFUT_BACKUP_DEAL,0)) >0)
--       AND   (NVL(CFUT_INIT_CODE,0) = DECODE(varsubProdcode,'33899999' ,NVL(CFUT_INIT_CODE,0)) OR
--            INSTR(varsubProdcode ,NVL(CFUT_INIT_CODE,0)) >0)
--       AND  (NVL(cfut_Location_CODE,0) = DECODE(varLocationcode,'30299999' ,NVL(cfut_Location_CODE,0)) OR
--            INSTR(varLocationcode ,NVL(cfut_Location_CODE,0)) >0)	  
--     and cfut_execute_date <=   asondate
--     and (( cfut_process_complete =  Gconst.optionYes and cfut_complete_date > asondate)
--       OR cfut_process_complete= Gconst.optionNO)
--      and cfut_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
------------------------------------------------------Currency Options Added by Manjunath Reddy  on 18-06-2011----------------------------------
--varOperation := 'Insert Currency Options Module in to Assests ';
--
--    insert into trsystem997
--     (posn_company_code, POSN_LOCATION_CODE,posn_currency_code, posn_account_code,
--      posn_reference_number, posn_reference_serial, posn_reference_date,
--      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--      posn_user_id, posn_dealer_id, posn_counter_party, posn_due_date,
--      posn_maturity_month, posn_product_code,posn_m2m_inrrate,
--      posn_hedge_trade, posn_asset_liability, posn_for_currency)
--     select copt_company_code, copt_location_code,copt_base_currency,
--      decode(copt_hedge_trade,gconst.HEDGEDEAL,
--        decode(cosu_option_type,Gconst.OptionCall,
--        decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLHEDGEBUY,Gconst.SALEDEAL,Gconst.COCALLHEDGESALE),Gconst.OptionPut,
--        decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTHEDGEBUY, Gconst.SALEDEAL,Gconst.COPUTHEDGESALE)),gconst.TRADEDEAL,
--        decode(cosu_option_type,Gconst.OptionCall,
--        decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLTRADEBUY, Gconst.SALEDEAL,Gconst.COCALLTRADESALE),Gconst.OptionPut,
--        decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTTRADEBUY, Gconst.SALEDEAL,Gconst.COPUTTRADESALE))),
--      copt_deal_number, cosu_serial_number, copt_execute_date,
--      copt_base_amount,cosu_strike_rate,cosu_strike_rate,
--      --(copt_lot_quantity/copt_lot_numbers),fncFutureDealRate(cfut_deal_number),(cfut_lot_quantity/cfut_lot_numbers) ,
--      UserID, null, copt_counter_party, copt_maturity_date, fncAllotMonth(AsonDate, copt_maturity_date),
--      decode(copt_hedge_trade,gconst.HEDGEDEAL,
--        decode(cosu_option_type,Gconst.OptionCall,
--        decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLHEDGEBUY,Gconst.SALEDEAL,Gconst.COCALLHEDGESALE),Gconst.OptionPut,
--        decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTHEDGEBUY,Gconst.SALEDEAL,Gconst.COPUTHEDGESALE)),gconst.TRADEDEAL,
--        decode(cosu_option_type,Gconst.OptionCall,
--        decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLTRADEBUY,Gconst.SALEDEAL,Gconst.COCALLTRADESALE),Gconst.OptionPut,
--        decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTTRADEBUY, Gconst.SALEDEAL,Gconst.COPUTTRADESALE))),cosu_strike_rate,
--      decode(copt_hedge_trade,gconst.TRADEDEAL,'T','H'),
--      case
--      when cosu_buy_sell = GConst.SALEDEAL and cosu_option_type = GConst.OptionPut then 'A'
--      when cosu_buy_sell = Gconst.PURCHASEDEAL and cosu_option_type = Gconst.OptionCall then 'A'
--      when cosu_buy_sell = Gconst.SALEDEAL and cosu_option_type = Gconst.OptionCall then 'L'
--      when cosu_buy_sell = GConst.PURCHASEDEAL and cosu_option_type = GConst.OptionPut then 'L'
--      end, copt_other_currency
--      from trtran071 right outer join trtran072
--      on copt_deal_number=cosu_deal_number
--      where (copt_company_code = DECODE(VARCOMPCODE,'30199999' ,copt_company_code) OR
--            INSTR(VARCOMPCODE ,copt_company_code) >0)
--       AND (copt_base_currency = DECODE(VARCURCODE,'30499999' ,copt_base_currency) OR
--            INSTR(VARCURCODE ,copt_base_currency) >0)
--       AND   (NVL(COPT_BACKUP_DEAL,0) = DECODE(varProdcode,'33399999' ,NVL(COPT_BACKUP_DEAL,0)) OR
--            INSTR(varProdcode ,NVL(COPT_BACKUP_DEAL,0)) >0)
--       AND   (NVL(COPT_INIT_CODE,0) = DECODE(varsubProdcode,'33899999' ,NVL(COPT_INIT_CODE,0)) OR
--            INSTR(varsubProdcode ,NVL(COPT_INIT_CODE,0)) >0)
--       AND  (NVL(copt_Location_CODE,0) = DECODE(varLocationcode,'30299999' ,NVL(copt_Location_CODE,0)) OR
--            INSTR(varLocationcode ,NVL(copt_Location_CODE,0)) >0)
--            
--     and ((copt_complete_date is null) or (copt_complete_date > AsonDate))
--      and copt_company_code in
--      (select usco_company_code
--        from trsystem022a
--        where usco_user_id =UserID)
--      and copt_record_status in (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--commit;
----VAROPERATION := 'Insert Money Module Data in to Assests ';---exposure
----    INSERT INTO TRSYSTEM997
----     (posn_company_code, posn_currency_code, posn_account_code,
----      posn_reference_number, posn_reference_serial, posn_reference_date,
----      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
----      posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
----      posn_counter_party, posn_due_date, posn_maturity_month,
----      POSN_PRODUCT_CODE)
----     select mdel_company_code, mdel_currency_code,
----     -- decode( 24900011,24900011,Gconst.MONEYBORROWING,Gconst.TRADEBUYERCREDIT),
----      decode(mdel_transaction_type ,28100054,25900008,28100055,25900009),
----      mdel_deal_number, 0, mdel_execute_date,
----      mdel_deal_amount,mdel_exchange_rate,mdel_exchange_rate, 
----      mdel_amount_local,0,UserID, null,  mdel_counter_party, mdel_due_date,1,
----      decode(mdel_transaction_type ,28100054,25900008,28100055,25900009)
----      from trtran031
----      where (MDEL_PROCESS_COMPLETE= GCONST.OPTIONNO or (nvl(MDEL_COMPLETE_DATE,asondate+1) >asondate))
----      and MDEL_VALUE_DATE <asondate
----      and mdel_record_status in
----      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
----
---- VAROPERATION := 'Insert Fixed deposit Data in to Assests ';---exposure
---- 
---- INSERT INTO TRSYSTEM997
----     (posn_company_code, posn_currency_code, posn_account_code,
----      posn_reference_number, posn_reference_serial, posn_reference_date,
----      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
----      posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
----      posn_counter_party, posn_due_date, posn_maturity_month,
----      POSN_PRODUCT_CODE)
----     select fdrf_company_code, 30400003,
----     -- decode( 24900010,24900010,Gconst.MONEYBORROWING,Gconst.TRADEBUYERCREDIT),
----      25900006,
----      fdrf_fd_number, 1, fdrf_reference_date,
----      fdrf_deposit_amount,1,1, 
----      fdrf_deposit_amount,0,UserID, null,
----      fdrf_local_bank, fdrf_maturity_date,1,25900006
----      from trtran047
----      where( nvl(FDRF_PROCESS_COMPLETE,12400002)= GCONST.OPTIONNO or (nvl(FDRF_COMPLETE_DATE,asondate+1) >asondate))
----      and fdrf_reference_date <= asondate
----      and fdrf_record_status in
----      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
---- 
---- VAROPERATION := 'Insert Mutual Fund Data in to Assests ';---exposure
---- 
----  INSERT INTO TRSYSTEM997
----     (posn_company_code, posn_currency_code, posn_account_code,
----      posn_reference_number, posn_reference_serial, posn_reference_date,
----      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
----      posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
----      posn_counter_party, posn_due_date, posn_maturity_month,
----      POSN_PRODUCT_CODE)
----     select mftr_company_code, 30400003,
----     -- decode( 24900010,24900010,Gconst.MONEYBORROWING,Gconst.TRADEBUYERCREDIT),
----      25900007,
----      MFTR_REFERENCE_NUMBER, 0, mftr_reference_date,
----      round( ( pkgfixeddepositproject.fncgetnav(mftr_scheme_code ,asondate,2) *
----                pkgForexProcess.fncGetOutstanding(MFTr_reference_number,0,20,1,asondate)),2),0,1, 
----      round( ( pkgfixeddepositproject.fncgetnav(mftr_scheme_code ,asondate,2) *
----                pkgForexProcess.fncGetOutstanding(MFTr_reference_number,0,20,1,asondate)),2),0,UserID, null,
----      MFTR_BANK_CODE, asondate+1,1,25900007
----      from trtran048
----      where 
----      --((mdel_complete_date is null) or (mdel_complete_date > datpositionworkdate))
----      MFTR_PROCESS_COMPLETE= GCONST.OPTIONNO
----      and MFTR_record_status in (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--     varOperation := 'Calculate Total INR amount ';
--    update trsystem997
--      set posn_inr_value = posn_transaction_amount * posn_fcy_rate ;-- * posn_usd_rate,
--      --posn_revalue_inr = posn_transaction_amount *  posn_m2m_inrrate -- *posn_usd_rate
--
----   ConvertToCurrency in number := 30400004 ,
----     ConvertToLocalCurrency in number := 30400003
--     
--    varOperation := 'Calculating M2M Rates for Forwards';
--    update trsystem997
--      set posn_m2m_inrrate =  fncGetRate
--      (posn_currency_code,ConvertToLocalCurrency, AsonDate, DECODE(SIGN(25900050 - POSN_ACCOUNT_CODE),1 , 25300002,-1,25300001), posn_maturity_month, posn_due_date),
--      posn_usd_rate = fncGetRate
--      (posn_currency_code, ConvertToCurrency, POSN_reference_date, DECODE(SIGN(25900050 - POSN_ACCOUNT_CODE),1 , 25300002,-1,25300001), posn_maturity_month, posn_due_date),
--       posn_M2M_usdrate = fncGetRate
--      (ConvertToCurrency, ConvertToLocalCurrency, AsonDate, DECODE(SIGN(25900050 - POSN_ACCOUNT_CODE),1 , 25300002,-1,25300001), posn_maturity_month, posn_due_date)
--     where posn_currency_code not in (gconst.FORWARDHEDGEBUY,gconst.FORWARDHEDGESALE);
--
----    varOperation := 'Calculating M2M Rates for Forwards';
----    update trsystem997
----      set posn_m2m_inrrate =  fncGetRate
----      (posn_currency_code,30400003, AsonDate, DECODE(SIGN(25900050 - POSN_ACCOUNT_CODE),1 , 25300001,-1,25300002), posn_maturity_month, posn_due_date),
----      posn_usd_rate = fncGetRate
----      (posn_currency_code, 30400004, AsonDate, DECODE(SIGN(25900050 - POSN_ACCOUNT_CODE),1 , 25300001,-1,25300002), posn_maturity_month, posn_due_date)
----      where posn_currency_code  in (gconst.FORWARDHEDGEBUY,gconst.FORWARDHEDGESALE);
--
--    update trsystem997
--      set posn_revalue_inr =
--        round(posn_transaction_amount * posn_usd_rate *posn_M2M_usdrate ,0),
--        posn_revalue_usd =round(posn_transaction_amount * posn_usd_rate,2),
--        posn_position_inr =
--         decode(sign(25900050 - posn_account_code), 1,
--       round(posn_transaction_amount * posn_m2m_inrrate,0) - posn_inr_value,
--       -1, posn_inr_value - round(posn_transaction_amount * posn_m2m_inrrate,0));
--
--
--
--
--   /* varOperation := 'Calculate Profit  According to M2m Rate';
--    update trsystem997
--      set posn_position_inr =decode(sign(25900050 - posn_account_code), 1,
--      posn_inr_value-posn_revalue_inr,-1, posn_revalue_inr-posn_inr_value)
--      where posn_product_code is not null; */
--
--      varOperation := 'Test error';
--    update trsystem997
--      set posn_position_usd = round(posn_position_inr / decode(nvl(posn_usd_rate,0),0,1,posn_usd_rate),2)
--     -- posn_revalue_usd = round((posn_transaction_amount * posn_m2m_inrrate) / decode(nvl(posn_usd_rate,0), 0,1,1),2)
--      where posn_product_code is not null;
--
--    update trsystem997
--      set posn_product_code= posn_account_code
--      where posn_product_code is null;
--
--  --
--
--    commit;
--    return numError;
--Exception
--
--  when others then
--      varError := SQLERRM;
--      varerror := 'PositionGen: ' || varmessage || varoperation || varerror;
--      raise_application_error(-20101,   varerror);
--      Rollback;
--
--      return -1;
--End fncPositionGenerate;

-----------------pkgforexprocess------------------
Function fncPositionGenerate
    (USERID IN VARCHAR2,
     ASONDATE IN DATE,
     VARCOMPCODE VARCHAR2 DEFAULT '30199999' ,
     varcurcode varchar2 default '30499999' ,
     varprodcode varchar2 default '33399999' ,
     varsubprodcode varchar2 default '33899999',
     varLocationcode varchar2 default '30299999',
     ConvertToCurrency in number := 30400004 ,
     ConvertToLocalCurrency in number := 30400003)
   return number
    is

    PRAGMA AUTONOMOUS_TRANSACTION;
--  Created on 19/03/08
    datPositionWorkDate date;
    datToday        date;
    datTemp         date;
    numError        number;
    varOperation    GConst.gvarOperation%type;
    varMessage      GConst.gvarMessage%type;
    varError        GConst.gvarError%type;
    numdaystatus number(8);
--    Type tpPosition is ref cursor return trsystem997%ROWTYPE;
--    curTermLoan     tpPosition;
--    recPosition     trsystem997%ROWTYPE;
Begin
    numError := 0;
    varMessage := 'Generating Position Figures for date: ' || AsonDate;
    datToday := AsonDate;
    datPositionWorkDate := AsonDate;
    
    varOperation := 'Deleting Old Records from A  File';
    delete from trsystem997;

    varOperation := 'Select the day status from database';
    SELECT HDAY_DAY_STATUS INTO numdaystatus FROM TRSYSTEM001
      WHERE HDAY_CALENDAR_DATE =ASONDATE
        AND HDAY_LOCATION_CODE =30299999 ;

   if numdaystatus <> 26400002 then
     varOperation := 'Inserting records from trsystem997d to trsystem997';
      insert into trsystem997( POSN_COMPANY_CODE,POSN_LOCATION_CODE, POSN_CURRENCY_CODE, 
                    POSN_ACCOUNT_CODE, POSN_USER_ID,
                    POSN_REFERENCE_NUMBER, POSN_REFERENCE_SERIAL, POSN_REFERENCE_DATE, POSN_DEALER_ID,
                    POSN_COUNTER_PARTY, POSN_TRANSACTION_AMOUNT, POSN_FCY_RATE, POSN_USD_RATE,
                    POSN_INR_VALUE, POSN_USD_VALUE, POSN_M2M_USDRATE, POSN_M2M_INRRATE,
                    POSN_REVALUE_USD, POSN_REVALUE_INR, POSN_POSITION_USD, POSN_POSITION_INR,
                    POSN_DUE_DATE, POSN_MATURITY_MONTH, POSN_PRODUCT_CODE, POSN_HEDGE_TRADE,
                    POSN_ASSET_LIABILITY, POSN_FOR_CURRENCY, POSN_SUBPRODUCT_CODE,POSN_BROKER_CODE,
                    POSN_OPTION_TYPE,POSN_MATURITY_FROM,POSN_PREMIUM_STATUS,POSN_PREMIUM_AMOUNT,
                    POSN_REFERENCE_SUBSERIAL)
      select  POSN_COMPANY_CODE,POSN_LOCATION_CODE,POSN_CURRENCY_CODE,
                    POSN_ACCOUNT_CODE, POSN_USER_ID,
                    POSN_REFERENCE_NUMBER, POSN_REFERENCE_SERIAL, POSN_REFERENCE_DATE, POSN_DEALER_ID,
                    POSN_COUNTER_PARTY, POSN_TRANSACTION_AMOUNT, POSN_FCY_RATE, POSN_USD_RATE,
                    POSN_INR_VALUE, POSN_USD_VALUE, POSN_MtM_fcyRATE, POSN_MtM_fcyRATE*POSN_MTM_LocalRATE,
                    POSN_REVALUE_USD, POSN_REVALUE_INR, POSN_POSITION_USD, POSN_POSITION_INR,
                    POSN_DUE_DATE, POSN_MATURITY_MONTH, POSN_PRODUCT_CODE, POSN_HEDGE_TRADE,
                    POSN_ASSET_LIABILITY, POSN_FOR_CURRENCY, POSN_SUBPRODUCT_CODE,POSN_BROKER_CODE,
                    POSN_OPTION_TYPE,POSN_MATURITY_FROM,POSN_PREMIUM_STATUS,POSN_PREMIUM_AMOUNT,
                    POSN_REFERENCE_SUBSERIAL
     from trsystem997d
     WHERE POSN_MTM_DATE=ASONDATE
      and POSN_TRANSACTION_AMOUNT != 0
       and posn_process_complete=12400002  ;
       numError := SQl%ROWCOUNT;
       if numError > 0 then
           commit;
           return numError;
       end if;

   end if;

------------ Underlyings in Trtran002 ------------------------
    varOperation := 'Inserting records for Underlying Details';
    insert into trsystem997
    (posn_company_code,POSN_LOCATION_CODE, posn_currency_code, posn_account_code,
     posn_reference_number, posn_reference_serial, posn_reference_date,
     posn_transaction_amount, posn_fcy_rate, posn_user_id, 
     posn_counter_party, posn_due_date, 
     posn_hedge_trade, posn_asset_liability, posn_for_currency,
     posn_product_code,posn_subproduct_code,POSN_REFERENCE_SUBSERIAL)
    select trad_company_code,trad_location_code, trad_trade_currency, 
      trad_import_export, Trad_Trade_Reference, 0, Trad_Entry_Date,
      ((case when trad_import_export < 25900050 then 1 else -1 end ) *
            fncGetOutstanding(trad_trade_reference,0,GConst.UTILEXPORTS,
              GConst.AMOUNTFCY, AsonDate)) tradefcy,
--           else
--           
--      case when trad_import_export < 25900050 then
--      fncGetOutstanding(trad_trade_reference,0,GConst.UTILEXPORTS,
--        GConst.AMOUNTFCY, AsonDate)
--        -  nvl((Select 
--         sum(brel_reversal_fcy)
--        From Trtran002 a ,Trtran003 b
--        Where a.Trad_Trade_Reference=b.brel_Trade_Reference
--        And a.Trad_Contract_No=m.Trad_Contract_No
--        and b.brel_entry_date <=AsonDate
--        and to_char(b.brel_entry_date,'yyyymm')= to_char(m.trad_maturity_date,'yyyymm')
--        And a.Trad_Record_Status In (10200005,10200006)
--        And B.Brel_Record_Status Not In (10200005,10200006)),0)
--       Else
--        (fncGetOutstanding(trad_trade_reference,0,GConst.UTILEXPORTS,
--        GConst.AMOUNTFCY, AsonDate) -  nvl((Select 
--         sum(brel_reversal_fcy)
--        From Trtran002 a ,Trtran003 b
--        Where a.Trad_Trade_Reference=b.brel_Trade_Reference
--        And a.Trad_Contract_No=m.Trad_Contract_No
--        and b.brel_entry_date <=AsonDate
--        and to_char(b.brel_entry_date,'yyyymm')= to_char(m.trad_maturity_date,'yyyymm')
--        And A.Trad_Record_Status In (10200005,10200006)
--        And B.Brel_Record_Status Not In (10200005,10200006)),0)) * -1
--        end
        trad_trade_rate, UserID, TRAD_LOCAL_BANK,  
      trad_maturity_date, 'H', decode(sign(25900050 - trad_import_export),-1,'L','A'), TRAD_LOCAL_CURRENCY,
      trad_product_category, trad_subproduct_code,1
      from trtran002 m
      where (trad_complete_date is null or trad_complete_date > AsonDate)
	    and (TRAD_COMPANY_CODE = DECODE(VARCOMPCODE,'30199999' ,TRAD_COMPANY_CODE) OR
            INSTR(VARCOMPCODE ,TRAD_COMPANY_CODE) >0)
      AND (trad_trade_currency = DECODE(varcurcode,'30499999' ,trad_trade_currency) OR
            INSTR(VARCURCODE ,TRAD_TRADE_CURRENCY) >0) 
      AND   (NVL(TRAD_product_category,0) = DECODE(varprodcode,'33399999' ,NVL(TRAD_product_category,0)) OR
            INSTR(varprodcode ,NVL(TRAD_PRODUCT_CATEGORY,0)) >0) 
      AND   (NVL(TRAD_subproduct_CODE,0) = DECODE(varsubprodcode,'33899999' ,NVL(TRAD_subproduct_CODE,0)) OR
            INSTR(varsubprodcode ,NVL(TRAD_subproduct_CODE,0)) >0)		
      AND   (NVL(TRAD_Location_CODE,0) = DECODE(varLocationcode,'30299999' ,NVL(TRAD_Location_CODE,0)) OR
            INSTR(varLocationcode ,NVL(TRAD_Location_CODE,0)) >0)		
      and trad_company_code in 
      (select usco_company_code 
        from trsystem022a 
        where usco_user_id =UserID)
      and trad_record_status in
      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);


      --numError := SQl%ROWCOUNT;

------ Trade Deals in trtran001 -----------------------------
--    varOperation := 'Inserting records for Trade Forward Deals';
--    insert into trsystem997
--    (posn_company_code, POSN_LOCATION_CODE,posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month,
--     posn_hedge_trade, posn_asset_liability, posn_for_currency,
--     posn_product_code,posn_subproduct_code,POSN_BROKER_CODE,POSN_MATURITY_FROM)
--    select deal_company_code CompanyCode,deal_location_code, deal_base_currency,
--        decode(deal_buy_sell, GConst.PURCHASEDEAL, GConst.FORWARDTRADEBUY,
--            GConst.SALEDEAL, GConst.FORWARDTRADESALE) AccountCode,
--      deal_deal_number, deal_serial_number, deal_execute_date,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADEDEAL,
--        GConst.AMOUNTFCY, AsonDate) tradefcy,
--      decode(deal_other_currency, GConst.INDIANRUPEE, deal_exchange_rate, deal_local_rate)
--        deal_exchange_rate,0,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADEDEAL,
--        GConst.AMOUNTINR, AsonDate) tradeinr,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate, deal_maturity_date),
--      'T', decode(deal_buy_sell, GConst.PURCHASEDEAL, 'A','L'), deal_other_currency,
--      deal_backup_deal, decode(deal_init_code,33800062,33800003,deal_init_code),DEAL_COUNTER_PARTY,
--      deal_maturity_from
--      from trtran001
--      where  (deal_company_code = DECODE(VARCOMPCODE,'30199999' ,deal_company_code) OR
--            INSTR(VARCOMPCODE ,deal_company_code) >0)
--        AND (deal_base_currency = DECODE(varcurcode,'30499999' ,deal_base_currency) OR
--            INSTR(VARCURCODE ,deal_base_currency) >0)
--        AND (NVL(deal_backup_deal,0) = DECODE(varprodcode,'33399999' ,NVL(deal_backup_deal,0)) OR
--            INSTR(varprodcode ,NVL(deal_backup_deal,0)) >0)
--        AND (NVL(DEAL_INIT_CODE,0) = DECODE(varsubprodcode,'33899999' ,NVL(DEAL_INIT_CODE,0)) OR
--            INSTR(varsubprodcode ,NVL(deal_init_code,0)) >0)
--        AND (NVL(Deal_Location_CODE,0) = DECODE(varLocationcode,'30299999' ,NVL(deal_Location_CODE,0)) OR
--            INSTR(varLocationcode ,NVL(deal_Location_CODE,0)) >0)	
--	AND ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_hedge_trade = GConst.TRADEDEAL
--      and deal_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED)
--    union
----  Cross Currency Trade Deals in Trtran001
--    select deal_company_code CompanyCode, deal_location_code,  deal_other_currency,
--       decode(deal_buy_sell, GConst.PURCHASEDEAL, GConst.FORWARDTRADESALE,
--            GConst.SALEDEAL, GConst.FORWARDTRADEBUY) AccountCode,
--      deal_deal_number, deal_serial_number, deal_execute_date,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADECROSS,
--        GConst.AMOUNTFCY, AsonDate) tradefcy, round(deal_amount_local / deal_other_amount,4),0,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADECROSS,
--        GConst.AMOUNTINR, AsonDate) tradeinr,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate, deal_maturity_date),
--      'T', decode(deal_buy_sell, GConst.PURCHASEDEAL, 'L','A') ,deal_base_currency,
--       deal_backup_deal,decode(deal_init_code,33800062,33800003,deal_init_code),DEAL_COUNTER_PARTY,
--       deal_maturity_from
--      from trtran001
--      where  (deal_company_code = DECODE(VARCOMPCODE,'30199999' ,deal_company_code) OR
--            INSTR(VARCOMPCODE ,deal_company_code) >0)
--       AND (deal_base_currency = DECODE(varcurcode,'30499999' ,deal_base_currency) OR
--            INSTR(VARCURCODE ,deal_base_currency) >0)
--       AND  (NVL(deal_backup_deal,0) = DECODE(varprodcode,'33399999' ,NVL(deal_backup_deal,0)) OR
--            INSTR(varprodcode ,NVL(deal_backup_deal,0)) >0)
--       AND  (NVL(DEAL_INIT_CODE,0) = DECODE(varsubprodcode,'33899999' ,NVL(DEAL_INIT_CODE,0)) OR
--            INSTR(varsubprodcode ,NVL(deal_init_code,0)) >0)
--       AND  (NVL(Deal_Location_CODE,0) = DECODE(varLocationcode,'30299999' ,NVL(deal_Location_CODE,0)) OR
--            INSTR(varLocationcode ,NVL(deal_Location_CODE,0)) >0)	
--      AND deal_other_currency != GConst.INDIANRUPEE
--      and deal_hedge_trade = GConst.TRADEDEAL
--      and deal_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);

--
----
    varOperation := 'Inserting Hedge Deals for Forwards';
    insert into trsystem997
    (posn_company_code,POSN_LOCATION_CODE, posn_currency_code, posn_account_code,
     posn_reference_number, posn_reference_serial, posn_reference_date,
     posn_transaction_amount, posn_fcy_rate, posn_user_id, posn_dealer_id,
     posn_counter_party, posn_due_date, 
     posn_hedge_trade, posn_asset_liability, posn_for_currency,
     posn_product_code,posn_subproduct_code,POSN_USER_REFERENCE,
     POSN_BROKER_CODE,POSN_MATURITY_FROM,POSN_REFERENCE_SUBSERIAL)
    select deal_company_code CompanyCode, deal_location_code, deal_base_currency,
       decode(deal_buy_sell, GConst.PURCHASEDEAL, GConst.FORWARDHEDGEBUY,
            GConst.SALEDEAL, GConst.FORWARDHEDGESALE) AccountCode,
      Deal_Deal_Number, 0 , Deal_Execute_Date,
      (Case When Deal_Buy_Sell = 25300001 Then -1 else 1 end) *
      (Fncgetoutstanding(Deal_Deal_Number, Deal_Serial_Number,Gconst.Utiltradedeal,
        Gconst.Amountfcy, Asondate) ) 
        Tradefcy,  deal_exchange_rate,
        UserID, deal_user_id, deal_counter_party, deal_maturity_date,
      'H', decode(deal_buy_sell, GConst.PURCHASEDEAL, 'A','L'),deal_other_currency,
       deal_backup_deal,deal_init_code,DEAL_USER_REFERENCE,DEAL_COUNTER_PARTY,
       deal_maturity_from,1
      from trtran001
        WHERE (deal_company_code = DECODE(VARCOMPCODE,'30199999' ,deal_company_code) OR
            INSTR(VARCOMPCODE ,deal_company_code) >0)
        AND (deal_base_currency = DECODE(varcurcode,'30499999' ,deal_base_currency) OR
            INSTR(VARCURCODE ,deal_base_currency) >0)
        AND   (NVL(deal_backup_deal,0) = DECODE(varProdcode,'33399999' ,NVL(deal_backup_deal,0)) OR
            INSTR(varProdCode ,NVL(deal_backup_deal,0)) >0)
        AND   (NVL(DEAL_INIT_CODE,0) = DECODE(varsubProdcode,'33899999' ,NVL(DEAL_INIT_CODE,0)) OR
            INSTR(varsubProdcode ,NVL(deal_init_code,0)) >0) 
        AND  (NVL(Deal_Location_CODE,0) = DECODE(varLocationcode,'30299999' ,NVL(deal_Location_CODE,0)) OR
            INSTR(varLocationcode ,NVL(deal_Location_CODE,0)) >0)	    
        AND ((deal_complete_date is null) or (deal_complete_date > AsonDate))
      and deal_execute_date <= AsonDate
      --and deal_hedge_trade in (GConst.HEDGEDEAL, GCONST.FTDEAL)
      and deal_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
      /*and fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGEDEAL,
        GConst.AMOUNTFCY, AsonDate) >0*/
      and (deal_complete_date is null or deal_complete_date > AsonDate)
      and deal_record_status  not in (10200005,10200006);





--    varOperation := 'Inserting Cross Currency Hedge Deals for Forwards';
--    insert into trsystem997
--    (posn_company_code, POSN_LOCATION_CODE,posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month,
--     posn_hedge_trade, posn_asset_liability, posn_for_currency,
--     posn_product_code,posn_subproduct_code,POSN_USER_REFERENCE,POSN_BROKER_CODE,POSN_MATURITY_FROM)
--    select deal_company_code,deal_location_code, deal_other_currency,
--      decode(deal_buy_sell, GConst.PURCHASEDEAL, GConst.FORWARDHEDGESALE,
--            GConst.SALEDEAL, GConst.FORWARDHEDGEBUY) AccountCode,
--      Deal_Deal_Number, Deal_Serial_Number, Deal_Execute_Date,
--    Case When  Deal_Buy_Sell = 25300001 Then    
--      (Fncgetoutstanding(Deal_Deal_Number, Deal_Serial_Number,Gconst.Utiltradecross,
--        Gconst.Amountfcy, Asondate))*-1
--    Else    
--    Fncgetoutstanding(Deal_Deal_Number, Deal_Serial_Number,Gconst.Utiltradecross,
--        Gconst.Amountfcy, Asondate)
--        end
--        tradefcy,
--      round(deal_amount_local / deal_other_amount,4),0,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADECROSS,
--        GConst.AMOUNTINR, AsonDate) tradeinr,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number)),
--      'H', decode(deal_buy_sell, GConst.PURCHASEDEAL, 'L', 'A'),deal_base_currency,
--       deal_backup_deal,decode(deal_init_code,33800062,33800003,deal_init_code),DEAL_USER_REFERENCE,DEAL_COUNTER_PARTY,
--       deal_maturity_from
--      from trtran001
--      where  (deal_company_code = DECODE(VARCOMPCODE,'30199999' ,deal_company_code) OR
--            INSTR(VARCOMPCODE ,deal_company_code) >0)
--      AND (deal_base_currency = DECODE(varcurcode,'30499999' ,deal_base_currency) OR
--            INSTR(VARCURCODE ,deal_base_currency) >0)
--      AND   (NVL(deal_backup_deal,0) = DECODE(varProdcode,'33399999' ,NVL(deal_backup_deal,0)) OR
--            INSTR(varProdcode ,NVL(deal_backup_deal,0)) >0)
--      AND   (NVL(DEAL_INIT_CODE,0) = DECODE(varsubProdcode,'33899999' ,NVL(DEAL_INIT_CODE,0)) OR
--            INSTR(varsubProdcode ,NVL(deal_init_code,0)) >0)
--      AND  (NVL(Deal_Location_CODE,0) = DECODE(varLocationcode,'30299999' ,NVL(deal_Location_CODE,0)) OR
--            INSTR(varLocationcode ,NVL(deal_Location_CODE,0)) >0)	
--	AND deal_other_currency != GConst.INDIANRUPEE
--      and deal_hedge_trade in (GConst.HEDGEDEAL, GConst.FTDEAL)
--      and deal_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_execute_date <= AsonDate
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);

-- varOperation := 'Inserting records for Hedge Contracts';
--    insert into trsystem997
--    (posn_company_code, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month)
--    select hedg_company_code CompanyCode, deal_base_currency,
--       decode(deal_buy_sell, GConst.PURCHASEDEAL, GConst.FORWARDHEDGEBUY,
--            GConst.SALEDEAL, GConst.FORWARDHEDGESALE) AccountCode,
--      deal_deal_number, rownum+100, deal_execute_date,
--      fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
--        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference) tradefcy,
--      decode(deal_other_currency, GConst.INDIANRUPEE, deal_exchange_rate, deal_local_rate),
--        0, decode(deal_other_currency,30400003,(fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
--        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference)* deal_exchange_rate),
--        (fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
--        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference)* deal_local_rate)),0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number))
--      from trtran001, trtran004
--      where deal_deal_number = hedg_deal_number
--      and deal_serial_number = hedg_deal_serial
--      and deal_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_execute_date <= AsonDate
--      and deal_hedge_trade in (GConst.HEDGEDEAL, GConst.FTDEAL)
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
----------------------------------------------------
------modified by ishwar as on 24/05/2013---
----------------------------------------------------
--  varOperation := 'Inserting Cross Currency Hedge Contracts';
--    insert into trsystem997
--    (posn_company_code, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month)
--    select hedg_company_code, deal_other_currency,
--     decode(deal_buy_sell, GConst.PURCHASEDEAL, GConst.FORWARDHEDGESALE,
--            GConst.SALEDEAL, GConst.FORWARDHEDGEBUY) AccountCode,
--      deal_deal_number,rownum+100 , deal_execute_date,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGECROSS,
--        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference) tradefcy,
--        deal_exchange_Rate,0,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGECROSS,
--        GConst.AMOUNTINR, AsonDate, hedg_trade_reference) tradeinr,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number))
--      from trtran001, trtran004
--      where deal_deal_number = hedg_deal_number
--      and deal_serial_number = hedg_deal_serial
--      and deal_other_currency != GConst.INDIANRUPEE
--      and deal_hedge_trade in (GConst.HEDGEDEAL, GConst.FTDEAL)
--      and deal_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_execute_date <= AsonDate
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);


--
--    varOperation := 'Inserting records for FCY Loans';
--    insert into trsystem997
--    (posn_company_code,POSN_LOCATION_CODE, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month,
--     posn_hedge_trade, posn_asset_liability, posn_for_currency,
--     posn_product_code,posn_subproduct_code)
--    select fcln_company_code,fcln_Location_CODE, fcln_currency_code,
--      9,
--      fcln_loan_number, 0, fcln_sanction_date,
--      pkgForexProcess.fncGetOutstanding(fcln_loan_number, 0,1,
--        1, AsonDate) fcln_sanctioned_fcy,fcln_conversion_rate,0,
--      pkgForexProcess.fncGetOutstanding(fcln_loan_number, 0,1,
--        2, AsonDate) fcln_sanctioned_inr,0,
--      UserID, null, fcln_local_bank, fcln_maturity_to,
--      pkgForexProcess.fncAllotMonth(AsonDate, fcln_maturity_to),'H','L',30400003,
--      FCLN_PRODUCT_CATEGORY,FCLN_SUBPRODUCT_CODE
--      from trtran005
--      where (fcln_company_code = DECODE(VARCOMPCODE,'30199999' ,fcln_company_code) OR
--            INSTR(VARCOMPCODE ,fcln_company_code) >0)
--        AND (fcln_currency_code = DECODE(varcurcode,'30499999' ,fcln_currency_code) OR
--            INSTR(VARCURCODE ,fcln_currency_code) >0)
--        AND  (NVL(fcln_Location_CODE,0) = DECODE(varLocationcode,'30299999' ,NVL(fcln_Location_CODE,0)) OR
--            INSTR(varLocationcode ,NVL(fcln_Location_CODE,0)) >0)	
--        AND ((fcln_complete_date is null) or (fcln_complete_date > AsonDate))
--      and fcln_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID);
--      and fcln_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED)
--      and fcln_loan_type not in (GConst.LOANBUYERSCREDIT);
      
      
 ---kumar.h updates 0n 12/05/09  for buyers credit
--     varOperation := 'Inserting records for Buyers Credit';
--    insert into trsystem997
--    (posn_company_code,POSN_LOCATION_CODE, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month,
--     posn_hedge_trade, posn_asset_liability, posn_for_currency,
--     posn_product_code,posn_subproduct_code)
--    select bcrd_company_code,bcrd_location_code, bcrd_currency_code,
--           PKGGLOBALMETHODS.TRADEBUYERCREDIT,
--           bcrd_buyers_credit, 0, bcrd_sanction_date,
--      fncGetOutstanding(bcrd_buyers_credit, 0,PKGGLOBALMETHODS.UTILBCRLOAN,
--        PKGGLOBALMETHODS.AMOUNTFCY, AsonDate) *-1 bcrd_sanctioned_fcy,bcrd_conversion_rate,0,
--      Fncgetoutstanding(Bcrd_Buyers_Credit, 0,PKGGLOBALMETHODS.Utilbcrloan,
--        PKGGLOBALMETHODS.AMOUNTINR, AsonDate)*-1 bcrd_sanctioned_inr,0,
--      UserID, null, bcrd_local_bank, bcrd_due_date,
--      fncAllotMonth(AsonDate, bcrd_due_date), 'H','L',30400003,
--      33300003,33800003
--      from BuyersCredit
--      where (bcrd_company_code = DECODE(VARCOMPCODE,'30199999' ,bcrd_company_code) OR
--            INSTR(VARCOMPCODE ,bcrd_company_code) >0)
--        AND (bcrd_currency_code = DECODE(VARCURCODE,'30499999' ,bcrd_currency_code) OR
--            INSTR(VARCURCODE ,bcrd_currency_code) >0)
--        AND  (NVL(bcrd_Location_CODE,0) = DECODE(varLocationcode,'30299999' ,NVL(bcrd_Location_CODE,0)) OR
--            INSTR(varLocationcode ,NVL(bcrd_Location_CODE,0)) >0)	       
--        AND ((bcrd_completion_date is null) or (bcrd_completion_date > AsonDate))
--      and bcrd_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and bcrd_record_status in
--      (PKGGLOBALMETHODS.STATUSENTRY, PKGGLOBALMETHODS.STATUSAUTHORIZED, PKGGLOBALMETHODS.STATUSUPDATED);
     ---kumar.h updates 0n 12/05/09  for buyers credit
--------------------------------------------------Money Module Added by Manjunath Reddy  on 09-04-2009----------------------------------
--24900011		Short Term Borrowing
  varOperation := 'Insert Money Module Data in to Assests ';
--    insert into trsystem997
--     (posn_company_code, posn_currency_code, posn_account_code,
--      posn_reference_number, posn_reference_serial, posn_reference_date,
--      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--      posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--      posn_counter_party, posn_due_date, posn_maturity_month,
--      posn_product_code)
--     select mdel_company_code, mdel_currency_code,
--      decode( 24900011,24900011,Gconst.MONEYBORROWING,Gconst.TRADEBUYERCREDIT),
--      mdel_deal_number, 0, mdel_execute_date,
--      mdel_deal_amount,mdel_exchange_rate,mdel_exchange_rate,
--      mdel_amount_local,0,UserID, null,
--      mdel_counter_party, mdel_due_date,1,0
--      from trtran031
--      where
--      --((mdel_complete_date is null) or (mdel_complete_date > AsonDate))
--      (mdel_company_code = DECODE(VARCOMPCODE,'30199999' ,mdel_company_code) OR
--            INSTR(VARCOMPCODE ,mdel_company_code) >0)
--     AND (mdel_currency_code = DECODE(VARCURCODE,'30499999' ,mdel_currency_code) OR
--            INSTR(VARCURCODE ,mdel_currency_code) >0)
--     and mdel_process_complete= Gconst.optionNO
--      and mdel_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and mdel_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);



----------------------------------------------------Commodity Added by Manjunath Reddy  on 09-04-2009----------------------------------
varOperation := 'Insert Commodity Module in to Assests ';
-- posn_transaction_amount     No of LOts
-- posn_fcy_rate               Lot Price
-- posn_usd_rate               Lot Size
-- posn_inr_value              Transaction Amount
-- posn_m2m_inrrate            M2M Lot Price
-- posn_revalue_inr            Tansaction Amount For M2m Rate
-- posn_position_inr           Profit LOSS

--    insert into trsystem997
--     (posn_company_code, posn_currency_code, posn_account_code,
--      posn_reference_number, posn_reference_serial, posn_reference_date,
--      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--      posn_user_id, posn_dealer_id,
--      posn_counter_party, posn_due_date, posn_maturity_month, posn_product_code,
--      posn_m2m_inrrate)
--     select cmdl_company_code, cmdl_currency_code,
--      decode(cmdl_hedge_trade,gconst.HEDGEDEAL,decode(cmdl_buy_sell,Gconst.PURCHASEDEAL,Gconst.COMMODITYHEDGEBUY,
--             Gconst.SALEDEAL,Gconst.COMMODITYHEDGESALE),gconst.TRADEDEAL,
--            decode(cmdl_buy_sell,Gconst.PURCHASEDEAL,Gconst.COMMODITYTRADEBUY,Gconst.SALEDEAL,Gconst.COMMODITYTRADESALE)),
--      cmdl_deal_number, 0, cmdl_execute_date,
--      fncGetOutstanding(cmdl_deal_number, 0,GConst.UTILCOMMODITYDEAL,
--      GConst.AMOUNTFCY, AsonDate),fncCommDealRate(cmdl_deal_number),(cmdl_product_quantity/cmdl_lot_numbers) ,
--      UserID, null, cmdl_exchange_code, cmdl_maturity_date,1,cmdl_product_code,
--      pkgforexprocess.fncCommodityMTMRate(cmdl_maturity_date,cmdl_exchange_code,cmdl_product_code,AsonDate)
--      from trtran051
--      where (cmdl_company_code = DECODE(VARCOMPCODE,'30199999' ,cmdl_company_code) OR
--            INSTR(VARCOMPCODE ,cmdl_company_code) >0)
--     AND (cmdl_currency_code = DECODE(VARCURCODE,'30499999' ,cmdl_currency_code) OR
--            INSTR(VARCURCODE ,cmdl_currency_code) >0)
--     and ((cmdl_complete_date is null) or (cmdl_complete_date > AsonDate))
--      and cmdl_process_complete= Gconst.optionNO
--      and cmdl_company_code in (select usco_company_code from trsystem022a where usco_user_id =UserID)
--      and cmdl_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);

      --fncFutureDealRate(cfut_deal_number)
----------------------------------------------------Currency Futures Added by Manjunath Reddy  on 10-06-2011----------------------------------
    varOperation := 'Inserting Currency Futures';
    insert into trsystem997
     (posn_company_code,POSN_LOCATION_CODE, posn_currency_code, posn_account_code,
      posn_reference_number, posn_reference_serial, posn_reference_date,
      posn_transaction_amount, posn_fcy_rate, 
      posn_user_id, posn_dealer_id,
      posn_counter_party, posn_due_date,  posn_product_code,
      posn_hedge_trade, posn_asset_liability, posn_for_currency,POSN_SUBPRODUCT_CODE,POSN_BROKER_CODE,
      POSN_MATURITY_FROM,POSN_REFERENCE_SUBSERIAL)
     select cfut_company_code,cfut_location_code, cfut_base_currency,
      decode(cfut_buy_sell,Gconst.PURCHASEDEAL,Gconst.CFHEDGEBUY,
             Gconst.SALEDEAL,Gconst.CFHEDGESALE),
      cfut_deal_number, 0, cfut_execute_date,
      fncGetOutstanding(cfut_deal_number, 0,GConst.UTILFUTUREDEAL, GConst.AMOUNTFCY, AsonDate) * 1000,
      cfut_exchange_rate,
      UserID, cfut_user_id, cfut_exchange_code, cfut_maturity_date,
--      decode(cfut_hedge_trade,gconst.HEDGEDEAL,decode(cfut_buy_sell,Gconst.PURCHASEDEAL,Gconst.CFHEDGEBUY,
--             Gconst.SALEDEAL,Gconst.CFHEDGESALE),gconst.TRADEDEAL,
--            decode(cfut_buy_sell,Gconst.PURCHASEDEAL,Gconst.CFTRADEBUY,Gconst.SALEDEAL,Gconst.CFTRADESALE)),
      CFUT_BACKUP_DEAL, decode(cfut_hedge_trade,GConst.TRADEDEAL,'T','H'),
      decode(cfut_buy_sell, Gconst.PURCHASEDEAL, 'A','L'),cfut_other_currency,CFUT_INIT_CODE,CFUT_COUNTER_PARTY,
      cfut_maturity_from,1
      from trtran061 
      where (cfut_company_code = DECODE(VARCOMPCODE,'30199999' ,cfut_company_code) OR
            INSTR(VARCOMPCODE ,cfut_company_code) >0)
       AND (cfut_base_currency = DECODE(VARCURCODE,'30499999' ,cfut_base_currency) OR
            INSTR(VARCURCODE ,CFUT_BASE_CURRENCY) >0)
       AND   (NVL(CFUT_BACKUP_DEAL,0) = DECODE(varProdcode,'33399999' ,NVL(CFUT_BACKUP_DEAL,0)) OR
            INSTR(varProdcode ,NVL(CFUT_BACKUP_DEAL,0)) >0)
       AND   (NVL(CFUT_INIT_CODE,0) = DECODE(varsubProdcode,'33899999' ,NVL(CFUT_INIT_CODE,0)) OR
            INSTR(varsubProdcode ,NVL(CFUT_INIT_CODE,0)) >0)
       AND  (NVL(cfut_Location_CODE,0) = DECODE(varLocationcode,'30299999' ,NVL(cfut_Location_CODE,0)) OR
            INSTR(varLocationcode ,NVL(cfut_Location_CODE,0)) >0)	  
     and cfut_execute_date <=   asondate
     and (cfut_complete_date is null or cfut_complete_date > AsonDate)
      and cfut_record_status not in (10200005,10200006);

----------------------------------------------------Currency Options Added by Manjunath Reddy  on 18-06-2011----------------------------------
varOperation := 'Insert Currency Options Module in to Assests ';
--      decode(copt_hedge_trade,gconst.HEDGEDEAL,
--        decode(cosu_option_type,Gconst.OptionCall,
--        decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLHEDGEBUY,Gconst.SALEDEAL,Gconst.COCALLHEDGESALE),Gconst.OptionPut,
--        decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTHEDGEBUY, Gconst.SALEDEAL,Gconst.COPUTHEDGESALE)),
--        gconst.FTDEAL,
--        decode(cosu_option_type,Gconst.OptionCall,
--        decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLHEDGEBUY,Gconst.SALEDEAL,Gconst.COCALLHEDGESALE),Gconst.OptionPut,
--        decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTHEDGEBUY, Gconst.SALEDEAL,Gconst.COPUTHEDGESALE)),         
--        gconst.TRADEDEAL,
--        decode(cosu_option_type,Gconst.OptionCall,
--        decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLTRADEBUY, Gconst.SALEDEAL,Gconst.COCALLTRADESALE),Gconst.OptionPut,
--        decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTTRADEBUY, Gconst.SALEDEAL,Gconst.COPUTTRADESALE)),
--        decode(cosu_option_type,Gconst.OptionCall,
--        decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLHEDGEBUY,Gconst.SALEDEAL,Gconst.COCALLHEDGESALE),Gconst.OptionPut,
--        decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTHEDGEBUY, Gconst.SALEDEAL,Gconst.COPUTHEDGESALE))),

    insert into trsystem997
     (posn_company_code, POSN_LOCATION_CODE,posn_currency_code, posn_account_code,
      posn_reference_number, posn_reference_serial,POSN_REFERENCE_SUBSERIAL,
      posn_reference_date, posn_transaction_amount, posn_fcy_rate, posn_user_id, posn_dealer_id,
      posn_counter_party, posn_due_date, posn_product_code,   posn_hedge_trade, 
      posn_asset_liability, posn_for_currency,POSN_SUBPRODUCT_CODE,
      POSN_BROKER_CODE,POSN_OPTION_TYPE, POSN_MATURITY_FROM,
      POSN_PREMIUM_STATUS,POSN_PREMIUM_AMOUNT)
     select copt_company_code, copt_location_code,copt_base_currency,
      decode(cosu_option_type,Gconst.OptionCall,Gconst.COCALLHEDGEBUY,Gconst.COCALLHEDGESALE,Gconst.COCALLHEDGESALE),
      copt_deal_number, COSM_SERIAL_NUMBER, cosm_subserial_number, copt_execute_date,
      pkgForexProcess.fncGetOutstanding
      (COPT_DEAL_NUMBER,COSU_SERIAL_NUMBER,GConst.UTILOPTIONHEDGEDEAL,1,asondate,null,COSU_SERIAL_NUMBER),
      cosu_strike_rate,
      --(copt_lot_quantity/copt_lot_numbers),fncFutureDealRate(cfut_deal_number),(cfut_lot_quantity/cfut_lot_numbers) ,
      UserID, null, 
      case when COPT_CONTRACT_TYPE = 32800001 then
      copt_broker_code
      else copt_counter_party end, 
      cosm_maturity_date,
      COPT_BACKUP_DEAL,
--      decode(copt_hedge_trade,gconst.HEDGEDEAL,
--        decode(cosu_option_type,Gconst.OptionCall,
--        decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLHEDGEBUY,Gconst.SALEDEAL,Gconst.COCALLHEDGESALE),Gconst.OptionPut,
--        decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTHEDGEBUY,Gconst.SALEDEAL,Gconst.COPUTHEDGESALE)),gconst.TRADEDEAL,
--        decode(cosu_option_type,Gconst.OptionCall,
--        decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLTRADEBUY,Gconst.SALEDEAL,Gconst.COCALLTRADESALE),Gconst.OptionPut,
--        decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTTRADEBUY, Gconst.SALEDEAL,Gconst.COPUTTRADESALE))),
        
      decode(copt_hedge_trade,gconst.TRADEDEAL,'T','H'),
      (case
      when cosu_buy_sell = GConst.SALEDEAL and cosu_option_type = GConst.OptionPut then 'A'
      when cosu_buy_sell = Gconst.PURCHASEDEAL and cosu_option_type = Gconst.OptionCall then 'A'
      when cosu_buy_sell = Gconst.SALEDEAL and cosu_option_type = Gconst.OptionCall then 'L'
      when cosu_buy_sell = GConst.PURCHASEDEAL and cosu_option_type = GConst.OptionPut then 'L'
      end), copt_other_currency,COPT_INIT_CODE,
      (case when COPT_CONTRACT_TYPE = 32800001 then
      copt_broker_code
      else copt_counter_party end),COSU_OPTION_TYPE,copt_expiry_date,COPT_PREMIUM_STATUS,
      (CASE WHEN COPT_PREMIUM_STATUS = 33200002 THEN ABS(COPT_PREMIUM_AMOUNT)*-1 ELSE COPT_PREMIUM_AMOUNT END)
      from trtran071 inner join trtran072
      on copt_deal_number=cosu_deal_number
      and cosu_record_status not in (10200005,10200006)
      inner join trtran072A
      on cosu_deal_number=cosm_deal_number
      and COSU_SERIAL_NUMBER=COSM_SERIAL_NUMBER
      and cosu_record_status not in (10200005,10200006)
      and cosm_record_status not in (10200005,10200006)
      where (copt_company_code = DECODE(VARCOMPCODE,'30199999' ,copt_company_code) OR
            INSTR(VARCOMPCODE ,copt_company_code) >0)
       AND (copt_base_currency = DECODE(VARCURCODE,'30499999' ,copt_base_currency) OR
            INSTR(VARCURCODE ,copt_base_currency) >0)
       AND   (NVL(COPT_BACKUP_DEAL,0) = DECODE(varProdcode,'33399999' ,NVL(COPT_BACKUP_DEAL,0)) OR
            INSTR(varProdcode ,NVL(COPT_BACKUP_DEAL,0)) >0)
       AND   (NVL(COPT_INIT_CODE,0) = DECODE(varsubProdcode,'33899999' ,NVL(COPT_INIT_CODE,0)) OR
            INSTR(varsubProdcode ,NVL(COPT_INIT_CODE,0)) >0)
       AND  (NVL(copt_Location_CODE,0) = DECODE(varLocationcode,'30299999' ,NVL(copt_Location_CODE,0)) OR
            INSTR(varLocationcode ,NVL(copt_Location_CODE,0)) >0)
          and cOPT_execute_date <=   asondate       
     and ((copt_complete_date is null) or (copt_complete_date > AsonDate))
      and copt_company_code in
      (select usco_company_code
        from trsystem022a
        where usco_user_id =UserID)
      and copt_record_status in (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
commit;
--VAROPERATION := 'Insert Money Module Data in to Assests ';---exposure
--    INSERT INTO TRSYSTEM997
--     (posn_company_code, posn_currency_code, posn_account_code,
--      posn_reference_number, posn_reference_serial, posn_reference_date,
--      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--      posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--      posn_counter_party, posn_due_date, posn_maturity_month,
--      POSN_PRODUCT_CODE)
--     select mdel_company_code, mdel_currency_code,
--     -- decode( 24900011,24900011,Gconst.MONEYBORROWING,Gconst.TRADEBUYERCREDIT),
--      decode(mdel_transaction_type ,28100054,25900008,28100055,25900009),
--      mdel_deal_number, 0, mdel_execute_date,
--      mdel_deal_amount,mdel_exchange_rate,mdel_exchange_rate, 
--      mdel_amount_local,0,UserID, null,  mdel_counter_party, mdel_due_date,1,
--      decode(mdel_transaction_type ,28100054,25900008,28100055,25900009)
--      from trtran031
--      where (MDEL_PROCESS_COMPLETE= GCONST.OPTIONNO or (nvl(MDEL_COMPLETE_DATE,asondate+1) >asondate))
--      and MDEL_VALUE_DATE <asondate
--      and mdel_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
-- VAROPERATION := 'Insert Fixed deposit Data in to Assests ';---exposure
-- 
-- INSERT INTO TRSYSTEM997
--     (posn_company_code, posn_currency_code, posn_account_code,
--      posn_reference_number, posn_reference_serial, posn_reference_date,
--      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--      posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--      posn_counter_party, posn_due_date, posn_maturity_month,
--      POSN_PRODUCT_CODE)
--     select fdrf_company_code, 30400003,
--     -- decode( 24900010,24900010,Gconst.MONEYBORROWING,Gconst.TRADEBUYERCREDIT),
--      25900006,
--      fdrf_fd_number, 1, fdrf_reference_date,
--      fdrf_deposit_amount,1,1, 
--      fdrf_deposit_amount,0,UserID, null,
--      fdrf_local_bank, fdrf_maturity_date,1,25900006
--      from trtran047
--      where( nvl(FDRF_PROCESS_COMPLETE,12400002)= GCONST.OPTIONNO or (nvl(FDRF_COMPLETE_DATE,asondate+1) >asondate))
--      and fdrf_reference_date <= asondate
--      and fdrf_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
-- 
-- VAROPERATION := 'Insert Mutual Fund Data in to Assests ';---exposure
-- 
--  INSERT INTO TRSYSTEM997
--     (posn_company_code, posn_currency_code, posn_account_code,
--      posn_reference_number, posn_reference_serial, posn_reference_date,
--      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--      posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--      posn_counter_party, posn_due_date, posn_maturity_month,
--      POSN_PRODUCT_CODE)
--     select mftr_company_code, 30400003,
--     -- decode( 24900010,24900010,Gconst.MONEYBORROWING,Gconst.TRADEBUYERCREDIT),
--      25900007,
--      MFTR_REFERENCE_NUMBER, 0, mftr_reference_date,
--      round( ( pkgfixeddepositproject.fncgetnav(mftr_scheme_code ,asondate,2) *
--                pkgForexProcess.fncGetOutstanding(MFTr_reference_number,0,20,1,asondate)),2),0,1, 
--      round( ( pkgfixeddepositproject.fncgetnav(mftr_scheme_code ,asondate,2) *
--                pkgForexProcess.fncGetOutstanding(MFTr_reference_number,0,20,1,asondate)),2),0,UserID, null,
--      MFTR_BANK_CODE, asondate+1,1,25900007
--      from trtran048
--      where 
--      --((mdel_complete_date is null) or (mdel_complete_date > datpositionworkdate))
--      MFTR_PROCESS_COMPLETE= GCONST.OPTIONNO
--      and MFTR_record_status in (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);

    varOperation := 'Calculate Total Other amount it is for all currency ';
    update trsystem997
      set POSN_USD_VALUE = posn_transaction_amount * posn_fcy_rate ;-- * posn_usd_rate,
    
--    varOperation := 'Update Other Currency Rate to convert Amount into Local for all local currency Deal';
--    update trsystem997 set POSN_USD_RATE =1 
--    where POSN_FOR_CURRENCY= (select LOCN_LOCAL_CURRENCY from trmaster302
--     where POSN_LOCATION_CODE= LOCN_PICK_CODE
--     and locn_record_Status not in (10200005,10200006));
     
    varOperation := 'Get rate to convert Base Amount into Desired Amount ';   
    update trsystem997 set POSN_USD_RATE = fncGetRate
      (POSN_CURRENCY_CODE,ConvertToCurrency, AsonDate, DECODE(POSN_ASSET_LIABILITY,'A' , 25300001,'L',25300002),
      posn_maturity_month, posn_due_date);
      
--    where POSN_FOR_CURRENCY != (select LOCN_LOCAL_CURRENCY from trmaster302
--     where POSN_LOCATION_CODE= LOCN_PICK_CODE
--     and locn_record_Status not in (10200005,10200006));

    varOperation := 'Convert Base Amount into Desired Amount ';   
    update trsystem997
      set POSN_REVALUE_USD =  posn_transaction_amount * POSN_USD_RATE ;-- * posn_usd_rate,

    varOperation := 'Convert Base Amount into Desired Amount ';   
    update trsystem997
      set POSN_REVALUE_INR =  posn_transaction_amount * Posn_fcy_rate * POSN_USD_RATE ;-- * posn_usd_rate,
      
--    varOperation := 'Update Local Amount for the Position';   
--    update trsystem997
--      set POSN_INR_VALUE = posn_transaction_amount * posn_fcy_rate *POSN_USD_RATE ;-- * posn_usd_rate,

--   ConvertToCurrency in number := 30400004 ,
--     ConvertToLocalCurrency in number := 30400003
    
     -- POSN_USD_RATE Convert into Exchange Rate
     -- POSN_USD_VALUE Converted Value 
     -- POSN_REVALUE_USD Revalued USD
     -- POSN_REVALUE_INR Revalued INR
     -- POSN_MTM_RateActual MTM Rate Actual,
     -- POSN_MTM_actual Actual Amount
     -- POSN_MTM_Local MTM in Local Currency
     -- Posn_Was_Rate Convert into Local Currency
     --commit;
   varOperation := 'Update Actual MTM - Forward';  
   update trsystem997 set POSN_MTM_RateActual =  fncGetRate
      (posn_currency_code,POSN_FOR_CURRENCY, AsonDate,  DECODE(POSN_ASSET_LIABILITY,'A' , 25300001,'L',25300002), 
       posn_maturity_month, posn_due_date);
   varOperation := 'usd inr spot rate update';        
   update trsystem997 set POSN_SPOT_RATE = pkgForexProcess.fncGetRate(30400004,30400003,POSN_REFERENCE_DATE,
                          DECODE(POSN_ASSET_LIABILITY,'A' , 25300001,'L',25300002),0,NULL)
                          WHERE (POSN_FOR_CURRENCY != 30400003 OR POSN_CURRENCY_CODE != 30400004)
                          AND POSN_DUE_DATE >= AsonDate ;
   update trsystem997 set POSN_SPOT_RATE = POSN_FCY_RATE
                          WHERE POSN_FOR_CURRENCY = 30400003 AND POSN_CURRENCY_CODE = 30400004;    
                          
   varOperation := 'usd value updating';        
   update trsystem997 set POSN_USD_VALUE = POSN_TRANSACTION_AMOUNT * POSN_USD_RATE;

                          
    --where POSN_ACCOUNT_CODE not in (gconst.CFHEDGEBUY,gconst.CFHEDGESALE);
    --Uncommented below lines for Futures rate update
--     varOperation := 'Update Actual MTM - Futures ';  
--   update trsystem997 set POSN_MTM_RateActual =  fncGetRate
--      (posn_currency_code,POSN_FOR_CURRENCY, AsonDate,  DECODE(POSN_ASSET_LIABILITY,'A' , 25300001,'L',25300002), 
--      posn_maturity_month, posn_due_date)
--    where POSN_ACCOUNT_CODE in (gconst.CFHEDGEBUY,gconst.CFHEDGESALE);
    
     varOperation := 'Update Actual MTM Amount - Futures ';  
     
    update trsystem997 set  POSN_MTM_actual = fncgetprofitloss(POSN_TRANSACTION_AMOUNT,POSN_MTM_RateActual,POSN_FCY_RATE, 
      DECODE(POSN_ASSET_LIABILITY,'A' , 25300001,'L',25300002));

    
     varOperation := 'Update Actual MTM - Wash Rate for Non Local Currency';  
   update trsystem997 set posn_MTM_WashRate =  fncGetRate
      (POSN_FOR_CURRENCY, (select LOCN_LOCAL_CURRENCY from trmaster302
     where POSN_LOCATION_CODE= LOCN_PICK_CODE
     and locn_record_Status not in (10200005,10200006)), AsonDate,  
     DECODE(POSN_ASSET_LIABILITY,'A' , 25300001,'L',25300002), posn_maturity_month, posn_due_date)
    where POSN_FOR_CURRENCY != (select LOCN_LOCAL_CURRENCY from trmaster302
     where POSN_LOCATION_CODE= LOCN_PICK_CODE
     and locn_record_Status not in (10200005,10200006));
    
  
   varOperation := 'Update Actual MTM - Wash Rate for Non Local Currency';  
   update trsystem997 set posn_MTM_WashRate =  1
   where POSN_FOR_CURRENCY = (select LOCN_LOCAL_CURRENCY from trmaster302
     where POSN_LOCATION_CODE= LOCN_PICK_CODE
     and locn_record_Status not in (10200005,10200006));
     
    varOperation := 'Update Actual MTM Convert into Local Currency ';  
     
    update trsystem997 set POSN_MTM_Local = POSN_MTM_actual*posn_MTM_WashRate;
    

--    varOperation := 'Calculating M2M Rates for Forwards';
--    update trsystem997 set posn_m2m_inrrate =  fncGetRate
--      (posn_currency_code,ConvertToLocalCurrency, AsonDate, DECODE(SIGN(25900050 - POSN_ACCOUNT_CODE),1 , 25300001,-1,25300002), posn_maturity_month, posn_due_date),
--      posn_usd_rate = fncGetRate
--      (posn_currency_code, ConvertToCurrency, AsonDate, DECODE(SIGN(25900050 - POSN_ACCOUNT_CODE),1 , 25300002,-1,25300001), posn_maturity_month, posn_due_date),
--       posn_M2M_usdrate = fncGetRate
--      (ConvertToCurrency, ConvertToLocalCurrency, AsonDate, DECODE(SIGN(25900050 - POSN_ACCOUNT_CODE),1 , 25300002,-1,25300001), posn_maturity_month, posn_due_date),
--      POSN_MTM_RateActual =fncGetRate
--      (ConvertToCurrency, ConvertToLocalCurrency, AsonDate, DECODE(SIGN(25900050 - POSN_ACCOUNT_CODE),1 , 25300002,-1,25300001), posn_maturity_month, posn_due_date)
--     where posn_currency_code not in (gconst.FORWARDHEDGEBUY,gconst.FORWARDHEDGESALE);

--    varOperation := 'Calculating M2M Rates for Forwards';
--    update trsystem997
--      set posn_m2m_inrrate =  fncGetRate
--      (posn_currency_code,30400003, AsonDate, DECODE(SIGN(25900050 - POSN_ACCOUNT_CODE),1 , 25300001,-1,25300002), posn_maturity_month, posn_due_date),
--      posn_usd_rate = fncGetRate
--      (posn_currency_code, 30400004, AsonDate, DECODE(SIGN(25900050 - POSN_ACCOUNT_CODE),1 , 25300001,-1,25300002), posn_maturity_month, posn_due_date)
--      where posn_currency_code  in (gconst.FORWARDHEDGEBUY,gconst.FORWARDHEDGESALE);

--    update trsystem997
--      set posn_revalue_inr =
--        round(posn_transaction_amount * posn_usd_rate *posn_M2M_usdrate ,0),
--        posn_revalue_usd =round(posn_transaction_amount * posn_usd_rate,2),
--        posn_position_inr =
--         decode(sign(25900050 - posn_account_code), 1,
--       round(posn_transaction_amount * posn_m2m_inrrate,0) - posn_inr_value,
--       -1, posn_inr_value - round(posn_transaction_amount * posn_m2m_inrrate,0));




   /* varOperation := 'Calculate Profit  According to M2m Rate';
    update trsystem997
      set posn_position_inr =decode(sign(25900050 - posn_account_code), 1,
      posn_inr_value-posn_revalue_inr,-1, posn_revalue_inr-posn_inr_value)
      where posn_product_code is not null; */

--      varOperation := 'Test error';
--    update trsystem997
--      set posn_position_usd = round(posn_position_inr / decode(nvl(posn_usd_rate,0),0,1,posn_usd_rate),2)
--     -- posn_revalue_usd = round((posn_transaction_amount * posn_m2m_inrrate) / decode(nvl(posn_usd_rate,0), 0,1,1),2)
--      where posn_product_code is not null;

    update trsystem997
      set posn_product_code= posn_account_code
      where posn_product_code is null;

  --

    commit;
    return numError;
Exception

  when others then
      Rollback;
      varError := SQLERRM;
      varerror := 'PositionGen: ' || varmessage || varoperation || varerror;
      raise_application_error(-20101,   varerror);
      

      Return SQLERRM;
End fncPositionGenerate;

----end

--Function fncRbiReport
--    ( UserID in varchar2,
--      AsonDate in date)
--    return number
--    is
--
--    PRAGMA AUTONOMOUS_TRANSACTION;
----  Created on 19/03/08
--    datToday        date;
--    datTemp         date;
--    numError        number;
--    varOperation    GConst.gvarOperation%type;
--    varMessage      GConst.gvarMessage%type;
--    varError        GConst.gvarError%type;
----    Type tpPosition is ref cursor return trsystem997%ROWTYPE;
----    curTermLoan     tpPosition;
----    recPosition     trsystem997%ROWTYPE;
--Begin
--    numError := 0;
--    varMessage := 'Generating Position Figures for date: ' || AsonDate;
--    datToday := AsonDate;
--
--    delete from trsystem997;
--    varOperation := 'Inserting records for Trade Details';
--    insert into trsystem997
--    (posn_company_code, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month)
--    select trad_company_code, trad_trade_currency, trad_import_export,
--      trad_trade_reference, 0, trad_entry_date,
--      fncGetOutstanding(trad_trade_reference,0,GConst.UTILEXPORTS,
--        GConst.AMOUNTFCY, AsonDate) tradefcy,trad_trade_rate,0,
--      fncGetOutstanding(trad_trade_reference,0,GConst.UTILEXPORTS,
--        GConst.AMOUNTINR, AsonDate) tradeinr, 0, UserID, null,TRAD_LOCAL_BANK,
--      trad_maturity_date,fncAllotMonth(AsonDate, trad_maturity_date)
--      from trtran002
--      --abhijit commented
--    --  where (trad_complete_date is null or trad_complete_date > AsonDate)
--    where (TRAD_MATURITY_MONTH > AsonDate) and trad_import_export in(25900077,25900017)
--      and trad_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--      numError := SQl%ROWCOUNT;
--
--
----    varOperation := 'Inserting records for Trade Contracts';
----    insert into trsystem997
----    (posn_company_code, posn_currency_code, posn_account_code,
----     posn_reference_number, posn_reference_serial, posn_reference_date,
----     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
----     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
----     posn_counter_party, posn_due_date, posn_maturity_month)
----    select 30199999 CompanyCode, deal_base_currency,
----      decode(fncAllotMonth(deal_counter_party, AsonDate, deal_maturity_date), 0,
----        decode(deal_buy_sell,
----            GConst.PURCHASEDEAL, GConst.TRADEBUYSPOT,
----            GConst.SALEDEAL, GConst.TRADESALESPOT),
----        decode(deal_buy_sell,
----            GConst.PURCHASEDEAL, GConst.TRADEBUYFORWARD,
----            GConst.SALEDEAL, GConst.TRADESALEFORWARD)) AccountCode,
----      deal_deal_number, deal_serial_number, deal_execute_date,
----      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADEDEAL,
----        GConst.AMOUNTFCY, AsonDate) tradefcy,
----      decode(deal_other_currency, GConst.INDIANRUPEE, deal_exchange_rate, deal_local_rate)
----        deal_exchange_rate,0,
----      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADEDEAL,
----        GConst.AMOUNTINR, AsonDate) tradeinr,0,
----      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
----      fncAllotMonth(deal_counter_party, AsonDate, deal_maturity_date)
----      from trtran001
----      where ((deal_complete_date is null) or (deal_complete_date > AsonDate))
----      and deal_hedge_trade = GConst.TRADEDEAL
----      and deal_record_status in
----      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED)
----    union
------  Cross Currency Deals
----    select 30199999 CompanyCode, deal_other_currency,
----      decode(fncAllotMonth(deal_counter_party, AsonDate, deal_maturity_date), 0,
----         decode(deal_buy_sell,
----            GConst.PURCHASEDEAL, GConst.TRADESALESPOT,
----            GConst.SALEDEAL, GConst.TRADEBUYSPOT),
----         decode(deal_buy_sell,
----            GConst.PURCHASEDEAL, GConst.TRADESALEFORWARD ,
----            GConst.SALEDEAL, GConst.TRADEBUYFORWARD)) AccountCode,
----      deal_deal_number, deal_serial_number, deal_execute_date,
----      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADECROSS,
----        GConst.AMOUNTFCY, AsonDate) tradefcy, round(deal_amount_local / deal_other_amount,4),0,
----      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADECROSS,
----        GConst.AMOUNTINR, AsonDate) tradeinr,0,
----      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
----      fncAllotMonth(deal_counter_party, AsonDate, deal_maturity_date)
----      from trtran001
----      where deal_other_currency != GConst.INDIANRUPEE
----      and deal_hedge_trade = GConst.TRADEDEAL
----      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
----      and deal_record_status in
----      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--
----
--       varOperation := 'Inserting records for Hedge which are all not at linked and partially linked Contracts';
--    insert into trsystem997
--    (posn_company_code, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month)
--    select deal_company_code CompanyCode, deal_base_currency,
--      decode(fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number)), 0,
--        decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADEBUYSPOT,
--            GConst.SALEDEAL, GConst.TRADESALESPOT),
--        decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADEBUYFORWARD,
--            GConst.SALEDEAL, GConst.TRADESALEFORWARD)) AccountCode,
--      deal_deal_number, 0 , deal_execute_date,
--     fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGEDEAL,
--        GConst.AMOUNTFCY, AsonDate) tradefcy, deal_exchange_rate,
--      --decode(deal_other_currency, GConst.INDIANRUPEE, deal_exchange_rate, deal_local_rate),
--        0,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGEDEAL,
--        GConst.AMOUNTINR, AsonDate) tradeinr,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number))
--      from trtran001
--      where ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_execute_date <= AsonDate
--      and deal_hedge_trade = GConst.HEDGEDEAL
--      and fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGEDEAL,
--        GConst.AMOUNTFCY, AsonDate) >0
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--
--   -- union
----  Cross Currency Deals
--    insert into trsystem997
--    (posn_company_code, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month)
--    select deal_company_code, deal_other_currency,
--      decode(fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number)), 0,
--         decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADESALESPOT,
--            GConst.SALEDEAL, GConst.TRADEBUYSPOT),
--         decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADESALEFORWARD ,
--            GConst.SALEDEAL, GConst.TRADEBUYFORWARD)) AccountCode,
--      deal_deal_number, deal_serial_number, deal_execute_date,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGECROSS,
--        GConst.AMOUNTFCY, AsonDate) tradefcy,
--      round(deal_amount_local / deal_other_amount,4),0,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGECROSS,
--        GConst.AMOUNTINR, AsonDate) tradeinr,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number))
--      from trtran001
--      where  deal_other_currency != GConst.INDIANRUPEE
--      and deal_hedge_trade = GConst.HEDGEDEAL
--      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_execute_date <= AsonDate
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
----    varOperation := 'Inserting records for Hedge Contracts';
----    insert into trsystem997
----    (posn_company_code, posn_currency_code, posn_account_code,
----     posn_reference_number, posn_reference_serial, posn_reference_date,
----     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
----     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
----     posn_counter_party, posn_due_date, posn_maturity_month)
----    select hedg_company_code CompanyCode, deal_base_currency,
----      decode(fncAllotMonth(deal_counter_party, AsonDate,
----        pkgReturnCursor.fncRollover(deal_deal_number)), 0,
----        decode(deal_buy_sell,
----            GConst.PURCHASEDEAL, GConst.TRADEBUYSPOT,
----            GConst.SALEDEAL, GConst.TRADESALESPOT),
----        decode(deal_buy_sell,
----            GConst.PURCHASEDEAL, GConst.TRADEBUYFORWARD,
----            GConst.SALEDEAL, GConst.TRADESALEFORWARD)) AccountCode,
----      deal_deal_number, rownum, deal_execute_date,
----      fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
----        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference) tradefcy,
----      decode(deal_other_currency, GConst.INDIANRUPEE, deal_exchange_rate, deal_local_rate),
----        0, decode(deal_other_currency,30400003,(fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
----        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference)* deal_exchange_rate),
----        (fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
----        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference)* deal_local_rate))
------      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGEDEAL,
------        GConst.AMOUNTINR, AsonDate, hedg_trade_reference) tradeinr
----        ,0,
----      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
----      fncAllotMonth(deal_counter_party, AsonDate,
----        pkgReturnCursor.fncRollover(deal_deal_number))
----      from trtran001, trtran004
----      where deal_deal_number = hedg_deal_number
----      and deal_serial_number = hedg_deal_serial
----      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
----      and deal_execute_date <= AsonDate
----      and deal_hedge_trade = GConst.HEDGEDEAL
----      and deal_record_status in
----      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED)
----      and pkgforexprocess.fncGetOutstanding(deal_deal_number, deal_serial_number,2,1, AsonDate) =0;
--
--   --abhijit commented on 05072012
---- varOperation := 'Inserting records for Hedge Contracts';
----    insert into trsystem997
----    (posn_company_code, posn_currency_code, posn_account_code,
----     posn_reference_number, posn_reference_serial, posn_reference_date,
----     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
----     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
----     posn_counter_party, posn_due_date, posn_maturity_month)
----    select hedg_company_code CompanyCode, deal_base_currency,
----      decode(fncAllotMonth(deal_counter_party, AsonDate,
----        pkgReturnCursor.fncRollover(deal_deal_number)), 0,
----        decode(deal_buy_sell,
----            GConst.PURCHASEDEAL, GConst.TRADEBUYSPOT,
----            GConst.SALEDEAL, GConst.TRADESALESPOT),
----        decode(deal_buy_sell,
----            GConst.PURCHASEDEAL, GConst.TRADEBUYFORWARD,
----            GConst.SALEDEAL, GConst.TRADESALEFORWARD)) AccountCode,
----      deal_deal_number, rownum+100, deal_execute_date,
----      fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
----        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference) tradefcy,
----      decode(deal_other_currency, GConst.INDIANRUPEE, deal_exchange_rate, deal_local_rate),
----        0, decode(deal_other_currency,30400003,(fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
----        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference)* deal_exchange_rate),
----        (fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
----        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference)* deal_local_rate))
------      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGEDEAL,
------        GConst.AMOUNTINR, AsonDate, hedg_trade_reference) tradeinr
----        ,0,
----      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
----      fncAllotMonth(deal_counter_party, AsonDate,
----        pkgReturnCursor.fncRollover(deal_deal_number))
----      from trtran001, trtran004
----      where deal_deal_number = hedg_deal_number
----      and deal_serial_number = hedg_deal_serial
----      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
----      and deal_execute_date <= AsonDate
----      and deal_hedge_trade = GConst.HEDGEDEAL
----      and deal_record_status in
----      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
------    union
------  Cross Currency Deals
----
----  varOperation := 'Inserting Cross Currency Hedge Contracts';
----    insert into trsystem997
----    (posn_company_code, posn_currency_code, posn_account_code,
----     posn_reference_number, posn_reference_serial, posn_reference_date,
----     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
----     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
----     posn_counter_party, posn_due_date, posn_maturity_month)
----    select hedg_company_code, deal_other_currency,
----      decode(fncAllotMonth(deal_counter_party, AsonDate,
----        pkgReturnCursor.fncRollover(deal_deal_number)), 0,
----         decode(deal_buy_sell,
----            GConst.PURCHASEDEAL, GConst.TRADESALESPOT,
----            GConst.SALEDEAL, GConst.TRADEBUYSPOT),
----         decode(deal_buy_sell,
----            GConst.PURCHASEDEAL, GConst.TRADESALEFORWARD ,
----            GConst.SALEDEAL, GConst.TRADEBUYFORWARD)) AccountCode,
----      deal_deal_number,rownum , deal_execute_date,
----      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGECROSS,
----        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference) tradefcy,
----        deal_exchange_Rate,0,
----      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGECROSS,
----        GConst.AMOUNTINR, AsonDate, hedg_trade_reference) tradeinr,0,
----      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
----      fncAllotMonth(deal_counter_party, AsonDate,
----        pkgReturnCursor.fncRollover(deal_deal_number))
----      from trtran001, trtran004
----      where deal_deal_number = hedg_deal_number
----      and deal_serial_number = hedg_deal_serial
----      and deal_other_currency != GConst.INDIANRUPEE
----      and deal_hedge_trade = GConst.HEDGEDEAL
----      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
----      and deal_execute_date <= AsonDate
----      and deal_record_status in
----      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--  --abhijit ends
--
----    varOperation := 'Inserting records for FCY Loans';
----    insert into trsystem997
----    (posn_company_code, posn_currency_code, posn_account_code,
----     posn_reference_number, posn_reference_serial, posn_reference_date,
----     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
----     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
----     posn_counter_party, posn_due_date, posn_maturity_month)
----    select fcln_company_code, fcln_currency_code,
----      decode(fcln_loan_type, GConst.LOANBUYERSCREDIT, GConst.TRADEBUYERCREDIT,
----      GConst.LOANPCFC, GConst.TRADEPCFC, GConst.LOANPSCFC, GConst.TRADEPSCFC),
----      fcln_loan_number, 0, fcln_sanction_date,
----      fncGetOutstanding(fcln_loan_number, 0,GConst.UTILFCYLOAN,
----        GConst.AMOUNTFCY, AsonDate) fcln_sanctioned_fcy,fcln_conversion_rate,0,
----      fncGetOutstanding(fcln_loan_number, 0,GConst.UTILFCYLOAN,
----        GConst.AMOUNTINR, AsonDate) fcln_sanctioned_inr,0,
----      UserID, null, fcln_local_bank, fcln_maturity_to,
----      fncAllotMonth(AsonDate, fcln_maturity_to)
----      from trtran005
----      where ((fcln_complete_date is null) or (fcln_complete_date > AsonDate))
----      and fcln_record_status in
----      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--  --    and fcln_loan_type not in (GConst.LOANBUYERSCREDIT);
-- ---kumar.h updates 0n 12/05/09  for buyers credit
--     varOperation := 'Inserting records for Buyers Credit';
--    insert into trsystem997
--    (posn_company_code, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month)
--    select bcrd_company_code, bcrd_currency_code,
--           GConst.TRADEBUYERCREDIT,
--           bcrd_buyers_credit, 0, bcrd_sanction_date,
--      fncGetOutstanding(bcrd_buyers_credit, 0,GConst.UTILBCRLOAN,
--        GConst.AMOUNTFCY, AsonDate) bcrd_sanctioned_fcy,bcrd_conversion_rate,0,
--      fncGetOutstanding(bcrd_buyers_credit, 0,GConst.UTILBCRLOAN,
--        GConst.AMOUNTINR, AsonDate) bcrd_sanctioned_inr,0,
--      UserID, null, bcrd_local_bank, bcrd_due_date,
--      fncAllotMonth(AsonDate, bcrd_due_date)
--      from BuyersCredit
--      where ((bcrd_completion_date is null) or (bcrd_completion_date > AsonDate))
--      and bcrd_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--     ---kumar.h updates 0n 12/05/09  for buyers credit
----------------------------------------------------Money Module Added by Manjunath Reddy  on 09-04-2009----------------------------------
----24900011		Short Term Borrowing
----  varOperation := 'Insert Money Module Date in to Assests ';
----    insert into trsystem997
----     (posn_company_code, posn_currency_code, posn_account_code,
----      posn_reference_number, posn_reference_serial, posn_reference_date,
----      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
----      posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
----      posn_counter_party, posn_due_date, posn_maturity_month,posn_product_code)
----     select mdel_company_code, mdel_currency_code,
----      decode( mdel_account_head,24900011,Gconst.MONEYBORROWING,Gconst.TRADEBUYERCREDIT),
----      mdel_deal_number, 0, mdel_execute_date,
----      mdel_deal_amount,mdel_exchange_rate,mdel_exchange_rate,
----      mdel_amount_local,0,UserID, null,
----      mdel_counter_party, mdel_due_date,1,mdel_account_head
----      from trtran031
----      where
----      --((mdel_complete_date is null) or (mdel_complete_date > AsonDate))
----      mdel_process_complete= Gconst.optionNO
----      and mdel_record_status in
----      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--
----    varOperation := 'Calculating M2M Rates';
----    update trsystem997
----      set posn_m2m_inrrate =  fncGetRate
----      (posn_currency_code,30400003, AsonDate, 0, posn_maturity_month, posn_due_date),
----      posn_usd_rate = fncGetRate
----      (30400004, 30400003, AsonDate, 0, posn_maturity_month, posn_due_date);
----
----    update trsystem997
----      set posn_revalue_inr =
----        round(posn_transaction_amount * posn_m2m_inrrate,0),
----        posn_revalue_usd =
----        round((posn_transaction_amount * posn_m2m_inrrate) / posn_usd_rate,2),
----        posn_position_inr =
----        decode(sign(25900050 - posn_account_code), 1,
----        round(posn_transaction_amount * posn_m2m_inrrate,0) - posn_inr_value,
----        -1, posn_inr_value - round(posn_transaction_amount * posn_m2m_inrrate,0));
----
--
--
------------------------------------------------------Commodity Added by Manjunath Reddy  on 09-04-2009----------------------------------
----varOperation := 'Insert Commodity Module in to Assests ';
------ posn_transaction_amount     No of LOts
------ posn_fcy_rate               Lot Price
------ posn_usd_rate               Lot Size
------ posn_inr_value              Transaction Amount
------ posn_m2m_inrrate            M2M Lot Price
------ posn_revalue_inr            Tansaction Amount For M2m Rate
------ posn_position_inr           Profit LOSS
----
----    insert into trsystem997
----     (posn_company_code, posn_currency_code, posn_account_code,
----      posn_reference_number, posn_reference_serial, posn_reference_date,
----      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
----      posn_user_id, posn_dealer_id,
----      posn_counter_party, posn_due_date, posn_maturity_month, posn_product_code,
----      posn_m2m_inrrate)
----     select cmdl_company_code, cmdl_currency_code,
----      decode(cmdl_hedge_trade,gconst.HEDGEDEAL,decode(cmdl_buy_sell,Gconst.PURCHASEDEAL,Gconst.COMMODITYHEDGEBUY,
----             Gconst.SALEDEAL,Gconst.COMMODITYHEDGESALE),gconst.TRADEDEAL,
----            decode(cmdl_buy_sell,Gconst.PURCHASEDEAL,Gconst.COMMODITYTRADEBUY,Gconst.SALEDEAL,Gconst.COMMODITYTRADESALE)),
----      cmdl_deal_number, 0, cmdl_execute_date,
----      fncGetOutstanding(cmdl_deal_number, 0,GConst.UTILCOMMODITYDEAL,
----      GConst.AMOUNTFCY, AsonDate),fncCommDealRate(cmdl_deal_number),(cmdl_product_quantity/cmdl_lot_numbers) ,
----      UserID, null, cmdl_exchange_code, cmdl_maturity_date,1,cmdl_product_code,
----      pkgforexprocess.fncCommodityMTMRate(cmdl_maturity_date,cmdl_exchange_code,cmdl_product_code,AsonDate)
----      from trtran051
----      where ((cmdl_complete_date is null) or (cmdl_complete_date > AsonDate))
----      and cmdl_process_complete= Gconst.optionNO
----      and cmdl_record_status in
----      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
----    begin
----      VarOperation :='Calling Tf';
----    --  numError  := trfinance.fncReturnTlGap(AsonDate);
----    Exception
----      when others then
----        NULL;
----    end;
----    fetch curTermLoan bulk collect into recPosition;
----
----    Loop
------      Fetch curTermLoan bulinto recPosition;
----      Exit when curTermLoan%NOTFOUND;
----
----     insert into trsystem997
----       (posn_company_code, posn_currency_code, posn_account_code,
----        posn_reference_number, posn_reference_serial, posn_reference_date,
----        posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
----        posn_user_id, posn_dealer_id,
----        posn_counter_party, posn_due_date, posn_maturity_month, posn_product_code,
----        posn_m2m_inrrate)
----    values
----       (recPosition.posn_company_code, recPosition.posn_currency_code,
----        recPosition.posn_account_code, recPosition.posn_reference_number,
----        recPosition.posn_reference_serial, recPosition.posn_reference_date,
----        recPosition.posn_transaction_amount, recPosition.posn_fcy_rate,
----        recPosition.posn_usd_rate, recPosition.posn_user_id,
----        recPosition.posn_dealer_id, recPosition.posn_counter_party,
----        recPosition.posn_due_date, recPosition.posn_maturity_month,
----        recPosition.posn_product_code,recPosition.posn_m2m_inrrate);
----    End Loop;
----    loop
----    end loop;
----
--
--
------------------------------------------------------Currency Futures Added by Manjunath Reddy  on 10-06-2011----------------------------------
----varOperation := 'Insert Currency Future Module in to Assests ';
----
----    insert into trsystem997
----     (posn_company_code, posn_currency_code, posn_account_code,
----      posn_reference_number, posn_reference_serial, posn_reference_date,
----      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
----      posn_user_id, posn_dealer_id,
----      posn_counter_party, posn_due_date, posn_maturity_month, posn_product_code,
----      posn_m2m_inrrate)
----     select cfut_company_code, cfut_base_currency,
----      decode(cfut_hedge_trade,gconst.HEDGEDEAL,decode(cfut_buy_sell,Gconst.PURCHASEDEAL,Gconst.CFHEDGEBUY,
----             Gconst.SALEDEAL,Gconst.CFHEDGESALE),gconst.TRADEDEAL,
----            decode(cfut_buy_sell,Gconst.PURCHASEDEAL,Gconst.CFTRADEBUY,Gconst.SALEDEAL,Gconst.CFTRADESALE)),
----      cfut_deal_number, 0, cfut_execute_date,
----      cfut_base_amount,fncFutureDealRate(cfut_deal_number),(cfut_lot_quantity/cfut_lot_numbers) ,
----      UserID, null, cfut_exchange_code, cfut_maturity_date,1,decode(cfut_hedge_trade,gconst.HEDGEDEAL,decode(cfut_buy_sell,Gconst.PURCHASEDEAL,Gconst.CFHEDGEBUY,
----             Gconst.SALEDEAL,Gconst.CFHEDGESALE),gconst.TRADEDEAL,
----            decode(cfut_buy_sell,Gconst.PURCHASEDEAL,Gconst.CFTRADEBUY,Gconst.SALEDEAL,Gconst.CFTRADESALE)),
----      pkgforexprocess.fncCommodityMTMRate(cfut_maturity_date,cfut_exchange_code,cfut_product_code,AsonDate)
----      from trtran061
----      where ((cfut_complete_date is null) or (cfut_complete_date > AsonDate))
----      and cfut_process_complete= Gconst.optionNO
----      and cfut_record_status in
----      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
----
----    begin
----      VarOperation :='Calling Tf';
----    --  numError  := trfinance.fncReturnTlGap(AsonDate);
----    Exception
----      when others then
----        NULL;
----    end;
--
--
--
------------------------------------------------------Currency Options Added by Manjunath Reddy  on 18-06-2011----------------------------------
--varOperation := 'Insert Currency Options Module in to Assests ';
--
--    insert into trsystem997
--     (posn_company_code, posn_currency_code, posn_account_code,
--      posn_reference_number, posn_reference_serial, posn_reference_date,
--      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--      posn_user_id, posn_dealer_id,
--      posn_counter_party, posn_due_date, posn_maturity_month, posn_product_code,posn_m2m_inrrate)
--     select copt_company_code, copt_base_currency,
--      decode(copt_hedge_trade,gconst.HEDGEDEAL,decode(cosu_option_type,Gconst.OptionCall,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLHEDGEBUY,
--             Gconst.SALEDEAL,Gconst.COCALLHEDGESALE),Gconst.OptionPut,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTHEDGEBUY,
--             Gconst.SALEDEAL,Gconst.COPUTHEDGESALE)),gconst.TRADEDEAL,
--             decode(cosu_option_type,Gconst.OptionCall,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLTRADEBUY,
--             Gconst.SALEDEAL,Gconst.COCALLTRADESALE),Gconst.OptionPut,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTTRADEBUY,
--             Gconst.SALEDEAL,Gconst.COPUTTRADESALE))),
--      copt_deal_number, cosu_serial_number, copt_execute_date,
--      decode(COPT_DEAL_TYPE,32300002,copt_base_amount*2,32300005,copt_base_amount*2,copt_base_amount),cosu_strike_rate,0,
--      --(copt_lot_quantity/copt_lot_numbers),
--
--      --fncFutureDealRate(cfut_deal_number),(cfut_lot_quantity/cfut_lot_numbers) ,
--      UserID, null, copt_counter_party, copt_maturity_date,1,      decode(copt_hedge_trade,gconst.HEDGEDEAL,decode(cosu_option_type,Gconst.OptionCall,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLHEDGEBUY,
--             Gconst.SALEDEAL,Gconst.COCALLHEDGESALE),Gconst.OptionPut,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTHEDGEBUY,
--             Gconst.SALEDEAL,Gconst.COPUTHEDGESALE)),gconst.TRADEDEAL,
--             decode(cosu_option_type,Gconst.OptionCall,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLTRADEBUY,
--             Gconst.SALEDEAL,Gconst.COCALLTRADESALE),Gconst.OptionPut,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTTRADEBUY,
--             Gconst.SALEDEAL,Gconst.COPUTTRADESALE))),0
--             --,
--             --,
--     -- pkgforexprocess.fncCommodityMTMRate(cfut_maturity_date,cfut_exchange_code,cfut_product_code,AsonDate)
--      --copt_strike_rate
--      from trtran071 right outer join trtran072
--      on copt_deal_number=cosu_deal_number
--     where ((copt_complete_date is null) or (copt_complete_date > AsonDate))
--      and copt_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--
--
----    varOperation := 'Calculate Total Tansaction amount  Transaction amount';
----
----    update trsystem997
----      set posn_inr_value=posn_transaction_amount * posn_fcy_rate * posn_usd_rate,
----      posn_revalue_inr= posn_transaction_amount * posn_usd_rate * posn_m2m_inrrate
----      where posn_product_code is not null;
--
--  --  varOperation := 'Calculate Profit  According to M2m Rate';
--
----    update trsystem997
----      set posn_position_inr=decode(sign(25900050 - posn_account_code), 1,
----      posn_inr_value-posn_revalue_inr,-1, posn_revalue_inr-posn_inr_value)
----      where posn_product_code is not null;
----
----    update trsystem997
----      set posn_position_usd = round(posn_position_inr / posn_usd_rate,2),
----      posn_product_code= posn_account_code
----      where posn_product_code is  null;
--
--    commit;
--    return numError;
--Exception
--
--  when others then
--      varError := SQLERRM;
--      varerror := 'PositionGen: ' || varmessage || varoperation || varerror;
--      raise_application_error(-20101,   varerror);
--      Rollback;
--
--      return -1;
--End fncRbiReport;
Function fncRbiReport
    ( UserID in varchar2,
      AsonDate in date)
    return number
    is

    PRAGMA AUTONOMOUS_TRANSACTION;
--  Created on 19/03/08
    datToday        date;
    datTemp         date;
    numError        number;
    varOperation    GConst.gvarOperation%type;
    varMessage      GConst.gvarMessage%type;
    varError        GConst.gvarError%type;
--    Type tpPosition is ref cursor return trsystem997%ROWTYPE;
--    curTermLoan     tpPosition;
--    recPosition     trsystem997%ROWTYPE;
Begin
    numError := 0;
    varMessage := 'Generating Position Figures for date: ' || AsonDate;
    datToday := AsonDate;

    delete from trsystem997;
    varOperation := 'Inserting records for Trade Details';
    insert into trsystem997
    (posn_company_code, posn_currency_code, posn_account_code,
     posn_reference_number, posn_reference_serial, posn_reference_date,
     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
     posn_counter_party, posn_due_date, posn_maturity_month)
    select trad_company_code, trad_trade_currency, trad_import_export,
      trad_trade_reference, 0, trad_entry_date,
      fncGetOutstanding(trad_trade_reference,0,GConst.UTILEXPORTS,
        GConst.AMOUNTFCY, AsonDate) tradefcy,trad_trade_rate,0,
      fncGetOutstanding(trad_trade_reference,0,GConst.UTILEXPORTS,
        GConst.AMOUNTINR, AsonDate) tradeinr, 0, UserID, null,
        --decode(TRAD_LOCAL_BANK,'0',30699999,trad_local_bank),
        pkgforexprocess.GETCOUNTERPARTY(TRAD_TRADE_REFERENCE),
      trad_maturity_date,fncAllotMonth(AsonDate, trad_maturity_date)
      from trtran002
      --abhijit commented
      where trad_maturity_date > AsonDate and trad_import_export in(25900077,25900017)
      and trad_record_status in
      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);

      numError := SQl%ROWCOUNT;


--    varOperation := 'Inserting records for Trade Contracts';
--    insert into trsystem997
--    (posn_company_code, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month)
--    select 30199999 CompanyCode, deal_base_currency,
--      decode(fncAllotMonth(deal_counter_party, AsonDate, deal_maturity_date), 0,
--        decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADEBUYSPOT,
--            GConst.SALEDEAL, GConst.TRADESALESPOT),
--        decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADEBUYFORWARD,
--            GConst.SALEDEAL, GConst.TRADESALEFORWARD)) AccountCode,
--      deal_deal_number, deal_serial_number, deal_execute_date,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADEDEAL,
--        GConst.AMOUNTFCY, AsonDate) tradefcy,
--      decode(deal_other_currency, GConst.INDIANRUPEE, deal_exchange_rate, deal_local_rate)
--        deal_exchange_rate,0,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADEDEAL,
--        GConst.AMOUNTINR, AsonDate) tradeinr,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate, deal_maturity_date)
--      from trtran001
--      where ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_hedge_trade = GConst.TRADEDEAL
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED)
--    union
----  Cross Currency Deals
--    select 30199999 CompanyCode, deal_other_currency,
--      decode(fncAllotMonth(deal_counter_party, AsonDate, deal_maturity_date), 0,
--         decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADESALESPOT,
--            GConst.SALEDEAL, GConst.TRADEBUYSPOT),
--         decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADESALEFORWARD ,
--            GConst.SALEDEAL, GConst.TRADEBUYFORWARD)) AccountCode,
--      deal_deal_number, deal_serial_number, deal_execute_date,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADECROSS,
--        GConst.AMOUNTFCY, AsonDate) tradefcy, round(deal_amount_local / deal_other_amount,4),0,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILTRADECROSS,
--        GConst.AMOUNTINR, AsonDate) tradeinr,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate, deal_maturity_date)
--      from trtran001
--      where deal_other_currency != GConst.INDIANRUPEE
--      and deal_hedge_trade = GConst.TRADEDEAL
--      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);


--
       varOperation := 'Inserting records for Hedge which are all not at linked and partially linked Contracts';
    insert into trsystem997
    (posn_company_code, posn_currency_code, posn_account_code,
     posn_reference_number, posn_reference_serial, posn_reference_date,
     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
     posn_counter_party, posn_due_date, posn_maturity_month)
    select deal_company_code CompanyCode, deal_base_currency,
--Updated From Cygnet
--      decode(fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number)), 0,
--        decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADEBUYSPOT,
--            GConst.SALEDEAL, GConst.TRADESALESPOT),
--        decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADEBUYFORWARD,
--            GConst.SALEDEAL, GConst.TRADESALEFORWARD)) AccountCode,
        decode(deal_buy_sell,
            GConst.PURCHASEDEAL, GConst.FORWARDHEDGEBUY,
            Gconst.Saledeal, Gconst.Forwardhedgesale) Accountcode,
 --Upto
      deal_deal_number, 0 , deal_execute_date,
     fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGEDEAL,
        GConst.AMOUNTFCY, AsonDate) tradefcy, deal_exchange_rate,
      --decode(deal_other_currency, GConst.INDIANRUPEE, deal_exchange_rate, deal_local_rate),
        0,
      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGEDEAL,
        GConst.AMOUNTINR, AsonDate) tradeinr,0,
      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
      fncAllotMonth(deal_counter_party, AsonDate,
        pkgReturnCursor.fncRollover(deal_deal_number))
--      from trtran001
--      where ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_execute_date <= AsonDate
--      and deal_hedge_trade = GConst.HEDGEDEAL
--      and fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGEDEAL,
--        GConst.AMOUNTFCY, AsonDate) >0
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
      from trtran001 a
       left outer join trtran006 d on CDEL_DEAL_NUMBER=DEAL_DEAL_NUMBER
     where   DEAL_RECORD_STATUS not in(10200005,10200006 )
      and ((DEAL_PROCESS_COMPLETE = 12400001  and DEAL_COMPLETE_DATE > AsonDate) or DEAL_PROCESS_COMPLETE = 12400002)
       and deal_hedge_trade IN (GConst.HEDGEDEAL, GConst.FTDEAL)
      and fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGEDEAL,
        GConst.AMOUNTFCY, AsonDate) >0
      and deal_record_status in
      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);

   -- union
--  Cross Currency Deals
    insert into trsystem997
    (posn_company_code, posn_currency_code, posn_account_code,
     posn_reference_number, posn_reference_serial, posn_reference_date,
     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
     posn_counter_party, posn_due_date, posn_maturity_month)
    Select Deal_Company_Code, Deal_Other_Currency,
--Updated From cygnet
/*      decode(fncAllotMonth(deal_counter_party, AsonDate,
        pkgReturnCursor.fncRollover(deal_deal_number)), 0,
         decode(deal_buy_sell,
            GConst.PURCHASEDEAL, GConst.TRADESALESPOT,
            GConst.SALEDEAL, GConst.TRADEBUYSPOT),
         decode(deal_buy_sell,
            GConst.PURCHASEDEAL, GConst.TRADESALEFORWARD ,
            GConst.SALEDEAL, GConst.TRADEBUYFORWARD)) AccountCode,*/
          decode(deal_buy_sell,
            Gconst.Purchasedeal, Gconst.Forwardhedgesale ,
            GConst.SALEDEAL, GConst.FORWARDHEDGEBUY) AccountCode,
      deal_deal_number, deal_serial_number, deal_execute_date,
      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGECROSS,
        GConst.AMOUNTFCY, AsonDate) tradefcy,
      round(deal_amount_local / deal_other_amount,4),0,
      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGECROSS,
        GConst.AMOUNTINR, AsonDate) tradeinr,0,
      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
      fncAllotMonth(deal_counter_party, AsonDate,
        pkgReturnCursor.fncRollover(deal_deal_number))
      from trtran001
      where  deal_other_currency != GConst.INDIANRUPEE
      and deal_hedge_trade IN (GConst.HEDGEDEAL, GConst.FTDEAL)
      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
      and deal_execute_date <= AsonDate
      and deal_record_status in
      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);

--    varOperation := 'Inserting records for Hedge Contracts';
--    insert into trsystem997
--    (posn_company_code, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month)
--    select hedg_company_code CompanyCode, deal_base_currency,
--      decode(fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number)), 0,
--        decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADEBUYSPOT,
--            GConst.SALEDEAL, GConst.TRADESALESPOT),
--        decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADEBUYFORWARD,
--            GConst.SALEDEAL, GConst.TRADESALEFORWARD)) AccountCode,
--      deal_deal_number, rownum, deal_execute_date,
--      fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
--        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference) tradefcy,
--      decode(deal_other_currency, GConst.INDIANRUPEE, deal_exchange_rate, deal_local_rate),
--        0, decode(deal_other_currency,30400003,(fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
--        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference)* deal_exchange_rate),
--        (fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
--        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference)* deal_local_rate))
----      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGEDEAL,
----        GConst.AMOUNTINR, AsonDate, hedg_trade_reference) tradeinr
--        ,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number))
--      from trtran001, trtran004
--      where deal_deal_number = hedg_deal_number
--      and deal_serial_number = hedg_deal_serial
--      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_execute_date <= AsonDate
--      and deal_hedge_trade = GConst.HEDGEDEAL
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED)
--      and pkgforexprocess.fncGetOutstanding(deal_deal_number, deal_serial_number,2,1, AsonDate) =0;

   --abhijit commented on 05072012
-- varOperation := 'Inserting records for Hedge Contracts';
--    insert into trsystem997
--    (posn_company_code, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month)
--    select hedg_company_code CompanyCode, deal_base_currency,
--      decode(fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number)), 0,
--        decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADEBUYSPOT,
--            GConst.SALEDEAL, GConst.TRADESALESPOT),
--        decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADEBUYFORWARD,
--            GConst.SALEDEAL, GConst.TRADESALEFORWARD)) AccountCode,
--      deal_deal_number, rownum+100, deal_execute_date,
--      fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
--        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference) tradefcy,
--      decode(deal_other_currency, GConst.INDIANRUPEE, deal_exchange_rate, deal_local_rate),
--        0, decode(deal_other_currency,30400003,(fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
--        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference)* deal_exchange_rate),
--        (fncGetOutstanding(deal_deal_number, deal_serial_number ,GConst.UTILHEDGEDEAL,
--        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference)* deal_local_rate))
----      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGEDEAL,
----        GConst.AMOUNTINR, AsonDate, hedg_trade_reference) tradeinr
--        ,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number))
--      from trtran001, trtran004
--      where deal_deal_number = hedg_deal_number
--      and deal_serial_number = hedg_deal_serial
--      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_execute_date <= AsonDate
--      and deal_hedge_trade = GConst.HEDGEDEAL
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
----    union
----  Cross Currency Deals
--
--  varOperation := 'Inserting Cross Currency Hedge Contracts';
--    insert into trsystem997
--    (posn_company_code, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month)
--    select hedg_company_code, deal_other_currency,
--      decode(fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number)), 0,
--         decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADESALESPOT,
--            GConst.SALEDEAL, GConst.TRADEBUYSPOT),
--         decode(deal_buy_sell,
--            GConst.PURCHASEDEAL, GConst.TRADESALEFORWARD ,
--            GConst.SALEDEAL, GConst.TRADEBUYFORWARD)) AccountCode,
--      deal_deal_number,rownum , deal_execute_date,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGECROSS,
--        GConst.AMOUNTFCY, AsonDate, hedg_trade_reference) tradefcy,
--        deal_exchange_Rate,0,
--      fncGetOutstanding(deal_deal_number, deal_serial_number,GConst.UTILHEDGECROSS,
--        GConst.AMOUNTINR, AsonDate, hedg_trade_reference) tradeinr,0,
--      UserID, deal_user_id, deal_counter_party, deal_maturity_date,
--      fncAllotMonth(deal_counter_party, AsonDate,
--        pkgReturnCursor.fncRollover(deal_deal_number))
--      from trtran001, trtran004
--      where deal_deal_number = hedg_deal_number
--      and deal_serial_number = hedg_deal_serial
--      and deal_other_currency != GConst.INDIANRUPEE
--      and deal_hedge_trade = GConst.HEDGEDEAL
--      and ((deal_complete_date is null) or (deal_complete_date > AsonDate))
--      and deal_execute_date <= AsonDate
--      and deal_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
  --abhijit ends

--    varOperation := 'Inserting records for FCY Loans';
--    insert into trsystem997
--    (posn_company_code, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month)
--    select fcln_company_code, fcln_currency_code,
--      decode(fcln_loan_type, GConst.LOANBUYERSCREDIT, GConst.TRADEBUYERCREDIT,
--      GConst.LOANPCFC, GConst.TRADEPCFC, GConst.LOANPSCFC, GConst.TRADEPSCFC),
--      fcln_loan_number, 0, fcln_sanction_date,
--      fncGetOutstanding(fcln_loan_number, 0,GConst.UTILFCYLOAN,
--        GConst.AMOUNTFCY, AsonDate) fcln_sanctioned_fcy,fcln_conversion_rate,0,
--      fncGetOutstanding(fcln_loan_number, 0,GConst.UTILFCYLOAN,
--        GConst.AMOUNTINR, AsonDate) fcln_sanctioned_inr,0,
--      UserID, null, fcln_local_bank, fcln_maturity_to,
--      fncAllotMonth(AsonDate, fcln_maturity_to)
--      from trtran005
--      where ((fcln_complete_date is null) or (fcln_complete_date > AsonDate))
--      and fcln_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
  --    and fcln_loan_type not in (GConst.LOANBUYERSCREDIT);
 ---kumar.h updates 0n 12/05/09  for buyers credit
--     varOperation := 'Inserting records for Buyers Credit';
--    insert into trsystem997
--    (posn_company_code, posn_currency_code, posn_account_code,
--     posn_reference_number, posn_reference_serial, posn_reference_date,
--     posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--     posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--     posn_counter_party, posn_due_date, posn_maturity_month)
--    select bcrd_company_code, bcrd_currency_code,
--           GConst.TRADEBUYERCREDIT,
--           bcrd_buyers_credit, 0, bcrd_sanction_date,
--      fncGetOutstanding(bcrd_buyers_credit, 0,GConst.UTILBCRLOAN,
--        GConst.AMOUNTFCY, AsonDate) bcrd_sanctioned_fcy,bcrd_conversion_rate,0,
--      fncGetOutstanding(bcrd_buyers_credit, 0,GConst.UTILBCRLOAN,
--        GConst.AMOUNTINR, AsonDate) bcrd_sanctioned_inr,0,
--      UserID, null, bcrd_local_bank, bcrd_due_date,
--      fncAllotMonth(AsonDate, bcrd_due_date)
--      from BuyersCredit
--      where ((bcrd_completion_date is null) or (bcrd_completion_date > AsonDate))
--      and bcrd_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
     ---kumar.h updates 0n 12/05/09  for buyers credit
--------------------------------------------------Money Module Added by Manjunath Reddy  on 09-04-2009----------------------------------
--24900011        Short Term Borrowing
--  varOperation := 'Insert Money Module Date in to Assests ';
--    insert into trsystem997
--     (posn_company_code, posn_currency_code, posn_account_code,
--      posn_reference_number, posn_reference_serial, posn_reference_date,
--      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--      posn_inr_value, posn_usd_value, posn_user_id, posn_dealer_id,
--      posn_counter_party, posn_due_date, posn_maturity_month,posn_product_code)
--     select mdel_company_code, mdel_currency_code,
--      decode( mdel_account_head,24900011,Gconst.MONEYBORROWING,Gconst.TRADEBUYERCREDIT),
--      mdel_deal_number, 0, mdel_execute_date,
--      mdel_deal_amount,mdel_exchange_rate,mdel_exchange_rate,
--      mdel_amount_local,0,UserID, null,
--      mdel_counter_party, mdel_due_date,1,mdel_account_head
--      from trtran031
--      where
--      --((mdel_complete_date is null) or (mdel_complete_date > AsonDate))
--      mdel_process_complete= Gconst.optionNO
--      and mdel_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);


--    varOperation := 'Calculating M2M Rates';
--    update trsystem997
--      set posn_m2m_inrrate =  fncGetRate
--      (posn_currency_code,30400003, AsonDate, 0, posn_maturity_month, posn_due_date),
--      posn_usd_rate = fncGetRate
--      (30400004, 30400003, AsonDate, 0, posn_maturity_month, posn_due_date);
--
--    update trsystem997
--      set posn_revalue_inr =
--        round(posn_transaction_amount * posn_m2m_inrrate,0),
--        posn_revalue_usd =
--        round((posn_transaction_amount * posn_m2m_inrrate) / posn_usd_rate,2),
--        posn_position_inr =
--        decode(sign(25900050 - posn_account_code), 1,
--        round(posn_transaction_amount * posn_m2m_inrrate,0) - posn_inr_value,
--        -1, posn_inr_value - round(posn_transaction_amount * posn_m2m_inrrate,0));
--


----------------------------------------------------Commodity Added by Manjunath Reddy  on 09-04-2009----------------------------------
--varOperation := 'Insert Commodity Module in to Assests ';
---- posn_transaction_amount     No of LOts
---- posn_fcy_rate               Lot Price
---- posn_usd_rate               Lot Size
---- posn_inr_value              Transaction Amount
---- posn_m2m_inrrate            M2M Lot Price
---- posn_revalue_inr            Tansaction Amount For M2m Rate
---- posn_position_inr           Profit and Loss
--
--    insert into trsystem997
--     (posn_company_code, posn_currency_code, posn_account_code,
--      posn_reference_number, posn_reference_serial, posn_reference_date,
--      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--      posn_user_id, posn_dealer_id,
--      posn_counter_party, posn_due_date, posn_maturity_month, posn_product_code,
--      posn_m2m_inrrate)
--     select cmdl_company_code, cmdl_currency_code,
--      decode(cmdl_hedge_trade,gconst.HEDGEDEAL,decode(cmdl_buy_sell,Gconst.PURCHASEDEAL,Gconst.COMMODITYHEDGEBUY,
--             Gconst.SALEDEAL,Gconst.COMMODITYHEDGESALE),gconst.TRADEDEAL,
--            decode(cmdl_buy_sell,Gconst.PURCHASEDEAL,Gconst.COMMODITYTRADEBUY,Gconst.SALEDEAL,Gconst.COMMODITYTRADESALE)),
--      cmdl_deal_number, 0, cmdl_execute_date,
--      fncGetOutstanding(cmdl_deal_number, 0,GConst.UTILCOMMODITYDEAL,
--      GConst.AMOUNTFCY, AsonDate),fncCommDealRate(cmdl_deal_number),(cmdl_product_quantity/cmdl_lot_numbers) ,
--      UserID, null, cmdl_exchange_code, cmdl_maturity_date,1,cmdl_product_code,
--      pkgforexprocess.fncCommodityMTMRate(cmdl_maturity_date,cmdl_exchange_code,cmdl_product_code,AsonDate)
--      from trtran051
--      where ((cmdl_complete_date is null) or (cmdl_complete_date > AsonDate))
--      and cmdl_process_complete= Gconst.optionNO
--      and cmdl_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--    begin
--      VarOperation :='Calling Tf';
--    --  numError  := trfinance.fncReturnTlGap(AsonDate);
--    Exception
--      when others then
--        NULL;
--    end;
--    fetch curTermLoan bulk collect into recPosition;
--
--    Loop
----      Fetch curTermLoan bulinto recPosition;
--      Exit when curTermLoan%NOTFOUND;
--
--     insert into trsystem997
--       (posn_company_code, posn_currency_code, posn_account_code,
--        posn_reference_number, posn_reference_serial, posn_reference_date,
--        posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--        posn_user_id, posn_dealer_id,
--        posn_counter_party, posn_due_date, posn_maturity_month, posn_product_code,
--        posn_m2m_inrrate)
--    values
--       (recPosition.posn_company_code, recPosition.posn_currency_code,
--        recPosition.posn_account_code, recPosition.posn_reference_number,
--        recPosition.posn_reference_serial, recPosition.posn_reference_date,
--        recPosition.posn_transaction_amount, recPosition.posn_fcy_rate,
--        recPosition.posn_usd_rate, recPosition.posn_user_id,
--        recPosition.posn_dealer_id, recPosition.posn_counter_party,
--        recPosition.posn_due_date, recPosition.posn_maturity_month,
--        recPosition.posn_product_code,recPosition.posn_m2m_inrrate);
--    End Loop;
--    loop
--    end loop;
--


----------------------------------------------------Currency Futures Added by Manjunath Reddy  on 10-06-2011----------------------------------
--varOperation := 'Insert Currency Future Module in to Assests ';
--
--    insert into trsystem997
--     (posn_company_code, posn_currency_code, posn_account_code,
--      posn_reference_number, posn_reference_serial, posn_reference_date,
--      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
--      posn_user_id, posn_dealer_id,
--      posn_counter_party, posn_due_date, posn_maturity_month, posn_product_code,
--      posn_m2m_inrrate)
--     select cfut_company_code, cfut_base_currency,
--      decode(cfut_hedge_trade,gconst.HEDGEDEAL,decode(cfut_buy_sell,Gconst.PURCHASEDEAL,Gconst.CFHEDGEBUY,
--             Gconst.SALEDEAL,Gconst.CFHEDGESALE),gconst.TRADEDEAL,
--            decode(cfut_buy_sell,Gconst.PURCHASEDEAL,Gconst.CFTRADEBUY,Gconst.SALEDEAL,Gconst.CFTRADESALE)),
--      cfut_deal_number, 0, cfut_execute_date,
--      cfut_base_amount,fncFutureDealRate(cfut_deal_number),(cfut_lot_quantity/cfut_lot_numbers) ,
--      UserID, null, cfut_exchange_code, cfut_maturity_date,1,decode(cfut_hedge_trade,gconst.HEDGEDEAL,decode(cfut_buy_sell,Gconst.PURCHASEDEAL,Gconst.CFHEDGEBUY,
--             Gconst.SALEDEAL,Gconst.CFHEDGESALE),gconst.TRADEDEAL,
--            decode(cfut_buy_sell,Gconst.PURCHASEDEAL,Gconst.CFTRADEBUY,Gconst.SALEDEAL,Gconst.CFTRADESALE)),
--      pkgforexprocess.fncCommodityMTMRate(cfut_maturity_date,cfut_exchange_code,cfut_product_code,AsonDate)
--      from trtran061
--      where ((cfut_complete_date is null) or (cfut_complete_date > AsonDate))
--      and cfut_process_complete= Gconst.optionNO
--      and cfut_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--    begin
--      VarOperation :='Calling Tf';
--    --  numError  := trfinance.fncReturnTlGap(AsonDate);
--    Exception
--      when others then
--        NULL;
--    end;

----------------------------------------------------Currency Options Added by Manjunath Reddy  on 18-06-2011----------------------------------
varOperation := 'Insert Currency Options Module in to Assests ';

    insert into trsystem997
     (posn_company_code, posn_currency_code, posn_account_code,
      posn_reference_number, posn_reference_serial, posn_reference_date,
      posn_transaction_amount, posn_fcy_rate, posn_usd_rate,
      posn_user_id, posn_dealer_id,
      posn_counter_party, posn_due_date, posn_maturity_month, posn_product_code,posn_m2m_inrrate)
     select copt_company_code, copt_base_currency,
      decode(copt_hedge_trade,gconst.HEDGEDEAL,decode(cosu_option_type,Gconst.OptionCall,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLHEDGEBUY,
             Gconst.SALEDEAL,Gconst.COCALLHEDGESALE),Gconst.OptionPut,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTHEDGEBUY,
             Gconst.SALEDEAL,Gconst.COPUTHEDGESALE)),gconst.TRADEDEAL,
             decode(cosu_option_type,Gconst.OptionCall,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLTRADEBUY,
             Gconst.SALEDEAL,Gconst.COCALLTRADESALE),Gconst.OptionPut,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTTRADEBUY,
             Gconst.SALEDEAL,Gconst.COPUTTRADESALE))),
      copt_deal_number, cosu_serial_number, copt_execute_date,
      decode(COPT_DEAL_TYPE,32300002,copt_base_amount*2,32300005,copt_base_amount*2,copt_base_amount),cosu_strike_rate,0,
      --(copt_lot_quantity/copt_lot_numbers),

      --fncFutureDealRate(cfut_deal_number),(cfut_lot_quantity/cfut_lot_numbers) ,
      UserID, null, copt_counter_party, copt_maturity_date,1,      decode(copt_hedge_trade,gconst.HEDGEDEAL,decode(cosu_option_type,Gconst.OptionCall,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLHEDGEBUY,
             Gconst.SALEDEAL,Gconst.COCALLHEDGESALE),Gconst.OptionPut,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTHEDGEBUY,
             Gconst.SALEDEAL,Gconst.COPUTHEDGESALE)),gconst.TRADEDEAL,
             decode(cosu_option_type,Gconst.OptionCall,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COCALLTRADEBUY,
             Gconst.SALEDEAL,Gconst.COCALLTRADESALE),Gconst.OptionPut,decode(cosu_buy_sell,Gconst.PURCHASEDEAL,Gconst.COPUTTRADEBUY,
             Gconst.SALEDEAL,Gconst.COPUTTRADESALE))),0
             --,
             --,
     -- pkgforexprocess.fncCommodityMTMRate(cfut_maturity_date,cfut_exchange_code,cfut_product_code,AsonDate)
      --copt_strike_rate
--      from trtran071 right outer join trtran072
--      on copt_deal_number=cosu_deal_number
--     where ((copt_complete_date is null) or (copt_complete_date > AsonDate))
--      and copt_record_status in
--      (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
    from trtran071 right outer join trtran072
      on copt_deal_number=cosu_deal_number
      left outer join  trtran073
       ON corv_deal_number = copt_deal_number
          and corv_record_status not in(10200005,10200006)
        WHERE  ((copt_PROCESS_COMPLETE = 12400001  and copt_COMPLETE_DATE > AsonDate) or copt_PROCESS_COMPLETE = 12400002)
          and (COPT_EXECUTE_DATE <= AsonDate)
          and copt_record_status not in(10200005,10200006)
          and pkgForexProcess.fncGetOutstanding(COPT_DEAL_NUMBER,1,15,1, AsonDate) > 0
          order by copt_maturity_date;


--    varOperation := 'Calculate Total Tansaction amount  Transaction amount';
--
--    update trsystem997
--      set posn_inr_value=posn_transaction_amount * posn_fcy_rate * posn_usd_rate,
--      posn_revalue_inr= posn_transaction_amount * posn_usd_rate * posn_m2m_inrrate
--      where posn_product_code is not null;

  --  varOperation := 'Calculate Profit  According to M2m Rate';

--    update trsystem997
--      set posn_position_inr=decode(sign(25900050 - posn_account_code), 1,
--      posn_inr_value-posn_revalue_inr,-1, posn_revalue_inr-posn_inr_value)
--      where posn_product_code is not null;
--
--    update trsystem997
--      set posn_position_usd = round(posn_position_inr / posn_usd_rate,2),
--      posn_product_code= posn_account_code
--      where posn_product_code is  null;

    commit;
    return numError;
Exception

  when others then
      varError := SQLERRM;
      varerror := 'PositionGen: ' || varmessage || varoperation || varerror;
      raise_application_error(-20101,   varerror);
      Rollback;

      return -1;
End fncRbiReport;


function fncCommodityMTMRate(
             DealMaturityDate in date,
             Exchangecode in number,
             ProductCode in number,
             asondate in date)
             RETURN number
   is
   nummtmrate     number(15,6);
   maxdate        date;

 begin

   select max(cm2m_effective_date ) into maxdate
    from  trtran054
    where cm2m_commodity_code=ProductCode
      and cm2m_exchange_code=ExchangeCode
      and cm2m_expiry_month=DealMaturityDate
      and cm2m_effective_date <= asondate;


   select cm2m_closing_rate into nummtmrate
   from trtran054
   where cm2m_commodity_code=ProductCode
   and  cm2m_exchange_code=ExchangeCode
   and  cm2m_expiry_month=DealMaturityDate
   and  cm2m_serial_number = (select max(cm2m_serial_number)
                              from trtran054
                               where cm2m_commodity_code=ProductCode
                                 and  cm2m_exchange_code=ExchangeCode
                                 and  cm2m_expiry_month=DealMaturityDate
                                 and cm2m_effective_date=maxdate)
    and cm2m_effective_date=maxdate ;

 return nummtmrate;
 exception
    when No_data_found then
      nummtmrate:=0.00;
   return nummtmrate;
 end fncCommodityMTMRate;


--function fncMarginAmount
--         (MarginRate in number,
--          UnitPrice  in number,
--          NofLots    in number,
--          MtmPrice   in number :=0,
--          Excess     in number :=0)
--    return number
-- is
--
-- begin
-- if excess=0 then
--     return((marginrate*UnitPrice*NofLots));
-- else
--     return((marginrate*(UnitPrice-MtmPrice)*NofLots));
-- end if;
--
-- exception
--  when OTHERS then
--  return(0);
--end fncMarginAmount;
function fncCommMarginAmount
         (Dealnumber in varchar2,
          AsOnDate in date,
          MarginType in number)
    return number
is
 numdealAmount number(15,2);
 numMargin     number(15,6);
 numrecord     number(5);
begin

   if MarginType = Gconst.YesterdayMargin then
    begin
       select cmtr_margin_amount
              into numMargin
         from trtran052
        where cmtr_deal_number = dealnumber
          and cmtr_mtm_date= (select max(cmtr_mtm_date)
                                from trtran052
                               where cmtr_deal_number=DealNumber) ;
       return numMargin;
     exception
       when no_data_found then
         numMargin := 0;
     end;
    end if;
   numdealAmount := fncGetOutstanding(dealnumber, 0,GConst.UTILCOMMODITYDEAL,
                                    GConst.AMOUNTINR, AsonDate);

   select cmdl_margin_rate
     into numMargin
     from trtran051
     where cmdl_deal_number= dealnumber;

     return numMargin* numdealAmount;

end fncCommMarginAmount;


function fncGetCommPandL
          (Dealnumber in varchar2,
           ProfitType in number)
  return number
  is
  MtmProfitLoss  number(15,2):=0;
  RevProfitLoss  number (15,2):=0;
  TotProfitLoss  number(15,2):=0;
BEGIN
   Begin
      select nvl(sum(cmtr_profit_loss),0)
             into MtmProfitLoss
        from trtran052
       where cmtr_deal_number= dealnumber
    group by cmtr_deal_number;
     TotProfitLoss:=MtmProfitLoss;
  exception
     when no_data_found then
      TotProfitLoss:=0;
 end;
 if ProfitType= gconst.TOTALPANDL then
      select nvl(sum(crev_profit_loss),0) into RevProfitLoss
        from trtran053
       where crev_reverse_deal=Dealnumber;
 end if;
     TotProfitLoss:=TotProfitLoss+RevProfitLoss;
return TotProfitLoss;
Exception
 when no_data_found then
   TotProfitLoss:=0;
   return TotProfitLoss;
end fncGetCommPandL;

--function fncComDealAmount
--         (DealNumber in varchar2,
--          numOption  in number)
--          return number
-- --numoption =1 return dealvalue
-- --numoption =2 return  mtmrate
-- is
--   numReturnValue   number(15,2);
--   numMtmRate       number(15,2);
--   numDealValue     number(15,2);
--   numRowCount      number(4);
--begin
-- --for checking whether dealnumber is present in mtmtable(trtran052)
--   select count(*) into numRowCount
--     from trtran052
--    where cmtr_mtm_date = (select max(cmtr_mtm_date)
--                              from trtran052
--                             where cmtr_deal_number=DealNumber)
--      and cmtr_deal_number=DealNumber;
-- if numRowCount !=0 then
--   select cmtr_mtm_amount,cmtr_mtm_rate
--          into numDealValue,numMtmRate
--     from trtran052
--     where cmtr_mtm_date = (select max(cmtr_mtm_date)
--                              from trtran052
--                             where cmtr_deal_number=DealNumber)
--      and cmtr_deal_number=DealNumber;
-- else
-- ---if not present in the mtmtable then get the values from the deal table(trtran051)
--   select  cmdl_deal_amount ,cmdl_lot_price
--           into numDealValue,numMtmRate
--      from trtran051
--     where cmdl_deal_number=DealNumber;
-- end if;
-- --for selecting the return value;
-- if numoption =1 then
--   numReturnValue:=numDealValue;
-- else
--   numReturnValue:=numMtmRate;
-- end if;
-- return numReturnValue;
--Exception
--  when others then
--   return 0.00;
--End fncComDealAmount;
--
function fncCommDealRate
         (DealNumber in varchar2,
          asondate in date default null )
          return number
is
   numMtmRate       number(15,6);
 begin
  begin
     select cmtr_mtm_rate
       into numMtmRate
      from trtran052
      where cmtr_mtm_date = (select  max(cmtr_mtm_date)
                               from  trtran052
                               where cmtr_deal_number=DealNumber)
       and cmtr_deal_number=DealNumber;
  exception
    when no_data_found then
--     select  cmdl_lot_price
--        into numMtmRate
--        from trtran051
--        where cmdl_deal_number=DealNumber;
---    modified by kumar.h on 27-apr-09
     select AVG(cmdl_lot_price)  into numMtmRate
       from trtran051
      where cmdl_product_code=(select  cmdl_product_code from trtran051 where cmdl_deal_number = DealNumber)
        and cmdl_maturity_date=(select cmdl_maturity_date from trtran051 where cmdl_deal_number = DealNumber )
        and cmdl_exchange_code=(select cmdl_exchange_code from trtran051 where cmdl_deal_number = DealNumber)
        and cmdl_deal_number not in (select cmtr_deal_number from trtran052);

  end;
  return numMtmRate;
Exception
  when others then
   return 0.00;
End fncCommDealRate;

------------Currency Futures


--function fncFutureMTMRate(
--             DealMaturityDate in date,
--             Exchangecode in number,
--             BaseCurrency in number,
--             OtherCurrency in number,
--             asondate in date)
--             RETURN number
--   is
--   nummtmrate     number(15,6);
--   maxdate        date;
--
-- begin
--
--   select max(cfmm_effective_date ) into maxdate
--    from  trtran064
--    where cfmm_base_currency=BaseCurrency
--      and cfmm_other_currency=OtherCurrency
--      and cfmm_exchange_code=decode(ExchangeCode,70199999,70100001,ExchangeCode) -- Mapping all the unknow Exchange Deals to NSE MTM Rate
--      and cfmm_expiry_month=DealMaturityDate
--      and cfmm_effective_date <= asondate;
--
--
--   select cfmm_closing_rate into nummtmrate
--   from trtran064
--   where cfmm_base_currency=BaseCurrency
--   and cfmm_other_currency=OtherCurrency
--   and  cfmm_exchange_code=decode(ExchangeCode,70199999,70100001,ExchangeCode) -- Mapping all the unknow Exchange Deals to NSE MTM Rate
--   and  cfmm_expiry_month=DealMaturityDate
--   and  cfmm_serial_number = (select max(cfmm_serial_number)
--                              from trtran064
--                               where cfmm_base_currency=BaseCurrency
--                                 and cfmm_other_currency=OtherCurrency
--                                 and  cfmm_exchange_code=decode(ExchangeCode,70199999,70100001,ExchangeCode) -- Mapping all the unknow Exchange Deals to NSE MTM Rate
--                                 and  cfmm_expiry_month=DealMaturityDate
--                                 and cfmm_effective_date=maxdate)
--    and cfmm_effective_date=maxdate ;
--
-- return nummtmrate;
-- exception
--    when No_data_found then
--      nummtmrate:=0.00;
--   return nummtmrate;
-- end fncFutureMTMRate;
function fncFutureMTMRate(
             DealMaturityDate in date,
             Exchangecode in number,
             BaseCurrency in number,
             OtherCurrency in number,
             asondate in date)
             RETURN number
   is
   nummtmrate     number(15,6);
   maxdate        date;
   numTempExchange number(8);
   numCount       number(8) := 0;

 begin
--Added by Ishwarachandra for checking NSE rate if other exchange rate not uploaded
    select count(*)  into numCount
    from  trtran064
    where cfmm_base_currency=BaseCurrency
      and cfmm_other_currency=OtherCurrency
      and cfmm_exchange_code=Exchangecode -- Mapping all the unknow Exchange Deals to NSE MTM Rate
      and cfmm_expiry_month=DealMaturityDate
      and cfmm_effective_date = asondate;
      
      if numCount = 0 then
        numTempExchange := 70100001;
      else
        numTempExchange := Exchangecode;
      end if;
--Commented by ishwarachandra  
--   select max(cfmm_effective_date ) into maxdate
--    from  trtran064
--    where cfmm_base_currency=BaseCurrency
--      and cfmm_other_currency=OtherCurrency
--      and cfmm_exchange_code=decode(ExchangeCode,70199999,70100001,ExchangeCode) -- Mapping all the unknow Exchange Deals to NSE MTM Rate
--      and cfmm_expiry_month=DealMaturityDate
--      and cfmm_effective_date <= asondate;


   select cfmm_closing_rate into nummtmrate
   from trtran064
   where cfmm_base_currency=BaseCurrency
   and cfmm_other_currency=OtherCurrency
   and  cfmm_exchange_code=numTempExchange--decode(ExchangeCode,70199999,70100001,ExchangeCode) -- Mapping all the unknow Exchange Deals to NSE MTM Rate
   and  cfmm_expiry_month=DealMaturityDate
   and  cfmm_serial_number = (select max(cfmm_serial_number)
                              from trtran064
                               where cfmm_base_currency=BaseCurrency
                                 and cfmm_other_currency=OtherCurrency
                                 and  cfmm_exchange_code= numTempExchange --decode(ExchangeCode,70199999,70100001,ExchangeCode) -- Mapping all the unknow Exchange Deals to NSE MTM Rate
                                 and  cfmm_expiry_month=DealMaturityDate
                                 and cfmm_effective_date=asondate)
    and cfmm_effective_date=asondate ;

 return nummtmrate;
 exception
    when No_data_found then
      nummtmrate:=0.00;
   return nummtmrate;
 end fncFutureMTMRate;


function fncFutureMarginAmount
         (Dealnumber in varchar2,
          AsOnDate in date,
          MarginType in number)
    return number
is
 numdealAmount number(15,2);
 numMargin     number(15,6);
 numrecord     number(5);
begin

   if MarginType = Gconst.YesterdayMargin then
    begin
       select cfmr_margin_amount
              into numMargin
         from trtran062
        where cfmr_deal_number = dealnumber
          and cfmr_mtm_date= (select max(cfmr_mtm_date)
                                from trtran062
                               where cfmr_deal_number=DealNumber) ;
       return numMargin;
     exception
       when no_data_found then
         numMargin := 0;
     end;
    end if;
   numdealAmount := fncGetOutstanding(dealnumber, 0,GConst.UTILFUTUREDEAL,
                                    GConst.AMOUNTINR, AsonDate);

   select cfut_margin_rate
     into numMargin
     from trtran061
     where cfut_deal_number= dealnumber;

     return numMargin* numdealAmount;

end fncFutureMarginAmount;


function fncGetFuturePandL
          (Dealnumber in varchar2,
           ProfitType in number)
  return number
  is
  MtmProfitLoss  number(15,2):=0;
  RevProfitLoss  number (15,2):=0;
  TotProfitLoss  number(15,2):=0;
BEGIN
   Begin
      select nvl(sum(cfmr_profit_loss),0)
             into MtmProfitLoss
        from trtran062
       where cfmr_deal_number= dealnumber
    group by cfmr_deal_number;
     TotProfitLoss:=MtmProfitLoss;
  exception
     when no_data_found then
      TotProfitLoss:=0;
 end;
 if ProfitType= gconst.TOTALPANDL then
      select nvl(sum(cfrv_profit_loss),0) into RevProfitLoss
        from trtran063
       where cfrv_reverse_deal=Dealnumber;
 end if;
     TotProfitLoss:=TotProfitLoss+RevProfitLoss;
return TotProfitLoss;
Exception
 when no_data_found then
   TotProfitLoss:=0;
   return TotProfitLoss;
end fncGetFuturePandL;

function fncFutureDealRate
         (DealNumber in varchar2,
          asondate in date default null )
          return number
is
   numMtmRate       number(15,6);
 begin
  begin
     select cfmr_mtm_rate
       into numMtmRate
      from trtran062
      where cfmr_mtm_date = (select  max(cfmr_mtm_date)
                               from  trtran062
                               where cfmr_deal_number=DealNumber)
       and cfmr_deal_number=DealNumber;
  exception
    when no_data_found then
--     select  cmdl_lot_price
--        into numMtmRate
--        from trtran051
--        where cmdl_deal_number=DealNumber;
---    modified by kumar.h on 27-apr-09
     select AVG(cfut_exchange_rate)  into numMtmRate
       from trtran061
      where cfut_product_code=(select  cfut_product_code from trtran061 where cfut_deal_number = DealNumber)
        and cfut_maturity_date=(select cfut_maturity_date from trtran061 where cfut_deal_number = DealNumber )
        and cfut_exchange_code=(select cfut_exchange_code from trtran061 where cfut_deal_number = DealNumber)
        and cfut_deal_number not in (select cfmr_deal_number from trtran062);

  end;
  return numMtmRate;
Exception
  when others then
   return 0.00;
End fncFutureDealRate;

           --commented by aakash 17-may-13 11:13 am
--Function  Fncgetprofitlossoptnetpandl(
--     Dealnumber in varchar2,Serialno in number
--     )return number
--is
--    numTotalproftloss  number(15,2);
--    numEPremimumStatus number(8);
--    numEPremiumlocal number(15,2);
--    numCPremimumStatus number(8);
--    Numcpremiumlocal Number(15,2);
--    numOptionEXorCA number(8,0);
--    numProfitLoss number(8);
--begin
--    select COPT_PREMIUM_STATUS,
--    DECODE(COPT_OTHER_CURRENCY,30400003, copt_premium_AMOUNT,COPT_PREMIUM_LOCAL)
--      into numEPremimumStatus,numEPremiumlocal
--      from trtran071
--      where copt_deal_number=Dealnumber
--       and COPT_RECORD_STATUS not in(10200005,10200006);
--
--    select corv_exercise_type,corv_premium_status,
--    corv_premium_local,
--    corv_profit_loss
--      into numOptionEXorCA,numCPremimumStatus,numCPremiumlocal,numProfitLoss
--     from trtran073
--     where corv_deal_number =Dealnumber
--     and CORV_SERIAL_NUMBER = Serialno
--      and CORV_RECORD_STATUS not in(10200005,10200006);
--
--    if numOptionEXorCA =Gconst.Exercise then
--        select numProfitLoss+decode(numEPremimumStatus,Gconst.Received,numEPremiumlocal,Gconst.PremiumPaid,-1*numEPremiumlocal)
--         into numTotalproftloss
--         From Dual;
--    elsif  numOptionEXorCA =Gconst.CancelDeal then
--        select decode(numCPremimumStatus,Gconst.Received,numCPremiumlocal,Gconst.PremiumPaid,-1*numCPremiumlocal) +decode(numEPremimumStatus,Gconst.Received,numEPremiumlocal,Gconst.PremiumPaid,-1*numEPremiumlocal)
--          into numTotalproftloss
--         from dual;
-- --   else if  numOptionEXorCA =Gconst.CancelDeal then
--    end if;
--     return numTotalproftloss;
--
--end fncgetprofitlossOptNetPandL ;

          --added by gouri/aakash 17-may-13 11:14 am


--Function  Fncgetprofitlossoptnetpandl(
--     Dealnumber in varchar2,Serialno in number
--     )return number
--is
--    numTotalproftloss  number(15,2);
--    numEPremimumStatus number(8);
--    numEBaseAmount number(15,2);
--    NumcBaseAmount Number(15,2);
--    numEPremiumlocal number(15,2);
--    Numcpremiumlocal Number(15,2);
--    numCPremimumStatus number(8);
--    Numoptionexorca Number(8,0);
--    numProfitLoss number(15,2);
--begin
--    select copt_base_amount, COPT_PREMIUM_STATUS,
--    DECODE(COPT_OTHER_CURRENCY,30400003, copt_premium_AMOUNT,COPT_PREMIUM_LOCAL)
--      into numEBaseAmount, numEPremimumStatus,numEPremiumlocal
--      from trtran071
--      where copt_deal_number=Dealnumber
--       and COPT_RECORD_STATUS not in(10200005,10200006);
--
--    select corv_base_amount, corv_exercise_type,corv_premium_status,
--    corv_premium_local,corv_profit_loss
--      into NumcBaseAmount, numOptionEXorCA,numCPremimumStatus,numCPremiumlocal,numProfitLoss
--     from trtran073
--     where corv_deal_number =Dealnumber
--     and CORV_SERIAL_NUMBER = Serialno
--      and CORV_RECORD_STATUS not in(10200005,10200006);
--
--    if numCBaseAmount < numEBaseAmount then
--      numEPremiumLocal := (numEPremiumLocal / numEBaseAmount) * numCBaseAmount;
--    End if;
--
--    if numOptionEXorCA =Gconst.Exercise then
--        select numProfitLoss+decode(numEPremimumStatus,Gconst.Received,numEPremiumlocal,Gconst.PremiumPaid,-1*numEPremiumlocal)
--         into numTotalproftloss
--         From Dual;
--    elsif  numOptionEXorCA =Gconst.CancelDeal then
--        select decode(numCPremimumStatus,Gconst.Received,numCPremiumlocal,Gconst.PremiumPaid,-1*numCPremiumlocal) +decode(numEPremimumStatus,Gconst.Received,numEPremiumlocal,Gconst.PremiumPaid,-1*numEPremiumlocal)
--          into numTotalproftloss
--         from dual;
-- --   else if  numOptionEXorCA =Gconst.CancelDeal then
--    end if;
--     return numTotalproftloss;
--
--end fncgetprofitlossOptNetPandL ;

---modified by Gouri/Aakash 04072013

--Function  Fncgetprofitlossoptnetpandl(
--     Dealnumber in varchar2,Serialno in number
--     )return number
--is
--    numTotalproftloss  number(15,2);
--    numEPremimumStatus number(8);
--    numEBaseAmount number(15,2);
--    NumcBaseAmount Number(15,2);
--    numEPremiumlocal number(15,2);
--    Numcpremiumlocal Number(15,2);
--    numCPremimumStatus number(8);
--    Numoptionexorca Number(8,0);
--    numProfitLoss number(15,2);
--  begin
--    select copt_base_amount, COPT_PREMIUM_STATUS,
--    DECODE(COPT_OTHER_CURRENCY,30400003, copt_premium_AMOUNT,COPT_PREMIUM_LOCAL)
--      into numEBaseAmount, numEPremimumStatus,numEPremiumlocal
--      from trtran071
--      where copt_deal_number=Dealnumber
--       and COPT_RECORD_STATUS not in(10200005,10200006);
--   begin
--    select corv_base_amount, corv_exercise_type,corv_premium_status,
--    corv_premium_amount,corv_profit_loss
--      into NumcBaseAmount, numOptionEXorCA,numCPremimumStatus,numCPremiumlocal,numProfitLoss
--     from trtran073
--     where corv_deal_number =Dealnumber
--     and CORV_SERIAL_NUMBER = Serialno
--      and CORV_RECORD_STATUS not in(10200005,10200006);
--   exception
--     when no_data_found then
--      numOptionEXorCA:=0;
--   end;
--
--     if numCBaseAmount < numEBaseAmount then
--      numEPremiumLocal := (numEPremiumLocal / numEBaseAmount) * numCBaseAmount;
--    End if;
--    if numOptionEXorCA =Gconst.Exercise then
--        select numProfitLoss+decode(numEPremimumStatus,Gconst.Received,numEPremiumlocal,Gconst.PremiumPaid,-1*numEPremiumlocal)
--         into numTotalproftloss
--         From Dual;
--    elsif  numOptionEXorCA =Gconst.CancelDeal then
--        select decode(numCPremimumStatus,Gconst.Received,numCPremiumlocal,Gconst.PremiumPaid,-1*numCPremiumlocal) +decode(numEPremimumStatus,Gconst.Received,numEPremiumlocal,Gconst.PremiumPaid,-1*numEPremiumlocal)
--          into numTotalproftloss
--         from dual;
-- --   else if  numOptionEXorCA =Gconst.CancelDeal then
--    else
--       select decode(numEPremimumStatus,Gconst.Received,numEPremiumlocal,Gconst.PremiumPaid,-1*numEPremiumlocal)
--         into numTotalproftloss
--         From Dual;
--    end if;
--     return numTotalproftloss;
--
--end fncgetprofitlossOptNetPandL ;

--Function  Fncgetprofitlossoptnetpandl(
--     Dealnumber in varchar2,Serialno in number
--     )return number
--is
--    numTotalproftloss  number(15,2);
--    numEPremimumStatus number(8);
--    numEBaseAmount number(15,2);
--    NumcBaseAmount Number(15,2);
--    numEPremiumlocal number(15,2);
--    Numcpremiumlocal Number(15,2);
--    numCPremimumStatus number(8);
--    Numoptionexorca Number(8,0);
--    numProfitLoss number(15,2);
--  begin
--    select copt_base_amount, COPT_PREMIUM_STATUS,
--    ABS(DECODE(COPT_OTHER_CURRENCY,30400003, copt_premium_AMOUNT,COPT_PREMIUM_LOCAL))
--      into numEBaseAmount, numEPremimumStatus,numEPremiumlocal
--      from trtran071
--      where copt_deal_number=Dealnumber
--       and COPT_RECORD_STATUS not in(10200005,10200006);
--   begin
--    select corv_base_amount, corv_exercise_type,corv_premium_status,
--    ABS(corv_premium_amount),corv_profit_loss
--      into NumcBaseAmount, numOptionEXorCA,numCPremimumStatus,numCPremiumlocal,numProfitLoss
--     from trtran073
--     where corv_deal_number =Dealnumber
--     and CORV_SERIAL_NUMBER = Serialno
--      and CORV_RECORD_STATUS not in(10200005,10200006);
--   exception
--     when no_data_found then
--      numOptionEXorCA:=0;
--   end;
--
--     if numCBaseAmount < numEBaseAmount then
--      numEPremiumLocal := (numEPremiumLocal / numEBaseAmount) * numCBaseAmount;
--    End if;
--    if numOptionEXorCA =Gconst.Exercise then
--        select numProfitLoss+decode(numEPremimumStatus,Gconst.Received,numEPremiumlocal,Gconst.PremiumPaid,-1*numEPremiumlocal)
--         into numTotalproftloss
--         From Dual;
--    elsif  numOptionEXorCA =Gconst.CancelDeal then
--        select decode(numCPremimumStatus,Gconst.Received,numCPremiumlocal,Gconst.PremiumPaid,-1*numCPremiumlocal) +decode(numEPremimumStatus,Gconst.Received,numEPremiumlocal,Gconst.PremiumPaid,-1*numEPremiumlocal)
--          into numTotalproftloss
--         from dual;
-- --   else if  numOptionEXorCA =Gconst.CancelDeal then
--    else
--       select decode(numEPremimumStatus,Gconst.Received,numEPremiumlocal,Gconst.PremiumPaid,-1*numEPremiumlocal)
--         into numTotalproftloss
--         From Dual;
--    end if;
--     return numTotalproftloss;
--
--end fncgetprofitlossOptNetPandL ;

--end
Function  Fncgetprofitlossoptnetpandl(
     Dealnumber in varchar2,Serialno in number
     )return number
is
    numTotalproftloss  number(15,2);
    numEPremimumStatus number(8);
    numEBaseAmount number(15,2);
    NumcBaseAmount Number(15,2);
    numEPremiumlocal number(15,2);
    Numcpremiumlocal Number(15,2);
    numCPremimumStatus number(8);
    Numoptionexorca Number(8,0);
    numProfitLoss number(15,2);
  begin
    select copt_base_amount, COPT_PREMIUM_STATUS,
    ABS(DECODE(COPT_OTHER_CURRENCY,30400003, copt_premium_AMOUNT,COPT_PREMIUM_LOCAL))
      into numEBaseAmount, numEPremimumStatus,numEPremiumlocal
      from trtran071
      where copt_deal_number=Dealnumber
       and COPT_RECORD_STATUS not in(10200005,10200006);
   begin
    select corv_base_amount, corv_exercise_type,corv_premium_status,
    ABS(corv_premium_amount),corv_profit_loss
      into NumcBaseAmount, numOptionEXorCA,numCPremimumStatus,numCPremiumlocal,numProfitLoss
     from trtran073
     where corv_deal_number =Dealnumber
     and CORV_SERIAL_NUMBER = Serialno
      and CORV_RECORD_STATUS not in(10200005,10200006);
   exception
     when no_data_found then
      numOptionEXorCA:=0;
   end;

     if numCBaseAmount < numEBaseAmount then
      numEPremiumLocal := (numEPremiumLocal / numEBaseAmount) * numCBaseAmount;
    End if;
    if numOptionEXorCA =Gconst.Exercise then
        select numProfitLoss+decode(numEPremimumStatus,Gconst.Received,numEPremiumlocal,Gconst.PremiumPaid,-1*numEPremiumlocal)
         into numTotalproftloss
         From Dual;
    elsif  numOptionEXorCA =Gconst.CancelDeal then
        select decode(numCPremimumStatus,Gconst.Received,numCPremiumlocal,Gconst.PremiumPaid,-1*numCPremiumlocal) +decode(numEPremimumStatus,Gconst.Received,numEPremiumlocal,Gconst.PremiumPaid,-1*numEPremiumlocal)
          into numTotalproftloss
         from dual;
 --   else if  numOptionEXorCA =Gconst.CancelDeal then
    else
       select decode(numEPremimumStatus,Gconst.Received,numEPremiumlocal,Gconst.PremiumPaid,-1*numEPremiumlocal)
         into numTotalproftloss
         From Dual;
    end if;
     return numTotalproftloss;

end fncgetprofitlossOptNetPandL ;

Function  Fncgetprofitlossoptnetpandl(
     Dealnumber in varchar2,Serialno in number,
     AsonDate date
     )return number
is
    numTotalproftloss  number(15,2);
    numEPremimumStatus number(8);
    numEBaseAmount number(15,2);
    NumcBaseAmount Number(15,2);
    numEPremiumlocal number(15,2);
    Numcpremiumlocal Number(15,2);
    numCPremimumStatus number(8);
    Numoptionexorca Number(8,0);
    numProfitLoss number(15,2);
  begin
    
    select copt_base_amount, COPT_PREMIUM_STATUS,
    CASE WHEN NVL(COPT_PREMIUM_DOLLERAMOUNT,0) != 0 THEN
     ROUND(ABS(COPT_PREMIUM_DOLLERAMOUNT) * fncgetPandLRate(COPT_DEAL_NUMBER,1,AsonDate,2),2)
    ELSE
    ABS(DECODE(COPT_OTHER_CURRENCY,30400003, copt_premium_AMOUNT,COPT_PREMIUM_LOCAL)) END
      into numEBaseAmount, numEPremimumStatus,numEPremiumlocal
      from trtran071
      where copt_deal_number=Dealnumber
       and COPT_RECORD_STATUS not in(10200005,10200006);
   begin
    select corv_base_amount, corv_exercise_type,corv_premium_status,
    ABS(corv_premium_amount),corv_profit_loss
      into NumcBaseAmount, numOptionEXorCA,numCPremimumStatus,numCPremiumlocal,numProfitLoss
     from trtran073
     where corv_deal_number =Dealnumber
     and CORV_REVERSE_SERIAL = Serialno
      and CORV_RECORD_STATUS not in(10200005,10200006);
   exception
     when no_data_found then
      numOptionEXorCA:=0;
   end;

     if numCBaseAmount < numEBaseAmount then
      numEPremiumLocal := (numEPremiumLocal / numEBaseAmount) * numCBaseAmount;
    End if;
    if numOptionEXorCA =Gconst.Exercise then
        select numProfitLoss+decode(numEPremimumStatus,Gconst.Received,numEPremiumlocal,Gconst.PremiumPaid,-1*numEPremiumlocal)
         into numTotalproftloss
         From Dual;
    elsif  numOptionEXorCA =Gconst.CancelDeal then
        select decode(numCPremimumStatus,Gconst.Received,numCPremiumlocal,Gconst.PremiumPaid,-1*numCPremiumlocal) +decode(numEPremimumStatus,Gconst.Received,numEPremiumlocal,Gconst.PremiumPaid,-1*numEPremiumlocal)
          into numTotalproftloss
         from dual;
 --   else if  numOptionEXorCA =Gconst.CancelDeal then
    else
       select decode(numEPremimumStatus,Gconst.Received,numEPremiumlocal,Gconst.PremiumPaid,-1*numEPremiumlocal)
         into numTotalproftloss
         From Dual;
    end if;
     return numTotalproftloss;

end fncgetprofitlossOptNetPandL ;
function fncUserDetails
  (varUserIDs in varchar)
  return varchar
is
   intLength number(3);
   vartemp varchar(1000);
   varUserList varchar(1000);
   varTemp1 varchar(1000);
   vartemp2 varchar(1000);
   varEmail varchar(1000);
   varPhone varchar(1000);
begin
  intlength:= length(varUserIDs);
  varUserList:=varUserIDs;
  varEmail:='';
  varPhone:='';
  while (intlength!=0)
   loop
    if (instr(varUserList,',')!=0) then
      vartemp :=substr(varUserList,0,instr(varUserList,',')-1);
      select user_email_id,user_mobile_phone
        into varTemp1,varTemp2
        from trsystem022
        where user_user_id =vartemp;
      varEmail:=varEmail || ',' || varTemp1;
      varPhone:=varPhone || ',' || varTemp2;
      varUserList:= replace(varUserList,vartemp||',' ,'');
      intlength:=length(varUserList);
    end if;
  end loop;
  return substr(varEmail,2);
end fncUserDetails;

function  fncgetprofitloss(
     baseamount in  number,
     m2mrate     in number,
     exchangerate in number,
     buysell in number
     )return number is

     numproloss  number;
begin
     select  decode(buysell, 25300001,(m2mrate*baseamount)-(baseamount *exchangerate), (baseamount *exchangerate )-(m2mrate*baseamount)) into numproloss
     from dual ;

     return numproloss;

end fncgetprofitloss ;

--function fncGetprofitLossOptions
--  (varReference in varchar,
--   refRate in number,
--   numBaseAMount in number,
--   datEffectDate in date,
--   numSerial in out nocopy number,
--   numPLFCY in out nocopy number,
--   numPLLocal in out nocopy number,
--   varRemarks in out nocopy varchar)
--   return number
-- is
--   numDealType number(8);
--   numLeg1 number(8);
--   numLeg2 number(8);
--  -- numBaseAmount number(8);
--
--   numOptionType number(8);
--   numBuySell number(8);
--   numStrikeRate number(15,6);
--   numSerial2  number(8);
--   numOptionType2 number(8);
--   numBuySell2 number(8);
--   numStrikeRate2 number(15,6);
--   numSerial3  number(8);
--   numOptionType3 number(8);
--   numBuySell3 number(8);
--   numStrikeRate3 number(15,6);
--   numSerial4  number(8);
--   numOptionType4 number(8);
--   numBuySell4 number(8);
--   numStrikeRate4 number(15,6);
--
--   numTemp number(15,6);
--
-- begin
--
--    select copt_deal_type
--    --copt_base_amount
--      into numdealtype
--      --,numBaseAmount
--      from trtran071
--     where copt_deal_number= varReference
--       and copt_record_status not in (Gconst.StatusinActive,Gconst.STATUSDELETED);
--
--    if ((numDealType = Gconst.PlainVenela) or (numDealType = Gconst.Straddle)) then
--       for C1 in ( select cosu_serial_number,cosu_option_type OptionType,cosu_buy_sell buysell,
--                          cosu_strike_rate StrikeRate
--                     from trtran072
--                     where cosu_deal_number=varReference
--                     and cosu_record_status not in(10200005,10200006))
--        loop
--           if C1.buysell= Gconst.PURCHASEDEAL then
--                if c1.OptionType =Gconst.OptionCall then
--                     if refrate > C1.strikeRate then
--                        numPLFCY:= (refrate-C1.StrikeRate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                        return numPLFCY;
--                     elsif refrate < C1.strikeRate then
--                        numPLFCY:= (refRate-C1.StrikeRate)*numBaseAmount;
--                        varRemarks:='No Exercise';
--                     end if;
--                elsif C1.OptionType =Gconst.OptionPut then
--                     if refrate < C1.strikeRate then
--                        numPLFCY:= (C1.StrikeRate-refrate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                        return numPLFCY;
--                     elsif refrate > C1.StrikeRate then
--                        numPLFCY:= (C1.StrikeRate-refrate)*numBaseAmount;
--                        varRemarks:='No Exercise';
--                     end if;
--                end if;
--             elsif C1.buysell= Gconst.SALEDEAL then
--                if C1.OptionType =Gconst.OptionCall then
--                     if refrate > C1.strikeRate then
--                        numPLFCY:= (refrate-C1.StrikeRate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                        return numPLFCY;
--                     elsif refrate < C1.strikeRate then
--                        numPLFCY:= (refrate-C1.StrikeRate)*numBaseAmount;
--                        varRemarks:='No Exercise';
--                     end if;
--                elsif C1.OptionType =Gconst.OptionPut then
--                     if C1.strikeRate > refrate then
--                        numPLFCY:= (C1.StrikeRate-refrate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                        return numPLFCY;
--                     elsif refrate < C1.strikeRate then
--                        numPLFCY:= (C1.StrikeRate-refrate)*numBaseAmount;
--                        varRemarks:='No Exercise';
--                     end if;
--                end if;
--             end if;
--
--        end loop;
--    elsif numDealType = Gconst.Seagull then
--
--              varRemarks:='Enter into Seagull';
--              numtemp:=0;
--              numPLFCY:=0;
--       for C1 in ( select cosu_serial_number,cosu_option_type OptionType,cosu_buy_sell buysell,
--                          cosu_strike_rate StrikeRate
--                     from trtran072
--                     where cosu_deal_number=varReference
--                     and cosu_record_status not in(10200005,10200006))
--        loop
--           if ((c1.OptionType=Gconst.OptionCall) and (c1.BuySell=Gconst.PURCHASEDEAL)) then
--              select decode(sign((refRate-c1.StrikeRate)*numBaseAmount),-1,0,((refRate-c1.StrikeRate)*numBaseAmount))
--                into numtemp
--                from dual;
--               -- varRemarks:= varRemarks || 'Enter into Seagull 1' || to_char(numtemp) ;
--           end if;
--
--
--           if ((c1.OptionType=Gconst.OptionPut) and (c1.BuySell=Gconst.PURCHASEDEAL)) then
--               select decode(sign((c1.StrikeRate-refRate)*numBaseAmount),-1,0,((c1.StrikeRate-refRate)*numBaseAmount))
--                 into numtemp
--                 from dual;
--                -- varRemarks:= varRemarks || 'Enter into Seagull 2' || to_char(numtemp) ;
--           end if;
--
--           if ((c1.OptionType=Gconst.OptionCall) and (c1.BuySell=Gconst.SALEDEAL)) then
--              select -1 * decode(sign((refRate-c1.StrikeRate)*numBaseAmount),-1,0,((refRate-c1.StrikeRate)*numBaseAmount))
--                into numtemp
--                from  dual;
--               --  varRemarks:= varRemarks || 'Enter into Seagull 3' || to_char(numtemp) ;
--           end if;
--
--           if ((c1.OptionType=Gconst.OptionPut) and (c1.BuySell=Gconst.SALEDEAL)) then
--              select -1 * decode(sign((c1.StrikeRate-refRate)*numBaseAmount),-1,0,((c1.StrikeRate-refRate)*numBaseAmount))
--               into numtemp
--               from dual;
--                 --varRemarks:= varRemarks || 'Enter into Seagull 4' || to_char(numtemp) ;
--           end if;
--
--           numPLFCY:= numTemp+numPLFCY;
--
--           if numPLFCY >0 then
--             varRemarks:='Option Exercise';
--           else
--              varRemarks:='No Exercise';
--           end if;
--        end loop;
--
--    elsif numDealType = Gconst.Stragles then
--    --Checking first Leg
--       begin
--        select cosu_serial_number,cosu_option_type,cosu_buy_sell,
--                cosu_strike_rate
--          into numserial,numoptionType,numbuysell,numStrikeRate
--          from trtran072
--         where cosu_deal_number=varReference
--           and cosu_option_type =Gconst.OptionCall;
--          -- and cosu_strike_rate>refRate;
--          if numbuysell= Gconst.PURCHASEDEAL then
--             if numstrikeRate< refrate then
--                numPLFCY:= (refrate-numStrikeRate)*numBaseAmount;
--                varRemarks:='Option Exercise';
--                goto Result_return;
--             else
--                  varRemarks:='NO Exercise';
--             end if;
--          elsif numbuysell= Gconst.SALEDEAL then
--             if numstrikeRate< refrate then
--                numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
--                varRemarks:='Option Exercise';
--                goto Result_return;
--             else
--                  varRemarks:='No Exercise';
--             end if;
--          end if;
--
--       exception
--       when others then
--            numserial:=0;--,numoptionType,numbuysell,numStrikeRate
--       end;
--     -- --Checking first Second Leg
--       begin
--        select cosu_serial_number,cosu_option_type,cosu_buy_sell,
--               cosu_strike_rate
--          into numserial,numoptionType,numbuysell,numStrikeRate
--          from trtran072
--         where cosu_deal_number=varReference
--           and cosu_option_type =Gconst.OptionPut;
--          -- and cosu_strike_rate<refRate;
--          if numbuysell= Gconst.PURCHASEDEAL then
--             if refrate> numstrikeRate  then
--                numPLFCY:= (refrate-numStrikeRate)*numBaseAmount;
--                varRemarks:='Option Exercise';
--                goto Result_return;
--             else
--                  varRemarks:='No Exercise';
--             end if;
--          elsif numbuysell= Gconst.SALEDEAL then
--             if numstrikeRate< refrate then
--                numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
--                varRemarks:='Option Exercise';
--                goto Result_return;
--             else
--                  varRemarks:='NO Exercise';
--             end if;
--          end if;
--       exception
--       when others then
--            numserial:=0;--,numoptionType,numbuysell,numStrikeRate
--       end;
--
--    end if;
--  <<Result_return>>
--      if varRemarks='No Exercise' then
--         numPLFCY:=0;
--      end if;
--      numPLLocal:= numPLFCY * refRate;
--   return numPLFCY;
-- end;
-----Old function--
--function fncGetprofitLossOptions
--  (varReference in varchar,
--   refRate in number,
--   numBaseAMount in number,
--   datEffectDate in date,
--   numSerial in out nocopy number,
--   numPLFCY in out nocopy number,
--   numPLLocal in out nocopy number,
--   varRemarks in out nocopy varchar,
--    ReverseSerial in number default 1)
--   return number
-- is
--   numDealType number(8);
--   numLeg1 number(8);
--   numLeg2 number(8);
--  -- numBaseAmount number(8);
--
--   numOptionType number(8);
--   numBuySell number(8);
--   numStrikeRate number(15,6);
--   numSerial2  number(8);
--   numOptionType2 number(8);
--   numBuySell2 number(8);
--   numStrikeRate2 number(15,6);
--   numSerial3  number(8);
--   numOptionType3 number(8);
--   numBuySell3 number(8);
--   numStrikeRate3 number(15,6);
--   numSerial4  number(8);
--   numOptionType4 number(8);
--   numBuySell4 number(8);
--   numStrikeRate4 number(15,6);
--
--   numTemp number(15,6);
--
-- begin
--
--    select copt_deal_type
--    --copt_base_amount
--      into numdealtype
--      --,numBaseAmount
--      from trtran071
--     where copt_deal_number= varReference
--       and copt_record_status not in (Gconst.StatusinActive,Gconst.STATUSDELETED);
-- if (numDealType = Gconst.PlainVenela) then
--    select cosu_option_type ,cosu_buy_sell ,cosu_strike_rate
--         into numOptionType,numBuySell, numStrikeRate
--           from trtran072
--           where cosu_deal_number=varReference
--           and cosu_serial_number=ReverseSerial
--           and cosu_record_status not in(10200005,10200006);
--           
--             if numBuySell= Gconst.PURCHASEDEAL then
--                if numOptionType =Gconst.OptionCall then
--                     if refrate > numStrikeRate then
--                        numPLFCY:= (refrate-numStrikeRate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                        return numPLFCY;
--                     elsif refrate < numStrikeRate then
--                        numPLFCY:= (refRate-numStrikeRate)*numBaseAmount;
--                        varRemarks:='No Exercise';
--                     end if;
--                elsif numOptionType =Gconst.OptionPut then
--                     if refrate < numStrikeRate then
--                        numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                        return numPLFCY;
--                     elsif refrate > numStrikeRate then
--                        numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
--                        varRemarks:='No Exercise';
--                     end if;
--                end if;
--             elsif numBuySell= Gconst.SALEDEAL then
--                if numOptionType =Gconst.OptionCall then
--                     if refrate > numStrikeRate then
--                        numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                        return numPLFCY;
--                     elsif refrate < numStrikeRate then
--                        numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
--                        varRemarks:='No Exercise';
--                     end if;
--                elsif numOptionType =Gconst.OptionPut then
--                     if numStrikeRate > refrate then
--                        numPLFCY:= (refrate-numStrikeRate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                        return numPLFCY;
--                     elsif numStrikeRate < refrate then
--                        numPLFCY:= (refrate-numStrikeRate )*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                     end if;
--                end if;
--             end if;
--
--  end if;
--    if ((numDealType = Gconst.PlainVenela) or (numDealType = Gconst.Straddle)) then
--       for C1 in ( select cosu_serial_number,cosu_option_type OptionType,cosu_buy_sell buysell,
--                          cosu_strike_rate StrikeRate
--                     from trtran072
--                     where cosu_deal_number=varReference
--                     and cosu_record_status not in(10200005,10200006))
--        loop
--           if C1.buysell= Gconst.PURCHASEDEAL then
--                if numOptionType =Gconst.OptionCall then
--                     if refrate > numStrikeRate then
--                        numPLFCY:= (refrate-numStrikeRate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                        return numPLFCY;
--                     elsif refrate < numStrikeRate then
--                        numPLFCY:=(refRate-numStrikeRate)*numBaseAmount;
--                        varRemarks:='No Exercise';
--                     end if;
--                elsif numOptionType =Gconst.OptionPut then
--                     if refrate < numStrikeRate then
--                        numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                        return numPLFCY;
--                     elsif refrate > numStrikeRate then
--                        numPLFCY:=(numStrikeRate-refrate)*numBaseAmount;
--                        varRemarks:='No Exercise';
--                     end if;
--               end if;
--             elsif C1.buysell= Gconst.SALEDEAL then
--                if numOptionType =Gconst.OptionCall then
--                     if refrate > numStrikeRate then
--                        numPLFCY:= (refrate-numStrikeRate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                        return numPLFCY;
--                     elsif refrate < numStrikeRate then
--                        numPLFCY:= (refRate-numStrikeRate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                     end if;
--                elsif numOptionType =Gconst.OptionPut then
--                     if refrate < numStrikeRate then
--                        numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                        return numPLFCY;
--                     elsif refrate > numStrikeRate then
--                        numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                     end if;
--               end if;
--             end if;
--
--        end loop;
--    elsif numDealType = Gconst.Seagull then
--
--              varRemarks:='Enter into Seagull';
--              numtemp:=0;
--              numPLFCY:=0;
--       for C1 in ( select cosu_serial_number,cosu_option_type OptionType,cosu_buy_sell buysell,
--                          cosu_strike_rate StrikeRate
--                     from trtran072
--                     where cosu_deal_number=varReference
--                     and cosu_record_status not in(10200005,10200006))
--        loop
--           if ((c1.OptionType=Gconst.OptionCall) and (c1.BuySell=Gconst.PURCHASEDEAL)) then
--              select decode(sign((refRate-c1.StrikeRate)*numBaseAmount),-1,0,((refRate-c1.StrikeRate)*numBaseAmount))
--                into numtemp
--                from dual;
--               -- varRemarks:= varRemarks || 'Enter into Seagull 1' || to_char(numtemp) ;
--           end if;
--
--
--           if ((c1.OptionType=Gconst.OptionPut) and (c1.BuySell=Gconst.PURCHASEDEAL)) then
--               select decode(sign((c1.StrikeRate-refRate)*numBaseAmount),-1,0,((c1.StrikeRate-refRate)*numBaseAmount))
--                 into numtemp
--                 from dual;
--                -- varRemarks:= varRemarks || 'Enter into Seagull 2' || to_char(numtemp) ;
--           end if;
--
--           if ((c1.OptionType=Gconst.OptionCall) and (c1.BuySell=Gconst.SALEDEAL)) then
--              select -1 * decode(sign((refRate-c1.StrikeRate)*numBaseAmount),-1,0,((refRate-c1.StrikeRate)*numBaseAmount))
--                into numtemp
--                from  dual;
--               --  varRemarks:= varRemarks || 'Enter into Seagull 3' || to_char(numtemp) ;
--           end if;
--
--           if ((c1.OptionType=Gconst.OptionPut) and (c1.BuySell=Gconst.SALEDEAL)) then
--              select -1 * decode(sign((c1.StrikeRate-refRate)*numBaseAmount),-1,0,((c1.StrikeRate-refRate)*numBaseAmount))
--               into numtemp
--               from dual;
--                 --varRemarks:= varRemarks || 'Enter into Seagull 4' || to_char(numtemp) ;
--           end if;
--
--           numPLFCY:= numTemp+numPLFCY;
--
--           if numPLFCY >0 then
--             varRemarks:='Option Exercise';
--           else
--              varRemarks:='No Exercise';
--           end if;
--        end loop;
--
--    elsif numDealType = Gconst.Stragles then
--    --Checking first Leg
--       begin
--        select cosu_serial_number,cosu_option_type,cosu_buy_sell,
--                cosu_strike_rate
--          into numserial,numoptionType,numbuysell,numStrikeRate
--          from trtran072
--         where cosu_deal_number=varReference
--           and cosu_option_type =Gconst.OptionCall;
--          -- and cosu_strike_rate>refRate;
--          if numbuysell= Gconst.PURCHASEDEAL then
--             if numstrikeRate< refrate then
--                numPLFCY:= (refrate-numStrikeRate)*numBaseAmount;
--                varRemarks:='Option Exercise';
--                goto Result_return;
--             else
--                  varRemarks:='NO Exercise';
--             end if;
--          elsif numbuysell= Gconst.SALEDEAL then
--             if numstrikeRate< refrate then
--                numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
--                varRemarks:='Option Exercise';
--                goto Result_return;
--             else
--                  varRemarks:='No Exercise';
--             end if;
--          end if;
--
--       exception
--       when others then
--            numserial:=0;--,numoptionType,numbuysell,numStrikeRate
--       end;
--     -- --Checking first Second Leg
--       begin
--        select cosu_serial_number,cosu_option_type,cosu_buy_sell,
--               cosu_strike_rate
--          into numserial,numoptionType,numbuysell,numStrikeRate
--          from trtran072
--         where cosu_deal_number=varReference
--           and cosu_option_type =Gconst.OptionPut;
--          -- and cosu_strike_rate<refRate;
--          if numbuysell= Gconst.PURCHASEDEAL then
--             if refrate> numstrikeRate  then
--                numPLFCY:= (refrate-numStrikeRate)*numBaseAmount;
--                varRemarks:='Option Exercise';
--                goto Result_return;
--             else
--                  varRemarks:='No Exercise';
--             end if;
--          elsif numbuysell= Gconst.SALEDEAL then
--             if numstrikeRate< refrate then
--                numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
--                varRemarks:='Option Exercise';
--                goto Result_return;
--             else
--                  varRemarks:='NO Exercise';
--             end if;
--          end if;
--       exception
--       when others then
--            numserial:=0;--,numoptionType,numbuysell,numStrikeRate
--       end;
--
--    end if;
--  <<Result_return>>
--      if varRemarks='No Exercise' then
--         numPLFCY:=0;
--      end if;
--      numPLLocal:= numPLFCY * refRate;
--   return numPLFCY;
-- end;
--------Updated from olam------
function fncGetprofitLossOptions
  (varReference in varchar,
   refRate in number,
   numBaseAMount in number,
   datEffectDate in date,
   numSerial in out nocopy number,
   numPLFCY in out nocopy number,
   numPLLocal in out nocopy number,
   varRemarks in out nocopy varchar,
    ReverseSerial in number default 1)
   return number
 is
   numDealType number(8);
   numLeg1 number(8);
   numLeg2 number(8);
  -- numBaseAmount number(8);

   numOptionType number(8);
   numBuySell number(8);
   numStrikeRate number(15,6);
   numSerial2  number(8);
   numOptionType2 number(8);
   numBuySell2 number(8);
   numStrikeRate2 number(15,6);
   numSerial3  number(8);
   numOptionType3 number(8);
   numBuySell3 number(8);
   numStrikeRate3 number(15,6);
   numSerial4  number(8);
   numOptionType4 number(8);
   numBuySell4 number(8);
   numStrikeRate4 number(15,6);

   numTemp number(15,6);

 begin

    select copt_deal_type
    --copt_base_amount
      into numdealtype
      --,numBaseAmount
      from trtran071
     where copt_deal_number= varReference
       and copt_record_status not in (Gconst.StatusinActive,Gconst.STATUSDELETED);

    select cosu_option_type ,cosu_buy_sell ,cosu_strike_rate
         into numOptionType,numBuySell, numStrikeRate
           from trtran072
           where cosu_deal_number=varReference
           and cosu_serial_number=ReverseSerial
           and cosu_record_status not in(10200005,10200006);
           
--             if numBuySell= Gconst.PURCHASEDEAL then
--                if numOptionType =Gconst.OptionCall then
--                     if refrate > numStrikeRate then
--                        numPLFCY:= (refrate-numStrikeRate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                        return numPLFCY;
--                     elsif refrate < numStrikeRate then
--                        numPLFCY:= (refRate-numStrikeRate)*numBaseAmount;
--                        varRemarks:='No Exercise';
--                     end if;
--                elsif numOptionType =Gconst.OptionPut then
--                     if refrate < numStrikeRate then
--                        numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                        return numPLFCY;
--                     elsif refrate > numStrikeRate then
--                        numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
--                        varRemarks:='No Exercise';
--                     end if;
--                end if;
--             elsif numBuySell= Gconst.SALEDEAL then
--                if numOptionType =Gconst.OptionCall then
--                     if refrate > numStrikeRate then
--                        numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                        return numPLFCY;
--                     elsif refrate < numStrikeRate then
--                        numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
--                        varRemarks:='No Exercise';
--                     end if;
--                elsif numOptionType =Gconst.OptionPut then
--                     if numStrikeRate > refrate then
--                        numPLFCY:= (refrate-numStrikeRate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                        return numPLFCY;
--                     elsif numStrikeRate < refrate then
--                        numPLFCY:= (refrate-numStrikeRate )*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                     end if;
--                end if;
--             end if;


    if ((numDealType = Gconst.PlainVenela) or (numDealType = Gconst.Straddle)) then
       for C1 in ( select cosu_serial_number,cosu_option_type OptionType,cosu_buy_sell buysell,
                          cosu_strike_rate StrikeRate
                     from trtran072
                     where cosu_deal_number=varReference
                     and cosu_record_status not in(10200005,10200006))
        loop
           if C1.buysell= Gconst.PURCHASEDEAL then
                if numOptionType =Gconst.OptionCall then
                     if refrate > numStrikeRate then
                        numPLFCY:= (refrate-numStrikeRate)*numBaseAmount;
                        varRemarks:='Option Exercise';
                        return numPLFCY;
                     elsif refrate < numStrikeRate then
                        numPLFCY:=(refRate-numStrikeRate)*numBaseAmount;
                        varRemarks:='No Exercise';
                     end if;
                elsif numOptionType =Gconst.OptionPut then
                     if refrate < numStrikeRate then
                        numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
                        varRemarks:='Option Exercise';
                        return numPLFCY;
                     elsif refrate > numStrikeRate then
                        numPLFCY:=(numStrikeRate-refrate)*numBaseAmount;
                        varRemarks:='No Exercise';
                     end if;
               end if;
             elsif C1.buysell= Gconst.SALEDEAL then
                if numOptionType =Gconst.OptionCall then
                     if refrate > numStrikeRate then
                        numPLFCY:= (refrate-numStrikeRate)*numBaseAmount;
                        varRemarks:='Option Exercise';
                        return numPLFCY;
                     elsif refrate < numStrikeRate then
                        numPLFCY:= (refRate-numStrikeRate)*numBaseAmount;
                        varRemarks:='Option Exercise';
                     end if;
                elsif numOptionType =Gconst.OptionPut then
                     if refrate < numStrikeRate then
                        numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
                        varRemarks:='Option Exercise';
                        return numPLFCY;
                     elsif refrate > numStrikeRate then
                        numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
                        varRemarks:='Option Exercise';
                     end if;
               end if;
             end if;

        end loop;
    elsif numDealType = Gconst.Seagull then

              varRemarks:='Enter into Seagull';
              numtemp:=0;
              numPLFCY:=0;
       for C1 in ( select cosu_serial_number,cosu_option_type OptionType,cosu_buy_sell buysell,
                          cosu_strike_rate StrikeRate
                     from trtran072
                     where cosu_deal_number=varReference
                     and cosu_record_status not in(10200005,10200006))
        loop
           if ((c1.OptionType=Gconst.OptionCall) and (c1.BuySell=Gconst.PURCHASEDEAL)) then
              select decode(sign((refRate-c1.StrikeRate)*numBaseAmount),-1,0,((refRate-c1.StrikeRate)*numBaseAmount))
                into numtemp
                from dual;
               -- varRemarks:= varRemarks || 'Enter into Seagull 1' || to_char(numtemp) ;
           end if;


           if ((c1.OptionType=Gconst.OptionPut) and (c1.BuySell=Gconst.PURCHASEDEAL)) then
               select decode(sign((c1.StrikeRate-refRate)*numBaseAmount),-1,0,((c1.StrikeRate-refRate)*numBaseAmount))
                 into numtemp
                 from dual;
                -- varRemarks:= varRemarks || 'Enter into Seagull 2' || to_char(numtemp) ;
           end if;

           if ((c1.OptionType=Gconst.OptionCall) and (c1.BuySell=Gconst.SALEDEAL)) then
              select -1 * decode(sign((refRate-c1.StrikeRate)*numBaseAmount),-1,0,((refRate-c1.StrikeRate)*numBaseAmount))
                into numtemp
                from  dual;
               --  varRemarks:= varRemarks || 'Enter into Seagull 3' || to_char(numtemp) ;
           end if;

           if ((c1.OptionType=Gconst.OptionPut) and (c1.BuySell=Gconst.SALEDEAL)) then
              select -1 * decode(sign((c1.StrikeRate-refRate)*numBaseAmount),-1,0,((c1.StrikeRate-refRate)*numBaseAmount))
               into numtemp
               from dual;
                 --varRemarks:= varRemarks || 'Enter into Seagull 4' || to_char(numtemp) ;
           end if;

           numPLFCY:= numTemp+numPLFCY;

           if numPLFCY >0 then
             varRemarks:='Option Exercise';
           else
              varRemarks:='No Exercise';
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
             if refrate> numstrikeRate  then
                numPLFCY:= (refrate-numStrikeRate)*numBaseAmount;
                varRemarks:='Option Exercise';
                goto Result_return;
             else
                  varRemarks:='No Exercise';
             end if;
          elsif numbuysell= Gconst.SALEDEAL then
             if numstrikeRate< refrate then
                numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
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
 end;
    --pkgforexprocess

 -----------------------------------------
--pkgforexprocess body


Function fncGetSpotDueDate
    ( CounterParty in number,
      AsonDate in Date,
      SubDays in number := 0)
      return Date
      is
--  Created on 28/05/08
    numError      number;
    numFlag       number(1);
    datReturn     date;
    datTemp       date;
    varOperation  gconst.gvaroperation%type;
    varMessage    gconst.gvarmessage%type;
    varError      gconst.gvarerror%type;
Begin
    varMessage := 'Returning Spot Due Date for ' || AsonDate;
    datReturn := null;

    if SubDays = 0 then
      datTemp := AsonDate - 2;
    else
      datTemp := AsonDate - SubDays;
    end if;

     select decode(trim(to_char(datTemp , 'DAY')),
        'SATURDAY', datTemp - 2,
        'SUNDAY', datTemp - 3)
        into datTemp
        from dual;


    numFlag := 0;

    varOperation := 'Extracting Holidays for the counter Party';
    for curHoliday in
    (select distinct hday_calendar_date
      from trsystem001
      where hday_location_code in
      (select nvl(lbnk_bank_location, 0)
        from trmaster306
        where lbnk_pick_code = Counterparty
        and hday_day_status in
        (GConst.DAYHOLIDAY, GConst.DAYWEEKLYOFF1, GConst.DAYWEEKLYOFF2)
       union
       select nvl(lbnk_corr_location,0)
        from trmaster306
        where lbnk_pick_code = CounterParty
        and hday_day_status in
        (GConst.DAYHOLIDAY, GConst.DAYWEEKLYOFF1, GConst.DAYWEEKLYOFF2))
      and hday_calendar_date <= datTemp
      order by hday_calendar_date desc)
    Loop
      numFlag := 1;

      if  curHoliday.hday_calendar_date < datTemp then
        datReturn := datTemp;
        exit;
      else
        datTemp := datTemp - 1;
      end if;

    End Loop;

    if numFlag = 0 then -- No Holiday records after the date
      select decode(trim(to_char(AsonDate - 2, 'DAY')),
        'SATURDAY', AsonDate - 3,
        'SUNDAY', AsonDate - 4,
        AsonDate - 2)
        into datReturn
        from dual;
    End if;

    return datReturn;
Exception
    when others then
      varerror := 'SpotDueDate: ' || varmessage || varoperation || varerror;
      raise_application_error(-20101,   varerror);
      return datReturn;
End fncGetSpotDueDate;

--updated gouri/aakash 11-july-13 03:46 pm
--  Function fncGetOptionMTM
--  ( DealNumber in varchar2,
--    AsonDate in Date)
--    return number
--
--  is
----  Created on 01/07/2013 by TMM
--    numError            number;
--    numProcess          number(8);
--    numCounterParty     number(8);
--    numBuySale          number(8);
--    numMTMValue         number(15,2);
--    numProfitLoss       number(15,2);
--    numBaseAmount       number(15,2);
--    numBalance          number(15,2);
--    numReturn           number(15,2);
--    numStrikeRate       number(15,6);
--    numMTMRate          number(15,6);
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    datComplete         date;
--  Begin
--    numError := 0;
--    numMTMValue := 0;
--    numProfitLoss := 0;
--    numReturn := 0;
--
--    varMessage := 'Calculating MTM for Option ' || DealNumber;
--
--    varOperation := 'Getting Details for the ';
--    SELECT COPT_BASE_AMOUNT,
--    --FNCGETOUTSTANDING(DEALNUMBER, 1, GConst.UTILOPTIONHEDGEDEAL, GConst.AMOUNTFCY, AsonDate),
--     FNCGETOUTSTANDING(DEALNUMBER, 1, 15, 1, AsonDate),
--      copt_counter_party, copt_process_complete, copt_complete_date
--      into numBaseAmount, numBalance,
--      numCounterParty, numProcess, datComplete
--      from trtran071
--      where copt_deal_number = DealNumber;
--
--       VAROPERATION := 'Getting net pandl';
--
--    if  datComplete is not null and datComplete <= AsonDate then -- Deal is closed as on date
--      numReturn := Fncgetprofitlossoptnetpandl(DealNumber, 1);
--      Goto Process_End;
--    End if;
---- The following statement takes care of Premia Paid / Received
---- and P L of Partilly cancelled deals
-- varOperation := 'Getting opt pandl';
--    NUMPROFITLOSS := FNCGETPROFITLOSSOPTNETPANDL(DEALNUMBER, 1);
--     varOperation := 'Getting Details for the Otc Deals ';
---- The Following Statment to calculate MTM even if it is partially cancelled
--  -- if numCounterParty between 30600001 and 30699999 then     -- MTM if it an OTC Deal
--      select NVL(cfmr_profit_loss,0)
--        INTO NUMMTMVALUE
--        FROM TRTRAN062
--        where cfmr_deal_number = DealNumber
--        and cfmr_mtm_date =
--        (select max(cfmr_mtm_date)
--          from trtran062
--          where cfmr_deal_number = DealNumber
--          AND CFMR_MTM_DATE <= ASONDATE);
--      if numBalance < numBaseAmount then -- Partially Cancelled OTC
--        numReturn := numProfitLoss + numMTMValue;
--      else -- Completely open
---- MTM takes care of premium already paid / received hence only MTM is taken
--        NUMRETURN := NUMMTMVALUE;
--  --    END IF;
--
----    ELSE
----          varOperation := 'Getting Details for Exchange Deal';
----    -- MTM if Exchange Deal
----      SELECT FNCGETPROFITLOSS(NUMBALANCE, cfmm_closing_rate, cosu_strike_rate,cosu_buy_sell)
----        into numMTMValue
----        from trtran071, trtran072, trtran064
----        WHERE COPT_DEAL_NUMBER = COSU_DEAL_NUMBER
----        AND COPT_EXCHANGE_CODE = CFMM_EXCHANGE_CODE
----        and copt_deal_number=DealNumber
----        AND COPT_BASE_CURRENCY= CFMM_BASE_CURRENCY
----        and copt_other_currency= cfmm_other_currency
----        and cfmm_effective_date =
----        (select max(cfmm_effective_date)
----          FROM TRTRAN064
----          where cfmm_exchange_code = copt_exchange_code
----          AND CFMM_INSTRUMENT_TYPE = 32200003)
----         AND cfmm_serial_number =
----        (select max(cfmm_serial_number)
----          FROM TRTRAN064
----          WHERE CFMM_EXCHANGE_CODE = COPT_EXCHANGE_CODE
----          AND CFMM_INSTRUMENT_TYPE = 32200003)
----          order by 1;
--    --  numMTMValue := fncgetprofitloss(numBalance, numMTMRate, numStrikeRate,numBuySale);
---- For Exchange deals the old Premium should be taken into consideration
--      --numReturn := nvl(numProfitLoss,0) + nvl(numMTMValue,0);
--      numReturn:=nvl(numMTMValue,0);
--    End if;
--
--<<Process_End>>
--
--    return numReturn;
--Exception
--    When others then
--      numError := SQLCODE;
--      varError := SQLERRM;
--      varError := GConst.fncReturnError('OptandL', numError, varMessage,
--                      varOperation, varError);
--      raise_application_error(-20101, varError);
--      return numError;
--
--  END fncGetOptionMTM;
-----------------------UPDATED 22-JULY-13 05:35PM
-----------------------commented on 02-AUG-13 07:48 pm
--Function fncGetOptionMTM
--  ( DEALNUMBER IN VARCHAR2,
--    AsonDate in Date,checkData in char default 'Y')
--    return number
--
--  is
----  Created on 01/07/2013 by TMM
--    numError            number;
--    numProcess          number(8);
--    numCounterParty     number(8);
--    numBuySale          number(8);
--    numMTMValue         number(15,2);
--    numProfitLoss       number(15,2);
--    numBaseAmount       number(15,2);
--    numPewmium          number(15,2);
--    numPremiumTot       number(15,2);
--    numBalance          number(15,2);
--    numReturn           number(15,2);
--    numStrikeRate       number(15,6);
--    numMTMRate          number(15,6);
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    DATCOMPLETE         DATE;
--
--  Begin
--    numError := 0;
--    numMTMValue := 0;
--    numProfitLoss := 0;
--    numReturn := 0;
--
--    varMessage := 'Calculating MTM for Option ' || DealNumber;
--
--    varOperation := 'Getting Details for the ';
--    SELECT COPT_BASE_AMOUNT,
--        FNCGETOUTSTANDING(DEALNUMBER, 1, 15, 1, AsonDate),
--      copt_counter_party, copt_process_complete, copt_complete_date,
--      decode(copt_premium_status,Gconst.Received,1,Gconst.PremiumPaid,-1)*copt_premium_amount
--      into numBaseAmount, numBalance,
--      numCounterParty, numProcess, datComplete,numPewmium
--      from trtran071
--      where copt_deal_number = DealNumber;
--
--      -- Calculate the premium for the balance amount
--      select (numPewmium/numbaseamount)* numBalance
--       into numPremiumTot
--       from dual;
--
--       VAROPERATION := 'Getting net pandl';
--
--    if  datComplete is not null and datComplete <= AsonDate then -- Deal is closed as on date
--      numReturn := Fncgetprofitlossoptnetpandl(DealNumber, 1);
--      Goto Process_End;
--    End if;
---- The following statement takes care of Premia Paid / Received
---- and P L of Partilly cancelled deals
-- varOperation := 'Getting opt pandl';
--    NUMPROFITLOSS := FNCGETPROFITLOSSOPTNETPANDL(DEALNUMBER, 1);
--     varOperation := 'Getting Details for the Otc Deals ';
---- The Following Statment to calculate MTM even if it is partially cancelled
-- if numCounterParty between 30600001 and 30699999 then     -- MTM if it an OTC Deal
--
--     IF CHECKDATA= 'Y' THEN
--       select NVL(cfmr_profit_loss,0)
--           INTO NUMMTMVALUE
--           FROM TRTRAN062
--           where cfmr_deal_number = DealNumber
--           and cfmr_mtm_date =
--           (select max(cfmr_mtm_date)
--             from trtran062
--             WHERE CFMR_DEAL_NUMBER = DEALNUMBER
--             AND CFMR_MTM_DATE <= ASONDATE);
--     else
--         BEGIN
--
--             select NVL(cfmr_profit_loss,0)
--               INTO NUMMTMVALUE
--               FROM TRTRAN062
--               where cfmr_deal_number = DealNumber
--               and cfmr_mtm_date =
--               (select max(cfmr_mtm_date)
--                 from trtran062
--                 WHERE CFMR_DEAL_NUMBER = DEALNUMBER
--                 AND CFMR_MTM_DATE <= ASONDATE);
--           EXCEPTION
--           WHEN OTHERS THEN
--           NUMMTMVALUE :=0;
--       END;
--       end if;
--         if numBalance < numBaseAmount then -- Partially Cancelled OTC
--           numReturn := numProfitLoss + numMTMValue;
--         else -- Completely open
--   -- MTM takes care of premium already paid / received hence only MTM is taken
--           NUMRETURN := NUMMTMVALUE;
--         END IF;
--
--    ELSE
--      IF CHECKDATA= 'Y' THEN
--        SELECT numPremiumTot+ sum(pkgforexprocess.fncGetprofitLossOptions(COPT_DEAL_NUMBER,
--          opmm_strike_rate+opmm_settlement_price,numBalance, copt_expiry_date)) Pandl
--          into numMTMValue
--           --into numMTMValue
--           from trtran071, trtran072, trtran078 ma
--           WHERE COPT_DEAL_NUMBER = COSU_DEAL_NUMBER
--          -- AND COPT_EXCHANGE_CODE = opmm_EXCHANGE_CODE
--           and copt_deal_number=DEALNUMBER
--           AND COPT_BASE_CURRENCY= opmm_BASE_CURRENCY
--           AND COPT_EXCHANGE_CODE =70100001
--          -- and copt_process_complete =12400002
--           and ((copt_PROCESS_COMPLETE = 12400001  and copt_COMPLETE_DATE >ASONDATE) or copt_PROCESS_COMPLETE = 12400002)
--           and copt_other_currency= opmm_other_currency  and ((copt_PROCESS_COMPLETE = 12400001  and copt_COMPLETE_DATE >ASONDATE) or copt_PROCESS_COMPLETE = 12400002)
--           and copt_expiry_date= opmm_maturity_date
--           and cosu_strike_rate= opmm_strike_rate
--           and cosu_option_type= opmm_put_call
--           and opmm_trade_date = ASONDATE
--           and copt_record_status not in(10200005,10200006)
--           and opmm_serial_number= (select max(opmm_serial_number) from trtran078 Op
--                                     where op.opmm_base_currency= ma.opmm_base_currency
--                                       and op.opmm_other_currency= ma.opmm_other_currency
--                                       and op.opmm_maturity_date= copt_expiry_date
--                                       and op.opmm_strike_rate= cosu_strike_rate
--                                       and op.opmm_put_call= cosu_option_type
--                                       and op.opmm_trade_date = op.opmm_trade_date)
--        group by copt_deal_number;
--
--     else
--
--      begin
--        SELECT numPremiumTot+ sum(pkgforexprocess.fncGetprofitLossOptions(COPT_DEAL_NUMBER,
--          opmm_strike_rate+opmm_settlement_price,numBalance, copt_expiry_date)) Pandl
--          into numMTMValue
--           --into numMTMValue
--           from trtran071, trtran072, trtran078 ma
--           WHERE COPT_DEAL_NUMBER = COSU_DEAL_NUMBER
--          -- AND COPT_EXCHANGE_CODE = opmm_EXCHANGE_CODE
--           and copt_deal_number=DEALNUMBER
--           AND COPT_BASE_CURRENCY= opmm_BASE_CURRENCY
--           and copt_exchange_code =70100001
--          -- AND COPT_PROCESS_COMPLETE =12400002
--           and ((copt_PROCESS_COMPLETE = 12400001  and copt_COMPLETE_DATE >ASONDATE) or copt_PROCESS_COMPLETE = 12400002)
--           and copt_other_currency= opmm_other_currency
--           and copt_expiry_date= opmm_maturity_date
--           and cosu_strike_rate= opmm_strike_rate
--           and cosu_option_type= opmm_put_call
--           and opmm_trade_date = ASONDATE
--           and copt_record_status not in(10200005,10200006)
--           and opmm_serial_number= (select max(opmm_serial_number) from trtran078 Op
--                                     where op.opmm_base_currency= ma.opmm_base_currency
--                                       and op.opmm_other_currency= ma.opmm_other_currency
--                                       and op.opmm_maturity_date= copt_expiry_date
--                                       and op.opmm_strike_rate= cosu_strike_rate
--                                       and op.opmm_put_call= cosu_option_type
--                                       and op.opmm_trade_date = op.opmm_trade_date)
--        group by copt_deal_number;
--       exception
--        when no_data_found then
--        NUMMTMVALUE :=0;
--       end ;
--
--     end if;
--   --          varOperation := 'Getting Details for Exchange Deal';
--   --    -- MTM if Exchange Deal
--   --      SELECT FNCGETPROFITLOSS(NUMBALANCE, cfmm_closing_rate, cosu_strike_rate,cosu_buy_sell)
--   --        into numMTMValue
--   --        from trtran071, trtran072, trtran064
--   --        WHERE COPT_DEAL_NUMBER = COSU_DEAL_NUMBER
--   --        AND COPT_EXCHANGE_CODE = CFMM_EXCHANGE_CODE
--   --        and copt_deal_number=DealNumber
--   --        AND COPT_BASE_CURRENCY= CFMM_BASE_CURRENCY
--   --        and copt_other_currency= cfmm_other_currency
--   --        and cfmm_effective_date =
--   --        (select max(cfmm_effective_date)
--   --          FROM TRTRAN064
--   --          where cfmm_exchange_code = copt_exchange_code
--   --          AND CFMM_INSTRUMENT_TYPE = 32200003)
--   --         AND cfmm_serial_number =
--   --        (select max(cfmm_serial_number)
--   --          FROM TRTRAN064
--   --          WHERE CFMM_EXCHANGE_CODE = COPT_EXCHANGE_CODE
--   --          AND CFMM_INSTRUMENT_TYPE = 32200003)
--   --          order by 1;
--       --  numMTMValue := fncgetprofitloss(numBalance, numMTMRate, numStrikeRate,numBuySale);
--   -- For Exchange deals the old Premium should be taken into consideration
--         --numReturn := nvl(numProfitLoss,0) + nvl(numMTMValue,0);
--         numReturn:=nvl(numMTMValue,0);
--    End if;
--
--<<Process_End>>
--
--    return numReturn;
--Exception
--    When others then
--      NUMERROR := 0;
--      VARERROR := '0';
--      varError := GConst.fncReturnError('OptandL', numError, varMessage,
--                     varOperation, varError);
--   --   varError :=0;
--      raise_application_error(-20101, varError);
--      return numError;
--
--  END FNCGETOPTIONMTM;
-----modified by Gouri/Aakash 02-Aug-13 07:51 pm
Function fncGetOptionMTM
  ( DEALNUMBER IN VARCHAR2,
    AsonDate in Date,checkData in char default 'Y')
    return number

  is
--  Created on 01/07/2013 by TMM
    numError            number;
    numProcess          number(8);
    numCounterParty     number(8);
    numBuySale          number(8);
    numMTMValue         number(15,2);
    numProfitLoss       number(15,2);
    numBaseAmount       number(15,2);
    numPewmium          number(15,2);
    numPremiumTot       number(15,2);
    numBalance          number(15,2);
    numReturn           number(15,2);
    numStrikeRate       number(15,6);
    numMTMRate          number(15,6);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    DATCOMPLETE         DATE;

  Begin
    numError := 0;
    numMTMValue := 0;
    numProfitLoss := 0;
    numReturn := 0;

    varMessage := 'Calculating MTM for Option ' || DealNumber;

    varOperation := 'Getting Details for the ';
    begin
    SELECT COPT_BASE_AMOUNT,
        FNCGETOUTSTANDING(DEALNUMBER, 1, 15, 1, AsonDate),
      copt_counter_party, copt_process_complete, copt_complete_date,
      decode(copt_premium_status,Gconst.Received,1,Gconst.PremiumPaid,-1)*copt_premium_amount
      into numBaseAmount, numBalance,
      numCounterParty, numProcess, datComplete,numPewmium
      from trtran071
      where copt_deal_number = DealNumber
      and ((copt_PROCESS_COMPLETE = 12400001  and copt_COMPLETE_DATE >ASONDATE) or copt_PROCESS_COMPLETE = 12400002);
      EXCEPTION
           WHEN OTHERS THEN
           numPewmium :=0;
       END;
      -- Calculate the premium for the balance amount
      select (numPewmium/numbaseamount)* numBalance
       into numPremiumTot
       from dual;

       VAROPERATION := 'Getting net pandl';

    if  datComplete is not null and datComplete <= AsonDate then -- Deal is closed as on date
      numReturn := Fncgetprofitlossoptnetpandl(DealNumber, 1);
      Goto Process_End;
    End if;
-- The following statement takes care of Premia Paid / Received
-- and P L of Partilly cancelled deals
 varOperation := 'Getting opt pandl';
    NUMPROFITLOSS := FNCGETPROFITLOSSOPTNETPANDL(DEALNUMBER, 1);
     varOperation := 'Getting Details for the Otc Deals ';
-- The Following Statment to calculate MTM even if it is partially cancelled
 if numCounterParty between 30600001 and 30699999 then     -- MTM if it an OTC Deal

     IF CHECKDATA= 'Y' THEN
     begin
       select NVL(cfmr_profit_loss,0)
           INTO NUMMTMVALUE
           FROM TRTRAN062
           where cfmr_deal_number = DealNumber
           and cfmr_mtm_date =
           (select max(cfmr_mtm_date)
             from trtran062
             WHERE CFMR_DEAL_NUMBER = DEALNUMBER
             AND CFMR_MTM_DATE <= ASONDATE);
           EXCEPTION
           WHEN OTHERS THEN
           NUMMTMVALUE :=0;
          end; 
     else
         BEGIN

             select NVL(cfmr_profit_loss,0)
               INTO NUMMTMVALUE
               FROM TRTRAN062
               where cfmr_deal_number = DealNumber
               and cfmr_mtm_date =
               (select max(cfmr_mtm_date)
                 from trtran062
                 WHERE CFMR_DEAL_NUMBER = DEALNUMBER
                 AND CFMR_MTM_DATE <= ASONDATE);
           EXCEPTION
           WHEN OTHERS THEN
           NUMMTMVALUE :=0;
       END;
       end if;
         if numBalance < numBaseAmount then -- Partially Cancelled OTC
           numReturn := numProfitLoss + numMTMValue;
         else -- Completely open
   -- MTM takes care of premium already paid / received hence only MTM is taken
           NUMRETURN := NUMMTMVALUE;
         END IF;

    ELSE
      IF CHECKDATA= 'Y' THEN
      begin
      
      
        SELECT numPremiumTot+ sum(pkgforexprocess.fncGetprofitLossOptions(COPT_DEAL_NUMBER,
          opmm_strike_rate+opmm_settlement_price,numBalance, copt_expiry_date)) Pandl
          into numMTMValue
           --into numMTMValue
           from trtran071, trtran072, trtran078 ma
           WHERE COPT_DEAL_NUMBER = COSU_DEAL_NUMBER
          -- AND COPT_EXCHANGE_CODE = opmm_EXCHANGE_CODE
           and copt_deal_number=DEALNUMBER
           AND COPT_BASE_CURRENCY= opmm_BASE_CURRENCY
           --AND COPT_EXCHANGE_CODE =70100001 --Ishwara chandra if other exchange mtm value not populating
          -- and copt_process_complete =12400002
           and ((copt_PROCESS_COMPLETE = 12400001  and copt_COMPLETE_DATE >ASONDATE) or copt_PROCESS_COMPLETE = 12400002)
           and copt_other_currency= opmm_other_currency  and ((copt_PROCESS_COMPLETE = 12400001  and copt_COMPLETE_DATE >ASONDATE) or copt_PROCESS_COMPLETE = 12400002)
           and copt_expiry_date= opmm_maturity_date
           and cosu_strike_rate= opmm_strike_rate
           and cosu_option_type= opmm_put_call
           and opmm_trade_date = ASONDATE
           and copt_record_status not in(10200005,10200006)
           and opmm_serial_number= (select max(opmm_serial_number) from trtran078 Op
                                     where op.opmm_base_currency= ma.opmm_base_currency
                                       and op.opmm_other_currency= ma.opmm_other_currency
                                       and op.opmm_maturity_date= copt_expiry_date
                                       and op.opmm_strike_rate= cosu_strike_rate
                                       and op.opmm_put_call= cosu_option_type
                                       and op.opmm_trade_date = ma.opmm_trade_date)
        group by copt_deal_number;
       exception
        when no_data_found then
        NUMMTMVALUE :=NUMPROFITLOSS;
       end ;
     else

      begin
        SELECT numPremiumTot+ sum(pkgforexprocess.fncGetprofitLossOptions(COPT_DEAL_NUMBER,
          opmm_strike_rate+opmm_settlement_price,numBalance, copt_expiry_date)) Pandl
          into numMTMValue
           --into numMTMValue
           from trtran071, trtran072, trtran078 ma
           WHERE COPT_DEAL_NUMBER = COSU_DEAL_NUMBER
          -- AND COPT_EXCHANGE_CODE = opmm_EXCHANGE_CODE
           and copt_deal_number=DEALNUMBER
           AND COPT_BASE_CURRENCY= opmm_BASE_CURRENCY
           --and copt_exchange_code =70100001 --Ishwara chandra if other exchange mtm value not populating
          -- AND COPT_PROCESS_COMPLETE =12400002
           and ((copt_PROCESS_COMPLETE = 12400001  and copt_COMPLETE_DATE >ASONDATE) or copt_PROCESS_COMPLETE = 12400002)
           and copt_other_currency= opmm_other_currency
           and copt_expiry_date= opmm_maturity_date
           and cosu_strike_rate= opmm_strike_rate
           and cosu_option_type= opmm_put_call
           and opmm_trade_date = ASONDATE
           and copt_record_status not in(10200005,10200006)
           and opmm_serial_number= (select max(opmm_serial_number) from trtran078 Op
                                     where op.opmm_base_currency= ma.opmm_base_currency
                                       and op.opmm_other_currency= ma.opmm_other_currency
                                       and op.opmm_maturity_date= copt_expiry_date
                                       and op.opmm_strike_rate= cosu_strike_rate
                                       and op.opmm_put_call= cosu_option_type
                                       and op.opmm_trade_date = ma.opmm_trade_date)
        group by copt_deal_number;
       exception
        when no_data_found then
        NUMMTMVALUE :=NUMPROFITLOSS;
       end ;

     end if;
   --          varOperation := 'Getting Details for Exchange Deal';
   --    -- MTM if Exchange Deal
   --      SELECT FNCGETPROFITLOSS(NUMBALANCE, cfmm_closing_rate, cosu_strike_rate,cosu_buy_sell)
   --        into numMTMValue
   --        from trtran071, trtran072, trtran064
   --        WHERE COPT_DEAL_NUMBER = COSU_DEAL_NUMBER
   --        AND COPT_EXCHANGE_CODE = CFMM_EXCHANGE_CODE
   --        and copt_deal_number=DealNumber
   --        AND COPT_BASE_CURRENCY= CFMM_BASE_CURRENCY
   --        and copt_other_currency= cfmm_other_currency
   --        and cfmm_effective_date =
   --        (select max(cfmm_effective_date)
   --          FROM TRTRAN064
   --          where cfmm_exchange_code = copt_exchange_code
   --          AND CFMM_INSTRUMENT_TYPE = 32200003)
   --         AND cfmm_serial_number =
   --        (select max(cfmm_serial_number)
   --          FROM TRTRAN064
   --          WHERE CFMM_EXCHANGE_CODE = COPT_EXCHANGE_CODE
   --          AND CFMM_INSTRUMENT_TYPE = 32200003)
   --          order by 1;
       --  numMTMValue := fncgetprofitloss(numBalance, numMTMRate, numStrikeRate,numBuySale);
   -- For Exchange deals the old Premium should be taken into consideration
         --numReturn := nvl(numProfitLoss,0) + nvl(numMTMValue,0);
         numReturn:=nvl(numMTMValue,0);
    End if;

<<Process_End>>

    return numReturn;
Exception

    When others then
      NUMERROR := 0;
      VARERROR := '0';
      varError := GConst.fncReturnError('OptandL', numError, varMessage,
                     varOperation, varError);
   --   varError :=0;
      raise_application_error(-20101, varError);
      return numError;

  END FNCGETOPTIONMTM;

--end



   ----commented Aakash 30-july-13
--function fncGetprofitLossOptions  --added on 22/03/12 for OPTMTMEXCHNGSTMT
--  (varReference  in varchar,
--   refRate       in number,
--   numBaseAMount in number,
--   datEffectDate in date)
--   return number
-- is
--   numDealType number(8);
--   numLeg1 number(8);
--   numLeg2 number(8);
--  -- numBaseAmount number(8);
--
--   numOptionType number(8);
--   numBuySell number(8);
--   numStrikeRate number(15,6);
--   numSerial2  number(8);
--   numOptionType2 number(8);
--   numBuySell2 number(8);
--   numStrikeRate2 number(15,6);
--   numSerial3  number(8);
--   numOptionType3 number(8);
--   numBuySell3 number(8);
--   numStrikeRate3 number(15,6);
--   numSerial4  number(8);
--   numOptionType4 number(8);
--   numBuySell4 number(8);
--   numStrikeRate4 number(15,6);
--
--   numTemp number(15,6);
--
--   numSerial  number := 0;
--   numPLFCY   number := 0;
--   numPLLocal number := 0;
--   varRemarks varchar(2000);
-- begin
--
--    select copt_deal_type
--    --copt_base_amount
--      into numdealtype
--      --,numBaseAmount
--      from trtran071
--     where copt_deal_number= varReference
--       and copt_record_status not in (Gconst.StatusinActive,Gconst.STATUSDELETED);
--
--    if ((numDealType = Gconst.PlainVenela) or (numDealType = Gconst.Straddle)) then
--       for C1 in ( select cosu_serial_number,cosu_option_type OptionType,cosu_buy_sell buysell,
--                          cosu_strike_rate StrikeRate
--                     from trtran072
--                     where cosu_deal_number=varReference
--                     and cosu_record_status not in(10200005,10200006))
--        loop
--           if C1.buysell= Gconst.PURCHASEDEAL then
--                if c1.OptionType =Gconst.OptionCall then
--                     if refrate > C1.strikeRate then
--                        numPLFCY:= (refrate-C1.StrikeRate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                        return numPLFCY;
--                     elsif refrate < C1.strikeRate then
--                        numPLFCY:= (refRate-C1.StrikeRate)*numBaseAmount;
--                        varRemarks:='No Exercise';
--                     end if;
--                elsif C1.OptionType =Gconst.OptionPut then
--                     if refrate < C1.strikeRate then
--                        numPLFCY:= (refrate-C1.StrikeRate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                        return numPLFCY;
--                     elsif refrate > C1.StrikeRate then
--                        numPLFCY:= (refrate-C1.StrikeRate)*numBaseAmount;
--                        varRemarks:='No Exercise';
--                     end if;
--                end if;
--             elsif C1.buysell= Gconst.SALEDEAL then
--                if C1.OptionType =Gconst.OptionCall then
--                     if refrate > C1.strikeRate then
--                        numPLFCY:= (refrate-C1.StrikeRate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                        return numPLFCY;
--                     elsif refrate < C1.strikeRate then
--                        numPLFCY:= (refrate-C1.StrikeRate)*numBaseAmount;
--                        varRemarks:='No Exercise';
--                     end if;
--                elsif C1.OptionType =Gconst.OptionPut then
--                     if C1.strikeRate > refrate then
--                        numPLFCY:= (refrate-C1.StrikeRate)*numBaseAmount;
--                        varRemarks:='Option Exercise';
--                        return numPLFCY;
--                     elsif refrate < C1.strikeRate then
--                        numPLFCY:= (refrate-C1.StrikeRate)*numBaseAmount;
--                        varRemarks:='No Exercise';
--                     end if;
--                end if;
--             end if;
--
--        end loop;
--    elsif numDealType = Gconst.Seagull then
--
--              varRemarks:='Enter into Seagull';
--              numtemp:=0;
--              numPLFCY:=0;
--       for C1 in ( select cosu_serial_number,cosu_option_type OptionType,cosu_buy_sell buysell,
--                          cosu_strike_rate StrikeRate
--                     from trtran072
--                     where cosu_deal_number=varReference
--                     and cosu_record_status not in(10200005,10200006))
--        loop
--           if ((c1.OptionType=Gconst.OptionCall) and (c1.BuySell=Gconst.PURCHASEDEAL)) then
--              select decode(sign((refRate-c1.StrikeRate)*numBaseAmount),-1,0,((refRate-c1.StrikeRate)*numBaseAmount))
--                into numtemp
--                from dual;
--               -- varRemarks:= varRemarks || 'Enter into Seagull 1' || to_char(numtemp) ;
--           end if;
--
--
--           if ((c1.OptionType=Gconst.OptionPut) and (c1.BuySell=Gconst.PURCHASEDEAL)) then
--               select decode(sign((c1.StrikeRate-refRate)*numBaseAmount),-1,0,((c1.StrikeRate-refRate)*numBaseAmount))
--                 into numtemp
--                 from dual;
--                -- varRemarks:= varRemarks || 'Enter into Seagull 2' || to_char(numtemp) ;
--           end if;
--
--           if ((c1.OptionType=Gconst.OptionCall) and (c1.BuySell=Gconst.SALEDEAL)) then
--              select -1 * decode(sign((refRate-c1.StrikeRate)*numBaseAmount),-1,0,((refRate-c1.StrikeRate)*numBaseAmount))
--                into numtemp
--                from  dual;
--               --  varRemarks:= varRemarks || 'Enter into Seagull 3' || to_char(numtemp) ;
--           end if;
--
--           if ((c1.OptionType=Gconst.OptionPut) and (c1.BuySell=Gconst.SALEDEAL)) then
--              select -1 * decode(sign((c1.StrikeRate-refRate)*numBaseAmount),-1,0,((c1.StrikeRate-refRate)*numBaseAmount))
--               into numtemp
--               from dual;
--                 --varRemarks:= varRemarks || 'Enter into Seagull 4' || to_char(numtemp) ;
--           end if;
--
--           numPLFCY:= numTemp+numPLFCY;
--
--           if numPLFCY >0 then
--             varRemarks:='Option Exercise';
--           else
--              varRemarks:='No Exercise';
--           end if;
--        end loop;
--
--    elsif numDealType = Gconst.Stragles then
--    --Checking first Leg
--       begin
--        select cosu_serial_number,cosu_option_type,cosu_buy_sell,
--                cosu_strike_rate
--          into numserial,numoptionType,numbuysell,numStrikeRate
--          from trtran072
--         where cosu_deal_number=varReference
--           and cosu_option_type =Gconst.OptionCall;
--          -- and cosu_strike_rate>refRate;
--          if numbuysell= Gconst.PURCHASEDEAL then
--             if numstrikeRate< refrate then
--                numPLFCY:= (refrate-numStrikeRate)*numBaseAmount;
--                varRemarks:='Option Exercise';
--                goto Result_return;
--             else
--                  varRemarks:='NO Exercise';
--             end if;
--          elsif numbuysell= Gconst.SALEDEAL then
--             if numstrikeRate< refrate then
--                numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
--                varRemarks:='Option Exercise';
--                goto Result_return;
--             else
--                  varRemarks:='No Exercise';
--             end if;
--          end if;
--
--       exception
--       when others then
--            numserial:=0;--,numoptionType,numbuysell,numStrikeRate
--       end;
--     -- --Checking first Second Leg
--       begin
--        select cosu_serial_number,cosu_option_type,cosu_buy_sell,
--               cosu_strike_rate
--          into numserial,numoptionType,numbuysell,numStrikeRate
--          from trtran072
--         where cosu_deal_number=varReference
--           and cosu_option_type =Gconst.OptionPut;
--          -- and cosu_strike_rate<refRate;
--
--          if numbuysell= Gconst.PURCHASEDEAL then
--             if numstrikeRate> refrate then
--                numPLFCY:= (numStrikeRate-refrate)*numBaseAmount;
--                varRemarks:='Option Exercise';
--                goto Result_return;
--             else
--                  varRemarks:='No Exercise';
--             end if;
--          elsif numbuysell= Gconst.SALEDEAL then
--             if numstrikeRate< refrate then
--                numPLFCY:= (refrate-numStrikeRate)*numBaseAmount;
--                varRemarks:='Option Exercise';
--                goto Result_return;
--             else
--                  varRemarks:='NO Exercise';
--             end if;
--          end if;
--       exception
--       when others then
--            numserial:=0;--,numoptionType,numbuysell,numStrikeRate
--       end;
--
--    end if;
--  <<Result_return>>
--      if varRemarks='No Exercise' then
--         numPLFCY:=0;
--      end if;
--      numPLLocal:= numPLFCY * refRate;
--   return numPLFCY;
-- end;
------modified by manjunath reddyr/aakash 30-july-13
function fncGetprofitLossOptions  --added on 22/03/12 for OPTMTMEXCHNGSTMT
  (varReference  in varchar,
   refRate       in number,
   numBaseAMount in number,
   datEffectDate in date)
   return number
 is
   numDealType number(8);
   numLeg1 number(8);
   numLeg2 number(8);
  -- numBaseAmount number(8);

   numOptionType number(8);
   numBuySell number(8);
   numStrikeRate number(15,6);
   numSerial2  number(8);
   numOptionType2 number(8);
   numBuySell2 number(8);
   numStrikeRate2 number(15,6);
   numSerial3  number(8);
   numOptionType3 number(8);
   numBuySell3 number(8);
   numStrikeRate3 number(15,6);
   numSerial4  number(8);
   numOptionType4 number(8);
   numBuySell4 number(8);
   numStrikeRate4 number(15,6);

   numTemp number(15,6);

   numSerial  number := 0;
   numPLFCY   number := 0;
   numPLLocal number := 0;
   varRemarks varchar(2000);
 begin

    select copt_deal_type
    --copt_base_amount
      into numdealtype
      --,numBaseAmount
      from trtran071
     where copt_deal_number= varReference
       and copt_record_status not in (Gconst.StatusinActive,Gconst.STATUSDELETED);

    if ((numDealType = Gconst.PlainVenela) or (numDealType = Gconst.Straddle)) then
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
                        numPLFCY:= (C1.StrikeRate-refrate)*numBaseAmount;
                        varRemarks:='Option Exercise';
                        return numPLFCY;
                     elsif refrate > C1.StrikeRate then
                        numPLFCY:= (C1.StrikeRate-refrate)*numBaseAmount;
                        varRemarks:='No Exercise';
                     end if;
                end if;
             elsif C1.buysell= Gconst.SALEDEAL then
                if C1.OptionType =Gconst.OptionCall then
                     if refrate > C1.strikeRate then
                        numPLFCY:= (C1.StrikeRate-refrate)*numBaseAmount;
                        varRemarks:='Option Exercise';
                        return numPLFCY;
                     elsif refrate < C1.strikeRate then
                        numPLFCY:= (C1.StrikeRate-refrate)*numBaseAmount;
                        varRemarks:='No Exercise';
                     end if;
                elsif C1.OptionType =Gconst.OptionPut then
                     if C1.strikeRate > refrate then
                        numPLFCY:= (refrate-C1.StrikeRate)*numBaseAmount;
                        varRemarks:='Option Exercise';
                        return numPLFCY;
                     elsif C1.strikeRate < refrate then
                        numPLFCY:= (C1.StrikeRate - refrate)*numBaseAmount;
                        varRemarks:='Option Exercise';
                     end if;
                end if;
             end if;

        end loop;
    elsif numDealType = Gconst.Seagull then

              varRemarks:='Enter into Seagull';
              numtemp:=0;
              numPLFCY:=0;
       for C1 in ( select cosu_serial_number,cosu_option_type OptionType,cosu_buy_sell buysell,
                          cosu_strike_rate StrikeRate
                     from trtran072
                     where cosu_deal_number=varReference
                     and cosu_record_status not in(10200005,10200006))
        loop
           if ((c1.OptionType=Gconst.OptionCall) and (c1.BuySell=Gconst.PURCHASEDEAL)) then
              select decode(sign((refRate-c1.StrikeRate)*numBaseAmount),-1,0,((refRate-c1.StrikeRate)*numBaseAmount))
                into numtemp
                from dual;
               -- varRemarks:= varRemarks || 'Enter into Seagull 1' || to_char(numtemp) ;
           end if;


           if ((c1.OptionType=Gconst.OptionPut) and (c1.BuySell=Gconst.PURCHASEDEAL)) then
               select decode(sign((c1.StrikeRate-refRate)*numBaseAmount),-1,0,((c1.StrikeRate-refRate)*numBaseAmount))
                 into numtemp
                 from dual;
                -- varRemarks:= varRemarks || 'Enter into Seagull 2' || to_char(numtemp) ;
           end if;

           if ((c1.OptionType=Gconst.OptionCall) and (c1.BuySell=Gconst.SALEDEAL)) then
              select -1 * decode(sign((refRate-c1.StrikeRate)*numBaseAmount),-1,0,((refRate-c1.StrikeRate)*numBaseAmount))
                into numtemp
                from  dual;
               --  varRemarks:= varRemarks || 'Enter into Seagull 3' || to_char(numtemp) ;
           end if;

           if ((c1.OptionType=Gconst.OptionPut) and (c1.BuySell=Gconst.SALEDEAL)) then
              select -1 * decode(sign((c1.StrikeRate-refRate)*numBaseAmount),-1,0,((c1.StrikeRate-refRate)*numBaseAmount))
               into numtemp
               from dual;
                 --varRemarks:= varRemarks || 'Enter into Seagull 4' || to_char(numtemp) ;
           end if;

           numPLFCY:= numTemp+numPLFCY;

           if numPLFCY >0 then
             varRemarks:='Option Exercise';
           else
              varRemarks:='No Exercise';
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
 end;
 ----end

function fncCalFuturePandL
    (buysell number,
     Lot number,
     LotRate number,
     ReverseRate number)
    return number
  is
  begin
     if buysell = Gconst.PURCHASEDEAL then
     begin
        return (ReverseRate-LotRate)*Lot;
     end;
     elsif buysell = Gconst.SALEDEAL then
        return (LotRate-ReverseRate)*Lot;
     end if;
  end;


  function fncPurchaseContractOS(TradeReference in varchar,
                               AsonDate in date,
                               Maturity in Date,
                               Contractno in varchar) return number
as
numFcy number(15,2);
numinr number(15,2);
numUtilFcy number(15,2);
numUtilInr number(15,2);
begin
     -- varOperation := 'Extracting Purchase contract details';
      select nvl(sum(trad_trade_fcy),0), nvl(sum(trad_trade_inr),0)
        into numFcy, numInr
        from trtran002
        where trad_trade_reference = TradeReference
        and trad_entry_date <= AsonDate
        and trad_record_status not in(10200005,10200006);



     -- varOperation := 'Extracting Merchant Utilization';

      begin

          Select nvl(sum(brel_reversal_fcy),0), nvl(sum(brel_reversal_fcy*brel_reversal_rate),0)
             into numUtilFcy, numUtilInr
            From Trtran002 a ,Trtran003 b
            Where a.Trad_Trade_Reference=b.brel_Trade_Reference
            And a.Trad_Contract_No=Contractno
           -- and a.trad_trade_reference =TradeReference
            and b.brel_entry_date <=AsonDate
            and to_char(b.brel_entry_date,'yyyymm')= to_char(Maturity,'yyyymm')
            And a.Trad_Record_Status In (10200005)
            And b.Brel_Record_Status Not In (10200005,10200006);
      exception
      when others then
         numUtilFcy:=0;
         numUtilInr:=0;
      end;

    return numFcy-numUtilFcy;
end fncPurchaseContractOS;
function fncGetMFNav(DatDate date,
                      navCode varchar2)
            return number
  as
     decTemp number(15,6);
  begin

    select mfmm_netasset_value
      into decTemp
     from trtran050
    where mfmm_reference_date= datDate
      and mfmm_nav_code=navCode ;
  return    decTemp;
  end fncGetMFNav;
function fncGetIRSRate(Effectivedate date,
                       SettlementDate date,
                       RateType number)
         return number
as
   decTemp number(15,6);      
begin
select avg(irat_settlement_price)
 into decTemp
from TRTRAN094 where irat_interest_type=RateType
and IRAT_effective_date =Effectivedate
and irat_settlement_date between '01-' || to_char(SettlementDate,'MON') || to_char(SettlementDate,'YYYY')
                         and last_day(SettlementDate);

return decTemp;
end fncGetIRSRate;

--RateReturnType
-- 1 Custom Rate
-- 2 Cross Rate
-- 3 Spot Rate / Marketing Plan Rate
-- 4 Budget Rate
function fncGetCustomRate(
    datEffectiveDate in date,
    numCurrency in number,
    numBuysell in number, -- Import Export
    numRateReturnType in number) 
return number
as 
    numError      number;
    numTemp       number(15,6);
    varOperation  gconst.gvaroperation%type;
    varMessage    gconst.gvarmessage%type;
    varError      gconst.gvarerror%type;
begin

  
      select (case when ((numBuysell= 25300001) and (numRateReturnType=2)) then ERAT_EXPORT_CROSS 
                  when ((numBuysell= 25300001) and (numRateReturnType=3)) then ERAT_EXPORT_SPOT 
                  when ((numBuysell= 25300001) and (numRateReturnType=1)) then ERAT_EXPORT_CUSTOM 
                  when ((numBuysell= 25300001) and (numRateReturnType=4)) then ERAT_EXPORT_BUDGET 
                  when ((numBuysell= 25300002) and (numRateReturnType=2)) then ERAT_Import_CROSS 
                  when ((numBuysell= 25300002) and (numRateReturnType=3)) then ERAT_Import_SPOT 
                  when ((numBuysell= 25300002) and (numRateReturnType=1)) then ERAT_Import_CUSTOM 
                  when ((numBuysell= 25300002) and (numRateReturnType=4)) then ERAT_Import_BUDGET 
              end)
          into numTemp
      from tfsystem009
      where ERAT_CURRENCY_CODE =numCurrency
      and ERAT_RECORD_STATUS not in (10200005,10200006)
      and ERAT_EFFECTIVE_DATE = (select max(ERAT_EFFECTIVE_DATE) 
                                    from  tfsystem009
                                  where ERAT_CURRENCY_CODE= numCurrency
                                  and ERAT_EFFECTIVE_DATE <=datEffectiveDate
                                  and ERAT_RECORD_STATUS not in (10200005,10200006));
    
    return numTemp;
  exception
   when no_data_found then
     return 0;
    when others then
      varmessage := sqlerrm;
      varerror := 'fncCustomRate: ' || varmessage || varoperation || varerror;
      raise_application_error(-20101,   varerror);
      return 0;
end fncGetCustomRate;
PROCEDURE prcgetchargeamount(clbdetails in clob ,errorcode out number) 
as
      numAction  number(8);
      varentity  varchar(50);
      varLimitReference varchar2(30);
      datTemp    date;
      numCode    number(8);
      numerror   number;
      numtemp number(8);
      varOperation varchar2(2000);
      varerror varchar2(4000);
      varTemp2 varchar2(4000);
      numCompany number(8);
      numLocation number(8);
      numlob number(8);
      numcurrency number(8);
      Numperiod number(4);
      numperiodtype number(8);
      numsanctionamt    number(15,2);
      numlimittype number(8);
      datWorkDate date;
      datlcduedate date;
      numbankcode number(8);
      xmlTemp xmlType;
      numchargeamt number(15,2);
      numtransactionamt number(15,2);
      numcommitmentperiod number(3);
      datexpirydate date;
      datapplicationdate date;
      nummonths  number(3);
      numdays number(3);
      numquarters number(3);
      numcharge number(15,2);
      numusanceperiod number(5);
      varreference varchar2(30);
      Numpaymentterm number(8);
      numcount number;
      varlcdiscount varchar2(30);
      numpbdtenor number(5);
      numtenortype number(8);
      numcalculatedamount number(15,2);
      numcaldays  number(5);
      numcalmonths  number(5);
      numproducttype number(8);
      numbc number;
      numminamount number(15,2);
      nummaxamount number(15,2);
      numservicecharge number(15,2);
      numSWATCHBHARATCharge number(15,2);
      numKRISHIKALYANCharge number(15,2);
      numAmountFrom number(15,2);
      limitref varchar2(50);
      chgevent number(8) ;
      ToleranceRate number (6,2);
      NumRate number(15,6);
      numServiceTax number(15,6);
      numServiceTemp number(15,2);
      numSWATCHBHARATTemp number(15,2);
      numKRISHIKALYANTemp number(15,2);
      numForeignExchangeTaxTemp number(15,2);
      numForeignExchangeTaxTotal number(15,2);
      numChargeTotalamount number(15,2); 
      
      nodTemp             xmlDom.domNode;
      nmpTemp             xmldom.domNamedNodeMap;
      nlsTemp             xmlDom.DomNodeList;
      varXPath            varchar2(512);
      varTemp             varchar2(512);
      varTemp1            varchar2(512);
      nodFinal            xmlDom.domNode;
      numSub              number(3);
      docFinal            xmlDom.domDocument;
begin
         
    
    varOperation := 'Extracting Input Parameters';
    xmlTemp := xmlType(clbdetails);
    delete from temp2;
    delete from trtemp015D;commit;
   INSERT INTO temp2 VALUES('charge started to extract parameter');commit;
   -- varUserID := GConst.fncXMLExtract(xmlTemp, 'UserCode', varUserID);
    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
    numCompany := GConst.fncXMLExtract(xmlTemp, 'CompanyID', numCompany);
    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationID', numLocation);
   
    INSERT INTO temp2 VALUES(' Step 1 : Calcualting Charges' || varEntity  );commit;
    
   -- numbankcode:=GConst.fncXMLExtract(xmlTemp, 'LocalBank', numbankcode);
   NUMCOUNT:=1;
     numproducttype:=34099999 ; --all product
   if varEntity in ('HEDGEDEALREGISTER','FORWARDDEALSFOREDIT') then
        numbc:=2 ;
         begin
             varreference:=GConst.fncXMLExtract(xmlTemp, '//' || varEntity||'/ROW/DealNumber', varreference,GConst.TYPENODEPATH);  
             numtransactionamt:=GConst.fncXMLExtract(xmlTemp, '//' || varEntity||'/ROW/OtherAmount', numtransactionamt,GConst.TYPENODEPATH);  --GConst.fncXMLExtract(xmlTemp, 'OtherAmount', numtransactionamt);
          exception
            when others then
              varreference:='0';
              numtransactionamt:=0;
           end;
           numtransactionamt:=GConst.fncXMLExtract(xmlTemp, '//' || varEntity||'/ROW/OtherAmount', numtransactionamt,GConst.TYPENODEPATH);  --GConst.fncXMLExtract(xmlTemp, 'OtherAmount', numtransactionamt);
        --numtransactionamt:=GConst.fncXMLExtract(xmlTemp, 'OtherAmount', numtransactionamt);
        varLimitReference:=null;
        Numpaymentterm:=0 ;
        numcurrency:=30499999 ;
        numCompany:= 30199999;
        numbankcode:=GConst.fncXMLExtract(xmlTemp, '//' || varEntity||'/ROW/CounterParty', numbankcode,GConst.TYPENODEPATH);  
        varlcdiscount:='0';
        insert into temp values(numtransactionamt,'numtransactionamt');
        insert into temp values(numbankcode,'numbankcode');

    end if;
    if varEntity in ('HEDGEDEALCANCELLATION','FORWARDDEALCANCELFOREDIT') then
        numbc:=2 ;
         begin
             varreference:=GConst.fncXMLExtract(xmlTemp, '//' || varEntity||'/ROW/DealNumber', varreference,GConst.TYPENODEPATH);  
          exception
            when others then
              varreference:='0';
           end;
        numtransactionamt:=GConst.fncXMLExtract(xmlTemp, 'CancelInr', numtransactionamt);
        varLimitReference:=null;
        Numpaymentterm:=0 ;
        numcurrency:=30499999 ;
        numCompany:=30199999;
            select Deal_counter_party
            into numbankcode
            from trtran001
              where deal_deal_number= VarReference
              and deal_record_Status not in (10200005,10200006);

     --   numbankcode:=GConst.fncXMLExtract(xmlTemp, '//' || varEntity||'/ROW/Counterparty', numbankcode,GConst.TYPENODEPATH);  
        varlcdiscount:='0';
    end if;
   
    numservicecharge:=0;
    INSERT INTO TEMP2 VALUES('Step 2 :: Limit : '||varLimitReference|| ' LC Discount: ' || varlcdiscount|| ' Entity: ' || varEntity|| ' Company: ' || numCompany|| ' Bank Code :' || numbankcode|| ' Currency :' || numcurrency|| ' Transaction Amount : ' || numtransactionamt || ' Limit : ' || varLimitReference ||  ' numBC : ' ||numbc || ' Function Return ' ||  ' Producttype ' || numproducttype);
    
    for recdata in (select * from trtran015E 
                     where CHGA_BANK_CODE=numbankcode
                       and (chGa_limit_type= 34699999)
--                       or
--                           (CHGA_SANCTION_APPLIED=DECODE(CHGA_SCREEN_NAME ,'PBDLCDREALIZE',pkglcprocess.FNCsanctionreference(varLimitReference ,3,numbc),
--                                                 decode(varlcdiscount,'12400001','0',fncsanctionreference(varLimitReference ,3,numbc)))))
                       and CHGA_SCREEN_NAME=varEntity
                         -- and CHGA_CURRENCY_CODE=DECODE(numcurrency,20599999,CHGA_CURRENCY_CODE,numcurrency)
                       and (CHGA_CURRENCY_CODE= 30499999 or CHGA_CURRENCY_CODE=DECODE(numcurrency,0, 30400003,30499999,CHGA_CURRENCY_CODE,numcurrency) OR
                            DECODE(CHGA_CURRENCY_CODE,30499999,numcurrency,CHGA_CURRENCY_CODE)=numcurrency)
                       and CHGA_EFFECTIVE_DATE= 
                            (select max(A.CHGA_EFFECTIVE_DATE) from trtran015E A
                                         where A.CHGA_BANK_CODE=numbankcode
                                          and (chGa_limit_type= 34699999)
--                                          or
--                                              (A.CHGA_SANCTION_APPLIED=DECODE(CHGA_SCREEN_NAME ,'PBDLCDREALIZE',pkglcprocess.FNCsanctionreference(varLimitReference ,3,numbc),
--                                                decode(varlcdiscount,'12400001','0',fncsanctionreference(varLimitReference ,3,numbc))
--                                                )
--                                                )
                                                
                                            and A.CHGA_SCREEN_NAME=varEntity
                                           -- and A.CHGA_CURRENCY_CODE=DECODE(numcurrency,20599999,CHGA_CURRENCY_CODE,numcurrency) 
                                           and (CHGA_CURRENCY_CODE= 30499999 or CHGA_CURRENCY_CODE=DECODE(numcurrency,0, 30400003,30499999,CHGA_CURRENCY_CODE,numcurrency)
                                                OR DECODE(CHGA_CURRENCY_CODE,30499999,numcurrency,CHGA_CURRENCY_CODE)=numcurrency)
                                            AND A.CHGA_RECORD_STATUS not IN (10200005,10200006))
                                            and CHGA_RECORD_STATUS not IN (10200005,10200006))
    
    loop
        begin
          numcharge:=0;
          numcalculatedamount:=0;
          numcaldays:=0;
          numcalmonths:=0;
          INSERT INTO TEMP2 VALUES('Step 3: Bankcode '||numbankcode || 'Limit : ' || varLimitReference|| 'Trans Amount :' || numtransactionamt|| ' Charge Type : ' || recdata.CHGA_CHARGE_TYPE|| 'Payment Term : ' || Numpaymentterm);commit;
          
          for recdata1 in ( select *  from trtran015D 
                             where CHAR_BANK_CODE= numbankcode  
                               and CHAR_ACCOUNT_HEAD=recdata.CHGA_CHARGE_TYPE
                               and char_reference_number= recData.Chga_Ref_number
                               AND (CHAR_LIMIT_TYPE= 34699999) 
                                  -- (CHAR_LIMIT_TYPE=DECODE(varLimitReference, '0',34699999,fncsanctionreference(varLimitReference ,4 ,numbc) )))
                               and (CHAR_APPLICABLE_BILL=35599999)
--                               OR 
--                                    (CHAR_APPLICABLE_BILL=decode(fncgetbilltype(recdata.CHGA_CHARGE_TYPE,numbankcode,fncsanctionreference(varLimitReference ,4,numbc),Numpaymentterm),0,CHAR_APPLICABLE_BILL,
--                                                      fncgetbilltype(recdata.CHGA_CHARGE_TYPE,numbankcode,fncsanctionreference(varLimitReference ,4,numbc),Numpaymentterm))))
                            --   and  (CHAR_PRODUCT_TYPE=35499999) 
                                  --  (CHAR_PRODUCT_TYPE=DECODE(numproducttype,24200008,34000001, 24299999,34099999 ,34099999,numproducttype ,34000002))) 
                               AND CHAR_EFFECTIVE_DATE=  (select max(A.CHAR_EFFECTIVE_DATE) from trtran015D A 
                                                            where A.CHAR_BANK_CODE= numbankcode  
                                                              and A.CHAR_ACCOUNT_HEAD=recdata.CHGA_CHARGE_TYPE  
--                                                              AND (CHAR_LIMIT_TYPE= 34699999) OR 
--                                                                 (CHAR_LIMIT_TYPE=DECODE(varLimitReference, '0',34699999,fncsanctionreference(varLimitReference ,4,numbc))))
                                                           --   and (CHAR_PRODUCT_TYPE=34099999) 
                                                              --    (a.CHAR_PRODUCT_TYPE =DECODE(numproducttype,24200008,34000001, 24299999,34099999 ,34099999,numproducttype ,34000002))) 
                                                                  and a.CHAR_RECORD_STATUS not in (10200005,10200006)
                                                              and CHAR_RECORD_STATUS NOT IN (10200005,10200006))
                            and ((numtransactionamt=0) or 
                                  (numtransactionamt between CHAR_AMOUNT_FROM and CHAR_AMOUNT_UPTO))
                            and CHAR_RECORD_STATUS NOT IN (10200005,10200006)
                            order by CHAR_PERIOD_TYPE,CHAR_PERIOD_UPTO)
                                                    
         
            loop
                --336--Actual,round month
               -- 337-percentage
               --338-each invoice,or each supplier
               --339-sight bill,
               --341-once or everytime
               --342 based on commitment period ,usance period
               INSERT INTO TEMP2 VALUES('Step 4: Inside Inner Loop Min '||recdata1.CHAR_MIN_AMOUNT || 'Max : ' || recdata1.CHAR_MAX_AMOUNT|| ' Charge Amount :' || recdata1.CHAR_CHARGES_AMOUNT);commit;
    
                 numminamount:= nvl(recdata1.CHAR_MIN_AMOUNT,0);
                 nummaxamount:=nvl(recdata1.CHAR_MAX_AMOUNT,999999999);
                 if recdata1.CHAR_PERCENT_TYPE = 34700001 then
                  numcharge:=(recdata1.CHAR_CHARGES_AMOUNT * numtransactionamt)/100;
                 else
                  numcharge:=recdata1.CHAR_CHARGES_AMOUNT ;
                 end if;
                 insert into temp values(numcharge,'numcharge');
--                INSERT INTO TEMP2 VALUES(' Step 4.1 : event'||recdata1.CHAR_CHARGING_EVENT);
--                insert into temp2 values('Step 4.1 : service tax' || recdata1.CHAR_ACCOUNT_HEAD || numservicecharge );commit;
--                
--               if recdata1.CHAR_CHARGING_EVENT=34100001 then --once
--                        if varEntity in ('IMPORTLCAMENDMENT') then -- 'IMPORTLCCLOSURE'
--                           varreference:=GConst.fncXMLExtract(xmlTemp, 'LcNumber', varreference);
--                            select COUNT(*) into numcount FROM tftran039 
--                                where polc_company_code=numcompany
--                                  and polc_location_code=numlocation and polc_lc_number=varreference 
--                                  and nvl(polc_amendment_fields,33299999) <> 33299999 
--                                  and polc_record_status not in (10200005,10200006);
--                                  
--                              if nvl(numcount,0) > 0 then --already charged
--                                  numcharge:=0;
--                                  goto process_end;
--                             end if; 
--                        elsif varEntity in ('PBDSANCTION' ) then   
--                              
--                              numtemp:=GConst.fncXMLExtract(xmlTemp, 'NegotiatingType', numtemp);
--                              if numtemp=12400001 then
--                                 varreference:=GConst.fncXMLExtract(xmlTemp, 'LcNumber', varreference);
--                                 select count(*) into numcount FROM tftran081 
--                                    where PBDA_COMPANY_CODE=numcompany and PBDA_LOCATION_CODE=numlocation
--                                     and PBDA_LC_NUMBER=varreference  and  PBDA_RECORD_STATUS NOT IN (10200005,10200006) ;
--                                     
--                              end if;
--                              if nvl(numcount,0) > 1 then --already charged
--                                  numcharge:=0;
--                                  goto process_end;
--                             end if;  
--                       elsif varEntity in ('PBDLCDREALIZE' ) then   
--                           -- varreference:=GConst.fncXMLExtract(xmlTemp, 'ReferenceNumber', varreference);   
--                            varreference:=GConst.fncXMLExtract(xmlTemp, '//' || varEntity||'/ROW/ReferenceNumber', varreference,GConst.TYPENODEPATH);  
--                                   select count(*) into numcount FROM tftran083
--                                            where PBDR_COMPANY_CODE=numcompany and PBDR_LOCATION_CODE=numlocation
--                                           and PBDR_REFERENCE_NUMBER=varreference  and  PBDR_RECORD_STATUS NOT IN (10200005,10200006) ;
--                          
--                                 
--                                  if nvl(numcount,0) > 1 then --already charged
--                                        numcharge:=0;
--                                        goto process_end;
--                                   end if; 
--                             
--                       elsif varEntity in ( 'BCCLOSURE','BUYERSCREDITROLLOVER') then 
--                             numcount:=0; ---NEED TO BE ADDED ONCE ROLLOVER COMPLETE
--                           
--                             varreference:=GConst.fncXMLExtract(xmlTemp, '//' || varEntity||'/ROW/BuyersCredit', varreference,GConst.TYPENODEPATH);  
--                            
--                             
--                             if nvl(numcount,0) > 1 then --already charged
--                                  numcharge:=0;
--                                  goto process_end;
--                             end if; 
--                       end if; 
--                       
--                       
--                 elsif recdata1.CHAR_CHARGING_EVENT=34100002 then --everytime 
--                       numcharge:=0;
--                     --  INSERT INTO TEMP1 VALUES('charge started2');
--                 end if; 
--                 
--               if varEntity in ('IMPORTLCAPPLICATION','IMPORTLCSANCTION','IMPORTLCAMENDMENT', 'IMPORTLCCLOSURE') then
--                    INSERT INTO TEMP1 VALUES('charge3 '||recdata1.CHAR_BASED_ON||recdata1.CHAR_PERIOD_TYPE||recdata1.CHAR_TIMING_EVENT||recdata1.CHAR_ACCOUNT_HEAD || 
--                         ' Pecentage ' || recdata1.CHAR_PERCENT_TYPE );
--                  --  numcommitmentperiod:=GConst.fncXMLExtract(xmlTemp, 'PeriodApplied', numcommitmentperiod);
--                    datexpirydate :=GConst.fncXMLExtract(xmlTemp, 'DueDate', datexpirydate);
--                    datapplicationdate:=GConst.fncXMLExtract(xmlTemp, 'ApplicationDate', datapplicationdate);
--                    numusanceperiod:=GConst.fncXMLExtract(xmlTemp, 'LcTenor', numusanceperiod);
--                    INSERT INTO TEMP1 VALUES('charge3.2  datexpirydate '||datexpirydate|| ' datapplicationdate ' || datapplicationdate || ' numusanceperiod ' || numusanceperiod  );
--                         
--                     INSERT INTO TEMP1 VALUES('charge started4 Charge Based on' || recdata1.CHAR_BASED_ON || ' CHAR_PERIOD_TYPE ' || recdata1.CHAR_PERIOD_TYPE  );
--                         if recdata1.CHAR_BASED_ON=34200001 then --commitment period
--                             if recdata1.CHAR_PERIOD_TYPE=23400001 THEN  --days
--                                numdays :=datexpirydate-datapplicationdate + 1 ; --commitmentperiod
--                             elsif recdata1.CHAR_PERIOD_TYPE=23400002 THEN --month
--                                prcgetcompletedmonths( datapplicationdate, datexpirydate + 1,2,nummonths,numdays);  
--                                
--                             end if;  
--                          elsif recdata1.CHAR_BASED_ON=34200002 then --Usance period
--                             if recdata1.CHAR_PERIOD_TYPE=23400001 THEN  --days
--                                numdays :=numusanceperiod ;-- usance period
--                             elsif recdata1.CHAR_PERIOD_TYPE=23400002 THEN --month
--                                nummonths:= floor(numusanceperiod /30);
--                                numdays:=(numusanceperiod-(nummonths *30));
--                             end if; 
--                          elsif recdata1.CHAR_BASED_ON=34299999 then --flat charge
--                               if recdata1.CHAR_TIMING_EVENT=33699999 then 
--                                  if recdata1.CHAR_PERCENT_TYPE=33700001 then --percentage
--                                     numcharge:=(recdata1.CHAR_CHARGES_AMOUNT * numtransactionamt/100); -- + ((recdata1.CHAR_CHARGES_AMOUNT * numtransactionamt/100)*recdata1.CHAR_SERVICE_TAX/100);
--                     --                numservicecharge:=numservicecharge+ ((recdata1.CHAR_CHARGES_AMOUNT * numtransactionamt/100)*recdata1.CHAR_SERVICE_TAX/100);
--                                  ELSE
--                                     numcharge:=recdata1.CHAR_CHARGES_AMOUNT ;--+ (recdata1.CHAR_CHARGES_AMOUNT*recdata1.CHAR_SERVICE_TAX/100);
--                       --              numservicecharge:=numservicecharge+ (recdata1.CHAR_CHARGES_AMOUNT*recdata1.CHAR_SERVICE_TAX/100);
--                                  END IF;
--                                  
--                                   goto data_insert ;
--                               end if;   
--                          end if;
--                           
--                        insert into TEMP1 values ('charge started5 Inside LC Process ' || numdays || ' ' || recdata1.CHAR_CHARGES_AMOUNT  || ' ' || numtransactionamt);
--                        commit;
--                         if recdata1.CHAR_TIMING_EVENT=33600001 then ---actual
--                              if recdata1.CHAR_PERIOD_TYPE=23400001 THEN  --days
--                                   if numdays <=recdata1.CHAR_PERIOD_UPTO then
--                                      if recdata1.CHAR_PERCENT_TYPE=33700001 then --percentage
--
--                                          numchargeamt:=(numdays * recdata1.CHAR_CHARGES_AMOUNT * numtransactionamt/36500 );
--                                        --  numchargeamt:=numcalculatedamount+((numdays-numcaldays)*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/36500 );
--                                       else
--                                            numchargeamt:= recdata1.CHAR_CHARGES_AMOUNT ;
--                                          --  numchargeamt:=numcalculatedamount + recdata1.CHAR_CHARGES_AMOUNT ;
--                                       end if;
--                                     numcharge:=numchargeamt ;--+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100) ;
--                           --          numservicecharge:=numservicecharge+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100);
----                                   else
----                                      ---calculate charge for next slab.
----                                      numcalculatedamount:=numcalculatedamount+ (recdata1.CHAR_PERIOD_UPTO*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/36500) ;
----                                      numcaldays:=numcaldays+ recdata1.CHAR_PERIOD_UPTO ;
--                                      
--                                   end if;
--                                elsif   recdata1.CHAR_PERIOD_TYPE=23400002 THEN --month
--                                     if nummonths <=recdata1.CHAR_PERIOD_UPTO then
--                                        if recdata1.CHAR_PERCENT_TYPE=33700001 then --percentage
--                                            numchargeamt:=nummonths*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/1200 ;
--                                        else
--                                              numchargeamt:=recdata1.CHAR_CHARGES_AMOUNT ;
--                                        end if;
--                                        numcharge:=numchargeamt ; --+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100);
--                           --             numservicecharge:=numservicecharge+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100);
--                                 --- else
--                                      ---calculate charge for next slab.
--                                     end if;
--                                end if;
--                            elsif recdata1.CHAR_TIMING_EVENT=33600002 then ---roundmonth
--                                 -- prcgetcompletedmonths( datapplicationdate, datexpirydate,2,nummonths,numdays); 
--                                  if numdays >0 then
--                                      nummonths:=nummonths+1 ;
--                                  end if;
--                                  if nummonths <=recdata1.CHAR_PERIOD_UPTO then
--                                    --numchargeamt:=fncgetchargeamount(
--                                          insert into temp1 values(numcalculatedamount||'charges for previus slab' ||numcalmonths || '  '||nummonths||'  '||recdata1.CHAR_CHARGES_AMOUNT);
--                                        if recdata1.CHAR_PERCENT_TYPE=33700001 then --percentage
--                                            --  numchargeamt:=nummonths*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/1200 ;
--                                               numchargeamt:=numcalculatedamount + ((nummonths-numcalmonths)*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/1200 );
--                                        else
--                                               -- numchargeamt:=recdata1.CHAR_CHARGES_AMOUNT ;
--                                                numchargeamt:=numcalculatedamount+recdata1.CHAR_CHARGES_AMOUNT ;
--                                        end if;
--                                       -- numcharge:=numchargeamt + (numchargeamt*recdata1.CHAR_SERVICE_TAX/100);
--                                        numcharge:=numchargeamt ;--+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100);
--                          --              numservicecharge:=numservicecharge+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100);
--                                        insert  into temp1 values (numchargeamt||'monthcharge'||nummonths||recdata1.CHAR_ACCOUNT_HEAD||recdata1.CHAR_CHARGES_AMOUNT);
--                                  else
--                                      ---calculate charge for next slab.
--                                        numcalculatedamount:=numcalculatedamount+ (recdata1.CHAR_PERIOD_UPTO*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/1200) ;
--                                        numcalmonths:=numcalmonths+ recdata1.CHAR_PERIOD_UPTO ;
--                                       insert into temp1 values('charges for next slabround month' ||numcalmonths);
--                                   end if;  
--                            elsif recdata1.CHAR_TIMING_EVENT=33600003 then ---roundquarter
--                               -- prcgetcompletedmonths( datapplicationdate, datexpirydate,2,nummonths,numdays); 
--                                  if numdays >0 then
--                                      nummonths:=nummonths+1 ;
--                                  end if;
--                                  numquarters:=ceil(nummonths/3) ;
--                              
--                                  if numquarters <=(recdata1.CHAR_PERIOD_UPTO/3) then
--                                    --numchargeamt:=fncgetchargeamount(
--                                    if recdata1.CHAR_PERCENT_TYPE=33700001 then --percentage
--                                         -- numchargeamt:=numquarters*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/400 ;
--                                          numchargeamt:=numcalculatedamount+((numquarters-(numcalmonths/3))*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/400 );
--                                    else
--                                           -- numchargeamt:=recdata1.CHAR_CHARGES_AMOUNT ;
--                                            numchargeamt:= numcalculatedamount+ recdata1.CHAR_CHARGES_AMOUNT ;
--                                    end if;
--                                    numcharge:=numchargeamt ;--+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100) ;
--                          --          numservicecharge:=numservicecharge+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100);
--                                  else
--                                      ---calculate charge for next slab.
--                                      numcalculatedamount:=numcalculatedamount+ (recdata1.CHAR_PERIOD_UPTO*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/1200) ;
--                                      numcalmonths:=numcalmonths+ recdata1.CHAR_PERIOD_UPTO ;
--                                      insert into temp1 values ('charges for next slab roundquarter' ||numcalmonths);
--                                   end if;  
--                            
--                            end if;
--                      
--                      
--                      
--                      
--                  elsif varEntity in ('PURCHASEBILL','PBDSANCTION', 'PBDLCDREALIZE') then
--                       numcharge:=0;
--                       begin
--                         varreference:=GConst.fncXMLExtract(xmlTemp, '//' || varEntity||'/ROW/ReferenceNumber', varreference,GConst.TYPENODEPATH);  
--                       
--                       exception
--                        when others then
--                          varreference:='0';
--                       end;
--                       begin
--                         numpbdtenor:=GConst.fncXMLExtract(xmlTemp, 'DiscountTenor', numpbdtenor);
--                         numtenortype :=GConst.fncXMLExtract(xmlTemp, 'TenorType', numtenortype);
--                       exception
--                        when others then
--                          numpbdtenor:=0;
--                       end;
--                        if recdata1.char_bill_event =33800001 then
--                          
--                          select nvl(count(*),1) into numcount FROM (SELECT PBDB_INVOICE_NUMBER from tftran082 where PBDB_COMPANY_CODE=numcompany
--                               and PBDB_LOCATION_CODE=numlocation and  PBDB_PBD_REFERENCE=varreference
--                               and PBDB_LIMIT_REFERENCE=varlimitreference and PBDB_RECORD_STATUS not in (10200005,10200006)
--                          group by PBDB_INVOICE_NUMBER );
--       
--                        elsif recdata1.char_bill_event =33800002 then
--                             select nvl(count(*),1) into numcount FROM (SELECT PBDB_SUPPLIER_CODE from tftran082 where PBDB_COMPANY_CODE=numcompany
--                               and PBDB_LOCATION_CODE=numlocation and  PBDB_PBD_REFERENCE=varreference
--                               and PBDB_LIMIT_REFERENCE=varlimitreference and PBDB_RECORD_STATUS not in (10200005,10200006)
--                             group by PBDB_SUPPLIER_CODE) ;
--                          INSERT INTO TEMP1 VALUES ('ALL SUPPLIER'||numcount||varreference);
--                        elsif recdata1.char_bill_event =33899999 then
--                            numcount:=1;
--                        end if;
--                        
--                        if recdata1.CHAR_BASED_ON=34200003 then --pbd tenor
--                             if recdata1.CHAR_PERIOD_TYPE=23400001 THEN  --days
--                                select decode(numtenortype,23400001,numpbdtenor,23400002,numpbdtenor*30,numpbdtenor*365)
--                                 into numdays from dual;
--                             elsif recdata1.CHAR_PERIOD_TYPE=23400002 THEN --month
--                                select decode(numtenortype,23400001,floor(numpbdtenor/30),23400002,numpbdtenor,numpbdtenor*12),
--                                    decode(numtenortype,23400001,(numpbdtenor-(floor(numpbdtenor/30)*30)),0)
--                                 into nummonths,numdays from dual;  
--                                 
--                             end if;  
--                        elsif recdata1.CHAR_BASED_ON=34299999 then --flat charge
--                               if recdata1.CHAR_TIMING_EVENT=33699999 then  
----                                   numcharge:=(recdata1.CHAR_CHARGES_AMOUNT + (recdata1.CHAR_CHARGES_AMOUNT*recdata1.CHAR_SERVICE_TAX/100)) * NUMCOUNT;
----                                   goto data_insert ;
--                              -- end if;   
--                               if recdata1.CHAR_PERCENT_TYPE=33700001 then --percentage
--                                  -- numcharge:=((recdata1.CHAR_CHARGES_AMOUNT * numtransactionamt/100)+ ((recdata1.CHAR_CHARGES_AMOUNT * numtransactionamt/100)*recdata1.CHAR_SERVICE_TAX/100))* NUMCOUNT;
--                                    numcharge:=(recdata1.CHAR_CHARGES_AMOUNT * numtransactionamt/100)* NUMCOUNT;--+ ((recdata1.CHAR_CHARGES_AMOUNT * numtransactionamt/100)*recdata1.CHAR_SERVICE_TAX/100))* NUMCOUNT;
--
--                         --          numservicecharge:=numservicecharge+ (((recdata1.CHAR_CHARGES_AMOUNT * numtransactionamt/100)*recdata1.CHAR_SERVICE_TAX/100)* NUMCOUNT);
--                                else
--                                 --  numcharge:=(recdata1.CHAR_CHARGES_AMOUNT + (recdata1.CHAR_CHARGES_AMOUNT*recdata1.CHAR_SERVICE_TAX/100)) *NUMCOUNT;
--                                   numcharge:=recdata1.CHAR_CHARGES_AMOUNT *NUMCOUNT;--+ (recdata1.CHAR_CHARGES_AMOUNT*recdata1.CHAR_SERVICE_TAX/100)) *NUMCOUNT;
--
--                         --         numservicecharge:=numservicecharge+ (((recdata1.CHAR_CHARGES_AMOUNT )*recdata1.CHAR_SERVICE_TAX/100)* NUMCOUNT);
--   
--                                end if;
--                                  goto data_insert ;
--                               end if;   
--                          end if;
--                           
--                         if recdata1.CHAR_TIMING_EVENT=33600001 then ---actual
--                              if recdata1.CHAR_PERIOD_TYPE=23400001 THEN  --days
--                                   if numdays <=recdata1.CHAR_PERIOD_UPTO then
--                                      if recdata1.CHAR_PERCENT_TYPE=33700001 then --percentage
--                                          numchargeamt:=numdays*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/36500 ;
--                                       else
--                                            numchargeamt:=recdata1.CHAR_CHARGES_AMOUNT ;
--                                       end if;
--                                     numcharge:=numchargeamt ;--+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100) ;
--                           --          numservicecharge:=numservicecharge+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100);
--
--                                 --- else
--                                      ---calculate charge for next slab.
--                                   end if;
--                                elsif   recdata1.CHAR_PERIOD_TYPE=23400002 THEN --month
--                                     if nummonths <=recdata1.CHAR_PERIOD_UPTO then
--                                        if recdata1.CHAR_PERCENT_TYPE=33700001 then --percentage
--                                            numchargeamt:=nummonths*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/1200 ;
--                                        else
--                                              numchargeamt:=recdata1.CHAR_CHARGES_AMOUNT ;
--                                        end if;
--                                        numcharge:=numchargeamt ;--+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100);
--                               --           numservicecharge:=numservicecharge+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100);
--
--                                 --- else
--                                      ---calculate charge for next slab.
--                                     end if;
--                                end if;
--                            elsif recdata1.CHAR_TIMING_EVENT=33600002 then ---roundmonth
--                                 -- prcgetcompletedmonths( datapplicationdate, datexpirydate,2,nummonths,numdays); 
--                                  if numdays >0 then
--                                      nummonths:=nummonths+1 ;
--                                  end if;
--                                  if nummonths <=recdata1.CHAR_PERIOD_UPTO then
--                                    --numchargeamt:=fncgetchargeamount(
--                                    if recdata1.CHAR_PERCENT_TYPE=33700001 then --percentage
--                                          numchargeamt:=nummonths*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/1200 ;
--                                    else
--                                            numchargeamt:=recdata1.CHAR_CHARGES_AMOUNT ;
--                                    end if;
--                                    numcharge:=numchargeamt ;--+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100);
--                           --         numservicecharge:=numservicecharge+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100);
--
--                                 --- else
--                                      ---calculate charge for next slab.
--                                   end if;  
--                            elsif recdata1.CHAR_TIMING_EVENT=33600003 then ---roundquarter
--                               -- prcgetcompletedmonths( datapplicationdate, datexpirydate,2,nummonths,numdays); 
--                                  if numdays >0 then
--                                      nummonths:=nummonths+1 ;
--                                  end if;
--                                  numquarters:=ceil(nummonths/3) ;
--                              
--                                  if numquarters <=recdata1.CHAR_PERIOD_UPTO then
--                                    --numchargeamt:=fncgetchargeamount(
--                                    if recdata1.CHAR_PERCENT_TYPE=33700001 then --percentage
--                                          numchargeamt:=numquarters*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/400 ;
--                                    else
--                                            numchargeamt:=recdata1.CHAR_CHARGES_AMOUNT ;
--                                    end if;
--                                    numcharge:=numchargeamt ;--+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100) ;
--                       --             numservicecharge:=numservicecharge+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100);
--
--                                 --- else
--                                      ---calculate charge for next slab.
--                                   end if;  
--                            
--                            end if; 
--                      
--                        numchargeamt:=numchargeamt*numcount ; --each bill
--                  
--              elsif varEntity in ('BUYERSCREDIT','BUYERSCREDITSANCTION', 'BCCLOSURE','BUYERSCREDITROLLOVER') then
--                INSERT INTO TEMP1 VALUES ('eNTERED iNTO'||numcount||varreference);
--                     numcharge:=0;
--                       begin
--                     --   varreference:=GConst.fncXMLExtract(xmlTemp, '//' || varEntity||'/ROW/ReferenceNumber', varreference,GConst.TYPENODEPATH);  
--                         varreference:=GConst.fncXMLExtract(xmlTemp, '//' || varEntity||'/ROW/BuyersCredit', varreference,GConst.TYPENODEPATH);  
--
--                       
--                       exception
--                        when others then
--                          varreference:='0';
--                       end;
--                       numpbdtenor:=GConst.fncXMLExtract(xmlTemp, 'NoofDays', numpbdtenor);
--                       numtenortype :=23400001;
--                        if recdata1.char_bill_event =33800001 then
--                          
--                          select nvl(count(*),1) into numcount FROM (SELECT BCPO_CONTRACT_NUMBER from tftran046B where BCPO_COMPANY_CODE=numcompany
--                               and  BCPO_BUYERS_CREDIT=varreference
--                               and BCPO_RECORD_STATUS not in (10200005,10200006)
--                            group by BCPO_BUYERS_CREDIT ,BCPO_CONTRACT_NUMBER );
--       
--    
--       
--                        elsif recdata1.char_bill_event =33800002 then
--                             select nvl(count(*),1) into numcount FROM (SELECT ISHP_SUPPLIER_CODE from TFTRAN042,TFTRAN046B 
--                             where BCPO_COMPANY_CODE=numcompany
--                               and BCPO_COMPANY_CODE=ISHP_COMPANY_CODE and  BCPO_BUYERS_CREDIT=varreference
--                               and BCPO_CONTRACT_NUMBER= ISHP_SHIPMENT_NUMBER
--                               and  ISHP_RECORD_STATUS not in (10200005,10200006)
--                               and BCPO_RECORD_STATUS not in (10200005,10200006)
--                             group by ISHP_SUPPLIER_CODE) ;
--                        
--                        elsif recdata1.char_bill_event =33899999 then
--                            numcount:=1;
--                        end if;
--                          INSERT INTO TEMP1 VALUES ('bc tenor'||numcount||varreference || ' No Of Days ' ||  numpbdtenor );
--                        if recdata1.CHAR_BASED_ON=34200004 then --bc tenor
--                             if recdata1.CHAR_PERIOD_TYPE=23400001 THEN  --days
--                                select decode(numtenortype,23400001,numpbdtenor,23400002,numpbdtenor*30,numpbdtenor*360)
--                                 into numdays from dual;
--                             elsif recdata1.CHAR_PERIOD_TYPE=23400002 THEN --month
--                                select decode(numtenortype,23400001,floor(numpbdtenor/30),23400002,numpbdtenor,numpbdtenor*12),
--                                    decode(numtenortype,23400001,(numpbdtenor-(floor(numpbdtenor/30)*30)),0)
--                                 into nummonths,numdays from dual;  
--                                 
--                             end if;  
--                        elsif recdata1.CHAR_BASED_ON=34299999 then --flat charge
--                               if recdata1.CHAR_TIMING_EVENT=33699999 then  
----                                   numcharge:=(recdata1.CHAR_CHARGES_AMOUNT + (recdata1.CHAR_CHARGES_AMOUNT*recdata1.CHAR_SERVICE_TAX/100)) * NUMCOUNT;
----                                   goto data_insert ;
--                              -- end if;   
--                               if recdata1.CHAR_PERCENT_TYPE=33700001 then --percentage
--                                  -- numcharge:=((recdata1.CHAR_CHARGES_AMOUNT * numtransactionamt/100)+ ((recdata1.CHAR_CHARGES_AMOUNT * numtransactionamt/100)*recdata1.CHAR_SERVICE_TAX/100))* NUMCOUNT;
--                                     numcharge:=(recdata1.CHAR_CHARGES_AMOUNT * numtransactionamt/100)* NUMCOUNT;
--                        --             numservicecharge:=numservicecharge+ (((recdata1.CHAR_CHARGES_AMOUNT * numtransactionamt/100)*recdata1.CHAR_SERVICE_TAX/100)* NUMCOUNT);
--
--                                else
--                                  -- numcharge:=(recdata1.CHAR_CHARGES_AMOUNT + (recdata1.CHAR_CHARGES_AMOUNT*recdata1.CHAR_SERVICE_TAX/100)) *NUMCOUNT;
--                                   numcharge:=recdata1.CHAR_CHARGES_AMOUNT  *NUMCOUNT;
--
--                         --          numservicecharge:=numservicecharge+ ((recdata1.CHAR_CHARGES_AMOUNT *recdata1.CHAR_SERVICE_TAX/100)* NUMCOUNT);
--
--                                end if;
--                                  goto data_insert ;
--                               end if;   
--                          end if;
--                         INSERT INTO TEMP1 VALUES ('Timing Event '||recdata1.CHAR_TIMING_EVENT|| ' Period Type ' || recdata1.CHAR_PERIOD_TYPE || ' Period Upto ' ||  recdata1.CHAR_PERIOD_UPTO || ' CHAR_PERCENT_TYPE ' ||  recdata1.CHAR_PERCENT_TYPE );  
--                         if recdata1.CHAR_TIMING_EVENT=33600001 then ---actual
--                              if recdata1.CHAR_PERIOD_TYPE=23400001 THEN  --days
--                              INSERT INTO TEMP1 VALUES ('Step 1.2. ' || numdays  ||  ' Period Upto ' || recdata1.CHAR_PERIOD_UPTO );  
--                                   if numdays <=recdata1.CHAR_PERIOD_UPTO then
--                                    INSERT INTO TEMP1 VALUES ('Step 1.3. ' || numchargeamt );  
--                                      if recdata1.CHAR_PERCENT_TYPE=33700001 then --percentage
--                                          numchargeamt:=numdays*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/36000 ;
--                                       else
--                                            numchargeamt:=recdata1.CHAR_CHARGES_AMOUNT ;
--                                       end if;
--                                     numcharge:=numchargeamt; -- + (numchargeamt*recdata1.CHAR_SERVICE_TAX/100) ;
--                          --           numservicecharge:=numservicecharge+ ((numchargeamt )*recdata1.CHAR_SERVICE_TAX/100);
--                                      INSERT INTO TEMP1 VALUES (' Charge Amount ' || numchargeamt );  
--                     
--                                 --- else
--                                      ---calculate charge for next slab.
--                                   end if;
--                                elsif   recdata1.CHAR_PERIOD_TYPE=23400002 THEN --month
--                                     if nummonths <=recdata1.CHAR_PERIOD_UPTO then
--                                        if recdata1.CHAR_PERCENT_TYPE=33700001 then --percentage
--                                            numchargeamt:=nummonths*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/1200 ;
--                                        else
--                                              numchargeamt:=recdata1.CHAR_CHARGES_AMOUNT ;
--                                        end if;
--                                        numcharge:=numchargeamt ;--+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100);
--                               --         numservicecharge:=numservicecharge+ ((numchargeamt )*recdata1.CHAR_SERVICE_TAX/100);
--                                 --- else
--                                      ---calculate charge for next slab.
--                                     end if;
--                                end if;
--                            elsif recdata1.CHAR_TIMING_EVENT=33600002 then ---roundmonth
--                                 -- prcgetcompletedmonths( datapplicationdate, datexpirydate,2,nummonths,numdays); 
--                                  if numdays >0 then
--                                      nummonths:=nummonths+1 ;
--                                  end if;
--                                  if nummonths <=recdata1.CHAR_PERIOD_UPTO then
--                                    --numchargeamt:=fncgetchargeamount(
--                                    if recdata1.CHAR_PERCENT_TYPE=33700001 then --percentage
--                                          numchargeamt:=nummonths*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/1200 ;
--                                    else
--                                            numchargeamt:=recdata1.CHAR_CHARGES_AMOUNT ;
--                                    end if;
--                                    numcharge:=numchargeamt ;--+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100);
--                          --          numservicecharge:=numservicecharge+ ((numchargeamt )*recdata1.CHAR_SERVICE_TAX/100);
--                                 --- else
--                                      ---calculate charge for next slab.
--                                   end if;  
--                            elsif recdata1.CHAR_TIMING_EVENT=33600003 then ---roundquarter
--                               -- prcgetcompletedmonths( datapplicationdate, datexpirydate,2,nummonths,numdays); 
--                                  if numdays >0 then
--                                      nummonths:=nummonths+1 ;
--                                  end if;
--                                  numquarters:=ceil(nummonths/3) ;
--                              
--                                  if numquarters <=recdata1.CHAR_PERIOD_UPTO then
--                                    --numchargeamt:=fncgetchargeamount(
--                                    if recdata1.CHAR_PERCENT_TYPE=33700001 then --percentage
--                                          numchargeamt:=numquarters*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/400 ;
--                                    else
--                                            numchargeamt:=recdata1.CHAR_CHARGES_AMOUNT ;
--                                    end if;
--                                    numcharge:=numchargeamt ;--+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100) ;
--                         --           numservicecharge:=numservicecharge+ ((numchargeamt )*recdata1.CHAR_SERVICE_TAX/100);
--                                 --- else
--                                      ---calculate charge for next slab.
--                                   end if;  
--                            
--                            end if; 
--                    insert into temp1 values ('VarEntity ' || varEntity || ' Calc Charge Amount '|| numchargeamt || ' Transaction Amount '|| numtransactionamt || ' NUMCOUNT ' || NUMCOUNT);
--     
--                        numchargeamt:=numchargeamt*numcount ; --each bill
--                        
--              elsif varEntity in ('PACKINGCREDITSANCTION','PSCFCLOAN','PSLLOAN','IMPORTREALIZE','BILLREALISATION','BANKGUARANTEE','FOREIGNREMITTANCE','IMPORTADVICE','EXPORTADVANCE','BANKCONFIRMATION1') then
--              
--              insert into temp1 values ('VarEntity ' || varEntity || ' Charge Amount '|| recdata1.CHAR_CHARGES_AMOUNT || ' Transaction Amount '|| numtransactionamt || ' NUMCOUNT ' || NUMCOUNT);
--                 numcharge:=0;
----                       begin
----                         varreference:=GConst.fncXMLExtract(xmlTemp, '//' || varEntity||'/ROW/PkgcreditNumber', varreference,GConst.TYPENODEPATH);  
----
----                       
----                       exception
----                        when others then
----                          varreference:='0';
----                       end;
--                     begin
--                       numpbdtenor:=GConst.fncXMLExtract(xmlTemp, 'NoofDays', numpbdtenor);
--                     exception
--                      when others then
--                        numpbdtenor:=90; --default value
--                     end ;
--                       numtenortype :=23400001;
--                        if recdata1.char_bill_event =33800001 then
--                          
----                          select nvl(count(*),1) into numcount FROM (SELECT BCPO_CONTRACT_NUMBER from tftran046B where BCPO_COMPANY_CODE=numcompany
----                               and  BCPO_BUYERS_CREDIT=varreference
----                               and BCPO_RECORD_STATUS not in (10200005,10200006)
----                            group by BCPO_BUYERS_CREDIT ,BCPO_CONTRACT_NUMBER );
--                           numcount:=1 ;
--    
--       
--                        elsif recdata1.char_bill_event =33800002 then
----                             select nvl(count(*),1) into numcount FROM (SELECT ISHP_SUPPLIER_CODE from TFTRAN042,TFTRAN046B 
----                             where BCPO_COMPANY_CODE=numcompany
----                               and BCPO_COMPANY_CODE=ISHP_COMPANY_CODE and  BCPO_BUYERS_CREDIT=varreference
----                               and BCPO_CONTRACT_NUMBER= ISHP_SHIPMENT_NUMBER
----                               and  ISHP_RECORD_STATUS not in (10200005,10200006)
----                               and BCPO_RECORD_STATUS not in (10200005,10200006)
----                             group by ISHP_SUPPLIER_CODE) ;
--                           numcount:=1;
--                          INSERT INTO TEMP1 VALUES ('ALL SUPPLIER'||numcount||varreference);
--                        elsif recdata1.char_bill_event =33899999 then
--                            numcount:=1;
--                        end if;
--                        
--                        if recdata1.CHAR_BASED_ON=34200004 then --bc tenor
--                             if recdata1.CHAR_PERIOD_TYPE=23400001 THEN  --days
--                                select decode(numtenortype,23400001,numpbdtenor,23400002,numpbdtenor*30,numpbdtenor*360)
--                                 into numdays from dual;
--                             elsif recdata1.CHAR_PERIOD_TYPE=23400002 THEN --month
--                                select decode(numtenortype,23400001,floor(numpbdtenor/30),23400002,numpbdtenor,numpbdtenor*12),
--                                    decode(numtenortype,23400001,(numpbdtenor-(floor(numpbdtenor/30)*30)),0)
--                                 into nummonths,numdays from dual;  
--                                 
--                             end if;  
--                        elsif recdata1.CHAR_BASED_ON=34299999 then --flat charge
--                               if recdata1.CHAR_TIMING_EVENT=33699999 then  
----                                   numcharge:=(recdata1.CHAR_CHARGES_AMOUNT + (recdata1.CHAR_CHARGES_AMOUNT*recdata1.CHAR_SERVICE_TAX/100)) * NUMCOUNT;
----                                   goto data_insert ;
--                              -- end if;   
--                               if recdata1.CHAR_PERCENT_TYPE=33700001 then --percentage
--                                  -- numcharge:=((recdata1.CHAR_CHARGES_AMOUNT * numtransactionamt/100)+ ((recdata1.CHAR_CHARGES_AMOUNT * numtransactionamt/100)*recdata1.CHAR_SERVICE_TAX/100))* NUMCOUNT;
--                                    numcharge:=(recdata1.CHAR_CHARGES_AMOUNT * numtransactionamt/100)* NUMCOUNT;
--
--                         --          numservicecharge:=numservicecharge+ (((recdata1.CHAR_CHARGES_AMOUNT * numtransactionamt/100)*recdata1.CHAR_SERVICE_TAX/100)* NUMCOUNT);
--
--                                else
--                                --   numcharge:=(recdata1.CHAR_CHARGES_AMOUNT + (recdata1.CHAR_CHARGES_AMOUNT*recdata1.CHAR_SERVICE_TAX/100)) *NUMCOUNT;
--                                    numcharge:=recdata1.CHAR_CHARGES_AMOUNT  *NUMCOUNT;
--
--                           --        numservicecharge:=numservicecharge+ ((recdata1.CHAR_CHARGES_AMOUNT *recdata1.CHAR_SERVICE_TAX/100)* NUMCOUNT);
--
--                                end if;
--                                  goto data_insert ;
--                               end if;   
--                          end if;
--                           
--                         if recdata1.CHAR_TIMING_EVENT=33600001 then ---actual
--                              if recdata1.CHAR_PERIOD_TYPE=23400001 THEN  --days
--                                 --  if numdays <=recdata1.CHAR_PERIOD_UPTO then -- Feel this is redundent so we are commenting for now 
--                                      if recdata1.CHAR_PERCENT_TYPE=33700001 then --percentage
--                                          numchargeamt:=numdays*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/36000 ;
--                                       else
--                                            numchargeamt:=recdata1.CHAR_CHARGES_AMOUNT ;
--                                       end if;
--                                     numcharge:=numchargeamt ;--+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100) ;
--                          --           numservicecharge:=numservicecharge+ ((numchargeamt )*recdata1.CHAR_SERVICE_TAX/100);
--
--                                 --- else
--                                      ---calculate charge for next slab.
--                                --   end if;
--                                elsif   recdata1.CHAR_PERIOD_TYPE=23400002 THEN --month
--                                     if nummonths <=recdata1.CHAR_PERIOD_UPTO then
--                                        if recdata1.CHAR_PERCENT_TYPE=33700001 then --percentage
--                                            numchargeamt:=nummonths*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/1200 ;
--                                        else
--                                              numchargeamt:=recdata1.CHAR_CHARGES_AMOUNT ;
--                                        end if;
--                                        numcharge:=numchargeamt ;--+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100);
--                              --          numservicecharge:=numservicecharge+ ((numchargeamt )*recdata1.CHAR_SERVICE_TAX/100);
--                                 --- else
--                                      ---calculate charge for next slab.
--                                     end if;
--                                end if;
--                            elsif recdata1.CHAR_TIMING_EVENT=33600002 then ---roundmonth
--                                 -- prcgetcompletedmonths( datapplicationdate, datexpirydate,2,nummonths,numdays); 
--                                  if numdays >0 then
--                                      nummonths:=nummonths+1 ;
--                                  end if;
--                                  if nummonths <=recdata1.CHAR_PERIOD_UPTO then
--                                    --numchargeamt:=fncgetchargeamount(
--                                    if recdata1.CHAR_PERCENT_TYPE=33700001 then --percentage
--                                          numchargeamt:=nummonths*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/1200 ;
--                                    else
--                                            numchargeamt:=recdata1.CHAR_CHARGES_AMOUNT ;
--                                    end if;
--                                    numcharge:=numchargeamt ;--+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100);
--                           --         numservicecharge:=numservicecharge+ ((numchargeamt )*recdata1.CHAR_SERVICE_TAX/100);
--                                 --- else
--                                      ---calculate charge for next slab.
--                                   end if;  
--                            elsif recdata1.CHAR_TIMING_EVENT=33600003 then ---roundquarter
--                               -- prcgetcompletedmonths( datapplicationdate, datexpirydate,2,nummonths,numdays); 
--                                  if numdays >0 then
--                                      nummonths:=nummonths+1 ;
--                                  end if;
--                                  numquarters:=ceil(nummonths/3) ;
--                              
--                                  if numquarters <=recdata1.CHAR_PERIOD_UPTO then
--                                    --numchargeamt:=fncgetchargeamount(
--                                    if recdata1.CHAR_PERCENT_TYPE=33700001 then --percentage
--                                          numchargeamt:=numquarters*recdata1.CHAR_CHARGES_AMOUNT*numtransactionamt/400 ;
--                                    else
--                                            numchargeamt:=recdata1.CHAR_CHARGES_AMOUNT ;
--                                    end if;
--                                    numcharge:=numchargeamt ;--+ (numchargeamt*recdata1.CHAR_SERVICE_TAX/100) ;
--                         --           numservicecharge:=numservicecharge+ ((numchargeamt )*recdata1.CHAR_SERVICE_TAX/100);
--                                 --- else
--                                      ---calculate charge for next slab.
--                                   end if;  
--                            
--                            end if; 
--                      
--                        numchargeamt:=numchargeamt*numcount ; --each bill
--              END IF;
--                INSERT INTO TEMP1 VALUES (' Step 10: Charge Amount '||numcharge|| ' Min Amount ' || numminamount || ' Max Amount ' || nummaxamount ); 
               -- numchargeamt:=0;
            end loop;
            <<data_insert>>
                   if numcharge >0 then
                      if numminamount > numcharge then
                          numcharge:=numminamount;
                      elsif nummaxamount < numcharge then
                          numcharge:=nummaxamount;
                      end if;
                   end if;
                  insert into trtemp015D (CHGC_BANK_CODE,CHGC_LIMIT_REFERENCE,CHGC_CHARGE_TYPE,CHGC_CHARGE_EVENT,CHGC_CHARGE_AMOUNT) 
                          values (recdata.CHGA_BANK_CODE,recdata.CHGA_SANCTION_APPLIED,recdata.CHGA_CHARGE_TYPE,
                                  recdata.CHGA_CHARGING_EVENT ,nvl(numcharge,0)) ;
            <<Process_End>>
                errorcode:=0;
        exception 
          when others then
              insert into trtemp015D (CHGC_BANK_CODE,CHGC_LIMIT_REFERENCE,CHGC_CHARGE_TYPE,CHGC_CHARGE_EVENT,CHGC_CHARGE_AMOUNT) 
                          values (recdata.CHGA_BANK_CODE,recdata.CHGA_SANCTION_APPLIED,recdata.CHGA_CHARGE_TYPE,
                                  recdata.CHGA_CHARGING_EVENT ,0) ;
        end;
        ---for service charges
        limitref:=recdata.CHGA_SANCTION_APPLIED;
        chgevent:=recdata.CHGA_CHARGING_EVENT ;
    end loop;
    
    
    ---- Service tax calcualtion on Foreign rate conversion 
    -- for this kind of transactions we will be having the nodes FORWARDSETTLEMENT or CASHSETTLEMENT or Both 
    docFinal := xmlDom.newDomDocument(xmlTemp);
    nodFinal := xmlDom.makeNode(docFinal);
    
--     IF numservicecharge !=0  THEN 
--        
--        numSWATCHBHARATCharge := ((numservicecharge/0.15) * 0.005);
--        numKRISHIKALYANCharge := ((numservicecharge/0.15) * 0.005);
--        numservicecharge := ((numservicecharge/0.15)*0.14);
--     else
--       numSWATCHBHARATCharge :=0;
--       numKRISHIKALYANCharge:=0;
--     END IF;
       insert into temp2  values ('Step 20 :  Selecting Total Charge Amount '); commit;
       select sum(CHGC_CHARGE_AMOUNT) into numChargeTotalamount
         from trtemp015D;
        insert into temp2  values ('Step 20.1 :  Calcualting the Tax for the  ' || numChargeTotalamount); commit;  
  
       if numChargeTotalamount>0 then
       
        insert into temp2  values ('Step 20.2 : CGST Amount on  ' || numChargeTotalamount); commit;  
        insert into trtemp015D (CHGC_BANK_CODE,CHGC_LIMIT_REFERENCE,CHGC_CHARGE_TYPE,CHGC_CHARGE_EVENT,CHGC_CHARGE_AMOUNT) 
                          values (numbankcode,limitref,24900062, chgevent ,nvl(numChargeTotalamount*0.09,0)) ;
                          
        insert into temp2 values ('Step 20.2 : SGST Amount on  ' || numChargeTotalamount); commit;  
        
        insert into trtemp015D (CHGC_BANK_CODE,CHGC_LIMIT_REFERENCE,CHGC_CHARGE_TYPE,CHGC_CHARGE_EVENT,CHGC_CHARGE_AMOUNT) 
                  values (numbankcode,limitref,24900063, chgevent ,nvl(numChargeTotalamount*0.09,0)) ;

       end if;

              
        insert into temp2  values ('Foreign Exch GST on Before Forex Conversion ' || numtransactionamt); commit;
--        numsanctionamt :=0;
--        numServiceTemp:=0;
--        varXPath := '//FORWARDSETTLEMENT/ROW';
--        numsanctionamt:=0;

--        nodTemp := xslProcessor.SELECTSINGLENO  DE(nodFinal,varXPath || '/ReverseAmount');
--        
--       IF(DBMS_XMLDOM.ISNULL(nodTemp) = FALSE) then
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--        numSub := xmlDom.getLength(nlsTemp);
--        
--            for numSub in 0..xmlDom.getLength(nlsTemp) -1
--            Loop
--             insert into temp1  values (' FORWARDSETTLEMENT Server Tax Calcuation ');
--             commit;
--        
--              nodTemp := xmlDom.Item(nlsTemp, numSub);
--              nmpTemp:= xmlDom.getAttributes(nodTemp);
--              nodTemp := xmlDom.Item(nmpTemp, 0);
--              numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
--              varTemp := varXPath || '[@NUM="' || numTemp || '"]/';
--            --varTemp := varXPath || '/';
--              varTemp1 := varTemp || 'ReverseAmount';
--              numtransactionamt := GConst.fncXMLExtract(xmlTemp,varTemp1,numtransactionamt, Gconst.TYPENODEPATH);
--              varTemp1 := varTemp || 'FinalRate';
--              numrate := GConst.fncXMLExtract(xmlTemp,varTemp1,numtransactionamt, Gconst.TYPENODEPATH);
--              numsanctionamt:=  round(numtransactionamt * numrate,0);
        numForeignExchangeTaxTotal:=0;
        numForeignExchangeTaxTemp:=0;
--         if ((numcurrency !=20500003) and (numcurrency !=20599999))  then   
--            insert into temp1  values (' Step 30 Tax Calcuation For Forex Conversion '
--               || numtransactionamt  || ' and Rate ' || numrate || ' Total Amount '|| numsanctionamt); commit;  
--              select (case when (numtransactionamt <=100000) then
--                       ((numtransactionamt * 0.01)*0.18)
--                      when numtransactionamt between 100001 and 1000000 then
--                        ((100000*0.01)*0.18) + (((numtransactionamt-100000)*0.005)*0.18)
--                      when numtransactionamt > 1000000 then
--                        (((100000*0.01)*0.18) + (((900000)*0.005)*0.18) +
--                        (((numtransactionamt-1000000)*0.001)*0.18)) end)
--                    into numForeignExchangeTaxTemp
--                 from dual;
--                 numForeignExchangeTaxTotal:=numForeignExchangeTaxTotal+ numForeignExchangeTaxTemp;
--         end if;
--     --- CGST        
--              select char_charges_amount,Char_min_amount,char_max_amount,
--                     char_service_tax,CHAR_AMOUNT_FROM
--                into Numcharge,numminamount,nummaxamount,numServiceTax,numAmountFrom
--                from tftran015D
--                where CHAR_ACCOUNT_HEAD=24900090 -- service Tax
--                and char_product_type=34000003  -- Foreign Rate Conversion Type
--                and numsanctionamt between char_amount_from and char_amount_upto
--                and char_record_status not in (10200005,10200006);
--             
--             numcalculatedamount :=  (Numcharge +   ((numsanctionamt-numAmountFrom) *  (numServiceTax /100)));
--             
--              if numcalculatedamount >= nummaxamount then
--                numcalculatedamount:=nummaxamount;
--             end if;
--             numservicecharge:= numservicecharge+numcalculatedamount;
--             
--                insert into temp1  values (' FORWARDSETTLEMENT Server Tax Paramaters ' || 'Numcharge: ' ||Numcharge ||
--                   'numminamount: ' || numminamount || ' nummaxamount : '|| nummaxamount ||
--                   ' numServiceTax ' || numServiceTax ||  ' numsanctionamt : ' || numsanctionamt);
--                insert into temp1  values (' FORWARDSETTLEMENT Server Tax Amount ' || numcalculatedamount);
--             commit;
--        -- Swatch Bharath Cess     
--               numcalculatedamount:=0;
--              select char_charges_amount,Char_min_amount,char_max_amount,
--                     char_service_tax,CHAR_AMOUNT_FROM
--                into Numcharge,numminamount,nummaxamount,numServiceTax,numAmountFrom
--                from tftran015D
--                where CHAR_ACCOUNT_HEAD=24900091 -- service Tax
--                and char_product_type=34000003  -- Foreign Rate Conversion Type
--                and numsanctionamt between char_amount_from and char_amount_upto
--                and char_record_status not in (10200005,10200006);
--             
--             numcalculatedamount :=   (Numcharge +   ((numsanctionamt-numAmountFrom) *  (numServiceTax /100)));
--             
--                insert into temp1  values (' FORWARDSETTLEMENT Swatch Bharath Paramaters ' || 'Numcharge: ' ||Numcharge ||
--                   'numminamount: ' || numminamount || ' nummaxamount : '|| nummaxamount ||
--                   ' numServiceTax ' || numServiceTax ||  ' numsanctionamt : ' || numsanctionamt);
--                insert into temp1  values (' FORWARDSETTLEMENT Server Tax Amount ' || numcalculatedamount);
--             commit;
--             
--           
--               
--              if numcalculatedamount >= nummaxamount then
--                numcalculatedamount:=nummaxamount;
--             end if;
--             
--            numSWATCHBHARATCharge := numSWATCHBHARATCharge+numcalculatedamount;
 
--         -- KRISHIKALYAN Cess     
--             numcalculatedamount:=0;
--              select char_charges_amount,Char_min_amount,char_max_amount,
--                     char_service_tax,CHAR_AMOUNT_FROM
--                into Numcharge,numminamount,nummaxamount,numServiceTax,numAmountFrom
--                from tftran015D
--                where CHAR_ACCOUNT_HEAD=24900064-- service Tax
--                and char_product_type=34000003  -- Foreign Rate Conversion Type
--                and numsanctionamt between char_amount_from and char_amount_upto
--                and char_record_status not in (10200005,10200006);
--             
--             numcalculatedamount :=    (Numcharge +   ((numsanctionamt-numAmountFrom) *  (numServiceTax /100)));
--             
--                insert into temp1  values (' FORWARDSETTLEMENT KRISHIKALYAN Paramaters ' || 'Numcharge: ' ||Numcharge ||
--                   'numminamount: ' || numminamount || ' nummaxamount : '|| nummaxamount ||
--                   ' numServiceTax ' || numServiceTax ||  ' numsanctionamt : ' || numsanctionamt);
--                insert into temp1  values (' FORWARDSETTLEMENT Server Tax Amount ' || numcalculatedamount);
--             commit;
--             
--           --  numcalculatedamount :=(numAmountFrom-numminamount) +   (numsanctionamt *  (numServiceTax /100));
--             if numcalculatedamount >= nummaxamount then
--                numcalculatedamount:=nummaxamount;
--             end if;
--             
--            numKRISHIKALYANCharge := numKRISHIKALYANCharge+numcalculatedamount;
 
 
-- 
--            end loop;
--        end if;
--        
--      varXPath := '//CASHSETTLEMENT';
--      nodTemp := xslProcessor.SELECTSINGLENODE(nodFinal,varXPath || '/CashAmount');
--      IF(DBMS_XMLDOM.ISNULL(nodTemp) = FALSE) then   
--          nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--          numSub := xmlDom.getLength(nlsTemp);
--          for numSub in 0..xmlDom.getLength(nlsTemp) -1
--          Loop 
--              nodTemp := xmlDom.Item(nlsTemp, numSub);
--              nmpTemp:= xmlDom.getAttributes(nodTemp);
--              nodTemp := xmlDom.Item(nmpTemp, 0);
--              numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
--              varTemp := varXPath || '/';
--              varTemp1 := varTemp || 'CashAmount';
--              numtransactionamt := GConst.fncXMLExtract(xmlTemp,varTemp1,numtransactionamt, Gconst.TYPENODEPATH);
--              varTemp1 := varTemp || 'CashRate';
--              numrate := GConst.fncXMLExtract(xmlTemp,varTemp1,numtransactionamt, Gconst.TYPENODEPATH);
--              numsanctionamt:= numsanctionamt + round(numtransactionamt * numrate,0);
--              
--                       insert into temp1  values (' Step 30 Tax Calcuation For Forex Conversion '
--               || numtransactionamt  || ' and Rate ' || numrate || ' Total Amount '|| numsanctionamt); commit;  
--               
--             select (case when (numsanctionamt <=100000) then
--                       ((numsanctionamt * 0.01)*0.18)
--                     when numsanctionamt between 100001 and 1000000 then
--                        ((100000*0.01)*0.18) + (((numsanctionamt-100000)*0.005)*0.18)
--                     when numsanctionamt > 1000000 then
--                        (((100000*0.01)*0.18) + (((900000)*0.005)*0.18) +
--                        (((numsanctionamt-1000000)*0.001)*0.18)) end)
--                    into numForeignExchangeTaxTemp
--                 from dual;
--                 numForeignExchangeTaxTotal:=numForeignExchangeTaxTotal+ numForeignExchangeTaxTemp;    
--          end loop;
--     end if;

   
--     -- CGST   
--             begin
--                select char_charges_amount,Char_min_amount,char_max_amount,
--                       char_service_tax,CHAR_AMOUNT_FROM
--                   into Numcharge,numminamount,nummaxamount,numServiceTax,numAmountFrom
--                  from tftran015D
--                  where CHAR_ACCOUNT_HEAD=24900090 -- CGST
--                  and char_product_type=34099999  -- Foreign Rate Conversion Type
--                  and numsanctionamt between char_amount_from and char_amount_upto
--                  and char_record_status not in (10200005,10200006);
--              exception 
--                when no_Data_found then 
--                numServiceTax:=0.09;
--              end;
--              
--               numcalculatedamount :=  (Numcharge +   ((numsanctionamt-numAmountFrom) *  (numServiceTax /100)));
--               
--                if numcalculatedamount >= nummaxamount then
--                  numcalculatedamount:=nummaxamount;
--               end if;
--               numservicecharge:= numservicecharge+numcalculatedamount;
--               
--                  insert into temp1  values (' CASHSETTLEMENT Server Tax Paramaters ' || 'Numcharge: ' ||Numcharge ||
--                     'numminamount: ' || numminamount || ' nummaxamount : '|| nummaxamount ||
--                     ' numServiceTax ' || numServiceTax ||  ' numsanctionamt : ' || numsanctionamt);
--                  insert into temp1  values (' CASHSETTLEMENT Server Tax Amount ' || numcalculatedamount);
--               commit;
--          --SGST
--                numcalculatedamount:=0; 
--            begin
--                select char_charges_amount,Char_min_amount,char_max_amount,
--                       char_service_tax,CHAR_AMOUNT_FROM
--                  into Numcharge,numminamount,nummaxamount,numServiceTax,numAmountFrom
--                  from tftran015D
--                  where CHAR_ACCOUNT_HEAD=24900091 -- CGST
--                  and char_product_type=34099999  -- Foreign Rate Conversion Type
--                  and numsanctionamt between char_amount_from and char_amount_upto
--                  and char_record_status not in (10200005,10200006);
--            exception
--              when no_Data_found then
--               numServiceTax :=0.09;
--            end;
--                numcalculatedamount :=  (Numcharge +   ((numsanctionamt-numAmountFrom) *  (numServiceTax /100)));
--               
--                  insert into temp1  values (' CASHSETTLEMENT Swatch Bharath Paramaters ' || 'Numcharge: ' ||Numcharge ||
--                     'numminamount: ' || numminamount || ' nummaxamount : '|| nummaxamount ||
--                     ' numServiceTax ' || numServiceTax ||  ' numsanctionamt : ' || numsanctionamt);
--                  insert into temp1  values (' CASHSETTLEMENT Swatch Bharath Server Tax Amount ' || numcalculatedamount);
--               commit;
--               
             
                 
                if numcalculatedamount >= nummaxamount then
                  numcalculatedamount:=nummaxamount;
               end if;
--               
--              numSWATCHBHARATCharge := numSWATCHBHARATCharge+numcalculatedamount;
--              numcalculatedamount:=0;
--           -- KRISHIKALYAN Cess     
--               
--                select char_charges_amount,Char_min_amount,char_max_amount,
--                       char_service_tax,CHAR_AMOUNT_FROM
--                  into Numcharge,numminamount,nummaxamount,numServiceTax,numAmountFrom
--                  from tftran015D
--                  where CHAR_ACCOUNT_HEAD=24900064-- service Tax
--                  and char_product_type=34000003  -- Foreign Rate Conversion Type
--                  and numsanctionamt between char_amount_from and char_amount_upto
--                  and char_record_status not in (10200005,10200006);
--               
--                  numcalculatedamount :=  (Numcharge +   ((numsanctionamt-numAmountFrom) *  (numServiceTax /100)));
--                  
--                  insert into temp1  values (' CASHSETTLEMENT KRISHIKALYAN Paramaters ' || 'Numcharge: ' ||Numcharge ||
--                     'numminamount: ' || numminamount || ' nummaxamount : '|| nummaxamount ||
--                     ' numServiceTax ' || numServiceTax ||  ' numsanctionamt : ' || numsanctionamt);
--                  insert into temp1  values (' CASHSETTLEMENT KRISHIKALYAN Server Tax Amount ' || numcalculatedamount);
--               commit;
--               
--             
--               if numcalculatedamount >= nummaxamount then
--                  numcalculatedamount:=nummaxamount;
--               end if;
--               
--              numKRISHIKALYANCharge := numKRISHIKALYANCharge+numcalculatedamount;
              
              
--    -- numservicecharge:= numservicecharge+numServiceTemp;    
     if numForeignExchangeTaxTotal >0 then
        insert into trtemp015D (CHGC_BANK_CODE,CHGC_LIMIT_REFERENCE,CHGC_CHARGE_TYPE,CHGC_CHARGE_EVENT,CHGC_CHARGE_AMOUNT) 
                          values (numbankcode,limitref,24900094, chgevent ,nvl(numForeignExchangeTaxTotal,0)) ;
     end if;
--     
--      if numSWATCHBHARATCharge >0 then
--        insert into trtemp015D (CHGC_BANK_CODE,CHGC_LIMIT_REFERENCE,CHGC_CHARGE_TYPE,CHGC_CHARGE_EVENT,CHGC_CHARGE_AMOUNT) 
--                          values (numbankcode,limitref,24900091, chgevent ,nvl(numSWATCHBHARATCharge,0)) ;
--     end if;
--     
--      if numKRISHIKALYANCharge >0 then
--        insert into trtemp015D (CHGC_BANK_CODE,CHGC_LIMIT_REFERENCE,CHGC_CHARGE_TYPE,CHGC_CHARGE_EVENT,CHGC_CHARGE_AMOUNT) 
--                          values (numbankcode,limitref,24900064, chgevent ,nvl(numKRISHIKALYANCharge,0)) ;
--     end if;
     


    errorcode:=0;
exception 
when others then
errorcode:= 1;
varerror := varerror || sqlerrm ;
insert into temp2 values (varerror ); commit;
raise_application_error(-20100 ,varError);
end prcgetchargeamount;
end pkgForexProcess;
/