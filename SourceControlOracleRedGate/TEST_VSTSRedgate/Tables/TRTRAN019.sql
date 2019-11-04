CREATE TABLE "TEST_VSTSRedgate".trtran019 (
  link_company_code NUMBER(8) NOT NULL,
  link_batch_number VARCHAR2(25 BYTE) NOT NULL,
  link_serial_number NUMBER(5) NOT NULL,
  link_link_date DATE,
  link_deal_number VARCHAR2(25 BYTE),
  link_add_date DATE,
  link_create_date DATE,
  link_entry_details XMLTYPE,
  link_record_status NUMBER(8),
  CONSTRAINT trtran019_pk PRIMARY KEY (link_company_code,link_batch_number,link_serial_number)
);