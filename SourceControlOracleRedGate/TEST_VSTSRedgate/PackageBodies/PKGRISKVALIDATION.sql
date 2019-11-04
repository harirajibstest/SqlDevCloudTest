CREATE OR REPLACE PACKAGE BODY "TEST_VSTSRedgate"."PKGRISKVALIDATION" IS

--PROCEDURE prcvalidation (varmessage out varchar2) IS
--    numcompanycode  NUMBER(8);
--    varquery        VARCHAR(2000);
--    vartemp         VARCHAR(2000);
--    varTemp1        varchar(15);
--    numtemp         NUMBER(15,   6);
--    numtemp1        NUMBER(15,   6);
--  BEGIN
--    numcompanycode := 10300007;
--    FOR curfields IN
--      (SELECT risk_risk_type,
--         risk_risk_reference,
--         risk_limit_local,
--         risk_limit_usd
--       FROM riskmaster
--       WHERE risk_record_status NOT IN(gconst.statusdeleted,    gconst.statusinactive))
--    LOOP
--       IF(curfields.risk_risk_type = 21000001) THEN   -- Gross Currency Exposure 
--          vartemp := fncbuildquery(21000001);
--          varquery := 'select sum(DEAL_AMOUNT_LOCAL) from tradedealregister where  deal_company_code= 10300007 ' || vartemp;
--          execute immediate varquery into numtemp; -- for Local Amount 
--          varquery := 'select sum(DEAL_OTHER_AMOUNT) from tradedealregister where  deal_company_code= 10300007 ' || vartemp;              
--          execute immediate varquery into numtemp1; -- for USD Amount 
--          IF numtemp >= curfields.risk_limit_local THEN
--            goto InsertData;
--          ELSIF numtemp1 >= curfields.risk_limit_usd THEN
--            goto InsertData;   
--          END IF;
--         varmessage:= 'Gross Currency Exposure is Cross The Limit' ;
--      END IF;
--      IF(curfields.risk_risk_type = 21000002) THEN   -- Net Currency Exposure 
--        vartemp := fncbuildquery(21000002);
--        varquery := 'SELECT (sum(nvl(decode(deal_buy_sell, 25300001, deal_amount_local,0),0))- sum(nvl(decode(deal_buy_sell,25300002, deal_amount_local,0),0))) as netamount FROM tradedealregister WHERE deal_company_code = 10300007 and ' || vartemp;
--        execute immediate varquery into numtemp;
--        varquery := 'SELECT (sum(nvl(decode(deal_buy_sell, 25300001, deal_other_amount,0),0))- sum(nvl(decode(deal_buy_sell,25300002, deal_other_amount,0),0))) as netamount FROM tradedealregister WHERE deal_company_code = 10300007 and ' || vartemp;
--        execute immediate varquery into numtemp1;
--        if numtemp >= curfields.risk_limit_local then
--          goto insertdata;
--        elsif numtemp1 >= curfields.risk_limit_usd then
--          goto insertdata;
--         end if;
--      end if;   
--      IF(curfields.risk_risk_type = 21000003) THEN    -- Individual Currency Exposure
--          vartemp := fncbuildquery(21000003);
--          varquery := 'SELECT (sum(nvl(decode(deal_buy_sell, 25300001, deal_amount_local,0),0))- sum(nvl(decode(deal_buy_sell,25300002, deal_amount_local,0),0))) as netamount FROM tradedealregister WHERE deal_company_code = 10300007 and ' || vartemp;
--          execute immediate varquery into numtemp;
--          varquery := 'SELECT (sum(nvl(decode(deal_buy_sell, 25300001, deal_other_amount,0),0))- sum(nvl(decode(deal_buy_sell,25300002, deal_other_amount,0),0))) as netamount FROM tradedealregister WHERE deal_company_code = 10300007 and ' || vartemp;
--          execute immediate varquery into numtemp1;
--          if numtemp >= curfields.risk_limit_local then
--             goto insertdata;
--          elsif numtemp1 >= curfields.risk_limit_usd then
--             goto insertdata;
--          END IF;
--        end if;   
--
--        IF(curfields.risk_risk_type = 21000004) THEN   -- Individual Currency Overnight 
--          vartemp := fncbuildquery(21000004);
--          varquery := 'SELECT (sum(nvl(decode(deal_buy_sell, 25300001, deal_amount_local,0),0))- sum(nvl(decode(deal_buy_sell,25300002, deal_amount_local,0),0))) as netamount FROM tradedealregister WHERE deal_company_code = 10300007 and ' || vartemp;
--          execute immediate varquery into numtemp;
--          varquery := 'SELECT (sum(nvl(decode(deal_buy_sell, 25300001, deal_other_amount,0),0))- sum(nvl(decode(deal_buy_sell,25300002, deal_other_amount,0),0))) as netamount FROM tradedealregister WHERE deal_company_code = 10300007 and ' || vartemp;
--          execute immediate varquery into numtemp1;
--          if numtemp >= curfields.risk_limit_local then
--             goto insertdata;
--          elsif numtemp1 >= curfields.risk_limit_usd then
--             goto insertdata;
--          END IF;
--          
--        END IF;
--
--        IF(curfields.risk_risk_type = 21000005) THEN
--          -- Individual Currency Daylight
--          --name := 'dd';
--           varmessage:= 'Gross Currency Exposure is Cross The Limit' ;
--        END IF;
--
--        IF(curfields.risk_risk_type = 21000006) THEN
--          -- Individual Currency Gap - Spot
--          --name := 'dd';
--           varmessage:= 'Gross Currency Exposure is Cross The Limit' ;
--        END IF;
--        if (curfields.risk_risk_type=21000019) then   --Counter Party Exposure
--          vartemp := fncbuildquery(21000019);
--          varquery := 'select sum(DEAL_AMOUNT_LOCAL) from tradedealregister where  deal_company_code= 10300007 ' || vartemp;
--          execute immediate varquery into numtemp; -- for Local Amount 
--          varquery := 'select sum(DEAL_OTHER_AMOUNT) from tradedealregister where  deal_company_code= 10300007 ' || vartemp;              
--          execute immediate varquery into numtemp1; -- for USD Amount 
--          IF numtemp >= curfields.risk_limit_local THEN
--            goto InsertData;
--          ELSIF numtemp1 >= curfields.risk_limit_usd THEN
--            goto InsertData;   
--          END IF;
--        end if;
--      END LOOP;
--
----      << InsertData >>
----          INSERT INTO TRTRAN011 VALUES(numcompanycode,'ccc',25200001,1,25200001);
----          commit;
----          varTemp1 := 'sdfsdf';
--
--    END prcvalidation;

    FUNCTION fncbuildquery(numrisktype IN NUMBER) RETURN VARCHAR2 IS vartemp VARCHAR(2000);
    BEGIN
      FOR curfields IN
        (SELECT *
         FROM riskmaster
         WHERE risk_risk_type = numrisktype
         AND risk_record_status NOT IN(gconst.statusdeleted,    gconst.statusinactive))
      LOOP

        IF(curfields.risk_hedge_trade != 0) THEN
          vartemp := 'and risk_hedge_trade= ' || curfields.risk_hedge_trade;
        END IF;

        IF(curfields.risk_buy_sell != 0) THEN
          vartemp := vartemp || ' and risk_buy_sell= ' || curfields.risk_buy_sell;
        END IF;

        IF(curfields.risk_swap_outright != 0) THEN
          vartemp := vartemp || ' and risk_swap_outright=' || curfields.risk_swap_outright;
        END IF;

        IF(curfields.risk_deal_type != 0) THEN
          vartemp := vartemp || ' and risk_deal_type = ' || curfields.risk_deal_type;
        END IF;

        IF(curfields.risk_counter_party != 0) THEN
          vartemp := vartemp || ' and risk_deal_type = ' || curfields.risk_counter_party;
        END IF;

        IF(curfields.risk_currency_code != 0) THEN
          vartemp := vartemp || ' and risk_currency_code = ' || curfields.risk_currency_code;
        END IF;

      END LOOP;

      RETURN vartemp;

    END fncbuildquery;
    
procedure prcRiskPopulateNew
    (AsonDate in date)
as
    NUMERROR            number(15);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
begin

      varOperation := 'Delete Existing Data';
      delete from TRSYSTEM997F;

      VarOperation := 'Call the VaR MOdel Position Generate';
      
      NUMERROR:= PKGVARANALYSIS.FNCPOSITIONGENERATE('admin',AsonDate);
      
      varOperation := 'Inserting data from staging table ';
      
      insert into TRSYSTEM997F(
        RIPO_COMPANY_CODE , RIPO_LOCATION_CODE , RIPO_BASE_CURRENCY , 
        RIPO_OTHER_CURRENCY , RIPO_ACCOUNT_CODE , RIPO_USER_ID , 
        RIPO_REFERENCE_NUMBER , RIPO_REFERENCE_SERIAL , RIPO_REFERENCE_DATE , 
        RIPO_DEALER_ID , RIPO_COUNTER_PARTY , RIPO_TRANSACTION_AMOUNT , 
        RIPO_FCY_RATE , RIPO_USD_RATE , RIPO_INR_VALUE , RIPO_USD_VALUE , 
        RIPO_M2M_FCYRATE, RIPO_M2M_LOCALINRRATE , RIPO_REVALUE_USD , 
        RIPO_REVALUE_INR , RIPO_POSITION_USD, RIPO_POSITION_INR , 
        RIPO_DUE_DATE, RIPO_MATURITY_MONTH , RIPO_PRODUCT_CODE , 
        RIPO_HEDGE_TRADE,RIPO_ASSET_LIABILITY , RIPO_FOR_CURRENCY , RIPO_SUBPRODUCT_CODE , 
        RIPO_MTM_PNL, RIPO_MTM_PNLLOCAL,RIPO_BUY_SELL,RIPO_SWAP_OUTRIGHT , RIPO_DEAL_TYPE,
        RIPO_CURRENCY_PRODUCT)
     select 	POSN_COMPANY_CODE , 30299999,	posn_currency_code,
        POSN_OTHER_CURRENCY , POSN_ACCOUNT_CODE , POSN_USER_ID ,
        POSN_REFERENCE_NUMBER , POSN_REFERENCE_SERIAL , POSN_REFERENCE_DATE , 
        POSN_DEALER_ID , POSN_COUNTER_PARTY, POSN_TRANSACTION_AMOUNT ,
        POSN_FCY_RATE , POSN_USD_RATE , POSN_INR_VALUE , POSN_USD_VALUE , 
        POSN_MTM_FCYRATE , POSN_MTM_LOCALRATE , POSN_REVALUE_USD , 
        POSN_REVALUE_INR , POSN_POSITION_USD , 	POSN_POSITION_INR , 
        POSN_DUE_DATE , POSN_MATURITY_MONTH , POSN_PRODUCT_CODE, 
        decode(POSN_HEDGE_TRADE,'H',26000001,'T',26000002) , 
        POSN_ASSET_LIABILITY , POSN_FOR_CURRENCY, POSN_SUBPRODUCT_CODE, 
        POSN_MTM_PNL , POSN_MTM_PNLLOCAL,
        (case when (posn_account_code>25900050) then 25300002 else 25300001 end),25200000,25400000,
        (case when posn_account_code in (25900011,25900012,25900061,25900062) then 32200001
              when posn_account_code in (25900018,25900019,25900078,25900079) then 32200002
              when posn_account_code in (25900020,25900021,25900022,25900023,25900082,25900083,25900084,25900085) then 32200003
              else 32200000 end)
        from trsystem997D
        where POSN_TRANSACTION_AMOUNT !=0;
       
    varOperation := 'Gross Currency Exposure COUNTERPARTY Exposure';
    insert into trtran011
    (RDEL_COMPANY_CODE,RDEL_LOCATION_CODE,RDEL_RISK_REFERENCE,RDEL_DEAL_NUMBER,RDEL_SERIAL_NUMBER,
     RDEL_RISK_TYPE,RDEL_RISK_DATE,RDEL_LIMIT_FCY,RDEL_LIMIT_USD,RDEL_LIMIT_LOCAL,RDEL_LIMIT_PERCENT,
     RDEL_CAL_FCY,rdel_cal_usd,RDEL_CAL_LOCAL, RDEL_ACTION_TAKEN,
     RDEL_STAKE_HOLDER,RDEL_MOBILE_NUMBER,RDEL_EMAIL_ID,RDEL_MESSAGE_TEXT,RDEL_CREATE_DATE,
     RDEL_PRODUCT_code,RDEL_SUBPRODUCT_code,rdel_record_status)

    with Cal_data as(
    select RIPO_COMPANY_CODE,RIPO_LOCATION_CODE,Risk_Risk_reference,RISK_RISK_TYPE,
           RISK_LIMIT_FCY,Risk_LIMIT_USD,RISK_LIMIT_LOCAL,RISK_LIMIT_PERCENT,
           sum(RIPO_TRANSACTION_AMOUNT) TransactionAmount,sum(RIPO_REVALUE_USD) RevalueUsd,
           sum(RIPO_INR_VALUE) ReValueINR,risk_action_taken,risk_stake_holder,
           RIPO_PRODUCT_code,RIPO_SUBPRODUCT_code
     from
      (select * from trsystem012 m
        where risk_risk_type in (21000001,21000006)
        and risk_effective_date = ( select max(risk_effective_date)
                                     from trsystem012 sub
                                     where m.risk_risk_type =sub.risk_risk_type
                                      and risk_effective_date <= asondate
                                      and risk_record_status not in (10200005,10200006))
        and risk_record_status not in (10200005,10200006))risk
    left outer join 
      (select * from trsystem997F)Pos
        on decode(risk.RISK_HEDGE_TRADE,26000000,pos.RIPO_HEDGE_TRADE,risk.RISK_HEDGE_TRADE)=pos.RIPO_HEDGE_TRADE
        and decode(risk.RISK_BUY_SELL,25300000,pos.RIPO_BUY_SELL,risk.RISK_BUY_SELL)=pos.RIPO_BUY_SELL
        and decode(risk.RISK_SWAP_OUTRIGHT,25200000,pos.RIPO_SWAP_OUTRIGHT,risk.RISK_SWAP_OUTRIGHT)=pos.RIPO_SWAP_OUTRIGHT
        and decode(risk.RISK_DEAL_TYPE,0,pos.RIPO_DEAL_TYPE,risk.RISK_DEAL_TYPE)=pos.RIPO_DEAL_TYPE
        and decode(risk.RISK_COUNTER_PARTY,30600000,pos.RIPO_COUNTER_PARTY,risk.RISK_COUNTER_PARTY)=pos.RIPO_COUNTER_PARTY
        and decode(risk.RISK_DEALER_ID,'0',pos.RIPO_DEALER_ID,risk.RISK_DEALER_ID)=pos.RIPO_DEALER_ID
        and decode(risk.RISK_CURRENCY_CODE,30400000,pos.RIPO_BASE_CURRENCY,risk.RISK_CURRENCY_CODE)=pos.RIPO_BASE_CURRENCY
        and decode(risk.RISK_COMPANY_CODE,30100000,pos.RIPO_COMPANY_CODE,risk.RISK_COMPANY_CODE)=pos.RIPO_COMPANY_CODE
        and decode(risk.RISK_LOCATION_CODE,30200000,pos.RIPO_LOCATION_CODE,risk.RISK_LOCATION_CODE)=pos.RIPO_LOCATION_CODE
        and decode(risk.RISK_PRODUCT_CODE,33300000,pos.RIPO_PRODUCT_code,risk.RISK_PRODUCT_CODE)=pos.RIPO_PRODUCT_code
        and decode(risk.RISK_SUBPRODUCT_CODE,33800000,pos.RIPO_SUBPRODUCT_code,risk.RISK_SUBPRODUCT_CODE)=pos.RIPO_SUBPRODUCT_code
        and decode(risk.RISK_CURRENCY_PRODUCT,33200000,pos.RIPO_CURRENCY_PRODUCT,risk.RISK_CURRENCY_PRODUCT)=pos.RIPO_CURRENCY_PRODUCT
     group by RIPO_COMPANY_CODE,RIPO_LOCATION_CODE,Risk_Risk_reference,RISK_RISK_TYPE,
           RISK_LIMIT_FCY,Risk_LIMIT_USD,RISK_LIMIT_LOCAL,RISK_LIMIT_PERCENT,risk_action_taken,risk_stake_holder,
           RIPO_PRODUCT_code,RIPO_SUBPRODUCT_code)
      select RIPO_COMPANY_CODE,RIPO_LOCATION_CODE,Risk_Risk_reference,'NA' ReferenceNumber,0 ReferenceSerial,
           RISK_RISK_TYPE,AsOndate RiskDate,RISK_LIMIT_FCY,Risk_LIMIT_USD,RISK_LIMIT_LOCAL,RISK_LIMIT_PERCENT,
           TransactionAmount,RevalueUsd,ReValueINR,risk_action_taken,
           risk_stake_holder,null,pkgriskvalidation.fncgetUserEmailID(risk_stake_holder),null MessageText,sysdate CreateDate,
           Ripo_PRODUCT_code,Ripo_SUBPRODUCT_code,10200001
       from Cal_data
       where  ((RevalueUSD > decode(Risk_LIMIT_USD,0,999999999999999,Risk_LIMIT_USD)) or
              (RevalueInr > decode(RISK_LIMIT_LOCAL,0,999999999999999,RISK_LIMIT_LOCAL)) or
              (TransactionAmount > decode(Risk_LIMIT_FCY,0,999999999999999,Risk_LIMIT_FCY)))
       and not exists 
          (select 'X' from trtran011 
            where RDEL_COMPANY_CODE=RIPO_COMPANY_CODE
              and RDEL_LOCATION_CODE=RIPO_LOCATION_CODE
              and RDEL_RISK_TYPE=RISK_RISK_TYPE
              and RDEL_LIMIT_FCY= RDEL_LIMIT_FCY
              and RDEL_LIMIT_USD= RDEL_LIMIT_USD
              and RDEL_LIMIT_LOCAL= RDEL_LIMIT_LOCAL
              and RDEL_CAL_FCY=TransactionAmount 
              and rdel_cal_usd= RevalueUSD
              and RDEL_CAL_LOCAL= REvalueInr
              and Rdel_stake_holder=risk_stake_holder
              and RDEL_ACTION_TAKEN=risk_action_taken
              and RDEL_RISK_DAte=AsonDate);
    
    varOperation := 'Net Currency Exposure';
    insert into trtran011
    (RDEL_COMPANY_CODE,RDEL_LOCATION_CODE,RDEL_RISK_REFERENCE,RDEL_DEAL_NUMBER,RDEL_SERIAL_NUMBER,
     RDEL_RISK_TYPE,RDEL_RISK_DATE,RDEL_LIMIT_FCY,RDEL_LIMIT_USD,RDEL_LIMIT_LOCAL,RDEL_LIMIT_PERCENT,
     RDEL_CAL_FCY,rdel_cal_usd,RDEL_CAL_LOCAL, RDEL_ACTION_TAKEN,
     RDEL_STAKE_HOLDER,RDEL_MOBILE_NUMBER,RDEL_EMAIL_ID,RDEL_MESSAGE_TEXT,RDEL_CREATE_DATE,
     RDEL_PRODUCT_code,RDEL_SUBPRODUCT_code,rdel_record_status)
    with Cal_data as 
        (select RIPO_COMPANY_CODE,RIPO_LOCATION_CODE,Risk_Risk_reference,
           RISK_RISK_TYPE,Risk_LIMIT_FCY,Risk_LIMIT_USD,RISK_LIMIT_LOCAL,RISK_LIMIT_PERCENT,
           sum(decode(RIPO_BUY_SELL,25300002,-1,1)*RIPO_TRANSACTION_AMOUNT) TransactionAmount,
           sum(decode(RIPO_BUY_SELL,25300002,-1,1)*RIPO_REVALUE_USD) RevalueUsd,
           sum(decode(RIPO_BUY_SELL,25300002,-1,1)*RIPO_INR_VALUE) RevalueInr,risk_action_taken,risk_stake_holder,
           ripo_PRODUCT_code,ripo_SUBPRODUCT_code
          from
          (select * from trsystem012 m
          where risk_risk_type=21000002
          and risk_effective_date = ( select max(risk_effective_date)
                             from trsystem012 sub
                             where sub.risk_risk_type =m.risk_risk_type
                              and risk_effective_date <= asondate
                              and risk_record_status not in (10200005,10200006))
          and risk_record_status not in (10200005,10200006))risk
          left outer join 
          (select * from trsystem997F)Pos
          on decode(risk.RISK_HEDGE_TRADE,26000000,pos.RIPO_HEDGE_TRADE,risk.RISK_HEDGE_TRADE)=pos.RIPO_HEDGE_TRADE
          and decode(risk.RISK_BUY_SELL,25300000,pos.RIPO_BUY_SELL,risk.RISK_BUY_SELL)=pos.RIPO_BUY_SELL
          and decode(risk.RISK_SWAP_OUTRIGHT,25200000,pos.RIPO_SWAP_OUTRIGHT,risk.RISK_SWAP_OUTRIGHT)=pos.RIPO_SWAP_OUTRIGHT
          and decode(risk.RISK_DEAL_TYPE,0,pos.RIPO_DEAL_TYPE,risk.RISK_DEAL_TYPE)=pos.RIPO_DEAL_TYPE
          and decode(risk.RISK_COUNTER_PARTY,30600000,pos.RIPO_COUNTER_PARTY,risk.RISK_COUNTER_PARTY)=pos.RIPO_COUNTER_PARTY
          and decode(risk.RISK_DEALER_ID,'0',pos.RIPO_DEALER_ID,risk.RISK_DEALER_ID)=pos.RIPO_DEALER_ID
          and decode(risk.RISK_CURRENCY_CODE,30400000,pos.RIPO_BASE_CURRENCY,risk.RISK_CURRENCY_CODE)=pos.RIPO_BASE_CURRENCY
          and decode(risk.RISK_COMPANY_CODE,30100000,pos.RIPO_COMPANY_CODE,risk.RISK_COMPANY_CODE)=pos.RIPO_COMPANY_CODE
          and decode(risk.RISK_LOCATION_CODE,30200000,pos.RIPO_LOCATION_CODE,risk.RISK_LOCATION_CODE)=pos.RIPO_LOCATION_CODE
          and decode(risk.RISK_CURRENCY_PRODUCT,33200000,pos.RIPO_CURRENCY_PRODUCT,risk.RISK_CURRENCY_PRODUCT)=pos.RIPO_CURRENCY_PRODUCT
          and decode(risk.RISK_Product_code,33300000,pos.RIPO_Product_code,risk.risk_product_code)=pos.RIPO_Product_code
          and decode(risk.RISK_subProduct_code,33800000,pos.RIPO_subPRODUCT_code,risk.RISK_subPRODUCT_code)=pos.RIPO_subPRODUCT_code
          group by RIPO_COMPANY_CODE,RIPO_LOCATION_CODE,Risk_Risk_reference,
           RISK_RISK_TYPE,Risk_LIMIT_FCY,Risk_LIMIT_USD,RISK_LIMIT_LOCAL,RISK_LIMIT_PERCENT,
            risk_action_taken,risk_stake_holder,
           ripo_PRODUCT_code,ripo_SUBPRODUCT_code)
         select RIPO_COMPANY_CODE,RIPO_LOCATION_CODE,Risk_Risk_reference,'NA' referencenumber,0 referenceSerial,
           RISK_RISK_TYPE,AsOndate,Risk_LIMIT_FCY,Risk_LIMIT_USD,RISK_LIMIT_LOCAL,RISK_LIMIT_PERCENT,
           TransactionAmount,RevalueUsd,RevalueInr,risk_action_taken,
           risk_stake_holder,null,fncgetUserEmailID(risk_stake_holder) EmailId,null Message,sysdate Createdate,
           Ripo_PRODUCT_code,Ripo_SUBPRODUCT_code,10200001
          from Cal_data
          where ((TransactionAmount>decode(Risk_LIMIT_FCY,0,999999999999999,Risk_LIMIT_FCY)) or
                 (RevalueUsd > decode(Risk_LIMIT_USD,0,999999999999999,Risk_LIMIT_USD)) or
                 (RevalueInr > decode(RISK_LIMIT_LOCAL,0,999999999999999,RISK_LIMIT_LOCAL)))
         and not exists 
          (select 'X' from trtran011 
            where RDEL_COMPANY_CODE=RIPO_COMPANY_CODE
              and RDEL_LOCATION_CODE=RIPO_LOCATION_CODE
              and RDEL_RISK_TYPE=RISK_RISK_TYPE
              and RDEL_LIMIT_FCY= RDEL_LIMIT_FCY
              and RDEL_LIMIT_USD= RDEL_LIMIT_USD
              and RDEL_LIMIT_LOCAL= RDEL_LIMIT_LOCAL
              and RDEL_CAL_FCY=TransactionAmount 
              and rdel_cal_usd= RevalueUSD
              and RDEL_CAL_LOCAL= REvalueInr
              and Rdel_stake_holder=risk_stake_holder
              and RDEL_ACTION_TAKEN=risk_action_taken
              and RDEL_RISK_DAte=AsonDate);
       
           
    varOperation := 'Individual Deal Limit';
    
    insert into trtran011
    (RDEL_COMPANY_CODE,RDEL_LOCATION_CODE,RDEL_RISK_REFERENCE,RDEL_DEAL_NUMBER,RDEL_SERIAL_NUMBER,
     RDEL_RISK_TYPE,RDEL_RISK_DATE,RDEL_LIMIT_FCY,RDEL_LIMIT_USD,RDEL_LIMIT_LOCAL,RDEL_LIMIT_PERCENT,
     RDEL_CAL_FCY,rdel_cal_usd,RDEL_CAL_LOCAL, RDEL_ACTION_TAKEN,
     RDEL_STAKE_HOLDER,RDEL_MOBILE_NUMBER,RDEL_EMAIL_ID,RDEL_MESSAGE_TEXT,RDEL_CREATE_DATE,
     Rdel_PRODUCT_code,Rdel_SUBPRODUCT_code,rdel_record_status)
     
      select RIPO_COMPANY_CODE,RIPO_LOCATION_CODE,Risk_Risk_reference,RIPO_REFERENCE_NUMBER,RIPO_reference_serial,
           RISK_RISK_TYPE,AsOndate,Risk_LIMIT_FCY,Risk_LIMIT_USD,RISK_LIMIT_LOCAL,RISK_LIMIT_PERCENT,
           RIPO_TRANSACTION_AMOUNT TransactionAmount, RIPO_REVALUE_USD RevalueUsd,
           RIPO_INR_VALUE RevalueInr,risk_action_taken,
           risk_stake_holder,null,pkgriskvalidation.fncgetUserEmailID(risk_stake_holder) EmailId,null,sysdate,
           RIPO_PRODUCT_code,RIPO_SUBPRODUCT_code,10200001
       from (select * from trsystem012 m
        where risk_risk_type=21000003
          and risk_effective_date = ( select max(risk_effective_date)
                     from trsystem012 sub
                     where sub.risk_risk_type =m.risk_risk_type
                      and risk_effective_date <= asondate
                      and risk_record_status not in (10200005,10200006))
        and risk_record_status not in (10200005,10200006))risk
        left outer join 
        (select * from trsystem997F)Pos
        on decode(risk.RISK_HEDGE_TRADE,26000000,pos.RIPO_HEDGE_TRADE,risk.RISK_HEDGE_TRADE)=pos.RIPO_HEDGE_TRADE
        and decode(risk.RISK_BUY_SELL,25300000,pos.RIPO_BUY_SELL,risk.RISK_BUY_SELL)=pos.RIPO_BUY_SELL
        and decode(risk.RISK_SWAP_OUTRIGHT,25200000,pos.RIPO_SWAP_OUTRIGHT,risk.RISK_SWAP_OUTRIGHT)=pos.RIPO_SWAP_OUTRIGHT
        and decode(risk.RISK_DEAL_TYPE,0,pos.RIPO_DEAL_TYPE,risk.RISK_DEAL_TYPE)=pos.RIPO_DEAL_TYPE
        and decode(risk.RISK_COUNTER_PARTY,30600000,pos.RIPO_COUNTER_PARTY,risk.RISK_COUNTER_PARTY)=pos.RIPO_COUNTER_PARTY
        and decode(risk.RISK_DEALER_ID,'0',pos.RIPO_DEALER_ID,risk.RISK_DEALER_ID)=pos.RIPO_DEALER_ID
        and decode(risk.RISK_CURRENCY_CODE,30400000,pos.RIPO_BASE_CURRENCY,risk.RISK_CURRENCY_CODE)=pos.RIPO_BASE_CURRENCY
        and decode(risk.RISK_COMPANY_CODE,30100000,pos.RIPO_COMPANY_CODE,risk.RISK_COMPANY_CODE)=pos.RIPO_COMPANY_CODE
        and decode(risk.RISK_LOCATION_CODE,30200000,pos.RIPO_LOCATION_CODE,risk.RISK_LOCATION_CODE)=pos.RIPO_LOCATION_CODE
        and decode(risk.RISK_PRODUCT_CODE,33300000,pos.RIPO_PRODUCT_code,risk.RISK_PRODUCT_CODE)=pos.RIPO_PRODUCT_code
        and decode(risk.RISK_SUBPRODUCT_CODE,33800000,pos.RIPO_SUBPRODUCT_code,risk.RISK_SUBPRODUCT_CODE)=pos.RIPO_SUBPRODUCT_code
        and decode(risk.RISK_CURRENCY_PRODUCT,33200000,pos.RIPO_CURRENCY_PRODUCT,risk.RISK_CURRENCY_PRODUCT)=pos.RIPO_CURRENCY_PRODUCT
     where ((RIPO_TRANSACTION_AMOUNT>decode(Risk_LIMIT_FCY,0,999999999999999,Risk_LIMIT_FCY)) or
           (RIPO_REVALUE_USD > decode(Risk_LIMIT_USD,0,999999999999999,Risk_LIMIT_USD)) or
           (RIPO_INR_VALUE > decode(RISK_LIMIT_LOCAL,0,999999999999999,RISK_LIMIT_LOCAL)))
        and not exists 
          (select 'X' from trtran011 
            where RDEL_COMPANY_CODE=RIPO_COMPANY_CODE
              and RDEL_LOCATION_CODE=RIPO_LOCATION_CODE
              and RDEL_RISK_TYPE=RISK_RISK_TYPE
              and RDEL_LIMIT_FCY= RDEL_LIMIT_FCY
              and RDEL_LIMIT_USD= RDEL_LIMIT_USD
              and RDEL_LIMIT_LOCAL= RDEL_LIMIT_LOCAL
              and RDEL_CAL_FCY=RIPO_TRANSACTION_AMOUNT  
             -- and rdel_cal_usd= RIPO_REVALUE_USD     --remove teemporary to avoid duplicate mail
              and RDEL_CAL_LOCAL= RIPO_INR_VALUE
              and Rdel_stake_holder=risk_stake_holder
              and RDEL_product_code= RIPO_product_code
              and RDEL_subproduct_code= RIPO_subproduct_code
              and RDEL_ACTION_TAKEN=risk_action_taken
              and RDEL_RISK_DAte=AsonDate);
              
    varOperation := 'Individual Deal Limit Stop Loss limit';
    
    insert into trtran011
    (RDEL_COMPANY_CODE,RDEL_LOCATION_CODE,RDEL_RISK_REFERENCE,RDEL_DEAL_NUMBER,RDEL_SERIAL_NUMBER,
     RDEL_RISK_TYPE,RDEL_RISK_DATE,RDEL_LIMIT_FCY,RDEL_LIMIT_USD,RDEL_LIMIT_LOCAL,RDEL_LIMIT_PERCENT,
     RDEL_CAL_FCY,rdel_cal_usd,RDEL_CAL_LOCAL,rdel_cal_percent, RDEL_ACTION_TAKEN,
     RDEL_STAKE_HOLDER,RDEL_MOBILE_NUMBER,RDEL_EMAIL_ID,RDEL_MESSAGE_TEXT,RDEL_CREATE_DATE,
     RDEL_PRODUCT_code,RDEL_SUBPRODUCT_code,rdel_record_status
     )
      select RIPO_COMPANY_CODE,RIPO_LOCATION_CODE,Risk_Risk_reference,RIPO_REFERENCE_NUMBER,RIPO_reference_serial,
           RISK_RISK_TYPE,AsOndate,Risk_LIMIT_FCY,Risk_LIMIT_USD,RISK_LIMIT_LOCAL,RISK_LIMIT_PERCENT,
           RIPO_TRANSACTION_AMOUNT TransactionAmount, RIPO_REVALUE_USD RevalueUsd,
           RIPO_INR_VALUE RevalueInr, (case when RIPO_BUY_SELL=25300002 then 
                                       round(((RIPO_FCY_RATE-RIPO_M2M_FCYRate)/RIPO_FCY_RATE)*100,2)
                                       when RIPO_BUY_SELL=25300002 then 
                                         round(((RIPO_M2M_FCYRate-RIPO_FCY_RATE)/RIPO_FCY_RATE)*100,2)
                                       end),
           risk_action_taken,
           risk_stake_holder,null,pkgriskvalidation.fncgetUserEmailID(risk_stake_holder) EmailId,null,sysdate,
           RIPO_PRODUCT_code,RIPO_SUBPRODUCT_code,10200001
       from (select * from trsystem012 m
        where risk_risk_type=21000015
          and risk_effective_date = ( select max(risk_effective_date)
             from trsystem012 sub
             where sub.risk_risk_type =m.risk_risk_type
              and risk_effective_date <= asondate
              and risk_record_status not in (10200005,10200006))
        and risk_record_status not in (10200005,10200006))risk
        left outer join 
        (select * from trsystem997F)Pos
        on decode(risk.RISK_HEDGE_TRADE,26000000,pos.RIPO_HEDGE_TRADE,risk.RISK_HEDGE_TRADE)=pos.RIPO_HEDGE_TRADE
        and decode(risk.RISK_BUY_SELL,25300000,pos.RIPO_BUY_SELL,risk.RISK_BUY_SELL)=pos.RIPO_BUY_SELL
        and decode(risk.RISK_SWAP_OUTRIGHT,25200000,pos.RIPO_SWAP_OUTRIGHT,risk.RISK_SWAP_OUTRIGHT)=pos.RIPO_SWAP_OUTRIGHT
        and decode(risk.RISK_DEAL_TYPE,0,pos.RIPO_DEAL_TYPE,risk.RISK_DEAL_TYPE)=pos.RIPO_DEAL_TYPE
        and decode(risk.RISK_COUNTER_PARTY,30600000,pos.RIPO_COUNTER_PARTY,risk.RISK_COUNTER_PARTY)=pos.RIPO_COUNTER_PARTY
        and decode(risk.RISK_DEALER_ID,'0',pos.RIPO_DEALER_ID,risk.RISK_DEALER_ID)=pos.RIPO_DEALER_ID
        and decode(risk.RISK_CURRENCY_CODE,30400000,pos.RIPO_BASE_CURRENCY,risk.RISK_CURRENCY_CODE)=pos.RIPO_BASE_CURRENCY
        and decode(risk.RISK_COMPANY_CODE,30100000,pos.RIPO_COMPANY_CODE,risk.RISK_COMPANY_CODE)=pos.RIPO_COMPANY_CODE
        and decode(risk.RISK_LOCATION_CODE,30200000,pos.RIPO_LOCATION_CODE,risk.RISK_LOCATION_CODE)=pos.RIPO_LOCATION_CODE
        and decode(risk.RISK_PRODUCT_CODE,33300000,pos.RIPO_PRODUCT_code,risk.RISK_PRODUCT_CODE)=pos.RIPO_PRODUCT_code
        and decode(risk.RISK_SUBPRODUCT_CODE,33800000,pos.RIPO_SUBPRODUCT_code,risk.RISK_SUBPRODUCT_CODE)=pos.RIPO_SUBPRODUCT_code
        and decode(risk.RISK_CURRENCY_PRODUCT,33200000,pos.RIPO_CURRENCY_PRODUCT,risk.RISK_CURRENCY_PRODUCT)=pos.RIPO_CURRENCY_PRODUCT
     where (((RIPO_BUY_SELL=25300002) and (round(((RIPO_FCY_RATE-RIPO_M2M_FCYRate)/RIPO_FCY_RATE)*100,2) >= Risk_LIMIT_PERCENT)) or
           ((RIPO_BUY_SELL=25300001) and (round(((RIPO_M2M_FCYRate-RIPO_FCY_RATE)/RIPO_FCY_RATE)*100,2) >= Risk_LIMIT_PERCENT)))
       and not exists 
          (select 'X' from trtran011 
            where RDEL_COMPANY_CODE=RIPO_COMPANY_CODE
              and RDEL_LOCATION_CODE=RIPO_LOCATION_CODE
              and RDEL_RISK_TYPE=RISK_RISK_TYPE
              and RDEL_LIMIT_FCY= RDEL_LIMIT_FCY
              and RDEL_LIMIT_USD= RDEL_LIMIT_USD
              and RDEL_LIMIT_LOCAL= risk_LIMIT_LOCAL
              and RDEL_CAL_FCY=RIPO_TRANSACTION_AMOUNT 
             -- and rdel_cal_usd= RIPO_REVALUE_USD
              and RDEL_CAL_LOCAL= RIPO_INR_VALUE
              and Rdel_stake_holder=risk_stake_holder
              and RDEL_Product_code= RIPO_Product_code
              and Rdel_subproduct_code=RIPO_subProduct_code
             -- and Rdel_Currency_product=RIPO_CURRENCY_PRODUCT
              and RDEL_ACTION_TAKEN=risk_action_taken
              and RDEL_RISK_DAte=AsonDate);

--21000011	STLSD	Stop Loss Daily
--21000012	STLSM	Stop Loss Monthly
--21000013	STLSQ	Stop Loss Quarteryly
--21000014	STLSY	Stop Loss Yearly

    varOperation := 'Stop Loss Daily Monthly Quarteryly Yearly';
    
    insert into trtran011
    (RDEL_COMPANY_CODE,RDEL_LOCATION_CODE,RDEL_RISK_REFERENCE,RDEL_DEAL_NUMBER,RDEL_SERIAL_NUMBER,
     RDEL_RISK_TYPE,RDEL_RISK_DATE,RDEL_LIMIT_FCY,RDEL_LIMIT_USD,RDEL_LIMIT_LOCAL,RDEL_LIMIT_PERCENT,
     RDEL_CAL_FCY,rdel_cal_usd,RDEL_CAL_LOCAL, RDEL_ACTION_TAKEN,
     RDEL_STAKE_HOLDER,RDEL_MOBILE_NUMBER,RDEL_EMAIL_ID,RDEL_MESSAGE_TEXT,RDEL_CREATE_DATE,
     RDEL_PRODUCT_code,RDEL_SUBPRODUCT_code,rdel_record_status
     )
      select CompanyCode,LocationCode,Risk_Risk_reference,'NA',0,
           RISK_RISK_TYPE,AsOndate,Risk_LIMIT_FCY,Risk_LIMIT_USD,RISK_LIMIT_LOCAL,RISK_LIMIT_PERCENT,
           0 TransactionAmount, 0 RevalueUsd,
           decode(risk_risk_type,21000011,pnlDTD,21000012,pnlMTD,21000013,pnlQTD,21000014,pnlYTD),risk_action_taken,
           risk_stake_holder,null,pkgriskvalidation.fncgetUserEmailID(risk_stake_holder) EmailId,null,sysdate,
           ProductCode,SubProductCode,10200001
      from     
     (select * from trsystem012 m
        where risk_risk_type in(21000011,21000012,21000013,21000014)
            and risk_effective_date = ( select max(risk_effective_date)
                     from trsystem012 sub
                 where sub.risk_risk_type =m.risk_risk_type
                  and risk_effective_date <= asondate
                  and risk_record_status not in (10200005,10200006))
        and risk_record_status not in (10200005,10200006))risk left outer join
         (select CompanyCode,LocationCode,UserID,HedgeTrade,sum(Case when CancelDate=AsonDate then ProfitLoss else 0 end) PnlDTD,
           sum(Case when to_char(CancelDate,'mm')= to_char(to_date(AsonDate),'mm') then ProfitLoss else 0 end) PnLMTD,
           sum(case when (Case when to_char(to_date(AsonDate),'mm') between '01' and '03' then '01-jan-' || To_char(to_date(AsonDate),'YYYY') 
                 when to_char(to_date(AsonDate),'mm') between '04' and '06' then '01-Apr-' || To_char(to_date(AsonDate),'YYYY') 
                 when to_char(to_date(AsonDate),'mm') between '07' and '09' then '01-Jul-' || To_char(to_date(AsonDate),'YYYY') 
                 when to_char(to_date(AsonDate),'mm') between '10' and '12' then '01-Oct-' || To_char(to_date(AsonDate),'YYYY') end)
                 >=CancelDate then ProfitLoss else 0 end) PnLQTD,ProductCode,SubProductCode,
           Sum(ProfitLoss) PnLYTD,CurrencyProduct
         from    
            (select deal_company_code CompanyCode,deal_location_code LocationCode, 
                    deal_user_id userID,deal_hedge_trade HedgeTrade,cdel_cancel_date CancelDate, 
                   sum(cdel_profit_loss) ProfitLoss , deal_backup_deal ProductCode,deal_init_code SubProductCode,
                   32200001 as CurrencyProduct
             from trtran006 left outer join trtran001
              on cdel_deal_number= deal_deal_number
             where cdel_cancel_date >='01-Apr-2014'
             and cdel_record_Status not in (10200005,10200006)
             and deal_record_status not in (10200005,10200006)
             group by deal_user_id,deal_hedge_trade,cdel_cancel_date,deal_company_code,
                      deal_location_code, deal_backup_deal,deal_init_code
            union all
            select cfut_company_code CompanyCode,cfut_location_code LocationCode, cfut_user_id UserID,
                   cfut_hedge_trade HedgeTrade,cfrv_Execute_date CancelDate, 
                   sum(cfrv_profit_loss) ProfitLoss, cfut_backup_deal ProductCode,cfut_init_code SubProductCode,
                   32200002 as CurrencyProduct
             from trtran063 left outer join trtran061
              on cfrv_deal_number= cfut_deal_number
             where cfrv_Execute_date >='01-apr-2014'
             and cfrv_record_status not in (10200005,10200006)
             and cfut_record_status not in (10200005,10200006)
             group by cfut_user_id,cfut_hedge_trade,cfrv_Execute_date,cfut_company_code,cfut_location_code,
             cfut_backup_deal,cfut_init_code
            union all
            select copt_company_code CompanyCode,copt_location_code LocationCode, copt_user_id UserID,
                   copt_hedge_trade HedgeTrade,corv_exercise_date CancelDate,
                   sum(corv_Profit_loss) ProfitLoss,copt_backup_deal ProductCode,copt_init_code SubProductCode,
                   32200003 as CurrencyProduct
             from trtran073 left outer join trtran071
              on copt_deal_number= corv_deal_number
             where corv_exercise_date >='01-apr-2014'
             and corv_record_status not in (10200005,10200006)
             and copt_record_status not in (10200005,10200006)
             group by copt_user_id,copt_hedge_trade,corv_exercise_date,copt_company_code,copt_location_code,
                      copt_backup_deal,copt_init_code)
             group by UserID,HedgeTrade,CompanyCode,LocationCode,ProductCode,SubProductCode,CurrencyProduct) pos
     on decode(risk.RISK_HEDGE_TRADE,26000000,pos.HedgeTrade,risk.RISK_HEDGE_TRADE)=pos.HedgeTrade
     and decode(risk.RISK_DEALER_ID,'0',pos.UserID,risk.RISK_DEALER_ID)=pos.UserID
     and decode(risk.RISK_COMPANY_CODE,30100000,pos.CompanyCode,risk.RISK_COMPANY_CODE)=pos.CompanyCode
     and decode(risk.RISK_LOCATION_CODE,30200000,pos.LocationCode,risk.RISK_LOCATION_CODE)=pos.LocationCode
     and decode(risk.RISK_Product_CODE,33300000,pos.ProductCode,risk.RISK_Product_CODE)=pos.ProductCode
     and decode(risk.RISK_subProduct_CODE,33800000,pos.SubProductCode,risk.RISK_subProduct_CODE)=pos.SubProductCode
     and decode(risk.RISK_CURRENCY_PRODUCT,33200000,pos.CurrencyProduct,risk.RISK_CURRENCY_PRODUCT)=pos.CurrencyProduct

     where (decode(risk.RISK_Risk_TYPE,21000011,abs(PnlDTD),0)>RISK_LIMIT_LOCAL
      or decode(risk.RISK_Risk_TYPE,21000012,abs(PnlMTD),0)>RISK_LIMIT_LOCAL
      or decode(risk.RISK_Risk_TYPE,21000013,abs(PnlQTD),0)>RISK_LIMIT_LOCAL
      or decode(risk.RISK_Risk_TYPE,21000014,abs(PnlYTD),0)>RISK_LIMIT_LOCAL)
      and not exists
        (select 'X' from trtran011 
            where RDEL_COMPANY_CODE=CompanyCode
              and RDEL_LOCATION_CODE=LocationCode
              and RDEL_RISK_TYPE=RISK_RISK_TYPE
              and RDEL_LIMIT_LOCAL= risk_LIMIT_LOCAL
              --and RDEL_CAL_LOCAL= RIPO_INR_VALUE
              and Rdel_stake_holder=risk_stake_holder
              and rdel_product_code= ProductCode
              and rdel_subproduct_code= subproductCode
            ---  and nvl(rdel_currency_product,0)=nvl(CurrencyProduct,0) --commented by prasanta as null
              and RDEL_ACTION_TAKEN=risk_action_taken
              and RDEL_RISK_REFERENCE=RISK_RISK_REFERENCE  ---added by   prasanta
              and RDEL_RISK_DAte=AsonDate);
        
    varOperation := 'Individual Exposure GAP Limit deals';
    
    insert into trtran011
    (RDEL_COMPANY_CODE,RDEL_LOCATION_CODE,RDEL_RISK_REFERENCE,RDEL_DEAL_NUMBER,RDEL_SERIAL_NUMBER,
     RDEL_RISK_TYPE,RDEL_RISK_DATE,RDEL_LIMIT_FCY,RDEL_LIMIT_USD,RDEL_LIMIT_LOCAL,RDEL_LIMIT_PERCENT,
     RDEL_CAL_FCY,rdel_cal_usd,RDEL_CAL_LOCAL, RDEL_ACTION_TAKEN,
     RDEL_STAKE_HOLDER,RDEL_MOBILE_NUMBER,RDEL_EMAIL_ID,RDEL_MESSAGE_TEXT,RDEL_CREATE_DATE,
     RDEL_PRODUCT_code,RDEL_SUBPRODUCT_code,rdel_record_status
     )
      select RIPO_COMPANY_CODE,RIPO_LOCATION_CODE,Risk_Risk_reference,'NA',0,
           RISK_RISK_TYPE,AsonDate,Risk_LIMIT_FCY,Risk_LIMIT_USD,RISK_LIMIT_LOCAL,RISK_LIMIT_PERCENT,
           TransactionAmount TransactionAmount,  RevalueUsd, RevalueInr,risk_action_taken,
           risk_stake_holder,null,pkgriskvalidation.fncgetUserEmailID(risk_stake_holder) EmailId,null,sysdate,
           RIPO_PRODUCT_code,RIPO_SUBPRODUCT_code,10200001
        from (select m.*, (Risk_risk_type-21000021)Gap   
                from trsystem012 m
                where risk_risk_type in (21000021,21000022,21000023,21000024,
                                         21000025,21000026,21000027,21000028,
                                         21000029,21000030,21000031,21000032,21000033)
                and risk_effective_date = ( select max(risk_effective_date)
                          from trsystem012 sub
                         where sub.risk_risk_type =m.risk_risk_type
                          and risk_effective_date <= asondate
                          and risk_record_status not in (10200005,10200006))
        and risk_record_status not in (10200005,10200006))risk
        left outer join 
          (select RIPO_COMPANY_CODE,RIPO_LOCATION_CODE,RIPO_PRODUCT_code,RIPO_SUBPRODUCT_code,RIPO_Counter_party,
--                  sum(RIPO_TRANSACTION_AMOUNT) TransactionAmount,
--                  sum(nvl(Hedg_Hedged_fcy,0)) HedgedAmount,
                 ripo_base_currency,
                (case when ripo_due_date between to_date(AsonDate) and
                         pkgforexprocess.fncgetspotdate(ripo_Counter_party,to_date(AsonDate),1) then
                         0
                     else round(months_between(to_date(AsonDate),ripo_due_date))
                     end) Gap,
                 sum(decode(RIPO_BUY_SELL,25300002,-1,1)*RIPO_TRANSACTION_AMOUNT) TransactionAmount,
                 sum(decode(RIPO_BUY_SELL,25300002,-1,1)*RIPO_REVALUE_USD) RevalueUsd,
                 sum(decode(RIPO_BUY_SELL,25300002,-1,1)*RIPO_INR_VALUE) RevalueInr
             from trsystem997F 
                   group by RIPO_Counter_party,RIPO_COMPANY_CODE,RIPO_LOCATION_CODE,
                            RIPO_PRODUCT_code,
                            RIPO_SUBPRODUCT_code,ripo_base_currency,
                           (case when ripo_due_date between to_date(AsonDate) and
                              pkgforexprocess.fncgetspotdate(ripo_Counter_party,to_date(AsonDate),1) then
                              0
                           else round(months_between(to_date(AsonDate),ripo_due_date))
                           end))  pos 
        on decode(risk.RISK_COUNTER_PARTY,30600000,pos.RIPO_COUNTER_PARTY,risk.RISK_COUNTER_PARTY)=pos.RIPO_COUNTER_PARTY
        and decode(risk.RISK_COMPANY_CODE,30100000,pos.RIPO_COMPANY_CODE,risk.RISK_COMPANY_CODE)=pos.RIPO_COMPANY_CODE
        and decode(risk.RISK_LOCATION_CODE,30200000,pos.RIPO_LOCATION_CODE,risk.RISK_LOCATION_CODE)=pos.RIPO_LOCATION_CODE
        and decode(risk.RISK_Product_code,33300000,pos.RIPO_PRODUCT_code,risk.RISK_COMPANY_CODE)=pos.RIPO_PRODUCT_code
        and decode(risk.RISK_SUBPRODUCT_code,33800000,pos.RIPO_SUBPRODUCT_code,risk.RISK_SUBPRODUCT_code)=pos.RIPO_SUBPRODUCT_code
        and decode(risk.RISK_currency_code,30400000,pos.RIPO_base_currency,risk.RISK_currency_code)=pos.RIPO_base_currency
        and risk.Gap =pos.Gap
     where  ((TransactionAmount>decode(Risk_LIMIT_FCY,0,999999999999999,Risk_LIMIT_FCY)) or
           (RevalueUsd > decode(Risk_LIMIT_USD,0,999999999999999,Risk_LIMIT_USD)) or
           (RevalueInr > decode(RISK_LIMIT_LOCAL,0,999999999999999,RISK_LIMIT_LOCAL)))
        and not exists 
          (select 'X' from trtran011 
            where RDEL_COMPANY_CODE=RIPO_COMPANY_CODE
              and RDEL_LOCATION_CODE=RIPO_LOCATION_CODE
              and RDEL_RISK_TYPE=RISK_RISK_TYPE
              and RDEL_LIMIT_FCY= RDEL_LIMIT_FCY
              and RDEL_LIMIT_USD= RDEL_LIMIT_USD
              and RDEL_LIMIT_LOCAL= RDEL_LIMIT_LOCAL
              and RDEL_CAL_FCY=TransactionAmount
              and Rdel_stake_holder=risk_stake_holder
              and rdel_product_code=RIPO_PRODUCT_code
              and rdel_subproduct_code=RIPO_SUBPRODUCT_code
              and RDEL_ACTION_TAKEN=risk_action_taken
              and RDEL_RISK_DAte=AsonDate);

    varOperation := 'Stop Loss Unhedge';
    
    insert into trtran011
    (RDEL_COMPANY_CODE,RDEL_LOCATION_CODE,RDEL_RISK_REFERENCE,RDEL_DEAL_NUMBER,RDEL_SERIAL_NUMBER,
     RDEL_RISK_TYPE,RDEL_RISK_DATE,RDEL_LIMIT_FCY,RDEL_LIMIT_USD,RDEL_LIMIT_LOCAL,RDEL_LIMIT_PERCENT,
     RDEL_CAL_FCY,rdel_cal_usd,RDEL_CAL_LOCAL, RDEL_ACTION_TAKEN,
     RDEL_STAKE_HOLDER,RDEL_MOBILE_NUMBER,RDEL_EMAIL_ID,RDEL_MESSAGE_TEXT,RDEL_CREATE_DATE,
     RDEL_PRODUCT_code,RDEL_SUBPRODUCT_code,rdel_record_Status)
     
      select RIPO_COMPANY_CODE,RIPO_LOCATION_CODE,Risk_Risk_reference,RIPO_REFERENCE_NUMBER,RIPO_reference_serial,
           RISK_RISK_TYPE,asonDate,Risk_LIMIT_FCY,Risk_LIMIT_USD,RISK_LIMIT_LOCAL,RISK_LIMIT_PERCENT,
           TransactionAmount-HedgedAmount TransactionAmount, 0 RevalueUsd,
           0 RevalueInr,risk_action_taken,
           risk_stake_holder,null,pkgriskvalidation.fncgetUserEmailID(risk_stake_holder) EmailId,null,sysdate,
           RIPO_PRODUCT_code,RIPO_SUBPRODUCT_code,10200001
        from (select * from trsystem012 m
              where risk_risk_type=21000017
              and risk_effective_date = ( select max(risk_effective_date)
                  from trsystem012 sub
                 where sub.risk_risk_type =m.risk_risk_type
                  and risk_effective_date <= asondate
                  and risk_record_status not in (10200005,10200006))
              and risk_record_status not in (10200005,10200006))risk
        left outer join 
          (select RIPO_COMPANY_CODE,RIPO_LOCATION_CODE,RIPO_PRODUCT_code,RIPO_SUBPRODUCT_code,
                  RIPO_REFERENCE_NUMBER,RIPO_reference_serial,RIPO_Counter_party,sum(RIPO_TRANSACTION_AMOUNT) TransactionAmount,
                  ripo_fcy_rate,ripo_m2m_fcyrate,
                  sum(nvl(Hedg_Hedged_fcy,0)) HedgedAmount
             from trsystem997F left outer join trtran004 on Hedg_trade_reference = RIPO_REFERENCE_NUMBER
            where RIPo_hedge_trade is null
                   group by RIPO_Counter_party,RIPO_COMPANY_CODE,RIPO_LOCATION_CODE,
                            RIPO_REFERENCE_NUMBER,RIPO_reference_serial,RIPO_PRODUCT_code,
                            RIPO_SUBPRODUCT_code,ripo_fcy_rate,ripo_m2m_fcyrate)  pos 
        on decode(risk.RISK_COUNTER_PARTY,30600000,pos.RIPO_COUNTER_PARTY,risk.RISK_COUNTER_PARTY)=pos.RIPO_COUNTER_PARTY
        and decode(risk.RISK_COMPANY_CODE,30100000,pos.RIPO_COMPANY_CODE,risk.RISK_COMPANY_CODE)=pos.RIPO_COMPANY_CODE
        and decode(risk.RISK_LOCATION_CODE,30200000,pos.RIPO_LOCATION_CODE,risk.RISK_LOCATION_CODE)=pos.RIPO_LOCATION_CODE
        and decode(risk.RISK_Product_code,33300000,pos.RIPO_PRODUCT_code,risk.RISK_COMPANY_CODE)=pos.RIPO_PRODUCT_code
        and decode(risk.RISK_SUBPRODUCT_code,33800000,pos.RIPO_SUBPRODUCT_code,risk.RISK_SUBPRODUCT_code)=pos.RIPO_SUBPRODUCT_code
     where abs((TransactionAmount-HedgedAmount) * ( ripo_fcy_rate-ripo_m2m_fcyrate))> Risk_LIMIT_local
        and not exists 
          (select 'X' from trtran011 
            where RDEL_COMPANY_CODE=RIPO_COMPANY_CODE
              and RDEL_LOCATION_CODE=RIPO_LOCATION_CODE
              and RDEL_RISK_TYPE=RISK_RISK_TYPE
              and RDEL_LIMIT_FCY= RDEL_LIMIT_FCY
              and RDEL_LIMIT_USD= RDEL_LIMIT_USD
              and RDEL_LIMIT_LOCAL= RDEL_LIMIT_LOCAL
              and RDEL_CAL_FCY=TransactionAmount-HedgedAmount
              and Rdel_stake_holder=risk_stake_holder
              and rdel_product_code=RIPO_PRODUCT_code
              and rdel_subproduct_code=RIPO_SUBPRODUCT_code
              and RDEL_ACTION_TAKEN=risk_action_taken
              and RDEL_RISK_Date=AsonDate);
      commit;        
Exception
    When others then
      NUMERROR := 0;
      varerror := sqlerrm || ' - ' || varerror;
      varError := GConst.fncReturnError('prcRiskPopulateNew', numError, varMessage, 
                     varOperation, varError);
      raise_application_error(-20101,   varerror);
  end prcRiskPopulateNew;    
  
  Function fncgetUserEmailID 
      (varUserids in varchar2) return varchar2
  as
    varQuery varchar(1000);
    varUseridTemp varchar(4000);
    varUserId varchar(50);
    varEmailID varchar(200);
    varEmailIDS varchar(4000);
  begin
     varUseridTemp:=varUserids;
     if instr(varUseridTemp,',',1,1)=0 then
       begin
          select user_email_id 
            into varEmailID
            from trsystem022
           where user_user_id=varUseridTemp
           and user_record_status not in (10200005,10200006);
         exception
          when no_data_found then
             varEmailID:='';
         end;
        return varEmailID;
     end if;
     while (instr(varUseridTemp,',',1,1)>0) 
     loop
        varUserId:= substr(varUseridTemp,1,instr(varUserIDTemp,',',1,1)-1);
        begin
          select user_email_id 
            into varEmailID
            from trsystem022
           where user_user_id=varUserId
           and user_record_status not in (10200005,10200006);
         exception
          when no_data_found then
             varEmailID:='';
         end;
           varEmailIDS:= varEmailIDS || varEmailID || ';';
           varUseridTemp:= substr(varUseridTemp,instr(varUserIDTemp,',',1,1)+1,length(varUserIDTemp));
           if (instr(varUseridTemp,',',1,1)=0) then
                   begin
                      select user_email_id 
                        into varEmailID
                        from trsystem022
                       where user_user_id=varUseridTemp
                       and user_record_status not in (10200005,10200006);
               exception
                when no_data_found then
                   varEmailID:='';
               end;
           end if;
           varEmailIDS:= varEmailIDS || varEmailID || ';';
          --return substr(varUseridTemp,1,instr(varUserIDTemp,',',1,1)-1);
     end loop;
     varEmailIDS:=substr(varEmailIDS,1,LENGTH(varEmailIDS)-1);
     return varEmailIDS;
  end fncgetUserEmailID;
  
  procedure prcActiononRisk (datWorkDate in date)
  as
    NUMERROR            number(15);
    varOperation        GConst.gvarOperation%Type;
    varMessage          GConst.gvarMessage%Type;
    varError            GConst.gvarError%Type;
    FromMail            varchar(100);
    smtpserver          varchar(50);
    smtpPort            varchar(10);
   -- datWorkDate         date;
    varTemp varchar(4000);
  begin
    varOperation:= 'Prepare the data risk deviation alerts';
    
   -- datWorkDate := sysdate;
--    select max(HDAY_CALENDAR_DATE)
--      into datWorkDate
--      from trsystem001
--      where HDAY_DAY_STATUS=26400002
--      and HDAY_LOCATION_CODE=30299999
--      and hday_record_status not in (10200005,10200006);

    --prcRiskPopulateNew (datWorkDate);
    
    select prmc_mail_userid,prmc_smtp_server,prmc_smtp_port
      into FromMail,SmtpServer,SmtpPort
      from trsystem051;    
                 
                 
      for curD in (select pkgreturncursor.fncgetdescription(RDEL_COMPANY_CODE,1) CompanyCode,
                          pkgreturncursor.fncgetdescription(RDEL_LOCATION_CODE,1) LocationCode,
                          RDEL_RISK_REFERENCE RiskReference,RDEL_DEAL_NUMBER DealNumber,RDEL_SERIAL_NUMBER SerialNumber,
                          pkgreturncursor.fncgetdescription(RDEL_RISK_TYPE,1) RiskType,
                          RDEL_RISK_DATE RiskDate,RDEL_LIMIT_FCY LimitFcy,RDEL_LIMIT_USD LimitUSD,
                          RDEL_LIMIT_LOCAL LimitLocal,RDEL_LIMIT_PERCENT LimitPercent,
                          RDEL_CAL_FCY CalFcy,rdel_cal_usd CalUSD,RDEL_CAL_LOCAL CalLocal, RDEL_ACTION_TAKEN ActionTaken,
                          RDEL_STAKE_HOLDER StakeHolder,RDEL_MOBILE_NUMBER MobileNumber,
                          RDEL_EMAIL_ID EmailID,RDEL_MESSAGE_TEXT MessageText,
                          pkgreturncursor.fncgetdescription(RDEL_PRODUCT_code,1) ProductCode,
                          pkgreturncursor.fncgetdescription(RDEL_SUBPRODUCT_code,1) SubProductCode
                     from trtran011
                          where RDEL_RISK_DATE= datWorkDate
                          and  nvl(rdel_record_status,10200001) =10200001
                          and nvl(rdel_sent_status,12400002) =12400002)
      loop 
          varOperation:= 'Checking data inside the alerts';
--          26100001	SMS
--          26100002	Email
--          26100003	Back Office
--          26100004	Suspend Deal
          if (curd.ActionTaken in(26100002, 26100001)) then --Email
           
              varTemp:= '<h4>'|| curd.MessageText || '</h4>';
              varTemp:= varTemp || '<TABLE BORDER=1 BGCOLOR="#EEEEEE">';
              varTemp:=varTemp||'<TR BGCOLOR="Gray">';
              varTemp:=varTemp||'<TH><FONT COLOR="WHITE">Header</FONT>';
              varTemp:=varTemp||'<TH><FONT COLOR="WHITE">Values</FONT>';
              varTemp:=varTemp||'</TR>';
              varTemp:= varTemp || '<TR BGCOLOR="WHITE"><td>Company</td><td>' || curd.CompanyCode || '</td></tr>';
              varTemp:= varTemp || '<TR BGCOLOR="WHITE"<td>Location</td><td>' || curd.LocationCode || '</td></tr>';
              varTemp:= varTemp || '<TR BGCOLOR="WHITE"<td>RiskReference</td><td>' || curd.RiskReference || '</td></tr>';
              varTemp:= varTemp || '<TR BGCOLOR="WHITE"<td>DealNumber</td><td>' || curd.DealNumber || '</td></tr>';
              varTemp:= varTemp || '<TR BGCOLOR="WHITE"<td>SerialNumber</td><td>' || curd.SerialNumber || '</td></tr>';
              varTemp:= varTemp || '<TR BGCOLOR="WHITE"<td>RiskType</td><td>' || curd.RiskType || '</td></tr>';
              varTemp:= varTemp || '<TR BGCOLOR="WHITE"<td>RiskDate</td><td>' || curd.RiskDate || '</td></tr>';
              varTemp:= varTemp || '<TR BGCOLOR="yellow"<td>LimitFcy</td><td>' || pkgreturnreport.fncConvRs(curd.LimitFcy,2,30400004) || '</td></tr>';
              varTemp:= varTemp || '<TR BGCOLOR="yellow"<td>LimitUSD</td><td>' || pkgreturnreport.fncConvRs(curd.LimitUSD,2,30400004) || '</td></tr>';
              varTemp:= varTemp || '<TR BGCOLOR="yellow"<td>LimitLocal</td><td>' || pkgreturnreport.fncConvRs(curd.LimitLocal,2,30400004) || '</td></tr>';
              varTemp:= varTemp || '<TR BGCOLOR="yellow"<td>LimitPercent</td><td>' || pkgreturnreport.fncConvRs(curd.LimitPercent,2,30400004) || '</td></tr>';
              varTemp:= varTemp || '<TR BGCOLOR="yellow"<td>CalculateFcy</td><td>' || pkgreturnreport.fncConvRs(curd.CalFcy,2,30400004) || '</td></tr>';
              varTemp:= varTemp || '<TR BGCOLOR="yellow"<td>CalculateUSD</td><td>' || pkgreturnreport.fncConvRs(curd.CalUSD,2,30400004) || '</td></tr>';
              varTemp:= varTemp || '<TR BGCOLOR="yellow"<td>CalculateLocal</td><td>' || pkgreturnreport.fncConvRs(curd.CalLocal,2,30400004) || '</td></tr>';
              varTemp:= varTemp || '<TR BGCOLOR="WHITE"<td>Product</td><td>' || curd.ProductCode || '</td></tr>';
              varTemp:= varTemp || '<TR BGCOLOR="WHITE"<td>SubProduct</td><td>' || curd.SubProductCode || '</td></tr>';
              varTemp:= varTemp || '</table>';
              
--              Pkgsendingmail.send_mail (Curd.EmailID,FromMail,'','',
--                     Curd.RiskType || ' Violated',
--                     Curd.RiskType || ' got violated please see the below ',varTemp,
--                     SmtpServer,SmtpPort);
         
                 --    Pkgsendingmail.send_mail (Curd.EmailID,'manjunathreddy@ibsfintech.com','','', ' violated',' got violated please see the below ',varTemp,'smtp.ibsfintech.com',25);

              update trtran011 set rdel_sent_status =12400001, rdel_sent_timestamp=to_char(systimestamp, 'DD-MON-YYYY HH24:MI:SS:FF3')  
                where RDEL_RISK_DATE= datWorkDate
                  and RDEL_RISK_REFERENCE=Curd.RiskReference
                  and rdel_record_status =10200001
                  and nvl(rdel_sent_status,12400002) =12400002;

          end if;
          
      end loop;
      commit;
  Exception
    When others then
      NUMERROR := 0;
      varerror := sqlerrm || ' - ' || varerror;
      varError := GConst.fncReturnError('prcRiskPopulateNew', numError, varMessage, 
                     varOperation, varError);
      raise_application_error(-20101,   varerror);
    
  end prcActiononRisk;
  
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
    varRefNumber  varchar2(30);
    varUserID     varchar2(50);
    varEmailID    varchar2(50);
    varQuuery     varchar2(256);
    numActionTaken number(8);
    varEmailid    varchar2(500);
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
 varOperation:= 'Populate the Exposure Data For Export';
  insert into trsystem996A(CRSH_COMPANY_CODE,CRSH_LOCATION_CODE,CRSH_PORTFOLIO_CODE,
  CRSH_SUBPORTFOLIO_CODE,CRSH_REFERENCE_DATE,CRSH_CURRENCY_CODE,CRSH_FOR_CURRENCY,
  CRSH_MATURITY_DATE,CRSH_EXPORT_FCY,CRSH_IMPORT_FCY,CRSH_REFERENCE_NUMBER)
  select TRAD_COMPANY_CODE,TRAD_LOCATION_CODE,trad_Product_category,
     TRAD_SUBPRODUCT_CODE,TRAD_REFERENCE_DATE,TRAD_TRADE_CURRENCY,TRAD_LOCAL_CURRENCY,
     last_day(trunc(TRAD_MATURITY_DATE,'MM')), sum(case when trad_import_export <25900050 then TRAD_TRADE_FCY else 0 end),
     sum(case when trad_import_export >25900050 then TRAD_TRADE_FCY else 0 end),TRAD_TRADE_REFERENCE
   from trtran002
   where TRAD_RECORD_STATUS not in (10200005,10200006)
    and trad_process_complete =12400002
    and trad_import_export <25900050 
   group by TRAD_COMPANY_CODE,TRAD_LOCATION_CODE,trad_Product_category,
       TRAD_SUBPRODUCT_CODE,TRAD_REFERENCE_DATE,TRAD_TRADE_CURRENCY,
       TRAD_LOCAL_CURRENCY,TRAD_MATURITY_DATE,TRAD_TRADE_REFERENCE;
  
  
  BEGIN
  
  FOR cur IN(SELECT MAX(CRSH_MATURITY_DATE) matdate,CRSH_LOCATION_CODE,CRSH_CURRENCY_CODE,
                               CRSH_FOR_CURRENCY,CRSH_PORTFOLIO_CODE FROM trsystem996A GROUP BY CRSH_MATURITY_DATE,
                               CRSH_LOCATION_CODE,CRSH_CURRENCY_CODE,CRSH_FOR_CURRENCY,CRSH_PORTFOLIO_CODE)
  LOOP
    SELECT CRSH_REFERENCE_NUMBER INTO varRefNumber  FROM trsystem996A WHERE CRSH_MATURITY_DATE = cur.matdate
                                                          AND CRSH_LOCATION_CODE = cur.CRSH_LOCATION_CODE
                                                          and CRSH_CURRENCY_CODE = cur.CRSH_CURRENCY_CODE
                                                          and CRSH_FOR_CURRENCY = cur.CRSH_FOR_CURRENCY
                                                          and CRSH_PORTFOLIO_CODE = cur.CRSH_PORTFOLIO_CODE
                                                          AND ROWNUM = 1; --ORDER BY CRSH_REFERENCE_DATE;
    UPDATE trsystem996A SET  CRSH_IMPORT_FCY  = 
        (select  sum(TRAD_TRADE_FCY)
       from trtran002
       where TRAD_RECORD_STATUS not in (10200005,10200006)
        and trad_process_complete =12400002
        and trad_import_export > 25900050
        and last_day(trunc(TRAD_MATURITY_DATE,'MM'))=last_day(trunc(CRSH_MATURITY_DATE,'MM'))
        and TRAD_LOCATION_CODE=CRSH_LOCATION_CODE
        and trad_Product_category=CRSH_PORTFOLIO_CODE
        AND TRAD_TRADE_CURRENCY=CRSH_CURRENCY_CODE
        and TRAD_LOCAL_CURRENCY=CRSH_FOR_CURRENCY
       group by TRAD_COMPANY_CODE,TRAD_LOCATION_CODE,trad_Product_category,
           TRAD_SUBPRODUCT_CODE,TRAD_REFERENCE_DATE,TRAD_TRADE_CURRENCY,
           TRAD_LOCAL_CURRENCY,TRAD_MATURITY_DATE) WHERE CRSH_REFERENCE_NUMBER = varRefNumber;
  END LOOP;
  
  END;

 varOperation:= 'Update the Net Exposure';
 update trsystem996A set CRSH_NET_EXPOSURE= NVL(CRSH_EXPORT_FCY,0)-NVL(CRSH_IMPORT_FCY,0);

 varOperation:= 'Update the Hedged FCY';
 
  update  trsystem996A set (CRSH_HEDGE_BUY,CRSH_HEDGE_SELL,CRSH_HEDGE_BUYRATE,CRSH_HEDGE_SELLRATE)=
  ( select sum(case when (deal_buy_sell=25300001) then HEDG_HEDGED_FCY else 0 end),
           sum(case when (deal_buy_sell=25300002) then HEDG_HEDGED_FCY else 0 end),
           (sum(case when (deal_buy_sell=25300001) then HEDG_HEDGED_FCY*Deal_Exchange_RATE else 0 end)/
            decode(sum(case when (deal_buy_sell=25300001) then HEDG_HEDGED_FCY else 0 end),0,1,
             sum(case when (deal_buy_sell=25300001) then HEDG_HEDGED_FCY else 0 end) )),
           (sum(case when (deal_buy_sell=25300002) then HEDG_HEDGED_FCY*Deal_Exchange_RATE else 0 end)/
            decode(sum(case when (deal_buy_sell=25300002) then HEDG_HEDGED_FCY else 0 end),0,1,
             sum(case when (deal_buy_sell=25300002) then HEDG_HEDGED_FCY else 0 end) ))
     from trtran004 inner join trtran001
     on HEDG_DEAL_NUMBER= deal_deal_number

     where  DEAL_COMPANY_CODE=CRSH_COMPANY_CODE
      and DEAL_LOCATION_CODE=CRSH_LOCATION_CODE
      and DEAL_BACKUP_DEAL=CRSH_PORTFOLIO_CODE
    --  and DEAL_INIT_CODE=CRSH_SUBPORTFOLIO_CODE
      and DEAL_BASE_CURRENCY=CRSH_CURRENCY_CODE
      and DEAL_OTHER_CURRENCY=CRSH_FOR_CURRENCY
      AND HEDG_TRADE_REFERENCE = CRSH_REFERENCE_NUMBER
      and last_day(trunc(DEAL_MATURITY_DATE,'MM'))=last_day(trunc(CRSH_MATURITY_DATE,'MM'))
      and deal_Record_Status not in (10200005,10200006)
      and Hedg_Record_Status not in (10200005,10200006)
      and deal_process_complete =12400002);
      
--HEDG_TRADE_REFERENCE in (select TRAD_TRADE_REFERENCE from trtran002
--            where trad_reference_Date = CRSH_REFERENCE_DATE)
--      and
      
 varOperation:= 'Update the Hedged FCY';
 update trsystem996A set CRSH_TOT_HEDGE= abs(CRSH_HEDGE_SELL-CRSH_HEDGE_BUY);
 
 varOperation:= 'Update the First Forward Rate';
  
  update  trsystem996A set CRSH_FIRSTFORWARD_RATE=fncGetHedgeRate(CRSH_REFERENCE_DATE,
          CRSH_COMPANY_CODE,CRSH_LOCATION_CODE,CRSH_PORTFOLIO_CODE,CRSH_SUBPORTFOLIO_CODE,
          CRSH_CURRENCY_CODE,CRSH_FOR_CURRENCY,CRSH_MATURITY_DATE);

 varOperation:= 'Update the Hedged Percentage';
 update trsystem996A set CRSH_PERCENTAGE_HEDGE= (abs(nvl(CRSH_TOT_HEDGE,0))/abs(CRSH_NET_EXPOSURE)) *100
  where CRSH_NET_EXPOSURE !=0;
 
 commit;
  varOperation:= 'Update the Hedged Percentage';
 update trsystem996A set CRSH_MTM_RATE= pkgforexprocess.fncgetrate(CRSH_CURRENCY_CODE, CRSH_FOR_CURRENCY,
          asonDate,25300001,0,CRSH_MATURITY_DATE) ;  

  varOperation:= 'Update the Lock in Rate';
 update trsystem996A set (CRSH_LOCKIN_RATE,CRSH_Action_taken,crsh_action_emailids,
                          crsh_limit_min , crsh_limit_max)
                          = (select RISK_LOCKINRATE,
                    RISK_ACTION_TAKEN,pkgriskvalidation.fncgetUserEmailID(risk_stake_holder) EmailId,
                          RISK_LIMIT_PERCENT,RISK_FLUCT_ALLOWED
                    from trsystem012 
                    where decode(RISK_COMPANY_CODE,30100000,CRSH_COMPANY_CODE,RISK_COMPANY_CODE)= CRSH_COMPANY_CODE
                      and decode(RISK_CURRENCY_CODE,30400000,CRSH_CURRENCY_CODE,RISK_CURRENCY_CODE)=CRSH_CURRENCY_CODE
                      and decode(RISK_PRODUCT_CODE,33300000,CRSH_PORTFOLIO_CODE,RISK_PRODUCT_CODE)=CRSH_PORTFOLIO_CODE
                      and decode(RISK_SUBPRODUCT_CODE,33800000,CRSH_SUBPORTFOLIO_CODE,RISK_SUBPRODUCT_CODE)=CRSH_SUBPORTFOLIO_CODE
                      and decode(RISK_LOCATION_CODE,30200000,CRSH_LOCATION_CODE,RISK_LOCATION_CODE) =CRSH_LOCATION_CODE
                      and CRSH_PERCENTAGE_HEDGE between RISK_LIMIT_PERCENT and RISK_FLUCT_ALLOWED
                      and RISK_RISK_TYPE= 21000020
                      and RISK_RECORD_STATUS not in (10200005,10200006) );
 
   varOperation:= 'Update the Next Lock-in Rate';
   update trsystem996A set (CRSH_NextLOCKIN_RATE ,
                            crsh_Nextlimit_min  , crsh_Nextlimit_max)
                            = (select RISK_LOCKINRATE,
                                    RISK_LIMIT_PERCENT,RISK_FLUCT_ALLOWED
                      from trsystem012 
                      where decode(RISK_COMPANY_CODE,30100000,CRSH_COMPANY_CODE,RISK_COMPANY_CODE)= CRSH_COMPANY_CODE
                        and decode(RISK_CURRENCY_CODE,30400000,CRSH_CURRENCY_CODE,RISK_CURRENCY_CODE)=CRSH_CURRENCY_CODE
                        and decode(RISK_PRODUCT_CODE,33300000,CRSH_PORTFOLIO_CODE,RISK_PRODUCT_CODE)=CRSH_PORTFOLIO_CODE
                        and decode(RISK_SUBPRODUCT_CODE,33800000,CRSH_SUBPORTFOLIO_CODE,RISK_SUBPRODUCT_CODE)=CRSH_SUBPORTFOLIO_CODE
                        and decode(RISK_LOCATION_CODE,30200000,CRSH_LOCATION_CODE,RISK_LOCATION_CODE) =CRSH_LOCATION_CODE
                        and CRSH_PERCENTAGE_HEDGE +1 between RISK_LIMIT_PERCENT and RISK_FLUCT_ALLOWED
                        and RISK_RISK_TYPE= 21000020
                        and RISK_RECORD_STATUS not in (10200005,10200006) );
                      

   PRCExchangeRateVaR(asonDate,90);
   
   varOperation:= 'Update the Risk Adjusted Return';
   update trsystem996A set CRSH_Adjusted_Return =fncRiskAdjustedMTMRate(CRSH_CURRENCY_CODE,
           CRSH_FOR_CURRENCY,25300001,asonDate,CRSH_MATURITY_DATE);

    varOperation:= 'Update the Risk Adjusted MTM Rate';
   update trsystem996A set CRSH_Adjusted_MTMRATE =CRSH_Adjusted_Return+CRSH_MTM_RATE;
   
   varOperation:= 'Update the Budget Rate';
   update trsystem996A set CRSH_BUDGET_RATE = CRSH_FIRSTFORWARD_RATE + (CRSH_FIRSTFORWARD_RATE * (-0.02));

   varOperation:= 'Update the Total Hedge Rate';
   update trsystem996A set CRSH_TOT_HEDGERATE = 
              (case when (CRSH_HEDGE_SELL <=CRSH_HEDGE_BUY) then CRSH_HEDGE_BUYRATE
              when (CRSH_HEDGE_SELL >=CRSH_HEDGE_BUY) then CRSH_HEDGE_SELLRATE end );
        
   varOperation:= 'Update the  Portfolio Rate';
   update trsystem996A set CRSH_PORTFOLIO_RATE = 
      ((((CRSH_NET_EXPOSURE-CRSH_TOT_HEDGE) * CRSH_MTM_RATE)+ 
        (CRSH_TOT_HEDGE* CRSH_TOT_HEDGERATE))/
        decode(CRSH_NET_EXPOSURE,0,1,CRSH_NET_EXPOSURE));
                            
   varOperation:= 'Insert the data into Log table to send the e-mail Trigger Where No Hedging Done';
   
    insert into trtran011
    (RDEL_COMPANY_CODE,RDEL_LOCATION_CODE,RDEL_RISK_REFERENCE,RDEL_DEAL_NUMBER,
    RDEL_SERIAL_NUMBER,
     RDEL_RISK_TYPE,RDEL_RISK_DATE,RDEL_LIMIT_PERCENT,
     RDEL_CAL_FCY,rdel_cal_usd, RDEL_ACTION_TAKEN,
     RDEL_EMAIL_ID,RDEL_MESSAGE_TEXT,RDEL_CREATE_DATE,
     RDEL_PRODUCT_code,RDEL_SUBPRODUCT_code,rdel_record_Status)
     
     select CRSH_COMPANY_CODE,CRSH_LOCATION_CODE,' ',' ',1,21000020,asonDate,
            crsh_limit_max,CRSH_NET_EXPOSURE,CRSH_TOT_HEDGE,
            CRSH_Action_taken,crsh_action_emailids,'The New Exposure has been identified for the Amount ' || CRSH_NET_EXPOSURE
             || ' and Maturity Date ' || CRSH_MATURITY_DATE ||
             'please lock the rate by booking the Forward Contrat',sysdate,
            CRSH_PORTFOLIO_CODE,CRSH_SUBPORTFOLIO_CODE,10200001
       from trsystem996A
      where CRSH_PERCENTAGE_HEDGE = 0;
      
    varOperation:= 'Insert the data into Log table to send the e-mail Trigger';
   
    insert into trtran011
    (RDEL_COMPANY_CODE,RDEL_LOCATION_CODE,RDEL_RISK_REFERENCE,RDEL_DEAL_NUMBER,
    RDEL_SERIAL_NUMBER,
     RDEL_RISK_TYPE,RDEL_RISK_DATE,RDEL_LIMIT_PERCENT,
     RDEL_CAL_FCY,rdel_cal_usd, RDEL_ACTION_TAKEN,
     RDEL_EMAIL_ID,RDEL_MESSAGE_TEXT,RDEL_CREATE_DATE,
     RDEL_PRODUCT_code,RDEL_SUBPRODUCT_code,rdel_record_Status)
     
     select CRSH_COMPANY_CODE,CRSH_LOCATION_CODE,' ',' ',1,21000020,asonDate,
            crsh_limit_max,CRSH_NET_EXPOSURE,CRSH_TOT_HEDGE,
            CRSH_Action_taken,crsh_action_emailids,'The Lock-in rate Tigger has been fired for Hedge Percentage form ' ||
            CRSH_LIMIT_MIN || ' To ' || CRSH_LIMIT_MAX || ' and Maturity Date ' || CRSH_MATURITY_DATE ||
             ' Please Cover Following Amount ' || ((CRSH_PERCENTAGE_HEDGE-CRSH_LIMIT_MAX)/100) * CRSH_NET_EXPOSURE
             ,sysdate,
            CRSH_PORTFOLIO_CODE,CRSH_SUBPORTFOLIO_CODE,10200001
       from trsystem996A
      where CRSH_PERCENTAGE_HEDGE != 0
      and CRSH_LOCKIN_RATE+CRSH_FIRSTFORWARD_RATE >=CRSH_MTM_RATE
      and CRSH_PERCENTAGE_HEDGE-CRSH_LIMIT_MAX <0
      and CRSH_LIMIT_MIN = CRSH_NEXTLIMIT_MIN
      and CRSH_LIMIT_MAX=CRSH_NEXTLIMIT_MAX;
      
 
    varOperation:= 'Insert the data into Log table to send the e-mail Trigger';
   
    insert into trtran011
    (RDEL_COMPANY_CODE,RDEL_LOCATION_CODE,RDEL_RISK_REFERENCE,RDEL_DEAL_NUMBER,
    RDEL_SERIAL_NUMBER,
     RDEL_RISK_TYPE,RDEL_RISK_DATE,RDEL_LIMIT_PERCENT,
     RDEL_CAL_FCY,rdel_cal_usd, RDEL_ACTION_TAKEN,
     RDEL_EMAIL_ID,RDEL_MESSAGE_TEXT,RDEL_CREATE_DATE,
     RDEL_PRODUCT_code,RDEL_SUBPRODUCT_code,rdel_record_Status)
     
     select CRSH_COMPANY_CODE,CRSH_LOCATION_CODE,' ',' ',1,21000020,asonDate,
            crsh_limit_max,CRSH_NET_EXPOSURE,CRSH_TOT_HEDGE,
            CRSH_Action_taken,crsh_action_emailids,'The Lock-in rate Tigger has been fired for Hedge Percentage form ' ||
            CRSH_LIMIT_MIN || ' To ' || CRSH_LIMIT_MAX || ' and Maturity Date ' || CRSH_MATURITY_DATE ||
             ' Please Cover Following Amount ' || ((CRSH_PERCENTAGE_HEDGE-CRSH_LIMIT_MAX)/100) * CRSH_NET_EXPOSURE
             ,sysdate,
            CRSH_PORTFOLIO_CODE,CRSH_SUBPORTFOLIO_CODE,10200001
       from trsystem996A
      where CRSH_PERCENTAGE_HEDGE != 0
      and CRSH_NEXTLOCKIN_RATE+CRSH_FIRSTFORWARD_RATE >=CRSH_MTM_RATE
      and CRSH_LIMIT_MIN != CRSH_NEXTLIMIT_MIN
      and CRSH_PERCENTAGE_HEDGE-CRSH_NEXTLIMIT_MIN <0
      and CRSH_LIMIT_MAX!=CRSH_NEXTLIMIT_MAX;
      
   varOperation:= 'Insert the data into Log table to send the e-mail Trigger Complete Hedging ';
   
    insert into trtran011
    (RDEL_COMPANY_CODE,RDEL_LOCATION_CODE,RDEL_RISK_REFERENCE,RDEL_DEAL_NUMBER,
    RDEL_SERIAL_NUMBER,
     RDEL_RISK_TYPE,RDEL_RISK_DATE,RDEL_LIMIT_PERCENT,
     RDEL_CAL_FCY,rdel_cal_usd, RDEL_ACTION_TAKEN,
     RDEL_EMAIL_ID,RDEL_MESSAGE_TEXT,RDEL_CREATE_DATE,
     RDEL_PRODUCT_code,RDEL_SUBPRODUCT_code,rdel_record_Status)
     
     select CRSH_COMPANY_CODE,CRSH_LOCATION_CODE,' ',' ',1,21000020,asonDate,
            crsh_limit_max,CRSH_NET_EXPOSURE,CRSH_TOT_HEDGE,
            CRSH_Action_taken,crsh_action_emailids,' MTM Rate is going Below -2 '||
             ' , So Hedge Complete Amount ' || ((CRSH_PERCENTAGE_HEDGE-100)/100) * CRSH_NET_EXPOSURE ||
          ' For the Maturity Date ' || CRSH_MATURITY_DATE             
             ,sysdate,
            CRSH_PORTFOLIO_CODE,CRSH_SUBPORTFOLIO_CODE,10200001
       from trsystem996A
      where CRSH_PERCENTAGE_HEDGE != 0
      and CRSH_BUDGET_RATE >=CRSH_MTM_RATE;
      
      
      
    -- where CRSH_PERCENTAGE_HEDGE <=
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
    from ( select row_number() over (order by deal_execute_date,deal_time_stamp ) Rownumber,
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
                      and last_day(trunc(DEAL_MATURITY_DATE,'MM'))=MaturityDate)
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

Function fncRiskAdjustedMTMRate
       (CurrencyCode in number,
        ForCurrency in Number,
        BuySell in Number,
        AsonDate in Date,
        MaturityDate in date ) return number
is
   RiskAdjustedMTMRate number(15,6);
  varOperation  GConst.gvarOperation%type;
  varMessage    gconst.gvarMessage%type;
  varError      gconst.gvarError%type;
begin
varOperation := 'Get the Risk Adjusted MTM Rate ' || CurrencyCode || ' ' || ForCurrency || ' ' || BuySell || ' ' || ' ' || AsonDate || ' ' || MaturityDate;
  
 if BuySell=25300001 then
    select RVAR_RATE_RETURN 
      into RiskAdjustedMTMRate
    from 
      (select row_number() over (order by RVAR_RATE_RETURN asc) Row_num,
           RVAR_RATE_RETURN
       from trsystem996B
      where RVAR_CURRENCY_CODE=CurrencyCode
        and RVAR_FOR_CURRENCY=ForCurrency
        and RVAR_EFFECTIVE_DATE=AsonDate)
      where Row_num=5;
 else
     select RVAR_RATE_RETURN
     into RiskAdjustedMTMRate
     from 
      (select row_number() over (order by RVAR_RATE_RETURN Desc) Row_num,
           RVAR_RATE_RETURN
       from trsystem996B
      where RVAR_CURRENCY_CODE=CurrencyCode
        and RVAR_FOR_CURRENCY=ForCurrency
        and RVAR_EFFECTIVE_DATE=AsonDate)
      where Row_num=5;
 end if;
 
 return RiskAdjustedMTMRate;
exception 

  when others then 
      varError := SQLERRM;
      varerror := 'fncRiskAdjustedMTMRate: ' || varmessage || varoperation || varerror;
      raise_application_error(-20101,   varerror);
end fncRiskAdjustedMTMRate;


Procedure PRCExchangeRateVaR 
   (AsonDate in date,
   NoofDays in Number)
as
  numdaysDiff number(5);
  varOperation  GConst.gvarOperation%type;
  varMessage    gconst.gvarMessage%type;
  varError      gconst.gvarError%type;
begin
 delete from trsystem996B;
 varOperation:= ' Enter into Loop To get the required details to calcuate the Rate Var';
  for cur in (select Distinct CRSH_CURRENCY_CODE CurrencyCode,
                    CRSH_FOR_CURRENCY ForCurrency,
                    crsh_maturity_date MaturityDate
              from trsystem996A)
  loop
   varOperation:= ' Enter into inner loop for Base ' || cur.CurrencyCode || ' For ' || cur.ForCurrency || ' Maturity Date ' || cur.MaturityDate  ;
      for curR in (select distinct DRAT_EFFECTIVE_DATE EffectiveDate 
                     from trtran012
                     where drat_Currency_code=cur.CurrencyCode
                       and drat_for_currency= cur.ForCurrency
                       and DRAT_EFFECTIVE_DATE >= AsonDate -NoofDays
                       and DRAT_EFFECTIVE_DATE <=AsonDate)
       loop  
       
          varOperation:= ' Enter into inside the inner loop for Base ' || cur.CurrencyCode || ' For ' || cur.ForCurrency || ' Effecitve Date ' || curR.EffectiveDate  ;
          numdaysDiff:= cur.MaturityDate- AsonDate;
           
           insert into trsystem996B (RVAR_EFFECTIVE_DATE,RVAR_RATE_DATE,
                RVAR_CURRENCY_CODE,RVAR_FOR_CURRENCY,
                RVAR_Maturity_DATE,RVAR_EXCHAGE_RATE,RVAR_EFFMATURITY_DATE)
             values (AsonDate,curR.EffectiveDate,cur.CurrencyCode,
                    cur.ForCurrency,CURR.EffectiveDate +numdaysDiff,
                pkgforexprocess.fncgetrate(cur.CurrencyCode, cur.ForCurrency,
                    curR.EffectiveDate,25300002,0,curR.EffectiveDate +numdaysDiff ),
                    cur.MaturityDate); 
       end loop;
  END LOOP ;
  
  varOperation:= ' Update the Rate Return ' ;
  
  update trsystem996B M set RVAR_RATE_RETURN=  nvl((((select s.RVAR_EXCHAGE_RATE 
                                               from trsystem996B S
                                              where M.RVAR_EFFECTIVE_DATE= S.RVAR_EFFECTIVE_DATE
                                                and M.RVAR_CURRENCY_CODE=S.RVAR_CURRENCY_CODE
                                                and M.RVAR_FOR_CURRENCY=S.RVAR_FOR_CURRENCY       
                                                and M.RVAR_EFFMATURITY_DATE= S.RVAR_EFFMATURITY_DATE
                                                and M.RVAR_RATE_DATE = (select max(RVAR_RATE_DATE) 
                                                                   from trsystem996B Sub
                                                                  where Sub.RVAR_EFFECTIVE_DATE= S.RVAR_EFFECTIVE_DATE
                                                                    and Sub.RVAR_CURRENCY_CODE=S.RVAR_CURRENCY_CODE
                                                                    and Sub.RVAR_FOR_CURRENCY=S.RVAR_FOR_CURRENCY
                                                                    and sub.RVAR_EFFMATURITY_DATE= s.RVAR_EFFMATURITY_DATE
                                                                    and Sub.RVAR_RATE_DATE <S.RVAR_RATE_DATE))
                                                  -RVAR_EXCHAGE_RATE)/RVAR_EXCHAGE_RATE),0)
  where RVAR_EFFECTIVE_DATE=AsonDate;
  
  commit;
exception 
  when others then 
      varError := SQLERRM;
      varerror := 'fncGetHedgeRate: ' || varmessage || varoperation || varerror;
      raise_application_error(-20101,   varerror);

end PRCExchangeRateVaR;
END pkgriskvalidation;
/