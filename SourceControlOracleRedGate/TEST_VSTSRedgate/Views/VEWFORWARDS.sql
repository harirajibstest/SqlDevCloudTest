CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewforwards (dealnumber,dealref,buysell,companycode,companyname,bankcode,bankname,dealdate,dealamount,currency,exrate,maturity,canceldate,cancelrate,pandlfcy,status,completedate,transcode,trans,hedgetrade,userid,initcode) AS
select deal_deal_number DealNumber, 
        deal_dealer_remarks dealref, deal_buy_sell BuySell,
        deal_company_code CompanyCode, a.pick_short_description CompanyName,
        deal_counter_party BankCode, b.pick_short_description BankName,
        deal_execute_date DealDate, deal_base_amount DealAmount, 
        c.pick_short_description || '/' || d.pick_short_description Currency,
        deal_exchange_rate Exrate,deal_maturity_date Maturity, 
        max(cdel_cancel_date) CancelDate, Round(avg(cdel_cancel_rate),6) CancelRate, 
        NVL(sum(cdel_profit_loss),0) PandLFcy, deal_process_complete Status,
        deal_complete_date CompleteDate, 
        deal_backup_deal TransCode, e.pick_short_description Trans,
        deal_hedge_trade HedgeTrade, deal_user_id UserID, deal_init_code InitCode
        from trtran001
        left outer join trtran006
          on deal_deal_number = cdel_deal_number
          and cdel_record_status between 10200001 and 10200004
        join trmaster001 a
          on deal_company_code = a.pick_key_value
        join trmaster001 b
          on deal_counter_party = b.pick_key_value
        join trmaster001 c
          on deal_base_currency = c.pick_key_value
        join trmaster001 d
          on deal_other_currency = d.pick_key_value
        join trmaster001 e
          on NVL(deal_backup_deal,12400001) = e.pick_key_value
        group by deal_deal_number, deal_buy_sell,
        deal_company_code,deal_counter_party,
        deal_execute_date,deal_base_amount,
        a.pick_short_description, b.pick_short_description,
        c.pick_short_description,d.pick_short_description, e.pick_short_description,
        deal_exchange_rate,deal_maturity_date, deal_dealer_remarks,
        deal_process_complete, deal_complete_date, deal_backup_deal,
        deal_hedge_trade, deal_user_id, deal_init_code
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 ;