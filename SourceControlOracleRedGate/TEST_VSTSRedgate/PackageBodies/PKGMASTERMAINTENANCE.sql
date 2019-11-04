CREATE OR REPLACE PACKAGE BODY "TEST_VSTSRedgate"."PKGMASTERMAINTENANCE" is


Function fncBuildQuery
    (   ParamData   in  Gconst.gClobType%Type)
    return varchar2

    is

    numError            number;
    numAction           number(3);
    numTemp             number(4);
    numCnt              number(4);
    numRecords          number(4);
    varStatusField      varchar2(30);
    varEntity           varchar2(30);
    varValue            varchar2(100);
    varKey              varchar2(2048);
    varQuery            varchar2(4000);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;

Begin
    numError := 4;
    numTemp := 0;
    numCnt := 0;
    numRecords := 0;
    varQuery := 'select ';
    varKey := ' where ';
 
    varOperation := 'Extracting parameters for building query';
 --   insert into rtemp(TT,TT2) values ('Inside fncBuildQuery 0','welcome - Extracting parameters for building query');commit;
    varEntity := GConst.fncXMLExtract(xmlType(ParamData), 'Entity', varEntity);
    numAction := GConst.fncXMLExtract(xmlType(ParamData), 'Action', numAction);
    varMessage := 'Building dynamic query for: ' || varEntity;

    varOperation := 'Extracting Entity fields for : ' || varEntity;
  --insert into rtemp(TT,TT2,TT3) values ('Inside fncBuildQuery 1','numAction: '||numAction||' varEntity: '||varEntity,' ParamData: '||ParamData);commit;


    For curFields in
    (select fldp_column_name, fldp_xml_field,
        fldp_key_no, fldp_data_type
        from trsystem999
        where fldp_table_synonym = varEntity
        AND FLDP_PROCESS_YN=12400001
        order by fldp_column_id)

    Loop
    numCnt := numCnt +1;
-- insert into rtemp(TT,TT2) values ('Inside fncBuildQuery looping 3','numCnt: '||numCnt );commit;
      if varEntity = 'TRADEDEALREGISTER' and curFields.fldp_xml_field = 'SerialNumber' then
        curFields.fldp_key_no := 0;
      elsif  varEntity = 'DEALCONFIRMATION' and curFields.fldp_xml_field = 'SerialNumber' then
        curFields.fldp_key_no := 0;
      end if;

      if curFields.fldp_xml_field = 'RecordStatus' then
        varStatusField := curFields.fldp_column_name;
      end if;

      if numRecords > 0 then
        varQuery := varQuery || ',';
      end if;

      if curFields.fldp_key_no != 0 then

        if numTemp > 0 then
          varKey := varKey || ' and ';
        end if;

        varValue := GConst.fncReturnParam(ParamData, curFields.fldp_xml_field);
        varkey := varKey || ' ' || curFields.fldp_column_name || ' = ';

        if curFields.fldp_data_type = 'DATE' then
            varKey := varKey || ' to_date(' || '''' || substr(varValue,1,10) || '''' || ',';
            varKey := varKey || '''' || 'dd/mm/yyyy' || '''' || ')';
        elsif curFields.fldp_data_type <> 'NUMBER' then
            varkey := varKey || '''' || varValue || '''';
        else
          varkey := varKey || varValue;
        end if;

        numTemp := numTemp + 1;

      end if;

      if curFields.fldp_data_type = 'DATE' then
        varQuery := varQuery || ' to_char(' || curFields.fldp_column_name || ',';
        varQuery := varQuery || '''' || 'dd/mm/yyyy' || '''' || ') as ';
      else
        varQuery := varQuery || curFields.fldp_Column_name || ' as ';
      end if;

      --varQuery := varQuery || '"' || curFields.fldp_column_name || '"';--commented by hari after taking TMM DB
      varQuery := varQuery || '"' || curFields.fldp_xml_field || '"';
      -- varQuery := varQuery || '"' || curFields.fldp_xml_field || '"';
      numRecords := numRecords + 1;
    End Loop;


    varQuery := varQuery || ' from ' || varEntity || varKey;

    varQuery := varQuery || ' and ' || varStatusField || ' not in (';
    varQuery := varQuery || GConst.STATUSINACTIVE || ',' || GConst.STATUSDELETED || ')';
    --    if numAction = GConst.VIEWLOAD then
    --      varQuery := varQuery || ' and ' || varStatusField || ' != ';
    --      varQuery := varQuery || GConst.STATUSAUTHORIZED;
    --    elsif numAction in (GConst.EDITLOAD, GConst.DELETELOAD) then
    --      varQuery := varQuery || ' and ' || varStatusField || ' not in (';
    --      varQuery := varQuery || GConst.STATUSINACTIVE || ',' || GConst.STATUSDELETED || ')';
    --    elsif numAction =  GConst.CONFIRMLOAD then
    --      varQuery := varQuery || ' and ' || varStatusField || ' in ( ';
    --      varQuery := varQuery || GConst.STATUSENTRY || ',' || GConst.STATUSUPDATED || ')';
    --    end if;

    --  For Edit Codes: Everything except inactive
    --  for Delete: same as above
    --  For Confirm: only records with updated status

--insert into rtemp(TT,TT2) values ('Inside fncBuildQuery 4','varQuery: '||varQuery );commit;
       return varQuery;

    Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('BuildQuery', numError, varMessage,
                      varOperation, varError);
      raise_application_error(-20101, varError);
      return varQuery;
End;

Function fncAuditTrail
    ( TableData in clob,
      ImageType in number)
      Return Number
      is
--  Created on 23/04/08

    numError            number;
    numRecords          number;
    numAction           number;
    numSerial           number(12);
    numSc               number(15,6);
    numSp               number(15,6);
    numbc               number(15,6);
    numbp               number(15,6);
    datWorkDate         date;
    varImage            varchar2(10);
    varPattern          varchar2(50);
    varDateStamp        varchar2(25);
    varSource           varchar2(30);
    varTarget           varchar2(30);
    varReference        varchar2(25);
    varTemp             varchar2(1000);
    varQuery            varchar2(4000);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    xmlTemp             GConst.gXMLType%Type;
    xmlTemp1            GConst.gXMLType%Type;
    queryCTX            dbms_xmlQuery.ctxHandle;
    clbParam            clob;
    clbError            clob;
    clbProcess          clob;
Begin
    numError := 0;
    varOperation := 'Extracting table details';
    xmlTemp := xmlType(TableData);
   --- insert into temp values (xmlTemp,'Audit Trail'); commit;
    varSource := GConst.fncXMLExtract(xmlTemp, 'Entity', varSource);
    numAction := NVL(to_number(GConst.fncXMLExtract(xmlTemp, 'Action', numAction)),0);
    
    --- Commented on 24-11-2018 because of date format issues we need to enable the same 
    --datworkdate := gconst.fncxmlextract(xmlTemp,'WorkDate',datworkdate);
    datworkdate := sysdate;
    
    if numAction in (GConst.ADDSAVE, GcONST.CONFIRMSAVE) then
      return numError;
    end if;

    varMessage := 'Creating Audit trail for ' || varSource;

    Begin
      varOperation := 'Checking the audit trail table';
      select audt_audit_id
        into varTarget
        from trsystem015
        where audt_table_id = varSource;
      Exception
        when no_data_found then
          numError := -1;
    End;

    if  numError = -1 then
      return 0;
    end if;

    varQuery := fncBuildQuery(TableData);
    varQuery := 'select * ' || substr(varQuery, instr(varQuery, 'from'));

    select fldp_column_name
      into varPattern
      from trsystem999
      where fldp_table_synonym = varSource
      and fldp_xml_field = 'RecordStatus';

    varPattern := 'and ' || varPattern || ' not in (10200005,10200006)';
    varQuery := replace(varQuery, varPattern, '');
    varOperation := 'Extracting data in XML';
    dbms_lob.createTemporary (clbParam,  TRUE);
    queryCTX := dbms_xmlQuery.newContext(varQuery);
    dbms_xmlQuery.setDateFormat(queryCTX, 'dd/MM/yyyy');
    clbParam := dbms_xmlQuery.getxml(queryCTX);
    xmlTemp1 := xmlType(clbParam);
    numRecords := dbms_xmlQuery.getNumRowsProcessed(queryCTX);
    dbms_xmlQuery.closeContext(queryCTX);
    dbms_lob.createTemporary (clbError,  TRUE);
    dbms_lob.createTemporary (clbProcess,  TRUE);
--    numSerial := GConst.fncGenerateSerial(GConst. SERIALAUDIT);

    numError := GConst.fncSetParam(xmlTemp1, 'Entity', varTarget, 2);
    clbParam := xmlTemp1.getClobval();
    GConst.prcGenericInsert(clbParam, clbError, clbProcess);

    varTemp := substr(varQuery, instr(varQuery, 'where'));
    varQuery := 'update ' || varTarget || ' set ';
--------------------------------------------------------------------------------------------
--  Added to accomodate the second table - trtrn072 in the audit trail for options 13/02/13- TMM
--  the value cannot be taken from the view as figures will not be reflected till session is over
    if varSource in ('OPTIONHEDGEDEAL','OPTIONTRADEDEAL') then
        varOperation := 'Getting Strike Rates for Option Deal';

        varReference := GConst.fncXMLExtract(xmlTemp, 'COPT_DEAL_NUMBER', varReference);

        select NVL(bc.cosu_strike_rate,0) BC, NVL(bp.cosu_strike_rate, 0) BP,
        NVL(sc.cosu_strike_rate,0) SC, NVL(sp.cosu_strike_rate, 0) SP
        into numBc, numBp, numSc, numSP
        from trtran071
        left outer join trtran072 bc
          on copt_deal_number = bc.cosu_deal_number
          and bc.cosu_buy_sell = 25300001
          and bc.cosu_option_type = 32400001
        left outer join trtran072 bp
          on copt_deal_number = bp.cosu_deal_number
          and bp.cosu_buy_sell = 25300001
          and bp.cosu_option_type  = 32400002
        left outer join trtran072 sc
          on copt_deal_number = sc.cosu_deal_number
          and sc.cosu_buy_sell = 25300002
          and sc.cosu_option_type = 32400001
        left outer join trtran072 sp
          on copt_deal_number = sp.cosu_deal_number
          and sp.cosu_buy_sell = 25300002
          and sp.cosu_option_type  = 32400002
        where copt_deal_number = varReference;

      varQuery := varQuery || ' SC = :4, SP = :5, BC = :6, BP = :7,';


    End if;

------------------------------------------------------------------------------------------
    varQuery := varQuery || ' workdate = :1, DateStamp = :2, ImageType = :3, Entity = :4';
    varQuery := varQuery || varTemp;
    varQuery := varQuery || ' and ImageType is null';
    select to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
      decode(ImageType, GConst.BEFOREIMAGE, 'Before',
        GConst.AFTERIMAGE, 'After', 'Unknown')
      into varDateStamp, varImage
      from dual;

    varOperation := 'Updating Audti Trails for ' || varSource;
    if varSource in ('OPTIONHEDGEDEAL','OPTIONTRADEDEAL') then
      Execute Immediate varQuery using numSc, numSp, numBc, numBp,datWorkDate, varDateStamp, varImage, varSource;
    else
      Execute Immediate varQuery using datWorkDate, varDateStamp, varImage, varSource;
    end if;

    return numError;
Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('AuditTrail', numError, varMessage,
                      varOperation, varError);
      raise_application_error(-20101, varError);
      return numError;
End fncAuditTrail;

Procedure prcProcessPickup
              ( PickDetails in Clob,
                PickField in varchar2,
                PickValue out nocopy varchar2)
is
    --  created on 04/04/2007
    --  Last Modified on 07/04/2007
      numError            number;
      numRecords          number;
      numAction           number(3);
      numKeyGroup         number(3);
      numKeyNumber        number(5);
      numPickValue        number(8);
      numKeyType          number(8);
      numRecordStatus     number(8);
      varUserID           varchar2(15);
      varPickField        varchar2(30);
      varLongField        varchar2(30);
      varShortField       varchar2(30);
      varEntity           varchar2(30);
      varTerminalID       varchar2(30);
      varShortDescription varchar2(15);
      varLongDescription  varchar2(50);
      varOperation        GConst.gvarOperation%Type;
      varMessage          GConst.gvarMessage%Type;
      varError            GConst.gvarError%Type;
      xmlTemp             xmlType;
      Error_Occurred      Exception;

      numCompanyCode      number;
      varTemp             varchar(50);
    Begin
      numError := 0;
      xmlTemp := xmlType(PickDetails);

      numError := 1;
      varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
      varOperation := 'Extracting Field Information for: ' || varEntity;
      select a.fldp_pick_group, a.fldp_column_name,
      b.fldp_column_name, c.fldp_column_name
      into numKeyGroup, varPickField, varShortField, varLongField
      from trsystem999 a, trsystem999 b, trsystem999 c
      where a.fldp_table_synonym = b.fldp_table_synonym
      and b.fldp_table_synonym = c.fldp_table_synonym
      and a.fldp_table_synonym = varEntity
      and a.fldp_column_name = PickField
      and b.fldp_xml_field = 'ShortDescription'
      and c.fldp_xml_field = 'LongDescription';

      numError := 2;
      varOperation := 'Extracting Parameters ' ;
      varUserID := GConst.fncXMLExtract(xmlTemp, 'UserCode', varUserID);
      varTerminalID := Gconst.fncXMLExtract(xmlTemp, 'TerminalID', varTerminalID);
      numAction := NVL(GConst.fncXMLExtract(xmlTemp, 'Action', numAction),0);

      varShortDescription := GConst.fncXMLExtract(xmlTemp, varShortField, varShortDescription);
      varLongDescription := GConst.fncXMLExtract(xmlTemp, varLongField, varLongDescription);
      numPickValue := NVL(GConst.fncXMLExtract(xmlTemp, varPickField, numPickValue),0);

      begin
       select fldp_column_name
         into vartemp
        from trsystem999
        where fldp_table_synonym=varEntity
         and fldp_xml_field='CompanyCode';

       numCompanyCode := Gconst.fncXMLExtract(xmlTemp, vartemp, numCompanyCode);
       --if num
       exception
       when others then
         numCompanyCode:=30199999;
      end;

      varMessage := 'Pick Key Value operation: ' ||  numAction || ' for Group: ' || numKeyGroup ;

      select decode(numAction,
          GConst.ADDSAVE, GConst.STATUSENTRY,
          GConst.EDITSAVE, GConst.STATUSUPDATED,
          GConst.CONFIRMSAVE, GConst.STATUSAUTHORIZED,
          GConst.DELETESAVE, GConst.STATUSDELETED)
      into numRecordStatus
      from dual;

      if numAction = GConst.ADDSAVE then
        numError := 2;
        varOperation := 'Generating the next sequence';

        select NVL(max(pick_key_number),0) + 1
        into numKeyNumber
        from PickupMaster
        where pick_key_group = numKeyGroup
        and pick_key_number < 99999;

        numError := 3;
        varOperation := 'Generating and adding pickup value';
        numPickValue := (numKeyGroup *  100000) + numKeyNumber;

        numError := 4;
        varOperation := 'Getting Key Type';

        select pick_key_type
        into numKeyType
        from PickupMaster
        where pick_key_group = numKeyGroup
        and pick_key_number = 0;

      numError := 5;
      varOperation := 'Inserting new value for Pickup' || numRecordStatus;

      insert into PickupMaster (pick_company_code, pick_key_group, pick_key_number,
        pick_key_value, pick_short_description, pick_long_description,pick_key_type,
        pick_remarks, pick_entry_detail, pick_record_status)
        values(numCompanyCode, numKeyGroup, numKeyNumber,
        numPickValue, varShortDescription, varLongDescription, numKeyType,
        'Cascaded from master entry', null, numRecordStatus);

      end if;

      if numAction = GConst.EDITSAVE then
          numError := 5;
          varOperation := 'Performing update for edit';

          update PickupMaster
          set pick_short_Description = varShortDescription,
          pick_long_description = varLongDescription,
          pick_record_status = numRecordStatus
          where pick_key_value = numPickValue;

--          numRecords := SQL%ROWCOUNT;
--
--          if numRecords <> 1 then
--            varError := 'Unable to  edit Pickup Record';
--            raise Error_Occurred;
        --  end if;

      end if;

      if numAction in (GConst.DELETESAVE, GConst.CONFIRMSAVE) then
          numError := 6;
          varOperation := 'Performing update for delete/confirm';

          update PickupMaster
          set pick_record_status = numRecordStatus
          where pick_key_value = numPickValue;

        numRecords := SQL%ROWCOUNT;

        if numRecords <> 1 then
          varError := 'Unable to Delete / confirm Pickup Record';
          raise Error_Occurred;
        end if;

      end if;

      PickValue := numPickValue;
      numError := 0;
      varError := 'Successful Operation';
      Exception
          When Error_Occurred then
            numError := -1;
            varError := GConst.fncReturnError('PickValue', numError, varMessage,
                            varOperation, varError);
            raise_application_error(-20101, varError);

          When others then
            numError := SQLCODE;
            varError := SQLERRM;
            varError := GConst.fncReturnError('PickValue', numError, varMessage,
                            varOperation, varError);
            raise_application_error(-20101, varError);
End;
Function fncIsFieldKey
    (   EntityName in varchar2,
        FieldName in varchar2)
    return number
    is
--  Created by 13/05/2007
    numError            number;
    numTemp             number;
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;

    Begin
        varMessage := 'Checking Key for ' || FieldName || ' Of ' || EntityName;
        numTemp := 0;

        varOperation := 'Extracting key details';

        select fldp_key_no
        into numTemp
        from trsystem999
        where fldp_table_synonym = EntityName
        and fldp_column_name = FieldName;

        return numTemp;

        Exception
            When others then
              numError := SQLCODE;
              varError := SQLERRM;
              varError := GConst.fncReturnError('IsKey', numError, varMessage,
                              varOperation, varError);
              raise_application_error(-20101, varError);
       return numTemp;
End fncIsFieldKey;


--Function fncCurrentAccount
--    (   RecordDetail in GConst.gClobType%Type,
--        ErrorNumber in out nocopy number)
--    return clob
--    is
----  Created on 23/09/2007
--    numError            number;
--    numTemp             number;
--    numStatus           number;
--    numSub              number(3);
--    numAction           number(4);
--    numSerial           number(5);
--    numCompany          number(8);
--    numLocation         number(8);
--    numBank             number(8);
--    numCrdr             number(8);
--    numType             number(8);
--    numHead             number(8);
--    numCurrency         number(8);
--    numVoucher          number(12);
--    numFCY              number(15,4);
--    numRate             number(15,4);
--    numINR              number(15,2);
--    varReference        varchar2(30);
--    varUserID           varchar2(30);
--    varEntity           varchar2(30);
--    varDetail           varchar2(100);
--    varTemp             varchar2(512);
--    varTemp1            varchar2(512);
--    varXPath            varchar2(512);
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    datWorkDate         date;
--    clbTemp             clob;
--    xmlTemp             xmlType;
--    nodTemp             xmlDom.domNode;
--    nmpTemp             xmldom.domNamedNodeMap;
--    nlsTemp             xmlDom.DomNodeList;
--    xlParse             xmlparser.parser;
--    nodFinal            xmlDom.domNode;
--    docFinal            xmlDom.domDocument;
--Begin
--    varMessage := 'Miscellaneous Updates';
--    dbms_lob.createTemporary (clbTemp,  TRUE);
--    clbTemp := RecordDetail;
--
--    numError := 1;
--    varOperation := 'Extracting Input Parameters';
--    xmlTemp := xmlType(RecordDetail);
--
--    varUserID := GConst.fncXMLExtract(xmlTemp, 'UserID', varUserID);
--    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
--    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
--    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
--    numCompany := GConst.fncXMLExtract(xmlTemp, 'CompanyID', numCompany);
--    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationCode', numLocation);
--
--    numError := 2;
--    varOperation := 'Creating Document for Master';
--    docFinal := xmlDom.newDomDocument(xmlTemp);
--    nodFinal := xmlDom.makeNode(docFinal);
--
--    varXPath := '//CURRENTACCOUNTMASTER/ROW';
--    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--    numSub := xmlDom.getLength(nlsTemp);
--
--    for numSub in 0..xmlDom.getLength(nlsTemp) -1
--    Loop
--      nodTemp := xmlDom.Item(nlsTemp, numSub);
--      nmpTemp:= xmlDom.getAttributes(nodTemp);
--      nodTemp := xmlDom.Item(nmpTemp, 0);
--      numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
--      varTemp := varXPath || '[@NUM="' || numTemp || '"]/';
--      varTemp1 := varTemp || 'LocalBank';
--      numBank := GConst.fncXMLExtract(xmlTemp,varTemp1,numBank,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'CrdrCode';
--      numCrdr := GConst.fncXMLExtract(xmlTemp,varTemp1,numCrdr,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'AccountHead';
--      numHead := GConst.fncXMLExtract(xmlTemp,varTemp1,numHead,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherType';
--      numType := GConst.fncXMLExtract(xmlTemp,varTemp1,numType,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'CurrencyCode';
--      numCurrency := GConst.fncXMLExtract(xmlTemp,varTemp1,numCurrency,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherReference';
--      varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'ReferenceSerial';
--      numSerial := GConst.fncXMLExtract(xmlTemp,varTemp1,numSerial,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherFcy';
--      numFcy := GConst.fncXMLExtract(xmlTemp,varTemp1,numFcy,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherRate';
--      numRate := GConst.fncXMLExtract(xmlTemp,varTemp1,numRate,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherInr';
--      numInr := GConst.fncXMLExtract(xmlTemp,varTemp1,numInr,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherDetail';
--      varDetail := GConst.fncXMLExtract(xmlTemp,varTemp1,varDetail,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'RecordStatus';
--      numStatus := GConst.fncXMLExtract(xmlTemp,varTemp1,numStatus,Gconst.TYPENODEPATH);
--
--      varOperation := 'Processing Current Account Transaction';
--
--      if numStatus = GConst.LOTNOCHANGE then
--        NULL;
--      elsif numStatus = GConst.LOTNEW then
--        numVoucher := GConst.fncGenerateSerial(Gconst.SERIALCURRENTAC);
--        insert into tftran053 (bcac_company_code, bcac_location_code,
--        bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--	bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--	bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--	bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--        bcac_create_date, bcac_record_status)
--        values(numCompany, numLocation, numBank, numVoucher, datWorkDate,
--        numCrdr, numHead, numType, varReference, numSerial, numCurrency,
--        numFcy, numRate, numInr, varDetail, sysdate, GConst.STATUSENTRY);
--      elsif numStatus = GConst.LOTMODIFIED then
--        update tftran053
--          set bcac_voucher_fcy = numFcy,
--          bcac_voucher_rate = numRate,
--          bcac_voucher_inr = numInr,
--          bcac_record_status = GConst.STATUSUPDATED
--          where bcac_voucher_reference = varReference
--          and bcac_reference_serial = numSerial
--          and bcac_account_head = numHead;
--      else
--        select decode(numStatus,
--          GConst.LOTDELETED, GConst.STATUSDELETED,
--          GConst.LOTCONFIRMED, GConst.STATUSAUTHORIZED)
--          into numStatus
--          from dual;
--
--        update tftran053
--          set bcac_record_status = numStatus
--          where bcac_voucher_reference = varReference
--          and bcac_reference_serial = numSerial
--          and bcac_account_head = numHead;
--
--      end if;
--
--    End Loop;
--
--    return clbTemp;
--Exception
--    When others then
--      numError := SQLCODE;
--      varError := SQLERRM;
--      varError := GConst.fncReturnError('CurAccount', numError, varMessage,
--                      varOperation, varError);
--      raise_application_error(-20101, varError);
--      return clbTemp;
--End fncCurrentAccount;
--
--
--Procedure prcInsertImage
--    (UpdateType in number,
--     ClobImage  in blob  )
--is
-- numTemp number(4);
--begin
--   select max(icon_icon_id)
--     into numTemp
--     from trsystem025;
--
--   insert into trsystem025
--     values( numTemp+1 ,clobimage);
--
--end prcInsertImage;
Function fncMasterMaintenance
    (   MasterDetail in GConst.gClobType%Type,
        ErrorNumber in out nocopy number)
    return clob
    is
-- Created on 13/05/2007
    numError            number;
    numTemp             number;
    numSub              number;
    numSub1             number;
    numReturn           number;
    numKey              number(2);
    numCode             number(8);
    numCode1            number(8);
    numProcess          number(8);
    numSerialProcess    number(8);
    numAction           number(4);
    numStatus           number(2);
    numRate             number(15,6);
    varProcessYN        varchar2(8);
    varFlag             varchar2(1);
    varDeal             varchar2(30);
    varStatus           varchar2(30);
    varUserID           varchar2(30);
    varEntity           varchar2(30);
    varNode             varchar2(30);
    VarReference        varchar(50);
    
    --VarTemp             varchar(50);
    VarTemp1            varchar(50);
      
    varXPath            varchar2(2048);
    varTemp             varchar2(2048);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    datTemp             date;
    datToday            date;
    clbTemp             clob;
    insCtx              dbms_xmlsave.ctxType;
    updCtx              dbms_xmlsave.ctxType;
    xmlTemp             xmlType;
    nlsTemp             xmlDom.domNodeList;
    nlsTemp1            xmlDom.domNodeList;
    nmpTemp             xmldom.domNamedNodeMap;
    nodTemp             xmlDom.domNode;
    nodTemp1            xmlDom.domNode;
    nodFinal            xmlDom.domNode;
    docFinal            xmlDom.domDocument;
    docTemp             xmlDom.domDocument;
    docOld              xmlDom.domDocument;
    raiseerrorexp       exception;
    BEGIN
--insert into rtemp(TT,TT4) values ('Inside fncMasterMaintenance 0',xmlType(MasterDetail));commit;
        varMessage := 'Master Maintenance';
        dbms_lob.createTemporary (clbTemp,  TRUE);
        varFlag := 'N';
        varDeal := '';

        numError := 1;
        varOperation := 'Extracting Input Parameters';
        xmlTemp := xmlType(MasterDetail);
        varUserID := GConst.fncXMLExtract(xmlTemp, 'UserCode', varUserID);
        varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
        numAction := NVL(to_number(GConst.fncXMLExtract(xmlTemp, 'Action', numAction)),0);
        datToday := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datToday);

        numError := 2;
        varOperation := 'Extracting Field information';
        select fldp_column_name
          into varStatus
          from trsystem999
          where fldp_table_synonym = varEntity
          and fldp_xml_field = 'RecordStatus';


        if numAction = GConst.EDITSAVE then
          varOperation := 'Checking process plan for updates';
          begin
              select NVL(fldp_edit_action,0)
              into numSerialProcess
              from trsystem999
              where fldp_table_synonym = varEntity
              and fldp_xml_field = 'SerialNumber';

              Exception
              When no_data_found then
              numSerialProcess := 0;
          End;
        End if;

        varMessage := 'Maintenace of: ' || varEntity || ', Action: ' || numAction;
        numError := 3;
        varOperation := 'Creating Document for Master';
        docFinal := xmlDom.newDomDocument(xmlTemp);
        nodFinal := xmlDom.makeNode(docFinal);

        numError := 4;
        varOperation := 'Processing Master Rows';
        varXPath := '//' || varEntity || '/ROW[@NUM]';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
       
        for numSub in 0..xmlDom.getLength(nlsTemp) -1

        Loop
          nodTemp := xmlDom.item(nlsTemp, numSub);
          nmpTemp := xmlDom.getAttributes(nodTemp);
          nodTemp1 := xmlDom.item(nmpTemp, 0);
          numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
          varXPath := '//' || varEntity || '/ROW[@NUM="' || numTemp || '"]';

          varOperation := 'Getting Status for processing';

--          if numAction  = GConst.ADDSAVE then
--            numStatus := GConst.LOTNEW;
--          else
--            varTemp := varXPath || '/' || varStatus;
--            numStatus := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--          end if;
         begin 
            varTemp := varXPath || '/' || varStatus;
            numStatus := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          exception 
            when others then
                if numAction  = GConst.ADDSAVE then
                   numStatus := GConst.LOTNEW;
                end if;
            end;
            
          select decode(numStatus,
            GConst.LOTNOCHANGE, 0,
            GConst.LOTNEW, GConst.ADDSAVE,
            GConst.LOTMODIFIED, GConst.EDITSAVE,
            GConst.LOTDELETED, GConst.DELETESAVE,
            GConst.LOTCONFIRMED, GConst.CONFIRMSAVE)
            into numAction
            from dual;


          numError := 5;
          varOperation := 'Preparing context for Edit';
          insCtx := dbms_xmlsave.newContext(varEntity);
          dbms_xmlsave.clearUpdateColumnList(insCtx);

 -- Changed
        if numStatus = GConst.LOTMODIFIED
                  and numSerialProcess = GConst.SYSADDSERIAL then
          numError := 6;

          varOperation := 'Marking old record for deletion';
          docOld := GConst.fncWriteTree('MasterEntity', varXPath, docFinal);
          updCtx := dbms_xmlsave.newContext(varEntity);
          dbms_xmlSave.clearUpdateColumnList(updCtx);
        end if;

        nlsTemp1 := xmlDom.getChildNodes(nodTemp);

---------------------------Check for status and then process
        numError := 6;
        varOperation := 'Processing Nodes';
        for numSub1 in 0..xmlDom.getLength(nlsTemp1) -1
        Loop
          nodTemp := xmlDom.item(nlsTemp1, numSub1);
          varNode := xmlDom.getNodeName(nodTemp);

--        if  substr(varNode,6) = 'SERIAL_NUMBER' then
--          varSerial := varNode;
--        end if;

          numError := 7;
          varOperation := 'Checking Field attributes :: ' || varNode ;
          select NVL(fldp_key_no, 0),
              NVL(decode(numAction,
              GConst.ADDSAVE, fldp_add_action,
              GConst.EDITSAVE, fldp_edit_action,
              GConst.DELETESAVE, fldp_delete_action,
              GConst.CONFIRMSAVE, fldp_confirm_action),0) as action_type,
              fldp_process_yn
          into numKey, numProcess, varProcessYN
          from trsystem999
          where fldp_table_synonym = varEntity
          and fldp_column_name = varNode;
          --insert into temp values (varNode || ' ' || numkey ,numProcess || varProcessYN);commit;
 ---Modified By Manjunath Reddy 20-jun-2011 To Take care of Options Muitiple Deals Update
         if ((varNode = 'COPT_SERIAL_NUMBER') and (numAction=GConst.EDITSAVE)) then
            numKey:=3;
            numProcess:=0;
            varProcessYN:='Y';
         end if;
  ------------ Code modified on 17/07/2007  to take care all types of updates
  --  For new records all columns are updated
          if numStatus = GConst.LOTNEW then
            dbms_xmlsave.setUpdateColumn(insCtx, varNode);
          elsif numStatus = GConst.LOTMODIFIED then
  --  If records are for modification
            if numSerialProcess = GConst.SYSADDSERIAL then
  --  if new records are added for updation, update all columns
              dbms_xmlsave.setUpdateColumn(insCtx, varNode);
  --  update key columns for old record

              if numKey > 0 then
                dbms_xmlsave.setKeyColumn(updCtx, varNode);

              End if;
  --  For reords where existing records are updated
            elsif numKey > 0 then
              dbms_xmlsave.setKeyColumn(insCtx, varNode);
            else
              dbms_xmlsave.setUpdateColumn(insCtx, varNode);
            end if;
  --  For actions other than add and modify
          elsif numKey > 0 then
            dbms_xmlsave.setKeyColumn(insCtx, varNode);
  --  For options other than add and edit only related columns are updated
          elsif numProcess <> 0 then
           dbms_xmlsave.setUpdateColumn(insCtx, varNode);
          end if;

  --  Only if there is a process to be performed, the function is called
          if numProcess <> 0 then
--  The second record of deal (in swap etc) should not generate a new
--  number - Change made by TMM on 12/03/08
              if varNode = 'DEAL_DEAL_NUMBER' and varFlag = 'Y' then
                numError := GConst.fncSetNodeValue(nodFinal, nodTemp, varDeal);
              elsif varNode = 'COPT_DEAL_NUMBER' and varFlag = 'Y' then
                numError := GConst.fncSetNodeValue(nodFinal, nodTemp, varDeal);
              else
                --numReturn := GConst.fncProcessNode(nodFinal, nodTemp, numAction);
                 numReturn := GConst.fncProcessNode(nodFinal, nodTemp, numAction, numTemp);
                 --insert into temp values (varNode,numReturn); commit;
              end if;
          end if;
          varOperation := 'Checking Deal Entry';
          if ((varNode = 'DEAL_DEAL_NUMBER') or (varNode = 'COPT_DEAL_NUMBER')) then
           nodTemp1 := xmldom.getFirstChild(nodTemp);
           varDeal := xmldom.getNodeValue(nodTemp1);
           varFlag := 'Y';
          end if;

      End Loop;


      docFinal := xmlDom.makeDocument(nodFinal);
      dbms_lob.createTemporary (clbTemp,  TRUE);
      docTemp := GConst.fncWriteTree('MasterEntity', varXPath, docFinal);
      xmlDom.writeToClob(docTemp, clbTemp);
      dbms_xmlsave.setDateFormat(insctx, 'dd/MM/yyyy');
      dbms_xmlsave.setRowTag(insctx, 'ROW');


      numError := 7;
      varOperation := 'Processing Master record ' || insCtx || numTemp ||varXPath;
--      xmlDom.writeToFile(docFinal, 'XMLDIR1\upd.xml');
 --change here

     -- delete from temp ;
    --  insert into temp values (insCtx,clbtemp); commit;

      if numStatus = GConst.LOTNEW
          or (numStatus = GConst.LOTMODIFIED
          and numSerialProcess = GConst.SYSADDSERIAL ) then
        numTemp := dbms_xmlSave.insertXML(insCtx, clbTemp);
      else
        numTemp := dbms_xmlSave.updateXML(insCtx, clbTemp);
      end if;
---------------------------Check for status and then process
      varOperation := 'Check for status and then process';
      if numStatus = GConst.LOTMODIFIED
          and numSerialProcess = GConst.SYSADDSERIAL then

          numError := 8;
          varOperation := 'Updating old record to inactive status';
          nodTemp := xmlDom.makeNode(docOld);
          dbms_xmlsave.setUpdateColumn(updCtx, varStatus);
          varTemp := '//' || varStatus;
          nodTemp1 := xslProcessor.selectSingleNode(nodTemp, varTemp);

          numError := 9;
          varOperation := 'Setting value to record staus';
          numTemp := GConst.fncsetNodeValue(nodFinal, nodTemp1,
                        to_char(GConst.STATUSINACTIVE));
  --        xmlDom.writeToFile(docOld, 'XMLDIR\upd.xml');
          dbms_lob.createTemporary (clbTemp,  TRUE);
          xmlDom.writeToClob(docOld, clbTemp);
          dbms_xmlsave.setDateFormat(updCtx, 'dd/MM/yyyy');

          numError := 10;
          varOperation := 'Updating old record';
          numTemp := dbms_xmlSave.updateXML(updCtx, clbTemp);


      end if;

    End Loop;

    dbms_lob.createTemporary (clbTemp,  TRUE);
    xmlDom.writeToClob(docFinal, clbTemp);
--xmlDom.writeToFile(docFinal, 'XMLDIR1\upd.xml');

--Added on 09/03/08 to take care of miscellaneous updates after master processing

 ---kumar.h 12/05/09  updates for Fixed Deposit--------
   if varEntity = 'BUYERSCREDIT' then
      clbTemp := fncMiscellaneousUpdates(clbTemp,GConst.SYSBCRFDLIEN ,numError);
   elsif varEntity ='RELATIONTABLE'then
      clbTemp := fncMiscellaneousUpdates(clbTemp,GConst.SYSRELATION ,numError);
   elsif ((varEntity ='OPTIONTRADEEXERCISE') or (varEntity ='OPTIONHEDGEEXERCISE' )) then
      varOperation := 'Effecting Cancelation  Options Deal ';
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  GConst.SYSOPTIONCANCELDEAL, numError);
      --Clbtemp := Pkgmastermaintenance.Fnccurrentaccount(Clbtemp, Numerror);
      -- Numerror:=Pkgfixeddepositproject.Fncgeneratemaildetails1(Clbtemp ) ;
                  -- added by sivadas on 11apr2012 --
    elsif ((varEntity ='OPTIONHEDGEDEAL') or (varEntity ='OPTIONHEDGEDEAL' )) then
      varOperation := 'Effecting Cancelation  Options Deal ';
     -- Clbtemp := Pkgmastermaintenance.Fnccurrentaccount(Clbtemp, Numerror);
      -- numerror:=pkgfixeddepositproject.fncgeneratemaildetails1(clbTemp ) ;
    Elsif  (Varentity ='HEDGEDEALREGISTER') Then
        --clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
        
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  GConst.SYSDEALADJUST, numError);
                  
        --Numerror:=Pkgfixeddepositproject.Fncgeneratemaildetails1(Clbtemp ) ;
   elsif varEntity ='ORDINVLINKING'then
       varOperation := 'Effecting Order Invoice Linking';
        --dbms_lob.CreateTemporary(clbTemp, True);
        --xmlDom.writeToClob(DocFinal, clbTemp);
        clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                GConst.SYSUPDATEORDINVLINK, numError);
   elsif (varEntity ='CURRENCYFUTUREDEALCANCEL' or varEntity ='' or varEntity= 'CURRENCYFUTURETRADDEALCANCEL') then
      varOperation := 'Reversal OF Future Deals';
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                   GConst.SYSFUTUREREVERSAL, numError);
    elsif varEntity = 'AANDLPOSITION' then
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        GConst.SYSAANDLPOSITION, numError);
    elsif varEntity = 'SVCFUTUREMTMRATE' then
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        GConst.SYSFUTUREMTMUPLOAD, numError);
    elsif varEntity in ('STRESSTESTSENSITIVE') then
      Clbtemp := Pkgmastermaintenance.Fncmiscellaneousupdates(Clbtemp,
        Gconst.Sysstressinsertsub, Numerror);
    elsif varEntity = 'FOREIGNREMITTANCE' then
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        GConst.SYSCASHDEAL, numError);
    elsif varEntity = 'DAILYRATETABLENEW' then
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        GConst.SYSRATEUPLOAD, numError);        
    elsif varEntity = 'CONTRACTBUCKETING' then
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        GConst.SYSCONTRACTSHCEDULE, numError);
    elsif varEntity = 'TDSPLAN' then
       clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        GConst.SYSTDSRATE, numError);
    elsif varEntity = 'FDINTERESTRATE' then
       clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        GConst.SYSFDRATE, numError);
    elsif varEntity ='CONTRACTSCHEDULEUPLOAD' then
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        GConst.SYSCONTRACTUPLOAD, numError);
    elsif varEntity = 'MARKETDEAL' then
      varOperation := 'Update the Currenct Account Details';
      clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
     -- numerror:=pkgfixeddepositproject.fncgeneratemaildetails(clbTemp ) ;
    elsif varEntity = 'MARKETDEALCONFIRMATION' then
      varOperation := 'Update the Currenct Account Details';
      clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
       --numerror:=pkgfixeddepositproject.fncgeneratemaildetails(clbTemp ) ;
    elsif varEntity = 'DEALREDEMPTION' then
        varOperation := 'Update the Currenct Account Details';
        clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
        --numerror:=pkgfixeddepositproject.fncgeneratemaildetails(clbTemp ) ;
    elsif varEntity = 'DEALREDEMPTIONCONFIRMATION' then
      varOperation := 'Update the Currenct Account Details';
      clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
       --numerror:=pkgfixeddepositproject.fncgeneratemaildetails(clbTemp ) ;
    elsif varEntity = 'CURRENCYFUTUREPRODUCT' then
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,GConst.SYSPRODUCTMATURITY, numError);
   elsif varEntity = 'BONDDEBENTUREPURCHASE' then
      varOperation := 'Update the Currenct Account Details';
      clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
      --numerror:=pkgfixeddepositproject.fncgeneratemaildetails(clbTemp ) ;
   elsif varEntity = 'BONDDEBENTUREREDEMPTION' then
      varOperation := 'Update the Currenct Account Details';
      clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
       varOperation := 'Update the Pre Closure Details';
       clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,GConst.UTILBONDCLOSE, numError);
       
   elsif varEntity = 'EXPOSURESETTLEMENTNEW' then
--      varOperation := 'Update the Currenct Account Details';
--      clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
       varOperation := 'Exposure settlement entry';
       clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,GConst.SYSEXPOSURESETTLEMENT, numError);       
      
      --numerror:=pkgfixeddepositproject.fncgeneratemaildetails(clbTemp ) ;  
    elsif varEntity = 'EXPOSURESETTLEMENTADD' then
--      varOperation := 'Update the Currenct Account Details';
--      clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
       Varoperation := 'Exposure settlement entry';
       clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,GConst.SYSEXPOSURESETTLEMENT, numError); 
    elsif varEntity ='MUTUALFUNDCLOSURE' then  --  curProcess.action_type = GConst.SYSMUTUALCOMPLETESTATUS then --Added by Sivadas on 18DEC2011
      varOperation := 'Check the process complete stage and update';
     -- VarReference := GConst.fncXMLExtract(xmltype(clbTemp),'MFCL_REFERENCE_NUMBER',VarReference);
     -- numError := pkgMasterMaintenance.fncCompleteUtilization(VarReference,GConst.UTILMUTUALFUND,datToday,1);
       if  numAction = GConst.EDITSAVE then
           VarReference := GConst.fncXMLExtract(xmltype(clbTemp),'MFCL_REFERENCE_NUMBER',VarReference);
           select NVL(COUNT(*),0) into numerror from trtran049A
            where REDM_REDEMPTION_REFERENCE=VarReference AND REDM_RECORD_STATUS NOT IN (10200005,10200006);
          if numerror >0 then
              varError := 'Mutual Fund Redemption Process has already been initiated';
              raise raiseerrorexp;
          end if;
       end if;
       
      if numAction != GConst.ADDSAVE then
      
        
        clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
        clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp, GConst.SYSMUTUALSWITCHIN, numError);
        --numerror:=pkgfixeddepositproject.fncgeneratemaildetails(clbTemp ) ;
      else
         clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp, GConst.SYSMUTUALSWITCHIN, numError);
      End if;
    elsif VarEntity ='MUTUALFUNDTRANSACTION' then
      varOperation := 'Update mutual Transaction Fund Details';
      clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
      --numerror:=pkgfixeddepositproject.fncgeneratemaildetails(clbTemp ) ;
    elsif VarEntity ='USERMASTER' then
      varOperation := 'Update Company Access detail at User Creation';
     clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                        GConst.UTILUSERUPDATE, numError);      

--   Elsif ((Varentity ='DEALCONFIRMCANCELATION') Or (Varentity ='FORWARDDEALCANCELFOREDIT') Or
--         (VarEntity ='HEDGEDEALCANCELLATION') or (VarEntity ='TRADEDEALCANCELLATION')) then
--        clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
    Elsif ((Varentity ='DEALCONFIRMCANCELATION') Or (Varentity ='FORWARDDEALCANCELFOREDIT') Or
         (VarEntity ='TRADEDEALCANCELLATION')) then
        clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
--    Elsif  (Varentity ='HEDGEDEALCANCELLATION') Then
     --   clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
        --numerror:=pkgfixeddepositproject.fncgeneratemaildetails1(clbTemp ) ;
  --  Elsif  (Varentity ='HEDGEDEALREGISTER') Then
    --    clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);        
    elsif ((VarEntity ='CCIRSSETTLEMENT')) then
        clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
   Elsif ((Varentity ='IRSSETTLEMENT')) Then
        Clbtemp := Pkgmastermaintenance.Fnccurrentaccount(Clbtemp, Numerror);
        numError := pkgMasterMaintenance.forwardSettlement(clbTemp);
    elsif varEntity ='FIXEDDEPOSITFILE' then
      varOperation := 'Update the Currenct Account Details';
      clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
      varOperation := 'Update the Pre Closure Details';
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        GConst.UTILFDPRECLOSE, numError);
       --numerror:=pkgfixeddepositproject.fncgeneratemaildetails(clbTemp ) ;
   
   
    elsif varEntity ='FIXEDDEPOSITFILECONFIRM' then
      varOperation := 'Update the Currenct Account Details';
      clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
      --numerror:=pkgfixeddepositproject.fncgeneratemaildetails(clbTemp ) ;

    elsif varEntity ='FDCLOSURECONFIRM' then
       varOperation := 'Update the Currenct Account Details';
       clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
       varOperation := 'Update the Interest and TDS Details';
        clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        GConst.UTILFIXEDDEPOSIT, numError);
       -- numerror:=pkgfixeddepositproject.fncgeneratemaildetails(clbTemp ) ;

    elsif varEntity ='MUTUALFUNDCLOSURECONFIRM' then
        varOperation := 'Update the Currenct Account Details';
        clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
        clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp, GConst.SYSMUTUALSWITCHIN, numError); ---added by prasanta
        --numerror:=pkgfixeddepositproject.fncgeneratemaildetails(clbTemp ) ;

    elsif varEntity ='MUTUALFUNDTRANSACTIONCONFIRM' then
        varOperation := 'Update the Currenct Account Details';
        clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
        --numerror:=pkgfixeddepositproject.fncgeneratemaildetails(clbTemp ) ;

    elsif varEntity ='FDCLOSURE' then  --  curProcess.action_type = GConst.SYSMUTUALCOMPLETESTATUS then --Added by Sivadas on 18DEC2011
      varOperation := 'Check the process complete stage and update';
      VarReference := GConst.fncXMLExtract(xmltype(clbTemp),'FDCL_FD_NUMBER',VarReference);
      numtemp:=GConst.fncXMLExtract(xmltype(clbTemp),'FDCL_SR_NUMBER',numtemp);
      ----Ishwarachandra--
      dattemp:=GConst.fncXMLExtract(XMLTYPE(clbTemp),'FDCL_CLOSURE_DATE',dattemp);
      if numaction <> gconst.DELETESAVE then
        select fdrf_process_complete into numerror from trtran047 
          where fdrf_fd_number=VarReference and fdrf_sr_number=numtemp;
        if numerror =12400001 then
            varError := 'FD Closing process has already been initiated';
            raise raiseerrorexp;
        END IF;
     end if;
      numError := pkgMasterMaintenance.fncCompleteUtilization(VarReference,GConst.UTILFIXEDDEPOSIT,dattemp,numtemp);
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        GConst.UTILFIXEDDEPOSIT, numError);
      clbTemp := pkgMasterMaintenance.fncCurrentAccount(clbTemp, numError);
   
      --numerror:=pkgfixeddepositproject.fncgeneratemaildetails(clbTemp ) ;
      
    elsif varEntity ='IMPORTTRADEREGISTER' then 
       Clbtemp := Pkgmastermaintenance.Fncmiscellaneousupdates(Clbtemp, Gconst.Syspurconcancel, Numerror);  
--    Elsif Varentity='HEDGEDEALREGISTER' Then
--           numerror:=pkgfixeddepositproject.fncgeneratemaildetails1(clbTemp) ;
  --  elsif varEntity ='IMPORTTRADEREGISTERDETAIL1' then 
     --  numerror:=pkgfixeddepositproject.fncgeneratemaildetails1(clbTemp) ;
--    elsif varEntity ='IMPORTTRADEREGISTERDETAIL' then 
--       --numerror:=pkgfixeddepositproject.fncgeneratemaildetails1(clbTemp) ;       
    elsif varEntity ='HEDGEREGISTER' then 
       clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp, GConst.SYSHEDGELINKINGCANCEL, numError);    
    elsif varEntity ='TERMLOAN' then  --  curProcess.action_type = GConst.SYSMUTUALCOMPLETESTATUS then --Added by Sivadas on 18DEC2011
      varOperation := 'Update Term loan Principal and Interest table';
      --VarReference := GConst.fncXMLExtract(xmltype(clbTemp),'FDCL_FD_NUMBER',VarReference);
      --numError := pkgMasterMaintenance.fncCompleteUtilization(VarReference,GConst.UTILFIXEDDEPOSIT,datToday,1);
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        GConst.SYSTERMLOAN, numError);
    ELSIF VARENTITY = 'DUMMYFILE' THEN
        CLBTEMP := pkgMasterMaintenance.fncMiscellaneousUpdates(CLBTEMP,
        GConst.SYSUSERUPDATE, numError);
--    ELSIF VARENTITY = 'COMPANYMASTER' THEN
--        clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
--        GConst.SYSCOMPANYUPDATE, numError);
   elsif varEntity ='IRS' then  --  curProcess.action_type = GConst.SYSMUTUALCOMPLETESTATUS then --Added by Sivadas on 18DEC2011
      varOperation := 'Populate the IRS details';
      --VarReference := GConst.fncXMLExtract(xmltype(clbTemp),'FDCL_FD_NUMBER',VarReference);
      --numError := pkgMasterMaintenance.fncCompleteUtilization(VarReference,GConst.UTILFIXEDDEPOSIT,datToday,1);
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        GConst.SYSIRSPOPULATE, numError);
   elsif varEntity ='CCIRSWAP' then  --  curProcess.action_type = GConst.SYSMUTUALCOMPLETESTATUS then --Added by Sivadas on 18DEC2011
      varOperation := 'Populate the CC IRS details';
      --VarReference := GConst.fncXMLExtract(xmltype(clbTemp),'FDCL_FD_NUMBER',VarReference);
      --numError := pkgMasterMaintenance.fncCompleteUtilization(VarReference,GConst.UTILFIXEDDEPOSIT,datToday,1);
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        Gconst.Sysccirspopulate, Numerror);        
   elsif varEntity = 'CCIRSSETTLEMENT' THEN
      varOperation := 'Passing another entry in CCIRSSettlement';
--      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
--        GConst.SYSCCIRSSETTLE, numError);   
   elsif varEntity ='IRO' then  --  curProcess.action_type = GConst.SYSMUTUALCOMPLETESTATUS then --Added by Sivadas on 18DEC2011
      varOperation := 'Populate the IRS details';
      --VarReference := GConst.fncXMLExtract(xmltype(clbTemp),'FDCL_FD_NUMBER',VarReference);
      --numError := pkgMasterMaintenance.fncCompleteUtilization(VarReference,GConst.UTILFIXEDDEPOSIT,datToday,1);
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        GConst.SYSIROPOPULATE, numError);  
     elsif varEntity ='HEDGECOMMODITYDEAL' then  --  curProcess.action_type = GConst.SYSMUTUALCOMPLETESTATUS then --Added by Sivadas on 18DEC2011
      varOperation := 'Populate the Hedge Commodity details';
      clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
        GConst.SYSCOMHEDGELINKING, numError);    
     elsif varEntity='FUTURESDATA' then
       varOperation := 'Deleting Futures deals';
       clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
       GConst.SYSDELETEFUTUREDATA, numError);   
     elsif varEntity = 'BANKCHARGEMASTERNEW' then 
        varOperation := 'Deleting Futures deals';
        clbTemp := fncMiscellaneousUpdates(clbTemp, GConst.SYSBANKCHARGEINSERT, numError);  
    elsif varEntity = 'FORWARDROLLOVER' then 
        varOperation := 'Save, Confirm and Delete forward rollover';
        clbTemp := fncMiscellaneousUpdates(clbTemp, GConst.SYSFORWARDROLLOVERPROCESS, numError);  
     elsif varEntity = 'EXCHANGERATE' then 
        varOperation := 'Inserting RBI reference rate';
        clbTemp := fncMiscellaneousUpdates(clbTemp, GConst.SYSRBIREFRATE, numError);          
    end if;        

 --   end if;
  
     For curProcess in
      (select NVL(fldp_key_no, 0),
          NVL(decode(numAction,
          GConst.ADDSAVE, fldp_add_action,
          GConst.EDITSAVE, fldp_edit_action,
          GConst.DELETESAVE, fldp_delete_action,
          GConst.CONFIRMSAVE, fldp_confirm_action),0) as action_type,
          fldp_process_yn
          from trsystem999
          where fldp_table_synonym = varEntity
          and fldp_data_type!='BLOB')
      Loop



        if curProcess.action_type = GConst.SYSRISKGENERATE then
          varOperation := 'Generating Risk violations';
          --numerror := pkgForexProcess.fncRiskPopulate(datToday, GConst.TRADEDEAL);
          numError := pkgForexProcess.fncRiskGenerate(datToday, GConst.TRADEDEAL);
        elsif curProcess.action_type = GConst.SYSHEDGERISK then
          varOperation := 'Generating Hedge Risk violations';
          --numError := pkgForexProcess.fncHedgeRisk(datToday);
        elsif curProcess.action_type = GConst.SYSVOUCHERCA then
          varOperation := 'Inserting Current Account vouchers';
          dbms_lob.createTemporary (clbTemp,  TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          numError := fncCurrentAccount(clbTemp);
        elsif curProcess.action_type = GConst.SYSRATECALCULATE then
          varOperation := 'Calculating Rates';
          dbms_lob.createTemporary (clbTemp,  TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          numError := pkgForexProcess.fncCalculateRate(clbTemp);
          numtemp:=0;
          begin
            varOperation := 'Getting the Count of the  Rates' || numtemp ;
           select count(*)
             into numtemp
             from trtran012
             where drat_effective_date=datToday
             and drat_serial_number= (select max(drat_serial_number)
                      from trtran012 where drat_effective_date=datToday);
           exception
           when others then
            numtemp :=0;
          end;
           if (numtemp=16) then
              varOperation := 'Getting the Count of the  Rates Temp' || numtemp || datToday;
              numError := pkgForexProcess.fncRiskGenerate(datToday, GConst.TRADEDEAL);
           end if;
          --numError := pkgForexProcess.fncRiskGenerate(datToday, GConst.TRADEDEAL);
          --numError := pkgForexProcess.fncHedgeRisk(datToday);
        elsif curProcess.action_type = GConst.SYSRATECALCULATE1 then
          varOperation := 'Calculating Rates for Windows Services';
          datTemp := GConst.fncXMLExtract(xmlTemp, 'ROW[@NUM="1"]/RATE_EFFECTIVE_DATE', datTemp);
          numSub1 := GConst.fncXMLExtract(xmlTemp, 'ROW[@NUM="1"]/RATE_SERIAL_NUMBER', numSub1);
           numError := pkgForexProcess.fncCalculateRate(datTemp,
            30400004, 30400003, numSub1);
          for CurRates in
          (select rate_effective_date, rate_currency_code, rate_for_currency,
            rate_serial_number
            from trsystem009 a
            where rate_effective_date = datTemp
            and rate_serial_number = numSub1
            and not exists
            (select 'x'
              from trsystem009 b
              where b.rate_currency_code = a.rate_currency_code
              and b.rate_for_currency = a.rate_for_currency
              and b.rate_effective_date = a.rate_effective_date
              and b.rate_serial_number = a.rate_serial_number
              and rate_currency_code = 30400004 and rate_for_currency = 30400003))
          Loop
          numError := pkgForexProcess.fncCalculateRate(datTemp,
            CurRates.rate_currency_code, curRates.rate_for_currency, numSub1);
          End Loop;

          --dbms_snapshot.refresh('mvewLatestRates');
         -- numError := pkgForexProcess.fncRiskGenerate(datToday, GConst.TRADEDEAL);

        elsif curProcess.action_type = GConst.SYSLOANCONNECT then
          varOperation := 'Connecting Import/Export to Loans';
          dbms_lob.createTemporary (clbTemp,  TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  GConst.SYSLOANCONNECT, numError);

       --added by kumar.h 12/05/09 for buyers credit
        elsif curProcess.action_type = GConst.SYSBCRCONNECT then
          varOperation := 'Connecting Import/Export to Loans';
          dbms_lob.createTemporary (clbTemp,  TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  GConst.SYSBCRCONNECT, numError);
        --added by kumar.h 12/05/09 for IMPORTORDER and EXPORT ORDER
       elsif curProcess.action_type = GConst.SYSPURCONNECT then
          varOperation := 'Moving Purchase Order details';
          dbms_lob.createTemporary (clbTemp,  TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  GConst.SYSPURCONNECT, numError);

        --added by kumar.h 12/05/09 for buyers credit

        elsif curProcess.action_type = GConst.SYSEXPORTADJUST then
          varOperation := 'Effecting Export Adjustment';
          dbms_lob.createTemporary (clbTemp,  TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  GConst.SYSEXPORTADJUST, numError);
        elsif curProcess.action_type = GConst.SYSDEALDELIVERY then
          varOperation := 'Effecting Deal Delivery';
          dbms_lob.createTemporary (clbTemp,  TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  GConst.SYSDEALDELIVERY, numError);
--        elsif curProcess.action_type = GConst.SYSDEALADJUST then
--          varOperation := 'Effecting Deal Adjustment';
--          dbms_lob.CreateTemporary(clbTemp, TRUE);
--          xmlDom.writeToClob(DocFinal, clbTemp);
--          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
--                  GConst.SYSDEALADJUST, numError);

        elsif curProcess.action_type = GConst.SYSCOMMDEALREVERSAL then
          varOperation := 'Effecting Commodity Deal Reversal';
          dbms_lob.CreateTemporary(clbTemp, TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  GConst.SYSCOMMDEALREVERSAL, numError);

        elsif curProcess.action_type = GConst.SYSHOLDINGRATE then
          varOperation := 'Generating Holding Rate for deals';
          varXPath := '//' || varEntity || '/ROW[@NUM="1"]/';

          if varEntity = 'TRADEDEALREGISTER' then
            numCode := to_number(GConst.fncGetNodeValue(nodFinal, varXPath || 'DEAL_BASE_CURRENCY'));
            Dattemp := To_Date(Gconst.Fncgetnodevalue(Nodfinal, Varxpath || 'DEAL_EXECUTE_DATE'), 'dd/mm/yyyy');
            --numRate := pkgForexProcess.fncHoldingRate(numCode, datTemp, numError);
            --numRate := pkgForexProcess.fncHoldingRate(numCode, datTemp, numError, varUserID);
            numCode := to_number(GConst.fncGetNodeValue(nodFinal, varXPath || 'DEAL_OTHER_CURRENCY'));
--            if numCode != GConst.INDIANRUPEE then
--              numRate := pkgForexProcess.fncHoldingRate(numCode, datTemp, numError);
--              numRate := pkgForexProcess.fncHoldingRate(numCode, datTemp, numError, varUserID);
--            end if;

          elsif varEntity = 'TRADEDEALCANCELLATION' then
            varDeal := GConst.fncGetNodeValue(nodFinal, varXPath || 'CDEL_DEAL_NUMBER');
            numSub :=  to_number(GConst.fncGetNodeValue(nodFinal, varXPath || 'CDEL_DEAL_SERIAL'));
            datTemp := to_date(GConst.fncGetNodeValue(nodFinal, varXPath || 'CDEL_CANCEL_DATE'), 'dd/mm/yyyy');

--            varOperation := 'Getting Deal Details';
--            select deal_base_currency, deal_other_currency
--              into numCode, numCode1
--              from trtran001
--              where deal_deal_number = varDeal
--              and deal_serial_number = numSub;
           -- numRate := pkgForexProcess.fncHoldingRate(numCode, datTemp, numError);
            --numRate := pkgForexProcess.fncHoldingRate(numCode, datTemp, numError, varUserID);

--            if numCode1 != GConst.INDIANRUPEE then
--              numRate := pkgForexProcess.fncHoldingRate(numCode1, datTemp, numError);
--              numRate := pkgForexProcess.fncHoldingRate(numCode1, datTemp, numError, varUserID);
--            end if;

          End if;

          varTemp := numRate;

        elsif curProcess.action_type = GConst.SYSCANCELDEAL then
          varOperation := 'Effecting Deal Cancellation';
          dbms_lob.CreateTemporary(clbTemp, TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  GConst.SYSCANCELDEAL, numError);

--------------Currency Future Manjunath Reddy
--       elsif curProcess.action_type = GConst.SYSFUTUREREVERSAL then
--
--
--          varOperation := 'Effecting Currency Future Deal Reversal';
--          dbms_lob.CreateTemporary(clbTemp, TRUE);
--          xmlDom.writeToClob(DocFinal, clbTemp);
--          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
--                  GConst.SYSFUTUREREVERSAL, numError);
--
--------------Currency Options Manjunath Reddy
       elsif curProcess.action_type = GConst.SYSOPTIONMATURITY then

        -- insert into Temp Values('Enter into SYSOPTIONMATURITY ','SYSOPTIONMATURITY');
          varOperation := 'Effecting Options Deal ';
          dbms_lob.CreateTemporary(clbTemp, TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  GConst.SYSOPTIONMATURITY, numError);

       elsif curProcess.action_type = GConst.SYSLINKUPDATETABLES then

        -- insert into Temp Values('Enter into SYSLINKUPDATETABLES ','SYSLINKUPDATETABLES');
          varOperation := 'Effecting Options Deal ';
          dbms_lob.CreateTemporary(clbTemp, TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  GConst.SYSLINKUPDATETABLES, numError);

       elsif curProcess.action_type = GConst.SYSUPDATEDEALNO then --Added by Sivadas on 18DEC2011
          varOperation := 'Effecting Options Deal ';
          dbms_lob.CreateTemporary(clbTemp, TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
                  GConst.SYSUPDATEDEALNO, numError);

       elsif curProcess.action_type = GConst.SYSEXCHMTMUPDATE then --Added by Sivadas on 18DEC2011
          varOperation := 'updating exchange MTM uploaded file ';
          dbms_lob.CreateTemporary(clbTemp, TRUE);
          xmlDom.writeToClob(DocFinal, clbTemp);
          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
          GConst.SYSEXCHMTMUPDATE, numError);

--          elsif curProcess.action_type = GConst.SYSCONTRACTSHCEDULE then
--          varOperation := 'Contract Schedule';
--          dbms_lob.createTemporary (clbTemp,  TRUE);
--          xmlDom.writeToClob(DocFinal, clbTemp);
--          clbTemp := pkgMasterMaintenance.fncMiscellaneousUpdates(clbTemp,
--                  GConst.SYSCONTRACTSHCEDULE, numError);
     end if;
    End Loop;

    varOperation := 'Update Reference number for the Document Attached';
    begin
       varOperation := 'Extracting Document GUID number';
       varReference := GConst.fncXMLExtract(xmlTemp, 'SCANNEDIMAGESREFERENCE', varReference);
    exception 
      when others then
        varReference:=' ';
    end;
       insert into temp values(varReference||varEntity,'ABC');
    
    varOperation := ' Document Reference number' ||varReference ;
    if (varReference !=' ') then 
      varOperation := ' Extracting Reference Number 2' ||varReference ;
      insert into temp values(varReference||varOperation,'ROW2'); COMMIT;
       select FLDP_COLUMN_NAME 
         into varTemp
       from trsystem999
        where FLDP_TABLE_SYNONYM = varEntity 
         and nvl(FLDP_KEY_NO,0) >= 1
         and FLDP_DATA_TYPE ='VARCHAR2'
         and rownum=1;
   
   BEGIN
       varOperation := ' Extracting Serial Number for '  ;      
      select FLDP_COLUMN_NAME 
         into varTemp1
       from trsystem999
        where FLDP_TABLE_SYNONYM = varEntity 
         and nvl(FLDP_KEY_NO,0) >= 1
         and FLDP_DATA_TYPE ='NUMBER'  
         and rownum=1;
         varTemp1:=  GConst.fncXMLExtract(xmlTemp, varTemp1, varReference);
         EXCEPTION
          when others then
        varTemp1:=0;
    end;
--         insert into temp values(varReference,varTemp1);
  --  commit; 
       varOperation := 'Extract Reference number for ' || varTemp   ;   
       varTemp:=  GConst.fncXMLExtract(xmlTemp,varTemp, varReference);
--       varOperation := 'Extract Reference number for ' || varTemp1   ;   
    
  --       insert into temp values(varReference,varTemp);
  --  commit; 
       varOperation := 'Update Reference number in Document Table ' || varTemp1   ;   
       update tftran101 set IMAG_DOCUMENT_REFERENCE = varTemp
         -- IMAG_DOCUMENT_SERIAL=varTemp1
        where IMAG_REFERENCE_NUMBER= varReference;
         
    end if;
    


    numError := 0;

    xmlDom.freeDocument(docOld);
    xmlDom.freeDocument(docFinal);
    xmlDom.freeDocument(docTemp);

    ErrorNumber := numError;
    return clbTemp;

    Exception
     when raiseerrorexp then
        rollback;
        ErrorNumber := numError;
      
      varError := GConst.fncReturnError('MasterMaintain', numError, varMessage,
                      varOperation, varError);
        raise_application_error(-20801,varError);
        return clbTemp;
    When others then
      numError := SQLCODE;
      ErrorNumber := numError;
      varError := SQLERRM;
      varError := GConst.fncReturnError('MasterMaintain', numError, varMessage,
                      varOperation, varError);
      raise_application_error(-20101, varError);
      return clbTemp;
End fncMasterMaintenance;

--Function fncCompleteUtilization
--    (   ReferenceNumber in varchar2,
--        ReferenceType in number,
--        WorkDate in date,
--        SerialNumber in number default 1)
--    return number
--    is
----  Created on 22/05/08
--    numError            number;
--    numCode             number(8);
--    numAmount           number(15,4);
--    numUtilization      number(15,4);
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--Begin
--    numError := 0;
--    varOperation := 'Checking Process Completion for: ' || ReferenceNumber || 'Reverse Type ' || ReferenceType ;
--    numAmount := 0;
--    numUtilization := 0;
--
--    if ReferenceType = GConst.UTILHEDGEDEAL then
--      varOperation := 'Checking Utilization';
--      select deal_base_amount, deal_hedge_trade
--        into numAmount, numCode
--        from trtran001
--        where deal_deal_number = ReferenceNumber
--         and deal_record_status in
--          (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED,GConst.STATUSAPREUTHORIZATION);
--
--      select NVL(sum(cdel_cancel_amount),0)
--        into numUtilization
--        from trtran006
--        where cdel_deal_number = ReferenceNumber
--        and cdel_record_status in
--        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED,GConst.STATUSAPREUTHORIZATION);
--
--      if numAmount = numUtilization then
--          update trtran001
--            set deal_process_complete = GConst.OPTIONYES,
--            deal_complete_date = WorkDate
--            --deal_record_status = GConst.STATUSCOMPLETED
--           --deal_record_status = GConst.STATUSPOSTCANCEL
--            where deal_deal_number = ReferenceNumber;
--
--           if numCode = GConst.HEDGEDEAL and numAmount = numUtilization then
--            update trtran004
--              set hedg_record_status = GConst.STATUSPOSTCANCEL
--              where hedg_deal_number = ReferenceNumber;
--          end if;
--      else
--          update trtran001
--            set deal_process_complete = GConst.OPTIONNO,
--            deal_complete_date = NULL
--            where deal_deal_number = ReferenceNumber;
--
----        update trtran001
----          set deal_record_status = GConst.STATUSCOMPLETED
----          where deal_deal_number = ReferenceNumber;
--      end if;
--
--    elsif ReferenceType = GConst.UTILFCYLOAN then
--      varOperation := 'Checking Utilization';
--      select fcln_sanctioned_fcy
--        into numAmount
--        from trtran005
--        where fcln_loan_number = ReferenceNumber;
--
--      select NVL(sum(trln_adjusted_fcy),0)
--        into numUtilization
--        from trtran007
--        where trln_loan_number = ReferenceNumber
--        and trln_serial_number > 0
--        and trln_record_status in
--        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);
--
--      varOperation := 'Updating process complete status for Loan';
--      if numAmount = numUtilization then
--        update trtran005
--          set fcln_process_complete = GConst.OPTIONYES,
--          fcln_complete_date = WorkDate
--          where fcln_loan_number = ReferenceNumber;
--      else
--        update trtran005
--          set fcln_process_complete = GConst.OPTIONNO,
--          fcln_complete_date = NULL
--          where fcln_loan_number = ReferenceNumber;
--
----        update trtran005
----          set fcln_record_status = GConst.STATUSCOMPLETED
----          where fcln_loan_number = ReferenceNumber;
--      end if;
--------------- FOR TOI and Newsprint TMM 26/01/14 Checking status inactive-------------------------
--    elsif ReferenceType in (GConst.UTILEXPORTS,GConst.UTILPURCHASED,GConst.UTILCOLLECTION,
--                             GConst.UTILIMPORTS,GConst.UTILIMPORTBILL) then
--      select trad_trade_fcy
--        into numAmount
--        from trtran002
--        where trad_trade_reference = ReferenceNumber
--         and trad_record_status in
--              (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED, GConst.STATUSINACTIVE);
--
--      select NVL(sum(brel_reversal_fcy),0)
--        into numUtilization
--        from trtran003
--        where brel_trade_reference = ReferenceNumber
--        and brel_record_status in
--        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED, GConst.STATUSINACTIVE);
--
--      varOperation := 'Updating process complete status';
--      if numAmount = numUtilization then
--        update trtran002
--          set trad_process_complete = GConst.OPTIONYES,
--          trad_complete_date = WorkDate
--          where trad_trade_reference = ReferenceNumber;
--      else
--        update trtran002
--          set trad_process_complete = GConst.OPTIONNO,
--          trad_complete_date = null
--          where trad_trade_reference = ReferenceNumber;
--      end if;
--
--    elsif ReferenceType in (Gconst.UTILCOMMODITYDEAL) then
--      select cmdl_lot_numbers
--        into numamount
--        from trtran051
--        where cmdl_deal_number= ReferenceNumber;
--
--      select crev_reverse_lot
--        into numUtilization
--        from trtran053
--        where crev_deal_number= ReferenceNumber
--        and crev_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
--      if numAmount = numUtilization then
--        update trtran051
--          set cmdl_process_complete=GConst.OPTIONYES,
--          cmdl_complete_date = WorkDate
--          where cmdl_deal_number=ReferenceNumber;
--      else
--        update trtran051
--          set cmdl_process_complete=GConst.OPTIONNO,
--          cmdl_complete_date = null
--          where cmdl_deal_number=ReferenceNumber;
--      end if;
--
--    elsif ReferenceType in (Gconst.UTILBCRLOAN) then
--      varOperation := 'Extracting Buyers Credit Loan Amount ';
--      select bcrd_sanctioned_fcy
--        into numAmount
--        from trtran045
--        where bcrd_buyers_credit = ReferenceNumber;
--
--       select sum(brel_reversal_fcy)
--         into numUtilization
--         from trtran003
--         where brel_trade_reference = ReferenceNumber
--         and brel_record_status in(GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED, GConst.STATUSINACTIVE);
--
--      varOperation := 'Checking for Buyers Credit Loan closure';
--      if numAmount = numUtilization then
--          update trtran045
--            set bcrd_process_complete = GConst.OPTIONYES,
--            bcrd_completion_date = WorkDate
--            where bcrd_buyers_credit = ReferenceNumber;
--      else
--          update trtran045
--            set bcrd_process_complete = GConst.OPTIONNO,
--            bcrd_completion_date = null
--            Where bcrd_buyers_credit = Referencenumber;
--       end if;
--
-- --Commented aakash 17-May-13 11:03 am
--
----    elsif ReferenceType in (Gconst.UTILOPTIONHEDGEDEAL) then
----     VarOperation :='getting otion hedge deal base amount';
----     begin
----      select copt_base_amount
----        into numamount
----        from trtran071
----        where copt_deal_number= ReferenceNumber
----        and copt_serial_number =SerialNumber;
----     exception
----     when no_data_found then
----       numamount:=0;
----     end;
----     VarOperation :='getting otion hedge deal utlization amount';
----     begin
----      select sum(corv_base_amount)
----        into numUtilization
----        from trtran073
----        where corv_deal_number= ReferenceNumber
----      --  and corv_serial_number =SerialNumber
----        and corv_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
----      exception
----      when no_data_found then
----         numUtilization:=0;
----      end;
----      if numAmount <= numUtilization then
----        update trtran071
----          set copt_process_complete=GConst.OPTIONYES,
----          copt_complete_date = WorkDate
----          where copt_deal_number=ReferenceNumber;
----
----         update trtran072  set cosu_process_complete = Gconst.OPTIONYES,
----                cosu_complete_date =workDate
----          where cosu_deal_number =ReferenceNumber;
----          --and copt_serial_number= SerialNumber;
----      else
----        update trtran071
----          set copt_process_complete=GConst.OPTIONNO,
----          copt_complete_date = null
----          where copt_deal_number=ReferenceNumber;
----
----        update trtran072  set cosu_process_complete = Gconst.OPTIONNO,
----                cosu_complete_date =null
----          where cosu_deal_number =ReferenceNumber;
----          --and copt_Serial_number= SerialNumber;
----      end if;
----end
----added by aakash/gouri 17-May-13 11:03 am
--elsif ReferenceType in (Gconst.UTILOPTIONHEDGEDEAL) then
--VarOperation :='getting option hedge deal base amount';
--     Begin
--      select copt_base_amount
--        into numamount
--        from trtran071
--        Where Copt_Deal_Number= Referencenumber
--       -- and copt_serial_number =SerialNumber;
--         and copt_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
--     exception
--     when no_data_found then
--       numamount:=0;
--     end;
--     VarOperation :='getting option hedge deal utlization amount';
--     begin
--      Select Sum(Corv_Base_Amount)
--        into numUtilization
--        from trtran073
--        where corv_deal_number= ReferenceNumber
--      --  and corv_serial_number =SerialNumber
--        and corv_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
--      exception
--      when no_data_found then
--         numUtilization:=0;
--      End;
--      if numAmount = numUtilization then
--        update trtran071
--          set copt_process_complete=GConst.OPTIONYES,
--          copt_complete_date = WorkDate
--          where copt_deal_number=ReferenceNumber;
--
--         update trtran072  set cosu_process_complete = Gconst.OPTIONYES,
--                cosu_complete_date =workDate
--          where cosu_deal_number =ReferenceNumber;
--          --and copt_serial_number= SerialNumber;
--      else
--        update trtran071
--          set copt_process_complete=GConst.OPTIONNO,
--          copt_complete_date = null
--          where copt_deal_number=ReferenceNumber;
--
--        update trtran072  set cosu_process_complete = Gconst.OPTIONNO,
--                cosu_complete_date =null
--          where cosu_deal_number =ReferenceNumber;
--          --and copt_Serial_number= SerialNumber;
--      end if;
----end
--
--    elsif ReferenceType in (Gconst.UTILFUTUREDEAL) then
--      select cfut_lot_numbers
--        into numamount
--        from trtran061
--        where cfut_deal_number= ReferenceNumber
--        and cfut_record_status not in(10200005,10200006);
--
--      select nvl(sum(cfrv_reverse_lot),0)
--        into numUtilization
--        from trtran063
--        where cfrv_deal_number= ReferenceNumber
--        and cfrv_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
--      if numAmount = numUtilization then
--        update trtran061
--          set cfut_process_complete=GConst.OPTIONYES,
--          cfut_complete_date = WorkDate
--          where cfut_deal_number=ReferenceNumber;
--      else
--        update trtran061
--          set cfut_process_complete=GConst.OPTIONNO,
--          cfut_complete_date = null
--          where cfut_deal_number=ReferenceNumber;
--      end if;
--
--
--    end if;
--
--
--    return numError;
--Exception
--    When others then
--      numError := SQLCODE;
--      varError := GConst.fncReturnError('CompleteUtil', numError, varMessage,
--                      varOperation, varError);
--      raise_application_error(-20101, varError);
--      return numError;
--End fncCompleteUtilization;


---new update by Manjunath sir as on 22042014
Function fncCompleteUtilization
    (   ReferenceNumber in varchar2,
        ReferenceType in number,
        WorkDate in date,
        SerialNumber in number default 1)
    return number
    is
--  Created on 22/05/08
    numError            number;
    numFlag             number(1);
    numCode             number(8);
    numAmount           number(15,4);
    numUtilization      number(15,4);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
Begin
    numError := 0;
    varOperation := 'Checking Process Completion for: ' || ReferenceNumber || 'Reverse Type ' || ReferenceType ;
    numAmount := 0;
    numUtilization := 0;

    if ReferenceType = GConst.UTILHEDGEDEAL then
      varOperation := 'Checking Utilization 1';
      select deal_base_amount, deal_hedge_trade
        into numAmount, numCode
        from trtran001
        where deal_deal_number = ReferenceNumber
         and deal_record_status in
          (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED,GConst.STATUSAPREUTHORIZATION);
varOperation := 'Checking Utilization 2';
      select NVL(sum(cdel_cancel_amount),0)
        into numUtilization
        from trtran006
        where cdel_deal_number = ReferenceNumber
        and cdel_record_status in
        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED,GConst.STATUSAPREUTHORIZATION);
varOperation := 'Checking Utilization 3';
      if numAmount = numUtilization then
          update trtran001
            set deal_process_complete = GConst.OPTIONYES,
            deal_complete_date = WorkDate
            --deal_record_status = GConst.STATUSCOMPLETED
           --deal_record_status = GConst.STATUSPOSTCANCEL
            where deal_deal_number = ReferenceNumber;
varOperation := 'Checking Utilization 4';
           if numCode = GConst.HEDGEDEAL and numAmount = numUtilization then
            UPDATE trtran004
              SET hedg_record_status = 10200010--GConst.STATUSDELETED
              where hedg_deal_number = ReferenceNumber;
          end if;
      else
      varOperation := 'Checking Utilization 5';
          update trtran001
            set deal_process_complete = GConst.OPTIONNO,
            deal_complete_date = NULL
            where deal_deal_number = ReferenceNumber;

--        update trtran001
--          set deal_record_status = GConst.STATUSCOMPLETED
--          where deal_deal_number = ReferenceNumber;
      end if;

    elsif ReferenceType = GConst.UTILFCYLOAN then
      varOperation := 'Checking Utilization 6';
      select fcln_sanctioned_fcy
        into numAmount
        from trtran005
        where fcln_loan_number = ReferenceNumber;

      select NVL(sum(trln_adjusted_fcy),0)
        into numUtilization
        from trtran007
        where trln_loan_number = ReferenceNumber
        and trln_serial_number > 0
        and trln_record_status in
        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED);

      varOperation := 'Updating process complete status for Loan';
      if numAmount = numUtilization then
        update trtran005
          set fcln_process_complete = GConst.OPTIONYES,
          fcln_complete_date = WorkDate
          where fcln_loan_number = ReferenceNumber;
      else
        update trtran005
          set fcln_process_complete = GConst.OPTIONNO,
          fcln_complete_date = NULL
          where fcln_loan_number = ReferenceNumber;

--        update trtran005
--          set fcln_record_status = GConst.STATUSCOMPLETED
--          where fcln_loan_number = ReferenceNumber;
      end if;
------------- FOR TOI and Newsprint TMM 26/01/14 Checking status inactive-------------------------
    elsif ReferenceType in (GConst.UTILEXPORTS,GConst.UTILPURCHASED,GConst.UTILCOLLECTION,
                             GConst.UTILIMPORTS,GConst.UTILIMPORTBILL) then
    begin
      select trad_trade_fcy
        into numAmount
        from trtran002
        where trad_trade_reference = ReferenceNumber
         and trad_record_status in
              (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED, GConst.STATUSINACTIVE);
    exception
     when no_data_found then 
        numAmount:=0;
     end ;
     
     begin
      select NVL(sum(brel_reversal_fcy),0)
        into numUtilization
        from trtran003
        where brel_trade_reference = ReferenceNumber
        and brel_record_status in
        (GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED, GConst.STATUSINACTIVE);
     exception 
       when no_Data_found then 
        numUtilization :=0;
     end ;
     
      varOperation := 'Updating process complete status';
      if numAmount = numUtilization then
        update trtran002
          set trad_process_complete = GConst.OPTIONYES,
          trad_complete_date = WorkDate
          where trad_trade_reference = ReferenceNumber;
      else
        update trtran002
          set trad_process_complete = GConst.OPTIONNO,
          trad_complete_date = null
          where trad_trade_reference = ReferenceNumber;
      end if;

    elsif ReferenceType in (Gconst.UTILCOMMODITYDEAL) then
      select cmdl_lot_numbers
        into numamount
        from trtran051
        where cmdl_deal_number= ReferenceNumber;

      select crev_reverse_lot
        into numUtilization
        from trtran053
        where crev_deal_number= ReferenceNumber
        and crev_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
      if numAmount = numUtilization then
        update trtran051
          set cmdl_process_complete=GConst.OPTIONYES,
          cmdl_complete_date = WorkDate
          where cmdl_deal_number=ReferenceNumber;
      else
        update trtran051
          set cmdl_process_complete=GConst.OPTIONNO,
          cmdl_complete_date = null
          where cmdl_deal_number=ReferenceNumber;
      end if;

    elsif ReferenceType in (Gconst.UTILBCRLOAN) then
      varOperation := 'Extracting Buyers Credit Loan Amount ';
      Begin
        numFlag := 0;
    
        select nvl(sum(bcrd_sanctioned_fcy),0)
          into numAmount
          from trtran045
          where bcrd_buyers_credit = ReferenceNumber;
      Exception
        when no_data_found then
          numFlag := 1;
        
          select nvl(sum(trad_trade_fcy),0)
            into numAmount
            from trtran002
            where trad_trade_reference = ReferenceNumber;
      End;

       select nvl(sum(brel_reversal_fcy),0)
         into numUtilization
         from trtran003
         where brel_trade_reference = ReferenceNumber
         and brel_record_status in(GConst.STATUSENTRY, Gconst.STATUSAUTHORIZED, GConst.STATUSUPDATED, GConst.STATUSINACTIVE);

      varOperation := 'Checking for Buyers Credit Loan closure';
      if numAmount = numUtilization then
        if numFlag = 0 then
          update trtran045
            set bcrd_process_complete = GConst.OPTIONYES,
            bcrd_completion_date = WorkDate
            where bcrd_buyers_credit = ReferenceNumber;
        else
          update trtran002
            set trad_process_complete = GConst.OPTIONYES,
            trad_complete_date = WorkDate
            where trad_trade_reference = ReferenceNumber;
        end if;
      else
        if numFlag = 0 then
          update trtran045
            set bcrd_process_complete = GConst.OPTIONNO,
            bcrd_completion_date = null
            Where bcrd_buyers_credit = Referencenumber;
        else
          update trtran002
            set trad_process_complete = GConst.OPTIONNO,
            trad_complete_date =  null
            where trad_trade_reference = ReferenceNumber;
        end if;

       end if;

 --Commented aakash 17-May-13 11:03 am

--    elsif ReferenceType in (Gconst.UTILOPTIONHEDGEDEAL) then
--     VarOperation :='getting otion hedge deal base amount';
--     begin
--      select copt_base_amount
--        into numamount
--        from trtran071
--        where copt_deal_number= ReferenceNumber
--        and copt_serial_number =SerialNumber;
--     exception
--     when no_data_found then
--       numamount:=0;
--     end;
--     VarOperation :='getting otion hedge deal utlization amount';
--     begin
--      select sum(corv_base_amount)
--        into numUtilization
--        from trtran073
--        where corv_deal_number= ReferenceNumber
--      --  and corv_serial_number =SerialNumber
--        and corv_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
--      exception
--      when no_data_found then
--         numUtilization:=0;
--      end;
--      if numAmount <= numUtilization then
--        update trtran071
--          set copt_process_complete=GConst.OPTIONYES,
--          copt_complete_date = WorkDate
--          where copt_deal_number=ReferenceNumber;
--
--         update trtran072  set cosu_process_complete = Gconst.OPTIONYES,
--                cosu_complete_date =workDate
--          where cosu_deal_number =ReferenceNumber;
--          --and copt_serial_number= SerialNumber;
--      else
--        update trtran071
--          set copt_process_complete=GConst.OPTIONNO,
--          copt_complete_date = null
--          where copt_deal_number=ReferenceNumber;
--
--        update trtran072  set cosu_process_complete = Gconst.OPTIONNO,
--                cosu_complete_date =null
--          where cosu_deal_number =ReferenceNumber;
--          --and copt_Serial_number= SerialNumber;
--      end if;
--end
--added by aakash/gouri 17-May-13 11:03 am
elsif ReferenceType in (Gconst.UTILOPTIONHEDGEDEAL) then
VarOperation :='getting option hedge deal base amount';
     Begin
      select copt_base_amount
        into numamount
        from trtran071
        Where Copt_Deal_Number= Referencenumber
       -- and copt_serial_number =SerialNumber;
         and copt_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
     exception
     when no_data_found then
       numamount:=0;
     end;
     VarOperation :='getting option hedge deal utlization amount';
     begin
      Select Sum(Corv_Base_Amount)
        into numUtilization
        from trtran073
        where corv_deal_number= ReferenceNumber
      --  and corv_serial_number =SerialNumber
        and corv_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
      exception
      when no_data_found then
         numUtilization:=0;
      End;
      if numAmount = numUtilization then
        update trtran071
          set copt_process_complete=GConst.OPTIONYES,
          copt_complete_date = WorkDate
          where copt_deal_number=ReferenceNumber;

         update trtran072  set cosu_process_complete = Gconst.OPTIONYES,
                cosu_complete_date =workDate
          where cosu_deal_number =ReferenceNumber;
          --and copt_serial_number= SerialNumber;
      else
        update trtran071
          set copt_process_complete=GConst.OPTIONNO,
          copt_complete_date = null
          where copt_deal_number=ReferenceNumber;

        update trtran072  set cosu_process_complete = Gconst.OPTIONNO,
                cosu_complete_date =null
          where cosu_deal_number =ReferenceNumber;
          --and copt_Serial_number= SerialNumber;
      end if;
--end

    elsif ReferenceType in (Gconst.UTILFUTUREDEAL) then
      select cfut_lot_numbers
        into numamount
        from trtran061
        where cfut_deal_number= ReferenceNumber
        and cfut_record_status not in(10200005,10200006);

      select nvl(sum(cfrv_reverse_lot),0)
        into numUtilization
        from trtran063
        where cfrv_deal_number= ReferenceNumber
        and cfrv_record_status not in (Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
      if numAmount = numUtilization then
        update trtran061
          set cfut_process_complete=GConst.OPTIONYES,
          cfut_complete_date = WorkDate
          where cfut_deal_number=ReferenceNumber;
      else
        update trtran061
          set cfut_process_complete=GConst.OPTIONNO,
          cfut_complete_date = null
          where cfut_deal_number=ReferenceNumber;
      end if;

   elsif ReferenceType in (Gconst.UTILMUTUALFUND) then
     VarOperation := 'Update the Process Complete for the Mutual Funds';

      select sum(MFTR_TRANSACTION_Quantity)
       into numamount
        from trtran048
      where mftr_reference_number =ReferenceNumber
        and mftr_record_status not in (10200005,10200006);

      select sum(MFcl_TRANSACTION_Quantity)
        into numUtilization
        from trtran049
       where mfcl_reference_number =ReferenceNumber
         and mfcl_record_status not in (10200005,10200006);

      if numAmount = numUtilization then
        update trtran048
          set mftr_process_complete=GConst.OPTIONYES,
              mftr_complete_date = WorkDate
          where mftr_reference_number=ReferenceNumber;
      else
        update trtran048
          set mftr_process_complete=GConst.OPTIONNO,
              mftr_complete_date = null
          where mftr_reference_number=ReferenceNumber;
      end if;
   elsif ReferenceType in (Gconst.UTILFIXEDDEPOSIT) then
     VarOperation := 'Update the Process Complete to Fixed deposit';

       select sum(FDRF_DEPOSIT_AMOUNT)
         into numamount
        from trtran047
      where FDRF_FD_NUMBER =ReferenceNumber
        and FDRF_SR_NUMBER=SerialNumber
        and FDRF_record_status not in (10200005,10200006);

      select sum(FDCL_DEPOSIT_AMOUNT)
        into numUtilization
        from trtran047a
       where FDCL_FD_number =ReferenceNumber
       and FDCL_SR_NUMBER=SerialNumber
         and FDCL_record_status not in (10200005,10200006);

      if numAmount = numUtilization then
        update trtran047
          set FDRF_process_complete=GConst.OPTIONYES,
              FDRF_complete_date = WorkDate
          where FDRF_FD_NUMBER=ReferenceNumber
             and FDRF_SR_NUMBER=SerialNumber;
      else
          update trtran047
          set FDRF_process_complete=GConst.OPTIONNO,
              FDRF_complete_date = null
          where FDRF_FD_NUMBER=ReferenceNumber
             and FDRF_SR_NUMBER=SerialNumber;
      end if;
   elsif ReferenceType in (Gconst.UTILFRA) then 
   
     VarOperation := 'Update the Process Complete for FRA';
       select sum(IFRA_NOTIONAL_AMOUNT)
         into numamount
        from trtran090
      where IFRA_FRA_NUMBER =ReferenceNumber
       -- and FDRF_SR_NUMBER=SerialNumber
        and IFRA_record_status not in (10200005,10200006);

      select sum(IFRS_NOTIONAL_AMOUNT)
         into numUtilization
        from trtran090a
      where IFRS_FRA_NUMBER =ReferenceNumber
       -- and FDRF_SR_NUMBER=SerialNumber
        and IFRS_record_status not in (10200005,10200006);
        
     if numAmount >= numUtilization then
        update trtran090
          set IFRA_process_complete=GConst.OPTIONYES,
              IFRA_complete_date = WorkDate
          where IFRA_FRA_NUMBER=ReferenceNumber;
      else
        update trtran090
          set IFRA_process_complete=GConst.OPTIONNO,
              IFRA_complete_date = null
          where IFRA_FRA_NUMBER=ReferenceNumber;
      end if;      
   end if;


    return numError;
Exception
    When others then
      numError := SQLCODE;
      varError := GConst.fncReturnError('CompleteUtil', numError, varMessage,
                      varOperation, varError);
      raise_application_error(-20101, varError);
      return numError;
End fncCompleteUtilization;

---manjunath sir modified on 16042014

--Function fncBillSettlement
--    (   RecordDetail in GConst.gClobType%Type)
--    return number
--    is
----  created by TMM on 31/01/2014
--    numError            number;
--    numTemp             number;
--    numAction           number(4);
--    numSerial           number(5);
--    numLocation         number(8);
--    numCompany          number(8);
--    numReversal         number(8);
--    numReverseAmount    number(15,2);
--    numDealReverse      number(15,2);
--    numBillReverse      number(15,2);
--    numCashDeal         number(15,2);
--    numPandL            number(15,2);
--    numFcy              number(15,2);
--    numSpot             number(15,6);
--    numPremium          number(15,6);
--    numMargin           number(15,6);
--    numFinal            number(15,6);
--    numCashRate         number(15,6);
--    varCompany          varchar2(15);
--    varEntity           varchar2(25);
--    varVoucher          varchar2(25);
--    varTradeReference   varchar2(25);
--    varDealReference    varchar2(25);
--    varReference        varchar2(25);
--    varXPath            varchar2(1024);
--    varTemp             varchar2(1024);
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    datWorkDate         Date;
--    datReference        Date;
--    xmlTemp             xmlType;
--    nlsTemp             xmlDom.DomNodeList;
--    nodFinal            xmlDom.domNode;
--    docFinal            xmlDom.domDocument;
--    nodTemp             xmlDom.domNode;
--    nodTemp1            xmlDom.domNode;
--    nmpTemp             xmldom.domNamedNodemap;
--    numLocalBank        number(8);
--    numCompanyCode      number(8);
--    numReverseSerial    number(5);
--    numCurrencyCode     number(8);
--
--  Begin
--    varMessage := 'Entering Bill Settlement Process';
--    numError := 0;
--    numDealReverse := 0;
--    numBillReverse := 0;
--    numCashDeal := 0;
--
--    varOperation := 'Extracting Parameters';
--    xmlTemp := xmlType(RecordDetail);
--    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
--    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
--    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
--    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationID', numLocation);
--
--varOperation := 'Extracting Parameters' || numLocation;
--
--    numCompany := GConst.fncXMLExtract(xmlTemp, 'BREL_COMPANY_CODE', numCompany);
--    varTradeReference := GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_REFERENCE', varTradeReference);
--    numSerial := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', numSerial);
--    numReversal := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_TYPE', numReversal);
--    varOperation := 'Extracting Parameters BREL_REVERSAL_TYPE ' || numReversal;
--    
--    datReference := GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datReference);
--    numBillReverse := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_FCY', numBillReverse);
--    numCashRate :=  GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_RATE', numCashRate);
--    varOperation := 'Extracting Parameters BREL_REVERSAL_RATE ' || numCashRate;
--    numCompanyCode :=  GConst.fncXMLExtract(xmlTemp, 'BREL_COMPANY_CODE',numCompanyCode);
--    numReverseSerial:=  GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', numReverseSerial); 
--    numLocalBank := GConst.fncXMLExtract(xmlTemp, 'BREL_LOCAL_BANK', numLocalBank); 
--    varOperation := 'Extracting Parameters BREL_LOCAL_BANK ' || numLocalBank;
--    numCurrencyCode := Gconst.fncXMLExtract(xmlTemp, 'CurrencyCode', numCurrencyCode); 
--    varCompany := pkgReturnCursor.fncGetDescription(numCompany,2);
--    
--     varOperation := 'Extracting Parameters CurrencyCode ' || numCurrencyCode;
--    
--    docFinal := xmlDom.newDomDocument(xmlTemp);
--    nodFinal := xmlDom.makeNode(docFinal);
--
--    if numReversal not in (GConst.BILLREALIZE,GConst.BILLINWARDREMIT,
--      GConst.BILLIMPORTREL,GConst.BILLOUTWARDREMIT,GConst.BILLLOANCLOSURE) then
--      Goto Trade_reversal;
--    End if;
--
--    varOperation := 'Checking for Deal Delivery, if any';
--    varXPath := '//CommandSet/DealDetails/ReturnFields/ROWD[@NUM]';
--    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--
--    if xmlDom.getLength(nlsTemp) = 0 then
--      numCashDeal := numBillReverse;
--      GOto Cash_Deal;
--    End if;
--
--<<Deal_Reversal>>
--    varXPath := '//CommandSet/DealDetails/ReturnFields/ROWD[@NUM="';
--      for numSub in 0..xmlDom.getLength(nlsTemp) -1
--      Loop
--        nodTemp := xmlDom.item(nlsTemp, numSub);
--        nmpTemp := xmlDom.getAttributes(nodTemp);
--        nodTemp1 := xmlDom.item(nmpTemp, 0);
--        numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
--        varTemp := varXPath || numTemp || '"]/DealNumber';
--        varDealReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--        varTemp := varXPath || numTemp || '"]/SpotRate'; --Updated From cygnet
--        numSpot := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
---- Node Name changed from FrwRate to Premium for TOI by TMM 31/01/14
--        varTemp := varXPath || numTemp || '"]/Premium';
--        numPremium := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || numTemp || '"]/MarginRate';
--        numMargin := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || numTemp || '"]/FinalRate';
--        numFinal := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
--        varTemp := varXPath || numTemp || '"]/ReverseNow';
--        numReverseAmount := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        numDealReverse := numDealReverse + numReverseAmount;
--
--        select
--          case
--          when datWorkDate < deal_maturity_date and deal_forward_rate != numPremium then
--            round(numReverseAmount * (deal_forward_rate - numPremium))
--          when numFinal != deal_exchange_rate then
--            decode(deal_buy_sell, GConst.PURCHASEDEAL,
--              Round(numReverseAmount * deal_exchange_rate) - Round(numReverseAmount * numFinal),
--              Round(numReverseAmount * numFinal) - Round(numReverseAmount * deal_exchange_rate))
--          else 0
--          end
--          into numPandL
--          from trtran001
--          where deal_deal_number = varDealReference;
--
--        if numPandL > 0 then
--          varOperation := 'Inserting voucher for PL';
--          varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--          insert into trtran008 (bcac_company_code, bcac_location_code,
--            bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--            bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--            bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--            bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--            bcac_create_date, bcac_local_merchant, bcac_record_status,
--            bcac_record_type, bcac_account_number)
--          select numCompany, numLocation, deal_counter_party, varVoucher,
--            deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
--            GConst.TRANSACTIONCREDIT),GConst.ACEXCHANGE,
--            decode(deal_buy_sell,GConst.PURCHASEDEAL,
--            GConst.EVENTPURCHASE, GConst.EVENTSALE),
--            deal_deal_number, 1, deal_base_currency, numReverseAmount,
--            numFinal, Round(numReverseAmount *  numFinal), 'Deal Reversal No: ' ||
--            deal_deal_number, sysdate,30999999,GConst.STATUSENTRY, 23800002,
--            (select lbnk_account_number
--              from trmaster306
--              where lbnk_pick_code = deal_counter_party)
--            from trtran001
--            where deal_deal_number = varDealReference
--            and deal_serial_number = 1;
--        else
--          varVoucher := NULL;
--        end if;
--
--        varOperation := 'Inserting entries to Hedge Table, if necessary';
--        select count(*)
--          into numTemp
--          from trtran004
--          where hedg_trade_reference = varTradeReference
--          and hedg_deal_number = varDealReference
--          and hedg_record_status between 10200001 and 10200004;
---- Deal was not dynamically linked in the realization screen
--        if numtemp = 0 then
--          insert into trtran004
--          (hedg_company_code,hedg_trade_reference,hedg_deal_number,
--            hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
--            hedg_create_date,hedg_entry_detail,hedg_record_status,
--            hedg_hedging_with,hedg_multiple_currency)
--          values(numCompany,varTradeReference,varDealReference,
--          1, numReverseAmount,0, Round(numReverseAmount * numFinal),
--          sysdate,NULL,10200012, 32200001,12400002);
--        End if;
--
--        varOperation := 'Inserting Hedge Deal Delivery';
--        insert into trtran006(cdel_company_code, cdel_deal_number,
--          cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
--          cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
--          cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
--          cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
--          cdel_entry_detail, cdel_record_status, cdel_trade_reference,
--          Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
--          cdel_spot_rate,cdel_forward_rate,cdel_margin_rate) -- Updated from Cygnet
--          select deal_company_code, deal_deal_number,
--          deal_serial_number,
--          (select NVL(max(cdel_reverse_serial),0) + 1
--            from trtran006
--            where cdel_deal_number = varDealReference),
--          datWorkdate, deal_hedge_trade, Gconst.Dealdelivery,
--          numReverseAmount, numFinal, Round(numReverseAmount * numFinal), 1,
--          Round(numReverseAmount * numFinal), to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--          Sysdate, Null, Gconst.Statusentry, varTradeReference, 1, numPandL,
--          varVoucher ,numSpot,numPremium,numMargin
--          from trtran001
--          where deal_deal_number = varDealReference;
--
--        numError := fncCompleteUtilization(varDealReference,GConst.UTILHEDGEDEAL,datWorkDate);
--
--      End Loop;
--
--      numCashDeal := numBillReverse - numDealReverse;
--
--<<Cash_Deal>>
--
--      if numCashDeal > 0 then
--          varOperation := 'Inserting Cash Deal';
--          varDealReference := varCompany || '/FWD/' || GConst.fncGenerateSerial(Gconst.SERIALDEAL,numCompany);
--          insert into trtran001
--            (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
--            deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
--            deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
--            deal_confirm_date,deal_holding_rate,deal_holding_rate1,deal_dealer_holding,deal_dealer_holding1,deal_dealer_remarks,deal_time_stamp,
--            deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
--            deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,cdel_forward_rate,
--            cdel_spot_rate,cdel_margin_rate,deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
--            deal_bo_remark,deal_analysis_option,deal_analysis_type,deal_analysis_frequency,deal_analysis_selection)
--          values ( numCompanyCode, varDealReference, 1, datWorkDate, 26000001,decode(sign(25800050 - numReversal),-1,25300002,25300001),
--            25200002,25400001,NumLocalBank,numCurrencyCode, 30400003,numCashRate, 1, numCashDeal,
--            Round(numCashRate * numCashDeal),0,0,datWorkDate,datWorkDate,null, 'System',
--            NULL, 0,0,0,0,varTradeReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--            to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,sysdate,NULL, 10200001,
--            null,null,null,0,numCashRate,0, 0,
--            0,0,33399999,0,0,33899999, NULL,
--            'Cash Delivery ' || varTradeReference,null,null,null,null);
--            
----            from trtran002
----            where trad_trade_reference = varTradeReference;
--
--          varOperation := 'Inserting Cash Deal Cancellation';
--          insert into trtran006
--            (cdel_company_code,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
--            cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
--            cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
--            cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
--            cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
--            cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark)
--          select deal_company_code, deal_deal_number, 1, 1, varTradeReference, deal_local_rate,
--            datWorkDate, 26000001,27000002,deal_base_amount, deal_exchange_rate, deal_other_amount, 0,
--            0,0,0,0,0,0,'System',varTradeReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), sysdate,
--            null, 10200001, null,null,1,0,deal_exchange_rate,0,0,0,33500001,null,null,deal_bank_reference,
--            deal_bo_remark
--            from trtran001
--            where deal_deal_number = varDealReference;
--      
--         begin 
--           select nvl(HEDG_TRADE_SERIAL,1) +1
--           into  numserial 
--            from trtran004 
--            where hedg_trade_reference=varTradeReference;
--         exception 
--           when no_data_found then
--             numserial:=1;
--         end ;
--          varOperation := 'Inserting Hedge record';
--          insert into trtran004
--          (hedg_company_code,hedg_trade_reference,hedg_deal_number,
--            hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
--            hedg_create_date,hedg_entry_detail,hedg_record_status,
--            hedg_hedging_with,hedg_multiple_currency,HEDG_TRADE_SERIAL)
--          values(numCompany,varTradeReference,varDealReference,
--          1, numCashDeal,0, Round(numCashDeal * numCashRate),
--          sysdate,NULL,10200012, 32200001,12400002,numserial);
--
--      End if;
--
--
--
--<<Trade_Reversal>>
--
----        if numReversal in (GConst.BILLREALIZE,GConst.BILLIMPORTREL) then
----          numError := fncCompleteUtilization(varTradeReference,GConst.UTILEXPORTS,datWorkDate);
--      if numReversal in (GConst.BILLREALIZE,GConst.BILLIMPORTREL,
--             GConst.BILLEXPORTCANCEL,GConst.BILLIMPORTCANCEL,GCONST.BILLAMENDMENT) then
--             --Changed by Manjunath Reddy to include Export cancel and import cancel for process complete
--          numError := fncCompleteUtilization(varTradeReference,GConst.UTILEXPORTS,datWorkDate);
--          
--          if  numReversal in (GConst.BILLEXPORTCANCEL,GConst.BILLIMPORTCANCEL) then              
--              update trtran004     
--                set hedg_record_status = GConst.STATUSPOSTCANCEL
--                where hedg_trade_reference = varTradeReference
--                and hedg_record_Status not in (10200005,10200006);
--          end if;
--          
----      varOperation := 'Checking for PSCFC Details';
----      Begin
----        numFcy := 0;
----        varReference := '';
----   --     varReference := GConst.fncXMLExtract(xmlTemp, 'LoanNumber', varReference);
----        numFcy := GConst.fncXMLExtract(xmlTemp, '//PSCFCDetails/SanctionedFcy', 
----                        numFcy, GConst.TYPENODEPATH);
----        
----      Exception
----        when others then
----          numFcy := 0;
----          varReference := '';
----      End;
----      
----      if numFcy > 0 then
----        
----        if numAction = GConst.ADDSAVE then
----          varReference := PkgReturnCursor.fncGetDescription(GConst.LOANPSCFC, GConst.PICKUPSHORT);
----          varReference := varReference || '/' || GConst.fncGenerateSerial(GConst.SERIALLOAN);
----          
----          varOperation := 'Inserting PSCFC Record';
----          insert into trtran005(fcln_company_code, fcln_loan_number,
----          fcln_loan_type, fcln_local_bank, fcln_bank_reference, fcln_sanction_date,
----          fcln_noof_days, fcln_currency_code, fcln_sanctioned_fcy,
----          fcln_conversion_rate, fcln_sanctioned_inr, fcln_reason_code,
----          fcln_maturity_from, fcln_maturity_to, fcln_loan_remarks,
----          Fcln_Libor_Rate,Fcln_Rate_Spread,Fcln_Interest_Rate, -- Updated From Cygnet
----          fcln_create_date, fcln_entry_detail, fcln_record_status,fcln_process_complete) -- Updated From Cygnet
----          values(numCompany, varReference, GConst.LOANPSCFC,
----          Gconst.Fncxmlextract(Xmltemp, 'BREL_LOCAL_BANK', Numfcy),
----          GConst.fncXMLExtract(xmlTemp, 'BankReference', varReference),
----          GConst.fncXMLExtract(xmlTemp, 'SanctionDate', datWorkDate),
----          GConst.fncXMLExtract(xmlTemp, 'NoofDays', numError),
----          (select trad_trade_currency
----            from trtran002
----            where trad_trade_reference = varTradeReference),
----          GConst.fncXMLExtract(xmlTemp, 'SanctionedFcy', numFcy),
----          GConst.fncXMLExtract(xmlTemp, 'ConversionRate', numFcy),
----          GConst.fncXMLExtract(xmlTemp, 'SanctionedInr', numFcy),
----          GConst.REASONEXPORT,
----          GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_FROM', datWorkDate),
----          GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datWorkDate),
----          'PSCFC From Bill Trade Reference ' || varTradeReference,
----          GConst.fncXMLExtract(xmlTemp, 'LiborRate', numSpot), -- Updated From Cygnet
----          GConst.fncXMLExtract(xmlTemp, 'SpreadRate', numSpot),
----          GConst.fncXMLExtract(xmlTemp, 'InterestRate', numSpot),
----          sysdate, null, GConst.STATUSENTRY,
----          12400002); -- End updated cygnet
----          
----          varOperation := 'Inserting Loan Connect';
----          insert into trtran010(loln_company_code, loln_loan_number,      -- Updated from cygnet
----          loln_trade_reference, loln_serial_number, loln_adjusted_date, 
----          Loln_Adjusted_Fcy, Loln_Adjusted_Rate, Loln_Adjusted_Inr,
----          loln_create_date, loln_entry_detail, loln_record_status)        --End Updated Cygnet
----          values(numCompany, varReference, varTradeReference, 0, datWorkDate,
----          GConst.fncXMLExtract(xmlTemp, 'SanctionedFcy', numFcy),
----          GConst.fncXMLExtract(xmlTemp, 'ConversionRate', numFcy),
----          GConst.fncXMLExtract(xmlTemp, 'SanctionedInr', numFcy),
----          sysdate, null, GConst.STATUSENTRY);
----          
----        End if;
--      
----    End if;  
--        elsif numReversal = GConst.BILLLOANCLOSURE then
--          numError := fncCompleteUtilization(varTradeReference,GConst.UTILBCRLOAN,datWorkDate);
--        end if;
--
--      if numReversal in (GConst.BILLREALIZE,GConst.BILLIMPORTREL,GConst.BILLLOANCLOSURE) then
--          himatsingkatf_prod.pkgTreasury.prcBillSettlement(RecordDetail,numReversal);
--      end if;
--      return numError;
--Exception
--        When others then
--          numError := SQLCODE;
--          varError := SQLERRM;
--          varError := GConst.fncReturnError('BillSettle', numError, varMessage,
--                          varOperation, varError);
--          raise_application_error(-20101, varError);
--          return numError;
--End fncBillSettlement;
--Function fncBillSettlement
--    (   RecordDetail in GConst.gClobType%Type)
--    return number
--    is
----  created by TMM on 31/01/2014
--    numError            number;
--    numTemp             number;
--    numAction           number(4);
--    numSerial           number(5);
--    numLocation         number(8);
--    numCompany          number(8);
--    numReversal         number(8);
--    numImportExport     number(8);    
--    numReverseAmount    number(15,2);
--    numDealReverse      number(15,2);
--    numBillReverse      number(15,2);
--    numCashDeal         number(15,2);
--    numPandL            number(15,2);
--    numFcy              number(15,2);
--    numSpot             number(15,6);
--    numPremium          number(15,6);
--    numMargin           number(15,6);
--    numFinal            number(15,6);
--    numCashRate         number(15,6);
--    varCompany          varchar2(15);
--    varEntity           varchar2(25);
--    varVoucher          varchar2(25);
--    varTradeReference   varchar2(25);
--    varDealReference    varchar2(25);
--    varReference        varchar2(25);
--    varXPath            varchar2(1024);
--    varTemp             varchar2(1024);
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    datWorkDate         Date;
--    datReference        Date;
--    xmlTemp             xmlType;
--    nlsTemp             xmlDom.DomNodeList;
--    nodFinal            xmlDom.domNode;
--    docFinal            xmlDom.domDocument;
--    nodTemp             xmlDom.domNode;
--    nodTemp1            xmlDom.domNode;
--    nmpTemp             xmldom.domNamedNodemap;
--    numLocalBank        number(8);
--    numCompanyCode      number(8);
--    numReverseSerial    number(5);
--    numCurrencyCode     number(8);
--
--  Begin
--    varMessage := 'Entering Bill Settlement Process';
--    numError := 0;
--    numDealReverse := 0;
--    numBillReverse := 0;
--    numCashDeal := 0;
--
--    varOperation := 'Extracting Parameters';
--    xmlTemp := xmlType(RecordDetail);
--    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
--    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
--    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
--    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationID', numLocation);
--
--varOperation := 'Extracting Parameters' || numLocation;
--
--    numCompany := GConst.fncXMLExtract(xmlTemp, 'BREL_COMPANY_CODE', numCompany);
--    varTradeReference := GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_REFERENCE', varTradeReference);
--    numSerial := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', numSerial);
--    numReversal := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_TYPE', numReversal);
--    varOperation := 'Extracting Parameters BREL_REVERSAL_TYPE ' || numReversal;
--    
--    datReference := GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datReference);
--    numBillReverse := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_FCY', numBillReverse);
--    numCashRate :=  GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_RATE', numCashRate);
--    varOperation := 'Extracting Parameters BREL_REVERSAL_RATE ' || numCashRate;
--    numCompanyCode :=  GConst.fncXMLExtract(xmlTemp, 'BREL_COMPANY_CODE',numCompanyCode);
--    numReverseSerial:=  GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', numReverseSerial); 
--    numLocalBank := GConst.fncXMLExtract(xmlTemp, 'BREL_LOCAL_BANK', numLocalBank); 
--    varOperation := 'Extracting Parameters BREL_LOCAL_BANK ' || numLocalBank;
--    numCurrencyCode := Gconst.fncXMLExtract(xmlTemp, 'CurrencyCode', numCurrencyCode); 
--    numImportExport := gconst.fncxmlextract(xmltemp, 'ImportExport', numImportExport);
--    
--    varCompany := pkgReturnCursor.fncGetDescription(numCompany,2);
--    
--     varOperation := 'Extracting Parameters CurrencyCode ' || numCurrencyCode;
--    
--    docFinal := xmlDom.newDomDocument(xmlTemp);
--    nodFinal := xmlDom.makeNode(docFinal);
--
--    if numReversal not in (GConst.BILLREALIZE,GConst.BILLINWARDREMIT,
--      GConst.BILLIMPORTREL,GConst.BILLOUTWARDREMIT,GConst.BILLLOANCLOSURE) then
--      Goto Trade_reversal;
--    End if;
--
--    varOperation := 'Checking for Deal Delivery, if any';
--    varXPath := '//CommandSet/DealDetails/ReturnFields/ROWD[@NUM]';
--    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--
--    if xmlDom.getLength(nlsTemp) = 0 then
--      numCashDeal := numBillReverse;
--      GOto Cash_Deal;
--    End if;
--
--<<Deal_Reversal>>
--    varXPath := '//CommandSet/DealDetails/ReturnFields/ROWD[@NUM="';
--      for numSub in 0..xmlDom.getLength(nlsTemp) -1
--      Loop
--        nodTemp := xmlDom.item(nlsTemp, numSub);
--        nmpTemp := xmlDom.getAttributes(nodTemp);
--        nodTemp1 := xmlDom.item(nmpTemp, 0);
--        numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
--        varTemp := varXPath || numTemp || '"]/DealNumber';
--        varDealReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--        varTemp := varXPath || numTemp || '"]/SpotRate'; --Updated From cygnet
--        numSpot := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
---- Node Name changed from FrwRate to Premium for TOI by TMM 31/01/14
--        varTemp := varXPath || numTemp || '"]/Premium';
--        numPremium := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || numTemp || '"]/MarginRate';
--        numMargin := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || numTemp || '"]/FinalRate';
--        numFinal := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
--        varTemp := varXPath || numTemp || '"]/ReverseNow';
--        numReverseAmount := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        numDealReverse := numDealReverse + numReverseAmount;
--
--        select
--          case
--          when datWorkDate < deal_maturity_date and deal_forward_rate != numPremium then
--            round(numReverseAmount * (deal_forward_rate - numPremium))
--          when numFinal != deal_exchange_rate then
--            decode(deal_buy_sell, GConst.PURCHASEDEAL,
--              Round(numReverseAmount * deal_exchange_rate) - Round(numReverseAmount * numFinal),
--              Round(numReverseAmount * numFinal) - Round(numReverseAmount * deal_exchange_rate))
--          else 0
--          end
--          into numPandL
--          from trtran001
--          where deal_deal_number = varDealReference;
--
--        if numPandL > 0 then
--          varOperation := 'Inserting voucher for PL';
--          varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--          insert into trtran008 (bcac_company_code, bcac_location_code,
--            bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--            bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--            bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--            bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--            bcac_create_date, bcac_local_merchant, bcac_record_status,
--            bcac_record_type, bcac_account_number)
--          select numCompany, numLocation, deal_counter_party, varVoucher,
--            deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
--            GConst.TRANSACTIONCREDIT),GConst.ACEXCHANGE,
--            decode(deal_buy_sell,GConst.PURCHASEDEAL,
--            GConst.EVENTPURCHASE, GConst.EVENTSALE),
--            deal_deal_number, 1, deal_base_currency, numReverseAmount,
--            numFinal, Round(numReverseAmount *  numFinal), 'Deal Reversal No: ' ||
--            deal_deal_number, sysdate,30999999,GConst.STATUSENTRY, 23800002,
--            (select lbnk_account_number
--              from trmaster306
--              where lbnk_pick_code = deal_counter_party)
--            from trtran001
--            where deal_deal_number = varDealReference
--            and deal_serial_number = 1;
--        else
--          varVoucher := NULL;
--        end if;
--
--        varOperation := 'Inserting entries to Hedge Table, if necessary';
--        select count(*)
--          into numTemp
--          from trtran004
--          where hedg_trade_reference = varTradeReference
--          and hedg_deal_number = varDealReference
--          and hedg_record_status between 10200001 and 10200004;
---- Deal was not dynamically linked in the realization screen
--        if numtemp = 0 then
--          insert into trtran004
--          (hedg_company_code,hedg_trade_reference,hedg_deal_number,
--            hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
--            hedg_create_date,hedg_entry_detail,hedg_record_status,
--            hedg_hedging_with,hedg_multiple_currency)
--          values(numCompany,varTradeReference,varDealReference,
--          1, numReverseAmount,0, Round(numReverseAmount * numFinal),
--          sysdate,NULL,10200012, 32200001,12400002);
--        End if;
--
--        varOperation := 'Inserting Hedge Deal Delivery';
--        insert into trtran006(cdel_company_code, cdel_deal_number,
--          cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
--          cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
--          cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
--          cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
--          cdel_entry_detail, cdel_record_status, cdel_trade_reference,
--          Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
--          cdel_spot_rate,cdel_forward_rate,cdel_margin_rate) -- Updated from Cygnet
--          select deal_company_code, deal_deal_number,
--          deal_serial_number,
--          (select NVL(max(cdel_reverse_serial),0) + 1
--            from trtran006
--            where cdel_deal_number = varDealReference),
--          datWorkdate, deal_hedge_trade, Gconst.Dealdelivery,
--          numReverseAmount, numFinal, Round(numReverseAmount * numFinal), 1,
--          Round(numReverseAmount * numFinal), to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--          Sysdate, Null, Gconst.Statusentry, varTradeReference, 1, numPandL,
--          varVoucher ,numSpot,numPremium,numMargin
--          from trtran001
--          where deal_deal_number = varDealReference;
--
--        numError := fncCompleteUtilization(varDealReference,GConst.UTILHEDGEDEAL,datWorkDate);
--
--      End Loop;
--
--      numCashDeal := numBillReverse - numDealReverse;
--
--<<Cash_Deal>>
--
--      if numCashDeal > 0 then
--          varOperation := 'Inserting Cash Deal';
--          varDealReference := varCompany || '/FWD/' || GConst.fncGenerateSerial(Gconst.SERIALDEAL,numCompany);
--          insert into trtran001
--            (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
--            deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
--            deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
--            deal_confirm_date,deal_holding_rate,deal_holding_rate1,deal_dealer_holding,deal_dealer_holding1,deal_dealer_remarks,deal_time_stamp,
--            deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
--            deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,cdel_forward_rate,
--            cdel_spot_rate,cdel_margin_rate,deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
--            deal_bo_remark,deal_analysis_option,deal_analysis_type,deal_analysis_frequency,deal_analysis_selection)
--          values ( numCompanyCode, varDealReference, 1, datWorkDate, 26000001,decode(sign(25800050 - numReversal),-1,25300002,25300001),
--            25200002,25400001,NumLocalBank,numCurrencyCode, 30400003,numCashRate, 1, numCashDeal,
--            Round(numCashRate * numCashDeal),0,0,datWorkDate,datWorkDate,null, 'System',
--            NULL, 0,0,0,0,varTradeReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--            to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,sysdate,NULL, 10200001,
--            null,null,null,0,numCashRate,0, 0,
--            0,0,33399999,0,0,33899999, NULL,
--            'Cash Delivery ' || varTradeReference,null,null,null,null);
--            
----            from trtran002
----            where trad_trade_reference = varTradeReference;
--
--          varOperation := 'Inserting Cash Deal Cancellation';
--          insert into trtran006
--            (cdel_company_code,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
--            cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
--            cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
--            cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
--            cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
--            cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark)
--          select deal_company_code, deal_deal_number, 1, 1, varTradeReference, deal_local_rate,
--            datWorkDate, 26000001,27000002,deal_base_amount, deal_exchange_rate, deal_other_amount, 0,
--            0,0,0,0,0,0,'System',varTradeReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), sysdate,
--            null, 10200001, null,null,1,0,deal_exchange_rate,0,0,0,33500001,null,null,deal_bank_reference,
--            deal_bo_remark
--            from trtran001
--            where deal_deal_number = varDealReference;
--      
--         begin 
--           select nvl(HEDG_TRADE_SERIAL,1) +1
--           into  numserial 
--            from trtran004 
--            where hedg_trade_reference=varTradeReference;
--         exception 
--           when no_data_found then
--             numserial:=1;
--         end ;
--          varOperation := 'Inserting Hedge record';
--          insert into trtran004
--          (hedg_company_code,hedg_trade_reference,hedg_deal_number,
--            hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
--            hedg_create_date,hedg_entry_detail,hedg_record_status,
--            hedg_hedging_with,hedg_multiple_currency,HEDG_TRADE_SERIAL)
--          values(numCompany,varTradeReference,varDealReference,
--          1, numCashDeal,0, Round(numCashDeal * numCashRate),
--          sysdate,NULL,10200012, 32200001,12400002,numserial);
--
--      End if;
--
--
--
--<<Trade_Reversal>>
--
----        if numReversal in (GConst.BILLREALIZE,GConst.BILLIMPORTREL) then
----          numError := fncCompleteUtilization(varTradeReference,GConst.UTILEXPORTS,datWorkDate);
--      if numReversal in (GConst.BILLREALIZE,GConst.BILLIMPORTREL,
--             GConst.BILLEXPORTCANCEL,GConst.BILLIMPORTCANCEL,GCONST.BILLAMENDMENT) then
--             --Changed by Manjunath Reddy to include Export cancel and import cancel for process complete
--          numError := fncCompleteUtilization(varTradeReference,GConst.UTILEXPORTS,datWorkDate);
--          
--          if  numReversal in (GConst.BILLEXPORTCANCEL,GConst.BILLIMPORTCANCEL) then              
--              update trtran004     
--                set hedg_record_status = GConst.STATUSPOSTCANCEL
--                where hedg_trade_reference = varTradeReference
--                and hedg_record_Status not in (10200005,10200006);
--          end if;
--          
----      varOperation := 'Checking for PSCFC Details';
----      Begin
----        numFcy := 0;
----        varReference := '';
----   --     varReference := GConst.fncXMLExtract(xmlTemp, 'LoanNumber', varReference);
----        numFcy := GConst.fncXMLExtract(xmlTemp, '//PSCFCDetails/SanctionedFcy', 
----                        numFcy, GConst.TYPENODEPATH);
----        
----      Exception
----        when others then
----          numFcy := 0;
----          varReference := '';
----      End;
----      
----      if numFcy > 0 then
----        
----        if numAction = GConst.ADDSAVE then
----          varReference := PkgReturnCursor.fncGetDescription(GConst.LOANPSCFC, GConst.PICKUPSHORT);
----          varReference := varReference || '/' || GConst.fncGenerateSerial(GConst.SERIALLOAN);
----          
----          varOperation := 'Inserting PSCFC Record';
----          insert into trtran005(fcln_company_code, fcln_loan_number,
----          fcln_loan_type, fcln_local_bank, fcln_bank_reference, fcln_sanction_date,
----          fcln_noof_days, fcln_currency_code, fcln_sanctioned_fcy,
----          fcln_conversion_rate, fcln_sanctioned_inr, fcln_reason_code,
----          fcln_maturity_from, fcln_maturity_to, fcln_loan_remarks,
----          Fcln_Libor_Rate,Fcln_Rate_Spread,Fcln_Interest_Rate, -- Updated From Cygnet
----          fcln_create_date, fcln_entry_detail, fcln_record_status,fcln_process_complete) -- Updated From Cygnet
----          values(numCompany, varReference, GConst.LOANPSCFC,
----          Gconst.Fncxmlextract(Xmltemp, 'BREL_LOCAL_BANK', Numfcy),
----          GConst.fncXMLExtract(xmlTemp, 'BankReference', varReference),
----          GConst.fncXMLExtract(xmlTemp, 'SanctionDate', datWorkDate),
----          GConst.fncXMLExtract(xmlTemp, 'NoofDays', numError),
----          (select trad_trade_currency
----            from trtran002
----            where trad_trade_reference = varTradeReference),
----          GConst.fncXMLExtract(xmlTemp, 'SanctionedFcy', numFcy),
----          GConst.fncXMLExtract(xmlTemp, 'ConversionRate', numFcy),
----          GConst.fncXMLExtract(xmlTemp, 'SanctionedInr', numFcy),
----          GConst.REASONEXPORT,
----          GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_FROM', datWorkDate),
----          GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datWorkDate),
----          'PSCFC From Bill Trade Reference ' || varTradeReference,
----          GConst.fncXMLExtract(xmlTemp, 'LiborRate', numSpot), -- Updated From Cygnet
----          GConst.fncXMLExtract(xmlTemp, 'SpreadRate', numSpot),
----          GConst.fncXMLExtract(xmlTemp, 'InterestRate', numSpot),
----          sysdate, null, GConst.STATUSENTRY,
----          12400002); -- End updated cygnet
----          
----          varOperation := 'Inserting Loan Connect';
----          insert into trtran010(loln_company_code, loln_loan_number,      -- Updated from cygnet
----          loln_trade_reference, loln_serial_number, loln_adjusted_date, 
----          Loln_Adjusted_Fcy, Loln_Adjusted_Rate, Loln_Adjusted_Inr,
----          loln_create_date, loln_entry_detail, loln_record_status)        --End Updated Cygnet
----          values(numCompany, varReference, varTradeReference, 0, datWorkDate,
----          GConst.fncXMLExtract(xmlTemp, 'SanctionedFcy', numFcy),
----          GConst.fncXMLExtract(xmlTemp, 'ConversionRate', numFcy),
----          GConst.fncXMLExtract(xmlTemp, 'SanctionedInr', numFcy),
----          sysdate, null, GConst.STATUSENTRY);
----          
----        End if;
--      
----    End if;          
--        elsif numReversal = GConst.BILLLOANCLOSURE then
--          numError := fncCompleteUtilization(varTradeReference,GConst.UTILBCRLOAN,datWorkDate);
--        end if;
--      if numReversal in (GConst.BILLREALIZE,GConst.BILLIMPORTREL,GConst.BILLLOANCLOSURE) then
--          --prcbillsettlement(recorddetail,numreversal);
--          himatsingkatf_prod.pkgTreasury.prcBillSettlement(RecordDetail,numImportExport);
--      end if;
--      
--      return numError;
--Exception
--        When others then
--          numError := SQLCODE;
--          varError := SQLERRM;
--          varError := GConst.fncReturnError('BillSettle', numError, varMessage,
--                          varOperation, varError);
--          raise_application_error(-20101, varError);
--          RETURN numError;
--End fncBillSettlement;

--Function forwardSettlement
--    (   RecordDetail in GConst.gClobType%Type)
--    return number
--    is
----  created by TMM on 31/01/2014
--    numError            number;
--    numTemp             number;
--    numAction           number(4);
--    numSerial           number(5):=0;
--    numLocation         number(8);
--    numCompany          number(8);
--    numReversal         number(8);
--    numImportExport     number(8);    
--    numReverseAmount    number(15,2);
--    numDealReverse      number(15,2);
--    numBillReverse      number(15,2);
--    numCashDeal         number(15,2);
--    numPandL            number(15,2);
--    numFcy              number(15,2);
--    numSpot             number(15,6);
--    numPremium          number(15,6);
--    numMargin           number(15,6);
--    numFinal            number(15,6);
--    numCashRate         number(15,6);
--    varCompany          varchar2(15);
--    varEntity           varchar2(25);
--    varVoucher          varchar2(25);
--    varTradeReference   varchar2(25);
--    varDealReference    varchar2(25);
--    varReference        varchar2(25);
--    varXPath            varchar2(1024);
--    varTemp             varchar2(1024);
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    datWorkDate         Date;
--    datReference        Date;
--    xmlTemp             xmlType;
--    nlsTemp             xmlDom.DomNodeList;
--    nodFinal            xmlDom.domNode;
--    docFinal            xmlDom.domDocument;
--    nodTemp             xmlDom.domNode;
--    nodTemp1            xmlDom.domNode;
--    nmpTemp             xmldom.domNamedNodemap;
--    numLocalBank        number(8);
--    numCompanyCode      number(8);
--    numReverseSerial    number(5);
--    numCurrencyCode     NUMBER(8);
--    numTradeSerial      NUMBER(5):=0;
--    userID              varchar2(15);
--    numBuySell          number(8);
--    numLOBCode          number(8);
--    numRecordStatus     number(1);
--    numRefSerial        number(5);
--    numRevSerial        number(5);
--    numTemp1            number(5):= 0;
--    numintOutlayRate    number(15,6);
--    numIntoutlay        number(15,2);
--    clbTemp             clob;
--   
--
--  Begin
--    varMessage := 'Entering Bill Settlement Process';
--    numError := 0;
--    numDealReverse := 0;
--    numBillReverse := 0;
--    numCashDeal := 0;
--
--    varOperation := 'Extracting Parameters';
--    xmlTemp := xmlType(RecordDetail);
--    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
--    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
--    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationID', numLocation);
--    userID      := GConst.fncXMLExtract(xmlTemp, 'UserCode', userID);
--    numCompany := GConst.fncXMLExtract(xmlTemp, 'CompanyID', numCompany);
--    varEntity :=  gconst.fncxmlextract(xmltemp, 'CommandSet/Entity', varEntity);
--
--    varXPath := '//FORWARDSETTLEMENTS/CASHSETTLEMENT';
--    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--    if xmlDom.getLength(nlsTemp) > 0 then
--        numCashRate :=  gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/CashRate', numCashRate);
--        numCashDeal :=  gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/CashAmount', numCashDeal); 
--        datReference := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/ReferenceDate', datReference);  -- Pass this value from XML
--        numBuySell := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/BuySell', numBuySell);  -- Pass this value from XML
--        numLocalBank := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/BankCode', numLocalBank); 
--        numCurrencyCode := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/CurrencyCode', numCurrencyCode); 
--        numLOBCode := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/LobCode', numLOBCode); 
--        varTradeReference := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/TradeReference', varTradeReference); 
--    END IF;
--    
--    --end loop;
--    
--    varOperation := 'Extracting Parameters CurrencyCode ' || numCurrencyCode;
--    if varEntity = 'BILLREALISATION' then -- LOB code will comming in Main XML only
--      numLOBCode := gconst.fncxmlextract(xmltemp, 'BNKC_LOB_CODE', numLOBCode);
--      numTradeSerial := gconst.fncxmlextract(xmltemp, 'BREL_REALIZATION_NUMBER', numTradeSerial);
--    elsif varEntity = 'IMPORTREALIZE' then
--      numLOBCode := gconst.fncxmlextract(xmltemp, 'SPAY_LOB_CODE', numLOBCode);
--      numTradeSerial := gconst.fncxmlextract(xmltemp, 'SPAY_SHIPMENT_SERIAL', numTradeSerial);
--    elsif varEntity = 'IMPORTADVICE' then
--      numLOBCode := gconst.fncxmlextract(xmltemp, 'IADP_LOB_CODE', numLOBCode);
--      numTradeSerial := 0;
--     elsif varEntity = 'LOANCLOSURE' then
--      numLOBCode := gconst.fncxmlextract(xmltemp, 'INTC_LOB_CODE', numLOBCode);
--      numTradeSerial := gconst.fncxmlextract(xmltemp, 'INTC_INTEREST_NUMBER', numTradeSerial);
--    end if;
--    
--    varOperation := 'Extracting Parameters Location ' || numLocation;
--    numLocation := nvl(himatsingkatf_prod.PKGTREASURY.GetTreasuryCode(numLocation),0);--Mapping Required in Trade finance
--        varOperation := 'Extracting Parameters numCompany ' || numCompany;
--    numCompany := himatsingkatf_prod.PKGTREASURY.GetTreasuryCode(numCompany);
--    varOperation := 'Extracting Parameters numBuySell ' || numBuySell;
--    numBuySell := himatsingkatf_prod.PKGTREASURY.GetTreasuryCode(numBuySell);
--    numLocalBank := himatsingkatf_prod.PKGTREASURY.GetTreasuryCode(numLocalBank);
--    varOperation := 'Extracting Parameters numCurrencyCode ' || numCurrencyCode;
--    numCurrencyCode := himatsingkatf_prod.PKGTREASURY.GetTreasuryCode(numCurrencyCode);
--    varOperation := 'Extracting Parameters numLOBCode ' || numLOBCode;
--    numLOBCode := nvl(himatsingkatf_prod.PKGTREASURY.GetTreasuryCode(numLOBCode),0);--Mapping Required in Trade finance
--    varCompany := PKGRETURNCURSOR.fncGetdescription(numCompany,2);
--    docFinal := xmlDom.newDomDocument(xmlTemp);
--    nodFinal := xmlDom.makeNode(docFinal);
--    varOperation := 'Checking for Deal Delivery, if any';
--    varXPath := '//FORWARDSETTLEMENTS/FORWARDSETTLEMENT/ROW[@NUM]';
--    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--    if xmlDom.getLength(nlsTemp) = 0 then
--      GOto Cash_Deal;
--    END IF;
-- --   insert into temp values(varXPath,'chandra');
--    varXPath := '//FORWARDSETTLEMENTS/FORWARDSETTLEMENT/ROW[@NUM="';
--    for numSub in 0..xmlDom.getLength(nlsTemp) -1
--      Loop
--        nodTemp := xmlDom.item(nlsTemp, numSub);
--        nmpTemp := xmlDom.getAttributes(nodTemp);
--        nodTemp1 := xmlDom.item(nmpTemp, 0);
--        numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
--        varTemp := varXPath || numTemp || '"]/DealNumber';
--        varDealReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--        varTemp := varXPath || numTemp || '"]/SpotRate';
--        numSpot := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
--        varTemp := varXPath || numTemp || '"]/Premium';
--        numPremium := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || numTemp || '"]/MarginRate';
--        numMargin := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || numTemp || '"]/FinalRate';
--        numFinal := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
--        varTemp := varXPath || numTemp || '"]/ReverseAmount';
--        numReverseAmount := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || numTemp || '"]/RecordStatus';
--        numRecordStatus := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || numTemp || '"]/ReverseSerial';
--        numRevSerial := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--
--        varTemp := varXPath || numTemp || '"]/IntoutlayRate';
--        numintOutlayRate := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || numTemp || '"]/IntOutply';
--
--        numIntoutlay := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        numDealReverse := numDealReverse + numReverseAmount;
--        insert into temp values(numFinal,numReverseAmount);
--            varOperation := 'Before Select ';
--        IF numAction  IN(GConst.ADDSAVE, GConst.EDITSAVE) THEN
--          select
--            case
--            when datWorkDate < deal_maturity_date and deal_forward_rate != numPremium then
--              round(numReverseAmount * (deal_forward_rate - numPremium))
--            when numFinal != deal_exchange_rate then
--              decode(deal_buy_sell, GConst.PURCHASEDEAL,
--                Round(numReverseAmount * deal_exchange_rate) - Round(numReverseAmount * numFinal),
--                Round(numReverseAmount * numFinal) - Round(numReverseAmount * deal_exchange_rate))
--            else 0
--            end
--            into numPandL
--            from trtran001
--            where deal_deal_number = varDealReference
--             and Deal_Record_status not in (10200005,10200006);
--         END IF;    
--           varOperation := 'After  Select ';
--        if numAction = GConst.ADDSAVE then
--          varOperation := 'Inserting Hedge Deal Delivery';
--          insert into trtran006(cdel_company_code, cdel_deal_number,
--            cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
--            cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
--            cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
--            cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
--            cdel_entry_detail, cdel_record_status, cdel_trade_reference,
--            Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
--            cdel_spot_rate,cdel_forward_rate,cdel_margin_rate,CDEL_DELIVERY_SERIAL,cdel_int_outlay,cdel_intoutlay_rate)
--            select deal_company_code, deal_deal_number,
--            deal_serial_number,
--            (select NVL(max(cdel_reverse_serial),0) + 1
--              from trtran006
--              where cdel_deal_number = varDealReference),
--            datWorkdate, deal_hedge_trade, Gconst.Dealdelivery,
--            numReverseAmount, numFinal, Round(numReverseAmount * numFinal), 1,
--            Round(numReverseAmount * numFinal), to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--            SYSDATE, NULL, Gconst.Statusentry, varTradeReference, numTradeSerial,
--            numPandL,varVoucher ,numSpot,numPremium,numMargin,numSerial,numIntoutlay,numintOutlayRate
--            from trtran001
--            where deal_deal_number = varDealReference;
--  
--          numError := fncCompleteUtilization(varDealReference,GConst.UTILHEDGEDEAL,datWorkDate);
--          
--          if numPandL != 0 then
--              select CDEL_REVERSE_SERIAL into numTemp1
--                from trtran006
--              where cdel_deal_number = varDealReference
--                    and cdel_trade_reference = varTradeReference
--                    and Cdel_Trade_Serial = numTradeSerial;
--
--            varOperation := 'Inserting Current Account voucher for PL';
--            varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--            insert into trtran008 (bcac_company_code, bcac_location_code,
--              bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--              bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--              bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--              bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--              bcac_create_date, bcac_local_merchant, bcac_record_status,
--              bcac_record_type, bcac_account_number)
--            select numCompany, deal_location_code, deal_counter_party, varVoucher,
--              deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
--              GConst.TRANSACTIONCREDIT),24900049,24800051,
--              deal_deal_number,numTemp1, 
--              deal_base_currency, 0,
--              0, numPandL, 'Deal Reversal No: ' ||
--              deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
--              (select lbnk_account_number
--                from trmaster306
--                where lbnk_pick_code = deal_counter_party)
--              from trtran001
--              where deal_deal_number = varDealReference
--              and deal_serial_number = 1;    
--            varOperation := 'Inserting INterest OutLay';
--            if numIntoutlay <> 0 then
--              varOperation := 'Inserting INterest OutLay';
--              varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--              insert into trtran008 (bcac_company_code, bcac_location_code,
--                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                bcac_create_date, bcac_local_merchant, bcac_record_status,
--                bcac_record_type, bcac_account_number)
--              select numCompany, deal_location_code, deal_counter_party, varVoucher,
--                deal_maturity_date, GConst.TRANSACTIONDEBIT,24900079,24800057,
--                deal_deal_number,numTemp1, 
--                deal_base_currency, 0,
--                0, numIntoutlay, 'Deal Reversal No: ' ||
--                deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
--                (select lbnk_account_number
--                  from trmaster306
--                  where lbnk_pick_code = deal_counter_party)
--                from trtran001
--                where deal_deal_number = varDealReference
--                and deal_serial_number = 1;   
--            end if;
--            varOperation := 'Inserting Interest Current';
--            
--            varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--            insert into trtran008 (bcac_company_code, bcac_location_code,
--              bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--              bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--              bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--              bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--              bcac_create_date, bcac_local_merchant, bcac_record_status,
--              bcac_record_type, bcac_account_number)
--            select numCompany, deal_location_code, deal_counter_party, varVoucher,
--              deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONCREDIT,
--              GConst.TRANSACTIONDEBIT),24900030,24800051,
--              deal_deal_number,numTemp1,
--              deal_base_currency, 0,
--              0, (numPandL - numIntoutlay), 'Deal Reversal No: ' ||
--              deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
--              (select lbnk_account_number
--                from trmaster306
--                where lbnk_pick_code = deal_counter_party)
--              from trtran001
--              where deal_deal_number = varDealReference
--              and deal_serial_number = 1;  
--              
--          else
--            varVoucher := NULL;
--          end if;
--          
--      elsif numAction = GConst.EDITSAVE then
--        if numRecordStatus = 1 then
--           varOperation := 'Inserting Hedge Deal Delivery';
--          insert into trtran006(cdel_company_code, cdel_deal_number,
--            cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
--            cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
--            cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
--            cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
--            cdel_entry_detail, cdel_record_status, cdel_trade_reference,
--            Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
--            cdel_spot_rate,cdel_forward_rate,cdel_margin_rate,CDEL_DELIVERY_SERIAL,cdel_int_outlay,cdel_intoutlay_rate)
--            select deal_company_code, deal_deal_number,
--            deal_serial_number,
--            (select NVL(max(cdel_reverse_serial),0) + 1
--              from trtran006
--              where cdel_deal_number = varDealReference),
--            datWorkdate, deal_hedge_trade, Gconst.Dealdelivery,
--            numReverseAmount, numFinal, Round(numReverseAmount * numFinal), 1,
--            Round(numReverseAmount * numFinal), to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--            SYSDATE, NULL, Gconst.Statusentry, varTradeReference, numTradeSerial,
--            numPandL,varVoucher ,numSpot,numPremium,numMargin,numSerial,numIntoutlay,numintOutlayRate
--            from trtran001
--            where deal_deal_number = varDealReference;
--            
--            varOperation := 'Inserting Hedge Deal Delivery after insert';
--          numError := fncCompleteUtilization(varDealReference,GConst.UTILHEDGEDEAL,datWorkDate);
--          varOperation := 'Inserting Hedge Deal Delivery after fncCompleteUtilization';  
--          
--          if numPandL != 0 then
--              select CDEL_REVERSE_SERIAL into numTemp1
--                from trtran006
--              where cdel_deal_number = varDealReference
--                    and cdel_trade_reference = varTradeReference
--                    and Cdel_Trade_Serial = numTradeSerial;
--            varOperation := 'Inserting C/A voucher for PL';
--            
--            varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--            
--            insert into trtran008 (bcac_company_code, bcac_location_code,
--              bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--              bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--              bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--              bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--              bcac_create_date, bcac_local_merchant, bcac_record_status,
--              bcac_record_type, bcac_account_number)
--            select numCompany, deal_location_code, deal_counter_party, varVoucher,
--              deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
--              GConst.TRANSACTIONCREDIT),24900049,24800051,
--              deal_deal_number,numTemp1,
--              deal_base_currency, 0,
--              0, numPandL, 'Deal Reversal No: ' ||
--              deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
--              (select lbnk_account_number
--                from trmaster306
--                where lbnk_pick_code = deal_counter_party)
--              from trtran001
--              where deal_deal_number = varDealReference
--              and deal_serial_number = 1; 
--              
--            varOperation := 'Inserting Interest Outlay voucher for PL' || numIntoutlay;   
--            if numIntoutlay <> 0 then
--              varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--              insert into trtran008 (bcac_company_code, bcac_location_code,
--                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                bcac_create_date, bcac_local_merchant, bcac_record_status,
--                bcac_record_type, bcac_account_number)
--              select numCompany, deal_location_code, deal_counter_party, varVoucher,
--                deal_maturity_date, GConst.TRANSACTIONDEBIT,24900079,24800057,
--                deal_deal_number,numTemp1, 
--                deal_base_currency, 0,
--                0, numIntoutlay, 'Deal Reversal No: ' ||
--                deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
--                (select lbnk_account_number
--                  from trmaster306
--                  where lbnk_pick_code = deal_counter_party)
--                from trtran001
--                where deal_deal_number = varDealReference
--                and deal_serial_number = 1;   
--            end if;              
--            varOperation := 'Inserting C/A voucher for PL' || numIntoutlay;  
--            
--            varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--            insert into trtran008 (bcac_company_code, bcac_location_code,
--              bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--              bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--              bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--              bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--              bcac_create_date, bcac_local_merchant, bcac_record_status,
--              bcac_record_type, bcac_account_number)
--            select numCompany, deal_location_code, deal_counter_party, varVoucher,
--              deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONCREDIT,
--              GConst.TRANSACTIONDEBIT),24900030,24800051,
--              deal_deal_number,numTemp1,
--              deal_base_currency, 0,
--              0, (numPandL - numIntoutlay), 'Deal Reversal No: ' ||
--              deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
--              (select lbnk_account_number
--                from trmaster306
--                where lbnk_pick_code = deal_counter_party)
--              from trtran001
--              where deal_deal_number = varDealReference
--              and deal_serial_number = 1;  
--              
--          else
--            varVoucher := NULL;
--          end if;
--        elsif  numRecordStatus = 2 then
----            SELECT CDEL_DEAL_NUMBER,CDEL_REVERSE_SERIAL INTO varReference,numRefSerial FROM TRTRAN006,TRTRAN001
----              WHERE CDEL_TRADE_REFERENCE = varTradeReference  AND CDEL_TRADE_SERIAL = numTradeSerial
----              AND CDEL_DEAL_NUMBER = DEAL_DEAL_NUMBER AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
----              AND DEAL_DEAL_TYPE != 25400001
----              AND CDEL_REVERSE_SERIAL = numRevSerial
----              AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
--          if numPandL != 0 then
--              SELECT NVL(COUNT(*),0) INTO numRefSerial FROM TRTRAN008  WHERE BCAC_VOUCHER_REFERENCE = varDealReference
--                                                                  AND BCAC_REFERENCE_SERIAL = numRevSerial
--                                                                  AND BCAC_RECORD_STATUS BETWEEN 10200001 AND 10200004;
--              IF numRefSerial > 0 THEN
--              ----Currenct account entry Update
--                UPDATE TRTRAN008 SET BCAC_VOUCHER_INR = (numPandL - numIntoutlay),
--                                    BCAC_RECORD_STATUS = 10200004 WHERE BCAC_VOUCHER_REFERENCE = varDealReference
--                                                                    AND BCAC_REFERENCE_SERIAL = numRevSerial
--                                                                    AND BCAC_ACCOUNT_HEAD = 24900030
--                                                                    AND BCAC_RECORD_STATUS BETWEEN 10200001 AND 10200004;
--                ---Proft loss head entry update                                                    
--                UPDATE TRTRAN008 SET BCAC_VOUCHER_INR = numPandL,
--                                    BCAC_RECORD_STATUS = 10200004 WHERE BCAC_VOUCHER_REFERENCE = varDealReference
--                                                                    AND BCAC_REFERENCE_SERIAL = numRevSerial
--                                                                    AND BCAC_ACCOUNT_HEAD = 24900049
--                                                                    AND BCAC_RECORD_STATUS BETWEEN 10200001 AND 10200004;
--                ---Interest Outlay Entry Update                                                    
--                UPDATE TRTRAN008 SET BCAC_VOUCHER_INR = numIntoutlay,
--                                    BCAC_RECORD_STATUS = 10200004 WHERE BCAC_VOUCHER_REFERENCE = varDealReference
--                                                                    AND BCAC_REFERENCE_SERIAL = numRevSerial
--                                                                    AND BCAC_ACCOUNT_HEAD = 24900079
--                                                                    AND BCAC_RECORD_STATUS BETWEEN 10200001 AND 10200004;                                                                    
--              ELSE
--                select CDEL_REVERSE_SERIAL into numTemp1
--                  from trtran006
--                where cdel_deal_number = varDealReference
--                      and cdel_trade_reference = varTradeReference
--                      and Cdel_Trade_Serial = numTradeSerial;
--                
--                varOperation := 'Inserting Currenct Account voucher for PL';
--                varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--                insert into trtran008 (bcac_company_code, bcac_location_code,
--                  bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                  bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                  bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                  bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                  bcac_create_date, bcac_local_merchant, bcac_record_status,
--                  bcac_record_type, bcac_account_number)
--                select numCompany, deal_location_code, deal_counter_party, varVoucher,
--                  deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
--                  GConst.TRANSACTIONCREDIT),24900049,24800051,
--                  deal_deal_number,numTemp1,
--                  deal_base_currency, 0,
--                  0, numPandL, 'Deal Reversal No: ' ||
--                  deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
--                  (select lbnk_account_number
--                    from trmaster306
--                    where lbnk_pick_code = deal_counter_party)
--                  from trtran001
--                  where deal_deal_number = varDealReference
--                  and deal_serial_number = 1;    
--                if numIntoutlay <> 0 then
--                  varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--                  insert into trtran008 (bcac_company_code, bcac_location_code,
--                    bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                    bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                    bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                    bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                    bcac_create_date, bcac_local_merchant, bcac_record_status,
--                    bcac_record_type, bcac_account_number)
--                  select numCompany, deal_location_code, deal_counter_party, varVoucher,
--                    deal_maturity_date, GConst.TRANSACTIONDEBIT,24900079,24800057,
--                    deal_deal_number,numTemp1, 
--                    deal_base_currency, 0,
--                    0, numIntoutlay, 'Deal Reversal No: ' ||
--                    deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
--                    (select lbnk_account_number
--                      from trmaster306
--                      where lbnk_pick_code = deal_counter_party)
--                    from trtran001
--                    where deal_deal_number = varDealReference
--                    and deal_serial_number = 1;   
--                end if;                  
--                varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--                insert into trtran008 (bcac_company_code, bcac_location_code,
--                  bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                  bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                  bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                  bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                  bcac_create_date, bcac_local_merchant, bcac_record_status,
--                  bcac_record_type, bcac_account_number)
--                select numCompany, deal_location_code, deal_counter_party, varVoucher,
--                  deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONCREDIT,
--                  GConst.TRANSACTIONDEBIT),24900030,24800051,
--                  deal_deal_number,numTemp1,
--                  deal_base_currency, 0,
--                  0, (numPandL -numIntoutlay), 'Deal Reversal No: ' ||
--                  deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
--                  (select lbnk_account_number
--                    from trmaster306
--                    where lbnk_pick_code = deal_counter_party)
--                  from trtran001
--                  where deal_deal_number = varDealReference
--                  and deal_serial_number = 1;                
--              END IF;
--          end if;
--          UPDATE TRTRAN006 SET CDEL_CANCEL_AMOUNT = numReverseAmount,
--                               CDEL_CANCEL_RATE = numFinal,
--                               CDEL_PROFIT_LOSS = numPandL,
--                               CDEL_FORWARD_RATE = numPremium,
--                               CDEL_INT_OUTLAY = numIntoutlay,
--                               cdel_intoutlay_rate = numintOutlayRate,
--                               CDEL_RECORD_STATUS = 10200004 WHERE CDEL_TRADE_REFERENCE = varTradeReference  
--                                                                AND CDEL_TRADE_SERIAL = numTradeSerial
--                                                                AND CDEL_DEAL_NUMBER = varDealReference
--                                                                AND CDEL_REVERSE_SERIAL = numRevSerial
--                                                                AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
--          numError := fncCompleteUtilization(varDealReference,GConst.UTILHEDGEDEAL,datWorkDate);
--        elsif  numRecordStatus = 3 then
----            SELECT CDEL_DEAL_NUMBER,CDEL_REVERSE_SERIAL INTO varReference,numRefSerial FROM TRTRAN006,TRTRAN001
----              WHERE CDEL_TRADE_REFERENCE = varTradeReference  AND CDEL_TRADE_SERIAL = numTradeSerial
----              AND CDEL_DEAL_NUMBER = DEAL_DEAL_NUMBER AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
----              AND DEAL_DEAL_TYPE != 25400001
----              AND CDEL_REVERSE_SERIAL = numRevSerial
----              AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
--          UPDATE TRTRAN008 SET BCAC_RECORD_STATUS = 10200006 WHERE BCAC_VOUCHER_REFERENCE = varDealReference
--                                                                  AND BCAC_REFERENCE_SERIAL = numRevSerial;
--          UPDATE TRTRAN006 SET CDEL_RECORD_STATUS = 10200006 WHERE CDEL_TRADE_REFERENCE = varTradeReference  
--                                                                AND CDEL_TRADE_SERIAL = numTradeSerial
--                                                                AND CDEL_DEAL_NUMBER = varDealReference
--                                                                AND CDEL_REVERSE_SERIAL = numRevSerial                                                                
--                                                                AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
--          numError := fncCompleteUtilization(varDealReference,GConst.UTILHEDGEDEAL,datWorkDate);        
--        end if;
--      elsif numAction = GConst.DELETESAVE then
----            SELECT CDEL_DEAL_NUMBER,CDEL_REVERSE_SERIAL INTO varReference,numRefSerial FROM TRTRAN006,TRTRAN001
----              WHERE CDEL_TRADE_REFERENCE = varTradeReference  AND CDEL_TRADE_SERIAL = numTradeSerial
----              AND CDEL_DEAL_NUMBER = DEAL_DEAL_NUMBER AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
----              AND DEAL_DEAL_TYPE != 25400001
----              AND CDEL_REVERSE_SERIAL = numRevSerial              
----              AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
--          UPDATE TRTRAN008 SET BCAC_RECORD_STATUS = 10200006 WHERE BCAC_VOUCHER_REFERENCE = varDealReference
--                                                                AND BCAC_REFERENCE_SERIAL = numRevSerial;
--          UPDATE TRTRAN006 SET CDEL_RECORD_STATUS = 10200006 WHERE CDEL_TRADE_REFERENCE = varTradeReference  
--                                                                AND CDEL_TRADE_SERIAL = numTradeSerial
--                                                                AND CDEL_DEAL_NUMBER = varDealReference
--                                                                AND CDEL_REVERSE_SERIAL = numRevSerial                                                                
--                                                                AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
--          numError := fncCompleteUtilization(varDealReference,GConst.UTILHEDGEDEAL,datWorkDate);  
--          
--      elsif numAction = GConst.CONFIRMSAVE then
--          UPDATE TRTRAN008 SET BCAC_RECORD_STATUS = 10200003 WHERE BCAC_VOUCHER_REFERENCE = varDealReference
--                                                                AND BCAC_REFERENCE_SERIAL = numRevSerial;
--          UPDATE TRTRAN006 SET CDEL_RECORD_STATUS = 10200003 WHERE CDEL_TRADE_REFERENCE = varTradeReference  
--                                                                AND CDEL_TRADE_SERIAL = numTradeSerial
--                                                                AND CDEL_DEAL_NUMBER = varDealReference
--                                                                AND CDEL_REVERSE_SERIAL = numRevSerial                                                                
--                                                                AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
--                                                                
--      end if;
--      End Loop;
--<<Cash_Deal>>
--        if numAction = GConst.ADDSAVE then
--          if numCashDeal > 0 then
--            varOperation := 'Inserting Cash Deal';
--            varDealReference := varCompany || '/FWD/' || GConst.fncGenerateSerial(Gconst.SERIALDEAL,numCompany);
--            insert into trtran001
--              (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
--              deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
--              deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
--              deal_confirm_date,deal_holding_rate,deal_holding_rate1,deal_dealer_holding,deal_dealer_holding1,deal_dealer_remarks,deal_time_stamp,
--              deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
--              deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,cdel_forward_rate,
--              cdel_spot_rate,cdel_margin_rate,deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
--              deal_bo_remark,deal_analysis_option,deal_analysis_type,deal_analysis_frequency,deal_analysis_selection)
--            values ( numCompany, varDealReference, 1, datWorkDate, 26000001,numBuySell,
--              25200002,25400001,NumLocalBank,numCurrencyCode, 30400003,numCashRate, 1, numCashDeal,
--              Round(numCashRate * numCashDeal),0,0,datWorkDate,datWorkDate,null, 'System',
--              NULL, 0,0,0,0,varTradeReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--              to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,sysdate,NULL, 10200001,
--              null,null,null,0,numCashRate,0, 0,
--              0,0,33399999,0,0,33899999, NULL,
--              'Cash Delivery ' || varTradeReference,null,null,null,null);
--  
--            varOperation := 'Inserting Cash Deal Cancellation';
--            insert into trtran006
--              (cdel_company_code,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
--              cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
--              cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
--              cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
--              cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
--              cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark)
--            select deal_company_code, deal_deal_number, 1, 1, varTradeReference, numTradeSerial,
--              datWorkDate, 26000001,27000002,deal_base_amount, deal_exchange_rate, deal_other_amount, 0,
--              0,0,0,0,0,0,'System',varTradeReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), sysdate,
--              null, 10200001, null,null,numSerial,0,deal_exchange_rate,0,0,0,33500001,null,null,deal_bank_reference,
--              deal_bo_remark
--              from trtran001
--              where deal_deal_number = varDealReference;
--        
--  --         begin 
--  --           select nvl(HEDG_TRADE_SERIAL,1) +1
--  --           into  numserial 
--  --            from trtran004 
--  --            where hedg_trade_reference=varTradeReference;
--  --         exception 
--  --           when no_data_found then
--  --             numserial:=1;
--  --         end ;
--  --          varOperation := 'Inserting Hedge record';
--  --          insert into trtran004
--  --          (hedg_company_code,hedg_trade_reference,hedg_deal_number,
--  --            hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
--  --            hedg_create_date,hedg_entry_detail,hedg_record_status,
--  --            hedg_hedging_with,hedg_multiple_currency,HEDG_TRADE_SERIAL)
--  --          values(numCompany,varTradeReference,varDealReference,
--  --          1, numCashDeal,0, Round(numCashDeal * numCashRate),
--  --          sysdate,NULL,10200012, 32200001,12400002,numserial);
--  
--        End if;
--        INSERT INTO TRTRAN003
--        (BREL_COMPANY_CODE, BREL_TRADE_REFERENCE,BREL_REVERSE_SERIAL,BREL_ENTRY_DATE,BREL_USER_REFERENCE,
--        BREL_REFERENCE_DATE,BREL_REVERSAL_TYPE,BREL_REVERSAL_FCY,BREL_REVERSAL_RATE,BREL_REVERSAL_INR,
--        BREL_PERIOD_CODE,BREL_TRADE_PERIOD,BREL_MATURITY_FROM,BREL_MATURITY_DATE,BREL_CREATE_DATE,
--        BREL_ENTRY_DETAIL,BREL_RECORD_STATUS,BREL_LOCAL_BANK,BREL_REVERSE_REFERENCE,BREL_LOCATION_CODE)
--        SELECT numCompany,varTradeReference,numTradeSerial,SYSDATE,'Exposure Settlement',datReference,
--        25899999,numCashDeal+numDealReverse,numCashRate,numCashRate*(numCashDeal+numDealReverse),0,
--        0,sysdate,sysdate,sysdate,null,10200001,NumLocalBank,null,numLocation from dual;
--      ELSif numAction = GConst.EDITSAVE then
--      begin
--        SELECT CDEL_DEAL_NUMBER INTO varReference FROM TRTRAN006,TRTRAN001
--        WHERE CDEL_TRADE_REFERENCE = varTradeReference  
--        AND CDEL_TRADE_SERIAL = numTradeSerial
--        AND CDEL_DEAL_NUMBER = DEAL_DEAL_NUMBER AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
--        AND DEAL_DEAL_TYPE = 25400001
--        AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
--        UPDATE TRTRAN006 SET CDEL_CANCEL_AMOUNT = numCashDeal,
--                             CDEL_CANCEL_RATE = numCashRate,
--                             CDEL_SPOT_RATE = numCashRate,
--                             CDEL_RECORD_STATUS = 10200004 WHERE CDEL_DEAL_NUMBER = varReference;
--        UPDATE TRTRAN001 SET DEAL_BASE_AMOUNT = numCashDeal,
--                             DEAL_EXCHANGE_RATE = numCashRate,
--                             DEAL_SPOT_RATE = numCashRate,
--                             DEAL_RECORD_STATUS = 10200004 WHERE DEAL_DEAL_NUMBER = varReference;
--        UPDATE TRTRAN003 SET BREL_REVERSAL_FCY = (numCashDeal+numDealReverse),
--                             BREL_REVERSAL_RATE = numCashRate,
--                             BREL_RECORD_STATUS = 10200004 WHERE BREL_TRADE_REFERENCE = varTradeReference
--                                                               AND  BREL_REVERSE_SERIAL = numTradeSerial;
--        exception
--        when no_data_found then 
--          if numCashDeal > 0 then
--            varOperation := 'Inserting Cash Deal';
--            varDealReference := varCompany || '/FWD/' || GConst.fncGenerateSerial(Gconst.SERIALDEAL,numCompany);
--            insert into trtran001
--              (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
--              deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
--              deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
--              deal_confirm_date,deal_holding_rate,deal_holding_rate1,deal_dealer_holding,deal_dealer_holding1,deal_dealer_remarks,deal_time_stamp,
--              deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
--              deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,cdel_forward_rate,
--              cdel_spot_rate,cdel_margin_rate,deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
--              deal_bo_remark,deal_analysis_option,deal_analysis_type,deal_analysis_frequency,deal_analysis_selection)
--            values ( numCompany, varDealReference, 1, datWorkDate, 26000001,numBuySell,
--              25200002,25400001,NumLocalBank,numCurrencyCode, 30400003,numCashRate, 1, numCashDeal,
--              Round(numCashRate * numCashDeal),0,0,datWorkDate,datWorkDate,null, 'System',
--              NULL, 0,0,0,0,varTradeReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--              to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,sysdate,NULL, 10200001,
--              null,null,null,0,numCashRate,0, 0,
--              0,0,33399999,0,0,33899999, NULL,
--              'Cash Delivery ' || varTradeReference,null,null,null,null);
--  
--            varOperation := 'Inserting Cash Deal Cancellation';
--            insert into trtran006
--              (cdel_company_code,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
--              cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
--              cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
--              cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
--              cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
--              cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark)
--            select deal_company_code, deal_deal_number, 1, 1, varTradeReference, numTradeSerial,
--              datWorkDate, 26000001,27000002,deal_base_amount, deal_exchange_rate, deal_other_amount, 0,
--              0,0,0,0,0,0,'System',varTradeReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), sysdate,
--              null, 10200001, null,null,numSerial,0,deal_exchange_rate,0,0,0,33500001,null,null,deal_bank_reference,
--              deal_bo_remark
--              from trtran001
--              where deal_deal_number = varDealReference;
--        End if;
--        INSERT INTO TRTRAN003
--        (BREL_COMPANY_CODE, BREL_TRADE_REFERENCE,BREL_REVERSE_SERIAL,BREL_ENTRY_DATE,BREL_USER_REFERENCE,
--        BREL_REFERENCE_DATE,BREL_REVERSAL_TYPE,BREL_REVERSAL_FCY,BREL_REVERSAL_RATE,BREL_REVERSAL_INR,
--        BREL_PERIOD_CODE,BREL_TRADE_PERIOD,BREL_MATURITY_FROM,BREL_MATURITY_DATE,BREL_CREATE_DATE,
--        BREL_ENTRY_DETAIL,BREL_RECORD_STATUS,BREL_LOCAL_BANK,BREL_REVERSE_REFERENCE,BREL_LOCATION_CODE)
--        SELECT numCompany,varTradeReference,numTradeSerial,SYSDATE,'Exposure Settlement',datReference,
--        25899999,numCashDeal+numDealReverse,numCashRate,numCashRate*(numCashDeal+numDealReverse),0,
--        0,sysdate,sysdate,sysdate,null,10200001,NumLocalBank,null,numLocation from dual; 
--      end;  
--      ELSif numAction = GConst.DELETESAVE then
--
--        SELECT CDEL_DEAL_NUMBER INTO varReference FROM TRTRAN006,TRTRAN001
--        WHERE CDEL_TRADE_REFERENCE = varTradeReference  
--        AND CDEL_TRADE_SERIAL = numTradeSerial
--        AND CDEL_DEAL_NUMBER = DEAL_DEAL_NUMBER AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
--        AND DEAL_DEAL_TYPE = 25400001
--        AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
--        UPDATE TRTRAN006 SET CDEL_RECORD_STATUS = 10200006 WHERE CDEL_DEAL_NUMBER = varReference;
--        UPDATE TRTRAN001 SET DEAL_RECORD_STATUS = 10200006 WHERE DEAL_DEAL_NUMBER = varReference;
--        UPDATE TRTRAN003 SET BREL_RECORD_STATUS = 10200006 WHERE BREL_TRADE_REFERENCE = varTradeReference
--                                                               AND  BREL_REVERSE_SERIAL = numTradeSerial;
--      end if;
--      return numError;
--Exception
--        When others then
--          numError := SQLCODE;
--          varError := SQLERRM;
--          varError := GConst.fncReturnError('BillSettle', numError, varMessage,
--                          varOperation, varError);
--          raise_application_error(-20101, varError);
--          RETURN numError;
--End forwardSettlement;

Function forwardSettlement
    (   RecordDetail in GConst.gClobType%Type)
    return number
    is
--  created by TMM on 31/01/2014
    numError            number;
    numTemp             number;
    numAction           number(4);
    numSerial           number(5):=0;
    numLocation         number(8);
    numCompany          number(8);
    numReversal         number(8);
    numImportExport     number(8);    
    numReverseAmount    number(15,2);
    numDealReverse      number(15,2);
    numBillReverse      number(15,2);
    numCashDeal         number(15,2);
    numPandL            number(15,2);
    numFcy              number(15,2);
    numSpot             number(15,6);
    numPremium          number(15,6);
    numMargin           number(15,6);
    numFinal            number(15,6);
    numCashRate         number(15,6);
    varCompany          varchar2(15);
    varEntity           varchar2(25);
    varVoucher          varchar2(25);
    varTradeReference   varchar2(25);
    varDealReference    varchar2(25);
    varReference        varchar2(25);
    varXPath            varchar2(1024);
    varTemp             varchar2(1024);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    datWorkDate         Date;
    datReference        Date;
    xmlTemp             xmlType;
    nlsTemp             xmlDom.DomNodeList;
    nodFinal            xmlDom.domNode;
    docFinal            xmlDom.domDocument;
    nodTemp             xmlDom.domNode;
    nodTemp1            xmlDom.domNode;
    nmpTemp             xmldom.domNamedNodemap;
    numLocalBank        number(8);
    numCompanyCode      number(8);
    numReverseSerial    number(5);
    numCurrencyCode     NUMBER(8);
    numTradeSerial      NUMBER(5):=0;
    userID              varchar2(15);
    numBuySell          number(8);
    numLOBCode          number(8);
    numRecordStatus     number(1);
    numRefSerial        number(5);
    numRevSerial        number(5);
    numTemp1            number(5):= 0;
    numintOutlayRate    number(15,6);
    numIntoutlay        number(15,2);
    clbTemp             clob;
   

  Begin
    varMessage := 'Entering Bill Settlement Process';
    numError := 0;
    numDealReverse := 0;
    numBillReverse := 0;
    numCashDeal := 0;


    varOperation := 'Extracting Parameters';
    xmlTemp := xmlType(RecordDetail);
    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
    Numlocation := Gconst.Fncxmlextract(Xmltemp, 'LocationId', Numlocation);
    userID      := GConst.fncXMLExtract(xmlTemp, 'UserCode', userID);
    numCompany := GConst.fncXMLExtract(xmlTemp, 'CompanyId', numCompany);
    varEntity :=  gconst.fncxmlextract(xmltemp, 'CommandSet/Entity', varEntity);


--        numCashRate :=  gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/CashRate', numCashRate);
--        numCashDeal :=  gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/CashAmount', numCashDeal); 
--        datReference := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/ReferenceDate', datReference);  -- Pass this value from XML
--        numBuySell := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/BuySell', numBuySell);  -- Pass this value from XML
--        numLocalBank := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/BankCode', numLocalBank); 
--        numCurrencyCode := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/CurrencyCode', numCurrencyCode); 
--        numLOBCode := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/LobCode', numLOBCode); 
--        varTradeReference := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/TradeReference', varTradeReference); 
--    END IF;
 
         varOperation := 'Extracting Parameters CurrencyCode ' || numCurrencyCode;
        if varEntity = 'BILLREALISATION' then -- LOB code will comming in Main XML only
          numLOBCode := gconst.fncxmlextract(xmltemp, 'BNKC_LOB_CODE', numLOBCode);
          numTradeSerial := gconst.fncxmlextract(xmltemp, 'BREL_REALIZATION_NUMBER', numTradeSerial);
          varTradeReference := gconst.fncxmlextract(xmltemp, 'BREL_INVOICE_NUMBER', varTradeReference);
        elsif varEntity = 'IMPORTREALIZE' then
          numLOBCode := gconst.fncxmlextract(xmltemp, 'SPAY_LOB_CODE', numLOBCode);
          numTradeSerial := gconst.fncxmlextract(xmltemp, 'SPAY_SHIPMENT_SERIAL', numTradeSerial);
          varTradeReference := gconst.fncxmlextract(xmltemp, 'SPAY_SHIPMENT_NUMBER', varTradeReference);
        elsif varEntity = 'IMPORTADVICE' then
          numLOBCode := gconst.fncxmlextract(xmltemp, 'IADP_LOB_CODE', numLOBCode);
          numTradeSerial := 0;
          varTradeReference := gconst.fncxmlextract(xmltemp, 'IADP_ADVANCE_REFERENCE', varTradeReference);
         elsif varEntity = 'LOANCLOSURE' then
          numLOBCode := gconst.fncxmlextract(xmltemp, 'INTC_LOB_CODE', numLOBCode);
          numTradeSerial := gconst.fncxmlextract(xmltemp, 'INTC_INTEREST_NUMBER', numTradeSerial);
          varTradeReference := gconst.fncxmlextract(xmltemp, 'INTC_LOAN_REFERENCE', varTradeReference);
        elsif varEntity = 'PSCFCLOAN' then 
          numLOBCode := gconst.fncxmlextract(xmltemp, 'INLN_LOB_CODE', numLOBCode);
          numTradeSerial := gconst.fncxmlextract(xmltemp, 'INLN_PSLOAN_NUMBER', numTradeSerial);
          varTradeReference := gconst.fncxmlextract(xmltemp, 'INLN_INVOICE_NUMBER', varTradeReference);
        elsif varEntity = 'PACKINGCREDITAPPLICATION' then 
          numLOBCode := gconst.fncxmlextract(xmltemp, 'PKCR_LOB_CODE', numLOBCode);
          numTradeSerial := 0;
          varTradeReference := gconst.fncxmlextract(xmltemp, 'PKCR_PKGCREDIT_NUMBER', varTradeReference);     
        elsif varEntity = 'FOREIGNREMITTANCE' then 
          numLOBCode := gconst.fncxmlextract(xmltemp, 'REMT_LOB_CODE', numLOBCode);
          numTradeSerial := 0;
          varTradeReference := gconst.fncxmlextract(xmltemp, 'REMT_REMITTANCE_REFERENCE', varTradeReference);   
        elsif varEntity = 'EXPORTADVANCE' then 
          numLOBCode := gconst.fncxmlextract(xmltemp, 'EADV_LOB_CODE', numLOBCode);
          Numtradeserial := 0;
          Vartradereference := Gconst.Fncxmlextract(Xmltemp, 'EADV_ADVANCE_REFERENCE', Vartradereference);  
        elsif varEntity = 'IRSSETTLEMENT' then 
         -- numLOBCode := gconst.fncxmlextract(xmltemp, 'EADV_LOB_CODE', numLOBCode);
          Numtradeserial := Gconst.Fncxmlextract(Xmltemp, 'IIRM_LEG_SERIAL', Numtradeserial);
          Vartradereference := Gconst.Fncxmlextract(Xmltemp, 'IIRM_IRS_NUMBER', Vartradereference);
          If Numaction=Gconst.Editsave Then
              numAction:=GConst.ADDSAVE ;
              end if;
        end if;

    docFinal := xmlDom.newDomDocument(xmlTemp);
    nodFinal := xmlDom.makeNode(docFinal);          
    varXPath := '//FORWARDSETTLEMENTS/CASHSETTLEMENT';
    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
    if xmlDom.getLength(nlsTemp) > 0 then

        numCashRate :=  gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/CashRate', numCashRate);
        numCashDeal :=  gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/CashAmount', numCashDeal); 
        datReference := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/ReferenceDate', datReference);  -- Pass this value from XML
        numBuySell := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/BuySell', numBuySell);  -- Pass this value from XML
        numLocalBank := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/BankCode', numLocalBank); 
        numCurrencyCode := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/CurrencyCode', numCurrencyCode); 
        --numLOBCode := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/LobCode', numLOBCode); 
       -- varTradeReference := gconst.fncxmlextract(xmltemp, 'FORWARDSETTLEMENTS/CASHSETTLEMENT/TradeReference', varTradeReference); 
        
        --end loop;
        

        insert into temp values(numBuySell,'chandra1');
        insert into temp values(numLocalBank,'chandra2');
        varOperation := 'Extracting Parameters Location ' || numLocation;
--        numLocation := nvl(himatsingkatf_prod.PKGTREASURY.GetTreasuryCode(numLocation),0);--Mapping Required in Trade finance
--            varOperation := 'Extracting Parameters numCompany ' || numCompany;
--        numCompany := himatsingkatf_prod.PKGTREASURY.GetTreasuryCode(numCompany);
--        varOperation := 'Extracting Parameters numBuySell ' || numBuySell;
--        numBuySell := himatsingkatf_prod.PKGTREASURY.GetTreasuryCode(numBuySell);
--        numLocalBank := himatsingkatf_prod.PKGTREASURY.GetTreasuryCode(numLocalBank);
--        varOperation := 'Extracting Parameters numCurrencyCode ' || numCurrencyCode;
--        numCurrencyCode := himatsingkatf_prod.PKGTREASURY.GetTreasuryCode(numCurrencyCode);
--        varOperation := 'Extracting Parameters numLOBCode ' || numLOBCode;
--        numLOBCode := nvl(himatsingkatf_prod.PKGTREASURY.GetTreasuryCode(numLOBCode),0);--Mapping Required in Trade finance
        varCompany := PKGRETURNCURSOR.fncGetdescription(numCompany,2);
--        docFinal := xmlDom.newDomDocument(xmlTemp);
--        nodFinal := xmlDom.makeNode(docFinal);
        varOperation := 'Checking for Deal Delivery, if any';
        Varxpath := '//FORWARDSETTLEMENTS/FORWARDSETTLEMENT/ROW[@NUM]';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        if xmlDom.getLength(nlsTemp) = 0 then
          GOto Cash_Deal;
        END IF;
    end if;
    
   insert into temp values(varXPath,'chandra');
    Varxpath := '//FORWARDSETTLEMENTS/FORWARDSETTLEMENT/ROW[@NUM]';
   Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
      Varxpath := '//FORWARDSETTLEMENTS/FORWARDSETTLEMENT/ROW[@NUM="';
      insert into temp values(varXPath,'chandra');
    for numSub in 0..xmlDom.getLength(nlsTemp) -1
      Loop
        nodTemp := xmlDom.item(nlsTemp, numSub);
        nmpTemp := xmlDom.getAttributes(nodTemp);
        nodTemp1 := xmlDom.item(nmpTemp, 0);
        numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
        varTemp := varXPath || numTemp || '"]/DealNumber';
        varDealReference := GConst.fncGetNodeValue(nodFinal, varTemp);
        varTemp := varXPath || numTemp || '"]/SpotRate';
        numSpot := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
        varTemp := varXPath || numTemp || '"]/Premium';
        numPremium := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || numTemp || '"]/MarginRate';
        numMargin := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || numTemp || '"]/FinalRate';
        numFinal := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
        varTemp := varXPath || numTemp || '"]/ReverseAmount';
        numReverseAmount := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || numTemp || '"]/RecordStatus';
        numRecordStatus := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || numTemp || '"]/ReverseSerial';
        numRevSerial := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

        varTemp := varXPath || numTemp || '"]/IntoutlayRate';
        numintOutlayRate := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || numTemp || '"]/IntOutply';

        numIntoutlay := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        numDealReverse := numDealReverse + numReverseAmount;
        insert into temp values(numFinal,numReverseAmount);
            varOperation := 'Before Select ';
        IF numAction  IN(GConst.ADDSAVE, GConst.EDITSAVE) THEN
          select
            case
            when datWorkDate < deal_maturity_date and deal_forward_rate != numPremium then
              round(numReverseAmount * (deal_forward_rate - numPremium))
            when numFinal != deal_exchange_rate then
              decode(deal_buy_sell, GConst.PURCHASEDEAL,
                Round(numReverseAmount * deal_exchange_rate) - Round(numReverseAmount * numFinal),
                Round(numReverseAmount * numFinal) - Round(numReverseAmount * deal_exchange_rate))
            else 0
            end
            into numPandL
            from trtran001
            where deal_deal_number = varDealReference
             and Deal_Record_status not in (10200005,10200006);
         End If;    
           varOperation := 'After  Select '|| numAction || varDealReference;
        if numAction = GConst.ADDSAVE then
          varOperation := 'Inserting Hedge Deal Delivery';
          insert into trtran006(cdel_company_code, cdel_deal_number,
            cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
            cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
            cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
            cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
            cdel_entry_detail, cdel_record_status, cdel_trade_reference,
            Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
            cdel_spot_rate,cdel_forward_rate,cdel_margin_rate,CDEL_DELIVERY_SERIAL,cdel_int_outlay,cdel_intoutlay_rate)
            select deal_company_code, deal_deal_number,
            deal_serial_number,
            (select NVL(max(cdel_reverse_serial),0) + 1
              from trtran006
              where cdel_deal_number = varDealReference),
            datWorkdate, deal_hedge_trade, Gconst.Dealdelivery,
            numReverseAmount, numFinal, Round(numReverseAmount * numFinal), 1,
            Round(numReverseAmount * numFinal), to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
            SYSDATE, NULL, Gconst.Statusentry, varTradeReference, numTradeSerial,
            Numpandl,Varvoucher ,Numspot,Numpremium,Nummargin,Numserial,Numintoutlay,Numintoutlayrate
            from trtran001
            Where Deal_Deal_Number = Vardealreference;
          varOperation := 'After  Insert into 001 ' || varDealReference;
          Numerror := Fnccompleteutilization(Vardealreference,Gconst.Utilhedgedeal,Datworkdate);
          Varoperation := 'After  Process Complete ' || Vardealreference;
          If Numpandl != 0 Then
          varOperation := 'Checking for pandl ' || varDealReference || Numpandl;
              select CDEL_REVERSE_SERIAL into numTemp1
                From Trtran006
              where cdel_deal_number = varDealReference
                    and cdel_trade_reference = varTradeReference
                    and Cdel_Trade_Serial = numTradeSerial;

            varOperation := 'Inserting Current Account voucher for PL';
            varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
            insert into trtran008 (bcac_company_code, bcac_location_code,
              bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
              bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
              bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
              bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
              bcac_create_date, bcac_local_merchant, bcac_record_status,
              bcac_record_type, bcac_account_number)
            select numCompany, deal_location_code, deal_counter_party, varVoucher,
              deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
              GConst.TRANSACTIONCREDIT),24900049,24800051,
              deal_deal_number,numTemp1, 
              deal_base_currency, 0,
              0, numPandL, 'Deal Reversal No: ' ||
              deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
              (select lbnk_account_number
                from trmaster306
                where lbnk_pick_code = deal_counter_party)
              from trtran001
              where deal_deal_number = varDealReference
              and deal_serial_number = 1;    
            varOperation := 'Inserting INterest OutLay';
            if numIntoutlay <> 0 then
              varOperation := 'Inserting INterest OutLay';
              varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
              insert into trtran008 (bcac_company_code, bcac_location_code,
                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                bcac_create_date, bcac_local_merchant, bcac_record_status,
                bcac_record_type, bcac_account_number)
              select numCompany, deal_location_code, deal_counter_party, varVoucher,
                deal_maturity_date, GConst.TRANSACTIONDEBIT,24900079,24800057,
                deal_deal_number,numTemp1, 
                deal_base_currency, 0,
                0, numIntoutlay, 'Deal Reversal No: ' ||
                deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
                (select lbnk_account_number
                  from trmaster306
                  where lbnk_pick_code = deal_counter_party)
                from trtran001
                where deal_deal_number = varDealReference
                and deal_serial_number = 1;   
            end if;
            varOperation := 'Inserting Interest Current';
            
            varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
            insert into trtran008 (bcac_company_code, bcac_location_code,
              bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
              bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
              bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
              bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
              bcac_create_date, bcac_local_merchant, bcac_record_status,
              bcac_record_type, bcac_account_number)
            select numCompany, deal_location_code, deal_counter_party, varVoucher,
              deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONCREDIT,
              GConst.TRANSACTIONDEBIT),24900030,24800051,
              deal_deal_number,numTemp1,
              deal_base_currency, 0,
              0, (numPandL - numIntoutlay), 'Deal Reversal No: ' ||
              deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
              (select lbnk_account_number
                from trmaster306
                where lbnk_pick_code = deal_counter_party)
              from trtran001
              where deal_deal_number = varDealReference
              and deal_serial_number = 1;  
              
          else
            varVoucher := NULL;
          end if;
          
      elsif numAction = GConst.EDITSAVE then
        if numRecordStatus = 1 then
           varOperation := 'Inserting Hedge Deal Delivery';
          insert into trtran006(cdel_company_code, cdel_deal_number,
            cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
            cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
            cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
            cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
            cdel_entry_detail, cdel_record_status, cdel_trade_reference,
            Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
            cdel_spot_rate,cdel_forward_rate,cdel_margin_rate,CDEL_DELIVERY_SERIAL,cdel_int_outlay,cdel_intoutlay_rate)
            select deal_company_code, deal_deal_number,
            deal_serial_number,
            (select NVL(max(cdel_reverse_serial),0) + 1
              from trtran006
              where cdel_deal_number = varDealReference),
            datWorkdate, deal_hedge_trade, Gconst.Dealdelivery,
            numReverseAmount, numFinal, Round(numReverseAmount * numFinal), 1,
            Round(numReverseAmount * numFinal), to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
            SYSDATE, NULL, Gconst.Statusentry, varTradeReference, numTradeSerial,
            numPandL,varVoucher ,numSpot,numPremium,numMargin,numSerial,numIntoutlay,numintOutlayRate
            from trtran001
            where deal_deal_number = varDealReference;
            
            varOperation := 'Inserting Hedge Deal Delivery after insert';
          numError := fncCompleteUtilization(varDealReference,GConst.UTILHEDGEDEAL,datWorkDate);
          varOperation := 'Inserting Hedge Deal Delivery after fncCompleteUtilization';  
          
          if numPandL != 0 then
              select CDEL_REVERSE_SERIAL into numTemp1
                from trtran006
              where cdel_deal_number = varDealReference
                    and cdel_trade_reference = varTradeReference
                    and Cdel_Trade_Serial = numTradeSerial;
            varOperation := 'Inserting C/A voucher for PL';
            
            varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
            
            insert into trtran008 (bcac_company_code, bcac_location_code,
              bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
              bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
              bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
              bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
              bcac_create_date, bcac_local_merchant, bcac_record_status,
              bcac_record_type, bcac_account_number)
            select numCompany, deal_location_code, deal_counter_party, varVoucher,
              deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
              GConst.TRANSACTIONCREDIT),24900049,24800051,
              deal_deal_number,numTemp1,
              deal_base_currency, 0,
              0, numPandL, 'Deal Reversal No: ' ||
              deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
              (select lbnk_account_number
                from trmaster306
                where lbnk_pick_code = deal_counter_party)
              from trtran001
              where deal_deal_number = varDealReference
              and deal_serial_number = 1; 
              
            varOperation := 'Inserting Interest Outlay voucher for PL' || numIntoutlay;   
            if numIntoutlay <> 0 then
              varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
              insert into trtran008 (bcac_company_code, bcac_location_code,
                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                bcac_create_date, bcac_local_merchant, bcac_record_status,
                bcac_record_type, bcac_account_number)
              select numCompany, deal_location_code, deal_counter_party, varVoucher,
                deal_maturity_date, GConst.TRANSACTIONDEBIT,24900079,24800057,
                deal_deal_number,numTemp1, 
                deal_base_currency, 0,
                0, numIntoutlay, 'Deal Reversal No: ' ||
                deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
                (select lbnk_account_number
                  from trmaster306
                  where lbnk_pick_code = deal_counter_party)
                from trtran001
                where deal_deal_number = varDealReference
                and deal_serial_number = 1;   
            end if;              
            varOperation := 'Inserting C/A voucher for PL' || numIntoutlay;  
            
            varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
            insert into trtran008 (bcac_company_code, bcac_location_code,
              bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
              bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
              bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
              bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
              bcac_create_date, bcac_local_merchant, bcac_record_status,
              bcac_record_type, bcac_account_number)
            select numCompany, deal_location_code, deal_counter_party, varVoucher,
              deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONCREDIT,
              GConst.TRANSACTIONDEBIT),24900030,24800051,
              deal_deal_number,numTemp1,
              deal_base_currency, 0,
              0, (numPandL - numIntoutlay), 'Deal Reversal No: ' ||
              deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
              (select lbnk_account_number
                from trmaster306
                where lbnk_pick_code = deal_counter_party)
              from trtran001
              where deal_deal_number = varDealReference
              and deal_serial_number = 1;  
              
          else
            varVoucher := NULL;
          end if;
        elsif  numRecordStatus = 2 then
--            SELECT CDEL_DEAL_NUMBER,CDEL_REVERSE_SERIAL INTO varReference,numRefSerial FROM TRTRAN006,TRTRAN001
--              WHERE CDEL_TRADE_REFERENCE = varTradeReference  AND CDEL_TRADE_SERIAL = numTradeSerial
--              AND CDEL_DEAL_NUMBER = DEAL_DEAL_NUMBER AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
--              AND DEAL_DEAL_TYPE != 25400001
--              AND CDEL_REVERSE_SERIAL = numRevSerial
--              AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
          if numPandL != 0 then
              SELECT NVL(COUNT(*),0) INTO numRefSerial FROM TRTRAN008  WHERE BCAC_VOUCHER_REFERENCE = varDealReference
                                                                  AND BCAC_REFERENCE_SERIAL = numRevSerial
                                                                  AND BCAC_RECORD_STATUS BETWEEN 10200001 AND 10200004;
              IF numRefSerial > 0 THEN
              ----Currenct account entry Update
                UPDATE TRTRAN008 SET BCAC_VOUCHER_INR = (numPandL - numIntoutlay),
                                    BCAC_RECORD_STATUS = 10200004 WHERE BCAC_VOUCHER_REFERENCE = varDealReference
                                                                    AND BCAC_REFERENCE_SERIAL = numRevSerial
                                                                    AND BCAC_ACCOUNT_HEAD = 24900030
                                                                    AND BCAC_RECORD_STATUS BETWEEN 10200001 AND 10200004;
                ---Proft loss head entry update                                                    
                UPDATE TRTRAN008 SET BCAC_VOUCHER_INR = numPandL,
                                    BCAC_RECORD_STATUS = 10200004 WHERE BCAC_VOUCHER_REFERENCE = varDealReference
                                                                    AND BCAC_REFERENCE_SERIAL = numRevSerial
                                                                    AND BCAC_ACCOUNT_HEAD = 24900049
                                                                    AND BCAC_RECORD_STATUS BETWEEN 10200001 AND 10200004;
                ---Interest Outlay Entry Update                                                    
                UPDATE TRTRAN008 SET BCAC_VOUCHER_INR = numIntoutlay,
                                    BCAC_RECORD_STATUS = 10200004 WHERE BCAC_VOUCHER_REFERENCE = varDealReference
                                                                    AND BCAC_REFERENCE_SERIAL = numRevSerial
                                                                    AND BCAC_ACCOUNT_HEAD = 24900079
                                                                    AND BCAC_RECORD_STATUS BETWEEN 10200001 AND 10200004;                                                                    
              ELSE
                select CDEL_REVERSE_SERIAL into numTemp1
                  from trtran006
                where cdel_deal_number = varDealReference
                      and cdel_trade_reference = varTradeReference
                      and Cdel_Trade_Serial = numTradeSerial;
                
                varOperation := 'Inserting Currenct Account voucher for PL';
                varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
                insert into trtran008 (bcac_company_code, bcac_location_code,
                  bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                  bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                  bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                  bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                  bcac_create_date, bcac_local_merchant, bcac_record_status,
                  bcac_record_type, bcac_account_number)
                select numCompany, deal_location_code, deal_counter_party, varVoucher,
                  deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
                  GConst.TRANSACTIONCREDIT),24900049,24800051,
                  deal_deal_number,numTemp1,
                  deal_base_currency, 0,
                  0, numPandL, 'Deal Reversal No: ' ||
                  deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
                  (select lbnk_account_number
                    from trmaster306
                    where lbnk_pick_code = deal_counter_party)
                  from trtran001
                  where deal_deal_number = varDealReference
                  and deal_serial_number = 1;    
                if numIntoutlay <> 0 then
                  varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
                  insert into trtran008 (bcac_company_code, bcac_location_code,
                    bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                    bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                    bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                    bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                    bcac_create_date, bcac_local_merchant, bcac_record_status,
                    bcac_record_type, bcac_account_number)
                  select numCompany, deal_location_code, deal_counter_party, varVoucher,
                    deal_maturity_date, GConst.TRANSACTIONDEBIT,24900079,24800057,
                    deal_deal_number,numTemp1, 
                    deal_base_currency, 0,
                    0, numIntoutlay, 'Deal Reversal No: ' ||
                    deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
                    (select lbnk_account_number
                      from trmaster306
                      where lbnk_pick_code = deal_counter_party)
                    from trtran001
                    where deal_deal_number = varDealReference
                    and deal_serial_number = 1;   
                end if;                  
                varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
                insert into trtran008 (bcac_company_code, bcac_location_code,
                  bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                  bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                  bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                  bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                  bcac_create_date, bcac_local_merchant, bcac_record_status,
                  bcac_record_type, bcac_account_number)
                select numCompany, deal_location_code, deal_counter_party, varVoucher,
                  deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONCREDIT,
                  GConst.TRANSACTIONDEBIT),24900030,24800051,
                  deal_deal_number,numTemp1,
                  deal_base_currency, 0,
                  0, (numPandL -numIntoutlay), 'Deal Reversal No: ' ||
                  deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
                  (select lbnk_account_number
                    from trmaster306
                    where lbnk_pick_code = deal_counter_party)
                  from trtran001
                  where deal_deal_number = varDealReference
                  and deal_serial_number = 1;                
              END IF;
          end if;
          UPDATE TRTRAN006 SET CDEL_CANCEL_AMOUNT = numReverseAmount,
                               CDEL_CANCEL_RATE = numFinal,
                               CDEL_PROFIT_LOSS = numPandL,
                               CDEL_FORWARD_RATE = numPremium,
                               CDEL_INT_OUTLAY = numIntoutlay,
                               cdel_intoutlay_rate = numintOutlayRate,
                               CDEL_RECORD_STATUS = 10200004 WHERE CDEL_TRADE_REFERENCE = varTradeReference  
                                                                AND CDEL_TRADE_SERIAL = numTradeSerial
                                                                AND CDEL_DEAL_NUMBER = varDealReference
                                                                AND CDEL_REVERSE_SERIAL = numRevSerial
                                                                AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
          numError := fncCompleteUtilization(varDealReference,GConst.UTILHEDGEDEAL,datWorkDate);
        elsif  numRecordStatus = 3 then
--            SELECT CDEL_DEAL_NUMBER,CDEL_REVERSE_SERIAL INTO varReference,numRefSerial FROM TRTRAN006,TRTRAN001
--              WHERE CDEL_TRADE_REFERENCE = varTradeReference  AND CDEL_TRADE_SERIAL = numTradeSerial
--              AND CDEL_DEAL_NUMBER = DEAL_DEAL_NUMBER AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
--              AND DEAL_DEAL_TYPE != 25400001
--              AND CDEL_REVERSE_SERIAL = numRevSerial
--              AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
          UPDATE TRTRAN008 SET BCAC_RECORD_STATUS = 10200006 WHERE BCAC_VOUCHER_REFERENCE = varDealReference
                                                                  AND BCAC_REFERENCE_SERIAL = numRevSerial;
          UPDATE TRTRAN006 SET CDEL_RECORD_STATUS = 10200006 WHERE CDEL_TRADE_REFERENCE = varTradeReference  
                                                                AND CDEL_TRADE_SERIAL = numTradeSerial
                                                                AND CDEL_DEAL_NUMBER = varDealReference
                                                                AND CDEL_REVERSE_SERIAL = numRevSerial                                                                
                                                                AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
          numError := fncCompleteUtilization(varDealReference,GConst.UTILHEDGEDEAL,datWorkDate);        
        end if;
      elsif numAction = GConst.DELETESAVE then
--            SELECT CDEL_DEAL_NUMBER,CDEL_REVERSE_SERIAL INTO varReference,numRefSerial FROM TRTRAN006,TRTRAN001
--              WHERE CDEL_TRADE_REFERENCE = varTradeReference  AND CDEL_TRADE_SERIAL = numTradeSerial
--              AND CDEL_DEAL_NUMBER = DEAL_DEAL_NUMBER AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
--              AND DEAL_DEAL_TYPE != 25400001
--              AND CDEL_REVERSE_SERIAL = numRevSerial              
--              AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
          UPDATE TRTRAN008 SET BCAC_RECORD_STATUS = 10200006 WHERE BCAC_VOUCHER_REFERENCE = varDealReference
                                                                AND BCAC_REFERENCE_SERIAL = numRevSerial;
          UPDATE TRTRAN006 SET CDEL_RECORD_STATUS = 10200006 WHERE CDEL_TRADE_REFERENCE = varTradeReference  
                                                                AND CDEL_TRADE_SERIAL = numTradeSerial
                                                                AND CDEL_DEAL_NUMBER = varDealReference
                                                                AND CDEL_REVERSE_SERIAL = numRevSerial                                                                
                                                                AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
          numError := fncCompleteUtilization(varDealReference,GConst.UTILHEDGEDEAL,datWorkDate);  
          
      elsif numAction = GConst.CONFIRMSAVE then
          UPDATE TRTRAN008 SET BCAC_RECORD_STATUS = 10200003 WHERE BCAC_VOUCHER_REFERENCE = varDealReference
                                                                AND BCAC_REFERENCE_SERIAL = numRevSerial;
          UPDATE TRTRAN006 SET CDEL_RECORD_STATUS = 10200003 WHERE CDEL_TRADE_REFERENCE = varTradeReference  
                                                                AND CDEL_TRADE_SERIAL = numTradeSerial
                                                                AND CDEL_DEAL_NUMBER = varDealReference
                                                                AND CDEL_REVERSE_SERIAL = numRevSerial                                                                
                                                                AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
                                                                
      end if;
      End Loop;
<<Cash_Deal>>
        if numAction = GConst.ADDSAVE then
          if numCashDeal > 0 then
            varOperation := 'Inserting Cash Deal';
            varDealReference := varCompany || '/FWD/' || GConst.fncGenerateSerial(Gconst.SERIALDEAL,numCompany);
            insert into trtran001
              (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
              deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
              deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
              deal_confirm_date,deal_dealer_remarks,deal_time_stamp,
              deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
              deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,
              deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
              deal_bo_remark,deal_location_code)
            values ( numCompany, varDealReference, 1, datWorkDate, 26000001,numBuySell,
              25200002,25400001,NumLocalBank,numCurrencyCode, 30400003,numCashRate, 1, numCashDeal,
              Round(numCashRate * numCashDeal),0,0,datWorkDate,datWorkDate,null, 'System',
              NULL, varTradeReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
              to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,sysdate,NULL, 10200001,
              null,null,null,0,numCashRate,
              0,33399999,0,0,33899999, NULL,
              'Cash Delivery ' || varTradeReference,numLocation);
  
            varOperation := 'Inserting Cash Deal Cancellation';
            insert into trtran006
              (cdel_company_code,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
              cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
              cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
              cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
              cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
              cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark)
            select deal_company_code, deal_deal_number, 1, 1, varTradeReference, numTradeSerial,
              datWorkDate, 26000001,27000002,deal_base_amount, deal_exchange_rate, deal_other_amount, 0,
              0,0,0,0,0,0,'System',varTradeReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), sysdate,
              null, 10200001, null,null,numSerial,0,deal_exchange_rate,0,0,0,33500001,null,null,deal_bank_reference,
              deal_bo_remark
              from trtran001
              where deal_deal_number = varDealReference;
        
  --         begin 
  --           select nvl(HEDG_TRADE_SERIAL,1) +1
  --           into  numserial 
  --            from trtran004 
  --            where hedg_trade_reference=varTradeReference;
  --         exception 
  --           when no_data_found then
  --             numserial:=1;
  --         end ;
  --          varOperation := 'Inserting Hedge record';
  --          insert into trtran004
  --          (hedg_company_code,hedg_trade_reference,hedg_deal_number,
  --            hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
  --            hedg_create_date,hedg_entry_detail,hedg_record_status,
  --            hedg_hedging_with,hedg_multiple_currency,HEDG_TRADE_SERIAL)
  --          values(numCompany,varTradeReference,varDealReference,
  --          1, numCashDeal,0, Round(numCashDeal * numCashRate),
  --          sysdate,NULL,10200012, 32200001,12400002,numserial);
  
        End if;
        if numCashDeal > 0 or numDealReverse > 0 then
          INSERT INTO TRTRAN003
          (BREL_COMPANY_CODE, BREL_TRADE_REFERENCE,BREL_REVERSE_SERIAL,BREL_ENTRY_DATE,BREL_USER_REFERENCE,
          BREL_REFERENCE_DATE,BREL_REVERSAL_TYPE,BREL_REVERSAL_FCY,BREL_REVERSAL_RATE,BREL_REVERSAL_INR,
          BREL_PERIOD_CODE,BREL_TRADE_PERIOD,BREL_MATURITY_FROM,BREL_MATURITY_DATE,BREL_CREATE_DATE,
          BREL_ENTRY_DETAIL,BREL_RECORD_STATUS,BREL_LOCAL_BANK,BREL_REVERSE_REFERENCE,BREL_LOCATION_CODE)
          Select Numcompany,Vartradereference,Numtradeserial,Sysdate,'Exposure Settlement',Datreference,
          25899999,Numcashdeal+Numdealreverse,Nvl(Numcashrate,Numfinal),Nvl(Numcashrate,Numfinal)*(Numcashdeal+Numdealreverse),0,
          0,sysdate,sysdate,sysdate,null,10200001,NumLocalBank,null,numLocation from dual;
        end if;  
      ELSif numAction = GConst.EDITSAVE then
      begin
        SELECT CDEL_DEAL_NUMBER INTO varReference FROM TRTRAN006,TRTRAN001
        WHERE CDEL_TRADE_REFERENCE = varTradeReference  
        AND CDEL_TRADE_SERIAL = numTradeSerial
        AND CDEL_DEAL_NUMBER = DEAL_DEAL_NUMBER AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
        AND DEAL_DEAL_TYPE = 25400001
        AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
        if numCashDeal > 0 then  
          UPDATE TRTRAN006 SET CDEL_CANCEL_AMOUNT = numCashDeal,
                               CDEL_CANCEL_RATE = numCashRate,
                               CDEL_SPOT_RATE = numCashRate,
                               CDEL_RECORD_STATUS = 10200004 WHERE CDEL_DEAL_NUMBER = varReference;
          UPDATE TRTRAN001 SET DEAL_BASE_AMOUNT = numCashDeal,
                               DEAL_EXCHANGE_RATE = numCashRate,
                               DEAL_SPOT_RATE = numCashRate,
                               DEAL_RECORD_STATUS = 10200004 WHERE DEAL_DEAL_NUMBER = varReference;
          UPDATE TRTRAN003 SET BREL_REVERSAL_FCY = (numCashDeal+numDealReverse),
                               BREL_REVERSAL_RATE = numCashRate,
                               BREL_RECORD_STATUS = 10200004 WHERE BREL_TRADE_REFERENCE = varTradeReference
                                                                 AND  BREL_REVERSE_SERIAL = numTradeSerial;
        end if;                                                                 
        exception
        when no_data_found then 
          if numCashDeal > 0 then
            varOperation := 'Inserting Cash Deal';
            varDealReference := varCompany || '/FWD/' || GConst.fncGenerateSerial(Gconst.SERIALDEAL,numCompany);
            insert into trtran001
              (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
              deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
              deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
              deal_confirm_date,deal_dealer_remarks,deal_time_stamp,
              deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
              deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,
              deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
              deal_bo_remark,deal_location_code)
            values ( numCompany, varDealReference, 1, datWorkDate, 26000001,numBuySell,
              25200002,25400001,NumLocalBank,numCurrencyCode, 30400003,numCashRate, 1, numCashDeal,
              Round(numCashRate * numCashDeal),0,0,datWorkDate,datWorkDate,null, 'System',
              NULL,varTradeReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
              to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,sysdate,NULL, 10200001,
              null,null,null,0,numCashRate,0,33399999,0,0,33899999, NULL,
              'Cash Delivery ' || varTradeReference,numLocation);
  
            varOperation := 'Inserting Cash Deal Cancellation';
            insert into trtran006
              (cdel_company_code,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
              cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
              cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
              cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
              cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
              cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark)
            select deal_company_code, deal_deal_number, 1, 1, varTradeReference, numTradeSerial,
              datWorkDate, 26000001,27000002,deal_base_amount, deal_exchange_rate, deal_other_amount, 0,
              0,0,0,0,0,0,'System',varTradeReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), sysdate,
              null, 10200001, null,null,numSerial,0,deal_exchange_rate,0,0,0,33500001,null,null,deal_bank_reference,
              deal_bo_remark
              from trtran001
              where deal_deal_number = varDealReference;
        End if;
--        if numCashDeal > 0 or numDealReverse > 0 then
--          INSERT INTO TRTRAN003
--          (BREL_COMPANY_CODE, BREL_TRADE_REFERENCE,BREL_REVERSE_SERIAL,BREL_ENTRY_DATE,BREL_USER_REFERENCE,
--          BREL_REFERENCE_DATE,BREL_REVERSAL_TYPE,BREL_REVERSAL_FCY,BREL_REVERSAL_RATE,BREL_REVERSAL_INR,
--          BREL_PERIOD_CODE,BREL_TRADE_PERIOD,BREL_MATURITY_FROM,BREL_MATURITY_DATE,BREL_CREATE_DATE,
--          BREL_ENTRY_DETAIL,BREL_RECORD_STATUS,BREL_LOCAL_BANK,BREL_REVERSE_REFERENCE,BREL_LOCATION_CODE)
--          SELECT numCompany,varTradeReference,numTradeSerial,SYSDATE,'Exposure Settlement',datReference,
--          25899999,numCashDeal+numDealReverse,numCashRate,numCashRate*(numCashDeal+numDealReverse),0,
--          0,sysdate,sysdate,sysdate,null,10200001,NumLocalBank,null,numLocation from dual; 
--        end if;  
      end;  
      ELSif numAction = GConst.DELETESAVE then
        begin
          SELECT CDEL_DEAL_NUMBER INTO varReference FROM TRTRAN006,TRTRAN001
          WHERE CDEL_TRADE_REFERENCE = varTradeReference  
          AND CDEL_TRADE_SERIAL = numTradeSerial
          AND CDEL_DEAL_NUMBER = DEAL_DEAL_NUMBER AND DEAL_RECORD_STATUS NOT IN(10200005,10200006)
          AND DEAL_DEAL_TYPE = 25400001
          AND CDEL_RECORD_STATUS BETWEEN 10200001 AND 10200004;
          
          UPDATE TRTRAN006 SET CDEL_RECORD_STATUS = 10200006 WHERE CDEL_DEAL_NUMBER = varReference;
          UPDATE TRTRAN001 SET DEAL_RECORD_STATUS = 10200006 WHERE DEAL_DEAL_NUMBER = varReference;
          UPDATE TRTRAN003 SET BREL_RECORD_STATUS = 10200006 WHERE BREL_TRADE_REFERENCE = varTradeReference

                                                                 AND  BREL_REVERSE_SERIAL = numTradeSerial;
        exception
        when no_data_found then 
          varTradeReference := '';
        end; 
      end if;
      return numError;
Exception
        When others then
          numError := SQLCODE;
          varError := SQLERRM;
          varError := GConst.fncReturnError('BillSettle', numError, varMessage,
                          varOperation, varError);
          raise_application_error(-20101, varError);
          RETURN numError;
End forwardSettlement;

---manjunath sir modification ends
Function fncBillSettlement
    (   RecordDetail in GConst.gClobType%Type)
    return number
    is
--  created by TMM on 31/01/2014
    numError            number;
    numTemp             number;
    numAction           number(4);
    numSerial           number(5);
    numLocation         number(8);
    numCompany          number(8);
    numReversal         number(8);
    numImportExport     number(8);    
    numReverseAmount    number(15,2);
    numDealReverse      number(15,2);
    numBillReverse      number(15,2);
    numCashDeal         number(15,2);
    numPandL            number(15,2);
    numFcy              number(15,2);
    numSpot             number(15,6);
    numPremium          number(15,6);
    numMargin           number(15,6);
    numFinal            number(15,6);
    numCashRate         number(15,6);
    varCompany          varchar2(15);
    varEntity           varchar2(25);
    varVoucher          varchar2(25);
    varTradeReference   varchar2(25);
    varDealReference    varchar2(25);
    varReference        varchar2(25);
    varXPath            varchar2(1024);
    varTemp             varchar2(1024);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    datWorkDate         Date;
    datReference        Date;
    xmlTemp             xmlType;
    nlsTemp             xmlDom.DomNodeList;
    nodFinal            xmlDom.domNode;
    docFinal            xmlDom.domDocument;
    nodTemp             xmlDom.domNode;
    nodTemp1            xmlDom.domNode;
    nmpTemp             xmldom.domNamedNodemap;
    numLocalBank        number(8);
    numCompanyCode      number(8);
    numReverseSerial    number(5);
    numCurrencyCode     NUMBER(8);
    numTradeSerial      NUMBER(5);
    clbTemp             clob;

  Begin
    varMessage := 'Entering Bill Settlement Process';
    numError := 0;
    numDealReverse := 0;
    numBillReverse := 0;
    numCashDeal := 0;

    varOperation := 'Extracting Parameters';
    xmlTemp := xmlType(RecordDetail);
    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationId', numLocation);

varOperation := 'Extracting Parameters' || numLocation;

    numCompany := GConst.fncXMLExtract(xmlTemp, 'BREL_COMPANY_CODE', numCompany);
    varTradeReference := GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_REFERENCE', varTradeReference);
    numSerial := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', numSerial);
    numReversal := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_TYPE', numReversal);
    varOperation := 'Extracting Parameters BREL_REVERSAL_TYPE ' || numReversal;
    
    datReference := GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datReference);
    numBillReverse := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_FCY', numBillReverse);
    numCashRate :=  GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_RATE', numCashRate);
    varOperation := 'Extracting Parameters BREL_REVERSAL_RATE ' || numCashRate;
    numCompanyCode :=  GConst.fncXMLExtract(xmlTemp, 'BREL_COMPANY_CODE',numCompanyCode);
    numReverseSerial:=  GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', numReverseSerial); 
    numLocalBank := GConst.fncXMLExtract(xmlTemp, 'BREL_LOCAL_BANK', numLocalBank); 
    varOperation := 'Extracting Parameters BREL_LOCAL_BANK ' || numLocalBank;
    numCurrencyCode := Gconst.fncXMLExtract(xmlTemp, 'TradeCurrencyCode', numCurrencyCode); 
    numImportExport := gconst.fncxmlextract(xmltemp, 'ImportExport', numImportExport);
    numTradeSerial := gconst.fncxmlextract(xmltemp, 'TradeSerial', numTradeSerial);
    varCompany := pkgReturnCursor.fncGetDescription(numCompany,2);
    
     varOperation := 'Extracting Parameters CurrencyCode ' || numCurrencyCode;
    
    docFinal := xmlDom.newDomDocument(xmlTemp);
    nodFinal := xmlDom.makeNode(docFinal);
    IF numImportExport = 25900073 THEN
      numTradeSerial := 0;
    --  SELECT nvl(MAX(INTC_INTEREST_NUMBER)+1,0) INTO numTradeSerial FROM himatsingkatf_prod.tftran051 WHERE INTC_LOAN_REFERENCE = varTradeReference;
    end if; 
    if numReversal not in (GConst.BILLREALIZE,GConst.BILLINWARDREMIT,
      GConst.BILLIMPORTREL,GConst.BILLOUTWARDREMIT,GConst.BILLLOANCLOSURE) then
      Goto Trade_reversal;
    End if;

    varOperation := 'Checking for Deal Delivery, if any';
    varXPath := '//CommandSet/DealDetails/ReturnFields/ROWD[@NUM]';
    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);

    if xmlDom.getLength(nlsTemp) = 0 then
      numCashDeal := numBillReverse;
      GOto Cash_Deal;
    END IF;
    DELETE FROM temp;
    insert into temp values (numTradeSerial,'Chandra');commit;
<<Deal_Reversal>>
    varXPath := '//CommandSet/DealDetails/ReturnFields/ROWD[@NUM="';
      for numSub in 0..xmlDom.getLength(nlsTemp) -1
      Loop
        nodTemp := xmlDom.item(nlsTemp, numSub);
        nmpTemp := xmlDom.getAttributes(nodTemp);
        nodTemp1 := xmlDom.item(nmpTemp, 0);
        numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
        varTemp := varXPath || numTemp || '"]/DealNumber';
        varDealReference := GConst.fncGetNodeValue(nodFinal, varTemp);
        varTemp := varXPath || numTemp || '"]/SpotRate'; --Updated From cygnet
        numSpot := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
-- Node Name changed from FrwRate to Premium for TOI by TMM 31/01/14
        varTemp := varXPath || numTemp || '"]/Premium';
        numPremium := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || numTemp || '"]/MarginRate';
        numMargin := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || numTemp || '"]/FinalRate';
        numFinal := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
        varTemp := varXPath || numTemp || '"]/ReverseNow';
        numReverseAmount := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        numDealReverse := numDealReverse + numReverseAmount;

        select
          case
          when datWorkDate < deal_maturity_date and deal_forward_rate != numPremium then
            round(numReverseAmount * (deal_forward_rate - numPremium))
          when numFinal != deal_exchange_rate then
            decode(deal_buy_sell, GConst.PURCHASEDEAL,
              Round(numReverseAmount * deal_exchange_rate) - Round(numReverseAmount * numFinal),
              Round(numReverseAmount * numFinal) - Round(numReverseAmount * deal_exchange_rate))
          else 0
          end
          into numPandL
          from trtran001
          where deal_deal_number = varDealReference;

        if numPandL > 0 then
          varOperation := 'Inserting voucher for PL';
          clbTemp := pkgMasterMaintenance.fncCurrentAccount(RecordDetail, numError);          
--          varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--          insert into trtran008 (bcac_company_code, bcac_location_code,
--            bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--            bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--            bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--            bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--            bcac_create_date, bcac_local_merchant, bcac_record_status,
--            bcac_record_type, bcac_account_number)
--          select numCompany, numLocation, deal_counter_party, varVoucher,
--            deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
--            GConst.TRANSACTIONCREDIT),GConst.ACEXCHANGE,
--            decode(deal_buy_sell,GConst.PURCHASEDEAL,
--            GConst.EVENTPURCHASE, GConst.EVENTSALE),
--            deal_deal_number, 1, deal_base_currency, numReverseAmount,
--            numFinal, Round(numReverseAmount *  numFinal), 'Deal Reversal No: ' ||
--            deal_deal_number, sysdate,30999999,GConst.STATUSENTRY, 23800002,
--            (select lbnk_account_number
--              from trmaster306
--              where lbnk_pick_code = deal_counter_party)
--            from trtran001
--            where deal_deal_number = varDealReference
--            and deal_serial_number = 1;
        else
          varVoucher := NULL;
        end if;

        varOperation := 'Inserting entries to Hedge Table, if necessary';
        select count(*)
          into numTemp
          from trtran004
          where hedg_trade_reference = varTradeReference
          and hedg_deal_number = varDealReference
          and hedg_record_status between 10200001 and 10200004;
-- Deal was not dynamically linked in the realization screen
        if numtemp = 0 then
          insert into trtran004
          (hedg_company_code,hedg_trade_reference,hedg_deal_number,
            hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
            hedg_create_date,hedg_entry_detail,hedg_record_status,
            hedg_hedging_with,hedg_multiple_currency,HEDG_TRADE_SERIAL)
          values(numCompany,varTradeReference,varDealReference,
            (select NVL(max(hedg_deal_serial),0) + 1
            from trtran004
            where hedg_deal_number = varDealReference),
          numReverseAmount,0, Round(numReverseAmount * numFinal),
          sysdate,NULL,10200012, 32200001,12400002,numTradeSerial);
        END IF;

        varOperation := 'Inserting Hedge Deal Delivery';
        insert into trtran006(cdel_company_code, cdel_deal_number,
          cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
          cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
          cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
          cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
          cdel_entry_detail, cdel_record_status, cdel_trade_reference,
          Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
          cdel_spot_rate,cdel_forward_rate,cdel_margin_rate,CDEL_DELIVERY_SERIAL) -- Updated from Cygnet
          select deal_company_code, deal_deal_number,
          deal_serial_number,
          (select NVL(max(cdel_reverse_serial),0) + 1
            from trtran006
            where cdel_deal_number = varDealReference),
          datWorkdate, deal_hedge_trade, Gconst.Dealdelivery,
          numReverseAmount, numFinal, Round(numReverseAmount * numFinal), 1,
          Round(numReverseAmount * numFinal), to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
          SYSDATE, NULL, Gconst.Statusentry, varTradeReference, numTradeSerial, numPandL,
          varVoucher ,numSpot,numPremium,numMargin,numSerial
          from trtran001
          where deal_deal_number = varDealReference;

        numError := fncCompleteUtilization(varDealReference,GConst.UTILHEDGEDEAL,datWorkDate);

      End Loop;

      numCashDeal := numBillReverse - numDealReverse;

<<Cash_Deal>>

      if numCashDeal > 0 then
          varOperation := 'Inserting Cash Deal';
          varDealReference := varCompany || '/FWD/' || GConst.fncGenerateSerial(Gconst.SERIALDEAL,numCompany);
          insert into trtran001
            (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
            deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
            deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
            deal_confirm_date,deal_dealer_remarks,deal_time_stamp,
            deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
            deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,
            deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
            deal_bo_remark)
          values ( numCompanyCode, varDealReference, 1, datWorkDate, 26000001,decode(sign(25800050 - numReversal),-1,25300002,25300001),
            25200002,25400001,NumLocalBank,numCurrencyCode, 30400003,numCashRate, 1, numCashDeal,
            Round(numCashRate * numCashDeal),0,0,datWorkDate,datWorkDate,null, 'System',
            NULL,varTradeReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
            to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,sysdate,NULL, 10200001,
            null,null,null,0,numCashRate,0,33399999,0,0,33899999, NULL,
            'Cash Delivery ' || varTradeReference);
            
--            from trtran002
--            where trad_trade_reference = varTradeReference;

          varOperation := 'Inserting Cash Deal Cancellation';
          insert into trtran006
            (cdel_company_code,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
            cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
            cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
            cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
            cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
            cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark)
          select deal_company_code, deal_deal_number, 1, 1, varTradeReference, deal_local_rate,
            datWorkDate, 26000001,27000002,deal_base_amount, deal_exchange_rate, deal_other_amount, 0,
            0,0,0,0,0,0,'System',varTradeReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), sysdate,
            null, 10200001, null,null,numSerial,0,deal_exchange_rate,0,0,0,33500001,null,null,deal_bank_reference,
            deal_bo_remark
            from trtran001
            where deal_deal_number = varDealReference;
      
         begin 
           select nvl(Max(HEDG_TRADE_SERIAL),1) +1
           into  numserial 
            from trtran004 
            where hedg_trade_reference=varTradeReference;
         exception 
           when no_data_found then
             numserial:=1;
         end ;
          varOperation := 'Inserting Hedge record';
          insert into trtran004
          (hedg_company_code,hedg_trade_reference,hedg_deal_number,
            hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
            hedg_create_date,hedg_entry_detail,hedg_record_status,
            hedg_hedging_with,hedg_multiple_currency,HEDG_TRADE_SERIAL)
          values(numCompany,varTradeReference,varDealReference,
          1, numCashDeal,0, Round(numCashDeal * numCashRate),
          sysdate,NULL,10200012, 32200001,12400002,numserial);

      End if;



<<Trade_Reversal>>

--        if numReversal in (GConst.BILLREALIZE,GConst.BILLIMPORTREL) then
--          numError := fncCompleteUtilization(varTradeReference,GConst.UTILEXPORTS,datWorkDate);
      if numReversal in (GConst.BILLREALIZE,GConst.BILLIMPORTREL,
             GConst.BILLEXPORTCANCEL,GConst.BILLIMPORTCANCEL,GCONST.BILLAMENDMENT) then
             --Changed by Manjunath Reddy to include Export cancel and import cancel for process complete
          numError := fncCompleteUtilization(varTradeReference,GConst.UTILEXPORTS,datWorkDate);
          
          if  numReversal in (GConst.BILLEXPORTCANCEL,GConst.BILLIMPORTCANCEL) then              
              update trtran004     
                set hedg_record_status = GConst.STATUSPOSTCANCEL
                where hedg_trade_reference = varTradeReference
                and hedg_record_Status not in (10200005,10200006);
          end if;
          
--      varOperation := 'Checking for PSCFC Details';
--      Begin
--        numFcy := 0;
--        varReference := '';
--   --     varReference := GConst.fncXMLExtract(xmlTemp, 'LoanNumber', varReference);
--        numFcy := GConst.fncXMLExtract(xmlTemp, '//PSCFCDetails/SanctionedFcy', 
--                        numFcy, GConst.TYPENODEPATH);
--        
--      Exception
--        when others then
--          numFcy := 0;
--          varReference := '';
--      End;
--      
--      if numFcy > 0 then
--        
--        if numAction = GConst.ADDSAVE then
--          varReference := PkgReturnCursor.fncGetDescription(GConst.LOANPSCFC, GConst.PICKUPSHORT);
--          varReference := varReference || '/' || GConst.fncGenerateSerial(GConst.SERIALLOAN);
--          
--          varOperation := 'Inserting PSCFC Record';
--          insert into trtran005(fcln_company_code, fcln_loan_number,
--          fcln_loan_type, fcln_local_bank, fcln_bank_reference, fcln_sanction_date,
--          fcln_noof_days, fcln_currency_code, fcln_sanctioned_fcy,
--          fcln_conversion_rate, fcln_sanctioned_inr, fcln_reason_code,
--          fcln_maturity_from, fcln_maturity_to, fcln_loan_remarks,
--          Fcln_Libor_Rate,Fcln_Rate_Spread,Fcln_Interest_Rate, -- Updated From Cygnet
--          fcln_create_date, fcln_entry_detail, fcln_record_status,fcln_process_complete) -- Updated From Cygnet
--          values(numCompany, varReference, GConst.LOANPSCFC,
--          Gconst.Fncxmlextract(Xmltemp, 'BREL_LOCAL_BANK', Numfcy),
--          GConst.fncXMLExtract(xmlTemp, 'BankReference', varReference),
--          GConst.fncXMLExtract(xmlTemp, 'SanctionDate', datWorkDate),
--          GConst.fncXMLExtract(xmlTemp, 'NoofDays', numError),
--          (select trad_trade_currency
--            from trtran002
--            where trad_trade_reference = varTradeReference),
--          GConst.fncXMLExtract(xmlTemp, 'SanctionedFcy', numFcy),
--          GConst.fncXMLExtract(xmlTemp, 'ConversionRate', numFcy),
--          GConst.fncXMLExtract(xmlTemp, 'SanctionedInr', numFcy),
--          GConst.REASONEXPORT,
--          GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_FROM', datWorkDate),
--          GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datWorkDate),
--          'PSCFC From Bill Trade Reference ' || varTradeReference,
--          GConst.fncXMLExtract(xmlTemp, 'LiborRate', numSpot), -- Updated From Cygnet
--          GConst.fncXMLExtract(xmlTemp, 'SpreadRate', numSpot),
--          GConst.fncXMLExtract(xmlTemp, 'InterestRate', numSpot),
--          sysdate, null, GConst.STATUSENTRY,
--          12400002); -- End updated cygnet
--          
--          varOperation := 'Inserting Loan Connect';
--          insert into trtran010(loln_company_code, loln_loan_number,      -- Updated from cygnet
--          loln_trade_reference, loln_serial_number, loln_adjusted_date, 
--          Loln_Adjusted_Fcy, Loln_Adjusted_Rate, Loln_Adjusted_Inr,
--          loln_create_date, loln_entry_detail, loln_record_status)        --End Updated Cygnet
--          values(numCompany, varReference, varTradeReference, 0, datWorkDate,
--          GConst.fncXMLExtract(xmlTemp, 'SanctionedFcy', numFcy),
--          GConst.fncXMLExtract(xmlTemp, 'ConversionRate', numFcy),
--          GConst.fncXMLExtract(xmlTemp, 'SanctionedInr', numFcy),
--          sysdate, null, GConst.STATUSENTRY);
--          
--        End if;
      
--    End if;          
        elsif numReversal = GConst.BILLLOANCLOSURE then
          numError := fncCompleteUtilization(varTradeReference,GConst.UTILBCRLOAN,datWorkDate);
        end if;
--      if numReversal in (GConst.BILLREALIZE,GConst.BILLIMPORTREL,GConst.BILLLOANCLOSURE) then
--          --prcbillsettlement(recorddetail,numreversal);
--          himatsingkatf_prod.pkgTreasury.prcBillSettlement(RecordDetail,numImportExport);
--      end if;
      
      return numError;
Exception
        When others then
          numError := SQLCODE;
          varError := SQLERRM;
          varError := GConst.fncReturnError('BillSettle', numError, varMessage,
                          varOperation, varError);
          raise_application_error(-20101, varError);
          RETURN numError;
End fncBillSettlement;

--Function fncExposuresettlement
--    (   RecordDetail in GConst.gClobType%Type)
--    return number
--    is
----  created by TMM on 31/01/2014
--    numError            number;
--    numTemp             number;
--    numTemp1            NUMBER;
--    numAction           number(4);
--    numSerial           number(5);
--    numLocation         number(8);
--    numCompany          number(8);
--    numReversal         number(8);
--    numImportExport     number(8);    
--    numReverseAmount    number(15,2);
--    numDealReverse      number(15,2);
--    numBillReverse      number(15,2);
--    numCashDeal         number(15,2);
--    numPandL            number(15,2);
--    numFcy              number(15,2);
--    numSpot             number(15,6);
--    numPremium          number(15,6);
--    numMargin           number(15,6);
--    numFinal            number(15,6);
--    numCashRate         number(15,6);
--    numEDAmount         number(15,2);
--    varCompany          varchar2(15);
--    varBatch            varchar2(25);
--    varEntity           varchar2(25);
--    varVoucher          varchar2(25);
--    varTradeReference   varchar2(25);
--    varDealReference    varchar2(25);
--    varReference        varchar2(25);
--    varBatchNo          varchar2(30);
--    varXPath            varchar2(1024);
--    varTemp             varchar2(1024);
--    varTemp1             varchar2(1024);
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    datWorkDate         Date;
--    datReference        Date;
--    xmlTemp             xmlType;
--    nlsTemp             xmlDom.DomNodeList;
--    nodFinal            xmlDom.domNode;
--    docFinal            xmlDom.domDocument;
--    nodTemp             xmlDom.domNode;
--    nodTemp1            xmlDom.domNode;
--    nmpTemp             xmldom.domNamedNodemap;
--    numLocalBank        number(8);
--    numCompanyCode      number(8);
--    numReverseSerial    number(5);
--    numCurrencyCode     NUMBER(8);
--    numTradeSerial      NUMBER(5);
--    numPortfolio        number(8);
--    numSubportfolio     number(8);
--    numCount            number(3);
--    clbTemp             clob;
--
--  Begin
--    varMessage := 'Entering Bill Settlement Process';
--    numError := 0;
--    numDealReverse := 0;
--    numBillReverse := 0;
--    numCashDeal := 0;
--
--    varOperation := 'Extracting Parameters';
--    xmlTemp := xmlType(RecordDetail);
--    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
--    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
--    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
--    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationID', numLocation);
--    if numAction = GConst.DELETESAVE then
--      varBatchNo := GConst.fncXMLExtract(xmlTemp, 'KeyValues/BatchNumber', varBatchNo);
--      update trtran004 set hedg_record_status = 10200006 where hedg_batch_number = varBatchNo;
--      update trtran006 set cdel_record_status = 10200006 where cdel_batch_number = varBatchNo;
--      update trtran008 set bcac_record_status = 10200006 WHERE BCAC_BATCH_NO = varBatchNo;
--      begin  
--        for cur_in in(select * from trtran006  where cdel_batch_number = varBatchNo)
--        loop
--          
--          varOperation := 'Settlement entry delete';
--          select max(BREL_REVERSE_SERIAL) into numSerial from trtran003;
--          if numSerial < 10000 then
--            numSerial := 10000;
--          end if;
--          update trtran001 set deal_record_status = 10200006 
--                          where deal_deal_number = cur_in.cdel_deal_number 
--                          and DEAL_DEAL_TYPE = 25400001;
--          update trtran001 set deal_process_complete = 12400002,
--                               deal_complete_date = null 
--                          where deal_deal_number = cur_in.cdel_deal_number 
--                          and DEAL_DEAL_TYPE != 25400001; 
--          update trtran002 set trad_process_complete = 12400002,
--                               trad_complete_date = null 
--                          where trad_trade_reference = cur_in.cdel_trade_reference;
----          update trtran003 set  BREL_REVERSE_SERIAL = numSerial + 1 where  brel_trade_reference = cur_in.cdel_trade_reference
----                                                                            and BREL_BATCH_NUMBER = cur_in.CDEL_BATCH_NUMBER;    
--                                                                            
--          update trtran003 set  BREL_BATCH_NUMBER = ''  where  brel_trade_reference = cur_in.cdel_trade_reference
--                                                                            and BREL_BATCH_NUMBER = cur_in.CDEL_BATCH_NUMBER;
--
--          update trtran045 set bcrd_process_complete = 12400002,
--                               bcrd_completion_date = null 
--                          where bcrd_buyers_credit = cur_in.cdel_trade_reference;                                                                                      
--        end loop;
--      end;
--    else
--      varOperation := 'Extracting Parameters' || numLocation;
--      docFinal := xmlDom.newDomDocument(xmlTemp);
--      nodFinal := xmlDom.makeNode(docFinal);       
--      varOperation := 'Before Loop';
--      varXPath := '//FORWARDSETTLEMENTS/CASHSETTLEMENT/ROW';
--      nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--      if xmlDom.getLength(nlsTemp) > 0 then
--            varXPath := '//FORWARDSETTLEMENTS/CASHSETTLEMENT/ROW[@NUM="';
--            for numSub in 0..xmlDom.getLength(nlsTemp) -1
--              Loop
--                varOperation := 'Inside Loop';
--                nodTemp := xmlDom.item(nlsTemp, numSub);
--                nmpTemp := xmlDom.getAttributes(nodTemp);
--                nodtemp1 := xmldom.item(nmptemp, 0);
--                numtemp := to_number(xmldom.getnodevalue(nodtemp1));
--                varTemp := varXPath || numTemp || '"]/TradeReference';
--                varTradeReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--                varTemp := varXPath || numTemp || '"]/CashRate';
--                numCashRate := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
--                varTemp := varXPath || numTemp || '"]/CashFcy';
--                numCashDeal := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--                varTemp := varXPath || numTemp || '"]/ImportExport';
--                numImportExport := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--                varTemp := varXPath || numTemp || '"]/BatchNo';
--                varBatchNo := GConst.fncGetNodeValue(nodFinal, varTemp);              
--                numSerial := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', numSerial);
--                begin
--                  select TRAD_TRADE_CURRENCY,TRAD_LOCAL_BANK,
--                         TRAD_PRODUCT_CATEGORY,TRAD_SUBPRODUCT_CODE,TRAD_COMPANY_CODE
--                    into  numCurrencyCode,numLocalBank,numPortfolio,numSubportfolio,numCompany
--                  from trtran002 where trad_trade_reference = varTradeReference 
--                  and trad_record_status between 10200001 and 10200004
--                  UNION ALL
--                  select BCRD_CURRENCY_CODE,BCRD_LOCAL_BANK,
--                         BCRD_PRODUCT_CATEGORY,BCRD_SUBPRODUCT_CODE,BCRD_COMPANY_CODE
--                  from trtran045 where BCRD_BUYERS_CREDIT = varTradeReference 
--                  and BCRD_RECORD_STATUS between 10200001 and 10200004                  
--                  UNION ALL
--                  select DISTINCT TLON_CURRENCY_CODE,TLON_LOCAL_BANK,
--                         33399999,33899999,TLON_COMPANY_CODE
--                  from TRTRAN081 where TLON_LOAN_NUMBER = varTradeReference 
--                  and TLON_RECORD_STATUS between 10200001 and 10200004;                    
--                exception when no_data_found then
--                   numCurrencyCode := 0;
--                   numLocalBank := 0;
--                   numPortfolio := 0;
--                   numSubportfolio :=0;
--                   numCompany := 0;
--                end ;
--                IF numAction = GConst.EDITSAVE then
--                  varCompany:= pkgReturnCursor.fncGetDescription(numCompany,2);
--                  varDealReference := 'CASH' || GConst.fncGenerateSerial(Gconst.SERIALDEAL,numCompany);
--                  varOperation := 'Inserting Cash deal to main table';
--                  insert into trtran001
--                    (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
--                    deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
--                    deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
--                    deal_confirm_date,deal_holding_rate,deal_holding_rate1,deal_dealer_holding,deal_dealer_holding1,deal_dealer_remarks,deal_time_stamp,
--                    deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
--                    deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,cdel_forward_rate,
--                    cdel_spot_rate,cdel_margin_rate,deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
--                    deal_bo_remark,deal_analysis_option,deal_analysis_type,deal_analysis_frequency,deal_analysis_selection)
--                  values (numCompany, varDealReference, 1, datWorkDate, 26000001,case when numImportExport < 25900050 then 25300002 else 25300001 end,
--                    25200002,25400001,NumLocalBank,numCurrencyCode, 30400003,numCashRate, 1, numCashDeal,
--                    Round(numCashRate * numCashDeal),0,0,datWorkDate,datWorkDate,null, 'System',
--                    NULL, 0,0,0,0,varTradeReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--                    to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,sysdate,NULL, 10200001,
--                    null,null,null,0,numCashRate,0, 0,
--                    0,0,numPortfolio,0,0,numSubportfolio, NULL,
--                    'Cash Delivery ' || varTradeReference,null,null,null,null);              
--                  varOperation := 'Inserting Cash Deal Cancellation';
--                  insert into trtran006
--                    (cdel_company_code,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
--                    cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
--                    cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
--                    cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
--                    cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
--                    cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark,CDEL_BATCH_NUMBER)
--                  select deal_company_code, deal_deal_number, 1, 1, varTradeReference, deal_local_rate,
--                    datWorkDate, 26000001,27000002,deal_base_amount, deal_exchange_rate, deal_other_amount, 0,
--                    0,0,0,0,0,0,'System',varTradeReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), sysdate,
--                    null, 10200001, null,null,numSerial,0,deal_exchange_rate,0,0,0,33500001,null,null,deal_bank_reference,
--                    deal_bo_remark,varBatchNo
--                    from trtran001
--                    where deal_deal_number = varDealReference;              
--                  begin 
--                   select nvl(MAX(HEDG_TRADE_SERIAL),1) +1
--                   into  numserial 
--                    from trtran004 
--                    where hedg_trade_reference=varTradeReference;
--                  exception 
--                   when no_data_found then
--                     numserial:=1;
--                  end ;
--                  varOperation := 'Inserting Cash deal Linking details';
--                  insert into trtran004
--                  (hedg_company_code,hedg_trade_reference,hedg_deal_number,
--                    hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
--                    hedg_create_date,hedg_entry_detail,hedg_record_status,
--                    hedg_hedging_with,hedg_multiple_currency,HEDG_TRADE_SERIAL,
--                    HEDG_BATCH_NUMBER,HEDG_LINKED_DATE)
--                  values(numCompany,varTradeReference,varDealReference,
--                  1, numCashDeal,0, Round(numCashDeal * numCashRate),
--                  sysdate,NULL,10200012, 32200001,12400002,numserial,varBatchNo,datWorkDate);
--                  varOperation := 'After linking Cash deal Linking details';                
--                  numError := fncCompleteUtilization(varTradeReference,GConst.UTILEXPORTS,datWorkDate);
--                END IF;    
--              End loop;
--      end if;
--      
--      docFinal := xmlDom.newDomDocument(xmlTemp);
--      nodFinal := xmlDom.makeNode(docFinal);
--      varXPath := '//FORWARDSETTLEMENTS/FORWARDSETTLEMENT/ROW';
--      nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--      if xmlDom.getLength(nlsTemp) > 0 then
--        varXPath := '//FORWARDSETTLEMENTS/FORWARDSETTLEMENT/ROW[@NUM="';
--        for numSub in 0..xmlDom.getLength(nlsTemp) -1
--        Loop
--          nodTemp := xmlDom.item(nlsTemp, numSub);
--          nmpTemp := xmlDom.getAttributes(nodTemp);
--          nodTemp1 := xmlDom.item(nmpTemp, 0);
--          numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
--          varTemp := varXPath || numTemp || '"]/DealNumber';
--          varDealReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--  
--          varTemp := varXPath || numTemp || '"]/TradeReference';
--          varTradeReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--          varTemp := varXPath || numTemp || '"]/ImportExport';
--          numImportExport := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--          varTemp := varXPath || numTemp || '"]/BatchNo';
--          varBatchNo := GConst.fncGetNodeValue(nodFinal, varTemp);               
--          varTemp := varXPath || numTemp || '"]/ForwardRate';
--          numFinal := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
--          varTemp := varXPath || numTemp || '"]/EDAmount';
--          numEDAmount := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));          
--          varTemp := varXPath || numTemp || '"]/ForwardFcy';
--          numSerial := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', numSerial);
--          numReverseAmount := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--                select DEAL_BASE_CURRENCY,DEAL_COUNTER_PARTY,
--                       DEAL_BACKUP_DEAL,DEAL_INIT_CODE,DEAL_COMPANY_CODE
--                  into  numCurrencyCode,numLocalBank,numPortfolio,numSubportfolio,numCompany
--                from TRTRAN001 where DEAL_DEAL_NUMBER = varDealReference 
--                and DEAL_record_status between 10200001 and 10200004;
--          select
--            case
--  --          when datWorkDate < deal_maturity_date and deal_forward_rate != numPremium then
--  --            round(numReverseAmount * (deal_forward_rate - numPremium))
--            when numFinal != deal_exchange_rate then
--              decode(deal_buy_sell, GConst.PURCHASEDEAL,
--                Round(numReverseAmount * deal_exchange_rate) - Round(numReverseAmount * numFinal),
--                Round(numReverseAmount * numFinal) - Round(numReverseAmount * deal_exchange_rate))
--            else 0
--            end
--            into numPandL
--            from trtran001
--            where deal_deal_number = varDealReference;
--            numPandL := numEDAmount;
--          varOperation := 'Inserting entries to Hedge Table, if necessary';
--          BEGIN
--            SELECT NVL(max(HEDG_TRADE_SERIAL),0) +1
--            INTO numTradeSerial
--            FROM trtran004
--            WHERE hedg_trade_reference=varTradeReference;
--          EXCEPTION
--          WHEN no_data_found THEN
--            numTradeSerial:=1;
--          END ;
--          BEGIN
--            SELECT NVL(max(hedg_deal_serial),0) +1
--            INTO numSerial
--            FROM trtran004
--            WHERE hedg_deal_number=varDealReference;
--          EXCEPTION
--          WHEN no_data_found THEN
--            numSerial:=1;
--          END ;   
--          
--          
--            insert into trtran004
--            (hedg_company_code,hedg_trade_reference,hedg_deal_number,
--              hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
--              hedg_create_date,hedg_entry_detail,hedg_record_status,
--              hedg_hedging_with,hedg_multiple_currency,HEDG_TRADE_SERIAL,
--              HEDG_BATCH_NUMBER,HEDG_LINKED_DATE)
--            values(numCompany,varTradeReference,varDealReference,
--            numSerial, numReverseAmount,0, Round(numReverseAmount * numFinal),
--            sysdate,NULL,10200012, 32200001,12400002,numTradeSerial,varBatchNo,datWorkDate);
--            
--            
--          varOperation := 'Inserting Hedge Deal Delivery';
--          insert into trtran006(cdel_company_code, cdel_deal_number,
--            cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
--            cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
--            cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
--            cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
--            cdel_entry_detail, cdel_record_status, cdel_trade_reference,
--            Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
--            cdel_spot_rate,cdel_forward_rate,cdel_margin_rate,CDEL_DELIVERY_SERIAL,
--            CDEL_BATCH_NUMBER,cdel_cashflow_date)
--            select deal_company_code, deal_deal_number,
--            deal_serial_number,
--            (select NVL(max(cdel_reverse_serial),0) + 1
--              from trtran006
--              where cdel_deal_number = varDealReference),
--            datWorkdate, deal_hedge_trade, Gconst.Dealdelivery,
--            numReverseAmount, numFinal, Round(numReverseAmount * numFinal), 1,
--            Round(numReverseAmount * numFinal), to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--            SYSDATE, NULL, Gconst.Statusentry, varTradeReference, numTradeSerial, numPandL,
--            varVoucher ,numSpot,numPremium,numMargin,numSerial,varBatchNo,datWorkdate
--            from trtran001
--            where deal_deal_number = varDealReference;
--            if numPandL != 0 then
--              select CDEL_REVERSE_SERIAL into numTemp1
--                from trtran006
--              where cdel_deal_number = varDealReference
--                    and cdel_trade_reference = varTradeReference
--                    and Cdel_Trade_Serial = numTradeSerial;
--
--              varOperation := 'Inserting Current Account voucher for PL';
--              varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--              insert into trtran008 (bcac_company_code, bcac_location_code,
--                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                bcac_create_date, bcac_local_merchant, bcac_record_status,
--                bcac_record_type, bcac_account_number,BCAC_BATCH_NO)
--              select numCompany, deal_location_code, deal_counter_party, varVoucher,
--                datWorkdate, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
--                GConst.TRANSACTIONCREDIT),24900153,24800062,
--                deal_deal_number,numTemp1, 
--                deal_base_currency, 0,
--                0, numPandL, 'Deal Reversal No: ' ||
--                deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
--                (select lbnk_account_number
--                  from trmaster306
--                  where lbnk_pick_code = deal_counter_party),varBatchNo
--                from trtran001
--                where deal_deal_number = varDealReference
--                and deal_serial_number = 1;    
--              varOperation := 'Inserting Interest Current';
--              varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--              insert into trtran008 (bcac_company_code, bcac_location_code,
--                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                bcac_create_date, bcac_local_merchant, bcac_record_status,
--                bcac_record_type, bcac_account_number,BCAC_BATCH_NO)
--              select numCompany, deal_location_code, deal_counter_party, varVoucher,
--                datWorkdate, decode(sign(numPandL), -1, GConst.TRANSACTIONCREDIT,
--                GConst.TRANSACTIONDEBIT),24900030,24800062,
--                deal_deal_number,numTemp1,
--                deal_base_currency, 0,
--                0, (numPandL), 'Deal Reversal No: ' ||
--                deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
--                (select lbnk_account_number
--                  from trmaster306
--                  where lbnk_pick_code = deal_counter_party),varBatchNo
--                from trtran001
--                where deal_deal_number = varDealReference
--                and deal_serial_number = 1;  
--              
--            else
--              varVoucher := NULL;
--            end if;           
--            numError := fncCompleteUtilization(varDealReference,GConst.UTILHEDGEDEAL,datWorkDate);
--            numError := fncCompleteUtilization(varTradeReference,GConst.UTILEXPORTS,datWorkDate);
--        End Loop;
--        numTradeSerial := 0;
--      end if;
--      varOperation := 'Extracting Parameters' || numLocation;
--      docFinal := xmlDom.newDomDocument(xmlTemp);
--      nodFinal := xmlDom.makeNode(docFinal);       
--      varOperation := 'Before Loop';
--      varXPath := '//FORWARDSETTLEMENTS/CROSSFORWARDSETTLEMENT/ROW';
--      nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--      if xmlDom.getLength(nlsTemp) > 0 then
--            varXPath := '//FORWARDSETTLEMENTS/CROSSFORWARDSETTLEMENT/ROW[@NUM="';
--            for numSub in 0..xmlDom.getLength(nlsTemp) -1
--              Loop
--                varOperation := 'Inside Loop';
--                nodTemp := xmlDom.item(nlsTemp, numSub);
--                nmpTemp := xmlDom.getAttributes(nodTemp);
--                nodtemp1 := xmldom.item(nmptemp, 0);
--                numtemp := to_number(xmldom.getnodevalue(nodtemp1));
--                varTradeReference := '';
--                varTemp := varXPath || numTemp || '"]/CImportExport';
--                numImportExport := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--                varTemp := varXPath || numTemp || '"]/CBatchNo';
--                varBatchNo := GConst.fncGetNodeValue(nodFinal, varTemp);
--                varTemp := varXPath || numTemp || '"]/CDealNumber';
--                varDealReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--                varTemp := varXPath || numTemp || '"]/CForwardRate';
--                numFinal := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
--                varTemp := varXPath || numTemp || '"]/CForwardFcy';
--                numReverseAmount := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--                varTemp := varXPath || numTemp || '"]/DealType';
--                varTemp1 := GConst.fncGetNodeValue(nodFinal, varTemp);
--                numSerial := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', numSerial);
--                varOperation := 'Before Batch No DealType';
--                if varTemp1 = 'Other' then
--                  varOperation := 'After Batch No';
--                      select DEAL_BASE_CURRENCY,DEAL_COUNTER_PARTY,
--                             DEAL_BACKUP_DEAL,DEAL_INIT_CODE,DEAL_COMPANY_CODE
--                        into  numCurrencyCode,numLocalBank,numPortfolio,numSubportfolio,numCompany
--                      from TRTRAN001 where DEAL_DEAL_NUMBER = varDealReference 
--                      and DEAL_record_status between 10200001 and 10200004;
--                  select
--                  case
--        --          when datWorkDate < deal_maturity_date and deal_forward_rate != numPremium then
--        --            round(numReverseAmount * (deal_forward_rate - numPremium))
--                  when numFinal != deal_exchange_rate then
--                    decode(deal_buy_sell, GConst.PURCHASEDEAL,
--                      Round(numReverseAmount * deal_exchange_rate) - Round(numReverseAmount * numFinal),
--                      Round(numReverseAmount * numFinal) - Round(numReverseAmount * deal_exchange_rate))
--                  else 0
--                  end
--                  into numPandL
--                  from trtran001
--                  where deal_deal_number = varDealReference;
--                varOperation := 'Inserting Hedge Deal Delivery';
--                insert into trtran006(cdel_company_code, cdel_deal_number,
--                  cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
--                  cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
--                  cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
--                  cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
--                  cdel_entry_detail, cdel_record_status, cdel_trade_reference,
--                  Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
--                  cdel_spot_rate,cdel_forward_rate,cdel_margin_rate,CDEL_DELIVERY_SERIAL,
--                  CDEL_BATCH_NUMBER,cdel_cashflow_date)
--                  select deal_company_code, deal_deal_number,
--                  deal_serial_number,
--                  (select NVL(max(cdel_reverse_serial),0) + 1
--                    from trtran006
--                    where cdel_deal_number = varDealReference),
--                  datWorkdate, deal_hedge_trade, Gconst.Dealdelivery,
--                  numReverseAmount, numFinal, Round(numReverseAmount * numFinal), 1,
--                  Round(numReverseAmount * numFinal), to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--                  SYSDATE, NULL, Gconst.Statusentry, varTradeReference, numTradeSerial, numPandL,
--                  varVoucher ,numSpot,numPremium,numMargin,numSerial,varBatchNo,datWorkdate
--                  from trtran001
--                  where deal_deal_number = varDealReference;
--                  if numPandL != 0 then
--                    select CDEL_REVERSE_SERIAL into numTemp1
--                      from trtran006
--                    where cdel_deal_number = varDealReference
--                          and cdel_trade_reference = varTradeReference
--                          and Cdel_Trade_Serial = numTradeSerial;
--      
--                    varOperation := 'Inserting Current Account voucher for PL';
--                    varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--                    insert into trtran008 (bcac_company_code, bcac_location_code,
--                      bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                      bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                      bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                      bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                      bcac_create_date, bcac_local_merchant, bcac_record_status,
--                      bcac_record_type, bcac_account_number,BCAC_BATCH_NO)
--                    select numCompany, deal_location_code, deal_counter_party, varVoucher,
--                      datWorkdate, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
--                      GConst.TRANSACTIONCREDIT),24900153,24800062,
--                      deal_deal_number,numTemp1, 
--                      deal_base_currency, 0,
--                      0, numPandL, 'Deal Reversal No: ' ||
--                      deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
--                      (select lbnk_account_number
--                        from trmaster306
--                        where lbnk_pick_code = deal_counter_party),varBatchNo
--                      from trtran001
--                      where deal_deal_number = varDealReference
--                      and deal_serial_number = 1;    
--                    varOperation := 'Inserting Interest Current';
--                    varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--                    insert into trtran008 (bcac_company_code, bcac_location_code,
--                      bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                      bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                      bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                      bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                      bcac_create_date, bcac_local_merchant, bcac_record_status,
--                      bcac_record_type, bcac_account_number,BCAC_BATCH_NO)
--                    select numCompany, deal_location_code, deal_counter_party, varVoucher,
--                      datWorkdate, decode(sign(numPandL), -1, GConst.TRANSACTIONCREDIT,
--                      GConst.TRANSACTIONDEBIT),24900030,24800062,
--                      deal_deal_number,numTemp1,
--                      deal_base_currency, 0,
--                      0, (numPandL), 'Deal Reversal No: ' ||
--                      deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
--                      (select lbnk_account_number
--                        from trmaster306
--                        where lbnk_pick_code = deal_counter_party),varBatchNo
--                      from trtran001
--                      where deal_deal_number = varDealReference
--                      and deal_serial_number = 1;  
--                    
--                  else
--                    varVoucher := NULL;
--                  end if;           
--                  numError := fncCompleteUtilization(varDealReference,GConst.UTILHEDGEDEAL,datWorkDate);
--               else
--                  varCompany:= pkgReturnCursor.fncGetDescription(numCompany,2);
--                  varDealReference := 'CASH' || GConst.fncGenerateSerial(Gconst.SERIALDEAL,numCompany);
--                  varOperation := 'Inserting Cash deal to main table';
--                  insert into trtran001
--                    (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
--                    deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
--                    deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
--                    deal_confirm_date,deal_holding_rate,deal_holding_rate1,deal_dealer_holding,deal_dealer_holding1,deal_dealer_remarks,deal_time_stamp,
--                    deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
--                    deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,cdel_forward_rate,
--                    cdel_spot_rate,cdel_margin_rate,deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
--                    deal_bo_remark,deal_analysis_option,deal_analysis_type,deal_analysis_frequency,deal_analysis_selection)
--                  values (numCompany, varDealReference, 1, datWorkDate, 26000001,case when numImportExport < 25900050 then 25300002 else 25300001 end,
--                    25200002,25400001,NumLocalBank,numCurrencyCode, 30400003,numFinal, 1, numReverseAmount,
--                    Round(numCashRate * numReverseAmount),0,0,datWorkDate,datWorkDate,null, 'System',
--                    NULL, 0,0,0,0,varTradeReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--                    to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,sysdate,NULL, 10200001,
--                    null,null,null,0,numFinal,0, 0,
--                    0,0,numPortfolio,0,0,numSubportfolio, NULL,
--                    'Cash Delivery ' || varTradeReference,null,null,null,null);              
--                  varOperation := 'Inserting Cash Deal Cancellation';
--                  insert into trtran006
--                    (cdel_company_code,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
--                    cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
--                    cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
--                    cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
--                    cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
--                    cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark,CDEL_BATCH_NUMBER)
--                  select deal_company_code, deal_deal_number, 1, 1, varTradeReference, deal_local_rate,
--                    datWorkDate, 26000001,27000002,deal_base_amount, deal_exchange_rate, deal_other_amount, 0,
--                    0,0,0,0,0,0,'System',varTradeReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), sysdate,
--                    null, 10200001, null,null,numSerial,0,deal_exchange_rate,0,0,0,33500001,null,null,deal_bank_reference,
--                    deal_bo_remark,varBatchNo
--                    from trtran001
--                    where deal_deal_number = varDealReference;              
--               end if;   
--              End loop;
--      end if;
--    end if;
--    return numError;
--Exception
--        When others then
--          numError := SQLCODE;
--          varError := SQLERRM;
--          varError := GConst.fncReturnError('BillSettle', numError, varMessage,
--                          varOperation, varError);
--          raise_application_error(-20101, varError);
--          RETURN numError;
--End fncExposuresettlement;
Function fncExposuresettlement
    (   RecordDetail in GConst.gClobType%Type)
    return number
    is
--  created by TMM on 31/01/2014
    numError            number;
    numTemp             number;
    numTemp1            NUMBER;
    numAction           number(4);
    numSerial           number(5);
    numLocation         number(8);
    numCompany          number(8);
    numReversal         number(8);
    numImportExport     number(8);    
    numReverseAmount    number(15,2);
    numDealReverse      number(15,2);
    numBillReverse      number(15,2);
    numCashDeal         number(15,2);
    numPandL            number(15,2);
    numFcy              number(15,2);
    numSpot             number(15,6);
    numPremium          number(15,6);
    numMargin           number(15,6);
    numFinal            number(15,6);
    numCashRate         number(15,6);
    numRefrate          number(15,6);
    numEDAmount         number(15,2);
    varCompany          varchar2(15);
    varBatch            varchar2(25);
    varEntity           varchar2(25);
    varVoucher          varchar2(25);
    varTradeReference   varchar2(25);
    varDealReference    varchar2(25);
    varReference        varchar2(25);
    varBatchNo          varchar2(30);
    varXPath            varchar2(1024);
    varTemp             varchar2(1024);
    varTemp1             varchar2(1024);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    datWorkDate         Date;
    datReference        Date;
    xmlTemp             xmlType;
    nlsTemp             xmlDom.DomNodeList;
    nodFinal            xmlDom.domNode;
    docFinal            xmlDom.domDocument;
    nodTemp             xmlDom.domNode;
    nodTemp1            xmlDom.domNode;
    nmpTemp             xmldom.domNamedNodemap;
    numLocalBank        number(8);
    numCompanyCode      number(8);
    numReverseSerial    number(5);
    numCurrencyCode     NUMBER(8);
    numTradeSerial      NUMBER(5);
    numPortfolio        number(8);
    numSubportfolio     number(8);
    numCount            number(3);
    clbTemp             clob;

  Begin
    varMessage := 'Entering fncExposuresettlement Settlement Process';
    numError := 0;
    numDealReverse := 0;
    numBillReverse := 0;
    numCashDeal := 0;

    varOperation := 'Extracting Parameters';
    xmlTemp := xmlType(RecordDetail);
    
      
      
    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationId', numLocation);
    if numAction = GConst.DELETESAVE then
      varBatchNo := GConst.fncXMLExtract(xmlTemp, 'BREL_DELIVERY_BATCH', varBatchNo);
      update trtran004 set hedg_record_status = 10200006
        
      where hedg_batch_number = varBatchNo;
      update trtran006 set cdel_record_status = 10200006 where cdel_batch_number = varBatchNo;
      update trtran008 set bcac_record_status = 10200006 WHERE BCAC_BATCH_NO = varBatchNo;
      
      varoperation:='Populate the entire batch details again so that user can take care of this same using add mode 
                    incase of any changes in the remittace then they ahve take care from previous screen';
      
      INSERT INTO TRTRAN003(
            BREL_COMPANY_CODE, BREL_TRADE_REFERENCE,  BREL_REVERSE_SERIAL,
            BREL_ENTRY_DATE,  BREL_USER_REFERENCE,  BREL_REFERENCE_DATE,
            BREL_REVERSAL_TYPE, BREL_REVERSAL_FCY, BREL_REVERSAL_RATE,
            BREL_REVERSAL_INR,  BREL_PERIOD_CODE,  BREL_TRADE_PERIOD,
            BREL_MATURITY_FROM,   BREL_MATURITY_DATE,  BREL_CREATE_DATE,
            BREL_RECORD_STATUS,   BREL_LOCAL_BANK,
            BREL_REVERSE_REFERENCE, BREL_LOCATION_CODE,  BREL_BATCH_NUMBER,
            BREL_TRADE_CURRENCY,   BREL_LOCAL_CURRENCY,   BREL_IMPORT_EXPORT,
            BREL_USER_PORTFOLIO,  BREL_OTHER_CURRENCY_YESNO,  BREL_PRODUCT_CATEGORY,
            BREL_REMARKS,  BREL_TRANSACTION_DATE,   BREL_SUB_PORTFOLIO )
      select BREL_COMPANY_CODE, BREL_TRADE_REFERENCE,  
            (select nvl(max(sub.BREL_REVERSE_SERIAL),0) from TRTRAN003 sub
             where sub.BREL_DELIVERY_BATCH=varBatchNo
             and sub.BREL_TRADE_REFERENCE=m.BREL_TRADE_REFERENCE)+1 ,
            BREL_ENTRY_DATE,  BREL_USER_REFERENCE,  BREL_REFERENCE_DATE,
            BREL_REVERSAL_TYPE, BREL_REVERSAL_FCY, BREL_REVERSAL_RATE,
            BREL_REVERSAL_INR,  BREL_PERIOD_CODE,  BREL_TRADE_PERIOD,
            BREL_MATURITY_FROM,   BREL_MATURITY_DATE,  sysdate,
              BREL_RECORD_STATUS,   BREL_LOCAL_BANK,
            BREL_REVERSE_REFERENCE, BREL_LOCATION_CODE,  BREL_BATCH_NUMBER,
            BREL_TRADE_CURRENCY,   BREL_LOCAL_CURRENCY,   BREL_IMPORT_EXPORT,
            BREL_USER_PORTFOLIO,  BREL_OTHER_CURRENCY_YESNO,  BREL_PRODUCT_CATEGORY,
            BREL_REMARKS,  BREL_TRANSACTION_DATE,   BREL_SUB_PORTFOLIO
        from TRTRAN003 M
        where BREL_DELIVERY_BATCH=varBatchNo
        and brel_record_Status not in (10200005,10200006);
        
     varoperation:='Update the Record stauts for Remittance of the Batch';
       update trtran003 set BREL_RECORD_STATUS = 10200006 where BREL_DELIVERY_BATCH=varBatchNo;
        
      
      begin  
        for cur_in in(select * from trtran006  where cdel_batch_number = varBatchNo)
        loop
          
          varOperation := 'Settlement entry delete';
          select max(BREL_REVERSE_SERIAL) into numSerial from trtran003;
          if numSerial < 10000 then
            numSerial := 10000;
          end if;
          update trtran001 set deal_record_status = 10200006 
                          where deal_deal_number = cur_in.cdel_deal_number 
                          and DEAL_DEAL_TYPE = 25400001;
          update trtran001 set deal_process_complete = 12400002,
                               deal_complete_date = null 
                          where deal_deal_number = cur_in.cdel_deal_number 
                          and DEAL_DEAL_TYPE != 25400001; 
--          update trtran002 set trad_process_complete = 12400002,
--                               trad_complete_date = null 
--                          where trad_trade_reference = cur_in.cdel_trade_reference;
--          update trtran003 set  BREL_REVERSE_SERIAL = numSerial + 1 where  brel_trade_reference = cur_in.cdel_trade_reference
--                                                                            and BREL_BATCH_NUMBER = cur_in.CDEL_BATCH_NUMBER;    
                                                                            
--          update trtran003 set  BREL_BATCH_NUMBER = ''  where  brel_trade_reference = cur_in.cdel_trade_reference
--                                                                            and BREL_BATCH_NUMBER = cur_in.CDEL_BATCH_NUMBER;

--          update trtran045 set bcrd_process_complete = 12400002,
--                               bcrd_completion_date = null 
--                          where bcrd_buyers_credit = cur_in.cdel_trade_reference;                                                                                      
        end loop;
      end;
    else
     
     
      varOperation := 'Extracting Parameters' || numLocation;
      docFinal := xmlDom.newDomDocument(xmlTemp);
      nodFinal := xmlDom.makeNode(docFinal);       
      varOperation := 'Before Loop';
      varXPath := '//CASHSETTLEMENT/DROW';
      nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
      if xmlDom.getLength(nlsTemp) > 0 then
            varXPath := '//CASHSETTLEMENT/DROW[@DNUM="';
            for numSub in 0..xmlDom.getLength(nlsTemp) -1
              Loop
                varOperation := 'Inside Loop';
                nodTemp := xmlDom.item(nlsTemp, numSub);
                nmpTemp := xmlDom.getAttributes(nodTemp);
                nodtemp1 := xmldom.item(nmptemp, 0);
               
              
                numtemp := to_number(xmldom.getnodevalue(nodtemp1));
                varTemp := varXPath || numTemp || '"]/TradeRefNo';
                varTradeReference := GConst.fncGetNodeValue(nodFinal, varTemp);
                varTemp := varXPath || numTemp || '"]/CashRate';
                numCashRate := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
                varTemp := varXPath || numTemp || '"]/CashFcy';
                numCashDeal := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
                varTemp := varXPath || numTemp || '"]/ImpExp';
                numImportExport := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
                varTemp := varXPath || numTemp || '"]/BatchNo';
                varBatchNo := GConst.fncGetNodeValue(nodFinal, varTemp);              
                numSerial := 1;--GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', numSerial);
          
                begin
                  SELECT DISTINCT BREL_TRADE_CURRENCY,BREL_LOCAL_BANK,
                  33399999,33899999, BREL_COMPANY_CODE 
                  into  numCurrencyCode,numLocalBank,numPortfolio,numSubportfolio,numCompany
                  FROM TRTRAN003 
                  WHERE BREL_BATCH_NUMBER = varTradeReference
                  AND BREL_RECORD_STATUS NOT IN(10200005,10200006);
--                  select TRAD_TRADE_CURRENCY,TRAD_LOCAL_BANK,
--                         TRAD_PRODUCT_CATEGORY,TRAD_SUBPRODUCT_CODE,TRAD_COMPANY_CODE
--                    into  numCurrencyCode,numLocalBank,numPortfolio,numSubportfolio,numCompany
--                  from trtran002 where trad_trade_reference = varTradeReference 
--                  and trad_record_status between 10200001 and 10200004
--                  UNION ALL
--                  select BCRD_CURRENCY_CODE,BCRD_LOCAL_BANK,
--                         BCRD_PRODUCT_CATEGORY,BCRD_SUBPRODUCT_CODE,BCRD_COMPANY_CODE
--                  from trtran045 where BCRD_BUYERS_CREDIT = varTradeReference 
--                  and BCRD_RECORD_STATUS between 10200001 and 10200004                  
--                  UNION ALL
--                  select DISTINCT TLON_CURRENCY_CODE,TLON_LOCAL_BANK,
--                         33399999,33899999,TLON_COMPANY_CODE
--                  from TRTRAN081 where TLON_LOAN_NUMBER = varTradeReference 
--                  and TLON_RECORD_STATUS between 10200001 and 10200004;                    
                exception when no_data_found then
                   numCurrencyCode := 0;
                   numLocalBank := 0;
                   numPortfolio := 0;
                   numSubportfolio :=0;
                   numCompany := 0;
                end ;
              -- IF numAction = GConst.EDITSAVE then
                  varCompany:= pkgReturnCursor.fncGetDescription(numCompany,2);
                  varDealReference := 'CASH' || GConst.fncGenerateSerial(Gconst.SERIALDEAL,numCompany);                  
                  varOperation := 'Inserting Cash deal to main table';
                  insert into trtran001
                    (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
                    deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
                    deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
                    deal_confirm_date,deal_dealer_remarks,deal_time_stamp,
                    deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
                    deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,
                    deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
                    deal_bo_remark)
                  values (numCompany, varDealReference, 1, datWorkDate, 26000001,case when numImportExport < 25900050 then 25300002 else 25300001 end,
                    25200002,25400001,NumLocalBank,numCurrencyCode, 30400003,numCashRate, 1, numCashDeal,
                    Round(numCashRate * numCashDeal),0,0,datWorkDate,datWorkDate,null, 'System',
                    NULL,varTradeReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
                    to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,sysdate,NULL, 10200001,
                    null,null,null,0,numCashRate,0,numPortfolio,0,0,numSubportfolio, NULL,
                    'Cash Delivery ' || varTradeReference);              
                  varOperation := 'Inserting Cash Deal Cancellation';
                  insert into trtran006
                    (cdel_company_code,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
                    cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
                    cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
                    cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
                    cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
                    cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark,CDEL_BATCH_NUMBER)
                  select deal_company_code, deal_deal_number, 1, 1, varTradeReference, deal_local_rate,
                    datWorkDate, 26000001,27000002,deal_base_amount, deal_exchange_rate, deal_other_amount, 0,
                    0,0,0,0,0,0,'System',varTradeReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), sysdate,
                    null, 10200001, null,null,numSerial,0,deal_exchange_rate,0,0,0,33500001,null,null,deal_bank_reference,
                    deal_bo_remark,varBatchNo
                    from trtran001
                    where deal_deal_number = varDealReference;              
                  begin 
                   select nvl(MAX(HEDG_TRADE_SERIAL),1) +1
                   into  numserial 
                    from trtran004 
                    where hedg_trade_reference=varTradeReference;
                  exception 
                   when no_data_found then
                     numserial:=1;
                  end ;
                  varOperation := 'Inserting Cash deal Linking details';
--                  insert into trtran004
--                  (hedg_company_code,hedg_trade_reference,hedg_deal_number,
--                    hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
--                    hedg_create_date,hedg_entry_detail,hedg_record_status,
--                    hedg_hedging_with,hedg_multiple_currency,HEDG_TRADE_SERIAL,
--                    HEDG_BATCH_NUMBER,HEDG_LINKED_DATE)
--                  values(numCompany,varTradeReference,varDealReference,
--                  1, numCashDeal,0, Round(numCashDeal * numCashRate),
--                  sysdate,NULL,10200012, 32200001,12400002,numserial,varBatchNo,datWorkDate);
                  varOperation := 'After linking Cash deal Linking details';                
                  --numError := fncCompleteUtilization(varTradeReference,GConst.UTILEXPORTS,datWorkDate);
               -- END IF;
              End loop;
      end if;
      
      docFinal := xmlDom.newDomDocument(xmlTemp);
      nodFinal := xmlDom.makeNode(docFinal);
      varXPath := '//FORWARDSETTLEMENT/DROW';
      nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
      if xmlDom.getLength(nlsTemp) > 0 then
        varXPath := '//FORWARDSETTLEMENT/DROW[@DNUM="';
        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.item(nlsTemp, numSub);
          nmpTemp := xmlDom.getAttributes(nodTemp);
          nodTemp1 := xmlDom.item(nmpTemp, 0);
          numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
          varTemp := varXPath || numTemp || '"]/DealNumber';
          varDealReference := GConst.fncGetNodeValue(nodFinal, varTemp);
                  
          varTemp := varXPath || numTemp || '"]/TradeRefNo';           
          varTradeReference := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp := varXPath || numTemp || '"]/ImpExp';
          numImportExport := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/BatchNo';
          varBatchNo := GConst.fncGetNodeValue(nodFinal, varTemp);               
          varTemp := varXPath || numTemp || '"]/ForwardRate';
          numFinal := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
          varTemp := varXPath || numTemp || '"]/EDAmount';
          numEDAmount := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));          
          varTemp := varXPath || numTemp || '"]/ForwardFcy';
          numReverseAmount := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
          varTemp := varXPath || numTemp || '"]/ReferenceRate';
          numRefrate := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));          
          numSerial := 1;--GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', numSerial);
                select DEAL_BASE_CURRENCY,DEAL_COUNTER_PARTY,
                       DEAL_BACKUP_DEAL,DEAL_INIT_CODE,DEAL_COMPANY_CODE
                  into  numCurrencyCode,numLocalBank,numPortfolio,numSubportfolio,numCompany
                from TRTRAN001 where DEAL_DEAL_NUMBER = varDealReference 
                and DEAL_record_status between 10200001 and 10200004;
          select
            case
  --          when datWorkDate < deal_maturity_date and deal_forward_rate != numPremium then
  --            round(numReverseAmount * (deal_forward_rate - numPremium))
            when numFinal != deal_exchange_rate then
              decode(deal_buy_sell, GConst.PURCHASEDEAL,
                Round(numReverseAmount * deal_exchange_rate) - Round(numReverseAmount * numFinal),
                Round(numReverseAmount * numFinal) - Round(numReverseAmount * deal_exchange_rate))
            else 0
            end
            into numPandL
            from trtran001
            where deal_deal_number = varDealReference;
            numPandL := numEDAmount;
          varOperation := 'Inserting entries to Hedge Table, if necessary';
--          BEGIN
--            SELECT NVL(max(HEDG_TRADE_SERIAL),0) +1
--            INTO numTradeSerial
--            FROM trtran004
--            WHERE hedg_trade_reference=varTradeReference;
--          EXCEPTION
--          WHEN no_data_found THEN
--            numTradeSerial:=1;
--          END ;
--          BEGIN
--            SELECT NVL(max(hedg_deal_serial),0) +1
--            INTO numSerial
--            FROM trtran004
--            WHERE hedg_deal_number=varDealReference;
--          EXCEPTION
--          WHEN no_data_found THEN
--            numSerial:=1;
--          END ;   
          
          
--            insert into trtran004
--            (hedg_company_code,hedg_trade_reference,hedg_deal_number,
--              hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
--              hedg_create_date,hedg_entry_detail,hedg_record_status,
--              hedg_hedging_with,hedg_multiple_currency,HEDG_TRADE_SERIAL,
--              HEDG_BATCH_NUMBER,HEDG_LINKED_DATE)
--            values(numCompany,varTradeReference,varDealReference,
--            numSerial, numReverseAmount,0, Round(numReverseAmount * numFinal),
--            sysdate,NULL,10200012, 32200001,12400002,numTradeSerial,varBatchNo,datWorkDate);
            
            
          varOperation := 'FORWARDSETTLEMENT Inserting Hedge Deal Delivery';
          insert into trtran006(cdel_company_code, cdel_deal_number,
            cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
            cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
            cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
            cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
            cdel_entry_detail, cdel_record_status, cdel_trade_reference,
            Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
            cdel_spot_rate,cdel_forward_rate,cdel_margin_rate,CDEL_DELIVERY_SERIAL,
            CDEL_BATCH_NUMBER,cdel_cashflow_date,CDEL_REFERENCE_RATE)
            select deal_company_code, deal_deal_number,
            deal_serial_number,
            (select NVL(max(cdel_reverse_serial),0) + 1
              from trtran006
              where cdel_deal_number = varDealReference),
            datWorkdate, deal_hedge_trade, Gconst.Dealdelivery,
            numReverseAmount, numFinal, Round(numReverseAmount * numFinal), 1,
            Round(numReverseAmount * numFinal), to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
            SYSDATE, NULL, Gconst.Statusentry, varTradeReference, numTradeSerial, numPandL,
            varVoucher ,numSpot,numPremium,numMargin,numSerial,varBatchNo,datWorkdate,numRefrate
            from trtran001
            where deal_deal_number = varDealReference;
            if numPandL != 0 then
              select CDEL_REVERSE_SERIAL into numTemp1
                from trtran006
              where cdel_deal_number = varDealReference
                    and cdel_trade_reference = varTradeReference
                    and Cdel_Trade_Serial = numTradeSerial;

              varOperation := 'Inserting Current Account voucher for PL';
              varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
              insert into trtran008 (bcac_company_code, bcac_location_code,
                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                bcac_create_date, bcac_local_merchant, bcac_record_status,
                bcac_record_type, bcac_account_number,BCAC_BATCH_NO)
              select numCompany, deal_location_code, deal_counter_party, varVoucher,
                datWorkdate, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
                GConst.TRANSACTIONCREDIT),24900049,24800051,
                deal_deal_number,numTemp1, 
                deal_base_currency, 0,
                0, numPandL, 'Deal Reversal No: ' ||
                deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
                (select lbnk_account_number
                  from trmaster306
                  where lbnk_pick_code = deal_counter_party),varBatchNo
                from trtran001
                where deal_deal_number = varDealReference
                and deal_serial_number = 1;    
              varOperation := 'Inserting Interest Current';
              varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
              insert into trtran008 (bcac_company_code, bcac_location_code,
                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                bcac_create_date, bcac_local_merchant, bcac_record_status,
                bcac_record_type, bcac_account_number,BCAC_BATCH_NO)
              select numCompany, deal_location_code, deal_counter_party, varVoucher,
                datWorkdate, decode(sign(numPandL), -1, GConst.TRANSACTIONCREDIT,
                GConst.TRANSACTIONDEBIT),24900030,24800051,
                deal_deal_number,numTemp1,
                deal_base_currency, 0,
                0, (numPandL), 'Deal Reversal No: ' ||
                deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
                (select lbnk_account_number
                  from trmaster306
                  where lbnk_pick_code = deal_counter_party),varBatchNo
                from trtran001
                where deal_deal_number = varDealReference
                and deal_serial_number = 1;  
              
            else
              varVoucher := NULL;
            end if;           
            numError := fncCompleteUtilization(varDealReference,GConst.UTILHEDGEDEAL,datWorkDate);
            --numError := fncCompleteUtilization(varTradeReference,GConst.UTILEXPORTS,datWorkDate);
        End Loop;
        numTradeSerial := 0;
      end if;
      varOperation := 'Extracting Parameters' || numLocation;
      docFinal := xmlDom.newDomDocument(xmlTemp);
      nodFinal := xmlDom.makeNode(docFinal);       
      varOperation := 'Before Loop';
      varXPath := '//CROSSFORWARDSETTLEMENT/DROW';
      nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
      if xmlDom.getLength(nlsTemp) > 0 then
            varXPath := '//CROSSFORWARDSETTLEMENT/DROW[@DNUM="';
            for numSub in 0..xmlDom.getLength(nlsTemp) -1
              Loop
                varOperation := 'Inside Loop';
                nodTemp := xmlDom.item(nlsTemp, numSub);
                nmpTemp := xmlDom.getAttributes(nodTemp);
                nodtemp1 := xmldom.item(nmptemp, 0);
                numtemp := to_number(xmldom.getnodevalue(nodtemp1));
                varTradeReference := '';
                varTemp := varXPath || numTemp || '"]/CImpExp';
                numImportExport := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
                varTemp := varXPath || numTemp || '"]/CBatchNo';
                varBatchNo := GConst.fncGetNodeValue(nodFinal, varTemp);
                varTemp := varXPath || numTemp || '"]/CDealNumber';
                varDealReference := GConst.fncGetNodeValue(nodFinal, varTemp);
                varTemp := varXPath || numTemp || '"]/CForwardRate';
                numFinal := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
                varTemp := varXPath || numTemp || '"]/CForwardFcy';
                numReverseAmount := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
                varTemp := varXPath || numTemp || '"]/DealType';
                varTemp1 := GConst.fncGetNodeValue(nodFinal, varTemp);
                numSerial := 1;
                varOperation := 'Before Batch No DealType';
                if varTemp1 = 'Other' then
                  varOperation := 'After Batch No';
                      select DEAL_BASE_CURRENCY,DEAL_COUNTER_PARTY,
                             DEAL_BACKUP_DEAL,DEAL_INIT_CODE,DEAL_COMPANY_CODE
                        into  numCurrencyCode,numLocalBank,numPortfolio,numSubportfolio,numCompany
                      from TRTRAN001 where DEAL_DEAL_NUMBER = varDealReference 
                      and DEAL_record_status between 10200001 and 10200004;
                  select
                  case
        --          when datWorkDate < deal_maturity_date and deal_forward_rate != numPremium then
        --            round(numReverseAmount * (deal_forward_rate - numPremium))
                  when numFinal != deal_exchange_rate then
                    decode(deal_buy_sell, GConst.PURCHASEDEAL,
                      Round(numReverseAmount * deal_exchange_rate) - Round(numReverseAmount * numFinal),
                      Round(numReverseAmount * numFinal) - Round(numReverseAmount * deal_exchange_rate))
                  else 0
                  end
                  into numPandL
                  from trtran001
                  where deal_deal_number = varDealReference;
                  delete from temp;commit;
                  insert into temp values('varDealReference',varDealReference);commit;
                varOperation := 'CROSSFORWARDSETTLEMENT Inserting Hedge Deal Delivery';
                insert into trtran006(cdel_company_code, cdel_deal_number,
                  cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
                  cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
                  cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
                  cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
                  cdel_entry_detail, cdel_record_status, cdel_trade_reference,
                  Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
                  cdel_spot_rate,cdel_forward_rate,cdel_margin_rate,CDEL_DELIVERY_SERIAL,
                  CDEL_BATCH_NUMBER,cdel_cashflow_date)
                  select deal_company_code, deal_deal_number,
                  deal_serial_number,
                  (select NVL(max(cdel_reverse_serial),0) + 1
                    from trtran006
                    where cdel_deal_number = varDealReference),
                  datWorkdate, deal_hedge_trade, Gconst.Dealdelivery,
                  numReverseAmount, numFinal, Round(numReverseAmount * numFinal), 1,
                  Round(numReverseAmount * numFinal), to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
                  SYSDATE, NULL, Gconst.Statusentry, varTradeReference, numTradeSerial, numPandL,
                  varVoucher ,numSpot,numPremium,numMargin,numSerial,varBatchNo,datWorkdate
                  from trtran001
                  where deal_deal_number = varDealReference;
                  if numPandL != 0 then
                    select CDEL_REVERSE_SERIAL into numTemp1
                      from trtran006
                    where cdel_deal_number = varDealReference
                          and cdel_trade_reference = varTradeReference
                          and Cdel_Trade_Serial = numTradeSerial;
      
                    varOperation := 'Inserting Current Account voucher for PL';
                    varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
                    insert into trtran008 (bcac_company_code, bcac_location_code,
                      bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                      bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                      bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                      bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                      bcac_create_date, bcac_local_merchant, bcac_record_status,
                      bcac_record_type, bcac_account_number,BCAC_BATCH_NO)
                    select numCompany, deal_location_code, deal_counter_party, varVoucher,
                      datWorkdate, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
                      GConst.TRANSACTIONCREDIT),24900049,24800051,
                      deal_deal_number,numTemp1, 
                      deal_base_currency, 0,
                      0, numPandL, 'Deal Reversal No: ' ||
                      deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
                      (select lbnk_account_number
                        from trmaster306
                        where lbnk_pick_code = deal_counter_party),varBatchNo
                      from trtran001
                      where deal_deal_number = varDealReference
                      and deal_serial_number = 1;    
                    varOperation := 'Inserting Interest Current';
                    varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
                    insert into trtran008 (bcac_company_code, bcac_location_code,
                      bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                      bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                      bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                      bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                      bcac_create_date, bcac_local_merchant, bcac_record_status,
                      bcac_record_type, bcac_account_number,BCAC_BATCH_NO)
                    select numCompany, deal_location_code, deal_counter_party, varVoucher,
                      datWorkdate, decode(sign(numPandL), -1, GConst.TRANSACTIONCREDIT,
                      GConst.TRANSACTIONDEBIT),24900030,24800051,
                      deal_deal_number,numTemp1,
                      deal_base_currency, 0,
                      0, (numPandL), 'Deal Reversal No: ' ||
                      deal_deal_number, sysdate,25399999,GConst.STATUSENTRY, 23800002,
                      (select lbnk_account_number
                        from trmaster306
                        where lbnk_pick_code = deal_counter_party),varBatchNo
                      from trtran001
                      where deal_deal_number = varDealReference
                      and deal_serial_number = 1;  
                    
                  else
                    varVoucher := NULL;
                  end if;           
                  numError := fncCompleteUtilization(varDealReference,GConst.UTILHEDGEDEAL,datWorkDate);
               else
                  varCompany:= pkgReturnCursor.fncGetDescription(numCompany,2);
                  varDealReference := 'CASH' || GConst.fncGenerateSerial(Gconst.SERIALDEAL,numCompany);
                  varOperation := 'Inserting Cash deal to main table';
                  insert into trtran001
                    (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
                    deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
                    deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
                    deal_confirm_date,deal_dealer_remarks,deal_time_stamp,
                    deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
                    deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,
                    deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
                    deal_bo_remark)
                  values (numCompany, varDealReference, 1, datWorkDate, 26000001,case when numImportExport < 25900050 then 25300002 else 25300001 end,
                    25200002,25400001,NumLocalBank,numCurrencyCode, 30400003,numFinal, 1, numReverseAmount,
                    Round(numCashRate * numReverseAmount),0,0,datWorkDate,datWorkDate,null, 'System',
                    NULL,varTradeReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
                    to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,sysdate,NULL, 10200001,
                    null,null,null,0,numFinal,0,numPortfolio,0,0,numSubportfolio, NULL,
                    'Cash Delivery ' || varTradeReference);              
                  varOperation := 'Inserting Cash Deal Cancellation';
                  insert into trtran006
                    (cdel_company_code,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
                    cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
                    cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
                    cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
                    cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
                    cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark,CDEL_BATCH_NUMBER)
                  select deal_company_code, deal_deal_number, 1, 1, varTradeReference, deal_local_rate,
                    datWorkDate, 26000001,27000002,deal_base_amount, deal_exchange_rate, deal_other_amount, 0,
                    0,0,0,0,0,0,'System',varTradeReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), sysdate,
                    null, 10200001, null,null,numSerial,0,deal_exchange_rate,0,0,0,33500001,null,null,deal_bank_reference,
                    deal_bo_remark,varBatchNo
                    from trtran001
                    where deal_deal_number = varDealReference;              
               end if;   
              End loop;
      end if;
    end if;
    return numError;
Exception
        When others then
          numError := SQLCODE;
          varError := SQLERRM;
          varError := GConst.fncReturnError('BillSettle', numError, varMessage,
                          varOperation, varError);
          raise_application_error(-20101, varError);
          RETURN numError;
End fncExposuresettlement;
Function fncLoanDeal
    (   RecordDetail in GConst.gClobType%Type,
        TradeReference in varchar2)
    return number
    is
--  Created on 21/05/08m
    numError            number;
    numTemp             number;
    numAction           number(4);
    numSerial           number(5);
    numSerial1          number(5);
    numsubserial        number(5);
    numStatus           number(8);
    numCompany          number(8);
    numLocation         number(8);
    numCode             number(8);
    numCode1            number(8);
    numCode2            number(8);
    numCode4            number(8);
    numFcy              number(15,4);
    Numfcy1             Number(15,4);
--Updated From cygnet
    Numamount1          Number(15,4); -- ishwarachandra
    Numutilization1     Number(15,4);
--
    numInr              number(15,2);
    numRate             number(15,6);
    numRate1            number(15,6);
    Numrate2            Number(15,6);
    numCashRate         number(15,6);
 --Updated from Cygnet
    Numfinalrate        Number(15,6);
    numBaseRate         number(15,6);
    numBaseRate1        number(15,6);
    numBaseRate2        number(15,6);
    Numbasefinalrate    Number(15,6);
--
    numReversed         number(15,4);
    numPL               number(15,2);
    numRateInr          number(15,2);
    numDealReverse      number(15,2);
    numBillReverse      number(15,2);
    varReference        varchar2(25);
    varReference1       varchar2(25);
    varReference2       varchar2(25);
    varTrade            varchar2(25);
    varEntity           varchar2(30);
    varXPath            varchar2(1024);
    varTemp             varchar2(1024);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    datWorkDate         Date;
    datMaturity         date;
    datTemp             date;
    datReference        date;
    xmlTemp             xmlType;
    nlsTemp             xmlDom.DomNodeList;
    nodFinal            xmlDom.domNode;
    docFinal            xmlDom.domDocument;
    nodTemp             xmlDom.domNode;
    nodTemp1            xmlDom.domNode;
    nmpTemp             xmldom.domNamedNodemap;

    clbTemp             clob;
Begin
    numError := 0;

    xmlTemp := xmlType(RecordDetail);
    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
    numCompany := GConst.fncXMLExtract(xmlTemp, 'BREL_COMPANY_CODE', numCompany);
    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationId', numLocation);
    varTrade := GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_REFERENCE', varTrade);
    numSerial := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', varTrade);
    datReference := GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datReference);
    numBillReverse := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_FCY', numBillReverse);
    numCashRate :=  GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_RATE', numRate);

    docFinal := xmlDom.newDomDocument(xmlTemp);
    nodFinal := xmlDom.makeNode(docFinal);

    varOperation := 'Checking for Deal Delivery';
    varXPath := '//CommandSet/DealDetails/ReturnFields/ROWD[@NUM]';
    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
    numDealReverse := 0;

    if xmlDom.getLength(nlsTemp) > 0 then
      varXPath := '//CommandSet/DealDetails/ReturnFields/ROWD[@NUM="';
        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.item(nlsTemp, numSub);
          nmpTemp := xmlDom.getAttributes(nodTemp);
          nodTemp1 := xmlDom.item(nmpTemp, 0);
          numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
          varTemp := varXPath || numTemp || '"]/RecordStatus';
          numStatus := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/DealNumber';
          varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp := varXPath || numTemp || '"]/TradeReference';
          varTrade := GConst.fncGetNodeValue(nodFinal, varTemp);
--          varTemp := varXPath || numTemp || '"]/HedgedBase';
--          Numfcy1 := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
          varTemp := varXPath || numTemp || '"]/SpotRate'; --Updated From cygnet
          Numrate := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
  --Updated from Cygnet
  -- Node Name changed from FrwRate to Premium for TOI by TMM 31/01/14
          varTemp := varXPath || numTemp || '"]/Premium';
          numRate1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

          varTemp := varXPath || numTemp || '"]/MarginRate';
          numRate2 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

          varTemp := varXPath || numTemp || '"]/FinalRate';
          Numfinalrate := To_Number(Gconst.Fncgetnodevalue(Nodfinal, Vartemp));
 --
          varTemp := varXPath || numTemp || '"]/ReverseNow';
          numFcy := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          numDealReverse := numDealReverse + numFcy;
          varTemp := varXPath || numTemp || '"]/SerialNumber';
          numSerial1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/SubserialNumber';
          numsubserial := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/HedgingWith';
          numcode2 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

        if numcode2=Gconst.ForwardContract then
           if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
--Updated from Cygnet
                if numBillReverse > numDealReverse then
                  prcCashDealEntry(datWorkDate,varTrade,numCashRate,numBillReverse - numDealReverse ,datWorkDate);
                End if;

                select deal_spot_rate,deal_forward_rate,
                       deal_margin_rate,deal_exchange_rate
                  into numBaseRate, numBaseRate1,
                       numBaseRate2, numbaseFinalRate
                  from trtran001
                  Where Deal_Deal_Number = Varreference;
--
                if numCode = GConst.INDIANRUPEE then
                  numInr := Round(numFcy * numRate);
                  numFcy1 := 0.00;
                else
                  numFcy1 := Round(numFcy * numRate);
                  numInr := Round(numFcy * numRate1);
                end if;
 -- For Early Delivery the premium / discount is taken as Profit / Loss
-- Added by TMM on 30/05/13
                if datMaturity > datReference then
                  numPL := Round(numFcy * numRate1);
                elsif numFinalRate != numBaseFinalRate then -- Updated from Cygnet
                  If Numcode1 = Gconst.Purchasedeal Then
                    numPL := Round(numFCY * numBaseFinalRate) - Round(numFCY * numFinalRate); -- Updated From Cygnet
                  Elsif Numcode1 = Gconst.Saledeal Then
                    numPL := Round(numFCY * numFinalRate) - Round(numFCY * numBaseFinalRate); -- Updated from Cygnet
                  end if;
                else
                  numPL := 0;
                End if;

                if numStatus = GConst.LOTNEW then

                  if numPl != 0 then
                    varOperation := 'Inserting voucher for PL';
                    varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
                    insert into trtran008 (bcac_company_code, bcac_location_code,
                      bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                      bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                      bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                      bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                      bcac_create_date, bcac_local_merchant, bcac_record_status,
                      bcac_record_type, bcac_account_number)
                    select numCompany, numLocation, deal_counter_party, varReference1,
                      datMaturity, decode(sign(numPL), -1, GConst.TRANSACTIONDEBIT,
                      GConst.TRANSACTIONCREDIT),GConst.ACEXCHANGE,
                      decode(numCode1,GConst.PURCHASEDEAL,
                      GConst.EVENTPURCHASE, GConst.EVENTSALE),
                      varReference, 0, deal_base_currency, deal_base_amount,
                      numRate, deal_amount_local, 'Deal Reversal No: ' ||
                      deal_deal_number, sysdate,30999999,GConst.STATUSENTRY, 23800002,
                      (select lbnk_account_number
                        from trmaster306
                        where lbnk_pick_code = deal_counter_party)
                      from trtran001
                      where deal_deal_number = varReference
                      and deal_serial_number = numSerial;
                  end if;

                  varOperation := 'Inserting Hedge Deal Delivery';
                  insert into trtran006(cdel_company_code, cdel_deal_number,
                    cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
                    cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
                    cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
                    cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
                    cdel_entry_detail, cdel_record_status, cdel_trade_reference,
                    Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
                    cdel_spot_rate,cdel_forward_rate,cdel_margin_rate) -- Updated from Cygnet
                  values(numCompany, varReference, 1,
                    (select NVL(max(cdel_reverse_serial),0) + 1
                      from trtran006
                      where cdel_deal_number = varReference),
                    Datworkdate, Gconst.Hedgedeal, Gconst.Dealdelivery,
                    numFcy, numFinalRate, numFcy1, numRate1, numInr, -- Updated From Cygnet
                    to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
                    Sysdate, Null, Gconst.Statusentry, Vartrade, Numserial,
                    numPL, varReference1,numrate,numrate1,numrate2); --Updated From Cygnet
                elsif numAction = GConst.LOTMODIFIED then
                  if numFcy > 0 then
                    varOperation := 'Updating Hedge Deal Delivery';
                    update trtran006
                      set cdel_cancel_amount = numFcy,
                      cdel_other_amount = numFcy1,
                      cdel_cancel_rate = numRate,
                      cdel_local_rate = numRate1,
                      cdel_cancel_inr = numInr
                      where cdel_trade_reference = varTrade
                      and cdel_trade_serial = numSerial;
                  else
                    varOperation := 'Deleting Hedge Deal Delivery';
                    update trtran006
                      set cdel_record_status = GConst.STATUSDELETED
                      where cdel_trade_reference = varTrade
                      and cdel_trade_serial = numSerial;
                  end if;
                end if;

                numError := fncCompleteUtilization(varReference,  GConst.UTILHEDGEDEAL,
                                datWorkDate);
           -- End Loop;

          elsif numAction in (GConst.DELETESAVE, GConst.CONFIRMSAVE) then
              varOperation := 'Processing for Delete / Confirm';
              select decode(numAction,
                GConst.DELETESAVE, GConst.STATUSDELETED,
                GConst.CONFIRMSAVE,GConst.STATUSAUTHORIZED)
                into numStatus
                from dual;

              update trtran006
                set cdel_record_status = numStatus
                where cdel_trade_reference = varTrade
                and cdel_trade_serial = numSerial;
          End if;

      elsif numcode2= Gconst.OptionContract then
        if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
            if numStatus = GConst.LOTNEW then
                  varOperation := 'Inserting Hedge Deal Delivery';
                  insert into trtran073(corv_company_code, corv_deal_number,
                    corv_serial_number, corv_subserial_number,corv_reverse_serial,
                    corv_exercise_date,corv_exercise_type,  corv_base_amount,
                    corv_exercise_rate, corv_other_amount, corv_wash_rate,
                    corv_time_stamp, corv_create_date,
                    corv_record_status, corv_trade_reference,
                    corv_trade_serial)
                  values(numCompany, varReference,
                    numserial1,numsubserial,
                    (select NVL(max(corv_reverse_serial),0) + 1
                      from trtran073
                      where corv_deal_number = varReference),
                    datWorkDate,  GConst.DEALDELIVERY,
                    numFcy, numRate, numFcy1, numRate1,
                    to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
                    sysdate,  GConst.STATUSENTRY, varTrade, numSerial);
                elsif numAction = GConst.LOTMODIFIED then
                  if numFcy > 0 then
                    varOperation := 'Updating Hedge Deal Delivery';
                    update trtran073
                      set corv_base_amount = numFcy,
                      corv_other_amount = numFcy1,
                      corv_exercise_rate = numRate,
                      --cdel_local_rate = numRate1,
                      --cdel_cancel_inr = numInr
                      corv_record_status =10200004
                      where corv_trade_reference = varTrade
                      and corv_trade_serial = numSerial;
                  else
                    varOperation := 'Deleting Hedge Deal Delivery';
                    update trtran073
                      set corv_record_status = GConst.STATUSDELETED
                      where corv_trade_reference = varTrade
                      and corv_trade_serial = numSerial;
                  end if;
                end if;

                numError := fncCompleteUtilization(varReference,  GConst.UTILOPTIONHEDGEDEAL,
                                datWorkDate,numSerial1);
         --   End Loop;

          elsif numAction in (GConst.DELETESAVE, GConst.CONFIRMSAVE) then
              varOperation := 'Processing for Delete / Confirm';
              select decode(numAction,
                GConst.DELETESAVE, GConst.STATUSDELETED,
                GConst.CONFIRMSAVE,GConst.STATUSAUTHORIZED)
                into numStatus
                from dual;

              update trtran073
                set corv_record_status = numStatus
                where corv_trade_reference = varTrade
                and corv_trade_serial = numSerial;
         End if;
     end if;
   end loop;
  End if;

    --------------- Added By Manjunath Reddy For Reversing OF CrossCurrency Deals


    varOperation := 'Checking for Deal Delivery';
    varXPath := '//CommandSet/CrossDealDetails/ReturnFields/ROWD[@NUM]';
    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);

    if xmlDom.getLength(nlsTemp) > 0 then
 --     numRate :=  GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_RATE', numRate);
      varXPath := '//CommandSet/CrossDealDetails/ReturnFields/ROWD[@NUM="';


      if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then

        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.item(nlsTemp, numSub);
          nmpTemp := xmlDom.getAttributes(nodTemp);
          nodTemp1 := xmlDom.item(nmpTemp, 0);
          numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
          varTemp := varXPath || numTemp || '"]/RecordStatus';
          numStatus := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/DealNumber';
          varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp := varXPath || numTemp || '"]/TradeReference';
          varTrade := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp := varXPath || numTemp || '"]/HedgedBase';
          numFcy1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/BaseRate';
          numRate := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/REVERSEAMOUNT';
          numFcy := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numtemp || '"]/DeliveryFrom';
          varReference2 := GConst.fncGetNodeValue(nodFinal, varTemp);

          select pkgReturnCursor.fncRollover(deal_deal_number,2),
            pkgReturnCursor.fncRollover(deal_deal_number,4),
            pkgReturnCursor.fncRollover(deal_deal_number),
            deal_other_currency, deal_buy_sell
            into numRate2, numRate1, datMaturity, numCode, numCode1
            from trtran001
            where deal_deal_number = varReference;

          if numCode = GConst.INDIANRUPEE then
            numInr := Round(numFcy * numRate);
            numRateInr:= numRate;
            numFcy1 := 0.00;
          else
            numFcy1 := Round(numFcy * numRate);
            numInr := Round(numFcy * numRate1);
            numRateInr:= numRate1;
          end if;

          if numRate != numRate2 then

            if numCode1 = GConst.PURCHASEDEAL then
              numPL := Round(numFCY * numRate) - Round(numFCY * numRate2);
            elsif numCode1 = GConst.SALEDEAL then
              numPL := Round(numFCY * numRate2) - Round(numFCY * numRate);
            end if;
          else
            numPL := 0;
          End if;

          if numStatus = GConst.LOTNEW then


            varOperation := 'Inserting Hedge Deal Delivery';
            insert into trtran006(cdel_company_code, cdel_deal_number,
              cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
              cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
              cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
              cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
              cdel_entry_detail, cdel_record_status, cdel_trade_reference,
              cdel_trade_serial, cdel_profit_loss, cdel_pl_voucher,
              cdel_delivery_from, cdel_delivery_serial)
            values(numCompany, varReference, 1,
              (select NVL(max(cdel_reverse_serial),0) + 1
                from trtran006
                where cdel_deal_number = varReference),
              datWorkDate, GConst.HEDGEDEAL, GConst.DEALDELIVERY,
              numFcy, numRate, numFcy1, numRate1, numInr,
              to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
              sysdate, null, GConst.STATUSENTRY, varTrade, numSerial,
              numPL, varReference1,varReference2,1);

            varOperation := 'Inserting Bills Send For Collection';

            varOperation := 'Selecting particulars of Trade Reference';
            select trad_company_code, trad_buyer_seller, trad_trade_currency,
              trad_product_code, trad_product_description,
              trad_import_export
              into numCompany, numCode, numCode1, numCode2,
              varTemp,  numCode4
              from TradeRegister
              where trad_trade_reference = varTrade;

            varOperation := 'Getting Serial Number';
            varReference1 := pkgReturnCursor.fncGetDescription(GConst.TRADECOLLECTION, GConst.PICKUPSHORT);
            --Here I am Hard Coding To Bill Send For Collection
            varReference1 := varReference1 || '/' || GConst.fncGenerateSerial(GCOnst.SERIALTRADE);


             varOperation := 'Inserting Trade Order Details into Bill Relization table';
              insert into trtran003 (brel_company_code, brel_trade_reference,
                 brel_reverse_serial, brel_entry_date, brel_user_reference,
                 brel_reference_date, brel_reversal_type,brel_reversal_fcy,
                 brel_reversal_rate, brel_reversal_inr,brel_period_code,
                 brel_trade_period,brel_maturity_from,brel_maturity_date,
                 brel_create_date,brel_record_status,brel_local_bank)
                 values (numCompany,varTrade,
                     (select nvl(max(brel_reverse_serial),0)+1
                        from trtran003
                         where brel_trade_reference=varTrade),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_ENTRY_DATE', datTemp),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_USER_REFERENCE', varTemp),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datTemp),
                 GConst.BILLCOLLECTION,numFcy,numRateInr,numInr,
                 GConst.fncXMLExtract(xmlTemp, 'BREL_PERIOD_CODE', numFCY),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_PERIOD', numFCY),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_FROM', datTemp),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datTemp),
                 sysdate,GConst.STATUSENTRY,
                 GConst.fncXMLExtract(xmlTemp, 'BREL_LOCAL_BANK', numFCY));

          varOperation := 'Inserting Bill realization Details into Bill Relization table';
              insert into trtran003 (brel_company_code, brel_trade_reference,
                 brel_reverse_serial, brel_entry_date, brel_user_reference,
                 brel_reference_date, brel_reversal_type,brel_reversal_fcy,
                 brel_reversal_rate, brel_reversal_inr,brel_period_code,
                 brel_trade_period,brel_maturity_from,brel_maturity_date,
                 brel_create_date,brel_record_status,brel_local_bank)
                 values (numCompany,varReference1,
                     (select nvl(max(brel_reverse_serial),0)+1
                        from trtran003
                        where brel_trade_reference=varReference1),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_ENTRY_DATE', datTemp),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_USER_REFERENCE', varTemp),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datTemp),
                 GConst.BILLCOLLECTION,numFcy,numRateInr,numInr,
                 GConst.fncXMLExtract(xmlTemp, 'BREL_PERIOD_CODE', numFCY),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_PERIOD', numFCY),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_FROM', datTemp),
                 GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datTemp),
                 sysdate,GConst.STATUSENTRY,
                 GConst.fncXMLExtract(xmlTemp, 'BREL_LOCAL_BANK', numFCY));


            varOperation := 'Adding record for Bill Realization';

              insert into TradeRegister(trad_company_code, trad_trade_reference,
                trad_reverse_reference, trad_reverse_serial, trad_import_export,
                trad_entry_date, trad_user_reference, trad_reference_date,
                trad_buyer_seller, trad_trade_currency, trad_product_code,
                 trad_trade_fcy, trad_trade_rate,
                trad_trade_inr, trad_period_code, trad_trade_period,
                trad_maturity_from, trad_maturity_date, trad_local_bank,
                trad_create_date, trad_entry_detail, trad_record_status, trad_process_complete)
                values(numCompany, varReference1, varTrade,
                (select nvl(max(trad_reverse_serial),0)+1
                        from trtran002
                        where trad_reverse_reference=varTrade), GConst.BILLCOLLECTION,
                GConst.fncXMLExtract(xmlTemp, 'BREL_ENTRY_DATE', datTemp),
                GConst.fncXMLExtract(xmlTemp, 'BREL_USER_REFERENCE', varTemp),
                GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datTemp),
                numCode, numCode1, numCode2,
                numFcy,numRateInr,numInr,
                GConst.fncXMLExtract(xmlTemp, 'BREL_PERIOD_CODE', numFCY),
                GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_PERIOD', numFCY),
                GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_FROM', datTemp),
                GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datTemp),
                GConst.fncXMLExtract(xmlTemp, 'BREL_LOCAL_BANK', numFCY),
                sysdate, null, GConst.STATUSENTRY, GConst.OPTIONNO);

                numError := fncCompleteUtilization(varTrade, GConst.UTILEXPORTS,
                              datWorkDate);


          elsif numAction = GConst.LOTMODIFIED then
            if numFcy > 0 then
              varOperation := 'Updating Hedge Deal Delivery';
              update trtran006
                set cdel_cancel_amount = numFcy,
                cdel_other_amount = numFcy1,
                cdel_cancel_rate = numRate,
                cdel_local_rate = numRate1,
                cdel_cancel_inr = numInr,
                cdel_delivery_from = varReference2,
                cdel_delivery_serial=1
                where cdel_trade_reference = varTrade
                and cdel_trade_serial = numSerial;

              varOperation := 'Updating Relization Of Cross Delivery';
              update trtran003
                set brel_reversal_fcy=numFcy,
                brel_reversal_rate=numRateInr,
                brel_reversal_inr=numInr,
                brel_record_status=Gconst.STATUSUPDATED,
                brel_user_reference=GConst.fncXMLExtract(xmlTemp, 'BREL_USER_REFERENCE', varTemp)
                where brel_trade_reference=varTrade
                and brel_reverse_serial=numSerial;
              varOperation := 'Updating Relization Of Cross Delivery';
              update trtran003
                set brel_reversal_fcy=numFcy,
                brel_reversal_rate=numRateInr,
                brel_reversal_inr=numInr,
                brel_record_status=Gconst.STATUSUPDATED,
                brel_user_reference=GConst.fncXMLExtract(xmlTemp, 'BREL_USER_REFERENCE', varTemp)
                where brel_trade_reference=GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_REFERENCE', varTemp)
                and brel_reverse_serial=numSerial;

              update traderegister
                set trad_trade_fcy=numFcy,
                trad_trade_rate=numRateInr,
                trad_trade_inr =numinr,
                trad_record_status=Gconst.STATUSUPDATED
                where trad_trade_reference= GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_REFERENCE', varTemp)
                and trad_reverse_serial = numserial;

            else
              varOperation := 'Deleting Hedge Deal Delivery';
              update trtran006
                set cdel_record_status = GConst.STATUSDELETED
                where cdel_trade_reference = varTrade
                and cdel_trade_serial = numSerial;
            end if;
          end if;

          numError := fncCompleteUtilization(varReference,  GConst.UTILHEDGEDEAL,
                          datWorkDate);
      End Loop;

    elsif numAction in (GConst.DELETESAVE, GConst.CONFIRMSAVE) then
        varOperation := 'Processing for Delete / Confirm';
        select decode(numAction,
          GConst.DELETESAVE, GConst.STATUSDELETED,
          GConst.CONFIRMSAVE,GConst.STATUSAUTHORIZED)
          into numStatus
          from dual;

        update trtran006
          set cdel_record_status = numStatus
          where cdel_trade_reference = varTrade
          and cdel_trade_serial = numSerial;
    End if;

  End if;

 ----------------------




--    Begin
--      numFcy := 0;
--      varReference := '';
--      varReference := GConst.fncXMLExtract(xmlTemp, 'DealNumber', varReference);
--      numFcy := GConst.fncXMLExtract(xmlTemp, 'DealAmount', numFcy);
--
--    Exception
--      when others then
--        numFcy := 0;
--        varReference := '';
--    End;
--
--    if Length(Trim(varReference)) > 0  then
--
--        select deal_exchange_rate, NVL(deal_local_rate,0), deal_other_currency
--          into numRate, numRate1, numCode
--          from trtran001
--          where deal_deal_number = varReference;
--
--        if numCode = GConst.INDIANRUPEE then
--          numInr := Round(numFcy * numRate);
--          numFcy1 := 0.00;
--        else
--          numFcy1 := Round(numFcy * numRate);
--          numInr := Round(numFcy * numRate1);
--        end if;
--
----        numRate :=  GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_RATE', numRate);
----        numInr := Round(numFcy * numRate);
--
--        if numAction = GConst.ADDSAVE and numFcy > 0 then
--          varOperation := 'Inserting Hedge Deal Delivery';
--          insert into trtran006(cdel_company_code, cdel_deal_number,
--            cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
--            cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
--            cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
--            cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
--            cdel_entry_detail, cdel_record_status, cdel_trade_reference,
--            cdel_trade_serial)
--          values(numCompany, varReference, 1,
--            (select NVL(max(cdel_reverse_serial),0) + 1
--              from trtran006
--              where cdel_deal_number = varReference),
--            datWorkDate, GConst.HEDGEDEAL, GConst.DEALDELIVERY,
--            numFcy, numRate, numFcy1, numRate1, numInr,
--            to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--            sysdate, null, GConst.STATUSENTRY, varTrade, numSerial);
--
--          numError := fncCompleteUtilization(varReference, GConst.UTILHEDGEDEAL,
--                        datWorkDate);
--        elsif numAction = GConst.EDITSAVE then
--          if numFcy > 0 then
--            varOperation := 'Updating Hedge Deal Delivery';
--            update trtran006
--              set cdel_cancel_amount = numFcy,
--              cdel_other_amount = numFcy1,
--              cdel_cancel_rate = numRate,
--              cdel_local_rate = numRate1,
--              cdel_cancel_inr = numInr
--              where cdel_trade_reference = varTrade
--              and cdel_trade_serial = numSerial;
--          else
--            varOperation := 'Deleting Hedge Deal Delivery';
--            update trtran006
--              set cdel_record_status = GConst.STATUSDELETED
--              where cdel_trade_reference = varTrade
--              and cdel_trade_serial = numSerial;
--          end if;
--
--        elsif numAction in (GConst.DELETESAVE, GConst.CONFIRMSAVE) then
--            varOperation := 'Processing for Delete / Confirm';
--            select decode(numAction,
--              GConst.DELETESAVE, GConst.STATUSDELETED,
--              GConst.CONFIRMSAVE,GConst.STATUSAUTHORIZED)
--              into numStatus
--              from dual;
--
--            update trtran006
--              set cdel_record_status = numStatus
--              where cdel_trade_reference = varTrade
--              and cdel_trade_serial = numSerial;
--        End if;
--
--    End if;

    varOperation := 'Checking for Loan Realization';
    varXPath := '//CommandSet/LoanDetails/ReturnFields/ROWD[@NUM]';
    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);

    if xmlDom.getLength(nlsTemp) > 0 then
 --     numRate :=  GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_RATE', numRate);
      varXPath := '//CommandSet/LoanDetails/ReturnFields/ROWD[@NUM="';

      if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then

        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.item(nlsTemp, numSub);
          nmpTemp := xmlDom.getAttributes(nodTemp);
          nodTemp1 := xmlDom.item(nmpTemp, 0);
          numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
          varTemp := varXPath || numTemp || '"]/RecordStatus';
          numStatus := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/LoanNumber';
          varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp := varXPath || numTemp || '"]/LoanAmount';
          numFcy1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/ExchangeRate';
          numRate := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/REVERSEAMOUNT';
          numFcy := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/RupeeValue';
          numInr := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

          if numFcy != numFcy1 then
            numInr := Round(numFcy * numRate);
          end if;

          if numStatus = GConst.LOTNEW then
            Varoperation := 'Inserting Loan Repayment';
 --Updated From Cygnet
              insert into trtran007(trln_company_code, trln_loan_number,
              trln_serial_number, trln_trade_reference, trln_adjusted_date,
              trln_adjusted_fcy, trln_adjusted_rate, trln_adjusted_inr,
              trln_create_date,  trln_record_status)
              values(numCompany,varReference,(select nvl(max(trln_serial_number),0)+1
                 from trtran007
                 where trln_loan_number=varReference),varTrade,
                 datworkdate,numFcy,numRate,numInr,datworkdate,Gconst.STATUSENTRY);
      begin
       varTemp:='PC';
       select FCLN_SANCTIONED_FCY  into numAmount1
         from trtran005
         where FCLN_LOAN_NUMBER= varReference ;
      exception
      when no_data_found then
        select bcrd_SANCTIONED_FCY  into numAmount1
          from trtran045
         where bcrd_buyers_credit= varReference ;
         varTemp:='BC';
      end;
     begin
       select sum(brel_reversal_fcy)
         into numUtilization1
         from trtran003
         where brel_trade_reference=varReference
         and brel_record_status not in(Gconst.STATUSINACTIVE,Gconst.STATUSDELETED);
     exception
       when no_data_found then
       numUtilization1:=0;
     end;
     varOperation := 'Compare Buyers Credit Loan Amount with Utilized Amount ';
     if vartemp='PC' then
         if numAmount1 = numUtilization1 then
          --varOperation := GConst.OPTIONYES || '' || WorkDate || ' ' || ReferenceNumber ;
           update trtran005
             set fcln_process_complete = GConst.OPTIONYES,
               fcln_complete_date = datworkdate
             where fcln_loan_number = varReference;
         else
           update trtran005
             set fcln_process_complete = GConst.OPTIONNO,
             fcln_complete_date = null
             where fcln_loan_number = varReference;
          end if;
     else
         if numAmount1 = numUtilization1 then
          --varOperation := GConst.OPTIONYES || '' || WorkDate || ' ' || ReferenceNumber ;
           update trtran045
             set bcrd_process_complete = GConst.OPTIONYES,
               bcrd_completion_date = datworkdate
             where bcrd_buyers_credit = varReference;
         else
           update trtran045
             set bcrd_process_complete = GConst.OPTIONNO,
             bcrd_completion_date = null
             where bcrd_buyers_credit = varReference;
          end if;
     End If;
-- End Cygnet update
          elsif numAction = GConst.LOTMODIFIED then
              if numFcy > 0 then
                varOperation := 'Updating Loan Repayment';
                update trtran007
                  set trln_adjusted_fcy = numFcy,
                  trln_adjusted_rate = numRate,
                  trln_adjusted_inr = numInr
                  where trln_trade_reference = varTrade
                  and trln_trade_serial = numSerial;
              else
                varOperation := 'Deleting Loan Repayment Entry';
                update trtran007
                  set trln_record_status = GConst.STATUSDELETED
                  where trln_trade_reference = varTrade
                  and trln_trade_serial = numSerial;
              end if;
          end if;
 --Updated From Cygnet
          if vartemp='PC' then
             numError := fncCompleteUtilization(varReference, GConst.UTILFCYLOAN,
                             datWorkDate);
          elsif vartemp='BC' then
             numError := fncCompleteUtilization(varReference, GConst.UTILBCRLOAN,
                             Datworkdate);
          End If;
 --
      End Loop;

    elsif numAction in (GConst.DELETESAVE, GConst.CONFIRMSAVE) then
        varOperation := 'Processing for Delete / Confirm';
        select decode(numAction,
          GConst.DELETESAVE, GConst.STATUSDELETED,
          GConst.CONFIRMSAVE,GConst.STATUSAUTHORIZED)
          into numStatus
          from dual;

        update trtran007
          set trln_record_status = numStatus
          where trln_trade_reference = varTrade
          and trln_trade_serial = numSerial;
    End if;

  End if;

    varOperation := 'Checking for PSCFC Details';
    delete from temp ;
    insert into temp values(varOperation,'chandra');
    Begin
      numFcy := 0;
      varReference := '';
 --     varReference := GConst.fncXMLExtract(xmlTemp, 'LoanNumber', varReference);
      numFcy := GConst.fncXMLExtract(xmlTemp, '//PSCFCDetails/SanctionedFcy',
                      numFcy, GConst.TYPENODEPATH);

    Exception
      when others then
        numFcy := 0;
        varReference := '';
    End;

    if numFcy > 0 then

      if numAction = GConst.ADDSAVE then
        varReference := PkgReturnCursor.fncGetDescription(GConst.LOANPSCFC, GConst.PICKUPSHORT);
        varReference := varReference || '/' || GConst.fncGenerateSerial(GConst.SERIALLOAN);

        varOperation := 'Inserting PSCFC Record';
        insert into trtran005(fcln_company_code, fcln_loan_number,
        fcln_loan_type, fcln_local_bank, fcln_bank_reference, fcln_sanction_date,
        fcln_noof_days, fcln_currency_code, fcln_sanctioned_fcy,
        fcln_conversion_rate, fcln_sanctioned_inr, fcln_reason_code,
        fcln_maturity_from, fcln_maturity_to, fcln_loan_remarks,
        Fcln_Libor_Rate,Fcln_Rate_Spread,Fcln_Interest_Rate, -- Updated From Cygnet
        fcln_create_date, fcln_entry_detail, fcln_record_status,fcln_process_complete) -- Updated From Cygnet
        values(numCompany, varReference, GConst.LOANPSCFC,
        Gconst.Fncxmlextract(Xmltemp, 'BREL_LOCAL_BANK', Numfcy),
        GConst.fncXMLExtract(xmlTemp, 'BankReference', varReference),
        GConst.fncXMLExtract(xmlTemp, 'SanctionDate', datWorkDate),
        GConst.fncXMLExtract(xmlTemp, 'NoofDays', numError),
        (select trad_trade_currency
          from trtran002
          where trad_trade_reference = TradeReference),
        GConst.fncXMLExtract(xmlTemp, 'SanctionedFcy', numFcy),
        GConst.fncXMLExtract(xmlTemp, 'ConversionRate', numFcy),
        GConst.fncXMLExtract(xmlTemp, 'SanctionedInr', numFcy),
        GConst.REASONEXPORT,
        GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_FROM', datWorkDate),
        GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datWorkDate),
        'PSCFC From Bill Trade Reference ' || varTrade,
        GConst.fncXMLExtract(xmlTemp, 'LiborRate', numrate), -- Updated From Cygnet
        GConst.fncXMLExtract(xmlTemp, 'SpreadRate', numrate),
        GConst.fncXMLExtract(xmlTemp, 'InterestRate', numrate),
        sysdate, null, GConst.STATUSENTRY,
        GConst.fncXMLExtract(xmlTemp, 'ProcessComplete', numcode)); -- End updated cygnet

        varOperation := 'Inserting Loan Connect';
        insert into trtran010(loln_company_code, loln_loan_number,      -- Updated from cygnet
        loln_trade_reference, loln_serial_number, loln_adjusted_date,
        Loln_Adjusted_Fcy, Loln_Adjusted_Rate, Loln_Adjusted_Inr,
        loln_create_date, loln_entry_detail, loln_record_status)        --End Updated Cygnet
        values(numCompany, varReference, TradeReference, 0, datWorkDate,
        GConst.fncXMLExtract(xmlTemp, 'SanctionedFcy', numFcy),
        GConst.fncXMLExtract(xmlTemp, 'ConversionRate', numFcy),
        GConst.fncXMLExtract(xmlTemp, 'SanctionedInr', numFcy),
        sysdate, null, GConst.STATUSENTRY);

      End if;

    End if;

    return numError;
Exception
        When others then
          numError := SQLCODE;
          varError := SQLERRM;
          varError := GConst.fncReturnError('LoanDeal', numError, varMessage,
                          varOperation, varError);
          raise_application_error(-20101, varError);
          return numError;
End fncLoanDeal;

--Function fncCurrentAccount
--    (RecordDetail in clob)
--    return number
--    is
----  Created on 29/07/08
--    numError            number;
--    numTemp             number;
--    numStatus           number;
--    numSub              number(3);
--    numSub1             number(3);
--    numSerial           number(5);
--    numSerial1          number(5);
--    numAction           number(4);
--    numCompany          number(8);
--    numLocation         number(8);
--    numCode             number(8);
--    numCode1            number(8);
--    numCode2            number(8);
--    numCode3            number(8);
--    numCode4            number(8);
--    numCross            number(15,4);
--    numFCY              number(15,4);
--    numFCY1             number(15,4);
--    numFCY2             number(15,6);
--    numFCY3             number(15,4);
--    numFcy4             number(15,4);
--    numINR              number(15,2);
--    numRate             number(15,6);
--    numRate1            number(15,6);
--    varReference        varchar2(30);
--    varReference1       varchar2(30);
--    varReference2       varchar2(30);
--    varUserID           varchar2(30);
--    varEntity           varchar2(30);
--    varAcNumber         varchar2(50);
--    VarVoucherPass      number(8);
--    varTemp             varchar2(512);
--    varTemp1            varchar2(512);
--    varXPath            varchar2(512);
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    datWorkDate         date;
--    datTemp             date;
--    datTemp1            date;
--    datMaturity         date;
--    clbTemp             clob;
--    clbError            clob;
--    clbProcess          clob;
--    xmlTemp             xmlType;
--    nodTemp             xmlDom.domNode;
--    nodTemp1            xmlDom.domNode;
--    nmpTemp             xmldom.domNamedNodemap;
--    nmpTemp1            xmldom.domNamedNodemap;
--    nlsTemp             xmlDom.DomNodeList;
--    nlsTemp1            xmlDom.DomNodeList;
--    xlParse             xmlparser.parser;
--    nodFinal            xmlDom.domNode;
--    docFinal            xmlDom.domDocument;
--      -------added by kumar.h on 21/05/09------------
--    numBank             number(8);
--    numCrdr             number(8);
--    numType             number(8);
--    numHead             number(8);
--    numRecord           number(8);
--    numCurrency         number(8);
--    numMerchant         number(8);
--    varAccount          varchar2(25);
--    varVoucher          varchar2(25);
--    varDetail           varchar2(100);
--    varTemp2            varchar2(512);
--    nodVoucher          xmlDom.domNode;
--   ---------------------------------------------------
--    Begin
--    varMessage := 'Current Account Maintenance';
--    dbms_lob.createTemporary (clbTemp,  TRUE);
--    clbTemp := RecordDetail;
--
--    numError := 0;
--    varOperation := 'Extracting Input Parameters';
--    xmlTemp := xmlType(RecordDetail);
--
--    varUserID := GConst.fncXMLExtract(xmlTemp, 'UserID', varUserID);
--    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
--    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
--    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
--    numCompany := GConst.fncXMLExtract(xmlTemp, 'CompanyID', numCompany);
--    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationID', numLocation);
--
--    numError := 2;
--    varOperation := 'Creating Document for Master';
--    docFinal := xmlDom.newDomDocument(xmlTemp);
--    nodFinal := xmlDom.makeNode(docFinal);
--
--    if varEntity = 'EXTENSIONHEDGEDEAL' then
--        varXPath := '//' || varEntity || '/ROW[@NUM]/';
--        varTemp := varXPath || 'LMOD_REFERENCE_NUMBER';
--        varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--        varTemp := varXPath || 'LMOD_REFERENCE_SERIAL';
--        numSerial := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || 'LMOD_SERIAL_NUMBER';
--        numSerial1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--
----        select deal_buy_sell, deal_other_currency, lbnk_account_number
----          into numCode, numCode1, varAcNumber
----          from trtran001, trmaster306
----          where deal_deal_number = varReference
----          and deal_serial_number = numSerial
----          and deal_counter_party = lbnk_pick_code;
--            select deal_buy_sell, deal_other_currency, lbnk_account_number,lbnk_voucher_pass
--              into numCode, numCode1, varAcNumber,VarVoucherPass
--              from trtran001, trmaster306
--              where deal_deal_number = varReference
--              and deal_serial_number = numSerial
--              and deal_counter_party = lbnk_pick_code;
---- REVERSAL ENTRIES
--        if numCode = GConst.PURCHASEDEAL then
--          numCode2 := GConst.TRANSACTIONCREDIT;
--          numCode3 := GConst.ACFCYSALE;
--          numCode4 := GConst.EVENTPURROLLOVER;
--        else
--          numCode2 := GConst.TRANSACTIONDEBIT;
--          numCode3 := GConst.ACFCYPURCHASE;
--          numCode4 := GConst.EVENTSALROLLOVER;
--        end if;
--
--       if numAction in (GConst.EDITSAVE, GConst.DELETESAVE) then
--        delete from trtran008
--          where bcac_voucher_number =
--          (select lmod_pl_voucher
--            from trtran009
--            where lmod_reference_number = varReference
--            and lmod_reference_serial = numSerial
--            and lmod_serial_number = numSerial1);
--      end if;
--
--      if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
--
--        varOperation := 'Inserting voucher for Profit/Loss';
--        varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--        insert into trtran008 (bcac_company_code, bcac_location_code,
--          bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--          bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--          bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--          bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--          bcac_create_date, bcac_local_merchant, bcac_record_status,
--          bcac_record_type, bcac_account_number)
--        select numCompany, numLocation, deal_counter_party, varReference1,
----          pkgReturnCursor.fncRollover(deal_deal_number),
--          decode(VarVoucherPass,gconst.CAVOUCHERONVALUEDATE,
----          pkgReturnCursor.fncRollover(deal_deal_number),
--          deal_maturity_date,
--          gconst.CAVOUCHERONCANCELDATE,lmod_change_date),
--          --deal_maturity_date,
--          decode(sign(lmod_profit_loss),-1,GConst.TRANSACTIONDEBIT,
--          GConst.TRANSACTIONCREDIT), GConst.ACEXCHANGE, numCode4, varReference,
--          numSerial,deal_base_currency, lmod_enhanced_fcy, lmod_enhanced_rate,
--          abs(lmod_profit_loss), 'Deal Rollover No: ' || deal_deal_number,
--          sysdate,30999999,GConst.STATUSENTRY, 23800002, varAcNumber
--          from trtran001, trtran009
--          where deal_deal_number = lmod_reference_number
--          and deal_serial_number = lmod_reference_serial
--          and deal_deal_number = varReference
--          and deal_serial_number = numSerial
--          and lmod_serial_number = numSerial1;
--
--        varOperation := 'Updating Voucher Number in Cancel Deal';
--        update trtran009
--          set lmod_pl_voucher = varReference1
--          where lmod_reference_number = varReference
--          and lmod_reference_serial = numSerial
--          and lmod_serial_number = numSerial1;
--
--      End if;
--
--    END IF;
----Since voucher generation has beed disabled, logic for edit, deletion etc
----has not been written. If the company wants these vouchers then logic has
----written, However for P L entry the logic already exists - TMM 12/10/08
--
--    if varEntity in ('TRADEDEALREGISTER', 'HEDGEDEALREGISTER') then
-- -- The return statement is incorporated to disable automatic voucher passing - 12/10/08
--      return numError;
--      if numAction in (GConst.ADDSAVE) then
--        varXPath := '//' || varEntity || '/ROW[@NUM]';
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--        varXPath := '//' || varEntity||  '/ROW[@NUM="';
--        for numSub in 0..xmlDom.getLength(nlsTemp) -1
--          Loop
--            nodTemp := xmlDom.item(nlsTemp, numSub);
--            nmpTemp := xmlDom.getAttributes(nodTemp);
--            nodTemp1 := xmlDom.item(nmpTemp, 0);
--            numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
--            varTemp := varXPath || numTemp || '"]/DEAL_DEAL_NUMBER';
--            varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--            varTemp := varXPath || numTemp || '"]/DEAL_SERIAL_NUMBER';
--            numSerial := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--            varTemp := varXPath || numTemp || '"]/DEAL_BUY_SELL';
--            numCode := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--            varTemp := varXPath || numTemp || '"]/DEAL_OTHER_CURRENCY';
--            numCode1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--            varTemp := varXPath || numTemp || '"]/DEAL_COUNTER_PARTY';
--            numCode2 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--
--            varOperation := 'Getting Bank Account Number';
--            select NVL(lbnk_account_number,'')
--              into varAcNumber
--              from trmaster306
--              where lbnk_pick_code = numCode2;
--
--            if numCode = GConst.SALEDEAL then
--              numCode2 := GConst.TRANSACTIONCREDIT;
--              numCode3 := GConst.ACFCYSALE;
--              numCode4 := GConst.EVENTSALE;
--            else
--              numCode2 := GConst.TRANSACTIONDEBIT;
--              numCode3 := GConst.ACFCYPURCHASE;
--              numCode4 := GConst.EVENTPURCHASE;
--            end if;
--
--            varOperation := 'Inserting voucher for Foreign Currency';
--            varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--            insert into trtran008 (bcac_company_code, bcac_location_code,
--              bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--              bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--              bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--              bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--              bcac_create_date, bcac_local_merchant, bcac_record_status,
--              bcac_record_type, bcac_account_number)
--            select numCompany, numLocation, deal_counter_party, varReference1,
--              datWorkDate, numCode2, numCode3, numCode4, varReference, numSerial,
--              deal_base_currency, deal_base_amount, deal_exchange_rate,
--              decode(deal_other_currency, GConst.INDIANRUPEE, deal_other_amount,
--              deal_amount_local), 'Deal Execution No: ' || deal_deal_number,
--              sysdate,30999999,GConst.STATUSENTRY, 23800002, varAcNumber
--              from trtran001
--              where deal_deal_number = varReference
--              and deal_serial_number = numSerial;
--
--            varOperation := 'Inserting voucher for Local Currency';
--            varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--            insert into trtran008 (bcac_company_code, bcac_location_code,
--              bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--              bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--              bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--              bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--              bcac_create_date, bcac_local_merchant, bcac_record_status,
--              bcac_record_type, bcac_account_number)
--            select numCompany, numLocation, deal_counter_party, varReference1,
--              datWorkDate,
--              decode(numCode2, GConst.TRANSACTIONCREDIT, GConst.TRANSACTIONDEBIT,
--              GConst.TRANSACTIONCREDIT), decode(numCode3, GConst.ACFCYSALE,
--              GConst.ACINRPURCHASE, GConst.ACINRSALE),  numCode4,
--              varReference, numSerial, deal_base_currency, deal_base_amount,
--              deal_exchange_rate, decode(deal_other_currency, GConst.INDIANRUPEE,
--              deal_other_amount, deal_amount_local), 'Deal Execution No: ' ||
--              deal_deal_number,sysdate,30999999,GConst.STATUSENTRY, 23800002, varAcNumber
--              from trtran001
--              where deal_deal_number = varReference
--              and deal_serial_number = numSerial;
--  --Cross Currency Deals
--            if numCode1 != GConst.INDIANRUPEE then
--              varOperation := 'Inserting voucher for Cross Currency';
--              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--              insert into trtran008 (bcac_company_code, bcac_location_code,
--                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                bcac_create_date, bcac_local_merchant, bcac_record_status,
--                bcac_record_type, bcac_account_number)
--              select numCompany, numLocation, deal_counter_party, varReference1,
--                datWorkDate,
--                decode(numCode2, GConst.TRANSACTIONCREDIT, GConst.TRANSACTIONDEBIT,
--                GConst.TRANSACTIONCREDIT), decode(numCode3, GConst.ACFCYSALE,
--                 GConst.ACFCYPURCHASE, GConst.ACFCYSALE),  decode(numCode4,
--                GConst.EVENTSALE, GConst.EVENTPURCHASE, GConst.EVENTSALE),
--                varReference, numSerial, deal_other_currency, deal_other_amount,
--                deal_local_rate, deal_amount_local, 'Deal Execution No: ' ||
--                deal_deal_number,sysdate,30999999,GConst.STATUSENTRY, 23800002, ''
--                from trtran001
--                where deal_deal_number = varReference
--                and deal_serial_number = numSerial;
--
--              varOperation := 'Inserting voucher for Cross Currency INR';
--              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--              insert into trtran008 (bcac_company_code, bcac_location_code,
--                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                bcac_create_date, bcac_local_merchant, bcac_record_status,
--                bcac_record_type, bcac_account_number)
--              select numCompany, numLocation, deal_counter_party, varReference1,
--                datWorkDate, numCode2, decode(numCode3, GConst.ACFCYSALE,
--                GConst.ACINRSALE, GConst.ACINRPURCHASE), decode(numCode4,
--                GConst.EVENTSALE, GConst.EVENTPURCHASE, GConst.EVENTSALE),
--                varReference, numSerial, deal_base_currency, deal_base_amount,
--                deal_exchange_rate, deal_amount_local, 'Deal Execution No: ' ||
--                deal_deal_number, sysdate,30999999,GConst.STATUSENTRY, 23800002, varAcNumber
--                from trtran001
--                where deal_deal_number = varReference
--                and deal_serial_number = numSerial;
--          end if;
--
--        End Loop;
--
--      end if;
--
--     elsif varEntity in ('TRADEDEALCANCELLATION', 'HEDGEDEALCANCELLATION') then
----      if numAction in (GConst.ADDSAVE) then
--        varXPath := '//' || varEntity || '/ROW[@NUM]';
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--        varXPath := '//' || varEntity||  '/ROW[@NUM="';
--        for numSub in 0..xmlDom.getLength(nlsTemp) -1
--          Loop
--            nodTemp := xmlDom.item(nlsTemp, numSub);
--            nmpTemp := xmlDom.getAttributes(nodTemp);
--            nodTemp1 := xmlDom.item(nmpTemp, 0);
--            numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
--            varTemp := varXPath || numTemp || '"]/CDEL_DEAL_NUMBER';
--            varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--            varTemp := varXPath || numTemp || '"]/CDEL_DEAL_SERIAL';
--            numSerial := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
----            varTemp := varXPath || numTemp || '"]/CDEL_TRADE_SERIAL';
----            numSerial1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--            varTemp := varXPath || numTemp || '"]/CDEL_REVERSE_SERIAL';
--            numSerial1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--
--            select deal_buy_sell, deal_other_currency, lbnk_account_number,lbnk_voucher_pass
--              into numCode, numCode1, varAcNumber,VarVoucherPass
--              from trtran001, trmaster306
--              where deal_deal_number = varReference
--              and deal_serial_number = numSerial
--              and deal_counter_party = lbnk_pick_code;
---- REVERSAL ENTRIES
--            if numCode = GConst.PURCHASEDEAL then
--              numCode2 := GConst.TRANSACTIONCREDIT;
--              numCode3 := GConst.ACFCYSALE;
--              numCode4 := GConst.EVENTPURREVERSAL;
--            else
--              numCode2 := GConst.TRANSACTIONDEBIT;
--              numCode3 := GConst.ACFCYPURCHASE;
--              numCode4 := GConst.EVENTSALREVERSAL;
--            end if;
-- -- The Go to statement is incorporated to disable automatic voucher passing - 12/10/08
--            Goto Profit_Loss;
--
--            varOperation := 'Reversing voucher for Foreign Currency';
--            varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--            delete from temp;
--            insert into temp values (datWorkDate,datWorkDate);
--            commit;
--
--            insert into trtran008 (bcac_company_code, bcac_location_code,
--              bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--              bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--              bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--              bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--              bcac_create_date, bcac_local_merchant, bcac_record_status,
--              bcac_record_type, bcac_account_number)
--            select numCompany, numLocation, deal_counter_party, varReference1,
--              datWorkDate, numCode2, numCode3, numCode4, varReference, numSerial,
--              deal_base_currency, cdel_cancel_amount, deal_exchange_rate,
--              decode(sign(deal_base_amount - cdel_cancel_amount), 0,
--              decode(deal_other_currency, GConst.INDIANRUPEE, deal_other_amount,
--              deal_amount_local), round(cdel_cancel_amount * deal_exchange_rate)),
--              'Deal Reversal No: ' || deal_deal_number,
--              sysdate,30999999,GConst.STATUSENTRY, 23800002, varAcNumber
--              from trtran001, trtran006
--              where deal_deal_number = cdel_deal_number
--              and deal_serial_number = cdel_deal_serial
--              and deal_deal_number = varReference
--              and deal_serial_number = numSerial
--              and cdel_reverse_serial = numSerial1;
--
--            varOperation := 'Inserting voucher for Local Currency';
--            varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--            insert into trtran008 (bcac_company_code, bcac_location_code,
--              bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--              bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--              bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--              bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--              bcac_create_date, bcac_local_merchant, bcac_record_status,
--              bcac_record_type, bcac_account_number)
--            select numCompany, numLocation, deal_counter_party, varReference1,
--              datWorkDate,
--              decode(numCode2, GConst.TRANSACTIONCREDIT, GConst.TRANSACTIONDEBIT,
--              GConst.TRANSACTIONCREDIT), decode(numCode3, GConst.ACFCYSALE,
--              GConst.ACINRPURCHASE, GConst.ACINRSALE), numCode4,
--              varReference, numSerial, deal_base_currency, cdel_cancel_amount,
--              deal_exchange_rate,
--              decode(sign(deal_base_amount - cdel_cancel_amount), 0,
--              decode(deal_other_currency, GConst.INDIANRUPEE, deal_other_amount,
--              deal_amount_local), round(cdel_cancel_amount * deal_exchange_rate)),
--              'Deal Reversal No: ' ||
--              deal_deal_number,sysdate,30999999,GConst.STATUSENTRY, 23800002, varAcNumber
--              from trtran001, trtran006
--              where deal_deal_number = cdel_deal_number
--              and deal_serial_number = cdel_deal_serial
--              and deal_deal_number = varReference
--              and deal_serial_number = numSerial
--              and cdel_reverse_serial = numSerial1;
----  Cross Currency Deals
--            if numCode1 != GConst.INDIANRUPEE then
--              varOperation := 'Inserting voucher for Cross Currency';
--              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--              insert into trtran008 (bcac_company_code, bcac_location_code,
--                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                bcac_create_date, bcac_local_merchant, bcac_record_status,
--                bcac_record_type, bcac_account_number)
--              select numCompany, numLocation, deal_counter_party, varReference1,
--                datWorkDate,
--                decode(numCode2, GConst.TRANSACTIONCREDIT, GConst.TRANSACTIONDEBIT,
--                GConst.TRANSACTIONCREDIT), decode(numCode3, GConst.ACFCYSALE,
--                GConst.ACFCYPURCHASE, GConst.ACFCYSALE), decode(numCode4,
--                GConst.EVENTSALREVERSAL, GConst.EVENTPURREVERSAL, GConst.EVENTSALREVERSAL),
--                varReference, numSerial, deal_other_currency, cdel_other_amount,
--                deal_local_rate,
--                decode(sign(deal_other_amount - cdel_other_amount), 0,
--                  deal_amount_local, round(cdel_other_amount * deal_local_rate)),
--                'Deal Reversal No: ' ||
--                deal_deal_number,sysdate,30999999,GConst.STATUSENTRY, 23800002, varAcNumber
--                from trtran001, trtran006
--                where deal_deal_number = cdel_deal_number
--                and deal_serial_number = cdel_deal_serial
--                and deal_deal_number = varReference
--                and deal_serial_number = numSerial
--                and cdel_reverse_serial = numSerial1;
--
--              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--              insert into trtran008 (bcac_company_code, bcac_location_code,
--                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                bcac_create_date, bcac_local_merchant, bcac_record_status,
--                bcac_record_type, bcac_account_number)
--              select numCompany, numLocation, deal_counter_party, varReference1,
--                datWorkDate, numCode2, decode(numCode3, GConst.ACFCYSALE,
--                GConst.ACINRSALE, GConst.ACINRPURCHASE),decode(numCode4,
--                GConst.EVENTSALREVERSAL, GConst.EVENTPURREVERSAL,
--                GConst.EVENTSALREVERSAL),varReference, numSerial,
--                deal_other_currency, cdel_other_amount, deal_local_rate,
--                decode(sign(deal_other_amount - cdel_other_amount), 0,
--                  deal_amount_local, round(cdel_other_amount * deal_local_rate)),
--                'Deal Reversal No: ' || deal_deal_number,
--                sysdate,30999999,GConst.STATUSENTRY, 23800002, varAcNumber
--                from trtran001, trtran006
--                where deal_deal_number = cdel_deal_number
--                and deal_serial_number = cdel_deal_serial
--                and deal_deal_number = varReference
--                and deal_serial_number = numSerial
--                and cdel_reverse_serial = numSerial1;
--            end if;
--<<Profit_Loss>>
--          if numAction in (GConst.EDITSAVE, GConst.DELETESAVE) then
--              delete from trtran008
--                where bcac_voucher_number =
--                (select cdel_pl_voucher
--                  from trtran006
--                  where cdel_deal_number = varReference
--                  and cdel_deal_serial = numSerial
--                  and cdel_reverse_serial = numSerial1);
--            end if;
--
--            if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
--
--              varOperation := 'Inserting voucher for Profit/Loss';
--              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--              insert into trtran008 (bcac_company_code, bcac_location_code,
--                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                bcac_create_date, bcac_local_merchant, bcac_record_status,
--                bcac_record_type, bcac_account_number, bcac_recon_flag)
--              select numCompany, numLocation, deal_counter_party, varReference1,
--                decode(VarVoucherPass,gconst.CAVOUCHERONVALUEDATE,
--                pkgReturnCursor.fncRollover(deal_deal_number),
--                gconst.CAVOUCHERONCANCELDATE,cdel_cancel_date,
--                gconst.CAVOUCHERPROFITLOSS, decode(sign(cdel_profit_loss),-1,cdel_cancel_date,
--                pkgReturnCursor.fncRollover(deal_deal_number))),
--                decode(sign(cdel_profit_loss),-1,GConst.TRANSACTIONDEBIT,
--                GConst.TRANSACTIONCREDIT), GConst.ACEXCHANGE, numCode4, varReference,
--                numSerial,deal_base_currency, CDEL_PANDL_USD, CDEL_PANDL_SPOT,
--                abs(cdel_profit_loss), 'Deal Reversal No: ' || deal_deal_number,
--                sysdate,30999999,GConst.STATUSENTRY, 23800002, varAcNumber,12400002
--                from trtran001, trtran006
--                where deal_deal_number = cdel_deal_number
--                and deal_serial_number = cdel_deal_serial
--                and deal_deal_number = varReference
--                and deal_serial_number = numSerial
--                and cdel_reverse_serial = numSerial1;
--
--              varOperation := 'Updating Voucher Number in Cancel Deal';
--              update trtran006
--                set cdel_pl_voucher = varReference1
--                where cdel_deal_number = varReference
--                and cdel_deal_serial = numSerial
--                and cdel_reverse_serial = numSerial1;
--
--            End if;
--          End Loop;
-----Passing Vouchers For Commodity Daily Profit Loss  Modified on 03-apr-2009
--    elsif varEntity in ('COMMODITYVALUATION') then
--        varXPath := '//' || varEntity || '/ROW[@NUM]';
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--        varXPath := '//' || varEntity||  '/ROW[@NUM="';
--        for numSub in 0..xmlDom.getLength(nlsTemp) -1
--          Loop
--            nodTemp := xmlDom.item(nlsTemp, numSub);
--            nmpTemp := xmlDom.getAttributes(nodTemp);
--            nodTemp1 := xmlDom.item(nmpTemp, 0);
--            numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
--            varTemp := varXPath || numTemp || '"]/CMTR_DEAL_NUMBER';
--            varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--            varTemp := varXPath || numTemp || '"]/CMTR_SERIAL_NUMBER';
--            numSerial := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--
--            if numAction in (GConst.EDITSAVE, GConst.DELETESAVE) then
--              delete from trtran008
--                where bcac_voucher_number =
--                (select cmtr_pl_voucher
--                  from trtran052
--                  where cmtr_deal_number = varReference
--                  and cmtr_serial_number = numSerial);
--            end if;
--
--            if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
--              varOperation := 'Inserting voucher for Daily Commodity Profit/Loss';
--              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--              insert into trtran008 (bcac_company_code, bcac_location_code,
--                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                bcac_create_date, bcac_local_merchant, bcac_record_status,
--                bcac_record_type, bcac_account_number, bcac_recon_flag)
--              select numCompany, numLocation, cmdl_local_bank, varReference1,
--                datWorkDate,decode(sign(cmtr_profit_loss),-1,GConst.TRANSACTIONDEBIT,
--                GConst.TRANSACTIONCREDIT), GConst.ACEXCHANGE, GConst.EVENTCOMMDAILYPL, varReference,
--                1,cmdl_currency_code, cmdl_deal_amount, cmdl_exchange_rate,
--                abs(cmtr_profit_loss), 'Daily Commodity P No: ' || cmtr_deal_number,
--                sysdate,30999999,GConst.STATUSENTRY, 23800002, (select lbnk_account_number
--                   from trmaster306
--                   where lbnk_pick_code = cmdl_local_bank
--                   and lbnk_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED)),12400002
--                from trtran051, trtran052
--                where cmdl_deal_number = cmtr_deal_number
--                and cmtr_deal_number = varReference
--                and cmtr_mtm_date=datWorkDate;
--
--              varOperation := 'Updating Voucher Number in Daily Profit/Loss';
--              update trtran052
--                set cmtr_pl_voucher = varReference1
--                where cmtr_deal_number = varReference
--                 and cmtr_mtm_date=datWorkDate ;
--            End if;
--         end loop;
--    elsif varEntity in ('HEDGECOMMODITYDEAL','TRADECOMMODITYDEAL') then
--
--        varXPath := '//' || varEntity||  '/ROW[@NUM="1';
--        varTemp := varXPath || '"]/CMDL_DEAL_NUMBER';
--        varReference2 := GConst.fncGetNodeValue(nodFinal, varTemp);
--
--        varXPath := '//' || varEntity || '/ReverseDetails/ReverseRow[@NUM]';
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--        varXPath := '//' || varEntity || '/ReverseDetails/ReverseRow[@NUM="';
--        for numSub in 0..xmlDom.getLength(nlsTemp) -1
--          Loop
--
--            nodTemp := xmlDom.item(nlsTemp, numSub);
--            nmpTemp := xmlDom.getAttributes(nodTemp);
--            nodTemp1 := xmlDom.item(nmpTemp, 0);
--            numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
--
--            varTemp := varXPath || numTemp || '"]/ReverseDealNumber';
--
--            varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--
--           -- insert into temp values(varReference,varTemp);
--
--            if numAction in (GConst.EDITSAVE, GConst.DELETESAVE) then
--              delete from trtran008
--                where bcac_voucher_number =
--                (select crev_pl_voucher
--                  from trtran053
--                  where crev_deal_number = varReference
--                  and crev_reverse_deal = varReference2);
--            end if;
--
--            if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
--              varOperation := 'Inserting voucher for Commodity Deal Reversal';
--              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--              insert into trtran008 (bcac_company_code, bcac_location_code,
--                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                bcac_create_date, bcac_local_merchant, bcac_record_status,
--                bcac_record_type, bcac_account_number)
--              select numCompany, numLocation, cmdl_local_bank, varReference1,
--                datWorkDate,decode(sign(crev_profit_loss),-1,GConst.TRANSACTIONDEBIT,
--                GConst.TRANSACTIONCREDIT), GConst.ACEXCHANGE, GConst.EVENTCOMMDAILYPL, varReference,
--                1,cmdl_currency_code, cmdl_deal_amount, cmdl_exchange_rate,
--                abs(crev_profit_loss), 'Commodity Deal Reversal  No: ' || crev_reverse_deal,
--                sysdate,30999999,GConst.STATUSENTRY, 23800002, (select lbnk_account_number
--                   from trmaster306
--                   where lbnk_pick_code = cmdl_local_bank
--                   and lbnk_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED))
--                from trtran051, trtran053
--                where cmdl_deal_number = crev_deal_number
--                and crev_deal_number = varReference2
--                and crev_reverse_deal = varReference;
--
--              varOperation := 'Updating Voucher Number in Reversal Commodity Deal';
--              update trtran053
--                set crev_pl_voucher = varReference1
--                where crev_deal_number = varReference2
--                 and crev_reverse_deal= varReference;
--            End if;
--         end loop;
--
--
--    elsif varEntity in ('COMMODITYDEALCANCEL') then
--
--        varXPath := '//' || varEntity||  '/ROW[@NUM="1';
--        varTemp := varXPath || '"]/CREV_DEAL_NUMBER';
--        varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--
--        if numAction in (GConst.EDITSAVE, GConst.DELETESAVE) then
--              delete from trtran008
--                where bcac_voucher_number =
--                (select crev_pl_voucher
--                  from trtran053
--                  where crev_deal_number = varReference);
--        end if;
--        if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
--              varOperation := 'Inserting voucher for Commodity Deal cancellation';
--              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--              insert into trtran008 (bcac_company_code, bcac_location_code,
--                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                bcac_create_date, bcac_local_merchant, bcac_record_status,
--                bcac_record_type, bcac_account_number)
--              select numCompany, numLocation, cmdl_local_bank, varReference1,
--                datWorkDate,decode(sign(crev_profit_loss),-1,GConst.TRANSACTIONDEBIT,
--                GConst.TRANSACTIONCREDIT), GConst.ACEXCHANGE, GConst.EVENTCOMMDAILYPL, varReference,
--                1,cmdl_currency_code, cmdl_deal_amount, cmdl_exchange_rate,
--                abs(crev_profit_loss), 'Commodity Deal Reversal  No: ' || crev_reverse_deal,
--                sysdate,30999999,GConst.STATUSENTRY, 23800002, (select lbnk_account_number
--                   from trmaster306
--                   where lbnk_pick_code = cmdl_local_bank
--                   and lbnk_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED))
--                from trtran051, trtran053
--                where cmdl_deal_number = crev_deal_number
--                and crev_deal_number = varReference
--                and crev_reverse_deal = varReference;
--
--              varOperation := 'Updating Voucher Number in Reversal Commodity Deal';
--              update trtran053
--                set crev_pl_voucher = varReference1
--                where crev_deal_number = varReference
--                 and crev_reverse_deal= varReference;
--            End if;
--    elsif varEntity in ('OPTIONHEDGEEXERCISE','OPTIONTRADEEXERCISE') then
--
--        varXPath := '//' || varEntity||  '/ROW[@NUM="1';
--        varTemp := varXPath || '"]/CORV_DEAL_NUMBER';
--        varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--        varTemp := varXPath || '"]/CORV_SERIAL_NUMBER';
--        numserial := GConst.fncGetNodeValue(nodFinal, varTemp);
--        varTemp := varXPath || '"]/CORV_SUBSERIAL_NUMBER';
--        numserial1 := GConst.fncGetNodeValue(nodFinal, varTemp);
--        varTemp := varXPath || '"]/CORV_SETTLEMENT_DATE';
--        VarOperation :='Extracting Deals' || GConst.fncGetNodeValue(nodFinal, varTemp);
--        --varTemp := varXPath || '"]/CORV_SETTLEMENT_DATE';
--        datTemp := to_date(GConst.fncGetNodeValue(nodFinal, varTemp),'dd-MM-yyyy');
--
--        varTemp := varXPath || '"]/CORV_EXERCISE_DATE';
--        VarOperation :='Extracting Deals' || GConst.fncGetNodeValue(nodFinal, varTemp);
--
--
--
--
--
--        --varTemp := varXPath || '"]/CORV_SETTLEMENT_DATE';
--        datTemp1 := to_date(GConst.fncGetNodeValue(nodFinal, varTemp),'dd-MM-yyyy');
--
--        VarOperation :='Getting information ' || GConst.fncGetNodeValue(nodFinal, varTemp);
--        varTemp := varXPath || '"]/CORV_EXERCISE_TYPE';
--        numcode1 :=GConst.fncGetNodeValue(nodFinal, varTemp);
--
--        varTemp := varXPath || '"]/CORV_PREMIUM_STATUS';
--        numCode3 := GConst.fncGetNodeValue(nodFinal, varTemp);
--
--        --VarOperation :='Getting information for Exercise Type' || ;
--     if numcode1!= Gconst.NoExercise then
--      begin
--        select lbnk_voucher_pass,lbnk_account_number,lbnk_pick_code,copt_base_currency
--          into VarVoucherPass,varAccount,numBank,numcode
--          from trtran071, trmaster306
--         where copt_deal_number = varReference
--           and copt_counter_party = lbnk_pick_code
--           and copt_record_status not in(10200005,10200006);
--        exception
--        when others then
--           select cbrk_voucher_pass,cbrk_account_number,cbrk_pick_code,copt_base_currency
--             into VarVoucherPass,varAccount,numBank,numcode
--            from trtran071, trmaster502
--           where copt_deal_number = varReference
--             and copt_counter_party = cbrk_pick_code
--             and copt_record_status not in(10200005,10200006);
--         end;
--
--
--        if numAction in (GConst.EDITSAVE, GConst.DELETESAVE) then
--              delete from trtran008
--                where bcac_voucher_number =
--               (select corv_pl_voucher
--                   from trtran073
--                  where corv_deal_number = varReference
--                                      and corv_serial_number =numserial
--                    and corv_record_status in (GConst.STATUSINACTIVE,Gconst.STATUSDELETED))
--                    and bcac_reference_serial =numserial ;
--        end if;
--
--              if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
--              varOperation := 'Inserting voucher for Option Deal cancellation';
--              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--              insert into trtran008 (bcac_company_code, bcac_location_code,
--                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                bcac_create_date, bcac_local_merchant, bcac_record_status,
--                bcac_record_type, bcac_account_number)
--              select numCompany, numLocation, numBank, varReference1,
--              decode(VarVoucherPass,gconst.CAVOUCHERONVALUEDATE,
--                   dattemp,gconst.CAVOUCHERONCANCELDATE,datTemp1,Gconst.CAVOUCHERPROFITLOSS,dattemp),
--                decode(numcode1,Gconst.CancelDeal,decode(numCode3,Gconst.Received,GConst.TRANSACTIONCREDIT,GConst.PremiumPaid,
--                GConst.TRANSACTIONDEBIT),Gconst.Exercise,
--                decode(sign(corv_profit_loss),-1,GConst.TRANSACTIONDEBIT,
--                GConst.TRANSACTIONCREDIT))  , Decode(numcode1,Gconst.CancelDeal,GCONST.ACPREMIUMAC,
--                Gconst.Exercise,GConst.ACEXCHANGE), GConst.EVENTOPTIONSPL, varReference,
--                1,numcode, corv_pandl_spot,corv_pandl_usd,--copt_b_amount, 0,--copt_premium_exrate,  ------ Here is the change
--
--
--                abs(corv_Profit_Loss), 'Options Deal Reversal No: ' || corv_deal_number || '-' || corv_serial_number || '-' ||  corv_subserial_number,
--                sysdate,30999999,GConst.STATUSENTRY, 23800002, varAccount
--                from trtran073
--                where corv_deal_number = varReference
--                  and corv_serial_number =numserial
--                --and copt_serial_number =corv_serial_number
--               -- and copt_subserial_number=corv_subserial_number
--               -- and corv_serial_number= numserial
--               -- and corv_subserial_number= numserial1
--               -- and corv_deal_number = varReference
--                and corv_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED);
--
--              varOperation := 'Updating Voucher Number in Reversal Commodity Deal';
--              update trtran073
--                set corv_pl_voucher = varReference1
--                where corv_deal_number = varReference
--                 and corv_serial_number= numserial
--                 and corv_subserial_number= numserial1
--                 and corv_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED);
--        end if;
--      End if;
--  elsif varEntity in('OPTIONHEDGEDEAL','OPTIONTRADEDEAL') then
--
--        varXPath := '//' || varEntity||  '/ROW[@NUM="1';
--        varTemp := varXPath || '"]/COPT_DEAL_NUMBER';
--        varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--        varTemp := varXPath || '"]/COPT_SERIAL_NUMBER';
--        numserial := GConst.fncGetNodeValue(nodFinal, varTemp);
--
--        varTemp := varXPath || '"]/COPT_PREMIUM_STATUS';
--        --akash added on 19112012
--        numCode3 := GConst.fncGetNodeValue(nodFinal, varTemp);
--        if numCode3 = GConst.NoPremium then
--          return 0;
--          end if;
--
--        if numAction in (GConst.EDITSAVE, GConst.DELETESAVE) then
--              delete from trtran008
--                where bcac_voucher_number =
--                (select copt_pl_voucher
--                  from trtran071
--                  where copt_deal_number = varReference
--                   and copt_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED));
--        end if;
--        if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
--              varOperation := 'Inserting voucher for Option Deal';
--              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--              insert into trtran008 (bcac_company_code, bcac_location_code,
--                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--                bcac_create_date, bcac_local_merchant, bcac_record_status,
--                bcac_record_type, bcac_account_number)
--              select numCompany, numLocation, copt_counter_party, varReference1,
--                copt_premium_valuedate,decode(numCode3,Gconst.Received,GConst.TRANSACTIONCREDIT,GConst.PremiumPaid,
--                GConst.TRANSACTIONDEBIT), GConst.ACPREMIUMAC, GConst.EVENTOPTIONSPL, varReference,
--                1,copt_base_currency, copt_premium_amount,copt_premium_exrate,--copt_b_amount, 0,--copt_premium_exrate,
--                abs(copt_premium_local), 'Options Deal   No: ' || copt_deal_number || '-' || copt_serial_number ,
--                sysdate,30999999,GConst.STATUSENTRY, 23800002, (select lbnk_account_number
--                   from trmaster306
--                   where lbnk_pick_code = copt_counter_party
--                   and lbnk_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED))
--                from trtran071
--                where copt_deal_number = varReference
--                and copt_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED);
--
--              varOperation := 'Updating Voucher Number Option Deal';
--              update trtran071
--                set copt_pl_voucher = varReference1
--                where copt_deal_number = varReference
--                and copt_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED);
--      End if;
--
--  end if;
-- --Money Module
--    if varEntity = 'MARKETDEAL' then
--      varReference := GConst.fncXMLExtract(xmlTemp, 'MDEL_DEAL_NUMBER', varReference);
--      varOperation := 'Inserting voucher for Money Market Deal';
--      varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--
--      insert into trtran008 (bcac_company_code, bcac_location_code,
--        bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--        bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--        bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--        bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--        bcac_create_date, bcac_local_merchant, bcac_record_status,
--        bcac_record_type, bcac_account_number)
--      select mdel_company_code, 0, mdel_local_bank, varReference1,
--        mdel_execute_date, decode(mdel_borrow_invest, GConst.MMBorrowing,
--        GConst.TRANSACTIONCREDIT, GConst.TRANSACTIONDEBIT), mdel_account_head,
--        GConst.EVENTMMDEAL, varReference, 0, mdel_currency_code, mdel_deal_amount,
--        mdel_exchange_rate, mdel_amount_local,'MM Deal Booking - ' || varReference,
--        sysdate, mdel_counter_party, GConst.STATUSENTRY,GConst.RECCURRENT,
--        lbnk_account_number
--        from trtran031, trmaster306
--        where mdel_deal_number = varReference
--        and mdel_local_bank = lbnk_pick_code;
--
--    End if;
--
--    if varEntity = 'DEALREDEMPTION' then
--      varReference := GConst.fncXMLExtract(xmlTemp, 'REDM_DEAL_CODE', varReference);
--      varOperation := 'Inserting voucher for MM Deal Redemption';
--      varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--
--      insert into trtran008 (bcac_company_code, bcac_location_code,
--        bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--        bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--        bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--        bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--        bcac_create_date, bcac_local_merchant, bcac_record_status,
--        bcac_record_type, bcac_account_number)
--      select mdel_company_code, 0, mdel_local_bank, varReference1,
--        datWorkDate, decode(mdel_borrow_invest, GConst.MMBorrowing,
--        GConst.TRANSACTIONDEBIT, GConst.TRANSACTIONCREDIT), mdel_account_head,
--        GConst.EVENTMMREDEEM, varReference, 0, mdel_currency_code, mdel_deal_amount,
--        mdel_exchange_rate, mdel_amount_local,'MM Deal Redemption - ' || varReference,
--        sysdate, mdel_counter_party, GConst.STATUSENTRY,GConst.RECCURRENT,
--        lbnk_account_number
--        from trtran031, trmaster306
--        where mdel_deal_number = varReference
--        and mdel_local_bank = lbnk_pick_code;
--
--      varOperation := 'Inserting voucher for Income / Expenditure';
--      varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--
--      insert into trtran008 (bcac_company_code, bcac_location_code,
--        bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--        bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--        bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--        bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--        bcac_create_date, bcac_local_merchant, bcac_record_status,
--        bcac_record_type, bcac_account_number)
--      select mdel_company_code, 0, mdel_local_bank, varReference1,
--        mdel_execute_date, decode(mdel_borrow_invest, GConst.MMBorrowing,
--        GConst.TRANSACTIONDEBIT, GConst.TRANSACTIONCREDIT),
--        decode(mdel_borrow_invest, GConst.MMBorrowing,
--        GConst.ACINTEXPENSE, GConst.ACINTINCOME),
--        GConst.EVENTMMREDEEM, varReference, 0, mdel_currency_code, redm_interest_amount,
--        redm_interest_rate, redm_interest_local,decode(mdel_borrow_invest, GConst.MMBorrowing,
--        'MM Deal Int.Expense - ' || varReference,'MM Deal Int.Income - ' || varReference),
--        sysdate, mdel_counter_party, GConst.STATUSENTRY,GConst.RECCURRENT,
--        lbnk_account_number
--        from trtran031, trtran043, trmaster306
--        where mdel_deal_number = varReference
--        and mdel_deal_number = redm_deal_code
--        and mdel_local_bank = lbnk_pick_code;
--
--        varOperation := 'Marking the MM Deal Closed';
--
--        update trtran031
--          set mdel_process_complete = GConst.OPTIONYES,
--          mdel_complete_date = datWorkDate
--          where mdel_deal_number = varReference;
--
--    end if;
--  --Money Module
--
--
--     --kumar.h updates 21/05/09
--  if varEntity in ('BUYERSCREDIT') then
--
--    varXPath := '//CURRENTACCOUNTMASTER/ROW';
--    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--    numSub := xmlDom.getLength(nlsTemp);
--
--    if numSub = 0 then
--      return numError;
--    End if;
--
--    Begin
--      varTemp := varXPath || '[@NUM="1"]/LocalBank';
--      numBank := GConst.fncXMLExtract(xmlTemp,varTemp,numBank,Gconst.TYPENODEPATH);
--
--      select lbnk_account_number
--        into varAccount
--        from trmaster306
--       where lbnk_pick_code = numBank
--         and lbnk_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED);
--
--    Exception
--      when no_data_found then
--        varAccount := '';
--    End;
--
--    for numSub in 0..xmlDom.getLength(nlsTemp) -1
--    Loop
--      nodTemp := xmlDom.Item(nlsTemp, numSub);
--      nmpTemp:= xmlDom.getAttributes(nodTemp);
--      nodTemp := xmlDom.Item(nmpTemp, 0);
--      numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
--      varTemp := varXPath || '[@NUM="' || numTemp || '"]/';
--      varTemp1 := varTemp || 'CrdrCode';
--      numCrdr := GConst.fncXMLExtract(xmlTemp,varTemp1,numCrdr,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'AccountHead';
--      numHead := GConst.fncXMLExtract(xmlTemp,varTemp1,numHead,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherType';
--      numType := GConst.fncXMLExtract(xmlTemp,varTemp1,numType,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'RecordType';
--      numRecord := GConst.fncXMLExtract(xmlTemp,varTemp1,numRecord,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'CurrencyCode';
--      numCurrency := GConst.fncXMLExtract(xmlTemp,varTemp1,numCurrency,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherReference';
--      varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'ReferenceSerial';
--      numSerial := GConst.fncXMLExtract(xmlTemp,varTemp1,numSerial,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherFcy';
--      numFcy := GConst.fncXMLExtract(xmlTemp,varTemp1,numFcy,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherRate';
--      numRate := GConst.fncXMLExtract(xmlTemp,varTemp1,numRate,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherInr';
--      numInr := GConst.fncXMLExtract(xmlTemp,varTemp1,numInr,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherDetail';
--      varDetail := GConst.fncXMLExtract(xmlTemp,varTemp1,varDetail,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'LocalMerchant';
--      numMerchant := GConst.fncXMLExtract(xmlTemp,varTemp1,numStatus,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'RecordStatus';
--      numStatus := GConst.fncXMLExtract(xmlTemp,varTemp1,numStatus,Gconst.TYPENODEPATH);
--
--      if numAction = GConst.DELETESAVE then
--        numStatus := GConst.LOTDELETED;
--      elsif numAction = GConst.CONFIRMSAVE then
--        numStatus := GConst.LOTCONFIRMED;
--      end if;
--
--      varOperation := 'Processing Current Account Transaction';
--
--      if numStatus = GConst.LOTNOCHANGE then
--        NULL;
--      elsif numStatus in (GConst.LOTNEW, GConst.LOTMODIFIED) then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BCRD_BUYERS_CREDIT';
--          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          numSerial := 0;
--          varDetail := varDetail || varReference;
--        if numStatus = GConst.LOTMODIFIED then
--            delete from trtran008
--                   where bcac_voucher_reference = varReference
--                   and bcac_reference_serial = numSerial
--                   and bcac_account_head = numHead;
--        End if;
--         varVoucher := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--        insert into trtran008 (bcac_company_code, bcac_location_code,
--          bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--          bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--          bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--          bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--          bcac_create_date, bcac_local_merchant, bcac_record_status,
--          bcac_record_type, bcac_account_number)
--        values(numCompany, numLocation, numBank, varVoucher, datWorkDate,
--        numCrdr, numHead, numType, varReference, numSerial, numCurrency,
--        numFcy, numRate, numInr, varDetail, sysdate, numMerchant, GConst.STATUSENTRY,
--        numRecord, varAccount);
--
--      elsif numStatus = GConst.LOTDELETED then
--           delete from trtran008
--                   where bcac_voucher_reference = varReference
--                   and bcac_reference_serial = numSerial
--                   and bcac_account_head = numHead;
--     end if;
--
--    End Loop;
--  End If;
--
--
--    return numError;
--Exception
--    When others then
--      numError := SQLCODE;
--      varError := SQLERRM;
--      varError := GConst.fncReturnError('Current A/c', numError, varMessage,
--                      varOperation, varError);
--      raise_application_error(-20101, varError);
--      return numError;
--
--End fncCurrentAccount;

Function fncCurrentAccount
    (RecordDetail in clob)
    return number
    is
--  Created on 29/07/08
    numError            number;
    numTemp             number;
    numStatus           number;
    numSub              number(3);
    numSub1             number(3);
    numSerial           number(5);
    numSerial1          number(5);
    numAction           number(4);
    numCompany          number(8);
    numLocation         number(8);
    numCode             number(8);
    numCode1            number(8);
    numCode2            number(8);
    numCode3            number(8);
    numCode4            number(8);
    numCross            number(15,4);
    numFCY              number(15,4);
    numFCY1             number(15,4);
    numFCY2             number(15,6);
    numFCY3             number(15,4);
    numFcy4             number(15,4);
    numINR              number(15,2);
    numRate             number(15,6);
    numRate1            number(15,6);
    varReference        varchar2(30);
    varReference1       varchar2(30);
    varReference2       varchar2(30);
    varUserID           varchar2(30);
    varEntity           varchar2(30);
    varAcNumber         varchar2(50);
    VarVoucherPass      number(8);
    varTemp             varchar2(512);
    varTemp1            varchar2(512);
    varXPath            varchar2(512);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    datWorkDate         date;
    datTemp             date;
    datTemp1            date;
    datMaturity         date;
    clbTemp             clob;
    clbError            clob;
    clbProcess          clob;
    xmlTemp             xmlType;
    nodTemp             xmlDom.domNode;
    nodTemp1            xmlDom.domNode;
    nmpTemp             xmldom.domNamedNodemap;
    nmpTemp1            xmldom.domNamedNodemap;
    nlsTemp             xmlDom.DomNodeList;
    nlsTemp1            xmlDom.DomNodeList;
    xlParse             xmlparser.parser;
    nodFinal            xmlDom.domNode;
    docFinal            xmlDom.domDocument;
      -------added by kumar.h on 21/05/09------------
    numBank             number(8);
    numCrdr             number(8);
    numType             number(8);
    numHead             number(8);
    numRecord           number(8);
    numCurrency         number(8);
    numMerchant         number(8);
    varAccount          varchar2(25);
    varVoucher          varchar2(25);
    varDetail           varchar2(100);
    varTemp2            varchar2(512);
    nodVoucher          xmlDom.domNode;
   ---------------------------------------------------
    Begin
    varMessage := 'Current Account Maintenance';
    dbms_lob.createTemporary (clbTemp,  TRUE);
    clbTemp := RecordDetail;

    numError := 0;
    varOperation := 'Extracting Input Parameters';
    xmlTemp := xmlType(RecordDetail);

    varUserID := GConst.fncXMLExtract(xmlTemp, 'UserCode', varUserID);
    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
    numCompany := GConst.fncXMLExtract(xmlTemp, 'CompanyId', numCompany);
    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationId', numLocation);

    numError := 2;
    varOperation := 'Creating Document for Master';
    docFinal := xmlDom.newDomDocument(xmlTemp);
    nodFinal := xmlDom.makeNode(docFinal);

    if varEntity = 'EXTENSIONHEDGEDEAL' then
        varXPath := '//' || varEntity || '/ROW[@NUM]/';
        varTemp := varXPath || 'LMOD_REFERENCE_NUMBER';
        varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
        varTemp := varXPath || 'LMOD_REFERENCE_SERIAL';
        numSerial := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || 'LMOD_SERIAL_NUMBER';
        numSerial1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

--        select deal_buy_sell, deal_other_currency, lbnk_account_number
--          into numCode, numCode1, varAcNumber
--          from trtran001, trmaster306
--          where deal_deal_number = varReference
--          and deal_serial_number = numSerial
--          and deal_counter_party = lbnk_pick_code;
            select deal_buy_sell, deal_other_currency, lbnk_account_number,lbnk_voucher_pass
              into numCode, numCode1, varAcNumber,VarVoucherPass
              from trtran001, trmaster306
              where deal_deal_number = varReference
              and deal_serial_number = numSerial
              and deal_counter_party = lbnk_pick_code;
-- REVERSAL ENTRIES
        if numCode = GConst.PURCHASEDEAL then
          numCode2 := GConst.TRANSACTIONCREDIT;
          numCode3 := GConst.ACFCYSALE;
          numCode4 := GConst.EVENTPURROLLOVER;
        else
          numCode2 := GConst.TRANSACTIONDEBIT;
          numCode3 := GConst.ACFCYPURCHASE;
          numCode4 := GConst.EVENTSALROLLOVER;
        end if;

       if numAction in (GConst.EDITSAVE, GConst.DELETESAVE) then
        delete from trtran008
          where bcac_voucher_number =
          (select lmod_pl_voucher
            from trtran009
            where lmod_reference_number = varReference
            and lmod_reference_serial = numSerial
            and lmod_serial_number = numSerial1);
      end if;

      if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then

        varOperation := 'Inserting voucher for Profit/Loss';
        varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
        insert into trtran008 (bcac_company_code, bcac_location_code,
          bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
          bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
          bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
          bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
          bcac_create_date, bcac_local_merchant, bcac_record_status,
          bcac_record_type, bcac_account_number)
        select numCompany, numLocation, deal_counter_party, varReference1,
--          pkgReturnCursor.fncRollover(deal_deal_number),
          decode(VarVoucherPass,gconst.CAVOUCHERONVALUEDATE,
--          pkgReturnCursor.fncRollover(deal_deal_number),
          deal_maturity_date,
          gconst.CAVOUCHERONCANCELDATE,lmod_change_date),
          --deal_maturity_date,
          decode(sign(lmod_profit_loss),-1,GConst.TRANSACTIONDEBIT,
          GConst.TRANSACTIONCREDIT), GConst.ACEXCHANGE, numCode4, varReference,
          numSerial,deal_base_currency, lmod_enhanced_fcy, lmod_enhanced_rate,
          abs(lmod_profit_loss), 'Deal Rollover No: ' || deal_deal_number,
          sysdate,30999999,GConst.STATUSENTRY, 23800002, varAcNumber
          from trtran001, trtran009
          where deal_deal_number = lmod_reference_number
          and deal_serial_number = lmod_reference_serial
          and deal_deal_number = varReference
          and deal_serial_number = numSerial
          and lmod_serial_number = numSerial1;

        varOperation := 'Updating Voucher Number in Cancel Deal';
        update trtran009
          set lmod_pl_voucher = varReference1
          where lmod_reference_number = varReference
          and lmod_reference_serial = numSerial
          and lmod_serial_number = numSerial1;

      End if;

    END IF;
--Since voucher generation has beed disabled, logic for edit, deletion etc
--has not been written. If the company wants these vouchers then logic has
--written, However for P L entry the logic already exists - TMM 12/10/08

    if varEntity in ('TRADEDEALREGISTER', 'HEDGEDEALREGISTER') then
 -- The return statement is incorporated to disable automatic voucher passing - 12/10/08
      return numError;
      if numAction in (GConst.ADDSAVE) then
        varXPath := '//' || varEntity || '/ROW[@NUM]';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        varXPath := '//' || varEntity||  '/ROW[@NUM="';
        for numSub in 0..xmlDom.getLength(nlsTemp) -1
          Loop
            nodTemp := xmlDom.item(nlsTemp, numSub);
            nmpTemp := xmlDom.getAttributes(nodTemp);
            nodTemp1 := xmlDom.item(nmpTemp, 0);
            numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
            varTemp := varXPath || numTemp || '"]/DEAL_DEAL_NUMBER';
            varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
            varTemp := varXPath || numTemp || '"]/DEAL_SERIAL_NUMBER';
            numSerial := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
            varTemp := varXPath || numTemp || '"]/DEAL_BUY_SELL';
            numCode := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
            varTemp := varXPath || numTemp || '"]/DEAL_OTHER_CURRENCY';
            numCode1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
            varTemp := varXPath || numTemp || '"]/DEAL_COUNTER_PARTY';
            numCode2 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

            varOperation := 'Getting Bank Account Number';
            select NVL(lbnk_account_number,'')
              into varAcNumber
              from trmaster306
              where lbnk_pick_code = numCode2;

            if numCode = GConst.SALEDEAL then
              numCode2 := GConst.TRANSACTIONCREDIT;
              numCode3 := GConst.ACFCYSALE;
              numCode4 := GConst.EVENTSALE;
            else
              numCode2 := GConst.TRANSACTIONDEBIT;
              numCode3 := GConst.ACFCYPURCHASE;
              numCode4 := GConst.EVENTPURCHASE;
            end if;

            varOperation := 'Inserting voucher for Foreign Currency';
            varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
            insert into trtran008 (bcac_company_code, bcac_location_code,
              bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
              bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
              bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
              bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
              bcac_create_date, bcac_local_merchant, bcac_record_status,
              bcac_record_type, bcac_account_number)
            select numCompany, numLocation, deal_counter_party, varReference1,
              datWorkDate, numCode2, numCode3, numCode4, varReference, numSerial,
              deal_base_currency, deal_base_amount, deal_exchange_rate,
              decode(deal_other_currency, GConst.INDIANRUPEE, deal_other_amount,
              deal_amount_local), 'Deal Execution No: ' || deal_deal_number,
              sysdate,30999999,GConst.STATUSENTRY, 23800002, varAcNumber
              from trtran001
              where deal_deal_number = varReference
              and deal_serial_number = numSerial;

            varOperation := 'Inserting voucher for Local Currency';
            varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
            insert into trtran008 (bcac_company_code, bcac_location_code,
              bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
              bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
              bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
              bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
              bcac_create_date, bcac_local_merchant, bcac_record_status,
              bcac_record_type, bcac_account_number)
            select numCompany, numLocation, deal_counter_party, varReference1,
              datWorkDate,
              decode(numCode2, GConst.TRANSACTIONCREDIT, GConst.TRANSACTIONDEBIT,
              GConst.TRANSACTIONCREDIT), decode(numCode3, GConst.ACFCYSALE,
              GConst.ACINRPURCHASE, GConst.ACINRSALE),  numCode4,
              varReference, numSerial, deal_base_currency, deal_base_amount,
              deal_exchange_rate, decode(deal_other_currency, GConst.INDIANRUPEE,
              deal_other_amount, deal_amount_local), 'Deal Execution No: ' ||
              deal_deal_number,sysdate,30999999,GConst.STATUSENTRY, 23800002, varAcNumber
              from trtran001
              where deal_deal_number = varReference
              and deal_serial_number = numSerial;
  --Cross Currency Deals
            if numCode1 != GConst.INDIANRUPEE then
              varOperation := 'Inserting voucher for Cross Currency';
              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
              insert into trtran008 (bcac_company_code, bcac_location_code,
                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                bcac_create_date, bcac_local_merchant, bcac_record_status,
                bcac_record_type, bcac_account_number)
              select numCompany, numLocation, deal_counter_party, varReference1,
                datWorkDate,
                decode(numCode2, GConst.TRANSACTIONCREDIT, GConst.TRANSACTIONDEBIT,
                GConst.TRANSACTIONCREDIT), decode(numCode3, GConst.ACFCYSALE,
                 GConst.ACFCYPURCHASE, GConst.ACFCYSALE),  decode(numCode4,
                GConst.EVENTSALE, GConst.EVENTPURCHASE, GConst.EVENTSALE),
                varReference, numSerial, deal_other_currency, deal_other_amount,
                deal_local_rate, deal_amount_local, 'Deal Execution No: ' ||
                deal_deal_number,sysdate,30999999,GConst.STATUSENTRY, 23800002, ''
                from trtran001
                where deal_deal_number = varReference
                and deal_serial_number = numSerial;

              varOperation := 'Inserting voucher for Cross Currency INR';
              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
              insert into trtran008 (bcac_company_code, bcac_location_code,
                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                bcac_create_date, bcac_local_merchant, bcac_record_status,
                bcac_record_type, bcac_account_number)
              select numCompany, numLocation, deal_counter_party, varReference1,
                datWorkDate, numCode2, decode(numCode3, GConst.ACFCYSALE,
                GConst.ACINRSALE, GConst.ACINRPURCHASE), decode(numCode4,
                GConst.EVENTSALE, GConst.EVENTPURCHASE, GConst.EVENTSALE),
                varReference, numSerial, deal_base_currency, deal_base_amount,
                deal_exchange_rate, deal_amount_local, 'Deal Execution No: ' ||
                deal_deal_number, sysdate,30999999,GConst.STATUSENTRY, 23800002, varAcNumber
                from trtran001
                where deal_deal_number = varReference
                and deal_serial_number = numSerial;
          end if;

        End Loop;

      end if;

     elsif varEntity in ('TRADEDEALCANCELLATION', 'HEDGEDEALCANCELLATION') then
--      if numAction in (GConst.ADDSAVE) then
        varXPath := '//' || varEntity || '/ROW[@NUM]';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        varXPath := '//' || varEntity||  '/ROW[@NUM="';
        for numSub in 0..xmlDom.getLength(nlsTemp) -1
          Loop
            nodTemp := xmlDom.item(nlsTemp, numSub);
            nmpTemp := xmlDom.getAttributes(nodTemp);
            nodTemp1 := xmlDom.item(nmpTemp, 0);
            numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
            varTemp := varXPath || numTemp || '"]/CDEL_DEAL_NUMBER';
            varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
            varTemp := varXPath || numTemp || '"]/CDEL_DEAL_SERIAL';
            numSerial := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--            varTemp := varXPath || numTemp || '"]/CDEL_TRADE_SERIAL';
--            numSerial1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
            varTemp := varXPath || numTemp || '"]/CDEL_REVERSE_SERIAL';
            numSerial1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

            select deal_buy_sell, deal_other_currency, lbnk_account_number,lbnk_voucher_pass
              into numCode, numCode1, varAcNumber,VarVoucherPass
              from trtran001, trmaster306
              where deal_deal_number = varReference
              and deal_serial_number = numSerial
              and deal_counter_party = lbnk_pick_code;
-- REVERSAL ENTRIES
            if numCode = GConst.PURCHASEDEAL then
              numCode2 := GConst.TRANSACTIONCREDIT;
              numCode3 := GConst.ACFCYSALE;
              numCode4 := GConst.EVENTPURREVERSAL;
            else
              numCode2 := GConst.TRANSACTIONDEBIT;
              numCode3 := GConst.ACFCYPURCHASE;
              numCode4 := GConst.EVENTSALREVERSAL;
            end if;
 -- The Go to statement is incorporated to disable automatic voucher passing - 12/10/08
            Goto Profit_Loss;

            varOperation := 'Reversing voucher for Foreign Currency';
            varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--            delete from temp;
--            insert into temp values (datWorkDate,datWorkDate);
--            commit;

            insert into trtran008 (bcac_company_code, bcac_location_code,
              bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
              bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
              bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
              bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
              bcac_create_date, bcac_local_merchant, bcac_record_status,
              bcac_record_type, bcac_account_number)
            select numCompany, numLocation, deal_counter_party, varReference1,
              datWorkDate, numCode2, numCode3, numCode4, varReference, numSerial,
              deal_base_currency, cdel_cancel_amount, deal_exchange_rate,
              decode(sign(deal_base_amount - cdel_cancel_amount), 0,
              decode(deal_other_currency, GConst.INDIANRUPEE, deal_other_amount,
              deal_amount_local), round(cdel_cancel_amount * deal_exchange_rate)),
              'Deal Reversal No: ' || deal_deal_number,
              sysdate,30999999,GConst.STATUSENTRY, 23800002, varAcNumber
              from trtran001, trtran006
              where deal_deal_number = cdel_deal_number
              and deal_serial_number = cdel_deal_serial
              and deal_deal_number = varReference
              and deal_serial_number = numSerial
              and cdel_reverse_serial = numSerial1;

            varOperation := 'Inserting voucher for Local Currency';
            varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
            insert into trtran008 (bcac_company_code, bcac_location_code,
              bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
              bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
              bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
              bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
              bcac_create_date, bcac_local_merchant, bcac_record_status,
              bcac_record_type, bcac_account_number)
            select numCompany, numLocation, deal_counter_party, varReference1,
              datWorkDate,
              decode(numCode2, GConst.TRANSACTIONCREDIT, GConst.TRANSACTIONDEBIT,
              GConst.TRANSACTIONCREDIT), decode(numCode3, GConst.ACFCYSALE,
              GConst.ACINRPURCHASE, GConst.ACINRSALE), numCode4,
              varReference, numSerial, deal_base_currency, cdel_cancel_amount,
              deal_exchange_rate,
              decode(sign(deal_base_amount - cdel_cancel_amount), 0,
              decode(deal_other_currency, GConst.INDIANRUPEE, deal_other_amount,
              deal_amount_local), round(cdel_cancel_amount * deal_exchange_rate)),
              'Deal Reversal No: ' ||
              deal_deal_number,sysdate,30999999,GConst.STATUSENTRY, 23800002, varAcNumber
              from trtran001, trtran006
              where deal_deal_number = cdel_deal_number
              and deal_serial_number = cdel_deal_serial
              and deal_deal_number = varReference
              and deal_serial_number = numSerial
              and cdel_reverse_serial = numSerial1;
--  Cross Currency Deals
            if numCode1 != GConst.INDIANRUPEE then
              varOperation := 'Inserting voucher for Cross Currency';
              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
              insert into trtran008 (bcac_company_code, bcac_location_code,
                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                bcac_create_date, bcac_local_merchant, bcac_record_status,
                bcac_record_type, bcac_account_number)
              select numCompany, numLocation, deal_counter_party, varReference1,
                datWorkDate,
                decode(numCode2, GConst.TRANSACTIONCREDIT, GConst.TRANSACTIONDEBIT,
                GConst.TRANSACTIONCREDIT), decode(numCode3, GConst.ACFCYSALE,
                GConst.ACFCYPURCHASE, GConst.ACFCYSALE), decode(numCode4,
                GConst.EVENTSALREVERSAL, GConst.EVENTPURREVERSAL, GConst.EVENTSALREVERSAL),
                varReference, numSerial, deal_other_currency, cdel_other_amount,
                deal_local_rate,
                decode(sign(deal_other_amount - cdel_other_amount), 0,
                  deal_amount_local, round(cdel_other_amount * deal_local_rate)),
                'Deal Reversal No: ' ||
                deal_deal_number,sysdate,30999999,GConst.STATUSENTRY, 23800002, varAcNumber
                from trtran001, trtran006
                where deal_deal_number = cdel_deal_number
                and deal_serial_number = cdel_deal_serial
                and deal_deal_number = varReference
                and deal_serial_number = numSerial
                and cdel_reverse_serial = numSerial1;

              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
              insert into trtran008 (bcac_company_code, bcac_location_code,
                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                bcac_create_date, bcac_local_merchant, bcac_record_status,
                bcac_record_type, bcac_account_number)
              select numCompany, numLocation, deal_counter_party, varReference1,
                datWorkDate, numCode2, decode(numCode3, GConst.ACFCYSALE,
                GConst.ACINRSALE, GConst.ACINRPURCHASE),decode(numCode4,
                GConst.EVENTSALREVERSAL, GConst.EVENTPURREVERSAL,
                GConst.EVENTSALREVERSAL),varReference, numSerial,
                deal_other_currency, cdel_other_amount, deal_local_rate,
                decode(sign(deal_other_amount - cdel_other_amount), 0,
                  deal_amount_local, round(cdel_other_amount * deal_local_rate)),
                'Deal Reversal No: ' || deal_deal_number,
                sysdate,30999999,GConst.STATUSENTRY, 23800002, varAcNumber
                from trtran001, trtran006
                where deal_deal_number = cdel_deal_number
                and deal_serial_number = cdel_deal_serial
                and deal_deal_number = varReference
                and deal_serial_number = numSerial
                and cdel_reverse_serial = numSerial1;
            end if;
<<Profit_Loss>>
          if numAction in (GConst.EDITSAVE, GConst.DELETESAVE) then
              delete from trtran008
                where bcac_voucher_number =
                (select cdel_pl_voucher
                  from trtran006
                  where cdel_deal_number = varReference
                  and cdel_deal_serial = numSerial
                  and cdel_reverse_serial = numSerial1);
            end if;

            if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then

              varOperation := 'Inserting voucher for Profit/Loss';
              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
              insert into trtran008 (bcac_company_code, bcac_location_code,
                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                bcac_create_date, bcac_local_merchant, bcac_record_status,
                bcac_record_type, bcac_account_number, bcac_recon_flag)
              select numCompany, numLocation, deal_counter_party, varReference1,
                decode(VarVoucherPass,gconst.CAVOUCHERONVALUEDATE,
                pkgReturnCursor.fncRollover(deal_deal_number),
                gconst.CAVOUCHERONCANCELDATE,cdel_cancel_date,
                gconst.CAVOUCHERPROFITLOSS, decode(sign(cdel_profit_loss),-1,cdel_cancel_date,
                pkgReturnCursor.fncRollover(deal_deal_number)),datworkdate),
                decode(sign(cdel_profit_loss),-1,GConst.TRANSACTIONDEBIT,
                GConst.TRANSACTIONCREDIT), GConst.ACEXCHANGE, numCode4, varReference,
                numSerial,deal_base_currency, CDEL_PANDL_USD, CDEL_PANDL_SPOT,
                abs(cdel_profit_loss), 'Deal Reversal No: ' || deal_deal_number,
                sysdate,30999999,GConst.STATUSENTRY, 23800002, varAcNumber,12400002
                from trtran001, trtran006
                where deal_deal_number = cdel_deal_number
                and deal_serial_number = cdel_deal_serial
                and deal_deal_number = varReference
                and deal_serial_number = numSerial
                and cdel_reverse_serial = numSerial1;

              varOperation := 'Updating Voucher Number in Cancel Deal';
              update trtran006
                set cdel_pl_voucher = varReference1
                where cdel_deal_number = varReference
                and cdel_deal_serial = numSerial
                and cdel_reverse_serial = numSerial1;

            End if;
          End Loop;
---Passing Vouchers For Commodity Daily Profit Loss  Modified on 03-apr-2009
    elsif varEntity in ('COMMODITYVALUATION') then
        varXPath := '//' || varEntity || '/ROW[@NUM]';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        varXPath := '//' || varEntity||  '/ROW[@NUM="';
        for numSub in 0..xmlDom.getLength(nlsTemp) -1
          Loop
            nodTemp := xmlDom.item(nlsTemp, numSub);
            nmpTemp := xmlDom.getAttributes(nodTemp);
            nodTemp1 := xmlDom.item(nmpTemp, 0);
            numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
            varTemp := varXPath || numTemp || '"]/CMTR_DEAL_NUMBER';
            varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
            varTemp := varXPath || numTemp || '"]/CMTR_SERIAL_NUMBER';
            numSerial := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

            if numAction in (GConst.EDITSAVE, GConst.DELETESAVE) then
              delete from trtran008
                where bcac_voucher_number =
                (select cmtr_pl_voucher
                  from trtran052
                  where cmtr_deal_number = varReference
                  and cmtr_serial_number = numSerial);
            end if;

            if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
              varOperation := 'Inserting voucher for Daily Commodity Profit/Loss';
              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
              insert into trtran008 (bcac_company_code, bcac_location_code,
                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                bcac_create_date, bcac_local_merchant, bcac_record_status,
                bcac_record_type, bcac_account_number, bcac_recon_flag)
              select numCompany, numLocation, cmdl_local_bank, varReference1,
                datWorkDate,decode(sign(cmtr_profit_loss),-1,GConst.TRANSACTIONDEBIT,
                GConst.TRANSACTIONCREDIT), GConst.ACEXCHANGE, GConst.EVENTCOMMDAILYPL, varReference,
                1,cmdl_currency_code, cmdl_deal_amount, cmdl_exchange_rate,
                abs(cmtr_profit_loss), 'Daily Commodity P No: ' || cmtr_deal_number,
                sysdate,30999999,GConst.STATUSENTRY, 23800002, (select lbnk_account_number
                   from trmaster306
                   where lbnk_pick_code = cmdl_local_bank
                   and lbnk_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED)),12400002
                from trtran051, trtran052
                where cmdl_deal_number = cmtr_deal_number
                and cmtr_deal_number = varReference
                and cmtr_mtm_date=datWorkDate;

              varOperation := 'Updating Voucher Number in Daily Profit/Loss';
              update trtran052
                set cmtr_pl_voucher = varReference1
                where cmtr_deal_number = varReference
                 and cmtr_mtm_date=datWorkDate ;
            End if;
         end loop;

    --currency Future Valuvation
    elsif varEntity in ('CURRENCYFUTUREVALUATION') then
        varXPath := '//' || varEntity || '/ROW[@NUM]';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        varXPath := '//' || varEntity||  '/ROW[@NUM="';
        for numSub in 0..xmlDom.getLength(nlsTemp) -1
          Loop
            nodTemp := xmlDom.item(nlsTemp, numSub);
            nmpTemp := xmlDom.getAttributes(nodTemp);
            nodTemp1 := xmlDom.item(nmpTemp, 0);
            numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
            varTemp := varXPath || numTemp || '"]/CFMR_DEAL_NUMBER';
            varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
            varTemp := varXPath || numTemp || '"]/CFMR_SERIAL_NUMBER';
            numSerial := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));

            if numAction in (GConst.EDITSAVE, GConst.DELETESAVE) then
              delete from trtran008
                where bcac_voucher_number =
                (select cfmr_pl_voucher
                  from trtran062
                  where cfmr_deal_number = varReference
                  and cfmr_serial_number = numSerial);
            end if;

            if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
              varOperation := 'Inserting voucher for Daily Currency Future Profit/Loss';
              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
              insert into trtran008 (bcac_company_code, bcac_location_code,
                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                bcac_create_date, bcac_local_merchant, bcac_record_status,
                bcac_record_type, bcac_account_number, bcac_recon_flag)
              select numCompany, numLocation, cfut_local_bank, varReference1,
                datWorkDate,decode(sign(cfmr_profit_loss),-1,GConst.TRANSACTIONDEBIT,
                GConst.TRANSACTIONCREDIT), GConst.ACEXCHANGE, GConst.EVENTFUTUREPL, varReference,
                1,30400003, 0, CFMR_MTM_RATE,
                abs(cfmr_profit_loss), 'Daily Currency Future P No: ' || cfmr_deal_number,
                sysdate,30999999,GConst.STATUSENTRY, 23800002, (select lbnk_account_number
                   from trmaster306
                   where lbnk_pick_code = cfut_local_bank
                   and lbnk_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED)),12400002
                from trtran061, trtran062
                where cfut_deal_number = cfmr_deal_number
                and cfmr_deal_number = varReference
                and cfmr_mtm_date=datWorkDate;

              varOperation := 'Updating Voucher Number in Daily Profit/Loss';
              update trtran062
                set cfmr_pl_voucher = varReference1
                where cfmr_deal_number = varReference
                 and cfmr_mtm_date=datWorkDate ;
            End if;
         end loop;

    elsif varEntity in ('HEDGECOMMODITYDEAL','TRADECOMMODITYDEAL') then

        varXPath := '//' || varEntity||  '/ROW[@NUM="1';
        varTemp := varXPath || '"]/CMDL_DEAL_NUMBER';
        varReference2 := GConst.fncGetNodeValue(nodFinal, varTemp);

        varXPath := '//' || varEntity || '/ReverseDetails/ReverseRow[@NUM]';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        varXPath := '//' || varEntity || '/ReverseDetails/ReverseRow[@NUM="';
        for numSub in 0..xmlDom.getLength(nlsTemp) -1
          Loop

            nodTemp := xmlDom.item(nlsTemp, numSub);
            nmpTemp := xmlDom.getAttributes(nodTemp);
            nodTemp1 := xmlDom.item(nmpTemp, 0);
            numTemp := to_number(xmlDom.getNodeValue(nodTemp1));

            varTemp := varXPath || numTemp || '"]/ReverseDealNumber';

            varReference := GConst.fncGetNodeValue(nodFinal, varTemp);

           -- insert into temp values(varReference,varTemp);

            if numAction in (GConst.EDITSAVE, GConst.DELETESAVE) then
              delete from trtran008
                where bcac_voucher_number =
                (select crev_pl_voucher
                  from trtran053
                  where crev_deal_number = varReference
                  and crev_reverse_deal = varReference2);
            end if;

            if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
              varOperation := 'Inserting voucher for Commodity Deal Reversal';
              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
              insert into trtran008 (bcac_company_code, bcac_location_code,
                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                bcac_create_date, bcac_local_merchant, bcac_record_status,
                bcac_record_type, bcac_account_number)
              select numCompany, numLocation, cmdl_local_bank, varReference1,
                datWorkDate,decode(sign(crev_profit_loss),-1,GConst.TRANSACTIONDEBIT,
                GConst.TRANSACTIONCREDIT), GConst.ACEXCHANGE,GConst.EVENTCOMMDAILYPL, varReference,
                1,cmdl_currency_code, cmdl_deal_amount, cmdl_exchange_rate,
                abs(crev_profit_loss), 'Commodity Deal Reversal  No: ' || crev_reverse_deal,
                sysdate,30999999,GConst.STATUSENTRY, 23800002, (select lbnk_account_number
                   from trmaster306
                   where lbnk_pick_code = cmdl_local_bank
                   and lbnk_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED))
                from trtran051, trtran053
                where cmdl_deal_number = crev_deal_number
                and crev_deal_number = varReference2
                and crev_reverse_deal = varReference;

              varOperation := 'Updating Voucher Number in Reversal Commodity Deal';
              update trtran053
                set crev_pl_voucher = varReference1
                where crev_deal_number = varReference2
                 and crev_reverse_deal= varReference;
            End if;
         end loop;


    elsif varEntity in ('COMMODITYDEALCANCEL') then

        varXPath := '//' || varEntity||  '/ROW[@NUM="1';
        varTemp := varXPath || '"]/CREV_DEAL_NUMBER';
        varReference := GConst.fncGetNodeValue(nodFinal, varTemp);

        if numAction in (GConst.EDITSAVE, GConst.DELETESAVE) then
              delete from trtran008
                where bcac_voucher_number =
                (select crev_pl_voucher
                  from trtran053
                  where crev_deal_number = varReference);
        end if;
        if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
              varOperation := 'Inserting voucher for Commodity Deal cancellation';
              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
              insert into trtran008 (bcac_company_code, bcac_location_code,
                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                bcac_create_date, bcac_local_merchant, bcac_record_status,
                bcac_record_type, bcac_account_number)
              select numCompany, numLocation, cmdl_local_bank, varReference1,
                datWorkDate,decode(sign(crev_profit_loss),-1,GConst.TRANSACTIONDEBIT,
                GConst.TRANSACTIONCREDIT), GConst.ACEXCHANGE, GConst.EVENTCOMMDAILYPL, varReference,
                1,cmdl_currency_code, cmdl_deal_amount, cmdl_exchange_rate,
                abs(crev_profit_loss), 'Commodity Deal Reversal  No: ' || crev_reverse_deal,
                sysdate,30999999,GConst.STATUSENTRY, 23800002, (select lbnk_account_number
                   from trmaster306
                   where lbnk_pick_code = cmdl_local_bank
                   and lbnk_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED))
                from trtran051, trtran053
                where cmdl_deal_number = crev_deal_number
                and crev_deal_number = varReference
                and crev_reverse_deal = varReference;

              varOperation := 'Updating Voucher Number in Reversal Commodity Deal';
              update trtran053
                set crev_pl_voucher = varReference1
                where crev_deal_number = varReference
                 and crev_reverse_deal= varReference;
            End if;
            -----
   elsif varEntity in ('CURRENCYFUTURETRADDEALCANCEL','CURRENCYFUTUREDEALCANCEL') then
        
        varXPath := '//' || varEntity||  '/ROW[@NUM="1';   
        varTemp := varXPath || '"]/CFRV_DEAL_NUMBER';
        varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
        varTemp := varXPath ||'"]/CFRV_REVERSE_SERIAL'; 
  
        varReference2 := GConst.fncGetNodeValue(nodFinal, varTemp);
        if numAction in (GConst.EDITSAVE, GConst.DELETESAVE) then
              delete from trtran008
                where bcac_voucher_number =
                (select cfrv_pl_voucher
                  from trtran063
                  where cfrv_deal_number = varReference
                and CFRV_REVERSE_SERIAL = varReference2);
        end if;
        if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
              varOperation := 'Inserting voucher for Currency Future Deal cancellation';
              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
              insert into trtran008 (bcac_company_code, bcac_location_code, 
                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code, 
                bcac_account_head, bcac_voucher_type, bcac_voucher_reference, 
                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy, 
                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                bcac_create_date, bcac_local_merchant, bcac_record_status,
                bcac_record_type, bcac_account_number)
              select numCompany, numLocation, cfut_local_bank, varReference1,
                datWorkDate,decode(sign(cfrv_profit_loss),-1,GConst.TRANSACTIONDEBIT,
                GConst.TRANSACTIONCREDIT), GConst.ACEXCHANGE, GConst.EVENTFUTUREPL, varReference, 
                1,cfut_base_currency, cfrv_reverse_lot, cfrv_lot_price,
                abs(cfrv_profit_loss), 'Future Deal Reversal  No: ' || cfrv_reverse_deal,
                sysdate,30999999,GConst.STATUSENTRY, 23800002, (select lbnk_account_number
                   from trmaster306
                   where lbnk_pick_code = cfut_local_bank
                   and lbnk_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED))
--                from trtran061, trtran063
--                where cfut_deal_number = cfrv_deal_number
--                and cfrv_deal_number = varReference
--                and cfrv_reverse_deal = varReference;
                from trtran061 left outer join trtran063 m
                on cfut_deal_number = m.cfrv_deal_number
                where cfut_deal_number = varReference
                and m.cfrv_reverse_deal = varReference
                and m.cfrv_reverse_serial = (select max(cfrv_reverse_serial) 
                                            from trtran063 sub
                                           where sub.cfrv_reverse_deal= m.cfrv_reverse_deal)
                                           
                and m.cfrv_record_status not in(10200005,10200006)
                and cfut_record_status not in(10200005,10200006);

              varOperation := 'Updating Voucher Number in Reversal Commodity Deal';
              update trtran063
                set cfrv_pl_voucher = varReference1
                where cfrv_deal_number = varReference
                 and cfrv_reverse_deal= varReference
                AND CFRV_REVERSE_SERIAL = varReference2;
            End if;      
      
      ---------  
    elsif varEntity in ('OPTIONHEDGEEXERCISE','OPTIONTRADEEXERCISE') then
        
        varXPath := '//' || varEntity||  '/ROW[@NUM="1';   
        varTemp := varXPath || '"]/CORV_DEAL_NUMBER';
        varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
        varTemp := varXPath || '"]/CORV_SERIAL_NUMBER';
        numserial := GConst.fncGetNodeValue(nodFinal, varTemp);
        varTemp := varXPath || '"]/CORV_SUBSERIAL_NUMBER';
        numserial1 := GConst.fncGetNodeValue(nodFinal, varTemp);
        varTemp := varXPath || '"]/CORV_SETTLEMENT_DATE';
        VarOperation :='Extracting Deals' || GConst.fncGetNodeValue(nodFinal, varTemp);
        --varTemp := varXPath || '"]/CORV_SETTLEMENT_DATE';
        datTemp := to_date(GConst.fncGetNodeValue(nodFinal, varTemp),'dd-MM-yyyy');
        
        varTemp := varXPath || '"]/CORV_EXERCISE_DATE';
        VarOperation :='Extracting Deals' || GConst.fncGetNodeValue(nodFinal, varTemp);
        

        
        
        
        --varTemp := varXPath || '"]/CORV_SETTLEMENT_DATE';
        datTemp1 := to_date(GConst.fncGetNodeValue(nodFinal, varTemp),'dd-MM-yyyy');
        
        VarOperation :='Getting information ' || GConst.fncGetNodeValue(nodFinal, varTemp);
        varTemp := varXPath || '"]/CORV_EXERCISE_TYPE';
        numcode1 :=GConst.fncGetNodeValue(nodFinal, varTemp);
        
        varTemp := varXPath || '"]/CORV_PREMIUM_STATUS';
        numCode3 := GConst.fncGetNodeValue(nodFinal, varTemp);

        --VarOperation :='Getting information for Exercise Type' || ;
     if numcode1!= Gconst.NoExercise then
      begin        
        select lbnk_voucher_pass,lbnk_account_number,lbnk_pick_code,copt_base_currency
          into VarVoucherPass,varAccount,numBank,numcode
          from trtran071, trmaster306
         where copt_deal_number = varReference
           and copt_counter_party = lbnk_pick_code
           and copt_record_status not in(10200005,10200006);
        exception
        when others then
           select cbrk_voucher_pass,cbrk_account_number,cbrk_pick_code,copt_base_currency
             into VarVoucherPass,varAccount,numBank,numcode
            from trtran071, trmaster502
           where copt_deal_number = varReference
             and copt_counter_party = cbrk_pick_code
             and copt_record_status not in(10200005,10200006);
         end;

                      
        if numAction in (GConst.EDITSAVE, GConst.DELETESAVE) then
              delete from trtran008
                where bcac_voucher_number =
               (select corv_pl_voucher
                   from trtran073
                  where corv_deal_number = varReference
                                      and corv_serial_number =numserial
                    and corv_record_status in (GConst.STATUSINACTIVE,Gconst.STATUSDELETED))
                    and bcac_reference_serial =numserial ;
        end if;
        
              if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
              varOperation := 'Inserting voucher for Option Deal cancellation';
              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
              insert into trtran008 (bcac_company_code, bcac_location_code, 
                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code, 
                bcac_account_head, bcac_voucher_type, bcac_voucher_reference, 
                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy, 
                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                bcac_create_date, bcac_local_merchant, bcac_record_status,
                bcac_record_type, bcac_account_number)
              select numCompany, numLocation, numBank, varReference1,
              decode(VarVoucherPass,gconst.CAVOUCHERONVALUEDATE,
                   dattemp,gconst.CAVOUCHERONCANCELDATE,datTemp1,Gconst.CAVOUCHERPROFITLOSS,dattemp),
                decode(numcode1,Gconst.CancelDeal,decode(numCode3,Gconst.Received,GConst.TRANSACTIONCREDIT,GConst.PremiumPaid,
                GConst.TRANSACTIONDEBIT),Gconst.Exercise,
                decode(sign(corv_profit_loss),-1,GConst.TRANSACTIONDEBIT,
                GConst.TRANSACTIONCREDIT))  , Decode(numcode1,Gconst.CancelDeal,GCONST.ACPREMIUMAC,
                Gconst.Exercise,GConst.ACEXCHANGE), GConst.EVENTOPTIONSPL, varReference, 
                1,numcode, corv_pandl_spot,corv_pandl_usd,--copt_b_amount, 0,--copt_premium_exrate,  ------ Here is the change


                abs(corv_Profit_Loss), 'Options Deal Reversal No: ' || corv_deal_number || '-' || corv_serial_number || '-' ||  corv_subserial_number,
                sysdate,30999999,GConst.STATUSENTRY, 23800002, varAccount
                from trtran073
                where corv_deal_number = varReference
                  and corv_serial_number =numserial
                --and copt_serial_number =corv_serial_number
               -- and copt_subserial_number=corv_subserial_number
               -- and corv_serial_number= numserial
               -- and corv_subserial_number= numserial1
               -- and corv_deal_number = varReference
                and corv_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED);
 
              varOperation := 'Updating Voucher Number in Reversal Commodity Deal';
              update trtran073
                set corv_pl_voucher = varReference1
                where corv_deal_number = varReference
                 and corv_serial_number= numserial
                 and corv_subserial_number= numserial1
                 and corv_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED);
        end if;
      End if;                      
  elsif varEntity in('OPTIONHEDGEDEAL','OPTIONTRADEDEAL') then
        
        varXPath := '//' || varEntity||  '/ROW[@NUM="1';   
        varTemp := varXPath || '"]/COPT_DEAL_NUMBER';
        varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
        varTemp := varXPath || '"]/COPT_SERIAL_NUMBER';
        numserial := GConst.fncGetNodeValue(nodFinal, varTemp);
        
        varTemp := varXPath || '"]/COPT_PREMIUM_STATUS';
        numCode3 := GConst.fncGetNodeValue(nodFinal, varTemp);

        if numCode3 = GConst.NoPremium then
          return 0;
        end if;
        
        if numAction in (GConst.EDITSAVE, GConst.DELETESAVE) then
              delete from trtran008
                where bcac_voucher_number =
                (select copt_pl_voucher
                  from trtran071
                  where copt_deal_number = varReference
                   and copt_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED));
        end if;
        if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
              varOperation := 'Inserting voucher for Option Deal';
              varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
              insert into trtran008 (bcac_company_code, bcac_location_code, 
                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code, 
                bcac_account_head, bcac_voucher_type, bcac_voucher_reference, 
                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy, 
                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                bcac_create_date, bcac_local_merchant, bcac_record_status,
                bcac_record_type, bcac_account_number)
              select numCompany, numLocation, copt_counter_party, varReference1,
                copt_premium_valuedate,decode(numCode3,Gconst.Received,GConst.TRANSACTIONCREDIT,GConst.PremiumPaid,
                GConst.TRANSACTIONDEBIT), GConst.ACPREMIUMAC, GConst.EVENTOPTIONSPL, varReference, 
                1,copt_base_currency, copt_premium_amount,copt_premium_exrate,--copt_b_amount, 0,--copt_premium_exrate,
                abs(copt_premium_local), 'Options Deal   No: ' || copt_deal_number || '-' || copt_serial_number ,
                sysdate,30999999,GConst.STATUSENTRY, 23800002, (select lbnk_account_number
                   from trmaster306
                   where lbnk_pick_code = copt_counter_party
                   and lbnk_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED))
                from trtran071
                where copt_deal_number = varReference
                and copt_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED);
 
              varOperation := 'Updating Voucher Number Option Deal';
              update trtran071
                set copt_pl_voucher = varReference1
                where copt_deal_number = varReference
                and copt_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED);
      End if;                      

  end if;  
 --Money Module
--    if varEntity = 'MARKETDEAL' then
--      varReference := GConst.fncXMLExtract(xmlTemp, 'MDEL_DEAL_NUMBER', varReference);
--      varOperation := 'Inserting voucher for Money Market Deal';
--      varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--
--      insert into trtran008 (bcac_company_code, bcac_location_code,
--        bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--        bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--        bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--        bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--        bcac_create_date, bcac_local_merchant, bcac_record_status,
--        bcac_record_type, bcac_account_number)
--      select mdel_company_code, 0, mdel_local_bank, varReference1,
--        mdel_execute_date, decode(mdel_borrow_invest, GConst.MMBorrowing,
--        GConst.TRANSACTIONCREDIT, GConst.TRANSACTIONDEBIT), mdel_account_head,
--        GConst.EVENTMMDEAL, varReference, 0, mdel_currency_code, mdel_deal_amount,
--        mdel_exchange_rate, mdel_amount_local,'MM Deal Booking - ' || varReference,
--        sysdate, mdel_counter_party, GConst.STATUSENTRY,GConst.RECCURRENT,
--        lbnk_account_number
--        from trtran031, trmaster306
--        where mdel_deal_number = varReference
--        and mdel_local_bank = lbnk_pick_code;
--
--    End if;
--
--    if varEntity = 'DEALREDEMPTION' then
--      varReference := GConst.fncXMLExtract(xmlTemp, 'REDM_DEAL_CODE', varReference);
--      varOperation := 'Inserting voucher for MM Deal Redemption';
--      varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--
--      insert into trtran008 (bcac_company_code, bcac_location_code,
--        bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--        bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--        bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--        bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--        bcac_create_date, bcac_local_merchant, bcac_record_status,
--        bcac_record_type, bcac_account_number)
--      select mdel_company_code, 0, mdel_local_bank, varReference1,
--        datWorkDate, decode(mdel_borrow_invest, GConst.MMBorrowing,
--        GConst.TRANSACTIONDEBIT, GConst.TRANSACTIONCREDIT), mdel_account_head,
--        GConst.EVENTMMREDEEM, varReference, 0, mdel_currency_code, mdel_deal_amount,
--        mdel_exchange_rate, mdel_amount_local,'MM Deal Redemption - ' || varReference,
--        sysdate, mdel_counter_party, GConst.STATUSENTRY,GConst.RECCURRENT,
--        lbnk_account_number
--        from trtran031, trmaster306
--        where mdel_deal_number = varReference
--        and mdel_local_bank = lbnk_pick_code;
--
--      varOperation := 'Inserting voucher for Income / Expenditure';
--      varReference1 := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
--
--      insert into trtran008 (bcac_company_code, bcac_location_code,
--        bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--        bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--        bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--        bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--        bcac_create_date, bcac_local_merchant, bcac_record_status,
--        bcac_record_type, bcac_account_number)
--      select mdel_company_code, 0, mdel_local_bank, varReference1,
--        mdel_execute_date, decode(mdel_borrow_invest, GConst.MMBorrowing,
--        GConst.TRANSACTIONDEBIT, GConst.TRANSACTIONCREDIT),
--        decode(mdel_borrow_invest, GConst.MMBorrowing,
--        GConst.ACINTEXPENSE, GConst.ACINTINCOME),
--        GConst.EVENTMMREDEEM, varReference, 0, mdel_currency_code, redm_interest_amount,
--        redm_interest_rate, redm_interest_local,decode(mdel_borrow_invest, GConst.MMBorrowing,
--        'MM Deal Int.Expense - ' || varReference,'MM Deal Int.Income - ' || varReference),
--        sysdate, mdel_counter_party, GConst.STATUSENTRY,GConst.RECCURRENT,
--        lbnk_account_number
--        from trtran031, trtran043, trmaster306
--        where mdel_deal_number = varReference
--        and mdel_deal_number = redm_deal_code
--        and mdel_local_bank = lbnk_pick_code;
--
--        varOperation := 'Marking the MM Deal Closed';
--
--        update trtran031
--          set mdel_process_complete = GConst.OPTIONYES,
--          mdel_complete_date = datWorkDate
--          where mdel_deal_number = varReference;
--
--    end if;
  --Money Module


     --kumar.h updates 21/05/09
  if varEntity in ('BUYERSCREDIT') then

    varXPath := '//CURRENTACCOUNTMASTER/ROW';
    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
    numSub := xmlDom.getLength(nlsTemp);

    if numSub = 0 then
      return numError;
    End if;

    Begin
      varTemp := varXPath || '[@NUM="1"]/LocalBank';
      numBank := GConst.fncXMLExtract(xmlTemp,varTemp,numBank,Gconst.TYPENODEPATH);

      select lbnk_account_number
        into varAccount
        from trmaster306
       where lbnk_pick_code = numBank
         and lbnk_record_status not in(GConst.STATUSINACTIVE,Gconst.STATUSDELETED);

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
      elsif numStatus in (GConst.LOTNEW, GConst.LOTMODIFIED) then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BCRD_BUYERS_CREDIT';
          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
          numSerial := 0;
          varDetail := varDetail || varReference;
        if numStatus = GConst.LOTMODIFIED then
            delete from trtran008
                   where bcac_voucher_reference = varReference
                   and bcac_reference_serial = numSerial
                   and bcac_account_head = numHead;
        End if;
         varVoucher := 'CA/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
        insert into trtran008 (bcac_company_code, bcac_location_code,
          bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
          bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
          bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
          bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
          bcac_create_date, bcac_local_merchant, bcac_record_status,
          bcac_record_type, bcac_account_number)
        values(numCompany, numLocation, numBank, varVoucher, datWorkDate,
        numCrdr, numHead, numType, varReference, numSerial, numCurrency,
        numFcy, numRate, numInr, varDetail, sysdate, numMerchant, GConst.STATUSENTRY,
        numRecord, varAccount);

      elsif numStatus = GConst.LOTDELETED then
           delete from trtran008
                   where bcac_voucher_reference = varReference
                   and bcac_reference_serial = numSerial
                   and bcac_account_head = numHead;
     end if;

    End Loop;
  End If;


    return numError;
Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('Current A/c', numError, varMessage,
                      varOperation, varError);
      raise_application_error(-20101, varError);
      return numError;

End fncCurrentAccount;



Function fncMiscellaneousUpdates
    (   RecordDetail in GConst.gClobType%Type,
        EditType in number,
        ErrorNumber in out nocopy number)
    return clob
    is
--created on 20/09/07
    numError            number;
    numTemp             number;
    numTemp1            number;
    numStatus           number;
    numSub              number(3);
    numSub1             number(3);
    numSerial           number(5);
    numSerial1          number(5);
    numAction           number(4);
    numCompany          number(8);
    numLocation         number(8);
    numCode             number(8);
    numCode1            number(8);
    numCode2            number(8);
    numCode3            number(8);
    numCode4            number(8);

    
    numCross            number(15,2);
    numFCY              number(15,2);
    numFCY1             number(15,2);
    numFCY2             number(15,2);
    numFCY3             number(15,2);
    numFcy4             number(15,2);
    numFcy5             number(15,2);
    numFcy6             number(15,2);
    numINR              number(15,2);
    numRate             number(15,6);
    numRate1            number(15,6);
    numRate2            number(15,6);
    numRate3            number(15,6);
    numRateSr           number(15);
    numRenewalDepositAmt number(15,2);
    numRenewalInterestRate  number(6,2);
    numRenewalMaturityAmount number(15,2);
    datRenewalMaturityDate  date;
    numRenewalPeriodicalInterest number(15,2);
    numrenewalintamt  NUMBER(15,2);
    numpnlamt         NUMBER(15,2);
    numpramt          number(15,2);    
    numsrno           number(3);
    varReference        varchar2(30);
    varReference1       varchar2(30);
    varUserID           varchar2(30);
    varEntity           varchar2(30);
    varRelease          varchar2(50);
    varTemp             varchar2(512);
    varTemp1            varchar2(512);
    varXPath            varchar2(512);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    datWorkDate         date;
    datTemp             date;
    datTemp1            date;
    datTemp2            date;
    datTemp3            date;
    clbTemp             clob;
    clbError            clob;
    clbProcess          clob;
    xmlTemp             xmlType;
    nodTemp             xmlDom.domNode;
    nodTemp1            xmlDom.domNode;
    nmpTemp             xmldom.domNamedNodemap;
    nmpTemp1            xmldom.domNamedNodemap;
    nlsTemp             xmlDom.DomNodeList;
    nlsTemp1            xmlDom.DomNodeList;
    xlParse             xmlparser.parser;
    nodFinal            xmlDom.domNode;
    docFinal            xmlDom.domDocument;
    mail_body           varchar2(4000);
    varsubject          varchar2(1000);
    fromuser            varchar2(100);
    error_occured       Exception;
    
    numcode5         number(8);
    numcode6         number(8);
    numcode7         number(8);
    numcode8         number(8);
    numcode9         number(8);
    numcode10        number(8);
    numcode11        number(8);
    numcode12        number(8);
    numcode13        number(15,2);
    numcode14        number(15,2);
    numCode15        number(8);
    varTemp2            varchar2(512);
    numPeriodType    number(8);
    numPercentType   number(8);
    numMinAmount     number(15,2);
    numMaxAmount     number(15,2);
    numCharges       number(15,3);
    numAmountUpto    number(15,2);
    numAmountFrom    number(15,2); 
    numPeriodUpto    number(15);
    numCurrency    number(8);
    varSanctionApplied  VARCHAR2(30 BYTE);
    numChargeEvent  number(8);
    
    Begin
    varMessage := 'Miscellaneous Updates for ' || EditType;
    dbms_lob.createTemporary (clbTemp,  TRUE);
    clbTemp := RecordDetail;

    numError := 1;
    varOperation := 'Extracting Input Parameters';
    xmlTemp := xmlType(RecordDetail);

    varUserID := GConst.fncXMLExtract(xmlTemp, 'UserCode', varUserID);
    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
    numCompany := GConst.fncXMLExtract(xmlTemp, 'CompanyId', numCompany);
    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationId', numLocation);

    numError := 2;
    varOperation := 'Creating Document for Master';
    docFinal := xmlDom.newDomDocument(xmlTemp);
    nodFinal := xmlDom.makeNode(docFinal);

   -- insert into temp values(varoperation || '-1' ,varoperation);

--
--    if EditType = GConst.SYSCASHDEAL then
--      varOperation := 'Extracting Parameters for Foreign Remittance';
--      varReference := GConst.fncXMLExtract(xmlTemp, 'REMT_REMITTANCE_REFERENCE', varReference);
--      numCode := GConst.fncXMLExtract(xmlTemp, 'REMT_COMPANY_CODE', varReference);
--      varTemp :=  'BCCL/FRW/H/';
--      varTemp := varTemp  || pkgGlobalMethods.fncGenerateSerial(GConst.SERIALDEAL, numCode);
--
--
--      if numAction = GConst.ADDSAVE then
--          varOperation := 'Inserting Cash Deal';
--          insert into trtran001
--            (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
--            deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
--            deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
--            deal_confirm_date,deal_holding_rate,deal_holding_rate1,deal_dealer_holding,deal_dealer_holding1,deal_dealer_remarks,deal_time_stamp,
--            deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
--            deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,cdel_forward_rate,
--            cdel_spot_rate,cdel_margin_rate,deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
--            deal_bo_remark,deal_analysis_option,deal_analysis_type,deal_analysis_frequency,deal_analysis_selection)
--          select remt_company_code, varTemp, 1, datWorkDate, 26000001, decode(remt_remittance_type, 33900001, 25300002,25300001),25200002,
--            25400001, remt_local_bank, remt_currency_code, 30400003, remt_exchange_rate, 1, remt_remittance_fcy,
--            remt_remittance_inr, 0,0,datWorkDate,datWorkDate,null, 'System',
--            NULL, 0,0,0,0,varReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
--            to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,remt_create_date,remt_entry_detail, 10200001,
--            remt_remittance_details,null,null,0,remt_exchange_rate,0, 0,
--            0,0,remt_remittance_purpose + 9100000,0,0,0,remt_bank_reference,
--            decode(remt_remittance_type,33900001,'Inward Remittance','Outward Remittance'),null,null,null,null
--            from trtran008A
--            where remt_remittance_reference = varReference;
--
--          varOperation := 'Inserting Cash Deal Cancellation';
--          insert into trtran006
--            (cdel_company_code,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
--            cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
--            cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
--            cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
--            cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
--            cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark)
--          select remt_company_code, varTemp, 1, 1, varReference, 1,
--            datWorkDate, 26000001,27000002,remt_remittance_fcy, remt_exchange_rate, remt_remittance_inr, 0,
--            0,0,0,0,0,0,'System',varReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), remt_create_date,
--            remt_entry_detail, 10200001, null,null,1,0,remt_exchange_rate,0,0,0,33500001,null,null,remt_bank_reference,
--            decode(remt_remittance_type,33900001,'Inward Remittance','Outward Remittance')
--            from trtran008A
--            where remt_remittance_reference = varReference;
--
--          varOperation := 'Inserting Underlying Entry';
--          insert into trtran002
--            (trad_company_code,trad_trade_reference,trad_reverse_reference,trad_reverse_serial,trad_import_export,
--            trad_local_bank,trad_entry_date,trad_user_reference,trad_reference_date,trad_buyer_seller,trad_trade_currency,
--            trad_product_code,trad_product_description,trad_trade_fcy,trad_trade_rate,trad_trade_inr,trad_period_code,
--            trad_trade_period,trad_tenor_code,trad_tenor_period,trad_maturity_from,trad_maturity_date,trad_maturity_month,
--            trad_process_complete,trad_complete_date,trad_trade_remarks,trad_create_date,trad_entry_detail,
--            trad_record_status,trad_vessel_name,trad_port_name,trad_beneficiary,trad_usance,trad_bill_date,
--            trad_contract_no,trad_app,trad_transaction_type,trad_product_quantity,trad_product_rate,trad_term,
--            trad_voyage,trad_link_batchno,trad_link_date,trad_lc_beneficiary,trad_forward_rate,trad_margin_rate,
--            trad_final_rate,trad_spot_rate)
--          select remt_company_code, remt_remittance_reference,remt_remittance_reference, 1,
--            decode(remt_remittance_type, 33900001, 25300002,25300001),
--            remt_local_bank, datWorkDate, remt_remittance_reference,datWorkDate, remt_beneficiary_code, remt_currency_code,
--            remt_remittance_purpose, remt_remittance_details, remt_remittance_fcy, remt_exchange_rate,
--            remt_remittance_inr, 25500001,0,25500001,0,datWorkDate, datWorkDate,datWorkDate,
--            12400001, datWorkDate, decode(remt_remittance_type,33900001,'Inward Remittance','Outward Remittance'),
--            remt_create_date, remt_entry_detail, 10200001, null, null, null, null, null,
--            null,null,null,null,null,null,null,null,null,null,0,0,remt_exchange_rate,remt_exchange_rate
--            from trtran008A
--            where remt_remittance_reference = varReference;
--
--          varOperation := 'Inserting underlying reversal entry';
--          insert into trtran003
--            (brel_company_code,brel_trade_reference,brel_reverse_serial,brel_entry_date,brel_user_reference,
--            brel_reference_date,brel_reversal_type,brel_reversal_fcy,brel_reversal_rate,brel_reversal_inr,
--            brel_period_code,brel_trade_period,brel_maturity_from,brel_maturity_date,brel_create_date,
--            brel_entry_detail,brel_record_status,brel_local_bank,brel_reverse_reference)
--          select remt_company_code, remt_remittance_reference, 1, datWorkdate, remt_bank_reference,
--            datWorkDate, decode(remt_remittance_type, 33900001,25800011,25800056),
--            remt_remittance_fcy, remt_exchange_rate, remt_remittance_inr,
--            25500001,0,datWorkDate, datWorkDate, remt_create_date,
--            remt_entry_detail, 10200001, remt_local_bank, remt_remittance_reference
--            from trtran008A
--            where remt_remittance_reference = varReference;
--
--      End if;
--
--    End if;
--manjunath sir modified on 12052014
----Added by Ishwarachandra ---For new rate upload
 if EditType = GConst.SYSRATEUPLOAD then
  varOperation := 'Updating Rate Serial Number ';
  datTemp1 := GConst.fncXMLExtract(xmlTemp, 'DRAT_EFFECTIVE_DATE', datTemp1);
  VarReference := GConst.fncXMLExtract(xmlTemp, 'DRAT_RATE_TIME', VarReference);
  update trtran013 set drat_ratesr_number =  to_char(drat_effective_date,'ddmmyyyy')||lpad(DRAT_SERIAL_NUMBER,3,0)
                                            where drat_ratesr_number is null
                                            and DRAT_EFFECTIVE_DATE = datTemp1;
  varOperation := 'Selecting Rate Serial Number ';        
--  SELECT MAX(DRAT_SERIAL_NUMBER),
--    DRAT_RATESR_NUMBER INTO numCode4,numRateSr
--  FROM trtran013
--  WHERE DRAT_EFFECTIVE_DATE = datTemp1
--  GROUP BY DRAT_RATESR_NUMBER; 
  SELECT 
    DRAT_RATESR_NUMBER INTO numRateSr
  FROM trtran013
  WHERE DRAT_EFFECTIVE_DATE = datTemp1
  and DRAT_RATE_TIME = VarReference
  and DRAT_SERIAL_NUMBER = (select MAX(DRAT_SERIAL_NUMBER) from trtran013a b
                              where DRAT_EFFECTIVE_DATE = datTemp1
                              and DRAT_RATE_TIME = VarReference);
  varOperation := 'Inserting Rate into trtran013a ';
  varXPath     := '//RATEUPLOADNEW/ROW';
  nlsTemp      := xslProcessor.selectNodes(nodFinal, varXPath);
  varOperation := 'Update Reverse Reference ' || varXPath;
  FOR numTemp IN 1..xmlDom.getLength(nlsTemp)
  LOOP
    varTemp      := varXPath || '[@NUM="' || numTemp || '"]/BidRate';
    varoperation :='Extracting Data from XML' || varTemp;
    numRate      := GConst.fncXMLExtract(xmlTemp, varTemp, numRate, Gconst.TYPENODEPATH);
    varTemp      := varXPath || '[@NUM="' || numTemp || '"]/AskRate';
    varoperation :='Extracting Data from XML' || varTemp;
    numRate1     := GConst.fncXMLExtract(xmlTemp, varTemp, numRate1, Gconst.TYPENODEPATH);
    varTemp      := varXPath || '[@NUM="' || numTemp || '"]/CurrencyCode';
    varoperation :='Extracting Data from XML' || varTemp;
    numCode      := GConst.fncXMLExtract(xmlTemp, varTemp, numCode, Gconst.TYPENODEPATH);
    varTemp      := varXPath || '[@NUM="' || numTemp || '"]/ForCurrency';
    varoperation :='Extracting Data from XML' || varTemp;
    numCode1     := GConst.fncXMLExtract(xmlTemp, varTemp, numCode1, Gconst.TYPENODEPATH);
    varTemp      := varXPath || '[@NUM="' || numTemp || '"]/ContractMonth';
    varoperation :='Extracting Data from XML' || varTemp;
    datTemp      := GConst.fncXMLExtract(xmlTemp, varTemp, datTemp, Gconst.TYPENODEPATH);
    varTemp      := varXPath || '[@NUM="' || numTemp || '"]/ForwardMonth';
    varoperation :='Extracting Data from XML' || varTemp;
    numCode2     := GConst.fncXMLExtract(xmlTemp, varTemp, numCode2, Gconst.TYPENODEPATH);
    if numCode2 = 0 then
      INSERT
      INTO TRTRAN013A (DRAD_CURRENCY_CODE, DRAD_FOR_CURRENCY, 
                       DRAD_RATESR_NUMBER, DRAD_BID_RATE, DRAD_ASK_RATE, 
                       DRAD_CONTRACT_MONTH, DRAD_FORWARD_MONTHNO)
      SELECT numCode,numCode1,numRateSr,numRate,numRate1,datTemp,numCode2 from dual;
    else
      select DRAD_BID_RATE, DRAD_ASK_RATE INTO numRate2,numRate3 from trtran013a where DRAD_CURRENCY_CODE = numCode 
                                          and DRAD_FOR_CURRENCY = numCode1
                                          and DRAD_RATESR_NUMBER = numRateSr 
                                          and DRAD_FORWARD_MONTHNO = 0;
      INSERT INTO TRTRAN013A (DRAD_CURRENCY_CODE, DRAD_FOR_CURRENCY, 
                       DRAD_RATESR_NUMBER, DRAD_BID_RATE, DRAD_ASK_RATE, 
                       DRAD_CONTRACT_MONTH, DRAD_FORWARD_MONTHNO)
      SELECT numCode,numCode1,numRateSr,numRate2 + (numRate/100),numRate3 + (numRate1/100),datTemp,numCode2 from dual;
    end if;
  END LOOP;
  BEGIN----For USD - USD Rate for 12 month
  SELECT nvl(COUNT(*),0) INTO numSerial FROM TRTRAN013A WHERE DRAD_CURRENCY_CODE = 30400004 
                                                 AND DRAD_FOR_CURRENCY = 30400004
                                                 AND DRAD_RATESR_NUMBER = numRateSr;
  IF numSerial = 0 THEN
    INSERT
    INTO TRTRAN013A
      ( DRAD_CURRENCY_CODE,DRAD_FOR_CURRENCY,DRAD_RATESR_NUMBER,DRAD_BID_RATE,
        DRAD_ASK_RATE,DRAD_CONTRACT_MONTH,DRAD_FORWARD_MONTHNO)
    SELECT 30400004,30400004,numRateSr,1,1,datTemp,rownum + (-1)
    FROM TRTRAN013A WHERE DRAD_RATESR_NUMBER = numRateSr
    AND ROWNUM <=13;
  END IF;
  EXCEPTION
    WHEN OTHERS THEN
      INSERT
      INTO TRTRAN013A
        (DRAD_CURRENCY_CODE,DRAD_FOR_CURRENCY,DRAD_RATESR_NUMBER,DRAD_BID_RATE,
         DRAD_ASK_RATE,DRAD_CONTRACT_MONTH,DRAD_FORWARD_MONTHNO)
      SELECT 30400004,30400004,numRateSr,1,1,datTemp,rownum + (-1)
      FROM TRTRAN013A
      WHERE DRAD_RATESR_NUMBER = numRateSr AND ROWNUM <=13;
  END;  
 END IF;
 if EditType = GConst.SYSCASHDEAL then
      varOperation := 'Extracting Parameters for Foreign Remittance';
      numCode := GConst.fncXMLExtract(xmlTemp, 'REMT_COMPANY_CODE', varReference);
      varReference := GConst.fncXMLExtract(xmlTemp, 'REMT_REMITTANCE_REFERENCE', varReference);

      Begin
        varReference1 := NVL(GConst.fncXMLExtract(xmlTemp, 'REMT_REFERENCE_NUMBER', varReference1),'0');
      Exception
        when others then
          varReference1 := '0';
      End;

     -- varTemp :=  'BCCL/FRW/H/';
      varTemp :=  'FWDC'   || pkgGlobalMethods.fncGenerateSerial(GConst.SERIALDEAL, numCode);


      if numAction = GConst.ADDSAVE then
          varOperation := 'Inserting Cash Deal';
           insert into trtran001
            (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
            deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
            deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
            deal_confirm_date,deal_dealer_remarks,deal_time_stamp,
            deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
            deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,
            deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
            deal_bo_remark)
          select remt_company_code, varTemp, 1, datWorkDate, 26000001, decode(remt_remittance_type, 33900001, 25300002,25300001),25200002,
            25400001, remt_local_bank, remt_currency_code, 30400003, remt_exchange_rate, 1, remt_remittance_fcy,
            remt_remittance_inr, 0,0,remt_maturity_date,remt_maturity_date,null, 'System',
            NULL, varReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
            to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,remt_create_date,remt_entry_detail, 10200001,
            remt_remittance_details,null,null,remt_forward_rate,remt_spot_rate,remt_margin_rate,
            remt_product_category,0,0,remt_product_subcategory,remt_bank_reference,
            decode(remt_remittance_type,33900001,'Inward Remittance','Outward Remittance')
            from trtran008A
            where remt_remittance_reference = varReference;


          varOperation := 'Inserting Cash Deal Cancellation';
           insert into trtran006
            (cdel_company_code,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,cdel_trade_reference,cdel_trade_serial,
            cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,cdel_cancel_rate,cdel_other_amount,cdel_local_rate,
            cdel_cancel_inr,cdel_holding_rate,cdel_holding_rate1,cdel_dealer_holding,cdel_dealer_holding1,cdel_profit_loss,
            cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_entry_detail,cdel_record_status,cdel_pl_voucher,
            cdel_delivery_from,cdel_delivery_serial,cdel_forward_rate,cdel_spot_rate,cdel_margin_rate,cdel_pandl_spot,
            cdel_pandl_usd,cdel_cancel_reason,cdel_confirm_time,cdel_confirm_date,cdel_bank_reference,cdel_bo_remark)
          select remt_company_code, varTemp, 1, 1, varReference, 1,
            datWorkDate, 26000001,27000002,remt_remittance_fcy, remt_exchange_rate, remt_remittance_inr, 0,
            0,0,0,0,0,0,'System',varReference,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'), remt_create_date,
            remt_entry_detail, 10200001, null,null,1,0,remt_forward_rate,remt_spot_rate,remt_margin_rate,0,33500001,
            null,null,remt_bank_reference,decode(remt_remittance_type,33900001,'Inward Remittance','Outward Remittance')
            from trtran008A
            where remt_remittance_reference = varReference;


          varOperation := 'Inserting Underlying Entry';
          insert into trtran002
            (trad_company_code,trad_trade_reference,trad_reverse_reference,trad_reverse_serial,trad_import_export,
            trad_local_bank,trad_entry_date,trad_user_reference,trad_reference_date,trad_buyer_seller,trad_trade_currency,
            trad_product_code,trad_product_description,trad_trade_fcy,trad_trade_rate,trad_trade_inr,trad_period_code,
            trad_trade_period,trad_tenor_code,trad_tenor_period,trad_maturity_from,trad_maturity_date,
            trad_process_complete,trad_complete_date,trad_trade_remarks,trad_create_date,trad_entry_detail,
            trad_record_status,trad_vessel_name,trad_port_name,trad_beneficiary,trad_usance,trad_bill_date,
            trad_contract_no,trad_app,trad_transaction_type,trad_product_quantity,trad_product_rate,trad_term,
            trad_voyage,trad_link_batchno,trad_link_date,trad_lc_beneficiary,trad_forward_rate,trad_margin_rate,
            trad_spot_rate,trad_product_category,trad_subproduct_code)
          select remt_company_code, remt_remittance_reference,remt_remittance_reference, 1,
            decode(remt_remittance_type, 33900001, 25900025,25900087),
            remt_local_bank, datWorkDate, remt_remittance_reference,datWorkDate, remt_beneficiary_code, remt_currency_code,
            remt_remittance_purpose, remt_remittance_details, remt_remittance_fcy, remt_exchange_rate,
            remt_remittance_inr, 25500001,0,25500001,0,datWorkDate, datWorkDate,
            12400001, datWorkDate, decode(remt_remittance_type,33900001,'Inward Remittance','Outward Remittance'),
            remt_create_date, remt_entry_detail, 10200001, null, null, null, null, null,
            null,null,null,null,null,null,null,null,null,null,remt_forward_rate,remt_margin_rate,remt_spot_rate,
            remt_product_category, remt_product_subcategory
            from trtran008A
            where remt_remittance_reference = varReference;

          varOperation := 'Inserting underlying reversal entry';
          insert into trtran003
            (brel_company_code,brel_trade_reference,brel_reverse_serial,brel_entry_date,brel_user_reference,
            brel_reference_date,brel_reversal_type,brel_reversal_fcy,brel_reversal_rate,brel_reversal_inr,
            brel_period_code,brel_trade_period,brel_maturity_from,brel_maturity_date,brel_create_date,
            brel_entry_detail,brel_record_status,brel_local_bank,brel_reverse_reference)
          select remt_company_code, remt_remittance_reference, 1, datWorkdate, remt_bank_reference,
            datWorkDate, decode(remt_remittance_type, 33900001,25800011,25800056),
            remt_remittance_fcy, remt_exchange_rate, remt_remittance_inr,
            25500001,0,datWorkDate, datWorkDate, remt_create_date,
            remt_entry_detail, 10200001, remt_local_bank, remt_remittance_reference
            from trtran008A
            where remt_remittance_reference = varReference;

          varOperation := 'Inserting Hedge record';
          insert into trtran004
            (hedg_company_code,hedg_trade_reference,hedg_deal_number,
            hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
            hedg_create_date,hedg_entry_detail,hedg_record_status,
            hedg_hedging_with,hedg_multiple_currency)
          select remt_company_code, remt_remittance_reference, varTemp,
            1, remt_remittance_fcy,0,remt_remittance_inr,
            sysdate,NULL,10200001, 32200001,12400002
            from trtran008A
            where remt_remittance_reference = varReference;
-- Removed because of does not required for Olam
--        if varReference1 != '0' then
--           varOperation := 'Inserting Trade reversal entry';
--          insert into trtran003
--            (brel_company_code,brel_trade_reference,brel_reverse_serial,brel_entry_date,brel_user_reference,
--            brel_reference_date,brel_reversal_type,brel_reversal_fcy,brel_reversal_rate,brel_reversal_inr,
--            brel_period_code,brel_trade_period,brel_maturity_from,brel_maturity_date,brel_create_date,
--            brel_entry_detail,brel_record_status,brel_local_bank,brel_reverse_reference)
--          select remt_company_code, varReference1, 1, datWorkdate, remt_bank_reference,
--            datWorkDate, decode(remt_remittance_type, 33900001,25800011,25800056),
--            remt_remittance_fcy, remt_exchange_rate, remt_remittance_inr,
--            25500001,0,datWorkDate, datWorkDate, remt_create_date,
--            remt_entry_detail, 10200001, remt_local_bank, remt_remittance_reference
--            from trtran008A
--            where remt_remittance_reference = varReference;
--
--             numError := fncCompleteUtilization(varReference1,GConst.UTILEXPORTS,datWorkDate);
--        End if;

      elsif numAction = GConst.DELETESAVE then
        varOperation := 'Deleting the Cash Deal Entry';
        update trtran001
          set deal_record_status = Gconst.STATUSDELETED
          where deal_dealer_remarks = varReference;

        varOperation := 'Deleting the Trade Deal Entry';
        update trtran002
          set trad_record_status = Gconst.STATUSDELETED
          where trad_trade_reference = varReference;

        varOperation := 'Deleting the Deal Realization Entry';
        update trtran003
          set brel_record_status = Gconst.STATUSDELETED
          where brel_trade_reference = varReference;

        varOperation := 'Deleting the Hedge Entry';
        update trtran004
          set hedg_record_status = Gconst.STATUSDELETED
          where hedg_trade_reference = varReference;

        if varReference1 != '0' then
            varOperation := 'Deleting Trade reversal entry';
            update trtran003
              set brel_record_status = Gconst.STATUSDELETED
              where brel_trade_reference = varReference1;

              numError := fncCompleteUtilization(varReference1,GConst.UTILEXPORTS,datWorkDate);
        End if;

      End if;

    End if;
    
     if EditType = GConst.UTILBONDCLOSE then
            varOperation := 'Extracting the process complete status' ;
            varReference := GConst.fncXMLExtract(xmlTemp, 'BRED_DEAL_NUMBER', varReference);
            numCompany := GConst.fncXMLExtract(xmlTemp, 'BRED_COMPANY_CODE', numCompany);
            numLocation := GConst.fncXMLExtract(xmlTemp, 'BRED_LOCATION_CODE', numLocation);
            datTemp := GConst.fncXMLExtract(xmlTemp, 'BRED_DEAL_DATE', datTemp);
            numfcy := GConst.fncXMLExtract(xmlTemp, 'BRED_INTEREST_CHARGED', numfcy);
            
            if numAction = GConst.DELETESAVE then
                 update trtran032 set BPUR_PROCESS_COMPLETE = 12400002,BPUR_COMPLETE_DATE ='' 
                  where BPUR_DEAL_NUMBER = varReference
                  and   BPUR_RECORD_STATUS NOT IN (10200005,10200006);
                
                 update trtran034 set BINT_RECORD_STATUS=10200006
                    where BINT_DEAL_NUMBER=varReference
                      and BINT_CHARGE_TYPE=44600003
                      and BINT_CHARGE_DATE=datTemp;
                
            end if;
            if numAction = GConst.CONFIRMSAVE then
                  update trtran034 set BINT_RECORD_STATUS=10200003
                    where BINT_DEAL_NUMBER=varReference
                      and BINT_CHARGE_TYPE=44600003
                      and BINT_CHARGE_DATE=datTemp;
            end if;
            if (numAction = GConst.ADDSAVE) OR (numAction = GConst.EDITSAVE) then
                update trtran032 set BPUR_PROCESS_COMPLETE = 12400001,BPUR_COMPLETE_DATE =datTemp 
                  where BPUR_DEAL_NUMBER = varReference
                  and BPUR_UNIT_QUANTITY<=(select sum(BRED_UNIT_QUANTITY) from trtran033 
                                            where BRED_DEAL_NUMBER=varReference
                                            and BRED_RECORD_STATUS NOT IN (10200005,10200006))
                  and   BPUR_RECORD_STATUS NOT IN (10200005,10200006);
                if numfcy<>0 then
                   select nvl( max(BINT_SERIAL_NUMBER),0)+1 into numcode
                     from trtran034 
                     where BINT_DEAL_NUMBER=varReference;
                       
                   
                   insert into trtran034(BINT_COMPANY_CODE,BINT_LOCATION_CODE, BINT_DEAL_NUMBER,
                                        BINT_SERIAL_NUMBER, BINT_CHARGE_DATE, BINT_CHARGE_TYPE,
                                        BINT_CHARGE_AMOUNT, BINT_INTEREST_UPTO, BINT_CREATE_DATE,
                                        BINT_ENTRY_DETAIL, BINT_RECORD_STATUS)
                              values(numCompany,numlocation,varReference,numcode,datTemp,44600003,
                                     numfcy,dattemp,sysdate,null,10200001);
                end if;
                  
            END IF;
     end if;
     if EditType = GConst.SYSPRODUCTMATURITY then
           varOperation := 'Extracting Fileds For Maturity Dates' ;
           numCode := GConst.fncXMLExtract(xmlTemp, 'CPRO_PRODUCT_CODE', numCode);
           datTemp := GConst.fncXMLExtract(xmlTemp, 'CPRO_EFFECTIVE_DATE', datTemp);
           
            if numAction = GConst.DELETESAVE then
              update TRMASTER503A set CPRM_RECORD_STATUS = 10200006 where CPRM_EFFECTIVE_DATE = datTemp
              and CPRM_PRODUCT_CODE = numCode;
            end if;
         if (numAction = GConst.ADDSAVE) OR (numAction = GConst.EDITSAVE) then
            if numAction = GConst.EDITSAVE then
              begin
                varXPath := '//MATURITYDATEPOPULATE/ROW';
                varTemp := varXPath || '[@NUM="' || 1 || '"]/FCMaturityDate';
                datTemp1 := GConst.fncXMLExtract(xmlTemp, varTemp, datTemp1, Gconst.TYPENODEPATH);
                delete from TRMASTER503A where CPRM_EFFECTIVE_DATE = datTemp and CPRM_PRODUCT_CODE = numCode;
              exception
               when others then
               datTemp1 := '';
              end;
            end if; 
          varXPath := '//MATURITYDATEPOPULATE/ROW';
          nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
          varOperation := 'Update Reverse Reference ' || varXPath;
          for numTemp in 1..xmlDom.getLength(nlsTemp)
          Loop
              varTemp := varXPath || '[@NUM="' || numTemp || '"]/FCMaturityDate';
              varoperation :='Extracting Data from XML' || varTemp;
              datTemp2 := GConst.fncXMLExtract(xmlTemp, varTemp, datTemp2, Gconst.TYPENODEPATH);
            insert into TRMASTER503A(CPRM_PRODUCT_CODE,  CPRM_MATURITY_DATE ,CPRM_EFFECTIVE_DATE,CPRM_RECORD_STATUS)
               values           (numCode,datTemp2,datTemp,10200001);
          end loop;            
         end if;   
     end if;
     
     if EditType = GConst.SYSEXPOSURESETTLEMENT then
        numError := fncExposuresettlement(RecordDetail);
     end if;
     
     
      if EditType = GConst.UTILFDPRECLOSE then
            varOperation := 'Extracting Fileds For PRECLOSURE DETAILS' ;
            varReference := GConst.fncXMLExtract(xmlTemp, 'FDRF_FD_NUMBER', varReference);
            numCompany := GConst.fncXMLExtract(xmlTemp, 'FDRF_COMPANY_CODE', numCompany);
            numLocation := GConst.fncXMLExtract(xmlTemp, 'FDRF_LOCATION_CODE', numLocation);
            numCode := GConst.fncXMLExtract(xmlTemp, 'FDRF_LOCAL_BANK', numCode);
            numCode1 := GConst.fncXMLExtract(xmlTemp, 'FDRF_CURRENCY_CODE', numCode1);
            datTemp := GConst.fncXMLExtract(xmlTemp, 'FDRF_REFERENCE_DATE', datTemp);
            if numAction = GConst.DELETESAVE then
              update TRMASTER409 set PREC_RECORD_STATUS = 10200006 where PREC_fd_number = varReference;
            end if;
         if (numAction = GConst.ADDSAVE) OR (numAction = GConst.EDITSAVE) then
            if numAction = GConst.EDITSAVE then
              begin
                varXPath := '//PRECLOSURE/ROW';
                varTemp := varXPath || '[@NUM="' || 1 || '"]/PeriodUpto';
                numCross := GConst.fncXMLExtract(xmlTemp, varTemp, numCross, Gconst.TYPENODEPATH);
                delete from TRMASTER409 where PREC_fd_number = varReference;
              exception
               when others then
               numCross := 0;
              end;
            end if;

          varXPath := '//PRECLOSURE/ROW';
          nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
          varOperation := 'Update Reverse Reference ' || varXPath;
          for numTemp in 1..xmlDom.getLength(nlsTemp)
          Loop
              varTemp := varXPath || '[@NUM="' || numTemp || '"]/PeriodUpto';
              varoperation :='Extracting Data from XML' || varTemp;
              numCross := GConst.fncXMLExtract(xmlTemp, varTemp, numCross, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/PeriodIn';
              varoperation :='Extracting Data from XML' || varTemp;
              numCode3 := GConst.fncXMLExtract(xmlTemp, varTemp, numCode3, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/IntRate';
              varoperation :='Extracting Data from XML' || varTemp;
              numRate := GConst.fncXMLExtract(xmlTemp, varTemp, numRate, Gconst.TYPENODEPATH);

--            numCode2 := GConst.fncXMLExtract(xmlTemp, 'PRECLOSURE/ROW[@NUM="1"]/PeriodUpto', numCode2);
--            numCode3 := GConst.fncXMLExtract(xmlTemp, 'PRECLOSURE/ROW[@NUM="1"]/PeriodIn', numCode3);
--            numRate := GConst.fncXMLExtract(xmlTemp, 'PRECLOSURE/ROW[@NUM="1"]/IntRate', numRate);



            if numCode3 = 41600001 then
              datTemp1 := datTemp + numCross;
            elsif numCode3 = 41600002 then
              datTemp1 := Add_months(datTemp,numCross);
            else
              --numCode2 := numCode2 * 12;
              datTemp1 := Add_months(datTemp,(numCross * 12));
            end if;
            insert into TRMASTER409(PREC_COMPANY_CODE,  PREC_LOCATION_CODE ,PREC_COUNTER_PARTY,
                                    PREC_CURRENCY_CODE ,  prec_Value_date ,  PREC_PERIOD_UPTO ,
                                    PREC_PERIOD_IN ,  PREC_INT_RATE , PREC_MAT_DATE,PREC_CREATE_DATE,PREC_ADD_DATE,
                                    PREC_RECORD_STATUS,PREC_fd_number,prec_fd_srno)
                                    values
                                    (numCompany,numLocation,numCode,numCode1,datTemp,numCross,
                                    numCode3,numRate,datTemp1,sysdate,sysdate,10200001,varReference,numTemp);



           end loop;
        end if;
--        if (numAction = GConst.ADDSAVE) OR (numAction = GConst.EDITSAVE) then
--            VAROPERATION:='Sending Auto Generated mail for FD Opening';
--
--           numFcy6 := GConst.fncXMLExtract(xmlTemp, 'FDRF_DEPOSIT_AMOUNT', numFcy6);
--           if (numAction = GConst.ADDSAVE) then
--               varsubject:='Confirmation Pending: ' ||varReference||  ' Opened as on '|| datTemp;
--               mail_body:= 'Following FD has been opened by ';
--           else
--               varsubject:='Confirmation Pending: ' ||varReference||  ' Modified as on '|| datTemp;
--               mail_body:= 'Following FD has been modified by ';
--
--           end if;
--           mail_body:= mail_body || varuserid||chr(13)||chr(10) ;
--           mail_body:=mail_body ||chr(13)||chr(10)|| 'System FD Reference Number :' ||varReference||chr(13)||chr(10);
--           mail_body:=mail_body ||chr(13)||chr(10)|| 'Bank Name:'||pkgreturncursor.fncgetdescription(numCode,1)||chr(13)||chr(10) ;
--           mail_body:=mail_body ||chr(13)||chr(10)|| 'Principal Amount:'||numFcy6||chr(13)||chr(10) ;
--           mail_body:=mail_body ||chr(13)||chr(10)|| 'Value Date:'||datTemp||chr(13)||chr(10) ;
--           mail_body:=mail_body ||chr(13)||chr(10)|| 'Please Confirm the Record for further processing.';
--            select nvl(PRMC_EMAIL_ID,'') into fromuser from trsystem051;
--          numerror:=pkgfixeddepositproject.fncsendmail(fromuser,'','','',varsubject,mail_body);
--      end if;
    End if;
--manjunath sir ends
----For FD Closure------

    If Edittype = Gconst.Sysuserupdate Then
        VARREFERENCE := GCONST.FNCXMLEXTRACT(xmlTemp, 'PSWD_USER_ID', VARREFERENCE);
        Varxpath := '//USERUPDATE/ROW';
        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
        Loop
          Vartemp := Varxpath || '[@NUM="' || numTemp || '"]/UserComapnyCode';
          Numcompany := Gconst.Fncxmlextract(Xmltemp, Vartemp, Numcompany, Gconst.Typenodepath);
          DELETE FROM TRSYSTEM022A WHERE USCO_USER_ID=VARREFERENCE AND USCO_COMPANY_CODE=numCompany AND USCO_REPORT_DISPLAYCOM=numCompany;
          INSERT INTO TRSYSTEM022A
            (USCO_COMPANY_CODE,
            USCO_USER_ID,
            USCO_REPORT_DISPLAYCOM)
            values(numCompany,VARREFERENCE,numCompany);
        End Loop;
    END IF;
    If Edittype=Gconst.SYSCOMPANYUPDATE then
         varOperation := 'Duplicating the entry in Transaction table';
         varTemp := GConst.fncXMLExtract(xmlTemp, 'COMP_COMPANY_CODE', varTemp);
   
         if numAction =GConst.ADDSAVE then
            update trmaster001 set pick_company_code=30199999 where pick_key_value=varTemp;
            
            insert into trsystem022A (USCO_COMPANY_CODE,USCO_USER_ID,USCO_REPORT_DISPLAYCOM)
               select varTemp,USER_USER_ID,varTemp 
                from trsystem022 
                where USER_RECORD_STATUS not in (10200005,10200006); 
          end if;
    end if;
    If Edittype=Gconst.UTILUSERUPDATE then
         varOperation := 'Duplicating the entry in Transaction table';
         varTemp := GConst.fncXMLExtract(xmlTemp, 'USER_USER_ID', varTemp);
   
         if numAction =GConst.ADDSAVE then
            DELETE FROM  trsystem022A WHERE  USCO_USER_ID= varTemp;
            
            insert into trsystem022A (USCO_COMPANY_CODE,USCO_USER_ID,USCO_REPORT_DISPLAYCOM)
               select DECODE(COMP_COMPANY_CODE,30100000,30199999,COMP_COMPANY_CODE),varTemp,
                      DECODE(COMP_COMPANY_CODE,30100000,30199999,COMP_COMPANY_CODE) 
                from TRMASTER301 
                where COMP_RECORD_STATUS not in (10200005,10200006); 
                
           varOperation := 'Get the Maximium Password Serial Number';   
            begin
              select nvl(PSWD_SERIAL_NUMBER,1)
                into numCode
                from trsystem023
                where PSWD_RECORD_STATUS not in (10200005,10200006)
                and PSWD_USER_ID=varTemp;
            exception
              when others then
                numCode:=1;
            end;    
         varOperation := 'Insert PassCode';      
         
         Varxpath := '//USERPASSCODE/DROW';
         Vartemp := Varxpath || '[@DNUM="1"]/HashCode';
           insert into trsystem023(PSWD_COMPANY_CODE,PSWD_USER_ID,PSWD_SERIAL_NUMBER,
                  PSWD_PASSWORD_KEY,PSWD_PASSWORD_CODE,PSWD_PASSWORD_HINT,
                  PSWD_PASSWORD_STATUS,PSWD_CREATE_DATE,
                  PSWD_RECORD_STATUS)
            values( 30199999, varTemp, numCode,
                   Gconst.Fncxmlextract(Xmltemp, Vartemp, varTemp, Gconst.Typenodepath),
                   Gconst.Fncxmlextract(Xmltemp, Vartemp, varTemp, Gconst.Typenodepath),
                   null,14500001,sysdate,10200003);
            
          varOperation := 'Generating E-Mail ID for the new user';
          
          varTemp2 := '<TABLE BORDER=1 BGCOLOR="#EEEEEE">';
          varTemp2:=varTemp2||'<TR BGCOLOR="Gray">';
          varTemp2:=varTemp2||'<TH><FONT COLOR="WHITE">Header</FONT></TH>';
          varTemp2:=varTemp2||'<TH><FONT COLOR="WHITE">Values</FONT></TH>';
          varTemp2:=varTemp2||'</TR>';
          varTemp2:= varTemp2 || '<TR BGCOLOR="yellow"<td>User Name</td><td>' ||  GConst.fncXMLExtract(xmlTemp, 'USER_USER_NAME', varTemp) || '</td></tr>';
          varTemp2:= varTemp2 || '<TR BGCOLOR="yellow"<td>Password</td><td>' ||  
              Gconst.Fncxmlextract(Xmltemp, Vartemp, varTemp, Gconst.Typenodepath) || '</td></tr>';
          varTemp2:= varTemp2 || '</table>';
          
          varOperation := 'Sending Email';  
          
          pkgsendingmail.send_mail_secure(GConst.fncXMLExtract(xmlTemp, 'USER_EMAIL_ID', varTemp),'',
                           '',
                           'Password for First Time Login into TMS',
                           'Hi',
                           varTemp2);

          END IF;
    end if;
-------End FD Closure
    if EditType = GConst.SYSTERMLOAN then
      varOperation := 'Duplicating the entry in Transaction table';
      varTemp := GConst.fncXMLExtract(xmlTemp, 'TLON_LOAN_NUMBER', varTemp);
      datTemp := GConst.fncXMLExtract(xmlTemp, 'TLON_DISBURSAL_DATE',datTemp);
      varTemp1 := GConst.fncXMLExtract(xmlTemp, 'TLON_LOAN_NUMBER', varTemp);
      numCode1 := GConst.fncXMLExtract(xmlTemp, 'TLON_REPAYMENT_TYPE', varTemp);
      numCompany :=  GConst.fncXMLExtract(xmlTemp, 'TLON_COMPANY_CODE', varTemp);
      numCode2 :=  GConst.fncXMLExtract(xmlTemp, 'TLON_CURRENCY_CODE', varTemp);
      numCode3 :=  GConst.fncXMLExtract(xmlTemp, 'TLON_LOCAL_BANK', varTemp);

      if numAction in (GConst.ADDSAVE,GConst.EDITSAVE) then

        if numAction = GConst.EDITSAVE then
          delete from TRTRAN082
            where trpy_loan_number = varTemp
            and trpy_loan_serial = 1;

          delete from TRTRAN082B
            where tlbr_loan_number = varTemp
            and tlbr_effective_date = datTemp;
        end if;

        insert into TRTRAN082 (trpy_company_code, trpy_location_code,
          trpy_loan_number, trpy_loan_serial, trpy_repaid_date,
          trpy_debit_type, trpy_transfer_code, trpy_repaid_fcy,
          trpy_to_date, trpy_conversion_rate, trpy_repaid_inr,
          trpy_spot_rate, trpy_spot_inr,
          trpy_create_date,trpy_entry_detail, trpy_record_status)
        select tlon_company_code, tlon_location_code,
          tlon_loan_number, 1, tlon_disbursal_date,
          24900012, GConst.ENTRYDEBIT, tlon_sanctioned_fcy,
          tlon_disbursal_date, tlon_sanctioned_rate, tlon_sanctioned_inr,
          tlon_conversion_rate, round(tlon_sanctioned_fcy * tlon_conversion_rate,2),
          tlon_create_date,tlon_entry_detail, tlon_record_status
          from TRTRAN081
          where tlon_loan_number = varTemp;

        insert into TRTRAN082B (tlbr_company_code, tlbr_location_code,
          tlbr_loan_type, tlbr_local_bank, tlbr_loan_serial,
          tlbr_loan_number, tlbr_effective_date, tlbr_libor_rate,
          tlbr_interest_spread, tlbr_interest_rate, tlbr_user_remarks,
          tlbr_create_date, tlbr_entry_detail, tlbr_record_status)
        select tlon_company_code, tlon_location_code,
          GConst.LOANTERMLOAN,tlon_local_bank,0,
          tlon_loan_number, tlon_disbursal_date, tlon_libor_rate,
          tlon_interest_spread, tlon_interest_rate, 'Opening Interest Rate',
          tlon_create_date, tlon_entry_detail, tlon_record_status
          from TRTRAN081
          where tlon_loan_number = varTemp;
--------------Repayment Schedule adding to table trtran081A,trtran002 Ishwara----------------
         varXPath := '//REPAYMENTSCHEDULE/ROW';
          nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
          varOperation := 'Inserting Data to Repayment Schedule Table ' || varXPath;
          for numTemp in 1..xmlDom.getLength(nlsTemp)
          Loop
              varTemp := varXPath || '[@NUM="' || numTemp || '"]/EffectiveDate';
              varoperation :='Extracting Data from XML' || varTemp;
              datTemp1 := GConst.fncXMLExtract(xmlTemp, varTemp, datTemp1, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/InstallmentDate';
              varoperation :='Extracting Data from XML' || varTemp;
              datTemp2 := GConst.fncXMLExtract(xmlTemp, varTemp, datTemp2, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/InstallmentAmount';
              varoperation :='Extracting Data from XML' || varTemp;
              numFCY := GConst.fncXMLExtract(xmlTemp, varTemp, numFCY, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/PrincipalOutstanding';
              varoperation :='Extracting Data from XML' || varTemp;
              numFCY1 := GConst.fncXMLExtract(xmlTemp, varTemp, numFCY1, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/InterestAmount';
              varoperation :='Extracting Data from XML' || varTemp;
              numFCY2 := GConst.fncXMLExtract(xmlTemp, varTemp, numFCY2, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/SrNo';
              varoperation :='Extracting Data from XML' || varTemp;
              numCode := GConst.fncXMLExtract(xmlTemp, varTemp, numCode, Gconst.TYPENODEPATH);
              varoperation :='Inserting Data to Repayment Schedule Table';
              INSERT INTO trtran081A
--                (REPS_LOAN_NUMBER,REPS_SR_NUMBER,REPS_EFFECTIVE_DATE,
--                  REPS_INSTALLMENT_DATE,REPS_PRINCIPAL_AMOUNT,REPS_INTEREST_AMOUNT,
--                  REPS_PRINCIPAL_OUTSTANDING,REPS_CREATE_DATE,REPS_ENTRY_DETAIL,
--                  REPS_RECORD_STATUS)
                (REPS_LOAN_NUMBER,REPS_SR_NUMBER,REPS_EFFECTIVE_DATE,
                  REPS_INSTALLMENT_DATE,REPS_PRINCIPAL_AMOUNT,REPS_INTEREST_AMOUNT,
                  REPS_PRINCIPAL_OUTSTANDING,REPS_CREATE_DATE,REPS_ENTRY_DETAIL,
                  REPS_RECORD_STATUS,REPS_EMI_REFERENCE,REPS_PROCESS_COMPLETE,REPS_COMPLETE_DATE)
              VALUES
                (varTemp1,numCode,datTemp1,
                 datTemp2,numFcy,numFcy2,
                 numFcy1,SYSDATE,NULL,10200001,'TLN/EMI/000'||numCode,
                 12400002,null);
          end loop;
          if numcode1 = 34500001 then
            INSERT INTO TRTRAN002
                      (TRAD_COMPANY_CODE,TRAD_TRADE_REFERENCE,TRAD_REVERSE_REFERENCE,TRAD_REVERSE_SERIAL,TRAD_IMPORT_EXPORT,
                      TRAD_LOCAL_BANK,TRAD_ENTRY_DATE,TRAD_USER_REFERENCE,TRAD_REFERENCE_DATE,TRAD_BUYER_SELLER,
                      TRAD_TRADE_CURRENCY,TRAD_PRODUCT_CODE,TRAD_PRODUCT_DESCRIPTION,TRAD_TRADE_FCY,TRAD_TRADE_RATE,
                      TRAD_TRADE_INR,TRAD_PERIOD_CODE,TRAD_TRADE_PERIOD,TRAD_TENOR_CODE,TRAD_TENOR_PERIOD,TRAD_MATURITY_FROM,
                      TRAD_MATURITY_DATE,TRAD_PROCESS_COMPLETE,TRAD_COMPLETE_DATE,TRAD_TRADE_REMARKS,TRAD_CREATE_DATE,
                      TRAD_ENTRY_DETAIL,TRAD_RECORD_STATUS,TRAD_VESSEL_NAME,TRAD_PORT_NAME,TRAD_BENEFICIARY,TRAD_USANCE,
                      TRAD_BILL_DATE,TRAD_CONTRACT_NO,TRAD_APP,TRAD_TRANSACTION_TYPE,TRAD_PRODUCT_QUANTITY,TRAD_PRODUCT_RATE,
                      TRAD_TERM,TRAD_VOYAGE,TRAD_LINK_BATCHNO,TRAD_LINK_DATE,TRAD_LC_BENEFICIARY,TRAD_FORWARD_RATE,
                      TRAD_MARGIN_RATE,TRAD_SPOT_RATE,TRAD_SUBPRODUCT_CODE,TRAD_PRODUCT_CATEGORY,
                      TRAD_ADD_DATE,TRAD_LOCATION_CODE)
            SELECT TLON_COMPANY_CODE,
                   TLON_LOAN_NUMBER ||'-'||REPS_SR_NUMBER,NULL,0,25900088,TLON_LOCAL_BANK,
                   TLON_DISBURSAL_DATE,TLON_BANK_REFERENCE,TLON_REFERENCE_DATE,30599999,
                   TLON_CURRENCY_CODE,24299999,null,REPS_PRINCIPAL_AMOUNT,TLON_SANCTIONED_RATE,
                   TLON_SANCTIONED_RATE*REPS_PRINCIPAL_AMOUNT,0,0,25599999,0,REPS_INSTALLMENT_DATE,
                   REPS_INSTALLMENT_DATE,12400002,Null,null,SYSDATE,NULL,10200001,NULL,NULL,NULL,NULL,
                   NULL,NULL,NULL,0,0,0,0,NULL,NULL,NULL,NULL,0,0,
                   TLON_SANCTIONED_RATE,33800001,33300001,NULL,30299999
            FROM TRTRAN081,TRTRAN081A WHERE TLON_LOAN_NUMBER = reps_loan_number
            AND REPS_SR_NUMBER > 0
            AND TLON_LOAN_NUMBER = varTemp1;
          end if;
          
---------------------------------------------------------------------------
      elsif numAction = GConst.DELETESAVE then
        update TRTRAN082
          set trpy_record_status = GConst.STATUSDELETED
          where trpy_loan_number = varTemp1;

        update TRTRAN082B
          set tlbr_record_status = GConst.STATUSDELETED
          where tlbr_loan_number = varTemp1;
      elsif numAction = GConst.CONFIRMSAVE then
        update TRTRAN082
          set trpy_record_status = GConst.STATUSAUTHORIZED
          where trpy_loan_number = varTemp1;

        update TRTRAN082B
          set tlbr_record_status = GConst.STATUSAUTHORIZED
          where tlbr_loan_number = varTemp1;
      end if;
    End if;
    
    if EditType = Gconst.SYSIRSPOPULATE then
      varOperation := 'Extractng IRS Number';
      varReference := GConst.fncXMLExtract(xmlTemp, 'IIRS_IRS_NUMBER', varReference);
      varOperation := 'Insert Buy Leg into table';

    if numAction in (GConst.ADDSAVE) then
      
      insert into trtran091A (IIRL_IRS_NUMBER,IIRL_SERIAL_NUMBER,IIRL_BUY_SELL,
                              IIRL_CURRENCY_CODE,IIRL_INT_TYPE,IIRL_INT_CHARGE,
                              IIRL_BASE_RATE,IIRL_SPREAD,IIRL_FINAL_RATE,IIRL_INTEREST_DAYSTYPE,
                              IIRL_RATE_TYPE,IIRL_CREATE_DATE,IIRL_ADD_DATE,IIRL_TIME_STAMP,
                              IIRL_RECORD_STATUS,IIRL_USER_REFERENCE,IIRL_USER_REMARKS,
                              IIRL_INTEREST_FIXINGTYPE,IIRL_PAYMENTFIXING_DAYSTYPE)
                  values(varReference,1,25300001,
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/CurrencyCode', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/INTType', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/INTChargeFrequency', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/BaseRate', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/Spread', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/FinalRate', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/InterestDaystype', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/RateType', numTemp,Gconst.TYPENODEPATH),
                        sysdate(),sysdate(),sysdate(),10200001,null,null,
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/InterestFixingType', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/PaymentFixingDaysType', numTemp,Gconst.TYPENODEPATH));
                        
                        
      varOperation := 'Insert Sell Leg into table';
      insert into trtran091A (IIRL_IRS_NUMBER,IIRL_SERIAL_NUMBER,IIRL_BUY_SELL,
                              IIRL_CURRENCY_CODE,IIRL_INT_TYPE,IIRL_INT_CHARGE,
                              IIRL_BASE_RATE,IIRL_SPREAD,IIRL_FINAL_RATE,IIRL_INTEREST_DAYSTYPE,
                              IIRL_RATE_TYPE,IIRL_CREATE_DATE,IIRL_ADD_DATE,IIRL_TIME_STAMP,
                              IIRL_RECORD_STATUS,IIRL_USER_REFERENCE,IIRL_USER_REMARKS,
                              IIRL_INTEREST_FIXINGTYPE,IIRL_PAYMENTFIXING_DAYSTYPE)
                  values(varReference,2,25300002,
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/CurrencyCode', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/INTType', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/INTChargeFrequency', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/BaseRate', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/Spread', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/FinalRate', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/InterestDaystype', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/RateType', numTemp,Gconst.TYPENODEPATH),
                        sysdate(),sysdate(),sysdate(),10200001,null,null,
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/InterestFixingType', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/PaymentFixingDaysType', numTemp,Gconst.TYPENODEPATH));

      varOperation := 'Populate the buy Maturities';
      datTemp:=  GConst.fncXMLExtract(xmlTemp, 'IIRS_START_DATE', datTemp);
      datTemp1:=  GConst.fncXMLExtract(xmlTemp, 'IIRS_EXPIRY_DATE', datTemp1);
      numTemp :=GConst.fncXMLExtract(xmlTemp, '//BUYDetails/INTChargeFrequency', numTemp,Gconst.TYPENODEPATH);

      
        VarOperation:= 'Process the maturity Buy Details';
    
        Varxpath := '//SellMaturities/SellMaturity';
        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
        Loop
           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
          
          begin
            datTemp:= GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntFixingDate', DatTemp,Gconst.TYPENODEPATH);
          exception 
          when others then
           datTemp:= null;
          end;
          
            insert into TRTRAN091B(IIRM_IRS_NUMBER,IIRM_SERIAL_NUMBER,IIRM_INTSTART_DATE,
                       IIRM_INTEND_DATE,IIRM_SETTLEMENT_DATE,IIRM_LEG_SERIAL,IIRM_INTFIXING_DATE,
                       IIRM_CREATE_DATE,IIRM_RECORD_STATUS,IIRM_PROCESS_COMPLETE)
                    values (varReference,1,
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntStartDate', DatTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntEndDate', DatTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'SettlementDate', DatTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'SerialNumber', numtemp,Gconst.TYPENODEPATH),datTemp
                    ,sysdate(),10200001,12400002);
                    
              
        end loop;
        
        VarOperation:= 'Process the maturity Details';
    
        Varxpath := '//BuyMaturities/BuyMaturity';
        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
        Loop
           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
          
          begin
            datTemp:= GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntFixingDate', DatTemp,Gconst.TYPENODEPATH);
          exception 
          when others then
           datTemp:= null;
          end;
          
            insert into TRTRAN091B(IIRM_IRS_NUMBER,IIRM_SERIAL_NUMBER,IIRM_INTSTART_DATE,
                       IIRM_INTEND_DATE,IIRM_SETTLEMENT_DATE,IIRM_LEG_SERIAL,IIRM_INTFIXING_DATE,
                       IIRM_CREATE_DATE,IIRM_RECORD_STATUS,IIRM_PROCESS_COMPLETE)
                    values (varReference,2,
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntStartDate', DatTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntEndDate', DatTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'SettlementDate', DatTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'SerialNumber', numtemp,Gconst.TYPENODEPATH),datTemp
                     ,sysdate(),10200001,12400002);
                    
              
        end loop;
              
        VarOperation:= 'Process Roller Coaster Details';
    
        Varxpath := '//RollerCoaster/RollerCoasterDetails';
        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
        Loop
           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
          
            insert into TRTRAN091C(IIRN_IRS_NUMBER,IIRN_SERIAL_NUMBER,IIRN_OUTSTANDING_AMOUNT,
                       IIRN_EFFECTIVE_DATE,IIRN_EFFECTIVE_AMOUNT,IIRN_RECORD_STATUS,
                       IIRn_CREATE_DATE)
                    values (varReference,GConst.fncXMLExtract(xmlTemp, Vartemp || 'SerialNumber', numTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'OutstandingNotional', numTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'EffectiveDate', DatTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'Amount',numTemp,Gconst.TYPENODEPATH),10200001, sysdate());
                    
              
        end loop;
      
     VarOperation:= 'Select the fixed leg details ';
              
       select IIRL_SERIAL_NUMBER,IIRL_Final_Rate,
              IIRL_INTEREST_DAYSTYPE
         into Numcode,numfcy,numcode1
        from trtran091A
        where IIRL_IRS_NUMBER= VarReference
        and IIRL_INT_TYPE=80300001;
        
       VarOperation:= 'Update the fixed leg with interest details ';                             
       
        Update trtran091B set IIRM_INTEREST_Amount=  pkgIRS.fncIRSIntCalcforperiod(
                   iirm_intStart_date,iirm_intEnd_date,varReference,Numcode, numfcy,numcode1),
                   IIRM_FINAL_RATE=numfcy
        where IIRM_IRS_NUMBER= varReference
        and IIRM_Serial_number= Numcode;
                                --Fiexed)
        VarOperation:= 'Process Payment CalanderDates';
    
        Varxpath := '//PaymentCalendarLocs/PaymentCalendarLoc';
        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
        Loop
           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
            insert into TRTRAN091D(IIRP_IRS_NUMBER,IIRP_PAYMENT_CALENDAR_LOCATION,IIRP_CREATE_DATE,
                                   IIRP_RECORD_STATUS)
                    values (varReference,GConst.fncXMLExtract(xmlTemp, Vartemp || 'PLocationCode', numTemp,Gconst.TYPENODEPATH),
                    sysdate(),numStatus);
        end loop;
        
        VarOperation:= 'Process Payment FixingDates';
    
        Varxpath := '//FixingCalendarLocs/FixingCalendarLoc';
        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
        Loop
           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
            insert into TRTRAN091E(IIRF_IRS_NUMBER,IIRF_FIXING_CALENDAR_LOCATION,IIRF_CREATE_DATE,
                                   IIRF_RECORD_STATUS)
                    values (varReference,GConst.fncXMLExtract(xmlTemp, Vartemp || 'FLocationCode', numTemp,Gconst.TYPENODEPATH),
                    sysdate(),numStatus);
        end loop;
        
    end if;
    if numAction in (GConst.EDITSAVE) then
    
--     if numAction in (GConst.EDITSAVE) then 
--        delete from trtran091A where 
--        IIRL_IRS_NUMBER= varReference;
--        
--        delete from trtran091b where 
--        IIRM_IRS_NUMBER=  varReference;
--        
--        delete from trtran091c where 
--        IIRN_IRS_NUMBER=  varReference;
--    end if;    
      
--      insert into trtran091A (IIRL_IRS_NUMBER,IIRL_SERIAL_NUMBER,IIRL_BUY_SELL,
--                              IIRL_CURRENCY_CODE,IIRL_INT_TYPE,IIRL_INT_CHARGE,
--                              IIRL_BASE_RATE,IIRL_SPREAD,IIRL_FINAL_RATE,IIRL_INTEREST_DAYSTYPE,
--                              IIRL_RATE_TYPE,IIRL_CREATE_DATE,IIRL_ADD_DATE,IIRL_TIME_STAMP,
--                              IIRL_RECORD_STATUS,IIRL_USER_REFERENCE,IIRL_USER_REMARKS,
--                              IIRL_INTEREST_FIXINGTYPE,IIRL_PAYMENTFIXING_DAYSTYPE)
--                  values(varReference,1,25300001,
--                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/CurrencyCode', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/INTType', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/INTChargeFrequency', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/BaseRate', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/Spread', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/FinalRate', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/InterestDaystype', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/RateType', numTemp,Gconst.TYPENODEPATH),
--                        sysdate(),sysdate(),sysdate(),10200001,null,null,
--                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/InterestFixingType', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/PaymentFixingDaysType', numTemp,Gconst.TYPENODEPATH));
                        
                        
--      varOperation := 'Insert Sell Leg into table';
--      insert into trtran091A (IIRL_IRS_NUMBER,IIRL_SERIAL_NUMBER,IIRL_BUY_SELL,
--                              IIRL_CURRENCY_CODE,IIRL_INT_TYPE,IIRL_INT_CHARGE,
--                              IIRL_BASE_RATE,IIRL_SPREAD,IIRL_FINAL_RATE,IIRL_INTEREST_DAYSTYPE,
--                              IIRL_RATE_TYPE,IIRL_CREATE_DATE,IIRL_ADD_DATE,IIRL_TIME_STAMP,
--                              IIRL_RECORD_STATUS,IIRL_USER_REFERENCE,IIRL_USER_REMARKS,
--                              IIRL_INTEREST_FIXINGTYPE,IIRL_PAYMENTFIXING_DAYSTYPE)
--                  values(varReference,2,25300002,
--                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/CurrencyCode', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/INTType', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/INTChargeFrequency', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/BaseRate', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/Spread', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/FinalRate', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/InterestDaystype', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/RateType', numTemp,Gconst.TYPENODEPATH),
--                        sysdate(),sysdate(),sysdate(),10200001,null,null,
--                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/InterestFixingType', numTemp,Gconst.TYPENODEPATH),
--                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/PaymentFixingDaysType', numTemp,Gconst.TYPENODEPATH));

      varOperation := 'Populate the buy Maturities';
      datTemp:=  GConst.fncXMLExtract(xmlTemp, 'IIRS_START_DATE', datTemp);
      datTemp1:=  GConst.fncXMLExtract(xmlTemp, 'IIRS_EXPIRY_DATE', datTemp1);
      numTemp :=GConst.fncXMLExtract(xmlTemp, '//BUYDetails/INTChargeFrequency', numTemp,Gconst.TYPENODEPATH);

      
        VarOperation:= 'Process the maturity Buy Details';
    
        Varxpath := '//SellMaturities/SellMaturity';
        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
        Loop
           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
          
          begin
            datTemp:= GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntFixingDate', DatTemp,Gconst.TYPENODEPATH);
          exception 
          when others then
           datTemp:= null;
          end;
            datTemp1 := GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntStartDate', DatTemp1,Gconst.TYPENODEPATH);
            datTemp2 := GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntEndDate', DatTemp2,Gconst.TYPENODEPATH);
            datTemp3 := GConst.fncXMLExtract(xmlTemp, Vartemp || 'SettlementDate', DatTemp3,Gconst.TYPENODEPATH);
            begin
              numFcy6 := GConst.fncXMLExtract(xmlTemp, Vartemp || 'InterestFcy', numFcy6,Gconst.TYPENODEPATH);
            exception 
            when others then
             numFcy6:= 0;
            end;              
            numCode4 := GConst.fncXMLExtract(xmlTemp, Vartemp || 'SerialNumber', numCode4,Gconst.TYPENODEPATH);
            
            SELECT iirl_serial_number INTO numCode3 FROM TRTRAN091A WHERE IIRL_BUY_SELL = 25300002 
                                AND IIRL_IRS_NUMBER = varReference;--SellDetails
                                
            
            UPDATE TRTRAN091B SET IIRM_INTSTART_DATE = datTemp1,
                                  IIRM_INTEND_DATE = datTemp2,
                                  IIRM_SETTLEMENT_DATE = datTemp3,
                                  IIRM_INTEREST_Amount = numFcy6,
                                  IIRM_RECORD_STATUS = 10200004
                                  WHERE IIRM_IRS_NUMBER = varReference
                                  AND IIRM_SERIAL_NUMBER = numCode3
                                  AND IIRM_LEG_SERIAL = numCode4
                                  AND IIRM_PROCESS_COMPLETE = 12400002;
            
--            insert into TRTRAN091B(IIRM_IRS_NUMBER,IIRM_SERIAL_NUMBER,IIRM_INTSTART_DATE,
--                       IIRM_INTEND_DATE,IIRM_SETTLEMENT_DATE,IIRM_LEG_SERIAL,IIRM_INTFIXING_DATE,
--                       IIRM_CREATE_DATE,IIRM_RECORD_STATUS,IIRM_PROCESS_COMPLETE)
--                    values (varReference,1,
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntStartDate', DatTemp,Gconst.TYPENODEPATH),
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntEndDate', DatTemp,Gconst.TYPENODEPATH),
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'SettlementDate', DatTemp,Gconst.TYPENODEPATH),
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'SerialNumber', numtemp,Gconst.TYPENODEPATH),datTemp
--                    ,sysdate(),10200001,12400002);
                    
              
        end loop;
        
        VarOperation:= 'Process the maturity Details';
    
        Varxpath := '//BuyMaturities/BuyMaturity';
        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
        Loop
           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
          
          begin
            datTemp:= GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntFixingDate', DatTemp,Gconst.TYPENODEPATH);
          exception 
          when others then
           datTemp:= null;
          end;
            datTemp1 := GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntStartDate', DatTemp1,Gconst.TYPENODEPATH);
            datTemp2 := GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntEndDate', DatTemp2,Gconst.TYPENODEPATH);
            datTemp3 := GConst.fncXMLExtract(xmlTemp, Vartemp || 'SettlementDate', DatTemp3,Gconst.TYPENODEPATH);
            begin
              numFcy6 := GConst.fncXMLExtract(xmlTemp, Vartemp || 'InterestFcy', numFcy6,Gconst.TYPENODEPATH);
            exception 
            when others then
             numFcy6:= 0;
            end;              
            numCode4 := GConst.fncXMLExtract(xmlTemp, Vartemp || 'SerialNumber', numCode4,Gconst.TYPENODEPATH);
            
            SELECT iirl_serial_number INTO numCode3 FROM TRTRAN091A WHERE IIRL_BUY_SELL = 25300001 
                                AND IIRL_IRS_NUMBER = varReference;--BUYDetails
                                
            
            UPDATE TRTRAN091B SET IIRM_INTSTART_DATE = datTemp1,
                                  IIRM_INTEND_DATE = datTemp2,
                                  IIRM_SETTLEMENT_DATE = datTemp3,
                                  IIRM_INTEREST_Amount = numFcy6,
                                  IIRM_RECORD_STATUS = 10200004
                                  WHERE IIRM_IRS_NUMBER = varReference
                                  AND IIRM_SERIAL_NUMBER = numCode3
                                  AND IIRM_LEG_SERIAL = numCode4
                                  AND IIRM_PROCESS_COMPLETE = 12400002;          
          
--            insert into TRTRAN091B(IIRM_IRS_NUMBER,IIRM_SERIAL_NUMBER,IIRM_INTSTART_DATE,
--                       IIRM_INTEND_DATE,IIRM_SETTLEMENT_DATE,IIRM_LEG_SERIAL,IIRM_INTFIXING_DATE,
--                       IIRM_CREATE_DATE,IIRM_RECORD_STATUS,IIRM_PROCESS_COMPLETE)
--                    values (varReference,2,
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntStartDate', DatTemp,Gconst.TYPENODEPATH),
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntEndDate', DatTemp,Gconst.TYPENODEPATH),
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'SettlementDate', DatTemp,Gconst.TYPENODEPATH),
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'SerialNumber', numtemp,Gconst.TYPENODEPATH),datTemp
--                     ,sysdate(),10200001,12400002);
                    
              
        end loop;
              
--        VarOperation:= 'Process Roller Coaster Details';
--    
--        Varxpath := '//RollerCoaster/RollerCoasterDetails';
--        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
--        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
--        Loop
--           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
--          
--            insert into TRTRAN091C(IIRN_IRS_NUMBER,IIRN_SERIAL_NUMBER,IIRN_OUTSTANDING_AMOUNT,
--                       IIRN_EFFECTIVE_DATE,IIRN_EFFECTIVE_AMOUNT,IIRN_RECORD_STATUS,
--                       IIRn_CREATE_DATE)
--                    values (varReference,GConst.fncXMLExtract(xmlTemp, Vartemp || 'SerialNumber', numTemp,Gconst.TYPENODEPATH),
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'OutstandingNotional', numTemp,Gconst.TYPENODEPATH),
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'EffectiveDate', DatTemp,Gconst.TYPENODEPATH),
--                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'Amount',numTemp,Gconst.TYPENODEPATH),10200001, sysdate());
--                    
--              
--        end loop;
      
--     VarOperation:= 'Select the fixed leg details ';
--              
--       select IIRL_SERIAL_NUMBER,IIRL_Final_Rate,
--              IIRL_INTEREST_DAYSTYPE
--         into Numcode,numfcy,numcode1
--        from trtran091A
--        where IIRL_IRS_NUMBER= VarReference
--        and IIRL_INT_TYPE=80300001;
--        
--       VarOperation:= 'Update the fixed leg with interest details ';                             
--       
--        Update trtran091B set IIRM_INTEREST_Amount=  pkgIRS.fncIRSIntCalcforperiod(
--                   iirm_intStart_date,iirm_intEnd_date,varReference,Numcode, numfcy,numcode1),
--                   IIRM_FINAL_RATE=numfcy
--        where IIRM_IRS_NUMBER= varReference
--        and IIRM_Serial_number= Numcode;
--                                --Fiexed)
        VarOperation:= 'Process Payment CalanderDates';
        DELETE FROM TRTRAN091D WHERE IIRP_IRS_NUMBER = varReference;
        Varxpath := '//PaymentCalendarLocs/PaymentCalendarLoc';
        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
        Loop
           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
            insert into TRTRAN091D(IIRP_IRS_NUMBER,IIRP_PAYMENT_CALENDAR_LOCATION,IIRP_CREATE_DATE,
                                   IIRP_RECORD_STATUS)
                    values (varReference,GConst.fncXMLExtract(xmlTemp, Vartemp || 'PLocationCode', numTemp,Gconst.TYPENODEPATH),
                    sysdate(),numStatus);
        end loop;
        
        VarOperation:= 'Process Payment FixingDates';
        DELETE FROM TRTRAN091E WHERE IIRF_IRS_NUMBER = varReference;
        Varxpath := '//FixingCalendarLocs/FixingCalendarLoc';
        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
        Loop
           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
            insert into TRTRAN091E(IIRF_IRS_NUMBER,IIRF_FIXING_CALENDAR_LOCATION,IIRF_CREATE_DATE,
                                   IIRF_RECORD_STATUS)
                    values (varReference,GConst.fncXMLExtract(xmlTemp, Vartemp || 'FLocationCode', numTemp,Gconst.TYPENODEPATH),
                    sysdate(),numStatus);
        end loop;
        
    end if;    
    if  numAction in (GConst.CONFIRMSAVE) then
         update trtran091a set iirl_record_status =10200003
          where IIRL_IRS_NUMBER= varReference;
        
         update trtran091b set iirm_record_status =10200003
          where IIRm_IRS_NUMBER= varReference;
        
        update trtran091c set iirn_record_status =10200003
          where IIRn_IRS_NUMBER= varReference;
      end if; 
    if  numAction in (GConst.DELETESAVE) then
         update trtran091a set iirl_record_status =10200006
          where IIRL_IRS_NUMBER= varReference;
        
         update trtran091b set iirm_record_status =10200006
          where IIRm_IRS_NUMBER= varReference;
        
        update trtran091c set iirn_record_status =10200006
          where IIRn_IRS_NUMBER= varReference;
      end if; 
      
  end if;
 
   IF EditType = GConst.SYSCCIRSSETTLE THEN


    varOperation := 'Processing Mutual Fund Redemption';
    varReference := GConst.fncXMLExtract(xmlTemp, 'ICST_IRS_NUMBER', varTemp);
    numCode := GConst.fncXMLExtract(xmlTemp, 'ICST_TRAN_TYPE', numCode);
    numcode1 := Gconst.fncXMLExtract(xmlTemp, 'ICST_SERIAL_NUMBER', numCode1);
    datTemp := GConst.fncXMLExtract(xmlTemp, 'ICST_SETTLEMENT_DATE', datTemp);
    IF numCode = 81000001 THEN 
      datTemp1 := GConst.fncXMLExtract(xmlTemp,'KeyValues/IntStartDate',datTemp1);
      datTemp2 := GConst.fncXMLExtract(xmlTemp,'KeyValues/IntEndDate',datTemp2);
    end if;  
    
    IF numCode = 81000001 THEN 
      SELECT IIRM_LEG_SERIAL INTO numcode2 FROM  TRTRAN091B WHERE IIRM_IRS_NUMBER = varReference
                                                              AND IIRM_SERIAL_NUMBER = numcode1
                                                              AND IIRM_INTSTART_DATE = datTemp1
                                                              AND IIRM_INTEND_DATE = datTemp2;
      UPDATE TRTRAN091B SET  IIRM_PROCESS_COMPLETE = 12400001,
                             IIRM_COMPLETE_DATE =  datTemp
                             WHERE IIRM_IRS_NUMBER = varReference
                             AND IIRM_LEG_SERIAL = numcode2;
    ELSE
      UPDATE TRTRAN091C SET  IIRN_PROCESS_COMPLETE = 12400001,
                             IIRN_COMPLETE_DATE =  datTemp
                             WHERE IIRN_IRS_NUMBER = varReference
                             AND IIRN_SERIAL_NUMBER = numcode1;
    END IF;
  end if;
  
  if EditType = Gconst.SYSCCIRSPOPULATE then
      varOperation := 'Extractng CC IRS Number';
      varReference := GConst.fncXMLExtract(xmlTemp, 'IIRS_IRS_NUMBER', varReference);
      varOperation := 'Insert Buy Leg into table';
      
      
     if numAction in (GConst.EDITSAVE) then 
        delete from trtran091A where 
        IIRL_IRS_NUMBER= varReference;
        
        delete from trtran091b where 
        IIRM_IRS_NUMBER=  varReference;
        
        delete from trtran091c where 
        IIRN_IRS_NUMBER=  varReference;
        
        delete from trtran091D where 
        IIRP_IRS_NUMBER= varReference;
        
        delete from trtran091E where 
        IIRF_IRS_NUMBER= varReference;
        
    end if;
    if numAction in (GConst.ADDSAVE,GConst.EDITSAVE) then
      select decode(GConst.ADDSAVE,10200001,GConst.EDITSAVE,10200004)
        into numstatus
       from dual;

      insert into trtran091A (IIRL_IRS_NUMBER,IIRL_SERIAL_NUMBER,IIRL_BUY_SELL,
                              IIRL_CURRENCY_CODE,IIRL_INT_TYPE,IIRL_INT_CHARGE,
                              IIRL_BASE_RATE,IIRL_SPREAD,IIRL_FINAL_RATE,IIRL_INTEREST_DAYSTYPE,
                              IIRL_RATE_TYPE,IIRL_CREATE_DATE,IIRL_ADD_DATE,IIRL_TIME_STAMP,
                              IIRL_RECORD_STATUS,IIRL_USER_REFERENCE,IIRL_USER_REMARKS,
                              IIRL_INTEREST_FIXINGTYPE,IIRL_NOTIONAL_AMOUNT,IIRL_PAYMENTFIXING_DAYSTYPE)
                  values(varReference,1,25300001,
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/CurrencyCode', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/INTType', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/INTChargeFrequency', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/BaseRate', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/Spread', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/FinalRate', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/InterestDaystype', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/RateType', numTemp,Gconst.TYPENODEPATH),
                        sysdate(),sysdate(),sysdate(),numstatus,null,null,
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/InterestFixingType', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/NotionalAmount', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//BUYDetails/PaymentFixingDaysType', numTemp,Gconst.TYPENODEPATH));
                        
                        
      varOperation := 'Insert Sell Leg into table';
      insert into trtran091A (IIRL_IRS_NUMBER,IIRL_SERIAL_NUMBER,IIRL_BUY_SELL,
                              IIRL_CURRENCY_CODE,IIRL_INT_TYPE,IIRL_INT_CHARGE,
                              IIRL_BASE_RATE,IIRL_SPREAD,IIRL_FINAL_RATE,IIRL_INTEREST_DAYSTYPE,
                              IIRL_RATE_TYPE,IIRL_CREATE_DATE,IIRL_ADD_DATE,IIRL_TIME_STAMP,
                              IIRL_RECORD_STATUS,IIRL_USER_REFERENCE,IIRL_USER_REMARKS,
                              IIRL_INTEREST_FIXINGTYPE,IIRL_NOTIONAL_AMOUNT,IIRL_PAYMENTFIXING_DAYSTYPE)
                  values(varReference,2,25300002,
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/CurrencyCode', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/INTType', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/INTChargeFrequency', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/BaseRate', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/Spread', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/FinalRate', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/InterestDaystype', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/RateType', numTemp,Gconst.TYPENODEPATH),
                        sysdate(),sysdate(),sysdate(),numstatus,null,null,
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/InterestFixingType', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/NotionalAmount', numTemp,Gconst.TYPENODEPATH),
                        GConst.fncXMLExtract(xmlTemp, '//SELLDetails/PaymentFixingDaysType', numTemp,Gconst.TYPENODEPATH));

      varOperation := 'Populate the buy Maturities';
      datTemp:=  GConst.fncXMLExtract(xmlTemp, 'IIRS_START_DATE', datTemp);
      datTemp1:=  GConst.fncXMLExtract(xmlTemp, 'IIRS_EXPIRY_DATE', datTemp1);
      numTemp :=GConst.fncXMLExtract(xmlTemp, '//BUYDetails/INTChargeFrequency', numTemp,Gconst.TYPENODEPATH);

      
        VarOperation:= 'Process the maturity Buy Details';
    
        Varxpath := '//SellMaturities/SellMaturity';
        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
        Loop
           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
           begin
              dattemp := GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntFixingDate', DatTemp,Gconst.TYPENODEPATH);
           exception   
           when others then 
             datTemp:= null;
           end;  
             
            insert into TRTRAN091B(IIRM_IRS_NUMBER,IIRM_SERIAL_NUMBER,IIRM_INTSTART_DATE,
                       IIRM_INTEND_DATE,IIRM_SETTLEMENT_DATE,IIRM_LEG_SERIAL,IIRM_INTFIXING_DATE,
                       IIRM_CREATE_DATE,IIRM_RECORD_STATUS,IIRM_PROCESS_COMPLETE,
                       IIRM_INTEREST_AMOUNT)
                    values (varReference,1,
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntStartDate', DatTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntEndDate', DatTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'SettlementDate', DatTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'SerialNumber', numtemp,Gconst.TYPENODEPATH),
                    dattemp
                    ,sysdate(),numstatus,12400002,
                   (case when  GConst.fncXMLExtract(xmlTemp, '//BUYDetails/INTType', numTemp,Gconst.TYPENODEPATH) =80300002 then--Floating
                       0 
                       when  GConst.fncXMLExtract(xmlTemp, '//BUYDetails/INTType', numTemp,Gconst.TYPENODEPATH) =80300001 then --Fixed
                   pkgIRS.fncIRSIntCalcforperiod(
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntStartDate', DatTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntEndDate', DatTemp,Gconst.TYPENODEPATH),
                    varReference, 1,
                    GConst.fncXMLExtract(xmlTemp, '//BUYDetails/FinalRate', numTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, '//BUYDetails/InterestDaystype', numTemp,Gconst.TYPENODEPATH))
                    end));

                    --80300001	Fixed
--80300002	Floating
              
        end loop;
        
        VarOperation:= 'Process the maturity Details';
    
        Varxpath := '//BuyMaturities/BuyMaturity';
        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
        Loop
           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';

           begin
              dattemp := GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntFixingDate', DatTemp,Gconst.TYPENODEPATH);
           exception   
           when others then 
             datTemp:= null;
           end; 
           
            insert into TRTRAN091B(IIRM_IRS_NUMBER,IIRM_SERIAL_NUMBER,IIRM_INTSTART_DATE,
                       IIRM_INTEND_DATE,IIRM_SETTLEMENT_DATE,IIRM_LEG_SERIAL,IIRM_INTFIXING_DATE,
                       IIRM_CREATE_DATE,IIRM_RECORD_STATUS,IIRM_PROCESS_COMPLETE,
                       IIRM_INTEREST_AMOUNT)
                    values (varReference,2,
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntStartDate', DatTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntEndDate', DatTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'SettlementDate', DatTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'SerialNumber', numtemp,Gconst.TYPENODEPATH),
                    datTemp
                     ,sysdate(),numstatus,12400002,
                   (case when  GConst.fncXMLExtract(xmlTemp, '//BUYDetails/INTType', numTemp,Gconst.TYPENODEPATH) =80300002 then--Floating
                       0 
                       when  GConst.fncXMLExtract(xmlTemp, '//BUYDetails/INTType', numTemp,Gconst.TYPENODEPATH) =80300001 then --Fixed
                        pkgIRS.fncIRSIntCalcforperiod(
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntStartDate', DatTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'IntEndDate', DatTemp,Gconst.TYPENODEPATH),
                    varReference, 2,
                    GConst.fncXMLExtract(xmlTemp, '//SELLDetails/FinalRate', numTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, '//SELLDetails/InterestDaystype', numTemp,Gconst.TYPENODEPATH))
                    end));
                    
              
        end loop;
              
        VarOperation:= 'Process Roller Coaster Details';
    
        Varxpath := '//RollerCoaster/RollerCoasterDetails';
        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
        Loop
           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
          
            insert into TRTRAN091C(IIRN_IRS_NUMBER,IIRN_SERIAL_NUMBER,IIRN_OUTSTANDING_AMOUNT,
                       IIRN_EFFECTIVE_DATE,IIRN_EFFECTIVE_AMOUNT,IIRN_RECORD_STATUS,
                       IIRn_CREATE_DATE,IIRN_PAYMENT_AMOUNT,IIRN_OUTSTANDING_PAYMENT)
                    values (varReference,GConst.fncXMLExtract(xmlTemp, Vartemp || 'SerialNumber', numTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'OutstandingReceipt', numTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'EffectiveDate', DatTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'ReceiptAmount',numTemp,Gconst.TYPENODEPATH),numstatus, sysdate(),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'PaymentAmount', numTemp,Gconst.TYPENODEPATH),
                    GConst.fncXMLExtract(xmlTemp, Vartemp || 'OutstandingPayment', numTemp,Gconst.TYPENODEPATH));
                    
              
        end loop;

     VarOperation:= 'Select First fixed leg details ';
      
      begin         
       select IIRL_SERIAL_NUMBER,IIRL_Final_Rate,
              IIRL_INTEREST_DAYSTYPE
         into Numcode,numfcy,numcode1
        from trtran091A
        where IIRL_IRS_NUMBER= VarReference
        and IIRL_INT_TYPE=80300001 --Fixed Leg
        and IIRL_Serial_NUmber=1;
        numCode2:= sql%RowCount;
      exception 
        when no_data_found then 
         numCode2:= 0;
      end ; 
       VarOperation:= 'Update the First fixed leg with interest details ';                             
        if numCode2 !=0 then 
          Update trtran091B set IIRM_INTEREST_Amount=  pkgIRS.fncIRSIntCalcforperiod(
                     iirm_intStart_date,iirm_intEnd_date,varReference,Numcode, numfcy,numcode1),
                     IIRM_FINAL_RATE=numfcy
          where IIRM_IRS_NUMBER= varReference
          and IIRM_Serial_number =Numcode;
        end if;
        
       VarOperation:= 'Select Second fixed leg details ';
       numcode2:=0;
       begin        
         select IIRL_SERIAL_NUMBER,IIRL_Final_Rate,
                IIRL_INTEREST_DAYSTYPE
           into Numcode,numfcy,numcode1
          from trtran091A
          where IIRL_IRS_NUMBER= VarReference
          and IIRL_INT_TYPE=80300001  --Fixed Leg
          and IIRL_Serial_NUmber=2;
          numcode2:=SQl%rowcount;
       exception 
         when others then 
           numcode2:=0;
       end;
       VarOperation:= 'Update the Second fixed leg with interest details ';                             
        if numCode2 !=0 then 
          Update trtran091B set IIRM_INTEREST_Amount=  pkgIRS.fncIRSIntCalcforperiod(
                     iirm_intStart_date,iirm_intEnd_date,varReference,Numcode, numfcy,numcode1),
                     IIRM_FINAL_RATE=numfcy
          where IIRM_IRS_NUMBER= varReference
          and IIRM_Serial_number =Numcode;
        end if;
        
        


        
        VarOperation:= 'Process Payment CalanderDates';
    
        Varxpath := '//PaymentCalendarLocs/PaymentCalendarLoc';
        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
        Loop
           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
            insert into TRTRAN091D(IIRP_IRS_NUMBER,IIRP_PAYMENT_CALENDAR_LOCATION,IIRP_CREATE_DATE,
                                   IIRP_RECORD_STATUS)
                    values (varReference,GConst.fncXMLExtract(xmlTemp, Vartemp || 'PLocationCode', numTemp,Gconst.TYPENODEPATH),
                    sysdate(),numStatus);
        end loop;
        
        VarOperation:= 'Process Payment FixingDates';
    
        Varxpath := '//FixingCalendarLocs/FixingCalendarLoc';
        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
        Loop
           Vartemp := Varxpath || '[@ROWNUM="' || numTemp || '"]/';
            insert into TRTRAN091E(IIRF_IRS_NUMBER,IIRF_FIXING_CALENDAR_LOCATION,IIRF_CREATE_DATE,
                                   IIRF_RECORD_STATUS)
                    values (varReference,GConst.fncXMLExtract(xmlTemp, Vartemp || 'FLocationCode', numTemp,Gconst.TYPENODEPATH),
                    sysdate(),numStatus);
        end loop;
        
        
    end if;
    if  numAction in (GConst.CONFIRMSAVE) then
         update trtran091a set iirl_record_status =10200003
          where IIRL_IRS_NUMBER= varReference;
        
         update trtran091b set iirm_record_status =10200003
          where IIRm_IRS_NUMBER= varReference;
        
        update trtran091c set iirn_record_status =10200003
          where IIRn_IRS_NUMBER= varReference;
      end if; 
    if  numAction in (GConst.DELETESAVE) then
         update trtran091a set iirl_record_status =10200006
          where IIRL_IRS_NUMBER= varReference;
        
         update trtran091b set iirm_record_status =10200006
          where IIRm_IRS_NUMBER= varReference;
        
        update trtran091c set iirn_record_status =10200006
          where IIRn_IRS_NUMBER= varReference;
      end if; 
      
  end if;
    
      if edittype =Gconst.SYSIROPOPULATE then 
       VarOperation:= 'Extract the IRO Details from XML';
       
       
         VARREFERENCE := GCONST.FNCXMLEXTRACT(xmlTemp, 'IIRO_DEAL_NUMBER', VARREFERENCE);
        Varxpath := '//DealLegs/Leg';
        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
        Loop
          Vartemp := Varxpath || '[@NUM="' || numTemp || '"]/';
        
          VarOperation:= 'Process the multiple deals';
         insert into trtran093a( IROL_DEAL_NUMBER,IROL_SERIAL_NUMBER,
                      IROL_OPTION_TYPE,IROL_BUY_SELL,IROL_STRIKE_RATE,
                      IROL_SPREAD_RATE,IROL_BASE_AMOUNT,IROL_INIT_TYPE,
                      IROL_Interest_Startdate,IROL_Reset_Frequency,
                      IROL_Delivery_Type,IROL_PROCESS_COMPLETE,IROL_LOT_NUMBERS,
                      IROL_LOT_QUANTITY,IROL_RECORD_STATUS,IROL_CREATE_DATE)
                     values (VARREFERENCE,   
              GConst.fncXMLExtract(xmlTemp, Vartemp || 'SRNO', numTemp,Gconst.TYPENODEPATH),
              GConst.fncXMLExtract(xmlTemp, Vartemp || 'OptionType', numTemp,Gconst.TYPENODEPATH),
              GConst.fncXMLExtract(xmlTemp, Vartemp || 'BuySell', numTemp,Gconst.TYPENODEPATH),
              GConst.fncXMLExtract(xmlTemp, Vartemp || 'StrikeRate', numTemp,Gconst.TYPENODEPATH),
              GConst.fncXMLExtract(xmlTemp, Vartemp || 'Spread', numTemp,Gconst.TYPENODEPATH),
              GConst.fncXMLExtract(xmlTemp, Vartemp || 'BaseAmount', numTemp,Gconst.TYPENODEPATH),
              GConst.fncXMLExtract(xmlTemp, Vartemp || 'INTType', numTemp,Gconst.TYPENODEPATH),
              GConst.fncXMLExtract(xmlTemp, Vartemp || 'InterestStartDate', dattemp,Gconst.TYPENODEPATH),
              GConst.fncXMLExtract(xmlTemp, Vartemp || 'ResetFrequency', numTemp,Gconst.TYPENODEPATH),
              GConst.fncXMLExtract(xmlTemp, Vartemp || 'DeliveryType', numTemp,Gconst.TYPENODEPATH),
              12400001,
               GConst.fncXMLExtract(xmlTemp, Vartemp || 'LotNumbers', numTemp,Gconst.TYPENODEPATH),
               GConst.fncXMLExtract(xmlTemp, Vartemp || 'LotQuantity', numTemp,Gconst.TYPENODEPATH),
               10200001,sysdate);
              
         
        End Loop;
        
        VarOperation:= 'Process the maturity Details';
          
               Varxpath := '//Maturity/MaturityRow';
        Nlstemp := Xslprocessor.Selectnodes(Nodfinal, Varxpath);
        for numTemp in 0..xmlDom.getLength(nlsTemp)-1
        Loop
          Vartemp := Varxpath || '[@MRow="' || numTemp || '"]/';
          Numcompany := Gconst.Fncxmlextract(Xmltemp, Vartemp, Numcompany, Gconst.Typenodepath);
          insert into TRTRAN093B (IROM_DEAL_NUMBER,IROM_SERIAL_NUMBER,IROM_SUBSERIAL_NUMBER,
                    IROM_INTSTART_DATE,IROM_INTEND_DATE,IROM_SETTLEMENT_DATE,
                    IROM_CREATE_DATE,IROM_RECORD_STATUS,IROM_PROCESS_COMPLETE)
               values (VARREFERENCE,   
              GConst.fncXMLExtract(xmlTemp, Vartemp || 'LegSrNo', numTemp,Gconst.TYPENODEPATH),
              GConst.fncXMLExtract(xmlTemp, Vartemp || 'SrNo', numTemp,Gconst.TYPENODEPATH),
              GConst.fncXMLExtract(xmlTemp, Vartemp || 'InterestStartDate', dattemp,Gconst.TYPENODEPATH),
              GConst.fncXMLExtract(xmlTemp, Vartemp || 'InterestEndDate', dattemp,Gconst.TYPENODEPATH),
              GConst.fncXMLExtract(xmlTemp, Vartemp || 'SettlementDate', dattemp,Gconst.TYPENODEPATH),
              sysdate, 10200001,12400002);
              
         
        End Loop;
      end if;


    if EditType = GConst.SYSFUTUREMTMUPLOAD then

      varOperation := 'Extractng Parametersfor Futures MTM Rates';
      datTemp := GConst.fncXMLExtract(xmlTemp, '//ROW[@NUM="1"]/CFMM_EFFECTIVE_DATE', datTemp,Gconst.TYPENODEPATH);
      numCode := GConst.fncXMLExtract(xmlTemp, '//ROW[@NUM="1"]/CFMM_EXCHANGE_CODE', numCode,Gconst.TYPENODEPATH);

      varOperation := 'Inserting MTM Rates for Futures, Exchange ' || numCode;
      insert into trtran062
      (cfmr_company_code,cfmr_deal_number,cfmr_serial_number,cfmr_mtm_date,
      cfmr_mtm_rate,cfmr_profit_loss,cfmr_margin_amount,cfmr_create_date,
      cfmr_entry_detail,cfmr_record_status,cfmr_mtm_user,cfmr_pl_voucher,
      cfmr_mtm_amount,cfmr_margin_excess)
      select cfut_company_code, cfut_deal_number,
        (select NVL(max(cfmm_serial_number),0) + 1
          from trtran062
          where cfmr_deal_number = cfut_deal_number), datTemp,
        cfmm_closing_rate,pkgForexProcess.fnccalfuturepandl(cfut_buy_sell,
          cfut_lot_numbers,cfut_Exchange_rate,cfmm_closing_rate) * 1000, 0,
          sysdate, NULL, 10200001, cfut_user_id, NULL,
          Round(cfut_base_amount * cfmm_closing_rate), 0
        from trtran061, trtran064
        where cfut_exchange_code = cfmm_exchange_code
        and cfut_base_currency = cfmm_base_currency
        and cfut_maturity_date = cfmm_expiry_month
        and cfut_exchange_code = numCode
        and cfmm_effective_date = datTemp
        and cfut_process_complete = 12400002
        and cfmm_record_status in (10200001,10200002,10200004);

      update trtran064
        set cfmm_record_status = 10200003
        where cfmm_exchange_code = numCode
        and cfmm_effective_date = datTemp;
    End if;

    if EditType = GConst.SYSAANDLPOSITION then
      numCode := GConst.fncXMLExtract(xmlTemp, '//ROW[@NUM="1"]/UNLN_COMPANY_CODE', numCode,Gconst.TYPENODEPATH);
      datTemp := GConst.fncXMLExtract(xmlTemp, '//ROW[@NUM="1"]/UNLN_EFFECTIVE_DATE', datTemp,Gconst.TYPENODEPATH);
      numCode1 := GConst.fncXMLExtract(xmlTemp, '//ROW[@NUM="1"]/UNLN_CURRENCY_CODE', numCode1,Gconst.TYPENODEPATH);
      varTemp := pkgReturnCursor.fncGetDescription(numCode,GConst.PICKUPSHORT);

      varOperation := 'For Edit / Delete status delete the underlyings';
--      if numAction in (GConst.EDITSAVE, Gconst.DELETESAVE) then
--        update trtran002
--          set trad_record_status = GConst.STATUSDELETED
--          where trad_company_code = numCode
--          and trad_trade_reference in
--          (select unln_trade_reference
--            from trtran002A
--            where unln_company_code = numCode
--            and unln_effective_date = datTemp
--            and unln_line_item = 'T');
--      End if;

      varOperation := 'Creating Trades from ALM Position';
      if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
        for curAandL in
        (select unln_company_code,unln_aandl_code, unln_forward_months,
          unln_base_amount, unln_spot_rate, unln_forward_rate, unln_exchange_rate,
          unln_due_date
          from trtran002A
          where unln_company_code = numCode
          and unln_effective_date =  datTemp
          and unln_line_item = 'T'
          and unln_base_amount > 0)
          Loop
            varReference := varTemp || '/' ||
              pkgReturnCursor.fncGetDescription(curAandL.unln_aandl_code,GConst.PICKUPSHORT);
            varReference  :=  varReference || '/' || pkgGlobalMethods.fncGenerateSerial(GConst.SERIALTRADE);
--            varOperation := 'Inserting Records to Trade Register ' || varReference;
--            insert into trtran002
--            (trad_company_code,trad_trade_reference,trad_reverse_reference,trad_reverse_serial,
--            trad_import_export,trad_local_bank,trad_entry_date,trad_user_reference,
--            trad_reference_date,trad_buyer_seller,trad_trade_currency,trad_product_code,
--            trad_product_description,trad_trade_fcy,trad_trade_rate,trad_trade_inr,
--            trad_period_code,trad_trade_period,trad_tenor_code,trad_tenor_period,
--            trad_maturity_from,trad_maturity_date,trad_maturity_month,trad_process_complete,
--            trad_complete_date,trad_trade_remarks,trad_create_date,trad_entry_detail,
--            trad_record_status, trad_transaction_type,
--            trad_forward_rate,trad_margin_rate,trad_final_rate,trad_spot_rate)
--            values(numCode,varReference,null,0,
--            decode(curAandL.unln_aandl_code, 33700001,25900101,
--              33700002,25900102,33700003,25900103,33700050,25900150,
--              33700051,25900151,33700052,25900152,33700053,25900153,
--            25999999),30699999,datWorkDate,'ALM Generated',
--            datTemp, 30599999,numCode1,24299999,'ALM Increment/Decrement',
--            curAandL.unln_base_amount,curAandL.unln_exchange_rate,
--            Round(curAandL.unln_base_amount * curAandL.unln_exchange_rate),
--            25500003,curAandL.unln_forward_months,0,0,curAandL.unln_due_date,
--            curAandL.unln_due_date,null,12400002, NULL,'Inserted from ALM',
--            sysdate,NULL,10200001,curAandL.unln_aandl_code,
--            curAandL.unln_forward_rate,0,0,curAandL.unln_spot_rate);
            varOperation := 'Updating trade reference';
            update trtran002A
              set unln_trade_reference = varReference
              where unln_company_code = numCode
              and unln_effective_date =  datTemp
              and unln_aandl_code = curAandL.unln_aandl_code
              and unln_line_item = 'T';
          End Loop;
      End if;
    End if;

 if  EditType = GConst.SYSCONTRACTSHCEDULE  then
        varOperation := 'Extracting Trade Reference Number';


       -- varTemp := 'CONTRACTBUCKETING/ROW[@NUM="1"]/TradeReference';
        varReference := GConst.fncXMLExtract(xmlTemp,'KeyValues/TradeReference',varReference);


            VarOperation := 'If Alredy data is their then insert and update delete based on requirement';

            varXPath := '//SUBROW';
            nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
            numSub := xmlDom.getLength(nlsTemp);
            varOperation := 'Option Maturities Entering Into Main loop ' || varXPath;

            select CONR_REFERENCE_DATE,conr_base_currency
             into dattemp1,numcode4
             FROM TRTRAN002C
            where  CONR_TRADE_REFERENCE=varReference
            and conr_record_status not in (10200005,10200006);

            select max(drat_effective_date)
              into dattemp1
            from trtran012
            where drat_effective_date <=dattemp1
            and drat_currency_code =numcode4
            and drat_for_currency=30400003
            and drat_record_status not in (10200005,10200006);

            for numSub in 0..xmlDom.getLength(nlsTemp) -1
            Loop
              nodTemp := xmlDom.Item(nlsTemp, numSub);
              --nmpTemp:= xmlDom.getAttributes(nodTemp);

              nmpTemp:= xmlDom.getAttributes(nodTemp);
              nodTemp := xmlDom.Item(nmpTemp, 0);
              numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
              -- numTemp :=
              varTemp := varXPath || '[@SUBNUM="'|| numTemp || '"]/';
              varoperation :='Extracting Data from XML' || varTemp;
              begin
                 varTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'TradeReference',varTemp1, Gconst.TYPENODEPATH);
              exception
               when others then
                  varTemp1:= null;
              end ;

               varoperation :='Extracting Quantity Data from XML' || varTemp;
              numFCY := GConst.fncXMLExtract(xmlTemp,varTemp || 'Quantity',numFCY, Gconst.TYPENODEPATH);
              varoperation :='Extracting Amount Data from XML' || varTemp;
              numFCY1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'Amount',numFCY1, Gconst.TYPENODEPATH);
              varoperation :='Extracting Maturity Data from XML' || varTemp;
              DatTemp := GConst.fncXMLExtract(xmlTemp,varTemp || 'Maturity',DatTemp, Gconst.TYPENODEPATH);

              if numFCY1 !=0 and varTemp1 is null then
                  INSERT INTO TRTRAN002
                      ( TRAD_COMPANY_CODE, TRAD_TRADE_REFERENCE, TRAD_REVERSE_REFERENCE, TRAD_REVERSE_SERIAL,
                        TRAD_IMPORT_EXPORT, TRAD_LOCAL_BANK, TRAD_ENTRY_DATE, TRAD_USER_REFERENCE, TRAD_REFERENCE_DATE,
                        TRAD_BUYER_SELLER, TRAD_TRADE_CURRENCY, TRAD_PRODUCT_CODE, TRAD_PRODUCT_DESCRIPTION,
                        TRAD_TRADE_FCY,  TRAD_TRADE_RATE,  TRAD_TRADE_INR,  TRAD_PERIOD_CODE, TRAD_TRADE_PERIOD,
                        TRAD_TENOR_CODE,  TRAD_TENOR_PERIOD, TRAD_MATURITY_FROM, TRAD_MATURITY_DATE,
                         TRAD_PROCESS_COMPLETE,  TRAD_COMPLETE_DATE,
                        Trad_Create_Date, Trad_Entry_Detail,Trad_Record_Status, Trad_Product_Quantity,
                        TRAD_PRODUCT_RATE,  TRAD_TERM,TRAD_CONTRACT_NO,TRAD_PRODUCT_CATEGORY,TRAD_SUBPRODUCT_CODE
                      )
                 SELECT CONR_COMPANY_CODE,'BCCL/PURCON/' || PKGGLOBALMETHODS.fncGenerateSerial(10900015,0),
                        CONR_TRADE_REFERENCE,1,25900077,CONR_LOCAL_BANK,
                        datWorkdate,CONR_USER_REFERENCE,CONR_REFERENCE_DATE,CONR_BUYER_SELLER,
                        CONR_BASE_CURRENCY,24200001,null,NumFCY1,
                        (pkgforexprocess.fncGetRate(CONR_BASE_CURRENCY,30400003,dattemp1,25300001,0,
                        Last_Day(DatTemp),0) + ((pkgforexprocess.fncGetRate(CONR_BASE_CURRENCY,30400003,
                          dattemp1,
                      --  (SELECT MAX(DRAT_EFFECTIVE_DATE) FROM TRTRAN012),
                          25300001,0,
                        Last_Day(DatTemp),0)/100)*0.5))
                        ,NumFCY1*pkgforexprocess.fncGetRate(CONR_BASE_CURRENCY,30400003,dattemp1,25300001,0,
                        Last_Day(DatTemp),0),
                        25500001,1,25500001,1,trunc(DatTemp,'month'),last_day(DatTemp),
                        12400002,Null,Sysdate,Null,10200001,
                        Numfcy,Conr_Product_Rate,Conr_Payment_Terms,Conr_User_Reference,Conr_Product_Category,
                        CONR_SUB_CATEGORY
                   FROM TRTRAN002C
                   where  CONR_TRADE_REFERENCE=varReference;
              elsif numFCY1=0 and varTemp1 is not null then
                  update trtran002 set trad_record_Status =10200006
                   where trad_trade_reference=varTemp1;
              elsif varTemp1 is not null then
                 update trtran002 set trad_trade_fcy=numFCY1,trad_product_quantity=numFCY, trad_record_Status =10200003
                   where trad_trade_reference=varTemp1;
              end if;
            end loop;

                 varOperation := 'Checking whether Already Data has been inserted' || varReference;
        begin
           select Count(*) into
                 numCode
            from TRTRAN002
          where TRAD_TRADE_REFERENCE=varReference
           and trad_record_status not in (10200005,10200006);
        exception
          when others then
            numCode:=0;
        end;
        varOperation := 'if the scheduling goes beyond 12 months then taking 12 months as max';
         if  add_months(datWorkdate,12) <= DatTemp then
            DatTemp:=  add_months(datWorkdate,12);
         end if;

        varOperation := 'Insert Purchase Contract details into tradedeal register' ||  '-' || dattemp1;
        if numCode=0 then
            INSERT INTO TRTRAN002
                  ( TRAD_COMPANY_CODE, TRAD_TRADE_REFERENCE, TRAD_REVERSE_REFERENCE, TRAD_REVERSE_SERIAL,
                    TRAD_IMPORT_EXPORT, TRAD_LOCAL_BANK, TRAD_ENTRY_DATE, TRAD_USER_REFERENCE,
                    TRAD_REFERENCE_DATE,TRAD_BUYER_SELLER, TRAD_TRADE_CURRENCY, TRAD_PRODUCT_CODE,
                    TRAD_PRODUCT_DESCRIPTION,TRAD_TRADE_FCY,  TRAD_TRADE_RATE,  TRAD_TRADE_INR,
                    TRAD_PERIOD_CODE, TRAD_TRADE_PERIOD,TRAD_TENOR_CODE,  TRAD_TENOR_PERIOD,
                    TRAD_MATURITY_FROM, TRAD_MATURITY_DATE, TRAD_PROCESS_COMPLETE,
                    Trad_Complete_Date, Trad_Create_Date, Trad_Entry_Detail,Trad_Record_Status,
                    Trad_Product_Quantity,Trad_Product_Rate,Trad_Term,Trad_Contract_No,
                    TRAD_PRODUCT_CATEGORY,TRAD_SUBPRODUCT_CODE
                  )
              SELECT
                    CONR_COMPANY_CODE, CONR_TRADE_REFERENCE,'.',1,
                    25900086,CONR_LOCAL_BANK,datWorkdate,CONR_USER_REFERENCE,
                    CONR_REFERENCE_DATE,CONR_BUYER_SELLER,CONR_BASE_CURRENCY,24200001,
                    null,CONR_BASE_AMOUNT,
                   (pkgforexprocess.fncGetRate(CONR_BASE_CURRENCY,30400003,dattemp1,25300001,0,
                        dattemp1,0) )
                        ,CONR_BASE_AMOUNT*pkgforexprocess.fncGetRate(CONR_BASE_CURRENCY,30400003,
                       dattemp1,
                        25300001,0,
                        dattemp1,0),
                    25500001,1,25500001,1,
                    CONR_REFERENCE_DATE,DatTemp,12400001,
                    datWorkdate,sysdate,null,10200001,
                    CONR_TOTAL_QUANTITY,CONR_PRODUCT_RATE,CONR_PAYMENT_TERMS,CONR_USER_REFERENCE,
                    Conr_Product_Category,CONR_SUB_CATEGORY
              FROM TRTRAN002C where CONR_TRADE_REFERENCE=varReference;

              varOperation := 'Insert Reversal of Sales Order';
               insert into trtran003
                           (BREL_COMPANY_CODE, BREL_TRADE_REFERENCE,BREL_REVERSE_SERIAL,
                            BREL_ENTRY_DATE,BREL_USER_REFERENCE,
                            BREL_REFERENCE_DATE, BREL_REVERSAL_TYPE, BREL_REVERSAL_FCY,
                            BREL_REVERSAL_RATE, BREL_REVERSAL_INR,
                            BREL_PERIOD_CODE, BREL_TRADE_PERIOD,
                            BREL_MATURITY_FROM, BREL_MATURITY_DATE,
                            BREL_CREATE_DATE, BREL_ENTRY_DETAIL,
                            BREL_RECORD_STATUS, BREL_LOCAL_BANK, BREL_REVERSE_REFERENCE)
                SELECT
                      CONR_COMPANY_CODE, CONR_TRADE_REFERENCE,1,
                      datWorkdate,CONR_USER_REFERENCE,
                      CONR_REFERENCE_DATE,25800054,CONR_BASE_AMOUNT,
                      pkgforexprocess.fncGetRate(CONR_BASE_CURRENCY,30400003,
                      dattemp1,
                      25300001,0,DatTemp,0),
                     (CONR_BASE_AMOUNT*
                     pkgforexprocess.fncGetRate(CONR_BASE_CURRENCY,30400003,
                   --  CONR_REFERENCE_DATE,
                    dattemp1,
                     25300001,0, dattemp1,0)),
                       23400001,1,
                     DatTemp,DatTemp,
                       sysdate,null,
                       10200001,CONR_LOCAL_BANK,null
                FROM TRTRAN002C where CONR_TRADE_REFERENCE=varReference;

--         varOperation := 'Insert Monthly Bucketing information';
--            INSERT INTO TRTRAN002
--                      ( TRAD_COMPANY_CODE, TRAD_TRADE_REFERENCE, TRAD_REVERSE_REFERENCE, TRAD_REVERSE_SERIAL,
--                        TRAD_IMPORT_EXPORT, TRAD_LOCAL_BANK, TRAD_ENTRY_DATE, TRAD_USER_REFERENCE, TRAD_REFERENCE_DATE,
--                        TRAD_BUYER_SELLER, TRAD_TRADE_CURRENCY, TRAD_PRODUCT_CODE, TRAD_PRODUCT_DESCRIPTION,
--                        TRAD_TRADE_FCY,  TRAD_TRADE_RATE,  TRAD_TRADE_INR,  TRAD_PERIOD_CODE, TRAD_TRADE_PERIOD,
--                        TRAD_TENOR_CODE,  TRAD_TENOR_PERIOD, TRAD_MATURITY_FROM, TRAD_MATURITY_DATE,
--                        TRAD_MATURITY_MONTH, TRAD_PROCESS_COMPLETE,  TRAD_COMPLETE_DATE,
--                        TRAD_CREATE_DATE, TRAD_ENTRY_DETAIL,TRAD_RECORD_STATUS, TRAD_PRODUCT_QUANTITY,
--                        TRAD_PRODUCT_RATE,  TRAD_TERM
--                      )
--
--               SELECT CONR_COMPANY_CODE,'IMPINV/TOI/' || PKGGLOBALMETHODS.fncGenerateSerial(10900015,0),
--                      CONR_TRADE_REFERENCE,Months,25900086,CONR_LOCAL_BANK,
--                      CONR_REFERENCE_DATE,CONR_USER_REFERENCE,CONR_REFERENCE_DATE,CONR_BUYER_SELLER,
--                      CONR_BASE_CURRENCY,24200001,null,Amount,
--                      (pkgforexprocess.fncGetRate(CONR_BASE_CURRENCY,30400003,datWorkDate,25300001,0,
--                      add_months(CONR_REFERENCE_DATE,Months),0) +
--                      ((pkgforexprocess.fncGetRate(CONR_BASE_CURRENCY,30400003,datWorkDate,25300001,0,
--                      add_months(CONR_REFERENCE_DATE,Months),0)/100)*2))
--
--                      ,Amount*pkgforexprocess.fncGetRate(CONR_BASE_CURRENCY,30400003,CONR_REFERENCE_DATE,25300001,0,
--                      add_months(CONR_REFERENCE_DATE,Months),0),
--                      25500001,1,25500001,1,trunc(add_months(CONR_REFERENCE_DATE,Months),'month'),last_day(add_months(CONR_REFERENCE_DATE,Months)),
--                      last_day(add_months(CONR_REFERENCE_DATE,Months)),12400002,null,sysdate,null,10200001,
--                      QTY,CONR_PRODUCT_RATE,CONR_PAYMENT_TERMS
--                 FROM TRTRAN002C inner join
--              (select * from (select CONR_TRADE_REFERENCE TradeReference ,CONR_MONTH1_QTY QTY ,nvl(CONR_MONTH1_AMOUNT,0) Amount ,0 Months
--               from TRTRAN002C where CONR_TRADE_REFERENCE=varReference
--               union
--               select CONR_TRADE_REFERENCE TradeReference ,CONR_MONTH2_QTY QTY ,nvl(CONR_MONTH2_AMOUNT,0) Amount ,1 months
--               from TRTRAN002C where CONR_TRADE_REFERENCE=varReference
--               union
--               select CONR_TRADE_REFERENCE TradeReference ,CONR_MONTH3_QTY QTY ,nvl(CONR_MONTH3_AMOUNT,0) Amount , 2 months
--               from TRTRAN002C where CONR_TRADE_REFERENCE=varReference
--               union
--               select CONR_TRADE_REFERENCE TradeReference ,CONR_MONTH4_QTY QTY ,nvl(CONR_MONTH4_AMOUNT,0) Amount , 3 Months
--               from TRTRAN002C where CONR_TRADE_REFERENCE=varReference
--               union
--               select CONR_TRADE_REFERENCE TradeReference ,CONR_MONTH5_QTY QTY ,nvl(CONR_MONTH5_AMOUNT,0) Amount , 4 months
--               from TRTRAN002C where CONR_TRADE_REFERENCE=varReference
--               union
--               select CONR_TRADE_REFERENCE TradeReference ,CONR_MONTH6_QTY QTY,nvl(CONR_MONTH6_AMOUNT,0) Amount , 5 months
--               from TRTRAN002C where CONR_TRADE_REFERENCE=varReference
--               union
--               select CONR_TRADE_REFERENCE TradeReference ,CONR_MONTH7_QTY QTY,nvl(CONR_MONTH7_AMOUNT,0) Amount , 6 months
--               from TRTRAN002C where CONR_TRADE_REFERENCE=varReference
--               union
--               select CONR_TRADE_REFERENCE TradeReference ,CONR_MONTH8_QTY QTY,nvl(CONR_MONTH8_AMOUNT,0) Amount, 7 Months
--               from TRTRAN002C where CONR_TRADE_REFERENCE=varReference
--               union
--               select CONR_TRADE_REFERENCE TradeReference ,CONR_MONTH9_QTY QTY ,nvl(CONR_MONTH9_AMOUNT,0) Amount , 8 Months
--               from TRTRAN002C where CONR_TRADE_REFERENCE=varReference
--               union
--                select CONR_TRADE_REFERENCE TradeReference , CONR_MONTH10_QTY QTY,nvl(CONR_MONTH10_AMOUNT,0) Amount, 9 Months
--               from TRTRAN002C where CONR_TRADE_REFERENCE=varReference
--               union
--               select CONR_TRADE_REFERENCE TradeReference ,CONR_MONTH11_QTY QTY,nvl(CONR_MONTH11_AMOUNT,0) Amount, 10 Months
--               from TRTRAN002C where CONR_TRADE_REFERENCE=varReference
--               union
--                select CONR_TRADE_REFERENCE TradeReference , CONR_MONTH12_QTY QTY,nvl(CONR_MONTH12_AMOUNT,0) Amount , 11 Months
--               from TRTRAN002C where CONR_TRADE_REFERENCE=varReference) a
--               where Amount !=0) SplitCon
--              on CONR_TRADE_REFERENCE=  TradeReference
--              where CONR_TRADE_REFERENCE=varReference;
        end if;

 end if;

 if edittype = GConst.SYSTDSRATE then
    varOperation := 'inserting TDS Rates to the table trdepo04';
          varXPath := '//TDSRATES/SUBROW';
          nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
          varOperation := 'Update Reverse Reference ' || varXPath;
          numcode:=  GConst.fncXMLExtract(xmlTemp, 'DEPO_TDS_PLAN', numcode);

          if numAction = GConst.EDITSAVE then
          delete from TRMASTER407A where DETR_TDS_PLAN=numcode;
          end if;

          for numTemp in 1..xmlDom.getLength(nlsTemp)
          Loop
              varTemp := varXPath || '[@NUM="' || numTemp || '"]/TDSInterestAmt';
              varoperation :='Extracting Data from XML' || varTemp;
              numFcy := GConst.fncXMLExtract(xmlTemp, varTemp, numFcy, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/TDSInterestUPTo';
              varoperation :='Extracting Data from XML' || varTemp;
              numFcy1 := GConst.fncXMLExtract(xmlTemp, varTemp, numFcy1, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/TDSRATES';
              varoperation :='Extracting Data from XML' || varTemp;
              numFcy2 := GConst.fncXMLExtract(xmlTemp, varTemp, numFcy2, Gconst.TYPENODEPATH);

               varTemp := varXPath || '[@NUM="' || numTemp || '"]/TDSSurCharg';
              varoperation :='Extracting Data from XML' || varTemp;
              numFcy3 := GConst.fncXMLExtract(xmlTemp, varTemp, numFcy3, Gconst.TYPENODEPATH);

              varoperation :='Inserting Data into TDS rate plan table';
              if numAction = GConst.ADDSAVE then
                  insert into TRMASTER407A (DETR_TDS_PLAN,DETR_SERIAL_NUMBER,DETR_INT_AMOUNTFROM,
                                          DETR_INT_AMOUNTUPTO,DETR_TDS_RATE,DETR_TDS_SURCHARGERATE,
                                          DETR_RECORD_STATUS,DETR_CREATE_DATE,DETR_ADD_DATE)
                                    Values (numcode,numTemp,numFcy,
                                            numFcy1,numFcy2,numFcy3,
                                            10200001,sysdate,sysdate);
              elsif numAction = GConst.EDITSAVE then
                  insert into TRMASTER407A (DETR_TDS_PLAN,DETR_SERIAL_NUMBER,DETR_INT_AMOUNTFROM,
                                          DETR_INT_AMOUNTUPTO,DETR_TDS_RATE,DETR_TDS_SURCHARGERATE,
                                          DETR_RECORD_STATUS,DETR_CREATE_DATE,DETR_ADD_DATE)
                                    Values (numcode,numTemp,numFcy,
                                            numFcy1,numFcy2,numFcy3,
                                            10200004,sysdate,sysdate);

--                     update  TRDEPO004A set  DETR_SERIAL_NUMBER=numTemp,DETR_INT_AMOUNTFROM=numFcy,
--                              DETR_INT_AMOUNTUPTO=numFcy1,DETR_TDS_RATE=numFcy2,DETR_TDS_SURCHARGERATE=numFcy3,
--                              DETR_RECORD_STATUS=10200004,DETR_ADD_DATE=sysdate
--                      where DETR_TDS_PLAN=numcode;

              elsif numAction = GConst.DELETESAVE then
                   update  TRMASTER407A set DETR_RECORD_STATUS= 10200006
                    where DETR_TDS_PLAN=numcode;
              end if;
          end loop;
 end if;
 if edittype = GConst.SYSFDRATE then
    varOperation := 'Inserting FD Rates to the table TRMASTER408';
     if numAction = GConst.EDITSAVE then
          varXPath := '//FDINTERESTRATE/ROW';
          nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
          varOperation := 'Insert Reverse Reference ' || varXPath;
          numcode:=  GConst.fncXMLExtract(xmlTemp, 'KeyValues/CompanyCode', numcode);
          numcode1:=  GConst.fncXMLExtract(xmlTemp, 'KeyValues/CounterParty', numcode1);
          numcode2:=  GConst.fncXMLExtract(xmlTemp, 'KeyValues/CurrencyCode', numcode2);
          datTemp:=  GConst.fncXMLExtract(xmlTemp, 'KeyValues/EffectiveDate', datTemp);

             delete from TRMASTER408
              where TINT_COMPANY_CODE=numcode
                and TINT_COUNTER_PARTY=numcode1
                and TINT_CURRENCY_CODE=numcode2
                and TINT_EFFECTIVE_DATE=datTemp;
          numSerial:=1;
          for numTemp in 1..xmlDom.getLength(nlsTemp)
          Loop
              varTemp := varXPath || '[@NUM="' || numTemp || '"]/TINT_FROM_AMOUNT';
              varoperation :='Extracting Data from XML' || varTemp;
              numFcy := GConst.fncXMLExtract(xmlTemp, varTemp, numFcy, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/TINT_TO_AMOUNT';
              varoperation :='Extracting Data from XML' || varTemp;
              numFcy1 := GConst.fncXMLExtract(xmlTemp, varTemp, numFcy1, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/TINT_INT_RATE';
              varoperation :='Extracting Data from XML' || varTemp;
              numFcy2 := GConst.fncXMLExtract(xmlTemp, varTemp, numFcy2, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/TINT_NEGOTIATED_RATE';
              varoperation :='Extracting Data from XML' || varTemp;
              numFcy3 := GConst.fncXMLExtract(xmlTemp, varTemp, numFcy3, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/TINT_NEGOTIATED_RATE';
              varoperation :='Extracting Data from XML' || varTemp;
              numFcy4 := GConst.fncXMLExtract(xmlTemp, varTemp, numFcy4, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/TINT_PERIOD_UPTO';
              varoperation :='Extracting Data from XML' || varTemp;
              numFcy5 := GConst.fncXMLExtract(xmlTemp, varTemp, numFcy5, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/TINT_PERIOD_IN';
              varoperation :='Extracting Data from XML' || varTemp;
              numFcy6 := GConst.fncXMLExtract(xmlTemp, varTemp, numFcy6, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/TINT_SERIAL_NUMBER';
              varoperation :='Extracting Data from XML' || varTemp;
              numSerial := GConst.fncXMLExtract(xmlTemp, varTemp, numSerial, Gconst.TYPENODEPATH);

              varoperation :='Inserting Data into FD rate plan table';
                  insert into TRMASTER408 (TINT_COMPANY_CODE,TINT_COUNTER_PARTY,TINT_CURRENCY_CODE,
                                          TINT_EFFECTIVE_DATE,TINT_FROM_AMOUNT,TINT_TO_AMOUNT,
                                          TINT_INT_RATE,TINT_NEGOTIATED_RATE,TINT_PRECLOSURE_RATE,
                                          TINT_PERIOD_UPTO,TINT_PERIOD_IN,TINT_RECORD_STATUS,TINT_SERIAL_NUMBER,
                                          TINT_LOCATION_CODE,TINT_CREATE_DATE,TINT_ADD_DATE)
                                    Values (numcode,numcode1,numcode2,
                                            datTemp,numFcy,numFcy1,
                                            numFcy2,numFcy3,numFcy4,
                                            numFcy5,numFcy6,10200004,numSerial,
                                            30299999,sysdate,sysdate);
          end loop;
          numSerial:=numSerial+1;

          elsif   numAction = GConst.DELETESAVE then
            varXPath := '//FDINTERESTRATE/ROW';
            nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
            varOperation := 'Update Reverse Reference ' || varXPath;
            numcode:=  GConst.fncXMLExtract(xmlTemp, 'CompanyCode', numcode);
            numcode1:=  GConst.fncXMLExtract(xmlTemp, 'CounterParty', numcode1);
            numcode2:=  GConst.fncXMLExtract(xmlTemp, 'CurrencyCode', numcode2);
            datTemp:=  GConst.fncXMLExtract(xmlTemp, 'EffectiveDate', datTemp);

             update  TRMASTER408 set TINT_RECORD_STATUS= 10200006
                        where TINT_COMPANY_CODE=numcode
                        and TINT_COUNTER_PARTY=numcode1
                        and TINT_CURRENCY_CODE=numcode2
                        and TINT_EFFECTIVE_DATE=datTemp;
         end if;
 end if;
--  if edittype = GConst.SYSFDRATE then
--    varOperation := 'inserting FD Rates to the table trdepo005';
--          varXPath := '//FDRATES/SUBROW';
--          nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--          varOperation := 'Update Reverse Reference ' || varXPath;
--          numcode:=  GConst.fncXMLExtract(xmlTemp, 'DEPO_TDS_PLAN', numcode);
--
--          if numAction = GConst.EDITSAVE then
--         -- delete from TRDEPO004A where DETR_TDS_PLAN=numcode;
--          end if;
--
--          for numTemp in 1..xmlDom.getLength(nlsTemp)
--          Loop
--              varTemp := varXPath || '[@NUM="' || numTemp || '"]/FDFromAmt';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numFcy := GConst.fncXMLExtract(xmlTemp, varTemp, numFcy, Gconst.TYPENODEPATH);
--
--              varTemp := varXPath || '[@NUM="' || numTemp || '"]/FDToAmt';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numFcy1 := GConst.fncXMLExtract(xmlTemp, varTemp, numFcy1, Gconst.TYPENODEPATH);
--
--              varTemp := varXPath || '[@NUM="' || numTemp || '"]/FDRate';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numFcy2 := GConst.fncXMLExtract(xmlTemp, varTemp, numFcy2, Gconst.TYPENODEPATH);
--
--
--              varoperation :='Inserting Data into FD rate plan table';
--              if numAction = GConst.ADDSAVE then
--                  insert into TRDEPO004A (DETR_TDS_PLAN,DETR_SERIAL_NUMBER,DETR_INT_AMOUNTFROM,
--                                          DETR_INT_AMOUNTUPTO,DETR_TDS_RATE,DETR_TDS_SURCHARGERATE,
--                                          DETR_RECORD_STATUS,DETR_CREATE_DATE,DETR_ADD_DATE)
--                                    Values (numcode,numTemp,numFcy,
--                                            numFcy1,numFcy2,numFcy3,
--                                            10200001,sysdate,sysdate);
--              elsif numAction = GConst.EDITSAVE then
--                  insert into TRDEPO004A (DETR_TDS_PLAN,DETR_SERIAL_NUMBER,DETR_INT_AMOUNTFROM,
--                                          DETR_INT_AMOUNTUPTO,DETR_TDS_RATE,DETR_TDS_SURCHARGERATE,
--                                          DETR_RECORD_STATUS,DETR_CREATE_DATE,DETR_ADD_DATE)
--                                    Values (numcode,numTemp,numFcy,
--                                            numFcy1,numFcy2,numFcy3,
--                                            10200004,sysdate,sysdate);
--
----                     update  TRDEPO004A set  DETR_SERIAL_NUMBER=numTemp,DETR_INT_AMOUNTFROM=numFcy,
----                              DETR_INT_AMOUNTUPTO=numFcy1,DETR_TDS_RATE=numFcy2,DETR_TDS_SURCHARGERATE=numFcy3,
----                              DETR_RECORD_STATUS=10200004,DETR_ADD_DATE=sysdate
----                      where DETR_TDS_PLAN=numcode;
--
--              elsif numAction = GConst.DELETESAVE then
--                   update  TRDEPO004A set DETR_RECORD_STATUS= 10200006
--                    where DETR_TDS_PLAN=numcode;
--              end if;
--          end loop;
-- end if;

--if  EditType = GConst.SYSCONTRACTUPLOAD  then
--
--        varOperation := 'inserting scheduled monthwise contracts Trades into Traderegister  ';
--
--          merge into  trtran002 trd
--     using
--       (select tradereference,qty,amount,duedt,months,
--              pkgForexProcess.fncGetRate(Conr_base_currency,30400003,conr_reference_date,25300001,0,conr_reference_date) SptRt,
--              pkgForexProcess.fncGetRate(Conr_base_currency,30400003,conr_reference_date,25300001,0,duedt) FwdRt,
--              conr_local_bank,conr_buyer_seller,CONR_BASE_CURRENCY,conr_product_category,cont_reference_date referenceDate,
--              conr_sub_category,conr_company_code  CompanyCode
--       from (select cont_user_reference tradereference ,cont_month1_qty qty ,nvl(cont_month1_amount,0) amount,
--              fncGetCalendarDate(last_day(add_months(cont_execute_date,0))) duedt,1 months,
--              cont_reference_date
--        from trtran002d
--        where cont_month1_amount > 0
--        and cont_record_status =10200001
--        union
--        select cont_user_reference tradereference ,cont_month2_qty qty ,nvl(cont_month2_amount,0) amount,
--              fncGetCalendarDate(last_day(add_months(cont_execute_date,1))) duedt,2 months,
--              cont_reference_date
--        from  trtran002d
--        where cont_month2_amount > 0
--        and cont_record_status =10200001
--        union
--        select cont_user_reference tradereference ,cont_month3_qty qty ,nvl(cont_month3_amount,0) amount,
--               fncGetCalendarDate(last_day(add_months(cont_execute_date,2))) duedt,3 months,
--               cont_reference_date
--        from trtran002d
--        where cont_month3_amount > 0
--        and cont_record_status =10200001
--        union
--        select cont_user_reference tradereference ,cont_month4_qty qty ,nvl(cont_month4_amount,0) amount,
--               to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,3)))) duedt, 4 months,
--               cont_reference_date
--        from trtran002d
--        where cont_month4_amount > 0
--        union
--        select cont_user_reference tradereference ,cont_month5_qty qty ,nvl(CONT_MONTH5_AMOUNT,0) amount,
--              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,4)))) duedt,5 months,
--              cont_reference_date
--        from trtran002d
--        where CONT_MONTH5_AMOUNT > 0
--        and cont_record_status =10200001
--        union
--        select cont_user_reference tradereference ,CONT_MONTH6_QTY qty ,nvl(cont_month6_amount,0) amount,
--               to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,5)))) duedt,6 months,
--               cont_reference_date
--        from trtran002d
--        where cont_month6_amount > 0
--        and cont_record_status =10200001
--        union
--        select cont_user_reference tradereference ,cont_month7_qty qty ,nvl(cont_month7_amount,0) amount,
--               to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,6)))) duedt,7 months,
--               cont_reference_date
--        from trtran002d
--        where cont_month7_amount > 0
--        and cont_record_status =10200001
--        union
--        select cont_user_reference tradereference ,cont_month8_qty qty ,nvl(cont_month8_amount,0) amount,
--               to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,7)))) duedt,8 months,
--               cont_reference_date
--        from trtran002d
--        where cont_month8_amount > 0
--        and cont_record_status =10200001
--        union
--        select cont_user_reference tradereference ,cont_month9_qty qty ,nvl(cont_month9_amount,0) amount,
--              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,8)))) duedt,9 months, cont_reference_date
--        from trtran002d
--        where cont_month9_amount > 0
--        and cont_record_status =10200001
--        union
--        select cont_user_reference tradereference ,cont_month10_qty qty ,nvl(cont_month10_amount,0) amount,
--               to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,9)))) duedt,10 months,
--               cont_reference_date
--        from trtran002d
--        where cont_month10_amount > 0
--        and cont_record_status =10200001
--        union
--        select cont_user_reference tradereference ,cont_month11_qty qty ,nvl(cont_month11_amount,0) amount,
--              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,10)))) duedt,11 months,
--              cont_reference_date
--        from trtran002d
--        where cont_month11_amount > 0
--        and cont_record_status =10200001
--        union
--        select cont_user_reference tradereference ,cont_month12_qty qty ,nvl(cont_month12_amount,0) amount,
--              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,11)))) duedt,12 months,
--              cont_reference_date
--        from trtran002d
--        where cont_month12_amount > 0
--        and cont_record_status =10200001) a left outer join
--        trtran002c on a.tradereference= conr_user_reference)Cdata
--      on (CData.TradeReference= trd.Trad_contract_no
--        and to_char(CData.duedt,'MON-YYYY')= to_char(trd.trad_maturity_date,'MON-YYYY'))
--      when matched then
--           update set trd.trad_trade_fcy=Cdata.amount,
--               trd.trad_product_quantity=Cdata.qty,
--               trd.trad_record_Status=10200003,
--               trd.trad_trade_remarks='Amount has been moved from ' || trd.trad_trade_fcy ||  ' to ' || Cdata.amount
--               where trad_contract_no = Cdata.tradereference
--               and to_char(trad_maturity_date,'MON-YYYY') = to_char(Cdata.duedt,'MON-YYYY')
--               and trad_record_status not in (10200005,10200006)
--      when not matched then
--          insert (trd.trad_company_code, trd.trad_trade_reference, trd.trad_reverse_reference, trd.trad_reverse_serial,
--              trd.trad_import_export, trd.trad_local_bank,trd.trad_entry_date,
--              trd.trad_user_reference, trd.trad_reference_date,
--              trd.trad_buyer_seller, trd.trad_trade_currency, trd.trad_product_code, trd.trad_product_description,
--              trd.trad_trade_fcy, trd.trad_trade_rate, trd.trad_trade_inr, trd.trad_period_code, trd.trad_trade_period,
--              trd.trad_tenor_code, trd.trad_tenor_period, trd.trad_maturity_from, trd.trad_maturity_date,
--              trd.trad_maturity_month, trd.trad_process_complete, trd.trad_complete_date,
--              trd.trad_create_date,trd.trad_record_status, trd.trad_product_quantity,
--              trd.trad_product_rate, trd.trad_subproduct_code,trd.trad_product_category,
--              trd.trad_contract_no, trd.trad_trade_remarks, trd.trad_spot_rate, trd.trad_forward_rate,
--              trd.trad_margin_rate, trd.trad_final_rate,trad_add_date)
--           values( Cdata.CompanyCode,
--               'BCCL/PUR/' || PKGGLOBALMETHODS.fncGenerateSerial(10900015,0), null,1,
--              25900077,Cdata.conr_local_bank,Cdata.ReferenceDate,Cdata.tradereference,Cdata.ReferenceDate,
--              Cdata.conr_buyer_seller,Cdata.CONR_BASE_CURRENCY,Cdata.conr_product_category,null,
----              amount,
----              conr_sub_category,
-- --             24200001,'NewPrint',
--              round(Cdata.amount,2), round((Cdata.fwdrt) + (((Cdata.fwdrt)/100) *2),2) ,
--              round(Cdata.amount* (Cdata.fwdrt) + (((Cdata.fwdrt)/100) *2),2),
--              25500001, null,null,
--              null, Cdata.duedt,Cdata.duedt,Cdata.duedt,12400002,null,
--              sysdate,  10200001,round(Cdata.qty,0),
--              round((Cdata.amount /Cdata.qty),2),Cdata.conr_sub_category,Cdata.conr_product_category,
--              Cdata.tradereference,'New Scheduled entry',round( Cdata.sptrt,2),
--              round(Cdata.fwdrt-Cdata.sptrt,2), 0, round(Cdata.fwdrt + (Cdata.fwdrt * 0.02),2),sysdate);
--
--
----             insert into trtran002
----              (trad_company_code, trad_trade_reference, trad_reverse_reference, trad_reverse_serial,
----              trad_import_export, trad_local_bank, trad_entry_date, trad_user_reference, trad_reference_date,
----              trad_buyer_seller, trad_trade_currency, trad_product_code, trad_product_description,
----              trad_trade_fcy, trad_trade_rate, trad_trade_inr, trad_period_code, trad_trade_period,
----              trad_tenor_code, trad_tenor_period, trad_maturity_from, trad_maturity_date,
----              trad_maturity_month, trad_process_complete, trad_complete_date,
----              trad_create_date, trad_entry_detail,trad_record_status, trad_product_quantity,
----              trad_product_rate, trad_term,trad_subproduct_code,trad_product_category,
----              trad_contract_no, trad_trade_remarks, trad_spot_rate, trad_forward_rate,
----              trad_margin_rate, trad_final_rate)
----
----              select
----              cont_company_code,
----              --'BCCL/PURORD/' || lpad(seqdealno.nextval - 400, 4, '0') || '/13-14',
----               'BCCL/PURCON/' || PKGGLOBALMETHODS.fncGenerateSerial(10900015,0),
----              cont_user_reference,
----              months,
----              25900077,
----              --cont_local_bank,
----              (select conr_local_bank from trtran002C where conr_user_reference=cont_user_reference),
----              cont_reference_date,
----              cont_user_reference,
----              cont_reference_date,
----              --cont_buyer_seller,
----              (select conr_buyer_seller from trtran002C where conr_user_reference=cont_user_reference),
----              --cont_base_currency,
----              (select CONR_BASE_CURRENCY from trtran002C where conr_user_reference=cont_user_reference),
----              --CONR_BASE_CURRENCY
----              24200001,'NewPrint',
----              amount,
----              fwdrt + (fwdrt * 0.02),
----              round(amount * fwdrt + (fwdrt * 0.02)),
----              25500001,
----              duedt - cont_reference_date,
----              25500001,
----              duedt-cont_reference_date,
----              cont_reference_date,
----              duedt, duedt,
----              12400002,
----              null, sysdate, null, 10200001,
----              qty,
----              round(amount /qty,2),
----              null,
----              33800001,
----              33300001,
----              cont_user_reference,
----              decode(months, 1, 'Shifted from March to April', 'Month ' || Months),
----              sptrt, fwdrt - sptrt, fwdrt *0.02, fwdrt + (fwdrt * 0.02)
----              from trtran002D
----              inner join
----              ( select cont_user_reference tradereference ,cont_month1_qty qty ,nvl(cont_month1_amount,0) amount,
----                      fncGetCalendarDate(last_day(add_months(cont_execute_date,0))) duedt,1 months,
----                      pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----                      pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,
----                      fncGetCalendarDate(last_day(add_months(cont_execute_date,0)))) FwdRt
----              from trtran002d
----              where cont_month1_amount > 0
----              and cont_record_status =10200001
----              union
----              select cont_user_reference tradereference ,cont_month2_qty qty ,nvl(cont_month2_amount,0) amount,
----              fncGetCalendarDate(last_day(add_months(cont_execute_date,1))) duedt,2 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,
----              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,1))))) FwdRt
----              from  trtran002d
----              where cont_month2_amount > 0
----              and cont_record_status =10200001
----              union
----              select cont_user_reference tradereference ,cont_month3_qty qty ,nvl(cont_month3_amount,0) amount,
----              fncGetCalendarDate(last_day(add_months(cont_execute_date,2))) duedt,3 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,2))))) FwdRt
----              from trtran002d
----              where cont_month3_amount > 0
----              and cont_record_status =10200001
----              union
----              select cont_user_reference tradereference ,cont_month4_qty qty ,nvl(cont_month4_amount,0) amount,
----              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,3)))) duedt, 4 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,3))))) FwdRt
----              from trtran002d
----              where cont_month4_amount > 0
----              union
----              select cont_user_reference tradereference ,cont_month5_qty qty ,nvl(CONT_MONTH5_AMOUNT,0) amount,
----              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,4)))) duedt,5 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,4))))) FwdRt
----              from trtran002d
----              where CONT_MONTH5_AMOUNT > 0
----              and cont_record_status =10200001
----              union
----              select cont_user_reference tradereference ,CONT_MONTH6_QTY qty ,nvl(cont_month6_amount,0) amount,
----              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,5)))) duedt,6 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,5))))) FwdRt
----              from trtran002d
----              where cont_month6_amount > 0
----              and cont_record_status =10200001
----              union
----              select cont_user_reference tradereference ,cont_month7_qty qty ,nvl(cont_month7_amount,0) amount,
----              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,6)))) duedt,7 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,6))))) FwdRt
----              from trtran002d
----              where cont_month7_amount > 0
----              and cont_record_status =10200001
----              union
----              select cont_user_reference tradereference ,cont_month8_qty qty ,nvl(cont_month8_amount,0) amount,
----              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,7)))) duedt,8 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,7))))) FwdRt
----              from trtran002d
----              where cont_month8_amount > 0
----              and cont_record_status =10200001
----              union
----              select cont_user_reference tradereference ,cont_month9_qty qty ,nvl(cont_month9_amount,0) amount,
----              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,8)))) duedt,9 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,8))))) FwdRt
----              from trtran002d
----              where cont_month9_amount > 0
----              and cont_record_status =10200001
----              union
----              select cont_user_reference tradereference ,cont_month10_qty qty ,nvl(cont_month10_amount,0) amount,
----              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,9)))) duedt,10 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,9))))) FwdRt
----              from trtran002d
----              where cont_month10_amount > 0
----              and cont_record_status =10200001
----              union
----              select cont_user_reference tradereference ,cont_month11_qty qty ,nvl(cont_month11_amount,0) amount,
----              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,10)))) duedt,11 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,10))))) FwdRt
----              from trtran002d
----              where cont_month11_amount > 0
----              and cont_record_status =10200001
----              union
----              select cont_user_reference tradereference ,cont_month12_qty qty ,nvl(cont_month12_amount,0) amount,
----              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,11)))) duedt,12 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,11))))) FwdRt
----              from trtran002d
----              where cont_month12_amount > 0
----              and cont_record_status =10200001
----              ) a
----              on CONT_USER_REFERENCE = tradereference
----
----              where not exists (select 'X' from  trtran002
----              where trad_contract_no = CONT_USER_REFERENCE
----               and to_char(trad_maturity_date,'MON-YYYY') =to_char(duedt,'MON-YYYY'));
----
----
----
----         varOperation := 'Updating trade already present in register according to maturity month';
----               for curContract in
----
----            ( select amount, qty ,10200003,tradereference,duedt from trtran002D inner join
----              ( select cont_user_reference tradereference ,cont_month1_qty qty ,nvl(cont_month1_amount,0) amount,
----                      fncGetCalendarDate(last_day(add_months(cont_execute_date,0))) duedt,1 months,
----                      pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----                      pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,
----                      fncGetCalendarDate(last_day(add_months(cont_execute_date,0)))) FwdRt
----              from trtran002d
----              where cont_month1_amount > 0
----              and cont_record_status =10200001
----              union
----              select cont_user_reference tradereference ,cont_month2_qty qty ,nvl(cont_month2_amount,0) amount,
----              fncGetCalendarDate(last_day(add_months(cont_execute_date,1))) duedt,2 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,
----              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,1))))) FwdRt
----              from  trtran002d
----              where cont_month2_amount > 0
----              and cont_record_status =10200001
----              union
----              select cont_user_reference tradereference ,cont_month3_qty qty ,nvl(cont_month3_amount,0) amount,
----              fncGetCalendarDate(last_day(add_months(cont_execute_date,2))) duedt,3 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,2))))) FwdRt
----              from trtran002d
----              where cont_month3_amount > 0
----              and cont_record_status =10200001
----              union
----              select cont_user_reference tradereference ,cont_month4_qty qty ,nvl(cont_month4_amount,0) amount,
----              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,3)))) duedt, 4 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,3))))) FwdRt
----              from trtran002d
----              where cont_month4_amount > 0
----              union
----              select cont_user_reference tradereference ,cont_month5_qty qty ,nvl(CONT_MONTH5_AMOUNT,0) amount,
----              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,4)))) duedt,5 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,4))))) FwdRt
----              from trtran002d
----              where CONT_MONTH5_AMOUNT > 0
----              and cont_record_status =10200001
----              union
----              select cont_user_reference tradereference ,CONT_MONTH6_QTY qty ,nvl(cont_month6_amount,0) amount,
----              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,5)))) duedt,6 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,5))))) FwdRt
----              from trtran002d
----              where cont_month6_amount > 0
----              and cont_record_status =10200001
----              union
----              select cont_user_reference tradereference ,cont_month7_qty qty ,nvl(cont_month7_amount,0) amount,
----              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,6)))) duedt,7 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,6))))) FwdRt
----              from trtran002d
----              where cont_month7_amount > 0
----              and cont_record_status =10200001
----              union
----              select cont_user_reference tradereference ,cont_month8_qty qty ,nvl(cont_month8_amount,0) amount,
----              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,7)))) duedt,8 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,7))))) FwdRt
----              from trtran002d
----              where cont_month8_amount > 0
----              and cont_record_status =10200001
----              union
----              select cont_user_reference tradereference ,cont_month9_qty qty ,nvl(cont_month9_amount,0) amount,
----              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,8)))) duedt,9 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,8))))) FwdRt
----              from trtran002d
----              where cont_month9_amount > 0
----              and cont_record_status =10200001
----              union
----              select cont_user_reference tradereference ,cont_month10_qty qty ,nvl(cont_month10_amount,0) amount,
----              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,9)))) duedt,10 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,9))))) FwdRt
----              from trtran002d
----              where cont_month10_amount > 0
----              and cont_record_status =10200001
----              union
----              select cont_user_reference tradereference ,cont_month11_qty qty ,nvl(cont_month11_amount,0) amount,
----              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,10)))) duedt,11 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,10))))) FwdRt
----              from trtran002d
----              where cont_month11_amount > 0
----              and cont_record_status =10200001
----              union
----              select cont_user_reference tradereference ,cont_month12_qty qty ,nvl(cont_month12_amount,0) amount,
----              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,11)))) duedt,12 months,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,cont_reference_date) SptRt,
----              pkgForexProcess.fncGetRate(30400004,30400003,cont_reference_date,25300001,0,to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,11))))) FwdRt
----              from trtran002d
----              where cont_month12_amount > 0
----              and cont_record_status =10200001
----              ) a
----              on CONT_USER_REFERENCE = tradereference
----               where exists (select 'X' from  trtran002
----              where trad_contract_no = CONT_USER_REFERENCE
----               and to_char(trad_maturity_date,'MON-YYYY') =to_char(duedt,'MON-YYYY') and trad_record_status=10200001)
----               and cont_record_status =10200001)
----
----        loop
----            varOperation := 'Updating scheduled trades into trade register';
----
----              update trtran002
----               set trad_trade_fcy=curContract.amount,
----               trad_product_quantity=curContract.qty,
----               trad_record_Status=10200003
----               where trad_contract_no = curContract.tradereference
----               and to_char(trad_maturity_date,'MON-YYYY') = to_char(curContract.duedt,'MON-YYYY')
----               and trad_record_status=10200001;
----
----          End Loop;
--      End if;


    --- modified by prateek on 07th Jan 2015    -----   for Bank and Get Payment details
if  EditType = GConst.SYSCONTRACTUPLOAD  then  
    
        varOperation := 'inserting scheduled monthwise contracts Trades into Traderegister  ';
   
--   begin     
     varOperation:= 'Select the execute date from trtran002d';
      select distinct(cont_execute_date)
         into datTemp 
         from trtran002d 
        where cont_record_status=10200001;


       varOperation:= 'update or Insert data into trtran002';

    merge into  trtran002 trd         
     using 
       (select tradereference,qty,amount,duedt,months, 
              nvl(pkgForexProcess.fncGetRate(Conr_base_currency,30400003,conr_reference_date,25300001,0,conr_reference_date),0) SptRt,
              nvl(pkgForexProcess.fncGetRate(Conr_base_currency,30400003,conr_reference_date,25300001,0,duedt),0) FwdRt,
              localbank,conr_buyer_seller,CONR_BASE_CURRENCY,conr_product_category,cont_reference_date referenceDate,
              conr_sub_category,conr_company_code  CompanyCode
       from (select cont_user_reference tradereference ,cont_month1_qty qty ,(pkgfunctions.fncgetpayment(cont_execute_date,cont_user_reference)+nvl(cont_month1_amount,0)) amount,
              fncGetCalendarDate(last_day(add_months(cont_execute_date,0))) duedt,1 months,
              cont_reference_date,pkgfunctions.fncGetLocalbankCode(cont_local_bank) localbank
        from trtran002d 
        where cont_month1_amount >= 0
        and cont_record_status =10200001
        and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
        union 
        select cont_user_reference tradereference ,cont_month2_qty qty ,nvl(cont_month2_amount,0) amount,
              fncGetCalendarDate(last_day(add_months(cont_execute_date,1))) duedt,2 months,
              cont_reference_date,pkgfunctions.fncGetLocalbankCode(cont_local_bank) localbank
        from  trtran002d  
        where cont_month2_amount >= 0
        and cont_record_status =10200001
        and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
        union 
        select cont_user_reference tradereference ,cont_month3_qty qty ,nvl(cont_month3_amount,0) amount,
               fncGetCalendarDate(last_day(add_months(cont_execute_date,2))) duedt,3 months,
               cont_reference_date,pkgfunctions.fncGetLocalbankCode(cont_local_bank) localbank
        from trtran002d 
        where cont_month3_amount >= 0
        and cont_record_status =10200001
         and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
        union 
        select cont_user_reference tradereference ,cont_month4_qty qty ,nvl(cont_month4_amount,0) amount,
               to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,3)))) duedt, 4 months, 
               cont_reference_date,pkgfunctions.fncGetLocalbankCode(cont_local_bank) localbank
        from trtran002d 
        where cont_month4_amount >= 0
        and cont_record_status =10200001
        and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
        union 
        select cont_user_reference tradereference ,cont_month5_qty qty ,nvl(CONT_MONTH5_AMOUNT,0) amount,
              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,4)))) duedt,5 months,
              cont_reference_date,pkgfunctions.fncGetLocalbankCode(cont_local_bank) localbank
        from trtran002d 
        where CONT_MONTH5_AMOUNT >= 0
        and cont_record_status =10200001
         and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
        union 
        select cont_user_reference tradereference ,CONT_MONTH6_QTY qty ,nvl(cont_month6_amount,0) amount,
               to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,5)))) duedt,6 months,
               cont_reference_date,pkgfunctions.fncGetLocalbankCode(cont_local_bank) localbank  
        from trtran002d 
        where cont_month6_amount >= 0
        and cont_record_status =10200001
        and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
        union 
        select cont_user_reference tradereference ,cont_month7_qty qty ,nvl(cont_month7_amount,0) amount,
               to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,6)))) duedt,7 months,
               cont_reference_date,pkgfunctions.fncGetLocalbankCode(cont_local_bank) localbank 
        from trtran002d 
        where cont_month7_amount >= 0
        and cont_record_status =10200001
        and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
        union 
        select cont_user_reference tradereference ,cont_month8_qty qty ,nvl(cont_month8_amount,0) amount,
               to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,7)))) duedt,8 months,
               cont_reference_date,pkgfunctions.fncGetLocalbankCode(cont_local_bank) localbank 
        from trtran002d 
        where cont_month8_amount >= 0
        and cont_record_status =10200001
        and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
        union 
        select cont_user_reference tradereference ,cont_month9_qty qty ,nvl(cont_month9_amount,0) amount,
              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,8)))) duedt,9 months, cont_reference_date,
              pkgfunctions.fncGetLocalbankCode(cont_local_bank) localbank
        from trtran002d 
        where cont_month9_amount >= 0
        and cont_record_status =10200001
        and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
        union 
        select cont_user_reference tradereference ,cont_month10_qty qty ,nvl(cont_month10_amount,0) amount,
               to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,9)))) duedt,10 months,
               cont_reference_date,pkgfunctions.fncGetLocalbankCode(cont_local_bank) localbank   
        from trtran002d 
        where cont_month10_amount >= 0
        and cont_record_status =10200001
        and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
        union 
        select cont_user_reference tradereference ,cont_month11_qty qty ,nvl(cont_month11_amount,0) amount,
              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,10)))) duedt,11 months,
              cont_reference_date,pkgfunctions.fncGetLocalbankCode(cont_local_bank) localbank
        from trtran002d 
        where cont_month11_amount >= 0
        and cont_record_status =10200001
        and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
        union 
        select cont_user_reference tradereference ,cont_month12_qty qty ,nvl(cont_month12_amount,0) amount,
              to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,11)))) duedt,12 months,
              cont_reference_date,pkgfunctions.fncGetLocalbankCode(cont_local_bank) localbank 
        from trtran002d 
        where cont_month12_amount >= 0
        and cont_record_status =10200001
        and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
        ) a inner join 
        trtran002c on a.tradereference= conr_user_reference)Cdata
      on (CData.TradeReference= trd.Trad_contract_no
        and to_char(CData.duedt,'MON-YYYY')= to_char(trd.trad_maturity_date,'MON-YYYY')
        and trd.trad_record_status not in  (10200005,10200006)
        and trd.trad_import_export=25900077
        and not exists
        (select 'X'  from trtran003 
          where brel_trade_reference =trd.trad_trade_reference
           and brel_record_status not in (10200005,10200006)))
      when matched then 
           update set trd.trad_trade_fcy=Cdata.amount,
               trd.trad_product_quantity=Cdata.qty,
               trd.TRAD_LOCAL_BANK=Cdata.localbank,
               trd.trad_trade_inr= Cdata.amount * trd.trad_trade_rate,
              -- trd.trad_record_Status=10200003,
               trd.trad_process_complete =12400002,
               trd.trad_complete_date = null,
               trd.trad_trade_remarks= ' Updated on ' || sysdate ||  ' Amount has been moved from ' || trd.trad_trade_fcy ||  ' to ' || Cdata.amount,    
               trd.trad_add_date = sysdate
               where trad_contract_no = Cdata.tradereference
               and to_char(trad_maturity_date,'MON-YYYY') = to_char(Cdata.duedt,'MON-YYYY') 
--               and ((trd.trad_process_complete =10200002) or
--                    (trd.trad_complete_date >= Cdata.duedt))
      when not matched then 
          insert (trd.trad_company_code, trd.trad_trade_reference, trd.trad_reverse_reference, trd.trad_reverse_serial,
              trd.trad_import_export, trd.trad_local_bank,trd.trad_entry_date, 
              trd.trad_user_reference, trd.trad_reference_date,
              trd.trad_buyer_seller, trd.trad_trade_currency, trd.trad_product_code, trd.trad_product_description,
              trd.trad_trade_fcy, trd.trad_trade_rate, trd.trad_trade_inr, trd.trad_period_code, trd.trad_trade_period,
              trd.trad_tenor_code, trd.trad_tenor_period, trd.trad_maturity_from, trd.trad_maturity_date,
              trd.trad_process_complete, trd.trad_complete_date,
              trd.trad_create_date,trd.trad_record_status, trd.trad_product_quantity,
              trd.trad_product_rate, trd.trad_subproduct_code,trd.trad_product_category, 
              trd.trad_contract_no, trd.trad_trade_remarks, trd.trad_spot_rate, trd.trad_forward_rate,
              trd.trad_margin_rate, trad_add_date)
           values( Cdata.CompanyCode,
               'BCCL/PUR/' || PKGGLOBALMETHODS.fncGenerateSerial(10900015,0), null,1,
              25900077,Cdata.localbank,Cdata.ReferenceDate,Cdata.tradereference,Cdata.ReferenceDate,
              Cdata.conr_buyer_seller,Cdata.CONR_BASE_CURRENCY,Cdata.conr_product_category,null,
--              amount, 
--              conr_sub_category,
 --             24200001,'NewPrint',
              round(Cdata.amount,2), round((Cdata.fwdrt) + (((Cdata.fwdrt)/100) *2),2) ,
              round(Cdata.amount* (Cdata.fwdrt) + (((Cdata.fwdrt)/100) *2),2),
              25500001, null,null,
              null, Cdata.duedt,Cdata.duedt,12400002,null,
              sysdate,  10200001,round(Cdata.qty,0), 
              round((Cdata.amount /decode(Cdata.qty,0,1,Cdata.qty)),2),Cdata.conr_sub_category,Cdata.conr_product_category,
              Cdata.tradereference,'New Scheduled entry',round( Cdata.sptrt,2),
              round(Cdata.fwdrt-Cdata.sptrt,2), 0,sysdate);
--    exception 
--       when others then 
--           varOperation:= 'Error ';
--     end;  
       varOperation:= 'Select the execute date from trtran002d';
      select distinct(cont_execute_date)
         into datTemp 
         from trtran002d 
        where cont_record_status=10200001;
        
      varOperation:= 'update the process complete for the records whihc are having process complete yes';
        update trtran002 set trad_process_complete= 12400001, 
                 trad_complete_date = datTemp , trad_trade_remarks= trad_trade_remarks || ' Updated on ' || sysdate ||  ' Process Complete Received from the Excel',
                 trad_add_date=sysdate
        where trad_contract_no in(select CONT_USER_REFERENCE from trtran002d 
                                   where cont_process_complete ='Yes'
                                   and cont_record_status =10200001)
        and trad_import_export=25900077
        and trad_process_complete=12400002
        and TRAD_RECORD_STATUS not in (10200005,10200006);
        
           varOperation:= 'update the process complete for the records which are having process complete yes in 002c';
        update trtran002c set conr_record_Status=10200006,
                              conr_cont_remarks ='User marked as process complete on ' || sysdate() 
        where conr_user_reference in(select CONT_USER_REFERENCE from trtran002d 
                                   where cont_process_complete ='Yes'
                                   and cont_record_status =10200001);
        
      varoperation := 'Update the record status to delete where it does not have any schedule and process updated';
      
    --'update the process complete for the records does not have any schedule with new upload and which is exist earlier';
      varOperation:= 'update the process complete for the records does not have any schedule';
        update trtran002 set trad_process_complete= 12400001, 
                 trad_complete_date = datTemp , trad_trade_remarks= trad_trade_remarks || ' Updated on ' || sysdate ||  ' removed from excel schedule',
                 trad_add_date= sysdate
        where exists
           (select 'X' from 
            (select * from  (select trad_contract_no,trad_trade_reference,trad_maturity_date
             from trtran002 t
            where t.Trad_contract_no in (select cont_user_reference tradereference
                                                from trtran002d where cont_month1_amount > 0
                                                and cont_record_status =10200001)
             and t.trad_record_status not in  (10200005,10200006)
             and t.trad_import_export=25900077
             and t.trad_process_complete =12400002) T
            left outer join 
                  (select cont_user_reference tradereference ,cont_month1_qty qty ,nvl(cont_month1_amount,0) amount,
                    fncGetCalendarDate(last_day(add_months(cont_execute_date,0))) duedt,1 months,
                    cont_reference_date
              from trtran002d 
              where cont_month1_amount >= 0
              and cont_record_status =10200001
               and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
              union 
              select cont_user_reference tradereference ,cont_month2_qty qty ,nvl(cont_month2_amount,0) amount,
                    fncGetCalendarDate(last_day(add_months(cont_execute_date,1))) duedt,2 months,
                    cont_reference_date
              from  trtran002d  
              where cont_month2_amount >= 0
              and cont_record_status =10200001
              and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
              union 
              select cont_user_reference tradereference ,cont_month3_qty qty ,nvl(cont_month3_amount,0) amount,
                     fncGetCalendarDate(last_day(add_months(cont_execute_date,2))) duedt,3 months,
                     cont_reference_date
              from trtran002d 
              where cont_month3_amount >= 0
              and cont_record_status =10200001
              and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
              union 
              select cont_user_reference tradereference ,cont_month4_qty qty ,nvl(cont_month4_amount,0) amount,
                     to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,3)))) duedt, 4 months, 
                     cont_reference_date
              from trtran002d 
              where cont_month4_amount >= 0
               and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
              union 
              select cont_user_reference tradereference ,cont_month5_qty qty ,nvl(CONT_MONTH5_AMOUNT,0) amount,
                    to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,4)))) duedt,5 months,
                    cont_reference_date
              from trtran002d 
              where CONT_MONTH5_AMOUNT >= 0
              and cont_record_status =10200001
              and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
              union 
              select cont_user_reference tradereference ,CONT_MONTH6_QTY qty ,nvl(cont_month6_amount,0) amount,
                     to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,5)))) duedt,6 months,
                     cont_reference_date  
              from trtran002d 
              where cont_month6_amount >= 0
              and cont_record_status =10200001
              and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
              union 
              select cont_user_reference tradereference ,cont_month7_qty qty ,nvl(cont_month7_amount,0) amount,
                     to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,6)))) duedt,7 months,
                     cont_reference_date 
              from trtran002d 
              where cont_month7_amount >= 0
              and cont_record_status =10200001
              and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
              union 
              select cont_user_reference tradereference ,cont_month8_qty qty ,nvl(cont_month8_amount,0) amount,
                     to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,7)))) duedt,8 months,
                     cont_reference_date 
              from trtran002d 
              where cont_month8_amount >= 0
              and cont_record_status =10200001
               and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
              union 
              select cont_user_reference tradereference ,cont_month9_qty qty ,nvl(cont_month9_amount,0) amount,
                    to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,8)))) duedt,9 months, cont_reference_date
              from trtran002d 
              where cont_month9_amount >= 0
              and cont_record_status =10200001
              and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
              union 
              select cont_user_reference tradereference ,cont_month10_qty qty ,nvl(cont_month10_amount,0) amount,
                     to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,9)))) duedt,10 months,
                     cont_reference_date   
              from trtran002d 
              where cont_month10_amount >= 0
              and cont_record_status =10200001
              and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
              union 
              select cont_user_reference tradereference ,cont_month11_qty qty ,nvl(cont_month11_amount,0) amount,
                    to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,10)))) duedt,11 months,
                    cont_reference_date
              from trtran002d 
              where cont_month11_amount >= 0
              and cont_record_status =10200001
              and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
              union 
              select cont_user_reference tradereference ,cont_month12_qty qty ,nvl(cont_month12_amount,0) amount,
                    to_date(fncGetCalendarDate(last_day(add_months(cont_execute_date,11)))) duedt,12 months,
                    cont_reference_date 
              from trtran002d 
              where cont_month12_amount >= 0
              and cont_record_status =10200001
              and ((cont_process_complete is null) or (upper(cont_process_complete)='NO'))
                          )sc
          on sc.tradereference= t.trad_contract_no
          and to_char(sc.duedt,'MON-YYYY') != to_char(t.trad_maturity_date,'MON-YYYY')
          where sc.tradereference is null) Sc
       where sc.tradereference= trad_contract_no
        and to_char(sc.duedt,'MON-YYYY') = to_char(trad_maturity_date,'MON-YYYY'))
      and trad_import_export=25900077
        and trad_process_complete=12400002
        and TRAD_RECORD_STATUS in (10200001);
               
     varOperation:= 'update record status once complete the process ';   
    
     update trtran002d set CONT_RECORD_STATUS=10200006;

      End if;


---- end here ------

 
 

--Ishwarachandra ---
    if EditType = GConst.SYSCANCELDEAL then
      varReference := GConst.fncXMLExtract(xmlTemp, 'CDEL_DEAL_NUMBER', varTemp);
      numSerial := GConst.fncXMLExtract(xmlTemp, 'CDEL_DEAL_SERIAL', numFCY2);
      varOperation := 'Updating Cancelled Deals';

      if numAction = GConst.ADDSAVE then
      nlsTemp    := xslProcessor.selectNodes(nodFinal,'//DealUnLink/ROWD[@NUM]');
      varXPath   := '//DealUnLink/ROWD[@NUM="';
        FOR numSub IN 0..xmlDom.getLength(nlsTemp) -1
        LOOP
          nodTemp       := xmlDom.item(nlsTemp, numSub);
          nmpTemp       := xmlDom.getAttributes(nodTemp);
          nodTemp1      := xmlDom.item(nmpTemp, 0);
          numTemp       := to_number(xmlDom.getNodeValue(nodTemp1));
          varTemp       := varXPath || numTemp || '"]/DealSerial';
          numCode1      := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp       := varXPath || numTemp || '"]/TradeReference';
          varReference1 := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp       := varXPath || numTemp || '"]/LinkDealNumber';
          varReference  := GConst.fncGetNodeValue(nodFinal, varTemp);
          
          varTemp       := varXPath || numTemp || '"]/HedgedAmount';
          numFCY        := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          
          varTemp       := varXPath || numTemp || '"]/CompanyCode';
          numCompany    := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          
--          varTemp       := varXPath || numTemp || '"]/LinkDate';
--          datTemp       := GConst.fncGetNodeValue(nodFinal, varTemp);
          SELECT deal_exchange_rate
          INTO numRate1
          FROM trtran001
          WHERE deal_deal_number = varReference;
          
          IF numFCY <= 0 THEN
            UPDATE trtran004
            SET hedg_record_status     = GConst.STATUSDELETED
            WHERE hedg_trade_reference = varReference1
            AND hedg_deal_number       = varReference
            AND hedg_deal_serial       = numCode1;
          ELSE
            UPDATE trtran004
            SET hedg_record_status     = GConst.STATUSDELETED
            WHERE hedg_trade_reference = varReference1
            AND hedg_deal_number       = varReference
            AND hedg_deal_serial       = numCode1;
            
            INSERT
            INTO trtran004
              ( hedg_company_code,    hedg_trade_reference,    hedg_deal_number,    hedg_deal_serial,    hedg_hedged_fcy,
                hedg_other_fcy,    hedg_hedged_inr,    hedg_create_date,    hedg_entry_detail,    hedg_record_status,
                hedg_hedging_with,    hedg_multiple_currency,    hedg_linked_date,  hedg_location_code  )
              VALUES
              (
                numCompany,    varReference1,    varReference, numCode1+1,    numFCY,
                0,numFCY * numRate1,    sysdate,    NULL,    10200001,
                32200001,    12400002,    datWorkDate, 30299999 );
    
          END IF;
        END LOOP;      
      
          numError := fncCompleteUtilization(varReference, GConst.UTILHEDGEDEAL,
                        datWorkDate);
--        update trtran001
--          set deal_record_status = GConst.STATUSPOSTCANCEL,
--          deal_process_complete = GConst.OPTIONYES,
--          deal_complete_date = datWorkDate
--          where deal_deal_number = varReference
--          and deal_serial_number = numSerial;
      elsif numAction = GConst.EDITSAVE then
        numError := fncCompleteUtilization(varReference, GConst.UTILHEDGEDEAL,
                           datWorkDate);
      elsif numAction = GConst.DELETESAVE then
--        update trtran001
--          set deal_record_status = GConst.STATUSENTRY,
--          deal_process_complete = GConst.OPTIONNO,
--          deal_complete_date = NULL
--          where deal_deal_number = varReference
--          and deal_serial_number = numSerial;
        numError := fncCompleteUtilization(varReference, GConst.UTILHEDGEDEAL,
                           datWorkDate);
      
      End if;

    End if;

    if EditType = GConst.SYSLOANCONNECT then
      numCompany := GConst.fncXMLExtract(xmlTemp, 'FCLN_COMPANY_CODE', numCompany);
      varReference := GConst.fncXMLExtract(xmlTemp, 'FCLN_LOAN_NUMBER', varTemp);
      numRate := GConst.fncXMLExtract(xmlTemp, 'FCLN_CONVERSION_RATE', varTemp);

      if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
        nlsTemp := xslProcessor.selectNodes(nodFinal,'//EXIMPDETAIL/ReturnFields/ROWD[@NUM]');
        varXPath := '//EXIMPDETAIL/ReturnFields/ROWD[@NUM="';
        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.item(nlsTemp, numSub);
          nmpTemp := xmlDom.getAttributes(nodTemp);
          nodTemp1 := xmlDom.item(nmpTemp, 0);
          numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
          varTemp := varXPath || numTemp || '"]/RecordStatus';
          numStatus := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/TradeReference';
          varReference1 := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp := varXPath || numTemp || '"]/MerchantFcy';
          numFcy := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
            varTemp := varXPath || numTemp || '"]/ReverseNow';
          numFCY1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--          varTemp := varXPath || numTemp || '"]/MerchantRate';
--          numRate := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--          varTemp := varXPath || numTemp || '"]/MerchantInr';
--          numInr := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          numInr := Round(numFcy * numRate);
          -- updated by ramya on 19-apr-10to update record status in fcy loan edit mode
          if numStatus = GConst.LOTMODIFIED then
            varOperation := 'Deleting record of Loan Connect';
            update trtran010                                    -- Updated From Cygnet
              --set trln_record_status = GConst.STATUSDELETED
                set loln_record_status = GConst.STATUSUPDATED
              Where Loln_Company_Code = Numcompany
              and loln_loan_number = varReference;              -- End Updated Cygnet
              numStatus := GConst.LOTNEW;
          end if;
          if numStatus = GConst.LOTNEW then
            varOperation := 'Inserting record to Loan Connect';
            insert into trtran010(loln_company_code, loln_loan_number,                     -- Updated From cygnet
              loln_serial_number, loln_trade_reference, loln_adjusted_date,
              Loln_Adjusted_Fcy, Loln_Adjusted_Rate, Loln_Adjusted_Inr,
              loln_create_date, loln_entry_detail, loln_record_status)                     -- End Updated Cygnet
              values(numCompany, varReference, (select nvl(max(trln_serial_number),0)+1
                                                  from trtran007
                                                 where trln_trade_reference = varReference1
                                                   and trln_loan_number = varReference), varReference1,
              datWorkDate, numFCY1, numRate, numInr,
              sysdate, null, GConst.STATUSENTRY);
                 --RAMYA UPDATES on  23-ape-10 for fcy loan linking
                varOperation := 'Inserting Into Order Reveral Table TRTRAN003 Reverse the Orders';
--Updated From Cygnet
--                varOperation := 'Inserting Into Order Reveral Table TRTRAN003 Reverse the Orders';
--                  insert into trtran003(brel_company_code,brel_trade_reference,
--                              brel_reverse_serial,brel_entry_date,brel_reference_date,
--                              brel_reversal_type,brel_reversal_fcy,brel_reversal_rate,
--                              brel_reversal_inr,brel_period_code,brel_trade_period,
--                              brel_create_date,brel_record_status)
--                              values(numCompany,varReference1,(select nvl(max(brel_reverse_serial),0)+1
--                 from trtran003
--                 where brel_trade_reference=varReference1),datworkdate,datworkdate,
--              Gconst.TRADEPAYMENTS,numFCY1, numRate, numInr,0,0,datworkdate,Gconst.STATUSENTRY);

--            numError := fncCompleteUtilization(varReference1, GConst.UTILEXPORTS,
--                          datWorkDate);
---End Updated Cygnet
-- Since amounts are adjusted in full, there is no need for edit cluase here
          elsif numStatus = GConst.LOTDELETED then
            varOperation := 'Deleting record of Loan Connect';
            update trtran010                                        -- Updated From Cygnet
              set loln_record_status = GConst.STATUSDELETED
              where loln_company_code = numCompany
              And Loln_Loan_Number = Varreference
              and loln_trade_reference = varReference1;            -- End Update
          End if;

        End Loop;

      elsif numAction in (GConst.DELETESAVE, GConst.CONFIRMSAVE) then
        varOperation := 'Processing for Delete / Confirm';
        select decode(numAction,
          GConst.DELETESAVE, GConst.STATUSDELETED,
          GConst.CONFIRMSAVE,GConst.STATUSAUTHORIZED)
          into numCode
          from dual;
   -- Updated From  Cygnet
        update trtran010
          set loln_record_status = numCode
          where loln_company_code = numCompany
          And Loln_Loan_Number = Varreference;
   --End
      End if;

    End if;

        -- Order - Invoice linking -----------------------------------------------------
        -- Order - Invoice linking -----------------------------------------------------
   if EditType = Gconst.SYSUPDATEORDINVLINK then
      begin
          delete from temp;

          varOperation := 'Updating Reverse Reference Numbers';
          varXPath := '//ORDINVLINKING/ROW';
          nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
          varOperation := 'Update Reverse Reference ' || varXPath;

          for numTemp in 1..xmlDom.getLength(nlsTemp)
          Loop
              varTemp := varXPath || '[@NUM="' || numTemp || '"]/BREL_COMPANY_CODE';
              varoperation :='Extracting Data from XML' || varTemp;
              varReference := GConst.fncXMLExtract(xmlTemp, varTemp, varReference, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/BREL_TRADE_REFERENCE';
              varoperation :='Extracting Data from XML' || varTemp;
              varReference1 := GConst.fncXMLExtract(xmlTemp, varTemp, varReference1, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/BREL_USER_REFERENCE';
              varoperation :='Extracting Data from XML' || varTemp;
              varTemp1 := GConst.fncXMLExtract(xmlTemp, varTemp, varTemp1, Gconst.TYPENODEPATH);

              if numAction = GConst.ADDSAVE then
                 update trtran002
                    set TRAD_REVERSE_REFERENCE = varReference1
                  where TRAD_COMPANY_CODE = varReference
                    and TRAD_TRADE_REFERENCE =varTemp1;
              elsif numAction = GConst.DELETESAVE then
                 update trtran002
                    set TRAD_REVERSE_REFERENCE = null
                  where TRAD_COMPANY_CODE = varReference1
                    and TRAD_TRADE_REFERENCE = varTemp1;
              end if;
          end loop;
      end;
   end if;

 if EditType = Gconst.SYSDELETEFUTUREDATA then
      begin
          delete from temp;
         
          VAROPERATION := 'Deleting Future Reference Numbers';
        --  varXPath := '//FUTURESDATA/ROW';
           varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
          begin
          varReference := GConst.fncXMLExtract(xmlTemp, 'KeyValues/RefStaNumber', varReference);
        --  nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        --  varOperation := 'Deleting Future Reference Numbers ' || varXPath;
       exception
       WHEN OTHERS THEN
        VARREFERENCE:='';
        end ;
          if numAction = GConst.DELETESAVE then
            
--             update trtran103
--                set intc_record_status =10200006
--                where intc_refsta_number = varReference;     
--              
           UPDATE TRTRAN102 SET INTC_RECORD_STATUS = 10200006
              WHERE INTC_REFSTA_NUMBER=varReference;             
            
            UPDATE  TRTRAN061 SET CFUT_RECORD_STATUS = 10200006  
                WHERE CFUT_DEAL_NUMBER IN (SELECT INTC_DEAL_NUMBER FROM TRTRAN102 WHERE 
                INTC_REFSTA_NUMBER=VARREFERENCE AND INTC_DEAL_NUMBER IS NOT NULL
                AND INTC_CLASSIFICATION_CODE=64000001);
                
             UPDATE  TRTRAN063 SET CFRV_RECORD_STATUS = 10200006  
                WHERE CFRV_DEAL_NUMBER IN (SELECT INTC_DEAL_NUMBER FROM TRTRAN102 WHERE 
                INTC_REFSTA_NUMBER=VARREFERENCE AND INTC_DEAL_NUMBER IS NOT NULL
                AND INTC_CLASSIFICATION_CODE=64000002);
          end if;
          
        
      END;
   end if;


  ---kumar.h 12/05/09  updates for buyers credit--------
    if EditType = GConst.SYSBCRCONNECT then
      numCompany := GConst.fncXMLExtract(xmlTemp, 'BCRD_COMPANY_CODE', numCompany);
      varReference := GConst.fncXMLExtract(xmlTemp, 'BCRD_BUYERS_CREDIT', varTemp);
      numRate := GConst.fncXMLExtract(xmlTemp, 'BCRD_CONVERSION_RATE', varTemp);


      if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
        nlsTemp := xslProcessor.selectNodes(nodFinal,'//EXIMPDETAIL/ReturnFields/ROWD[@NUM]');
        varXPath := '//EXIMPDETAIL/ReturnFields/ROWD[@NUM="';
        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.item(nlsTemp, numSub);
          nmpTemp := xmlDom.getAttributes(nodTemp);
          nodTemp1 := xmlDom.item(nmpTemp, 0);
          numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
          varTemp := varXPath || numTemp || '"]/RecordStatus';
          numStatus := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/TradeReference';
          varReference1 := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp := varXPath || numTemp || '"]/ReverseNow';
          numFcy := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--          varTemp := varXPath || numTemp || '"]/MerchantRate';
--          numRate := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--          varTemp := varXPath || numTemp || '"]/MerchantInr';
--          numInr := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
          numInr := Round(numFcy * numRate);

          if numStatus = GConst.LOTNEW then
            varOperation := 'Inserting record to Loan Connect';
--Updated From cygnet
            insert into trtran010(loln_company_code, loln_loan_number,
              loln_serial_number, loln_trade_reference, loln_adjusted_date,
              loln_adjusted_fcy, loln_adjusted_rate, loln_adjusted_inr,
              loln_create_date, loln_entry_detail, loln_record_status)
              values(numCompany, varReference, 1, varReference1,
              datWorkDate, numFcy, numRate, numInr,
              sysdate, null, GConst.STATUSENTRY);
--End Updated
            insert into trtran007(trln_company_code, trln_loan_number,
              trln_serial_number, trln_trade_reference, trln_adjusted_date,
              trln_adjusted_fcy, trln_adjusted_rate, trln_adjusted_inr,
              trln_create_date, trln_entry_detail, trln_record_status)
              values(numCompany, varReference, 1, varReference1,
              datWorkDate, numFcy, numRate, numInr,
              sysdate, null, GConst.STATUSENTRY);

             Varoperation := 'Inserting Into Order Reveral Table TRTRAN003 Reverse the Orders';
--Updated From cygnet
             select nvl(max(BREL_REVERSE_SERIAL),0) into numcode3 from trtran003 where BREL_TRADE_REFERENCE = varReference1;
             Numcode3 := Numcode3 + 1;
--End Updated
             insert into trtran003 (brel_company_code,brel_trade_reference,
              brel_reverse_serial,brel_entry_date,brel_reference_date,
              brel_reversal_type,brel_reversal_fcy,brel_reversal_rate,
              brel_reversal_inr,brel_period_code,brel_trade_period,
              Brel_Create_Date,Brel_Record_Status)
              values( numCompany,varReference1,numcode3,datworkdate,datworkdate,                    -- Updated From Cygnet
              Gconst.Tradepayments,Numfcy, Numrate, Numinr,0,0,Datworkdate,Gconst.Statusentry);
                             varOperation := 'Inserting Into DEAL linking Table TRTRAN004';
              ---Cheking for Lc linked with deal-----------
  --Updated From cygnet
--              Select Count(Hedg_Trade_Reference) Into Numsub1 From Trtran004 Where Hedg_Trade_Reference = Varreference1
--                  and hedg_record_status not in (10200012,10200006,10200005) group by HEDG_TRADE_REFERENCE;
--              if numSub1 > 0 then
--                insert into trtran004 (HEDG_COMPANY_CODE,HEDG_TRADE_REFERENCE,
--                  HEDG_DEAL_NUMBER,HEDG_DEAL_SERIAL,
--                  HEDG_HEDGED_FCY,HEDG_OTHER_FCY,HEDG_HEDGED_INR,
--                  HEDG_CREATE_DATE,HEDG_ENTRY_DETAIL,HEDG_RECORD_STATUS,
--                  HEDG_HEDGING_WITH,HEDG_MULTIPLE_CURRENCY)
--                  (select HEDG_COMPANY_CODE,varReference,
--                  HEDG_DEAL_NUMBER,HEDG_DEAL_SERIAL,
--                  HEDG_HEDGED_FCY,HEDG_OTHER_FCY,HEDG_HEDGED_INR,
--                  HEDG_CREATE_DATE,HEDG_ENTRY_DETAIL,HEDG_RECORD_STATUS,
--                  HEDG_HEDGING_WITH,HEDG_MULTIPLE_CURRENCY
--                from trtran004 where HEDG_TRADE_REFERENCE = varReference1 and hedg_record_status not in (10200012,10200006,10200005));
--                ---Existing Link Closing---
--                update trtran004 set HEDG_RECORD_STATUS = 10200012 where HEDG_TRADE_REFERENCE = varReference1;
--              End If;
  --End Updated
            numfcy1 := pkgforexprocess.fncGetOutstanding(varReference1,0,GConst.UTILEXPORTS,
                   GConst.AMOUNTFCY, datworkdate);
--Updated From cygnet
            numfcy1 := pkgforexprocess.fncGetOutstanding(varReference1,0,GConst.UTILEXPORTS,
                   GConst.AMOUNTFCY, datworkdate);
             if numfcy1 = 0 then
              update trtran002 set trad_process_complete= Gconst.OptionYES,
                trad_complete_date= datworkdate
                where trad_trade_reference=varReference1;
                --and numfcy1 <=numFcy;
            End If;
--End Updated
-- Since amounts are adjusted in full, there is no need for edit clause here

-- Since amounts are adjusted in full, there is no need for edit cluase here
          elsif numStatus = GConst.LOTDELETED then
            varOperation := 'Deleting record of Loan Connect';
            update trtran007
              set trln_record_status = GConst.STATUSDELETED
              where trln_company_code = numCompany
              and trln_loan_number = varReference
              and trln_trade_reference = varReference1;
             varOperation := 'Deleting record of Reverseing Of Export Order';

             delete from trtran003 where  brel_trade_reference=varReference1;

             update trtran002 set trad_process_complete= Gconst.OptionNo,
               trad_complete_date= null
               where trad_trade_reference=varReference1;
          End if;

        End Loop;

      elsif numAction in (GConst.DELETESAVE, GConst.CONFIRMSAVE) then
        varOperation := 'Processing for Delete / Confirm';
        select decode(numAction,
          GConst.DELETESAVE, GConst.STATUSDELETED,
          GConst.CONFIRMSAVE,GConst.STATUSAUTHORIZED)
          into numCode
          from dual;

        update trtran007
          set trln_record_status = numCode
          where trln_company_code = numCompany
          and trln_loan_number = varReference;
      End if;
      ---adding hedge details to hedgeregister
      if numAction in (GConst.ADDSAVE,GConst.EDITSAVE) then
        varOperation := 'Inserting Hedge Details';
         nlsTemp := xslProcessor.selectNodes(nodFinal,'//HEDGEDETAIL/ReturnFields/ROWD[@NUM]');
         varXPath := '//HEDGEDETAIL/ReturnFields/ROWD[@NUM="';
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
          numSub := xmlDom.getLength(nlsTemp);
         if numSub > 0 and  numAction  in (GConst.EDITSAVE) then
  --      if  numAction  in (GConst.EDITSAVE) then
            delete
            from trtran004
            where hedg_company_code=numCompany
             and  hedg_trade_reference=varReference;
         end if;
              for numSub in 0..xmlDom.getLength(nlsTemp) -1
              Loop
                nodTemp := xmlDom.item(nlsTemp, numSub);
                nmpTemp := xmlDom.getAttributes(nodTemp);
                nodTemp1 := xmlDom.item(nmpTemp, 0);
                numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
                varTemp := varXPath || numTemp || '"]/RecordStatus';
                numStatus := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
                varTemp := varXPath || numTemp || '"]/DealNumber';
                varReference1 := GConst.fncGetNodeValue(nodFinal, varTemp);
                varTemp := varXPath || numTemp || '"]/HedgingAmount';
                numFcy := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
                varTemp := varXPath || numTemp || '"]/ExchangeRate';
                numRate := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
                numInr := Round(numFcy * numRate);
                 insert into trtran004(hedg_company_code, hedg_trade_reference,
                    hedg_deal_number, hedg_deal_serial, hedg_hedged_fcy,
                    hedg_other_fcy, hedg_hedged_inr,
                    hedg_create_date, hedg_entry_detail, hedg_record_status)
                    values(numCompany, varReference,
                    varReference1,1, numFcy,
                    numInr, 0,
                    sysdate, null, GConst.STATUSENTRY);
             End loop;
       elsif numAction in (GConst.DELETESAVE, GConst.CONFIRMSAVE) then
        varOperation := 'Processing for Delete / Confirm';
        if numAction in (GConst.DELETESAVE)then
           delete
           from trtran004
           where hedg_company_code=numCompany
           and  hedg_trade_reference=varReference;
        else
          update trtran004
            set hedg_record_status = gconst.STATUSAUTHORIZED
            where hedg_company_code = numCompany
            and hedg_trade_reference = varReference;
      End if;
    End if;
  End if;
  ---kumar.h 12/05/09  updates for buyers credit--------

   ---kumar.h 12/05/09  updates for purchase order--------
    if EditType = GConst.SYSPURCONNECT then
      numCompany := GConst.fncXMLExtract(xmlTemp, 'TRAD_COMPANY_CODE', numCompany);
      varReference := GConst.fncXMLExtract(xmlTemp, 'TRAD_REVERSE_REFERENCE', varTemp);
    --  numRate := GConst.fncXMLExtract(xmlTemp, 'BCRD_CONVERSION_RATE', varTemp);

      if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
        varOperation := 'Adding record for Bill Realization';
        insert into  ImportRealize(brel_company_code, brel_trade_reference,
            brel_reverse_serial,brel_entry_date,
            brel_user_reference, brel_reference_date,
            brel_reversal_type,brel_reversal_fcy, brel_reversal_rate,
            brel_reversal_inr, brel_period_code, brel_trade_period,
            brel_maturity_from, brel_maturity_date,brel_local_bank,
            brel_create_date, brel_entry_detail, brel_record_status)
            values(numCompany,varReference, 1,
            GConst.fncXMLExtract(xmlTemp, 'TRAD_ENTRY_DATE', datTemp),
            GConst.fncXMLExtract(xmlTemp, 'TRAD_USER_REFERENCE', varTemp),
            GConst.fncXMLExtract(xmlTemp, 'TRAD_REFERENCE_DATE', datTemp),
            25800008,
            GConst.fncXMLExtract(xmlTemp, 'TRAD_TRADE_FCY', numFCY),
            GConst.fncXMLExtract(xmlTemp, 'TRAD_TRADE_RATE', numFCY),
            GConst.fncXMLExtract(xmlTemp, 'TRAD_TRADE_INR', numFCY),
            GConst.fncXMLExtract(xmlTemp, 'TRAD_PERIOD_CODE', numFCY),
            GConst.fncXMLExtract(xmlTemp, 'TRAD_TRADE_PERIOD', numFCY),
            GConst.fncXMLExtract(xmlTemp, 'TRAD_MATURITY_FROM', datTemp),
            GConst.fncXMLExtract(xmlTemp, 'TRAD_MATURITY_DATE', datTemp),
            GConst.fncXMLExtract(xmlTemp, 'TRAD_LOCAL_BANK', numFCY),
            sysdate, null, GConst.STATUSENTRY);

         update trtran002
          set trad_process_complete =  GConst.OPTIONYES, trad_complete_date=datWorkDate
          where trad_company_code = numCompany
          and trad_trade_reference = varReference;

      End if;

    End if;
  ---kumar.h 12/05/09  updates for purchase order--------





    if EditType = GConst.SYSEXPORTADJUST then
      numCode := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_TYPE', numCode);
      varReference := GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_REFERENCE', varTemp);
      numSerial := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', numSerial);

      numFcy := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_FCY', numFcy);
      numRate := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_RATE', numRate);

      if numCode in (Gconst.BILLREALIZE,Gconst.BILLIMPORTREL,
        GConst.BILLEXPORTCANCEL, GConst.BILLIMPORTCANCEL, GConst.BILLLOANCLOSURE) then

        if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
--  The second parameter is just to indicate the utilization should be
--  checked between trtran002 and trtran003 and does not represent
--  the actual reversal type - 23/05/08 - TMM

--            if numRate <> 0 then -- Cash Deal entry
--                PrcCashDealEntry(datWorkDate  ,varReference ,numRate  ,numFcy ,datWorkDate);
--            end if ;

--            numError := fncLoanDeal(RecordDetail, varReference);
--            numError := fncCompleteUtilization(varReference, GConst.UTILEXPORTS,
--                          datWorkDate);
          numError := fncBillSettlement(RecordDetail);
        elsif numAction = GConst.DELETESAVE then
           --              update trtran002
--                set trad_record_status = GConst.STATUSAUTHORIZED
--                where trad_trade_reference = varReference;
--                
---Ishwara chandra update as on 27/03/2015 for deletion of reversal transactios

      if numCode in (GConst.BILLLOANCLOSURE) then
      
                  numError := fncCompleteUtilization(varReference, GConst.UTILBCRLOAN,
                          datWorkDate);
                -- himatsingkatf_prod.pkgTreasury.prcBillSettlement(RecordDetail,0);                          
      
      else
      
      

            numError := fncCompleteUtilization(varReference, GConst.UTILEXPORTS,
                          datWorkDate);
    end if;                          
--                UPDATE trtran002
--                SET Trad_Process_Complete  = GConst.OPTIONNO,
--                  Trad_Complete_Date       = NULL
--                WHERE trad_trade_reference = varReference;
        BEGIN
          FOR cur_in IN
          (SELECT cdel_deal_number,
            deal_deal_type
          FROM trtran006,
            trtran001
          WHERE cdel_trade_reference = varReference
          AND cdel_deal_number       = deal_deal_number
          AND CDEL_TRADE_SERIAL      = numSerial
          )
          LOOP
            UPDATE trtran006
            SET cdel_record_status     = GConst.STATUSDELETED
            WHERE cdel_trade_reference = varReference
            AND Cdel_Deal_Number       = cur_in.cdel_deal_number--varReference1
            AND CDEL_TRADE_SERIAL      = numSerial;
            numError                  := fncCompleteUtilization(cur_in.cdel_deal_number, GConst.UTILHEDGEDEAL, datWorkDate);
            IF cur_in.deal_deal_type   = 25400001 THEN ----For Cash deal
              UPDATE trtran001
              SET deal_record_status = GConst.STATUSDELETED
              WHERE deal_deal_number = cur_in.cdel_deal_number;--varReference1;
              UPDATE trtran004
              SET hedg_record_status     = GConst.STATUSDELETED
              WHERE hedg_trade_reference = varReference
              AND hedg_deal_number       = cur_in.cdel_deal_number;--varReference1;
            ELSE
--              UPDATE trtran001
--              SET deal_process_complete = 12400002,
--                  deal_complete_date = ''
--              WHERE deal_deal_number = cur_in.cdel_deal_number;
              UPDATE trtran004
              SET hedg_record_status     = GConst.STATUSDELETED
              WHERE hedg_trade_reference = varReference
              AND hedg_deal_number       = cur_in.cdel_deal_number
              and HEDG_TRADE_SERIAL = numSerial;--varReference1;
            END IF;
          END LOOP;
        end; 
              
       end if;           
        
      End if;


      if numCode in (Gconst.LOANBCCLOSER) then
        if numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
            numError := fncLoanDeal(RecordDetail, varReference);
            numError := fncCompleteUtilization(varReference, GConst.UTILBCRLOAN,
                          datWorkDate);
        elsif numAction = GConst.DELETESAVE then
             update BuyersCredit
               set bcrd_process_complete=Gconst.OptionNo,
               bcrd_completion_date=null
               where bcrd_buyers_credit= varReference;
        end if;
      end if;
      -- changed by Reddy on 18-05-2009
      if numCode in (Gconst.BILLCOLLECTION,GConst.BILLPURCHASE,GConst.BILLOVERDUE,
            GConst.BILLIMPORTCOL,Gconst.BILLEXPORTORDER,Gconst.BILLIMPORTORDER, Gconst.BILLPURCHASEORDER,gconst.BILLAMENDMENT) then

          select decode(numCode,
              GConst.BILLCOLLECTION, GConst.TRADECOLLECTION,
              GConst.BILLPURCHASE, GConst.TRADEPURCHASED,
              GConst.BILLOVERDUE,  GConst.TRADEOVERDUE,
              GConst.BILLIMPORTCOL, GConst.TRADEIMPORTBILL,
              Gconst.BILLEXPORTORDER,Gconst.TRADERECEIVABLE,
              Gconst.BILLIMPORTORDER ,Gconst.TRADEPAYMENTS,
              Gconst.BILLPURCHASEORDER, Gconst.TRADEPORDER,
              gconst.BILLAMENDMENT ,gconst.BILLAMENDMENT,
              numCode)
              into numCode3
              from Dual;

        if numAction = GConst.ADDSAVE then

--          varOperation := 'Selecting particulars of Trade Reference';
----          select trad_company_code, trad_buyer_seller, trad_trade_currency,
----            trad_product_code, trad_product_description, trad_trade_fcy,
----            trad_import_export
----            into numCompany, numCode, numCode1, numCode2,
----            varTemp, numFcy, numCode4
----            from TradeRegister
----            where trad_trade_reference = varReference;
--
--          varOperation := 'Getting Serial Number';
--          Varreference1 := Pkgreturncursor.Fncgetdescription(Numcode3, Gconst.Pickupshort);
--          varReference1 := varReference1 || '/' || GConst.fncGenerateSerial(GCOnst.SERIALTRADE,numCompany); -- Updated From  Cygnet
--
--          varOperation := 'Adding record for Bill Realization';
--          insert into TradeRegister(trad_company_code, trad_trade_reference,
--            trad_reverse_reference, trad_reverse_serial, trad_import_export,
--            trad_entry_date, trad_user_reference, trad_reference_date,
--            trad_buyer_seller, trad_trade_currency, trad_product_code,
--            trad_product_description, trad_trade_fcy, trad_trade_rate,
--            trad_forward_rate,trad_margin_rate,trad_final_rate,
--            trad_spot_rate,
--            trad_trade_inr, trad_period_code, trad_trade_period,
--            trad_maturity_from, trad_maturity_date, trad_local_bank,
--            trad_subproduct_code,trad_product_category,
--            trad_create_date, trad_entry_detail, trad_record_status, trad_process_complete)
--
--            select trad_company_code, varReference1, trad_trade_reference, numSerial, numCode3,
--                GConst.fncXMLExtract(xmlTemp, 'BREL_ENTRY_DATE', datTemp),
--                GConst.fncXMLExtract(xmlTemp, 'BREL_USER_REFERENCE', varTemp),
--                GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datTemp),
--                trad_buyer_seller, trad_trade_currency, trad_product_code, trad_product_description,
--                GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_FCY', numFCY),
--                trad_trade_rate,trad_forward_rate,trad_margin_rate,trad_final_rate,
--                trad_spot_rate, numFCY* trad_trade_rate,
--                GConst.fncXMLExtract(xmlTemp, 'BREL_PERIOD_CODE', numFCY),
--                GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_PERIOD', numFCY),
--                GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_FROM', datTemp),
--                GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datTemp),
--                GConst.fncXMLExtract(xmlTemp, 'BREL_LOCAL_BANK', numFCY),
--                trad_subproduct_code,trad_product_category,
--                sysdate, null, GConst.STATUSENTRY, GConst.OPTIONNO
--             from trtran002
--             where trad_trade_reference = varReference
--             and trad_record_status not in (10200005,10200006);
--
--
----            values(numCompany, varReference1, varReference, numSerial, numCode3,
----            GConst.fncXMLExtract(xmlTemp, 'BREL_ENTRY_DATE', datTemp),
----            GConst.fncXMLExtract(xmlTemp, 'BREL_USER_REFERENCE', varTemp),
----            GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datTemp),
----            numCode, numCode1, numCode2, varTemp,
----            GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_FCY', numFCY),
----            GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_RATE', numFCY),
----            GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_INR', numFCY),
----            GConst.fncXMLExtract(xmlTemp, 'BREL_PERIOD_CODE', numFCY),
----            GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_PERIOD', numFCY),
----            GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_FROM', datTemp),
----            GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datTemp),
----            GConst.fncXMLExtract(xmlTemp, 'BREL_LOCAL_BANK', numFCY),
----            sysdate, null, GConst.STATUSENTRY, GConst.OPTIONNO);
--
--            --;
----                   select trad_company_code, trad_buyer_seller, trad_trade_currency,
----            trad_product_code, trad_product_description, trad_trade_fcy,
----            trad_import_export
----            into numCompany, numCode, numCode1, numCode2,
----            varTemp, numFcy, numCode4
----            from TradeRegister
----            where trad_trade_reference = varReference;
--
--
--            numError := fncCompleteUtilization(varReference, GConst.UTILEXPORTS,
--                          datWorkDate);
--            numError := fncLoanDeal(RecordDetail, varReference1);
--------Added from Almus Source
          varOperation := 'Selecting particulars of Trade Reference';
          select trad_company_code, trad_buyer_seller, trad_trade_currency, 
            TRAD_PRODUCT_CODE, TRAD_PRODUCT_DESCRIPTION, TRAD_TRADE_FCY,
            trad_import_export,TRAD_REVERSE_SERIAL,trad_trade_reference
            Into Numcompany, Numcode, Numcode1, Numcode2, 
            varTemp, numFcy, numCode4,numSub,varRelease
            FROM TRADEREGISTER
            where trad_trade_reference = varReference;
          
            Varoperation := 'Getting Serial Number';
            Varreference1 := Pkgreturncursor.Fncgetdescription(Numcode3, Gconst.Pickupshort);
            Varreference1 := Varreference1 || '/' ||Gconst.Fncgenerateserial(Gconst.Serialtrade,Numcompany);  
            -- Updated From  Cygnet

          If Numcode3 In(Gconst.Billamendment) Then 
          -- 
            --VARREFERENCE1 := varRelease;
            Numcode3 := Numcode4;
            
            Numsub := Numsub + 1;
            
            Varrelease    := Pkgreturncursor.Fncgetdescription(Numcompany, Gconst.Pickupshort) ;
            Varreference1 := Pkgreturncursor.Fncgetdescription(Numcode3, Gconst.Pickupshort) ;
            Varreference1 := Varreference1 || '/' ||Varrelease|| '/' ||Gconst.Fncgenerateserial(Gconst.Serialtrade,Numcompany);
            DELETE FROM TEMP;
            Insert Into Temp Values(Varreference1,'chandra');
            INSERT INTO TEMP VALUES(varRelease,'chandra2');
            varOperation := 'Amendment details Inserting';
            insert into TradeRegister(trad_company_code, trad_trade_reference,
            trad_reverse_reference, trad_reverse_serial, trad_import_export, 
            trad_entry_date, trad_user_reference, trad_reference_date, 
            trad_buyer_seller, trad_trade_currency, trad_product_code, 
            trad_product_description, trad_trade_fcy, trad_trade_rate, 
            trad_trade_inr, trad_period_code, trad_trade_period,
            trad_maturity_from, trad_maturity_date, trad_local_bank,
            Trad_Create_Date, Trad_Entry_Detail, Trad_Record_Status, Trad_Process_Complete,
            trad_spot_rate,
            trad_forward_rate,trad_margin_rate)
            Values(Numcompany, Varreference1, varReference, Numsub, Numcode3,
            GConst.fncXMLExtract(xmlTemp, 'BREL_ENTRY_DATE', datTemp),
            GConst.fncXMLExtract(xmlTemp, 'BREL_USER_REFERENCE', varTemp),
            GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datTemp),
            numCode, numCode1, numCode2, varTemp,
            GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_FCY', numFCY),
            GConst.fncXMLExtract(xmlTemp, 'TradeRate', numRate),
            GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_INR', numFCY),
            GConst.fncXMLExtract(xmlTemp, 'BREL_PERIOD_CODE', numFCY),
            GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_PERIOD', numFCY),
            GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_FROM', datTemp),
            GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datTemp),
            Gconst.Fncxmlextract(Xmltemp, 'BREL_LOCAL_BANK', Numfcy),
            Sysdate, Null, Gconst.Statusentry, Gconst.Optionno,
            GConst.fncXMLExtract(xmlTemp, 'SpotRate', numRate),
            GConst.fncXMLExtract(xmlTemp, 'ForwardRate', numRate),
            GConst.fncXMLExtract(xmlTemp, 'MarginRate', numRate)
            );
            
            Update Trtran003 Set Brel_Reverse_Reference = (Select Fncchecktheoder(Brel_Trade_Reference) From Dual) 
                    where BREL_TRADE_REFERENCE = varReference;
            
          ELSE
            varOperation := 'Adding record for Bill Realization';
            insert into TradeRegister(trad_company_code, trad_trade_reference,
              trad_reverse_reference, trad_reverse_serial, trad_import_export, 
              trad_entry_date, trad_user_reference, trad_reference_date, 
              trad_buyer_seller, trad_trade_currency, trad_product_code, 
              trad_product_description, trad_trade_fcy, trad_trade_rate, 
              trad_trade_inr, trad_period_code, trad_trade_period,
              trad_maturity_from, trad_maturity_date, trad_local_bank,
              trad_create_date, trad_entry_detail, trad_record_status, trad_process_complete,
              trad_spot_rate,
              trad_forward_rate,trad_margin_rate)
              values(numCompany, varReference1, varReference, numSerial, numCode3,
              GConst.fncXMLExtract(xmlTemp, 'BREL_ENTRY_DATE', datTemp),
              GConst.fncXMLExtract(xmlTemp, 'BREL_USER_REFERENCE', varTemp),
              GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datTemp),
              numCode, numCode1, numCode2, varTemp,
              GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_FCY', numFCY),
              GConst.fncXMLExtract(xmlTemp, 'TradeRate', numRate),
              --GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_RATE', numFCY),
              GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_INR', numFCY),
              GConst.fncXMLExtract(xmlTemp, 'BREL_PERIOD_CODE', numFCY),
              GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_PERIOD', numFCY),
              GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_FROM', datTemp),
              GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datTemp),
              GConst.fncXMLExtract(xmlTemp, 'BREL_LOCAL_BANK', numFCY),
              SYSDATE, NULL, GCONST.STATUSENTRY, GCONST.OPTIONNO,
              GConst.fncXMLExtract(xmlTemp, 'SpotRate', numRate),
              GConst.fncXMLExtract(xmlTemp, 'ForwardRate', numRate),
              GConst.fncXMLExtract(xmlTemp, 'MarginRate', numRate));
            END IF;

          
            numError := fncCompleteUtilization(varReference, GConst.UTILEXPORTS,
                          datWorkDate);
            --numError := fncLoanDeal(RecordDetail, varReference1);
             numError := fncBillSettlement(RecordDetail);

        elsif numAction = GConst.EDITSAVE then
          varOperation := 'Editing the Bill Entry';

          update TradeRegister
            set trad_import_export = numCode3,
            trad_entry_date = GConst.fncXMLExtract(xmlTemp, 'BREL_ENTRY_DATE', datTemp),
            trad_user_reference = GConst.fncXMLExtract(xmlTemp, 'BREL_USER_REFERENCE', varTemp),
            trad_reference_date = GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datTemp),
            trad_trade_fcy = GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_FCY', numFCY),
            trad_trade_rate = GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_RATE', numFCY),
            trad_trade_inr = GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_INR', numFCY),
            trad_maturity_from = GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_FROM', datTemp),
            trad_maturity_date = GConst.fncXMLExtract(xmlTemp, 'BREL_MATURITY_DATE', datTemp),
            trad_record_status = GConst.STATUSUPDATED
            where trad_reverse_reference = varReference
            and trad_reverse_serial = numSerial;

            numError := fncCompleteUtilization(varReference, GConst.UTILEXPORTS,
                          datWorkDate);
            numError := fncLoanDeal(RecordDetail, varReference);

        elsif numAction in (GConst.DELETESAVE, GConst.CONFIRMSAVE) then
          varOperation := 'Marking the Bill Entry for ' || numAction;
          select decode(numAction,
            GConst.DELETESAVE, GConst.STATUSDELETED,
            GConst.CONFIRMSAVE, GConst.STATUSAUTHORIZED)
            into numCode
            from dual;

          update TradeRegister
            set trad_record_status = numCode
            where trad_reverse_reference = varReference
            and trad_reverse_serial = numSerial;

          numError := fncCompleteUtilization(varReference, GConst.UTILEXPORTS,
                        datWorkDate);
          numError := fncLoanDeal(RecordDetail, varReference1);

        End if;

      End if;
--
      numCode := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_TYPE', numCode);

      if numcode in(Gconst.BILLIMPORTORDER) then
--         INSERT INTO TEMP VALUES ('eNTER THE dETAILS','DFDF');
--         COMMIT;

         clbTemp := fncMiscellaneousUpdates(clbTemp,GConst.SYSBCRFDLIEN ,numError);
      end if;

--         INSERT INTO TEMP VALUES (Gconst.BILLIMPORTORDER,numcode);
--         COMMIT;


  End if;
        -- Order - Invoice linking -----------------------------------------------------
   if EditType = Gconst.SYSUPDATEORDINVLINK then
      begin
          delete from temp;

          varOperation := 'Updating Reverse Reference Numbers';
          varXPath := '//ORDINVLINKING/ROW';
          nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
          varOperation := 'Update Reverse Reference ' || varXPath;

          for numTemp in 1..xmlDom.getLength(nlsTemp)
          Loop
              varTemp := varXPath || '[@NUM="' || numTemp || '"]/BREL_COMPANY_CODE';
              varoperation :='Extracting Data from XML' || varTemp;
              varReference := GConst.fncXMLExtract(xmlTemp, varTemp, varReference, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/BREL_TRADE_REFERENCE';
              varoperation :='Extracting Data from XML' || varTemp;
              varReference1 := GConst.fncXMLExtract(xmlTemp, varTemp, varReference1, Gconst.TYPENODEPATH);

              varTemp := varXPath || '[@NUM="' || numTemp || '"]/BREL_USER_REFERENCE';
              varoperation :='Extracting Data from XML' || varTemp;
              varTemp1 := GConst.fncXMLExtract(xmlTemp, varTemp, varTemp1, Gconst.TYPENODEPATH);

              --insert into temp values ('Comp code',varReference);
              --insert into temp values ('Trade ref',varReference1);
              --insert into temp values ('User ref',varTemp1);
              --insert into temp values ('Action ->',to_char(numAction));
             -- commit;

              if numAction = GConst.ADDSAVE then
                 update trtran002
                    set TRAD_REVERSE_REFERENCE = varReference1
                  where TRAD_COMPANY_CODE = varReference
                    and TRAD_TRADE_REFERENCE =varTemp1;
              elsif numAction = GConst.DELETESAVE then
                 update trtran002
                    set TRAD_REVERSE_REFERENCE = null
                  where TRAD_COMPANY_CODE = varReference1
                    and TRAD_TRADE_REFERENCE = varTemp1;
              end if;
          end loop;
      end;
   end if;

  if EditType = GConst.SYSDEALADJUST then

    varOperation := 'Extracting Deal Type and Trade Reference';

    IF varEntity = 'HEDGEDEALREGISTER' THEN
      varXPath := '//HEDGEDEALREGISTER/ROW[@NUM]';
      varTemp := varXPath || '/DEAL_BUY_SELL';
      numCode := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
      varTemp := varXPath || '/DEAL_OTHER_CURRENCY';
      numCode1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
      varTemp := varXPath || '/DEAL_DEAL_NUMBER';
      varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
      varTemp := varXPath || '/DEAL_SERIAL_NUMBER';
      numSerial := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
      varTemp := varXPath || '/DEAL_BASE_AMOUNT';
      numFCY := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
      varTemp := varXPath || '/DEAL_OTHER_AMOUNT';
      numFCY1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
      varTemp := varXPath || '/DEAL_AMOUNT_LOCAL';
      numFcy2 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
      varTemp := varXPath || '/DEAL_EXCHANGE_RATE';
      numRate := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
      varTemp := varXPath || '/DEAL_LOCAL_RATE';
      numRate1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
     
      
      if numCode1 = GConst.INDIANRUPEE then
        numRate1 := numRate;
        numFcy2 := numFcy1;
      end if;
  
--        if numCode = GConst.PURCHASEDEAL then
--          nlsTemp := xslProcessor.selectNodes(nodFinal,'//BUY[@NUM]');
--          varXPath := '//BUY[@NUM="';
--        elsif numCode = GConst.SALEDEAL then
--          nlsTemp := xslProcessor.selectNodes(nodFinal,'//SELL[@NUM]');
--          varXPath := '//SELL[@NUM="';
--        end if;
        
        nlsTemp := xslProcessor.selectNodes(nodFinal,'//ExposureLink/DROW');
        varXPath := '//ExposureLink/DROW[@DNUM="';
  
        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
  
          nodTemp := xmlDom.item(nlsTemp, numSub);
          nmpTemp := xmlDom.getAttributes(nodTemp);
          nodTemp1 := xmlDom.item(nmpTemp, 0);
          numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
  
          varTemp := varXPath || numTemp || '"]/TradeReference';
            varReference1 := GConst.fncXMLExtract(xmlTemp, varTemp, varReference1, Gconst.TYPENODEPATH);
          --varReference1 := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp := varXPath || numTemp || '"]/HedgingAmount';
           numFCY3 := GConst.fncXMLExtract(xmlTemp, varTemp, numFCY3, Gconst.TYPENODEPATH);
          --numFCY3 := to_number (GConst.fncGetNodeValue(nodFinal, varTemp));
          varTemp := varXPath || numTemp || '"]/COMPANYCODE';
          numCompany := GConst.fncXMLExtract(xmlTemp, varTemp, numCompany, Gconst.TYPENODEPATH);
          --numCompany := to_number (GConst.fncGetNodeValue(nodFinal, varTemp));
          --varTemp := varXPath || numTemp || '"]/SERIALNUMBER';
          --numCode1 := to_number (GConst.fncGetNodeValue(nodFinal, varTemp));          
           numCode1 :=1;  --GConst.fncXMLExtract(xmlTemp, varTemp, numCode1, Gconst.TYPENODEPATH);      
    -- If the hedged amount = deal amount move the entire INR to the hedged amount
          numFcy := numFcy - numFcy3;
  
          if numFcy = 0 then
            numCross := numFcy1;
            numInr := numFCy2;
          else
            numCross := round(numFcy3 * numRate);
            numInr := round(numFcy3 * numRate1);
            numFcy1 := numFcy1 - numCross;
            numFcy2 := numFcy2 - numInr;
          end if;
          if numAction = GConst.ADDSAVE then
            varOperation := 'Inserting Hedge Details';
            insert into trtran004(hedg_company_code, hedg_trade_reference,
              hedg_deal_number, hedg_deal_serial, hedg_hedged_fcy,
              hedg_other_fcy, hedg_hedged_inr,
              hedg_create_date, hedg_entry_detail, hedg_record_status,
              hedg_hedging_with, hedg_multiple_currency,HEDG_TRADE_SERIAL,HEDG_LINKED_DATE)
              values(numCompany, varReference1, varReference,
              numSerial, numFCY3, numCross, numInr,
              SYSDATE, NULL, GConst.STATUSENTRY,
              Gconst.Forward, decode(numCode1,GConst.INDIANRUPEE, GConst.OPTIONNO, GConst.OPTIONYES),numCode1,datWorkDate);
          elsif numAction = GConst.EDITSAVE then
            varOperation := 'Updating Hedge Details';
              Update trtran004 set
                hedg_hedged_fcy= numFCY3,
                hedg_other_fcy = numCross,
                hedg_hedged_inr = numInr,
                hedg_record_status=Gconst.STATUSUPDATED
              where hedg_deal_number= varReference;
          end if;
       End Loop;
      END IF;
      IF varEntity = 'FORWARDRATEAGREEMENT' THEN
        varXPath := '//FORWARDRATEAGREEMENT/ROW[@NUM]';
        varTemp := varXPath || '/IFRA_BUY_SELL';
        numCode := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || '/DEAL_OTHER_CURRENCY';
--        numCode1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || '/IFRA_FRA_NUMBER';
        varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
--        varTemp := varXPath || '/DEAL_SERIAL_NUMBER';
--        numSerial := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || '/IFRA_NOTIONAL_AMOUNT';
        numFCY := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || '/DEAL_OTHER_AMOUNT';
--        numFCY1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || '/DEAL_AMOUNT_LOCAL';
--        numFcy2 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        varTemp := varXPath || '/IFRA_FRA_RATE';
        numRate := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
--        varTemp := varXPath || '/DEAL_LOCAL_RATE';
--        numRate1 := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
    
        if numCode1 = GConst.INDIANRUPEE then
          numRate1 := numRate;
          numFcy2 := numFcy1;
        end if;
    
          if numCode = GConst.PURCHASEDEAL then
            nlsTemp := xslProcessor.selectNodes(nodFinal,'//BUY[@NUM]');
            varXPath := '//BUY[@NUM="';
          elsif numCode = GConst.SALEDEAL then
            nlsTemp := xslProcessor.selectNodes(nodFinal,'//SELL[@NUM]');
            varXPath := '//SELL[@NUM="';
          end if;
    
          for numSub in 0..xmlDom.getLength(nlsTemp) -1
          Loop
    
            nodTemp := xmlDom.item(nlsTemp, numSub);
            nmpTemp := xmlDom.getAttributes(nodTemp);
            nodTemp1 := xmlDom.item(nmpTemp, 0);
            numTemp := to_number(xmlDom.getNodeValue(nodTemp1));
    
            varTemp := varXPath || numTemp || '"]/TradeReference';
            varReference1 := GConst.fncGetNodeValue(nodFinal, varTemp);
            varTemp := varXPath || numTemp || '"]/HedgingAmount';
            numFCY3 := to_number (GConst.fncGetNodeValue(nodFinal, varTemp));
            varTemp := varXPath || numTemp || '"]/COMPANYCODE';
            numCompany := to_number (GConst.fncGetNodeValue(nodFinal, varTemp));
      -- If the hedged amount = deal amount move the entire INR to the hedged amount
            numFcy := numFcy - numFcy3;
    
            if numFcy = 0 then
              numCross := numFcy1;
              numInr := numFCy2;
            else
              numCross := round(numFcy3 * numRate);
              numInr := round(numFcy3 * numRate1);
              numFcy1 := numFcy1 - numCross;
              numFcy2 := numFcy2 - numInr;
            end if;
            if numAction = GConst.ADDSAVE then
              varOperation := 'Inserting Hedge Details';
              insert into trtran004(hedg_company_code, hedg_trade_reference,
                hedg_deal_number, hedg_deal_serial, hedg_hedged_fcy,
                hedg_other_fcy, hedg_hedged_inr,
                hedg_create_date, hedg_entry_detail, hedg_record_status,
                hedg_hedging_with, hedg_multiple_currency)
                values(numCompany, varReference1, varReference,
                numSerial, numFCY3, numCross, numInr,
                sysdate, null, GConst.STATUSENTRY,
                Gconst.Forward, decode(numCode1,GConst.INDIANRUPEE, GConst.OPTIONNO, GConst.OPTIONYES));
            elsif numAction = GConst.EDITSAVE then
              varOperation := 'Updating Hedge Details';
                Update trtran004 set
                  hedg_hedged_fcy= numFCY3,
                  hedg_other_fcy = numCross,
                  hedg_hedged_inr = numInr,
                  hedg_record_status=Gconst.STATUSUPDATED
                where hedg_deal_number= varReference;
            end if;
         End Loop;
      END IF;
  
      if numAction =Gconst.DELETESAVE then
          varOperation := 'Deleting Hedge Details';
          Delete trtran004 where
             hedg_deal_number= varReference;
      end if;
  end if;

  if EditType = GConst.SYSCOMMDEALREVERSAL then
         varOperation := 'Inserting into Commodity Deal Reversal';

       if varEntity= 'COMMODITYDEALCANCEL' then
         varXPath := '//' || varEntity || '/ROW[@NUM]';
         varTemp := varXPath || '/CREV_DEAL_NUMBER';
         varOperation := 'Geting Deal Number';
         varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
         numError := fncCompleteUtilization(varReference, GConst.UTILCOMMODITYDEAL,
                        datWorkDate);
       else

         varXPath := '//' || varEntity || '/ROW[@NUM]';
         varTemp := varXPath || '/CMDL_DEAL_NUMBER';
         varOperation := 'Geting Deal Number';
         varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
         varTemp := varXPath || '/CMDL_COMPANY_CODE';
         numcode1 :=   to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
         nlsTemp := xslProcessor.selectNodes(nodFinal,'//' || varEntity || '/ReverseDetails/ReverseRow[@NUM]');
         varXPath := '//' || varEntity || '/ReverseDetails/ReverseRow[@NUM="';

        for numSub in 1..xmlDom.getLength(nlsTemp)
         loop
          varTemp := varXPath || numSub || '"]/ReverseDealNumber';
          varReference1 := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp := varXPath || numSub || '"]/ReverseLot';
          numcode := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp := varXPath || numSub || '"]/ReserveProcess';
           varOperation := 'Geting Process Complite  Number';
          numcode2:= GConst.fncGetNodeValue(nodFinal, varTemp);
          varOperation := 'Fetching ReserveProcessComplete';
          varTemp := varXPath || numSub || '"]/ReserveProfitLoss';
          numINR := GConst.fncGetNodeValue(nodFinal, varTemp);
          if numAction = GConst.ADDSAVE then
             insert into trtran053 ( crev_company_code,crev_deal_number,crev_reverse_deal,
               crev_reverse_lot,crev_profit_loss,crev_create_Date,crev_record_status, crev_execute_date)
               VALUES (numcode1,varReference, varReference1,
               numcode,numINR,sysdate,10200001,datWorkDate);

             varOperation := 'Updating Process Complete and Process Complite Date';
             if numcode2=Gconst.OptionYES then
                update trtran051 set cmdl_process_complete= numcode2,
                  cmdl_complete_date= datWorkDate
                  where cmdl_deal_number=  varReference1;
              end if;

          elsif numAction = GConst.EDITSAVE then
             update trtran053 set crev_reverse_deal=varReference1,
               crev_reverse_lot=numcode
               where crev_deal_number= varReference;

          elsif  numAction = GConst.DELETESAVE then
             delete from trtran053 where  crev_deal_number= varReference;
          end if;
        end Loop;
      end if;
  end if;
 --
    IF EditType = GConst.SYSFUTUREREVERSAL THEN
         varOperation := 'Inserting into Currency Future  Deal Reversal';
         

       IF ((varEntity= 'CURRENCYFUTUREDEALCANCEL') or (varEntity= 'CURRENCYFUTURETRADDEALCANCEL')) THEN
         varXPath := '//' || varEntity || '/ROW[@NUM]';
         varTemp := varXPath || '/CFRV_DEAL_NUMBER';
         varOperation := 'Geting Deal Number';

         varReference := GConst.fncGetNodeValue(nodFinal, varTemp);

         numError := fncCompleteUtilization(varReference, GConst.UTILFUTUREDEAL,
                        datWorkDate);
                        
          IF (varEntity= 'CURRENCYFUTUREDEALCANCEL') THEN
            IF numAction = GConst.ADDSAVE THEN                
              nlsTemp    := xslProcessor.selectNodes(nodFinal,'//DealUnLink/ROWD[@NUM]');
              varXPath   := '//DealUnLink/ROWD[@NUM="';
              FOR numSub IN 0..xmlDom.getLength(nlsTemp) -1
              LOOP
                nodTemp       := xmlDom.item(nlsTemp, numSub);
                nmpTemp       := xmlDom.getAttributes(nodTemp);
                nodTemp1      := xmlDom.item(nmpTemp, 0);
                numTemp       := to_number(xmlDom.getNodeValue(nodTemp1));
                varTemp       := varXPath || numTemp || '"]/DealSerial';
                numCode1      := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
                varTemp       := varXPath || numTemp || '"]/TradeReference';
                varReference1 := GConst.fncGetNodeValue(nodFinal, varTemp);
                varTemp       := varXPath || numTemp || '"]/LinkDealNumber';
                varReference  := GConst.fncGetNodeValue(nodFinal, varTemp);
                
                varTemp       := varXPath || numTemp || '"]/HedgedAmount';
                numFCY        := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
                
                varTemp       := varXPath || numTemp || '"]/CompanyCode';
                numCompany    := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
                
      --          varTemp       := varXPath || numTemp || '"]/LinkDate';
      --          datTemp       := GConst.fncGetNodeValue(nodFinal, varTemp);
--                SELECT deal_exchange_rate
--                INTO numRate1
--                FROM trtran001
--                WHERE deal_deal_number = varReference;
                
                IF numFCY <= 0 THEN
                  UPDATE trtran004
                  SET hedg_record_status     = GConst.STATUSDELETED
                  WHERE hedg_trade_reference = varReference1
                  AND hedg_deal_number       = varReference
                  AND hedg_deal_serial       = numCode1;
                ELSE
                  UPDATE trtran004
                  SET hedg_record_status     = GConst.STATUSDELETED
                  WHERE hedg_trade_reference = varReference1
                  AND hedg_deal_number       = varReference
                  AND hedg_deal_serial       = numCode1;
                  
                  INSERT
                  INTO trtran004
                    ( hedg_company_code,    hedg_trade_reference,    hedg_deal_number,    hedg_deal_serial,    hedg_hedged_fcy,
                      hedg_other_fcy,    hedg_hedged_inr,    hedg_create_date,    hedg_entry_detail,    hedg_record_status,
                      hedg_hedging_with,    hedg_multiple_currency,    hedg_linked_date,  hedg_location_code  )
                    VALUES
                    (
                      numCompany,    varReference1,    varReference, numCode1+1,    numFCY,
                      0, numFCY ,    sysdate,    NULL,    10200001,
                      32200002,    12400002,    datWorkDate, 30299999 );
          
                END IF;
              END LOOP;      
            END IF;
           END IF;                        
       ELSE

         varXPath := '//' || varEntity || '/ROW[@NUM]';
         varTemp := varXPath || '/CFUT_DEAL_NUMBER';
         varOperation := 'Geting Deal Number';
         varReference := GConst.fncGetNodeValue(nodFinal, varTemp);
         varTemp := varXPath || '/CFUT_COMPANY_CODE';
         numcode1 :=   to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
         nlsTemp := xslProcessor.selectNodes(nodFinal,'//' || varEntity || '/ReverseDetails/ReverseRow[@NUM]');
         varXPath := '//' || varEntity || '/ReverseDetails/ReverseRow[@NUM="';

        for numSub in 1..xmlDom.getLength(nlsTemp)
         loop
          varTemp := varXPath || numSub || '"]/ReverseDealNumber';
          varReference1 := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp := varXPath || numSub || '"]/ReverseLot';
          numcode := GConst.fncGetNodeValue(nodFinal, varTemp);
          varTemp := varXPath || numSub || '"]/ReserveProcess';
           varOperation := 'Geting Process Complite  Number';
          numcode2:= GConst.fncGetNodeValue(nodFinal, varTemp);
          varOperation := 'Fetching ReserveProcessComplete';
          varTemp := varXPath || numSub || '"]/ReserveProfitLoss';
          numINR := GConst.fncGetNodeValue(nodFinal, varTemp);
          if numAction = GConst.ADDSAVE then
             insert into trtran063 ( cfrv_company_code,cfrv_deal_number,cfrv_reverse_deal,
               cfrv_reverse_lot,cfrv_profit_loss,cfrv_create_Date,cfrv_record_status, cfrv_execute_date)
               VALUES (numcode1,varReference, varReference1,
               numcode,numINR,sysdate,10200001,datWorkDate);

             varOperation := 'Updating Process Complete and Process Complite Date';
             if numcode2=Gconst.OptionYES then
                update trtran061 set cfut_process_complete= numcode2,
                  cfut_complete_date= datWorkDate
                  where cfut_deal_number=  varReference1;
              end if;
          elsif numAction = GConst.EDITSAVE then
             update trtran063 set cfrv_reverse_deal=varReference1,
               cfrv_reverse_lot=numcode
               where cfrv_deal_number= varReference;

          elsif  numAction = GConst.DELETESAVE then
             delete from trtran063 where  cfrv_deal_number= varReference;
          end if;
        end Loop;
      end if;
  end if;


  ---kumar.h 12/05/09  updates for Fixed Deposit--------
  if EditType = GConst.SYSBCRFDLIEN then
     if varEntity='IMPORTREALIZE' then
         varReference := GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_REFERENCE', varReference);
     begin
        select trad_trade_reference
          into VarReference
        from trtran002
         where trad_reverse_reference =varReference
          and trad_record_Status not in(10200005,10200006);
     exception
       when others then
        VarReference:='Temp';
     end;
     else
         varReference := GConst.fncXMLExtract(xmlTemp, 'BCRD_BUYERS_CREDIT', varReference);
     end if;

      if numAction in (GConst.DELETESAVE, GConst.CONFIRMSAVE) then
        varOperation := 'Updating status of Import Adjustement';
        select decode(numAction,
                GConst.DELETESAVE,GConst.STATUSDELETED,
                GConst.CONFIRMSAVE, GConst.STATUSAUTHORIZED)
          into numCode
          from dual;

          update trtran017
            set fdln_record_status = numCode
            where fdln_company_code = numCompany
            and fdln_location_code =  numLocation
            and fdln_lien_reference = varReference;
      elsif numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then

        varXPath := '//FDDETAIL/ReturnFields/ROWD';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        numSub := xmlDom.getLength(nlsTemp);

        if numSub > 0 and numAction = GConst.EDITSAVE then
          update trtran017
            set fdln_record_status = GConst.STATUSDELETED
            where fdln_company_code = numCompany
            and fdln_location_code =  numLocation
            and fdln_lien_reference = varReference;
        End if;

        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.Item(nlsTemp, numSub);
          nmpTemp:= xmlDom.getAttributes(nodTemp);
          nodTemp := xmlDom.Item(nmpTemp, 0);
          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
          varTemp := varXPath || '[@NUM="' || numTemp || '"]/';

          varTemp1 := varTemp || 'FDReference';
          varReference1 := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference1,Gconst.TYPENODEPATH);
          varTemp1 := varTemp || 'RecordStatus';
          numStatus := GConst.fncXMLExtract(xmlTemp,varTemp1,numStatus, Gconst.TYPENODEPATH);
-- IF a record already exists with delete status then the
--  same is updated otherwise, a new record is added
          varOperation := 'Checking for Delete Status';
          Begin
            select fdln_record_status
              into numStatus
              from trtran017
              where fdln_fd_number = varReference1
              and fdln_lien_reference = varReference;
          Exception
            when no_data_found then
              numStatus := GCOnst.STATUSENTRY;
          End;

          if numStatus  = GConst.STATUSDELETED then
            update trtran017
              set fdln_record_status = GCOnst.STATUSENTRY
              where fdln_fd_number = varReference1
              and fdln_lien_reference = varReference;
          else

            insert into trtran017(fdln_company_code, fdln_location_code,
              fdln_fd_number, fdln_lien_reference, fdln_lien_date,
              fdln_create_date, fdln_entry_detail, fdln_record_status)
            values(numCompany, numLocation, varReference1, varReference,
            datWorkDate, sysdate, null, GCOnst.STATUSENTRY);
          end if;

        End Loop;

      end if;
  --//---kumar.h 06/06/09  updates Relation Table-------
  --//Purpose:-to delete the selected related Entries
   if EditType = GConst.SYSRELATION then
     if numAction in (GConst.DELETESAVE) then
        varOperation := 'Deleting the Details for the Selected Relation';

        varXPath := '//RELATIONTABLE/ROW[@NUM]';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        numSub := xmlDom.getLength(nlsTemp);

        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.Item(nlsTemp, numSub);
          nmpTemp:= xmlDom.getAttributes(nodTemp);
          nodTemp := xmlDom.Item(nmpTemp, 0);
          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
          varTemp := varXPath || '[@NUM="' || numTemp || '"]/';

          varTemp1 := varTemp || 'EREL_ENTITY_TYPE';
          numcode := GConst.fncXMLExtract(xmlTemp,varTemp1,numcode,Gconst.TYPENODEPATH);
          varTemp1 := varTemp || 'EREL_MAIN_ENTITY';
          numcode1 := GConst.fncXMLExtract(xmlTemp,varTemp1,numcode1, Gconst.TYPENODEPATH);
          varTemp1 := varTemp || 'EREL_RELATION_TYPE';
          numcode2 := GConst.fncXMLExtract(xmlTemp,varTemp1,numcode2,Gconst.TYPENODEPATH);
          varTemp1 := varTemp || 'EREL_ENTITY_RELATION';
          numcode3 := GConst.fncXMLExtract(xmlTemp,varTemp1,numcode3, Gconst.TYPENODEPATH);

         delete
           from  trsystem008
           where erel_company_code=30199999
             and erel_entity_type =numcode
             and erel_main_entity=numcode1
             and erel_relation_type =numcode2
             and erel_entity_relation=numcode3;
       End Loop;
    end if;
  End if;

    End if;

------------------------------------------ Option Deals-----------------------------------------
--   if EditType = GConst.SYSOPTIONMATURITY then
--
--        varOperation := 'Option Maturities Gettinging DealNumber';
--        varTemp := '//ROW[@NUM="1"]/COPT_DEAL_NUMBER';
--        varReference := GConst.fncXMLExtract(xmlTemp,varTemp,varReference,Gconst.TYPENODEPATH);
--      --Before adding deleteing the Existing data if anyh
--        delete from trtran072
--           where cosu_deal_number=varReference;
--
--     -- if numAction in (GConst.ADDSAVE) then
--        varXPath := '//LEG/LEGROW';
--        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--        numSub := xmlDom.getLength(nlsTemp);
--        varOperation := 'Option Maturities Entering Into Main loop ' || varXPath;
--        for numSub in 0..xmlDom.getLength(nlsTemp) -1
--        Loop
--          nodTemp := xmlDom.Item(nlsTemp, numSub);
--          nmpTemp:= xmlDom.getAttributes(nodTemp);
--          nodTemp := xmlDom.Item(nmpTemp, 0);
--          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
--          varTemp := varXPath || '[@NUM="' || numTemp || '"]/SUBROW';
--          varoperation :='Extracting Data from XML' || varTemp;
--          nlsTemp1 := xslProcessor.selectNodes(nodFinal, varTemp);
--          numSub1 := xmlDom.getLength(nlsTemp1);
--          for numsub1 in 0.. xmldom.getlength(nlsTemp1) -1
--          loop
--              varOperation := 'Option Maturities Entering Into Sub  loop ' || varXPath;
--              nodTemp := xmlDom.Item(nlsTemp1, numSub1);
--              nmpTemp:= xmlDom.getAttributes(nodTemp);
--              nodTemp := xmlDom.Item(nmpTemp, 0);
--              numTemp1 := to_number(xmlDom.GetNodeValue(nodTemp));
--
--              varTemp := varXPath || '[@NUM="' || numTemp || '"]/SUBROW[@SUBNUM="'|| numTemp1 || '"]/';
--              varoperation :='Extracting Data from XML' || varTemp;
--              numSerial := GConst.fncXMLExtract(xmlTemp,varTemp || 'SRNO',numSerial, Gconst.TYPENODEPATH);
--              numSerial1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SUBSRNO',numSerial1, Gconst.TYPENODEPATH);
--              numCode := GConst.fncXMLExtract(xmlTemp,varTemp || 'BuySell',numCode, Gconst.TYPENODEPATH);
--              numCode1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'OptionType',numCode1, Gconst.TYPENODEPATH);
--              numFCY := GConst.fncXMLExtract(xmlTemp,varTemp || 'BaseAmount',numFCY, Gconst.TYPENODEPATH);
--              numRate2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'StrikeRate',numFCY1, Gconst.TYPENODEPATH);
--              numFCY2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'OtherAmount',numFCY2, Gconst.TYPENODEPATH);
--              numFCY3 := GConst.fncXMLExtract(xmlTemp,varTemp || 'LocalRate',numFCY3, Gconst.TYPENODEPATH);
--              numCross := GConst.fncXMLExtract(xmlTemp,varTemp || 'LocalAmount',numCross, Gconst.TYPENODEPATH);
--              numRate := GConst.fncXMLExtract(xmlTemp,varTemp || 'PremiumRate',numRate, Gconst.TYPENODEPATH);
--              numFCY4 := GConst.fncXMLExtract(xmlTemp,varTemp || 'PremiumAmount',numFCY4, Gconst.TYPENODEPATH);
--              numRate1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'PremiumLocalRate',numRate1, Gconst.TYPENODEPATH);
--              numINR := GConst.fncXMLExtract(xmlTemp,varTemp || 'PremiumLocalAmount',numINR, Gconst.TYPENODEPATH);
--              datTemp := GConst.fncXMLExtract(xmlTemp,varTemp || 'MATURITY',datTemp, Gconst.TYPENODEPATH);
--              datTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SETTLEMENTDATE',datTemp1, Gconst.TYPENODEPATH);
--
--              insert into trtran072 (COSU_DEAL_NUMBER,COSU_SERIAL_NUMBER,COSU_SUBSERIAL_NUMBER,COSU_OPTION_TYPE,
--                                     COSU_BUY_SELL,COSU_BASE_AMOUNT,COSU_STRIKE_RATE,COSU_OTHER_AMOUNT,COSU_LOCAL_RATE,
--                                     COSU_LOCAL_AMOUNT,COSU_PREMIUM_RATE,COSU_PREMIUM_AMOUNT,COSU_PREMIUM_LOCALRATE,
--                                     COSU_PREMIUM_LOCALAMOUNT,COSU_MATURITY_DATE,COSU_SETTLEMENT_DATE,
--                                     COSU_RECORD_STATUS,COSU_PROCESS_COMPLETE)
--                            values (varReference,numSerial,numSerial1,numCode1,
--                                    numCode,numFCY,numRate2,numFCY2,numFCY3,
--                                    numCross,numRate,numFCY4,numRate1,
--                                    numINR,datTemp,datTemp1,10200001,12400002);
--
--         end loop;
--       End Loop;
----       elsif numAction in (GConst.DELETESAVE) then
----          varOperation :='Deleting Deals';
----          update trtran072 set cosu_record_status= 10200006
----                 where cosu_deal_number=varReference;
--   --   end if;
--
--  End if;
  if EditType = GConst.SYSOPTIONMATURITY then

        varOperation := 'Option Maturities Gettinging DealNumber';
        varTemp := '//ROW[@NUM="1"]/COPT_DEAL_NUMBER';
        varReference := GConst.fncXMLExtract(xmlTemp,varTemp,varReference,Gconst.TYPENODEPATH);
      --Before adding deleteing the Existing data if anyh
     if numAction in (GConst.DELETESAVE) then 
        update  trtran072 set cosu_record_Status =10200006
           where cosu_deal_number=varReference;
        
        update trtran072A set cosm_record_Status =10200006
           where cosm_deal_number=varReference;
     else
        delete from trtran072
           where cosu_deal_number=varReference;
        
        delete from trtran072A
           where cosm_deal_number=varReference;

     -- if numAction in (GConst.ADDSAVE) then
        varXPath := '//MultipleDeals/DROW';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        numSub := xmlDom.getLength(nlsTemp);
        varOperation := 'Option Maturities Entering Into Main loop ' || varXPath;
        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop
          nodTemp := xmlDom.Item(nlsTemp, numSub);
          nmpTemp:= xmlDom.getAttributes(nodTemp);
          nodTemp := xmlDom.Item(nmpTemp, 0);
          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
          varTemp := varXPath; --|| '[@NUM="' || numTemp || '"]/SUBROW';
          varoperation :='Extracting Data from XML' || varTemp;
--          nlsTemp1 := xslProcessor.selectNodes(nodFinal, varTemp);
--          numSub1 := xmlDom.getLength(nlsTemp1);
----          for numsub1 in 0.. xmldom.getlength(nlsTemp1) -1
----          loop
--              varOperation := 'Option Legs entering Into Sub  loop ' || varXPath;
--              nodTemp := xmlDom.Item(nlsTemp1, numSub1);
--              nmpTemp:= xmlDom.getAttributes(nodTemp);
--              nodTemp := xmlDom.Item(nmpTemp, 0);
--              numTemp1 := to_number(xmlDom.GetNodeValue(nodTemp));

              varTemp := varXPath || '[@DNUM="' || numTemp || '"]/';
              varoperation :='Extracting Data from XML' || varTemp;
              numSerial := GConst.fncXMLExtract(xmlTemp,varTemp || 'SerialNumber',numSerial, Gconst.TYPENODEPATH);
            --  numSerial1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SUBSRNO',numSerial1, Gconst.TYPENODEPATH);
              numCode := GConst.fncXMLExtract(xmlTemp,varTemp || 'BuySell',numCode, Gconst.TYPENODEPATH);
              numCode1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'OptionType',numCode1, Gconst.TYPENODEPATH);
              numFCY := GConst.fncXMLExtract(xmlTemp,varTemp || 'BaseAmount',numFCY, Gconst.TYPENODEPATH);
              numRate2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'StrikeRate',numRate2, Gconst.TYPENODEPATH);
              numFCY2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'OtherAmount',numFCY2, Gconst.TYPENODEPATH);
--              numFCY3 := GConst.fncXMLExtract(xmlTemp,varTemp || 'LocalRate',numFCY3, Gconst.TYPENODEPATH);
--              numCross := GConst.fncXMLExtract(xmlTemp,varTemp || 'LocalAmount',numCross, Gconst.TYPENODEPATH);
              numRate := GConst.fncXMLExtract(xmlTemp,varTemp || 'PremiumRate',numRate, Gconst.TYPENODEPATH);
              numFCY4 := GConst.fncXMLExtract(xmlTemp,varTemp || 'PremiumAmount',numFCY4, Gconst.TYPENODEPATH);
              begin 
               numCode2 := GConst.fncXMLExtract(xmlTemp,varTemp || 'ProductCode',numCode2, Gconst.TYPENODEPATH);
              exception
               when others then
                 numCode2 :=null;
              end;
              numINR := GConst.fncXMLExtract(xmlTemp,varTemp || 'NoOfLots',numINR, Gconst.TYPENODEPATH);
              datTemp := GConst.fncXMLExtract(xmlTemp,varTemp || 'MaturityDate',datTemp, Gconst.TYPENODEPATH);
              datTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SettlementDate',datTemp1, Gconst.TYPENODEPATH);

              insert into trtran072 (COSU_DEAL_NUMBER,COSU_SERIAL_NUMBER,COSU_OPTION_TYPE,
                                     COSU_BUY_SELL,COSU_BASE_AMOUNT,COSU_STRIKE_RATE,COSU_OTHER_AMOUNT,
                                     Cosu_Premium_rate,cosu_premium_amount,cosu_maturity_date,
                                     cosu_settlement_date,COSU_PRODUCT_CODE,COSU_LOT_NUMBERS,
                                     COSU_RECORD_STATUS,COSU_PROCESS_COMPLETE)
                            values (varReference,numSerial,numCode1,
                                    numCode,numFCY,numRate2,numFCY2,
                                    numrate,numfcy4,datTemp,
                                    datTemp1,numCode2,numINR,
                                    10200001,12400002);


         --end loop;
       End Loop;
       
        --varXPath := '//MLegs/MLeg';
        varXPath := '//Maturity/DROW';
        nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
        numSub := xmlDom.getLength(nlsTemp);
        varOperation := 'Option Maturities Entering Into Main loop ' || varXPath;
        for numSub in 0..xmlDom.getLength(nlsTemp) -1
        Loop       
       
              varOperation := 'Option Legs entering Into Sub  loop ' || varXPath;
              nodTemp := xmlDom.Item(nlsTemp, numSub);
              nmpTemp:= xmlDom.getAttributes(nodTemp);
              nodTemp := xmlDom.Item(nmpTemp, 0);
              numTemp1 := to_number(xmlDom.GetNodeValue(nodTemp));

              varTemp := varXPath || '[@DNUM="' || numTemp1 || '"]/';
              varoperation :='Extracting Data from XML' || varTemp;
              numSerial := GConst.fncXMLExtract(xmlTemp,varTemp || 'SrNo',numSerial, Gconst.TYPENODEPATH);
              numSerial1 := Gconst.fncXMLExtract(xmltemp,vartemp || 'SubSrNo',numserial1,Gconst.TYPENODEPATH);
              datTemp := GConst.fncXMLExtract(xmlTemp,varTemp || 'MaturityDate',datTemp, Gconst.TYPENODEPATH);
              datTemp1 := GConst.fncXMLExtract(xmlTemp,varTemp || 'SettlementDate',datTemp1, Gconst.TYPENODEPATH);
              numFcy6 :=  GConst.fncXMLExtract(xmlTemp,varTemp || 'Amount',numFcy6, Gconst.TYPENODEPATH);
          insert into trtran072A (COSM_DEAL_NUMBER,cosm_serial_number,COSM_SUBSERIAL_NUMBER,COSM_MATURITY_DATE,
                                 COSM_SETTLEMENT_DATE,COSM_PROCESS_COMPLETE,COSM_CREATE_DATE,
                                 COSM_RECORD_STATUS,COSM_AMOUNT_FCY)
             values (varReference,numSerial,numserial1,datTemp,
                     datTemp1,12400001,sysdate,10200001,numFcy6); 

      end loop;
    end if;
    DELETE FROM trsystem966;
  End if;


   if EditType = GConst.SYSOPTIONCANCELDEAL then
      varReference := GConst.fncXMLExtract(xmlTemp, 'CORV_DEAL_NUMBER', varTemp);
      numSerial := GConst.fncXMLExtract(xmlTemp, 'CORV_SERIAL_NUMBER', numFCY2);
      varOperation := 'Updating Cancelled Option Deals';

      if numAction = GConst.ADDSAVE then
          numError := fncCompleteUtilization(varReference, Gconst.UTILOPTIONHEDGEDEAL,
                        datWorkDate, numserial);
--        update trtran071
--          set copt_record_status = GConst.STATUSPOSTCANCEL,
--          copt_process_complete = GConst.OPTIONYES,
--          copt_complete_date = datWorkDate
--          where copt_deal_number = varReference
--          and copt_serial_number = numSerial;
      elsif numAction = GConst.DELETESAVE then
        update trtran071
          set --copt_record_status = GConst.STATUSENTRY,
          copt_process_complete = GConst.OPTIONNO,
          copt_complete_date = NULL
          where copt_deal_number = varReference
          and copt_serial_number = numSerial;
      End if;

    End if;

    if EditType =Gconst.SYSLINKUPDATETABLES then
      varReference := GConst.fncXMLExtract(xmlTemp, 'LINK_BATCH_NUMBER', varTemp);
      varOperation := 'Updating Updating Link Batch Numbers';
      varXPath := '//HEDGEREFERENCE';
      nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
      varOperation := 'Update Option Deals With Linking No ' || varXPath;

      varOperation := 'Updating null to Old Reference';
--      update trtran071 set copt_link_batchno=null, copt_link_date=datWorkDate
--             where copt_link_batchno=varReference;
--
--      varOperation := 'Updating null to Old Reference';
--      update trtran002 set trad_link_batchno=null, trad_link_date=datWorkDate
--             where trad_link_batchno=varReference;


     -- insert into temp values (varOperation,varXPath);
      for numSub in 0..xmlDom.getLength(nlsTemp) -1
      Loop
          nodTemp := xmlDom.Item(nlsTemp, numSub);
          nmpTemp:= xmlDom.getAttributes(nodTemp);
          nodTemp := xmlDom.Item(nmpTemp, 0);
          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
          varTemp := varXPath || '[@NUM="' || numTemp || '"]';
          varoperation :='Extracting Data from XML' || varTemp;
          varReference1 := GConst.fncXMLExtract(xmlTemp,varTemp,varReference, Gconst.TYPENODEPATH);

--          Update trtran071 set copt_link_batchno= varReference,
--                               copt_link_date= datWorkDate
--                where copt_deal_number =varReference1;
          --insert into temp values (varOperation,varReference1);
      end loop;

      varOperation := 'Updating Link Batch Trade Reference';
      varXPath := '//TRADEREFERENCE';
      nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
      varOperation := 'Update Option Deals With Linking No ' || varXPath;
      for numSub in 0..xmlDom.getLength(nlsTemp) -1
      Loop
          nodTemp := xmlDom.Item(nlsTemp, numSub);
          nmpTemp:= xmlDom.getAttributes(nodTemp);
          nodTemp := xmlDom.Item(nmpTemp, 0);
          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
          varTemp := varXPath || '[@NUM="' || numTemp || '"]';
          varoperation :='Extracting Data from XML' || varTemp;
          varReference1 := GConst.fncXMLExtract(xmlTemp,varTemp,varReference, Gconst.TYPENODEPATH);

          Update trtran002 set trad_link_batchno= varReference,
                               trad_link_date= datWorkDate
                where trad_trade_reference =varReference1;
          --insert into temp values (varOperation,varReference1);



      end loop;
   end if;

   if EditType =Gconst.SYSUPDATEDEALNO then --Added By Sivadas on 18DEC2011

        --delete from temp;
        --insert into temp values(varReference, varReference);
        varTemp := Gconst.fncXMLExtract(xmlTemp,'UpdateType',varTemp);

        if varTemp=Gconst.UpdateIBSRefNo then
            varReference  := GConst.fncXMLExtract(xmlTemp, 'MTMR_USER_REFERENCE', varTemp);
            varReference1 := GConst.fncXMLExtract(xmlTemp, 'MTMR_BATCH_NUMBER', varTemp);
            datWorkDate   := GConst.fncXMLExtract(xmlTemp, 'MTMR_REPORT_DATE', datWorkDate);

            begin
              select dealnumber,
                     companycode,
                     counterparty,
                     dealtype,
                     slno
                into varTemp1,
                     numCode1,
                     numCode2,
                     numCode3,
                     numTemp
                from (
                      select dealnumber,
                             regexp_substr(userref,'[^,]+', 1, level) userref,
                             companycode,
                             counterparty,
                             dealtype,
                             slno
                        from (
                              select copt_user_reference userref,
                                     copt_deal_number dealnumber,
                                     copt_company_code companycode,
                                     copt_counter_party counterparty,
                                     copt_deal_type dealtype,
                                     copt_serial_number slno
                                from trtran071
                               where instr(copt_user_reference, varReference) > 0
                                 and ((copt_process_complete = 12400001
                                       and copt_complete_date > datWorkDate)
                                        or copt_process_complete = 12400002)
                                 and copt_record_status not in (10200005,10200006)
                             )
                      connect by regexp_substr(userref, '[^,]+', 1, level) is not null
                     )
               where userref = varReference
                 and rownum = 1;

              -- Update Deal number, company code and bank code
              update trtran075
                 set mtmr_ibs_ref_no = varTemp1,
                     mtmr_company_code = numCode1,
                     mtmr_bank_code = numCode2
               where mtmr_user_reference = varReference
                    and mtmr_report_date=datWorkDate;
              -- update mtm amounts if Barclays/Citi bank
              update trtran075
                 set mtmr_mtm_amount = -mtmr_mtm_amount,
                     mtmr_mtm_usd = -mtmr_mtm_usd,
                     mtmr_national1 = -mtmr_national1
               where mtmr_user_reference = varReference
                 and mtmr_bank_code in (30600024, 30600114, 30600113, 30600034, 30600088, 30600089)
                 and mtmr_report_date=datWorkDate;
              -- update notional1 as '0' if Strangle/Straddle option for ICICI Bank
              if numCode3 = 32300002 or numCode3 = 32300005 then
                  update trtran075
                     set mtmr_national1 = 0
                   where mtmr_user_reference in (select userref
                                                   from (select rownum rno,
                                                                copt_deal_number,
                                                                regexp_substr(copt_user_reference,'[^,]+', 1, level) userref
                                                           from (select copt_user_reference,
                                                                        copt_deal_number
                                                                   from trtran071
                                                                  where instr(copt_user_reference, varReference) > 0)
                                                        connect by regexp_substr(copt_user_reference, '[^,]+', 1, level) is not null)
                                                    where rno > 1)
                     and mtmr_bank_code in (30600096, 30600097, 30600110, 30600115, 30600020)
                     and mtmr_report_date=datWorkDate;
              end if;

              -- update notional as 0 for Barclays bank STRANGLE option
              if numCode3 = 32300002 then
                  update trtran075
                     set mtmr_national1 = 0
                   where mtmr_user_reference = varReference
                     and mtmr_bank_code in (30600024, 30600114, 30600113)
                     and mtmr_national1 < 0;
              end if;

              -- Update Notional value for Axis Bank --
              update trtran075
                 set mtmr_national1 = (select copt_base_amount
                                         from trtran071
                                        where copt_company_code = numCode1
                                          and copt_deal_number = varTemp1
                                          and copt_serial_number = numTemp)
               where mtmr_user_reference = varReference
                 and mtmr_bank_code in (30600094, 30600011, 30600031, 30600035);

            exception
              when no_data_found then
                -- Delete all rows updated till now
                delete
                  from trtran075
                 where mtmr_batch_number = varReference1;
                 commit;

                -- Raise application error
                numError := 0;
                varError := 'No deal number found for ' || varReference || ' or is in process complete status!';
                --varError := GConst.fncReturnError('MTM Upload', numError, varMessage,
                --                varOperation, varError);
                --raise_application_error(-20101, varError);
                --raise error_occured;
                   --numError := SQLCODE;
               -- varError := SQLERRM;
                --varError := GConst.fncReturnError('MTM Upload', numError, varMessage,
                                --varOperation, varError);
                raise_application_error(-20101, varError);

              when others then
                numError := SQLCODE;
                varError := SQLERRM;
                varError := GConst.fncReturnError('MTM Upload', numError, varMessage,
                                varOperation, varError);
                raise_application_error(-20101, varError);
            end;







        elsif varTemp=Gconst.UpdateBankRefNo then
          begin
            --varReference := GConst.fncXMLExtract(xmlTemp, 'LINK_BATCH_NUMBER', varTemp);
            varOperation := 'Updating Batch Numbers';
            varXPath := '//Rows/Row';
            nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
            varOperation := 'Update Batch No ' || varXPath;

            for numTemp in 1..xmlDom.getLength(nlsTemp)
            Loop
                varTemp := varXPath || '[@Num="' || numTemp || '"]/DealNo';
                varoperation :='Extracting Data from XML' || varTemp;
                varReference := GConst.fncXMLExtract(xmlTemp,varTemp,varReference, Gconst.TYPENODEPATH);

                varTemp := varXPath || '[@Num="' || numTemp || '"]/UserRefNo';
                varoperation :='Extracting Data from XML' || varTemp;
                varReference1 := GConst.fncXMLExtract(xmlTemp,varTemp,varReference1, Gconst.TYPENODEPATH);

                update trtran071 set copt_user_reference= varReference1
                 where copt_deal_number =varReference
                   and copt_record_status not in(10200005,10200006);

            end loop;
        end;
        end if;
   end if;

-- abhijit added on 28/08/2012 for exchange mtm upload

--     if EditType =Gconst.SYSEXCHMTMUPDATE then --Added By Sivadas on 18DEC2011
--
--       -- delete from temp;
--           datWorkDate   := GConst.fncXMLExtract(xmlTemp, 'NSER_UPLOAD_DATE', datWorkDate);
--           insert into temp values(datWorkDate, datWorkDate);
--              begin
--              delete from trtran077
--              where
--              nser_upload_date=datWorkDate;
--               exception
--                when no_data_found then
--                  -- Delete all rows updated till now
--              insert into temp values(datWorkDate,datWorkDate);
--                delete from trtran077
--                where
--                nser_upload_date=datWorkDate;
--                commit;
--                 numError := 0;
--                 varError := 'No deal number found for ' || varReference || ' or is in process complete status!';
--                 raise_application_error(-20101, varError);
--                 when others then
--                  numError := SQLCODE;
--                  varError := SQLERRM;
--                  varError := GConst.fncReturnError('MTM Upload', numError, varMessage,
--                                  varOperation, varError);
--                  raise_application_error(-20101, varError);
--              end;
--              end if;
--
      --abhijit added
    if EditType =Gconst.SYSEXCHMTMUPDATE then --Added By Sivadas on 18DEC2011
           ---insert into temp values('siva', 'Misc updates');commit;

           begin
               datWorkDate   := GConst.fncXMLExtract(xmlTemp, 'NSER_UPLOAD_DATE', datWorkDate);
               numSerial := to_number(GConst.fncXMLExtract(xmlTemp, 'NSER_SERIAL_NUMBER', numSerial));
               varReference := GConst.fncXMLExtract(xmlTemp, 'NSER_BATCH_NUMBER', varReference);

               --insert into temp values('siva', 'Delete calling');commit;
               if numSerial = 1 then
                  delete from trtran077
                   where nser_upload_date=datWorkDate
                     and NSER_BATCH_NUMBER <> varReference;

                  --insert into temp values('siva', 'Delete called!');
                  --commit;
               end if;
         exception
           when others then
              null;
               --insert into temp values('EXCHNG', 'Exception1');
              --commit;
           end;
    end if;

--      if numAction = GConst.ADDSAVE then
--          numError := fncCompleteUtilization(varReference, Gconst.UTILOPTIONHEDGEDEAL,
--                        datWorkDate, numserial);
----        update trtran001
----          set deal_record_status = GConst.STATUSPOSTCANCEL,
----          deal_process_complete = GConst.OPTIONYES,
----          deal_complete_date = datWorkDate
----          where deal_deal_number = varReference
----          and deal_serial_number = numSerial;
--      elsif numAction = GConst.DELETESAVE then
--        update trtran071
--          set copt_record_status = GConst.STATUSENTRY,
--          copt_process_complete = GConst.OPTIONNO,
--          copt_complete_date = NULL
--          where copt_deal_number = varReference
--          and copt_serial_number = numSerial;
--      End if;


    --end if

      if EditType =Gconst.SYSSTRESSINSERTSUB then
      varReference := GConst.fncXMLExtract(xmlTemp, 'STRE_REFERENCE_NUMBER', varTemp);
      varOperation := 'Data into Child Table';
      varXPath := '//STRESSTESTSENSITIVESUB/ROWSUB';
      nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
      numTemp:=1;
      varOperation := 'Data into Child Table';

      Delete from trsystem061
       where stre_reference_number=varReference;

      for numSub in 0..xmlDom.getLength(nlsTemp) -1
      Loop
          nodTemp := xmlDom.Item(nlsTemp, numSub);
          nmpTemp:= xmlDom.getAttributes(nodTemp);
          nodTemp := xmlDom.Item(nmpTemp, 0);
          numTemp := to_number(xmlDom.GetNodeValue(nodTemp));

          varTemp := varXPath || '[@NUM="' || numTemp || '"]/BaseCurrency';
          varoperation :='Extracting Data from XML' || varTemp;
          numCode := GConst.fncXMLExtract(xmlTemp,varTemp,numCode, Gconst.TYPENODEPATH);

          varTemp := varXPath || '[@NUM="' || numTemp || '"]/OtherCurrency';
          varoperation :='Extracting Data from XML' || varTemp;
          numCode1 := GConst.fncXMLExtract(xmlTemp,varTemp,numCode1, Gconst.TYPENODEPATH);

          varTemp := varXPath || '[@NUM="' || numTemp || '"]/ForwardMonth';
          varoperation :='Extracting Data from XML' || varTemp;
          numCode2 := GConst.fncXMLExtract(xmlTemp,varTemp,numCode2, Gconst.TYPENODEPATH);

          varTemp := varXPath || '[@NUM="' || numTemp || '"]/PriceChange';
          varoperation :='Extracting Data from XML' || varTemp;
          numFCY := GConst.fncXMLExtract(xmlTemp,varTemp,numFCY, Gconst.TYPENODEPATH);
        varOperation := 'Insertting data into Child Table' ;
          insert into trsystem061
           values (varReference,numCode,numCode1,numCode2,numFCY);

         numTemp:=numTemp+1;
      end loop;

   end if;
   
--   if EditType =Gconst.SYSCOMHEDGELINKING then 
--       varOperation := 'Extract Details ';
--    varReference := GConst.fncXMLExtract(xmlTemp, 'CMDL_DEAL_NUMBER', varTemp);
--    --numCode := GConst.fncXMLExtract(xmlTemp, 'MFCL_TRANSACTION_TYPE', numCode);
--    
--    
--    numcode1 := Gconst.fncXMLExtract(xmlTemp, 'MFCL_SCHEME_CODE', numCode1);
--    datTemp := GConst.fncXMLExtract(xmlTemp, 'MFCL_REFERENCE_DATE', datTemp);
--    numFcy := GConst.fncXMLExtract(xmlTemp, 'MFCL_TRANSACTION_AMOUNT', numFcy);
--    numRate := GConst.fncXMLExtract(xmlTemp, 'MFCL_TRANSACTION_QUANTITY', numRate);
--    
--    varOperation := 'Extract data for Linking ';
--    varXPath := '//STRESSTESTSENSITIVESUB/ROWSUB';
--    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--    numTemp:=1;
--    varOperation := 'Data into Child Table';
--
--      Delete from trsystem061
--       where stre_reference_number=varReference;
--
--      for numSub in 0..xmlDom.getLength(nlsTemp) -1
--      Loop
--      
--      
--    insert into trtran004A(HGCO_COMPANY_CODE,HGCO_TRADE_REFERENCE,HGCO_DEAL_NUMBER,
--          HGCO_DEAL_SERIAL,HGCO_HEDGED_QTY,HGCO_HEDGED_AMT,HGCO_CREATE_DATE,
--          HGCO_RECORD_STATUS,HGCO_HEDGING_WITH,HGCO_MULTIPLE_CURRENCY)
--          
--     
--   end if;
   --------Stress Analysis Ends---------------

-- Following Logic is for Mutual Fund Redemtion - Both for Switch-in
-- as well as regular redemption options - TMM 07/12/2014

    If Edittype = Gconst.SYSHEDGELINKINGCANCEL Then
        VarOperation:= 'Extracting Linking CancellationDeals';
        --Numcode:= GCONST.FNCXMLEXTRACT(xmlTemp, 'LinkingCancelledDeals', Numcode);
        Numcode:=12400002;
        VarOperation:= ' Exhecing Numcode' || Numcode;
        

              
        if Numcode= Gconst.OptionYes then
           
                    varXPath := '//HEDGEREGISTER/ROW';
          nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
          varOperation := 'Extracting Rows ' || varXPath;
          for numTemp in 1..xmlDom.getLength(nlsTemp)
          Loop
            
              varTemp := varXPath || '[@NUM="' || numTemp || '"]/HEDG_TRADE_REFERENCE';
              varoperation :='Extracting Data from XML' || varTemp;
              VARREFERENCE := GCONST.FNCXMLEXTRACT(xmlTemp,varTemp, VARREFERENCE,Gconst.TYPENODEPATH);
              varTemp := varXPath || '[@NUM="' || numTemp || '"]/HEDG_DEAL_NUMBER';
              varoperation :='Extracting Data from XML' || varTemp;
              VARREFERENCE1 := GCONST.FNCXMLEXTRACT(xmlTemp, varTemp, VARREFERENCE1,Gconst.TYPENODEPATH);
                
                update trtran004 set Hedg_record_status=10200010
                 where HEDG_TRADE_REFERENCE= VARREFERENCE
                 and HEDG_DEAL_NUMBER= VARREFERENCE1;
            end loop;
        end if;
     END IF;

    If Edittype = Gconst.SYSRBIREFRATE Then
        VarOperation:= 'Extracting Linking CancellationDeals';
        if  numAction = GConst.ADDSAVE then       
          varXPath := '//RBIREFERENCERATE/ROW';
          nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
          varOperation := 'Extracting Rows ' || varXPath;
          for numSub in 0..xmlDom.getLength(nlsTemp) -1
          Loop
              nodTemp := xmlDom.Item(nlsTemp, numSub);
              nmpTemp:= xmlDom.getAttributes(nodTemp);
              nodTemp := xmlDom.Item(nmpTemp, 0);
              numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
    
              varTemp := varXPath || '[@NUM="' || numTemp || '"]/CurrencyCode';
              varoperation :='Extracting Data from XML' || varTemp;
              numCode := GConst.fncXMLExtract(xmlTemp,varTemp,numCode, Gconst.TYPENODEPATH);
    
              varTemp := varXPath || '[@NUM="' || numTemp || '"]/EffectiveDate';
              varoperation :='Extracting Data from XML' || varTemp;
              datTemp := GConst.fncXMLExtract(xmlTemp,varTemp,datTemp, Gconst.TYPENODEPATH);
    
              varTemp := varXPath || '[@NUM="' || numTemp || '"]/Rate';
              varoperation :='Extracting Data from XML' || varTemp;
              numRate := GConst.fncXMLExtract(xmlTemp,varTemp,numRate, Gconst.TYPENODEPATH);
              insert into TRSYSTEM017
              (lrat_currency_code,lrat_for_currency,lrat_effective_date,
              lrat_serial_number,LRAT_RBI_USD,lrat_record_status,lrat_add_date)
              values (numCode,30400003,datTemp,1,numRate,10200003,sysdate);
          end loop;
       END IF; 
     END IF;
     
    if EditType = GConst.SYSMUTUALSWITCHIN then

    varOperation := 'Processing Mutual Fund Redemption';
    varReference := GConst.fncXMLExtract(xmlTemp, 'MFCL_REFERENCE_NUMBER', varTemp);
    numCode := GConst.fncXMLExtract(xmlTemp, 'MFCL_TRANSACTION_TYPE', numCode);
    numcode1 := Gconst.fncXMLExtract(xmlTemp, 'MFCL_SCHEME_CODE', numCode1);
    datTemp := GConst.fncXMLExtract(xmlTemp, 'MFCL_REFERENCE_DATE', datTemp);
    numFcy := GConst.fncXMLExtract(xmlTemp, 'MFCL_TRANSACTION_AMOUNT', numFcy);
    numRate := GConst.fncXMLExtract(xmlTemp, 'MFCL_TRANSACTION_QUANTITY', numRate);
--  Regular insert to trtran049 in Add Mode, nothing else to be done



    if  numAction != GConst.ADDSAVE then

      if numAction = GConst.DELETESAVE then
        varOperation := 'Deleting the redemption in Link Table';
        update trtran049A
          set redm_record_status = 10200006
          where redm_redemption_reference = varReference
          and redm_record_status not in (10200005,10200006);


        varOperation := 'Deleting the Switchin Transaction, if any';
        update trtran048
          set mftr_record_status = 10200006
          where mftr_reference_number in
          (select NVL(mfcl_switchin_number,0)
            from trtran049
            where mfcl_reference_number = varReference);

       varOperation := 'Reverse  the complete status';   ---added by prasanta
         update trtran048
          set mftr_process_complete = 12400002,
              MFTR_COMPLETE_DATE=null
          where mftr_reference_number in
              (select REDM_INVEST_REFERENCE
                from trtran049A
                where REDM_REDEMPTION_REFERENCE = varReference);

      elsif numAction = GConst.CONFIRMSAVE then
        varOperation := 'Confirming the redemption in Link Table';
        update trtran049A
          set redm_record_status = 10200003
          where redm_redemption_reference = varReference
            and redm_record_status not in (10200005,10200006);   --added by prasanta.



        varOperation := 'Confirming the Switchin Transaction, if any';
        update trtran048
          set mftr_record_status = 10200003
          where mftr_reference_number in
          (select NVL(mfcl_switchin_number,0)
            from trtran049
            where mfcl_reference_number = varReference);
      elsif numAction = GConst.EDITSAVE then
        varOperation := 'Deleting Old Transactions, if any';
        update trtran049A
          set redm_record_status = 10200005
          where redm_redemption_reference = varReference
           and redm_record_status not in (10200005,10200006);   --added by prasanta.

        update trtran048
          set mftr_process_complete = 12400001,
          mftr_complete_date = datworkdate   --need to check prasanta i think do not required as already done in below.
          where mftr_reference_number in
          (select redm_invest_reference
            from trtran049A
            where redm_redemption_reference = varReference
            and REDM_PROCESS_COMPLETE=12400001 );

       varOperation := 'Editing the Switchin Transaction quantity and nav, if any';  --added by prasanta.
        update trtran048
          set (mftr_transaction_quantity,mftr_transaction_price,mftr_reference_date,mftr_transaction_amount) =
                      (select  mfcl_switchin_qty, mfcl_switchin_nav,MFCL_SWITCHIN_NAVDATE,mfcl_maturity_amount from trtran049
                                where mfcl_reference_number = varReference)
           where mftr_reference_number in
                  (select NVL(mfcl_switchin_number,0)
                    from trtran049
                    where mfcl_reference_number = varReference);

-- Mutual Fund Redemtion Logic
     varOperation := 'Adjusting Redemptions against Transactions on FIFO basis';
      select  MFCL_PROFIT_LOSS,mfcl_transaction_price,mfcl_transaction_amount ,mfcl_transaction_quantity
         into numpnlamt ,numrate1 ,numfcy5 ,numRate2
           FROM trtran049
      where mfcl_reference_number = varReference;     
      for curInvest in
        (select mftr_reference_number, mftr_transaction_date, mftr_transaction_price,
          pkgForexProcess.fncGetOutstanding(mftr_reference_number, 0, 20, 1,
            datTemp) mftr_transaction_quantity,
          pkgForexProcess.fncGetOutstanding(mftr_reference_number, 0, 20, 2,
            datTemp) mftr_transaction_amount,
            csmt_balance_amount,csmt_debit_amount
          from trtran048 ,trsystem993
          where mftr_scheme_code = numCode1
          --and mftr_transaction_date < datTemp --commented to include same day transaction
          and mftr_reference_date < datTemp
          and mftr_record_status between 10200001 and 10200004
          and csmt_account_number=mftr_reference_number
--          and mftr_reference_number not in
--          (select NVL(redm_invest_reference,0)
--            from trtran049A
--            where redm_process_complete = 12400001
--            and redm_record_status between 10200001 and 10200004)
          order by mftr_transaction_date)
          Loop
---principal
             if round(curInvest.csmt_balance_amount,2) > numfcy5 then
               -- if curInvest.csmt_debit_amount =numRate2 then
                    numpramt:=numfcy5 ;
                    numfcy5:=0;
--                else
--                    numpramt:=round(curInvest.csmt_balance_amount,2) ;
--                    numfcy5:=numfcy5-numpramt ;
--                   
--                end if;
             else
                if curInvest.csmt_debit_amount =numRate2 then
                    numpramt:=numfcy5 ;
                    numfcy5:=0 ;
                elsif (curInvest.mftr_transaction_quantity-curInvest.csmt_debit_amount) > 0 then
                    numpramt:=numfcy5 ;
                    numfcy5:=numfcy5-numpramt ;
                else
                    numpramt:=round(curInvest.csmt_balance_amount,2) ;
                    numfcy5:=numfcy5-numpramt ;
                end if;
             end if;
--pnl             
             numfcy6:=Round(((numrate1  * curInvest.csmt_debit_amount)- numpramt) ,2) ;
             if numfcy6 >= numpnlamt then
                    numfcy6:=numpnlamt ;
                    numpnlamt:=0;
                
             else
                if curInvest.csmt_debit_amount =numRate2 then
                    numfcy6:=numpnlamt ;
                    numpnlamt:=0;
                elsif (curInvest.mftr_transaction_quantity-curInvest.csmt_debit_amount) > 0 then
                     numfcy6:=numpnlamt ;
                     numpnlamt:=numpnlamt-numfcy6 ;
                else
                    numfcy6:=Round(((numrate1  * curInvest.csmt_debit_amount)- numpramt) ,2) ;
                    numpnlamt:=numpnlamt-numfcy6 ;
                end if;
             END IF;          
          
              insert into trtran049A(redm_redemption_reference,redm_serial_number,
                redm_invest_reference, redm_transaction_date, redm_noof_units,redm_invest_amount,
                redm_process_complete, redm_complete_date, redm_redeem_nav, redm_record_status,
                redm_redeem_pandl)
            select mfcl_reference_number,
              (select nvl(max(redm_serial_number),0) + 1
                from trtran049A
                WHERE redm_redemption_reference = varReference),
              curInvest.mftr_reference_number, mfcl_reference_date, curInvest.csmt_debit_amount, numpramt,--curInvest.csmt_balance_amount,
--              curInvest.mftr_reference_number, mfcl_reference_date, curInvest.csmt_debit_amount,curInvest.csmt_balance_amount,
              decode( sign(curInvest.mftr_transaction_quantity-curInvest.csmt_debit_amount) ,1,12400002,12400001),
              decode( sign(curInvest.mftr_transaction_quantity-curInvest.csmt_debit_amount) ,1,null,mfcl_reference_date),
              mfcl_transaction_price, 10200001,
              --Round(((mfcl_transaction_price  * curInvest.csmt_debit_amount)- curInvest.csmt_balance_amount) ,2)
              numfcy6              
              from trtran049
              where mfcl_reference_number = varReference;
              if (curInvest.mftr_transaction_quantity-curInvest.csmt_debit_amount) <=0 then
                 update trtran048
                  set mftr_process_complete = 12400001,
                  mftr_complete_date = datTemp
                  where mftr_reference_number = curInvest.mftr_reference_number;
              end if;
--          if curInvest.mftr_transaction_quantity <= numRate then
--            varOperation := 'Inserting Completed transactions into FIFO table';
--            insert into trtran049A(redm_redemption_reference,redm_serial_number,
--            redm_invest_reference, redm_transaction_date, redm_noof_units,
--            redm_invest_amount,redm_process_complete, redm_complete_date,
--            redm_redeem_nav, redm_record_status,redm_redeem_pandl)
--            select mfcl_reference_number,
--              (select nvl(max(redm_serial_number),0) + 1
--                from trtran049A
--                where redm_redemption_reference = varReference),
--              curInvest.mftr_reference_number,mfcl_reference_date,curInvest.mftr_transaction_quantity,
--              --curInvest.mftr_transaction_amount,
--              -- pkgfixeddepositproject.fncgetbalance(numCode1,curInvest.mftr_reference_number,curInvest.mftr_transaction_quantity,curInvest.mftr_transaction_price,mfcl_transaction_price ,1),
--              ---(select csmt_balance_amount from trsystem993 where csmt_account_number=curInvest.mftr_reference_number),
--               curInvest.csmt_balance_amount, 12400001,mfcl_reference_date,mfcl_transaction_price, 10200001,
--            --  Round((mfcl_transaction_price - curInvest.mftr_transaction_price) * curInvest.mftr_transaction_quantity,2)
--               Round(( mfcl_transaction_price * curInvest.mftr_transaction_quantity)-curInvest.csmt_balance_amount
--                      -- pkgfixeddepositproject.fncgetbalance(numCode1,curInvest.mftr_reference_number,curInvest.mftr_transaction_quantity,curInvest.mftr_transaction_price,mfcl_transaction_price ,1)
--                      --(select csmt_balance_amount from trsystem993 where csmt_account_number=curInvest.mftr_reference_number)
--                  ,2)
--              from trtran049
--              where mfcl_reference_number = varReference;
--
--
--            varOperation := 'Updating transaction table with Process COmplete Status';
--            update trtran048
--              set mftr_process_complete = 12400001,
--              mftr_complete_date = datTemp
--              where mftr_reference_number = curInvest.mftr_reference_number;
--
--            numRate := numRate - curInvest.mftr_transaction_quantity;
--         --   numFcy := Round((numRate * curInvest.mftr_transaction_price),2); commented by prasanta
--          elsif numRate > 0 then
--            varOperation := 'Inserting Partial transactions into FIFO table';
--             numFcy := Round((numRate * curInvest.mftr_transaction_price),2); --added by Prasanta
--
--    				insert into trtran049A(redm_redemption_reference,redm_serial_number,
--              redm_invest_reference, redm_transaction_date, redm_noof_units,redm_invest_amount,
--              redm_process_complete, redm_complete_date, redm_redeem_nav, redm_record_status,
--              redm_redeem_pandl)
--            select mfcl_reference_number,
--              (select nvl(max(redm_serial_number),0) + 1
--                from trtran049A
--                where redm_redemption_reference = varReference),
--              curInvest.mftr_reference_number, mfcl_reference_date, numRate,
--              --numFcy,
--              -- pkgfixeddepositproject.fncgetbalance(numCode1,curInvest.mftr_reference_number,numRate,curInvest.mftr_transaction_price,mfcl_transaction_price ,2),
--              (select csmt_balance_amount from trsystem993 where csmt_account_number=curInvest.mftr_reference_number),
--              12400002, NULL,mfcl_transaction_price, 10200001,
--             -- Round((mfcl_transaction_price - curInvest.mftr_transaction_price) * numRate,2)
--              Round((mfcl_transaction_price  * numRate)-
--              -- pkgfixeddepositproject.fncgetbalance(numCode1,curInvest.mftr_reference_number,numRate,curInvest.mftr_transaction_price,mfcl_transaction_price ,2)
--                (select csmt_balance_amount from trsystem993 where csmt_account_number=curInvest.mftr_reference_number)
--              ,2)
--              from trtran049
--              where mfcl_reference_number = varReference;
--            exit;
--
--          End if;



        End Loop;
      End if;

    End if;

-- Switch In Logic
    if numcode in (Gconst.MFFULLSWITCHIN,Gconst.MFPARTIALSWITCHIN) and  numAction = GConst.ADDSAVE then
      varOperation := 'Processing Switch-in Request';
      varReference1:= 'MFIN/' || GConst.fncGenerateSerial(Gconst.SERIALMUTUALFUND, 0);

      insert into trtran048
        (mftr_company_code,mftr_location_code,mftr_reference_number,mftr_transaction_date,
        mftr_reference_date,mftr_scheme_code,mftr_nav_code,mftr_transaction_type,
        mftr_transaction_amount,mftr_transaction_price,mftr_transaction_quantity,
        mftr_lockin_duedate,mftr_entryload_charges,mftr_exitload_charges,
        mftr_transaction_charges,mftr_other_charges,mftr_bank_code,mftr_current_ac,
        mftr_payment_through,mftr_user_reference,mftr_broker_code,mftr_cheque_number,
        mftr_user_remarks,mftr_process_complete,mftr_complete_date,mftr_add_date,
        mftr_create_date,mftr_entry_details,mftr_record_status)
      select mfcl_company_code,mfcl_location_code,varReference1,mfcl_transaction_date,
        mfcl_switchin_navdate,mfcl_switchin_scheme,mfsc_nav_code,mfcl_transaction_type,
        mfcl_maturity_amount,mfcl_switchin_nav,mfcl_switchin_qty,
        null,mfsc_entry_load,mfsc_exit_load,0,0,30699999,null,
        43199999,mfsc_folio_number,43399999,null,
        pkgReturnCursor.fncGetDescription(mfcl_transaction_type,1) || ' From Scheme: ' ||
        pkgReturnCursor.fncGetDescription(mfcl_scheme_code,1), 12400002,null,
        datWorkDate, sysdate,null,10200001
        from trtran049, trmaster404
        where mfcl_switchin_scheme = mfsc_scheme_code
        and mfcl_reference_number = varReference
        and mfcl_record_status not in (10200005,10200006);

      update trtran049
        set mfcl_switchin_number = varReference1
        where mfcl_reference_number = varReference
        and mfcl_record_status not in (10200005,10200006);
  End if;




-- if EditType =Gconst.SYSMUTUALSWITCHIN then
--      varOperation := 'Entered into Switch IN Operations' ;
--      varReference := GConst.fncXMLExtract(xmlTemp, 'MFCL_REFERENCE_NUMBER', varTemp);
--      numSerial := GConst.fncXMLExtract(xmlTemp, 'MFCL_SERIAL_NUMBER', varTemp);
--      numCode := GConst.fncXMLExtract(xmlTemp, 'MFCL_TRANSACTION_TYPE', varTemp);
--      datTemp :=GConst.fncXMLExtract(xmlTemp, 'MFCL_REFERENCE_DATE', datTemp);
--      numcode2 := Gconst.fncXMLExtract(xmlTemp, 'MFCL_SCHEME_CODE', NumCode2);
--    if ((numcode = Gconst.MUTUALFUND_REDEPTION_FULL) or  (numCode = Gconst.MUTUALFUND_SWITCHIN_FULL)) then
--       if(numAction != GConst.ADDSAVE) then
--          update trtran048 set MFTR_REDEMPTION_NUMBER= varReference,
--                               mftr_process_complete= 12400001,
--                               mftr_complete_date = datTemp
--              where mftr_scheme_code=numcode2
--              and mftr_process_complete =12400002;
--
--          update trtran049 set mfCL_process_complete= 12400001,
--                               mfCL_complete_date = datTemp
--              where MFCL_scheme_code=numcode2
--              and MFCL_process_complete =12400002;
--
--       elsif (numAction = GConst.DELETESAVE) then
--          update trtran048 set MFTR_REDEMPTION_NUMBER= null,
--                               mftr_process_complete= 12400002,
--                               mftr_complete_date = null
--              where mftr_scheme_code=numcode2
--              and MFTR_REDEMPTION_NUMBER= varReference;
--
--       end if;
--    end if;
--    if ((numCode = Gconst.MUTUALFUND_SWITCHIN_FULL) or (numCode = Gconst.MUTUALFUND_SWITCHIN_PARTIAL)) then
--      varOperation := 'Entered into Switch IN Operations Inside the Conditions' ;
--      if (numAction = GConst.EDITSAVE) or (numAction = GConst.DELETESAVE) then
--         update trtran048 set mftr_record_status =10200006
--           where MFTR_REDEMPTION_NUMBER= varReference
--           and mftr_scheme_code= numCode;
--
--        elsif((numAction = GConst.ADDSAVE) or (numAction = GConst.EDITSAVE))  then
--
--            varReference1:= 'MF/' || GConst.fncGenerateSerial(Gconst.SERIALMUTUALFUND, 0);
--
--            datTemp1 :=GConst.fncXMLExtract(xmlTemp, 'MFCL_TRANSACTION_DATE', datTemp1);
--            numcode1 := Gconst.fncXMLExtract(xmlTemp, 'MFCL_SWITCHIN_SCHEME', NumCode1);
--            numFcy := Gconst.fncXMLExtract(xmlTemp, 'MFCL_SWITCHIN_NAV', numFcy);
--            numFcy1 := Gconst.fncXMLExtract(xmlTemp, 'MFCL_SWITCHIN_QTY', numFcy1);
--            if (numCode = Gconst.MUTUALFUND_SWITCHIN_FULL) then
--              numFcy2 := Gconst.fncXMLExtract(xmlTemp,'MFCL_MATURITY_AMOUNT',NumFcy2);
--            elsif (numCode = Gconst.MUTUALFUND_SWITCHIN_PARTIAL) then
--              numFcy2 := Gconst.fncXMLExtract(xmlTemp,'MFCL_TRANSACTION_AMOUNT',NumFcy2);
--            end if;
--            if numFcy2>0 then
--               insert into trtran048
--                ( MFTR_COMPANY_CODE,MFTR_REFERENCE_NUMBER,MFTR_REFERENCE_DATE,MFTR_SCHEME_CODE,
--                  MFTR_BUY_SELL,MFTR_TRANSACTION_AMOUNT,MFTR_TRANSACTION_PRICE,MFTR_TRANSACTION_QUANTITY,
--                  MFTR_ENTRYLOAD_CHARGES,MFTR_EXITLOAD_CHARGES,MFTR_OTHER_CHARGES,MFTR_TRANSACTION_CHARGES,
--                  MFTR_LOCKIN_DUEDATE,MFTR_RECORD_STATUS,MFTR_ADD_DATE,MFTR_CREATE_DATE,MFTR_PROCESS_COMPLETE,
--                  MFTR_LOCATION_CODE,MFTR_TRANSACTION_DATE,MFTR_BANK_CODE,MFTR_CURRENT_AC,
--                  MFTR_PAYMENT_THROUGH,MFTR_USER_REFERENCE,MFTR_TRANSACTION_TYPE,MFTR_USER_REMARKS,MFTR_Broker_Code,MFTR_REDEMPTION_SERIAL)
--                values  (30100001,varReference1,datTemp,numcode1,
--                  numCode,numFcy2,numFcy,numFcy1,
--                  0,0,0,0,
--                  null,10200001,sysdate,sysdate,12400002,
--                  30299999,datTemp1,30699999,null,
--                  43199999	,null,numCode,'Switch in from ' || numSerial,
--                  43399999,numSerial);
--
--               update trtran049 set MFCL_SWITCHIN_NUMBER= varReference1
--                 where MFCL_REFERENCE_NUMBER=varReference;
--
--            end if;
--      elsif(numAction = GConst.CONFIRMSAVE) then
--
--          update trtran049 set MFCL_RECORD_STATUS =GConst.CONFIRMSAVE
--            where  MFCL_REFERENCE_NUMBER=varReference
--                  and MFCL_SERIAL_NUMBER= numSerial;
--       end if;
--
--     end if;

--            docFinal := xmlDom.newDomDocument(xmlTemp);
--            nodFinal := xmlDom.makeNode(docFinal);
--
--            nodTemp := xslProcessor.selectSingleNode(nodFinal, 'MFCL_SWITCHIN_NUMBER');
--
--            numError:= Gconst.fncSetNodeValue(nodFinal,nodTemp,varReference1);
--            dbms_lob.createTemporary (clbTemp,  TRUE);
--            xmlDom.WriteToClob(nodFinal, clbTemp);


--       elsif(numAction = GConst.DELETESAVE) then
--           delete from trtran048 where
--             MFTR_REFERENCE_NUMBER=(select MFCL_SWITCHIN_NUMBER from trtran049
--                                     where MFCL_REFERENCE_NUMBER=varReference);



 end if;



 if EditType=Gconst.SYSBANKCHARGEINSERT then 
          varOperation := 'Add multiple record to trtran015d';
     
          varTemp2 := '//BANKCHARGEMASTERNEW//ROW';  
          nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);         
          varreference:=GConst.fncXMLExtract(xmlTemp, 'CHAR_REFERENCE_NUMBER', varreference);          
          numcode:=  GConst.fncXMLExtract(xmlTemp, 'CHAR_COMPANY_CODE', numcode);
          numcode1:=  GConst.fncXMLExtract(xmlTemp, 'CHAR_LOCATION_CODE', numcode1);
        --  numcode2:=  GConst.fncXMLExtract(xmlTemp, 'CHAR_LOB_CODE', numcode2);
           numcode2:=  33399999;
          numSerial:=GConst.fncXMLExtract(xmlTemp, 'CHAR_SERIAL_NUMBER', numSerial);
          numcode3:=GConst.fncXMLExtract(xmlTemp,'CHAR_BANK_CODE',numcode3);          
          datTemp:=  GConst.fncXMLExtract(xmlTemp, 'CHAR_EFFECTIVE_DATE', datTemp); 
          numcode4:=GConst.fncXMLExtract(xmlTemp, 'CHAR_ACCOUNT_HEAD', numcode4);           
          numcode5:=GConst.fncXMLExtract(xmlTemp, 'CHAR_LIMIT_TYPE', numcode5);
          numcode6:=GConst.fncXMLExtract(xmlTemp, 'CHAR_BILL_EVENT', numcode6);
          numcode7:=GConst.fncXMLExtract(xmlTemp, 'CHAR_TIMING_EVENT', numcode7);
          numcode8:=GConst.fncXMLExtract(xmlTemp, 'CHAR_ROUNDING_UPTO', numcode8);        
          numcode9:=GConst.fncXMLExtract(xmlTemp, 'CHAR_CHARGING_EVENT', numcode9);          
          numcode10:=GConst.fncXMLExtract(xmlTemp, 'CHAR_BASED_ON', numcode10);
          numcode11:=GConst.fncXMLExtract(xmlTemp, 'CHAR_PRODUCT_TYPE', numcode11);
          numcode12:=GConst.fncXMLExtract(xmlTemp, 'CHAR_APPLICABLE_BILL', numcode12);          
          numcode13:=GConst.fncXMLExtract(xmlTemp, 'CHAR_MIN_AMOUNT', numcode13);
          numcode14:=GConst.fncXMLExtract(xmlTemp, 'CHAR_MAX_AMOUNT', numcode14); 
          numCode15:=GConst.fncXMLExtract(xmlTemp, 'CHAR_CONSOLIDATE_TYPE', numcode15); 
    if  numAction in(GConst.ADDSAVE) then
          delete from trtran015d 
          where CHAR_REFERENCE_NUMBER=varreference; 
          
          varTemp2 := '//PERIODTYPENODE//ROW';       
          nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);         
          numSerial:=1;
          if(xmlDom.getLength(nlsTemp)>0) then
          
          for numTemp in 1..xmlDom.getLength(nlsTemp)
           Loop
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/PeriodType';
              varoperation :='Extracting Data from XML' || varTemp;
              numPeriodType := GConst.fncXMLExtract(xmlTemp, varTemp, numPeriodType, Gconst.TYPENODEPATH);
              
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/PeriodUpto';
              varoperation :='Extracting Data from XML' || varTemp;
              numPeriodUpto := GConst.fncXMLExtract(xmlTemp, varTemp, numPeriodUpto, Gconst.TYPENODEPATH);
              
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/AmountFrom';
              varoperation :='Extracting Data from XML' || varTemp;
              numAmountFrom := GConst.fncXMLExtract(xmlTemp, varTemp, numAmountFrom, Gconst.TYPENODEPATH);
              
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/AmountUpto';
              varoperation :='Extracting Data from XML' || varTemp;
              numAmountUpto := GConst.fncXMLExtract(xmlTemp, varTemp, numAmountUpto, Gconst.TYPENODEPATH);
              
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/PercentType';
              varoperation :='Extracting Data from XML' || varTemp;
              numPercentType := GConst.fncXMLExtract(xmlTemp, varTemp, numPercentType, Gconst.TYPENODEPATH);
              
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ChargesAmount';
              varoperation :='Extracting Data from XML' || varTemp;
              numCharges := GConst.fncXMLExtract(xmlTemp, varTemp, numCharges, Gconst.TYPENODEPATH);
              
              varoperation :='Inserting Data into BankChargeMaster table';
                  insert into trtran015d (CHAR_BANK_CODE,CHAR_EFFECTIVE_DATE,CHAR_ACCOUNT_HEAD,CHAR_LIMIT_TYPE,
                  CHAR_APPLICABLE_BILL,CHAR_PERIOD_TYPE,CHAR_PERIOD_UPTO,CHAR_AMOUNT_FROM,CHAR_AMOUNT_UPTO,CHAR_PERCENT_TYPE,
                  CHAR_CHARGES_AMOUNT,CHAR_SERVICE_TAX,CHAR_BILL_EVENT,CHAR_TIMING_EVENT,CHAR_ROUNDING_UPTO,CHAR_CREATE_DATE,
                  CHAR_ENTRY_DETAIL,CHAR_RECORD_STATUS,CHAR_CHARGING_EVENT,CHAR_BASED_ON,CHAR_REFERENCE_NUMBER,CHAR_PRODUCT_TYPE,
                  CHAR_MIN_AMOUNT,CHAR_MAX_AMOUNT,CHAR_COMPANY_CODE,CHAR_LOCATION_CODE,CHAR_LOB_CODE,CHAR_SERIAL_NUMBER,CHAR_CONSOLIDATE_TYPE)
                                   Values (numcode3,datTemp,numcode4,numcode5,
                                            numcode12,numPeriodType,nvl(numPeriodUpto,0),nvl(numAmountFrom,0),nvl(numAmountUpto,0),numPercentType,
                                            nvl(numCharges,0),0,numcode6,numcode7,numcode8,sysdate,
                                            null,10200001,numcode9,numcode10,varreference,numcode11,
                                            numcode13,numcode14,numcode,numcode1,numcode2,numSerial,numCode15
                                            );
                                            numSerial:=numSerial+1;
          end loop;
          else
          varoperation :='Inserting Data into BankChargeMaster table';
                  insert into trtran015d (CHAR_BANK_CODE,CHAR_EFFECTIVE_DATE,CHAR_ACCOUNT_HEAD,CHAR_LIMIT_TYPE,
                  CHAR_APPLICABLE_BILL,CHAR_PERIOD_TYPE,CHAR_PERIOD_UPTO,CHAR_AMOUNT_FROM,CHAR_AMOUNT_UPTO,CHAR_PERCENT_TYPE,
                  CHAR_CHARGES_AMOUNT,CHAR_SERVICE_TAX,CHAR_BILL_EVENT,CHAR_TIMING_EVENT,CHAR_ROUNDING_UPTO,CHAR_CREATE_DATE,
                  CHAR_ENTRY_DETAIL,CHAR_RECORD_STATUS,CHAR_CHARGING_EVENT,CHAR_BASED_ON,CHAR_REFERENCE_NUMBER,CHAR_PRODUCT_TYPE,
                  CHAR_MIN_AMOUNT,CHAR_MAX_AMOUNT,CHAR_COMPANY_CODE,CHAR_LOCATION_CODE,CHAR_LOB_CODE,CHAR_SERIAL_NUMBER,CHAR_CONSOLIDATE_TYPE)
                                     Values (numcode3,datTemp,numcode4,numcode5,
                                            numcode12,nvl(numPeriodType,23499999),nvl(numPeriodUpto,0),nvl(numAmountFrom,0),nvl(numAmountUpto,0),nvl(numPercentType,33799999),
                                            nvl(numCharges,0),0,numcode6,numcode7,numcode8,sysdate,
                                            null,10200001,numcode9,numcode10,varreference,numcode11,
                                            numcode13,numcode14,numcode,numcode1,numcode2,numSerial,numCode15
                                            );
      end if;
        varTemp2 := '//ScreenNameNode//ROW';       
        nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);   
        
          delete from trtran015e
        where chga_ref_number=varreference;  
     
          for numTemp in 1..xmlDom.getLength(nlsTemp)
           Loop  
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ScreenName';
              varoperation :='Extracting Data from XML' || varTemp;
              Varreference1 := GConst.fncXMLExtract(xmlTemp, varTemp, Varreference1, Gconst.TYPENODEPATH);
              
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ChargeEventnew';
              varoperation :='Extracting Data from XML' || varTemp;
              numChargeEvent := GConst.fncXMLExtract(xmlTemp, varTemp, numChargeEvent, Gconst.TYPENODEPATH);
              
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/CurrencyCode';
              varoperation :='Extracting Data from XML' || varTemp;
              numCurrency := GConst.fncXMLExtract(xmlTemp, varTemp, numCurrency, Gconst.TYPENODEPATH);
              
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/SanctionApplied';
              varoperation :='Extracting Data from XML' || varTemp;
              varSanctionApplied := GConst.fncXMLExtract(xmlTemp, varTemp, varSanctionApplied, Gconst.TYPENODEPATH);
              
             varoperation :='Inserting Data into BankChargeLinking table';
             insert into trtran015e(CHGA_COMPANY_CODE,CHGA_BANK_CODE,CHGA_EFFECTIVE_DATE,CHGA_CHARGE_TYPE,
                                    CHGA_CHARGING_EVENT,CHGA_SANCTION_APPLIED,CHGA_SCREEN_NAME,CHGA_CREATE_DATE,
                                    CHGA_ENTRY_DETAIL,CHGA_RECORD_STATUS,CHGA_CURRENCY_CODE,CHGA_LIMIT_TYPE,
                                    CHGA_LOCATION_CODE,CHGA_LOB_CODE,chga_ref_number)
                                    Values(numcode,numcode3,datTemp,numcode4,
                                    numChargeEvent,varSanctionApplied,Varreference1,sysdate,
                                    null,10200001,numCurrency,numcode5,
                                    numcode1,numcode2,varreference);
                                   -- insert into temp values(numcode||numcode3||datTemp||numcode4||numChargeEvent||varSanctionApplied||Varreference1||sysdate||null||10200001||numCurrency||numcode5||numcode1||numcode2||varreference);
          end loop;
        
    elsif  numAction in(GConst.EDITSAVE) then
--          update trtran015d 
--          set char_record_status=10200006
--          where CHAR_REFERENCE_NUMBER=varreference; 
--          
--          update tftran015e
--           set chga_record_status=10200006,CHGA_ENTRY_DETAIL=null
--           where chga_ref_number=varreference; 
          
--          varreference:= pkgGlobalMethods.fncGenerateSerial(GConst.SEARIALCHARGE, nodFinal);
--          varreference:='BCHA/'||varreference;
       --insert into temp2 values(varreference||'inside edit save'); 
              insert into trtran015d_audit select * from trtran015d where CHAR_REFERENCE_NUMBER=varreference
              and char_record_status not in(10200005,10200006);commit;
          --   insert into temp2 values(varreference||'123'); 
              delete from trtran015d where CHAR_REFERENCE_NUMBER=varreference;commit;
             -- insert into temp2 values(varreference||'345');
               insert into trtran015e_audit select * from trtran015e where chga_ref_number=varreference
              and chga_record_status not in(10200005,10200006);commit;
              
              delete from trtran015e where chga_ref_number=varreference;commit;
          
          varTemp2 := '//PERIODTYPENODE//ROW';       
          nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);         
          numSerial:=1;
        if(xmlDom.getLength(nlsTemp)>0) then
          for numTemp in 1..xmlDom.getLength(nlsTemp)
           Loop
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/PeriodType';
              varoperation :='Extracting Data from XML' || varTemp;
              numPeriodType := GConst.fncXMLExtract(xmlTemp, varTemp, numPeriodType, Gconst.TYPENODEPATH);
              
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/PeriodUpto';
              varoperation :='Extracting Data from XML' || varTemp;
              numPeriodUpto := GConst.fncXMLExtract(xmlTemp, varTemp, numPeriodUpto, Gconst.TYPENODEPATH);
              
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/AmountFrom';
              varoperation :='Extracting Data from XML' || varTemp;
              numAmountFrom := GConst.fncXMLExtract(xmlTemp, varTemp, numAmountFrom, Gconst.TYPENODEPATH);
              
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/AmountUpto';
              varoperation :='Extracting Data from XML' || varTemp;
              numAmountUpto := GConst.fncXMLExtract(xmlTemp, varTemp, numAmountUpto, Gconst.TYPENODEPATH);
              
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/PercentType';
              varoperation :='Extracting Data from XML' || varTemp;
              numPercentType := GConst.fncXMLExtract(xmlTemp, varTemp, numPercentType, Gconst.TYPENODEPATH);
              
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ChargesAmount';
              varoperation :='Extracting Data from XML' || varTemp;
              numCharges := GConst.fncXMLExtract(xmlTemp, varTemp, numCharges, Gconst.TYPENODEPATH);
              
              varoperation :='Inserting Data into BankChargeMaster table';
                  insert into trtran015d (CHAR_BANK_CODE,CHAR_EFFECTIVE_DATE,CHAR_ACCOUNT_HEAD,CHAR_LIMIT_TYPE,
                  CHAR_APPLICABLE_BILL,CHAR_PERIOD_TYPE,CHAR_PERIOD_UPTO,CHAR_AMOUNT_FROM,CHAR_AMOUNT_UPTO,CHAR_PERCENT_TYPE,
                  CHAR_CHARGES_AMOUNT,CHAR_SERVICE_TAX,CHAR_BILL_EVENT,CHAR_TIMING_EVENT,CHAR_ROUNDING_UPTO,CHAR_CREATE_DATE,
                  CHAR_ENTRY_DETAIL,CHAR_RECORD_STATUS,CHAR_CHARGING_EVENT,CHAR_BASED_ON,CHAR_REFERENCE_NUMBER,CHAR_PRODUCT_TYPE,
                  CHAR_MIN_AMOUNT,CHAR_MAX_AMOUNT,CHAR_COMPANY_CODE,CHAR_LOCATION_CODE,CHAR_LOB_CODE,CHAR_SERIAL_NUMBER,CHAR_CONSOLIDATE_TYPE)
                                     Values (numcode3,datTemp,numcode4,numcode5,
                                            numcode12,numPeriodType,nvl(numPeriodUpto,0),nvl(numAmountFrom,0),nvl(numAmountUpto,0),numPercentType,
                                            nvl(numCharges,0),0,numcode6,numcode7,numcode8,sysdate,
                                            null,10200001,numcode9,numcode10,varreference,numcode11,
                                            numcode13,numcode14,numcode,numcode1,numcode2,numSerial,numcode15
                                            );
                                            numSerial:=numSerial+1;
                                         --    insert into temp2 values(numSerial||'999');
          end loop;
          else
         -- insert into temp values(varreference||'Hari');
           varoperation :='Inserting Data into BankChargeMaster table';
                  insert into trtran015d (CHAR_BANK_CODE,CHAR_EFFECTIVE_DATE,CHAR_ACCOUNT_HEAD,CHAR_LIMIT_TYPE,
                  CHAR_APPLICABLE_BILL,CHAR_PERIOD_TYPE,CHAR_PERIOD_UPTO,CHAR_AMOUNT_FROM,CHAR_AMOUNT_UPTO,CHAR_PERCENT_TYPE,
                  CHAR_CHARGES_AMOUNT,CHAR_SERVICE_TAX,CHAR_BILL_EVENT,CHAR_TIMING_EVENT,CHAR_ROUNDING_UPTO,CHAR_CREATE_DATE,
                  CHAR_ENTRY_DETAIL,CHAR_RECORD_STATUS,CHAR_CHARGING_EVENT,CHAR_BASED_ON,CHAR_REFERENCE_NUMBER,CHAR_PRODUCT_TYPE,
                  CHAR_MIN_AMOUNT,CHAR_MAX_AMOUNT,CHAR_COMPANY_CODE,CHAR_LOCATION_CODE,CHAR_LOB_CODE,CHAR_SERIAL_NUMBER,CHAR_CONSOLIDATE_TYPE)
                                     Values (numcode3,datTemp,numcode4,numcode5,
                                            numcode12,nvl(numPeriodType,23499999),nvl(numPeriodUpto,0),nvl(numAmountFrom,0),nvl(numAmountUpto,0),nvl(numPercentType,33799999),
                                            nvl(numCharges,0),0,numcode6,numcode7,numcode8,sysdate,
                                            null,10200001,numcode9,numcode10,varreference,numcode11,
                                            numcode13,numcode14,numcode,numcode1,numcode2,numSerial,numcode15
                                            );
          end if;
          
        varTemp2 := '//ScreenNameNode//ROW';       
        nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);  
      
          for numTemp in 1..xmlDom.getLength(nlsTemp)
           Loop  
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ScreenName';
              varoperation :='Extracting Data from XML' || varTemp;
              Varreference1 := GConst.fncXMLExtract(xmlTemp, varTemp, Varreference1, Gconst.TYPENODEPATH);
              
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/ChargeEventnew';
              varoperation :='Extracting Data from XML' || varTemp;
              numChargeEvent := GConst.fncXMLExtract(xmlTemp, varTemp, numChargeEvent, Gconst.TYPENODEPATH);
              
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/CurrencyCode';
              varoperation :='Extracting Data from XML' || varTemp;
              numCurrency := GConst.fncXMLExtract(xmlTemp, varTemp, numCurrency, Gconst.TYPENODEPATH);
              
              varTemp := varTemp2 || '[@NUM="' || numTemp || '"]/SanctionApplied';
              varoperation :='Extracting Data from XML' || varTemp;
              varSanctionApplied := GConst.fncXMLExtract(xmlTemp, varTemp, varSanctionApplied, Gconst.TYPENODEPATH);
              
             varoperation :='Inserting Data into BankChargeLinking table';
             insert into trtran015e(CHGA_COMPANY_CODE,CHGA_BANK_CODE,CHGA_EFFECTIVE_DATE,CHGA_CHARGE_TYPE,
                                    CHGA_CHARGING_EVENT,CHGA_SANCTION_APPLIED,CHGA_SCREEN_NAME,CHGA_CREATE_DATE,
                                    CHGA_ENTRY_DETAIL,CHGA_RECORD_STATUS,CHGA_CURRENCY_CODE,CHGA_LIMIT_TYPE,
                                    CHGA_LOCATION_CODE,CHGA_LOB_CODE,chga_ref_number)
                                    Values(numcode,numcode3,datTemp,numcode4,
                                    numChargeEvent,varSanctionApplied,Varreference1,sysdate,
                                    null,10200001,numCurrency,numcode5,
                                    numcode1,numcode2,varreference);
                                   -- insert into temp values(numcode||numcode3||datTemp||numcode4||numChargeEvent||varSanctionApplied||Varreference1||sysdate||null||10200001||numCurrency||numcode5||numcode1||numcode2||varreference);
          end loop;
      elsif  numAction in(GConst.DELETESAVE) then
     
--          update trtran015d
--          set char_record_status=10200006,CHAR_ENTRY_DETAIL=null
--          where CHAR_REFERENCE_NUMBER=varreference;
--           
--           update tftran015e
--           set chga_record_status=10200006,CHGA_ENTRY_DETAIL=null
--           where chga_ref_number=varreference;  
            insert into trtran015d_audit select * from trtran015d where CHAR_REFERENCE_NUMBER=varreference
              and char_record_status not in(10200005,10200006);commit;
            
              delete from trtran015d where CHAR_REFERENCE_NUMBER=varreference;commit;
              
               insert into trtran015e_audit select * from trtran015e where chga_ref_number=varreference
              and chga_record_status not in(10200005,10200006);commit;
              
              delete from trtran015e where chga_ref_number=varreference;commit;
              
  elsif  numAction in(GConst.CONFIRMSAVE) then
     
          update trtran015d
          set char_record_status=10200003,CHAR_ENTRY_DETAIL=null
          where CHAR_REFERENCE_NUMBER=varreference;
           
           update trtran015e
           set chga_record_status=10200003,CHGA_ENTRY_DETAIL=null
           where chga_ref_number=varreference;        
               
  end if;
end if;
 if EditType=Gconst.SYSFORWARDROLLOVERPROCESS then 
     
--64500001	Rollover
--64500002	Cancellation
  if  numAction in(GConst.ADDSAVE) then    
        -- if numCode1 in (64500002 then --Cancel
           varTemp2 := '//DealDetails//DROW';       
           nlsTemp := xslProcessor.selectNodes(nodFinal, varTemp2);  
      
          for numTemp in 1..xmlDom.getLength(nlsTemp)
           Loop  
                varxPath := '//DealDetails//DROW[@DNUM="' || numTemp || '"]';   
                varTemp := varxPath || '/DealNumber';
                varOperation:=' Extracting information from ' || varTemp;
              
                varoperation :='Extracting Data from XML' || varTemp;
                Varreference1 := GConst.fncXMLExtract(xmlTemp, varTemp, Varreference1, Gconst.TYPENODEPATH);
              varOperation:=' Extracting information for Deal' || Varreference1;
              begin
               select nvl(max(cdel_deal_serial) +1,1) 
                 into numSerial
                 from trtran006
                 where cdel_deal_number=varReference1;
               exception
                 when no_data_found then
                 numSerial:=1;
              end ;

              varOperation:=' Extracting information for Deal from Base Table' || Varreference1; 
                 select max(DEAL_HEDGE_TRADE)
                 into numCode2
                 from trtran001
                 where deal_deal_number=varReference1;

              varOperation:=' Insert Data into Cancel Table for Deal' || Varreference1; 
               
              insert into trtran006
                (cdel_company_code,cdel_deal_number,cdel_deal_serial,cdel_reverse_serial,
                 cdel_cancel_date,cdel_deal_type,cdel_cancel_type,cdel_cancel_amount,
                 cdel_cancel_rate,cdel_other_amount,CDEL_FORWARD_RATE,CDEL_SPOT_RATE,CDEL_MARGIN_RATE,
                 cdel_cancel_inr,cdel_profit_loss,
                 cdel_user_id,cdel_dealer_remark,cdel_time_stamp,cdel_create_date,cdel_record_status,
                 cdel_pandl_spot, cdel_pandl_usd,cdel_bank_reference,CDEL_ROLLOVER_REFERENCE,
                 CDEL_EDC_CHARGE,CDEL_CASHFLOW_DATE,CDEL_NPV_VALUE,CDEL_IRR_RATE)
             select GConst.fncXMLExtract(xmlTemp,'DEAR_COMPANY_CODE',numcode3) cdel_company_code,
                     GConst.fncXMLExtract(xmlTemp,varxPath || '/DealNumber',varReference, Gconst.TYPENODEPATH) cdel_deal_number,
                     numSerial cdel_deal_serial, 1 cdel_reverse_serial,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_DATE',datTemp) cdel_cancel_date,
                     numCode2 cdel_deal_type ,27000001 cdel_cancel_type,
                     GConst.fncXMLExtract(xmlTemp,varxPath || '/CancelAmount',numFcy, Gconst.TYPENODEPATH) cdel_cancel_amount,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_SPOT_RATE',numFcy) cdel_cancel_rate,
                     GConst.fncXMLExtract(xmlTemp,varxPath || '/CancelAmount',numFcy, Gconst.TYPENODEPATH) *
                     GConst.fncXMLExtract(xmlTemp,'DEAR_SPOT_RATE',numFcy) cdel_other_amount,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_FORWARD_RATE',numFcy) CDEL_FORWARD_RATE,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_SPOT_RATE',numFcy) CDEL_SPOT_RATE,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_MARGIN_RATE',numFcy) CDEL_MARGIN_RATE,
                     0 cdel_cancel_inr,
                     GConst.fncXMLExtract(xmlTemp,varxPath || '/ProfitLoss',numFcy, Gconst.TYPENODEPATH) cdel_profit_loss,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_USER_ID',varReference) cdel_user_id,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_CANCEL_REMARKS',varReference) cdel_dealer_remark,
                     to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3') cdel_time_stamp, sysdate cdel_create_date,
                     10200001 cdel_record_status,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_CONVERSION_RATE',numFcy) cdel_pandl_spot,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_CONVERSION_PANDL',numFcy) cdel_pandl_usd,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_CANCEL_REFERENCE',varReference) cdel_bank_reference,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_NUMBER',varReference) CDEL_ROLLOVER_REFERENCE,
                     GConst.fncXMLExtract(xmlTemp,varxPath || '/EarlyDeliveryCharges',numFcy, Gconst.TYPENODEPATH) CDEL_EDC_CHARGE,
                     GConst.fncXMLExtract(xmlTemp,varxPath || '/CashflowDate',datTemp, Gconst.TYPENODEPATH) CDEL_CASHFLOW_DATE,
                     GConst.fncXMLExtract(xmlTemp,varxPath || '/NpvValue',numFcy, Gconst.TYPENODEPATH) CDEL_NPV_VALUE,
                     GConst.fncXMLExtract(xmlTemp,varxPath || '/IrrRate',numFcy, Gconst.TYPENODEPATH) CDEL_NPV_VALUE
              from dual;
                
            varOperation:=' Update the Deal Linking table ' || Varreference1; 
            
            update trtran004 set HEDG_RECORD_STATUS= 10200010,
                                 HEDG_RollOVer_Reference= GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_NUMBER',varReference)
              where Hedg_deal_number= varReference1
              and hedg_record_Status not in (10200005,10200006);
           end loop;

        numCode1 := GConst.fncXMLExtract(xmlTemp,'DEAR_ROLLOVER_TYPE',numCode1);
         
         if numCode1=64500001 then --Rollover
          varOperation:=' Insert Deal into Base Table incase of Roll Over  ' || Varreference1; 
           varReference := 'FWD' || GConst.fncGenerateSerial(Gconst.SERIALDEAL,numCompany);
            insert into trtran001
              (deal_company_code,deal_deal_number,deal_serial_number,deal_execute_date,
              deal_hedge_trade,deal_buy_sell,deal_swap_outright,
              deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,
              deal_forward_rate,deal_spot_rate,deal_margin_rate,deal_exchange_rate,deal_base_amount,
              deal_other_amount,DEAL_AMOUNT_LOCAL,deal_maturity_from,deal_maturity_date,
              deal_user_id,deal_dealer_remarks,deal_time_stamp,deal_process_complete,
              deal_create_date,deal_record_status,
              deal_user_reference, deal_backup_deal,deal_init_code,deal_location_code,deal_maturity_code)
              select GConst.fncXMLExtract(xmlTemp,'DEAR_COMPANY_CODE',numcode3) deal_company_code,
                      varReference deal_deal_number,1 deal_serial_number,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_DATE',datTemp) deal_execute_date,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_HEDGE_TRADE',numCode) deal_hedge_trade ,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_BUY_SELL',numCode) deal_buy_sell ,
                     25200002 deal_swap_outright,25400001  deal_deal_type,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_COUNTER_PARTYNEW',numCode) deal_counter_party,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_BASE_CURRENCY',numCode) deal_base_currency,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_OTHER_CURRENCY',numCode) deal_other_currency,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_FORWARD_RATE',numFcy) deal_forward_rate,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_SPOT_RATE',numCode) deal_spot_rate,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_MARGIN_RATE',numCode) deal_margin_rate,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_EXCHNAGE_RATE',numCode) deal_exchange_rate,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_DEAL_AMOUNT',numCode) deal_base_amount,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_DEAL_AMOUNT',numCode)*
                     GConst.fncXMLExtract(xmlTemp,'DEAR_EXCHNAGE_RATE',numCode) deal_other_amount,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_DEAL_AMOUNT',numCode)*
                     GConst.fncXMLExtract(xmlTemp,'DEAR_EXCHNAGE_RATE',numCode) DEAL_AMOUNT_LOCAL,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_NEWMATURITY_DATE',datTemp) deal_maturity_from,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_NEWMATURITY_DATE',datTemp) deal_maturity_date,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_USER_ID',vartemp) deal_user_id,
                     GConst.fncXMLExtract(xmlTemp,'DEAR_USER_REMARKS',vartemp) deal_dealer_remarks,
                     to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3') deal_time_stamp,
                     12400002 deal_process_complete,sysdate deal_create_date,10200001 deal_record_status,
                      GConst.fncXMLExtract(xmlTemp,'DEAR_USER_REFERENCE',vartemp) deal_user_reference,
                        GConst.fncXMLExtract(xmlTemp,'DEAR_BACKUP_DEALNEW',numCode) deal_backup_deal,
                          GConst.fncXMLExtract(xmlTemp,'DEAR_INIT_CODENEW',numCode) deal_init_code,
                          GConst.fncXMLExtract(xmlTemp,'DEAR_LOCATION_CODENEW',numCode) deal_location_code,
                          25500005
                  from dual;
         
          varOperation:='Update Deal number to Roll Over Table';        
          update trtran001RA set  DEAR_NEWDEAL_NUMBER=varReference
            where DEAR_REFERENCE_NUMBER=GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_NUMBER',varReference)
            and dear_record_Status not in (10200005,10200006);
            
          varOperation:=' start the loop to do Hedge Deal linking To Retain the Linkage ';
          numFCY:=0;
          for curHedges in (select HEDG_COMPANY_CODE,HEDG_TRADE_REFERENCE,HEDG_DEAL_NUMBER,
                HEDG_DEAL_SERIAL,HEDG_HEDGED_FCY,HEDG_OTHER_FCY,HEDG_HEDGED_INR,HEDG_CREATE_DATE,
                HEDG_RECORD_STATUS,HEDG_HEDGING_WITH,HEDG_MULTIPLE_CURRENCY,HEDG_LOCATION_CODE,HEDG_LINKED_DATE,
                HEDG_TRADE_SERIAL,HEDG_BATCH_NUMBER,HEDG_ROLLOVER_REFERENCE
              from trtran004 inner join trtran001
               on HEDG_DEAL_NUMBER= deal_deal_number
                where HEDG_RECORD_STATUS not in (10200005,10200006)
                and HEDG_RollOVer_Reference= GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_NUMBER',varReference)
                and HEDG_LINKED_DATE >=GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_DATE',datTemp)
                and deal_record_status not in (102000005,102000006)
                order by Deal_maturity_date)       
            loop 
                numFCY:= numFCY+curHedges.HEDG_HEDGED_FCY;
               -- if numFCY <=  GConst.fncXMLExtract(xmlTemp,'DEAR_DEAL_AMOUNT',numCode) then
                    varOperation:=' Insert Deals into Hedge Deal linking To Retain the Linkage ' || Varreference1; 
                    insert into trtran004 (HEDG_COMPANY_CODE,HEDG_TRADE_REFERENCE,HEDG_DEAL_NUMBER,
                    HEDG_DEAL_SERIAL,HEDG_HEDGED_FCY,HEDG_OTHER_FCY,HEDG_HEDGED_INR,HEDG_CREATE_DATE,
                    HEDG_RECORD_STATUS,HEDG_HEDGING_WITH,HEDG_MULTIPLE_CURRENCY,HEDG_LOCATION_CODE,HEDG_LINKED_DATE,
                    HEDG_TRADE_SERIAL,HEDG_BATCH_NUMBER,HEDG_ROLLOVER_REFERENCE)
                    values (curHedges.HEDG_COMPANY_CODE,curHedges.HEDG_TRADE_REFERENCE,varReference,
                    1,(case when numFCY <=  GConst.fncXMLExtract(xmlTemp,'DEAR_DEAL_AMOUNT',numCode) then
                          curHedges.HEDG_HEDGED_FCY else
                           GConst.fncXMLExtract(xmlTemp,'DEAR_DEAL_AMOUNT',numCode) end)
                          ,curHedges.HEDG_OTHER_FCY,curHedges.HEDG_HEDGED_INR,sysdate,
                    10200003,curHedges.HEDG_HEDGING_WITH,curHedges.HEDG_MULTIPLE_CURRENCY,
                    GConst.fncXMLExtract(xmlTemp,'DEAR_LOCATION_CODENEW',numCode),
                     GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_DATE',datTemp),
                    curHedges.HEDG_TRADE_SERIAL,curHedges.HEDG_BATCH_NUMBER, 
                    GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_NUMBER',varReference));
             end loop;
         end if;
  elsif numAction in(GConst.DELETESAVE) then 
     varReference:= GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_NUMBER',varReference);

          
       varOperation:='Update the Hedge Deal Linking' || Varreference;    
        update trtran004 set HEDG_RECORD_STATUS =10200006
          where HEDG_ROLLOVER_REFERENCE=varReference
          and HEDG_RECORD_STATUS not in (10200010,10200006);
      
        varOperation:='Update the Hedge Deal Linking Back to Orginal' || Varreference;    
        update trtran004 set HEDG_RECORD_STATUS =10200003
         where HEDG_Deal_number in 
            (select Cdel_DEAL_NUMBER from trtran006
              where cdel_RECORD_STATUS not in (10200005,10200006)
              and CDEL_ROLLOVER_REFERENCE=varReference)
          and HEDG_RECORD_STATUS =10200010;
          
        varOperation:='Update the Delete Status to Cancel Records ' || Varreference; 
        update trtran006 set cdel_record_status =10200006
          where CDEL_ROLLOVER_REFERENCE=varReference;
          
       varOperation:='Update the new deal to Delete status ' || Varreference;      
        update trtran001 set DEAL_RECORD_STATUS =10200006
         where DEAL_Deal_number in 
            (select DEAR_NEWDEAL_NUMBER from TRTRAN001RA
             -- where DEAR_RECORD_STATUS not in (10200005,10200006) -- record status in TRTRAN001RA would already been changed to 10200006
              where DEAR_REFERENCE_NUMBER=varReference); 
         
          
  elsif numAction in(GConst.CONFIRMSAVE) then     
       varReference:= GConst.fncXMLExtract(xmlTemp,'DEAR_REFERENCE_NUMBER',varReference);
      varOperation:='Update the Delete Status to Cancel Records ' || Varreference; 
        update trtran006 set cdel_record_status =10200003
          where CDEL_ROLLOVER_REFERENCE=varReference;
          
       varOperation:='Update the Hedge Deal Linking' || Varreference;    
        update trtran004 set HEDG_RECORD_STATUS =10200003
          where HEDG_ROLLOVER_REFERENCE=varReference;

       varOperation:='Update the new deal to Delete status ' || Varreference;      
        update trtran001 set DEAL_RECORD_STATUS =10200003
         where DEAL_Deal_number in 
            (select DEAR_NEWDEAL_NUMBER from TRTRAN001RA
              where DEAR_RECORD_STATUS not in (10200005,10200006)
              and DEAR_REFERENCE_NUMBER=varReference); 
         
  end if;
 end if;




return clbTemp;
Exception
        When others then
          numError := SQLCODE;
          varError := SQLERRM;
          varError := GConst.fncReturnError('MiscUpdate', numError, varMessage,
                          varOperation, varError);
          raise_application_error(-20101, varError);
          return clbTemp;
End fncMiscellaneousUpdates;

--Procedure prcCoordinator
--        (   ParamData   in  Gconst.gClobType%Type,
--            ErrorData   out NoCopy Gconst.gClobType%Type,
--            ProcessData out NoCopy Gconst.gClobType%Type,
--            GenCursor   out Gconst.DataCursor,
--            NextCursor  out Gconst.DataCursor)
--  is
--
----|--------------------------------------------------------------|
----|Name of Function   PrcCoordinator                             |
----|Author             T M Manjunath                              |
----|Package            PkgMasterMaintenance                       |
----|Type               Procedure                                  |
----|Date of Creation   19-Mar-2007                                |
----|Last Modified On   19-Mar-2007                                |
----|Input Parameters   1.Voucher Details in Clob                  |
----|Output Parameters  1.Error Data in Clob                       |
----|                   2.Process Data in Clob                     |
----|                   3.Ref Cursor No.1 depending on operation   |
----|                   4.Ref Cursor No.2 depending on operation   |
----|Return, if any     No Returns                                 |
----|Brief Discription                                             |
----| The function                                                 |
----|                                                              |
----|--------------------------------------------------------------|
--
--      numError                number;
--      numRecordSets           number(1);
--      numTemp                 number(5);
--      numAction               number(4);
--      numType                 number(4);
--      numLocation             number(8);
--      numConsignee            number(8);
--      numCompany              number(8);
--      varAction               varchar2(15);
--      varEntity               varchar2(30);
--      varUserID               varchar2(30);
--      varsql                  varchar2(500);
--      varOperation            GConst.gvarOperation%Type;
--      varMessage              GConst.gvarMessage%Type;
--      varError                GConst.gvarError%Type;
--      xmlTemp                 GConst.gXMLType%Type;
--      xmlTemp1                GConst.gXMLType%Type;
--      Error_Function          Exception;
--      Error_Occurred          Exception;
--      pData                   clob;
--      clbTemp                 clob;
--      docRecord               xmldom.DomDocument;
--      Begin
--        numError := 0;
--        numRecordSets := 0;
--        xmlTemp := xmlType(ParamData);
--        dbms_lob.createTemporary (clbTemp,  TRUE);
--        dbms_lob.createTemporary (pData,  TRUE);
--
--        numError := 1;
--        varOperation := 'Extracting Parameters for User ID';
--        varUserID := GConst.fncXMLExtract(xmlTemp, 'UserID', varUserID);
--        varOperation := 'Extracting Parameters for Action';
--        numAction := NVL(to_number(GConst.fncXMLExtract(xmlTemp, 'Action', numAction)),0);
--        varOperation := 'Extracting Parameters for Entity';
--        varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
--        varMessage := 'Entity: ' || varEntity || ' Mode: ' || numAction;
--
--        if numAction = 0 then
--          varError := 'Action type not furnished';
--          raise Error_Occurred;
--        end if;
--
--        if numAction = GConst.MENULOAD then
--          numError := 2;
--          varOperation := 'Extracting Menu Items for the user';
--          pData := ParamData;
--          numTemp := Gconst.fncSetParam(pData, 'Type', GConst.REFMENUITEMS);
--          pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, GenCursor);
--          numError := GConst.fncReturnParam(ErrorData, 'Error');
--          varError := GConst.fncReturnParam(ErrorData, 'Message');
--
--          if numError <> 0 then
--              raise Error_Function;
--          else
--              numRecordSets := numRecordSets + 1;
--          end if;
--
--        end if;
--
--        if numAction = Gconst.BROWSERLOAD then
--          numError := 3;
--          varOperation := 'Setting parameters for the cursor';
--          pData := ParamData;
--
--          numTemp := GConst.fncSetParam(pData, 'Type', GConst.REFPICKUPLIST);
--          varOperation := 'Extracting Browser items for ' || varEntity;
--          pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, GenCursor);
--
--          numError := GConst.fncReturnParam(ErrorData, 'Error');
--          varError := GConst.fncReturnParam(ErrorData, 'Message');
--
--    if numError <> 0 then
--        raise Error_Function;
--    end if;
--
--    varOperation := 'Extracting XML Fields';
--    pData := ParamData;
--    numTemp := GConst.fncSetParam(pData, 'Type', GConst.REFXMLFIELDS);
--    pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, NextCursor);
--    numError := GConst.fncXMLExtract(xmlType(ErrorData), 'Error', numError);
--    varError := GConst.fncXMLExtract(xmlType(ErrorData), 'Message', varError);
--
--    if numError <> 0 then
--        raise Error_Function;
--    else
--        numRecordSets := 2;
--    end if;
--
--    varOperation := 'Getting key values for the entity: ' || varEntity;
--    select xmlElement("KeyValues",
--      xmlagg(xmlForest(a.fldp_xml_field as "FieldName" )))
--      into xmlTemp1
--      from trsystem999 a
--      where fldp_table_synonym = varEntity
--      and fldp_key_no != 0
--      order by fldp_key_no;
--
--    varOperation := 'Adding Key Values to the document';
--    xmlTemp := pkgGlobalMethods.fncAddNode(xmlTemp, xmlTemp1, 'CommandSet');
--
--    varOperation := 'Getting Show fields for the entity: ' || varEntity;
--    select xmlElement("ShowFields",
--      xmlagg(xmlForest(a.fldp_xml_field as "FieldName" )))
--      into xmlTemp1
--      from trsystem999 a
--      where fldp_table_synonym = varEntity
--      and fldp_show_yn  = 'Y';
--
--
--   varOperation := 'Adding Show Values to the document';
--    xmlTemp := pkgGlobalMethods.fncAddNode(xmlTemp, xmlTemp1, 'CommandSet');
--
--    varOperation := 'Getting Display fields for the entity: ' || varEntity;
--    select xmlElement("DisplayFields",
--      xmlagg(xmlForest(a.fldp_xml_field as "FieldName" )))
--      into xmlTemp1
--      from trsystem999 a
--      where fldp_table_synonym = varEntity
--      and fldp_show_yn  != 'Y';
--
--     xmlTemp := pkgGlobalMethods.fncAddNode(xmlTemp, xmlTemp1, 'CommandSet');
--
--     varOperation := 'Getting Key fields Display Name for the entity: ' || varEntity;
--
--    select xmlelement("KeyFieldsDisplayName",'')
--     into xmltemp1
--     from dual;
--
--    varOperation := 'Adding Key Display Values to the document';
--    xmlTemp := pkgGlobalMethods.fncAddNode(xmlTemp, xmltemp1, 'CommandSet');
--
--    for cur in (select a.fldp_xml_field as FieldName
--                 from trsystem999 a
--                where fldp_table_synonym = varEntity
--                  and fldp_key_no != 0)
--    loop
--      varSQL := 'select xmlElement(' || '"' || cur.FieldName || '"' || ', fldp_column_displayname )
--      from trsystem999 a
--      where fldp_table_synonym = ' || '''' ||  varEntity || '''' ||
--       ' and fldp_xml_field = '|| '''' ||  cur.FieldName || ''''  ;
--
--      EXECUTE IMMEDIATE  varsql into xmlTemp1;
--
--      xmlTemp := pkgGlobalMethods.fncAddNode(xmlTemp, xmltemp1, 'KeyFieldsDisplayName');
--    end loop;
--
--
--
--    clbTemp := xmlTemp.GetClobVal();
--    Goto Process_End;
--
--  end if;
--
--
--
--        if numAction = GConst.ACTIONDATA then
--          varOperation := 'Extracting information';
--          pData := ParamData;
--          pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, GenCursor);
--          numError := GConst.fncXMLExtract(xmlType(ErrorData), 'Error', numError);
--          varError := GConst.fncXMLExtract(xmlType(ErrorData), 'Message', varError);
--
--          if numError <> 0 then
--              raise Error_Function;
--          else
--              numRecordSets := 1;
--          end if;
--        numType:=GConst.fncXMLExtract(xmlType(pData), 'Type', numError);
--
--          if numType= Gconst.REFPOSITIONGAPVIEW then
--              pData := ParamData;
--              numType := GConst.fncSetParam(pData, 'Type', Gconst.REFPOSITIONGAPVIEWGRID);
--
--              pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, NextCursor);
--              if numError <> 0 then
--                  raise Error_Function;
--              else
--                  numRecordSets := 2;
--              end if;
--          end if;
--        end if;
--
--        if numAction in
--                    ( GConst.VIEWLOAD,
--                      Gconst.DELETELOAD,
--                      Gconst.CONFIRMLOAD,
--                      GConst.EDITLOAD) then
--            numError := 5;
--            varOperation := 'Extracting entity data';
--
--
--            xmlTemp1 := GConst.fncGenericGet(fncBuildQuery(ParamData));
--            xmlTemp := GConst.fncAddNode(xmlTemp, xmlTemp1, varEntity, 'ROW');
--            clbTemp := xmlTemp.getClobVal();
--
--
--            open GenCursor for
--            select '0' from dual;
--
--            varOperation := 'Extracting XML Fields';
--            pData := ParamData;
--            numTemp := GConst.fncSetParam(pData, 'Type', GConst.REFXMLFIELDS);
--            pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, NextCursor);
--            numError := GConst.fncXMLExtract(xmlType(ErrorData), 'Error', numError);
--            varError := GConst.fncXMLExtract(xmlType(ErrorData), 'Message', varError);
--
--            if numError <> 0 then
--                raise Error_Function;
--            else
--                numRecordSets := 2;
--            end if;
--
--      end if;
--
--        if numAction in
--                    ( GConst.ADDSAVE,
--                      GConst.EDITSAVE,
--                      GConst.DELETESAVE,
--                      GcONST.CONFIRMSAVE) then
--        numError := 0;
--        pData := ParamData;
--        
----        if numAction in( GConst.EDITSAVE) then
----       -- begin 
----            varOperation := 'Inserting Pre-edit audit Trails';
----            numError := fncAuditTrail(pData, GConst.BEFOREIMAGE);
----        end if;
--
--        varOperation := 'Inserting Pre-edit audit Trails';
--        numError := fncAuditTrail(pData, GConst.BEFOREIMAGE);
--
--       -- insert into temp values(pData,pData);
--      --  commit;
--        varOperation := 'Performing Table Processing';
--        clbTemp := fncMasterMaintenance(pData, numError);
--
--        if numError <> 0 then
--            raise Error_Function;
--        end if;
--        varOperation := 'Inserting Post-edit audit Trails';
--        numError := fncAuditTrail(pData, Gconst.AFTERIMAGE);
--
--        if numError <> 0 then
--            raise Error_Function;
--        else
--            numRecordsets := 0;
--            Goto Process_End;
--        end if;
--
--  end if;
--
----  if numAction in
----              ( GConst.DELETESAVE,
----                GConst.CONFIRMSAVE) then
----    pData := ParamData;
----
----    varOperation := 'Performing system updates';
----    numError := fncSystemUpdate(pData);
----    clbTemp := pData;
----
----    if numError <> 0 then
----        raise Error_Function;
----    else
----        numRecordsets := 0;
----        Goto Process_End;
----    end if;
----
----  end if;
--
--      <<Process_End>>
--          numError := 0;
--          varError := 'Successful Operation' ;
--          ProcessData := clbTemp;
--          ErrorData := pkgGlobalMethods.fncReturnError('Coordinator', varMessage, numRecordSets,
--                numError, varOperation, varError);
--
--    Exception
--        When Error_Function then -- Error thrown by the called method
--       --   Null;   -- Error object is already populated by the called method
--          insert into errorlog(ERRO_ERROR_NO,ERRO_ERROR_MSG,ERRO_INPUT_XML,
--                      ERRO_OUTPUT_XML,ERRO_USER_ID,ERRO_EXEC_DATE,ERRO_ERROR_MODULE)
--              values  (-20101,varError,xmltype(ParamData),
--                      xmltype(ErrorData),varUserID,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),'MASTER');
--          raise_application_error(-20101, varError);
--        When Error_Occurred then
--          ErrorData := pkgGlobalMethods.fncReturnError('Coordinator',varMessage, 0, numError,varOperation,varError);
--           insert into errorlog(ERRO_ERROR_NO,ERRO_ERROR_MSG,ERRO_INPUT_XML,
--                       ERRO_OUTPUT_XML,ERRO_USER_ID,ERRO_EXEC_DATE,ERRO_ERROR_MODULE)
--              values  (numError,varError,xmltype(ParamData),
--                       xmltype(ErrorData),varUserID,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),'MASTER');
--        When others then
--          varError := SQLERRM || ' - ' || varError;
--          numError := SQLERRM;
--          ErrorData := pkgGlobalMethods.fncReturnError('Coordinator',varMessage, 0, numError,varOperation,varError);
--          insert into errorlog(ERRO_ERROR_NO,ERRO_ERROR_MSG,ERRO_INPUT_XML,
--                       ERRO_OUTPUT_XML,ERRO_USER_ID,ERRO_EXEC_DATE,ERRO_ERROR_MODULE)
--              values  (numError,varError,xmltype(ParamData),
--                       xmltype(ErrorData),varUserID,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),'MASTER');
--End prcCoordinator;

Procedure prcCoordinator
        (   ParamData   in  Gconst.gClobType%Type,
            ErrorData   out NoCopy Gconst.gClobType%Type,
            ProcessData out NoCopy Gconst.gClobType%Type,
            GenCursor   out Gconst.DataCursor,
            NextCursor  out Gconst.DataCursor,
            CursorNo3   out Gconst.DataCursor,
            CursorNo4   out Gconst.DataCursor,
            CursorNo5   out Gconst.DataCursor,
            CursorNo6   out Gconst.DataCursor)
            
  is            
  
--|--------------------------------------------------------------|
--|Name of Function   PrcCoordinator                             |
--|Author             T M Manjunath                              |
--|Package            PkgMasterMaintenance                       |
--|Type               Procedure                                  |
--|Date of Creation   19-Mar-2007                                |
--|Last Modified On   19-Mar-2007                                |
--|Input Parameters   1.Voucher Details in Clob                  |
--|Output Parameters  1.Error Data in Clob                       |
--|                   2.Process Data in Clob                     |
--|                   3.Ref Cursor No.1 depending on operation   |
--|                   4.Ref Cursor No.2 depending on operation   |
--|Return, if any     No Returns                                 |
--|Brief Discription                                             |
--| The function                                                 |
--|                                                              |
--|--------------------------------------------------------------|

      numError                number;
      numRecordSets           number(1);
      numTemp                 number(5);
      numAction               number(4);
      numType                 number(4);
      numLocation             number(8);
      numConsignee            number(8);
      numCompany              number(8);
      varAction               varchar2(15);
      varEntity               varchar2(30);
      varType               varchar2(30);
      varUserID               varchar2(30);
      varsql                  varchar2(500);
      varOperation            GConst.gvarOperation%Type;
      varMessage              GConst.gvarMessage%Type;
      varError                GConst.gvarError%Type;
      xmlTemp                 GConst.gXMLType%Type;
      xmlTemp1                GConst.gXMLType%Type;
      Error_Function          Exception;
      Error_Occurred          Exception;
      pData                   clob;
      clbTemp                 clob;
      docRecord               xmldom.DomDocument;
      varWebLogin             Char(1);
      
      ApprovalConfirmStatus  number(8);
      ApprovalConfirmRemarks Varchar(500);
      datToday               Date;
      varTypes                varchar2(30);
      
      VarKeyValues           varchar(500);
      BEGIN
  --  insert into rtemp(TT,TT2) values ('Inside prcCoordinator 0','welcome');
        numError := 0;
        numRecordSets := 0;
        xmltemp := XMLTYPE(paramdata);
    --    insert into rtemp(TT,TT2) values ('Inside prcCoordinator 1','xmlTemp: '||xmlTemp);
        dbms_lob.createTemporary (clbTemp,  TRUE);
        dbms_lob.createTemporary (pData,  TRUE);

        numError := 1;
        varOperation := 'Extracting Parameters for User ID';
        varUserID := GConst.fncXMLExtract(xmlTemp, 'UserCode', varUserID);
        varOperation := 'Extracting Parameters for Action';
        numAction := NVL(to_number(GConst.fncXMLExtract(xmlTemp, 'Action', numAction)),0);
        varOperation := 'Extracting Parameters for Entity';
        varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
        varMessage := 'Entity: ' || varEntity || ' Mode: ' || numAction;
        varType := GConst.fncXMLExtract(xmlTemp, 'Type', varType);

        varMessage := 'To Check whether User Loged in from Windows or Web : ' || varEntity || ' Mode: ' || numAction;
        begin 
            varWebLogin:= GConst.fncXMLExtract(xmlTemp, 'WEBLogin', varWebLogin);
        exception 
          when others then 
            varWebLogin:='N';
        end;
        insert into temp(TT,TT1) values (varWebLogin,varWebLogin);
        commit;
--
--        insert into rtemp(TT,TT2) values ('Inside prcCoordinator 2','varType: '||varType||' varUserID: '||varUserID||' ;numAction: '|| numAction|| ' ;numAction: '|| numAction || ' ;varEntity: '|| varEntity ||' ;varMessage: '||varMessage);
        if numAction = 0 then
          varError := 'Action type not furnished';
          raise Error_Occurred;
        end if;

        if numAction = GConst.MENULOAD then
          numError := 2;
          varOperation := 'Extracting Menu Items for the user';
          pData := ParamData;
          numTemp := Gconst.fncSetParam(pData, 'Type', GConst.REFMENUITEMS);
          pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, GenCursor);
          numError := GConst.fncReturnParam(ErrorData, 'Error');
          varError := GConst.fncReturnParam(ErrorData, 'Message');

          if numError <> 0 then
              raise Error_Function;
          else
              numRecordSets := numRecordSets + 1;
          end if;

        end if;

        if numAction = Gconst.BROWSERLOAD then
          numError := 3;
          varOperation := 'Setting parameters for the cursor';
          pData := ParamData;

          numTemp := GConst.fncSetParam(pData, 'Type', GConst.REFPICKUPLIST);
          varOperation := 'Extracting Browser items for ' || varEntity;
          pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, GenCursor);

          numError := GConst.fncReturnParam(ErrorData, 'Error');
          varError := GConst.fncReturnParam(ErrorData, 'Message');

    if numError <> 0 then
        raise Error_Function;
    end if;

    varOperation := 'Extracting XML Fields';
    pData := ParamData;
    numTemp := GConst.fncSetParam(pData, 'Type', GConst.REFXMLFIELDS);
    pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, NextCursor);
    numError := GConst.fncXMLExtract(xmlType(ErrorData), 'Error', numError);
    varError := GConst.fncXMLExtract(xmlType(ErrorData), 'Message', varError);

    if numError <> 0 then
        raise Error_Function;
    else
        numRecordSets := 2;
    end if;

    varOperation := 'Getting key values for the entity: ' || varEntity;
    select xmlElement("KeyValues",
      xmlagg(xmlForest(a.fldp_xml_field as "FieldName" )))
      into xmlTemp1
      from trsystem999 a
      where fldp_table_synonym = varEntity
      and fldp_key_no != 0
      order by fldp_key_no;

    varOperation := 'Adding Key Values to the document';
    xmlTemp := pkgGlobalMethods.fncAddNode(xmlTemp, xmlTemp1, 'CommandSet');

    varOperation := 'Getting Show fields for the entity: ' || varEntity;
    select xmlElement("ShowFields",
      xmlagg(xmlForest(a.fldp_xml_field as "FieldName" )))
      into xmlTemp1
      from trsystem999 a
      where fldp_table_synonym = varEntity
      and fldp_show_yn  = 'Y';


   varOperation := 'Adding Show Values to the document';
    xmlTemp := pkgGlobalMethods.fncAddNode(xmlTemp, xmlTemp1, 'CommandSet');

    varOperation := 'Getting Display fields for the entity: ' || varEntity;
    select xmlElement("DisplayFields",
      xmlagg(xmlForest(a.fldp_xml_field as "FieldName" )))
      into xmlTemp1
      from trsystem999 a
      where fldp_table_synonym = varEntity
      and fldp_show_yn  != 'Y';

     xmlTemp := pkgGlobalMethods.fncAddNode(xmlTemp, xmlTemp1, 'CommandSet');

     varOperation := 'Getting Key fields Display Name for the entity: ' || varEntity;

    select xmlelement("KeyFieldsDisplayName",'')
     into xmltemp1
     from dual;

    varOperation := 'Adding Key Display Values to the document';
    xmlTemp := pkgGlobalMethods.fncAddNode(xmlTemp, xmltemp1, 'CommandSet');

    for cur in (select a.fldp_xml_field as FieldName
                 from trsystem999 a
                where fldp_table_synonym = varEntity
                  and fldp_key_no != 0)
    loop
      varSQL := 'select xmlElement(' || '"' || cur.FieldName || '"' || ', fldp_column_displayname )
      from trsystem999 a
      where fldp_table_synonym = ' || '''' ||  varEntity || '''' ||
       ' and fldp_xml_field = '|| '''' ||  cur.FieldName || ''''  ;

      EXECUTE IMMEDIATE  varsql into xmlTemp1;

      xmlTemp := pkgGlobalMethods.fncAddNode(xmlTemp, xmltemp1, 'KeyFieldsDisplayName');
    end loop;



    clbTemp := xmlTemp.GetClobVal();
    Goto Process_End;

  end if;



--        if numAction = GConst.ACTIONDATA then
--          varOperation := 'Extracting information';
--          pData := ParamData;
--          pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, GenCursor);
--          numError := GConst.fncXMLExtract(xmlType(ErrorData), 'Error', numError);
--          varError := GConst.fncXMLExtract(xmlType(ErrorData), 'Message', varError);
--
--          if numError <> 0 then
--              raise Error_Function;
--          else
--              numRecordSets := 1;
--          end if;
--        numType:=GConst.fncXMLExtract(xmlType(pData), 'Type', numError);
--
--          if numType= Gconst.REFPOSITIONGAPVIEW then
--              pData := ParamData;
--              numType := GConst.fncSetParam(pData, 'Type', Gconst.REFPOSITIONGAPVIEWGRID);
--
--              pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, NextCursor);
--              if numError <> 0 then
--                  raise Error_Function;
--              else
--                  numRecordSets := 2;
--              end if;
--          end if;
--        end if;

  if numAction in (GConst.ACTIONDATA, GConst.USERVALIDATE) then
-- Logic for extracting multiple cursors (up to 5)  
-- The signature of procedure prcCoordinator is altered accordingly
-- TMM 07/06/2017fncM
    
    varOperation := 'Extracting information';
    pData := ParamData;
    varOperation := 'Extracting Parameters for Cursor Types';
    varTypes := NVL(GConst.fncXMLExtract(xmlTemp, 'Type', varTypes),0);
    varOperation := 'Extracting Parameters for varTypes';
    numRecordSets := NVL(GConst.fncXMLExtract(xmlTemp, 'RecordSets', numRecordSets),0);
    varOperation := 'Extracting Parameters for numRecordSets';
    numTemp := 0;
    
--    insert into temp values  ('No: ' ||  numRecordSets || ' type: ' || varTypes);
--    commit;
    for numTemp in 1 .. numRecordSets
    Loop
        numType := substr(varTypes,instr(varTypes,',',1, numTemp)-4,4);
        numType := Gconst.fncSetParam(pData, 'Type', numType); 
        
        if    numTemp = 1 then
            pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, GenCursor);
        elsif numTemp = 2 then
            pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, NextCursor);
        elsif numTemp = 3 then
            pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo3);
        elsif numTemp = 4 then
            pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo4);
        elsif numTemp = 5 then
            pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, CursorNo5);
        end if;
        
        -- this has been added by Manjunath Reddy on 07/08/2019 to get the Cursor schema information 
            -- this has been added by Manjunath Reddy on 07/08/2019 to get the Cursor schema information 
        open CursorNo6 for
            select GRID_CURSOR_NAME "CursorName",
                Grid_Cursor_Number CursorNumber, 
                --pkgreturncursor.fncgetdescription(GRID_LANGUAGE_CODE,2) LanguageCode,--- en English French fr 903
                GRID_COLUMN_NAME ColumnName,
                pkgreturncursor.fncgetdescription(GRID_COLUMN_TYPE,2) ColumnType , -- New Pick Code --STRING, NUMBER, DATE ColumnDataType 904
                GRID_DISPLAY_NAME DisplayName,
                pkgreturncursor.fncgetdescription(Nvl(GRID_DISPLAY_YN,12400002),1) DisplayYN,
                to_char(nvl(GRID_COLUMN_WIDTH,100)) Width,
                pkgreturncursor.fncgetdescription(nvl(GRID_AGGREGATE_YN,12400002),1) AggregateYN,
                GRID_AGGREGATE_FUNCTION AggregateFunction, -- New Pick Code -- SUM, AVG, Etc.. -905
                pkgreturncursor.fncgetdescription(nvl(GRID_EDITABLE_YN,12400002),1) EditableYN,
                to_char(nvl(GRID_DECIMAL_SCALE,(case when format_data_type in (90400002,90400007) 
                    then Format_Decimal_scale else 0 end))) DecimalScale, -- incase case of number Format and not
                     --specified at cursor level string take the decimal scale from Global based on User Config
                Format_format_string "FormatString",
                GRID_DISPLAY_ORDER "DisplayOrder"
                from TRSYSTEM999C left outer join trGlobalmas914
                on Grid_Column_type = format_data_type
                and format_pick_code=91499999
                where instr(varTypes,Grid_Cursor_Number)>0
                order by GRID_DISPLAY_ORDER asc;

        numError := GConst.fncXMLExtract(xmlType(ErrorData), 'Error', numError);
        varError := GConst.fncXMLExtract(xmlType(ErrorData), 'Message', varError);

       if numError <> 0 then
            raise Error_Function;
        end if;
        
    End Loop;
    
   
  end if; 
  
        if numAction in
                    ( GConst.VIEWLOAD,
                      Gconst.DELETELOAD,
                      Gconst.CONFIRMLOAD,
                      GConst.EDITLOAD) then
            numError := 5;
            varOperation := 'Extracting entity data';


            xmlTemp1 := GConst.fncGenericGet(fncBuildQuery(ParamData));
            xmlTemp := GConst.fncAddNode(xmlTemp, xmlTemp1, varEntity, 'ROW');
            clbTemp := xmlTemp.getClobVal();


            open GenCursor for
            select '0' from dual;

            varOperation := 'Extracting XML Fields';
            pData := ParamData;
            numTemp := GConst.fncSetParam(pData, 'Type', GConst.REFPICKUPFORM);
            pkgReturnCursor.prcReturnCursor(pData, ErrorData, ProcessData, NextCursor);
            numError := GConst.fncXMLExtract(xmlType(ErrorData), 'Error', numError);
            varError := GConst.fncXMLExtract(xmlType(ErrorData), 'Message', varError);

            if numError <> 0 then
                raise Error_Function;
            else
                numRecordSets := 2;
            end if;

      end if;

        if numAction in
                    ( GConst.ADDSAVE,
                      GConst.EDITSAVE,
                      GConst.DELETESAVE,
                      GcONST.CONFIRMSAVE) then
        
        insert into temp values ('Entered into Save Mode',numAction);commit;
        numError := 0;
        pData := ParamData;
        pData := fncSubstituteFields(pData, varEntity, 'Inward');
        
        insert into temp values ('After Substitute',numAction);commit;
--        if numAction in( GConst.EDITSAVE) then
--       -- begin 
--            varOperation := 'Inserting Pre-edit audit Trails';
--            numError := fncAuditTrail(pData, GConst.BEFOREIMAGE);
--        end if;

        varOperation := 'Inserting Pre-edit audit Trails';
        numError := fncAuditTrail(pData, GConst.BEFOREIMAGE);

--        insert into temp values('Before Insert',pData);
--        commit;
        varOperation := 'Performing Table Processing';
        clbTemp := fncMasterMaintenance(pData, numError);
--        insert into temp values('After Insert',pData);
--        commit;

        for curFields in
            (select fldp_xml_field, fldp_column_name
                from trsystem999
                where fldp_table_synonym = varEntity
                and nvl(FLDP_KEY_NO,0) !=0 )
        loop
           VarKeyValues := VarKeyValues ||  GConst.fncXMLExtract(xmltype(clbTemp), curFields.fldp_column_name, VarKeyValues) || '~' ; 
        end loop;
--        insert into temp values(VarKeyValues,VarKeyValues);
--        commit;


        clbTemp := fncSubstituteFields(clbTemp, varEntity, 'Outward');
        
        if numError <> 0 then
            raise Error_Function;
        end if;
        varOperation := 'Inserting Post-edit audit Trails';
        numError := fncAuditTrail(pData, Gconst.AFTERIMAGE);

--       --  insert into temp values (varOperation,varOperation);
--        varOperation := 'Before E-mail Notification Sent';
--       numerror:=pkgfixeddepositproject.fncgeneratemaildetails1(clbTemp,numError ) ;   
--        varOperation := 'After E-mail Notification Sent';
--     --    insert into temp values (varOperation,varOperation);
--     
--       if varEntity in ('HEDGEDEALREGISTER','IMPORTTRADEREGISTER','EXPORTTRADEREGISTER') then
--         datToday := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datToday);
--       --  pkgriskvalidation.prcRiskPopulateNew(datToday);
--        -- pkgriskvalidation.prcActiononRisk(datToday);
--         numError:=pkgriskvalidation.fncRiskPopulateGAP(datToday);
--      end if;
         
                 varOperation := 'Check whether the Entity is exist into the Notification sendign list';
        
        begin
            select count(*) 
             into numtemp
            from trsystem022B
             where ualt_synonym_name =varEntity
               and ualt_record_Status not in(10200005,10200006);
        exception
          when others then 
            numtemp:=0;
        end;
        
        if  ( numtemp >0) then
           varOperation := 'Before E-mail Notification Sent';
           --numerror:=pkgfixeddepositproject.fncgeneratemaildetails1(clbTemp,numError ) ;   
           varOperation := 'After E-mail Notification Sent';
        end if ;
         if varEntity in ('HEDGEDEALREGISTER','IMPORTTRADEREGISTER','EXPORTTRADEREGISTER') then
           datToday := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datToday);
         --  pkgriskvalidation.prcRiskPopulateNew(datToday);
          -- pkgriskvalidation.prcActiononRisk(datToday);
          -- numError:=pkgriskvalidation.fncRiskPopulateGAP(datToday);
        end if;
        
        if numError <> 0 then
            raise Error_Function;
        else
            numRecordsets := 0;
            Goto Process_End;
        end if;
    end if;
    
          -- Confirm Save Store the remarks
      if  (numAction = Gconst.VIEWLOAD ) then
        begin
         ApprovalConfirmStatus := GConst.fncXMLExtract(xmlTemp, 'ApprovalConfirmStatus', ApprovalConfirmStatus);
        exception
         when others then
           ApprovalConfirmStatus :=37800000;
         end;
      end if;
      if ((numAction = Gconst.CONFIRMSAVE) or
          (numAction = Gconst.VIEWLOAD and ApprovalConfirmStatus = 37800001))  then
        varOperation := 'Checking Process Confirm and Capture the information';
        ApprovalConfirmStatus := GConst.fncXMLExtract(xmlTemp, 'ApprovalConfirmStatus', ApprovalConfirmStatus);
        ApprovalConfirmRemarks:= GConst.fncXMLExtract(xmlTemp, 'ApprovalConfirmRemarks', ApprovalConfirmRemarks);
          insert into TRTRAN100 
                (CONF_KEY_VALUES, CONF_APPROVAL_STATUS,CONF_APPROVAL_REMARKS,
                  CONF_ENTITY_NAME,CONF_USER_ID)
          Values (null,ApprovalConfirmStatus,ApprovalConfirmRemarks,
                  varEntity,varUserID);
      end if;
    --  varOperation := 'Call Sending E-mail Procedure in case of Confirmation rejected';
      if ((numAction = Gconst.VIEWLOAD) and (ApprovalConfirmStatus = 37800001))then
          varOperation := 'Check whether the Entity is exist into the Notification sendign list';
            
            begin
                select count(*) 
                 into numtemp
                from trsystem022B
                 where ualt_synonym_name =varEntity
                   and ualt_record_Status not in(10200005,10200006);
            exception
              when others then 
                numtemp:=0;
            end;
--         if numtemp >0 then
--            --numerror:=pkgfixeddepositproject.fncgeneratemaildetails1(ParamData ) ;   
--         end if;
      end if;
--  if numAction in
--              ( GConst.DELETESAVE,
--                GConst.CONFIRMSAVE) then
--    pData := ParamData;
--
--    varOperation := 'Performing system updates';
--    numError := fncSystemUpdate(pData);
--    clbTemp := pData;
--
--    if numError <> 0 then
--        raise Error_Function;
--    else
--        numRecordsets := 0;
--        Goto Process_End;
--    end if;
--
--  end if;

      <<Process_End>>
          numError := 0;
          varError := 'Successful Operation ' || varKeyValues ;
          ProcessData := clbTemp;
          ErrorData := pkgGlobalMethods.fncReturnError('Coordinator', varMessage, numRecordSets,
                numError, varOperation, varError);

    Exception
    
        When Error_Function then -- Error thrown by the called method
       --   Null;   -- Error object is already populated by the called method
          insert into errorlog(ERRO_ERROR_NO,ERRO_ERROR_MSG,ERRO_INPUT_XML,
                      ERRO_OUTPUT_XML,ERRO_USER_ID,ERRO_EXEC_DATE,ERRO_ERROR_MODULE)
              values  (-20101,varError,xmltype(ParamData),
                      xmltype(ErrorData),varUserID,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),'MASTER');
          raise_application_error(-20101, varError);
        When Error_Occurred then
       --  insert into rtemp(TT,TT2) values ('Inside prcCoordinator exp ',varOperation);
          ErrorData := pkgGlobalMethods.fncReturnError('Coordinator',varMessage, 0, numError,varOperation,varError);
           insert into errorlog(ERRO_ERROR_NO,ERRO_ERROR_MSG,ERRO_INPUT_XML,
                       ERRO_OUTPUT_XML,ERRO_USER_ID,ERRO_EXEC_DATE,ERRO_ERROR_MODULE)
              values  (numError,varError,xmltype(ParamData),
                       xmltype(ErrorData),varUserID,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),'MASTER');
        When others then
          varError := SQLERRM || ' - ' || varError;
          numError := SQLERRM;
           
          ErrorData := pkgGlobalMethods.fncReturnError('Coordinator',varMessage, 0, numError,varOperation,varError);
           raise_application_error(-20101, varError);
        insert into errorlog(ERRO_ERROR_NO,ERRO_ERROR_MSG,ERRO_INPUT_XML,
                       ERRO_OUTPUT_XML,ERRO_USER_ID,ERRO_EXEC_DATE,ERRO_ERROR_MODULE)
              values  (numError,varError,xmltype(ParamData),
                       xmltype(ErrorData),varUserID,to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),'MASTER');
End prcCoordinator;

--Function fncCurrentAccount
--    (   RecordDetail in GConst.gClobType%Type,
--        ErrorNumber in out nocopy number)
--    return clob
--    is
----  Created on 23/09/2007
--    numError            number;
--    numTemp             number;
--
--    numStatus           number;
--    numSub              number(3);
--    numAction           number(4);
--    numSerial           number(5);
--    numCompany          number(8);
--    numLocation         number(8);
--    numBank             number(8);
--    numCrdr             number(8);
--    numType             number(8);
--    numHead             number(8);
--    numCurrency         number(8);
--    numMerchant         number(8);
--    numRecord           number(8);
--    numFCY              number(15,4);
--    numRate             number(15,4);
--    numINR              number(15,2);
--    varAccount          varchar2(25);
--    varVoucher          varchar2(25);
--    varBankRef          varchar2(25);
--    varReference        varchar2(30);
--    varUserID           varchar2(30);
--    varEntity           varchar2(30);
--    varDetail           varchar2(100);
--    varTemp             varchar2(512);
--    varTemp1            varchar2(512);
--    varTemp2            varchar2(512);
--    varXPath            varchar2(512);
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    datWorkDate         date;
--    clbTemp             clob;
--    xmlTemp             xmlType;
--    nodTemp             xmlDom.domNode;
--    nodVoucher          xmlDom.domNode;
--    nmpTemp             xmldom.domNamedNodeMap;
--    nlsTemp             xmlDom.DomNodeList;
--    nlsTemp1            xmlDom.DomNodeList;
--    xlParse             xmlparser.parser;
--    nodFinal            xmlDom.domNode;
--    docFinal            xmlDom.domDocument;
--Begin
--    varMessage := 'Current Account Entries';
--    dbms_lob.createTemporary (clbTemp,  TRUE);
--    clbTemp := RecordDetail;
--    numError := 1;
--    varOperation := 'Extracting Input Parameters';
--    xmlTemp := xmlType(RecordDetail);
--
----    varUserID := GConst.fncXMLExtract(xmlTemp, 'User', varUserID);
----    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
----    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
----    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
----    numCompany := GConst.fncXMLExtract(xmlTemp, 'CompanyID', numCompany);
----    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationID', numLocation);
--
--    varUserID := GConst.fncXMLExtract(xmlTemp, 'UserID', varUserID);
--    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
--    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
--    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
--    numCompany := GConst.fncXMLExtract(xmlTemp, 'CompanyID', numCompany);
--    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationID', numLocation);
--
--    numError := 2;
--    varOperation := 'Creating Document for Master';
--    docFinal := xmlDom.newDomDocument(xmlTemp);
--    nodFinal := xmlDom.makeNode(docFinal);
--
--    varXPath := '//CURRENTACCOUNTMASTER/ROW';
--    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
--    numSub := xmlDom.getLength(nlsTemp);
--
--    if numSub = 0 then
--      return clbTemp;
--    End if;
--
--    Begin
--      varTemp := varXPath || '[@NUM="1"]/LocalBank';
--      numBank := GConst.fncXMLExtract(xmlTemp,varTemp,numBank,Gconst.TYPENODEPATH);
--
--      select lbnk_Account_number
--        into varAccount
--        from trmaster306
--        where lbnk_company_code = numCompany
--        and lbnk_pick_code = numBank;
--        --and bank_record_type = GConst.BANKCURRENT
----        and bank_effective_date =
----        (select max(bank_effective_date)
----          from tftran015
----          where bank_company_code = numCompany
----          and bank_local_bank = numBank
----          and bank_record_type = GConst.BANKCURRENT
----          and bank_effective_date <= datWorkDate);
--    Exception
--      when no_data_found then
--        varAccount := '';
--    End;
--
--    for numSub in 0..xmlDom.getLength(nlsTemp) -1
--    Loop
--       varOperation := 'Extracting Data';
--      nodTemp := xmlDom.Item(nlsTemp, numSub);
--      nmpTemp:= xmlDom.getAttributes(nodTemp);
--      nodTemp := xmlDom.Item(nmpTemp, 0);
--      numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
--      varTemp := varXPath || '[@NUM="' || numTemp || '"]/';
--      varTemp1 := varTemp || 'LocalBank';
--      numBank := GConst.fncXMLExtract(xmlTemp,varTemp1,numBank,Gconst.TYPENODEPATH);
--      varOperation := 'Extracting VoucherNumber';
--     -- nodVoucher := xmlDom.Item(xslProcessor.selectNodes(nodFinal, varTemp || 'VoucherNumber'),0);
--
--      nodVoucher := xslProcessor.selectSingleNode(nodFinal, varTemp || 'VoucherNumber');
--      varTemp1 := varTemp || 'CrdrCode';
--      numCrdr := GConst.fncXMLExtract(xmlTemp,varTemp1,numCrdr,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'AccountHead';
--      numHead := GConst.fncXMLExtract(xmlTemp,varTemp1,numHead,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherType';
--
--        varOperation := 'Extracting VoucherType';
--
--      numType := GConst.fncXMLExtract(xmlTemp,varTemp1,numType,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'RecordType';
--      numRecord := GConst.fncXMLExtract(xmlTemp,varTemp1,numRecord,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'CurrencyCode';
--      numCurrency := GConst.fncXMLExtract(xmlTemp,varTemp1,numCurrency,Gconst.TYPENODEPATH);
----      varTemp1 := varTemp || 'VoucherReference';
----      varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference,Gconst.TYPENODEPATH);
--       varOperation := 'Extracting ReferenceSerial';
--
--      varTemp1 := varTemp || 'ReferenceSerial';
--      numSerial := GConst.fncXMLExtract(xmlTemp,varTemp1,numSerial,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherFcy';
--      numFcy := GConst.fncXMLExtract(xmlTemp,varTemp1,numFcy,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherRate';
--      numRate := GConst.fncXMLExtract(xmlTemp,varTemp1,numRate,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherInr';
--      numInr := GConst.fncXMLExtract(xmlTemp,varTemp1,numInr,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherDetail';
--
--      varOperation := 'Extracting Voucher Details';
--      varDetail := GConst.fncXMLExtract(xmlTemp,varTemp1,varDetail,Gconst.TYPENODEPATH);
----      varTemp1 := varTemp || 'BankReference';
----      varBankRef := GConst.fncXMLExtract(xmlTemp,varTemp1,varBankRef,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'LocalMerchant';
--      numMerchant := GConst.fncXMLExtract(xmlTemp,varTemp1,numStatus,Gconst.TYPENODEPATH);
--       varOperation := 'Extracting RecordStatus';
--      varTemp1 := varTemp || 'RecordStatus';
--      numStatus := GConst.fncXMLExtract(xmlTemp,varTemp1,numStatus,Gconst.TYPENODEPATH);
--      varOperation := 'After Extracting Data';
--      if numAction = GConst.DELETESAVE then
--        numStatus := GConst.LOTDELETED;
--      elsif numAction = GConst.CONFIRMSAVE then
--        numStatus := GConst.LOTCONFIRMED;
--      end if;
--
--      varOperation := 'Processing Current Account Transaction';
--
--      if numStatus = GConst.LOTNOCHANGE then
--        NULL;
--      elsif numStatus = GConst.LOTNEW then
-- --Added on 31/03/08 to accomodate primary keys that come with serial number  and where numbers are generated on 'Add' mode
--        if varEntity in ('FDCLOSURE') then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDCL_FD_NUMBER';
--          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDCL_SR_NUMBER';
--          numSerial:= GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--        elsif varEntity in ('FIXEDDEPOSITFILE') then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDRF_FD_NUMBER';
--          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDRF_SR_NUMBER';
--          numSerial:= GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--        elsif varEntity in ('MUTUALFUNDCLOSURE') then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/MFCL_REFERENCE_NUMBER';
--          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/MFCL_SERIAL_NUMBER';
--          numSerial:= GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--        elsif varEntity in ('MUTUALFUNDTRANSACTION') then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/MFTR_REFERENCE_NUMBER';
--          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/MFTR_SERIAL_NUMBER';
--          numSerial:= GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--
--        elsif varEntity in ('PSLLOAN', 'PSCFCLOAN') then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/INLN_PSLOAN_NUMBER';
--          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--
--        elsif varEntity = 'BILLREALISATION' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BREL_REALIZATION_NUMBER';
--          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--        elsif varEntity = 'IMPORTREALIZE' then
--         varTemp2 := '//' || varEntity || '/ROW[@NUM]/SPAY_SHIPMENT_SERIAL';
--         numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--        elsif varEntity = 'ROLLOVERFILE' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/LMOD_REFERENCE_SERIAL';
--          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--        elsif varEntity = 'BUYERSCREDIT' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BCRD_BUYERS_CREDIT';
--          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          numSerial := 0;
--          varDetail := varDetail || varReference;
--        elsif varEntity = 'EXPORTADVANCE' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/EADV_ADVANCE_REFERENCE';
--          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          numSerial := 0;
--          varDetail := varDetail || varReference;
--        elsif varEntity in ('INTERESTCAL', 'LOANCLOSURE') then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/INTC_PSLOAN_NUMBER';
--          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--        elsif varEntity = 'TERMLOAN' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/TLON_LOAN_NUMBER';
--          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          numSerial := 0;
--          varDetail := varDetail || varReference;
--        elsif varEntity = 'FOREIGNREMITTANCE' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/REMT_REMITTANCE_REFERENCE';
--          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          numSerial := 0;
--          varDetail := varDetail || varReference;
--        elsif varEntity = 'IMPORTLCAMENDMENT' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/POLC_SERIAL_NUMBER';
--          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--        elsif varEntity = 'BUYERSCREDITROLLOVER' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BCRL_SERIAL_NUMBER';
--          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--        elsif varEntity = 'BCCLOSURE' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BRPY_SERIAL_NUMBER';
--          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--        elsif varEntity = 'BANKGUARANTEE' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BGAR_BG_NUMBER';
--          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
--          numSerial := 0;
--          varDetail := varDetail || varReference;
--        elsif varEntity = 'BGROLLOVER' then
--          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BGRL_SERIAL_NUMBER';
--          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
--        end if;
--
--        varVoucher := GConst.fncGenerateSerial(Gconst.SERIALCURRENT, 0);
--        insert into trtran008 (bcac_company_code, bcac_location_code,
--        bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
--        bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
--        bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
--        bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
--        bcac_create_date, bcac_local_merchant, bcac_record_status,
--        bcac_record_type, bcac_account_number, bcac_bank_reference)
--        values(numCompany, numLocation, numBank, varVoucher, datWorkDate,
--        numCrdr, numHead, numType, varReference, numSerial, numCurrency,
--        numFcy, numRate, numInr, varDetail, sysdate, numMerchant, GConst.STATUSENTRY,
--        numRecord, varAccount, varBankRef);
--
--        numError := GConst.fncSetNodeValue(nodFinal, nodVoucher, varVoucher);
--      elsif numStatus = GConst.LOTMODIFIED then
--        update trtran008
--          set bcac_voucher_date = datWorkDate,
--          bcac_voucher_fcy = numFcy,
--          bcac_voucher_rate = numRate,
--          bcac_voucher_inr = numInr,
--          bcac_crdr_code = numCrdr,
--          bcac_record_type = numRecord,
--          bcac_bank_reference = varBankRef,
--          bcac_record_status = GConst.STATUSUPDATED
--          where bcac_voucher_reference = varReference
--          and bcac_reference_serial = numSerial
--          and bcac_account_head = numHead;
--      else
--        select decode(numStatus,
--          GConst.LOTDELETED, GConst.STATUSDELETED,
--          GConst.LOTCONFIRMED, GConst.STATUSAUTHORIZED)
--          into numStatus
--          from dual;
--
--        update trtran008
--          set bcac_record_status = numStatus
--          where bcac_voucher_reference = varReference
--          and bcac_reference_serial = numSerial
--          and bcac_account_head = numHead;
--
--      end if;
--
--    End Loop;
----    varOperation:='Reconsile Entry';
----    numError := fncReconsile(  RecordDetail,numType,varReference);
----
----    if datWorkDate >= '01-MAR-10' and numCompany = 10300201 and  numAction = GConst.CONFIRMSAVE then
----      If  Varentity In ('PSLLOAN', 'PSCFCLOAN') Then
----        varTemp1 := pkgCurrentInterface.fncPSCFCFormat(varReference, numSerial);
----
----      Elsif Varentity = 'BILLREALISATION' Then
----
----        Vartemp1 := Pkgcurrentinterface.Fncbillrealize(Varreference, Numserial);
----
----      Elsif Varentity = 'FREIGHTBATCH' Then
----        Varoperation := 'Generating Entries for Export Freight';
----        For Curfreight In
----        (Select distinct Sfrg_Invoice_Number, Sfin_Local_Bank,Sfin_Rtgs_Date
----          From Tftran073, Tftran074
----          Where sfrg_batch_number = sfin_batch_number
----          and Sfrg_Batch_Number = varReference)
----        Loop
----          Vartemp1 := Pkgcurrentinterface.Fncfreightcharges
----                      (Curfreight.Sfrg_Invoice_Number,
----                       Curfreight.Sfin_Local_Bank,
----                       curFreight.sfin_rtgs_date);
----        End Loop;
----
----      else
----        varTemp1 := pkgCurrentInterface.fncGeneralFormat(varReference, numSerial);
----      end if;
----    End if;
--
--    dbms_lob.createTemporary (clbTemp,  TRUE);
--    xmlDom.WriteToClob(nodFinal, clbTemp);
--    return clbTemp;
--Exception
--    When others then
--      numError := SQLCODE;
--      varError := SQLERRM || varVoucher;
--      varError := GConst.fncReturnError('CurAccount', numError, varMessage,
--                      varOperation, varError);
--      raise_application_error(-20101, varError);
--      return clbTemp;
--End fncCurrentAccount;
Function fncCurrentAccount
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
    varterminalid       varchar2(100);
    varTemp             varchar2(512);
    varTemp1            varchar2(512);
    varTemp2            varchar2(512);
    varXPath            varchar2(512);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    datWorkDate         date;
    datTransDate        date;
    clbTemp             clob;
    clbentrydetails    clob;
    xmlTemp             xmlType;
    nodTemp             xmlDom.domNode;
    nodVoucher          xmlDom.domNode;
    nmpTemp             xmldom.domNamedNodeMap;
    nlsTemp             xmlDom.DomNodeList;
    nlsTemp1            xmlDom.DomNodeList;
    xlParse             xmlparser.parser;
    nodFinal            xmlDom.domNode;
    docFinal            xmlDom.domDocument;
    numRecords          number;
Begin
    varMessage := 'Current Account Entries';
    dbms_lob.createTemporary (clbTemp,  TRUE);
    clbTemp := RecordDetail;
    numError := 1;
    varOperation := 'Extracting Input Parameters';
    xmlTemp := xmlType(RecordDetail);
  insert into temp values ('Enter Into CA',xmlTemp); commit;
  
--    varUserID := GConst.fncXMLExtract(xmlTemp, 'User', varUserID);
--    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
--    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
--    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
--    numCompany := GConst.fncXMLExtract(xmlTemp, 'CompanyID', numCompany);
--    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationID', numLocation);

    varUserID := GConst.fncXMLExtract(xmlTemp, 'UserCode', varUserID);
    varEntity := GConst.fncXMLExtract(xmlTemp, 'Entity', varEntity);
    varterminalid:=GConst.fncXMLExtract(xmlTemp, 'TerminalID', varterminalid);
    datWorkDate := GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
    numAction := GConst.fncXMLExtract(xmlTemp, 'Action', numAction);
    numCompany := GConst.fncXMLExtract(xmlTemp, 'CompanyId', numCompany);
    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationId', numLocation);



     select xmlElement("AuditTrails" , xmlElement("AuditTrail" ,
                    XmlForest( numAction as "Process" ,
                               varUserID as "UserName" ,
                               to_char(systimestamp ,'dd-mon-yyyy hh24:mi:ss:FF3') as "TimeStamp" ,
                               varterminalid as "TerminalName" ,
                               to_char(datworkdate,'dd-mon-yyyy') as "ProcessDate"
                               ))).getclobval()
        into clbentrydetails
        from Dual ;

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
    varOperation := 'Extracting Account Number';
    Begin

     IF varEntity ='MARKETDEALCONFIRMATION' THEN
         varTemp := varXPath || '[@NUM="2"]/LocalBank';
     ELSE
        varTemp := varXPath || '[@NUM="1"]/LocalBank';
     END IF;
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

    varOperation := 'Assign the datworkdate as by default to transactiondate';

    datTransDate:= datWorkdate;
    varOperation := 'Process begin to load the data';

    for numSub in 0..xmlDom.getLength(nlsTemp) -1
    Loop
       varOperation := 'Extracting Data';
      nodTemp := xmlDom.Item(nlsTemp, numSub);
      nmpTemp:= xmlDom.getAttributes(nodTemp);
      nodTemp := xmlDom.Item(nmpTemp, 0);
      numTemp := to_number(xmlDom.GetNodeValue(nodTemp));
      varTemp := varXPath || '[@NUM="' || numTemp || '"]/';
      varTemp1 := varTemp || 'LocalBank';
      numBank := GConst.fncXMLExtract(xmlTemp,varTemp1,numBank,Gconst.TYPENODEPATH);
      varOperation := 'Extracting VoucherNumber';
     -- nodVoucher := xmlDom.Item(xslProcessor.selectNodes(nodFinal, varTemp || 'VoucherNumber'),0);

      nodVoucher := xslProcessor.selectSingleNode(nodFinal, varTemp || 'VoucherNumber');
      begin
      varAccount := GConst.fncXMLExtract(xmlTemp, 'CURRENTACCOUNTMASTER/BankAccountNumber', varAccount);
        exception
          when others then
          varAccount:='0';
      end;      
      varTemp1 := varTemp || 'CrdrCode';
      numCrdr := GConst.fncXMLExtract(xmlTemp,varTemp1,numCrdr,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'AccountHead';
      numHead := GConst.fncXMLExtract(xmlTemp,varTemp1,numHead,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'VoucherType';

        varOperation := 'Extracting VoucherType';

      numType := GConst.fncXMLExtract(xmlTemp,varTemp1,numType,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'RecordType';
      numRecord := GConst.fncXMLExtract(xmlTemp,varTemp1,numRecord,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'CurrencyCode';
      numCurrency := GConst.fncXMLExtract(xmlTemp,varTemp1,numCurrency,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'VoucherReference';
--      varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference,Gconst.TYPENODEPATH);
       varOperation := 'Extracting ReferenceSerial';

      varTemp1 := varTemp || 'ReferenceSerial';
      numSerial := GConst.fncXMLExtract(xmlTemp,varTemp1,numSerial,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'VoucherFcy';
      numFcy := GConst.fncXMLExtract(xmlTemp,varTemp1,numFcy,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'VoucherRate';
      numRate := GConst.fncXMLExtract(xmlTemp,varTemp1,numRate,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'VoucherInr';
      numInr := GConst.fncXMLExtract(xmlTemp,varTemp1,numInr,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'VoucherDetail';

      varOperation := 'Extracting Voucher Details';
      varDetail := GConst.fncXMLExtract(xmlTemp,varTemp1,varDetail,Gconst.TYPENODEPATH);
--      varTemp1 := varTemp || 'BankReference';
--      varBankRef := GConst.fncXMLExtract(xmlTemp,varTemp1,varBankRef,Gconst.TYPENODEPATH);
      varTemp1 := varTemp || 'LocalMerchant';
      numMerchant := GConst.fncXMLExtract(xmlTemp,varTemp1,numStatus,Gconst.TYPENODEPATH);
       varOperation := 'Extracting RecordStatus';
      varTemp1 := varTemp || 'RecordStatus';
      numStatus := GConst.fncXMLExtract(xmlTemp,varTemp1,numStatus,Gconst.TYPENODEPATH);
      varOperation := 'After Extracting Data';
      if numAction = GConst.DELETESAVE then
        numStatus := GConst.LOTDELETED;
      elsif numAction = GConst.CONFIRMSAVE then
        numStatus := GConst.LOTCONFIRMED;
      elsif numAction = GConst.ADDSAVE and varEntity in ('FDCLOSURE' , 'MUTUALFUNDTRANSACTION','FIXEDDEPOSITFILE') then ---addedd by prasanta
         numStatus := GConst.LOTNEW ;
      end if;
         if varEntity in ('BONDDEBENTUREPURCHASE') then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BPUR_DEAL_NUMBER';
          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BPUR_VALUE_DATE';
          datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
         
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BPUR_COMPANY_CODE'; 
          numCompany  := GConst.fncXMLExtract(xmlTemp,varTemp2,numCompany, Gconst.TYPENODEPATH);
        
        elsif varEntity in ('BONDDEBENTUREREDEMPTION') then
         
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BRED_DEAL_NUMBER';
          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BRED_SETTLEMENT_DATE';
          datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
         
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BRED_COMPANY_CODE'; 
          numCompany  := GConst.fncXMLExtract(xmlTemp,varTemp2,numCompany, Gconst.TYPENODEPATH);   
        elsif varEntity in ('FDCLOSURE','FDCLOSURECONFIRM') then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDCL_FD_NUMBER';
          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDCL_SR_NUMBER';
          numSerial:= GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDCL_TRANSACTION_DATE';
          datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDCL_COMPANY_CODE'; 
          numCompany  := GConst.fncXMLExtract(xmlTemp,varTemp2,numCompany, Gconst.TYPENODEPATH);
          
        elsif ((varEntity ='FIXEDDEPOSITFILE') or (varEntity ='FIXEDDEPOSITFILECONFIRM')) then

          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDRF_FD_NUMBER';
          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDRF_SR_NUMBER';
          numSerial:= GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDRF_TRANSACTION_DATE';
          datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/FDRF_COMPANY_CODE'; 
          numCompany := GConst.fncXMLExtract(xmlTemp,varTemp2,numCompany, Gconst.TYPENODEPATH);
          
         --- insert into temp values ('Extract',varReference);
       elsif varEntity in ('MUTUALFUNDCLOSURE','MUTUALFUNDCLOSURECONFIRM') then
           varTemp2 := '//' || varEntity || '/ROW[@NUM]/MFCL_REFERENCE_NUMBER';
           varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
          -- varTemp2 := '//' || varEntity || '/ROW[@NUM]/MFCL_SERIAL_NUMBER';
          -- numSerial:= GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
           numSerial := 0;
           varTemp2 := '//' || varEntity || '/ROW[@NUM]/MFCL_TRANSACTION_DATE';
           datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
           varTemp2 := '//' || varEntity || '/ROW[@NUM]/MFCL_COMPANY_CODE'; 
           numCompany  := GConst.fncXMLExtract(xmlTemp,varTemp2,numCompany, Gconst.TYPENODEPATH);

      elsif varEntity in ('MUTUALFUNDTRANSACTION','MUTUALFUNDTRANSACTIONCONFIRM') then
           varTemp2 := '//' || varEntity || '/ROW[@NUM]/MFTR_REFERENCE_NUMBER';
           varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
           --varTemp2 := '//' || varEntity || '/ROW[@NUM]/MFTR_SERIAL_NUMBER';
           -- numSerial:= GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
           numSerial:=0;
           varTemp2 := '//' || varEntity || '/ROW[@NUM]/MFTR_TRANSACTION_DATE';
           datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/MFTR_COMPANY_CODE'; 
          numCompany  := GConst.fncXMLExtract(xmlTemp,varTemp2,numCompany, Gconst.TYPENODEPATH);
           
      elsif varEntity in ('MARKETDEAL' ,'MARKETDEALCONFIRMATION') then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/MDEL_DEAL_NUMBER';
          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
          numSerial:=0;
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/MDEL_VALUE_DATE';
          datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/MDEL_COMPANY_CODE'; 
          numCompany  := GConst.fncXMLExtract(xmlTemp,varTemp2,numCompany, Gconst.TYPENODEPATH);
          
        elsif varEntity in ('DEALREDEMPTION' ,'DEALREDEMPTIONCONFIRMATION') then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/REDM_DEAL_NUMBER';
          varReference := GConst.fncXMLExtract(xmlTemp,varTemp2,varReference, Gconst.TYPENODEPATH);
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/REDM_SERIAL_NUMBER';
          numSerial:= GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial,Gconst.TYPENODEPATH);
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/REDM_CLOSURE_DATE';
          datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/REDM_COMPANY_CODE'; 
          numCompany := GConst.fncXMLExtract(xmlTemp,varTemp2,numCompany, Gconst.TYPENODEPATH);
          
          if  numAction in (GConst.ADDSAVE, GConst.EDITSAVE) then
            varOperation := 'Updating Process Complete for Market Deal';
            update trtran031
              set mdel_process_complete = 12400001,
              mdel_complete_date = datTransDate
              where mdel_deal_number = varReference;
          elsif numAction = GConst.DELETESAVE then
            update trtran031
              set mdel_process_complete = 12400002,
              mdel_complete_date = NULL
              where mdel_deal_number = varReference;
          End if;

        elsif varEntity in ('PSLLOAN', 'PSCFCLOAN') then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/INLN_PSLOAN_NUMBER';
          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);

        elsif varEntity = 'BILLREALISATION' then
          varTemp2 := '//' || varEntity || '/ROW[@NUM]/BREL_REALIZATION_NUMBER';
          numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
        elsif varEntity = 'IMPORTREALIZE' then
         varTemp2 := '//' || varEntity || '/ROW[@NUM]//BREL_REVERSE_SERIAL';
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
        elsif ((VarEntity ='DEALCONFIRMCANCELATION') or (VarEntity ='FORWARDDEALCANCELFOREDIT') or
         (VarEntity ='HEDGEDEALCANCELLATION') or (VarEntity ='TRADEDEALCANCELLATION')) then 
           varTemp1 := '//' || varEntity || '/ROW[@NUM]/CDEL_DEAL_NUMBER';
           varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference, Gconst.TYPENODEPATH);
           varTemp2 := '//' || varEntity || '/ROW[@NUM]/CDEL_REVERSE_SERIAL';
           numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
           varTemp2 := '//' || varEntity || '/ROW[@NUM]/CDEL_CASHFLOW_DATE';
           datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
        elsif ((VarEntity ='OPTIONHEDGEEXERCISE') or (VarEntity ='OPTIONTRADEEXERCISE')) then 
           varTemp1 := '//' || varEntity || '/ROW[@NUM]/CORV_DEAL_NUMBER';
           varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference, Gconst.TYPENODEPATH);
           varTemp2 := '//' || varEntity || '/ROW[@NUM]/CORV_SERIAL_NUMBER';
           numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);    
           varTemp2 := '//' || varEntity || '/ROW[@NUM]/CORV_SETTLEMENT_DATE';
           datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
--           varTemp2 := '//' || varEntity || '/ROW[@NUM]/COPT_COMPANY_CODE'; 
--           numCompany  := GConst.fncXMLExtract(xmlTemp,varTemp2,numCompany, Gconst.TYPENODEPATH);
           
        elsif ((VarEntity ='OPTIONHEDGEDEAL') or (VarEntity ='OPTIONTRADEDEAL')) then 
           varTemp1 := '//' || varEntity || '/ROW[@NUM]/COPT_DEAL_NUMBER';
           varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference, Gconst.TYPENODEPATH);
           varTemp2 := '//' || varEntity || '/ROW[@NUM]/COPT_SERIAL_NUMBER';
           numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);    
           varTemp2 := '//' || varEntity || '/ROW[@NUM]/COPT_PREMIUM_VALUEDATE';
           datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
           varTemp2 := '//' || varEntity || '/ROW[@NUM]/COPT_COMPANY_CODE'; 
           numCompany  := GConst.fncXMLExtract(xmlTemp,varTemp2,numCompany, Gconst.TYPENODEPATH);
          
        elsif ((VarEntity ='CCIRSSETTLEMENT')) THEN 
           varTemp1 := '//' || varEntity || '/ROW[@NUM]/ICST_IRS_NUMBER';
           varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference, Gconst.TYPENODEPATH);
           varTemp2 := '//' || varEntity || '/ROW[@NUM]/ICST_LEG_SERIAL';
           numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
        elsif ((VarEntity ='IRSSETTLEMENT')) THEN 
           varTemp1 := '//' || varEntity || '/ROW[@NUM]/IIRM_IRS_NUMBER';
           varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference, Gconst.TYPENODEPATH);
           varTemp2 := '//' || varEntity || '/ROW[@NUM]/IIRM_LEG_SERIAL';
           numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);
            varTemp2 := '//' || varEntity || '/ROW[@NUM]/IIRM_SETTLEMENT_DATE';
           datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);
           
        elsif ((VarEntity ='IMPORTREALIZE') or (VarEntity ='EXPORTREALIZE') or
         (VarEntity ='BUYERSCREDITCLOSER')) THEN 
           varTemp1 := '//CommandSet/DealDetails/ReturnFields/ROWD[@NUM="1"]/DealNumber';--'//' || varEntity || '/ROW[@NUM]/DealNumber';
           varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference, Gconst.TYPENODEPATH);
           varTemp2 := '//' || varEntity || '/ROW[@NUM]/BREL_REVERSE_SERIAL';
           numSerial := GConst.fncXMLExtract(xmlTemp,varTemp2,numSerial, Gconst.TYPENODEPATH);   
        elsif ((VarEntity ='HEDGEDEALREGISTER')) then 
         
           varTemp1 := '//' || varEntity || '/ROW[@NUM]/DEAL_DEAL_NUMBER';
           varReference := GConst.fncXMLExtract(xmlTemp,varTemp1,varReference, Gconst.TYPENODEPATH);
           numSerial := 1 ;
           varTemp2 := '//' || varEntity || '/ROW[@NUM]/DEAL_EXECUTE_DATE';
           datTransDate:= GConst.fncXMLExtract(xmlTemp,varTemp2,datTransDate, Gconst.TYPENODEPATH);       
        end if;


    if numStatus = GConst.LOTMODIFIED then
         if varEntity <> 'MUTUALFUNDTRANSACTION' then
           insert into temp values ('Enter Into CA LOTMODIFIED' ,'1'); commit;
               varOperation := 'in Edit mode Update the Old transaction to Status in active';

                   update trtran008
                    set bcac_record_status = 10200005, bcac_add_date =sysdate,
                    bcac_account_number = varAccount
                    where bcac_voucher_reference = varReference
                    and bcac_reference_serial = numSerial
                    and bcac_account_head = numHead
                   -- and BCAC_ENTRY_DETAIL=xmltype(clbentrydetails)
                    and bcac_voucher_type=numType
                    and bcac_crdr_code=numCrdr

                  --  and trunc(sysdate ,'DD') = trunc(bcac_create_date ,'DD')
                    --and (bcac_voucher_inr <>numInr or bcac_local_bank <> numBank)
                    and bcac_record_Status not in (10200005,10200006)
                    and bcac_voucher_number = (  select max(bcac_voucher_number)  from trtran008
                                                where bcac_voucher_reference =varReference
                                                  and bcac_reference_serial = numSerial
                                                  and bcac_account_head =numHead
                                                  and bcac_record_Status not in(10200005,10200006)) ;

                    numRecords := SQL%ROWCOUNT;
                    if numRecords > 0  then
                        numStatus := GConst.LOTNEW;
                    elsif varEntity ='MUTUALFUNDCLOSURE'   then
                       select nvl(count(*),0) into numRecords from trtran008
                                  where bcac_voucher_reference =varReference
                                    and bcac_reference_serial = numSerial
                                    and bcac_account_head =numHead
                                    and bcac_voucher_type=numType
                                    and bcac_crdr_code=numCrdr
                                    and bcac_record_Status not in(10200005,10200006);
                        if numRecords = 0  then
                            numStatus := GConst.LOTNEW;
                        end if;
                    end if;
                    if numRecords = 0  then
                            numStatus := GConst.LOTNEW;
                    end if;
            end if;
      end if;
 insert into temp values ('Enter Into CA ' || numStatus ,numStatus); commit;
      if numStatus = GConst.LOTNOCHANGE then
        NULL;

      elsif numStatus = GConst.LOTNEW then
      varOperation := 'in Edit mode Update the Old transaction to Status in active';
        insert into temp values ('Enter Into CA LOTNEW','3'); commit;
        varVoucher := 'VC/Tr/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT, 0);
            insert into trtran008 (bcac_company_code, bcac_location_code,
            bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
            bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
            bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
            bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
            bcac_create_date, bcac_add_date, bcac_local_merchant, bcac_record_status,
            bcac_record_type, bcac_account_number, bcac_bank_reference,BCAC_ENTRY_DETAIL)
            values(numCompany, numLocation, numBank, varVoucher, datTransDate,
            numCrdr, numHead, numType, varReference, numSerial, numCurrency,
            numFcy, numRate, numInr,varDetail , sysdate,sysdate, numMerchant, GConst.STATUSENTRY,
            numRecord, varAccount, varBankRef,xmltype(clbentrydetails));

            numError := GConst.fncSetNodeValue(nodFinal, nodVoucher, varVoucher);

        elsif ((numStatus= GConst.LOTDELETED)) then
--            select decode(numStatus,
--              GConst.LOTDELETED, GConst.STATUSDELETED,
--              GConst.LOTCONFIRMED, GConst.STATUSAUTHORIZED)
--              into numStatus
--              from dual;
  insert into temp values ('Enter Into CA LOTNEW' || numStatus,'4'); commit;
            varOperation := 'Processing Current Account Transaction';
          
            update trtran008
              set bcac_record_status = GConst.STATUSDELETED,
                  bcac_add_date =sysdate,
                  bcac_account_number = varAccount
              where bcac_voucher_reference = varReference
              and bcac_reference_serial = numSerial
              and bcac_voucher_type=numType
              and bcac_account_head = numHead
              and bcac_record_Status not in(10200005,10200006);
              
        elsif  (numStatus= GConst.LOTCONFIRMED) then
            varOperation := 'Processing Current Account Transaction';
          
            update trtran008
              set bcac_record_status = GConst.STATUSAUTHORIZED,
                  bcac_add_date =sysdate
              where bcac_voucher_reference = varReference
              and bcac_reference_serial = numSerial
              and bcac_voucher_type=numType
              and bcac_account_head = numHead
              and bcac_record_Status not in(10200003,10200005,10200006);
        end if;

    End Loop;

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
END fncCurrentAccount;

--Function fncSubstituteFields
--    (ParamData in Gconst.gClobType%Type,
--     EntityName in varchar2,
--     InwardOutward in varchar2)
--return clob
--is
--    varEntity           varchar2(30);
--    numError            Number;
--    varOperation        GConst.gvarOperation%Type;
--    varMessage          GConst.gvarMessage%Type;
--    varError            GConst.gvarError%Type;
--    xmlTemp             GConst.gXMLType%Type;
--    xmlTemp1            GConst.gXMLType%Type;
--    clbTemp             Gconst.gClobType%Type;
--    nodTemp             xmlDom.domNode;
--    docFinal            xmlDom.domDocument;
--    nodFinal            xmlDom.domNode;
--    RootNode            xmlDom.domNode;
--    varXPath            varchar2(512);
--    nlsTemp             xmlDom.DomNodeList;
--    nmpTemp             xmldom.domNamedNodeMap;
--    numSub              number(5);
--Begin
--    varMessage := 'Substituting XML Fields to Database Fields';
--    dbms_lob.createTemporary (clbTemp,  TRUE);
--    clbTemp := ParamData;
--    xmlTemp:=XMLTYPE(ParamData);
--    docFinal := xmlDom.newDomDocument(xmlTemp);
--    nodFinal := xmlDom.makeNode(docFinal);
--   -- varXPath:= '//CommandSet'; 
--   -- RootNode:= xslProcessor.SELECTSINGLENODE(nodFinal,varXPath);
----    
----    varXPath := '//' || EntityName || '/ROW';
----    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
----    numSub := xmlDom.getLength(nlsTemp);
----    
----    for numSub in 0..xmlDom.getLength(nlsTemp) -1
----    Loop
----        varOperation := 'Extracting Data';
----        nodTemp := xmlDom.Item(nlsTemp, numSub);
----        nmpTemp:= xmlDom.getAttributes(nodTemp);
----        nodTemp := xmlDom.Item(nmpTemp, 0);
----        xmlDom.writeToClob(nodTemp, clbTemp);
----        
----        for curFields in
----        (select fldp_xml_field, fldp_column_name
----            from trsystem999
----            where fldp_table_synonym = EntityName)
----         Loop
----            if  InwardOutward = 'Inward' then               
----                  clbTemp := replace(clbTemp, curFields.fldp_xml_field ,curFields.fldp_column_name );         
----            end if;
----            if  InwardOutward = 'Outward' then
----                clbTemp := replace(clbTemp,curFields.fldp_column_name , curFields.fldp_xml_field );
----            End if; 
----         End Loop;
----         xmlTemp1:=XMLTYPE(clbTemp);
----         RootNode := XMLDOM.APPENDCHILD(xmlTemp1, RootNode);   
----    end loop;
----    xmlDom.writetoClob(docFinal , clbTemp);
--   
--
--
----  for curFields1 in
----    (select fldp_xml_field,FLDP_PROCESS_YN
----        from trsystem999
----        where fldp_table_synonym = EntityName)
----     Loop
----          IF curFields1.FLDP_PROCESS_YN='Y' THEN
----              varXPath := '//' ||curFields1.fldp_xml_field;
----              nodTemp := xslProcessor.selectNodes(nodFinal, varXPath);
----               -- XMLDOM.REMOVECHILD(nodTemp, xmlTemp);
----              
----              
------              BEGIN
------               xmlTemp:= nodTemp;
------               xmlTemp:= XMLDOM.REMOVECHILD(nodTemp, xmlTemp);
------               RETURN xmlTemp;
------            end;
----              FNCREMOVENODE(docFinal,nodFinal,nodTemp);
----        END IF;  
----        End Loop;
----        clbTemp := xmlTemp.GetClobVal();       
--
--          for curFields in
--        (select fldp_xml_field, fldp_column_name
--            from trsystem999
--            where fldp_table_synonym = EntityName)
--         Loop
--            if  InwardOutward = 'Inward' then               
--                  clbTemp := replace(clbTemp, curFields.fldp_xml_field ,curFields.fldp_column_name );         
--            end if;
--            if  InwardOutward = 'Outward' then
--                clbTemp := replace(clbTemp,curFields.fldp_column_name , curFields.fldp_xml_field );
--            End if; 
--         End Loop;
--    return clbTemp;
--Exception
--    When others then
--      numError := SQLCODE;
--      varError := SQLERRM;
--      varError := GConst.fncReturnError('AuditTrail', numError, varMessage,
--                      varOperation, varError);
--      raise_application_error(-20101, varError);
--      return clbTemp;
--End fncSubstituteFields;
-- Changed by Manjunath Reddy on 24/09/2019 insted of Replace process the complete row 
Function fncSubstituteFields
    (ParamData in Gconst.gClobType%Type,
     EntityName in varchar2,
     InwardOutward in varchar2)
return clob
is
    varEntity           varchar2(30);
    numError            Number;
    varOperation        varchar(4000);
    varMessage          varchar(4000);
    varError            varchar(4000);
    xmlTemp             xmltype;
    clbTemp             clob;
    nodTemp             xmlDom.domNode;
    nodTemp1             xmlDom.domNode;
    nodInnerTemp        xmlDom.domNode;
    docFinal            xmlDom.domDocument;
    nodFinal            xmlDom.domNode;
    RootNode            xmlDom.domNode;
    TXTNODE             XMLDOM.DOMTEXT;
    varXPath            varchar2(512);
    nlsTemp             xmlDom.DomNodeList;
    nlsTempInner        xmlDom.DomNodeList;
    nmpTemp             xmldom.domNamedNodeMap;
    ELMXML              XMLDOM.DOMELEMENT;
    numSub              number(5);
    varNodeName         varchar(30);
    varTemp             varchar2(100);
    varNodeValue        Clob;
    numInnerSub         number(5);
    TXTDOM              XMLDOM.DOMTEXT;
Begin
    varMessage := 'Substituting XML Fields to DB Fields  for ' ||  EntityName || ' Type ' ||  InwardOutward ;
    dbms_lob.createTemporary (clbTemp,  TRUE);
    clbTemp := ParamData;
    VarOperation:='Processing XML convertion for ' ||  EntityName || ' Type ' ||  InwardOutward ;
    xmlTemp:=XMLTYPE(ParamData);
    docFinal := xmlDom.newDomDocument(xmlTemp);
    nodFinal := xmlDom.makeNode(docFinal);
    
   -- dbms_lob.createtemporary (clbTempRows,true);
    --clbTempRows := nlsTemp;
    
    varXPath := '//' || EntityName  ;
    RootNode:= xslProcessor.SELECTSINGLENODE(nodFinal,varXPath);
 
    varXPath := '//' || EntityName || '/ROW';
    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);
    numSub := xmlDom.getLength(nlsTemp);
    
    for numSub in 1..xmlDom.getLength(nlsTemp)
    Loop
        varOperation := 'Extracting Data';
        nodTemp := xmlDom.Item(nlsTemp, numSub);
        nmpTemp:= xmlDom.getAttributes(nodTemp);
        nodTemp := xmlDom.Item(nmpTemp, 0);
        --xmlDom.writeToClob(nodTemp, clbTemp);
        varXPath :='//' || EntityName ||'/ROW[@NUM="'||numSub || '"]';
       -- VARTEMP := '//' || TRIM(NODENAME) || '/text()';
       -- nlsTempInner := xslProcessor.selectNodes(nodFinal, varXPath);
      
        RootNode:= xslProcessor.SelectSingleNode(nodFinal, varXPath);
        nlsTempInner :=xmlDom.getChildNodes(RootNode);
        for numInnerSub in 0..dbms_xmldom.getLength(nlsTempInner) -1
        loop
       
           nodTemp := xmlDom.Item(nlsTempInner, numInnerSub);
           varNodeName := DBMS_XMLDOM.getNodeName(nodTemp);
            varoperation:='Processign Node ' ||varNodeName;
           VARTEMP:=varXPath || '/' || varNodeName || '/text()';
           begin 
              varNodeValue := xmlTemp.EXTRACT(VARTEMP).GETSTRINGVAL();
           exception
             when others then 
              varNodeValue := null;
           end;
           if  InwardOutward = 'Inward' then     
              begin
                 select fldp_column_name 
                   into varTemp
                  from trsystem999
                  where fldp_table_synonym = EntityName
                    and fldp_xml_field=varNodeName;
              exception 
                when no_data_found then 
                    varTemp:=null;
              end;
           end if;
           if  InwardOutward = 'Outward' then
              begin
                select fldp_xml_field 
                 into varTemp
                from trsystem999
                where fldp_table_synonym = EntityName
                  and fldp_column_name=varNodeName;
              exception 
                when no_data_found then 
                    varTemp:=null;
              end;
           End if;
            
           
             varOperation := 'Extracting Data';
--            TXTNODE := DBMS_XMLDOM.CREATETEXTNODE(docFinal, varNodeValue);
--            nodInnerTemp := XMLDOM.MAKENODE(TXTNODE);
           if varTemp is not null then
              ELMXML := xmlDom.CreateElement(docFinal,varTemp); 
              nodInnerTemp := XMLDOM.MAKENODE(ELMXML);
              nodInnerTemp:=DBMS_XMLDOM.AppendCHILD(RootNode, nodInnerTemp);
              
              TXTDOM := XMLDOM.CREATETEXTNODE(docFinal, varNodeValue);
              nodTemp1 := XMLDOM.MAKENODE(TXTDOM);
              nodInnerTemp := XMLDOM.APPENDCHILD(nodInnerTemp, nodTemp1);
           end if; 
           -- XMLDOM.SETNODEVALUE(nodInnerTemp, varNodeValue);
            
            
            nodTemp:=XMLDOM.REMOVECHILD(nodTemp, nodTemp);
            
        end loop;
    end loop;

    DBMS_LOB.CREATETEMPORARY (clbTemp,  TRUE);
    XMLDOM.WRITETOCLOB(docFinal, clbTemp);
    --dbms_output.put_line(clbTemp);
    return clbTemp;
Exception
    When others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('fncSubstituteFields', numError, varMessage,
                      varOperation, varError);
      raise_application_error(-20101, varError);
      return clbTemp;
End fncSubstituteFields;

End pkgMasterMaintenance;
/