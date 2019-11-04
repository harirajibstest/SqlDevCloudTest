CREATE TABLE "TEST_VSTSRedgate".trtran096 (
  irdl_company_code NUMBER(8) NOT NULL,
  irdl_location_code NUMBER(8) NOT NULL,
  irdl_trade_reference VARCHAR2(25 BYTE) NOT NULL,
  irdl_deal_number VARCHAR2(25 BYTE) NOT NULL,
  irdl_deal_serial NUMBER(5) NOT NULL,
  irdl_hedged_amount NUMBER(15,2) NOT NULL,
  irdl_create_date DATE NOT NULL,
  irdl_add_date DATE NOT NULL,
  irdl_entry_detail XMLTYPE,
  irdl_record_status NUMBER(8) NOT NULL,
  irdl_hedging_with NUMBER(8),
  CONSTRAINT pk_trtran096 PRIMARY KEY (irdl_company_code,irdl_location_code,irdl_trade_reference,irdl_deal_number,irdl_deal_serial)
);