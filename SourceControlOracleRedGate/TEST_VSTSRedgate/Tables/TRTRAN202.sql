CREATE TABLE "TEST_VSTSRedgate".trtran202 (
  imap_company_code NUMBER(8) NOT NULL,
  imap_location_code NUMBER(8),
  imap_synonym_name VARCHAR2(50 BYTE) NOT NULL,
  imap_document_type NUMBER(8) NOT NULL,
  imap_create_date DATE,
  imap_add_date DATE,
  imap_record_status NUMBER(8),
  CONSTRAINT trtran202_pk PRIMARY KEY (imap_company_code,imap_synonym_name,imap_document_type)
);