CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewfutures (dealnumber,dealref,buysell,companycode,companyname,bankcode,bankname,dealdate,dealamount,currency,exrate,maturity,canceldate,cancelrate,pandlfcy,status,completedate,transcode,trans,hedgetrade,userid,initcode) AS
select cfut_deal_number DealNumber, 
        cfut_dealer_remark dealref, cfut_buy_sell BuySell,
        cfut_company_code CompanyCode, a.pick_short_description CompanyName,
        cfut_counter_party BankCode, b.pick_short_description BankName,
        cfut_execute_date DealDate, cfut_base_amount DealAmount, 
        c.pick_short_description || '/' || d.pick_short_description Currency,
        cfut_exchange_rate Exrate,cfut_maturity_date Maturity, 
        max(cfrv_execute_date) CancelDate, Round(avg(cfrv_lot_price),6) CancelRate, 
        NVL(sum(cfrv_profit_loss),0) PandLFcy, cfut_process_complete Status,
        cfut_complete_date CompleteDate, 
        cfut_backup_deal TransCode, e.pick_short_description Trans,
        cfut_hedge_trade HedgeTrade, cfut_user_id UserId, cfut_init_code InitCode
        from trtran061
        left outer join trtran063
          on cfut_deal_number = cfrv_deal_number
          and cfrv_record_status between 10200001 and 10200004
        join trmaster001 a
          on cfut_company_code = a.pick_key_value
        join trmaster001 b
          on cfut_counter_party = b.pick_key_value
        join trmaster001 c
          on cfut_base_currency = c.pick_key_value
        join trmaster001 d
          on cfut_other_currency = d.pick_key_value
        join trmaster001 e
          on cfut_backup_deal = e.pick_key_value
        group by cfut_deal_number, cfut_buy_sell,
        cfut_company_code,cfut_counter_party,
        cfut_execute_date,cfut_base_amount,
        a.pick_short_description, b.pick_short_description,
        c.pick_short_description,d.pick_short_description, e.pick_short_description,
        cfut_exchange_rate,cfut_maturity_date, cfut_dealer_remark,
        cfut_process_complete, cfut_complete_date, cfut_backup_deal,
        cfut_hedge_trade, cfut_user_id, cfut_init_code
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 ;