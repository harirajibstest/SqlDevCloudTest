CREATE TABLE "TEST_VSTSRedgate".trtran074 (
  link_company_code NUMBER(8) NOT NULL,
  link_batch_number VARCHAR2(25 BYTE) NOT NULL,
  link_trade_references VARCHAR2(500 BYTE),
  link_deal_numbers VARCHAR2(500 BYTE),
  link_hedge_with NUMBER(8),
  link_create_date DATE,
  link_add_date DATE,
  link_entry_detail XMLTYPE,
  link_record_status NUMBER(8),
  CONSTRAINT "trtran074_pk" PRIMARY KEY (link_company_code,link_batch_number)
);