CREATE OR REPLACE PACKAGE BODY "TEST_VSTSRedgate"."PKGSAPINTERFACE" as

--procedure PrcPushDataFrmSap
--    as
--    
--    numError            number;
--    varOperation        varchar(2000);
--    varMessage          varchar(100);
--    varError            varchar(4000);
--    numInsertedRows     number;
--    numUpdatedRows      number;
--    NUMDELETEDROWS      NUMBER;
--    NUMPROCESSEDROW     number;
--    Processdate         Date;
--    totalRows           number;
--    MAIL_BODY         VARCHAR2(4000);
--     MAIL_BODY1        VARCHAR2(4000);
--     MAIL_FROM         VARCHAR2(100); 
--     MAIL_TO           VARCHAR2(100); 
--     MAIL_CC            VARCHAR2(100) :=''; 
--     MAIL_BCC           VARCHAR2(100) :='';
--     STRSTRING        VARCHAR2(3500);
--     strstring1        VARCHAR2(3500);
--BEGIN 
--     MAIL_FROM:='fx.treasury@timesgroup.com';
--     MAIL_TO:='neha.gupta4@timesgroup.com' ||','||'Chetan.Agarwal@timesgroup.com';
--     MAIL_CC :='Prateek.mathur@ibsfintech.com'||',' ||'nilesh.atal@ibsfintech.com' ;
--     MAIL_BCC :='' ;     
--     MAIL_BODY :='Auto Scheduled for SAP data transfer completed Sucessfully. ' || 'Following Contracts have been added/updated:';
--     MAIL_BODY1 :='Auto Scheduled for SAP data transfer Failed. Please Find the failed contract Numbers: ' ;
--     STRSTRING :='';
--     STRSTRING1:='';
--     
--    varMessage := 'Building query for pushing data from sap table to temp table';
--     FOR CURDATA IN ( SELECT CONT_PO_NO  FROM   toilnk.TRSYSTEM801 INNER JOIN TRSYSTEM052 
--            ON MATERIALTYPE=CATEGORY_CD)
--       LOOP
--          STRSTRING1:=STRSTRING1 || CURDATA.CONT_PO_NO ||chr(13)||chr(10);
--       END LOOP;
--       if length(nvl(STRSTRING1,1)) < 8 then
--            MAIL_BODY :=' No Data Found To Process.';
--            MAIL_BODY1 :=MAIL_BODY;
--         else
--             MAIL_BODY :=MAIL_BODY || chr(13)|| CHR(10) || STRSTRING1;
--             MAIL_BODY1:=MAIL_BODY1 ||chr(13)||chr(10)|| STRSTRING1;
--         end if;
--       
--    varoperation:='pushing inserted records from sap to temp table ';
--    
--   MERGE INTO TRTRAN002C a
--      USING ( SELECT  CONT_PO_NO,ENTRY_DATE, 
--                      PKGSAPINTERFACE.FNCGETPICKCODE(301,COMP_CODE) COMP_CODE,
--                      PKGSAPINTERFACE.FNCGETPICKCODE(305,SUBSTR(VENDOR,3,LENGTH(VENDOR))) VENDOR,
--                      PKGSAPINTERFACE.FNCGETPICKCODE(304,CURRENCY) CURRENCY,
--                      PKGSAPINTERFACE.FNCGETPICKCODE(306,BANK) BANK ,
--                      PKGSAPINTERFACE.FNCGETPICKCODE(222,PAY_TERMS) PAY_TERMS,
--                      CONT_VAL, QUANTITY,PRICE,APPROVAL_DATE, CATEGORY_CODE,SUB_CATEGORY_CODE,
--                      TRANSFER_DATE, REMARKS,DUE_DATE,
--                       (CASE WHEN SUBSTR(CONT_PO_NO,1,1)=2 THEN '25900077' 
--                           WHEN SUBSTR(CONT_PO_NO,1,1)=3 THEN '25900086' END) ACCOUNT_CODE,
--                           decode(STATUS ,'D','10200006','10200004') STATUS
--                   FROM TOILNK.TRSYSTEM801 INNER JOIN TRSYSTEM052 
--                   ON MATERIALTYPE=CATEGORY_CD) SAPDATA
--        ON (a.CONR_USER_REFERENCE=sapdata.CONT_PO_NO)
--  WHEN  MATCHED THEN UPDATE SET
--                A.CONR_ADD_DATE = SYSDATE,
--                A.CONR_COMPANY_CODE=SAPDATA.COMP_CODE,A.CONR_BUYER_SELLER=SAPDATA.VENDOR,
--                A.CONR_BASE_CURRENCY=SAPDATA.CURRENCY,A.CONR_BASE_AMOUNT=SAPDATA.CONT_VAL,
--                A.CONR_LOCAL_BANK=SAPDATA.BANK,A.CONR_TOTAL_QUANTITY=SAPDATA.QUANTITY,
--                A.CONR_PRODUCT_RATE=SAPDATA.PRICE,
--                A.CONR_EXECUTE_DATE=TO_CHAR(TO_DATE(SAPDATA.APPROVAL_DATE,'yyyymmdd'),'dd-MON-yyyy'),
--                A.CONR_PRODUCT_CATEGORY=SAPDATA.CATEGORY_CODE,A.CONR_SUB_CATEGORY=SAPDATA.SUB_CATEGORY_CODE,
--                A.CONR_PAYMENT_TERMS=SAPDATA.PAY_TERMS,
--                A.CONR_REFERENCE_DATE=TO_CHAR(TO_DATE(SAPDATA.ENTRY_DATE,'yyyymmdd'),'dd-MON-yyyy'),
--                A.CONR_CREATE_DATE= TO_CHAR(TO_DATE(SAPDATA.TRANSFER_DATE,'yyyymmdd'),'dd-MON-yyyy'),
--                A.CONR_CONT_REMARKS=SAPDATA.REMARKS,
--                A.CONR_END_DATE=TO_CHAR(TO_DATE(SAPDATA.DUE_DATE,'yyyymmdd'),'dd-MON-yyyy'),
--                a.CONR_RECORD_STATUS= STATUS,A.CONR_ACCOUNT_CODE= SAPDATA.ACCOUNT_CODE
--              --  A.CONR_USER_REFERENCE=SAPDATA.CONT_PO_NO
--        --- where a.CONR_RECORD_STATUS <> 10200005
--WHEN NOT MATCHED THEN INSERT   
--                (CONR_TRADE_REFERENCE,CONR_COMPANY_CODE,CONR_BUYER_SELLER,
--                CONR_BASE_CURRENCY,CONR_BASE_AMOUNT,CONR_LOCAL_BANK,CONR_TOTAL_QUANTITY,
--                CONR_PRODUCT_RATE,CONR_EXECUTE_DATE,CONR_PRODUCT_CATEGORY,CONR_SUB_CATEGORY,
--                CONR_PAYMENT_TERMS, CONR_REFERENCE_DATE,CONR_CREATE_DATE,CONR_CONT_REMARKS,
--                CONR_END_DATE,CONR_ADD_DATE,CONR_RECORD_STATUS,CONR_ACCOUNT_CODE,
--                CONR_USER_REFERENCE) VALUES (                    
--                PKGSAPINTERFACE.FNCGENERATEKEYNUM(SAPDATA.CONT_PO_NO,TO_CHAR(TO_DATE(SAPDATA.ENTRY_DATE,'yyyymmdd'),'dd-MON-yyyy')), 
--                SAPDATA.COMP_CODE,SAPDATA.VENDOR,SAPDATA.CURRENCY,SAPDATA.CONT_VAL,
--                SAPDATA.BANK,SAPDATA.QUANTITY,SAPDATA.PRICE,
--                TO_CHAR(TO_DATE(SAPDATA.APPROVAL_DATE,'yyyymmdd'),'dd-MON-yyyy'),
--                SAPDATA.CATEGORY_CODE,SAPDATA.SUB_CATEGORY_CODE,
--                SAPDATA.PAY_TERMS,TO_CHAR(TO_DATE(SAPDATA.ENTRY_DATE,'yyyymmdd'),'dd-MON-yyyy'),
--                TO_CHAR(TO_DATE(SAPDATA.TRANSFER_DATE,'yyyymmdd'),'dd-MON-yyyy'),
--                SAPDATA.REMARKS,TO_CHAR(TO_DATE(SAPDATA.DUE_DATE,'yyyymmdd'),'dd-MON-yyyy'),SYSDATE,'10200001',
--                sapdata.Account_Code,sapdata.CONT_PO_NO);
--           
--         NUMPROCESSEDROW :=sql%rowcount;
--            
--            varoperation:='insert records into trtran002 contracts from trtran002c';
--              insert into trtran002
--                (trad_company_code,trad_trade_reference,trad_reverse_reference,trad_reverse_serial,
--                trad_import_export,trad_local_bank,trad_entry_date,trad_user_reference,trad_reference_date,
--                trad_buyer_seller,trad_trade_currency,trad_product_code,trad_product_description,
--                trad_trade_fcy,trad_trade_rate,trad_trade_inr,trad_period_code,trad_trade_period,
--                trad_tenor_code,trad_tenor_period,trad_maturity_from,trad_maturity_date,
--                trad_maturity_month,trad_process_complete,trad_complete_date,trad_trade_remarks,
--                trad_create_date,trad_entry_detail,trad_record_status,trad_vessel_name,
--                trad_port_name,trad_beneficiary,trad_usance,trad_bill_date,trad_contract_no,
--                trad_app,trad_transaction_type,trad_product_quantity,trad_product_rate,trad_term,
--                trad_voyage,trad_link_batchno,trad_link_date,trad_lc_beneficiary,trad_forward_rate,
--                trad_margin_rate,trad_final_rate,trad_spot_rate,trad_subproduct_code,
--                trad_product_category,trad_add_date)
--                select distinct 30100001,'PC/' || conr_user_reference || '/14-15', '.', 1, 25900086,conr_local_bank,conr_add_date,
--                conr_user_reference,conr_reference_date,conr_buyer_seller,conr_base_currency,
--                decode(conr_sub_category,33800001,24200001,33800002,24200005,33800051,24200003,24200058),
--                pkgReturnCursor.fncGetDescription(conr_sub_category,1),conr_base_amount,
--                nvl(pkgForexProcess.fncGetRate(Conr_base_currency,30400003,
--                  pkgSapInterface.fncGetCalendarDate1(conr_reference_date,conr_base_currency,30400003),25300001,0,conr_end_date),0),0,
--                25500001,conr_end_date - conr_reference_date,25500001,1,conr_reference_date,conr_end_date,conr_end_date,12400002,null,
--                'Transferred from SAP',conr_create_date,null,10200001,null,null,null,null,null,
--                conr_user_reference,null,null,conr_total_quantity,conr_product_rate,conr_payment_terms,
--                null,null,null,null,0,0,0,
--                nvl(pkgForexProcess.fncGetRate(Conr_base_currency,30400003,
--                  pkgSapInterface.fncGetCalendarDate1(conr_reference_date,conr_base_currency,30400003),25300001,0,conr_reference_date),0),
--                conr_sub_category, conr_product_category, conr_add_date
--                from trtran002c
--                where conr_create_date=to_date(sysdate,'dd-mon-yy');    
--            
--            
--             varoperation:='updating records into trtran002 contracts coming from trtran002c';
--              update trtran002
--              set trad_trade_rate = trad_spot_rate
--              where trad_trade_rate = 0
--              and trad_create_date=to_date(sysdate,'dd-mon-yy')
--              and trad_record_status not in (10200005);
--              
--              update trtran002
--              set trad_forward_rate = trad_trade_rate - trad_spot_rate
--              where trad_create_date=to_date(sysdate,'dd-mon-yy')
--              and trad_record_status not in (10200005);
--              
--              update trtran002
--              set trad_trade_rate = round(trad_trade_rate,4),
--              trad_spot_rate = round(trad_spot_rate,4),
--              trad_forward_rate = round(trad_forward_rate,4)
--              where trad_create_date=to_date(sysdate,'dd-mon-yy')
--              and trad_record_status not in (10200005);
--              
--              update trtran002
--              set trad_trade_rate = round(trad_trade_rate + trad_trade_rate * 0.02,4)
--              where trad_create_date=to_date(sysdate,'dd-mon-yy')
--              and trad_record_status not in (10200005);
--              
--            
--    varoperation:='pushing inserted records from sap to Archive table';
--
-- insert into trsystem801_archive(DATA_EXCEPTIONS,IBS_DB_TRANSFERDATE,IBS_DB_TRANSFERTIME_STAMP,
--    STATUS,COMP_CODE,CONT_PO_NO ,ENTRY_DATE,DUE_DATE ,VENDOR,CATEGORY_CD,SUB_CAT ,CURRENCY ,
--    QUANTITY,PRICE,CONT_VAL ,PAY_TERMS ,BANK ,REMARKS,APPROVAL_DATE,TRANSFER_DATE ,TRAN_TIME_STAMP)
--    
--    select '12400001',SYSDATE,to_char(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'),STATUS,COMP_CODE,
--    CONT_PO_NO ,ENTRY_DATE,DUE_DATE ,VENDOR,CATEGORY_CD,SUB_CAT ,CURRENCY ,QUANTITY,PRICE ,
--    CONT_VAL ,PAY_TERMS ,BANK ,REMARKS,APPROVAL_DATE,TRANSFER_DATE ,TRAN_TIME_STAMP
--    FROM TOILNK.TRSYSTEM801;
--
--      
--      varoperation:='Insert Process Records log into trsystem900 table';
--        
--      insert into toilnk.trsystem900 (SAPI_PROCESS_DATE,SAPI_DATA_TYPE,SAPI_TOTAL_ROWS,SAPI_INSERTED_ROWS,
--                              SAPI_UPDATED_ROWS,SAPI_DELETED_ROWS,SAPI_TOT_PROCESSED_ROWS,
--                              SAPI_SYSTEM_DATE,SAPI_RECORD_STATUS)
--         SELECT TO_DATE(SYSDATE,'yyyy-mm-dd') ,'FROM SAP', COUNT(*) TOTALROWS,0,0,0,NUMPROCESSEDROW,SYSTIMESTAMP,10200001
--            FROM TOILNK.TRSYSTEM801 ;
--      
--    varoperation:='Delete Records from TRSYSTEM801 table';
--    DELETE FROM TOILNK.TRSYSTEM801;
--    commit;
-- --   VAROPERATION:='Sending Auto Generated mail for SAP records';
--     
--     --UTL_MAIL.SEND(SENDER     => MAIL_FROM ,
--     --           RECIPIENTS => MAIL_TO,
--     --           CC         => mail_CC ,
--     --           BCC        => MAIL_BCC,
--     --           SUBJECT    => 'SAP Process Completed Sucessfully as on '|| SYSDATE ,
--     --           MESSAGE    => mail_body ) ; 
-- EXCEPTION  
-- WHEN OTHERS THEN
--   ROLLBACK;
--    NUMERROR := SQLCODE;
--    VARERROR := SQLERRM;
--   insert into toilnk.TRSYSTEM801_EXCEPTION (DATA_EXCEPTIONS,IBS_DB_TRANSFERDATE,IBS_DB_TRANSFERTIME_STAMP,
--    STATUS,COMP_CODE,CONT_PO_NO ,ENTRY_DATE,DUE_DATE ,VENDOR,CATEGORY_CD,SUB_CAT ,CURRENCY ,
--    QUANTITY,PRICE,CONT_VAL ,PAY_TERMS ,BANK ,REMARKS,APPROVAL_DATE,TRANSFER_DATE ,TRAN_TIME_STAMP)
--    
--    select substr(VARERROR,1,500),SYSDATE,to_char(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'),STATUS,COMP_CODE,
--    CONT_PO_NO ,ENTRY_DATE,DUE_DATE ,VENDOR,CATEGORY_CD,SUB_CAT ,CURRENCY ,QUANTITY,PRICE ,
--    CONT_VAL ,PAY_TERMS ,BANK ,REMARKS,APPROVAL_DATE,TRANSFER_DATE ,TRAN_TIME_STAMP
--    FROM toilnk.TRSYSTEM801;
--    
--      
--    DELETE FROM TOILNK.TRSYSTEM801;
--   COMMIT; 
--    
----     UTL_MAIL.SEND(SENDER     => mail_FROM ,
----                RECIPIENTS =>MAIL_TO,
----                CC         => mail_CC, 
----                BCC        => MAIL_BCC, 
----                SUBJECT    => 'SAP Auto Schedule Process failed as on '|| Sysdate ,
----                MESSAGE    => mail_body1 ) ; 
--    
-- 
--   
--    varError := GConst.fncReturnError('SapData', numError, varMessage, 
--                    VAROPERATION, VARERROR);
--    --dbms_output.put_line(VARERROR);
--    raise_application_error(-20101, varError); 
--      
--
--  end PrcPushDataFrmSap;
--       
--       
--  
--procedure PrcPushDataFrmSynnovate
--    as
--    numError            number;
--    varOperation        varchar(2000);
--    varMessage          varchar(100);
--    VARERROR            VARCHAR(4000);
--    numInsertedRows     number;
--    numUpdatedRows      number;
--    numDeletedRows      number;
--    Processdate         Date;
--    TOTALROWS           NUMBER;
--     MAIL_BODY         VARCHAR2(4000);
--     MAIL_BODY1        VARCHAR2(4000);
--     MAIL_FROM         VARCHAR2(100); 
--     MAIL_TO           VARCHAR2(100); 
--     MAIL_CC            VARCHAR2(100); 
--     MAIL_BCC           VARCHAR2(100);
--     STRSTRING          VARCHAR2(3000);
--     strstring1          VARCHAR2(3000);
--BEGIN 
--   MAIL_FROM:='fx.treasury@timesgroup.com';
--   MAIL_TO:='neha.gupta4@timesgroup.com' ||','||'Chetan.Agarwal@timesgroup.com';
--   MAIL_CC :='Prateek.mathur@ibsfintech.com'||',' ||'nilesh.atal@ibsfintech.com' ;
--   MAIL_BCC :='' ;
--   MAIL_BODY :='Auto Schedule for Synnovate data transfer have been completed Sucessfully. ' || 'Following Contracts have been added:';
--   MAIL_BODY1 :='Auto Schedule for Synnovate data transfer have been Failed. Please Find the fail Contract Numbers: ' ;
--   STRSTRING :='';
--   STRSTRING1 :='';
--   
--   VARMESSAGE := 'Building query for pushing data from Synnovate table to temp table';
--          FOR CURDATA IN ( SELECT NVL(CONTRACT_NUMBER,PO_NUMBER) as contractnumber FROM  TOILNK.TRSYSTEM802 INNER JOIN TRSYSTEM052 
--                    ON MATERIALTYPE=NVL(CATEGORY_CD, 'SER') where due_date <> '00000000') /*changed for ignoring due date with 00 changed by nilesh/prateek*/
--           LOOP
--              STRSTRING1:=STRSTRING1 || curdata.contractnumber ||chr(13)||chr(10);
--           END LOOP;
--          if length(nvl(STRSTRING1,1)) < 8 then
--            MAIL_BODY :=' No Data Found To Process.';
--            MAIL_BODY1 :=MAIL_BODY;
--         else
--             MAIL_BODY :=MAIL_BODY ||chr(13)||chr(10)||  STRSTRING1;
--             MAIL_BODY1:=MAIL_BODY1 ||chr(13)||chr(10)|| STRSTRING1;
--         end if;
--   varoperation:='Check if the PO number already came form SAP if Yes then update';
--  
--      MERGE INTO TRTRAN002 a USING (
--               SELECT   CONTRACT_NUMBER, BANK_REFERENCE,
--                         BANK_NAME, CURRENCY,VENDOR,
--                        LC_NUMBER,DUE_DATE, ACCEPTANCE_AMOUNT,Category_code, PO_NUMBER,
--                        sub_Category_code,APPROVAL_DATE,TRANSFER_DATE,DOCUMENT_NUMBER
--                  FROM  TOILNK.TRSYSTEM802 INNER JOIN TRSYSTEM052 
--                    ON MATERIALTYPE=nvl(CATEGORY_CD, 'SER')where   substr(DUE_DATE,1,2) = '20' ) SYNVTE  
--        ON   (A.TRAD_TRADE_REMARKS = SYNVTE.PO_NUMBER and A.TRAD_product_description=SYNVTE.DOCUMENT_NUMBER and nvl(A.TRAD_USER_REFERENCE, nvl(A.TRAD_LC_BENEFICIARY,0))=nvl(SYNVTE.BANK_REFERENCE, nvl(SYNVTE.LC_NUMBER,0))) 
--        
--      WHEN MATCHED THEN
--           UPDATE  SET A.TRAD_COMPANY_CODE=30100001,a.TRAD_CONTRACT_NO=nvl(SYNVTE.CONTRACT_NUMBER,SYNVTE.po_number),
----                  A.TRAD_USER_REFERENCE=SYNVTE.BANK_REFERENCE,
--                  A.TRAD_IMPORT_EXPORT=25900077,
--                  A.TRAD_LOCAL_BANK=PKGSAPINTERFACE.FNCGETPICKCODE(306,SYNVTE.BANK_NAME),
--                  A.TRAD_TRADE_CURRENCY=PKGSAPINTERFACE.FNCGETPICKCODE(304,SYNVTE.CURRENCY),  
--                  A.TRAD_BUYER_SELLER=PKGSAPINTERFACE.FNCGETPICKCODE(305,SUBSTR(SYNVTE.VENDOR,3,LENGTH(SYNVTE.VENDOR))),
--                  --A.TRAD_LC_BENEFICIARY=SYNVTE.LC_NUMBER,
--                  A.TRAD_MATURITY_FROM=TO_CHAR(TO_DATE(SYNVTE.DUE_DATE,'yyyymmdd'),'dd-MON-yyyy'),
--                  A.TRAD_MATURITY_DATE=TO_CHAR(TO_DATE(SYNVTE.DUE_DATE,'yyyymmdd'),'dd-MON-yyyy'),
--                  A.TRAD_TRADE_FCY=NVL(SYNVTE.ACCEPTANCE_AMOUNT,0),A.TRAD_TRADE_RATE=0,
--                  A.TRAD_TRADE_INR=0,A.TRAD_PRODUCT_CATEGORY=SYNVTE.Category_code,
--                  A.TRAD_SUBPRODUCT_CODE=SYNVTE.SUB_CATEGORY_CODE,
--                  A.TRAD_ENTRY_DATE=TO_CHAR(TO_DATE(SYNVTE.APPROVAL_DATE,'yyyymmdd'),'dd-MON-yyyy'),
--                  A.TRAD_REFERENCE_DATE=TO_CHAR(TO_DATE(SYNVTE.APPROVAL_DATE,'yyyymmdd'),'dd-MON-yyyy'),
--                  A.TRAD_CREATE_DATE=TO_CHAR(TO_DATE(SYNVTE.TRANSFER_DATE,'yyyymmdd'),'dd-MON-yyyy'),
--                  A.TRAD_VOYAGE='FROMSYN' --, A.TRAD_PRODUCT_DESCRIPTION=SYNVTE.DOCUMENT_NUMBER,
--                 -- A.TRAD_RECORD_STATUS=10200005, A.TRAD_PROCESS_COMPLETE=12400002 
--            where a.trad_process_complete = 12400002 and a.trad_record_Status =10200005
--      when not matched then
--                insert (TRAD_COMPANY_CODE,TRAD_TRADE_REFERENCE,
--                        TRAD_CONTRACT_NO,TRAD_USER_REFERENCE,trad_import_export,
--                        trad_local_bank,TRAD_TRADE_CURRENCY, 
--                        TRAD_BUYER_SELLER,TRAD_LC_BENEFICIARY,trad_maturity_from,
--                        TRAD_MATURITY_DATE,TRAD_TRADE_FCY,trad_trade_rate,
--                        trad_trade_inr,TRAD_PRODUCT_CATEGORY,
--                        TRAD_SUBPRODUCT_CODE,trad_entry_date,trad_reference_date,
--                        trad_create_date,TRAD_VOYAGE,
--                        TRAD_PRODUCT_DESCRIPTION,TRAD_RECORD_STATUS, TRAD_TRADE_REMARKS,
--                        TRAD_PROCESS_COMPLETE) VALUES(
--                        30100001,'BCCL/PURORD/' || PKGGLOBALMETHODS.FNCGENERATESERIAL(10900015),
--                        NVL(SYNVTE.CONTRACT_NUMBER,SYNVTE.PO_NUMBER),
--                        SYNVTE.BANK_REFERENCE,25900077,
--                        PKGSAPINTERFACE.FNCGETPICKCODE(306,SYNVTE.BANK_NAME),
--                        PKGSAPINTERFACE.FNCGETPICKCODE(304,SYNVTE.CURRENCY),
--                        PKGSAPINTERFACE.FNCGETPICKCODE(305,SUBSTR(SYNVTE.VENDOR,3,LENGTH(SYNVTE.VENDOR))),
--                        SYNVTE.LC_NUMBER,
--                        TO_CHAR(TO_DATE(SYNVTE.DUE_DATE,'yyyymmdd'),'dd-MON-yyyy'),
--                        TO_CHAR(TO_DATE(SYNVTE.DUE_DATE,'yyyymmdd'),'dd-MON-yyyy'),
--                        NVL(SYNVTE.ACCEPTANCE_AMOUNT,0), 0,0,
--                        SYNVTE.CATEGORY_CODE,SYNVTE.SUB_CATEGORY_CODE,
--                        TO_CHAR(TO_DATE(SYNVTE.APPROVAL_DATE,'yyyymmdd'),'dd-MON-yyyy'),
--                        TO_CHAR(TO_DATE(SYNVTE.APPROVAL_DATE,'yyyymmdd'),'dd-MON-yyyy'),
--                        TO_CHAR(TO_DATE(SYNVTE.TRANSFER_DATE,'yyyymmdd'),'dd-MON-yyyy'),'FROMSYN',
--                        SYNVTE.DOCUMENT_NUMBER,10200005,SYNVTE.po_number,12400002) ;
--       
--          
--
--             
--               numInsertedRows :=sql%rowcount;
--            
--       
--   varoperation:='details of Synnovate records from Archive table';
--    
-- /*  DELETE FROM TOILNK.TRSYSTEM802_ARCHIVE
--       where (transfer_date,DOCUMENT_NUMBER) in ( select distinct transfer_date ,DOCUMENT_NUMBER from toilnk.trsystem802); */
--
--     insert into trsystem802_archive(DATA_EXCEPTIONS,IBS_DB_TRANSFERDATE,IBS_DB_TRANSFERTIME_STAMP,
--                           DOCUMENT_NUMBER,CONTRACT_NUMBER,SERIAL_NUMBER,PO_NUMBER,VENDOR,PO_AMOUNT,
--                           ACCEPTANCE_AMOUNT,COUNT_AC_AMT,BANK_REFERENCE,STATUS,VENDOR_NAME,
--                           CATEGORY_CD,SUB_CAT,LC_NUMBER,CURRENCY,BANK_NAME,TRAN_TIME_STAMP,
--                           APPROVAL_DATE,TRANSFER_DATE,DUE_DATE)
--                           
--     select '12400001',SYSDATE,to_char(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'),DOCUMENT_NUMBER,
--             CONTRACT_NUMBER,SERIAL_NUMBER,PO_NUMBER,VENDOR,PO_AMOUNT,
--             ACCEPTANCE_AMOUNT,COUNT_AC_AMT,BANK_REFERENCE,STATUS,VENDOR_NAME,
--             CATEGORY_CD,SUB_CAT,LC_NUMBER,CURRENCY,BANK_NAME,TRAN_TIME_STAMP,
--             APPROVAL_DATE,TRANSFER_DATE,DUE_DATE
--             FROM TOILNK.TRSYSTEM802 where   substr(DUE_DATE,1,2) = '20' ;
--             
--        insert into toilnk.TRSYSTEM802_EXCEPTION(DATA_EXCEPTIONS,IBS_DB_TRANSFERDATE,IBS_DB_TRANSFERTIME_STAMP,
--                           DOCUMENT_NUMBER,CONTRACT_NUMBER,SERIAL_NUMBER,PO_NUMBER,VENDOR,PO_AMOUNT,
--                           ACCEPTANCE_AMOUNT,COUNT_AC_AMT,BANK_REFERENCE,STATUS,VENDOR_NAME,
--                           CATEGORY_CD,SUB_CAT,LC_NUMBER,CURRENCY,BANK_NAME,TRAN_TIME_STAMP,
--                           APPROVAL_DATE,TRANSFER_DATE,DUE_DATE)
--                           
--     select substr(VARERROR,1,500),SYSDATE,to_char(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'),DOCUMENT_NUMBER,
--             CONTRACT_NUMBER,SERIAL_NUMBER,PO_NUMBER,VENDOR,PO_AMOUNT,
--             ACCEPTANCE_AMOUNT,COUNT_AC_AMT,BANK_REFERENCE,STATUS,VENDOR_NAME,
--             CATEGORY_CD,SUB_CAT,LC_NUMBER,CURRENCY,BANK_NAME,TRAN_TIME_STAMP,
--             APPROVAL_DATE,TRANSFER_DATE,DUE_DATE
--             FROM TOILNK.TRSYSTEM802 where   substr(DUE_DATE,1,2) <> '20';
--    
--   
--
--     
--     varoperation:='details of Synnovate records from Archive table';
--          
--         
--     insert into toilnk.trsystem900 (SAPI_PROCESS_DATE,SAPI_DATA_TYPE,SAPI_TOTAL_ROWS,SAPI_INSERTED_ROWS,
--                              SAPI_UPDATED_ROWS,SAPI_DELETED_ROWS,SAPI_TOT_PROCESSED_ROWS,
--                              SAPI_SYSTEM_DATE,SAPI_RECORD_STATUS)
--                  
--      select TO_DATE(SYSDATE,'yyyy-mm-dd') ,'FROM SYN', COUNT(*) TOTALROWS,0,0,0,numInsertedRows,SYSTIMESTAMP,10200001
--            FROM TOILNK.TRSYSTEM802 ;
--
--     delete from toilnk.trsystem802;
--     
--     commit;
--  
--    VAROPERATION:='Sending Auto Generated mail Synnovate records';
----    UTL_MAIL.SEND(SENDER     => MAIL_FROM ,--'prasanta.panda@ibsfintech.com',
----                RECIPIENTS => MAIL_TO ,
----                CC         => mail_CC ,
----                BCC        => MAIL_BCC, 
----                SUBJECT    => 'Synnovate Process Completed Sucessfully as on '|| Sysdate ,
----                MESSAGE    => mail_body ) ; 
--    
--exception 
--WHEN OTHERS THEN
--   ROLLBACK;
--   NUMERROR := SQLCODE;
--   varError := SQLERRM;
--    insert into toilnk.TRSYSTEM802_EXCEPTION(DATA_EXCEPTIONS,IBS_DB_TRANSFERDATE,IBS_DB_TRANSFERTIME_STAMP,
--                           DOCUMENT_NUMBER,CONTRACT_NUMBER,SERIAL_NUMBER,PO_NUMBER,VENDOR,PO_AMOUNT,
--                           ACCEPTANCE_AMOUNT,COUNT_AC_AMT,BANK_REFERENCE,STATUS,VENDOR_NAME,
--                           CATEGORY_CD,SUB_CAT,LC_NUMBER,CURRENCY,BANK_NAME,TRAN_TIME_STAMP,
--                           APPROVAL_DATE,TRANSFER_DATE,DUE_DATE)
--                           
--     select substr(VARERROR,1,500),SYSDATE,to_char(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'),DOCUMENT_NUMBER,
--             CONTRACT_NUMBER,SERIAL_NUMBER,PO_NUMBER,VENDOR,PO_AMOUNT,
--             ACCEPTANCE_AMOUNT,COUNT_AC_AMT,BANK_REFERENCE,STATUS,VENDOR_NAME,
--             CATEGORY_CD,SUB_CAT,LC_NUMBER,CURRENCY,BANK_NAME,TRAN_TIME_STAMP,
--             APPROVAL_DATE,TRANSFER_DATE,DUE_DATE
--             FROM TOILNK.TRSYSTEM802;
--
--       DELETE FROM TOILNK.TRSYSTEM802;
--      COMMIT; 
--    
----     UTL_MAIL.SEND(SENDER     => mail_FROM ,--'prasanta.panda@ibsfintech.com',
----                RECIPIENTS =>MAIL_TO ,
----                CC         => mail_CC ,
----                BCC        => MAIL_BCC, 
----                SUBJECT    => 'Synnovate Auto Schedule Process failed as on '|| Sysdate ,
----                MESSAGE    => MAIL_BODY1 ) ;
--      
--    
--  
--   varError := GConst.fncReturnError('Synnovate Data', numError, varMessage, 
--                                                                  VAROPERATION, VARERROR);
--   raise_application_error(-20101, varError); 
--   
--end PrcPushDataFrmSynnovate;   
--       
       
 function  fncGetPickCode(KeyGroup in number, SapCode in varchar2)
      
      return number 
      as
     
      numError            number; 
      numKeyValue         number(8);   
      varOperation        GConst.gvarOperation%Type;
      varMessage          GConst.gvarMessage%Type;
      varError            GConst.gvarError%Type;

    begin 
      
     varMessage := 'Extracting Pick Up Code  for Sap Code:' || SapCode || ' And ' || KeyGroup;
     numKeyValue := 0;
     numError := 0;
     
     varOperation := 'Extracting Pik-up-code from Pickup Master';
     
     Begin
         select pick_key_value 
         into numKeyValue
         from trmaster001
         where pick_key_group = KeyGroup
         and Pick_Sap_Code = UPPER(SapCode);
    Exception
      when no_data_found then
           numKeyvalue := KeyGroup || '99999' ;

    End;
   
   return numKeyValue;
   
         exception  When others then
            numError := SQLCODE;
            varError := SQLERRM;
            varError := GConst.fncReturnError('SapData', numError, varMessage, 
                                                                   varOperation, varError);
            raise_application_error(-20101, varError); 
   
   END  fncgetPickCode ;
       
 
 
 function fncgetFianacialYear(datDate in date) return varchar
 as
  temp varchar(10);
 begin
       if (to_char(datDate,'MM')<3) then
            temp:= to_char(to_number(to_char(datDate,'YY'))-1) || '-' || to_char(to_number(to_char(datDate,'YY'))-0);
        else
            temp:= to_char(to_number(to_char(datDate,'YY'))-0) || '-' || to_char(to_number(to_char(datDate,'YY')) +1);
       end if;
    return temp;
  end fncgetFianacialYear;


 function fncGenerateKeyNum(PONumber in varchar,
                            datDate in date) 
  return varchar
  as 
    temp varchar(25);
  begin 
     return 'PC' ||'/' || PONumber  || '/' ||
            fncgetFianacialYear(datDate);
             
  end fncGenerateKeyNum;
  
  
 function fncGetCalendarDate1(EffectiveDate date, CurrencyCode number, ForCurrency number) return date
as
  datTemp date;
begin
  select NVL(max(drat_effective_date), to_date('01-APR-2013'))
    into datTemp
    from trtran012
    where drat_currency_code = CurrencyCode
    and drat_for_currency = ForCurrency
    and NVL(drat_spot_bid,0) > 0
    and drat_effective_date <= EffectiveDate;
    
 return datTemp;
end;
-------
function fncgetcompanycode(companycode in number,numtype in number) 
 return number
 as
 numcompanycode number(15,4);
 begin
  if numtype=1 then
  
    select COMP_ERP_CODE 
      into numcompanycode 
      from trmaster301
      where COMP_COMPANY_CODE=companycode
        and comp_record_status not in (10200005,10200006);
        
  elsif numtype=2 then
  
     select company_code 
      into numcompanycode 
      from trtran008D
      where SRNO=companycode ;  
      
  elsif numtype=3 then
  
      select COMP_TAX_RATE 
        into numcompanycode 
        from trmaster301
        where COMP_COMPANY_CODE=companycode
          and comp_record_status not in (10200005,10200006);
  end if;
  return nvl(numcompanycode,0);
 exception
 when others then
 RETURN 0;
 end fncgetcompanycode;
  function fncGetCounterpartyName(
                  varreference in varchar,
                   AccountEvent in number)
                return varchar
   is
     varTemp varchar(30);
   begin
      varTemp:='';
 --         EVENTFIXEDACCRUAL       CONSTANT number(8) := 24800032;
 --   EVENTFIXEDCLOSURE       CONSTANT number(8) := 24800036;

      if (AccountEvent = Gconst.EVENTMUTUALFUND) then
          SELECT pkgreturncursor.fncgetdescription(mfsc_amc_code,2)
             into vartemp
          FROM TRTRAN048 inner join trmaster404
            on mftr_scheme_code= mfsc_scheme_code
        WHERE MFTR_REFERENCE_NUMBER = varreference
          AND MFTR_RECORD_STATUS not in (10200005,10200006);
      elsif (AccountEvent in ( Gconst.EVENTMUTUALFUNDREDEM, gconst.EVENTMUTUALFUNDSWITCH)) then
          SELECT pkgreturncursor.fncgetdescription(mfsc_amc_code,2)
             into vartemp
          FROM TRTRAN049 inner join trmaster404
            on mfcl_scheme_code= mfsc_scheme_code
          WHERE MFcl_REFERENCE_NUMBER = varreference
          AND MFcl_RECORD_STATUS not in (10200005,10200006);
      elsif (AccountEvent in ( Gconst.EVENTFIXED, gconst.EVENTFIXEDCLOSURE ,gconst.EVENTFIXEDACCRUAL,GCONST.EVENTFDRENEW)) then
           SELECT pkgreturncursor.fncgetdescription(fdrf_Local_bank,2)
                 into vartemp
              FROM TRTRAN047
            WHERE fdrf_fd_NUMBER = varreference
             and fdrf_sr_number=(select max(fdrf_sr_number) from trtran047 where
                fdrf_fd_NUMBER = varreference AND fdrf_RECORD_STATUS not in (10200005,10200006))
              AND fdrf_RECORD_STATUS not in (10200005,10200006);
        elsif AccountEvent in ( 24800039,24800040,24800041,24800042) then
           select MDEL_USER_REFERENCE into vartemp
            from trtran031
            where MDEL_DEAL_NUMBER=varreference
            and  mdel_record_status between 10200001 and 10200004 ;

        end if;
    return varTemp;
   end fncGetCounterpartyName;

  function fncGetSchemeNavCode( varreference in varchar,numevent in number ,numcrdr in number )
                return varchar2
   is
     varNAVCode varchar(30);
   begin
  if numevent =24800033 then
        SELECT mftr_nav_code--mfsc_nav_code
             into varNAVCode
          FROM TRTRAN048 --inner join trmaster404
          --  on mftr_scheme_code= mfsc_scheme_code
        WHERE MFtr_REFERENCE_NUMBER = varreference
          AND MFtr_RECORD_STATUS = 10200003;

  elsif numevent in (24800037,24800038) then
        SELECT mfcl_nav_code--mfsc_nav_code
             into varNAVCode
          FROM TRTRAN049 --inner join trmaster404
          --  on mftr_scheme_code= mfsc_scheme_code
        WHERE MFcl_REFERENCE_NUMBER = varreference
          AND MFcl_RECORD_STATUS = 10200003;

--   elsif numevent =24800038 then
--     if numcrdr=14600002 then   --switch in
--         SELECT mfsc_nav_code
--               into varNAVCode
--            FROM TRTRAN049 inner join trmaster404
--              on MFCL_SWITCHIN_SCHEME= mfsc_scheme_code
--          WHERE MFcl_REFERENCE_NUMBER = varreference
--            AND MFcl_RECORD_STATUS = 10200003;
--    else
--
--          SELECT mfcl_nav_code--mfsc_nav_code
--             into varNAVCode
--          FROM TRTRAN049 --inner join trmaster404
--          --  on mftr_scheme_code= mfsc_scheme_code
--        WHERE MFcl_REFERENCE_NUMBER = varreference
--          AND MFcl_RECORD_STATUS = 10200003;
--     end if;
  end if;
    return varNAVCode;
   end fncGetSchemeNavCode;

  function fncgetAccountCode(
                  LocalBank in number,
                  AccountType in number,
                  AccountEvent in number,
                  VoucherReference in varchar,
                  numcrdr in number)
           return varchar
  is
     numSchemeCategory number(8);
     varFinanceCode varchar(50);
     Numinvesttype number(8);
  begin
      if AccountType =24900030 then --current a/c
         begin
           select cmap_finance_code
             into varFinanceCode from trtran008f
            where CMAP_SCHEME_CATEGORY=42099998
              and cmap_local_bank=LocalBank
              and cmap_account_type=AccountType
              and cmap_account_event =43599999;


          exception
            when no_data_found then
             
            
             if AccountEvent= gconst.EVENTFIXEDCLOSURE then
             
                 select cmap_finance_code
                 into varFinanceCode from trtran008f
                 where CMAP_SCHEME_CATEGORY=42099998
                  and cmap_local_bank=(select LBNK_PICK_CODE  from trmaster306 where LBNK_ACCOUNT_NUMBER=
                  (select fdcl_credit_acno from trtran047a where fdcl_fd_number= VoucherReference and FDCL_CLOSURE_SRNO=
                  (select max(FDCL_CLOSURE_SRNO) from trtran047a b where b.fdcl_fd_number= VoucherReference and b.fdcl_record_status=10200003 )))
                  and cmap_account_type=AccountType
                  and cmap_account_event =43599999;
               else
               
                 select cmap_finance_code
                 into varFinanceCode from trtran008f
                 where CMAP_SCHEME_CATEGORY=42099998
                  and cmap_local_bank=(select nvl(FDRF_UTR_BANK,30699999) from trtran047 where fdrf_fd_number= VoucherReference and FDRF_SR_NUMBER=1)
                  and cmap_account_type=AccountType
                  and cmap_account_event =43599999;
                  
              end if;
          end ;
          return varFinanceCode;
      end if;

      if (AccountEvent = Gconst.EVENTMUTUALFUND) then
          SELECT mfsc_scheme_category
             into numSchemeCategory
          FROM TRTRAN048 inner join trmaster404
            on mftr_scheme_code= mfsc_scheme_code
        WHERE MFTR_REFERENCE_NUMBER = VoucherReference
          AND MFTR_RECORD_STATUS not in (10200005,10200006);
      elsif (AccountEvent =Gconst.EVENTMUTUALFUNDREDEM) then
         SELECT mfsc_scheme_category
          into numSchemeCategory
         FROM TRTRAN049 inner join trmaster404
            on mfcl_scheme_code= mfsc_scheme_code
        WHERE MFcl_REFERENCE_NUMBER = VoucherReference
          AND MFcl_RECORD_STATUS not in (10200005,10200006);
       elsif (AccountEvent =Gconst.EVENTMUTUALFUNDSWITCH) then
          if numcrdr =14600001 then  --credit
               SELECT mfsc_scheme_category
                into numSchemeCategory
               FROM TRTRAN049 inner join trmaster404
                  on MFCL_SCHEME_code = mfsc_scheme_code
              WHERE MFcl_REFERENCE_NUMBER = VoucherReference
                AND MFcl_RECORD_STATUS not in (10200005,10200006);
          else
              SELECT mfsc_scheme_category
                into numSchemeCategory
               FROM TRTRAN049 inner join trmaster404
                  on MFCL_SWITCHIN_SCHEME = mfsc_scheme_code
              WHERE MFcl_REFERENCE_NUMBER = VoucherReference
                AND MFcl_RECORD_STATUS not in (10200005,10200006);
          end if;
     -- else
      --    numSchemeCategory := 42099998;
      end if;
  IF AccountEvent IN (Gconst.EVENTMUTUALFUND,Gconst.EVENTMUTUALFUNDREDEM,Gconst.EVENTMUTUALFUNDSWITCH) THEN
      begin
           select cmap_finance_code
             into varFinanceCode from trtran008f
            where CMAP_SCHEME_CATEGORY=numSchemeCategory
            --  and cmap_local_bank=LocalBank
              and cmap_account_type=AccountType
              and cmap_account_event =43500002;
       exception
          when no_data_found then

             select cmap_finance_code
               into varFinanceCode from trtran008f
              where CMAP_SCHEME_CATEGORY=42099998
                 and cmap_account_type=AccountType
                and cmap_account_event =43500002;
       end;
    ELSE
        IF AccountEvent IN ( Gconst.EVENTFIXED, gconst.EVENTFIXEDCLOSURE ,gconst.EVENTFIXEDACCRUAL,GCONST.EVENTFDRENEW) THEN
            Numinvesttype:=43500001;
        ELSIF AccountEvent IN (24800039,24800040) then
            Numinvesttype:=43500003;
        ELSIF AccountEvent IN (24800041,24800042) then
            Numinvesttype:=43500004 ;
        END IF;

        begin
             select cmap_finance_code
             into varFinanceCode from trtran008f
             where cmap_local_bank=LocalBank
              and cmap_account_type=AccountType
              and cmap_account_event =Numinvesttype;
         exception
          when no_data_found then
              select cmap_finance_code
             into varFinanceCode from trtran008f
             where cmap_local_bank=30699999
              and cmap_account_type=AccountType
              and cmap_account_event =Numinvesttype;
         end ;
    END IF;
    return varFinanceCode;
 exception
 when others then
 return 0;
  end fncgetAccountCode;




 procedure prcCurrentACInterface(
                  datParmDate in date := null)
    as
        numError            number;
        varOperation        varchar(2000);
        varMessage          varchar(100);
        varError            varchar(4000);
        numSrNo             number(8);
        numReceptNumber     number(5);
        datWorkDate         date;

    begin
        varMessage:= ' Populate Current Account interface staging table';




        if (datParmDate is null) then
            datWorkDate :=TRUNC(sysdate,'DD');
        else
            datWorkDate:= datParmDate;
        end if;

        varoperation := 'Delete the transactions from the Main table incase of any for the given date';

        delete from trtran008d
          where CreateDate=datWorkDate;

        varOperation:= 'Get the Max Serial Number';
        begin
          select max(SrNo)
            into numSrNo
          from trtran008D;
        exception
          when no_data_found then
            numSrNo:=0;
        end;


        select decode(numSrNo,null,0,numSrNo)
          into numSrNo
          from dual;

        varOperation:= 'Populating the new trasaction into the table';
        insert into trtran008D
                         (CreateDate,VoucherNumber,  SrNo ,	REVERSAL_RECEIPT_NUMBER ,
                         Status ,RECEIPT_NUMBER , LineNumber,
                         RECEIPT_DATE ,GL_DATE,GLName ,DEBIT_CREDIT_FLAG ,
                         RECEIPT_AMOUNT	,RECEIVABLE_ACTIVITY, ACCOUNT_CODE,BANK_NAME,
                         BRANCH_NAME,IFSC_CODE, BANK_ACCOUNT_NUMBER,CURRENCY_CODE,
                         EXCHANGE_RATE,EXCHANGE_DATE,RECORD_STATUS, ATTRIBUTE1,ATTRIBUTE2,
                         ATTRIBUTE3,LAST_UPDATED_BY,LAST_UPDATE_DATE,
                         LAST_UPDATE_LOGIN,CREATED_BY)

           select CreateDate,VoucherNumber, numSrNo+ SrNo ,	REVERSAL_RECEIPT_NUMBER ,
                         Status ,RECEIPT_NUMBER || '_' || to_char(nvl(UniqueNo,0)+RANK1) RECEIPT_NUMBER , LineNumber,
                         RECEIPT_DATE ,GL_DATE,GLName ,DEBIT_CREDIT_FLAG ,
                         RECEIPT_AMOUNT	,RECEIVABLE_ACTIVITY, ACCOUNT_CODE,BANK_NAME,
                         BRANCH_NAME,IFSC_CODE, BANK_ACCOUNT_NUMBER,CURRENCY_CODE,
                         EXCHANGE_RATE,EXCHANGE_DATE,RECORD_STATUS, ATTRIBUTE1,ATTRIBUTE2,
                         pkgsapinterface.fncgetusername(ATTRIBUTE3) ATTRIBUTE3 ,LAST_UPDATED_BY,LAST_UPDATE_DATE,
                         LAST_UPDATE_LOGIN,CREATED_BY
                from (select datWorkDate CREATEDATE ,bcac_voucher_number VoucherNumber,  rownum SRNO,null REVERSAL_RECEIPT_NUMBER,'N' Status,
                             bcac_voucher_reference RECEIPT_NUMBER,
                             row_number() over (partition by bcac_voucher_reference,bcac_voucher_date,bcac_voucher_type order by bcac_voucher_number) LINENUMBER,
                             DENSE_RANK() OVER( partition by bcac_voucher_reference ORDER BY bcac_voucher_reference,bcac_voucher_date, bcac_voucher_type) RANK1,
                             bcac_voucher_date RECEIPT_DATE ,bcac_voucher_date GL_DATE,fncGetCounterpartyName(bcac_voucher_reference,bcac_voucher_type) GLName,
                             decode(bcac_crdr_code,14600001,'CR','DR') DEBIT_CREDIT_FLAG,
                             bcac_voucher_inr RECEIPT_AMOUNT, pkgreturncursor.fncgetdescription(bcac_voucher_type,1) RECEIVABLE_ACTIVITY,
                             fncgetAccountCode(bcac_local_bank,bcac_account_head,bcac_voucher_type,bcac_voucher_reference,bcac_crdr_code) ACCOUNT_CODE,
                             decode(bcac_record_type,23800002,pkgsapinterface.fncgetcurrentacdetails(bcac_voucher_type,bcac_voucher_reference,BCAC_ACCOUNT_NUMBER,1),null) BANK_NAME,
                             decode(bcac_record_type,23800002,pkgsapinterface.fncgetcurrentacdetails(bcac_voucher_type,bcac_voucher_reference,BCAC_ACCOUNT_NUMBER,2),null) BRANCH_NAME,
                             decode(bcac_record_type,23800002,pkgsapinterface.fncgetcurrentacdetails(bcac_voucher_type,bcac_voucher_reference,BCAC_ACCOUNT_NUMBER,3),null) IFSC_CODE,
                             decode(bcac_record_type,23800002,pkgsapinterface.fncgetcurrentacdetails(bcac_voucher_type,bcac_voucher_reference,BCAC_ACCOUNT_NUMBER,4),null) BANK_ACCOUNT_NUMBER,

                             pkgreturncursor.fncgetdescription(bcac_voucher_currency,2) CURRENCY_CODE,
                             decode(bcac_voucher_currency,Gconst.INDIANRUPEE,1,bcac_voucher_rate) EXCHANGE_RATE,
                             bcac_voucher_date EXCHANGE_DATE,
                             'P' RECORD_STATUS,null,
                             pkgsapinterface.fncgetinvestmenttype(bcac_voucher_type) ATTRIBUTE1,
                             (case when bcac_voucher_type in (24800033,24800037,24800038) then
                                  fncGetSchemeNavCode(bcac_voucher_reference,bcac_voucher_type,bcac_crdr_code)
                                  else bcac_voucher_reference end) ATTRIBUTE2,
                                  pkgglobalmethods.fncXMLExtract(nvl(bcac_entry_detail,xmltype(xmlElement("AuditTrails" , xmlElement("AuditTrail" ,
                                  XmlForest( 'ADDSAVE' as "Process" ,  'admin' as "UserName" ))).getclobval())) ,'UserName','UserName',1) ATTRIBUTE3,
                             -1 LAST_UPDATED_BY,null LAST_UPDATE_DATE, null LAST_UPDATE_LOGIN, -1 CREATED_BY
                       from trtran008 ---left outer join trmaster306
                       --  on bcac_local_bank= lbnk_pick_code
                      where trunc(bcac_add_date) = trunc(datWorkDate)
                       and bcac_record_status =10200003
                      -- and trunc(bcac_create_date) = trunc(datWorkDate)
                       ) CA left outer join
                      (select Attribute2 voucherreference,nvl(Count(*),0) UniqueNo
                        from trtran008D
                        where LineNumber=1
                        group by Attribute2 ) NG
                      on ca.RECEIPT_NUMBER=ng.voucherreference;

--          varOperation:= 'Inserting Zero Records for Switch in';
--          begin
--              select max(SrNo)
--                into numSrNo
--              from trtran008D;
--            exception
--              when no_data_found then
--                numSrNo:=0;
--            end;
--          for recswitchdata in ( select a.* from trtran008d a where a.srno in
--          (select b.srno from trtran008d b where a.RECEIVABLE_ACTIVITY=b.RECEIVABLE_ACTIVITY
--                  and a.srno=b.srno and a.RECEIPT_NUMBER=b.RECEIPT_NUMBER
--                 and b.LINENUMBER= (select  min(c.LINENUMBER) from trtran008d c
--                                                where c.RECEIVABLE_ACTIVITY ='MF_Switching'
--                                                and b.RECEIPT_NUMBER=c.RECEIPT_NUMBER))
--                 and a.createdate=datWorkDate)
--          loop
--                numSrNo:=numSrNo+1;
--                 insert into trtran008d  (CreateDate,VoucherNumber,  SrNo ,	REVERSAL_RECEIPT_NUMBER ,
--                         Status ,RECEIPT_NUMBER , LineNumber,
--                         RECEIPT_DATE ,GL_DATE,GLName ,DEBIT_CREDIT_FLAG ,
--                         RECEIPT_AMOUNT	,RECEIVABLE_ACTIVITY, ACCOUNT_CODE,BANK_NAME,
--                         BRANCH_NAME,IFSC_CODE, BANK_ACCOUNT_NUMBER,CURRENCY_CODE,
--                         EXCHANGE_RATE,EXCHANGE_DATE,RECORD_STATUS, ATTRIBUTE1,ATTRIBUTE2,
--                         ATTRIBUTE3,LAST_UPDATED_BY,LAST_UPDATE_DATE,
--                         LAST_UPDATE_LOGIN,CREATED_BY) values
--
--                         (recswitchdata.CreateDate,'',  numSrNo  ,	recswitchdata.REVERSAL_RECEIPT_NUMBER ,
--                         recswitchdata.Status ,recswitchdata.RECEIPT_NUMBER ,recswitchdata.LineNumber + 1,
--                         recswitchdata.RECEIPT_DATE ,recswitchdata.GL_DATE,recswitchdata.GLName ,'DR', --recswitchdata.DEBIT_CREDIT_FLAG ,
--                         0	,recswitchdata.RECEIVABLE_ACTIVITY, '9999905','Accrual Account',
--                         'MF Swap Account','INT00000002', '00000000002',recswitchdata.CURRENCY_CODE,
--                         recswitchdata.EXCHANGE_RATE,recswitchdata.EXCHANGE_DATE,recswitchdata.RECORD_STATUS,
--                         recswitchdata.ATTRIBUTE1,recswitchdata.ATTRIBUTE2,
--                         recswitchdata.ATTRIBUTE3,recswitchdata.LAST_UPDATED_BY,recswitchdata.LAST_UPDATE_DATE,
--                         recswitchdata.LAST_UPDATE_LOGIN,recswitchdata.CREATED_BY);
--
--
--          end loop;
--
            varOperation:= 'Get the Max Serial Number For Edit';
            begin
              select max(SrNo)
                into numSrNo
              from trtran008D;
            exception
              when no_data_found then
                numSrNo:=0;
            end;
          varOperation:= 'Populating the Edit trasaction into the table';

          insert into trtran008D
                         (CreateDate,VoucherNumber,  SrNo ,	REVERSAL_RECEIPT_NUMBER ,
                         Status ,RECEIPT_NUMBER , LineNumber,
                         RECEIPT_DATE ,GL_DATE,GLName ,DEBIT_CREDIT_FLAG ,
                         RECEIPT_AMOUNT	,RECEIVABLE_ACTIVITY, ACCOUNT_CODE,BANK_NAME,
                         BRANCH_NAME,IFSC_CODE, BANK_ACCOUNT_NUMBER,CURRENCY_CODE,
                         EXCHANGE_RATE,EXCHANGE_DATE,RECORD_STATUS, ATTRIBUTE1,ATTRIBUTE2,
                         ATTRIBUTE3,LAST_UPDATED_BY,LAST_UPDATE_DATE,
                         LAST_UPDATE_LOGIN,CREATED_BY)

          select CreateDate,VoucherNumber, numSrNo+ SrNo ,	REVERSAL_RECEIPT_NUMBER1 ,
                         Status ,voucherreference1 || '_' || to_char(nvl(UniqueNo,0)+RANK1) RECEIPT_NUMBER , LineNumber,
                         RECEIPT_DATE ,GL_DATE,GLName ,DEBIT_CREDIT_FLAG ,
                         RECEIPT_AMOUNT	,RECEIVABLE_ACTIVITY, ACCOUNT_CODE,BANK_NAME,
                         BRANCH_NAME,IFSC_CODE, BANK_ACCOUNT_NUMBER,CURRENCY_CODE,
                         EXCHANGE_RATE,EXCHANGE_DATE,RECORD_STATUS, ATTRIBUTE1,ATTRIBUTE2,
                         ATTRIBUTE3,LAST_UPDATED_BY,LAST_UPDATE_DATE,
                         LAST_UPDATE_LOGIN,CREATED_BY
                from (    select datWorkDate CreateDate,VoucherNumber,  Rownum srno ,	RECEIPT_NUMBER REVERSAL_RECEIPT_NUMBER1 ,
                         'R' Status ,bcac_voucher_reference voucherreference1,   LineNumber,
                         DENSE_RANK() OVER(partition by bcac_voucher_reference ORDER BY bcac_voucher_reference,bcac_voucher_date, bcac_voucher_type) RANK1,
                         RECEIPT_DATE ,GL_DATE,GLName ,Decode(DEBIT_CREDIT_FLAG,'DR','CR','CR' ,'DR') DEBIT_CREDIT_FLAG ,
                         RECEIPT_AMOUNT	,RECEIVABLE_ACTIVITY, ACCOUNT_CODE,BANK_NAME,
                         BRANCH_NAME,IFSC_CODE, BANK_ACCOUNT_NUMBER,CURRENCY_CODE,
                         EXCHANGE_RATE,EXCHANGE_DATE,RECORD_STATUS, ATTRIBUTE1,ATTRIBUTE2,
                         ATTRIBUTE3,LAST_UPDATED_BY,LAST_UPDATE_DATE,
                         LAST_UPDATE_LOGIN,CREATED_BY
                from trtran008D inner join trtran008
                  on VoucherNumber= bcac_voucher_number
                   where bcac_record_status in (10200005)
                 and trunc(bcac_add_date) !=trunc(bcac_create_date)
                 and trunc(bcac_add_date) =datWorkDate) ca
                  left outer join (select Attribute2 voucherreference,nvl(Count(*),0)  UniqueNo
                        from trtran008D
                        where LineNumber=1
                        group by Attribute2 ) NG
                  on ca.voucherreference1=ng.voucherreference   ;





--           select datWorkDate,VoucherNumber,  numSrNo+Rownum ,	RECEIPT_NUMBER ,
--                         'R' Status ,voucherreference || '_' || to_char(nvl(UniqueNo,0)+ rank1) RECEIPT_NUMBER , LineNumber,
--                         RECEIPT_DATE ,GL_DATE,GLName ,DEBIT_CREDIT_FLAG ,
--                         RECEIPT_AMOUNT	,RECEIVABLE_ACTIVITY, ACCOUNT_CODE,BANK_NAME,
--                         BRANCH_NAME,IFSC_CODE, BANK_ACCOUNT_NUMBER,CURRENCY_CODE,
--                         EXCHANGE_RATE,EXCHANGE_DATE,RECORD_STATUS, ATTRIBUTE1,ATTRIBUTE2,
--                         ATTRIBUTE3,LAST_UPDATED_BY,LAST_UPDATE_DATE,
--                         LAST_UPDATE_LOGIN,CREATED_BY
--                from trtran008D inner join trtran008
--                  on VoucherNumber= bcac_voucher_number
--                  left outer join (select Attribute2 voucherreference,nvl(Count(*),0)  UniqueNo
--                        from trtran008D
--                        where LineNumber=1
--                        group by Attribute2 ) NG
--                  on trtran008D.ATTRIBUTE2=ng.voucherreference
--                where bcac_record_status in (10200005)
--                 and trunc(bcac_add_date) !=trunc(bcac_create_date)
--                 and trunc(bcac_add_date) =datWorkDate;

--          varOperation:= 'Get the Max Serial Number For Delete';
--          begin
--            select max(SrNo)
--              into numSrNo
--            from trtran008D;
--          exception
--            when no_data_found then
--              numSrNo:=0;
--          end;
--
--          varOperation:= 'Populating the Delete trasaction into the table';
--          insert into trtran008D
--                         (CreateDate,VoucherNumber,  SrNo ,	REVERSAL_RECEIPT_NUMBER ,
--                         Status ,RECEIPT_NUMBER , LineNumber,
--                         RECEIPT_DATE ,GL_DATE,GLName ,DEBIT_CREDIT_FLAG ,
--                         RECEIPT_AMOUNT	,RECEIVABLE_ACTIVITY, ACCOUNT_CODE,BANK_NAME,
--                         BRANCH_NAME,IFSC_CODE, BANK_ACCOUNT_NUMBER,CURRENCY_CODE,
--                         EXCHANGE_RATE,EXCHANGE_DATE,RECORD_STATUS, ATTRIBUTE1,ATTRIBUTE2,
--                         ATTRIBUTE3,LAST_UPDATED_BY,LAST_UPDATE_DATE,
--                         LAST_UPDATE_LOGIN,CREATED_BY)
--
--           select datWorkDate,VoucherNumber,  numSrNo+Rownum ,	RECEIPT_NUMBER ,
--                         'R' Status ,RECEIPT_NUMBER RECEIPT_NUMBER , LineNumber,
--                         RECEIPT_DATE ,GL_DATE,GLName ,DEBIT_CREDIT_FLAG ,
--                         RECEIPT_AMOUNT	,RECEIVABLE_ACTIVITY, ACCOUNT_CODE,BANK_NAME,
--                         BRANCH_NAME,IFSC_CODE, BANK_ACCOUNT_NUMBER,CURRENCY_CODE,
--                         EXCHANGE_RATE,EXCHANGE_DATE,RECORD_STATUS, ATTRIBUTE1,ATTRIBUTE2,
--                         ATTRIBUTE3,LAST_UPDATED_BY,LAST_UPDATE_DATE,
--                         LAST_UPDATE_LOGIN,CREATED_BY
--                from trtran008D inner join trtran008
--                  on VoucherNumber= bcac_voucher_number
--                where bcac_record_status in (10200006)
--                 and trunc(bcac_add_date) != trunc(bcac_create_date)
--                 and trunc(bcac_add_date) =datWorkDate;

           varOperation:= 'Truncate Staging table ';
           delete from  trtran008E;
           varOperation:= 'Populating the transactions into staging table';

           insert into trtran008E(SRNO , REVERSAL_RECEIPT_NUMBER,TYPE,RECEIPT_NUMBER,
                                  LINE_NUMBER,RECEIPT_DATE,GL_DATE,NAME ,
                                  DEBIT_CREDIT_FLAG,RECEIPT_AMOUNT,RECEIVABLE_ACTIVITY ,
                                  ACCOUNT_CODE ,BANK_NAME,BRANCH_NAME,IFSC_CODE ,
                                  BANK_ACCOUNT_NUMBER,CURRENCY_CODE,EXCHANGE_RATE,
                                  EXCHANGE_DATE,RECORD_STATUS,ATTRIBUTE1,
                                  ATTRIBUTE2,	ATTRIBUTE3,LAST_UPDATED_BY,
                                  LAST_UPDATE_DATE,LAST_UPDATE_LOGIN,CREATED_BY)
              select  SrNo ,	REVERSAL_RECEIPT_NUMBER ,  Status ,RECEIPT_NUMBER ,
                      LineNumber,RECEIPT_DATE ,GL_DATE,GLName ,
                      DEBIT_CREDIT_FLAG , RECEIPT_AMOUNT	,RECEIVABLE_ACTIVITY,
                      ACCOUNT_CODE,BANK_NAME,BRANCH_NAME,IFSC_CODE,
                      BANK_ACCOUNT_NUMBER,CURRENCY_CODE,EXCHANGE_RATE,
                      EXCHANGE_DATE,RECORD_STATUS, ATTRIBUTE1,ATTRIBUTE2,
                         ATTRIBUTE3,LAST_UPDATED_BY,LAST_UPDATE_DATE,
                         LAST_UPDATE_LOGIN,CREATED_BY
               from trtran008d
               where CreateDate= datWorkDate
           union all
             select  SRNO , REVERSAL_RECEIPT_NUMBER,TYPE,RECEIPT_NUMBER,
                                  LINE_NUMBER,RECEIPT_DATE,GL_DATE,NAME ,
                                  DEBIT_CREDIT_FLAG,RECEIPT_AMOUNT,RECEIVABLE_ACTIVITY ,
                                  ACCOUNT_CODE ,BANK_NAME,BRANCH_NAME,IFSC_CODE ,
                                  BANK_ACCOUNT_NUMBER,CURRENCY_CODE,EXCHANGE_RATE,
                                  EXCHANGE_DATE,RECORD_STATUS,ATTRIBUTE1,
                                  ATTRIBUTE2,	ATTRIBUTE3,LAST_UPDATED_BY,
                                  LAST_UPDATE_DATE,LAST_UPDATE_LOGIN,CREATED_BY
               from trtran008g
                where to_date(create_DATE)= datWorkDate;

               update trtran008g set process_date=datWorkDate where to_date(create_DATE)= datWorkDate;
      commit;
    exception
    when others then
    varError:=sqlerrm;
     raise_application_error(-20011 ,varError);

 end prcCurrentACInterface;

 function fncgetusername(varuserid in varchar2)
 return varchar2
 as
 varusername  varchar2(100);
 begin
  select user_user_name into varusername from trsystem022
    where user_user_id=varuserid and user_record_status not in (10200005,10200006);
  return varusername ;
 exception
 when others then
 return 'System';
 end;

function fncgetinvestmenttype(eventtype in number)
return varchar2
as
varinvestmenttype varchar2(100);
Numinvesttype number(8);
begin
if eventtype in (  Gconst.EVENTMUTUALFUND, Gconst.EVENTMUTUALFUNDREDEM, gconst.EVENTMUTUALFUNDSWITCH) then
  Numinvesttype:=43500002;
elsif eventtype in ( Gconst.EVENTFIXED, gconst.EVENTFIXEDCLOSURE ,gconst.EVENTFIXEDACCRUAL,GCONST.EVENTFDRENEW) THEN
   Numinvesttype:=43500001;
ELSIF eventtype IN (24800039,24800040) then
   Numinvesttype:=43500003;
ELSIF eventtype IN (24800041,24800042) then
   Numinvesttype:=43500004 ;
END IF;
varinvestmenttype:=pkgreturncursor.fncgetdescription(Numinvesttype ,1) ;
return varinvestmenttype ;

exception
when others then
 return 1;
end;

function fncgetcurrentacdetails(varevent in number,referencenumber in varchar2, varaccountnumber in varchar2,vartype in number)
return varchar2
as
varcurrentdetail varchar2(100);
varbankname varchar2(100);
varbranchname varchar2(100);
varifsccode varchar2(100);
varcurrentacnumber varchar2(25);
varacno varchar2(25);
varerrmsg varchar2(100);
begin
if varevent = 24800031 then
   case vartype
      when 1  then
          varcurrentdetail:='Accrual Account' ; ---bank name
      when 2 then
          varcurrentdetail:='Interest Accured on FD A/c' ; ---Branch name
      when 3 then
          varcurrentdetail:='INT00000001' ; ---IFSC Code
      else
         varcurrentdetail:='00000000001' ; ---current a/c number
   end case;
elsif  varevent = 24800032  then
   case vartype
      when 1  then
          varcurrentdetail:='Accrual Account' ; ---bank name
      when 2 then
          varcurrentdetail:='FD Renewal A/c' ; ---Branch name
      when 3 then
          varcurrentdetail:='INT00000003' ; ---IFSC Code
      else
         varcurrentdetail:='00000000003' ; ---current a/c number
   end case;
elsif  varevent = 24800038  then
   case vartype
      when 1  then
          varcurrentdetail:='INT00000002' ; ---bank name
      when 2 then
          varcurrentdetail:='MF Swap Account' ; ---Branch name
      when 3 then
          varcurrentdetail:='INT00000002' ; ---IFSC Code
      else
         varcurrentdetail:='00000000002' ; ---current a/c number
   end case;
 else
     --insert into temp values(varevent || ' '|| vartype,varcurrentacnumber); commit;
     if nvl(varaccountnumber,'0')='0' then
        
        if varevent in (24800030,24800032) then
          
           select fdrf_credit_acno into varacno from trtran047 where fdrf_fd_number=referencenumber
              and fdrf_sr_number =( select max(fdrf_sr_number) from trtran047 where fdrf_fd_number=referencenumber and fdrf_record_status not in (10200005,10200006))
              and fdrf_record_status not in (10200005,10200006);
       
       elsif varevent in (24800036) then
            
            select FDCL_CREDIT_ACNO into varacno from trtran047A where fdcl_fd_number=referencenumber
              and fdcl_sr_number =( select max(fdcl_sr_number) from trtran047A where fdcl_fd_number=referencenumber and fdcl_record_status not in (10200005,10200006))
              and fdcl_record_status not in (10200005,10200006);
              
        elsif varevent = 24800033 then --mf opening
             select mftr_current_ac into varacno from trtran048 where mftr_reference_number=referencenumber
              and  mftr_record_status not in (10200005,10200006);

        elsif varevent = 24800037 then --mf closing
            select mfcl_current_ac into varacno from trtran049 where mfcl_reference_number=referencenumber
              and  mfcl_record_status not in (10200005,10200006);


        elsif varevent in (24800039,24800040,24800041,24800042) then  ----cp/cd open/close
            select LBNK_ACCOUNT_NUMBER into varacno from trtran031,trmaster306 where
                 MDEL_LOCAL_BANK=LBNK_PICK_CODE
                 and MDEL_DEAL_NUMBER=referencenumber
                 and mdel_record_status between 10200001 and 10200004;

        end if;
     else
        varacno:=varaccountnumber;
     end if;

     select pkgreturncursor.fncgetdescription(LBNK_PICK_CODE,1),decode(referencenumber ,'', LBNK_ADDRESS_1,LBNK_short_DESCRIPTION) ,LBNK_IFSC_CODE,LBNK_ACCOUNT_NUMBER
       into varbankname,varbranchname ,varifsccode,varcurrentacnumber
      from trmaster306  where LBNK_ACCOUNT_NUMBER=varacno
       and LBNK_RECORD_STATUS not in (10200005,10200006);

     case vartype
      when 1  then

          varcurrentdetail:=varbankname ; ---bank name
      when 2 then
          varcurrentdetail:=varbranchname ; ---Branch name
      when 3 then
          varcurrentdetail:=varifsccode ; ---IFSC Code
      else
         varcurrentdetail:=varcurrentacnumber ; ---current a/c number
   end case;

 end if;
  return varcurrentdetail ;
exception
when others then
varerrmsg :=sqlerrm;
raise_application_error(-20001 ,varerrmsg);
  return 'error ' ;
end;

--end pkgSapInterface;

    procedure prcErrorinsertinto8G(
                 InSRNo in number,
                 Erro_msg in varchar,
                 datWorkDate in date)
    as
    begin

      if  (upper(Erro_msg) !='SUCCESS') then
        Insert into TRTRAN008G (SRNO,REVERSAL_RECEIPT_NUMBER,TYPE,
                    RECEIPT_NUMBER,LINE_NUMBER,RECEIPT_DATE,
                    GL_DATE,NAME,DEBIT_CREDIT_FLAG,RECEIPT_AMOUNT,
                    RECEIVABLE_ACTIVITY,ACCOUNT_CODE,BANK_NAME,
                    BRANCH_NAME,IFSC_CODE,BANK_ACCOUNT_NUMBER,
                    CURRENCY_CODE,EXCHANGE_RATE,EXCHANGE_DATE,
                    RECORD_STATUS,ERROR_MESSAGE,ATTRIBUTE1,ATTRIBUTE2,
                    ATTRIBUTE3,LAST_UPDATED_BY,LAST_UPDATE_DATE,LAST_UPDATE_LOGIN,
                    CREATED_BY,CREATION_DATE,CASH_RECEIPT_ID,RECEIPT_METHOD_ID,
                    ACTIVITY_ID,ERROR_DATE)
             select e.SRNO,e.REVERSAL_RECEIPT_NUMBER,e.TYPE,
                    e.RECEIPT_NUMBER,e.LINE_NUMBER,e.RECEIPT_DATE,
                    e.GL_DATE,e.NAME,e.DEBIT_CREDIT_FLAG,e.RECEIPT_AMOUNT,
                    e.RECEIVABLE_ACTIVITY,e.ACCOUNT_CODE,e.BANK_NAME,
                    e.BRANCH_NAME,e.IFSC_CODE,e.BANK_ACCOUNT_NUMBER,
                    e.CURRENCY_CODE,e.EXCHANGE_RATE,e.EXCHANGE_DATE,
                    e.RECORD_STATUS,Erro_msg,e.ATTRIBUTE1,e.ATTRIBUTE2,
                    e.ATTRIBUTE3,e.LAST_UPDATED_BY,e.LAST_UPDATE_DATE,e.LAST_UPDATE_LOGIN,
                    e.CREATED_BY,e.CREATION_DATE,e.CASH_RECEIPT_ID,e.RECEIPT_METHOD_ID,
                    e.ACTIVITY_ID,datWorkDate
              from trtran008E e
              where e.Srno=InSRNo ;
        end if;

      update trtran008D set ERROR_MESSAGE= Erro_msg where Srno = InSRNo;

    end prcErrorinsertinto8G;
  end pkgSapInterface;
/