CREATE TABLE "TEST_VSTSRedgate".trtran010 (
  loln_company_code NUMBER(8) NOT NULL,
  loln_loan_number VARCHAR2(30 BYTE) NOT NULL,
  loln_trade_reference VARCHAR2(25 BYTE) NOT NULL,
  loln_serial_number NUMBER(5) NOT NULL,
  loln_trade_serial NUMBER(5),
  loln_adjusted_date DATE NOT NULL,
  loln_adjusted_fcy NUMBER(15,4) NOT NULL,
  loln_adjusted_rate NUMBER(15,6),
  loln_adjusted_inr NUMBER(15,2),
  loln_create_date DATE NOT NULL,
  loln_entry_detail XMLTYPE,
  loln_record_status NUMBER(8) NOT NULL,
  CONSTRAINT pk_trtran010 PRIMARY KEY (loln_company_code,loln_loan_number,loln_trade_reference,loln_serial_number)
);