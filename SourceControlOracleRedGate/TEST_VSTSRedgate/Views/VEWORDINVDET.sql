CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".vewordinvdet (ord_trade_ref,ord_ref_date,ord_company,ord_counterparty,ord_trade_fcy,ord_exchange_rate,ord_currency,ord_outstand_amt,ord_user_ref,ord_maturity_month,ord_buy_sell,ord_import_export,ord_product,inv_trade_ref,inv_ref_date,inv_counter_party,inv_trade_fcy,inv_exchange_rate,inv_linked_amount,inv_currency,inv_user_ref,inv_maturity_month,deal_number,deal_execute_date,deal_exchange_rate,deal_maturity_from,deal_maturity_date,deal_hedge_amt) AS
select 
        tord__trade_reference,
        tord_reference_date,
        company,
        counterparty,
        tord_trade_fcy,
        tord_exchange_rate,
        currency,
        tord_outstanding_amount,
        tord_user_reference,
        tord_maturity_month,
        buysell,
        importexport,
        product,
        tinv_trade_reference,
        tinv_reference_date,
        invcounterparty,
        tinv_trade_fcy,
        tinv_exchange_rate,
        tinv_linked_amount,
        invcurrency,
        tinv_user_reference,
        tinv_maturity_month,
        --TINV_BUYER_SELLER,
        --TINV_IMPORT_EXPORT,
        --TINV_PRODUCT_CODE,
        tdel_deal_number,
        tdel_execute_date,
        --TDEL_COUNTER_PARTY,
        tdel_exchange_rate,
        tdel_maturity_from,
        tdel_maturity_date,
        tdel_hedged_fcy
       from (
         select tord_row_num,
                tord_sub_row,
                tord__trade_reference,
                tord_reference_date,
                pkgreturncursor.fncgetdescription(tord_company_code, 2) company,
                pkgreturncursor.fncgetdescription(tord_local_bank, 2) counterparty,
                tord_trade_fcy,
                tord_exchange_rate,
                pkgreturncursor.fncgetdescription(tord_currency_code, 2) currency,
                tord_outstanding_amount,
                tord_user_reference,
                tord_maturity_month,
                pkgreturncursor.fncgetdescription(tord_buyer_seller, 2) buysell,
                pkgreturncursor.fncgetdescription(tord_import_export, 2) importexport,
                pkgreturncursor.fncgetdescription(tord_product_code, 2) product,
                tinv_trade_reference,
                tinv_reference_date,
                pkgreturncursor.fncgetdescription(tinv_local_bank, 2) invcounterparty,
                tinv_trade_fcy,
                tinv_exchange_rate,
                tinv_linked_amount,
                pkgreturncursor.fncgetdescription(tinv_currency_code, 2) invcurrency,
                tinv_user_reference,
                tinv_maturity_month,
                --TINV_BUYER_SELLER,
                --TINV_IMPORT_EXPORT,
                --TINV_PRODUCT_CODE,
                tdel_deal_number,
                tdel_execute_date,
                --TDEL_COUNTER_PARTY,
                tdel_exchange_rate,
                tdel_maturity_from,
                tdel_maturity_date,
                tdel_hedged_fcy
           from tmprep_ordinv
          union all
         select tord_row_num,
                null,
                tord__trade_reference,
                tord_reference_date,
                pkgreturncursor.fncgetdescription(tord_company_code, 2) company,
                pkgreturncursor.fncgetdescription(tord_local_bank, 2) counterparty,
                null,
                null,
                '',
                null,
                '',
                null,
                '',
                '',
                '',
                '',
                null,
                'TOTAL',
                nvl(sum(tinv_trade_fcy), 0) tinv_trade_fcy,
                null,
                nvl(sum(tinv_linked_amount), 0) tinv_linked_amount,
                '',
                '',
                null,
                '',
                null,
                null,
                null,
                null,
                nvl(sum(tdel_hedged_fcy), 0) tdel_hedged_fcy
           from tmprep_ordinv
          group by tord_row_num,
                tord__trade_reference,
                tord_reference_date,
                tord_company_code,
                tord_local_bank
      )
 order by company,
          counterparty,
          tord__trade_reference,
          tord_reference_date,
          tord_row_num,
          tord_sub_row
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 ;