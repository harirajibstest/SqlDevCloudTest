CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewoptionrealizedpandlrep (company,dealnumber,bkname,trader,initiator,currency,executedate,basseamount,maturitydate,settelmentdate,bc,bp,sp,sc,bookingpremamt,canceldate,cancelamount,cancelpremamt,netpandl,remarks,tradetype,status,companycode) AS
Select     Pkgreturncursor.Fncgetdescription( Copt_Company_Code,2) As Company,
                         Copt_Deal_Number As Dealnumber,
                         pkgreturncursor.fncgetdescription(COPT_COUNTER_PARTY ,2)AS BKNAME,
                         Pkgreturncursor.Fncgetdescription(Copt_Init_Code,2) Trader,
                         Pkgreturncursor.Fncgetdescription(Copt_Backup_Deal,2) Initiator,
                          Pkgreturncursor.Fncgetdescription( Copt_Base_Currency,2) ||'/'||
                         Pkgreturncursor.Fncgetdescription(Copt_Other_Currency,2)Currency,
                        Copt_Execute_Date As Executedate, Copt_Base_Amount As BasseAmount,
                        Copt_Maturity_Date As Maturitydate,Copt_Expiry_Date As Settelmentdate,
                       ( Select Round( Avg(Cosu_Strike_Rate),4) From Trtran072 
                         where cosu_deal_number=copt_deal_number
                        and cosu_buy_sell=25300001
                        and cosu_option_type=32400001) "BC",
                       (select avg(cosu_strike_rate) from trtran072 
                        where cosu_deal_number=copt_deal_number
                          and cosu_buy_sell=25300001
                          and cosu_option_type=32400002) "BP",
                       (select avg(cosu_strike_rate) from trtran072 
                          where cosu_deal_number=copt_deal_number
                            and cosu_buy_sell=25300002
                            and cosu_option_type=32400002) "SP",
                        (select avg(cosu_strike_rate) from trtran072 
                          where cosu_deal_number=copt_deal_number
                            And Cosu_Buy_Sell=25300002
                            AND COSU_OPTION_TYPE=32400001) "SC",
                           -- Corv_Premium_Amount As Premiumamount,
                        DECODE(SIGN(CORV_BASE_AMOUNT - COPT_BASE_AMOUNT), -1, 
                      (COPT_PREMIUM_AMOUNT / COPT_BASE_AMOUNT) * CORV_BASE_AMOUNT,
                       COPT_PREMIUM_AMOUNT) AS BOOKINGPREMAMT,
                       CORV_EXERCISE_DATE CANCELDATE,CORV_BASE_AMOUNT AS CANCELAMOUNT,
                       (CORV_PROFIT_LOSS) AS CANCELPREMAMT,
                       PKGFOREXPROCESS.FNCGETPROFITLOSSOPTNETPANDL(CORV_DEAL_NUMBER,CORV_SERIAL_NUMBER) AS NETPANDL,
                       DECODE (COPT_RECORD_STATUS,10200001,'Unconfi.',10200003,'2nDConFI.',10200002,'1stConFI.',10200004,'Updated') REMARKS,
                       PKGRETURNCURSOR.FNCGETDESCRIPTION(COPT_HEDGE_TRADE,2) TRADETYPE,
                       SUBSTR(PKGRETURNCURSOR.FNCGETDESCRIPTION(COPT_PREMIUM_STATUS,2),1,1)AS STATUS ,
                       Copt_Company_Code as companyCode
           From Trtran071,Trtran073 
           where  copt_deal_number=corv_deal_number
               And Copt_Record_Status Not In(10200005,10200006)
               AND CORV_RECORD_STATUS NOT IN(10200005,10200006)
               order by Copt_Deal_Number
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 ;