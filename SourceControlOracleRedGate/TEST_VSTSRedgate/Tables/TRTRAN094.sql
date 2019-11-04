CREATE TABLE "TEST_VSTSRedgate".trtran094 (
  irat_effective_date DATE NOT NULL,
  irat_settlement_date DATE NOT NULL,
  irat_interest_type NUMBER(8) NOT NULL,
  irat_serial_number NUMBER(5) NOT NULL,
  irat_rate_time VARCHAR2(10 BYTE),
  irat_time_stamp VARCHAR2(25 BYTE),
  irat_rate_description VARCHAR2(50 BYTE),
  irat_instrument VARCHAR2(20 BYTE),
  irat_underlying VARCHAR2(20 BYTE),
  irat_settlement_price NUMBER(15,8),
  irat_record_status NUMBER(8),
  irat_currency_code NUMBER(8) NOT NULL,
  irat_forward_month NUMBER(5) NOT NULL,
  irat_bid_price NUMBER(15,8),
  CONSTRAINT trtran094_pk PRIMARY KEY (irat_effective_date,irat_settlement_date,irat_interest_type,irat_serial_number,irat_currency_code,irat_forward_month)
);