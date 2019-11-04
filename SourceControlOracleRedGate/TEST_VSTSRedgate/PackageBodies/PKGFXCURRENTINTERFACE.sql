CREATE OR REPLACE PACKAGE BODY "TEST_VSTSRedgate".PKGFXCURRENTINTERFACE as



function fncgetfiscalyear(workdate in date)
return varchar2
as
yeartmp varchar2(4);
varfinancialyear varchar2(10);

begin

 select to_char(decode( sign(to_char(workdate ,'MM')-4),-1,
             add_months(trunc(add_months(workdate ,-12) ,'YYYY') ,3),
             add_months(trunc(workdate ,'YYYY') ,3)),'YYYY')
        into yeartmp
        from dual;
    varfinancialyear := yeartmp;
 RETURN varfinancialyear;
EXCEPTION
WHEN OTHERS THEN
RETURN '0';
end fncgetfiscalyear;


function fncCheckAccountHeadExist( 
  AccountHead in number,
  numValutoCheck in number, 
  TypeofArgument in varchar,
  varAccountNumber in varchar2 default null)
  return number 
as
 numValueReturn number(8);
     numError            number;
     varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
begin 
--CRDR
--BANK
--LOB
--CURRENCY
--EVENT
--LOAN
--ACCOUNT
varOperation:= ' fncCheckAccountHeadExist for Acc ' || AccountHead || ' Value ' || numValutoCheck || 'A/C ' || varAccountNumber || ' Argument ' || TypeofArgument;
  
exception
When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('fncCheckAccountHeadExist', numError, varMessage, 
                      Varoperation, Varerror);
      numError := fncAuditTrail(varError);                      
      raise_application_error(-20101, varError);                      
end fncCheckAccountHeadExist;

Function fncExchangeRate
    (   VoucherReference in varchar2, 
        VoucherSerial in number,
        AccountCode in number)
    return number as
--  Created on 10/11/09 by T M Manjunath
    numError            number;
    numBill             number(15,2);
    numRate             number(15,4);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;

  begin
    numRate := 0.00;
    
    varMessage := 'Extracting exchange rate of the Bill : ' || VoucherReference ||
      ' Srl : ' || VoucherSerial;
-- If there is a current a/c entry, that rate is taken for all transactions otherwise
-- the rate taken for the main transaction is taken for all conversions
    varOperation := 'Extracting Exchange Rate for Current A/c';
    Begin    
      select NVL(sum(bcac_voucher_rate),0)
        into numRate
        from trtran008
        where bcac_voucher_reference = VoucherReference
        and bcac_reference_serial = VoucherSerial
        and bcac_account_head = 24900030
        and bcac_record_status != 10200006
        and rownum = 1;
    Exception
      When no_data_found then
        numRate := 0;
    End;
    
    if numRate = 0 then  
      select decode(bcac_voucher_rate, 0, 1, bcac_voucher_rate)
        into numRate
        from trtran008
        where bcac_voucher_reference = VoucherReference
        and bcac_reference_serial = VoucherSerial
        and bcac_account_head = AccountCode
        and bcac_record_status != 10200006
        and rownum = 1;
    End if;
    
    return numRate;
Exception
When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := varError || ' Head: ' || AccountCode;
      varError := GConst.fncReturnError('ExchangeRate', numError, varMessage, 
                      Varoperation, Varerror);
      raise_application_error(-20101, varError);                      
      return numRate;
End fncExchangeRate;

Function fncAccountHead
    (   BankCode in number ,
        AccountHead in number,
        CreditDebit in number default 14699999,
        CurrencyCode in number default 20599999,
        LOBCode in Number default 32699999,
        EventType in Number default 24899999,
        LoanType in number Default 23699999,
        AccountNumber in varchar2 default 'NA',
        BuySell in number  Default 26899999)
    return varchar2 as
--  Created on 10/11/09 by T M Manjunath

    numError            number;
    numAccount          number(8);
    varAccount          varchar2(15);
    numLocationCode      number(8);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    
    numBankCode number(8) ;
    numAccountHead  number(8);
    numCreditDebit  number(8) ;
    numCurrencyCode  number(8);
    numLOBCode  Number(8);
    numEventType  Number(8);
    numLoanType  number(8);
    varAccountNumber  varchar2(50);
    numBuysell number(8);
        

  begin
    varAccount := '';
    
        numBankCode :=BankCode ;
    numAccountHead :=AccountHead;
    numCreditDebit :=CreditDebit ;
    numCurrencyCode:=CurrencyCode;
    numLOBCode:=LOBCode;
    numEventType :=EventType;
    numLoanType :=LoanType;
    varAccountNumber :=AccountNumber;
    numBuysell := BuySell;
    


  if CreditDebit !=14699999 then 
    begin 
       select distinct CMAP_CRDR_CODE
         into numCreditDebit
         from trtran008F
        where CMAP_Account_TYPE = AccountHead
         and CMAP_CRDR_CODE= CreditDebit
         and cmap_record_status not in (10200005,10200006); 
    exception
    when no_data_found then
       select distinct CMAP_CRDR_CODE
         into numCreditDebit
         from trtran008F
        where CMAP_Account_TYPE = AccountHead
         and CMAP_CRDR_CODE= 14699999
         and cmap_record_status not in (10200005,10200006); 
    end;
  end if;
  if BankCode!=30699999 then 
        begin 
         select distinct CMAP_LOCAL_BANK
           into numBankCode
           from trtran008F
          where CMAP_Account_TYPE = AccountHead
           and CMAP_LOCAL_BANK= BankCode
           and cmap_record_status not in (10200005,10200006); 
      exception
      when no_data_found then
         select distinct CMAP_LOCAL_BANK
           into numBankCode
           from trtran008F
          where CMAP_Account_TYPE = AccountHead
           and CMAP_LOCAL_BANK= 30699999
           and cmap_record_status not in (10200005,10200006); 
      end;
   end if;
--   if CurrencyCode!=20599999 then 
--        begin 
--         select distinct CMAP_CURRENCY_CODE
--           into numCurrencyCode
--           from trtran008F
--          where CMAP_Account_TYPE = AccountHead
--           and CMAP_CURRENCY_CODE= CurrencyCode
--           and cmap_record_status not in (10200005,10200006); 
--      exception
--      when no_data_found then
--         select distinct CMAP_CURRENCY_CODE
--           into numCurrencyCode
--           from trtran008F
--          where CMAP_Account_TYPE = AccountHead
--           and CMAP_CURRENCY_CODE= 20599999
--           and cmap_record_status not in (10200005,10200006); 
--      end;
--   end if;
--   if LOBCode!=32699999 then 
--        begin 
--         select distinct CMAP_LOB_CODE
--           into numLOBCode
--           from trtran008F
--          where CMAP_Account_TYPE = AccountHead
--           and CMAP_LOB_CODE= LOBCode
--           and cmap_record_status not in (10200005,10200006); 
--      exception
--      when no_data_found then
--         select distinct CMAP_LOB_CODE
--           into numLOBCode
--           from trtran008F
--          where CMAP_Account_TYPE = AccountHead
--           and CMAP_LOB_CODE= 32699999
--           and cmap_record_status not in (10200005,10200006); 
--      end;
--    end if;
--    if EventType!=24899999 then 
--        begin 
--         select distinct CMAP_EVENT_TYPE
--           into numEventType
--           from trtran008F
--          where CMAP_Account_TYPE = AccountHead
--           and CMAP_EVENT_TYPE= EventType
--           and cmap_record_status not in (10200005,10200006); 
--      exception
--      when no_data_found then
--         select distinct CMAP_EVENT_TYPE
--           into numEventType
--           from trtran008F
--          where CMAP_Account_TYPE = AccountHead
--           and CMAP_EVENT_TYPE= 24899999
--           and cmap_record_status not in (10200005,10200006); 
--      end;
--    end if;
--   if LoanType != 23699999 then 
--        begin 
--         select distinct CMAP_LOAN_TYPE
--           into numLoanType
--           from trtran008F
--          where CMAP_Account_TYPE = AccountHead
--           and CMAP_LOAN_TYPE= LoanType
--           and cmap_record_status not in (10200005,10200006); 
--      exception
--      when no_data_found then
--         select distinct CMAP_LOAN_TYPE
--           into numLoanType
--           from trtran008F
--          where CMAP_Account_TYPE = AccountHead
--           and CMAP_LOAN_TYPE= 23699999
--           and cmap_record_status not in (10200005,10200006); 
--      end;
--   end if;
   if AccountNumber !='NA' then 
      varOperation := 'Checking Account Number';
        begin 
         select distinct CMAP_ACCOUNT_NUMBER
           into varAccountNumber
           from trtran008F
          where CMAP_Account_TYPE = AccountHead
           and CMAP_LOCAL_BANK= numBankCode
           and CMAP_ACCOUNT_NUMBER= AccountNumber
           and cmap_record_status not in (10200005,10200006); 
      exception
      when no_data_found then
         select distinct CMAP_ACCOUNT_NUMBER
           into varAccountNumber
           from trtran008F
          where CMAP_Account_TYPE = AccountHead
           and CMAP_LOCAL_BANK= numBankCode
           and cmap_record_status not in (10200005,10200006); 
      end;
   end if;
   
   if Buysell !=25399999 then 
      varOperation := 'Checking BuySell';
        begin 
        select distinct CMAP_buy_sell
           into numbuysell
           from trtran008F
          where CMAP_Account_TYPE = AccountHead
           and CMAP_buy_sell= Buysell
           and cmap_record_status not in (10200005,10200006); 
      exception
      when no_data_found then
          select distinct CMAP_buy_sell
           into numbuysell
           from trtran008F
          where CMAP_Account_TYPE = AccountHead
           and CMAP_buy_sell= 25399999
           and cmap_record_status not in (10200005,10200006); 
      end;
   end if;
   
    --  begin 
        varOperation := 'First Level B:' || BankCode || 'A : ' || AccountHead || 'Cr: ' || CreditDebit || 'Cu: ' || CurrencyCode || 'LoB ';

       select cmap_finance_code
       into varAccount
       from trtran008F
      where CMAP_Account_TYPE = decode(AccountHead,24999999,CMAP_Account_TYPE,AccountHead)
        and CMAP_CRDR_CODE = decode(CreditDebit,14699999,CMAP_CRDR_CODE,numCreditDebit)
        and CMAP_LOCAL_BANK = decode(BankCode,30699999,CMAP_LOCAL_BANK,numBankCode)
--        and CMAP_CURRENCY_CODE = decode(CurrencyCode,20599999,CMAP_CURRENCY_CODE,numCurrencyCode)
--        and CMAP_LOB_CODE = decode(LOBCode,32699999,CMAP_LOB_CODE,numLOBCode)
--        and CMAP_EVENT_TYPE = decode(EventType,24899999,CMAP_EVENT_TYPE,numEventType)
--        and CMAP_LOAN_TYPE = decode(LoanType,23699999,CMAP_LOAN_TYPE,numLoanType)
        and nvl(CMAP_ACCOUNT_NUMBER,'NA') = decode( AccountNumber,'NA' , nvl(CMAP_ACCOUNT_NUMBER,'NA'), nvl( varAccountNumber,'NA'))
        and nvl(cmap_buy_sell,25399999) = decode(BuySell,25399999,nvl(cmap_buy_sell,25399999),numBuySell)
        and cmap_record_status not in (10200005,10200006);

    return varAccount;
Exception
--when no_data_found then 
--    return '';
When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := varError  ||  ' B:' || BankCode || 'A : ' || AccountHead || 'Cr: ' || CreditDebit || 'Cu: ' || CurrencyCode || 'LoB '
    || LOBCode || 'Event:'  ||EventType || 'Loan :' || LoanType || 'AcNo' || AccountNumber || ' B' ||Buysell ;
      varError := GConst.fncReturnError('AccountHead', numError, varMessage, 
                      Varoperation, Varerror);
      raise_application_error(-20101, varError);                      
      return varAccount;
End fncAccountHead;

Function fncAccountNumber
    (   BankCode in number,
        AccountHead in number,
        CreditDebit in number)
    return varchar2 as
--  Created on 24/11/09 by T M Manjunath
    numError            number;
    varAccount          varchar2(25);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;

  begin
    varAccount := '';
    varOperation := 'Extracting AccountNumber Bank ' || BankCode || 'Account Head ' || AccountHead || ' CRDR ' || CreditDebit ;
    
   -- if CreditDebit > 0 then
   begin 
      select cmap_account_number
        into varAccount
        from trtran008F
        where cmap_local_bank = BankCode
        and cmap_account_type = CreditDebit
        and cmap_account_type = AccountHead
        and cmap_record_Status between 10200001 and 10200004;
   exception 
    when others then 
      select cmap_account_number
        into varAccount
        from trtran008F
        where cmap_local_bank = BankCode
        and cmap_account_type = AccountHead
        and cmap_record_Status between 10200001 and 10200004;
    end;
    
    return varAccount;
    Exception
    when No_Data_found then
      return pkgReturnCursor.fncGetDescription(BankCode, GConst.PICKUPSHORT);
    when too_many_rows then
      return pkgReturnCursor.fncGetDescription(BankCode, GConst.PICKUPSHORT);
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('AccountNumber', numError, varMessage, 
                      varOperation, varError);
      raise_application_error(-20101, varError);           
      return varAccount;
end fncAccountNumber;



Function fncAuditTrail
    (   ErrorText in varchar2,
        datWorkDate in date default sysdate)
    return number as
    --  Created on 02/03/10 by T M Manjunath   
    PRAGMA AUTONOMOUS_TRANSACTION;
    numError            number;
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;

  begin
    varMessage := 'Creating Audit Trails for Reference: ' || gVoucherReference;
    numError := 0;
    varError := ErrorText;
    
    if gProcessComplete = GConst.OPTIONYES then    

      if gCredit != gDebit then
        varError := 'Debits and Credits not matching';
        gProcessComplete := GConst.OPTIONNO;
        gCompletionDate := null;
      elsif gVoucherEvent != 24800006 and  (gCredit = 0 or gDebit = 0) then
        varError := 'Debit or Credit is zero';
        gProcessComplete := GConst.OPTIONNO;
        gCompletionDate := null;
      end if;

    End if;

    
    varOperation := 'Inserting Audit trails';
    insert into trsystem901a(sapo_File_name, sapo_voucher_date, sapo_voucher_reference,
      sapo_voucher_serial, sapo_voucher_event, sapo_local_bank, sapo_format_types,
      sapo_time_stamp, sapo_package_name, sapo_error_text, sapo_credit_total,
      sapo_debit_total, sapo_process_complete, sapo_completion_date,SAPO_ADD_DATE)
    values(gFileName, gVoucherDate, gVoucherReference,
      gVoucherSerial, gVoucherEvent, gLocalBank, gFormatTypes,
      gTimeStamp, gPackageName, varError, gCredit,
      gDebit, gProcessComplete, gCompletionDate,datWorkDate);
    
    commit;
    return 20101;
Exception
      when others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := varError;
      varError := GConst.fncReturnError('AuditTrail', numError, varMessage, 
                      Varoperation, Varerror);
      Numerror := Fncaudittrail(Varerror);     
      commit;
      raise_application_error(-20101, varError);                      
      return numError;
End fncAuditTrail;


--Function fncRunInterface
--    (   
--      VoucherDate in Date
--    )
--    return number
--    as
---- Written on 08/09/2010 by T M Manjunath
--    PRAGMA AUTONOMOUS_TRANSACTION;
--    numError            number;
--    numSerial           number(5);
--    numRecords          number(5);
--    numErrors           number(5);
--    varReference        varchar2(50);
--    varFile             varchar2(50);
--    varQuery            varchar2(2048);
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    datFrom             date;
--    datTo               date;
--Begin
--    numError := 0;
--
--    varMessage := 'Processing Vouchers for Date: ' || VoucherDate;
--    if  VoucherDate is null then
--      return 0;
--    end if;
----  Up to 7th data is processed for both current and previous month
----  and after that it is done only for the current month
--    if  to_number(to_char(VoucherDate, 'DD')) >= 10 then
--      datFrom := to_date('01' || to_char(VoucherDate, '-MON-YYYY'));
--    else      
--      datFrom := to_date('01' || to_char(add_months(VoucherDate,-1), '-MON-YYYY'));
--    End if;
--    
--    if to_number(to_char(VoucherDate, 'MM')) in (1,3,5,7,8,10,12) then
--      numSerial := 31;
--    elsif to_number(to_char(VoucherDate, 'MM')) in (4,6,9,11) then
--      numSerial := 30;
--    elsif  to_number(to_char(VoucherDate, 'MM')) = 2 then
--      if  remainder(to_number(to_char(sysdate, 'YYYY')), 4) = 0 then
--        numSerial := 29;
--      else
--        numSerial := 28;
--      end if;
--    end if;      
--    datTo := to_date(numSerial || to_char(VoucherDate, '-MON-YYYY'));
--    dbms_output.put_line('Processing For: ' || VoucherDate || ' From: ' || datFrom || ' To: ' || datTo);
--    
--    varOperation := 'Deleting Old Records ';
--    Delete from trtran008E;
--    Delete from trsystem901a;
--    Delete from tfsystem901C
--      where sapl_process_date = VoucherDate;
--    
--    varOperation := 'Updating Discounting Records';
--    update tftran021
--      set bnkc_negotiation_type = GConst.BILLCOLLECTION
--      where bnkc_record_status between 10200001 and 10200004
--      and bnkc_negotiation_type != GConst.BILLCOLLECTION
--      and bnkc_invoice_number in
--      (select distinct bcac_voucher_reference
--        from trtran008
--        where bcac_voucher_type = 24800006
--        and bcac_voucher_date between datFrom and datTo
----        and to_char(bcac_voucher_date, 'MM') = to_char(VoucherDate, 'MM')
--        and bcac_record_status between 10200001 and 10200004
--        and bcac_voucher_reference not in
--        (select inln_invoice_number
--          from tftran022
--          where inln_record_status between 10200001 and 10200004));
--
--    varOperation := 'Updating Process Complete Status';
--    varQuery := 'truncate table process_complete';
--    Execute immediate varQuery;
--
--    insert into Process_complete
--    select inln_invoice_number, inln_sanctioned_fcy, inln_process_complete, brel_local_bank, 
--        max(brel_realization_date) brel_realized_date, sum(brel_realized_fcy) brel_realized_fcy
--        from tftran022, tftran023
--        where inln_invoice_number = brel_invoice_number
--        and brel_realization_date between datFrom and datTo
----        and to_char(brel_realization_date,'MM') = to_char(VoucherDate, 'MM')
--        and brel_record_status between 10200001 and 10200004
--        and inln_record_status between 10200001 and 10200004
--        and NVL(inln_process_complete,12400002) = 12400002
--        group by inln_invoice_number, inln_sanctioned_fcy, inln_process_complete, brel_local_bank
--        having inln_sanctioned_fcy <=  sum(brel_realized_fcy);
--    
--    update tftran022 a
--      set (inln_process_complete, inln_completion_date) =
--      (select 12400001, brel_realized_date
--      from process_complete b
--      where a.inln_invoice_number = b.inln_invoice_number)
--      where NVL(inln_process_complete, 12400002) = 12400002
--      and exists
--      (select 'x'
--        from process_complete c
--        where a.inln_invoice_number = c.inln_invoice_number);
--
-------------------- updating Invoice completion status -------------------------- 
--    update tftran001
--    set (invc_process_complete, invc_completion_date) =
--    (select 12400001, realizeddate
--        from vewbillrealized
--        where invc_invoice_number = InvoiceNumber
--        and ((realizedfcy >= (invc_invoice_fcy - invc_advance_fcy))
--        or ((invc_invoice_fcy - invc_advance_fcy) - realizedfcy < 100)))
--    where NVL(invc_process_complete,12400002) = 12400002 
--    and exists
--    (select 'x'
--        from vewbillrealized
--      vewBillRealized
--      where invc_invoice_number = InvoiceNumber
--      and ((realizedfcy >= (invc_invoice_fcy - invc_advance_fcy))
--        or ((invc_invoice_fcy - invc_advance_fcy) - realizedfcy < 100)));
--    
--    delete from process_complete;
--    insert into process_complete
--    with tabRealize as
--    (select ilon_loan_reference, realizeddate, realizedfcy, 
--    sum(invc_invoice_fcy-invc_advance_fcy) invc_invoice_fcy
--    from tftran001, tftran022C, vewbillrealized 
--    where invc_invoice_number = ilon_invoice_number
--    and ilon_loan_reference = InvoiceNumber
--    and ilon_record_status between 10200001 and 10200004
--    and NVL(invc_process_complete,12400002) = 12400002
--    group by ilon_loan_reference, realizeddate, realizedfcy
--    having ((realizedfcy >= sum(invc_invoice_fcy - invc_advance_fcy))  
--    or sum(invc_invoice_fcy - invc_advance_fcy) - realizedfcy < 100 ))
--    select ilon_invoice_number, invc_invoice_fcy, 12400001, 0,  
--      realizeddate, realizedfcy
--      from tabrealize a, vewInvoiceProcessed b
--      where a.ilon_loan_reference = b.ilon_loan_reference;
--    
--    update tftran001
--    set (invc_process_complete,invc_completion_date) = 
--    (select inln_process_complete, brel_realized_date
--    from process_complete
--    where invc_invoice_number = inln_invoice_number)
--    where invc_process_complete = 12400002
--    and exists
--    (select 'x'
--    from process_complete
--    where invc_invoice_number = inln_invoice_number);
--    
--    delete from process_complete;
--
--    varOperation := 'Updating Process Complete for PCL';
--    update tftran025
--      set pkcr_process_complete = 12400001,
--      pkcr_completion_date = 
--      (select max(pkut_utilized_date)
--        from tftran026
--        where pkut_pkgcredit_number = pkcr_pkgcredit_number
--        and pkut_record_status between 10200001 and 10200004)
--      where pkcr_pkgcredit_number in  
--      (select pkcr_pkgcredit_number
--      from tftran025, tftran026
--      where pkcr_pkgcredit_number = pkut_pkgcredit_number
--      and pkcr_currency_code = 20500003
--      and pkcr_process_complete = 12400002
--      and pkcr_sanctioned_inr > 0
--      and pkut_record_status between 10200001 and 10200004
--      group by  pkcr_pkgcredit_number, pkcr_sanctioned_inr
--      having abs(pkcr_sanctioned_inr - sum(pkut_utilized_inr)) < 100);
--
--    varOperation := 'Updating Process Complete for PCFC';
--    update tftran025
--      set pkcr_process_complete = 12400001,
--      pkcr_completion_date = 
--      (select max(pkut_utilized_date)
--        from tftran026
--        where pkut_pkgcredit_number = pkcr_pkgcredit_number
--        and pkut_record_status between 10200001 and 10200004)
--      where pkcr_pkgcredit_number in  
--      (select pkcr_pkgcredit_number
--      from tftran025, tftran026
--      where pkcr_pkgcredit_number = pkut_pkgcredit_number
--      and pkcr_currency_code != 20500003
--      and pkcr_process_complete = 12400002
--      and pkcr_sanctioned_fcy > 0
--      and pkut_record_status between 10200001 and 10200004
--      group by  pkcr_pkgcredit_number, pkcr_sanctioned_fcy
--      having abs(pkcr_sanctioned_fcy - sum(pkut_utilized_fcy)) < 100);
--
------------------------------------------------------------------------------
--    numErrors := 0;
--    numRecords := 0;
--    
--------------------------------------------------------------    
--    varOperation := 'Running Export Freight Process';
--    For Curfreight In
--    (Select distinct Sfrg_Invoice_Number, Sfin_Local_Bank,Sfin_Rtgs_Date
--      From Tftran073, Tftran074
--      Where sfrg_batch_number = sfin_batch_number
--      and sfin_rtgs_date between '01-APR-12' and VoucherDate
----      and sfrg_invoice_date >= '01-NOV-12'
--      and sfrg_record_status between 10200001 and 10200004
--      and sfrg_invoice_number not in
--    	(select sapo_voucher_reference
--      	from system901A_freight))
--    Loop        
--      Begin
--        varReference := curFreight.sfrg_invoice_number;
--        numRecords := numRecords + 1;
--        VarFile := Pkgcurrentinterface.Fncfreightcharges
--                        (Curfreight.Sfrg_Invoice_Number,
--                         Curfreight.Sfin_Local_Bank,
--                         curFreight.sfin_rtgs_date);
--      exception
--      when others then
--        varError := SQLERRM;
--        numErrors := numErrors + 1;
--      End;
--    End Loop;
--
--
--    insert into tfsystem901C(sapl_process_date,sapl_voucher_event,
--      sapl_event_name,sapl_records_processed,sapl_error_records)
--      values(VoucherDate, 24800021,'Export Freight', numRecords, numErrors);   
--    numRecords := 0;
--    numErrors := 0;
--------------------------------------------------------------    
--
--    varOperation := 'Running Export Advance Process';    
--    for curInvoice in
--    (select distinct bcac_voucher_reference, bcac_reference_serial
--    from trtran008
--    where bcac_voucher_type in (24800013)
--    and bcac_voucher_date between datFrom and datTo
--    and bcac_record_status between 10200001 and 10200004
--    and bcac_create_date >= VoucherDate)
----      and bcac_voucher_reference not in
----    (select sapo_voucher_reference
----      from trsystem901a
----    where sapo_voucher_event in (24800013)))
--  
--    Loop
--      Begin
--        varReference := curInvoice.bcac_voucher_reference;
--        numSerial :=  curInvoice.bcac_reference_serial;
--        numRecords := numRecords + 1;
--        varFile := pkgCurrentInterface.fncGeneralFormat(varReference, numSerial);	
--      exception
--        when others then
--          varError := SQLERRM;
--          numErrors := numErrors + 1;
--      End;
--  
--    End Loop;
--
--    insert into tfsystem901C(sapl_process_date,sapl_voucher_event,
--      sapl_event_name,sapl_records_processed,sapl_error_records)
--      values(VoucherDate, 24800013,'Export Advance', numRecords, numErrors);   
--    numRecords := 0;
--    numErrors := 0;
--------------------------------------------------------------    
--
--    varOperation := 'Running Packing Credit Process';    
--    for curInvoice in
--    (select distinct bcac_voucher_reference, bcac_reference_serial 
--      from trtran008
--      where bcac_voucher_type in (24800004, 24800005)
--      and bcac_voucher_date between datFrom and datTo    
----      and to_char(bcac_voucher_date, 'MM') = to_char(VoucherDate, 'MM')
--      and bcac_create_date >= VoucherDate
--      and bcac_record_status between 10200001 and 10200004)
---- and bcac_voucher_reference not in
----	(select sapo_voucher_reference
----		from trsystem901a
----		where sapo_voucher_event in (24800004, 24800005)))
--    Loop
--      Begin
--        varReference := curInvoice.bcac_voucher_reference;
--        numSerial :=  curInvoice.bcac_reference_serial;
--        numRecords := numRecords + 1;
--        varFile := pkgCurrentInterface.fncGeneralFormat(varReference, numSerial);	
--      Exception
--        when others then
--          varError := SQLERRM;
--          numErrors := numErrors + 1;
--        End;          
--    End Loop;
--
--    insert into tfsystem901C(sapl_process_date,sapl_voucher_event,
--      sapl_event_name,sapl_records_processed,sapl_error_records)
--      values(VoucherDate, 24800004,'Packing Credit', numRecords, numErrors);   
--    numRecords := 0;
--    numErrors := 0;
--------------------------------------------------------------    
--
--    varOperation := 'Running Bill Discount Process';    
--    for curInvoice in
--    (select distinct bcac_voucher_reference, bcac_reference_serial
--      from trtran008
--      where bcac_voucher_type in (24800002,24800003)
--      and bcac_voucher_date between datFrom and datTo    
--      and bcac_record_status between 10200001 and 10200004
--      and bcac_create_date >= VoucherDate
--      and bcac_voucher_reference not in
--      (select ilon_loan_reference
--        from tftran022C, tftran001
--        where ilon_invoice_number = invc_invoice_number
--        and ilon_record_status between 10200001 and 10200004
--        group by ilon_loan_reference
--        having count(distinct invc_consignee_code) > 1))   
--      Loop
--      
--      Begin
--        varReference := curInvoice.bcac_voucher_reference;
--        numSerial :=  curInvoice.bcac_reference_serial;
--        numRecords := numRecords + 1;
--        varFile := pkgCurrentInterface.fncPSCFCFormat(varReference, numSerial);	
--      Exception 
--        when others then
--          varError := SQLERRM;
--          numErrors := numErrors + 1;
--      End;
--		
--    End Loop;   
--
--    insert into tfsystem901C(sapl_process_date,sapl_voucher_event,
--      sapl_event_name,sapl_records_processed,sapl_error_records)
--      values(VoucherDate, 24800002,'Bill Discount', numRecords, numErrors);   
--    numRecords := 0;
--    numErrors := 0;
--
---------------- Processing for SBOP - added on 20/03/11 -------    
----abhijit commented for null coming on 27/01/2014 
----update trtran008E a
----set ciaf_voucher_fcy = 
----(select sum(ciaf_voucher_amount)
----  from trtran008E b
----  where b.ciaf_posting_key = 40
----  and b.ciaf_account_number not in(221110,220106)
----  and a.ciaf_document_headertext = b.ciaf_document_headertext) 
----where ciaf_account_number = 270372
----and ciaf_format_file in
----(select sapo_file_name
----  from trsystem901a
----  where sapo_process_complete = 12400002
----  and sapo_local_bank = 22600007);
----
----update trtran008E a
----set ciaf_voucher_fcy = ciaf_voucher_fcy -
----(select sum(ciaf_voucher_amount)
----  from trtran008E c
----  where c.ciaf_account_number = 450003
----  and c.ciaf_posting_key = 50
----  and a.ciaf_document_headertext = c.ciaf_document_headertext)
----where ciaf_account_number = 270372
----and ciaf_format_file in
----(select sapo_file_name
----  from trsystem901a
----  where sapo_process_complete = 12400002
----  and sapo_local_bank = 22600007);
----  
----update trtran008E
----set ciaf_record_content = replace(ciaf_record_content, to_char(ciaf_voucher_amount), to_char(ciaf_voucher_fcy))
----where ciaf_account_number = 270372
----and ciaf_format_file in
----(select sapo_file_name
----  from trsystem901a
----  where sapo_process_complete = 12400002
----  and sapo_local_bank = 22600007);
----  
----update trtran008E
----set ciaf_voucher_amount = ciaf_voucher_fcy
----where ciaf_account_number = 270372
----and ciaf_format_file in
----(select sapo_file_name
----  from trsystem901a
----  where sapo_process_complete = 12400002
----  and sapo_local_bank = 22600007);
----  
----update trsystem901a
----set (sapo_debit_total, sapo_credit_total, sapo_error_text, 
----sapo_process_complete, sapo_completion_date) = 
----(select sum(decode(ciaf_posting_key, 40, ciaf_voucher_amount,0)),
----sum(decode(ciaf_posting_key, 50, ciaf_voucher_amount,0)),
----'Successful Operations', 12400001, sysdate
----from trtran008E
----where ciaf_format_file = sapo_file_name)
----where sapo_voucher_event in (24800002,24800003) 
----and sapo_process_complete = 12400002
----and sapo_local_bank = 22600007;
------------------SBOP --------------------------------------   
----abhijit ends
--
----abhijit commented for below code(new code)
----------------------  IOB - 06/11/2012 ---------------------------------    
----update trtran008E
----set ciaf_record_content = replace(ciaf_record_content, ciaf_voucher_amount, round(ciaf_voucher_amount)),
----ciaf_voucher_amount = round(ciaf_voucher_amount)
----where ciaf_account_number = 221105
----and ciaf_format_file in
----(select sapo_file_name
----from trsystem901a
----where sapo_local_bank = 22600009
----and sapo_process_complete = 12400002);
----
----update trtran008E
----set ciaf_process_complete = 12400002
----where ciaf_process_complete = 12400004
----and ciaf_format_file in
----(select sapo_file_name
----from trsystem901a
----where sapo_local_bank = 22600009
----and sapo_process_complete = 12400002);
----
----
----update trsystem901a
----set sapo_credit_total = round(sapo_credit_total),
----sapo_error_text = 'Successful Operations',
----sapo_process_complete = 12400001,
----sapo_completion_date = Sysdate
----where sapo_local_bank = 22600009
----and sapo_process_complete = 12400002;
--
-------------------------------------------------------------
--    
-------------------------abhijit added for rounding of EBD amount who is having diff <=1  19/01/2015---
-----
--update trtran008E
--set ciaf_record_content = replace(ciaf_record_content, ciaf_voucher_amount, round(ciaf_voucher_amount)),
--ciaf_voucher_amount = round(ciaf_voucher_amount)
--where ciaf_account_number in(221101,221102,221103,221104,221105,221106,221107,221108,221109,221110,221111,221112,221113,
--                              221114,221115,221116,221122,221123,221124,221125,221126,221133)
--and ciaf_format_file in
--(select sapo_file_name
--from trsystem901a
--where 
--nvl(sapo_debit_total - sapo_credit_total,0) <=1
----sapo_local_bank in (22600001,22600002,22600004,22600006,22600008,22600016,22600017)
--and sapo_process_complete = 12400002);
--
--
--update trtran008E
--set ciaf_process_complete = 12400002
--where ciaf_process_complete = 12400004
--and ciaf_format_file in
--(select sapo_file_name
--from trsystem901a
--where nvl(sapo_debit_total - sapo_credit_total,0) <=1
----sapo_local_bank in (22600001,22600002,22600004,22600006,22600008,22600016,22600017)
--and sapo_process_complete = 12400002);
--
--update trsystem901a
--set sapo_credit_total = round(sapo_credit_total),
--sapo_error_text = 'Successful Operations',
--sapo_process_complete = 12400001,
--sapo_completion_date = Sysdate
--where nvl(sapo_debit_total - sapo_credit_total,0) <=1
----sapo_local_bank in (22600001,22600002,22600004,22600006,22600008,22600016,22600017)
--and sapo_process_complete = 12400002;
--    
---------------abhijit ends------------------  
--    
--
--    varOperation := 'Running Full Realization Process';      
--    for curInvoice in
--    (select distinct bcac_voucher_reference, bcac_reference_serial
--      from trtran008
--      where bcac_record_status between 10200001 and 10200004
--      and bcac_voucher_type = 24800006
--      and bcac_voucher_date between datFrom and datTo    
----      and to_char(bcac_voucher_date, 'MM') = to_char(VoucherDate, 'MM')
--      and bcac_create_date >= VoucherDate
--      and bcac_voucher_reference in
--      (select inln_invoice_number
--    		from tftran022
--    		where inln_record_status between 10200001 and 10200004
--    		and inln_process_complete = 12400001
--    		and inln_invoice_number in
--  		(select brel_invoice_number
--    			from tftran023
--    		where brel_record_status between 10200001 and 10200004
--    		group by brel_invoice_number
--    		having count(*) = 1)))
----		and bcac_voucher_reference not in
----		(select sapo_voucher_reference
----			from trsystem901a
----		where sapo_voucher_event in (24800006)))
--
--      Loop
--        Begin
--          varReference := curInvoice.bcac_voucher_reference;
--          numSerial :=  curInvoice.bcac_reference_serial;
--          numRecords := numRecords + 1;
--          varFile := pkgCurrentInterface.fncBillRealize(varReference, numSerial);	
--        exception
--          when others then
--            varError := SQLERRM;
--            numErrors := numErrors + 1;
--        End;
--     End Loop;
--
--    insert into tfsystem901C(sapl_process_date,sapl_voucher_event,
--      sapl_event_name,sapl_records_processed,sapl_error_records)
--      values(VoucherDate, 24800006,'Full Realize', numRecords, numErrors);   
--    numRecords := 0;
--    numErrors := 0;
--------------------------------------------------------------    
--
--    varOperation := 'Running Partial Realization Process';      
--    for curInvoice in
--    (select distinct bcac_voucher_reference, bcac_reference_serial
--      from trtran008
--      where bcac_voucher_type = 24800006
--      and bcac_voucher_date between datFrom and datTo    
----     and to_char(bcac_voucher_date, 'MM') = to_char(VoucherDate, 'MM')
--      and bcac_create_date >= VoucherDate
--      and bcac_record_status between 10200001 and 10200004
--      and bcac_voucher_reference in
--      (select brel_invoice_number
--        from tftran023, tftran022
--        where brel_invoice_number = inln_invoice_number
--        and (NVL(inln_process_complete,12400002) = 12400002 or
--        brel_realization_number > 101)))
----        and bcac_voucher_reference not in
----        (select sapo_voucher_reference
----          from trsystem901a
----        where sapo_voucher_event in (24800006)))
--    
--      Loop
--        Begin
--          varReference := curInvoice.bcac_voucher_reference;
--          numSerial :=  curInvoice.bcac_reference_serial;
--          numRecords := numRecords + 1;
--          varFile := pkgCurrentInterface.fncBillRealize(varReference, numSerial);	
--        exception
--          when others then
--            varError := SQLERRM;
--            numErrors := numErrors + 1;
--        End;
--    
--      End Loop;
--
--    insert into tfsystem901C(sapl_process_date,sapl_voucher_event,
--      sapl_event_name,sapl_records_processed,sapl_error_records)
--      values(VoucherDate, 24800006,'Partial', numRecords, numErrors);   
--    numRecords := 0;
--    numErrors := 0;
--------------------------------------------------------------    
--
--    varOperation := 'Running Collection Bill Realization Process';      
--    for curInvoice in
--    (select distinct bcac_voucher_reference, bcac_reference_serial
--      from trtran008
--      where bcac_voucher_type = 24800006
--      and bcac_voucher_date between datFrom and datTo    
----      and to_char(bcac_voucher_date, 'MM') = to_char(VoucherDate, 'MM')
--      and bcac_create_date >= VoucherDate
--      and bcac_record_status between 10200001 and 10200004
--      and bcac_voucher_reference not in
--      (select inln_invoice_number
--        from tftran022
--        where inln_record_status between 10200001 and 10200004))    
----      and bcac_voucher_reference not in
----      (select sapo_voucher_reference
----        from trsystem901a
----      where sapo_voucher_event in (24800006)))
--    Loop
--      Begin
--        varReference := curInvoice.bcac_voucher_reference;
--        numSerial :=  curInvoice.bcac_reference_serial;
--        numRecords := numRecords + 1;
--        varFile := pkgCurrentInterface.fncBillRealize(varReference, numSerial);	
--      exception
--        when others then
--          varError := SQLERRM;
--          numErrors := numErrors + 1;
--      End;
--
--	End Loop;
--  
--  insert into tfsystem901C(sapl_process_date,sapl_voucher_event,
--    sapl_event_name,sapl_records_processed,sapl_error_records)
--    values(VoucherDate, 24800021,'Collection', numRecords, numErrors);   
--  numRecords := 0;
--  numErrors := 0;
--------------------------------------------------------------    
--    
--  varOperation := 'Updating Error Transactions';
--  update trtran008E
--    set ciaf_process_complete = 12400004
--    where ciaf_format_file in
--    (select sapo_file_name
--      from trsystem901a
--      where sapo_process_complete = 12400002)
--    and ciaf_process_complete = 12400002;      
--    
--  update trtran008E
--  set ciaf_process_complete = 12400005
--  where ciaf_format_type in ('F-02D', 'F-02R');
--  
----  insert into system901a_freight
----  select * from trsystem901a
----  where sapo_voucher_event = 24800021;
--
----  insert into tran053e_from0110
----  select * from trtran008E;
--
----  insert into system901a_from0110
----  select * from trsystem901a;
--
--  Commit;
--  numError := fncExportRegister(VoucherDate);
--  return numError;
--Exception
--When others then
--      numError := SQLCODE;
--      varError := SQLERRM;
--      varError := GConst.fncReturnError('RunInterface', numError, varMessage, 
--                      Varoperation, Varerror);
--      numError := fncAuditTrail(varError);                      
--      raise_application_error(-20101, varError);
--      ROLLBACK;
--      return numError;
--End fncRunInterface;

--Function fncCostCenter 
--    (   numCompanyCode in number,
--        numLocationCode in number,
--        numLOBCode in number,
--        numEventType in number
--    )
--    return Varchar2
--as
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    numError number;
--   varTemp varchar(20);
--   varEventType varchar(20);
--begin
--   
--
--   
----   if numEventType =GConst.EVENTEXPORTBILL 
----      OR numEventType = GConst.EVENTEXPORTADVANCE 
----      OR numEventType = GConst.EVENTIMPORTBILL
----      or NumEventType =Gconst.eventLoanClosure then  -- here we need to extend this for other events also
----      varEventType:= 'GL';
----   elsif numEventType =GConst.EVENTMANUAL then  -- here we need to extend this for other events also
----        varEventType:= 'Interest';
----   elsif NumEventType = Gconst.EVENTBANKCHARGES then
----        varEventType:= 'BankCharges';
----   else 
--      varEventType:= 'ForexGainLoss';
----   end if;
--   
--   Varoperation:= numCompanyCode || ',' || numLocationCode || ',' ||  numLOBCode || ',' ||  varEventType;
--   if varEventType = 'ForexGainLoss' then 
--       select COST_SAP_COSTCENTRE
--        into VarTemp
--       from trtran008K
--       where Cost_company_code = numCompanyCode
--    --    and nvl(COST_Location_code,numLocationCode) =numLocationCode
--        and cost_lob_code= numLOBCode
--        and COST_EVENT_TYPE= varEventType;
--  else
--      select COST_SAP_COSTCENTRE
--        into VarTemp
--       from trtran008K
--       where Cost_company_code = numCompanyCode
--       -- and nvl(COST_Location_code,numLocationCode) =numLocationCode
--        and cost_lob_code= numLOBCode
--        and COST_EVENT_TYPE= varEventType;
--  end if;
  
-- return VarTemp;
--Exception
--When others then
--      numError := SQLCODE;
--      varError := SQLERRM;
--      varError := GConst.fncReturnError('fncCostCenter', numError, varMessage, 
--                      Varoperation, Varerror);
--      numError := fncAuditTrail(varError);                      
--      raise_application_error(-20101, varError);
--      return numError;
--end fncCostCenter; 

--Function fncBankCharges(
--    varInvoiceNumber in varchar2,
--    EventCode in Number
--    )
--    return number
--as
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    numError number;
--    varDocType varchar(2);
--    --numRelizedFcy number(15,2);
--    numVoucherFcy number(15,2);
--begin 
--   select sum(bcac_voucher_inr) 
--     into numVoucherFcy
--    from trtran008 
--    where bcac_voucher_reference =varInvoiceNumber
--     and bcac_voucher_type in (248000
--     and bcac_account_head > 24900050;
-- 
-- return numVoucherFcy;
-- Exception
--When others then
--      numError := SQLCODE;
--      varError := SQLERRM;
--      varError := GConst.fncReturnError('fncCrossCurrencyGainLoss', numError, varMessage, 
--                      Varoperation, Varerror);
--      numError := fncAuditTrail(varError);                      
--      raise_application_error(-20101, varError);
--      return numError;
--end fncBankCharges;

--procedure  prcRunInterface 
--(datCurrentDate in Date)
--as 
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    varTemp varchar(50);
--    numError            number;
--    datCCurrentDate   date;
--    varAlertTo         varchar(500);
--    varAlertCC         varchar(500);
--    varAlertBcc        varchar(500);
--    varemailString     clob;
--    varHeader          varchar(4000);
--    varTemp2           varchar(4000);
--begin 
-- insert into temp values ('IBS to SAP Process started for ' || datCCurrentDate);
----changed temporarily to avoid duplicate records.
-- insert into trtran008J_Bkp select * from trtran008J;commit;
-- delete from trtran008J;commit;
-- 
--  if datCurrentDate= '01-Jan-2099' then
--      datCCurrentDate:= sysdate;
--  else 
--     datCCurrentDate := datCurrentDate;
--  end if;
----  varTemp := fncImportAdvance(datCCurrentDate) ;
----  varTemp := fncexportAdvance(datCCurrentDate) ;
----  varTemp := fncBillrealize(datCCurrentDate) ;
----  vartemp := fncImportFormat (datCCurrentDate);
----  vartemp :=  fncLoanClosure (datCCurrentDate);
----  vartemp :=  fncPCFCAvailment (datCCurrentDate);
----  vartemp :=  fncTreasuryFX (datCCurrentDate);
----  vartemp :=  fncRTGSTransfer (datCCurrentDate);
----  vartemp :=  fncPBD (datCCurrentDate);
----  vartemp :=  fncPBDRelization (datCCurrentDate);
----  vartemp :=  fncCCSCashFlow (datCCurrentDate);
----  vartemp :=  fncA2RemittanceFormat(datCCurrentDate);
--  
--    select  ALRT_ALERT_To ,
--           ALRT_ALERT_CC,ALRT_ALERT_BCC 
--      into varAlertTo,varAlertCC,varAlertBcc
--    from trsystem967
--    where ALRT_ALERT_Name= 'IBSTOSAPINTERFACE';
--   
--    varemailString := '<Table><TR><h3>Files generated successfully</h3></TR>' ;
--    varHeader:='<TR><TABLE BORDER=1 BGCOLOR=#EEEEEE>';
--    varHeader:=varHeader||'<TR BGCOLOR=Gray>';
--    varHeader:=varHeader||'<TH><FONT COLOR=WHITE>Format Type</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR=WHITE>No of Files</FONT></TH>';
--    varHeader:=varHeader||'</TR>';
--    varemailString:=varemailString || varHeader;
--    varOperation := 'Creating prepare HTML table for sending e-mail on the file process';
--    FOR CUR IN(select SIAF_Format_type Format ,count(*) NoofFiles
--                         from trtran008J
--                        group by SIAF_Format_type)
--    loop 
--      
--      varTemp2:='';
--      varTemp2:=varTemp2 || '<TR BGCOLOR=WHITE>';
--      varTemp2:=varTemp2 || '<td>'||Cur.Format||'</td>';
--      varTemp2:=varTemp2 || '<td>'||Cur.NoofFiles||'</td>';
--      varTemp2:=varTemp2 || '</TR>';
--      varemailString := varemailString || varTemp2;     
--    end loop;
--    varemailString := varemailString || '</TABLE></TR>';
--    
--    varOperation := 'Creating prepare HTML table for sending e-mail on the Errors while Creating files ';
--    varemailString := varemailString || '<h3>Transactions not processed because of below errors</h3>';
--    varHeader:='<TR> <TABLE BORDER=1 BGCOLOR=#EEEEEE>';
--    varHeader:=varHeader||'<TR BGCOLOR=Gray>';
--    varHeader:=varHeader||'<TH><FONT COLOR=WHITE>File Name</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR=WHITE>Reference Date</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR=WHITE>Reference No</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR=WHITE>Reference Serial</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR=WHITE>Voucher Event</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR=WHITE>Bank</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR=WHITE>Format Type</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR=WHITE>Error Details</FONT></TH>';
--    varHeader:=varHeader||'</TR>';
--    varemailString:=varemailString || varHeader;
--    FOR CUR IN( select  sapo_File_name FileName, sapo_voucher_date ReferenceDate, 
--                        sapo_voucher_reference Voucherreference, sapo_voucher_serial Referenceserial,
--                        pkgreturncursor.fncgetdescription(sapo_voucher_event,1) Event,
--                        pkgreturncursor.fncgetdescription(sapo_local_bank,1)Bank,
--                        sapo_format_types Format, sapo_time_stamp FilegenerationTime, 
--                        sapo_error_text ErrorMsg
--               from trsystem901a
--                where trunc(SAPO_ADD_DATE)= datCCurrentDate
--                and nvl(SAPO_EmailSent_YesNo,12400002)=12400002)
--    loop 
--      varOperation := 'Generating Confirmation Pending Auto mail';
--      varTemp2:='';
--      varTemp2:=varTemp2 || '<TR BGCOLOR=WHITE>';
--      varTemp2:=varTemp2 || '<td>'||Cur.FileName||'</td>';
--      varTemp2:=varTemp2 || '<td>'||Cur.ReferenceDate||'</td>';
--      varTemp2:=varTemp2 || '<td>'||Cur.Voucherreference||'</td>';
--      varTemp2:=varTemp2 || '<td>'||Cur.Referenceserial||'</td>';
--      varTemp2:=varTemp2 || '<td>'||Cur.Event||'</td>';
--      varTemp2:=varTemp2 || '<td>'||Cur.Bank||'</td>';
--      varTemp2:=varTemp2 || '<td>'||Cur.Format||'</td>';
--      varTemp2:=varTemp2 || '<td>'||Cur.ErrorMsg||'</td>';
--      varTemp2:=varTemp2 || '</tr>';
--      varemailString := varemailString || varTemp2;     
--    end loop;
--     varOperation := 'Sending E-mail';
--  varemailString := varemailString || '</TABLE></TR></TABLE>';
--   pkgsendingmail.send_mail (varAlertTo,varAlertCC,varAlertBcc,
--      'IBS to SAP data Interface- Files has been Generated for the Date ' || datCCurrentDate,
--      null,null,varemailString);
--
--   varOperation := 'Update the Error table with Process complete to not send the same error if we re run the process';
--   
--   update trsystem901a set  SAPO_EmailSent_YesNo =12400001
--          where nvl(SAPO_EmailSent_YesNo,12400002)=12400002
--          and trunc(SAPO_ADD_DATE)=datCCurrentDate;
--          
-- -- apex_mail_p.mail ('fxtreasury-icc@modi.com',varAlertTo || ';' || varAlertCC , 'IBS to SAP data Interface- Files processed Sucessfully',varemailString); 
----  insert into temp values (varemailString);
---- insert into temp values ('IBS to SAP Process Ended for ' || datCCurrentDate);
---- commit;
-- 
--Exception
--When others then
--      numError := SQLCODE;
--      varError := SQLERRM;
--      varError := GConst.fncReturnError('BillRealize', numError, varMessage, Varoperation, Varerror);
--      numError := fncAuditTrail(varError);                      
--      raise_application_error(-20101, varError);
--end prcRunInterface;
Function fncFXExchangeRate(datCreateDate in Date)
    return varchar2 as

   PRAGMA AUTONOMOUS_TRANSACTION;
    numError            number;
    numRealize          number(2);
    numRecords          number(5);
    numFile             number(5);
    numCode             number(8);
    numType             number(8);
    numProcess          number(8);
    numCredit           number(15,4);
    numDebit            number(15,4);
    numBalance          number(15,4);
    numExchange         number(15,4);
    datVoucher          date;
    datProcess          date;
    varFlag             varchar2(15);
    varKey              varchar2(10);
    varCurrency         varchar2(10);
    varFileName         varchar2(30);
    varTimeStamp        varchar2(25);
    varReference        varchar2(25);
    varReference1       varchar2(30);
    Varfile             Varchar2(50);
    Varformats          Varchar2(50);
    varInvoices         varchar2(256);
    varText             varchar2(200);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    numRowCount1         number(10);
    numRowCount2         number(10);
    numSerial           number(10);
    chrCurrentACCheck   char(1);
    numVoucherType     number(10);

begin
  gFileName := 'VF_02' || to_char(datCreateDate, 'YYYYMMDD');
  for cur in (SELECT hedg_trade_reference,
    hedg_deal_number,
    deal_exchange_rate,deal_user_reference
  FROM trtran004,trtran001
  WHERE deal_deal_number      = hedg_deal_number
  AND deal_record_status NOT IN(10200005,10200006)
  AND hedg_record_status NOT IN(10200005,10200006)
  AND deal_deal_type NOT     IN(25400001)
  AND hedg_linked_date = datCreateDate)
  loop
    INSERT INTO trtran008c
      (CIAF_FORMAT_FILE,CIAF_VOUCHER_NUMBER,CIAF_SERIAL_NUMBER,CIAF_FORMAT_TYPE,
      CIAF_COMPANY_CODE,CIAF_FILE_NUMBER,CIAF_POSTING_DATE,
      CIAF_CURRENCY_CODE,CIAF_EXCHANGE_RATE,CIAF_REFERENCE_NUMBER,
      CIAF_DOCUMENT_HEADERTEXT,CIAF_PROCESS_COMPLETE,
      CIAF_TIME_STAMP,CIAF_CREATE_DATE,CIAF_RECORD_STATUS,CIAF_BANK_REFERENCE)
      values(gFileName,null,1,null,30100001,1,datCreateDate,30400004,cur.deal_exchange_rate,cur.hedg_trade_reference,
      null,12400001,sysdate,sysdate,10200001,null);
  
  end loop;
  
Exception
When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('LoanClosure', numError, varMessage, 
                      Varoperation, Varerror);
      numError := fncAuditTrail(varError);                      
      raise_application_error(-20101, varError);                      
      return varFile;
End fncFXExchangeRate;


Function fncFXExchangeRateBC(datCreateDate in Date)
    return varchar2 as

   PRAGMA AUTONOMOUS_TRANSACTION;
    numError            number;
    numRealize          number(2);
    numRecords          number(5);
    numFile             number(5);
    numCode             number(8);
    numType             number(8);
    numProcess          number(8);
    numCredit           number(15,4);
    numDebit            number(15,4);
    numBalance          number(15,4);
    numExchange         number(15,4);
    datVoucher          date;
    datProcess          date;
    varFlag             varchar2(15);
    varKey              varchar2(10);
    varCurrency         varchar2(10);
    varFileName         varchar2(30);
    varTimeStamp        varchar2(25);
    varReference        varchar2(25);
    varReference1       varchar2(30);
    Varfile             Varchar2(50);
    Varformats          Varchar2(50);
    varInvoices         varchar2(256);
    varText             varchar2(200);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    numRowCount1         number(10);
    numRowCount2         number(10);
    numSerial           number(10);
    chrCurrentACCheck   char(1);
    numVoucherType     number(10);
    numCount            number(10);

begin
  gFileName := 'VF_02' || to_char(datCreateDate, 'YYYYMMDD');
  
  for curbc in (select bcrd_buyers_credit,bcrd_loan_remarks, trad_trade_reference,trad_contract_no 
                from trtran045 inner join trtran002
                on trad_contract_no = bcrd_loan_remarks
                where to_date(bcrd_create_date)=datCreateDate
                and bcrd_record_status not in (10200005,10200006)
                and trad_record_status not in (10200005,10200006))
                
      loop
          
          select count(*) 
          into numCount 
          from trtran004
          where hedg_trade_reference=curbc.trad_trade_reference
          and hedg_record_status not in (10200005,10200006,10200012);
          
          if numCount = 0 then
          
              update trtran045 set bcrd_product_detail = 'Not Hedged'
              where bcrd_buyers_credit = curbc.bcrd_buyers_credit;
          
          else
              for cur in (SELECT hedg_trade_reference,
                          hedg_deal_number,deal_base_currency,
                          deal_exchange_rate,hedg_hedged_fcy,deal_user_reference,rownum
              FROM trtran004,trtran001
              WHERE deal_deal_number      = hedg_deal_number
              AND HEDG_TRADE_REFERENCE=CURBC.TRAD_TRADE_REFERENCE
              AND deal_record_status NOT IN(10200005,10200006)
              AND hedg_record_status NOT IN(10200005,10200006)
              AND deal_deal_type NOT     IN(25400001))
      
              LOOP
                    INSERT INTO trtran008c
                    (CIAF_FORMAT_FILE,CIAF_VOUCHER_NUMBER,CIAF_SERIAL_NUMBER,CIAF_FORMAT_TYPE,
                    CIAF_COMPANY_CODE,CIAF_FILE_NUMBER,CIAF_POSTING_DATE,
                    CIAF_CURRENCY_CODE,CIAF_EXCHANGE_RATE,CIAF_REFERENCE_NUMBER,
                    CIAF_DOCUMENT_HEADERTEXT,CIAF_PROCESS_COMPLETE,CIAF_DOCUMENT_NUMBER,
                    CIAF_TIME_STAMP,CIAF_CREATE_DATE,CIAF_RECORD_STATUS,CIAF_BANK_REFERENCE)
                    values(gFileName||cur.rownum,1,1,null,
                    30100001,1,datCreateDate,
                    pkgreturncursor.fncgetdescription(cur.deal_base_currency,2),cur.deal_exchange_rate,cur.hedg_trade_reference,
                    CURBC.BCRD_BUYERS_CREDIT,12400001,CUR.HEDG_DEAL_NUMBER,
                    sysdate,sysdate,10200001,null);
                    
                    update trtran045 set 
                    BCRD_PRODUCT_DETAIL = 'HEDGED',
                    BCRD_HEDGE_REFERENCE = CUR.HEDG_DEAL_NUMBER,
                    BCRD_HEDGE_DATE = datCreateDate,
                    BCRD_HEDGE_RATE = CUR.DEAL_EXCHANGE_RATE,
                    BCRD_HEDGE_AMOUNT = CUR.HEDG_HEDGED_FCY
                    WHERE BCRD_BUYERS_CREDIT = CURBC.BCRD_BUYERS_CREDIT;
                    
                    COMMIT;
                    
              END LOOP;

          end if;
      end loop;
      
      return varFile;

Exception
When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('FXExchangeRateBC', numError, varMessage, 
                      Varoperation, Varerror);
      numError := fncAuditTrail(varError);                      
      raise_application_error(-20101, varError);                      
      return varFile;
End fncFXExchangeRateBC;


Function fncTreasuryFWD    
    (   datCreateDate in Date)
    return varchar2 as
--  Created on 04/01/10 by T M Manjunath
    PRAGMA AUTONOMOUS_TRANSACTION;
    numError            number;
    numRealize          number(2);
    numRecords          number(5);
    numFile             number(5);
    numCode             number(8);
    numType             number(8);
    numProcess          number(8);
    numCredit           number(15,4);
    numDebit            number(15,4);
    numBalance          number(15,4);
    numExchange         number(15,4);
    datVoucher          date;
    datProcess          date;
    varFlag             varchar2(15);
    varKey              varchar2(10);
    varCurrency         varchar2(10);
    varFileName         varchar2(30);
    varTimeStamp        varchar2(25);
    varReference        varchar2(25);
    varReference1       varchar2(30);
    Varfile             Varchar2(50);
    Varformats          Varchar2(50);
    varInvoices         varchar2(256);
    varText             varchar2(200);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    numRowCount1         number(10);
    numRowCount2         number(10);
    numSerial           number(10);
    chrCurrentACCheck   char(1);
    numVoucherType     number(10);

  begin


       
    varOperation := 'Creating FB50 format for FX';
        
    for cur in (select bcac_voucher_reference,bcac_reference_serial,bcac_account_head,
                  bcac_voucher_date,bcac_voucher_type
                from TRTRAN008   
--              inner join TRTRAN006 
--          on bcac_voucher_reference = cdel_deal_number
--          and bcac_reference_serial=cdel_reverse_serial
       where 
--       bcac_voucher_type = 24800051 --bcac_voucher_type = 24800099
--          and 
          trunc(BCAC_ADD_DATE,'dd') =datCreateDate
          and bcac_record_status in (10200003)
          AND bcac_voucher_reference NOT IN(SELECT CIAF_REFERENCE_NUMBER FROM TRTRAN008C)
--          and cdel_record_status in (10200003)
          group by bcac_voucher_reference,bcac_reference_serial,bcac_account_head,
                  bcac_voucher_date,bcac_voucher_type)
                  --,bcac_local_bank)
  loop 

    --gVoucherDate := datVoucher;
    varOperation := 'FB50 Update Global Variables ';
     gFileName := 'IBS_FB50_' || to_char(datCreateDate, 'YYYYMMDD');
     gVoucherDate:= cur.bcac_voucher_date;
     gVoucherReference:= cur.bcac_voucher_reference;
     gVoucherSerial:= cur.bcac_reference_serial;
     gLocalBank:= 30699999;
     gTimeStamp:= to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3');
     gPackageName :='fncBillRealize';
     numVoucherType := cur.bcac_voucher_type;
     
--     numSerial := 1;


     begin
        varOperation := 'FB50 FX transactions Ref ' || cur.bcac_voucher_reference || ' Ref Sr No ' || cur.bcac_reference_serial ;
        insert into temp values(cur.bcac_voucher_reference,cur.bcac_voucher_date);commit;
        
--        numSerial := numSerial + 1 ;

--          insert into trtran008J (
--          siaf_format_file,siaf_voucher_number,siaf_serial_number,siaf_format_type,
--          siaf_file_number,siaf_document_date, siaf_posting_date,siaf_company_code,
--          siaf_icompany_code,siaf_fiscal_period,siaf_fiscal_year,siaf_bank_reference,
--          siaf_voucher_reference, siaf_document_type,
--          siaf_account_head,siaf_voucher_date,
--          siaf_voucher_detail,siaf_assignment_reference,
--          siaf_assignment_DZ,
--          siaf_customer_code,siaf_account_type,siaf_voucher_currency,siaf_voucher_rate,siaf_voucher_fcy,
--          siaf_voucher_inr,siaf_DocProcess_complete,siaf_process_complete, siaf_time_stamp,siaf_create_date,
--          siaf_record_status,siaf_posting_key,siaf_accountno_gainloss,siaf_cost_center,
--          siaf_business_place,siaf_crosscurr_gainloss,siaf_reference_number,Siaf_reference_date,
--          siaf_account_number,SIAF_REFERENCE_SERIAL,SIAF_BANK_CHARGES,SIAF_GL_ColPos,SIAF_Interest_ColPos)
--      
--       
--       With CTE as (
--       select 'IBS_FB50_' || to_char(datCreateDate, 'YYYYMMDD')  siaf_format_file,
--            bcac_voucher_number siaf_voucher_number,
--           --to_number(substr(bcac_voucher_number,7,5)) siaf_serial_number,
--           0 siaf_serial_number,
--           'FB50' siaf_format_type ,
--           'IBS_FB50_' || to_char(datCreateDate, 'YYYYMMDDHH24MISS') || lpad((substr(bcac_voucher_number,7,5)),4,'0') siaf_file_number,
--           bcac_create_date siaf_document_date,  bcac_voucher_date siaf_posting_date,
--           --fncCompanyCode(bnkc_company_code) siaf_company_code,
--          -- decode(PKGINDOFILCURRENTINTERFACE.fncGetLobCode(bcac_voucher_reference,1,23600002),32600002,2000,1000) siaf_company_code,
--          1000 siaf_company_code,
--          '1000' siaf_icompany_code ,-- fncCompanyCode(bcac_company_code,0) siaf_icompany_code, Hard coded As Nilesh Said over the phone it is allways 1000
--           EXTRACT(MONTH FROM (ADD_MONTHS (bcac_voucher_date,-3))) siaf_fiscal_period,
--              fncgetfiscalyear(BCAC_VOUCHER_DATE) siaf_fiscal_year,
--         --  TO_CHAR(TRUNC(ADD_MONTHS(BCAC_VOUCHER_DATE,1),'yyyy'),'yyyy') siaf_fiscal_year,
--         --  to_char(bcac_voucher_date,'mm'),to_char(bcac_voucher_date,'yyyy'),
--           Cdel_dealer_Remark siaf_bank_reference,bcac_voucher_reference siaf_voucher_reference,
--                      'FX' siaf_document_type ,
--          
--           fncAccountHead(PKGRETURNCURSOR.fncGetTradeFiananceCode(bcac_local_bank),
--              BCAC_ACCOUNT_HEAD,decode(sign(cdel_profit_loss),-1,14600002,14600001),20599999,32699999,
--           24899999,23699999,'NA',PKGRETURNCURSOR.fncGetTradeFiananceCode(fncFXDealBuysell(cdel_deal_number,cdel_reverse_serial))) siaf_account_head,
--           bcac_voucher_date siaf_voucher_date,  BCAC_VOUCHER_DETAIL siaf_voucher_detail, 
--           substr(bcac_voucher_reference,1,18) siaf_assignment_reference,
--         BCAC_BANK_REFERENCE  siaf_assignment_DZ, '' siaf_customer_code,'D' siaf_account_type,
--           pkgreturncursor.fncgetdescription(PKGRETURNCURSOR.fncGetTradeFiananceCode(bcac_Voucher_currency),2)  siaf_voucher_currency , 
--           BCAC_VOUCHER_RATE Siaf_voucher_rate,
--          BCAC_VOUCHER_FCY siaf_voucher_fcy,  BCAC_VOUCHER_INR Siaf_Voucher_inr,
--          12400001 siaf_DocProcess_complete, 
--          12400002 siaf_process_complete,
--          to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3') siaf_time_stamp,
--           trunc(BCAC_ADD_DATE) siaf_create_date,10200001 siaf_record_status,
--          decode( PKGRETURNCURSOR.fncGetTradeFiananceCode(BCAC_CRDR_CODE), 14600001,50,14600002,40) siaf_posting_key,
--          0 siaf_accountno_gainloss, 
--           pkgIndofilCurrentInterface.fncCostCenter(10300501,30299999,32600001,Gconst.EventBankCharges) siaf_cost_center,
--           1000 siaf_business_place,
--         -- decode(pkgIndofilCurrentInterface.fncGetLobCode(bcac_voucher_reference,bcac_reference_serial,INTC_LOAN_TYPE),32600002,2000,1000) siaf_business_place,
--          --fncCompanyCode(bcac_company_code) siaf_business_place, --0 siaf_crosscurr_gainloss,
--          0 siaf_crosscurr_gainloss,
--          bcac_voucher_reference siaf_reference_number,cdel_cancel_date Siaf_reference_date,
--          fncAccountNumber(PKGRETURNCURSOR.fncGetTradeFiananceCode(BCAC_LOCAL_BANK),BCAC_ACCOUNT_HEAD,
--                        PKGRETURNCURSOR.fncGetTradeFiananceCode(BCAC_CRDR_CODE)) siaf_account_number,
--          bcac_reference_serial SIAF_REFERENCE_SERIAL, 0 SIAF_BANK_CHARGES,
--          Row_number() over ( Partition by bcac_voucher_reference,bcac_voucher_currency 
--             Order by bcac_voucher_reference,bcac_reference_serial,bcac_account_head) RoWNumber ,
--          null InterestYN,
--          (case when (bcac_account_head <24900028) then 1 else Null end) GLYN
--           from TRTRAN008  c 
--              inner join TRTRAN006 
--          on bcac_voucher_reference = cdel_deal_number
--          and bcac_reference_serial=cdel_reverse_serial
--       where bcac_voucher_type = 24800051 --bcac_voucher_type = 24800099
--        and bcac_account_head not in ( 24900029,24900030,24900028,24900033) -- NO Need to send the details 
--       -- AND BCAC_VOUCHER_FCY != 0
--        and trunc(BCAC_ADD_DATE,'dd') =datCreateDate
--        and bcac_voucher_reference= cur.bcac_voucher_reference
--        and bcac_reference_serial= cur.bcac_reference_serial
--        and bcac_record_status in (10200003)
--        and cdel_record_status in (10200003))
--        select siaf_format_file,siaf_voucher_number,siaf_serial_number,siaf_format_type,
--          siaf_file_number,siaf_document_date, siaf_posting_date,siaf_company_code,
--          siaf_icompany_code,siaf_fiscal_period,siaf_fiscal_year,siaf_bank_reference,
--          siaf_voucher_reference, siaf_document_type,
--          siaf_account_head,siaf_voucher_date,
--          siaf_voucher_detail,siaf_assignment_reference,
--          siaf_assignment_DZ,
--          siaf_customer_code,siaf_account_type,siaf_voucher_currency,siaf_voucher_rate,siaf_voucher_fcy,
--          siaf_voucher_inr,siaf_DocProcess_complete,siaf_process_complete, siaf_time_stamp,siaf_create_date,
--          siaf_record_status,siaf_posting_key,siaf_accountno_gainloss,siaf_cost_center,
--          siaf_business_place,siaf_crosscurr_gainloss,siaf_reference_number,Siaf_reference_date,
--          siaf_account_number,SIAF_REFERENCE_SERIAL,SIAF_BANK_CHARGES,GLYN,InterestYN 
--         
--       from CTE
--        where RoWNumber=1;

    if numVoucherType = 24800051 then
           select count(*),sum(bcac_voucher_inr) into numRowCount2,numRowCount1
           from trtran008
           where  trunc(BCAC_ADD_DATE,'dd') =datCreateDate
           and bcac_voucher_reference = cur.bcac_voucher_reference
           and bcac_reference_serial=cur.bcac_reference_serial
           and bcac_account_head between 24900050 and 24900149
           group by bcac_voucher_reference,bcac_reference_serial;    
          insert into trtran008c
          (CIAF_FORMAT_FILE, CIAF_VOUCHER_NUMBER, CIAF_SERIAL_NUMBER, CIAF_FORMAT_TYPE,
          CIAF_COMPANY_CODE, CIAF_VALUE_DATE,CIAF_FILE_NUMBER, 
          CIAF_DOCUMENT_DATE, CIAF_POSTING_DATE, CIAF_DOCUMENT_TYPE,
          CIAF_CURRENCY_CODE, CIAF_EXCHANGE_RATE, CIAF_REFERENCE_NUMBER, 
          CIAF_DOCUMENT_HEADERTEXT,CIAF_POSTING_KEY, 
          CIAF_ACCOUNT_NUMBER, CIAF_VOUCHER_AMOUNT, CIAF_DOCUMENT_NUMBER,
          CIAF_BANK_ACCOUNT, CIAF_PROFIT_CENTER, CIAF_COST_CENTER, CIAF_TEXT_FIELD,
          CIAF_DUE_ON, CIAF_DUE_BY, CIAF_ISSUE_DATE, CIAF_ADVANCE_AMOUNT,
          CIAF_CURRENCY_DETAILS, CIAF_RECORD_CONTENT, CIAF_PROCESS_COMPLETE, CIAF_TIME_STAMP,
          CIAF_CREATE_DATE, CIAF_RECORD_STATUS, CIAF_VOUCHER_FCY,CIAF_BANK_REFERENCE)
          
          (
          select 'IBS_FB50_' || to_char(datCreateDate, 'YYYYMMDD')||SUBSTR(bcac_voucher_reference,LENGTH(bcac_voucher_reference)-5), 
          bcac_voucher_number CIAF_VOUCHER_NUMBER, bcac_reference_serial CIAF_SERIAL_NUMBER, 'FB50' CIAF_FORMAT_TYPE,
          decode(bcac_company_code,30100001,1000,30100002,1010,30100003,1030) CIAF_COMPANY_CODE,
          CDEL_CASHFLOW_DATE CIAF_VALUE_DATE,
          'IBS_FB50_' || to_char(datCreateDate, 'YYYYMMDDHH24MISS') || lpad((substr(bcac_voucher_number,7,5)),4,'0')  CIAF_FILE_NUMBER, 
          bcac_create_date CIAF_DOCUMENT_DATE, bcac_voucher_date CIAF_POSTING_DATE, 'SA' CIAF_DOCUMENT_TYPE,
          /*bcac_voucher_currency*/ 'INR' CIAF_CURRENCY_CODE, 1 CIAF_EXCHANGE_RATE, bcac_voucher_reference CIAF_REFERENCE_NUMBER, 
          bcac_voucher_reference CIAF_DOCUMENT_HEADERTEXT,
          decode( BCAC_CRDR_CODE, 14600001,50,14600002,40) CIAF_POSTING_KEY, 
          CASE WHEN BCAC_ACCOUNT_HEAD = 24900030 THEN
            fncAccountHead(bcac_local_bank,BCAC_ACCOUNT_HEAD,14699999,20599999,32699999,24899999,23699999,nvl(bcac_account_number,'NA'),25399999) 
              WHEN BCAC_ACCOUNT_HEAD = 24900049 THEN 
            PKGFXCURRENTINTERFACE.fncAccountHead(bcac_local_bank,
                        BCAC_ACCOUNT_HEAD,decode(sign(cdel_profit_loss),-1,14600002,14600001),20599999,32699999,
                     24899999,23699999,nvl(bcac_account_number,'NA'),PKGFXCURRENTINTERFACE.fncFXDealBuysell(cdel_deal_number,cdel_reverse_serial))          
              WHEN BCAC_ACCOUNT_HEAD BETWEEN 24900050 AND 24900150 THEN
              PKGFXCURRENTINTERFACE.fncAccountHead(bcac_local_bank,BCAC_ACCOUNT_HEAD,14699999,20599999,32699999,24899999,23699999,nvl(bcac_account_number,'NA'),25399999)
          END CIAF_ACCOUNT_NUMBER, 
          bcac_voucher_inr CIAF_VOUCHER_AMOUNT, 0 CIAF_DOCUMENT_NUMBER,
          pkgreturncursor.fncgetdescription(bcac_local_bank,2) CIAF_BANK_ACCOUNT, decode(bcac_company_code,30100001,100000,0) CIAF_PROFIT_CENTER, 
          decode(bcac_company_code,30100001,101219,0)  CIAF_COST_CENTER, bcac_voucher_detail CIAF_TEXT_FIELD,
          '' CIAF_DUE_ON, '' CIAF_DUE_BY, cdel_cancel_date CIAF_ISSUE_DATE, 0 CIAF_ADVANCE_AMOUNT,
          pkgreturncursor.fncgetdescription(bcac_voucher_currency,2) CIAF_CURRENCY_DETAILS, '' CIAF_RECORD_CONTENT, 12400002 CIAF_PROCESS_COMPLETE, to_timestamp(sysdate) CIAF_TIME_STAMP,
          datCreateDate CIAF_CREATE_DATE, 10200001 CIAF_RECORD_STATUS, BCAC_VOUCHER_INR CIAF_VOUCHER_FCY, bcac_bank_reference CIAF_BANK_REFERENCE
          from TRTRAN008
                        inner join TRTRAN006 
                    on bcac_voucher_reference = cdel_deal_number
                    and bcac_reference_serial=cdel_reverse_serial
                 where bcac_voucher_type in( 24800051) --bcac_voucher_type = 24800099
--                  and bcac_account_head not in ( 24900029,24900030,24900028,24900033) -- NO Need to send the details 
                 -- AND BCAC_VOUCHER_FCY != 0
                  and trunc(BCAC_ADD_DATE,'dd') =datCreateDate
                  and bcac_voucher_reference= cur.bcac_voucher_reference
                  and bcac_reference_serial= cur.bcac_reference_serial
                  and bcac_account_head = cur.bcac_account_head
                  and bcac_record_status in (10200003)
                  and cdel_record_status in (10200003));
                  
                                varOperation := 'FB50 Bank Charges nilesh trial' ;    
            -- for bank charges
            insert into trtran008c
                  (CIAF_FORMAT_FILE, 
                  CIAF_VOUCHER_NUMBER, CIAF_SERIAL_NUMBER, CIAF_FORMAT_TYPE,
                  CIAF_COMPANY_CODE, CIAF_VALUE_DATE,
                  CIAF_FILE_NUMBER, 
                  CIAF_DOCUMENT_DATE, CIAF_POSTING_DATE, CIAF_DOCUMENT_TYPE,
                  CIAF_CURRENCY_CODE, CIAF_EXCHANGE_RATE, CIAF_REFERENCE_NUMBER, 
                  CIAF_DOCUMENT_HEADERTEXT,
                  CIAF_POSTING_KEY, 
                  CIAF_ACCOUNT_NUMBER, CIAF_VOUCHER_AMOUNT, CIAF_DOCUMENT_NUMBER,
                  CIAF_BANK_ACCOUNT, CIAF_PROFIT_CENTER, CIAF_COST_CENTER, CIAF_TEXT_FIELD,
                  CIAF_DUE_ON, CIAF_DUE_BY, CIAF_ISSUE_DATE, CIAF_ADVANCE_AMOUNT,
                  CIAF_CURRENCY_DETAILS, CIAF_RECORD_CONTENT, CIAF_PROCESS_COMPLETE, CIAF_TIME_STAMP,
                  CIAF_CREATE_DATE, CIAF_RECORD_STATUS, CIAF_VOUCHER_FCY,CIAF_BANK_REFERENCE)
                  (select    CIAF_FORMAT_FILE, 
                  '.',CIAF_SERIAL_NUMBER, CIAF_FORMAT_TYPE,
                  CIAF_COMPANY_CODE, CIAF_VALUE_DATE,
                  CIAF_FILE_NUMBER, 
                  CIAF_DOCUMENT_DATE, CIAF_POSTING_DATE, CIAF_DOCUMENT_TYPE,
                  CIAF_CURRENCY_CODE, CIAF_EXCHANGE_RATE, CIAF_REFERENCE_NUMBER, 
                  CIAF_DOCUMENT_HEADERTEXT,50,
                  --decode(CIAF_POSTING_KEY,40,50,40), 
                  fncAccountHead(bcac_local_bank,
                                24900030,14699999,20599999,32699999,
                             24899999,23699999,nvl(bcac_account_number,'NA'),25399999) CIAF_ACCOUNT_NUMBER,
                  numRowCount1, ciaf_document_number,
                  CIAF_BANK_ACCOUNT, CIAF_PROFIT_CENTER, CIAF_COST_CENTER,'bank charges consolidated', 
                  '','',ciaf_document_date,0,
                  CIAF_CURRENCY_DETAILS,'',12400002,to_timestamp(ciaf_document_date),
                  ciaf_document_date,10200003, sum(CIAF_VOUCHER_FCY),''
                  from trtran008c a inner join trtran008
                  on a.ciaf_document_headertext = cur.bcac_voucher_reference
                  and bcac_account_head between 24900050 and 24900149
                  where
                  ciaf_document_headertext = cur.bcac_voucher_reference
                  and bcac_voucher_reference=cur.bcac_voucher_reference
                  and trunc(BCAC_ADD_DATE,'dd') =datCreateDate
                  and not exists (select * from trtran008c b 
                  where b.ciaf_voucher_number ='.' and b.ciaf_document_headertext=a.ciaf_document_headertext )
                  group by  bcac_local_bank,bcac_account_number,CIAF_FORMAT_FILE, 
                            CIAF_SERIAL_NUMBER, CIAF_FORMAT_TYPE,
                            CIAF_COMPANY_CODE, CIAF_VALUE_DATE,
                            CIAF_FILE_NUMBER, 
                            CIAF_DOCUMENT_DATE, CIAF_POSTING_DATE, CIAF_DOCUMENT_TYPE,
                            CIAF_CURRENCY_CODE, CIAF_EXCHANGE_RATE, CIAF_REFERENCE_NUMBER, 
                            CIAF_DOCUMENT_HEADERTEXT,
                            CIAF_POSTING_KEY,ciaf_document_number,
                            CIAF_BANK_ACCOUNT, CIAF_PROFIT_CENTER, CIAF_COST_CENTER, 
                            CIAF_CURRENCY_DETAILS);
                  
          
          
    elsif numVoucherType = 24800061 then 
    
           select count(*),sum(bcac_voucher_inr) into numRowCount2,numRowCount1
           from trtran008
           where  trunc(BCAC_ADD_DATE,'dd') =datCreateDate
           and bcac_voucher_reference = cur.bcac_voucher_reference
           and bcac_reference_serial=cur.bcac_reference_serial
           and bcac_account_head between 24900050 and 24900149
           group by bcac_voucher_reference,bcac_reference_serial;
           
           
            insert into trtran008c
          (
          CIAF_FORMAT_FILE, 
          CIAF_VOUCHER_NUMBER, CIAF_SERIAL_NUMBER, CIAF_FORMAT_TYPE,
          CIAF_COMPANY_CODE, CIAF_VALUE_DATE,
          CIAF_FILE_NUMBER, 
          CIAF_DOCUMENT_DATE, CIAF_POSTING_DATE, CIAF_DOCUMENT_TYPE,
          CIAF_CURRENCY_CODE, CIAF_EXCHANGE_RATE, CIAF_REFERENCE_NUMBER, 
          CIAF_DOCUMENT_HEADERTEXT,
          CIAF_POSTING_KEY, 
          CIAF_ACCOUNT_NUMBER, CIAF_VOUCHER_AMOUNT, CIAF_DOCUMENT_NUMBER,
          CIAF_BANK_ACCOUNT, CIAF_PROFIT_CENTER, CIAF_COST_CENTER, CIAF_TEXT_FIELD,
          CIAF_DUE_ON, CIAF_DUE_BY, CIAF_ISSUE_DATE, CIAF_ADVANCE_AMOUNT,
          CIAF_CURRENCY_DETAILS, CIAF_RECORD_CONTENT, CIAF_PROCESS_COMPLETE, CIAF_TIME_STAMP,
          CIAF_CREATE_DATE, CIAF_RECORD_STATUS, CIAF_VOUCHER_FCY,CIAF_BANK_REFERENCE)
          
          (
          select 'IBS_FB50_' || to_char(datCreateDate, 'YYYYMMDD')||SUBSTR(bcac_voucher_reference,LENGTH(bcac_voucher_reference)-5) CIAF_FORMAT_FILE, 
          bcac_voucher_number CIAF_VOUCHER_NUMBER, bcac_reference_serial CIAF_SERIAL_NUMBER, 'FB50' CIAF_FORMAT_TYPE,
          decode(bcac_company_code,30100001,1000,30100002,1010,30100003,1030) CIAF_COMPANY_CODE,
          deal_execute_date CIAF_VALUE_DATE,
          'IBS_FB50_' || to_char(datCreateDate, 'YYYYMMDDHH24MISS') || lpad((substr(bcac_voucher_number,7,5)),4,'0')  CIAF_FILE_NUMBER, 
          bcac_create_date CIAF_DOCUMENT_DATE, bcac_voucher_date CIAF_POSTING_DATE, 'SA' CIAF_DOCUMENT_TYPE,
          /*bcac_voucher_currency*/ 'INR' CIAF_CURRENCY_CODE, 1 CIAF_EXCHANGE_RATE, bcac_voucher_reference CIAF_REFERENCE_NUMBER, 
          bcac_voucher_reference CIAF_DOCUMENT_HEADERTEXT,
          decode( BCAC_CRDR_CODE, 14600001,50,14600002,40) CIAF_POSTING_KEY, 
          fncAccountHead(bcac_local_bank,
                        BCAC_ACCOUNT_HEAD,14699999,20599999,32699999,
                     24899999,23699999,nvl(bcac_account_number,'NA'),25399999) CIAF_ACCOUNT_NUMBER, 
          bcac_voucher_inr CIAF_VOUCHER_AMOUNT, 0 CIAF_DOCUMENT_NUMBER,
          pkgreturncursor.fncgetdescription(bcac_local_bank,2) CIAF_BANK_ACCOUNT, decode(bcac_company_code,30100001,100000,0) CIAF_PROFIT_CENTER, 
          decode(bcac_company_code,30100001,101219,0)  CIAF_COST_CENTER, bcac_voucher_detail CIAF_TEXT_FIELD,
          '' CIAF_DUE_ON, '' CIAF_DUE_BY, deal_execute_date CIAF_ISSUE_DATE, 0 CIAF_ADVANCE_AMOUNT,
          pkgreturncursor.fncgetdescription(bcac_voucher_currency,2) CIAF_CURRENCY_DETAILS, '' CIAF_RECORD_CONTENT, 12400002 CIAF_PROCESS_COMPLETE, to_timestamp(sysdate) CIAF_TIME_STAMP,
          datCreateDate CIAF_CREATE_DATE, 10200001 CIAF_RECORD_STATUS, bcac_voucher_fcy CIAF_VOUCHER_FCY, bcac_bank_reference CIAF_BANK_REFERENCE
          from TRTRAN008
                        inner join TRTRAN001 
                    on bcac_voucher_reference = deal_deal_number
                    where bcac_voucher_type in( 24800061) --bcac_voucher_type = 24800099
--                  and bcac_account_head not in ( 24900029,24900030,24900028,24900033) -- NO Need to send the details 
                 -- AND BCAC_VOUCHER_FCY != 0
                  and trunc(BCAC_ADD_DATE,'dd') =datCreateDate
                  and bcac_voucher_reference= cur.bcac_voucher_reference
                  and bcac_reference_serial= cur.bcac_reference_serial
                  and bcac_account_head = cur.bcac_account_head
                  and bcac_record_status in (10200003)
                  and deal_record_status in (10200003));
                  
                  commit;
                  
              varOperation := 'FB50 Bank Charges nilesh trial' ;    
            -- for bank charges
            insert into trtran008c
                  (CIAF_FORMAT_FILE, 
                  CIAF_VOUCHER_NUMBER, CIAF_SERIAL_NUMBER, CIAF_FORMAT_TYPE,
                  CIAF_COMPANY_CODE, CIAF_VALUE_DATE,
                  CIAF_FILE_NUMBER, 
                  CIAF_DOCUMENT_DATE, CIAF_POSTING_DATE, CIAF_DOCUMENT_TYPE,
                  CIAF_CURRENCY_CODE, CIAF_EXCHANGE_RATE, CIAF_REFERENCE_NUMBER, 
                  CIAF_DOCUMENT_HEADERTEXT,
                  CIAF_POSTING_KEY, 
                  CIAF_ACCOUNT_NUMBER, CIAF_VOUCHER_AMOUNT, CIAF_DOCUMENT_NUMBER,
                  CIAF_BANK_ACCOUNT, CIAF_PROFIT_CENTER, CIAF_COST_CENTER, CIAF_TEXT_FIELD,
                  CIAF_DUE_ON, CIAF_DUE_BY, CIAF_ISSUE_DATE, CIAF_ADVANCE_AMOUNT,
                  CIAF_CURRENCY_DETAILS, CIAF_RECORD_CONTENT, CIAF_PROCESS_COMPLETE, CIAF_TIME_STAMP,
                  CIAF_CREATE_DATE, CIAF_RECORD_STATUS, CIAF_VOUCHER_FCY,CIAF_BANK_REFERENCE)
                  (select    CIAF_FORMAT_FILE, 
                  '.',CIAF_SERIAL_NUMBER, CIAF_FORMAT_TYPE,
                  CIAF_COMPANY_CODE, CIAF_VALUE_DATE,
                  CIAF_FILE_NUMBER, 
                  CIAF_DOCUMENT_DATE, CIAF_POSTING_DATE, CIAF_DOCUMENT_TYPE,
                  CIAF_CURRENCY_CODE, CIAF_EXCHANGE_RATE, CIAF_REFERENCE_NUMBER, 
                  CIAF_DOCUMENT_HEADERTEXT,50,
                  --decode(CIAF_POSTING_KEY,40,50,40), 
                  fncAccountHead(bcac_local_bank,
                                24900030,14699999,20599999,32699999,
                             24899999,23699999,nvl(bcac_account_number,'NA'),25399999) CIAF_ACCOUNT_NUMBER,
                  numRowCount1, ciaf_document_number,
                  CIAF_BANK_ACCOUNT, CIAF_PROFIT_CENTER, CIAF_COST_CENTER,'bank charges consolidated', 
                  '','',ciaf_document_date,0,
                  CIAF_CURRENCY_DETAILS,'',12400002,to_timestamp(ciaf_document_date),
                  ciaf_document_date,10200003, sum(CIAF_VOUCHER_FCY),''
                  from trtran008c a inner join trtran008
                  on a.ciaf_document_headertext = cur.bcac_voucher_reference
                  and bcac_account_head between 24900050 and 24900149
                  where
                  ciaf_document_headertext = cur.bcac_voucher_reference
                  and bcac_voucher_reference=cur.bcac_voucher_reference
                  and trunc(BCAC_ADD_DATE,'dd') =datCreateDate
                  and not exists (select * from trtran008c b 
                  where b.ciaf_voucher_number ='.' and b.ciaf_document_headertext=a.ciaf_document_headertext )
                  group by  bcac_local_bank,bcac_account_number,CIAF_FORMAT_FILE, 
                            CIAF_SERIAL_NUMBER, CIAF_FORMAT_TYPE,
                            CIAF_COMPANY_CODE, CIAF_VALUE_DATE,
                            CIAF_FILE_NUMBER, 
                            CIAF_DOCUMENT_DATE, CIAF_POSTING_DATE, CIAF_DOCUMENT_TYPE,
                            CIAF_CURRENCY_CODE, CIAF_EXCHANGE_RATE, CIAF_REFERENCE_NUMBER, 
                            CIAF_DOCUMENT_HEADERTEXT,
                            CIAF_POSTING_KEY,ciaf_document_number,
                            CIAF_BANK_ACCOUNT, CIAF_PROFIT_CENTER, CIAF_COST_CENTER, 
                            CIAF_CURRENCY_DETAILS);
      end if;
                  
--          select CIAF_FORMAT_FILE, 
--          CIAF_VOUCHER_NUMBER, CIAF_SERIAL_NUMBER, CIAF_FORMAT_TYPE,
--          CIAF_COMPANY_CODE, CIAF_VALUE_DATE,
--          CIAF_FILE_NUMBER, 
--          CIAF_DOCUMENT_DATE, CIAF_POSTING_DATE, CIAF_DOCUMENT_TYPE,
--          CIAF_CURRENCY_CODE, CIAF_EXCHANGE_RATE, CIAF_REFERENCE_NUMBER, 
--          CIAF_DOCUMENT_HEADERTEXT,
--          CIAF_POSTING_KEY, 
--          CIAF_ACCOUNT_NUMBER, CIAF_VOUCHER_AMOUNT, CIAF_DOCUMENT_NUMBER,
--          CIAF_BANK_ACCOUNT, CIAF_PROFIT_CENTER, CIAF_COST_CENTER, CIAF_TEXT_FIELD,
--          CIAF_DUE_ON, CIAF_DUE_BY, CIAF_ISSUE_DATE, CIAF_ADVANCE_AMOUNT,
--          CIAF_CURRENCY_DETAILS, CIAF_RECORD_CONTENT, CIAF_PROCESS_COMPLETE, CIAF_TIME_STAMP,
--          CIAF_CREATE_DATE, CIAF_RECORD_STATUS, CIAF_VOUCHER_FCY,CIAF_BANK_REFERENCE
--          from CTE;
     exception
     when others then 
            numError :=fncAuditTrail('ErroCode : ' ||SQLCODE || ' varOperation ' || varOperation || ' Error Message : '  || SQLERRM,datCreateDate );
            goto process_end;
     end;  
     
      
       
      
       
--       24900031	PCL Interest
--24900032	PSL Interest
--24900033	FBK Charges
--24900034	FD Interest
--24900035	BC Interest
--24900036	TL Interest
--24900037	PBD
--24900038	PBD Interest
numRowCount2:=0;
numRowCount1:=0;
   
--   begin 
--       varOperation := 'FB50 FX Details Update Ref ' || cur.bcac_voucher_reference || ' Ref Sr No ' || cur.bcac_reference_serial ;
--
--        Update trtran008E set (SIAF_GLCODE_CODE1 ,SIAF_DEBIT_CREDIT1,SIAF_VOUCHER_FCY1,
--                SIAF_VOUCHER_INR1,SIAF_COST_CENTER1,SIAF_COMPANY_CODE1,SIAF_Interest_ColPos) =
--              (select fncAccountHead(PKGRETURNCURSOR.fncGetTradeFiananceCode(BCAC_LOCAL_BANK),BCAC_ACCOUNT_HEAD,14699999,
--                                    20599999,32699999,24899999,23699999),
--                               decode( PKGRETURNCURSOR.fncGetTradeFiananceCode(BCAC_CRDR_CODE), 14600001,50,14600002,40),
--                               bcac_voucher_fcy,BCAC_VOUCHER_INR,
--                                pkgIndofilCurrentInterface.fncCostCenter(10300501,30299999,32600001,Gconst.EventBankCharges),
--                               1000,
--                               2
--                      from TRTRAN008  c 
--                        inner join TRTRAN006 
--                    on bcac_voucher_reference = cdel_deal_number
--                    and bcac_reference_serial=cdel_reverse_serial
--                 where bcac_voucher_type = 24800051 --bcac_voucher_type = 24800099
--                  and bcac_account_head =24900030 -- Covers all the GL Heads  
--                  --AND BCAC_VOUCHER_FCY != 0
--                  and trunc(BCAC_ADD_DATE,'dd') =datCreateDate
--                  and bcac_record_status in (10200003)
--                  and cdel_record_status in (10200003)
--                  and SIAF_VOUCHER_REFERENCE= bcac_voucher_reference
--                  and Siaf_reference_serial= bcac_reference_serial
--                  and trunc(siaf_create_date,'dd') =datCreateDate)
--               where  SIAF_Interest_ColPos is null
--               and siaf_format_type = 'FB50'
--               and siaf_document_type='FX'
--               and siaf_voucher_reference= cur.bcac_voucher_reference
--               and siaf_reference_serial= cur.bcac_reference_serial
--               and trunc(siaf_create_date,'dd') =datCreateDate;
--          
--       exception
--        when others then 
--            numError :=fncAuditTrail('ErroCode : ' ||SQLCODE || ' varOperation ' || varOperation || ' Error Message : '  || SQLERRM,datCreateDate );
--            goto process_end;
--      end;   
      
         begin 
      varOperation := 'FB50 FX Update Bank Charges for Ref ' || cur.bcac_voucher_reference || ' Ref Sr No ' || cur.bcac_reference_serial ;    
      
      insert into temp values('FB50 FX Update Bank Charges for Ref ' || cur.bcac_voucher_reference || ' Ref Sr No ','');commit; 
      update trtran008C
              set ciaf_record_content = 
               CIAF_SERIAL_NUMBER || '~' || CIAF_COMPANY_CODE || '~' || to_char(CIAF_DOCUMENT_DATE,'yyyymmdd') || '~' || to_char(CIAF_POSTING_DATE,'yyyymmdd') 
               || '~' || CIAF_DOCUMENT_TYPE || '~' || CIAF_CURRENCY_CODE || '~' 
               || CIAF_EXCHANGE_RATE || '~' || to_char(CIAF_DOCUMENT_DATE,'yyyymmdd') || '~' || CIAF_DOCUMENT_HEADERTEXT || '~' || CIAF_POSTING_KEY || '~' 
               || CIAF_ACCOUNT_NUMBER || '~' || CIAF_VOUCHER_AMOUNT || '~'  || '~' || to_char(TO_DATE(CIAF_VALUE_DATE),'yyyymmdd') || '~' || CIAF_BANK_REFERENCE || '~' 
               || CIAF_PROFIT_CENTER || '~' || CIAF_COST_CENTER || '~' || CIAF_TEXT_FIELD
              where ciaf_format_type = 'FB50'
              and trunc(ciaf_create_date,'dd') =datCreateDate
              and ciaf_document_headertext= cur.bcac_voucher_reference
              and Ciaf_document_type='SA';
              
--      SELECT CIAF_FILE_NUMBER INTO varFileName
--      from trtran008c
--      where ciaf_format_type = 'FB50'
--              and trunc(ciaf_create_date,'dd') =datCreateDate
--              and ciaf_document_headertext= cur.bcac_voucher_reference
--              and Ciaf_document_type='SA';
--              
              
--              SIAF_VOUCHER_NUMBER || '|' || 	decode(SIAF_DOCPROCESS_COMPLETE,12400002,'O','C') || '|' ||	 to_char(siaf_document_date, 'YYYYMMDD') || '|' ||
--              to_char(siaf_posting_date, 'YYYYMMDD') || '|' ||	siaf_fiscal_period || '|' ||	siaf_fiscal_year || '|' ||	 siaf_bank_reference || '|' ||	 
--              siaf_bank_reference || '|' ||	decode(siaf_posting_key,50,'H','S') || '|' ||	siaf_account_head || '|' ||	siaf_voucher_fcy || 
--              '|' ||	siaf_voucher_inr || '|' ||
--              substr(SIAF_COST_CENTER,1,6) || '|' ||	siaf_cost_center	|| '|' || siaf_company_code|| '|' || decode(SIAF_Debit_Credit1,50,'H',40, 'S')	
--              || '|' ||	SIAF_GLCODE_CODE1 || '|' || siaf_voucher_fcy1	|| '|' || siaf_voucher_inr1	|| '|' || substr(SIAF_COST_CENTER1,1,6)	|| '|' 
--              || siaf_cost_center1 || '|' ||	siaf_company_code1	|| '|' || decode(SIAF_Debit_Credit2,50,'H',40,'S')	
--              || '|' ||	SIAF_GLCODE_CODE2 || '|' || siaf_voucher_fcy2	|| '|' || siaf_voucher_inr2	|| '|' || substr(SIAF_COST_CENTER2,1,6)	|| '|' 
--              || siaf_cost_center2 || '|' ||	siaf_company_code2	|| '|' || decode(SIAF_Debit_Credit3,50,'H',40,'S')	
--              || '|' ||	SIAF_GLCODE_CODE3 || '|' || siaf_voucher_fcy3	|| '|' || siaf_voucher_inr3	|| '|' || substr(SIAF_COST_CENTER3,1,6)	|| '|' 
--              || siaf_cost_center3 || '|' ||	siaf_company_code3	|| '|' || to_char(siaf_voucher_date,'YYYYMMDD') || '|' ||
--              siaf_voucher_detail|| '|' ||	 siaf_reference_number || '|' ||	siaf_voucher_currency || '|' ||	siaf_voucher_rate || '|' ||	SIAF_BUSINESS_PLACE
--              || '|' ||	to_char(siaf_document_date,'YYYYMMDD')
--               where siaf_format_type = 'FB50'
--              and trunc(siaf_create_date,'dd') =datCreateDate
--              and siaf_voucher_reference= cur.bcac_voucher_reference
--              and siaf_reference_serial= cur.bcac_reference_serial
--              and siaf_document_type='FX';
      exception
        when others then 
            numError :=fncAuditTrail('ErroCode : ' ||SQLCODE || ' varOperation ' || varOperation || ' Error Message : '  || SQLERRM,datCreateDate );
            goto process_end;
      end;          
 
<<process_end>>
 if numError !=0 then 
    rollback;
 else 
    commit;
 end if;
  numError:=0;
end loop;
  commit;
  varFile := varFileName;
  Return varFile;

Exception
When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('LoanClosure', numError, varMessage, 
                      Varoperation, Varerror);
      numError := fncAuditTrail(varError);                      
      raise_application_error(-20101, varError);                      
      return varFile;
End fncTreasuryFWD;


Function fncTreasuryOpt    
    (   datCreateDate in Date)
    return varchar2 as
--  Created on 04/01/10 by T M Manjunath
    PRAGMA AUTONOMOUS_TRANSACTION;
    numError            number;
    numRealize          number(2);
    numRecords          number(5);
    numFile             number(5);
    numCode             number(8);
    numType             number(8);
    numProcess          number(8);
    numCredit           number(15,4);
    numDebit            number(15,4);
    numBalance          number(15,4);
    numExchange         number(15,4);
    datVoucher          date;
    datProcess          date;
    varFlag             varchar2(15);
    varKey              varchar2(10);
    varCurrency         varchar2(10);
    varFileName         varchar2(30);
    varTimeStamp        varchar2(25);
    varReference        varchar2(25);
    varReference1       varchar2(30);
    Varfile             Varchar2(50);
    Varformats          Varchar2(50);
    varInvoices         varchar2(256);
    varText             varchar2(200);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    numRowCount1         number(10);
    numRowCount2         number(10);
    numSerial           number(10);
    chrCurrentACCheck   char(1);
    numVoucherType     number(10);

  begin


       
    varOperation := 'Creating FB50 format for FX';
        
    for cur in (select bcac_voucher_reference,bcac_reference_serial,bcac_account_head,
                  bcac_voucher_date,bcac_voucher_type
                from TRTRAN008   
--              inner join TRTRAN006 
--          on bcac_voucher_reference = cdel_deal_number
--          and bcac_reference_serial=cdel_reverse_serial
       where 
       bcac_voucher_type not in (24800051,24800061)
       --bcac_voucher_type = 24800099
--     
      and trunc(BCAC_ADD_DATE,'dd') =datCreateDate
          and bcac_record_status in (10200003)
          
--          and cdel_record_status in (10200003)
          group by bcac_voucher_reference,bcac_reference_serial,bcac_account_head,
                  bcac_voucher_date,bcac_voucher_type)
                  --,bcac_local_bank)
  loop 

    --gVoucherDate := datVoucher;
    varOperation := 'FB50 Update Global Variables ';
     gFileName := 'IBS_FB50_' || to_char(datCreateDate, 'YYYYMMDD');
     gVoucherDate:= cur.bcac_voucher_date;
     gVoucherReference:= cur.bcac_voucher_reference;
     gVoucherSerial:= cur.bcac_reference_serial;
     gLocalBank:= 30699999;
     gTimeStamp:= to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3');
     gPackageName :='fncBillRealize';
     numVoucherType := cur.bcac_voucher_type;
     
--     numSerial := 1;


     begin
        varOperation := 'FB50 Opt transactions Ref ' || cur.bcac_voucher_reference || ' Ref Sr No ' || cur.bcac_reference_serial ;
        insert into temp values(cur.bcac_voucher_reference,cur.bcac_voucher_date);commit;
        
           select count(*),sum(bcac_voucher_inr) into numRowCount2,numRowCount1
           from trtran008
           where  trunc(BCAC_ADD_DATE,'dd') =datCreateDate
           and bcac_voucher_reference = cur.bcac_voucher_reference
           and bcac_reference_serial=cur.bcac_reference_serial
           and bcac_account_head between 24900050 and 24900149
           group by bcac_voucher_reference,bcac_reference_serial; 

          insert into trtran008c
          (
          
          CIAF_FORMAT_FILE, 
          CIAF_VOUCHER_NUMBER, CIAF_SERIAL_NUMBER, CIAF_FORMAT_TYPE,
          CIAF_COMPANY_CODE, CIAF_VALUE_DATE,
          CIAF_FILE_NUMBER, 
          CIAF_DOCUMENT_DATE, CIAF_POSTING_DATE, CIAF_DOCUMENT_TYPE,
          CIAF_CURRENCY_CODE, CIAF_EXCHANGE_RATE, CIAF_REFERENCE_NUMBER, 
          CIAF_DOCUMENT_HEADERTEXT,
          CIAF_POSTING_KEY, 
          CIAF_ACCOUNT_NUMBER, CIAF_VOUCHER_AMOUNT, CIAF_DOCUMENT_NUMBER,
          CIAF_BANK_ACCOUNT, CIAF_PROFIT_CENTER, CIAF_COST_CENTER, CIAF_TEXT_FIELD,
          CIAF_DUE_ON, CIAF_DUE_BY, CIAF_ISSUE_DATE, CIAF_ADVANCE_AMOUNT,
          CIAF_CURRENCY_DETAILS, CIAF_RECORD_CONTENT, CIAF_PROCESS_COMPLETE, CIAF_TIME_STAMP,
          CIAF_CREATE_DATE, CIAF_RECORD_STATUS, CIAF_VOUCHER_FCY,CIAF_BANK_REFERENCE)
          
          (
          select 'IBS_FB50_' || to_char(datCreateDate, 'YYYYMMDD') CIAF_FORMAT_FILE, 
          bcac_voucher_number CIAF_VOUCHER_NUMBER, bcac_reference_serial CIAF_SERIAL_NUMBER, 'FB50' CIAF_FORMAT_TYPE,
          decode(bcac_company_code,30100001,1000,30100002,1010,30100003,1030) CIAF_COMPANY_CODE,
          copt_execute_date CIAF_VALUE_DATE,
          'IBS_FB50_' || to_char(datCreateDate, 'YYYYMMDDHH24MISS') || lpad((substr(bcac_voucher_number,7,5)),4,'0')  CIAF_FILE_NUMBER, 
          bcac_create_date CIAF_DOCUMENT_DATE, bcac_voucher_date CIAF_POSTING_DATE, 'SA' CIAF_DOCUMENT_TYPE,
          /*bcac_voucher_currency*/ 'INR' CIAF_CURRENCY_CODE, bcac_voucher_rate CIAF_EXCHANGE_RATE, bcac_voucher_reference CIAF_REFERENCE_NUMBER, 
          bcac_voucher_reference CIAF_DOCUMENT_HEADERTEXT,
          decode( BCAC_CRDR_CODE, 14600001,50,14600002,40) CIAF_POSTING_KEY, 
--          fncAccountHead(bcac_local_bank,
--                        BCAC_ACCOUNT_HEAD,bcac_crdr_code,20599999,32699999,
--                     24899999,23699999,nvl(bcac_account_number,'NA'),bcac_crdr_code) CIAF_ACCOUNT_NUMBER, 
          CASE WHEN BCAC_ACCOUNT_HEAD = 24900030 THEN
            fncAccountHead(bcac_local_bank,BCAC_ACCOUNT_HEAD,14699999,20599999,32699999,24899999,23699999,nvl(bcac_account_number,'NA'),25399999) 
              WHEN BCAC_ACCOUNT_HEAD = 24900038 THEN 
            PKGFXCURRENTINTERFACE.fncAccountHead(bcac_local_bank,
                        BCAC_ACCOUNT_HEAD,bcac_crdr_code,20599999,32699999,
                     24899999,23699999,nvl(bcac_account_number,'NA'),25399999)          
              WHEN BCAC_ACCOUNT_HEAD BETWEEN 24900050 AND 24900150 THEN
              PKGFXCURRENTINTERFACE.fncAccountHead(bcac_local_bank,BCAC_ACCOUNT_HEAD,14699999,20599999,32699999,24899999,23699999,nvl(bcac_account_number,'NA'),25399999)
          END CIAF_ACCOUNT_NUMBER,
          bcac_voucher_inr CIAF_VOUCHER_AMOUNT, 0 CIAF_DOCUMENT_NUMBER,
          pkgreturncursor.fncgetdescription(bcac_local_bank,2) CIAF_BANK_ACCOUNT, decode(bcac_company_code,30100001,100000,0) CIAF_PROFIT_CENTER, 
          decode(bcac_company_code,30100001,101219,0)  CIAF_COST_CENTER, bcac_voucher_detail CIAF_TEXT_FIELD,
          '' CIAF_DUE_ON, '' CIAF_DUE_BY, copt_execute_date CIAF_ISSUE_DATE, 0 CIAF_ADVANCE_AMOUNT,
          pkgreturncursor.fncgetdescription(bcac_voucher_currency,2) CIAF_CURRENCY_DETAILS, '' CIAF_RECORD_CONTENT, 12400002 CIAF_PROCESS_COMPLETE, to_timestamp(sysdate) CIAF_TIME_STAMP,
          datCreateDate CIAF_CREATE_DATE, 10200001 CIAF_RECORD_STATUS, bcac_voucher_fcy CIAF_VOUCHER_FCY, bcac_bank_reference CIAF_BANK_REFERENCE
          from TRTRAN008
                        inner join trtran071 
                    on bcac_voucher_reference = copt_deal_number
                    where bcac_voucher_type in( 24800099) --bcac_voucher_type = 24800099
--                  and bcac_account_head not in ( 24900029,24900030,24900028,24900033) -- NO Need to send the details 
                 -- AND BCAC_VOUCHER_FCY != 0
                  and trunc(BCAC_ADD_DATE,'dd') =datCreateDate
                  and bcac_voucher_reference= cur.bcac_voucher_reference
                  and bcac_reference_serial= cur.bcac_reference_serial
                  and bcac_account_head = cur.bcac_account_head
                  and bcac_record_status in (10200003)
                  and copt_record_status in (10200003));
                  
                    varOperation := 'FB50 Bank Charges Options' ;    
            -- for bank charges
            insert into trtran008c
                  (CIAF_FORMAT_FILE, 
                  CIAF_VOUCHER_NUMBER, CIAF_SERIAL_NUMBER, CIAF_FORMAT_TYPE,
                  CIAF_COMPANY_CODE, CIAF_VALUE_DATE,
                  CIAF_FILE_NUMBER, 
                  CIAF_DOCUMENT_DATE, CIAF_POSTING_DATE, CIAF_DOCUMENT_TYPE,
                  CIAF_CURRENCY_CODE, CIAF_EXCHANGE_RATE, CIAF_REFERENCE_NUMBER, 
                  CIAF_DOCUMENT_HEADERTEXT,
                  CIAF_POSTING_KEY, 
                  CIAF_ACCOUNT_NUMBER, CIAF_VOUCHER_AMOUNT, CIAF_DOCUMENT_NUMBER,
                  CIAF_BANK_ACCOUNT, CIAF_PROFIT_CENTER, CIAF_COST_CENTER, CIAF_TEXT_FIELD,
                  CIAF_DUE_ON, CIAF_DUE_BY, CIAF_ISSUE_DATE, CIAF_ADVANCE_AMOUNT,
                  CIAF_CURRENCY_DETAILS, CIAF_RECORD_CONTENT, CIAF_PROCESS_COMPLETE, CIAF_TIME_STAMP,
                  CIAF_CREATE_DATE, CIAF_RECORD_STATUS, CIAF_VOUCHER_FCY,CIAF_BANK_REFERENCE)
                  (select    CIAF_FORMAT_FILE, 
                  '.',CIAF_SERIAL_NUMBER, CIAF_FORMAT_TYPE,
                  CIAF_COMPANY_CODE, CIAF_VALUE_DATE,
                  CIAF_FILE_NUMBER, 
                  CIAF_DOCUMENT_DATE, CIAF_POSTING_DATE, CIAF_DOCUMENT_TYPE,
                  CIAF_CURRENCY_CODE, CIAF_EXCHANGE_RATE, CIAF_REFERENCE_NUMBER, 
                  CIAF_DOCUMENT_HEADERTEXT,50,
                  --decode(CIAF_POSTING_KEY,40,50,40), 
                  fncAccountHead(bcac_local_bank,
                                24900030,14699999,20599999,32699999,
                             24899999,23699999,nvl(bcac_account_number,'NA'),25399999) CIAF_ACCOUNT_NUMBER,
                  numRowCount1, ciaf_document_number,
                  CIAF_BANK_ACCOUNT, CIAF_PROFIT_CENTER, CIAF_COST_CENTER,'bank charges consolidated', 
                  '','',ciaf_document_date,0,
                  CIAF_CURRENCY_DETAILS,'',12400002,to_timestamp(ciaf_document_date),
                  ciaf_document_date,10200003, sum(CIAF_VOUCHER_FCY),''
                  from trtran008c a inner join trtran008
                  on a.ciaf_document_headertext = cur.bcac_voucher_reference
                  and bcac_account_head between 24900050 and 24900149
                  where
                  ciaf_document_headertext = cur.bcac_voucher_reference
                  and bcac_voucher_reference=cur.bcac_voucher_reference
                  and trunc(BCAC_ADD_DATE,'dd') =datCreateDate
                  and not exists (select * from trtran008c b 
                  where b.ciaf_voucher_number ='.' and b.ciaf_document_headertext=a.ciaf_document_headertext )
                  group by  bcac_local_bank,bcac_account_number,CIAF_FORMAT_FILE, 
                            CIAF_SERIAL_NUMBER, CIAF_FORMAT_TYPE,
                            CIAF_COMPANY_CODE, CIAF_VALUE_DATE,
                            CIAF_FILE_NUMBER, 
                            CIAF_DOCUMENT_DATE, CIAF_POSTING_DATE, CIAF_DOCUMENT_TYPE,
                            CIAF_CURRENCY_CODE, CIAF_EXCHANGE_RATE, CIAF_REFERENCE_NUMBER, 
                            CIAF_DOCUMENT_HEADERTEXT,
                            CIAF_POSTING_KEY,ciaf_document_number,
                            CIAF_BANK_ACCOUNT, CIAF_PROFIT_CENTER, CIAF_COST_CENTER, 
                            CIAF_CURRENCY_DETAILS);
                  
--          select CIAF_FORMAT_FILE, 
--          CIAF_VOUCHER_NUMBER, CIAF_SERIAL_NUMBER, CIAF_FORMAT_TYPE,
--          CIAF_COMPANY_CODE, CIAF_VALUE_DATE,
--          CIAF_FILE_NUMBER, 
--          CIAF_DOCUMENT_DATE, CIAF_POSTING_DATE, CIAF_DOCUMENT_TYPE,
--          CIAF_CURRENCY_CODE, CIAF_EXCHANGE_RATE, CIAF_REFERENCE_NUMBER, 
--          CIAF_DOCUMENT_HEADERTEXT,
--          CIAF_POSTING_KEY, 
--          CIAF_ACCOUNT_NUMBER, CIAF_VOUCHER_AMOUNT, CIAF_DOCUMENT_NUMBER,
--          CIAF_BANK_ACCOUNT, CIAF_PROFIT_CENTER, CIAF_COST_CENTER, CIAF_TEXT_FIELD,
--          CIAF_DUE_ON, CIAF_DUE_BY, CIAF_ISSUE_DATE, CIAF_ADVANCE_AMOUNT,
--          CIAF_CURRENCY_DETAILS, CIAF_RECORD_CONTENT, CIAF_PROCESS_COMPLETE, CIAF_TIME_STAMP,
--          CIAF_CREATE_DATE, CIAF_RECORD_STATUS, CIAF_VOUCHER_FCY,CIAF_BANK_REFERENCE
--          from CTE;
     exception
     when others then 
            numError :=fncAuditTrail('ErroCode : ' ||SQLCODE || ' varOperation ' || varOperation || ' Error Message : '  || SQLERRM,datCreateDate );
            goto process_end;
     end;  
     
      
       
      
       
--       24900031	PCL Interest
--24900032	PSL Interest
--24900033	FBK Charges
--24900034	FD Interest
--24900035	BC Interest
--24900036	TL Interest
--24900037	PBD
--24900038	PBD Interest
--numRowCount2:=0;
--numRowCount1:=0;
   
--   begin 
--       varOperation := 'FB50 FX Details Update Ref ' || cur.bcac_voucher_reference || ' Ref Sr No ' || cur.bcac_reference_serial ;
--
--        Update trtran008E set (SIAF_GLCODE_CODE1 ,SIAF_DEBIT_CREDIT1,SIAF_VOUCHER_FCY1,
--                SIAF_VOUCHER_INR1,SIAF_COST_CENTER1,SIAF_COMPANY_CODE1,SIAF_Interest_ColPos) =
--              (select fncAccountHead(PKGRETURNCURSOR.fncGetTradeFiananceCode(BCAC_LOCAL_BANK),BCAC_ACCOUNT_HEAD,14699999,
--                                    20599999,32699999,24899999,23699999),
--                               decode( PKGRETURNCURSOR.fncGetTradeFiananceCode(BCAC_CRDR_CODE), 14600001,50,14600002,40),
--                               bcac_voucher_fcy,BCAC_VOUCHER_INR,
--                                pkgIndofilCurrentInterface.fncCostCenter(10300501,30299999,32600001,Gconst.EventBankCharges),
--                               1000,
--                               2
--                      from TRTRAN008  c 
--                        inner join TRTRAN006 
--                    on bcac_voucher_reference = cdel_deal_number
--                    and bcac_reference_serial=cdel_reverse_serial
--                 where bcac_voucher_type = 24800051 --bcac_voucher_type = 24800099
--                  and bcac_account_head =24900030 -- Covers all the GL Heads  
--                  --AND BCAC_VOUCHER_FCY != 0
--                  and trunc(BCAC_ADD_DATE,'dd') =datCreateDate
--                  and bcac_record_status in (10200003)
--                  and cdel_record_status in (10200003)
--                  and SIAF_VOUCHER_REFERENCE= bcac_voucher_reference
--                  and Siaf_reference_serial= bcac_reference_serial
--                  and trunc(siaf_create_date,'dd') =datCreateDate)
--               where  SIAF_Interest_ColPos is null
--               and siaf_format_type = 'FB50'
--               and siaf_document_type='FX'
--               and siaf_voucher_reference= cur.bcac_voucher_reference
--               and siaf_reference_serial= cur.bcac_reference_serial
--               and trunc(siaf_create_date,'dd') =datCreateDate;
--          
--       exception
--        when others then 
--            numError :=fncAuditTrail('ErroCode : ' ||SQLCODE || ' varOperation ' || varOperation || ' Error Message : '  || SQLERRM,datCreateDate );
--            goto process_end;
--      end;   
      
         begin 
      varOperation := 'FB50 Option Update Bank Charges for Ref ' || cur.bcac_voucher_reference || ' Ref Sr No ' || cur.bcac_reference_serial ;    
      
      insert into temp values('FB50 Option Bank Charges for Ref ' || cur.bcac_voucher_reference || ' Ref Sr No ','');commit; 
      update trtran008C
              set ciaf_record_content = 
               CIAF_SERIAL_NUMBER || '|' || CIAF_COMPANY_CODE || '|' || to_char(CIAF_DOCUMENT_DATE,'yyyymmdd') || '|' || to_char(CIAF_POSTING_DATE,'yyyymmdd') 
               || '|' || CIAF_DOCUMENT_TYPE || '|' || CIAF_CURRENCY_CODE || '|' 
               || CIAF_EXCHANGE_RATE || '|' || to_char(CIAF_DOCUMENT_DATE,'yyyymmdd') || '|' || CIAF_DOCUMENT_HEADERTEXT || '|' || CIAF_POSTING_KEY || '|' 
               || CIAF_ACCOUNT_NUMBER || '|' || CIAF_VOUCHER_AMOUNT || '|'  || '|' || to_char(TO_DATE(CIAF_VALUE_DATE),'yyyymmdd') || '|' || CIAF_BANK_REFERENCE || '|' 
               || CIAF_PROFIT_CENTER || '|' || CIAF_COST_CENTER || '|' || CIAF_TEXT_FIELD
              where ciaf_format_type = 'FB50'
              and trunc(ciaf_create_date,'dd') =datCreateDate
              and ciaf_document_headertext= cur.bcac_voucher_reference
              and Ciaf_document_type='SA';
              
--      SELECT CIAF_FILE_NUMBER INTO varFileName
--      from trtran008c
--      where ciaf_format_type = 'FB50'
--              and trunc(ciaf_create_date,'dd') =datCreateDate
--              and ciaf_document_headertext= cur.bcac_voucher_reference
--              and Ciaf_document_type='SA';
--              
              
--              SIAF_VOUCHER_NUMBER || '|' || 	decode(SIAF_DOCPROCESS_COMPLETE,12400002,'O','C') || '|' ||	 to_char(siaf_document_date, 'YYYYMMDD') || '|' ||
--              to_char(siaf_posting_date, 'YYYYMMDD') || '|' ||	siaf_fiscal_period || '|' ||	siaf_fiscal_year || '|' ||	 siaf_bank_reference || '|' ||	 
--              siaf_bank_reference || '|' ||	decode(siaf_posting_key,50,'H','S') || '|' ||	siaf_account_head || '|' ||	siaf_voucher_fcy || 
--              '|' ||	siaf_voucher_inr || '|' ||
--              substr(SIAF_COST_CENTER,1,6) || '|' ||	siaf_cost_center	|| '|' || siaf_company_code|| '|' || decode(SIAF_Debit_Credit1,50,'H',40, 'S')	
--              || '|' ||	SIAF_GLCODE_CODE1 || '|' || siaf_voucher_fcy1	|| '|' || siaf_voucher_inr1	|| '|' || substr(SIAF_COST_CENTER1,1,6)	|| '|' 
--              || siaf_cost_center1 || '|' ||	siaf_company_code1	|| '|' || decode(SIAF_Debit_Credit2,50,'H',40,'S')	
--              || '|' ||	SIAF_GLCODE_CODE2 || '|' || siaf_voucher_fcy2	|| '|' || siaf_voucher_inr2	|| '|' || substr(SIAF_COST_CENTER2,1,6)	|| '|' 
--              || siaf_cost_center2 || '|' ||	siaf_company_code2	|| '|' || decode(SIAF_Debit_Credit3,50,'H',40,'S')	
--              || '|' ||	SIAF_GLCODE_CODE3 || '|' || siaf_voucher_fcy3	|| '|' || siaf_voucher_inr3	|| '|' || substr(SIAF_COST_CENTER3,1,6)	|| '|' 
--              || siaf_cost_center3 || '|' ||	siaf_company_code3	|| '|' || to_char(siaf_voucher_date,'YYYYMMDD') || '|' ||
--              siaf_voucher_detail|| '|' ||	 siaf_reference_number || '|' ||	siaf_voucher_currency || '|' ||	siaf_voucher_rate || '|' ||	SIAF_BUSINESS_PLACE
--              || '|' ||	to_char(siaf_document_date,'YYYYMMDD')
--               where siaf_format_type = 'FB50'
--              and trunc(siaf_create_date,'dd') =datCreateDate
--              and siaf_voucher_reference= cur.bcac_voucher_reference
--              and siaf_reference_serial= cur.bcac_reference_serial
--              and siaf_document_type='FX';
      exception
        when others then 
            numError :=fncAuditTrail('ErroCode : ' ||SQLCODE || ' varOperation ' || varOperation || ' Error Message : '  || SQLERRM,datCreateDate );
            goto process_end;
      end;      
 
<<process_end>>
 if numError !=0 then 
    rollback;
 else 
    commit;
 end if;
  numError:=0;
end loop;
  commit;
  varFile := varFileName;
  Return varFile;

Exception
When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('LoanClosure', numError, varMessage, 
                      Varoperation, Varerror);
      numError := fncAuditTrail(varError);                      
      raise_application_error(-20101, varError);                      
      return varFile;
End fncTreasuryOpt;

Function fncTreasuryIRS    
    (   datCreateDate in Date)
    return varchar2 as
--  Created on 04/01/10 by T M Manjunath
    PRAGMA AUTONOMOUS_TRANSACTION;
    numError            number;
    numRealize          number(2);
    numRecords          number(5);
    numFile             number(5);
    numCode             number(8);
    numType             number(8);
    numProcess          number(8);
    numCredit           number(15,4);
    numDebit            number(15,4);
    numBalance          number(15,4);
    numExchange         number(15,4);
    datVoucher          date;
    datProcess          date;
    varFlag             varchar2(15);
    varKey              varchar2(10);
    varCurrency         varchar2(10);
    varFileName         varchar2(30);
    varTimeStamp        varchar2(25);
    varReference        varchar2(25);
    varReference1       varchar2(30);
    Varfile             Varchar2(50);
    Varformats          Varchar2(50);
    varInvoices         varchar2(256);
    varText             varchar2(200);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    numRowCount1         number(10);
    numRowCount2         number(10);
    numSerial           number(10);
    chrCurrentACCheck   char(1);
    numVoucherType     number(10);

  begin


       
    varOperation := 'Creating FB50 format for FX';
        
    for cur in (select bcac_voucher_reference,bcac_reference_serial,bcac_account_head,
                  bcac_voucher_date,bcac_voucher_type
                from TRTRAN008
       where bcac_voucher_type not in (24800051,24800061)
       and trunc(BCAC_ADD_DATE,'dd') =datCreateDate
       and bcac_record_status in (10200003)
       group by bcac_voucher_reference,bcac_reference_serial,bcac_account_head,
       bcac_voucher_date,bcac_voucher_type)
       
       loop 

    --gVoucherDate := datVoucher;
    varOperation := 'FB50 Update Global Variables ';
     gFileName := 'IBS_FB50_' || to_char(datCreateDate, 'YYYYMMDD');
     gVoucherDate:= cur.bcac_voucher_date;
     gVoucherReference:= cur.bcac_voucher_reference;
     gVoucherSerial:= cur.bcac_reference_serial;
     gLocalBank:= 30699999;
     gTimeStamp:= to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3');
     gPackageName :='fncBillRealize';
     numVoucherType := cur.bcac_voucher_type;
     
--     numSerial := 1;


     begin
        varOperation := 'FB50 Opt transactions Ref ' || cur.bcac_voucher_reference || ' Ref Sr No ' || cur.bcac_reference_serial ;
        insert into temp values(cur.bcac_voucher_reference,cur.bcac_voucher_date);commit;
        
           select nvl(count(*),0),nvl(sum(bcac_voucher_inr),0) into numRowCount2,numRowCount1
           from trtran008
           where  trunc(BCAC_ADD_DATE,'dd') =datCreateDate
           and bcac_voucher_reference = cur.bcac_voucher_reference
           and bcac_reference_serial=cur.bcac_reference_serial
           and bcac_account_head between 24900050 and 24900149
           group by bcac_voucher_reference,bcac_reference_serial; 

          insert into trtran008c
          (
          
          CIAF_FORMAT_FILE, 
          CIAF_VOUCHER_NUMBER, CIAF_SERIAL_NUMBER, CIAF_FORMAT_TYPE,
          CIAF_COMPANY_CODE, CIAF_VALUE_DATE,
          CIAF_FILE_NUMBER, 
          CIAF_DOCUMENT_DATE, CIAF_POSTING_DATE, CIAF_DOCUMENT_TYPE,
          CIAF_CURRENCY_CODE, CIAF_EXCHANGE_RATE, CIAF_REFERENCE_NUMBER, 
          CIAF_DOCUMENT_HEADERTEXT,
          CIAF_POSTING_KEY, 
          CIAF_ACCOUNT_NUMBER, CIAF_VOUCHER_AMOUNT, CIAF_DOCUMENT_NUMBER,
          CIAF_BANK_ACCOUNT, CIAF_PROFIT_CENTER, CIAF_COST_CENTER, CIAF_TEXT_FIELD,
          CIAF_DUE_ON, CIAF_DUE_BY, CIAF_ISSUE_DATE, CIAF_ADVANCE_AMOUNT,
          CIAF_CURRENCY_DETAILS, CIAF_RECORD_CONTENT, CIAF_PROCESS_COMPLETE, CIAF_TIME_STAMP,
          CIAF_CREATE_DATE, CIAF_RECORD_STATUS, CIAF_VOUCHER_FCY,CIAF_BANK_REFERENCE)
          
          (
          select 'IBS_FB50_' || to_char(datCreateDate, 'YYYYMMDD') CIAF_FORMAT_FILE, 
          bcac_voucher_number CIAF_VOUCHER_NUMBER, bcac_reference_serial CIAF_SERIAL_NUMBER, 'FB50' CIAF_FORMAT_TYPE,
          decode(bcac_company_code,30100001,1000,30100002,1010,30100003,1030) CIAF_COMPANY_CODE,
          bcac_voucher_date CIAF_VALUE_DATE,
          'IBS_FB50_' || to_char(datCreateDate, 'YYYYMMDDHH24MISS') || lpad((substr(bcac_voucher_number,7,5)),4,'0')  CIAF_FILE_NUMBER, 
          bcac_create_date CIAF_DOCUMENT_DATE, bcac_voucher_date CIAF_POSTING_DATE, 'SA' CIAF_DOCUMENT_TYPE,
          /*bcac_voucher_currency*/ 'INR' CIAF_CURRENCY_CODE, 1 CIAF_EXCHANGE_RATE, bcac_voucher_reference CIAF_REFERENCE_NUMBER, 
          bcac_voucher_reference CIAF_DOCUMENT_HEADERTEXT,
          decode( BCAC_CRDR_CODE, 14600001,50,14600002,40) CIAF_POSTING_KEY, 
--          fncAccountHead(bcac_local_bank,
--                        BCAC_ACCOUNT_HEAD,bcac_crdr_code,20599999,32699999,
--                     24899999,23699999,nvl(bcac_account_number,'NA'),bcac_crdr_code) CIAF_ACCOUNT_NUMBER, 
          CASE WHEN BCAC_ACCOUNT_HEAD = 24900030 THEN
            fncAccountHead(bcac_local_bank,BCAC_ACCOUNT_HEAD,14699999,20599999,32699999,24899999,23699999,nvl(bcac_account_number,'NA'),25399999) 
              WHEN BCAC_ACCOUNT_HEAD = 24900150 THEN 
            PKGFXCURRENTINTERFACE.fncAccountHead(bcac_local_bank,
                        BCAC_ACCOUNT_HEAD,14699999,20599999,32699999,
                     24899999,23699999,nvl(bcac_account_number,'NA'),25399999)          
              WHEN BCAC_ACCOUNT_HEAD BETWEEN 24900050 AND 24900149 THEN
              PKGFXCURRENTINTERFACE.fncAccountHead(bcac_local_bank,BCAC_ACCOUNT_HEAD,14699999,20599999,32699999,24899999,23699999,nvl(bcac_account_number,'NA'),25399999)
          END CIAF_ACCOUNT_NUMBER,
          bcac_voucher_inr CIAF_VOUCHER_AMOUNT, 0 CIAF_DOCUMENT_NUMBER,
          pkgreturncursor.fncgetdescription(bcac_local_bank,2) CIAF_BANK_ACCOUNT, decode(bcac_company_code,30100001,100000,0) CIAF_PROFIT_CENTER, 
          decode(bcac_company_code,30100001,101219,0)  CIAF_COST_CENTER, bcac_voucher_detail CIAF_TEXT_FIELD,
          '' CIAF_DUE_ON, '' CIAF_DUE_BY, iirm_intend_date CIAF_ISSUE_DATE, 0 CIAF_ADVANCE_AMOUNT,
          pkgreturncursor.fncgetdescription(bcac_voucher_currency,2) CIAF_CURRENCY_DETAILS, '' CIAF_RECORD_CONTENT, 12400002 CIAF_PROCESS_COMPLETE, to_timestamp(sysdate) CIAF_TIME_STAMP,
          datCreateDate CIAF_CREATE_DATE, 10200001 CIAF_RECORD_STATUS, bcac_voucher_fcy CIAF_VOUCHER_FCY, bcac_bank_reference CIAF_BANK_REFERENCE
          from TRTRAN008
                        inner join trtran091b 
                    on bcac_voucher_reference = iirm_irs_number
                    and bcac_reference_serial = iirm_leg_serial
                    where bcac_voucher_type in( 24800052)
                    and iirm_process_complete = 12400001
                  and trunc(BCAC_ADD_DATE,'dd') =datCreateDate
                  and bcac_voucher_reference= cur.bcac_voucher_reference
                  and bcac_reference_serial= cur.bcac_reference_serial
                  and bcac_account_head = cur.bcac_account_head
                  and bcac_record_status in (10200003));
                  
                    varOperation := 'FB50 Bank Charges IRS' ;    
            -- for bank charges
            insert into trtran008c
                  (CIAF_FORMAT_FILE, 
                  CIAF_VOUCHER_NUMBER, CIAF_SERIAL_NUMBER, CIAF_FORMAT_TYPE,
                  CIAF_COMPANY_CODE, CIAF_VALUE_DATE,
                  CIAF_FILE_NUMBER, 
                  CIAF_DOCUMENT_DATE, CIAF_POSTING_DATE, CIAF_DOCUMENT_TYPE,
                  CIAF_CURRENCY_CODE, CIAF_EXCHANGE_RATE, CIAF_REFERENCE_NUMBER, 
                  CIAF_DOCUMENT_HEADERTEXT,
                  CIAF_POSTING_KEY, 
                  CIAF_ACCOUNT_NUMBER, CIAF_VOUCHER_AMOUNT, CIAF_DOCUMENT_NUMBER,
                  CIAF_BANK_ACCOUNT, CIAF_PROFIT_CENTER, CIAF_COST_CENTER, CIAF_TEXT_FIELD,
                  CIAF_DUE_ON, CIAF_DUE_BY, CIAF_ISSUE_DATE, CIAF_ADVANCE_AMOUNT,
                  CIAF_CURRENCY_DETAILS, CIAF_RECORD_CONTENT, CIAF_PROCESS_COMPLETE, CIAF_TIME_STAMP,
                  CIAF_CREATE_DATE, CIAF_RECORD_STATUS, CIAF_VOUCHER_FCY,CIAF_BANK_REFERENCE)
                  (select    CIAF_FORMAT_FILE, 
                  '.',CIAF_SERIAL_NUMBER, CIAF_FORMAT_TYPE,
                  CIAF_COMPANY_CODE, CIAF_VALUE_DATE,
                  CIAF_FILE_NUMBER, 
                  CIAF_DOCUMENT_DATE, CIAF_POSTING_DATE, CIAF_DOCUMENT_TYPE,
                  CIAF_CURRENCY_CODE, CIAF_EXCHANGE_RATE, CIAF_REFERENCE_NUMBER, 
                  CIAF_DOCUMENT_HEADERTEXT,50,
                  --decode(CIAF_POSTING_KEY,40,50,40), 
                  fncAccountHead(bcac_local_bank,
                                24900030,14699999,20599999,32699999,
                             24899999,23699999,nvl(bcac_account_number,'NA'),25399999) CIAF_ACCOUNT_NUMBER,
                  numRowCount1, ciaf_document_number,
                  CIAF_BANK_ACCOUNT, CIAF_PROFIT_CENTER, CIAF_COST_CENTER,'bank charges consolidated', 
                  '','',ciaf_document_date,0,
                  CIAF_CURRENCY_DETAILS,'',12400002,to_timestamp(ciaf_document_date),
                  ciaf_document_date,10200003, sum(CIAF_VOUCHER_FCY),''
                  from trtran008c a inner join trtran008
                  on a.ciaf_document_headertext = cur.bcac_voucher_reference
                  and bcac_account_head between 24900050 and 24900149
                  where
                  ciaf_document_headertext = cur.bcac_voucher_reference
                  and bcac_voucher_reference=cur.bcac_voucher_reference
                  and trunc(BCAC_ADD_DATE,'dd') =datCreateDate
                  and not exists (select * from trtran008c b 
                  where b.ciaf_voucher_number ='.' and b.ciaf_document_headertext=a.ciaf_document_headertext )
                  group by  bcac_local_bank,bcac_account_number,CIAF_FORMAT_FILE, 
                            CIAF_SERIAL_NUMBER, CIAF_FORMAT_TYPE,
                            CIAF_COMPANY_CODE, CIAF_VALUE_DATE,
                            CIAF_FILE_NUMBER, 
                            CIAF_DOCUMENT_DATE, CIAF_POSTING_DATE, CIAF_DOCUMENT_TYPE,
                            CIAF_CURRENCY_CODE, CIAF_EXCHANGE_RATE, CIAF_REFERENCE_NUMBER, 
                            CIAF_DOCUMENT_HEADERTEXT,
                            CIAF_POSTING_KEY,ciaf_document_number,
                            CIAF_BANK_ACCOUNT, CIAF_PROFIT_CENTER, CIAF_COST_CENTER, 
                            CIAF_CURRENCY_DETAILS);
                  
--          select CIAF_FORMAT_FILE, 
--          CIAF_VOUCHER_NUMBER, CIAF_SERIAL_NUMBER, CIAF_FORMAT_TYPE,
--          CIAF_COMPANY_CODE, CIAF_VALUE_DATE,
--          CIAF_FILE_NUMBER, 
--          CIAF_DOCUMENT_DATE, CIAF_POSTING_DATE, CIAF_DOCUMENT_TYPE,
--          CIAF_CURRENCY_CODE, CIAF_EXCHANGE_RATE, CIAF_REFERENCE_NUMBER, 
--          CIAF_DOCUMENT_HEADERTEXT,
--          CIAF_POSTING_KEY, 
--          CIAF_ACCOUNT_NUMBER, CIAF_VOUCHER_AMOUNT, CIAF_DOCUMENT_NUMBER,
--          CIAF_BANK_ACCOUNT, CIAF_PROFIT_CENTER, CIAF_COST_CENTER, CIAF_TEXT_FIELD,
--          CIAF_DUE_ON, CIAF_DUE_BY, CIAF_ISSUE_DATE, CIAF_ADVANCE_AMOUNT,
--          CIAF_CURRENCY_DETAILS, CIAF_RECORD_CONTENT, CIAF_PROCESS_COMPLETE, CIAF_TIME_STAMP,
--          CIAF_CREATE_DATE, CIAF_RECORD_STATUS, CIAF_VOUCHER_FCY,CIAF_BANK_REFERENCE
--          from CTE;
     exception
     when others then 
            numError :=fncAuditTrail('ErroCode : ' ||SQLCODE || ' varOperation ' || varOperation || ' Error Message : '  || SQLERRM,datCreateDate );
            goto process_end;
     end;  
     
      
       
      
       
--       24900031	PCL Interest
--24900032	PSL Interest
--24900033	FBK Charges
--24900034	FD Interest
--24900035	BC Interest
--24900036	TL Interest
--24900037	PBD
--24900038	PBD Interest
--numRowCount2:=0;
--numRowCount1:=0;
   
--   begin 
--       varOperation := 'FB50 FX Details Update Ref ' || cur.bcac_voucher_reference || ' Ref Sr No ' || cur.bcac_reference_serial ;
--
--        Update trtran008E set (SIAF_GLCODE_CODE1 ,SIAF_DEBIT_CREDIT1,SIAF_VOUCHER_FCY1,
--                SIAF_VOUCHER_INR1,SIAF_COST_CENTER1,SIAF_COMPANY_CODE1,SIAF_Interest_ColPos) =
--              (select fncAccountHead(PKGRETURNCURSOR.fncGetTradeFiananceCode(BCAC_LOCAL_BANK),BCAC_ACCOUNT_HEAD,14699999,
--                                    20599999,32699999,24899999,23699999),
--                               decode( PKGRETURNCURSOR.fncGetTradeFiananceCode(BCAC_CRDR_CODE), 14600001,50,14600002,40),
--                               bcac_voucher_fcy,BCAC_VOUCHER_INR,
--                                pkgIndofilCurrentInterface.fncCostCenter(10300501,30299999,32600001,Gconst.EventBankCharges),
--                               1000,
--                               2
--                      from TRTRAN008  c 
--                        inner join TRTRAN006 
--                    on bcac_voucher_reference = cdel_deal_number
--                    and bcac_reference_serial=cdel_reverse_serial
--                 where bcac_voucher_type = 24800051 --bcac_voucher_type = 24800099
--                  and bcac_account_head =24900030 -- Covers all the GL Heads  
--                  --AND BCAC_VOUCHER_FCY != 0
--                  and trunc(BCAC_ADD_DATE,'dd') =datCreateDate
--                  and bcac_record_status in (10200003)
--                  and cdel_record_status in (10200003)
--                  and SIAF_VOUCHER_REFERENCE= bcac_voucher_reference
--                  and Siaf_reference_serial= bcac_reference_serial
--                  and trunc(siaf_create_date,'dd') =datCreateDate)
--               where  SIAF_Interest_ColPos is null
--               and siaf_format_type = 'FB50'
--               and siaf_document_type='FX'
--               and siaf_voucher_reference= cur.bcac_voucher_reference
--               and siaf_reference_serial= cur.bcac_reference_serial
--               and trunc(siaf_create_date,'dd') =datCreateDate;
--          
--       exception
--        when others then 
--            numError :=fncAuditTrail('ErroCode : ' ||SQLCODE || ' varOperation ' || varOperation || ' Error Message : '  || SQLERRM,datCreateDate );
--            goto process_end;
--      end;   
      
         begin 
      varOperation := 'FB50 IRS Update  for Ref ' || cur.bcac_voucher_reference || ' Ref Sr No ' || cur.bcac_reference_serial ;    
      
      insert into temp values('FB50 IRS File Gen for Ref ' || cur.bcac_voucher_reference || ' Ref Sr No ','');commit; 
      update trtran008C
              set ciaf_record_content = 
               CIAF_SERIAL_NUMBER || '|' || CIAF_COMPANY_CODE || '|' || to_char(CIAF_DOCUMENT_DATE,'yyyymmdd') || '|' || to_char(CIAF_POSTING_DATE,'yyyymmdd') 
               || '|' || CIAF_DOCUMENT_TYPE || '|' || CIAF_CURRENCY_CODE || '|' 
               || CIAF_EXCHANGE_RATE || '|' || to_char(CIAF_DOCUMENT_DATE,'yyyymmdd') || '|' || CIAF_DOCUMENT_HEADERTEXT || '|' || CIAF_POSTING_KEY || '|' 
               || CIAF_ACCOUNT_NUMBER || '|' || CIAF_VOUCHER_AMOUNT || '|'  || '|' || to_char(TO_DATE(CIAF_VALUE_DATE),'yyyymmdd') || '|' || CIAF_BANK_REFERENCE || '|' 
               || CIAF_PROFIT_CENTER || '|' || CIAF_COST_CENTER || '|' || CIAF_TEXT_FIELD
              where ciaf_format_type = 'FB50'
              and trunc(ciaf_create_date,'dd') =datCreateDate
              and ciaf_document_headertext= cur.bcac_voucher_reference
              and Ciaf_document_type='SA';
              
--      SELECT CIAF_FILE_NUMBER INTO varFileName
--      from trtran008c
--      where ciaf_format_type = 'FB50'
--              and trunc(ciaf_create_date,'dd') =datCreateDate
--              and ciaf_document_headertext= cur.bcac_voucher_reference
--              and Ciaf_document_type='SA';
--              
              
--              SIAF_VOUCHER_NUMBER || '|' || 	decode(SIAF_DOCPROCESS_COMPLETE,12400002,'O','C') || '|' ||	 to_char(siaf_document_date, 'YYYYMMDD') || '|' ||
--              to_char(siaf_posting_date, 'YYYYMMDD') || '|' ||	siaf_fiscal_period || '|' ||	siaf_fiscal_year || '|' ||	 siaf_bank_reference || '|' ||	 
--              siaf_bank_reference || '|' ||	decode(siaf_posting_key,50,'H','S') || '|' ||	siaf_account_head || '|' ||	siaf_voucher_fcy || 
--              '|' ||	siaf_voucher_inr || '|' ||
--              substr(SIAF_COST_CENTER,1,6) || '|' ||	siaf_cost_center	|| '|' || siaf_company_code|| '|' || decode(SIAF_Debit_Credit1,50,'H',40, 'S')	
--              || '|' ||	SIAF_GLCODE_CODE1 || '|' || siaf_voucher_fcy1	|| '|' || siaf_voucher_inr1	|| '|' || substr(SIAF_COST_CENTER1,1,6)	|| '|' 
--              || siaf_cost_center1 || '|' ||	siaf_company_code1	|| '|' || decode(SIAF_Debit_Credit2,50,'H',40,'S')	
--              || '|' ||	SIAF_GLCODE_CODE2 || '|' || siaf_voucher_fcy2	|| '|' || siaf_voucher_inr2	|| '|' || substr(SIAF_COST_CENTER2,1,6)	|| '|' 
--              || siaf_cost_center2 || '|' ||	siaf_company_code2	|| '|' || decode(SIAF_Debit_Credit3,50,'H',40,'S')	
--              || '|' ||	SIAF_GLCODE_CODE3 || '|' || siaf_voucher_fcy3	|| '|' || siaf_voucher_inr3	|| '|' || substr(SIAF_COST_CENTER3,1,6)	|| '|' 
--              || siaf_cost_center3 || '|' ||	siaf_company_code3	|| '|' || to_char(siaf_voucher_date,'YYYYMMDD') || '|' ||
--              siaf_voucher_detail|| '|' ||	 siaf_reference_number || '|' ||	siaf_voucher_currency || '|' ||	siaf_voucher_rate || '|' ||	SIAF_BUSINESS_PLACE
--              || '|' ||	to_char(siaf_document_date,'YYYYMMDD')
--               where siaf_format_type = 'FB50'
--              and trunc(siaf_create_date,'dd') =datCreateDate
--              and siaf_voucher_reference= cur.bcac_voucher_reference
--              and siaf_reference_serial= cur.bcac_reference_serial
--              and siaf_document_type='FX';
      exception
        when others then 
            numError :=fncAuditTrail('ErroCode : ' ||SQLCODE || ' varOperation ' || varOperation || ' Error Message : '  || SQLERRM,datCreateDate );
            goto process_end;
      end;      
 
<<process_end>>
 if numError !=0 then 
    rollback;
 else 
    commit;
 end if;
  numError:=0;
end loop;
  commit;
  varFile := varFileName;
  Return varFile;

Exception
When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('LoanClosure', numError, varMessage, 
                      Varoperation, Varerror);
      numError := fncAuditTrail(varError);                      
      raise_application_error(-20101, varError);                      
      return varFile;
End fncTreasuryIRS;


Function fncFXDealBuysell
    (   varDealNumber in varchar2,
        SerialNumber in Number)
        return number
as
    Numerror            Number;
    numBuysell number(8);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;

  begin
--    Varcenter := '';
--    varInvoice := InvoiceNumber;
    
    varOperation := 'Extracting Location Details for Invoice';
    select deal_buy_sell
      into numBuysell
      from trtran001
      where deal_deal_number =varDealNumber
      and deal_record_status not in (10200005,12000006);
 
    
    return numBuysell;
    
    Exception
    When others then
      numError := SQLCODE;
      Varerror := Sqlerrm;
     -- varError := varError || ' Inv: ' || varInvoice;
      varError := GConst.fncReturnError('BuySell', numError, varMessage, 
                      Varoperation, Varerror);
      raise_application_error(-20101, varError);                      
      return 0;

  end fncFXDealBuysell;    


Function fncRunInterface(VoucherDate in Date)
    return number
    as
-- Written on 08/09/2010 by T M Manjunath
    PRAGMA AUTONOMOUS_TRANSACTION;
    numError            number;
    numSerial           number(5);
    numRecords          number(5);
    numErrors           number(5);
    varReference        varchar2(50);
    varFile             varchar2(50);
    varQuery            varchar2(2048);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    datFrom             date;
    datTo               date;
Begin
    numError := 0;
    varMessage := 'Processing Vouchers for Date: ' || VoucherDate;
    varFile := fncTreasuryFWD(VoucherDate);
    varFile := fncTreasuryOpt(VoucherDate);
    varFile := fncTreasuryIRS(VoucherDate);
  return numError;
Exception
When others then
--      numError := SQLCODE;
--      varError := SQLERRM;
--      varError := GConst.fncReturnError('RunInterface', numError, varMessage, 
--                      Varoperation, Varerror);
--      numError := fncAuditTrail(varError);                      
--      raise_application_error(-20101, varError);
      ROLLBACK;
      return numError;
End fncRunInterface;

End PKGFXCURRENTINTERFACE;
/