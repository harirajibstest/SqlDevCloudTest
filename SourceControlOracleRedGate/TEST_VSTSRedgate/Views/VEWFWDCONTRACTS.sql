CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewfwdcontracts (dealnumber,company,bookdate,counterparty,currency,netrate,baseamt,duedate,refdate,traderef,buyseller,notional,matfrom,matto,product,canceldate,cancelamt,cancelnetrate,profitloss,profitlossusd) AS
SELECT DEALNUMBER, 
            Companycode,
            DealDate,
            Bank,
            decode(currency, '/', '', currency) currency,
            ExchangeRate,
            BaseAmount,
            Maturity,
            MaturityTO,
            TradeReference,
            BuyerSeller,
            NOTIONAL,
            TMaturityfrm,
            TMaturityTo,
            PRODUCT,
            CANCELDATE,
            CANCELAMT,
            CancelRate,
            PROFITLOSS,
            PROFITLOSSUSD
        FROM
          (SELECT FRWC_ROW_NUMBER RowNumber,
            FRWC_SUB_ROW SubRowNumber,
            FRWD_DEAL_NUMBER DealNumber,
            Pkgreturncursor.Fncgetdescription(FRWD_COMPANY_CODE,2) Companycode,
            FRWD_EXECUTE_DATE DealDate,
            pkgreturncursor.fncgetdescription(FRWD_COUNTER_PARTY,2) Bank,
            pkgreturncursor.fncgetdescription(FRWD_BASE_CURRENCY,2)
            || '/'
            || pkgreturncursor.fncgetdescription(FRWD_OTHER_CURRENCY,2) currency,
            FRWD_EXCHANGE_RATE ExchangeRate,
            FRWD_BASE_AMOUNT BaseAmount,
            FRWD_MATURITY_FROM Maturity,
            FRWD_MATURITY_DATE MaturityTo,
            FRWD_USER_REFERENCE BankReference,
            FRWO_REFERENCE_DATE Referencedate,
            pkgreturncursor.fncgetdescription(FRWO_BUYER_SELLER,2) BuyerSeller,
            FRWO_TRADE_REFERENCE TradeReference,
            FRWO_HEDGED_FCY Notional,
            FRWO_TRADMATURITY_FROM TMaturityfrm,
            FRWO_TRADMATURITY_DATE TMaturityTo,
            pkgreturncursor.fncgetdescription(FRWO_PRODUCT_CODE,2) Product,
            FRWC_CANCEL_DATE CancelDate,
            FRWC_CANCLE_AMOUNT CancelAmt,
            FRWC_CANCLE_RATE CancelRate,
            FRWC_PROFIT_LOSS ProfitLoss,
            FRWC_OTHER_AMOUNT ProfitLossUsd,
          --  pkgreturnreport.getCompanyName() AS CompanyName,
            FRWD_DEAL_NUMBER Dealno
          FROM trsystem986
          WHERE FRWD_ORDE_EXIST=1
          --AND FRWD_EXECUTE_DATE BETWEEN '01 Jan 2012' AND '31 Jan 2012'
          UNION ALL
          SELECT FRWC_ROW_NUMBER RowNumber,
            NULL SubRowNumber,
            '' DealNumber,
            Pkgreturncursor.Fncgetdescription(FRWD_COMPANY_CODE,2) Companycode,
            FRWD_EXECUTE_DATE DealDate,
            pkgreturncursor.fncgetdescription(FRWD_COUNTER_PARTY,2) Bank,
            '' currency,
            0 ExchangeRate,
            0 BaseAmount,
            NULL Maturity,
            NULL MaturityTo,
            '' BankReference,
            NULL Referencedate,
            '' BuyerSeller,
            'Total' TradeReference,
            SUM(NVL(FRWO_HEDGED_FCY, 0)) Notional,
            NULL TMaturityfrm,
            NULL TMaturityTo,
            '' Product,
            NULL CancelDate,
            SUM(NVL(FRWC_CANCLE_AMOUNT, 0)) CancelAmt,
            0 CancelRate,
            SUM(NVL(FRWC_PROFIT_LOSS, 0)) ProfitLoss,
            sum(nvl(FRWC_OTHER_AMOUNT, 0)) ProfitLossUsd,
           -- '' CompanyName,
            FRWD_DEAL_NUMBER Dealno
          FROM trsystem986
          WHERE FRWD_ORDE_EXIST=1
          --AND FRWD_EXECUTE_DATE BETWEEN '01 Jan 2012' AND '31 Jan 2012'
          GROUP BY FRWC_ROW_NUMBER,
            FRWD_DEAL_NUMBER,
            FRWD_EXECUTE_DATE,
            FRWD_COUNTER_PARTY,
            FRWD_COMPANY_CODE
          )
        ORDER BY Companycode, bank, Dealno, RowNumber, SubRowNumber
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 ;