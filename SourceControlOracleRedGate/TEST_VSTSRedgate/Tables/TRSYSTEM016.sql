CREATE TABLE "TEST_VSTSRedgate".trsystem016 (
  budg_company_code NUMBER(8) NOT NULL,
  budg_dealer_id VARCHAR2(50 BYTE) NOT NULL,
  budg_year_ending DATE NOT NULL,
  budg_deal_type NUMBER(8) NOT NULL,
  budg_currency_code NUMBER(8) NOT NULL,
  budg_period_type NUMBER(8) NOT NULL,
  budg_period_ending DATE NOT NULL,
  budg_budget_fcy NUMBER(15,6),
  budg_budget_usd NUMBER(15,6),
  budg_budget_inr NUMBER(15,2),
  budg_create_date DATE NOT NULL,
  budg_entry_detail XMLTYPE,
  budg_record_status NUMBER(8) NOT NULL,
  CONSTRAINT pk_trsystem016 PRIMARY KEY (budg_company_code,budg_dealer_id,budg_period_ending)
);