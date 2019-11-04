CREATE TABLE "TEST_VSTSRedgate".trtran007 (
  trln_company_code NUMBER(8) NOT NULL,
  trln_loan_number VARCHAR2(30 BYTE) NOT NULL,
  trln_trade_reference VARCHAR2(25 BYTE) NOT NULL,
  trln_serial_number NUMBER(5) NOT NULL,
  trln_trade_serial NUMBER(5),
  trln_adjusted_date DATE NOT NULL,
  trln_adjusted_fcy NUMBER(15,4) NOT NULL,
  trln_adjusted_rate NUMBER(15,6),
  trln_adjusted_inr NUMBER(15,2),
  trln_create_date DATE NOT NULL,
  trln_entry_detail XMLTYPE,
  trln_record_status NUMBER(8) NOT NULL,
  CONSTRAINT pk_trtran007 PRIMARY KEY (trln_company_code,trln_loan_number,trln_trade_reference,trln_serial_number)
);