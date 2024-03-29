CREATE TABLE "TEST_VSTSRedgate".tftran101 (
  imag_company_code NUMBER(8) NOT NULL,
  imag_location_code NUMBER(8) NOT NULL,
  imag_lob_code NUMBER(8) NOT NULL,
  imag_bank_code NUMBER(8) NOT NULL,
  imag_reference_number VARCHAR2(50 BYTE) NOT NULL,
  imag_reference_serial NUMBER(5) NOT NULL,
  imag_event_type NUMBER(8),
  imag_document_reference VARCHAR2(50 BYTE),
  imag_reference_date DATE,
  imag_document_serial NUMBER(5) NOT NULL,
  imag_user_remarks VARCHAR2(1025 BYTE),
  imag_document_image CLOB,
  imag_create_date DATE NOT NULL,
  imag_entry_detail XMLTYPE,
  imag_record_status NUMBER(8) NOT NULL,
  imag_entity_name VARCHAR2(50 BYTE) NOT NULL,
  imag_bank_reference VARCHAR2(50 BYTE),
  imag_document_type NUMBER(8),
  imag_document_name VARCHAR2(100 BYTE),
  imag_image_type VARCHAR2(20 BYTE),
  imag_voucher_number VARCHAR2(100 BYTE),
  imag_serial_number NUMBER(8),
  CONSTRAINT pk_tftran101 PRIMARY KEY (imag_reference_number,imag_reference_serial)
);