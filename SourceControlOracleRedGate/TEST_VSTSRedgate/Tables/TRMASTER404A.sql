CREATE TABLE "TEST_VSTSRedgate".trmaster404a (
  foli_company_code NUMBER(8) NOT NULL,
  foli_location_code NUMBER(8) NOT NULL,
  foli_amc_code NUMBER(8) NOT NULL,
  foli_serial_number NUMBER(4) NOT NULL,
  foli_folio_number VARCHAR2(25 BYTE),
  foli_user_remarks VARCHAR2(250 BYTE),
  foli_add_date DATE,
  foli_create_date DATE,
  foli_entry_detail XMLTYPE,
  foli_record_status NUMBER(8),
  CONSTRAINT pk_trmaster404a PRIMARY KEY (foli_company_code,foli_location_code,foli_amc_code,foli_serial_number)
);