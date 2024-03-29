CREATE TABLE "TEST_VSTSRedgate".trsystem983_hedgecost (
  hdct_company_code NUMBER(8),
  hdct_location_code NUMBER(8),
  hdct_business_unit NUMBER(8),
  hdct_profit_center NUMBER(8),
  hdct_buy_sell NUMBER(8),
  hdct_hedge_trade NUMBER(8),
  hdct_execute_date DATE,
  hdct_maturity_from DATE,
  hdct_maturity_to DATE,
  hdct_counter_party NUMBER(8),
  hdct_outstanding_amount NUMBER(15,2),
  hdct_exchange_rate NUMBER(15,6),
  hdct_spot_rate NUMBER(15,6),
  hdct_forward_rate NUMBER(15,6),
  hdct_margin_rate NUMBER(15,6),
  hdct_cancel_amount NUMBER(15,2),
  hdct_premium_amount NUMBER(15,2),
  hdct_exercise_type NUMBER(15,6),
  hdct_deal_number VARCHAR2(30 BYTE),
  hdct_main_description VARCHAR2(100 BYTE),
  hdct_sub_description VARCHAR2(100 BYTE),
  hdct_main_order NUMBER(2),
  hdct_sub_order NUMBER(2),
  hdct_instument VARCHAR2(30 BYTE),
  hdct_ason_date DATE,
  hdct_base_currency NUMBER(8),
  hdct_other_currency NUMBER(8),
  hdct_buycall_rate NUMBER(15,6),
  hdct_buyput_rate NUMBER(15,6),
  hdct_sellcall_rate NUMBER(15,6),
  hdct_sellput_rate NUMBER(15,6),
  hdct_cancel_rate NUMBER(15,6),
  hdct_cancel_spot NUMBER(15,6),
  hdct_cancel_forward NUMBER(15,6),
  hdct_cancel_margin NUMBER(15,6),
  hdct_cancel_date DATE,
  hdct_cpremium_amount NUMBER(15,2),
  hdct_premium_rate NUMBER(15,6),
  hdct_cpremium_rate NUMBER(15,6),
  hdct_profit_loss NUMBER(15,2),
  hdct_ason_month VARCHAR2(10 BYTE),
  hdct_mtm_amount NUMBER(15,2),
  hgct_cancel_premium NUMBER(15,6)
);