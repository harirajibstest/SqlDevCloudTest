CREATE OR REPLACE PROCEDURE "TEST_VSTSRedgate"."PRCTFBILLSSETTLEMENT" 
    (   RecordDetail in GConst.gClobType%Type)
    as
--  created by TMM on 31/01/2014
    numError            number;
    numTemp             number;
    numAction           number(4);
    numSerial           number(5);
    numSub              number(5);
    numLocation         number(8);
    numCompany          number(8);
    numCurrency         number(8);
    numReversal         number(8);
    numBankCode         number(8);
    numTradeSerialNum   Number(5);
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
    NumCode             number(8);
    xmlTemp             xmlType;
    nlsTemp             xmlDom.DomNodeList;
    nodFinal            xmlDom.domNode;
    docFinal            xmlDom.domDocument;
    nodTemp             xmlDom.domNode;
    nodTemp1            xmlDom.domNode;
    nmpTemp             xmldom.domNamedNodemap;
    numRecordStatus     number(5);

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
    numLocation := GConst.fncXMLExtract(xmlTemp, 'LocationID', numLocation);
    numCompany := GConst.fncXMLExtract(xmlTemp, 'CompanyID', numCompany);

    datWorkDate := sysdate(); -- GConst.fncXMLExtract(xmlTemp, 'WorkDate', datWorkDate);
    numCompany := 30100001;
    
--    numCompany := GConst.fncXMLExtract(xmlTemp, 'BREL_COMPANY_CODE', numCompany);
--    varTradeReference := GConst.fncXMLExtract(xmlTemp, 'BREL_TRADE_REFERENCE', varTradeReference);
--    numSerial := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSE_SERIAL', numSerial);
--    numReversal := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_TYPE', numReversal);
--    datReference := GConst.fncXMLExtract(xmlTemp, 'BREL_REFERENCE_DATE', datReference);
--    numBillReverse := GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_FCY', numBillReverse);
--    numCashRate :=  GConst.fncXMLExtract(xmlTemp, 'BREL_REVERSAL_RATE', numCashRate);
    varCompany := pkgReturnCursor.fncGetDescription(numCompany,2);

    docFinal := xmlDom.newDomDocument(xmlTemp);
    nodFinal := xmlDom.makeNode(docFinal);

    --INSERT INTO TEMP vALUES (varentity,GConst.fncXMLExtract(xmlTemp, 'BREL_REALIZATION_NUMBER', numTradeSerialNum));
    if varentity='BILLREALIZATION' then 
      numTradeSerialNum:= GConst.fncXMLExtract(xmlTemp, 'BREL_REALIZATION_NUMBER', numTradeSerialNum);
    else
      numTradeSerialNum:=1;
    end if;
      

      varTemp := '//Deals/ReferenceNumber';
      varTradeReference := GConst.fncGetNodeValue(nodFinal, varTemp);
      
      varTemp := '//Deals/BuySell';
      NumCode := GConst.fncGetNodeValue(nodFinal, varTemp);
      
      varTemp := '//Deals/BankCode';
      numBankCode := GConst.fncGetNodeValue(nodFinal, varTemp);
      
        varTemp := '//Deals/CurrencyCode';
      numCurrency := GConst.fncGetNodeValue(nodFinal, varTemp);
      
     

    varOperation := 'Checking for Deal Delivery, if any';
    varXPath := '//Deals/ForwardDeals/ROWD[@NUM]';
    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);


        
  if xmlDom.getLength(nlsTemp) != 0 then

    varXPath := '//Deals/ForwardDeals/ROWD[@NUM="';
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
        varTemp := varXPath || numTemp || '"]/ReverseAmount';
        numReverseAmount := to_number(GConst.fncGetNodeValue(nodFinal, varTemp));
        numDealReverse := numDealReverse + numReverseAmount;

        varTemp := varXPath || numTemp || '"]/DealRecordStatus';
        numRecordStatus := Gconst.fncGetNodeValue(nodFinal, varTemp);
       
        if (numRecordStatus=2) and (numAction=104) then 
        
           delete from trtran006 
           where cdel_deal_number=varDealReference
              and cdel_trade_reference=varTradeReference
              and Cdel_Trade_Serial= numTradeSerialNum;
        
          delete from trtran004 
           where hedg_deal_number=varDealReference
             and hedg_trade_reference=varTradeReference
             and hedg_Trade_Serial= numTradeSerialNum;

           numAction:=102;
        elsif (numAction=102) then
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
              varVoucher := varCompany || '/VOC/' || GConst.fncGenerateSerial(Gconst.SERIALCURRENT);
              insert into trtran008 (bcac_company_code, bcac_location_code,
                bcac_local_bank, bcac_voucher_number, bcac_voucher_date, bcac_crdr_code,
                bcac_account_head, bcac_voucher_type, bcac_voucher_reference,
                bcac_reference_serial, bcac_voucher_currency, bcac_voucher_fcy,
                bcac_voucher_rate, bcac_voucher_inr, bcac_voucher_detail,
                bcac_create_date, bcac_local_merchant, bcac_record_status,
                bcac_record_type, bcac_account_number)
              select numCompany, numLocation, deal_counter_party, varVoucher,
                deal_maturity_date, decode(sign(numPandL), -1, GConst.TRANSACTIONDEBIT,
                GConst.TRANSACTIONCREDIT),GConst.ACEXCHANGE,
                decode(deal_buy_sell,GConst.PURCHASEDEAL,
                GConst.EVENTPURCHASE, GConst.EVENTSALE),
                deal_deal_number, 1, deal_base_currency, numReverseAmount,
                numFinal, Round(numReverseAmount *  numFinal), 'Deal Reversal No: ' ||
                deal_deal_number, sysdate,30999999,GConst.STATUSENTRY, 23800002,
                (select lbnk_account_number
                  from trmaster306
                  where lbnk_pick_code = deal_counter_party)
                from trtran001
                where deal_deal_number = varDealReference
                and deal_serial_number = 1;
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
                hedg_hedging_with,hedg_multiple_currency,Hedg_Trade_serial)
              values(numCompany,varTradeReference,varDealReference,
              1, numReverseAmount,0, Round(numReverseAmount * numFinal),
              sysdate,NULL,10200012, 32200001,12400002,numTradeSerialNum);
            End if;
    
            varOperation := 'Inserting Hedge Deal Delivery';
            insert into trtran006(cdel_company_code, cdel_deal_number,
              cdel_deal_serial, cdel_reverse_serial, cdel_cancel_date,
              cdel_deal_type, cdel_cancel_type, cdel_cancel_amount,
              cdel_cancel_rate, cdel_other_amount, cdel_local_rate,
              cdel_cancel_inr, cdel_time_stamp, cdel_create_date,
              cdel_entry_detail, cdel_record_status, cdel_trade_reference,
              Cdel_Trade_Serial, Cdel_Profit_Loss, Cdel_Pl_Voucher,
              cdel_spot_rate,cdel_forward_rate,cdel_margin_rate) -- Updated from Cygnet
              select deal_company_code, deal_deal_number,
              deal_serial_number,
              (select NVL(max(cdel_reverse_serial),0) + 1
                from trtran006
                where cdel_deal_number = varDealReference),
              datWorkdate, deal_hedge_trade, Gconst.Dealdelivery,
              numReverseAmount, numFinal, Round(numReverseAmount * numFinal), 1,
              Round(numReverseAmount * numFinal), to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
              Sysdate, Null, Gconst.Statusentry, varTradeReference, numTradeSerialNum, numPandL,
              varVoucher ,numSpot,numPremium,numMargin
              from trtran001
              where deal_deal_number = varDealReference;
       elsif (numAction=106) then
          update trtran006 set cdel_record_status=10200006
           where cdel_deal_number=varDealReference
              --cdel_deal_serial=
              and cdel_trade_reference=varTradeReference
              and Cdel_Trade_Serial= numTradeSerialNum;
        
          delete from trtran004 
           where hedg_deal_number=varDealReference
              --cdel_deal_serial=
              and hedg_trade_reference=varTradeReference
              and hedg_Trade_Serial= numTradeSerialNum;
       
        elsif (numAction=108) then
          update trtran006 set cdel_record_status=10200003
           where cdel_deal_number=varDealReference
              --cdel_deal_serial=
             and cdel_trade_reference=varTradeReference
              and Cdel_Trade_Serial= numTradeSerialNum;
        
          update trtran004 set hedg_record_status=10200003
           where hedg_deal_number=varDealReference
              --cdel_deal_serial=
             and hedg_trade_reference=varTradeReference
             and hedg_Trade_Serial= numTradeSerialNum;
      
       end if;
       
        numError := pkgmastermaintenance.fncCompleteUtilization(varDealReference,GConst.UTILHEDGEDEAL,datWorkDate);

      End Loop;

--      numCashDeal := numBillReverse - numDealReverse;
--
--<<Cash_Deal>>
  end if;

    varOperation := 'Checking for Deal Delivery, if any';
    varXPath := '//Deals/CashDeal';
    nlsTemp := xslProcessor.selectNodes(nodFinal, varXPath);

  if xmlDom.getLength(nlsTemp) != 0 then
  
        nodTemp := xmlDom.item(nlsTemp, numSub);
        nmpTemp := xmlDom.getAttributes(nodTemp);
        nodTemp1 := xmlDom.item(nmpTemp, 0);
        numTemp := to_number(xmlDom.getNodeValue(nodTemp1));

        
        
        varTemp := varXPath || numTemp || '/CashDealAmount';
        numCashDeal := GConst.fncGetNodeValue(nodFinal, varTemp);
        
        varTemp := varXPath || numTemp || '/CashDealRate';
        numCashRate := GConst.fncGetNodeValue(nodFinal, varTemp);
        
       if (numRecordStatus=2) and (numAction=104) then 
        
           delete from trtran006 
           where cdel_deal_number=varDealReference
              and cdel_trade_reference=varTradeReference
              and Cdel_Trade_Serial= numTradeSerialNum;
        
          delete from trtran004 
           where hedg_deal_number=varDealReference
             and hedg_trade_reference=varTradeReference
             and hedg_Trade_Serial= numTradeSerialNum;

           numAction:=102;
       elsif (numAction=102) then
          varOperation := 'Inserting Cash Deal';
          varDealReference := varCompany || '/FWD/' || GConst.fncGenerateSerial(Gconst.SERIALDEAL,numCompany);
          insert into trtran001
            (deal_company_code,deal_deal_number,deal_serial_number,
             deal_execute_date,deal_hedge_trade,deal_buy_sell,deal_swap_outright,
             deal_deal_type,deal_counter_party,deal_base_currency,deal_other_currency,deal_exchange_rate,deal_local_rate,deal_base_amount,
            deal_other_amount,deal_amount_local,deal_maturity_code,deal_maturity_from,deal_maturity_date,deal_maturity_month,deal_user_id,
            deal_confirm_date,deal_dealer_remarks,deal_time_stamp,
            deal_execute_time,deal_confirm_time,deal_process_complete,deal_complete_date,deal_create_date,deal_entry_detail,deal_record_status,
            deal_user_reference,deal_fixed_option,deal_delivary_no,deal_forward_rate,deal_spot_rate,deal_margin_rate,
            deal_backup_deal,deal_stop_loss,deal_take_profit,deal_init_code,deal_bank_reference,
            deal_bo_remark)
           values (numCompany, varDealReference, 1,
                 datWorkDate, 26000001,NumCode,
            25200002,25400001,numBankCode,numCurrency, 30400003,numCashRate, 1, numCashDeal,
            Round(numCashRate * numCashDeal),0,0,datWorkDate,datWorkDate,null, 'System',
            NULL,varTradeReference, to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3'),
            to_char(systimestamp, 'HH24:MI'), null,12400001, datWorkDate,sysdate,NULL, 10200001,
            null,null,null,0,numCashRate,0,33399999,numCashRate,0,33899999, NULL,
            'Cash Delivery ' || varTradeReference);


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
            null, 10200001, null,null,1,0,deal_exchange_rate,0,0,0,33500001,null,null,deal_bank_reference,
            deal_bo_remark
            from trtran001
            where deal_deal_number = varDealReference;

          varOperation := 'Inserting Hedge record';
          insert into trtran004
          (hedg_company_code,hedg_trade_reference,hedg_deal_number,
            hedg_deal_serial,hedg_hedged_fcy,hedg_other_fcy,hedg_hedged_inr,
            hedg_create_date,hedg_entry_detail,hedg_record_status,
            hedg_hedging_with,hedg_multiple_currency,Hedg_Trade_serial)
          values(numCompany,varTradeReference,varDealReference,
          1, numCashDeal,0, Round(numCashDeal * numCashRate),
          sysdate,NULL,10200012, 32200001,12400002,numTradeSerialNum);

       elsif (numAction=106) then
          update trtran006 set cdel_record_status=10200006
           where cdel_deal_number=varDealReference
              --cdel_deal_serial=
              and cdel_trade_reference=varTradeReference
              and Cdel_Trade_Serial= numTradeSerialNum;
        
          delete from trtran004 
           where hedg_deal_number=varDealReference
              --cdel_deal_serial=
              and hedg_trade_reference=varTradeReference
              and hedg_Trade_Serial= numTradeSerialNum;
       
        elsif (numAction=108) then
          update trtran006 set cdel_record_status=10200003
           where cdel_deal_number=varDealReference
              --cdel_deal_serial=
             and cdel_trade_reference=varTradeReference
              and Cdel_Trade_Serial= numTradeSerialNum;
        
          update trtran004 set hedg_record_status=10200003
           where hedg_deal_number=varDealReference
              --cdel_deal_serial=
             and hedg_trade_reference=varTradeReference
             and hedg_Trade_Serial= numTradeSerialNum;
      
       end if;
       
      End if;
 -- commit;
end prcTFBillsSettlement;
/