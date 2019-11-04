CREATE TABLE "TEST_VSTSRedgate".trsystem959 (
  mtmf_company_code NUMBER(8),
  mtmf_location_code NUMBER(8),
  mtmf_business_unit NUMBER(8),
  mtmf_profit_center NUMBER(8),
  mtmf_buy_sell NUMBER(8),
  mtmf_counter_party NUMBER(8),
  mtmf_deal_number VARCHAR2(30 BYTE),
  mtmf_execute_date DATE,
  mtmf_maturity_from DATE,
  mtmf_maturity_date DATE,
  mtmf_base_currency NUMBER(8),
  mtmf_other_currency NUMBER(8),
  mtmf_user_reference VARCHAR2(50 BYTE),
  mtmf_outstanding_amount NUMBER(15,2),
  mtmf_spot_rate NUMBER(15,6),
  mtmf_premium_rate NUMBER(15,6),
  mtmf_bank_margin NUMBER(15,6),
  mtmf_final_rate NUMBER(15,6),
  mtmf_transaction_date DATE,
  mtmf_spot_mtm NUMBER(15,6),
  mtmf_premium_mtm NUMBER(15,6),
  mtmf_final_mtm NUMBER(15,6),
  mtmf_wash_rate NUMBER(15,6),
  mtmf_premium_amort NUMBER(15,6),
  mtmf_premium_amount NUMBER(15,2),
  mtmf_balance_premium NUMBER(15,2),
  mtmf_spot_amount NUMBER(15,2),
  mtmf_forward_amount NUMBER(15,2),
  mtmf_total_pandl NUMBER(15,2),
  mtmf_hedge_reserve NUMBER(15,2),
  mtmf_instument_type NUMBER(8),
  mtmf_record_status NUMBER(8),
  mtmf_user_id VARCHAR2(50 BYTE),
  mtmf_add_date DATE
);