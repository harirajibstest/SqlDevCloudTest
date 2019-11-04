CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewoptcontracts (rownumber,subrownumber,company,counterparty,dealdate,dealnumber,matdate,baseamount,bp,sp,bc,sc,userrefno,imporddate,imprefno,supplier,impnotional,impmatfrom,impmatto,impproduct,exporddate,exprefno,buyer,expnotional,expmatfrom,expmatto,expproduct,canceldate,cancelamt,cancelrate,profitlossusd,netgain) AS
SELECT ROWNUMBER,
            SUBROWNUMBER,
            COMPANY,
            COUNTERPARTY,
            DEALDATE,
            DEALNUMBER,
            MATDATE,
            BASEAMOUNT,
            BP,
            SP,
            BC,
            SC,
            USERREFNO,
            IMPORDDATE,
            IMPREFNO,
            SUPPLIER,
            IMPNOTIONAL,
            IMPMATFROM,
            IMPMATTO,
            IMPPRODUCT,
            EXPORDDATE,
            EXPREFNO,
            BUYER,
            EXPNOTIONAL,
            EXPMATFROM,
            EXPMATTO,
            EXPPRODUCT,
            CANCELDATE,
            CANCELAMT,
            CANCELRATE,
            PROFITLOSSUSD,
            NETGAIN
       FROM (SELECT REPC_ROW_NUMBER RowNumber,
                    REPC_SUB_ROW SubRowNumber,
                    Pkgreturncursor.Fncgetdescription (REPD_COMPANY_CODE, 2)
                       Company,
                    pkgreturncursor.fncgetdescription (REPD_COUNTER_PARTY, 2)
                       CounterParty,
                    REPD_DEAL_NUMBER DealNumber,
                    REPD_EXECUTE_DATE DealDate,
                    REPD_MATURITY_DATE MatDate,
                    REPD_BASE_AMOUNT BaseAmount,
                    (SELECT AVG (cosu_strike_rate)
                       FROM trtran072
                      WHERE     cosu_deal_number = REPD_DEAL_NUMBER
                            AND cosu_buy_sell = 25300001
                            AND cosu_option_type = 32400002)
                       BP,
                    (SELECT AVG (cosu_strike_rate)
                       FROM trtran072
                      WHERE     cosu_deal_number = REPD_DEAL_NUMBER
                            AND cosu_buy_sell = 25300002
                            AND cosu_option_type = 32400002)
                       SP,
                    (SELECT ROUND (AVG (cosu_strike_rate), 2)
                       FROM trtran072
                      WHERE     cosu_deal_number = REPD_DEAL_NUMBER
                            AND cosu_buy_sell = 25300001
                            AND cosu_option_type = 32400001)
                       BC,
                    (SELECT AVG (cosu_strike_rate)
                       FROM trtran072
                      WHERE     cosu_deal_number = REPD_DEAL_NUMBER
                            AND cosu_buy_sell = 25300002
                            AND cosu_option_type = 32400001)
                       SC,
                    REPD_USER_REFERENCE UserRefNo,
                    DECODE (SIGN (REPE_IMPORT_EXPORT - 25900050),
                            1, REPI_REFERENCE_DATE,
                            NULL)
                       ImpOrdDate,
                    DECODE (SIGN (REPE_IMPORT_EXPORT - 25900050),
                            1, REPe_TRADE_REFERENCE,
                            -1, '')
                       ImpRefNo,
                    DECODE (
                       SIGN (REPE_IMPORT_EXPORT - 25900050),
                       1,
                       pkgreturncursor.fncgetdescription (REPI_BUYER_SELLER, 2),
                       '')
                       Supplier,
                    DECODE (SIGN (REPE_IMPORT_EXPORT - 25900050),
                            1, REPI_trade_FCY,
                            0)
                       ImpNotional,
                    DECODE (SIGN (REPE_IMPORT_EXPORT - 25900050),
                            1, REPI_MATURITY_FROM,
                            NULL)
                       ImpMatFrom,
                    NULL ImpMatTo,
                    DECODE (
                       SIGN (REPE_IMPORT_EXPORT - 25900050),
                       1,
                       pkgreturncursor.fncgetdescription (REPE_PRODUCT_CODE, 2),
                       '')
                       ImpProduct,
                    DECODE (SIGN (REPE_IMPORT_EXPORT - 25900050),
                            -1, REPe_REFERENCE_DATE,
                            NULL)
                       ExpOrdDate,
                    DECODE (SIGN (REPE_IMPORT_EXPORT - 25900050),
                            -1, REPe_TRADE_REFERENCE,
                            '')
                       ExpRefNo,
                    DECODE (
                       SIGN (REPE_IMPORT_EXPORT - 25900050),
                       -1,
                       pkgreturncursor.fncgetdescription (REPe_BUYER_SELLER, 2),
                       '')
                       Buyer,
                    DECODE (SIGN (REPE_IMPORT_EXPORT - 25900050),
                            -1, REPe_trade_FCY,
                            0)
                       ExpNotional,
                    DECODE (SIGN (REPE_IMPORT_EXPORT - 25900050),
                            -1, REPe_MATURITY_FROM,
                            NULL)
                       ExpMatFrom,
                    NULL ExpMatTo,
                    DECODE (
                       SIGN (REPE_IMPORT_EXPORT - 25900050),
                       -1,
                       pkgreturncursor.fncgetdescription (REPE_PRODUCT_CODE, 2),
                       '')
                       ExpProduct,
                    REPC_EXERCISE_DATE CancelDate,
                    REPC_CANCLE_AMOUNT CancelAmt,
                    REPC_RBI_REFRATE CancelRate,
                    REPC_PROFIT_LOSS ProfitLossUsd,
                    REPC_PROFIT_LOSS - REPD_PREMIUM_LOCAL NetGain
               FROM trsystem987
              WHERE REPI_ORDER_EXIST = 1
             UNION ALL
               SELECT NULL RowNumber,
                      NULL SubRowNumber,
                      NULL Company,
                      NULL CounterParty,
                      '' DealNumber,
                      NULL DealDate,
                      NULL MatDate,
                      SUM (repd_base_amount) BaseAmount,
                      0 BP,
                      0 SP,
                      0 BC,
                      0 SC,
                      '' UserRefNo,
                      NULL ImpOrdDate,
                      DECODE (SIGN (REPE_IMPORT_EXPORT - 25900050),
                              1, REPe_TRADE_REFERENCE,
                              -1, '')
                         ImpRefNo,
                      'Total' Supplier,
                      (DECODE (SIGN (REPE_IMPORT_EXPORT - 25900050),
                               1, NVL (REPI_traDe_FCY, 0),
                               0))
                         ImpNotional,
                      NULL ImpMatFrom,
                      NULL ImpMatTo,
                      '' ImpProduct,
                      NULL ExpOrdDate,
                      DECODE (SIGN (REPE_IMPORT_EXPORT - 25900050),
                              -1, REPe_TRADE_REFERENCE,
                              '')
                         ExpRefNo,
                      'Total' Buyer,
                      (DECODE (SIGN (REPE_IMPORT_EXPORT - 25900050),
                               -1, NVL (REPE_trade_FCY, 0),
                               0))
                         ExpNotional,
                      NULL ExpMatFrom,
                      NULL ExpMatTo,
                      '' ExpProduct,
                      NULL CancelDate,
                      SUM (NVL (REPC_CANCLE_AMOUNT, 0)) CancelAmt,
                      0 CancelRate,
                      SUM (NVL (REPC_PROFIT_LOSS, 0)) ProfitLossUsd,
                      SUM (
                         NVL (REPC_PROFIT_LOSS, 0) - NVL (REPD_PREMIUM_LOCAL, 0))
                         NetGain
                 FROM trsystem987
                WHERE REPI_ORDER_EXIST = 1
             GROUP BY repe_trade_reference,
                      repe_import_EXPORT,
                      REPE_TRADE_FCY,
                      REPI_TRADE_FCY)
   ORDER BY exprefno, imprefno, DEALNUMBER
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 ;