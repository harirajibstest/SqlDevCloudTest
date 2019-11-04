CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewdealsdoneforthedayopt (company,dealnumber,execancdate,bank,trader,currency,initiator,tradetype,basecancamount,maturitydate,finalsettlement,bc,bp,sp,sc,premiumamount,premiumstatus,cancelrate,profitloss,netpandl,status,remarks,companycode) AS
Select Company,Dealnumber,Execancdate,Bank,Trader,Currency,
            Initiator,TradeType,Basecancamount,Maturitydate,Finalsettlement,
            Bc,Bp,Sp,Sc,Premiumamount,Premiumstatus,Cancelrate,Profitloss,Netpandl,Status,Remarks,companyCode
     from  (
         Select Pkgreturncursor.Fncgetdescription( Copt_Company_Code,2) As Company,  
                Copt_Deal_Number As Dealnumber,Copt_Execute_Date As ExeCancDate,
                Pkgreturncursor.Fncgetdescription(Copt_Counter_Party ,2)As Bank,
                 Pkgreturncursor.Fncgetdescription(Copt_Init_Code,2) Trader,
                 pkgreturncursor.fncgetdescription( COPT_BASE_CURRENCY,2) ||'/'||
                 Pkgreturncursor.Fncgetdescription(Copt_Other_Currency,2)Currency,
                 Pkgreturncursor.Fncgetdescription(Copt_Backup_Deal,2) Initiator,
                Decode(Copt_Hedge_Trade, 26000001, 'Hedge Deal', 26000002,'Trade Deal',26000003,'FT Deal') TradeType,
                Copt_Base_Amount As BaseCancAmount,
               --  COPT_PREMIUM_EXRATE AS EXRATE,
                 COPT_MATURITY_DATE AS MaturityDate,
                 COPT_EXPIRY_DATE AS FINALSETTLEMENT,
                  (select round( avg(cosu_strike_rate),4) from trtran072 
                   where cosu_deal_number=copt_deal_number
                    and cosu_buy_sell=25300001
                    And Cosu_Option_Type=32400001) "BC",
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
                        and cosu_buy_sell=25300002
                        And Cosu_Option_Type=32400001) "SC",
                  Copt_Premium_Amount As Premiumamount, 
               Substr(Pkgreturncursor.Fncgetdescription(Copt_Premium_Status,2),1,1) As Premiumstatus,
                1 Cancelrate,1 As Profitloss,1 As Netpandl,'Booked' As  Status,
                Decode (Copt_Record_Status,10200001,'Unconfirmed',10200003,'Confirmed',10200002,'First Confi') Remarks,
                Copt_Company_Code as companyCode
               
          From Trtran071
          Where    Copt_Record_Status Not In (10200005,10200006)
          
  union All
  
          Select Pkgreturncursor.Fncgetdescription( Copt_Company_Code,2) As Company,  
                Copt_Deal_Number As Dealnumber,CORV_EXERCISE_DATE As ExeCancDate,
                Pkgreturncursor.Fncgetdescription(Copt_Counter_Party ,2)As Bank,
                 Pkgreturncursor.Fncgetdescription(Copt_Init_Code,2) Trader,
                 pkgreturncursor.fncgetdescription( COPT_BASE_CURRENCY,2) ||'/'||
                 Pkgreturncursor.Fncgetdescription(Copt_Other_Currency,2)Currency,
                 Pkgreturncursor.Fncgetdescription(Copt_Backup_Deal,2) Initiator,
                Decode(Copt_Hedge_Trade, 26000001, 'Hedge Deal', 26000002,'Trade Deal',26000003,'FT Deal') Hedgetrade,
                CORV_BASE_AMOUNT As BaseCancAmount,
               --  COPT_PREMIUM_EXRATE AS EXRATE,
                 COPT_MATURITY_DATE AS MaturityDate,
                 COPT_EXPIRY_DATE AS FINALSETTLEMENT,
                  (select round( avg(cosu_strike_rate),4) from trtran072 
                   where cosu_deal_number=copt_deal_number
                    and cosu_buy_sell=25300001
                    And Cosu_Option_Type=32400001) "BC",
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
                        and cosu_buy_sell=25300002
                        And Cosu_Option_Type=32400001) "SC",
                  Corv_Premium_Amount As Premiumamount,
                   Substr(Pkgreturncursor.Fncgetdescription(Copt_Premium_Status,2),1,1) As PremiumStatus,
                 nvl(decode(CORV_EXERCISE_TYPE,33000003,CORV_PREMIUM_EXRATE,33000001,CORV_RBI_REFRATE,CORV_EXERCISE_RATE),0) Cancelrate,
                Corv_Profit_Loss As Profitloss,
                Pkgforexprocess.Fncgetprofitlossoptnetpandl(Copt_Deal_Number,Corv_Serial_Number) As Netpandl,
                'Cancled' As  Status,
                Decode (Copt_Record_Status,10200001,'Unconfirmed',10200003,'Confirmed',10200002,'First Confi') Remarks,
                Copt_Company_Code as companyCode
               
           from trtran071,trtran073 
          Where   Copt_Deal_Number=Corv_Deal_Number
                  And Corv_Record_Status Not In(10200005,10200006)
                  And Copt_Record_Status Not In  (10200005,10200006))
             order by dealnumber
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 ;