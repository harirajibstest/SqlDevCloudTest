CREATE TABLE "TEST_VSTSRedgate".trtran093 (
  iiro_company_code NUMBER(8) NOT NULL,
  iiro_location_code NUMBER(8),
  iiro_deal_number VARCHAR2(25 BYTE) NOT NULL,
  iiro_serial_number NUMBER(5) NOT NULL,
  iiro_multiple_deals NUMBER(8),
  iiro_deal_type NUMBER(8) NOT NULL,
  iiro_user_reference VARCHAR2(200 BYTE),
  iiro_execute_date DATE NOT NULL,
  iiro_exchange_code NUMBER(8) NOT NULL,
  iiro_counter_party NUMBER(8) NOT NULL,
  iiro_currency_code NUMBER(8) NOT NULL,
  iiro_base_amount NUMBER(15,2) NOT NULL,
  iiro_contract_type NUMBER(8) NOT NULL,
  iiro_hedge_trade NUMBER(8) NOT NULL,
  iiro_option_style NUMBER(8) NOT NULL,
  iiro_expiry_date DATE NOT NULL,
  iiro_maturity_date DATE NOT NULL,
  iiro_spread_yn NUMBER(8) NOT NULL,
  iiro_spread_deal VARCHAR2(25 BYTE),
  iiro_dealer_remark VARCHAR2(1000 BYTE),
  iiro_bo_remark VARCHAR2(1000 BYTE),
  iiro_product_code NUMBER(8) NOT NULL,
  iiro_broker_code NUMBER(8),
  iiro_local_bank NUMBER(8) NOT NULL,
  iiro_margin_rate NUMBER(15,4) NOT NULL,
  iiro_margin_amount NUMBER(15,2) NOT NULL,
  iiro_brokerage_rate NUMBER(15,4) NOT NULL,
  iiro_brokerage_amount NUMBER(15,2) NOT NULL,
  iiro_service_tax NUMBER(15,2),
  iiro_transaction_cost NUMBER(15,2),
  iiro_other_charges NUMBER(15,2),
  iiro_premium_rate NUMBER(15,6),
  iiro_premium_amount NUMBER(15,2),
  iiro_premium_exrate NUMBER(15,6),
  iiro_premium_local NUMBER(15,2),
  iiro_premium_valuedate DATE,
  iiro_premium_status NUMBER(8),
  iiro_execute_time VARCHAR2(10 BYTE) NOT NULL,
  iiro_time_stamp VARCHAR2(25 BYTE) NOT NULL,
  iiro_confirm_date DATE,
  iiro_process_complete NUMBER(8) NOT NULL,
  iiro_complete_date DATE,
  iiro_create_date DATE NOT NULL,
  iiro_add_date DATE NOT NULL,
  iiro_entry_detail XMLTYPE,
  iiro_record_status NUMBER(8) NOT NULL,
  iiro_portfolio NUMBER(8),
  iiro_rate_type NUMBER(8),
  iiro_interest_daystype NUMBER(8),
  iiro_sub_portfolio NUMBER(8),
  CONSTRAINT pk_trtran093 PRIMARY KEY (iiro_company_code,iiro_deal_number,iiro_serial_number)
);