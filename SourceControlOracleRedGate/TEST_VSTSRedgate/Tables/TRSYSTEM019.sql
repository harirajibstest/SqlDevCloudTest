CREATE TABLE "TEST_VSTSRedgate".trsystem019 (
  crsk_company_code NUMBER(8) NOT NULL,
  crsk_crsk_reference VARCHAR2(15 BYTE) NOT NULL,
  crsk_effective_date DATE NOT NULL,
  crsk_crsk_type NUMBER(8) NOT NULL,
  crsk_hedge_trade NUMBER(8) NOT NULL,
  crsk_buy_sell NUMBER(8) NOT NULL,
  crsk_deal_type NUMBER(8) NOT NULL,
  crsk_counter_party NUMBER(8) NOT NULL,
  crsk_product_code NUMBER(8) NOT NULL,
  crsk_dealer_id VARCHAR2(50 BYTE) NOT NULL,
  crsk_limit_usd NUMBER(15,2),
  crsk_limit_local NUMBER(15,2),
  crsk_limit_percent NUMBER(15,2),
  crsk_action_taken NUMBER(8),
  crsk_stake_holder VARCHAR2(50 BYTE),
  crsk_fluct_allowed NUMBER(15,2),
  crsk_fluct_ceo NUMBER(15,2),
  crsk_noof_days NUMBER(3),
  crsk_create_date DATE NOT NULL,
  crsk_add_date DATE NOT NULL,
  crsk_entry_detail XMLTYPE,
  crsk_record_status NUMBER(8) NOT NULL,
  crsk_exchange_code NUMBER(8),
  CONSTRAINT pk_trsystem019 PRIMARY KEY (crsk_crsk_reference,crsk_effective_date)
);