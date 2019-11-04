CREATE OR REPLACE FUNCTION "TEST_VSTSRedgate"."FNCCURRENTACCOUNT" 
    (   RecordDetail in GConst.gClobType%Type,
        ErrorNumber in out nocopy number)
    return clob
    is
--  Created on 23/09/2007
    numError            number;
    numTemp             number;
  
    numStatus           number;
    numSub              number(3);
    numAction           number(4);
    numSerial           number(5);
    numCompany          number(8);
    numLocation         number(8);
    numBank             number(8);
    numCrdr             number(8);
    numType             number(8);
    numHead             number(8);
    numCurrency         number(8);
    numMerchant         number(8);
    numRecord           number(8);
    numFCY              number(15,4);
    numRate             number(15,4);
    numINR              number(15,2); 
    varAccount          varchar2(25);
    varVoucher          varchar2(25);
    varBankRef          varchar2(25);
    varReference        varchar2(30);
    varUserID           varchar2(30);
    varEntity           varchar2(30);
    varDetail           varchar2(100);
    varTemp             varchar2(512);
    varTemp1            varchar2(512);
    varTemp2            varchar2(512);
    varXPath            varchar2(512);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    datWorkDate         date;
    clbTemp             clob;
    xmlTemp             xmlType;
    nodTemp             xmlDom.domNode;
    nodVoucher          xmlDom.domNode;
    nmpTemp             xmldom.domNamedNodeMap;
    nlsTemp             xmlDom.DomNodeList;
    nlsTemp1            xmlDom.DomNodeList;
    xlParse             xmlparser.parser;
    nodFinal            xmlDom.domNode;
    docFinal            xmlDom.domDocument;
Begin
    varMessage := 'Current Account Entries';
    dbms_lob.createTemporary (clbTemp,  TRUE);
    clbTemp := RecordDetail;
    numError := 1;
    varOperation := 'Extracting Input Parameters';
    xmlTemp := xmlType(RecordDetail);

    varUserID := GConst.fncXMLExtract(xmlTemp, 'UserCode', varUserID);
    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
    numCompany := GConst.fncXMLExtract(xmlTemp, 'CompanyID', numCompany);
    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationID', numLocation);
    
    numError := 2;
    varOperation := 'Creating Document for Master';
    docFinal := xmlDom.newDomDocument(xmlTemp);
    nodFinal := xmlDom.makeNode(docFinal);
    
    varXPath := '//CURRENTACCOUNTMASTER/ROW';
    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
    numSub := xmlDom.getLength(nlsTemp);
    
    if numSub = 0 then
      return clbTemp;
    End if;

    Begin
      varTemp := varXPath || '[@NUM="1"]/LocalBank';
      numBank := GConst.fncXMLExtract(xmlTemp,varTemp,numBank,Gconst.TYPENODEPATH);

      select lbnk_Account_number
        into varAccount
        from trmaster306
        where lbnk_company_code = numCompany
        and lbnk_pick_code = numBank;
        --and bank_record_type = GConst.BANKCURRENT
--        and bank_effective_date = 
--        (select max(bank_effective_date)
--          from tftran015
--          where bank_company_code = numCompany
--          and bank_local_bank = numBank
--          and bank_record_type = GConst.BANKCURRENT
--          and bank_effective_date <= datWorkDate);
    Exception
      when no_data_found then
        varAccount := '';
    End;

    for numSub in 0..xmlDom.getLength(nlsTemp) -1
    Loop
      nodTemp := xmlDom.Item(nlsTemp, numSub);
      nmpTemp:= xmlDom.getAttributes(nodTemp);
      nodTemp := xmlDom.Item(nmpTemp, 0);
      numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
      varTemp := varXPath || '[@NUM="' || numTemp || '"]/';
--      varTemp1 := varTemp || 'LocalBank';
--      numBank := GConst.fncXMLExtract(xmlTemp,varTemp1,numBank,Gconst.TYPENODEPATH);
--      nodVoucher := xmlDom.Item(xslProcessor.selectNodes(nodFinal, varTemp || 'VoucherNumber'),0);
      nodVoucher := xslProcessor.selectSingleNode(nodFinal, varTemp || 'VoucherNumber');
      varTemp1 := varTemp || 'CrdrCode';
      numCrdr := GConst.fncXMLExtract(xmlTemp,varTemp1,numCrdr,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'AccountHead';
      numHead := GConst.fncXMLExtract(xmlTemp,varTemp1,numHead,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'VoucherType';
      numType := GConst.fncXMLExtract(xmlTemp,varTemp1,numType,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'RecordType';
      numRecord := GConst.fncXMLExtract(xmlTemp,varTemp1,numRecord,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'CurrencyCode';
      numCurrency := GConst.fncXMLExtract(xmlTemp,varTemp1,numCurrency,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'VoucherReference';
      varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'ReferenceSerial';
      numSerial := GConst.fncXMLExtract(xmlTemp,varTemp1,numSerial,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'VoucherFcy';
      numFcy := GConst.fncXMLExtract(xmlTemp,varTemp1,numFcy,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'VoucherRate';
      numRate := GConst.fncXMLExtract(xmlTemp,varTemp1,numRate,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'VoucherInr';
      numInr := GConst.fncXMLExtract(xmlTemp,varTemp1,numInr,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'VoucherDetail';
      varDetail := GConst.fncXMLExtract(xmlTemp,varTemp1,varDetail,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'BankReference';
      varBankRef := GConst.fncXMLExtract(xmlTemp,varTemp1,varBankRef,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'LocalMerchant';
      numMerchant := GConst.fncXMLExtract(xmlTemp,varTemp1,numStatus,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'RecordStatus';
      numStatus := GConst.fncXMLExtract(xmlTemp,varTemp1,numStatus,Gconst.TYPENODEPATH);
      
      if numAction = GConst.DELETESAVE then
        numStatus := GConst.LOTDELETED;
      elsif numAction = GConst.CONFIRMSAVE then
        numStatus := GConst.LOTCONFIRMED;
      end if;
      
      varOperation := 'Processing Current Account Transaction';
      
      if numStatus = GConst.LOTNOCHANGE then
        NULL;
      elsif numStatus = GConst.LOTNEW then
 --Added on 31/03/08 to accomodate primary keys that come with serial number  and where numbers are generated on 'Add' mode 
        if varEntity in ('FDCLOSURE') then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDCL_FD_NUMBER';
          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
        elsif varEntity in ('FIXEDDEPOSITFILE') then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDRF_FD_NUMBER';
          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
        elsif varEntity in ('PSLLOAN', 'PSCFCLOAN') then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/INLN_PSLOAN_NUMBER';
          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);

        elsif varEntity = 'BILLREALISATION' then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BREL_REALIZATION_NUMBER';
          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
        elsif varEntity = 'IMPORTREALIZE' then
         varTemp2 := '//' || varEntity || '/ROW[@NUM]/SPAY_SHIPMENT_SERIAL';
         numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
        elsif varEntity = 'ROLLOVERFILE' then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/LMOD_REFERENCE_SERIAL';
          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
        elsif varEntity = 'BUYERSCREDIT' then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BCRD_BUYERS_CREDIT';
          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
          numSerial := 0;
          varDetail := varDetail || varReference;
        elsif varEntity = 'EXPORTADVANCE' then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/EADV_ADVANCE_REFERENCE';
          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
          numSerial := 0;
          varDetail := varDetail || varReference;
        elsif varEntity in ('INTERESTCAL', 'LOANCLOSURE') then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/INTC_PSLOAN_NUMBER';
          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
        elsif varEntity = 'TERMLOAN' then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/TLON_LOAN_NUMBER';
          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
          numSerial := 0;
          varDetail := varDetail || varReference;
        elsif varEntity = 'FOREIGNREMITTANCE' then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/REMT_REMITTANCE_REFERENCE';
          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
          numSerial := 0;
          varDetail := varDetail || varReference;
        elsif varEntity = 'IMPORTLCAMENDMENT' then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/POLC_SERIAL_NUMBER';
          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
        elsif varEntity = 'BUYERSCREDITROLLOVER' then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BCRL_SERIAL_NUMBER';
          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
        elsif varEntity = 'BCCLOSURE' then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BRPY_SERIAL_NUMBER';
          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
        elsif varEntity = 'BANKGUARANTEE' then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BGAR_BG_NUMBER';
          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
          numSerial := 0;
          varDetail := varDetail || varReference;
        elsif varEntity = 'BGROLLOVER' then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BGRL_SERIAL_NUMBER';
          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
        end if;

        varVoucher := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
        insert into trtran008 (bcac_company_code, bcac_location_code, 
        bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code, 
        bcac_account_head, bcac_voucher_type, bcac_voucher_reference, 
        bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy, 
        bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
        bcac_create_date, bcac_local_merchant, bcac_record_status,
        bcac_record_type, bcac_account_number, bcac_bank_reference)
        values(numCompany, numLocation, numBank, varVoucher, datWorkDate,
        numCrdr, numHead, numType, varReference, numSerial, numCurrency,
        numFcy, numRate, numInr, varDetail, sysdate, numMerchant, GConst.STATUSENTRY,
        numRecord, varAccount, varBankRef);
        
        numError := GConst.fncSetNodeValue(nodFinal, nodVoucher, varVoucher);
      elsif numStatus = GConst.LOTMODIFIED then
        update trtran008
          set bcac_voucher_date = datWorkDate,
          bcac_voucher_fcy = numFcy,
          bcac_voucher_rate = numRate,
          bcac_voucher_inr = numInr,
          bcac_crdr_code = numCrdr,
          bcac_record_type = numRecord,
          bcac_bank_reference = varBankRef,
          bcac_record_status = GConst.STATUSUPDATED 
          where bcac_voucher_reference = varReference
          and bcac_reference_serial = numSerial
          and bcac_account_head = numHead;
      else
        select decode(numStatus,
          GConst.LOTDELETED, GConst.STATUSDELETED,
          GConst.LOTCONFIRMED, GConst.STATUSAUTHORIZED)
          into numStatus
          from dual;

        update trtran008
          set bcac_record_status = numStatus
          where bcac_voucher_reference = varReference
          and bcac_reference_serial = numSerial
          and bcac_account_head = numHead;
          
      end if;
    
    End Loop;
--    varOperation:='Reconsile Entry';
--    numError := fncReconsile(  RecordDetail,numType,varReference);
--    
--    if datWorkDate >= '01-MAR-10' and numCompany = 10300201 and  numAction = GConst.CONFIRMSAVE then
--      If  Varentity In ('PSLLOAN', 'PSCFCLOAN') Then
--        varTemp1 := pkgCurrentInterface.fncPSCFCFormat(varReference, numSerial);
--      
--      Elsif Varentity = 'BILLREALISATION' Then
--      
--        Vartemp1 := Pkgcurrentinterface.Fncbillrealize(Varreference, Numserial);
--      
--      Elsif Varentity = 'FREIGHTBATCH' Then
--        Varoperation := 'Generating Entries for Export Freight';
--        For Curfreight In
--        (Select distinct Sfrg_Invoice_Number, Sfin_Local_Bank,Sfin_Rtgs_Date
--          From Tftran073, Tftran074
--          Where sfrg_batch_number = sfin_batch_number
--          and Sfrg_Batch_Number = varReference)
--        Loop
--          Vartemp1 := Pkgcurrentinterface.Fncfreightcharges
--                      (Curfreight.Sfrg_Invoice_Number,
--                       Curfreight.Sfin_Local_Bank,
--                       curFreight.sfin_rtgs_date);
--        End Loop;
--        
--      else
--        varTemp1 := pkgCurrentInterface.fncGeneralFormat(varReference, numSerial);
--      end if;      
--    End if;

    dbms_lob.createTemporary (clbTemp,  TRUE);
    xmlDom.WriteToClob(nodFinal, clbTemp);    
    return clbTemp;
Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM || varVoucher;
      varError := GConst.fncReturnError('CurAccount', numError, varMessage, 
                      varOperation, varError);
      raise_application_error(-20101, varError);                      
      return clbTemp;
End fncCurrentAccount;
/