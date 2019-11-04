CREATE OR REPLACE PACKAGE BODY "TEST_VSTSRedgate"."PKGRISKMONITORING" as

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
    numTemp       number(25,6);
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
    datToday := trunc(AsonDate);

    varOperation := 'Inserting outstanding deals';
    numError := fncRiskPopulate(AsonDate, DealType);
    dbms_output.put_line('Risk over, status: ' || numError);

    if numError != 0 then
      return numError;
    end if;
   
    delete from trtran011;
    
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

    varOperation := 'Insert Gap Violation';
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


    varOperation := 'Checking Day Light Limit for all deals';
    select risk_risk_reference, risk_limit_usd, risk_stake_holder,
      risk_action_taken, rprm_gross_net
      into varReference, numLimit, varUserID, numAction, numGrossNet
      from trsystem012 a, trsystem011
      where rprm_risk_type = risk_risk_type
      and risk_risk_type = GConst.RISKDAYLIGHT
      and risk_cross_currency = GConst.OPTIONNO
      and risk_effective_date =
      (select max(risk_effective_date)
        from trsystem012 b
        where a.risk_company_code = b.risk_company_code
        and a.risk_risk_type = b.risk_risk_type
        and a.risk_effective_date <= AsonDate);

    if numAction in (GConst.RISKACTSMS, GConst.RISKACTEMAIL) then
      select  user_mobile_phone, user_email_id
        into varMobile, varEmailID
        from trsystem022
        where user_user_id = varUserID;
    else
      varMobile := '';
      varEmailID := '';
    end if;

    varOperation := 'Getting Actual Daylight Deal Limit';
    select NVL(sum(abs(crsk_position_usd)),0)
      into numTemp
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = GConst.RISKDAYLIGHT
      and crsk_serial_number = 1;

    if numTemp > numLimit then
      varOperation := 'Inserting Daylight Limit Violation';
      insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
        rdel_serial_number, rdel_risk_date, rdel_risk_type,
        RDEL_LIMIT_USD, rdel_amount_excess, rdel_action_taken,
        rdel_stake_holder, rdel_mobile_number, rdel_email_id,
        rdel_message_text)
        select deal_company_code, varReference, deal_deal_number,
        deal_serial_number, AsonDate, GConst.RISKDAYLIGHT,
        numLimit, crsk_position_usd - numLimit,
        numAction, varUserID, varMobile, varEmailID,
        'Daylight Limit Violation No: ' || deal_deal_number || ' Currency: ' ||
        pkgReturnCursor.fncGetDescription(deal_base_currency, GConst.PICKUPSHORT) || '/' ||
        pkgReturnCursor.fncGetDescription(deal_other_currency, GConst.PICKUPSHORT) ||
        ' Limit: ' || to_char(numLimit) || ' Excess: ' || to_char(crsk_position_usd - numLimit)
        from trsystem996 , trtran001 a
        where deal_deal_number =
        (select deal_deal_number
          from trtran001
          where deal_execute_date = AsonDate
          and to_timestamp(deal_time_stamp,'DD-Mon-RR HH24:MI:SS:FF3') =
          (select max(to_timestamp(deal_time_stamp,'DD-Mon-RR HH24:MI:SS:FF3'))
            from trtran001 b
            where deal_execute_date = AsonDate))
        and crsk_risk_type = GConst.RISKDAYLIGHT
        and crsk_serial_number = 1
        and crsk_ason_date = datToday
        and crsk_user_id is null
        and a.deal_deal_number not in
        (select rdel_deal_number
          from trtran011
          where rdel_deal_number = a.deal_deal_number
          and rdel_risk_reference = varReference);
    end if;


    varOperation := 'Checking Day Light Limit for cross currency deals';
    select risk_risk_reference, risk_limit_usd, risk_stake_holder,
      risk_action_taken, rprm_gross_net
      into varReference, numLimit, varUserID, numAction, numGrossNet
      from trsystem012 a, trsystem011
      where rprm_risk_type = risk_risk_type
      and risk_risk_type = GConst.RISKDAYLIGHT
      and risk_cross_currency = GConst.OPTIONYES
      and risk_effective_date =
      (select max(risk_effective_date)
        from trsystem012 b
        where a.risk_company_code = b.risk_company_code
        and a.risk_risk_type = b.risk_risk_type
        and a.risk_effective_date <= AsonDate);

    if numAction in (GConst.RISKACTSMS, GConst.RISKACTEMAIL) then
      select  user_mobile_phone, user_email_id
        into varMobile, varEmailID
        from trsystem022
        where user_user_id = varUserID;
    else
      varMobile := '';
      varEmailID := '';
    end if;

    varOperation := 'Getting Actual Cross Currency Daylight Deal Limit';
    select NVL(sum(abs(crsk_position_usd)),0)
      into numTemp
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = GConst.RISKDAYLIGHT
      and crsk_serial_number = 2;

    if numTemp > numLimit then
      varOperation := 'Inserting Cross Currency Daylight Limit Violation';
      insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
        rdel_serial_number, rdel_risk_date, rdel_risk_type,
        RDEL_LIMIT_USD, rdel_amount_excess, rdel_action_taken,
        rdel_stake_holder, rdel_mobile_number, rdel_email_id,
        rdel_message_text)
        select deal_company_code, varReference, deal_deal_number,
        deal_serial_number, AsonDate, GConst.RISKDAYLIGHT,
        numLimit, crsk_position_usd - numLimit,
        numAction, varUserID, varMobile, varEmailID,
        'Daylight Limit Violation No: ' || deal_deal_number || ' Currency: ' ||
        pkgReturnCursor.fncGetDescription(deal_base_currency, GConst.PICKUPSHORT) || '/' ||
        pkgReturnCursor.fncGetDescription(deal_other_currency, GConst.PICKUPSHORT) ||
        ' Limit: ' || numLimit || ' Excess: ' || (crsk_position_usd - numLimit)
        from trsystem996 , trtran001 a
        where deal_deal_number =
        (select deal_deal_number
          from trtran001 b
          where deal_execute_date = AsonDate
          and deal_other_currency != GConst.INDIANRUPEE
          and to_timestamp(deal_time_stamp,'DD-Mon-RR HH24:MI:SS:FF3') =
          (select max(to_timestamp(deal_time_stamp,'DD-Mon-RR HH24:MI:SS:FF3'))
            from trtran001 c
            where deal_execute_date = AsonDate
            and deal_other_currency != GConst.INDIANRUPEE))
        and crsk_risk_type = GConst.RISKDAYLIGHT
        and crsk_serial_number = 2
        and crsk_ason_date = datToday
        and crsk_user_id is null
        and a.deal_deal_number not in
        (select rdel_deal_number
          from trtran011
          where rdel_deal_number = a.deal_deal_number
          and rdel_risk_reference = varReference);
    end if;


    varOperation := 'Checking Daily Stop Loss Limit';
    select risk_risk_reference, risk_limit_usd,risk_limit_local, risk_stake_holder,
      risk_action_taken, rprm_gross_net
      into varReference, numLimit,numlimitlocal, varUserID, numAction, numGrossNet
      from trsystem012 a, trsystem011
      where rprm_risk_type = risk_risk_type
      and risk_risk_type = GConst.RISKSTOPLOSSDAILY
      and risk_effective_date =
      (select max(risk_effective_date)
        from trsystem012 b
        where a.risk_company_code = b.risk_company_code
        and a.risk_risk_type = b.risk_risk_type
        and a.risk_effective_date <= AsonDate);

--    if numAction in (GConst.RISKACTSMS, GConst.RISKACTEMAIL) then
--      select  user_mobile_phone, user_email_id
--        into varMobile, varEmailID
--        from trsystem022
--        where user_user_id = varUserID;
--    else
--      varMobile := '';
--      varEmailID := '';
--    end if;

    varOperation := 'Summing up Losses for cancelled and outstanding deals';
    select abs(sum(crsk_profit_loss))
      into numTemp
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = GConst.RISKSTOPLOSSDAILY;


     --varEmailID:= fncUserDetails(varUserID);


    if numTemp > numlimitlocal then
--      varTemp := 'RISK/' || fncGenerateSerial(SERIALRISKSERIAL);
     varTemp := 'RISK/' || Gconst.fncGenerateSerial(Gconst.SERIALRISKSERIAL);
      insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
        rdel_serial_number, rdel_risk_date, rdel_risk_type,
        RDEL_LIMIT_USD, rdel_amount_excess, rdel_action_taken,
        rdel_stake_holder, rdel_mobile_number, rdel_email_id,
        rdel_message_text,rdel_sent_status,rdel_record_status)
      values(10399999, varTemp, '-', 0, datToday,
      GConst.RISKSTOPLOSSDAILY, numlimitlocal, numTemp - numlimitlocal,
      numAction,varEmailID  , varMobile, varEmailID,
      ' Daily Stoploss Limit Violation: REF No  ' || varTemp || to_char(13) ||
      '   Limit  :   ' || pkgreturnReport.fncConvRs(numlimitlocal) || to_char(13) ||
      '   Loss   :   ' || pkgreturnReport.fncConvRs(numTemp) || to_char(13) ||
      '   Excess :   ' || pkgreturnReport.fncConvRs((numTemp - numlimitlocal)),27300001,10200001);

    End if;

    varOperation := 'Checking Deal Stop Loss Limit';
    select risk_risk_reference, RISK_LOCKINRATE,risk_limit_local, risk_stake_holder,
      risk_action_taken, rprm_gross_net
      into varReference, numLimit,numlimitlocal, varUserID, numAction, numGrossNet
      from trsystem012 a, trsystem011
      where rprm_risk_type = risk_risk_type
      and risk_risk_type = GConst.RISKSTOPLOSSDEAL
      and risk_effective_date =
      (select max(risk_effective_date)
        from trsystem012 b
        where a.risk_company_code = b.risk_company_code
        and a.risk_risk_type = b.risk_risk_type
        and a.risk_effective_date <= AsonDate);

    if numAction in (GConst.RISKACTSMS, GConst.RISKACTEMAIL) then
      select  user_mobile_phone, user_email_id
        into varMobile, varEmailID
        from trsystem022
        where user_user_id = varUserID;
    else
      varMobile := '';
      varEmailID := '';
    end if;

    varOperation := 'Populating for Stop Loss Deal';


   --  varEmailID:= fncUserDetails(varUserID);

   -- if numTemp > numlimitlocal then
      --varTemp := 'RISK/' || fncGenerateSerial(SERIALRISKSERIAL);
      insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
        rdel_serial_number, rdel_risk_date, rdel_risk_type,
        RDEL_LIMIT_USD, rdel_amount_excess, rdel_action_taken,
        rdel_stake_holder, rdel_mobile_number, rdel_email_id,
        rdel_message_text,rdel_sent_status,rdel_record_status)
        select 10399999, 'RISK/' || Gconst.fncGenerateSerial(Gconst.SERIALRISKSERIAL),
        CRSK_DEAL_NUMBER,0,datToday,
        GConst.RISKSTOPLOSSDEAL,numlimitlocal,  round((case when crsk_buy_sell=25300001 then crsk_deal_rate - CRSK_MTM_RATEACTUAL
                  when crsk_buy_sell=25300002 then CRSK_MTM_RATEACTUAL-crsk_deal_rate end),2),
        numAction,varEmailID  , varMobile, varEmailID,
        ' Deal Stoploss Limit Violation: REF No  ' || CRSK_DEAL_NUMBER ||  chr(13) || chr(13) ||
        '   Deal Amount     :  ' || pkgreturnReport.fncConvRs(CRSK_POSITION_FCY) || chr(13) ||
        '   Currency Pair   : ' || pkgreturncursor.fncgetdescription(CRSK_CURRENCY_CODE,2) || '/' ||
         pkgreturncursor.fncgetdescription(CRSK_FOR_CURRENCY,2) || chr(13) ||
        '   Deal Rate        :  ' || CRSK_MTM_RATEACTUAL || chr(13) ||
        '   M2M Rate         :  ' || CRSK_MTM_RATE  || chr(13) ||
        '   Wash Rate        :  ' || CRSK_MTM_WASHRATE || chr(13) ||
        '   Limit            :   ' || numlimitlocal || chr(13) ||
        '   Loss             :   ' || pkgreturnReport.fncConvRs(CRSK_MTM_ACTUAL) ||  chr(13) ||
        '   Excess           :   ' || (CRSK_MTM_ACTUAL -( numlimitlocal*CRSK_MTM_ACTUAL)) || chr(13) || chr(13) || chr(13) ||
        '   Mail Has been send by  Treasury Software '  ,27300001,10200001
        from trsystem996
        where crsk_ason_date = datToday
        and crsk_risk_type = 0
        and (case when crsk_buy_sell=25300001 then crsk_deal_rate - CRSK_MTM_RATEACTUAL
                  when crsk_buy_sell=25300002 then CRSK_MTM_RATEACTUAL-crsk_deal_rate end) > numLimit;
    
    

    varOperation := 'Checking Deal Take Profit ';
    select risk_risk_reference, RISK_LOCKINRATE,risk_limit_local, risk_stake_holder,
      risk_action_taken, rprm_gross_net
      into varReference, numLimit,numlimitlocal, varUserID, numAction, numGrossNet
      from trsystem012 a, trsystem011
      where rprm_risk_type = risk_risk_type
      and risk_risk_type = GConst.RISKTAKEPROFIT
      and risk_effective_date =
      (select max(risk_effective_date)
        from trsystem012 b
        where a.risk_company_code = b.risk_company_code
        and a.risk_risk_type = b.risk_risk_type
        and a.risk_effective_date <= AsonDate);

    if numAction in (GConst.RISKACTSMS, GConst.RISKACTEMAIL) then
      select  user_mobile_phone, user_email_id
        into varMobile, varEmailID
        from trsystem022
        where user_user_id = varUserID;
    else
      varMobile := '';
      varEmailID := '';
    end if;

    varOperation := 'Populating for Take Profit';


   --  varEmailID:= fncUserDetails(varUserID);

   -- if numTemp > numlimitlocal then
      --varTemp := 'RISK/' || fncGenerateSerial(SERIALRISKSERIAL);
      insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
        rdel_serial_number, rdel_risk_date, rdel_risk_type,
        RDEL_LIMIT_USD, rdel_amount_excess, rdel_action_taken,
        rdel_stake_holder, rdel_mobile_number, rdel_email_id,
        rdel_message_text,rdel_sent_status,rdel_record_status)
        select 10399999, 'RISK/' || Gconst.fncGenerateSerial(Gconst.SERIALRISKSERIAL),
        CRSK_DEAL_NUMBER,0,datToday,
        GConst.RISKTAKEPROFIT,numlimitlocal,  round( (case when crsk_buy_sell=25300001 then  CRSK_MTM_RATEACTUAL-crsk_deal_rate
                  when crsk_buy_sell=25300002 then crsk_deal_rate-CRSK_MTM_RATEACTUAL end),2),
        numAction,varEmailID  , varMobile, varEmailID,
        ' Deal Stoploss Limit Violation: REF No  ' || CRSK_DEAL_NUMBER ||  chr(13) || chr(13) ||
        '   Deal Amount     :  ' || pkgreturnReport.fncConvRs(CRSK_POSITION_FCY) || chr(13) ||
        '   Currency Pair   : ' || pkgreturncursor.fncgetdescription(CRSK_CURRENCY_CODE,2) || '/' ||
         pkgreturncursor.fncgetdescription(CRSK_FOR_CURRENCY,2) || chr(13) ||
        '   Deal Rate        :  ' || CRSK_DEAL_RATE || chr(13) ||
        '   M2M Rate         :  ' || CRSK_MTM_RATEACTUAL  || chr(13) ||
        '   Wash Rate        :  ' || CRSK_MTM_WASHRATE || chr(13) ||
        '   Limit            :   ' || (numlimitlocal) || chr(13) ||
        '   Profit             :   ' || pkgreturnReport.fncConvRs(CRSK_MTM_ACTUAL) ||  chr(13) ||
        '   Excess           :   ' || ((CRSK_MTM_ACTUAL -( numlimitlocal*CRSK_MTM_ACTUAL))) || chr(13) || chr(13) || chr(13) ||
        '   Mail Has been send by  Treasury Software '  ,27300001,10200001
        from trsystem996
        where crsk_ason_date = datToday
        and crsk_risk_type = 0
        and (case when crsk_buy_sell=25300001 then  CRSK_MTM_RATEACTUAL-crsk_deal_rate
                  when crsk_buy_sell=25300002 then crsk_deal_rate-CRSK_MTM_RATEACTUAL end) > numLimit;
                  
                  
                  

    --End if;
    varOperation := 'Checking Monthy Stop Loss Limit';
    select risk_risk_reference, risk_limit_usd, risk_stake_holder,
      risk_action_taken, rprm_gross_net
      into varReference, numLimit, varUserID, numAction, numGrossNet
      from trsystem012 a, trsystem011
      where rprm_risk_type = risk_risk_type
      and risk_risk_type = GConst.RISKSTOPLOSSMTHLY
      and risk_effective_date =
      (select max(risk_effective_date)
        from trsystem012 b
        where a.risk_company_code = b.risk_company_code
        and a.risk_risk_type = b.risk_risk_type
        and a.risk_effective_date <= AsonDate);

    if numAction in (GConst.RISKACTSMS, GConst.RISKACTEMAIL) then
      select  user_mobile_phone, user_email_id
        into varMobile, varEmailID
        from trsystem022
        where user_user_id = varUserID;
    else
      varMobile := '';
      varEmailID := '';
    end if;

    varOperation := 'Summing up Losses for cancelled and outstanding deals';
    select sum(crsk_allowed_usd)
      into numTemp
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = GConst.RISKSTOPLOSSMTHLY;


    if numTemp > numLimit then
      insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
        rdel_serial_number, rdel_risk_date, rdel_risk_type,
        RDEL_LIMIT_USD, rdel_amount_excess, rdel_action_taken,
        rdel_stake_holder, rdel_mobile_number, rdel_email_id,
        rdel_message_text)
      values(10399999, varReference, null, 0, datToday,
      GConst.RISKSTOPLOSSMTHLY, numLimit, numTemp - numLimit,
      numAction,  varUserID, varMobile, varEmailID,
      'Monthly Stoploss Limit Violation: ' ||
      ' Limit: ' || to_char(numLimit) || ' Excess: ' || to_char((numTemp - numLimit)));
    End if;

    varOperation := 'Checking Quarterly Stop Loss Limit';
    select risk_risk_reference, risk_limit_usd, risk_stake_holder,
      risk_action_taken, rprm_gross_net
      into varReference, numLimit, varUserID, numAction, numGrossNet
      from trsystem012 a, trsystem011
      where rprm_risk_type = risk_risk_type
      and risk_risk_type = GConst.RISKSTOPLOSSQTRLY
      and risk_effective_date =
      (select max(risk_effective_date)
        from trsystem012 b
        where a.risk_company_code = b.risk_company_code
        and a.risk_risk_type = b.risk_risk_type
        and a.risk_effective_date <= AsonDate);

    if numAction in (GConst.RISKACTSMS, GConst.RISKACTEMAIL) then
      select  user_mobile_phone, user_email_id
        into varMobile, varEmailID
        from trsystem022
        where user_user_id = varUserID;
    else
      varMobile := '';
      varEmailID := '';
    end if;

    varOperation := 'Summing up Losses for cancelled and outstanding deals';
    select sum(crsk_allowed_usd)
      into numTemp
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = GConst.RISKSTOPLOSSQTRLY;

    if numTemp > numLimit then
      insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
        rdel_serial_number, rdel_risk_date, rdel_risk_type,
        RDEL_LIMIT_USD, rdel_amount_excess, rdel_action_taken,
        rdel_stake_holder, rdel_mobile_number, rdel_email_id,
        rdel_message_text)
      values(10399999, varReference, null, 0, datToday,
      GConst.RISKSTOPLOSSQTRLY, numLimit, numTemp - numLimit,
      numAction,  varUserID, varMobile, varEmailID,
      'Quarterly Stoploss Limit Violation: ' ||
      ' Limit: ' || to_char(numLimit) || ' Excess: ' || to_char((numTemp - numLimit)));
    End if;

    varOperation := 'Checking Yearly Stop Loss Limit';
    select risk_risk_reference, risk_limit_usd, risk_stake_holder,
      risk_action_taken, rprm_gross_net
      into varReference, numLimit, varUserID, numAction, numGrossNet
      from trsystem012 a, trsystem011
      where rprm_risk_type = risk_risk_type
      and risk_risk_type = GConst.RISKSTOPLOSSYERLY
      and risk_effective_date =
      (select max(risk_effective_date)
        from trsystem012 b
        where a.risk_company_code = b.risk_company_code
        and a.risk_risk_type = b.risk_risk_type
        and a.risk_effective_date <= AsonDate);

    if numAction in (GConst.RISKACTSMS, GConst.RISKACTEMAIL) then
      select  user_mobile_phone, user_email_id
        into varMobile, varEmailID
        from trsystem022
        where user_user_id = varUserID;
    else
      varMobile := '';
      varEmailID := '';
    end if;
    
    
    

    varOperation := 'Summing up Losses for cancelled and outstanding deals';
    select sum(crsk_allowed_usd)
      into numTemp
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = GConst.RISKSTOPLOSSYERLY;

    if numTemp > numLimit then
      insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
        rdel_serial_number, rdel_risk_date, rdel_risk_type,
        RDEL_LIMIT_USD, rdel_amount_excess, rdel_action_taken,
        rdel_stake_holder, rdel_mobile_number, rdel_email_id,
        rdel_message_text)
      values(10399999, varReference, null, 0, datToday,
      GConst.RISKSTOPLOSSYERLY, numLimit, numTemp - numLimit,
      numAction,  varUserID, varMobile, varEmailID,
      'Yearly Stoploss Limit Violation: ' ||
      ' Limit: ' || to_char(numLimit) || ' Excess: ' || (numTemp - numLimit));
    End if;
-------------------------- Commodity Module Done by manjunath reddy on 16-apr-2009

    varOperation := 'Checking Individual Commodity Deal Limit';
    select crsk_crsk_reference, crsk_limit_local, crsk_stake_holder,
      crsk_action_taken
      into varReference, numLimit, varUserID, numAction
      from trsystem019 a
      where crsk_crsk_type = GConst.CRISKDEALLIMIT
      and crsk_effective_date =
      (select max(crsk_effective_date)
        from trsystem019 b
        where a.crsk_company_code = b.crsk_company_code
        and a.crsk_crsk_type = b.crsk_crsk_type
        and crsk_effective_date <= AsonDate);



    varOperation := 'Inserting Individual Commodity Deal Limit Violation';
    insert into trtran011 (rdel_company_code, rdel_risk_reference, rdel_deal_number,
      rdel_serial_number,rdel_risk_date, rdel_risk_type,
      RDEL_LIMIT_USD, rdel_amount_excess,
      rdel_action_taken, rdel_stake_holder, rdel_mobile_number, rdel_email_id,
      rdel_message_text)
      select 30199999, varReference, crsk_deal_number,
      1,AsonDate, GConst.RISKDEALLIMIT,
      numLimit, crsk_position_inr - numLimit,
      numAction, varUserID, varMobile, varEmailID,
      'Deal Limit Violation No: ' || crsk_deal_number || ' Currency: ' ||
      pkgReturnCursor.fncGetDescription(crsk_other_currency, GConst.PICKUPSHORT) || '/' ||
      ' Limit: ' || to_char(numLimit) || ' Excess: ' || to_char(crsk_position_usd - numLimit)
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = 200
      and crsk_position_inr > numLimit
      and crsk_deal_number not in
      (select rdel_deal_number
        from trtran011
        where rdel_deal_number = crsk_deal_number
        and rdel_risk_reference = varReference);

    varOperation := 'Insert data into Archive table Get the serial number count';
    
    begin
        select count(*) into numtemp 
          from trtran011_archive
        where RDEL_RISK_DATE=datToday
        group by RDEL_Insert_serial;
    exception
      when others then
      numtemp:=0;
    end;
    
     varOperation := 'Insert data into Archive table';
    
    INSERT INTO trtran011_archive (    rdel_company_code,    rdel_risk_reference,    rdel_deal_number,
        rdel_serial_number,    rdel_risk_type,    rdel_risk_date,    rdel_limit_usd,
        rdel_amount_excess,    rdel_action_taken,    rdel_stake_holder,    rdel_mobile_number,
        rdel_email_id,    rdel_message_text,    rdel_sent_status,    rdel_sent_timestamp,
        rdel_record_status,    rdel_create_date,    rdel_entry_detail,    rdel_cal_usd,
        rdel_cal_local,    rdel_cal_percent,    rdel_limit_local,    rdel_limit_percent,
        rdel_limit_fcy,    rdel_cal_fcy,    rdel_location_code,    rdel_product_code,
        rdel_subproduct_code,    rdel_currency_product,    rdel_action_type,RDEL_Insert_serial)
        
        select rdel_company_code,    rdel_risk_reference,    rdel_deal_number,
        rdel_serial_number,    rdel_risk_type,    rdel_risk_date,    rdel_limit_usd,
        rdel_amount_excess,    rdel_action_taken,    rdel_stake_holder,    rdel_mobile_number,
        rdel_email_id,    rdel_message_text,    rdel_sent_status,    rdel_sent_timestamp,
        rdel_record_status,    rdel_create_date,    rdel_entry_detail,    rdel_cal_usd,
        rdel_cal_local,    rdel_cal_percent,    rdel_limit_local,    rdel_limit_percent,
        rdel_limit_fcy,    rdel_cal_fcy,    rdel_location_code,    rdel_product_code,
        rdel_subproduct_code,    rdel_currency_product,    rdel_action_type, numtemp
        from trtran011;
        
    varOperation := 'Delete data from Archive for Mim Serial Number';
       delete from trtran011_archive 
       where RDEL_RISK_DATE=datToday
         and RDEL_Insert_serial= 
          (select min(RDEL_Insert_serial) 
            from trtran011_archive
            where RDEL_RISK_DATE=datToday) ;
        
--        insert into trtran011_archive
--        select * from trtran011 where RDEL_RISK_DATE=datToday;


----    varOperation := 'Checking Commodity Deal Daily Stop Loss Limit';
----    select crsk_crsk_reference, crsk_limit_local, crsk_stake_holder,
----      crsk_action_taken
----      --, crsk_gross_net
----      into varReference, numLimit, varUserID, numAction
----      --, numGrossNet
----      from trsystem019 a, trsystem018
----      where crpm_crsk_type = crsk_crsk_type
----      and crsk_crsk_type = GConst.CRISKSTOPLOSSDAILY
----      and crsk_effective_date =
----      (select max(crsk_effective_date)
----        from trsystem019 b
----        where a.crsk_company_code = b.crsk_company_code
----        and a.crsk_crsk_type = b.crsk_crsk_type
----        and a.crsk_effective_date <= AsonDate);
----
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
--    varOperation := 'Summing up Losses for cancelled and outstanding Commodity deals : Daily Stop Loss';
--    select sum(crsk_position_inr)
--      into numTemp
--      from trsystem996
--      where crsk_ason_date = datToday
--      and crsk_risk_type = GConst.CRISKSTOPLOSSDAILY;
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
    numTemp       number(20,6);
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
    datToday := trunc(AsonDate);

    delete from trsystem996;
--    execute dbms_snapshot.refresh('mvewRiskDeals');
      --where crsk_ason_date = datToday;

    varOperation := 'Insert outstanding Position (RiskPopulate)';
    insert into trsystem996(crsk_risk_type, crsk_currency_code, crsk_buy_sell,
      crsk_deal_date,crsk_deal_rate ,crsk_position_fcy, crsk_inr_amount, crsk_rate_usd,
      crsk_position_usd,crsk_rate_inr,crsk_position_inr,
      crsk_counter_party, crsk_user_id, crsk_maturity_month,
      crsk_deal_number, crsk_serial_number, crsk_maturity_date, crsk_ason_date,
      crsk_for_currency, crsk_other_currency,CRSK_Account_code,
      CRSK_LOCATION_CODE,CRSK_Portfolio_code,CRSK_SUBPortfolio_code,
      CRSK_COMPANY_CODE,	CRSK_MTM_RATEACTUAL , CRSK_MTM_ACTUAL , 
	    CRSK_MTM_LOCAL , 	CRSK_MTM_WASHRATE,crsk_mtm_currency,crsk_wash_rate )
    select 0, POSN_CURRENCY_CODE,
      (Case when POSN_ACCOUNT_CODE <25900050 then 25300002
            when POSN_ACCOUNT_CODE >25900050 then 25300001 end),
      POSN_REFERENCE_DATE,POSN_FCY_RATE, POSN_TRANSACTION_AMOUNT,
      POSN_INR_VALUE, POSN_USD_RATE, POSN_USD_VALUE, POSN_M2M_INRRATE,
      POSN_REVALUE_INR, POSN_COUNTER_PARTY, POSN_DEALER_ID,
      0, POSN_REFERENCE_NUMBER, 
      (case when (POSN_REFERENCE_SERIAL=0) then 1 else POSN_REFERENCE_SERIAL end) , POSN_DUE_DATE, AsonDate,
      POSN_FOR_CURRENCY, POSN_TRANSACTION_AMOUNT*POSN_FCY_RATE,
      POSN_ACCOUNT_CODE,POSN_LOCATION_CODE,POSN_PRODUCT_CODE,POSN_SUBPRODUCT_CODE,
      POSN_COMPANY_CODE,POSN_MTM_RATEACTUAL , POSN_MTM_ACTUAL , 
	    POSN_MTM_LOCAL , 	POSN_MTM_WASHRATE,POSN_MTM_LOCAL,POSN_MTM_WASHRATE
      from trsystem997;

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


    varOperation := 'Calculate Net Position For Each Currency';
    insert into trsystem996(crsk_risk_type, crsk_currency_code, crsk_ason_date,
    crsk_position_fcy, crsk_position_usd,crsk_position_inr,
    CRSK_LOCATION_CODE,CRSK_Portfolio_code,CRSK_SUBPortfolio_code,CRSK_COMPANY_CODE)
    select 1, crsk_currency_code, datToday,
      sum(decode(crsk_buy_sell, 25300001, crsk_position_fcy, 0)) -
      sum(decode(crsk_buy_sell, 25300002, crsk_position_fcy, 0)),
      sum(decode(crsk_buy_sell, 25300001, crsk_position_usd, 0)) -
      sum(decode(crsk_buy_sell, 25300002, crsk_position_usd, 0)),
      sum(decode(crsk_buy_sell, 25300001, crsk_position_inr, 0)) -
      sum(decode(crsk_buy_sell, 25300002, crsk_position_inr, 0)),
      CRSK_LOCATION_CODE,CRSK_Portfolio_code,CRSK_SUBPortfolio_code,
      CRSK_COMPANY_CODE
      from trsystem996
      where crsk_risk_type = 0
      group by 1, crsk_currency_code, datToday,
       CRSK_LOCATION_CODE,CRSK_Portfolio_code,CRSK_SUBPortfolio_code,
      CRSK_COMPANY_CODE;

     varOperation := 'Calculate Net Position For Each Currency';
    insert into trsystem996(crsk_risk_type, crsk_currency_code, crsk_ason_date,
    crsk_user_id, crsk_position_fcy, crsk_position_usd,crsk_position_inr,
     CRSK_LOCATION_CODE,CRSK_Portfolio_code,CRSK_SUBPortfolio_code,CRSK_COMPANY_CODE)
    select 2, crsk_currency_code, datToday, crsk_user_id,
      sum(decode(crsk_buy_sell, 25300001, crsk_position_fcy, 0)) -
      sum(decode(crsk_buy_sell, 25300002, crsk_position_fcy, 0)),
      sum(decode(crsk_buy_sell, 25300001, crsk_position_usd, 0)) -
      sum(decode(crsk_buy_sell, 25300002, crsk_position_usd, 0)),
      sum(decode(crsk_buy_sell, 25300001, crsk_position_inr, 0)) -
      sum(decode(crsk_buy_sell, 25300002, crsk_position_inr, 0)),
       CRSK_LOCATION_CODE,CRSK_Portfolio_code,CRSK_SUBPortfolio_code,
       CRSK_COMPANY_CODE
      from trsystem996
      where crsk_risk_type = 0
      and crsk_account_code in (25900011,
            25900012,25900018,25900019,25900020,25900021,
            25900022,25900023,25900061,25900062,25900078,
            25900079,25900082,25900083,25900084,25900085)
      group by 2,  crsk_currency_code,crsk_user_id,
       CRSK_LOCATION_CODE,CRSK_Portfolio_code,CRSK_SUBPortfolio_code,CRSK_COMPANY_CODE;

     varOperation := 'Calculate Net of Forward Contracts For Each Currency & Month';
    insert into trsystem996(crsk_risk_type, crsk_currency_code, crsk_ason_date,
    crsk_user_id, crsk_position_fcy, crsk_position_usd,crsk_position_inr,
     CRSK_LOCATION_CODE,CRSK_Portfolio_code,CRSK_SUBPortfolio_code,
     CRSK_COMPANY_CODE,CRSK_MATURITY_DATE)
    select 3, crsk_currency_code, datToday, crsk_user_id,
      sum(decode(crsk_buy_sell, 25300001, crsk_position_fcy, 0)) -
      sum(decode(crsk_buy_sell, 25300002, crsk_position_fcy, 0)),
      sum(decode(crsk_buy_sell, 25300001, crsk_position_usd, 0)) -
      sum(decode(crsk_buy_sell, 25300002, crsk_position_usd, 0)),
      sum(decode(crsk_buy_sell, 25300001, crsk_position_inr, 0)) -
      sum(decode(crsk_buy_sell, 25300002, crsk_position_inr, 0)),
      CRSK_LOCATION_CODE,CRSK_Portfolio_code,CRSK_SUBPortfolio_code,
      CRSK_COMPANY_CODE,trunc(CRSK_MATURITY_DATE,'Month')
      from trsystem996
      where crsk_risk_type = 0
      and crsk_account_code in (25900011,
            25900012,25900018,25900019,25900020,25900021,
            25900022,25900023,25900061,25900062,25900078,
            25900079,25900082,25900083,25900084,25900085)
      group by 3,  crsk_currency_code,trunc(CRSK_MATURITY_DATE,'Month'),crsk_user_id,
       CRSK_LOCATION_CODE,CRSK_Portfolio_code,CRSK_SUBPortfolio_code,CRSK_COMPANY_CODE;
      

    varOperation := 'Calculate Net Exposure For Each Currency & Month ';
    insert into trsystem996(crsk_risk_type, crsk_currency_code, crsk_ason_date,
    crsk_position_fcy, crsk_position_usd,crsk_position_inr,
    CRSK_LOCATION_CODE,CRSK_Portfolio_code,CRSK_SUBPortfolio_code,
    CRSK_COMPANY_CODE,CRSK_MATURITY_DATE)
    select 4, crsk_currency_code, datToday,
      sum(decode(crsk_buy_sell, 25300001, crsk_position_fcy, 0)) -
      sum(decode(crsk_buy_sell, 25300002, crsk_position_fcy, 0)),
      sum(decode(crsk_buy_sell, 25300001, crsk_position_usd, 0)) -
      sum(decode(crsk_buy_sell, 25300002, crsk_position_usd, 0)),
      sum(decode(crsk_buy_sell, 25300001, crsk_position_inr, 0)) -
      sum(decode(crsk_buy_sell, 25300002, crsk_position_inr, 0)),
       CRSK_LOCATION_CODE,CRSK_Portfolio_code,CRSK_SUBPortfolio_code,
       CRSK_COMPANY_CODE, trunc(CRSK_MATURITY_DATE,'Month')
      from trsystem996
      where crsk_risk_type = 0
      and crsk_account_code not in (25900011,
            25900012,25900018,25900019,25900020,25900021,
            25900022,25900023,25900061,25900062,25900078,
            25900079,25900082,25900083,25900084,25900085)
      group by 4, crsk_currency_code,trunc(CRSK_MATURITY_DATE,'Month'),
      CRSK_LOCATION_CODE,CRSK_Portfolio_code,CRSK_SUBPortfolio_code,CRSK_COMPANY_CODE;

--    varOperation := 'Calculating Position for User and Currency wise';
--    insert into trsystem996(crsk_risk_type, crsk_currency_code, crsk_ason_date,
--    crsk_user_id, crsk_position_fcy, crsk_position_usd,crsk_position_inr)
--    select 2, crsk_currency_code, datToday, crsk_user_id,
--      sum(decode(crsk_buy_sell, 25300001, crsk_position_fcy, 0)) -
--      sum(decode(crsk_buy_sell, 25300002, crsk_position_fcy, 0)),
--      sum(decode(crsk_buy_sell, 25300001, crsk_position_usd, 0)) -
--      sum(decode(crsk_buy_sell, 25300002, crsk_position_usd, 0)),
--      sum(decode(crsk_buy_sell, 25300001, crsk_position_inr, 0)) -
--      sum(decode(crsk_buy_sell, 25300002, crsk_position_inr, 0))
--      from trsystem996
--      where crsk_risk_type = 0
--      and crsk_account_code in (25900011,
--         25900012,25900018,25900019,25900020,25900021,
--         25900022,25900023,25900061,25900062,25900078,
--         25900079,25900082,25900083,25900084,25900085)
--      and crsk_ason_date = datToday
--      group by 2, crsk_user_id, crsk_currency_code, datToday ;
      
      
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


    varOperation := 'Calculate Gross Currency Exposure';
    insert into trsystem996(crsk_risk_type, crsk_ason_date,
      crsk_position_usd, crsk_position_inr)
    select GConst.RISKGROSSCURRENCY, datToday,
      sum(decode(sign(crsk_position_fcy), -1, crsk_position_usd * -1, crsk_position_usd)),
      sum(decode(sign(crsk_position_fcy), -1, crsk_position_inr * -1, crsk_position_inr))
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = 1
      group by GConst.RISKGROSSCURRENCY, datToday;


    varOperation := 'Insert Record for Combined Day Light Limit';
    insert into trsystem996(crsk_risk_type, crsk_ason_date,
      crsk_position_usd, crsk_position_inr, crsk_serial_number, crsk_limit_usd)
    select GConst.RISKDAYLIGHT, datToday, crsk_position_usd, crsk_position_inr,
      1, fncRiskLimit(datToday, GConst.RISKDAYLIGHT, GConst.OPTIONNO)
      from trsystem996
      where crsk_risk_type = GConst.RISKGROSSCURRENCY
      and crsk_ason_date = datToday;

    varOperation := 'Calculate Gross Currency Exposure for Cross Currency';
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

    varOperation := 'Calculate Counter Party Exposure';
    insert into trsystem996(crsk_risk_type,  crsk_ason_date,
      crsk_position_usd, crsk_position_inr, crsk_counter_party)
    select GConst.RISKCOUNTERPARTY, datToday,
      sum(crsk_position_usd), sum(crsk_position_inr), crsk_counter_party
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = 0
      group by GConst.RISKCOUNTERPARTY, datToday, crsk_counter_party;

--    varOperation := 'Calculate Gap Exposures';
--    insert into trsystem996(crsk_risk_type, crsk_currency_code, crsk_buy_sell,
--      crsk_ason_date, crsk_position_fcy, crsk_position_usd, crsk_position_inr)
--    select decode(crsk_maturity_month, 0, GConst.RISKGAPSPOT,
--        1, GConst.RISKGAPFORWARD1, 2, GConst.RISKGAPFORWARD2, 3, GConst.RISKGAPFORWARD3,
--        4, GConst.RISKGAPFORWARD4, 5, GConst.RISKGAPFORWARD5, 6, GConst.RISKGAPFORWARD6,
--        7, GConst.RISKGAPFORWARD7, 8, GConst.RISKGAPFORWARD8, 9, GConst.RISKGAPFORWARD9,
--        10, GConst.RISKGAPFORWARD10, 11, GConst.RISKGAPFORWARD11, 12, GConst.RISKGAPFORWARD12),
--      crsk_currency_code, 0, datToday,
--        sum(decode(crsk_buy_sell, 25300001, crsk_position_fcy, 0)) -
--        sum(decode(crsk_buy_sell, 25300002, crsk_position_fcy, 0)) Gap,
--        sum(decode(crsk_buy_sell, 25300001, crsk_position_usd, 0)) -
--        sum(decode(crsk_buy_sell, 25300002, crsk_position_usd, 0)) GapUsd,
--        sum(decode(crsk_buy_sell, 25300001, crsk_position_inr, 0)) -
--        sum(decode(crsk_buy_sell, 25300002, crsk_position_inr, 0)) GapInr
--      from trsystem996
--      where crsk_ason_date = datToday
--      and crsk_risk_type = 0
--      group by crsk_maturity_month, crsk_currency_code, 0, datToday
--      order by crsk_currency_code, crsk_maturity_month;

    varOperation := 'Calculate Gap For all the months ';
    insert into trsystem996(crsk_ason_date,crsk_risk_type, crsk_currency_code,
       crsk_position_fcy, crsk_Hedged_percentage)

    select datToday, GConst.RISKGAPALL,  decode(exp.crsk_currency_code,null,deal.crsk_currency_code,exp.crsk_currency_code),
            (decode(exp.crsk_position_fcy,null,0,exp.crsk_position_fcy)-
             decode(deal.crsk_position_fcy,null,0,deal.crsk_position_fcy)),
            round((decode(exp.crsk_position_fcy,null,0,exp.crsk_position_fcy)-
             decode(deal.crsk_position_fcy,null,0,deal.crsk_position_fcy))
            /decode(deal.crsk_position_fcy,null,1,deal.crsk_position_fcy),2)
    from 
    (select crsk_currency_code,  CRSK_LOCATION_CODE,CRSK_Portfolio_code,
           CRSK_COMPANY_CODE,sum(crsk_position_fcy) crsk_position_fcy,
            sum(crsk_position_usd) crsk_position_usd, sum(crsk_position_inr) crsk_position_inr,
           crsk_maturity_month
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = 4
      group by crsk_maturity_month, crsk_currency_code,
      CRSK_LOCATION_CODE,CRSK_Portfolio_code,
           CRSK_COMPANY_CODE) Exp full outer join
     (select crsk_currency_code,  CRSK_LOCATION_CODE,CRSK_Portfolio_code,
           CRSK_COMPANY_CODE,sum(crsk_position_fcy) crsk_position_fcy,
            sum(crsk_position_usd) crsk_position_usd, sum(crsk_position_inr) crsk_position_inr,
           crsk_maturity_month
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = 4
      group by crsk_maturity_month, crsk_currency_code,
      CRSK_LOCATION_CODE,CRSK_Portfolio_code,
           CRSK_COMPANY_CODE) Deal
      on exp.CRSK_LOCATION_CODE= Deal.CRSK_LOCATION_CODE
     and exp.CRSK_Portfolio_code= Deal.CRSK_Portfolio_code
     and exp.CRSK_COMPANY_CODE= Deal.CRSK_COMPANY_CODE
     and exp.crsk_maturity_month= deal.crsk_maturity_month;
     
--       update trsystem996 Ma set crsk_lockinrate=
--            (select RISK_LOCKINRATE from TRSYSTEM012 P
--             where crsk_Hedged_percentage between  
--                RISK_LIMIT_PERCENT and RISK_FLUCT_ALLOWED
--                and risk_Record_status not in (10200005,10200006)
--                and Ma.CRSK_LOCATION_CODE= P.RISK_LOCATION_CODE
--                and Ma.CRSK_Portfolio_code= P.RISK_Portfolio_code
--                and Ma.CRSK_COMPANY_CODE= P.RISK_COMPANY_CODE
--                and p.risk_effective_date >= Today)
--        where  crsk_risk_type= GConst.RISKGAPALL;
        
        
            
                
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

    varOperation := 'Calculate Stop Losses - Intra Day';
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

    varOperation := 'Calculate Stop Losses - Daily';
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

    varOperation := 'Calculate Stop Loss - Monthly';
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

    varOperation := 'Calculate Stop Loss - Quarterly';
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

   varOperation := 'Calculating Stop Losses - Yearly Setp 2';
    if numTemp > 0 then
      insert into trsystem996(crsk_risk_type, crsk_ason_date,
        crsk_serial_number, crsk_position_usd, crsk_position_inr,
        crsk_limit_usd)
      values(GConst.RISKSTOPLOSSYERLY, datToday, 1,
        round(numTemp / numRate,2), numTemp,
        fncRiskLimit(datToday, GConst.RISKSTOPLOSSYERLY));
    End if;
 varOperation := 'Calculating Stop Losses - Yearly Setp 3';
    insert into trsystem996(crsk_risk_type, crsk_ason_date,
      crsk_serial_number, crsk_position_usd, crsk_position_inr, crsk_limit_usd)
    select GConst.RISKSTOPLOSSYERLY, datToday, 2,
      NVL(sum(crsk_allowed_usd),0), NVL(sum(crsk_allowed_inr),0),
      fncRiskLimit(datToday, GConst.RISKSTOPLOSSYERLY)
      from trsystem996
      where crsk_ason_date = datToday
      and crsk_risk_type = 0
      group by GConst.RISKSTOPLOSSYERLY, datToday, 2;

-- varOperation := 'Deal Stop Loss Limit';
--    insert into trsystem996(crsk_risk_type, crsk_ason_date,
--      crsk_serial_number, crsk_position_usd, crsk_position_inr, crsk_limit_usd)
--    select 21000015, datToday, 2,CRSK_DEAL_NUMBER,CRSK_SERIAL_NUMBER
--      NVL(sum(crsk_allowed_usd),0), NVL(sum(crsk_allowed_inr),0),
--      fncRiskLimit(datToday, 21000015)
--      from trsystem996
--      where crsk_ason_date = datToday
--      and crsk_risk_type = 0
--      group by 21000015, datToday, 2;
--
-- varOperation := 'Deal Take Profit';
--    insert into trsystem996(crsk_risk_type, crsk_ason_date,
--      crsk_serial_number, crsk_position_usd, crsk_position_inr, crsk_limit_usd)
--    select GConst.RISKSTOPLOSSYERLY, datToday, 2,
--      NVL(sum(crsk_allowed_usd),0), NVL(sum(crsk_allowed_inr),0),
--      fncRiskLimit(datToday, GConst.RISKSTOPLOSSYERLY)
--      from trsystem996
--      where crsk_ason_date = datToday
--      and crsk_risk_type = 0
--      group by GConst.RISKSTOPLOSSYERLY, datToday, 2;
--
--
--21000015
--21000034
--


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

Function fncRiskPopulateGAP
    (asonDate in date)
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

    delete from  trsystem996A;
--    execute dbms_snapshot.refresh('mvewRiskDeals');
      --where crsk_ason_date = datToday;
 varOperation:= 'Populate the Exposure Data';
  insert into trsystem996A(CRSH_COMPANY_CODE,CRSH_LOCATION_CODE,CRSH_PORTFOLIO_CODE,
  CRSH_SUBPORTFOLIO_CODE,CRSH_REFERENCE_DATE,CRSH_CURRENCY_CODE,CRSH_FOR_CURRENCY,
  CRSH_MATURITY_DATE,CRSH_EXPORT_FCY,CRSH_IMPORT_FCY)
  select TRAD_COMPANY_CODE,TRAD_LOCATION_CODE,trad_Product_category,
     TRAD_SUBPRODUCT_CODE,TRAD_REFERENCE_DATE,TRAD_TRADE_CURRENCY,TRAD_LOCAL_CURRENCY,
     TRAD_MATURITY_DATE, sum(case when trad_import_export <25900050 then TRAD_TRADE_FCY else 0 end),
     sum(case when trad_import_export >25900050 then TRAD_TRADE_FCY else 0 end)
   from trtran002
   where TRAD_RECORD_STATUS not in (10200005,10200006)
    and trad_process_complete =12400002
   group by TRAD_COMPANY_CODE,TRAD_LOCATION_CODE,trad_Product_category,
       TRAD_SUBPRODUCT_CODE,TRAD_REFERENCE_DATE,TRAD_TRADE_CURRENCY,
       TRAD_LOCAL_CURRENCY,TRAD_MATURITY_DATE;

 varOperation:= 'Update the Net Exposure';
 update trsystem996A set CRSH_NET_EXPOSURE= CRSH_EXPORT_FCY-CRSH_IMPORT_FCY;

 varOperation:= 'Update the Hedged FCY';
 
  update  trsystem996A set (CRSH_HEDGE_SELL,CRSH_HEDGE_BUY)=
  ( select (case when (deal_buy_sell=25300001) then HEDG_HEDGED_FCY else 0 end),
           (case when (deal_buy_sell=25300002) then HEDG_HEDGED_FCY else 0 end)
     from trtran004 inner join trtran001
     on HEDG_DEAL_NUMBER= deal_deal_number
     where HEDG_TRADE_REFERENCE in (select TRAD_TRADE_REFERENCE from trtran002
            where trad_reference_Date = CRSH_REFERENCE_DATE)
      and DEAL_COMPANY_CODE=CRSH_COMPANY_CODE
      and DEAL_LOCATION_CODE=CRSH_LOCATION_CODE
      and DEAL_BACKUP_DEAL=CRSH_PORTFOLIO_CODE
      and DEAL_INIT_CODE=CRSH_SUBPORTFOLIO_CODE
      and DEAL_BASE_CURRENCY=CRSH_CURRENCY_CODE
      and DEAL_OTHER_CURRENCY=CRSH_FOR_CURRENCY
      and DEAL_MATURITY_DATE=CRSH_MATURITY_DATE
      and deal_Record_Status not in (10200005,10200006)
      and deal_process_complete =12400002);

 varOperation:= 'Update the Hedged FCY';
 update trsystem996A set CRSH_TOT_HEDGE= CRSH_HEDGE_SELL-CRSH_HEDGE_BUY;
 
 varOperation:= 'Update the First Forward Rate';
  
  update  trsystem996A set CRSH_FIRSTFORWARD_RATE=fncGetHedgeRate(CRSH_REFERENCE_DATE,
          CRSH_COMPANY_CODE,CRSH_LOCATION_CODE,CRSH_PORTFOLIO_CODE,CRSH_SUBPORTFOLIO_CODE,
          CRSH_CURRENCY_CODE,CRSH_FOR_CURRENCY,CRSH_MATURITY_DATE);

 varOperation:= 'Update the Hedged Percentage';
 update trsystem996A set CRSH_PERCENTAGE_HEDGE= (abs(CRSH_TOT_HEDGE)/abs(CRSH_NET_EXPOSURE)) *100
  where CRSH_NET_EXPOSURE !=0;
 
 commit;
  varOperation:= 'Update the Hedged Percentage';
 update trsystem996A set CRSH_MTM_RATE= pkgforexprocess.fncgetrate(CRSH_CURRENCY_CODE, CRSH_FOR_CURRENCY,
          asonDate,25300001,0,CRSH_MATURITY_DATE) ;  

  varOperation:= 'Update the Lock in Rate';
 update trsystem996A set CRSH_LOCKIN_RATE= (select RISK_LOCKINRATE 
                    from trsystem012 
                    where RISK_COMPANY_CODE= CRSH_COMPANY_CODE
                      and RISK_CURRENCY_CODE=CRSH_CURRENCY_CODE
                      and RISK_PRODUCT_CODE=CRSH_PORTFOLIO_CODE
                      and RISK_SUBPRODUCT_CODE=CRSH_SUBPORTFOLIO_CODE
                      and RISK_LOCATION_CODE =CRSH_LOCATION_CODE
                      and CRSH_PERCENTAGE_HEDGE between RISK_LIMIT_PERCENT and RISK_FLUCT_ALLOWED
                      and RISK_RISK_TYPE= 21000020
                      and RISK_RECORD_STATUS not in (10200005,10200006) );
 
   varOperation:= 'Update the Limit Percent';
  update trsystem996A set CRSH_Limit_PERCENTAGE = (select RISK_FLUCT_ALLOWED 
                    from trsystem012 
                    where RISK_COMPANY_CODE= CRSH_COMPANY_CODE
                      and RISK_CURRENCY_CODE=CRSH_CURRENCY_CODE
                      and RISK_PRODUCT_CODE=CRSH_PORTFOLIO_CODE
                      and RISK_SUBPRODUCT_CODE=CRSH_SUBPORTFOLIO_CODE
                      and RISK_LOCATION_CODE =CRSH_LOCATION_CODE
                      and RISK_RISK_TYPE= 21000020
                      and CRSH_PERCENTAGE_HEDGE between RISK_LIMIT_PERCENT and RISK_FLUCT_ALLOWED
                      and RISK_RECORD_STATUS not in (10200005,10200006) );
      commit;
  return 0;
exception 
  when others then 
      varError := SQLERRM;
      varerror := 'fncRiskPopulateGAP: ' || varmessage || varoperation || varerror;
      raise_application_error(-20101,   varerror);
      return -1;
end fncRiskPopulateGAP;

function fncGetHedgeRate 
(datReferenceDate in date,
 CompanyCode in number,
 LocationCode in Number,
 PortfolioCode in Number,
 SubPortfolioCode in Number,
 CurrencyCode in Number,
 ForCurrency in Number,
 MaturityDate in date)

return number
is 
    varOperation  GConst.gvarOperation%type;
    varMessage    gconst.gvarMessage%type;
    varError      gconst.gvarError%type;
    ExchangeRate Number(15,6);
begin
  varmessage := ' Get the Hedge Rate';
  VarOperation := 'Get the Hedge Rate for the date ' || datReferenceDate;
  
  
   select deal_exchange_rate into ExchangeRate
    from ( select row_number() over (order by deal_time_stamp ) Rownumber,
                  deal_exchange_rate 
                  from trtran001 
                 where deal_deal_number in (   
                     select hedg_deal_number 
                       from trtran002 inner join trtran004
                       on trad_trade_Reference = hedg_trade_reference
                      where trad_reference_date =datReferenceDate
                      and hedg_record_status not in (10200005,10200006)
                      and trad_record_status not in (10200005,10200006))
                      and deal_record_status not in (10200005,10200006)
                      and DEAL_COMPANY_CODE=CompanyCode
                      and DEAL_LOCATION_CODE=LocationCode
                      and DEAL_BACKUP_DEAL=PortfolioCode
                      and DEAL_INIT_CODE=SubPortfolioCode
                      and DEAL_BASE_CURRENCY=CurrencyCode
                      and DEAL_OTHER_CURRENCY=ForCurrency
                      and DEAL_MATURITY_DATE=MaturityDate)
    where Rownumber=1;
    
    return ExchangeRate;
exception 
  when no_data_found then 
    return 0;
  when others then 
      varError := SQLERRM;
      varerror := 'fncGetHedgeRate: ' || varmessage || varoperation || varerror;
      raise_application_error(-20101,   varerror);

end fncGetHedgeRate;

--function fncGetHedgePercentage 
--  (datReferenceDate in Date,
--   datMaturityDate in Date,
--   numCurrency in Number,
--   numCompany in Number,
--   numLocation in Number,
--   numPortfolio in Number,
--   numSubPortfolio in Number)
--  return number
--is
--    varOperation  GConst.gvarOperation%type;
--    varMessage    gconst.gvarMessage%type;
--    varError      gconst.gvarError%type;
--    HedgePercentage Number(15,6);
--    datRate Number(15,6); 
--    numExposureFcy number(15,2);
--begin 
--  varMessage := 'Get the Hedge Percentage';
--  VarOperation := 'Get the Hedge Percentage ' || datMaturityDate;
--  
--  
--  select sum(case when trad_import_export <25900050 then trad_trade_fcy
--                  when trad_import_export >25900051 then -1 * trad_trade_fcy
--            end)
--    into  numExposureFcy
--    from trtran002 
--   where trad_reference_date =datReferenceDate
--   and trad_maturity_date = datMaturityDate
--   and trad_record_status not in (10200005,10200006)
--   and trad_company_code= NumCompany
--   and trad_Location_code =NumLocation
--   and TRAD_PRODUCT_CATEGORY = NumPortfolio
--   and TRAD_SUBPRODUCT_CODE= NumSubPortfolio
--   and Trad_trade_currency = numCurrency;
--   
--   select hedg_trade_reference,hedg_deal_number,
--          numExposureFcy / sum(Hedg_Hedged_fcy)
--          HedgedFcy
--    from trtran004 
--    where hedg_trade_reference in (
--    select Trad_Trade_reference 
--    from trtran002 
--   where trad_reference_date =datReferenceDate
--   and trad_maturity_date = datMaturityDate
--   and trad_record_status not in (10200005,10200006)
--   and trad_company_code= NumCompany
--   and trad_Location_code =NumLocation
--   and TRAD_PRODUCT_CATEGORY = NumPOrtfolio
--   and TRAD_SUBPRODUCT_CODE= NumSubPortfolio
--   and Trad_trade_currency = numCurrency);
--   
--   
-- 
--   select deal_exchange_rate 
--     into ExchangeRate
--    from (select row_number() over ( order by deal_time_stamp ) Rownumber,
--                  deal_exchange_rate 
--                  from trtran001 
--                 where deal_deal_number in (   
--                     select hedg_deal_number 
--                       from trtran002 inner join trtran004
--                       on trad_trade_reference= HEDG_DEAL_NUMBER
--                      where trad_maturity_date =datMaturityDate
--                      and trad_reference_date =datReferenceDate
--                      and hedg_record_status not in (10200005,10200006)
--                      and trad_record_status not in (10200005,10200006))
--                      and deal_record_status not in (10200005,10200006))
--    where Rownumber=1;
--exception 
--  when no_data_found then 
--    return 0;
--  when others then 
--      arError := SQLERRM;
--      varerror := 'fncGetHedgePercentage: ' || varmessage || varoperation || varerror;
--      raise_application_error(-20101,   varerror);
--end fncGetHedgePercentage;

PROCEDURE prcDueDateAlert
    ( EmailTrigger in number default 12400002)
AS
  Bank            VARCHAR2(10);
  Currency        VARCHAR2(10);
  LoanType        VARCHAR2(20);
  SupplierCode    VARCHAR2(50);
  AmountFCY       NUMBER(15,2);
  IntAmount       NUMBER(15,2);
  Repayment       NUMBER(15,2);
  DueDate         DATE;  
  --GenCursor gconst.datacursor;
  varOperation    VARCHAR2(200);
  varTemp1        VARCHAR2(4000);
  varTemp2       clob;
--  varTemp2        BLOB;
  varemailString  clob;
  varHeader       VARCHAR2(4000);
  vartouser       VARCHAR2(4000);
  fromuser        VARCHAR2(4000);
  varsubject      VARCHAR2(4000);
  varccuser        VARCHAR2(4000);
  intRowsImpacted  number(5);
  
BEGIN
 varoperation:=' Clearing of staging tables';
  DELETE FROM TRSYSTEM960;
  delete from TRAUDIT001;
  
 for cur in (select ALRT_ALERT_CODE,ALRT_NOOF_DAYS,ALRT_ALERT_REFERENCE,
        ALRT_UER_ID,ALRT_ALERT_TO,ALRT_ALERT_CC,ALRT_ALERT_BCC,
        ALRT_ALERT_DESCRIPTION,Alrt_Risk_level
        from trsystem013A
        where ALRT_RECORD_STATUS not in (10200005,10200006))
  loop
    if (cur.ALRT_ALERT_CODE=91700001) then --Forwards
        INSERT INTO TRSYSTEM960
            (MAIL_BANK_NAME,MAIL_CURRENCY_NAME,MAIL_TRANSACTION_TYPE,MAIL_SUPPLIER_NAME,MAIL_AMOUNT_FCY,
             MAIL_INTEREST_AMOUNT,MAIL_REPAYMENT_AMOUNT,MAIL_DUE_DATE,MAIL_REFERENCE_NUMBER,MAIL_DUE_FROM,
             MAIL_EXCHANGE_RATE,MAIL_EXCHANGE_CODE,MAIL_BUY_SELL,
             MAIL_OPTION_TYPE,MAIL_BACKUP_DEAL,MAIL_INIT_CODE,
             MAIL_ALERT_REFERENCE)        
          SELECT  pkgReturnCursor.fncGetDescription(DEAL_COUNTER_PARTY,2) AS BankName,
                 pkgReturnCursor.fncGetDescription(DEAL_BASE_CURRENCY,2) AS CurrencyCode,
                 'Forward Contract' AS   TypeofLoan,
                 pkgReturnCursor.fncGetDescription(DEAL_COUNTER_PARTY,1) SupplierCode,
                 deal_base_amount OUTSTANDINGAMOUNT, 0 AS InterestAmount,0 AS Repayment,
                 deal_maturity_date DueDate,DEAL_DEAL_NUMBER DealNumber,
                 deal_maturity_from DueFrom,deal_exchange_rate ExeRate,null,
                 pkgReturnCursor.fncGetDescription(DEAL_BUY_SELL,2) AS BuySell,
                 null, pkgReturnCursor.fncGetDescription(deal_backup_deal,2),
                  pkgReturnCursor.fncGetDescription(deal_init_code,2),cur.ALRT_ALERT_REFERENCE
             from TRTRAN001  
             WHERE  TO_DATE(deal_maturity_from,'DD/MM/YYYY') BETWEEN  TO_DATE(SYSDATE,'DD/MM/YYYY') AND TO_DATE(SYSDATE,'DD/MM/YYYY') + cur.ALRT_NOOF_DAYS
             AND (deal_process_complete = 12400002 OR (deal_process_complete=12400001 AND deal_complete_date >SYSDATE))
             AND deal_record_status NOT IN (10200005,10200006,10200010);
             
         intRowsImpacted:=sql%Rowcount;
         
         if (intRowsImpacted>0) then
              insert into TRALERT001(ALRT_USER_IDS,ALRT_Reference_number,
                                     ALRT_TITLE,ALRT_MESSAGE,ALRT_NOOF_TRANSACTION,
                                     ALRT_RECORD_STATUS,ALRT_CREATE_date,Alrt_Alert_TYPE,Alrt_Risk_level)
                              values(cur.ALRT_UER_ID,cur.ALRT_ALERT_REFERENCE,
                              pkgReturnCursor.fncGetDescription(cur.ALRT_ALERT_CODE,1),
                              cur.ALRT_ALERT_DESCRIPTION,intRowsImpacted,10200003,sysdate,91800001,cur.Alrt_Risk_level);
          end if;
            
    end if;
    
    if (cur.ALRT_ALERT_CODE=91700001) then --Forwards
          INSERT INTO TRSYSTEM960
              (MAIL_BANK_NAME,MAIL_CURRENCY_NAME,MAIL_TRANSACTION_TYPE,MAIL_SUPPLIER_NAME,MAIL_AMOUNT_FCY,
               MAIL_INTEREST_AMOUNT,MAIL_REPAYMENT_AMOUNT,MAIL_DUE_DATE,MAIL_REFERENCE_NUMBER,MAIL_DUE_FROM,
               MAIL_EXCHANGE_RATE,MAIL_EXCHANGE_CODE,MAIL_BUY_SELL,
               MAIL_OPTION_TYPE,MAIL_BACKUP_DEAL,MAIL_INIT_CODE,MAIL_ALERT_REFERENCE)
               
         SELECT   pkgReturnCursor.fncGetDescription(cfut_COUNTER_PARTY,2) AS BankName,
         pkgReturnCursor.fncGetDescription(cfut_BASE_CURRENCY,2) AS CurrencyCode,
         'Future Contract' AS   TypeofLoan,
         pkgReturnCursor.fncGetDescription(cfut_COUNTER_PARTY,1) SupplierCode,
         cfut_base_amount OUTSTANDINGAMOUNT,0 AS InterestAmount,0 AS Repayment,
         cfut_maturity_date DueDate,CFUT_DEAL_NUMBER DealNumber,
         cfut_maturity_from,cfut_exchange_rate,
         pkgReturnCursor.fncGetDescription(cfut_exchange_code,2),
         pkgReturnCursor.fncGetDescription(cfut_buy_sell,2),null,
         pkgReturnCursor.fncGetDescription(cfut_backup_deal,2),
         pkgReturnCursor.fncGetDescription(cfut_init_code,2),cur.ALRT_ALERT_REFERENCE
         from trtran061  WHERE 
         TO_DATE(cfut_maturity_from,'DD/MM/YYYY') BETWEEN  TO_DATE(SYSDATE,'DD/MM/YYYY') AND TO_DATE(SYSDATE,'DD/MM/YYYY') + cur.ALRT_NOOF_DAYS
         AND (cfut_process_complete = 12400002 OR (cfut_process_complete=12400001 AND cfut_complete_date >SYSDATE))
         AND cfut_record_status NOT IN (10200005,10200006,10200010);
         
         intRowsImpacted:=sql%Rowcount;
         
         if (intRowsImpacted>0) then
              insert into TRALERT001(ALRT_USER_IDS,ALRT_Reference_number,
                                     ALRT_TITLE,ALRT_MESSAGE,ALRT_NOOF_TRANSACTION,
                                     ALRT_RECORD_STATUS,ALRT_CREATE_date,Alrt_Alert_TYPE,Alrt_Risk_level)
                              values(cur.ALRT_UER_ID,cur.ALRT_ALERT_REFERENCE,
                              pkgReturnCursor.fncGetDescription(cur.ALRT_ALERT_CODE,1),
                              cur.ALRT_ALERT_DESCRIPTION,intRowsImpacted,10200003,sysdate,91800001,cur.Alrt_Risk_level);
          end if;
          
   end if;
      if (cur.ALRT_ALERT_CODE=91700001) then --Forwards
          INSERT INTO TRSYSTEM960
              (MAIL_BANK_NAME,MAIL_CURRENCY_NAME,MAIL_TRANSACTION_TYPE,MAIL_SUPPLIER_NAME,MAIL_AMOUNT_FCY,
               MAIL_INTEREST_AMOUNT,MAIL_REPAYMENT_AMOUNT,MAIL_DUE_DATE,MAIL_REFERENCE_NUMBER,MAIL_DUE_FROM,
               MAIL_EXCHANGE_RATE,MAIL_EXCHANGE_CODE,MAIL_BUY_SELL,
               MAIL_OPTION_TYPE,MAIL_BACKUP_DEAL,MAIL_INIT_CODE,MAIL_ALERT_REFERENCE)  
          SELECT
          CASE WHEN COPT_CONTRACT_TYPE = 32800002 THEN
          pkgReturnCursor.fncGetDescription(COPT_COUNTER_PARTY,2) 
          else
          pkgReturnCursor.fncGetDescription(COPT_BROKER_CODE,2) 	end AS Bank,
          pkgReturnCursor.fncGetDescription(COPT_BASE_CURRENCY,2) AS CurrencyCode,
         'Option Contract' AS   TypeofLoan,
          pkgReturnCursor.fncGetDescription(COPT_COUNTER_PARTY,1) SupplierCode,
          COPT_base_amount OUTSTANDINGAMOUNT,
          0 AS InterestAmount,0 AS Repayment,  
          COPT_maturity_date DueDate,COPT_DEAL_NUMBER DealNumber,
          copt_expiry_date,COSU_STRIKE_RATE,
          pkgReturnCursor.fncGetDescription(copt_exchange_code,2),pkgReturnCursor.fncGetDescription(cosu_buy_sell,2),
          pkgReturnCursor.fncGetDescription(COSU_OPTION_TYPE,2),
          pkgReturnCursor.fncGetDescription(COPT_BACKUP_DEAL,2),
          pkgReturnCursor.fncGetDescription(COPT_INIT_CODE,2),cur.ALRT_ALERT_REFERENCE
          from TRTRAN071,TRTRAN072   WHERE 
          COPT_DEAL_NUMBER = COSU_DEAL_NUMBER
          AND TO_DATE(COPT_EXPIRY_date,'DD/MM/YYYY') BETWEEN  TO_DATE(SYSDATE,'DD/MM/YYYY') AND TO_DATE(SYSDATE,'DD/MM/YYYY') + cur.ALRT_NOOF_DAYS
          AND (COPT_process_complete = 12400002 OR (COPT_process_complete=12400001 AND COPT_complete_date >SYSDATE))
          AND COPT_record_status NOT IN (10200005,10200006,10200010)
          AND COSU_record_status NOT IN (10200005,10200006,10200010);
          
         intRowsImpacted:=sql%Rowcount;
         
         if (intRowsImpacted>0) then
              insert into TRALERT001(ALRT_USER_IDS,ALRT_Reference_number,
                                     ALRT_TITLE,ALRT_MESSAGE,ALRT_NOOF_TRANSACTION,
                                     ALRT_RECORD_STATUS,ALRT_CREATE_date,Alrt_Alert_TYPE,Alrt_Risk_level)
                              values(cur.ALRT_UER_ID,cur.ALRT_ALERT_REFERENCE,
                              pkgReturnCursor.fncGetDescription(cur.ALRT_ALERT_CODE,1),
                              cur.ALRT_ALERT_DESCRIPTION,intRowsImpacted,10200003,
                              sysdate,91800001,cur.Alrt_Risk_level);
          end if;
          
     end if;
   end loop;
    if (EmailTrigger=12400001) then 
          varHeader:='<TABLE BORDER=1 BGCOLOR="#EEEEEE">';
          varHeader:=varHeader||'<TR BGCOLOR="Gray">';
          varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Bank/Broker</FONT></TH>';
          varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Currency</FONT></TH>';
          varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Instrument</FONT></TH>';
          varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Amount</FONT></TH>';
          varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Exchnage Rate</FONT></TH>';
          varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Expiry Date</FONT></TH>';
          varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Settlement Date</FONT></TH>';
          varHeader:=varHeader||'<TH><FONT COLOR="WHITE">SystemRefNo</FONT></TH>';
          varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Exchange</FONT></TH>';
          varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Buy Sell</FONT></TH>';
          varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Option Type</FONT></TH>';
          varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Business Unit</FONT></TH>';
          varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Profit Center</FONT></TH>';
          varHeader:=varHeader||'</TR>';
          varemailString:=varHeader;
        for Alert_details in (select * from trsystem013A 
                               where ALRT_RECORD_STATUS not in (10200005,10200006))
        loop
              FOR CUR_DUEDATE IN(SELECT * FROM TRSYSTEM960
                                 where MAIL_ALERT_REFERENCE= Alert_details.ALRT_ALERT_REFERENCE
                                ORDER BY MAIL_DUE_DATE,MAIL_TRANSACTION_TYPE)
              loop 
                varOperation := 'Generating Confirmation Pending Auto mail';
                varTemp2:='';
                varTemp2:=varTemp2 || '<TR BGCOLOR="WHITE">';
                varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.MAIL_BANK_NAME||'</td>';
                varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.MAIL_CURRENCY_NAME||'</td>';
                varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.MAIL_TRANSACTION_TYPE||'</td>';
                varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.MAIL_AMOUNT_FCY||'</td>';
                varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.MAIL_EXCHANGE_RATE||'</td>';
                varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.MAIL_DUE_FROM||'</td>';
                varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.MAIL_DUE_DATE||'</td>';
                varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.MAIL_REFERENCE_NUMBER||'</td>';
                varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.MAIL_EXCHANGE_CODE||'</td>';
                varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.MAIL_BUY_SELL||'</td>';
                varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.MAIL_OPTION_TYPE||'</td>';
                varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.MAIL_BACKUP_DEAL||'</td>';
                varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.MAIL_INIT_CODE||'</td>';
                varTemp2:=varTemp2 || '</tr>';
                varemailString := varemailString || varTemp2;     
              end loop;
          varemailString:= varemailString|| '</table>';  
      --    apex_mail_p.mail ('fxtreasury-icc@modi.com','ishwarachandra@ibsfintech.com', 'DueDateAlert',varemailString); 
          IF Alert_details.ALRT_NOOF_DAYS > 0 THEN
            varsubject := 'Transaction maturing in next ' ||Alert_details.ALRT_NOOF_DAYS|| ' days';
          ELSE
            varsubject := 'Transaction maturing in today';
          end if; 
      
          Pkgsendingmail.send_mail (Alert_details.ALRT_ALERT_TO,Alert_details.ALRT_ALERT_CC,
               null,varsubject, NULL,Null,varemailString);
        end loop;
    end if;
    --Pkgsendingmail.send_mail_secure(vartouser,varccuser,null,varsubject, NULL,Null,varemailString);
    
--    PROCEDURE send_mail (p_to      IN VARCHAR2,
--                     p_cc        IN VARCHAR2,
--                     p_bcc       IN VARCHAR2,
--                     p_subject   IN VARCHAR2,
--                     p_text_msg  IN VARCHAR2 DEFAULT NULL,
--                     p_html_msg  IN VARCHAR2 DEFAULT NULL,
--                     p_html_msg_Clob  IN Clob DEFAULT NULL);



end  prcDueDateAlert;
end PKGRISKMONITORING;
/