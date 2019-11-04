CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewoptionsforexcel (exe_date,company,bank,amount,maturity,settlement,bp,sp,bc,sc,rbi_ref_rate,premium,paid,spot,prem_inr,refno,canceldate,cancelrate,gain_loss,cancelpremium,exchangerate,premiumlocal,dealnumber) AS
SELECT copt_execute_date "Date"                                   ,
      pkgReturnCursor.fncGetDescription(copt_company_code,2) "Company",
      pkgReturnCursor.fncGetDescription(copt_counter_party,2) "Bank"  ,
      copt_base_amount "Amount"                                       ,
      copt_expiry_date "Maturity"                                     ,
      copt_maturity_date "Settlement"                                 ,
      (SELECT AVG(cosu_strike_rate)
         FROM trtran072
        WHERE cosu_deal_number = copt_deal_number
         AND cosu_buy_sell     = 25300001
         AND cosu_option_type  = 32400002
      ) "BP",
      (SELECT AVG(cosu_strike_rate)
         FROM trtran072
        WHERE cosu_deal_number = copt_deal_number
         AND cosu_buy_sell     = 25300002
         AND cosu_option_type  = 32400002
      ) "SP",
      (SELECT AVG(cosu_strike_rate)
         FROM trtran072
        WHERE cosu_deal_number = copt_deal_number
         AND cosu_buy_sell     = 25300001
         AND cosu_option_type  = 32400001
      ) "BC",
      (SELECT AVG(cosu_strike_rate)
         FROM trtran072
        WHERE cosu_deal_number = copt_deal_number
         AND cosu_buy_sell     = 25300002
         AND cosu_option_type  = 32400001
      ) "SC"                         ,
      CORV_RBI_REFRATE rbi_ref_rate,
      copt_premium_amount "Premium"  ,
      copt_premium_valuedate "Paid"  ,
      copt_premium_exrate "Spot"     ,
      copt_premium_local "Prem(INR)" ,
      copt_user_reference "RefNo"    ,
      corv_exercise_date "CancelDate",
      corv_rbi_refrate "CancelRate"  ,
      corv_profit_loss "Gain/Loss"   ,
      corv_premium_amount "CancelPremium" ,
    corv_premium_exrate "ExchangeRate" ,
    corv_premium_local "Premiumlocal" ,
      copt_deal_number "DealNumber"
      FROM trtran071
   LEFT OUTER JOIN trtran073
        ON corv_deal_number = copt_deal_number
      AND corv_record_status BETWEEN 10200001 AND 10200004
     WHERE copt_record_status BETWEEN 10200001 AND 10200004
  ORDER BY copt_execute_date
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 ;