CREATE OR REPLACE PROCEDURE "TEST_VSTSRedgate"."PRCEFFECTIVERATERPT" 
(FrmDate  DATE ,Todate DATE,ReportID Varchar,Condition Varchar)
AS
    Frm_date            DATE;
    To_date             DATE;
    VarEntity           varchar2(30 Byte);
    varmsg              varchar2(2000);
    tempDate            date;
    dattemp1            date;
    temp                date;
    SpotRate            number(15,6);
    SpotRate1           number(15,6);            
    dattemp2            date;
BEGIN
    Frm_date            := FrmDate;
    To_date             := Todate;
    VarEntity           := ReportID;
 ----------------OPEN HEDGE--------------------------------------------
delete from trsystem976;
If VarEntity = 'SOSREPORT' then
  IF (TO_CHAR(FrmDate,'MM') <=4) THEN
    tempDate                := '01-APR-' ||(TO_CHAR(FrmDate,'YYYY')-1) ;
  ELSE
    tempDate:= '01-APR-' || TO_CHAR(FrmDate,'YYYY');
  END IF;


--FOR Cur_date IN  (SELECT DISTINCT posn_mtm_date FROM trsystem997D WHERE posn_mtm_date BETWEEN Frm_date AND To_date
--                        ORDER BY posn_mtm_date)
--LOOP
--      To_date := Cur_date.posn_mtm_date;
--      ---Privous Working Day and SpotRate----------------
--      SELECT MAX(posn_mtm_date) INTO dattemp2 FROM trsystem997d WHERE posn_mtm_date < To_date ;
--      SpotRate   :=  pkgforexprocess.fncGetRate(30400004,30400003,To_date,0,0,NULL,0);
--
--      INSERT INTO trsystem976 
--        (effe_Spot_Rate,effe_Description,effe_ason_date)
--      SELECT SpotRate,'SpotRate',To_date FROM dual
--      GROUP BY To_date;
--      SpotRate1  :=  pkgforexprocess.fncGetRate(30400004,30400003,dattemp2,0,0,NULL,0);            
--      ------------Exposure Open Unhedge--------------------------
--      INSERT INTO TRSYSTEM976 
--              (EFFE_AMOUNT_FCY,EFFE_DESCRIPTION,EFFE_ASON_DATE,Effe_Effect_Inr,Effe_Cost_Inr,Effe_Currency_Code,effe_company_code)
--      SELECT SUM(Posn_Transaction_Amount),posn_hedge_trade,To_date,
--      SUM(posn_mtm_fcyrate * Posn_Transaction_Amount),
--              SUM(Posn_Transaction_Amount*posn_fcy_rate),Posn_Currency_Code,Posn_Company_Code
--      FROM trsystem997d
--      WHERE posn_mtm_date    = To_date
--      AND posn_hedge_trade   = 'E'
--      GROUP BY posn_hedge_trade,To_date,Posn_Currency_Code,Posn_Company_Code;
--      ---------FC DELIVERY--------------------------------------------
--      INSERT INTO TRSYSTEM976 
--              (EFFE_AMOUNT_FCY,EFFE_DESCRIPTION,EFFE_ASON_DATE,Effe_Effect_Inr,Effe_Cost_Inr,Effe_Currency_Code,effe_company_code)
--      SELECT SUM(Posn_Transaction_Amount),posn_hedge_trade,To_date,SUM(Posn_Transaction_Amount*Posn_Cancel_Rate),
--              SUM(Posn_Transaction_Amount*Posn_Fcy_Rate),Posn_Currency_Code,Posn_Company_Code
--      FROM trsystem997d
--      WHERE posn_mtm_date BETWEEN tempDate AND To_date
--      AND posn_hedge_trade   = 'EFC'
--      GROUP BY posn_hedge_trade,To_date,Posn_Currency_Code,Posn_Company_Code;
--      -------------CASH SETTLE---------------------------------------
--      INSERT INTO TRSYSTEM976 
--              (EFFE_AMOUNT_FCY,EFFE_DESCRIPTION,EFFE_ASON_DATE,Effe_Effect_Inr,Effe_Cost_Inr,Effe_Currency_Code,effe_company_code)
--      SELECT SUM(Posn_Transaction_Amount),posn_hedge_trade,To_date,SUM(Posn_Transaction_Amount*Posn_Cancel_Rate),
--              SUM(Posn_Transaction_Amount*Posn_Fcy_Rate),Posn_Currency_Code,Posn_Company_Code
--      FROM trsystem997d
--      WHERE posn_mtm_date BETWEEN tempDate AND To_date
--      AND posn_hedge_trade   = 'ECS'
--      GROUP BY posn_hedge_trade,To_date,Posn_Currency_Code,Posn_Company_Code;
---------------------------------------------FC CNCEL---------------
--      INSERT INTO TRSYSTEM976 
--              (Effe_PanL_Amount,EFFE_DESCRIPTION,EFFE_ASON_DATE,Effe_Currency_Code,effe_company_code)
--      SELECT SUM(Posn_Cancel_Pnl),posn_hedge_trade,To_date,Posn_Currency_Code,Posn_Company_Code
--      FROM trsystem997d
--      WHERE posn_mtm_date BETWEEN tempDate AND To_date
--      AND posn_hedge_trade   = 'HC'
--      GROUP BY posn_hedge_trade,To_date,Posn_Currency_Code,Posn_Company_Code;
--      ---------------------------------HEDGE MTM---------------
--      INSERT INTO TRSYSTEM976 
--              (effe_amount_mtmpl,EFFE_DESCRIPTION,EFFE_ASON_DATE,Effe_Amount_Fcy,Effe_Currency_Code,effe_company_code)
--      SELECT SUM(Pkgforexprocess.fncgetprofitloss( Posn_Transaction_Amount,
--              posn_mtm_fcyrate,
--              posn_fcy_rate,
--              CASE WHEN posn_account_code < 25900050 THEN 25300001 ELSE 25300002 END )), 
--              posn_hedge_trade,To_date,SUM(Posn_Transaction_Amount),Posn_Currency_Code,Posn_Company_Code
--      FROM trsystem997d
--      WHERE posn_mtm_date    = To_date
--      AND posn_hedge_trade   IN('H')
--      GROUP BY posn_hedge_trade,To_date,Posn_Currency_Code,Posn_Company_Code;
--      ---------------------------'CURRENCY FUTURE' ---------------------------------
--      INSERT INTO TRSYSTEM976 
--              (effe_amount_mtmpl,EFFE_DESCRIPTION,EFFE_ASON_DATE,Effe_Amount_Fcy,Effe_Currency_Code,effe_company_code)
--      SELECT SUM(Pkgforexprocess.fncgetprofitloss( Posn_Transaction_Amount,
--                                                pkgforexprocess.fncFutureMTMRate(POSN_DUE_DATE,POSN_COUNTER_PARTY,posn_currency_code,
--                                                posn_other_currency,To_date),
--                                                posn_fcy_rate,
--                                                CASE WHEN posn_account_code < 25900050 THEN 25300001 ELSE 25300002 END)),
--              'CFBUY',To_date,sum(Posn_Transaction_Amount),Posn_Currency_Code,Posn_Company_Code
--      FROM trsystem997d
--      WHERE posn_mtm_date    = To_date
--      AND posn_hedge_trade   IN('HF','TF')
--      and posn_account_code < 25900050
--      GROUP BY posn_hedge_trade,To_date,Posn_Currency_Code,Posn_Company_Code;
--      
--      INSERT INTO TRSYSTEM976 
--              (effe_amount_mtmpl,EFFE_DESCRIPTION,EFFE_ASON_DATE,Effe_Amount_Fcy,Effe_Currency_Code,effe_company_code)
--      SELECT SUM(Pkgforexprocess.fncgetprofitloss( Posn_Transaction_Amount,
--                                                pkgforexprocess.fncFutureMTMRate(POSN_DUE_DATE,POSN_COUNTER_PARTY,posn_currency_code,
--                                                posn_other_currency,To_date),
--                                                posn_fcy_rate,
--                                                CASE WHEN posn_account_code < 25900050 THEN 25300001 ELSE 25300002 END)),
--              'CFSELL',To_date,sum(Posn_Transaction_Amount),Posn_Currency_Code,Posn_Company_Code
--      FROM trsystem997d
--      WHERE posn_mtm_date    = To_date
--      and posn_account_code > 25900050
--      AND posn_hedge_trade   IN('HF','TF')
--      GROUP BY posn_hedge_trade,To_date,Posn_Currency_Code,Posn_Company_Code;
--      -----Future Cancel-------------------
--      INSERT INTO TRSYSTEM976 
--              (Effe_PanL_Amount,EFFE_DESCRIPTION,EFFE_ASON_DATE,Effe_Currency_Code,effe_company_code)
--      SELECT SUM(Posn_Cancel_Pnl),posn_hedge_trade,To_date,Posn_Currency_Code,Posn_Company_Code
--      FROM trsystem997d
--      WHERE posn_mtm_date BETWEEN tempDate AND To_date
--      AND posn_hedge_trade   IN('HFC','TFC')
--      GROUP BY posn_hedge_trade,To_date,Posn_Currency_Code,Posn_Company_Code;
--          ------------------'CURRENCY OPTION'-------------------
--      INSERT INTO TRSYSTEM976 
--            (effe_amount_mtmpl,EFFE_DESCRIPTION,EFFE_ASON_DATE,Effe_Currency_Code,effe_company_code)
--      SELECT
----            SUM(DECODE(SIGN(25900050 - POSN_ACCOUNT_CODE),1 , NVL(POSN_TRANSACTION_AMOUNT*(POSN_FCY_RATE -POSN_MTM_FCYRATE) ,0),
----                            -1,NVL(POSN_TRANSACTION_AMOUNT*(POSN_MTM_FCYRATE -POSN_FCY_RATE) ,0))),
--            Sum(pkgForexProcess.fncGetOptionMTM(posn_reference_number,To_date,'N')),
--            posn_hedge_trade,To_date,Posn_Currency_Code,Posn_Company_Code
--      FROM trsystem997d
--      WHERE posn_mtm_date    = To_date
--      AND posn_hedge_trade   IN('HO','TO')
--      GROUP BY posn_hedge_trade,To_date,Posn_Currency_Code,Posn_Company_Code;
--      --------------------------------------Option Cancel
--      INSERT INTO TRSYSTEM976 
--            (Effe_PanL_Amount,EFFE_DESCRIPTION,EFFE_ASON_DATE,Effe_Currency_Code,effe_company_code)
--      SELECT 
--            SUM(Posn_Cancel_Pnl),posn_hedge_trade,To_date,Posn_Currency_Code,Posn_Company_Code
--      FROM trsystem997d
--      WHERE posn_mtm_date BETWEEN tempDate AND To_date
--      AND posn_hedge_trade   IN('HOC','TOC')
--      GROUP BY posn_hedge_trade,To_date,Posn_Currency_Code,Posn_Company_Code;
--     ---------Intraday Future PandL---------------------
--      INSERT INTO TRSYSTEM976 
--            (Effe_PanL_Amount,EFFE_DESCRIPTION,EFFE_ASON_DATE,effe_company_code,effe_currency_code)
--      SELECT SUM(ProfitLoss),'INFUTIMPT',To_date,CompanyCode,BaseCurrency
--      FROM vewCancelDeals WHERE dealtype LIKE '%Fut%' 
--      AND Dealdate = Canceldate 
--      AND Canceldate = To_date 
--      GROUP BY To_date,CompanyCode,BaseCurrency;
-----------------Intraday Option Pandl-------------------
--      INSERT INTO TRSYSTEM976 
--            (Effe_PanL_Amount,EFFE_DESCRIPTION,EFFE_ASON_DATE,effe_company_code,effe_currency_code)
--      SELECT SUM(ProfitLoss),'INOPTIMPT',To_date,CompanyCode,BaseCurrency
--      FROM vewCancelDeals WHERE dealtype LIKE '%Opt%' 
--      AND Dealdate = Canceldate 
--      AND Canceldate = To_date 
--      GROUP BY To_date,CompanyCode,BaseCurrency;
-----------------Spot Impact------------------------------
----      INSERT INTO TRSYSTEM976 
----            (Effe_PanL_Amount,EFFE_DESCRIPTION,EFFE_ASON_DATE,effe_company_code,effe_currency_code)
----      SELECT SUM(Posn_Transaction_Amount * (SpotRate1 - SpotRate)),
----            'SPOTIMPT',To_date,Posn_Company_Code,Posn_Currency_Code
----      FROM trsystem997d
----      WHERE posn_mtm_date    = To_date
----      AND posn_hedge_trade   = 'E'
----      GROUP BY posn_hedge_trade,To_date,Posn_Currency_Code,Posn_Company_Code;
--
----      INSERT INTO TRSYSTEM976 
----            (EFFE_PANL_AMOUNT,EFFE_DESCRIPTION,EFFE_ASON_DATE,EFFE_COMPANY_CODE,EFFE_CURRENCY_CODE)
----      SELECT SUM(Posn_Transaction_Amount * (SpotRate - SpotRate1)),
----            'SPOTIMPT',To_date,Posn_Company_Code,Posn_Currency_Code
----      FROM trsystem997d
----      WHERE posn_mtm_date    = dattemp2
----      AND posn_hedge_trade   = 'E'
----      GROUP BY posn_hedge_trade,To_date,Posn_Currency_Code,Posn_Company_Code;
--
----      INSERT INTO TRSYSTEM976 
----            (EFFE_PANL_AMOUNT,EFFE_DESCRIPTION,EFFE_ASON_DATE,EFFE_COMPANY_CODE,EFFE_CURRENCY_CODE)
----      SELECT SUM((case when posn_hedge_trade IN('E') then sum(Posn_Transaction_Amount) end - ((case when posn_hedge_trade IN('H') then
----      sum(Posn_Transaction_Amount) end) + (      case when posn_hedge_trade IN('HF','TF') and posn_account_code < 25900050 then
----      sum(Posn_Transaction_Amount) end -       case when posn_hedge_trade IN('HF','TF') and posn_account_code > 25900050 then
----      sum(Posn_Transaction_Amount) end))) * (SpotRate - SpotRate1)),
----            'SPOTIMPT',To_date,Posn_Company_Code,Posn_Currency_Code
----      FROM trsystem997d
----      WHERE posn_mtm_date    = dattemp2
----      AND posn_hedge_trade   in('E','HF','TF','H')
----      GROUP BY posn_hedge_trade,To_date,Posn_Currency_Code,Posn_Company_Code;
--
--      INSERT INTO TRSYSTEM976 
--            (EFFE_PANL_AMOUNT,EFFE_DESCRIPTION,EFFE_ASON_DATE,EFFE_COMPANY_CODE,EFFE_CURRENCY_CODE)
--      select sum(SpotAmt),'SPOTIMPT',To_date, Posn_Company_Code,Posn_Currency_Code from(
--      SELECT (nvl(case when posn_hedge_trade IN('E') then nvl(sum(Posn_Transaction_Amount),0) end,0) - ((nvl(case when posn_hedge_trade IN('H') then
--      nvl(sum(Posn_Transaction_Amount),0) end,0)) + (      nvl(case when posn_hedge_trade IN('HF','TF') and posn_account_code < 25900050 then
--      nvl(sum(Posn_Transaction_Amount),0) end,0) -       nvl(case when posn_hedge_trade IN('HF','TF') and posn_account_code > 25900050 then
--      nvl(sum(Posn_Transaction_Amount),0) end,0)))) * (SpotRate - SpotRate1)SpotAmt,
--            'SPOTIMPT',
--            To_date,
--            Posn_Company_Code,
--            Posn_Currency_Code
--      FROM trsystem997d
--      WHERE posn_mtm_date    = dattemp2
--      AND posn_hedge_trade   in('E','HF','TF','H')
--      GROUP BY posn_hedge_trade,To_date,Posn_Currency_Code,Posn_Company_Code,posn_account_code,'SPOTIMPT')
--      group  by Posn_Currency_Code, Posn_Company_Code,To_date;
------------------------------------------------------             
--END LOOP;
DELETE FROM TEMP;

INSERT INTO TEMP VALUES(FrmDate,ToDate);

Else
    INSERT INTO TRSYSTEM976 
      (EFFE_COMPANY_CODE,EFFE_AMOUNT_FCY,EFFE_AMOUNT_MTMPL,EFFE_REF_DATE,EFFE_CURRENCY_CODE,EFFE_FOR_CURRENCY,
      EFFE_CLOSE_DATE,EFFE_ASON_DATE,EFFE_COST_RATE,EFFE_EFFE_RATE,EFFE_TRADE_REFRENCE,EFFE_DEAL_NUMBER, 
      EFFE_BALANCE_FCY,EFFE_DESCRIPTION,EFFE_CROSS_RATE,EFFE_BUY_SELL,EFFE_BANK_REFERENCE)
    SELECT trad_company_code,Hedg_Hedged_Fcy,0,TRAD_REFERENCE_DATE,TRAD_TRADE_CURRENCY,DEAL_OTHER_CURRENCY,
          TRAD_MATURITY_DATE,To_date,TRAD_TRADE_RATE,DEAL_EXCHANGE_RATE,TRAD_TRADE_REFERENCE, HEDG_DEAL_NUMBER,
          0,'OPEN HEDGE',0,
          CASE WHEN trad_import_export > 25900050 THEN
            25300001
          ELSE
            25300002
          END,Trad_User_Reference
    FROM Trtran004,Trtran002,trtran001
    WHERE Trad_Trade_Reference = Hedg_Trade_Reference
          AND Trad_Process_Complete  = 12400002
          AND Hedg_Record_Status    IN(10200001,10200002,10200003,10200004)
          AND HEDG_DEAL_NUMBER = DEAL_DEAL_NUMBER
          AND DEAL_RECORD_STATUS IN(10200001,10200002,10200003,10200004)
          AND TRAD_REFERENCE_DATE <= To_date;
-------OPEN UNHEDGE-----------------------------------------------------------------          
    INSERT INTO TRSYSTEM976 
      (EFFE_COMPANY_CODE,EFFE_AMOUNT_FCY,EFFE_AMOUNT_MTMPL,EFFE_REF_DATE,EFFE_CURRENCY_CODE,EFFE_FOR_CURRENCY,
      EFFE_CLOSE_DATE,EFFE_ASON_DATE,EFFE_COST_RATE,EFFE_EFFE_RATE,EFFE_TRADE_REFRENCE,EFFE_DEAL_NUMBER, 
      EFFE_BALANCE_FCY,EFFE_DESCRIPTION,EFFE_CROSS_RATE,EFFE_BUY_SELL,EFFE_BANK_REFERENCE)
    SELECT
        TRAD_COMPANY_CODE,
        (Pkgforexprocess.FncgetoutstANDINg(Trad_Trade_Reference,0,0,1,To_date)- 
        nvl((SELECT NVL(SUM(HEDG_HEDGED_FCY),0) FROM trtran004
        WHERE HEDG_TRADE_REFERENCE = trad_trade_reference AND Hedg_Record_Status NOT IN (10200005,10200006,10200012) ),0)),
        0,Trad_Reference_Date,Trad_Trade_Currency,30400003,Trad_Maturity_Date,To_Date,Trad_Trade_Rate,
        Round(Pkgforexprocess.Fncgetrate(TRAD_TRADE_CURRENCY,30400003,To_date,
          case when trad_import_export > 25900050 then 25300001
          else
          25300002
          end ,0,Trad_Maturity_Date),6),
        --Pkgforexprocess.Fncgetrate(TRAD_TRADE_CURRENCY,30400003,To_date,0,0,Trad_Maturity_Date),
        
        TRAD_TRADE_REFERENCE,
        NULL,
        Pkgforexprocess.FncgetoutstANDINg(Trad_Trade_Reference,0,0,1,To_date),
        'OPEN UNHEDGE',
        0,
        CASE WHEN trad_import_export > 25900050 THEN
          25300001
        ELSE
          25300002
        END,Trad_User_Reference
    FROM Trtran002 WHERE
    TRAD_RECORD_STATUS NOT IN(10200005,10200006,10200012) AND
                ((TRAD_PROCESS_COMPLETE = 12400001  AND trad_complete_date > To_date) or TRAD_PROCESS_COMPLETE = 12400002)
        AND trad_entry_date <= To_date
    UNION
    SELECT BCRD_COMPANY_CODE,BCRD_SANCTIONED_FCY, 0,BCRD_SANCTION_DATE,BCRD_CURRENCY_CODE,30400003,BCRD_DUE_DATE,TO_DATE,
         BCRD_CONVERSION_RATE,
         Pkgforexprocess.Fncgetrate(BCRD_CURRENCY_CODE,30400003,To_date,25300001,0,BCRD_DUE_DATE),
         BCRD_BUYERS_CREDIT,NULL,BCRD_SANCTIONED_FCY,'OPEN UNHEDGE',0,25300001,BCRD_SANCTION_REFERENCE
    FROM trtran045 WHERE 
   ((BCRD_PROCESS_COMPLETE = 12400001  AND BCRD_COMPLETION_DATE > To_date) or BCRD_PROCESS_COMPLETE = 12400002)
    AND BCRD_RECORD_STATUS BETWEEN 10200001 AND 10200004
    AND BCRD_RECORD_STATUS BETWEEN 10200001 and 10200004
    AND BCRD_SANCTION_DATE <=To_date;

---------FC DELIVERY--------------------------------------------
        INSERT INTO TRSYSTEM976 
      (EFFE_COMPANY_CODE,EFFE_AMOUNT_FCY,EFFE_AMOUNT_MTMPL,EFFE_REF_DATE,EFFE_CURRENCY_CODE,EFFE_FOR_CURRENCY,
      EFFE_CLOSE_DATE,EFFE_ASON_DATE,EFFE_COST_RATE,EFFE_EFFE_RATE,EFFE_TRADE_REFRENCE,EFFE_DEAL_NUMBER, 
      EFFE_BALANCE_FCY,EFFE_DESCRIPTION,EFFE_CROSS_RATE,EFFE_BUY_SELL,EFFE_BANK_REFERENCE)
    SELECT 
        Trad_Company_Code,CDEL_CANCEL_AMOUNT,0,TRAD_REFERENCE_DATE,TRAD_TRADE_CURRENCY,30400003,
        TRAD_MATURITY_DATE,TO_DATE,TRAD_TRADE_RATE,CDEL_CANCEL_RATE,TRAD_TRADE_REFERENCE,CDEL_DEAL_NUMBER,
        0,'FC DELIVERY',0,
        CASE WHEN trad_import_export > 25900050 THEN
          25300001
        ELSE
          25300002
        END,Trad_User_Reference
        
    FROM 
      trtran006,trtran002,trtran001
      WHERE CDEL_TRADE_REFERENCE = TRAD_TRADE_REFERENCE
      AND cdel_deal_number = deal_deal_number
      AND cdel_cancel_date BETWEEN Frm_date AND To_date
      and cdel_record_status  between 10200001 and 10200004
      and deal_record_status  between 10200001 and 10200004
      and trad_record_status  between 10200001 and 10200004      
      AND DEAL_DEAL_TYPE NOT IN(25400001)
      UNION
    SELECT 
        BCRD_COMPANY_CODE,CDEL_CANCEL_AMOUNT,0,BCRD_SANCTION_DATE,BCRD_CURRENCY_CODE,30400003,
        BCRD_DUE_DATE,TO_DATE,BCRD_CONVERSION_RATE,CDEL_CANCEL_RATE,BCRD_BUYERS_CREDIT,CDEL_DEAL_NUMBER,
        0,'FC DELIVERY',0,25300001,BCRD_SANCTION_REFERENCE
    FROM 
      trtran006,trtran045,trtran001
      WHERE CDEL_TRADE_REFERENCE = BCRD_BUYERS_CREDIT
      AND cdel_deal_number = deal_deal_number
      AND cdel_cancel_date BETWEEN Frm_date AND To_date
      and cdel_record_status  between 10200001 and 10200004
      and deal_record_status  between 10200001 and 10200004
      and BCRD_RECORD_STATUS  between 10200001 and 10200004      
      AND DEAL_DEAL_TYPE NOT IN(25400001);


-------------CASH SETTLE---------------------------------------
    INSERT INTO TRSYSTEM976 
      (EFFE_COMPANY_CODE,EFFE_AMOUNT_FCY,EFFE_AMOUNT_MTMPL,EFFE_REF_DATE,EFFE_CURRENCY_CODE,EFFE_FOR_CURRENCY,
       EFFE_CLOSE_DATE,EFFE_ASON_DATE,EFFE_COST_RATE,EFFE_EFFE_RATE,EFFE_TRADE_REFRENCE,EFFE_DEAL_NUMBER, 
       EFFE_BALANCE_FCY,EFFE_DESCRIPTION,EFFE_CROSS_RATE,EFFE_BUY_SELL,EFFE_BANK_REFERENCE)
    SELECT 
      Trad_Company_Code,CDEL_CANCEL_AMOUNT,0,TRAD_REFERENCE_DATE,TRAD_TRADE_CURRENCY,30400003,
      TRAD_MATURITY_DATE,TO_DATE,TRAD_TRADE_RATE,CDEL_CANCEL_RATE,TRAD_TRADE_REFERENCE,CDEL_DEAL_NUMBER,
      0,'CASH SETTLE',0,
      CASE WHEN trad_import_export > 25900050 THEN
        25300001
      ELSE
        25300002
      END,Trad_User_Reference
    FROM trtran006,trtran002,trtran001
    WHERE CDEL_TRADE_REFERENCE = TRAD_TRADE_REFERENCE
    AND CDEL_DEAL_NUMBER = DEAL_DEAL_NUMBER
    AND DEAL_DEAL_TYPE = 25400001 
    and cdel_record_status  between 10200001 and 10200004
    and deal_record_status  between 10200001 and 10200004
    and trad_record_status  between 10200001 and 10200004    
    AND CDEL_CANCEL_DATE BETWEEN Frm_date AND To_date;
    ----BC Cahs Settle------------
    INSERT INTO TRSYSTEM976 
      (EFFE_COMPANY_CODE,EFFE_AMOUNT_FCY,EFFE_AMOUNT_MTMPL,EFFE_REF_DATE,EFFE_CURRENCY_CODE,EFFE_FOR_CURRENCY,
       EFFE_CLOSE_DATE,EFFE_ASON_DATE,EFFE_COST_RATE,EFFE_EFFE_RATE,EFFE_TRADE_REFRENCE,EFFE_DEAL_NUMBER, 
       EFFE_BALANCE_FCY,EFFE_DESCRIPTION,EFFE_CROSS_RATE,EFFE_BUY_SELL,EFFE_BANK_REFERENCE)
    SELECT 
      BCRD_COMPANY_CODE,CDEL_CANCEL_AMOUNT,0,BCRD_SANCTION_DATE,BCRD_CURRENCY_CODE,30400003,
      BCRD_DUE_DATE,TO_DATE,BCRD_CONVERSION_RATE,CDEL_CANCEL_RATE,BCRD_BUYERS_CREDIT,CDEL_DEAL_NUMBER,
      0,'CASH SETTLE',0,
      25300001,BCRD_SANCTION_REFERENCE
    FROM trtran006,trtran045,trtran001
    WHERE CDEL_TRADE_REFERENCE = BCRD_BUYERS_CREDIT
    AND CDEL_DEAL_NUMBER = DEAL_DEAL_NUMBER
    AND DEAL_DEAL_TYPE = 25400001 
    and cdel_record_status  between 10200001 and 10200004
    and deal_record_status  between 10200001 and 10200004
    and BCRD_RECORD_STATUS  between 10200001 and 10200004    
    AND CDEL_CANCEL_DATE BETWEEN Frm_date AND To_date;

-------------------------------------------FC CNCEL---------------
    INSERT INTO TRSYSTEM976 
      (EFFE_COMPANY_CODE,EFFE_AMOUNT_FCY,EFFE_AMOUNT_MTMPL,EFFE_REF_DATE,EFFE_CURRENCY_CODE,EFFE_FOR_CURRENCY,
      EFFE_CLOSE_DATE,EFFE_ASON_DATE,EFFE_COST_RATE,EFFE_EFFE_RATE,EFFE_TRADE_REFRENCE,EFFE_DEAL_NUMBER, 
      EFFE_BALANCE_FCY,EFFE_DESCRIPTION,EFFE_CROSS_RATE,EFFE_BUY_SELL,EFFE_BANK_REFERENCE)
    SELECT DEAL_COMPANY_CODE,CDEL_CANCEL_AMOUNT,CDEL_PROFIT_LOSS,DEAL_EXECUTE_DATE,DEAL_BASE_CURRENCY,DEAL_OTHER_CURRENCY,
           CDEL_CANCEL_DATE,TO_DATE,DEAL_EXCHANGE_RATE,CDEL_CANCEL_RATE,NULL,DEAL_DEAL_NUMBER,
           0,'FC CNCEL',0,DEAL_BUY_SELL,DEAL_USER_REFERENCE
    FROM trtran006,trtran001
    WHERE CDEL_CANCEL_DATE BETWEEN Frm_date AND To_date
    AND cdel_deal_number = deal_deal_number
    and cdel_record_status  between 10200001 and 10200004
    and deal_record_status  between 10200001 and 10200004
    --and cdel_cancel_type = 27000001
    AND DEAL_HEDGE_TRADE = 26000001;
---------------------------------HEDGE MTM---------------
    INSERT INTO TRSYSTEM976 
      (EFFE_COMPANY_CODE,EFFE_AMOUNT_FCY,EFFE_AMOUNT_MTMPL,EFFE_REF_DATE,EFFE_CURRENCY_CODE,EFFE_FOR_CURRENCY,
      EFFE_CLOSE_DATE,EFFE_ASON_DATE,EFFE_COST_RATE,EFFE_EFFE_RATE,EFFE_TRADE_REFRENCE,EFFE_DEAL_NUMBER, 
      EFFE_BALANCE_FCY,EFFE_DESCRIPTION,EFFE_CROSS_RATE,EFFE_BUY_SELL,EFFE_BANK_REFERENCE)
    SELECT COMPANYCODE,balancefcy,MTMPANDLINR,DEALDATE,CURRENCYCODE,OTHERCODE,MATURITY,TO_DATE,EXRATE,M2MRATE,
        NULL,DEALNUMBER,balancefcy,'CURRENCY FORWARD',0,BUYSELLCODE,Null
    FROM vewReportForward  WHERE  
    ((status = 12400001 AND completedate > To_date) or status = 12400002)
    AND dealdate <= To_date 
    AND hedgeCode = 26000001;
    ---------------------------'CURRENCY FUTURE' ---------------------------------
    INSERT INTO TRSYSTEM976 
      (EFFE_COMPANY_CODE,EFFE_AMOUNT_FCY,EFFE_AMOUNT_MTMPL,EFFE_REF_DATE,EFFE_CURRENCY_CODE,EFFE_FOR_CURRENCY,
      EFFE_CLOSE_DATE,EFFE_ASON_DATE,EFFE_COST_RATE,EFFE_EFFE_RATE,EFFE_TRADE_REFRENCE,EFFE_DEAL_NUMBER, 
      EFFE_BALANCE_FCY,EFFE_DESCRIPTION,EFFE_CROSS_RATE,EFFE_BUY_SELL,EFFE_BANK_REFERENCE)
    SELECT COMPANYCODE,balancefcy,MTMPANDL,DEALDATE,CURRENCYCODE,OTHERCODE,MATURITY,TO_DATE,EXRATE,M2MRATE,
        NULL,DEALNUMBER,balancefcy,'CURRENCY FUTURE',0,BUYSELLCODE,Null
    FROM vewReportFuture  WHERE 
    ((status = 12400001 AND completedate > To_date) or status = 12400002) AND
     dealdate <= To_date 
    UNION
    SELECT COMPANYCODE,CANCELAMOUNT,PANDLFCY,DEALDATE,CURRENCYCODE,OTHERCODE,MATURITY,TO_DATE,EXRATE,ROUND(CANCELRATE,4),
        NULL,DEALNUMBER,0,'REALIZED FUTURE',0,BUYSELLCODE,Null
    FROM vewReportFuture  WHERE 
    canceldate BETWEEN Frm_date AND To_date;
    ------------------'CURRENCY OPTION'-------------------
    INSERT INTO TRSYSTEM976 
      (EFFE_COMPANY_CODE,EFFE_AMOUNT_FCY,EFFE_AMOUNT_MTMPL,EFFE_REF_DATE,EFFE_CURRENCY_CODE,EFFE_FOR_CURRENCY,
      EFFE_CLOSE_DATE,EFFE_ASON_DATE,EFFE_COST_RATE,EFFE_EFFE_RATE,EFFE_TRADE_REFRENCE,EFFE_DEAL_NUMBER, 
      EFFE_BALANCE_FCY,EFFE_DESCRIPTION,EFFE_CROSS_RATE,EFFE_BUY_SELL,EFFE_BANK_REFERENCE)
    SELECT COPT_COMPANY_CODE,COPT_BASE_AMOUNT,pkgForexProcess.fncGetOptionMTM(copt_deal_number,To_date,'N'),
        COPT_EXECUTE_DATE,COPT_BASE_CURRENCY,COPT_OTHER_CURRENCY,COPT_MATURITY_DATE,TO_DATE,COPT_LOT_PRICE,0,NULL,COPT_DEAL_NUMBER,
        COPT_BASE_AMOUNT,'CURRENCY OPTION',0,0,COPT_BANK_REFERENCE
    FROM trtran071 WHERE COPT_EXECUTE_DATE <= To_date 
    AND ((copt_PROCESS_COMPLETE = 12400001  AND copt_COMPLETE_DATE >To_date) or copt_PROCESS_COMPLETE = 12400002)
    AND COPT_RECORD_STATUS IN(10200001,10200002,10200003,10200004)
    UNION  
    SELECT COPT_COMPANY_CODE,COPT_BASE_AMOUNT,nvl( Pkgforexprocess.FncgetprofitlossoptnetpANDl(CORV_DEAL_NUMBER,CORV_SERIAL_NUMBER),0),
        COPT_EXECUTE_DATE,COPT_BASE_CURRENCY,COPT_OTHER_CURRENCY,COPT_MATURITY_DATE,TO_DATE,COPT_LOT_PRICE,0,NULL,COPT_DEAL_NUMBER,
        COPT_BASE_AMOUNT,'REALIZE OPTION',0,0,COPT_BANK_REFERENCE
    FROM trtran073,trtran071 
    WHERE 
    corv_exercise_date  BETWEEN Frm_date AND To_date
    AND copt_deal_number = CORV_DEAL_NUMBER --AND COPT_HEDGE_TRADE = 26000001
    AND CORV_RECORD_STATUS IN(10200001,10200002,10200003,10200004);
    
    Update trsystem976 set EFFE_AMOUNT_MTMPL = EFFE_AMOUNT_FCY * (EFFE_COST_RATE - EFFE_EFFE_RATE) WHERE 
    EFFE_DESCRIPTION IN('OPEN UNHEDGE','FC DELIVERY','CASH SETTLE');

------------------Order Cancelation------------------------------------

      INSERT INTO TRSYSTEM976 
      (EFFE_COMPANY_CODE,EFFE_AMOUNT_FCY,EFFE_AMOUNT_MTMPL,EFFE_REF_DATE,EFFE_CURRENCY_CODE,EFFE_FOR_CURRENCY,
      EFFE_CLOSE_DATE,EFFE_ASON_DATE,EFFE_COST_RATE,EFFE_EFFE_RATE,EFFE_TRADE_REFRENCE,EFFE_DEAL_NUMBER, 
      EFFE_BALANCE_FCY,EFFE_DESCRIPTION,EFFE_CROSS_RATE,EFFE_BUY_SELL,EFFE_BANK_REFERENCE)
       SELECT 
        Trad_Company_Code,BREL_REVERSAL_FCY,
	(BREL_REVERSAL_FCY * TRAD_TRADE_RATE) - (BREL_REVERSAL_FCY * BREL_REVERSAL_RATE),
	TRAD_REFERENCE_DATE,TRAD_TRADE_CURRENCY,30400003,
        TRAD_MATURITY_DATE,TO_DATE,TRAD_TRADE_RATE,BREL_REVERSAL_RATE,TRAD_TRADE_REFERENCE,TRAD_TRADE_REFERENCE,
        0,'ORDER CANCEL',0,
        CASE WHEN trad_import_export > 25900050 THEN
          25300001
        ELSE
          25300002
        END,Trad_User_Reference
        
        FROM trtran003,
          trtran002
        WHERE Brel_Reversal_Type = 25800053
        AND Brel_Trade_Reference = Trad_Trade_Reference
        AND Brel_Entry_Date BETWEEN Frm_date AND To_date
        AND Brel_record_status BETWEEN 10200001 AND 10200004
        AND trad_record_status BETWEEN 10200001 AND 10200004;
--------------------------------------------------------------------------

End if;
commit;
exception 
when others then
--varmsg:= sqlerrm;
varmsg:= varmsg;
rollback;
raise_application_error(-200001,varmsg);
  
end prceffectiveraterpt;
 
 
 
 
/