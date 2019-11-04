CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewoptoutstanding (company,dealnumber,executedate,trader,initiator,dealtype,contracttype,exchangetype,counterparty,currency,bc,bp,sp,sc,baseamount,maturitydate,outstanding,tradetype,remarks,premiumamount,companycode) AS
Select Pkgreturncursor.Fncgetdescription(Copt_Company_Code,2) Company,Copt_Deal_Number Dealnumber,
                Copt_Execute_Date Executedate,
                Pkgreturncursor.Fncgetdescription(Copt_Init_Code,2) Trader,
                Pkgreturncursor.Fncgetdescription(Copt_Backup_Deal,2) Initiator,
                Pkgreturncursor.Fncgetdescription(Copt_Deal_Type,2) Dealtype,
                Pkgreturncursor.Fncgetdescription(Copt_Contract_Type,2) Contracttype, 
                pkgreturncursor.fncGetdescription(COPT_EXCHANGE_CODE,2) ExchangeType, 
                Pkgreturncursor.Fncgetdescription(Copt_Counter_Party,2) Counterparty,
                Pkgreturncursor.Fncgetdescription(Copt_Base_Currency,2)||'/'||    
               pkgreturncursor.fncGetdescription(COPT_OTHER_CURRENCY,2) Currency, 
              (select round(avg(cosu_strike_rate),4) from trtran072 
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
                And Cosu_Option_Type=32400001) "SC",
            Copt_Base_Amount Baseamount,
            Copt_Maturity_Date As Maturitydate,
            Pkgforexprocess.Fncgetoutstanding(Copt_Deal_Number,Copt_Serial_Number,15,1,fncAsonDate()) As Outstanding,  
            Decode(Copt_Hedge_Trade, 26000001, 'Hedge', 'Trade') Tradetype,
             Decode (Copt_Record_Status,10200001,'Unconfirmed',10200003,'Confirmed',10200002,'First Confi') Remarks,
            copt_premium_amount PremiumAmount ,Copt_Company_Code as companyCode
     From Trtran071 
     Where Copt_Record_Status Not In(10200005,10200006)
     And ((Copt_Process_Complete = 12400001  And Copt_Complete_Date >Fncasondate()) Or Copt_Process_Complete = 12400002)
     Order By Copt_Deal_Number
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 ;