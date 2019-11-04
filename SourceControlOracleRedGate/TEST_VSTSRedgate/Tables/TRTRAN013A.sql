CREATE TABLE "TEST_VSTSRedgate".trtran013a (
  drad_currency_code NUMBER(8) NOT NULL,
  drad_for_currency NUMBER(8) NOT NULL,
  drad_ratesr_number NUMBER(15) NOT NULL,
  drad_bid_rate NUMBER(15,6),
  drad_ask_rate NUMBER(15,6),
  drad_contract_month DATE NOT NULL,
  drad_forward_monthno NUMBER(3) NOT NULL,
  remp_reference_number VARCHAR2(25 BYTE),
  CONSTRAINT trtran013a_pk PRIMARY KEY (drad_currency_code,drad_for_currency,drad_ratesr_number,drad_contract_month,drad_forward_monthno)
);