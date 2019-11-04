CREATE TABLE "TEST_VSTSRedgate".trsystem103 (
  brel_company_code NUMBER(8) NOT NULL,
  brel_trade_reference VARCHAR2(25 BYTE) NOT NULL,
  brel_reverse_serial NUMBER(5) NOT NULL,
  brel_entry_date DATE NOT NULL,
  brel_user_reference VARCHAR2(50 BYTE),
  brel_reference_date DATE,
  brel_reversal_type NUMBER(8) NOT NULL,
  brel_reversal_fcy NUMBER(15,2) NOT NULL,
  brel_reversal_rate NUMBER(15,6) NOT NULL,
  brel_reversal_inr NUMBER(15,2) NOT NULL,
  brel_period_code NUMBER(8) NOT NULL,
  brel_trade_period NUMBER(5) NOT NULL,
  brel_maturity_from DATE,
  brel_maturity_date DATE,
  brel_create_date DATE NOT NULL,
  brel_entry_detail XMLTYPE,
  brel_record_status NUMBER(8) NOT NULL,
  brel_local_bank NUMBER(8),
  brel_reverse_reference VARCHAR2(25 BYTE),
  brel_location_code NUMBER(8),
  brel_batch_number VARCHAR2(25 BYTE),
  workdate DATE,
  datestamp VARCHAR2(25 BYTE),
  imagetype VARCHAR2(10 BYTE),
  entity VARCHAR2(30 BYTE)
);