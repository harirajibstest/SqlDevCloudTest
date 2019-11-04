CREATE OR REPLACE PACKAGE BODY "TEST_VSTSRedgate"."PKGBULKDATALOAD" as
Procedure prcSchemDataload
as
  varOperation        GConst.gvarOperation%Type;
  varMessage          GConst.gvarMessage%Type;
  varError            GConst.gvarError%Type;
  numError            number;
 -- numPickValue        number(8);
begin


  varOperation := 'Inserting records from staging table';
  insert into trmaster410
   (	MFSC_COMPANY_CODE , MFSC_AMC_CODE, MFSC_SHORT_DESCRIPTION ,MFSC_LONG_DESCRIPTION,
      MFSC_SCHEME_TYPE,MFSC_SCHEME_CATEGORY,MFSC_SCHEME_NAVNAME,MFSC_SCHEME_MINAMOUNT,MFSC_LAUNCH_DATE,
      MFSC_CLOSURE_DATE,MFSC_CLOSEDFLAG,MFSC_ENTRY_LOAD,MFSC_EXIT_LOAD,	MFSC_EXIT_APLICABLE,
      MFSC_RECORD_STATUS,MFSC_ADD_DATE,MFSC_CREATE_DATE ,MFSC_NAV_CODE,MFSC_LOCATION_CODE,MFSC_MF_Remarks)

     select 30100001, pkgbulkdataload.fncGetPickCode(AMC,418,'Y'),
          substr(Scheme_name,1,15),scheme_name,
          pkgbulkdataload.fncGetPickCode(Scheme_type,419,'Y'),pkgbulkdataload.fncGetPickCode(scheme_category,420,'Y'),
          Scheme_nav_name,decode(isnumber(scheme_minimum_Amount), 0, scheme_minimum_amount, 0),
          decode(launch_date, NULL, NULL, to_date(launch_date,'dd-mon-yyyy')),
          decode(closure_date, NULL, NULL, to_date(launch_date,'dd-mon-yyyy')),
          decode(closed_flag,'Y',12400001,12400002),0,0,0,
          10200001,sysdate,sysdate,code,30299999,scheme_Load || ' Min Amount: ' || scheme_minimum_amount
     from trStaging001
     where not exists
      (select 'X' from trmaster410
        where mfsc_nav_code=Code)
    -- and to_date(substr(closure_date,1,10),'dd/mm/yyyy') >= sysdate
     and closed_flag='N';
    exception
    when others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('MFSchemLoad', numError, varMessage,
                      varOperation, varError);
      raise_application_error(-20101, varError);
 end prcSchemDataload;
-----------------------------------------------
function fncGetPickCode(
         PickDescription in varchar,
         pickCode in number,
         AddNewEntry in char) return number
as
  varOperation        GConst.gvarOperation%Type;
  varMessage          GConst.gvarMessage%Type;
  varError            GConst.gvarError%Type;
  numError            number;
  numPickCode number(8);
  pragma autonomous_transaction;
begin
      varMessage :=  substr(PickDescription,1,50) ;
      varOperation := 'Generating the next sequence';

        
   begin
    select PICK_KEY_VALUE
       into numPickCode
     from trmaster001
     where pick_key_group=pickCode
     and (pick_Long_description =substr(PickDescription,1,50));
   exception
   when no_data_found then
      numPickCode:= null;
   end;
   if numPickCode is null then
      prcProcessPickup(PickCode,substr(PickDescription,1,15),substr(PickDescription,1,50),numPickCode);
   end if;
   commit;
    return numPickCode;
exception
   when others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('fncGetPickCode', numError, varMessage,
                           varOperation, varError);
      rollback;
      raise_application_error(-20101, varError);
end fncGetPickCode;
-----------------------------------------------------------------------------------------------------
Procedure prcXlsRateUpLoad
as
  datTemp             date;
  numError            number;
  varOperation        GConst.gvarOperation%Type;
  varMessage          GConst.gvarMessage%Type;
  varError            GConst.gvarError%Type;
  datnavupto          date;
  numSerial            number;
begin
  datTemp := to_date(sysdate,'DD-MM-YY');
  begin
    select nvl(max(DRAT_SERIAL_NUMBER),0) into numSerial from trtran012 where drat_effective_date = to_date(sysdate,'DD-MM-YY');
  
      Exception
          When others then
        numSerial := 0;
  end;
  numSerial := numSerial + 1;
  INSERT INTO TRTRAN012
  (DRAT_CURRENCY_CODE,DRAT_FOR_CURRENCY,DRAT_EFFECTIVE_DATE,DRAT_SERIAL_NUMBER,DRAT_RATE_TIME,DRAT_TIME_STAMP,DRAT_RATE_DESCRIPTION,
  DRAT_SPOT_BID,DRAT_SPOT_ASK,DRAT_MONTH1_BID,DRAT_MONTH2_BID,DRAT_MONTH3_BID,DRAT_MONTH4_BID,DRAT_MONTH5_BID,DRAT_MONTH6_BID,
  DRAT_MONTH7_BID,DRAT_MONTH8_BID,DRAT_MONTH9_BID,DRAT_MONTH10_BID,DRAT_MONTH11_BID,DRAT_MONTH12_BID,DRAT_MONTH1_ASK,
  DRAT_MONTH2_ASK,DRAT_MONTH3_ASK,DRAT_MONTH4_ASK,DRAT_MONTH5_ASK,DRAT_MONTH6_ASK,DRAT_MONTH7_ASK,DRAT_MONTH8_ASK,DRAT_MONTH9_ASK,
  DRAT_MONTH10_ASK,DRAT_MONTH11_ASK,DRAT_MONTH12_ASK,DRAT_CREATE_DATE,DRAT_ADD_DATE,DRAT_ENTRY_DETAIL,DRAT_RECORD_STATUS)
  SELECT 
       CurrencyCode,ForCurrencyCode,to_date(sysdate,'DD-MM-YY'),numSerial,
       sysdate,sysdate,'Rates For :- ' || desceription ||' As on :- ' || sysdate,sum(Bid),Sum(Ask),
       SUM(NVL(Month1Bid,0))+ sum(Bid) Month1Bid,SUM(NVL(Month2Bid,0)) + sum(Bid) Month2Bid, 
       SUM(NVL(Month3Bid,0))+ sum(Bid)  Month3Bid,SUM(NVL(Month4Bid,0))+ sum(Bid) Month4Bid,
       SUM(NVL(Month5Bid,0))+ sum(Bid)  Month5Bid,SUM(NVL(Month6Bid,0))+ sum(Bid) Month6Bid, 
       SUM(NVL(Month7Bid,0))+ sum(Bid)  Month7Bid,SUM(NVL(Month8Bid,0))+ sum(Bid) Month8Bid,
       SUM(NVL(Month9Bid,0))+ sum(Bid)  Month9Bid,SUM(NVL(Month10Bid,0))+ sum(Bid) Month10Bid, 
       SUM(NVL(Month11Bid,0)) + sum(Bid) Month11Bid,SUM(NVL(Month12Bid,0))+ sum(Bid) Month12Bid,
       SUM(NVL(Month1Ask,0))+ sum(Ask)  Month1Ask,SUM(NVL(Month2Ask,0))+ sum(Ask) Month2Ask, 
       SUM(NVL(Month3Ask,0))+ sum(Ask)  Month3Ask,SUM(NVL(Month4Ask,0))+ sum(Ask) Month4Ask,
       SUM(NVL(Month5Ask,0))+ sum(Ask)  Month5Ask,SUM(NVL(Month6Ask,0))+ sum(Ask) Month6Ask, 
       SUM(NVL(Month7Ask,0))+ sum(Ask)  Month7Ask,SUM(NVL(Month8Ask,0))+ sum(Ask) Month8Ask,
       SUM(NVL(Month9Ask,0))+ sum(Ask)  Month9Ask,SUM(NVL(Month10Ask,0))+ sum(Ask) Month10Ask, 
       SUM(NVL(Month11Ask,0))+ sum(Ask)  Month11Ask,SUM(NVL(Month12Ask,0))+ sum(Ask) Month12Ask,
       sysdate,sysdate,null,10200001
       FROM(
              select 
              --substr(desceription,8,3),
              decode(substr(desceription,8,3),'01M',SUM(bid)/10000) Month1Bid,
              decode(substr(desceription,8,3),'02M',SUM(bid)/10000) Month2Bid,
              decode(substr(desceription,8,3),'03M',SUM(bid)/10000) Month3Bid,
              decode(substr(desceription,8,3),'04M',SUM(bid)/10000) Month4Bid,
              decode(substr(desceription,8,3),'05M',SUM(bid)/10000) Month5Bid,
              decode(substr(desceription,8,3),'06M',SUM(bid)/10000) Month6Bid,
              decode(substr(desceription,8,3),'07M',SUM(bid)/10000) Month7Bid,
              decode(substr(desceription,8,3),'08M',SUM(bid)/10000) Month8Bid,
              decode(substr(desceription,8,3),'09M',SUM(bid)/10000) Month9Bid,
              decode(substr(desceription,8,3),'10M',SUM(bid)/10000) Month10Bid,
              decode(substr(desceription,8,3),'11M',SUM(bid)/10000) Month11Bid,
              decode(substr(desceription,8,3),'12M',SUM(bid)/10000) Month12Bid,
              decode(substr(desceription,8,3),'01M',SUM(ask)/10000) Month1Ask,
              decode(substr(desceription,8,3),'02M',SUM(ask)/10000) Month2Ask,
              decode(substr(desceription,8,3),'03M',SUM(ask)/10000) Month3Ask,
              decode(substr(desceription,8,3),'04M',SUM(ask)/10000) Month4Ask,
              decode(substr(desceription,8,3),'05M',SUM(ask)/10000) Month5Ask,
              decode(substr(desceription,8,3),'06M',SUM(ask)/10000) Month6Ask,
              decode(substr(desceription,8,3),'07M',SUM(ask)/10000) Month7Ask,
              decode(substr(desceription,8,3),'08M',SUM(ask)/10000) Month8Ask,
              decode(substr(desceription,8,3),'09M',SUM(ask)/10000) Month9Ask,
              decode(substr(desceription,8,3),'10M',SUM(ask)/10000) Month10Ask,
              decode(substr(desceription,8,3),'11M',SUM(ask)/10000) Month11Ask,
              decode(substr(desceription,8,3),'12M',SUM(ask)/10000) Month12Ask,
              substr(desceription,1,6)desceription,
              case when length(desceription) <= 6 then SUM(ask) end Ask,
              case when length(desceription) <= 6 then SUM(bid) end Bid,
              case when length(desceription) <= 6 then SUM(LTP) end LTP,
              (select cncy_pick_code from trmaster304 where cncy_short_description = substr(desceription,1,3)) as CurrencyCode,
              (select cncy_pick_code from trmaster304 where cncy_short_description = substr(desceription,4,3)) as ForCurrencyCode
              --bid/10000,ask/10000 
              from TRSTAGING008 
              GROUP BY desceription,substr(desceription,8,3)) a
        group by desceription, CurrencyCode,ForCurrencyCode,numSerial;
    commit;
    Exception
          When others then
            numError := SQLCODE;
            varError := SQLERRM;
            varError := GConst.fncReturnError('prcXlsRateUpLoad', numError, varMessage,
                            varOperation, varError);
            raise_application_error(-20101, varError);

end prcXlsRateUpLoad;
-----------------------------------------------------------------------------------------------------
Procedure prcNAVLoad
as
  datTemp             date;
  numError            number;
  varOperation        GConst.gvarOperation%Type;
  varMessage          GConst.gvarMessage%Type;
  varError            GConst.gvarError%Type;
  datnavupto         date;
begin


        
    select max(to_date(schemedate,'dd-Mon-yyyy'))
      into datTemp
     from trstaging002 where isnumber(schemecode) = 0 and SCHEMECODE in (select mfsc_nav_code from trmaster404);
     
    -- if datnavupto< datTemp and next_day(datnavupto ,' then
     varOperation := 'deleting data if already loaded for the day';
     delete from  TRTRAN050
     where MFMM_REFERENCE_DATE = datTemp;
     
       varOperation := 'NAV Uploaded till date';
     select to_date(max(MFMM_REFERENCE_DATE),'dd-mon-yyyy') into datnavupto from trtran050 ;
      
    varOperation := 'Inseting NAV Data for the day';
    insert into TRTRAN050 (MFMM_SOURCE_NAME,MFMM_NAV_CODE,MFMM_REFERENCE_DATE,
      MFMM_ISINDIV_PAYOUT,MFMM_ISINDIV_REINVESTMENT,
      MFMM_NETASSET_VALUE,MFMM_REPURCHASE_PRICE,MFMM_SALE_PRICE,
      MFMM_RECORD_STATUS,MFMM_ADD_DATE,MFMM_CREATE_DATE,
      MFMM_SCHEME_NAME)
    select 'AIMF' ,schemecode,datTemp,
      isindivpayout_isingrowth,isindivreinvestment,
      decode(isnumber(netassetvalue),0, to_number(netassetvalue),0),
      decode(isnumber(repurchaseprice),0,to_number(repurchaseprice),0),
      decode(isnumber(saleprice),0,to_number(saleprice),0),
      10200003,to_date(schemedate),sysdate,schemename
      from trstaging002
      where isnumber(schemecode) = 0
--      and schemedate= datTemp commented on 09/02/15 as NAVs of previous dates are published
      and schemecode in
      (select mfsc_nav_code
        from trmaster404);

    varOperation := 'Inserting Previous day Records, if missing';
--    insert into trtran050
--			select mfmm_source_name,mfmm_nav_code,datTemp,mfmm_isindiv_payout,
--			mfmm_isindiv_reinvestment,mfmm_scheme_name,mfmm_netasset_value,mfmm_repurchase_price,
--			mfmm_sale_price,mfmm_corpus_amount,mfmm_reference_date,sysdate,mfmm_entry_details,
--			mfmm_record_status,mfmm_dividend_amount
--			from trtran050 a
--			where mfmm_reference_date =
--			(select max(mfmm_reference_date)
--				from trtran050 b
--				where b.mfmm_nav_code = a.mfmm_nav_code
--				and b.mfmm_reference_date < a.mfmm_reference_date)
--      and not exists
--      (select 'x'
--        from trtran050 c
--        where c.mfmm_nav_code = a.mfmm_nav_code
--        and c.mfmm_reference_date = datTemp);
  if trunc(to_date(datnavupto +1 ,'dd-mon-yyyy'),'DD') < trunc(to_date(datTemp,'dd-mon-yyyy'),'DD') then
    varOperation := 'Inserting Previous day Records, if missing';
    delete from trstaging007;
    insert into trstaging007 select * from trstaging002  where isnumber(schemecode) = 0 and SCHEMECODE in (select mfsc_nav_code from trmaster404);
    
    insert into TRTRAN050 (MFMM_SOURCE_NAME,MFMM_NAV_CODE,MFMM_REFERENCE_DATE,
      MFMM_ISINDIV_PAYOUT,MFMM_ISINDIV_REINVESTMENT,
      MFMM_NETASSET_VALUE,MFMM_REPURCHASE_PRICE,MFMM_SALE_PRICE,
      MFMM_RECORD_STATUS,MFMM_ADD_DATE,MFMM_CREATE_DATE,
      MFMM_SCHEME_NAME)
    select 'AIMF' ,schemecode,to_date(datnavupto +1),
      isindivpayout_isingrowth,isindivreinvestment,
      decode(isnumber(netassetvalue),0, to_number(netassetvalue),0),
      decode(isnumber(repurchaseprice),0,to_number(repurchaseprice),0),
      decode(isnumber(saleprice),0,to_number(saleprice),0),
      10200003,to_date(schemedate),sysdate,schemename
      from trstaging007
      where isnumber(schemecode) = 0
--      and schemedate= datTemp commented on 09/02/15 as NAVs of previous dates are published
      and schemecode in
      (select mfsc_nav_code
        from trmaster404);
 end if;
  if trunc(to_date(datnavupto +2 ,'dd-mon-yyyy'),'DD') < trunc(to_date(datTemp,'dd-mon-yyyy'),'DD') then
      varOperation := 'Inserting Previous day2 Records, if missing';
      insert into TRTRAN050 (MFMM_SOURCE_NAME,MFMM_NAV_CODE,MFMM_REFERENCE_DATE,
        MFMM_ISINDIV_PAYOUT,MFMM_ISINDIV_REINVESTMENT,
        MFMM_NETASSET_VALUE,MFMM_REPURCHASE_PRICE,MFMM_SALE_PRICE,
        MFMM_RECORD_STATUS,MFMM_ADD_DATE,MFMM_CREATE_DATE,
        MFMM_SCHEME_NAME)
      select 'AIMF' ,schemecode,to_date(datnavupto +2),
        isindivpayout_isingrowth,isindivreinvestment,
        decode(isnumber(netassetvalue),0, to_number(netassetvalue),0),
        decode(isnumber(repurchaseprice),0,to_number(repurchaseprice),0),
        decode(isnumber(saleprice),0,to_number(saleprice),0),
        10200003,to_date(schemedate),sysdate,schemename
        from trstaging007
        where isnumber(schemecode) = 0
  --      and schemedate= datTemp commented on 09/02/15 as NAVs of previous dates are published
        and schemecode in
        (select mfsc_nav_code
          from trmaster404);
   end if; 
    Exception
          When others then
            numError := SQLCODE;
            varError := SQLERRM;
            varError := GConst.fncReturnError('NAVUpload', numError, varMessage,
                            varOperation, varError);
            raise_application_error(-20101, varError);

end prcNAVLoad;
------------------------------------------------------------------------------------------------------------------------
Procedure prcNAVHistory
as
  datTemp             date;
  numError            number;
  varOperation        GConst.gvarOperation%Type;
  varMessage          GConst.gvarMessage%Type;
  varError            GConst.gvarError%Type;
begin

    varOperation := 'Merging NAV upload to NAV table';
    merge into trtran050 a using
      (select schemecode,schemename,netassetvalue,
        repurchaseprice,saleprice,to_date(schemedate) schemedate
        from trstaging003
        where isdate(schemedate,'dd-mon-yyyy') = 0) b
        on (b.schemecode = a.mfmm_nav_code
          and to_date(b.schemedate) = a.mfmm_reference_date)
        when matched then
          update set
          a.mfmm_netasset_value = decode(isnumber(b.netassetvalue),0, to_number(b.netassetvalue),0),
          a.mfmm_repurchase_price = decode(isnumber(b.repurchaseprice),0,to_number(b.repurchaseprice),0),
          a.mfmm_sale_price = decode(isnumber(b.saleprice),0,to_number(b.saleprice),0),
          a.mfmm_create_date = sysdate,a.mfmm_record_status = 10200004
        when not matched then insert
        (a.mfmm_source_name,a.mfmm_nav_code,a.mfmm_reference_date,
          a.mfmm_netasset_value,a.mfmm_repurchase_price,a.mfmm_sale_price,
          a.mfmm_record_status,a.mfmm_add_date,a.mfmm_create_date, a.mfmm_scheme_name)
         values ('AIMF',b.schemecode,to_date(b.schemedate),
          decode(isnumber(b.netassetvalue),0, to_number(b.netassetvalue),0),
          decode(isnumber(b.repurchaseprice),0,to_number(b.repurchaseprice),0),
          decode(isnumber(b.saleprice),0,to_number(b.saleprice),0),
          10200003,sysdate,sysdate,b.schemename)
      where b.schemename is not null
      and b.schemecode in
      (select mfsc_nav_code
        from trmaster404);

    Exception
          When others then
            numError := SQLCODE;
            varError := SQLERRM;
            varError := GConst.fncReturnError('NavHistory', numError, varMessage,
                            varOperation, varError);
            raise_application_error(-20101, varError);

end prcNAVHistory;
---------------------------------------------------------------------------
Procedure prcCPLoad
as
  datTemp             date;
  numError            number;
  varOperation        GConst.gvarOperation%Type;
  varMessage          GConst.gvarMessage%Type;
  varError            GConst.gvarError%Type;
begin

    varOperation := 'Uploading Commercial Paper Upload';
    insert into trmaster402
    (cpde_isin_number, cpde_company_name,cpde_issue_date,cpde_face_value,
     cpde_maturity_date,cpde_credit_rating, cpde_rating_agency, cpde_nsdl_details,
     cpde_cp_details, cpde_rta_agent,cpde_ipa_details,cpde_company_address,
     cpde_ipa_demat)
   select isinnumber, companyname, to_date(substr(cpdetails, instr(cpdetails,':',1,2) + 1,10),'dd-mm-yyyy'),
      substr(cpdetails, instr(cpdetails,':',1,1) + 1,6), to_date(substr(redeemdate,1,10),'dd/mm/yyyy'),
      substr(cpdetails, instr(cpdetails,':',1,4) + 1,(instr(cpdetails,'Credit Agency') -
        instr(cpdetails,'Credit Rating:')) - 14),substr(cpdetails, instr(cpdetails,':',1,5) + 1),
      nsdldesciption,cpdetails,rtagent,ipadetails,companyaddress,ipademat
      from trstaging004
      where to_date(substr(redeemdate,1,10),'dd/mm/yyyy') >= '01-JAN-2015'
      and isinnumber not in
      (select cpde_isin_number
        from trmaster402);

    Exception
          When others then
            numError := SQLCODE;
            varError := SQLERRM;
            varError := GConst.fncReturnError('CPUpload', numError, varMessage,
                            varOperation, varError);
            raise_application_error(-20101, varError);

end prcCPLoad;

Procedure prcCDLoad
as
  datTemp             date;
  numError            number;
  varOperation        GConst.gvarOperation%Type;
  varMessage          GConst.gvarMessage%Type;
  varError            GConst.gvarError%Type;
begin

    varOperation := 'Uploading Certificate of Deposit upload';
    insert into trmaster403
    (cdde_isin_number,cdde_bank_code,cdde_face_value,cdde_maturity_date,
     cdde_credit_rating,cdde_rating_agency,cdde_cd_details,cdde_rta_agent,
     cdde_redeem_details,cdde_issuer_contact,cdde_cd_demat)
    select isisnumber,
      (select pick_key_value
        from trmaster001
        where pick_key_group = 343
        and trim(substr(bankname,1,16)) = trim(substr(pick_long_description,1,16))),
      trim(substr(cddetails,instr(cddetails,':',1,1)+1,
      instr(upper(cddetails), 'MATUR')-1 - instr(cddetails,':',1,1))) fv,
      to_date(redeemdate,'mm/dd/yyyy'),   trim(substr(creditrating, instr(creditrating, ':', 1,1) + 1,
        instr(upper(creditrating),'AGENCY') - instr(creditrating, ':', 1,1))) rating,
      trim(substr(creditrating,instr(creditrating,':',1,2)+1)),cddetails,
      rtagent,redeemdetails, issuercontact,cddemat
      from trstaging005
      where to_date(redeemdate,'mm/dd/yyyy')  >= '01-JAN-2015'
      and isisnumber not in
      (select cdde_isin_number
        from trmaster403);

    Exception
          When others then
            numError := SQLCODE;
            varError := SQLERRM;
            varError := GConst.fncReturnError('CPUpload', numError, varMessage,
                            varOperation, varError);
            raise_application_error(-20101, varError);

end prcCDLoad;

--procedure prcCPTrade
--as
--  datTemp             date;
--  numError            number;
--  varOperation        GConst.gvarOperation%Type;
--  varMessage          GConst.gvarMessage%Type;
--  varError            GConst.gvarError%Type;
--begin
--    numError := 0;
--    varOperation := 'Uploading Commercial Paper Traded Data';
--    insert into trtran050A
--      (cpcd_isin_number,cpcd_reference_date,cpcd_transaction_type,
--      cpcd_security_name,cpcd_maturity_date,cpcd_residual_days,
--      cpcd_settlement_type,cpcd_last_price,cpcd_last_yield,
--      cpcd_open_yield,cpcd_high_yield,cpcd_low_yield,
--      cpcd_wtavg_price,cpcd_wtavg_yield,cpcd_create_date,
--      cpcd_record_status)
--    select isinumber,to_date(substr(dealdate,1,10),'dd/mm/yyyy'), GConst.COMMERCIALPAPER,
--      securityname,to_date(substr(maturitydate,1,10),'dd/mm/yyyy'),to_number(residualdays),
--      settlementtype,to_number(lastprice),to_number(lastyield),
--      to_number(openyield),to_number(highyield),to_number(lowyield),
--      to_number(weightprice),to_number(wieghtyield),sysdate,10200001
--      from trstaging006;
--    Exception
--          When others then
--            numError := SQLCODE;
--            varError := SQLERRM;
--            varError := GConst.fncReturnError('CPTrade', numError, varMessage,
--                            varOperation, varError);
--            raise_application_error(-20101, varError);
--
--end prcCPTrade;
--
--procedure prcCDTrade
--as
--  datTemp             date;
--  numError            number;
--  varOperation        GConst.gvarOperation%Type;
--  varMessage          GConst.gvarMessage%Type;
--  varError            GConst.gvarError%Type;
--begin
--    numError := 0;
--    varOperation := 'Uploading Commercial Paper Traded Data';
--    insert into trtran050A
--      (cpcd_isin_number,cpcd_reference_date,cpcd_transaction_type,
--      cpcd_security_name,cpcd_maturity_date,cpcd_residual_days,
--      cpcd_settlement_type,cpcd_last_price,cpcd_last_yield,
--      cpcd_open_yield,cpcd_high_yield,cpcd_low_yield,
--      cpcd_wtavg_price,cpcd_wtavg_yield,cpcd_create_date,
--      cpcd_record_status)
--    select isinumber,to_date(dealdate), GConst.CERTIFICATEOFDEPOSIT,
--    securityname,to_date(maturitydate),to_number(residualdays),
--    settlementtype,to_number(lastprice),to_number(lastyield),
--    to_number(openyield),to_number(highyield),to_number(lowyield),
--    to_number(weightprice),to_number(wieghtyield),sysdate,10200001
--    from trstaging006;
--    Exception
--          When others then
--            numError := SQLCODE;
--            varError := SQLERRM;
--            varError := GConst.fncReturnError('CDTrade', numError, varMessage,
--                            varOperation, varError);
--            raise_application_error(-20101, varError);
--
--end prcCDTrade;

procedure prcProcessPickup
              ( numKeyGroup in number,
                PickShortDescription in varchar,
                PickLongDescription in varchar,
                numPickValue out number)
as
      numError            number;
      numRecords          number;
      numAction           number(3);
    --  numKeyGroup         number(3);
      numKeyNumber        number(5);
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
      varMessage :=  PickLongDescription ;
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

        select distinct pick_company_code,pick_key_type
        into numCompanyCode,numKeyType
        from PickupMaster
        where pick_key_group = numKeyGroup
        and pick_key_number = 0;

      numError := 5;
      varOperation := 'Inserting new value for Pickup' || numRecordStatus;

      insert into PickupMaster (pick_company_code, pick_key_group, pick_key_number,
        pick_key_value, pick_short_description, pick_long_description,pick_key_type,
        pick_remarks, pick_entry_detail, pick_record_status)
        values(numCompanyCode, numKeyGroup, numKeyNumber,
        numPickValue, PickShortDescription, PickLongDescription, numKeyType,
        'Cascaded from master entry', null, 10200003);

    --  PickValue := numPickValue;
      numError := 0;
      varError := 'Successful Operation';

      Exception
          When Error_Occurred then
            numError := -1;
            varError := GConst.fncReturnError('prcProcessPickup', numError, varMessage,
                            varOperation, varError);
            raise_application_error(-20101, varError);

          When others then
            numError := SQLCODE;
            varError := SQLERRM;
            varError := GConst.fncReturnError('prcProcessPickup', numError, varMessage,
                            varOperation, varError);
            raise_application_error(-20101, varError);
  End prcProcessPickup;

procedure prcPopulateExposure
as
 datPreDate date;
 datRefDate date;
 numError            number;
  varOperation        GConst.gvarOperation%Type;
  varMessage          GConst.gvarMessage%Type;
  varError            GConst.gvarError%Type;
begin
  
  delete from trtran002e_stagingtable_c;
  
  insert into TRTRAN002E_STAGINGTABLE_C 
      (referenceDate,
      COMPANY,
      A_C,
      BANKER,
      PLACE,
      DUE_DATE,
      M,
      LC_NO,
      LC_DT,
      QTY,
      RATE,
      INTAMT,
      CONCHRG,
      AMOUNT_US,
      AMOUNT_RS,
      PAYMENTCONFIRMED,
      VESSEL_NAME,
      PORT,
      APP,
      BENEFICIARY,
      USANCE,
      BL_DATE,
      C_TYPE,
      CONTRACT_NO,
      CONTRACT_DATE,
      REMARK)
      select 
      referencedate,
      COMPANY,
      A_C,
      BANKER,
      PLACE,
      DUE_DATE,
      M,
      LC_NO,
      LC_DT,
      QTY,
      RATE,
      INTAMT,
      CONCHRG,
      AMOUNT_US,
      AMOUNT_RS,
      PAYMENTCONFIRMED,
      VESSEL_NAME,
      PORT,
      APP,
      BENEFICIARY,
      USANCE,
      BL_DATE,
      C_TYPE,
      CONTRACT_NO,
      CONTRACT_DATE,
      REMARK 
      from TRTRAN002E_STAGINGTABLE;
      
  VarOperation:='Converting Company Code ';  
  
  Update TRTRAN002E_STAGINGTABLE_C  set COMPANY_C = nvl((select Pick_key_value from trmaster001 
   where pick_short_description= COMPANY
   and pick_key_group=301),30199999);
  VarOperation:='Converting Bank Code ';   
  Update TRTRAN002E_STAGINGTABLE_C  set BANKER_C = nvl((select Pick_key_value from trmaster001 
   where pick_long_description= trim(BANKER)
   and pick_key_group=306),30699999);
  VarOperation:='Converting Due Date';
  Update TRTRAN002E_STAGINGTABLE_C  set DUE_DATE_C = to_date(DUE_DATE,'dd.mm.yy');

  VarOperation:='Converting LC Date';
  Update TRTRAN002E_STAGINGTABLE_C  set LC_DT_C = to_date(LC_DT,'dd.mm.yy');

  VarOperation:='Converting Contract Date';
  Update TRTRAN002E_STAGINGTABLE_C  set CONTRACT_DATE_C = to_date(CONTRACT_DATE,'dd.mm.yy');

  VarOperation:='Converting Quentity';
  Update TRTRAN002E_STAGINGTABLE_C  set QTY_C = to_number(QTY);
  
  VarOperation:='Converting Rate';
  Update TRTRAN002E_STAGINGTABLE_C  set RATE_C = to_number(RATE);

  VarOperation:='Converting Interest Amount';
  Update TRTRAN002E_STAGINGTABLE_C  set INTAMT_C = to_number(INTAMT);  

  VarOperation:='Converting Con Charge';
  Update TRTRAN002E_STAGINGTABLE_C  set CONCHRG_C = to_number(CONCHRG);  

  VarOperation:='Converting US Amount';
  Update TRTRAN002E_STAGINGTABLE_C  set AMOUNT_US_C = to_number(AMOUNT_US);  


  VarOperation:='Converting Local Amount';
  Update TRTRAN002E_STAGINGTABLE_C  set AMOUNT_RS_C = to_number(AMOUNT_RS);  
 
  VarOperation:='Delete the Existing transaction incase of any ';
  
  select distinct referencedate
  into datRefDate
  from trtran002e_stagingtable_c;
  
  
  delete from TRTRAN002E 
   where EXPO_REFERENCE_DATE =datRefDate;
   
   

  VarOperation:=' insert the data into transaction tables ';   
  insert into TRTRAN002E
    (EXPO_REFERENCE_DATE,  --1
    -- EXPO_CHANGE_TYPE,
     EXPO_COMPANY_CODE,  --2
     EXPO_ACCOUNT,       --3
     EXPO_COUNTER_PARTY, --4
     EXPO_COUNTERPARTY_REMARKS,  --5
     EXPO_PLACE ,   --6
    EXPO_DUE_DATE,  --7
    EXPO_FLAG_M,    --8
    EXPO_LC_NO,     --9
    EXPO_LC_DATE,   --10
    EXPO_QTY,      --11
    EXPO_RATE,     --12
    Expo_INTAMT,   --13
    EXPo_CONCHRG,  --14
    EXPO_BASE_CURRENCY,  --15
    EXPO_BASE_AMOUNT,  --16
    EXPO_EXCHAGE_RATE,  --17
    EXPO_AMOUNT_LOCAL,  --18
    EXPO_PAYMENT_CONFIRMED,  --19
    EXPO_VESSEL_NAME,--20
    EXPO_PORT,--21
    EXPO_APP,--22
    EXPO_BENEFICIARY,  --23
    EXPO_USANCE ,   --24
    EXPO_BL_DATE,   --25
    EXPO_CONTRACT_TYPE,  --26
    EXPO_CONTRACT_NO  ,  --27
    EXPO_CONTRACT_DATE,  --28
    EXPO_REMARK,
    Expo_serial_no)
      select 
      referencedate, --1
      COMPANY_C,--2
      A_C,--3
      BANKER_C,  --4
      banker,
      PLACE,  --5
      DUE_DATE_C,  --6
      M,  --7
      LC_NO,  --8
      LC_DT_C,  --9
      QTY_C,  --10
      RATE_C,  --11
      INTAMT_C,  --12
      CONCHRG,  --13
      30400004,
      AMOUNT_US_C,
      round(AMOUNT_RS_C/AMOUNT_US_C,4),
      AMOUNT_RS_C,  --15
      PAYMENTCONFIRMED,  --16
      VESSEL_NAME,  --17
      PORT,  --18
      APP,  --19
      BENEFICIARY,  --20
      USANCE,  --21
      BL_DATE_C,  --22
      C_TYPE,  --23
      CONTRACT_NO,  --24
      CONTRACT_DATE_C,  --25
      REMARK,   --26
      App_SerialNO
      from TRTRAN002E_STAGINGTABLE_C;

  VarOperation:=' Select the previous Update date to compare ';  
  
   select max(EXPO_REFERENCE_DATE) 
    into datPreDate
   from TRTRAN002E
   where EXPO_REFERENCE_DATE < (select distinct referencedate from trtran002e_stagingtable_c);
  
  VarOperation:=' Identify the new contracts ';  
  
 VarOperation:='Update the Serial Number';
 
   update  TRTRAN002E  set Expo_serial_no=
    (select Expo_serial_no from TRTRAN002E pre
      where Pre.EXPO_REFERENCE_DATE= datPreDate
     and  nvl(pre.EXPO_APP,'0')=  nvl(TRTRAN002E.EXPO_APP,'0')
     and  nvl(pre.EXPO_BASE_AMOUNT,'0')=  nvl(TRTRAN002E.EXPO_BASE_AMOUNT,'0')
     and nvl(pre.expo_lc_no,'NA')= nvl(TRTRAN002E.expo_lc_no,'NA')
     and nvl((select count(*) from  TRTRAN002E pre 
           where  Pre.EXPO_REFERENCE_DATE= datPreDate
             and  nvl(pre.EXPO_APP,'0')=  nvl(TRTRAN002E.EXPO_APP,'0')
             and nvl(pre.expo_lc_no,'NA')= nvl(TRTRAN002E.expo_lc_no,'NA')
             and  nvl(pre.EXPO_BASE_AMOUNT,'0')=  nvl(TRTRAN002E.EXPO_BASE_AMOUNT,'0')),0) =1
    and (select count(*) from  TRTRAN002E pre 
           where  Pre.EXPO_REFERENCE_DATE= datRefDate
             and  nvl(pre.EXPO_APP,'0')=  nvl(TRTRAN002E.EXPO_APP,'0')
             and nvl(pre.expo_lc_no,'NA')= nvl(TRTRAN002E.expo_lc_no,'NA')
             and  nvl(pre.EXPO_BASE_AMOUNT,'0')=  nvl(TRTRAN002E.EXPO_BASE_AMOUNT,'0')) =1)
    where EXPO_REFERENCE_DATE=datRefDate ;
     
     
  update trtran002e set  Expo_serial_no = (select appsrno from 
   (select rowid, row_number() over( partition by EXPO_APP order by EXPO_APP asc) appsrno
   from trtran002e
   where EXPO_REFERENCE_DATE=datRefDate) a
   where a.rowid= trtran002e.rowid)
   where Expo_serial_no is null
   and EXPO_REFERENCE_DATE=datRefDate;
   
 

     
 update TRTRAN002E set EXPO_CHANGE_TYPE='NE'
    where EXPO_REFERENCE_DATE=datRefDate   
  and not exists
   (select 'x' from TRTRAN002E Pre
    where Pre.EXPO_REFERENCE_DATE= datPreDate
     and  nvl(pre.EXPO_APP,'0')=  nvl(TRTRAN002E.EXPO_APP,'0')
     and  nvl(pre.Expo_serial_no,'0')=  nvl(TRTRAN002E.Expo_serial_no,'0'));

 update TRTRAN002E set EXPO_CHANGE_TYPE='EX'
    where EXPO_REFERENCE_DATE=datRefDate   
  and exists
   (select 'x' from TRTRAN002E Pre
    where Pre.EXPO_REFERENCE_DATE= datPreDate
     and  nvl(pre.EXPO_APP,'0')=  nvl(TRTRAN002E.EXPO_APP,'0')
     and  nvl(pre.Expo_serial_no,'0')=  nvl(TRTRAN002E.Expo_serial_no,'0'));
     
 

   
--  update TRTRAN002E set EXPO_CHANGE_TYPE='CH'
--  where EXPO_REFERENCE_DATE=datRefDate
--  and not exists
--   (select 'x' from TRTRAN002E Pre
--    where Pre.EXPO_REFERENCE_DATE= datPreDate
--     and nvl(pre.EXPO_COMPANY_CODE,'') = nvl(TRTRAN002E.EXPO_COMPANY_CODE,'')
--     and nvl(pre.EXPO_ACCOUNT,'0')= nvl(TRTRAN002E.EXPO_ACCOUNT,'0')
--     and nvl(pre.EXPO_COUNTER_PARTY,'0')=nvl(TRTRAN002E.EXPO_COUNTER_PARTY,'0')
--     and nvl(pre.EXPO_COUNTERPARTY_REMARKS,'0')=nvl(TRTRAN002E.EXPO_COUNTERPARTY_REMARKS,'0')
--     and nvl( pre.EXPO_PLACE ,'0')=nvl( TRTRAN002E.EXPO_PLACE ,'0')
--     and nvl(pre.EXPO_DUE_DATE,sysdate)= nvl(TRTRAN002E.EXPO_DUE_DATE,sysdate)
--     and nvl(pre.EXPO_FLAG_M,'0')=nvl(TRTRAN002E.EXPO_FLAG_M,'0')
--     and nvl(pre.EXPO_LC_NO,'0')= nvl(TRTRAN002E.EXPO_LC_NO,'0')
--     and nvl(pre.EXPO_LC_DATE,sysdate)= nvl(TRTRAN002E.EXPO_LC_DATE,sysdate)
--     and nvl(pre.EXPO_QTY,'0')= nvl(TRTRAN002E.EXPO_QTY,'0')
--     and nvl(pre.EXPO_RATE,'0')= nvl(TRTRAN002E.EXPO_RATE,'0')
--     and nvl(pre.Expo_INTAMT,'0')= nvl(TRTRAN002E.Expo_INTAMT,'0')
--     and nvl(pre.EXPo_CONCHRG,'0')=nvl(TRTRAN002E.EXPo_CONCHRG,'0')
--     and  nvl(pre.EXPO_BASE_CURRENCY,'0')= nvl(TRTRAN002E.EXPO_BASE_CURRENCY,'0')
--    and  nvl(pre.EXPO_BASE_AMOUNT,'0')=nvl(TRTRAN002E.EXPO_BASE_AMOUNT,'0')
--   and  nvl(pre.EXPO_EXCHAGE_RATE,'0')= nvl(TRTRAN002E.EXPO_EXCHAGE_RATE,'0')
--   and  nvl(pre.EXPO_AMOUNT_LOCAL,'0')=nvl(TRTRAN002E.EXPO_AMOUNT_LOCAL,'0')
--   and  nvl(pre.EXPO_PAYMENT_CONFIRMED,'0')=nvl(TRTRAN002E.EXPO_PAYMENT_CONFIRMED,'0')
--   and  nvl(pre.EXPO_VESSEL_NAME,'0')= nvl(TRTRAN002E.EXPO_VESSEL_NAME,'0')
--   and  nvl(pre.EXPO_PORT,'0')=nvl(TRTRAN002E.EXPO_PORT,'0')
--   and  nvl(pre.EXPO_APP,'0')=  nvl(TRTRAN002E.EXPO_APP,'0')
--   and  nvl(pre.EXPO_BENEFICIARY,'0')=nvl(TRTRAN002E.EXPO_BENEFICIARY,'0')
--   and  nvl(pre.EXPO_USANCE,'0') =nvl(TRTRAN002E.EXPO_USANCE,'0')
--   and  nvl(pre.EXPO_BL_DATE,'0')=nvl(TRTRAN002E.EXPO_BL_DATE,'0') 
--   and  nvl(pre.EXPO_CONTRACT_TYPE,'0')=nvl(TRTRAN002E.EXPO_CONTRACT_TYPE,'0')
--   and  nvl(pre.EXPO_CONTRACT_NO,sysdate)  =nvl(TRTRAN002E.EXPO_CONTRACT_NO,sysdate)
--   and  nvl(pre.EXPO_CONTRACT_DATE,sysdate)=  nvl(TRTRAN002E.EXPO_CONTRACT_DATE,sysdate)
--   and  nvl(pre.EXPO_REMARK,'0')=nvl(TRTRAN002E.EXPO_REMARK,'0'));



  VarOperation:=' Identify the Existing  contracts which are part of previous upload ';  
  
--  update TRTRAN002E set EXPO_CHANGE_TYPE='CH'
--  where EXPO_REFERENCE_DATE=datRefDate
--  and exists
--   (select 'x' from TRTRAN002E Pre
--    where Pre.EXPO_REFERENCE_DATE= datPreDate
--     and nvl(pre.EXPO_COMPANY_CODE,'') = nvl(TRTRAN002E.EXPO_COMPANY_CODE,'')
--     and nvl(pre.EXPO_ACCOUNT,'0')= nvl(TRTRAN002E.EXPO_ACCOUNT,'0')
--     and nvl(pre.EXPO_COUNTER_PARTY,'0')=nvl(TRTRAN002E.EXPO_COUNTER_PARTY,'0')
--     and nvl(pre.EXPO_COUNTERPARTY_REMARKS,'0')=nvl(TRTRAN002E.EXPO_COUNTERPARTY_REMARKS,'0')
--     and nvl( pre.EXPO_PLACE ,'0')=nvl( TRTRAN002E.EXPO_PLACE ,'0')
--     and nvl(pre.EXPO_DUE_DATE,sysdate)= nvl(TRTRAN002E.EXPO_DUE_DATE,sysdate)
--     and nvl(pre.EXPO_FLAG_M,'0')=nvl(TRTRAN002E.EXPO_FLAG_M,'0')
--     and nvl(pre.EXPO_LC_NO,'0')= nvl(TRTRAN002E.EXPO_LC_NO,'0')
--     and nvl(pre.EXPO_LC_DATE,sysdate)= nvl(TRTRAN002E.EXPO_LC_DATE,sysdate)
--     and nvl(pre.EXPO_QTY,'0')= nvl(TRTRAN002E.EXPO_QTY,'0')
--     and nvl(pre.EXPO_RATE,'0')= nvl(TRTRAN002E.EXPO_RATE,'0')
--     and nvl(pre.Expo_INTAMT,'0')= nvl(TRTRAN002E.Expo_INTAMT,'0')
--     and nvl(pre.EXPo_CONCHRG,'0')=nvl(TRTRAN002E.EXPo_CONCHRG,'0')
--     and  nvl(pre.EXPO_BASE_CURRENCY,'0')= nvl(TRTRAN002E.EXPO_BASE_CURRENCY,'0')
--    and  nvl(pre.EXPO_BASE_AMOUNT,'0')=nvl(TRTRAN002E.EXPO_BASE_AMOUNT,'0')
--   and  nvl(pre.EXPO_EXCHAGE_RATE,'0')= nvl(TRTRAN002E.EXPO_EXCHAGE_RATE,'0')
--   and  nvl(pre.EXPO_AMOUNT_LOCAL,'0')=nvl(TRTRAN002E.EXPO_AMOUNT_LOCAL,'0')
--   and  nvl(pre.EXPO_PAYMENT_CONFIRMED,'0')=nvl(TRTRAN002E.EXPO_PAYMENT_CONFIRMED,'0')
--   and  nvl(pre.EXPO_VESSEL_NAME,'0')= nvl(TRTRAN002E.EXPO_VESSEL_NAME,'0')
--   and  nvl(pre.EXPO_PORT,'0')=nvl(TRTRAN002E.EXPO_PORT,'0')
--   and  nvl(pre.EXPO_APP,'0')=  nvl(TRTRAN002E.EXPO_APP,'0')
--   and  nvl(pre.EXPO_BENEFICIARY,'0')=nvl(TRTRAN002E.EXPO_BENEFICIARY,'0')
--   and  nvl(pre.EXPO_USANCE,'0') =nvl(TRTRAN002E.EXPO_USANCE,'0')
--   and  nvl(pre.EXPO_BL_DATE,'0')=nvl(TRTRAN002E.EXPO_BL_DATE,'0') 
--   and  nvl(pre.EXPO_CONTRACT_TYPE,'0')=nvl(TRTRAN002E.EXPO_CONTRACT_TYPE,'0')
--   and  nvl(pre.EXPO_CONTRACT_NO,sysdate)  =nvl(TRTRAN002E.EXPO_CONTRACT_NO,sysdate)
--   and  nvl(pre.EXPO_CONTRACT_DATE,sysdate)=  nvl(TRTRAN002E.EXPO_CONTRACT_DATE,sysdate)
--   and  nvl(pre.EXPO_REMARK,'0')=nvl(TRTRAN002E.EXPO_REMARK,'0'));


  VarOperation:=' Identify the  contracts which are changed from previous Upload ';  
  
  update TRTRAN002E set EXPO_CHANGE_TYPE='CH'
  where EXPO_REFERENCE_DATE=datRefDate
   and EXPO_CHANGE_TYPE is null
  and not exists
   (select 'x' from TRTRAN002E Pre
    where Pre.EXPO_REFERENCE_DATE= datPreDate
     --and nvl(pre.EXPO_COMPANY_CODE,'') = nvl(TRTRAN002E.EXPO_COMPANY_CODE,'')
     --and nvl(pre.EXPO_ACCOUNT,'0')= nvl(TRTRAN002E.EXPO_ACCOUNT,'0')
     and nvl(pre.EXPO_COUNTER_PARTY,'0')=nvl(TRTRAN002E.EXPO_COUNTER_PARTY,'0')
     and nvl(pre.EXPO_COUNTERPARTY_REMARKS,'0')=nvl(TRTRAN002E.EXPO_COUNTERPARTY_REMARKS,'0')
     and nvl( pre.EXPO_PLACE ,'0')=nvl( TRTRAN002E.EXPO_PLACE ,'0')
     and nvl(pre.EXPO_DUE_DATE,sysdate)= nvl(TRTRAN002E.EXPO_DUE_DATE,sysdate)
     and nvl(pre.EXPO_FLAG_M,'0')=nvl(TRTRAN002E.EXPO_FLAG_M,'0')
     and nvl(pre.EXPO_LC_NO,'0')= nvl(TRTRAN002E.EXPO_LC_NO,'0')
     and nvl(pre.EXPO_LC_DATE,sysdate)= nvl(TRTRAN002E.EXPO_LC_DATE,sysdate)
     and nvl(pre.EXPO_QTY,'0')= nvl(TRTRAN002E.EXPO_QTY,'0')
     and nvl(pre.EXPO_RATE,'0')= nvl(TRTRAN002E.EXPO_RATE,'0')
     and nvl(pre.Expo_INTAMT,'0')= nvl(TRTRAN002E.Expo_INTAMT,'0')
     and nvl(pre.EXPo_CONCHRG,'0')=nvl(TRTRAN002E.EXPo_CONCHRG,'0')
     and  nvl(pre.EXPO_BASE_CURRENCY,'0')= nvl(TRTRAN002E.EXPO_BASE_CURRENCY,'0')
--    and  nvl(pre.EXPO_BASE_AMOUNT,'0')=nvl(TRTRAN002E.EXPO_BASE_AMOUNT,'0')
--   and  nvl(pre.EXPO_EXCHAGE_RATE,'0')= nvl(TRTRAN002E.EXPO_EXCHAGE_RATE,'0')
   and  nvl(pre.EXPO_AMOUNT_LOCAL,'0')=nvl(TRTRAN002E.EXPO_AMOUNT_LOCAL,'0')
   and  nvl(pre.EXPO_PAYMENT_CONFIRMED,'0')=nvl(TRTRAN002E.EXPO_PAYMENT_CONFIRMED,'0')
   and  nvl(pre.EXPO_VESSEL_NAME,'0')= nvl(TRTRAN002E.EXPO_VESSEL_NAME,'0')
   and  nvl(pre.EXPO_PORT,'0')=nvl(TRTRAN002E.EXPO_PORT,'0')
   and  nvl(pre.EXPO_APP,'0')=  nvl(TRTRAN002E.EXPO_APP,'0')
   and  nvl(pre.EXPO_BENEFICIARY,'0')=nvl(TRTRAN002E.EXPO_BENEFICIARY,'0')
   and  nvl(pre.EXPO_USANCE,'0') =nvl(TRTRAN002E.EXPO_USANCE,'0')
   and  nvl(pre.EXPO_BL_DATE,'0')=nvl(TRTRAN002E.EXPO_BL_DATE,'0') 
   and  nvl(pre.EXPO_CONTRACT_TYPE,'0')=nvl(TRTRAN002E.EXPO_CONTRACT_TYPE,'0')
   and  nvl(pre.EXPO_CONTRACT_NO,sysdate)  =nvl(TRTRAN002E.EXPO_CONTRACT_NO,sysdate)
   and  nvl(pre.EXPO_CONTRACT_DATE,sysdate)=  nvl(TRTRAN002E.EXPO_CONTRACT_DATE,sysdate)
   and  nvl(pre.EXPO_REMARK,'0')=nvl(TRTRAN002E.EXPO_REMARK,'0'));

     Exception
           When others then
            numError := SQLCODE;
            varError := SQLERRM;
            varError := GConst.fncReturnError('prcPopulateExposure', numError, varMessage,
                            varOperation, varError);
            raise_application_error(-20101, varError);

end;    


procedure prcFORWARDContractLoad
as
  datTemp             date;
  numError            number;
  varOperation        GConst.gvarOperation%Type;
  varMessage          GConst.gvarMessage%Type;
  varError            GConst.gvarError%Type;
  numSerial           number;
  companycode         number;
  numRowInserted      number;
  numRowsUpdated      number;
  numRowsNotProcessed number;
  numTotalRecords     number;
  varGUID                varchar(50);
  ErrorNum            number;
  ErrorMsg           varchar(4000);
  numProcessWhileErr  number(8);
begin
 numSerial := 0;
 companycode :=0;
  varMessage:=' Forward Contract Data Upload Process Started';
--insert into rtemp (TT) values(varMessage); commit;
  varOperation:=' Extracting GUID';
  select GUID
   into varGUID
  from trstaging015 where rownum=1;
  
  varOperation:=' Get the Total Rows';
  select Count(*)
   into numTotalRecords
  from trstaging015;
  
  
  varOperation:='Get the Flag to check whether to process the Rows While error';
  select nvl(LOAD_PROCESS_WHILE_ERR,12400001)
   into numProcessWhileErr
  from trsystem969
  where LOAD_DATA_NAME='FORWARDCONTRACT'
  and Load_record_status not in (10200005,10200006);
  
  varOperation := 'Staging ';    
  DELETE FROM TRSTAGING015_1;
  varoperation:=' Insert data from stage to stage 1 for firther process';
  insert into trstaging015_1 (EXECUTEDATE,LINKAMOUNT,BASECURRENCY,
                              OTHERCURRENCY,BANK,MATURITYDATE,
                              AMOUNTFCY,FORWARDRATE,CONTRACTNUMBER,BUYSELL,
                              COMPANYCODE,LOCATIONCODE,
                              PRODUCT, SUBPRODUCT, ENTRYDATE,RowNo,GUID)
          select EXECUTEDATE, LINKAMOUNT, BASECURRENCY,
                 OTHERCURRENCY,  BANK, MATURITYDATE,
                 AMOUNTFCY,FORWARDRATE,CONTRACTNUMBER,
                 BUYSELL,COMPANYCODE,
                 LOCATIONCODE,PRODUCT,SUBPRODUCT,
                 ENTRYDATE,rownum,varGUID
                 FROM trstaging015;
  

   varOperation:=' Processing Generic Validation'; 
  --  insert into rtemp (TT) values(varOperation); commit;          
   PKGBULKDATALOAD.ValidateData('FORWARDCONTRACT');  
   
   -- Custome Validations 
   
   update trstaging015_1 set Remarks = remarks || '|' || ' Maturity Date Can not be Less than the Execute Date'
    where EXECUTEDATE>MATURITYDATE;
   
  
    
   begin
     select nvl(count(*),0)
       into ErrorNum
      from trstaging015_1
      where remarks is not null;
   exception
    when others then 
      ErrorNum:=0;
   end;
    
   if ((ErrorNum!=0) and (numProcessWhileErr=12400001)) then
    varOperation:=' Update the audit table while error'; 
       update TRAUDIT001 set DATA_ROWS_PROCESSED =0,
        DATA_ROWS_NOTPROCESSED =numTotalRecords,
        DATA_UPLOAD_TIMESTAMP =SYSTIMESTAMP,
        DATA_UPLOAD_STATUS =12400002,
        DATA_UPLOAD_REMARKS='There are issues while Processing '
        where DATA_KEY_GUID=varGuid;
     Goto Process_end;
   end if;
     
    varOperation := 'Uploading Forward sysnumber';
    update trstaging015_1 set  sysreferencenumber= 'FWD' || Gconst.FNCGENERATESERIAL(Gconst.SERIALDEAL,30199999);
    varOperation := 'Insert into Base Table';
  --  insert into rtemp (TT) values(varOperation); commit;           
    INSERT INTO TRTRAN001 (DEAL_COMPANY_CODE,DEAL_EXECUTE_DATE,DEAL_BUY_SELL,
        DEAL_BASE_CURRENCY,DEAL_OTHER_CURRENCY, DEAL_COUNTER_PARTY,
        DEAL_MATURITY_FROM,DEAL_MATURITY_DATE,DEAL_BASE_AMOUNT,
        DEAL_OTHER_AMOUNT,DEAL_EXCHANGE_RATE,DEAL_SPOT_RATE,
        DEAL_FORWARD_RATE,DEAL_MARGIN_RATE,DEAL_DEAL_NUMBER,
        DEAL_SERIAL_NUMBER,DEAL_HEDGE_TRADE,DEAL_SWAP_OUTRIGHT,
        DEAL_DEAL_TYPE, DEAL_AMOUNT_LOCAL,DEAL_MATURITY_CODE,
        DEAL_BACKUP_DEAL,DEAL_INIT_CODE,DEAL_USER_ID,
        deal_process_complete,deal_create_date, deal_record_status,
        DEAL_TIME_STAMP,DEAL_DEALER_REMARKS) 
    SELECT  COMPANYCODE_CODE,EXECUTEDATE,BUYSELL_CODE,
         BASECURRENCY_CODE,OTHERCURRENCY_CODE,BANK_CODE,
         MATURITYDATE,MATURITYDATE,AMOUNTFCY,
         AMOUNTFCY* FORWARDRATE,FORWARDRATE,FORWARDRATE,
         0,0,sysreferencenumber,
         1,26000001,25200002,
         25400006,AMOUNTFCY* FORWARDRATE,25500005,
         PRODUCT_CODE,SUBPRODUCT_CODE,'sysAdmin',
         12400002,sysdate,10200001,
         TO_CHAR(SYSTIMESTAMP, 'DD-MON-YYYY HH24:MI:SS:FF3'),'Uploaded'
      from trstaging015_1
      where Remarks is null;
   
     varOperation := 'Extracting Rows Processed';
       SELECT  sum(case when  Remarks is null then 1 else 0 end),
                sum(case when  Remarks is not null then 1 else 0 end)
          into numRowInserted,numRowsNotProcessed
      from trstaging015_1;
      
    --numRowInserted:=SQL%Rowcount;
      varOperation := 'Update Audit Table with Status';
      update TRAUDIT001 set DATA_ROWS_PROCESSED =numRowInserted,
            DATA_ROWS_NOTPROCESSED =numRowsNotProcessed,
            DATA_UPLOAD_TIMESTAMP =SYSTIMESTAMP,
            DATA_UPLOAD_STATUS =12400001,
            DATA_UPLOAD_REMARKS='Sucessfully Processed'
            where DATA_KEY_GUID=varGuid;
    

    
   --  insert into rtemp (TT) values(varOperation); commit;          
    
    --update traudit001 set data_rows_processed=;
--      LEFT OUTER JOIN TRMASTER304 A
--      ON A.CNCY_SHORT_DESCRIPTION = BASECURRENCY
--      LEFT OUTER JOIN TRMASTER304 B
--      ON b.cncy_short_description = OTHERCURRENCY
--      LEFT OUTER JOIN TRMASTER306 C
--      on  c.lbnk_short_description = BANK and C.LBNK_COMPANY_CODE=COMPANYCODE
--      left outer join trmaster001 D
--      on d.pick_short_description=BUYSELL
--      left outer join TRMASTER301 E
--      ON e.comp_company_code=COMPANYCODE;  
--            
--       
--          
--         SELECT max(REVERSE(SUBSTR(REVERSE(DEAL_DEAL_NUMBER),7,4)))  into numserial FROM trtran001;
--        
--        update TRSYSTEM007 set serl_serial_number=numserial  WHERE SERL_SERIAL_CODE = 10900014
--        AND serl_company_code = companycode;
   <<Process_end>>     
    varOperation := 'Archive Data';    
    INSERT INTO TRSTAGING015_ARC
    SELECT * FROM TRSTAGING015_1;
    varOperation := 'Staging ';    
    DELETE FROM TRSTAGING015_1;
    delete  from TRSTAGING015;
    
     Varoperation:='Data Processed';
     commit;
   Exception
          When others then

            numError := SQLCODE;
            varError := SQLERRM;
            varError := GConst.fncReturnError('FORWARDCONTRACT', numError, varMessage,
                            varOperation, varError);
            --raise_application_error(-20101, varError);
        update TRAUDIT001 set DATA_ROWS_PROCESSED =0,
            DATA_ROWS_NOTPROCESSED =0,
            DATA_UPLOAD_TIMESTAMP =TO_CHAR(SYSTIMESTAMP, 'DD-MON-YYYY HH24:MI:SS:FF3'),
            DATA_UPLOAD_STATUS =12400001,
            DATA_UPLOAD_REMARKS=varError
            where DATA_KEY_GUID=varGuid;
            commit;
            
end prcFORWARDContractLoad;



procedure prcEXPOSUREDataLoad
as
  datTemp             date;
  numError            number;
  varOperation        GConst.gvarOperation%Type;
  varMessage          GConst.gvarMessage%Type;
  varError            GConst.gvarError%Type;
  numSerial           number;
  companycode         number;
  numRowInserted      number;
  numRowsUpdated      number;
  numRowsNotProcessed number;
  numTotalRecords     number;
  varGUID                varchar(50);
  ErrorNum            number;
  ErrorMsg           varchar(4000);
  numProcessWhileErr  number(8);
  begin



 numSerial := 0;
 companycode :=0;
  varMessage:=' Forward Contract Data Upload Process Started';
   insert into rtemp (TT) values('prcEXPOSUREDataLoad Called'); commit;
 
  varOperation:=' Extracting GUID';
  select GUID
   into varGUID
  from trstaging016 where rownum=1;
  
  varOperation:=' Get the Total Rows';
  select Count(*)
   into numTotalRecords
  from trstaging016;
  
  
  varOperation:='Get the Flag to check whether to process the Rows While error';
  select nvl(LOAD_PROCESS_WHILE_ERR,12400001)
   into numProcessWhileErr
  from trsystem969
  where LOAD_DATA_NAME='EXPOSUREDATALOAD'
  and Load_record_status not in (10200005,10200006);
  
  varOperation := 'Staging ';    
  DELETE FROM TRSTAGING016_1;
  varoperation:=' Insert data from stage to stage 1 for further process';
  insert into trstaging016_1 (TRANSACTIONTYPE,BANK,REFERENCEDATE,
                      AMOUNTFCY,MATURITYDATE,CONTRACTNUMBER,
                      CURRENCY,USERREFERENCE,EXCHANGERATE,
                      COMPANY,LOCATION,PRODUCT,
                      SUBPRODUCT,GUID,RowNo)
          select TRANSACTIONTYPE,BANK,REFERENCEDATE,
                  AMOUNTFCY,MATURITYDATE,CONTRACTNUMBER,
                  CURRENCY,USERREFERENCE,EXCHANGERATE,
                  COMPANY,LOCATION,PRODUCT,
                  SUBPRODUCT,GUID,rownum
           FROM trstaging016;
  

   varOperation:=' Processing Generic Validation'; 
              
   PKGBULKDATALOAD.ValidateData('EXPOSUREDATALOAD');  
   
   -- Custome Validations 
   
   update trstaging016_1 set Remarks = remarks || '|' || ' Maturity Date Can not be Less than the Execute Date'
    where to_date(REFERENCEDATE)>to_date(MATURITYDATE);
   
  
    
   begin
     select nvl(count(*),0)
       into ErrorNum
      from trstaging016_1
      where remarks is not null;
   exception
    when others then 
      ErrorNum:=0;
   end;
    
   if ((ErrorNum!=0) and (numProcessWhileErr=12400001)) then
    varOperation:=' Update the audit table while error'; 
       update TRAUDIT001 set DATA_ROWS_PROCESSED =0,
        DATA_ROWS_NOTPROCESSED =numTotalRecords,
        DATA_UPLOAD_TIMESTAMP =SYSTIMESTAMP,
        DATA_UPLOAD_STATUS =12400002,
        DATA_UPLOAD_REMARKS='There are issues while Processing'
        where DATA_KEY_GUID=varGuid;
     Goto Process_end;
   end if;
     
    varOperation := 'Uploading Forward sysnumber';
    update trstaging016_1 set  sysreferencenumber= 'EXP' || Gconst.FNCGENERATESERIAL(Gconst.SERIALPURCHASE,null);
    varOperation := 'Insert into Base Table';
    

    insert into trtran002 (TRAD_LOCAL_BANK,TRAD_REFERENCE_DATE,TRAD_BUYER_SELLER,
      TRAD_TRADE_FCY,TRAD_TRADE_INR,TRAD_MATURITY_FROM,
      TRAD_MATURITY_DATE,TRAD_CONTRACT_NO, TRAD_LOCAL_CURRENCY,
      TRAD_COMPANY_CODE,TRAD_LOCATION_CODE,TRAD_USER_REFERENCE,
      TRAD_SPOT_RATE,TRAD_FORWARD_RATE,TRAD_MARGIN_RATE,
      TRAD_PRODUCT_CODE,trad_product_category,TRAD_SUBPRODUCT_CODE,
      TRAD_TRANSACTION_TYPE,TRAD_CREATE_DATE, TRAD_RECORD_STATUS,
      TRAD_IMPORT_EXPORT,trad_trade_reference,trad_trade_currency,
      trad_trade_rate,trad_entry_date,trad_process_complete,
      TRAD_TRADE_PERIOD,TRAD_TENOR_PERIOD)      

--trad_product_category
--      TRAD_TENOR_CODE,trad_period_code,TRAD_PRODUCT_QUANTITY,
--      TRAD_PRODUCT_RATE,

    SELECT BANK_CODE,REFERENCEDATE,BUYER_SELLER_CODE,
         AMOUNTFCY,AMOUNTFCY* EXCHANGERATE,MATURITYDATE,
         MATURITYDATE,CONTRACTNUMBER,LOCN_LOCAL_CURRENCY,
         COMPANY_CODE,LOCATION_CODE,USERREFERENCE,
         EXCHANGERATE,0,0,
         24399999,PRODUCT_CODE,SUBPRODUCT_CODE,
         31399999,sysdate,10200001,
         TRANSACTIONTYPE,sysreferencenumber,CURRENCY_CODE,
         EXCHANGERATE,REFERENCEDATE,12400002,
         0,0
        from trstaging016_1 left outer join 
           trmaster302 on LOCN_PICK_CODE= LOCATION_CODE
        where Remarks is null;
         
--         COMPANYCODE_CODE,EXECUTEDATE,BUYSELL_CODE,
--         BASECURRENCY_CODE,OTHERCURRENCY_CODE,BANK_CODE,
--         MATURITYDATE,MATURITYDATE,AMOUNTFCY,
--         AMOUNTFCY* FORWARDRATE,FORWARDRATE,FORWARDRATE,
--         0,0,sysreferencenumber,
--         1,26000001,25200002,
--         25400006,AMOUNTFCY* FORWARDRATE,25500005,
--         PRODUCT_CODE,,'sysAdmin',
--         12400002,sysdate,10200001,
--         TO_CHAR(SYSTIMESTAMP, 'DD-MON-YYYY HH24:MI:SS:FF3'),'Uploaded'

   
--     select c.lbnk_pick_code,to_date(refERENCEdate,'dd-MON-yy'),30500001,AMOUNTFCY,(AMOUNTFCY*(EXCHANGERATE)),
--      refERENCEdate,maturitydate,CONTRACTNUMBER,null,d.comp_company_code,e.locn_pick_code,
--      userrefERENCE,0,0,0,33300001,33300001,33800001,25500001,23400001,NULL,NULL,b.pick_key_value,NULL,to_date(sysdate,'dd-MON-yy'),  
--      10200001,b.pick_key_value,  CASE WHEN (TO_CHAR(to_date(refERENCEdate,'dd/mm/yy'),'MM') < 4) THEN
--         B.pick_short_description || '/' || D.comp_short_description || '/' || lpad(rownum + numSerial,4,0)||'/'||to_number(to_char(to_date(refERENCEdate,'dd/mm/yy'),'YY')-1) ||'-'||to_char(to_date(refERENCEdate,'dd/mm/yy'),'YY')
--      ELSE
--            B.pick_short_description || '/' || D.comp_short_description || '/' || lpad(rownum + numSerial,4,0)||'/'||to_char(to_date(refERENCEdate,'dd/mm/yy'),'YY') ||'-'|| to_number(to_char(to_date(refERENCEdate,'dd/mm/yy'),'YY')+1)
--      END ,a.cncy_pick_code,EXCHANGERATE,to_date(sysdate,'dd-MON-yy'),NULL,12400002,0,(maturitydate-refERENCEdate)   from trstaging016
--      LEFT OUTER JOIN TRMASTER304 A
--      ON A.CNCY_SHORT_DESCRIPTION = currencycode
--      LEFT OUTER JOIN TRMASTER001 B
--      ON b.pick_short_description = TRANSACTIONTYPE
--      LEFT OUTER JOIN TRMASTER306 C
--      on  c.lbnk_short_description = bankcode and C.LBNK_COMPANY_CODE=COMPANYCODE
--      left outer join TRMASTER301 D
--      ON d.comp_company_code=COMPANYCODE
--      LEFT OUTER JOIN TRMASTER302 E
--      ON e.locn_pick_code=LOCATIONCODE;


     varOperation := 'Extracting Rows Processed';
       SELECT  sum(case when  Remarks is null then 1 else 0 end),
                sum(case when  Remarks is not null then 1 else 0 end)
          into numRowInserted,numRowsNotProcessed
      from trstaging016_1;
      
    --numRowInserted:=SQL%Rowcount;
      varOperation := 'Update Audit Table with Status';
      update TRAUDIT001 set DATA_ROWS_PROCESSED =numRowInserted,
            DATA_ROWS_NOTPROCESSED =numRowsNotProcessed,
            DATA_UPLOAD_TIMESTAMP =SYSTIMESTAMP,
            DATA_UPLOAD_STATUS =12400001,
            DATA_UPLOAD_REMARKS='Sucessfully Processed'
            where DATA_KEY_GUID=varGuid;
    

    
    
    
    --update traudit001 set data_rows_processed=;
--      LEFT OUTER JOIN TRMASTER304 A
--      ON A.CNCY_SHORT_DESCRIPTION = BASECURRENCY
--      LEFT OUTER JOIN TRMASTER304 B
--      ON b.cncy_short_description = OTHERCURRENCY
--      LEFT OUTER JOIN TRMASTER306 C
--      on  c.lbnk_short_description = BANK and C.LBNK_COMPANY_CODE=COMPANYCODE
--      left outer join trmaster001 D
--      on d.pick_short_description=BUYSELL
--      left outer join TRMASTER301 E
--      ON e.comp_company_code=COMPANYCODE;  
--            
--       
--          
--         SELECT max(REVERSE(SUBSTR(REVERSE(DEAL_DEAL_NUMBER),7,4)))  into numserial FROM trtran001;
--        
--        update TRSYSTEM007 set serl_serial_number=numserial  WHERE SERL_SERIAL_CODE = 10900014
--        AND serl_company_code = companycode;
   <<Process_end>>  
       varOperation := 'Archive Data';    
    INSERT INTO TRSTAGING016_ARC
    SELECT * FROM TRSTAGING016_1;
    varOperation := 'Staging ';    
--    DELETE FROM TRSTAGING016_1;
--    delete  from TRSTAGING016;
     Varoperation:='Data Processed';
     commit;
   Exception
          When others then

            numError := SQLCODE;
            varError := SQLERRM;
            varError := GConst.fncReturnError('FORWARDCONTRACT', numError, varMessage,
                            varOperation, varError);
            --raise_application_error(-20101, varError);
        update TRAUDIT001 set DATA_ROWS_PROCESSED =0,
            DATA_ROWS_NOTPROCESSED =0,
            DATA_UPLOAD_TIMESTAMP =TO_CHAR(SYSTIMESTAMP, 'DD-MON-YYYY HH24:MI:SS:FF3'),
            DATA_UPLOAD_STATUS =12400001,
            DATA_UPLOAD_REMARKS=varError
            where DATA_KEY_GUID=varGuid;
            commit;
            
--            
--  numSerial := 0;
--  companycode  :=0;
--  SELECT DISTINCT COMPANYCODE INTO companycode  FROM TRSTAGING016;
--   SELECT serl_serial_number INTO numSerial FROM TRSYSTEM007 WHERE SERL_SERIAL_CODE = 10900015
--   AND serl_company_code = companycode;
--     INSERT INTO TEMP VALUES(companycode,numserial);commit;
--   datTemp:= to_date(sysdate,'DD-MM-YY');
--    varOperation := 'Uploading EXPOSURECDATALOAD upload';
--      insert into trtran002 (TRAD_LOCAL_BANK,TRAD_REFERENCE_DATE,TRAD_BUYER_SELLER,TRAD_TRADE_FCY,TRAD_TRADE_INR,TRAD_MATURITY_FROM,
--     TRAD_MATURITY_DATE,TRAD_CONTRACT_NO,TRAD_LOCAL_CURRENCY,TRAD_COMPANY_CODE,TRAD_LOCATION_CODE,TRAD_USER_REFERENCE,TRAD_SPOT_RATE,
--     TRAD_FORWARD_RATE,TRAD_MARGIN_RATE,TRAD_PRODUCT_CODE,trad_product_category,TRAD_SUBPRODUCT_CODE,TRAD_TENOR_CODE,trad_period_code,TRAD_PRODUCT_QUANTITY,TRAD_PRODUCT_RATE,
--     TRAD_TRANSACTION_TYPE,TRAD_TERM,TRAD_CREATE_DATE,TRAD_RECORD_STATUS,TRAD_IMPORT_EXPORT,trad_trade_reference,
--     trad_trade_currency,trad_trade_rate,trad_entry_date,TRAD_ENTRY_DETAIL,trad_process_complete,TRAD_TRADE_PERIOD,TRAD_TENOR_PERIOD)      
--     select c.lbnk_pick_code,to_date(refERENCEdate,'dd-MON-yy'),30500001,AMOUNTFCY,(AMOUNTFCY*(EXCHANGERATE)),
--      refERENCEdate,maturitydate,CONTRACTNUMBER,null,d.comp_company_code,e.locn_pick_code,
--      userrefERENCE,0,0,0,33300001,33300001,33800001,25500001,23400001,NULL,NULL,b.pick_key_value,NULL,to_date(sysdate,'dd-MON-yy'),  
--      10200001,b.pick_key_value,  CASE WHEN (TO_CHAR(to_date(refERENCEdate,'dd/mm/yy'),'MM') < 4) THEN
--         B.pick_short_description || '/' || D.comp_short_description || '/' || lpad(rownum + numSerial,4,0)||'/'||to_number(to_char(to_date(refERENCEdate,'dd/mm/yy'),'YY')-1) ||'-'||to_char(to_date(refERENCEdate,'dd/mm/yy'),'YY')
--      ELSE
--            B.pick_short_description || '/' || D.comp_short_description || '/' || lpad(rownum + numSerial,4,0)||'/'||to_char(to_date(refERENCEdate,'dd/mm/yy'),'YY') ||'-'|| to_number(to_char(to_date(refERENCEdate,'dd/mm/yy'),'YY')+1)
--      END ,a.cncy_pick_code,EXCHANGERATE,to_date(sysdate,'dd-MON-yy'),NULL,12400002,0,(maturitydate-refERENCEdate)   from trstaging016
--      LEFT OUTER JOIN TRMASTER304 A
--      ON A.CNCY_SHORT_DESCRIPTION = currencycode
--      LEFT OUTER JOIN TRMASTER001 B
--      ON b.pick_short_description = TRANSACTIONTYPE
--      LEFT OUTER JOIN TRMASTER306 C
--      on  c.lbnk_short_description = bankcode and C.LBNK_COMPANY_CODE=COMPANYCODE
--      left outer join TRMASTER301 D
--      ON d.comp_company_code=COMPANYCODE
--      LEFT OUTER JOIN TRMASTER302 E
--      ON e.locn_pick_code=LOCATIONCODE;
--      
--      -- SELECT MAX(TO_NUMBER(SUBSTR(trad_trade_reference,18,2)))  INTO numserial FROM trtran002;
--        
--       SELECT max(REVERSE(SUBSTR(REVERSE(trad_trade_reference), 7,4))) into numserial  FROM trtran002;  
--        update TRSYSTEM007 set serl_serial_number=numserial  WHERE SERL_SERIAL_CODE = 10900015
--        AND serl_company_code = companycode;
--      Exception
--      
--          When others then   
--            numError := SQLCODE;
--            varError := SQLERRM;
--            varError := GConst.fncReturnError('EXPOSURECDATALOAD', numError, varMessage,
--                            varOperation, varError);
--            raise_application_error(-20101, varError);
End Prcexposuredataload;

procedure prcFUTURESDataLoad
as
  datTemp             date;
  numError            number;
  varOperation        GConst.gvarOperation%Type;
  varMessage          GConst.gvarMessage%Type;
  varError            GConst.gvarError%Type;
  numSerial            number;
  COMPANYCODE          NUMBER;
   varEntity        VARCHAR2(30 BYTE);
begin
  NUMSERIAL := 0;
  COMPANYCODE  :=0;

     INSERT INTO TEMP VALUES(30100001,varEntity);commit;
   datTemp:= to_date(sysdate,'DD-MM-YY');  
    VAROPERATION :=' Insert data into Intermidiate table';
    delete from TRINTERMEDIATE011;
      insert into TRINTERMEDIATE011(EXCHANGE,  PARTY_CODE,  PARTY_NAME,
      SYMBOL,  EXPIRY,  OPTION_TYPE,  STRIKE_PRICE,  BUY_QTY,  BUY_RATE,
      BUY_AMT,  SELL_QTY,  SELL_RATE,  SELL_AMT,  NET_QTY,  RECORDSTATUS)
      select EXCHANGE,  PARTY_CODE,  PARTY_NAME,
      SYMBOL,  EXPIRY,  OPTION_TYPE,  STRIKE_PRICE,  BUY_QTY,  BUY_RATE,
      BUY_AMT,  SELL_QTY,  SELL_RATE,  SELL_AMT,  NET_QTY,  RECORDSTATUS
       from TRSTAGING011;
    
       VAROPERATION :=' Update Exchange Code';
    
       UPDATE TRINTERMEDIATE011 SET EXCHAGE_CODE= FNCGETPICKCODE_New(EXCHANGE,2,701);
       VAROPERATION :=' Update Base Currency Code';
        UPDATE TRINTERMEDIATE011 SET BASECURRENCY_CODE= FNCGETPICKCODE_New(substr(Symbol,1,3),2,304);
          
       VAROPERATION :=' Update Other Currency Code';
        UPDATE TRINTERMEDIATE011 SET OTHERCURRENCY_CODE= FNCGETPICKCODE_New(SUBSTR(SYMBOL,4,6),2,304);
          
--         VAROPERATION :=' Update For Currency Code';
--        UPDATE TRINTERMEDIATE011 SET BASECURRENCY_CODE= FNCGETPICKCODE_New(Symbol,2,304);
     
--      
      Insert Into Trtran103 (Intc_Exchange_Type,Intc_Party_Code,Intc_Party_Name,INTC_BASE_CURRENCY,INTC_OTHER_CURRENCY,
      INTC_EXPIRY_DATE,INTC_OPTION_TYPE,INTC_STRIKE_PRICE,INTC_BUY_QTY,INTC_BUY_RATE,INTC_BUY_AMOUNT,
      INTC_SELL_QTY,INTC_SELL_RATE,INTC_SELL_AMOUNT,INTC_REFSTA_NUMBER,INTC_CREATE_DATE,INTC_RECORD_STATUS,INTC_PRODUCT_CODE,
      INTC_BROKER_NAME)      
      SELECT C.PICK_KEY_VALUE,PARTY_CODE,30100001,A.PICK_KEY_VALUE,D.PICK_KEY_VALUE, to_date(EXPIRY,'dd/MM/yy'),
      OPTION_TYPE,STRIKE_PRICE,BUY_QTY,BUY_RATE,BUY_AMT,SELL_QTY,SELL_RATE,SELL_AMT,
      GCONST.FNCGENERATESERIAL(GCONST.SERIALSTAFUTURE),TO_DATE(ENTRYDATE,'dd-MON-yy'),10200001,E.PICK_KEY_VALUE,BROKERNAME
      From Trstaging011
      Left Outer Join Trmaster001 A
      On A.Pick_Key_Group=304
      AND A.PICK_SHORT_DESCRIPTION = SUBSTR(SYMBOL,1,3)
      and A.pick_record_status not in (10200005,10200006)
      LEFT OUTER JOIN TRMASTER001 D
      ON D.PICK_SHORT_DESCRIPTION=SUBSTR(SYMBOL,4,6)   
      and D.pick_key_group=304
      and D.pick_record_status not in (10200005,10200006)
      Left Outer Join Trmaster001 C
      On  C.Pick_Key_Group=701 
      AND C.PICK_SHORT_DESCRIPTION=EXCHANGE
      and C.pick_record_status not in (10200005,10200006)
      LEFT OUTER JOIN TRMASTER001 E
      ON E.PICK_SHORT_DESCRIPTION=SYMBOL
      and E.pick_key_group=503
      and E.pick_record_status not in (10200005,10200006);
      -- SELECT MAX(TO_NUMBER(SUBSTR(trad_trade_reference,18,2)))  INTO numserial FROM trtran002;
--        
--        Select Max(Reverse(Substr(Reverse(Intc_Refsta_Number), 7,4))) into numserial   From Trtran103;  
--        Update Trsystem007 Set Serl_Serial_Number=numserial  Where Serl_Serial_Code = 10900060
--        AND serl_company_code = 30100001;
      Exception
      
          When others then   
            numError := SQLCODE;
            varError := SQLERRM;
            varError := GConst.fncReturnError('FUTURESDataLoad', numError, varMessage,
                            varOperation, varError);
            RAISE_APPLICATION_ERROR(-20101, VARERROR);
END  prcFUTURESDataLoad;


procedure prcEDELFUTURESDataLoad
as
  datTemp             date;
  numError            number;
  varOperation        GConst.gvarOperation%Type;
  varMessage          GConst.gvarMessage%Type;
  varError            GConst.gvarError%Type;
  numSerial            number;
  COMPANYCODE          NUMBER;
  varEntity            VARCHAR2(30 BYTE);
begin
  numSerial := 0;
  companycode  :=0;
  
--   Select Serl_Serial_Number  INTO numSerial From Trsystem007 Where Serl_Serial_Code = 10900060
--   And Serl_Company_Code = 30100001;
     INSERT INTO TEMP VALUES(30100001,varEntity);commit;
   datTemp:= to_date(sysdate,'DD-MM-YY');  
    VAROPERATION :=' Insert data into Intermidiate table';
      insert into TRINTERMEDIATE011(EXCHANGE,  PARTY_CODE,  PARTY_NAME,
      SYMBOL,  EXPIRY,  OPTION_TYPE,  STRIKE_PRICE,  BUY_QTY,  BUY_RATE,
      BUY_AMT,  SELL_QTY,  SELL_RATE,  SELL_AMT,  NET_QTY,  RECORDSTATUS)
      select EXCHANGE,  PARTY_CODE,  PARTY_NAME,
      SYMBOL,  EXPIRY,  OPTION_TYPE,  STRIKE_PRICE,  BUY_QTY,  BUY_RATE,
      BUY_AMT,  SELL_QTY,  SELL_RATE,  SELL_AMT,  NET_QTY,  RECORDSTATUS
       from TRSTAGING011;
    
       VAROPERATION :=' Update Exchange Code';
    
       UPDATE TRINTERMEDIATE011 SET EXCHAGE_CODE= FNCGETPICKCODE_New(EXCHANGE,2,701);
       VAROPERATION :=' Update Base Currency Code';
        UPDATE TRINTERMEDIATE011 SET BASECURRENCY_CODE= FNCGETPICKCODE_New(substr(Symbol,1,3),2,304);
          
       VAROPERATION :=' Update Other Currency Code';
        UPDATE TRINTERMEDIATE011 SET OTHERCURRENCY_CODE= FNCGETPICKCODE_New(SUBSTR(SYMBOL,4,6),2,304);
          
--         VAROPERATION :=' Update For Currency Code';
--        UPDATE TRINTERMEDIATE011 SET BASECURRENCY_CODE= FNCGETPICKCODE_New(Symbol,2,304);
--      
      Insert Into Trtran103 (Intc_Exchange_Type,Intc_Party_Code,Intc_Party_Name,INTC_BASE_CURRENCY,INTC_OTHER_CURRENCY,
      INTC_EXPIRY_DATE,INTC_OPTION_TYPE,INTC_STRIKE_PRICE,INTC_BUY_QTY,INTC_BUY_RATE,INTC_BUY_AMOUNT,
      INTC_SELL_QTY,INTC_SELL_RATE,INTC_SELL_AMOUNT,INTC_REFSTA_NUMBER,INTC_CREATE_DATE,INTC_RECORD_STATUS,INTC_PRODUCT_CODE,
      INTC_BROKER_NAME)      
      SELECT C.PICK_KEY_VALUE,PARTY_CODE,30100001,A.PICK_KEY_VALUE,D.PICK_KEY_VALUE,TO_DATE(EXPIRY,'dd-MON-yy'),
      OPTION_TYPE,STRIKE_PRICE,BUY_QTY,BUY_RATE,BUY_AMT,SELL_QTY,SELL_RATE,SELL_AMT,
      GCONST.FNCGENERATESERIAL(GCONST.SERIALSTAFUTURE),TO_DATE(SYSDATE,'dd-MON-yy'),10200001,E.PICK_KEY_VALUE,     
      70200015       
      From Trstaging011
           Left Outer Join Trmaster001 A
      On A.Pick_Key_Group=304
      AND A.PICK_SHORT_DESCRIPTION = SUBSTR(SYMBOL,1,3)
      and A.pick_record_status not in (10200005,10200006)
      LEFT OUTER JOIN TRMASTER001 D
      ON D.PICK_SHORT_DESCRIPTION=SUBSTR(SYMBOL,4,6)   
      and D.pick_key_group=304
      and D.pick_record_status not in (10200005,10200006)
      Left Outer Join Trmaster001 C
      On  C.Pick_Key_Group=701 
      AND C.PICK_SHORT_DESCRIPTION=EXCHANGE
      and C.pick_record_status not in (10200005,10200006)
      LEFT OUTER JOIN TRMASTER001 E
      ON E.PICK_SHORT_DESCRIPTION=SYMBOL
      and E.pick_key_group=503
      and E.pick_record_status not in (10200005,10200006);
      -- SELECT MAX(TO_NUMBER(SUBSTR(trad_trade_reference,18,2)))  INTO numserial FROM trtran002;
--        
--        Select Max(Reverse(Substr(Reverse(Intc_Refsta_Number), 7,4))) into numserial   From Trtran103;  
--        Update Trsystem007 Set Serl_Serial_Number=numserial  Where Serl_Serial_Code = 10900060
--        AND serl_company_code = 30100001;
      Exception
      
          When others then   
            numError := SQLCODE;
            VARERROR := SQLERRM;
            varError := GConst.fncReturnError('FUTURESDataLoadedelweiss', numError, varMessage,
                            varOperation, varError);
            RAISE_APPLICATION_ERROR(-20101, VARERROR);
END  prcEDELFUTURESDataLoad;

PROCEDURE PRCFUTURESDATAINSERT
as
  datTemp             date;
  numError            number;
  varOperation        GConst.gvarOperation%Type;
  varMessage          GConst.gvarMessage%Type;
  varError            GConst.gvarError%Type;
  VarDealNumber       varchar(25);
  numSerial            number;
  companycode          NUMBER;
begin
  numSerial := 0;
  companycode  :=0; 
 
   
    datTemp:= to_date(sysdate,'DD-MM-YY');
    VAROPERATION := 'Uploading FUTURESDataLoad upload';
    for cur in (select intc_reference_number
                 from  TRTRAN102
                 where intc_Deal_number is null
                 AND INTC_CLASSIFICATION_CODE=64000001
                 AND INTC_BUSINESS_UNIT!=0
                 AND INTC_SETTLEMENT_DATE IS NOT NULL)
    loop
         VarDealNumber := GCONST.FNCGENERATESERIAL(GCONST.SERIALFUTURETRADE,30100001);
    
--                  INSERT INTO TRTRAN061 (Cfut_Company_Code,Cfut_Deal_Number,Cfut_User_Reference,Cfut_Execute_Date,Cfut_Exchange_Code,
--              CFUT_COUNTER_PARTY,CFUT_BASE_CURRENCY,CFUT_OTHER_CURRENCY,CFUT_EXCHANGE_RATE,CFUT_LOCAL_RATE,CFUT_BASE_AMOUNT,
--              CFUT_OTHER_AMOUNT,CFUT_CONTRACT_TYPE,CFUT_HEDGE_TRADE,CFUT_BUY_SELL,CFUT_PRODUCT_CODE,
--              CFUT_LOCAL_BANK,CFUT_LOT_NUMBERS,CFUT_LOT_QUANTITY,CFUT_Excahgne_rate,cfut_maturity_from,CFUT_MATURITY_DATE,
--              CFUT_USER_ID,CFUT_DEALER_REMARK,CFUT_EXECUTE_TIME,CFUT_TIME_STAMP,CFUT_PROCESS_COMPLETE,CFUT_CREATE_DATE,
--              CFUT_ADD_DATE,CFUT_RECORD_STATUS,CFUT_BACKUP_DEAL,CFUT_INIT_CODE,CFUT_LOCATION_CODE,
--              CFUT_SPOT_RATE,CFUT_FORWARD_RATE,CFUT_BANK_MARGIN,CFUT_MATURITY_FROM,CFUT_DEALER_NAME,CFUT_COUNTER_DEALER,
--              CFUT_MARGIN_RATE,CFUT_MARGIN_AMOUNT,CFUT_BROKERAGE_RATE,CFUT_BROKERAGE_AMOUNT)
--             SELECT INTC_PARTY_NAME,'FUR'||VARDEALNUMBER,NULL,INTC_CREATE_DATE,INTC_EXCHANGE_TYPE --Gconst.SERIALFUTURETRADE
--             ,INTC_BROKER_NAME,INTC_BASE_CURRENCY,INTC_OTHER_CURRENCY,INTC_RATE,1,INTC_AMOUNT,INTC_AMOUNT*(INTC_RATE),
--            60700003,26000001,INTC_BUY_SELL,NVL(INTC_PRODUCT_CODE,0),30699999,INTC_QUANTITY,
--            INTC_QUANTITY*1000,INTC_RATE,0,INTC_SETTLEMENT_DATE,INTC_SETTLEMENT_DATE,INTC_USER_ID,NULL,
--            TO_DATE(SYSDATE,'dd-MON-yy'),TO_CHAR(SYSDATE,'HH24:MI'),12400002,INTC_CREATE_DATE,TO_DATE(SYSDATE,'dd-MON-yy'),
--            10200001,INTC_BUSINESS_UNIT,INTC_PROFIT_CENTER,30200001,INTC_SPOT_RATE,INTC_FORWARD_RATE,INTC_MARGIN_RATE,
--            INTC_EXPIRY_DATE,INTC_DEALER_NAME,INTC_COUNTER_DEALER,0,0,0,0
--            FROM  TRTRAN102 WHERE INTC_REFERENCE_NUMBER= CUR.INTC_REFERENCE_NUMBER;
            
          update trtran102 set intc_deal_number='FUR'||VarDealNumber
          where intc_reference_number= cur.intc_reference_number
           and intc_classification_code=64000001;
           -- AND INTC_REFERENCE_NUMBER NOT IN (SELECT CFUT_BANK_REFERENCE FROM TRTRAN061 WHERE CFUT_RECORD_STATUS NOT IN (10200005,10200006));   
    end loop;
    
      Exception
      
          When others then   
            numError := SQLCODE;
            varError := SQLERRM;
            varError := GConst.fncReturnError('FUTURESDataLoad', numError, varMessage,
                            VAROPERATION, VARERROR);
            Raise_Application_Error(-20101, Varerror);

END  PRCFUTURESDATAINSERT;

--PROCEDURE prcFXGOFXALLDATA
--as
--  datTemp             date;
--  numError            number;
--  varOperation        GConst.gvarOperation%Type;
--  varMessage          GConst.gvarMessage%Type;
--  varError            GConst.gvarError%Type;
--  numSerial           number;
--  companycode         number;
--  VarDealNumber       varchar(25);
--begin
-- numSerial := 0;
-- companycode :=0;
--  commit;
--    datTemp:= to_date(sysdate,'DD-MM-YY');
--    varOperation := 'Uploading FXGOFXALLDATA upload';   
--    
--      for cur in (select trade_id
--                 from  TRTRAN103A
--                 where CLASSIFICATION_CODE=64000001
--                 AND BUSINESS_UNIT!=0
--                 and BUSINESS_UNIT is not null
--                 and referencenumber is null)
--    loop
--         VarDealNumber :=GCONST.FNCGENERATESERIAL(GCONST.SERIALDEAL,30100001);
--         
--    INSERT INTO TRTRAN001 (DEAL_COMPANY_CODE,DEAL_LOCATION_CODE,DEAL_EXECUTE_DATE,DEAL_EXECUTE_TIME,DEAL_BUY_SELL,
--    DEAL_BASE_CURRENCY,DEAL_OTHER_CURRENCY,
--    DEAL_COUNTER_PARTY,DEAL_MATURITY_FROM,DEAL_MATURITY_DATE,DEAL_BASE_AMOUNT,DEAL_OTHER_AMOUNT,DEAL_EXCHANGE_RATE,DEAL_SPOT_RATE,
--    DEAL_MARGIN_RATE,DEAL_DEAL_NUMBER,DEAL_SERIAL_NUMBER,DEAL_HEDGE_TRADE,DEAL_SWAP_OUTRIGHT,DEAL_DEAL_TYPE,
--    DEAL_AMOUNT_LOCAL,DEAL_MATURITY_CODE,DEAL_BACKUP_DEAL,DEAL_INIT_CODE,DEAL_USER_ID,deal_process_complete,deal_create_date,
--    deal_record_status,deal_entry_detail,DEAL_LOCAL_RATE,DEAL_FORWARD_RATE,DEAL_DEALER_REMARKS,DEAL_DEALER_NAME,
--    DEAL_COUNTER_DEALER,deal_confirm_date,DEAL_USER_REFERENCE,DEAL_BANK_REFERENCE) 
--    SELECT  30100001,30200001,TRADE_DATE,TIME_OF_DEAL,SIDE_BUY_SELL,CURRENCY_1,CURRENCY_2,COUNTERPARTY_ID,
--    trade_date,value_date_period_1,amount_dealt,amount_dealt*exchange_rate_period_1,exchange_rate_period_1,
--    spot_basis_rate,margin,'FWD'|| VarDealNumber,1,    
--    26000001,25200002,25400006,0,0,BUSINESS_UNIT,PROFIT_CENTER,'admin',12400002,    
--    ENTRYDATE,10200001,Null,0,forward_rate,NULL,TRADER_NAME, COUNTERPARTY_TRADER_NAME ,DATE_CONFIRMED,TRADE_ID,TRADE_ID
--    FROM trtran103a where trade_id= CUR.trade_id;
--               
--          update trtran103A set REFERENCENUMBER='FWD'||VarDealNumber
--          where trade_id= cur.trade_id
--           and classification_code=64000001;
--           -- AND INTC_REFERENCE_NUMBER NOT IN (SELECT CFUT_BANK_REFERENCE FROM TRTRAN061 WHERE CFUT_RECORD_STATUS NOT IN (10200005,10200006));   
--    end loop;
--    
--   Exception
--          When others then
--            numError := SQLCODE;
--            varError := SQLERRM;
--            varError := GConst.fncReturnError('FXGOFXALLDATA', numError, varMessage,
--                            varOperation, varError);
--            raise_application_error(-20101, varError);
--END prcFXGOFXALLDATA;

PROCEDURE prcFXGOFXALLDATA
as
  datTemp             date;
  numError            number;
  varOperation        GConst.gvarOperation%Type;
  varMessage          GConst.gvarMessage%Type;
  varError            GConst.gvarError%Type;
  numSerial           number;
  companycode         number;
  VarDealNumber       varchar(25);
begin
 numSerial := 0;
 companycode :=0;
  commit;
    datTemp:= to_date(sysdate,'DD-MM-YY');
    varOperation := 'Uploading FXGOFXALLDATA upload';   
    
      for cur in (select DEAL_NUMBER
                 from  trtran103a_FXGO
                 where CLASSIFICATION=64000001
                 AND BUSINESS_UNIT!=0
                 and BUSINESS_UNIT is not null
                 and referencenumber is null)
    loop
         VarDealNumber :=GCONST.FNCGENERATESERIAL(GCONST.SERIALDEAL,30100001);
         
    INSERT INTO TRTRAN001 (DEAL_COMPANY_CODE,DEAL_LOCATION_CODE,DEAL_EXECUTE_DATE,DEAL_EXECUTE_TIME,DEAL_BUY_SELL,
    DEAL_BASE_CURRENCY,DEAL_OTHER_CURRENCY,
    DEAL_COUNTER_PARTY,DEAL_MATURITY_FROM,DEAL_MATURITY_DATE,DEAL_BASE_AMOUNT,DEAL_OTHER_AMOUNT,DEAL_EXCHANGE_RATE,DEAL_SPOT_RATE,
    DEAL_MARGIN_RATE,DEAL_DEAL_NUMBER,DEAL_SERIAL_NUMBER,DEAL_HEDGE_TRADE,DEAL_SWAP_OUTRIGHT,DEAL_DEAL_TYPE,
    DEAL_AMOUNT_LOCAL,DEAL_MATURITY_CODE,DEAL_BACKUP_DEAL,DEAL_INIT_CODE,DEAL_USER_ID,deal_process_complete,deal_create_date,
    deal_record_status,deal_entry_detail,DEAL_LOCAL_RATE,DEAL_FORWARD_RATE,DEAL_DEALER_REMARKS,DEAL_DEALER_NAME,
    DEAL_COUNTER_DEALER,deal_confirm_date,DEAL_CONFIRM_TIME,DEAL_USER_REFERENCE,DEAL_BANK_REFERENCE) 
      SELECT  30100001,30200001,TRADE_DATE,to_char(systimestamp, 'HH24:MI'),BUY_SELL,BASE_CURRENCY,OTHER_CURRENCY,COUNTER_PARTY,
    trade_date,settlement_date,BASEAMOUNT,OTHERAMOUNT,EXCHANGERATE,SPOTRATE,MARGIN_RATE,'FWD'||VarDealNumber,1,26000001,25200002,
    25400006,0,0,BUSINESS_UNIT,PROFIT_CENTER,USERID,12400002,trade_date,10200001,Null,0,forward_rate,NULL,TRADER_NAME,
    COUNTERPARTY_TRADER_NAME ,DATE_CONFIRMED,to_char(systimestamp, 'HH24:MI'),DEAL_NUMBER,DEAL_NUMBER
    FROM trtran103a_FXGO  where DEAL_NUMBER= CUR.DEAL_NUMBER;
               
          update trtran103a_FXGO set REFERENCENUMBER='FWD'||VarDealNumber
          where DEAL_NUMBER= CUR.DEAL_NUMBER
           and classification=64000001;
           -- AND INTC_REFERENCE_NUMBER NOT IN (SELECT CFUT_BANK_REFERENCE FROM TRTRAN061 WHERE CFUT_RECORD_STATUS NOT IN (10200005,10200006));   
    end loop;
    
   Exception
          When others then
            numError := SQLCODE;
            varError := SQLERRM;
            varError := GConst.fncReturnError('FXGOFXALLDATA', numError, varMessage,
                            varOperation, varError);
            raise_application_error(-20101, varError);
END prcFXGOFXALLDATA;
PROCEDURE prcOPTIONVALUATIONDATALOAD
as
  datTemp             date;
  numError            number;
  varOperation        GConst.gvarOperation%Type;
  varMessage          GConst.gvarMessage%Type;
  varError            GConst.gvarError%Type;
  VarDealNumber       varchar(25);
  numSerial            number;
  companycode          NUMBER;
begin
  numSerial := 0;
  companycode  :=0; 
 
   
   datTemp:= to_date(sysdate,'DD-MM-YY');
    VAROPERATION := 'Uploading prcOPTIONVALUATIONDATALOAD upload';      
        select count(*) into numserial from  TRTRAN074A WHERE OPTV_ENTRY_DATE=(SELECT DISTINCT ENTRYDATE FROM TRSTAGING011A);
       
         if numSerial!=0 then
            delete from TRTRAN074A   WHERE OPTV_ENTRY_DATE=(SELECT DISTINCT ENTRYDATE FROM TRSTAGING011A);
         end if;
         
--        INSERT INTO TRTRAN074A (OPTV_SECURITY,OPTV_EXTERNAL_ID,OPTV_PC,OPTV_DELTA_USD,OPTV_POS_DELTA2,OPTV_POS_DELTA1,
--        OPTV_COUNTER_PARTY,OPTV_TRADE_DATE,OPTV_CCY1_AMT,OPTV_STRIKE,OPTV_EXPIRY_DATE,OPTV_DELIVERY_DATE,OPTV_PREM_CCY1,
--        OPTV_PREM_CCY2,OPTV_PL_CCY2,OPTV_PL_CCY1,OPTV_VALUE_CCY1,OPTV_VALUE_CCY2,OPTV_ENTRY_DATE,OPTV_CREATE_DATE,
--        OPTV_RECORD_STATUS)
--        SELECT SECURITY,EXTERNAL_ID,PC,REPLACE(DELTA_USD,',',''),REPLACE(POS_DELTA2,',',''),REPLACE(POS_DELTA1,',',''),30699999,
--        TO_DATE(TRADE_DATE,'mm-dd-yy'),REPLACE(CCY1_AMT,',',''),STRIKE,
--        TO_DATE(EXPIRY_DATE,'mm-dd-yy'),TO_DATE(DELIVERY_DATE,'mm-dd-yy'),REPLACE(PREM_CCY1,',',''),
--        REPLACE(PREM_CCY2,',',''),REPLACE(PL_CCY2,',',''),REPLACE(PL_CCY1,',',''),
--        REPLACE(VALUE_CCY1,',',''),REPLACE(VALUE_CCY2,',',''),TO_DATE(ENTRYDATE,'dd-MON-yy'),
--        TO_DATE(SYSDATE,'dd-MON-yy'),10200001
--        FROM  TRSTAGING011A;   

        INSERT INTO TRTRAN074A (OPTV_SECURITY,OPTV_EXTERNAL_ID,OPTV_PC,OPTV_DELTA_USD,OPTV_POS_DELTA2,OPTV_POS_DELTA1,
        OPTV_COUNTER_PARTY,OPTV_TRADE_DATE,OPTV_CCY1_AMT,OPTV_STRIKE,OPTV_EXPIRY_DATE,OPTV_DELIVERY_DATE,OPTV_PREM_CCY1,
        OPTV_PREM_CCY2,OPTV_PL_CCY2,OPTV_PL_CCY1,OPTV_VALUE_CCY1,OPTV_VALUE_CCY2,OPTV_ENTRY_DATE,OPTV_CREATE_DATE,
        OPTV_RECORD_STATUS)
        SELECT SECURITY,EXTERNAL_ID,PC,REPLACE(DELTA_USD,',',''),REPLACE(POS_DELTA2,',',''),REPLACE(POS_DELTA1,',',''),30699999,
        TO_DATE(SUBSTR(TRADE_DATE,5,12),'DD-MM-YY'),REPLACE(CCY1_AMT,',',''),STRIKE,
        TO_DATE(SUBSTR(EXPIRY_DATE,5,12),'DD-MM-YY'),TO_DATE(SUBSTR(DELIVERY_DATE,5,12),'DD-MM-YY'),REPLACE(PREM_CCY1,',',''),
        REPLACE(PREM_CCY2,',',''),REPLACE(PL_CCY2,',',''),REPLACE(PL_CCY1,',',''),
        REPLACE(VALUE_CCY1,',',''),REPLACE(VALUE_CCY2,',',''),TO_DATE(ENTRYDATE,'dd-MON-yy'),
        TO_DATE(SYSDATE,'dd-MON-yy'),10200001
        FROM  TRSTAGING011A;  
   
      Exception
      
          When others then   
            numError := SQLCODE;
            varError := SQLERRM;
            varError := GConst.fncReturnError('prcOPTIONVALUATIONDATALOAD', numError, varMessage,
                            VAROPERATION, VARERROR);
            Raise_Application_Error(-20101, Varerror);

END  prcOPTIONVALUATIONDATALOAD;

--Procedure prcFXALLDATA
--as
--  datTemp             date;
--  numError            number;
--  varOperation        GConst.gvarOperation%Type;
--  varMessage          GConst.gvarMessage%Type;
--  varError            GConst.gvarError%Type;
--  numSerial           number;
--  companycode         number;
--  VarDealNumber       varchar(25);
--begin
-- numSerial := 0;
-- companycode :=0;
--  commit;
--    datTemp:= to_date(sysdate,'DD-MM-YY');
--    varOperation := 'Uploading FXALLDATA upload';   
--    
--      for cur in (select REFERENCE_NO
--                 from  TRTRAN103B_FXALL_DETAIL
--                 where CLASSIFICATION_CODE=64000001
--                 AND BUSINESS_UNIT!=0
--                 and BUSINESS_UNIT is not null
--                 and referencenumber is null)
--    loop
--         VarDealNumber :=GCONST.FNCGENERATESERIAL(GCONST.SERIALDEAL,30100001);
--         
--    INSERT INTO TRTRAN001 (DEAL_COMPANY_CODE,DEAL_LOCATION_CODE,DEAL_EXECUTE_DATE,DEAL_EXECUTE_TIME,DEAL_BUY_SELL,
--    DEAL_BASE_CURRENCY,DEAL_OTHER_CURRENCY,
--    DEAL_COUNTER_PARTY,DEAL_MATURITY_FROM,DEAL_MATURITY_DATE,DEAL_BASE_AMOUNT,DEAL_OTHER_AMOUNT,DEAL_EXCHANGE_RATE,DEAL_SPOT_RATE,
--    DEAL_MARGIN_RATE,DEAL_DEAL_NUMBER,DEAL_SERIAL_NUMBER,DEAL_HEDGE_TRADE,DEAL_SWAP_OUTRIGHT,DEAL_DEAL_TYPE,
--    DEAL_AMOUNT_LOCAL,DEAL_MATURITY_CODE,DEAL_BACKUP_DEAL,DEAL_INIT_CODE,DEAL_USER_ID,deal_process_complete,deal_create_date,
--    deal_record_status,deal_entry_detail,DEAL_LOCAL_RATE,DEAL_FORWARD_RATE,DEAL_DEALER_REMARKS,DEAL_DEALER_NAME,
--    DEAL_COUNTER_DEALER,deal_confirm_date) 
--   select * from (SELECT  30100001,30200001,DEALDATE,DEALTIME,BUYSELLCODE b,nvl(BASECURRENCYCODE,b.PICK_KEY_VALUE) n,nvl(OTHERCURRENCYCODE,C.PICK_KEY_VALUE) h,COUNTERPARTYCODE,
--   TO_DATE(MATURITYFROMDATE),TO_DATE(MATURITYDATE),DEALAMOUNT,DEALAMOUNT*EXCHANGERATE,EXCHANGERATE ERATE,EXCHANGERATE,
--   MARGIN,'FWD'||VarDealNumber,1, 26000001,25200002,25400006,0 amto,0 mc,BUSINESS_UNIT,PROFIT_CENTER,
--   'admin',12400002,TO_DATE(DEALCREATEDDATE),10200001,Null,0 lr,forward_rate,d.REFERENCE_NO,DEALERID, COUNTERPARTY_DEAR_NAME ,
--    TO_DATE(DEALCONFIRMATIONDATE)
--    FROM TRTRAN103B_FXALL_DETAIL  d
--    LEFT OUTER JOIN TRMASTER001 b
--    ON b.PICK_SHORT_DESCRIPTION=BASECURRENCY
--    AND b.PICK_KEY_GROUP=304
--    AND b.PICK_RECORD_STATUS NOT IN (1020005,10200006)
--     LEFT OUTER JOIN TRMASTER001 c
--    ON c.PICK_SHORT_DESCRIPTION=OTHERCURRENCY
--    AND c.PICK_KEY_GROUP=304
--    AND c.PICK_RECORD_STATUS NOT IN (1020005,10200006))
--    where REFERENCE_NO= CUR.REFERENCE_NO;
--               
--          update TRTRAN103B_FXALL_DETAIL set REFERENCENUMBER='FWD'||VarDealNumber
--          where REFERENCE_NO= cur.REFERENCE_NO
--           and classification_code=64000001;
--           -- AND INTC_REFERENCE_NUMBER NOT IN (SELECT CFUT_BANK_REFERENCE FROM TRTRAN061 WHERE CFUT_RECORD_STATUS NOT IN (10200005,10200006));   
--    end loop;
--    
--   Exception
--          When others then
--            numError := SQLCODE;
--            varError := SQLERRM;
--            varError := GConst.fncReturnError('FXALLDATA', numError, varMessage,
--                            varOperation, varError);
--            raise_application_error(-20101, varError);
--END prcFXALLDATA;
Procedure prcFXALLDATA
as
  datTemp             date;
  numError            number;
  varOperation        GConst.gvarOperation%Type;
  varMessage          GConst.gvarMessage%Type;
  varError            GConst.gvarError%Type;
  numSerial           number;
  companycode         number;
  VarDealNumber       varchar(25);
begin
 numSerial := 0;
 companycode :=0;
  commit;
    datTemp:= to_date(sysdate,'DD-MM-YY');
    varOperation := 'Uploading FXALLDATA upload';   
    
    for cur in (select DEAL_NUMBER
                 from  trtran103a_FXGO
                 where CLASSIFICATION=64000001
                 AND BUSINESS_UNIT!=0
                 and BUSINESS_UNIT is not null
                 and referencenumber is null)
    loop
         VarDealNumber :=GCONST.FNCGENERATESERIAL(GCONST.SERIALDEAL,30100001);
         
    INSERT INTO TRTRAN001 (DEAL_COMPANY_CODE,DEAL_LOCATION_CODE,DEAL_EXECUTE_DATE,DEAL_EXECUTE_TIME,DEAL_BUY_SELL,
    DEAL_BASE_CURRENCY,DEAL_OTHER_CURRENCY,
    DEAL_COUNTER_PARTY,DEAL_MATURITY_FROM,DEAL_MATURITY_DATE,DEAL_BASE_AMOUNT,DEAL_OTHER_AMOUNT,DEAL_EXCHANGE_RATE,DEAL_SPOT_RATE,
    DEAL_MARGIN_RATE,DEAL_DEAL_NUMBER,DEAL_SERIAL_NUMBER,DEAL_HEDGE_TRADE,DEAL_SWAP_OUTRIGHT,DEAL_DEAL_TYPE,
    DEAL_AMOUNT_LOCAL,DEAL_MATURITY_CODE,DEAL_BACKUP_DEAL,DEAL_INIT_CODE,DEAL_USER_ID,deal_process_complete,deal_create_date,
    deal_record_status,deal_entry_detail,DEAL_LOCAL_RATE,DEAL_FORWARD_RATE,DEAL_DEALER_REMARKS,DEAL_DEALER_NAME,
    DEAL_COUNTER_DEALER,deal_confirm_date,DEAL_CONFIRM_TIME,DEAL_USER_REFERENCE,DEAL_BANK_REFERENCE) 
      SELECT  30100001,30200001,TRADE_DATE,to_char(systimestamp, 'HH24:MI'),BUY_SELL,BASE_CURRENCY,OTHER_CURRENCY,COUNTER_PARTY,
    trade_date,settlement_date,BASEAMOUNT,OTHERAMOUNT,EXCHANGERATE,SPOTRATE,MARGIN_RATE,'FWD'||VarDealNumber,1,26000001,25200002,
    25400006,0,0,BUSINESS_UNIT,PROFIT_CENTER,nvl(USER_NAME,'admin'),12400002,trade_date,10200001,Null,0,forward_rate,NULL,TRADER_NAME,
    COUNTERPARTY_TRADER_NAME ,DATE_CONFIRMED,to_char(systimestamp, 'HH24:MI'),DEAL_NUMBER,DEAL_NUMBER
    FROM trtran103a_FXGO  where DEAL_NUMBER= CUR.DEAL_NUMBER;
               
          update trtran103a_FXGO set REFERENCENUMBER='FWD'||VarDealNumber
          where DEAL_NUMBER= CUR.DEAL_NUMBER
           and classification=64000001;
           -- AND INTC_REFERENCE_NUMBER NOT IN (SELECT CFUT_BANK_REFERENCE FROM TRTRAN061 WHERE CFUT_RECORD_STATUS NOT IN (10200005,10200006));   
    end loop;
    
   Exception
          When others then
            numError := SQLCODE;
            varError := SQLERRM;
            varError := GConst.fncReturnError('FXALLDATA', numError, varMessage,
                            varOperation, varError);
            raise_application_error(-20101, varError);
END prcFXALLDATA;

procedure prcShippingDetails
as
  datTemp             date;
  numError            number;
  varOperation        GConst.gvarOperation%Type;
  varMessage          GConst.gvarMessage%Type;
  varError            GConst.gvarError%Type;
  numSerial           number;
  companycode         number;
  VarDealNumber       varchar(25);
begin

      insert into trtran002 (TRAD_LOCAL_BANK,TRAD_REFERENCE_DATE,TRAD_BUYER_SELLER,TRAD_TRADE_FCY,TRAD_TRADE_INR,TRAD_MATURITY_FROM,
      TRAD_MATURITY_DATE,TRAD_CONTRACT_NO,TRAD_LOCAL_CURRENCY,TRAD_COMPANY_CODE,TRAD_LOCATION_CODE,TRAD_USER_REFERENCE,TRAD_SPOT_RATE,
      TRAD_FORWARD_RATE,TRAD_MARGIN_RATE,TRAD_PRODUCT_CODE,trad_product_category,TRAD_SUBPRODUCT_CODE,TRAD_TENOR_CODE,trad_period_code,TRAD_PRODUCT_QUANTITY,TRAD_PRODUCT_RATE,
      TRAD_TRANSACTION_TYPE,TRAD_TERM,TRAD_CREATE_DATE,TRAD_RECORD_STATUS,TRAD_IMPORT_EXPORT,trad_trade_reference,
      trad_trade_currency,trad_trade_rate,trad_entry_date,TRAD_ENTRY_DETAIL,trad_process_complete,TRAD_TRADE_PERIOD,TRAD_TENOR_PERIOD,
      TRAD_PRODUCT_DESCRIPTION,TRAD_VESSEL_NAME,TRAD_PORT_NAME,trad_Destination_port,TRAD_TRADE_REMARKS)  
      select A.COMP_COMPANY_CODE ,INTIMATION_DATE,NVL(B.CUST_PICK_CODE,30599999),PROVISIONAL_CF_VALUE,
      PROVISIONAL_CF_VALUE*BILL_RATE,DUE_DATE,DUE_DATE,LCRV_CADRV_NO,30400004,30400003,
      30200001,CONTRACTNO_DTAE,BILL_RATE,0,0,33300001,33300001,33800001,0,0,BILL_OF_LADING_QUANTITY,CFR,
      0,0,SYSDATE,10200001,25900077,'EXP'||GCONST.FNCGENERATESERIAL(GCONST.SERIALTRADE,A.COMP_COMPANY_CODE),
      30400004,BILL_RATE,INTIMATION_DATE,NULL,12400002,0,0,COMMODITY,VESSEL_NAME,LOAD_PORT,DISPORT,REMARKS
      FROM TRSTAGING019  
      LEFT OUTER JOIN TRMASTER301 A ON 
      A.COMP_SHORT_DESCRIPTION=COMPANY_NAME
      AND COMP_RECORD_STATUS NOT IN (10200005,10200006)
      LEFT OUTER JOIN TRMASTER305 B 
      ON B.CUST_SHORT_DESCRIPTION=SUPPLIER
      AND CUST_RECORD_STATUS NOT IN (10200005,10200006); 
END prcShippingDetails;

procedure prcBloomburgdataload
as
begin

INSERT INTO TRTRAN103A
  ( DEALING_SYSTEM,    MESSAGE_TYPE,    DEAL_TYPE,    SIDE_BUY_SELL,    PRODUCT,
    STATUS,    REVISION_VERSION,    TRADE_ID,    TRADER_ID,    TRADER_NAME,
    COUNTERPARTY_ID,    COUNTERPARTY_TRADER_NAME,    DATE_OF_DEAL,    TIME_OF_DEAL,
    TRADE_DATE,    DATE_CONFIRMED,    TIME_CONFIRMED,    COUNTERPARTY_DEALING_CODE,
    COUNTERPARTY_NAME,    CURRENCY_1,    CURRENCY_2,    AMOUNT_DEALT,
    COUNTER_AMOUNT,    SPOT_BASIS_RATE,    EXCHANGE_RATE_PERIOD_1,    VALUE_DATE_PERIOD_1,
    TENOR_PERIOD_1,    FIXING_DATE_PERIOD_1,    VALUE_DATE_PERIOD2,    TENOR_PERIOD_2,
    FIXING_DATE_PERIOD_2,    SPLIT_VALUEDATE_CURRENCY_1,    SPLIT_VALUEDATE_CURRENCY2,
    REFERENCE_SPOTRATE,    REFERENCE_RATE_PERIOD1,    DELIVERY_DATE,    BANKNOTE_RATETYPE,
    EXECUTION_VENUE,    TRADEMETHOD,FileName,RECORDSTATUS)
 
 select 'FxGo',    MESSAGE_TYPE,    DEAL_TYPE,   decode( SIDE,'S',25300002,'B',25300001),    PRODUCT,
    Decode(STATUS,'0','New','1','Cancel','2','Correction'),    REVISION_VERSION,    TRADE_ID,  
    TRADER_ID,    replace(TRADER_NAME,'"',''),
    COUNTERPARTY_ID,    replace(COUNTERPARTY_TRADER_NAME,'"',''),    to_date(DATE_OF_DEAL,'yyyymmdd'),  
    TIME_OF_DEAL,  to_date(TRADE_DATE,'yyyymmdd'),    to_date(DATE_CONFIRMED,'yyyymmdd'), 
    TIME_CONFIRMED,    COUNTERPARTY_DEALING_CODE,
    COUNTERPARTY_NAME,  FNCGETPICKCODE_New(  CURRENCY_1,2,304),    FNCGETPICKCODE_New(  CURRENCY_2,2,304), 
    to_number(AMOUNT_DEALT),
    to_number(COUNTER_AMOUNT),    to_number(SPOT_BASIS_RATE),    EXCHANGE_RATE_PERIOD_1, to_date(VALUE_DATE_PERIOD_1,'yyyymmdd'),
    TENOR_PERIOD_1,    FIXING_DATE_PERIOD_1,    VALUE_DATE_PERIOD2,    TENOR_PERIOD_2,
    FIXING_DATE_PERIOD_2,    SPLIT_VALUEDATE_CURRENCY_1,    SPLIT_VALUEDATE_CURRENCY2,
    to_number(REFERENCE_SPOTRATE),    to_number(REFERENCE_RATE_PERIOD1),    DELIVERY_DATE,    BANKNOTE_RATETYPE,
    EXECUTION_VENUE,    TRADEMETHOD,FileName,10200001
    from BloomburgFXGO;

end prcBloomburgdataload;


PROCEDURE prcDueDateAlert(NumDay in Number)
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
  
BEGIN

    --open GenCursor for
  SELECT ALRT_ALERT_TO,ALRT_ALERT_CC into vartouser,varccuser FROM TRSYSTEM965 WHERE ALRT_ALERT_NAME = 'DUEDATEALERT'  ;
  DELETE FROM TRSYSTEM960;COMMIT;
       INSERT INTO TRSYSTEM960
      (MAIL_BANK_NAME,MAIL_CURRENCY_NAME,MAIL_TRANSACTION_TYPE,MAIL_SUPPLIER_NAME,MAIL_AMOUNT_FCY,
       MAIL_INTEREST_AMOUNT,MAIL_REPAYMENT_AMOUNT,MAIL_DUE_DATE,MAIL_REFERENCE_NUMBER,MAIL_DUE_FROM,
       MAIL_EXCHANGE_RATE,MAIL_EXCHANGE_CODE,MAIL_BUY_SELL,MAIL_OPTION_TYPE,MAIL_BACKUP_DEAL,MAIL_INIT_CODE)        
    SELECT
       pkgReturnCursor.fncGetDescription(DEAL_COUNTER_PARTY,2) AS BankName,
       pkgReturnCursor.fncGetDescription(DEAL_BASE_CURRENCY,2) AS CurrencyCode,
       'Forward Contract' AS   TypeofLoan,
       pkgReturnCursor.fncGetDescription(DEAL_COUNTER_PARTY,1) SupplierCode,
       deal_base_amount OUTSTANDINGAMOUNT, 0 AS InterestAmount,0 AS Repayment,
       deal_maturity_date DueDate,DEAL_DEAL_NUMBER DealNumber,
       deal_maturity_from DueFrom,deal_exchange_rate ExeRate,null,
       pkgReturnCursor.fncGetDescription(DEAL_BUY_SELL,2) AS BuySell,
       null, pkgReturnCursor.fncGetDescription(deal_backup_deal,2),
        pkgReturnCursor.fncGetDescription(deal_init_code,2)
       from TRTRAN001  WHERE 
       TO_DATE(deal_maturity_from,'DD/MM/YYYY') BETWEEN  TO_DATE(SYSDATE,'DD/MM/YYYY') AND TO_DATE(SYSDATE,'DD/MM/YYYY') + NumDay 
       AND (deal_process_complete = 12400002 OR (deal_process_complete=12400001 AND deal_complete_date >SYSDATE))
       AND deal_record_status NOT IN (10200005,10200006,10200010)   
    UNION ALL
       SELECT
       pkgReturnCursor.fncGetDescription(cfut_COUNTER_PARTY,2) AS BankName,
       pkgReturnCursor.fncGetDescription(cfut_BASE_CURRENCY,2) AS CurrencyCode,
       'Future Contract' AS   TypeofLoan,
       pkgReturnCursor.fncGetDescription(cfut_COUNTER_PARTY,1) SupplierCode,
       cfut_base_amount OUTSTANDINGAMOUNT,0 AS InterestAmount,0 AS Repayment,
       cfut_maturity_date DueDate,CFUT_DEAL_NUMBER DealNumber,
       cfut_maturity_from,cfut_exchange_rate,
       pkgReturnCursor.fncGetDescription(cfut_exchange_code,2),
       pkgReturnCursor.fncGetDescription(cfut_buy_sell,2),null,
       pkgReturnCursor.fncGetDescription(cfut_backup_deal,2),
       pkgReturnCursor.fncGetDescription(cfut_init_code,2)
       from trtran061  WHERE 
       TO_DATE(cfut_maturity_from,'DD/MM/YYYY') BETWEEN  TO_DATE(SYSDATE,'DD/MM/YYYY') AND TO_DATE(SYSDATE,'DD/MM/YYYY') + NumDay
       AND (cfut_process_complete = 12400002 OR (cfut_process_complete=12400001 AND cfut_complete_date >SYSDATE))
       AND cfut_record_status NOT IN (10200005,10200006,10200010)
     union all   
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
        pkgReturnCursor.fncGetDescription(COPT_INIT_CODE,2)
        from TRTRAN071,TRTRAN072   WHERE 
	      COPT_DEAL_NUMBER = COSU_DEAL_NUMBER
        AND TO_DATE(COPT_EXPIRY_date,'DD/MM/YYYY') BETWEEN  TO_DATE(SYSDATE,'DD/MM/YYYY') AND TO_DATE(SYSDATE,'DD/MM/YYYY') + NumDay
        AND (COPT_process_complete = 12400002 OR (COPT_process_complete=12400001 AND COPT_complete_date >SYSDATE))
        AND COPT_record_status NOT IN (10200005,10200006,10200010)
      	AND COSU_record_status NOT IN (10200005,10200006,10200010);
    COMMIT;
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
    FOR CUR_DUEDATE IN(SELECT * FROM TRSYSTEM960 ORDER BY MAIL_DUE_DATE,MAIL_TRANSACTION_TYPE)
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
    IF NumDay > 0 THEN
      varsubject := 'Transaction maturing in next ' ||NumDay|| ' days';
    ELSE
      varsubject := 'Transaction maturing in today';
    end if; 

    Pkgsendingmail.send_mail (vartouser,varccuser,null,varsubject, NULL,Null,varemailString);
    --Pkgsendingmail.send_mail_secure(vartouser,varccuser,null,varsubject, NULL,Null,varemailString);
    
--    PROCEDURE send_mail (p_to      IN VARCHAR2,
--                     p_cc        IN VARCHAR2,
--                     p_bcc       IN VARCHAR2,
--                     p_subject   IN VARCHAR2,
--                     p_text_msg  IN VARCHAR2 DEFAULT NULL,
--                     p_html_msg  IN VARCHAR2 DEFAULT NULL,
--                     p_html_msg_Clob  IN Clob DEFAULT NULL);



end  prcDueDateAlert;
  Procedure prcIRSMTMUpload
  as
  varOperation    VARCHAR2(200);
  begin
    varOperation := 'IRS MTM Upload';
    INSERT INTO TRTRAN091F
     (IIRM_COMPANY_CODE,IIRM_MTM_DEALNO,IIRM_MTM_BANKREF,
     IIRM_MTM_DATE,IIRM_MTM_AMOUNT,IIRM_RECORD_STATUS,
     IIRM_CREATE_DATE,IIRM_ADD_DATE)
     SELECT 30100001,Dealnumber,BankReference,to_date(MTMDate,'DD/MM/YYYY'),MTMAmount,10200001,SYSDATE,SYSDATE FROM TRSTAGING028;
  
  end prcIRSMTMUpload;
  
--PROCEDURE prcShippingEntry (Traderefernce in Varchar2,Entrity in Varchar2,workdate in Date,numAction in number)
--AS
--  Bank            VARCHAR2(10);
--  Currency        VARCHAR2(10);
--  LoanType        VARCHAR2(20);
--  SupplierCode    VARCHAR2(50);
--  AmountFCY       NUMBER(15,2);
--  IntAmount       NUMBER(15,2);
--  Repayment       NUMBER(15,2);
--  DueDate         DATE;  
--  --GenCursor gconst.datacursor;
--  varOperation    VARCHAR2(200);
--  varTemp1        VARCHAR2(4000);
--  varTemp2       clob;
----  varTemp2        BLOB;
--  varemailString  clob;
--  varHeader       VARCHAR2(4000);
--  vartouser       VARCHAR2(4000);
--  fromuser        VARCHAR2(4000);
--  varsubject      VARCHAR2(4000);
--  varccuser        VARCHAR2(4000);
--  datTemp         date;
--  
--BEGIN
--    SELECT TRAD_ENTRY_DATE INTO datTemp FROM TRTRAN002 WHERE TRAD_TRADE_REFERENCE = Traderefernce;
--    SELECT ALRT_ALERT_TO,ALRT_ALERT_CC into vartouser,varccuser FROM TRSYSTEM965 WHERE ALRT_ALERT_NAME = 'SHIPMENTDETAILS'  ;
--    varHeader:='<TABLE BORDER=1 BGCOLOR="#EEEEEE">';
--    varHeader:=varHeader||'<TR BGCOLOR="Gray">';
--    varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Company Name</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Instrument Type</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Reference Date</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Vessel Name</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Supplier Name</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR="WHITE">User Reference</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR="WHITE">LCRV/CADRV No</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Product Quantity</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Product Rate</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Currency</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Amount Fcy</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Exchange Rate</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR="WHITE">BL Date</FONT></TH>';    
--    varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Maturity Date</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Item Purchased</FONT></TH>'; 
--    varHeader:=varHeader||'<TH><FONT COLOR="WHITE">LC No</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR="WHITE">LC Value</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Final LC Value</FONT></TH>';
--    varHeader:=varHeader||'<TH><FONT COLOR="WHITE">Bank</FONT></TH>';    
--    varHeader:=varHeader||'</TR>';
--    if Entrity IN ('IMPORTTRADEREGISTERDETAIL1') then
--      if (numAction = GConst.EDITSAVE) then
--        varemailString:='LC Open Dated  : '|| datTemp;
--      end if;
--    else
--        varemailString := 'Testing entry Following Shipment done';
--    end if; 
--
--    varemailString := varemailString || varHeader;
--    FOR CUR_DUEDATE IN(SELECT pkgreturncursor.fncgetdescription(TRAD_COMPANY_CODE,1)CompanyName,
--                        pkgreturncursor.fncgetdescription(TRAD_IMPORT_EXPORT,1)IntrumentType,
--                        TRAD_REFERENCE_DATE ReferenceDate,
--                        TRAD_VESSEL_NAME VesselName,
--                        TRAD_VOYAGE BuyerName,
--                        TRAD_USER_REFERENCE UserReference,
--                        TRAD_CONTRACT_NO LCRVCADRVNo,
--                        TRAD_PRODUCT_QUANTITY ProductQuantity,
--                        TRAD_PRODUCT_RATE ProductRate,
--                        pkgreturncursor.fncgetdescription(TRAD_TRADE_CURRENCY,2) Currency,
--                        TRAD_TRADE_FCY AmountFcy,
--                        TRAD_TRADE_RATE ExchangeRate,
--                        TRAD_BILL_DATE BLDate,
--                        TRAD_MATURITY_DATE MaturityDate,
--                        TRAD_PRODUCT_DESCRIPTION Prouct,
--                        TRAD_LC_BENEFICIARY LCNo,
--                        TRAD_LC_VALUE LCValue,
--                        pkgreturncursor.fncgetdescription(TRAD_LOCAL_BANK,2)Bank
--                      FROM trtran002 WHERE trad_import_export IN (25900053,25900059)
--                      AND TRAD_RECORD_STATUS NOT IN(10200005,10200006)
--                      AND TRAD_TRADE_REFERENCE = Traderefernce
--                      AND trad_entry_date = datTemp)
--    loop 
--      varOperation := 'Generating Confirmation Pending Auto mail';
--      varTemp2:='';
--      varTemp2:=varTemp2 || '<TR BGCOLOR="WHITE">';
--      varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.CompanyName||'</td>';
--      varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.IntrumentType||'</td>';
--      varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.ReferenceDate||'</td>';
--      varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.VesselName||'</td>';
--      varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.BuyerName||'</td>';
--      varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.UserReference||'</td>';
--      varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.LCRVCADRVNo||'</td>';
--      varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.ProductQuantity||'</td>';
--      varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.ProductRate||'</td>';
--      varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.Currency||'</td>';
--      varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.AmountFcy||'</td>';
--      varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.ExchangeRate||'</td>';
--      varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.BLDate||'</td>';
--      varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.MaturityDate||'</td>';
--      varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.Prouct||'</td>';
--      varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.LCNo||'</td>';  
--      varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.LCValue||'</td>';  
--      varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.TotalLC||'</td>';        
--      varTemp2:=varTemp2 || '<td>'||CUR_DUEDATE.Bank||'</td>';
--      varTemp2:=varTemp2 || '</tr>';
--      varemailString := varemailString || varTemp2;     
--    end loop;
--    varemailString:= varemailString|| '</table>';  
--    if Entrity IN ('IMPORTTRADEREGISTERDETAIL1') then
--      if (numAction = GConst.EDITSAVE) then
--        varsubject:= 'Following LC Open : '  ||datTemp;
--      end if;
--    else
--      varsubject := 'Testing entry Shipment file Dated : ' ||datTemp;
--    end if;
--    if Entrity IN ('IMPORTTRADEREGISTERDETAIL1') then
--      if (numAction = GConst.EDITSAVE) then
--        Pkgsendingmail.send_mail (vartouser,varccuser,null,varsubject, NULL,Null,varemailString);
--      end if;
--    else
--      if (numAction = GConst.ADDSAVE) then
--         Pkgsendingmail.send_mail (vartouser,varccuser,null,varsubject, NULL,Null,varemailString);
--      end if;  
--    end if;
--end  prcShippingEntry;
--Procedure prcPurchaseInvoice
--As  
--  numserial varchar2(25);
--  varinvref varchar2(25);
--  varnumfcy number(15,6) default 0;
--  varnuminr number(15,6)default 0;
--  varnumrate number(15,6)default 0;
--  varnumqty number(15,6)default 0;
--  varpterm varchar2(25);
--  varptermdes varchar2(25);
--  varcur varchar2(25);
--  varprod varchar2(25);
--  varproddes varchar2(25);
--  
--BEGIN
--  
--  --- selecting distinct values from invoice staging
--  
--  for curpinv in (select distinct company_code,location_code,lob_code,Document_no#,Purchase_order_no#,sum(amount) as Amt,sum(amount_in_local_currency) as amtinr,
--  payment_terms,payment_text,currency_code,vendor_name,vendor_No#,to_date(document_date,'dd.mm.yyyy') doc_date,reference_no#
--  from trstaging023 where  not exists (select 'x' from trtran002 where document_no# = trad_trade_reference ) 
--  group by company_code,location_code,lob_code,Purchase_order_no#,document_no#, vendor_No#,to_date(document_date,'dd.mm.yyyy'),currency_code,
--  payment_terms,payment_text,Vendor_Name,reference_no#)
--  
--  LOOP
--  
--        numserial := 0;
--        
--        for curpinv1 in (select * from trstaging023 where document_no# = curpinv.document_no#)
--        
--        LOOP
--        
--              numserial := numserial+1;
--              
--            	insert into trtran002g 
--              (ispi_COMPANY_CODE, ispi_TRADE_REFERENCE, ispi_IMPORT_EXPORT, ispi_ENTRY_DATE, 
--              ispi_USER_REFERENCE, ispi_REFERENCE_DATE, ispi_PRODUCT_CODE, ispi_PRODUCT_DESCRIPTION, 
--              ispi_TRADE_FCY, ispi_TRADE_RATE, ispi_TRADE_INR, ispi_PERIOD_CODE, 
--              ispi_TRADE_PERIOD, ispi_MATURITY_DATE, ispi_CREATE_DATE, ispi_ENTRY_DETAIL, 
--              ispi_RECORD_STATUS, ispi_CONTRACT_NO, ispi_PRODUCT_QUANTITY, ispi_PRODUCT_RATE)
--              VALUES(decode(CURpINV1.company_code,1000,30100001,1010,30100002,30100003),'ISPI/'||curpinv1.document_no#||'/'|| lpad(numserial,4,'0'),25900052,to_date(curpinv1.document_date,'dd.mm.yyyy'),
--              curpinv1.document_no#,to_date(curpinv1.document_date,'dd.mm.yyyy'),0,'',
--              curpinv1.amount,round(nvl(curpinv1.amount_in_local_currency,1)/curpinv1.amount,6),curpinv1.amount_in_local_currency,25500001,
--              0,to_date(curpinv1.document_date,'dd.mm.yyyy')+nvl(extract_number(curpinv1.payment_text),0),sysdate,'',
--              10200001,curpinv.purchase_order_no#,curpinv1.quantity,0);
--              
--              varpterm := curpinv1.payment_terms;
--              varptermdes := substr(curpinv1.payment_text,1,25);
--              varcur := curpinv1.currency_code;
----              varnumfcy := varnumfcy + curpinv1.amount;
----              varnuminr := varnuminr + nvl(curpinv1.invoice_inr,0);
----              varnumrate := curpinv1.invoice_rate;
----              varprod := curpinv1.product_code;
----              varproddes := curpinv1.product_description;
--              
--              
--        END LOOP;
--        
--        insert into temp values(curpinv.document_no#,'');
--        
--        Insert into TRTRAN002 
--    (TRAD_COMPANY_CODE,TRAD_TRADE_REFERENCE,TRAD_REVERSE_REFERENCE,TRAD_REVERSE_SERIAL,TRAD_IMPORT_EXPORT,TRAD_LOCAL_BANK,
--    TRAD_ENTRY_DATE,TRAD_USER_REFERENCE,TRAD_REFERENCE_DATE,TRAD_BUYER_SELLER,TRAD_TRADE_CURRENCY,TRAD_PRODUCT_CODE,
--    TRAD_PRODUCT_DESCRIPTION,TRAD_TRADE_FCY,TRAD_TRADE_RATE,TRAD_TRADE_INR,TRAD_PERIOD_CODE,TRAD_TRADE_PERIOD,
--    TRAD_TENOR_CODE,TRAD_TENOR_PERIOD,TRAD_MATURITY_FROM,TRAD_MATURITY_DATE,
--    TRAD_PROCESS_COMPLETE,TRAD_COMPLETE_DATE,TRAD_TRADE_REMARKS,TRAD_CREATE_DATE,
--    TRAD_RECORD_STATUS,TRAD_VESSEL_NAME,TRAD_PORT_NAME,TRAD_BENEFICIARY,
--    TRAD_USANCE,TRAD_BILL_DATE,TRAD_CONTRACT_NO,TRAD_APP,TRAD_TRANSACTION_TYPE,TRAD_PRODUCT_QUANTITY,
--    TRAD_PRODUCT_RATE,TRAD_TERM,
--    TRAD_FORWARD_RATE,TRAD_MARGIN_RATE,TRAD_FINAL_RATE,TRAD_SPOT_RATE,TRAD_SUBPRODUCT_CODE,
--    TRAD_PRODUCT_CATEGORY,TRAD_ADD_DATE,TRAD_LOCATION_CODE,TRAD_MATURITY_MONTH,TRAD_LC_DATE,
--    TRAD_CONTRACT_DATE,TRAD_UOM_CODE,TRAD_PRICE_TYPE,TRAD_BUY_SELL,TRAD_EXCHANGE_RATE,
--    TRAD_LOCAL_CURRENCY)
--    values(decode(curpinv.company_code,1000,30100001,1010,30100002,30100003),curpinv.document_no#,null,0,25900052,30600001,
--    to_date(curpinv.doc_date,'dd.mm.yyyy'),curpinv.reference_no#,to_date(curpinv.doc_date,'dd.mm.yyyy'),pkgbulkdataload.fncGetPickCode1(curpinv.vendor_No#,curpinv.vendor_name,334,'Y'),decode(curpinv.currency_code,'CHF',30400001, 'EUR',30400002, 'INR',30400003, 'USD',30400004, 'JPY',30400005, 'GBP',30400006, 'CAD',30400007, 'AUD',30400008, 'NZD',30400009, 'SGD',30400010, 'HKD',30400011, 'KRW',30400012, 'PKR',30400013, 'MYR',30400014, 'AED',30400015, 'CNY',30400016,30499999),0,
--    '',curpinv.amt,curpinv.amtinr/curpinv.amt,curpinv.amtinr,23400001,0,
--    25500001,0,to_date(curpinv.doc_date,'dd.mm.yyyy'),to_date(curpinv.doc_date,'dd.mm.yyyy')+nvl(extract_number(curpinv.payment_text),0),
--    12400002,null,'',sysdate,
--    10200001,'0','0','0',
--    0,null,curpinv.document_no#,null,0,0,
--    0,pkgbulkdataload.fncGetPickCode1(curpinv.payment_terms,curpinv.payment_text,222,'Y'),
--    0,0,curpinv.amtinr/curpinv.amt,curpinv.amtinr/curpinv.amt,33800001,
--    33300001,null,30200001,to_date(curpinv.doc_date,'dd.mm.yyyy')+nvl(extract_number(curpinv.payment_text),0),null,
--    to_date(curpinv.doc_date,'dd.mm.yyyy'),null,null,null,null,
--    30400003);
--    
----    commit;
--    
--    varnumfcy := 0;
--    varnuminr := 0;
--    varnumrate := 0;
--    
--  END LOOP;
--  
--  
--  END prcPurchaseInvoice;
--  
--    Procedure prcPurchaseOrder
--As  
--  numserial varchar2(25);
--  varinvref varchar2(25);
--  varnumfcy number(15,6) default 0;
--  varnuminr number(15,6)default 0;
--  varnumrate number(15,6)default 0;
--  varnumqty number(15,6)default 0;
--  varpterm varchar2(25);
--  varptermdes varchar2(25);
--  varcur varchar2(25);
--  varprod varchar2(25);
--  varproddes varchar2(25);
--  
--BEGIN
--  
--
--
--  --- selecting distinct values from invoice staging
--  
--  for curpo in (SELECT * from trstaging022 where document_no not in (select trad_trade_reference from trtran002 where trad_import_export = 25900077))
--  
--  LOOP
--  
--        numserial := 0;
--        
--        insert into temp values(curpo.DOCUMENT_NO,'');
--        
--         Insert into TRTRAN002 
--    (TRAD_COMPANY_CODE,TRAD_TRADE_REFERENCE,TRAD_REVERSE_REFERENCE,TRAD_REVERSE_SERIAL,TRAD_IMPORT_EXPORT,TRAD_LOCAL_BANK,
--    TRAD_ENTRY_DATE,TRAD_USER_REFERENCE,TRAD_REFERENCE_DATE,TRAD_BUYER_SELLER,TRAD_TRADE_CURRENCY,TRAD_PRODUCT_CODE,
--    TRAD_PRODUCT_DESCRIPTION,TRAD_TRADE_FCY,TRAD_TRADE_RATE,TRAD_TRADE_INR,TRAD_PERIOD_CODE,TRAD_TRADE_PERIOD,
--    TRAD_TENOR_CODE,TRAD_TENOR_PERIOD,TRAD_MATURITY_FROM,TRAD_MATURITY_DATE,
--    TRAD_PROCESS_COMPLETE,TRAD_COMPLETE_DATE,TRAD_TRADE_REMARKS,TRAD_CREATE_DATE,
--    TRAD_RECORD_STATUS,TRAD_VESSEL_NAME,TRAD_PORT_NAME,TRAD_BENEFICIARY,
--    TRAD_USANCE,TRAD_BILL_DATE,TRAD_CONTRACT_NO,TRAD_APP,TRAD_TRANSACTION_TYPE,TRAD_PRODUCT_QUANTITY,
--    TRAD_PRODUCT_RATE,TRAD_TERM,
--    TRAD_FORWARD_RATE,TRAD_MARGIN_RATE,TRAD_FINAL_RATE,TRAD_SPOT_RATE,TRAD_SUBPRODUCT_CODE,
--    TRAD_PRODUCT_CATEGORY,TRAD_ADD_DATE,TRAD_LOCATION_CODE,TRAD_MATURITY_MONTH,TRAD_LC_DATE,
--    TRAD_CONTRACT_DATE,TRAD_UOM_CODE,TRAD_PRICE_TYPE,
--    TRAD_LOCAL_CURRENCY)
--    values (decode(curpo.company_code,1000,30100001,1010,30100002,30100003),curpo.document_no,null,0,25900077,30600001,
--    to_date(curpo.reference_date,'dd.mm.yyyy'),curpo.reference_no,to_date(curpo.reference_date,'dd.mm.yyyy'),pkgbulkdataload.fncGetPickCode1(curpo.vendor_code,curpo.vendor_name,334,'Y'),decode(curpo.currency_code,'CHF',30400001, 'EUR',30400002, 'INR',30400003, 'USD',30400004, 'JPY',30400005, 'GBP',30400006, 'CAD',30400007, 'AUD',30400008, 'NZD',30400009, 'SGD',30400010, 'HKD',30400011, 'KRW',30400012, 'PKR',30400013, 'MYR',30400014, 'AED',30400015, 'CNY',30400016,30499999),pkgbulkdataload.fncGetPickCode1(curpo.material_code,curpo.material_desc,243,'Y'),
--    '',curpo.net_value,curpo.exchange_rate,curpo.net_value*curpo.exchange_rate,23400001,0,
--    25500001,0,to_date(curpo.reference_date,'dd.mm.yyyy'),to_date(curpo.reference_date,'dd.mm.yyyy')+nvl(extract_number(curpo.payment_terms_desc),0),
--    12400002,null,'',sysdate,
--    10200001,'0','0','0',
--    0,null,curpo.document_no,null,0,0,
--    0,pkgbulkdataload.fncGetPickCode1(curpo.payment_terms,nvl(curpo.payment_terms_desc,'x'),222,'Y'),
--    0,0,curpo.exchange_rate,curpo.exchange_rate,33800001,
--    33300001,null,30200001,to_date(curpo.reference_date,'dd.mm.yyyy')+nvl(extract_number(nvl(curpo.payment_terms_desc,'x')),0),null,
--    to_date(curpo.contract_date,'dd.mm.yyyy'),null,null,
--    30400003);
--    
----    commit;
--    
--    varnumfcy := 0;
--    varnuminr := 0;
--    varnumrate := 0;
--    
--  END LOOP;
--  
--  
--  END prcPurchaseOrder;
----  
--  Procedure prcSalesInvoice
--As
--  
--  numserial varchar2(25);
--  varinvref varchar2(25);
--  varnumfcy number(15,6) default 0;
--  varnuminr number(15,6)default 0;
--  varnumrate number(15,6)default 0;
--  varnumqty number(15,6)default 0;
--  varpterm varchar2(25);
--  varptermdes varchar2(25);
--  varcur varchar2(25);
--  varprod varchar2(25);
--  varproddes varchar2(25);
--  
--  BEGIN
--  
--  update trstaging021 set INVOICE_FCY = replace(invoice_fcy,','), INVOICE_RATE=replace(INVOICE_RATE,','), INVOICE_INR=replace(INVOICE_INR,',');
--  commit;
--  --- selecting distinct values from invoice staging
--  
--  for curinv in (select distinct company_code,location_code,lob_code,SALES_ORDER_NO#,invoice_no#,min(to_date(document_date,'dd.mm.yyyy')) doc_date,min(to_date(REFERENCE_NODATE,'dd.mm.yyyy')) as refdate,
--  currency_code,customer_code,customer_name
--  from trstaging021 where  not exists (select 'x' from trtran002 where invoice_no# = trad_trade_reference ) 
--  group by company_code,location_code,lob_code,SALES_ORDER_NO#,invoice_no#, currency_code,
--  customer_code,customer_name)
--  
--  LOOP
--  
--        numserial := 0;
--        
--        for curinv1 in (select * from trstaging021 where invoice_no# = curinv.invoice_no#)
--        
--        LOOP
--        
--              numserial := numserial+1;
--              
--            	insert into trtran002f 
--              (ISHM_COMPANY_CODE, ISHM_TRADE_REFERENCE, ishm_invoice_number,ISHM_IMPORT_EXPORT, ISHM_ENTRY_DATE, 
--              ISHM_USER_REFERENCE, ISHM_REFERENCE_DATE, ISHM_PRODUCT_CODE, ISHM_PRODUCT_DESCRIPTION, 
--              ISHM_TRADE_FCY, ISHM_TRADE_RATE, ISHM_TRADE_INR, ISHM_PERIOD_CODE, 
--              ISHM_TRADE_PERIOD, ISHM_MATURITY_DATE, ISHM_CREATE_DATE, ISHM_ENTRY_DETAIL, 
--              ISHM_RECORD_STATUS, ISHM_CONTRACT_NO, ISHM_PRODUCT_QUANTITY, ISHM_PRODUCT_RATE)
--              VALUES(decode(CURINV1.company_code,1000,30100001,1010,30100002,30100003),'ISHM/'||curinv1.invoice_no#||'/'|| lpad(numserial,4,'0'),curinv.invoice_no#,25900024,sysdate,
--              curinv1.invoice_no#,to_date(curinv1.document_date,'dd.mm.yyyy'),pkgbulkdataload.fncGetPickCode1(curinv1.product_code,curinv1.product_description,243,'Y'),curinv1.product_description,
--              to_number(curinv1.invoice_fcy),nvl(to_number(curinv1.invoice_rate),1),to_number(curinv1.invoice_inr),25500001,
--              0,to_date(curinv1.document_date,'dd.mm.yyyy')+extract_number(curinv1.payment_terms_desc),sysdate,'',
--              10200001,curinv1.SALES_ORDER_NO#,curinv1.uom_qty,to_number(curinv1.uom_rate));
--              
--              varpterm := curinv1.payment_terms;
--              varptermdes := substr(curinv1.payment_terms_desc,1,25);
--              varcur := curinv1.currency_code;
--              varnumfcy := varnumfcy + to_number(curinv1.invoice_fcy);
----              varnuminr := varnuminr + nvl(curinv1.invoice_inr,0);
--              varnumrate := to_number(curinv1.invoice_rate);
--              varprod := curinv1.product_code;
----              varproddes := curinv1.product_description;
--              
--              
--        END LOOP;
--        
--        insert into temp values(curinv.invoice_no#,'');
--        
--        Insert into TRTRAN002 
--    (TRAD_COMPANY_CODE,TRAD_TRADE_REFERENCE,TRAD_REVERSE_REFERENCE,TRAD_REVERSE_SERIAL,TRAD_IMPORT_EXPORT,TRAD_LOCAL_BANK,
--    TRAD_ENTRY_DATE,TRAD_USER_REFERENCE,TRAD_REFERENCE_DATE,TRAD_BUYER_SELLER,TRAD_TRADE_CURRENCY,TRAD_PRODUCT_CODE,
--    TRAD_PRODUCT_DESCRIPTION,TRAD_TRADE_FCY,TRAD_TRADE_RATE,TRAD_TRADE_INR,TRAD_PERIOD_CODE,TRAD_TRADE_PERIOD,
--    TRAD_TENOR_CODE,TRAD_TENOR_PERIOD,TRAD_MATURITY_FROM,TRAD_MATURITY_DATE,
--    TRAD_PROCESS_COMPLETE,TRAD_COMPLETE_DATE,TRAD_TRADE_REMARKS,TRAD_CREATE_DATE,
--    TRAD_RECORD_STATUS,TRAD_VESSEL_NAME,TRAD_PORT_NAME,TRAD_BENEFICIARY,
--    TRAD_USANCE,TRAD_BILL_DATE,TRAD_CONTRACT_NO,TRAD_APP,TRAD_TRANSACTION_TYPE,TRAD_PRODUCT_QUANTITY,
--    TRAD_PRODUCT_RATE,TRAD_TERM,
--    TRAD_FORWARD_RATE,TRAD_MARGIN_RATE,TRAD_FINAL_RATE,TRAD_SPOT_RATE,TRAD_SUBPRODUCT_CODE,
--    TRAD_PRODUCT_CATEGORY,TRAD_ADD_DATE,TRAD_LOCATION_CODE,TRAD_MATURITY_MONTH,TRAD_LC_DATE,
--    TRAD_CONTRACT_DATE,TRAD_UOM_CODE,TRAD_PRICE_TYPE,TRAD_BUY_SELL,
--    TRAD_LOCAL_CURRENCY)
--    values(decode(curinv.company_code,1000,30100001,1010,30100002,30100003),curinv.invoice_no#,null,0,25900024,30600001,
--    nvl(to_date(curinv.refdate,'dd.mm.yyyy'),to_date(curinv.doc_date,'dd.mm.yyyy')),curinv.invoice_no#,to_date(curinv.doc_date,'dd.mm.yyyy'),pkgbulkdataload.fncGetPickCode1(curinv.customer_code,curinv.customer_name,305,'Y'),decode(curinv.currency_code,'CHF',30400001, 'EUR',30400002, 'INR',30400003, 'USD',30400004, 'JPY',30400005, 'GBP',30400006, 'CAD',30400007, 'AUD',30400008, 'NZD',30400009, 'SGD',30400010, 'HKD',30400011, 'KRW',30400012, 'PKR',30400013, 'MYR',30400014, 'AED',30400015, 'CNY',30400016,30499999),pkgbulkdataload.fncGetPickCode1(varprod,varproddes,243,'Y'),
--    '',varnumfcy,varnumrate,varnumfcy*varnumrate,23400001,0,
--    25500001,0,to_date(curinv.doc_date,'dd.mm.yyyy'),to_date(curinv.doc_date,'dd.mm.yyyy')+nvl(extract_number(varptermdes),0),
--    12400002,null,'',sysdate,
--    10200001,'0','0','0',
--    0,null,curinv.SALES_ORDER_NO#,null,0,0,
--    0,pkgbulkdataload.fncGetPickCode1(varpterm,varptermdes,222,'Y'),
--    0,0,varnumrate,varnumrate,33800001,
--    33300001,null,30200001,to_date(curinv.doc_date,'dd.mm.yyyy')+extract_number(varptermdes),null,
--    to_date(curinv.doc_date,'dd.mm.yyyy'),null,null,null,
--    30400003);
--    
----    commit;
--    
--    varnumfcy := 0;
--    varnuminr := 0;
--    varnumrate := 0;
--    
--  END LOOP;
--  
--  
--  END prcSalesInvoice;
  
       procedure prcProcessPickupsap
              ( pickSapCode in varchar,
                numKeyGroup in number,
                PickShortDescription in varchar,
                PickLongDescription in varchar,
                numPickValue out number)
as
      numError            number;
      numRecords          number;
      numAction           number(3);
    --  numKeyGroup         number(3);
      numKeyNumber        number(5);
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
      varMessage :=  PickLongDescription ;
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

        select distinct pick_company_code,pick_key_type
        into numCompanyCode,numKeyType
        from PickupMaster
        where pick_key_group = numKeyGroup
        and pick_key_number = 0;

      numError := 5;
      varOperation := 'Inserting new value for Pickup' || numRecordStatus;

      insert into PickupMaster (pick_company_code, pick_key_group, pick_key_number,
        pick_key_value, pick_short_description, pick_long_description,pick_key_type,pick_sap_code,
        pick_remarks, pick_entry_detail, pick_record_status)
        values(numCompanyCode, numKeyGroup, numKeyNumber,
        numPickValue, PickShortDescription, PickLongDescription, numKeyType,pickSapCode,
        'Cascaded from master entry', null, 10200003);

    --  PickValue := numPickValue;
      numError := 0;
      varError := 'Successful Operation';

      Exception
          When Error_Occurred then
            numError := -1;
            varError := GConst.fncReturnError('prcProcessPickup', numError, varMessage,
                            varOperation, varError);
            raise_application_error(-20101, varError);

          When others then
            numError := SQLCODE;
            varError := SQLERRM;
            varError := GConst.fncReturnError('prcProcessPickup', numError, varMessage,
                            varOperation, varError);
            raise_application_error(-20101, varError);
  End prcProcessPickupsap;
  
  function extract_number(in_number varchar2) return varchar2 is
begin
  return regexp_replace(in_number, '[^[:digit:]]', '');
end;
function fncGetPickCode1(
         PickSapCode in varchar,
         PickDescription in varchar,
         pickCode in number,
         AddNewEntry in char) return number
as
  varOperation        GConst.gvarOperation%Type;
  varMessage          GConst.gvarMessage%Type;
  varError            GConst.gvarError%Type;
  numError            number;
  numPickCode number(8);
  pragma autonomous_transaction;
begin
      varMessage :=  substr(PickDescription,1,50) ;
      varOperation := 'Generating the next sequence';

        
   begin
    select PICK_KEY_VALUE
       into numPickCode
     from trmaster001
     where pick_key_group=pickCode
     and pick_sap_code=pickSapCode;
   exception
   when no_data_found then
      numPickCode:= null;
   end;
   if numPickCode is null then
      prcProcessPickupsap(pickSapCode,PickCode,substr(PickDescription,1,15),substr(PickDescription,1,50),numPickCode);
   end if;
   commit;
    return numPickCode;
exception
   when others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('fncGetPickCode', numError, varMessage,
                           varOperation, varError);
      rollback;
      raise_application_error(-20101, varError);
end fncGetPickCode1;

procedure ValidateData
(LoadName in varchar)
as
  varOperation        GConst.gvarOperation%Type;
  varMessage          GConst.gvarMessage%Type;
  varError            GConst.gvarError%Type;
  numError            number;
  varQuery            varchar(4000);
  
begin 
    varMessage:= 'Validate Date for Data Load ' || LoadName;
  --  insert into rtemp (TT) values(varMessage); commit;
    
    for cur in (select * from trsystem968 inner join trsystem969
                 on LOCL_DATA_NAME=LOAD_DATA_NAME
                where LOCL_DATA_NAME=LoadName
                and LOCL_RECORD_STATUS not in (10200005,10200006)
                and LOAD_record_status not in (10200005,10200006))
    loop
      varOperation:= ' Processing the data of '|| cur.LOCL_DESTINATION_COLUMN;
      varQuery:=null;
      if cur.LOCL_DATA_TYPE=90400003 then -- Date
      
           varQuery:=' Update  ' || cur.LOAD_STAGING_TABLE ||'_1'|| ' set ' || cur.LOCL_DESTINATION_COLUMN ||' = to_date('|| cur.LOCL_DESTINATION_COLUMN || ',' || ''''||  'dd/mm/yyyy' || '''' || ')' ||
            ' where isdate(' || cur.LOCL_DESTINATION_COLUMN ||  ','|| '''' ||  'dd/mm/yyyy'|| ''''|| ')=' ||  '''' || '0' || ''''  ;
            
          varoperation:=' Update the Date format for the Valid Dates ' || varQuery;  
          
          execute immediate varQuery;
          
          varQuery:=' Update  ' || cur.LOAD_STAGING_TABLE ||'_1'|| ' set REMARKS = nvl(REMARKS,'||'''' || ' ; ' || '''' ||' )|| '|| '''' ||
            '| Date Format is not Valid on Column '  || cur.LOCL_DESTINATION_COLUMN || '''' ||
           -- ', '||   ',PROCESSSTATUS=12400002' || 
            ' where isdate(' || cur.LOCL_DESTINATION_COLUMN  ||  ','|| '''' || 'dd/mm/yyyy'|| ''''|| ')!=' ||  '''' || '0' || ''''  ;
            
 
            
      elsif ((cur.LOCL_DATA_TYPE=90400002) and (cur.LOCL_PICK_GROUP>0)) then --PickCode
          varQuery:=' Update  ' || cur.LOAD_STAGING_TABLE ||'_1'|| ' set '
               || cur.LOCL_DESTINATION_COLUMN|| '_Code = ' || ' IS_Valid_PICKUP_TEXT(' || cur.LOCL_DESTINATION_COLUMN || ',' || cur.LOCL_PICK_GROUP ||')' ||
                -- ',PROCESSSTATUS=12400001' || 
            ' where IS_Valid_PICKUP_TEXT(' || cur.LOCL_DESTINATION_COLUMN || ',' || cur.LOCL_PICK_GROUP ||') !=' || '0';
            
          varoperation:='Update Pick Codes Query ' || varQuery;  
          
          execute immediate varQuery;   
          
          varQuery:=' Update  ' || cur.LOAD_STAGING_TABLE ||'_1'|| ' set REMARKS = nvl(REMARKS,'||'''' || ' ; ' || '''' ||' )|| '|| '''' ||
            '| Pick Text is not Valid on Column '  || cur.LOCL_DESTINATION_COLUMN || '''' || 
            -- ',PROCESSSTATUS=12400002' || 
            ' where IS_Valid_PICKUP_TEXT(' || cur.LOCL_DESTINATION_COLUMN || ',' || cur.LOCL_PICK_GROUP ||') =' || '0';
            
            
      elsif cur.LOCL_DATA_TYPE=90400002 then ----Number
           varQuery:=' Update  ' || cur.LOAD_STAGING_TABLE ||'_1'|| ' set REMARKS = nvl(REMARKS,'||'''' || ' ; ' || '''' ||' )|| '|| '''' || 
            '| Number Format is not Valid on Column '  || cur.LOCL_DESTINATION_COLUMN || '''' ||
             --',PROCESSSTATUS=12400002' || 
            ' where IS_NUMBER(' || cur.LOCL_DESTINATION_COLUMN ||')=' || '''' || 'N' ||'''' ;
      end if;
      --INSERT INTO temp VALUES (varQuery,varQuery);
     --  insert into rtemp (TT,TT2) values(LoadName,varQuery); commit;
      varoperation:='Execute Query ' || varQuery;
      if varQuery is not null then
          varoperation:=' Inside If Condition ' || varQuery;
          execute immediate varQuery;
      end if;
      
    end loop;
    
    commit;
exception
   when others then
      numError := SQLCODE;
      varError := SQLERRM;
      varError := GConst.fncReturnError('ValidateData', numError, varMessage,
                           varOperation, varError);
      rollback;
      raise_application_error(-20101, varError);
end ValidateData;
end pkgBulkDataload;
/