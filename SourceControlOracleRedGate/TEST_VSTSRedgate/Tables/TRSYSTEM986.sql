CREATE TABLE "TEST_VSTSRedgate".trsystem986 (
  frwd_deal_number VARCHAR2(25 BYTE),
  frwd_company_code NUMBER(8),
  frwd_execute_date DATE,
  frwd_counter_party NUMBER(8),
  frwd_base_currency NUMBER(8),
  frwd_other_currency NUMBER(8),
  frwd_exchange_rate NUMBER(15,6),
  frwd_base_amount NUMBER(15,2),
  frwd_maturity_from DATE,
  frwd_maturity_date DATE,
  frwd_user_reference VARCHAR2(200 BYTE),
  frwo_reference_date DATE,
  frwo_buyer_seller NUMBER(8),
  frwo_trade_reference VARCHAR2(25 BYTE),
  frwo_hedged_fcy NUMBER(15,2),
  frwo_tradmaturity_from DATE,
  frwo_tradmaturity_date DATE,
  frwo_product_code NUMBER(8),
  frwc_cancel_date DATE,
  frwc_cancle_amount NUMBER(15,4),
  frwc_cancle_rate NUMBER(15,6),
  frwc_profit_loss NUMBER(15,2),
  frwc_other_amount NUMBER(15,2),
  frwc_row_number NUMBER(5),
  frwc_sub_row NUMBER(5),
  frwd_orde_exist NUMBER(5),
  frwo_trade_rate NUMBER(15,6),
  frwo_local_bank NUMBER(8),
  frws_uncovered_total NUMBER(15,6),
  frws_covered_total NUMBER(15,6),
  frws_delivered_total NUMBER(15,6),
  frws_avgdel_rate NUMBER(15,6),
  frws_profit_loss NUMBER(15,6),
  frwo_trade_fcy NUMBER(15,6)
);