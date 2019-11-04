CREATE TABLE "TEST_VSTSRedgate".trtran043 (
  redm_company_code NUMBER(8),
  redm_location_code NUMBER(8),
  redm_deal_number VARCHAR2(25 BYTE) NOT NULL,
  redm_serial_number NUMBER(5) NOT NULL,
  redm_closure_date DATE,
  redm_user_reference VARCHAR2(25 BYTE),
  redm_deal_amount NUMBER(15,4),
  redm_interest_rate NUMBER(15,4),
  redm_market_price NUMBER(15,4),
  redm_maturity_amount NUMBER(15,2),
  redm_profit_loss NUMBER(15,2),
  redm_exchange_rate NUMBER(15,4),
  redm_local_amount NUMBER(15,2),
  redm_local_bank NUMBER(8),
  redm_current_ac VARCHAR2(25 BYTE),
  redm_total_cost NUMBER(15,2),
  redm_total_charges NUMBER(15,2),
  redm_user_remarks VARCHAR2(500 BYTE),
  redm_create_date DATE NOT NULL,
  redm_entry_detail XMLTYPE,
  redm_record_status NUMBER(8) NOT NULL,
  CONSTRAINT trtran043_pk PRIMARY KEY (redm_deal_number,redm_serial_number)
);