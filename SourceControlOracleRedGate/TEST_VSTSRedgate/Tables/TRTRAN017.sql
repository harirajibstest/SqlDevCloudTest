CREATE TABLE "TEST_VSTSRedgate".trtran017 (
  fdln_company_code NUMBER(8) NOT NULL,
  fdln_location_code NUMBER(8) NOT NULL,
  fdln_fd_number VARCHAR2(25 BYTE) NOT NULL,
  fdln_lien_reference VARCHAR2(30 BYTE) NOT NULL,
  fdln_lien_date DATE,
  fdln_create_date DATE NOT NULL,
  fdln_entry_detail XMLTYPE,
  fdln_record_status NUMBER(8) NOT NULL,
  CONSTRAINT pk_trtran017 PRIMARY KEY (fdln_company_code,fdln_location_code,fdln_fd_number,fdln_lien_reference)
);