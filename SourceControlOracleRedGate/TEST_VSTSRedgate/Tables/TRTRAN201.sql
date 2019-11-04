CREATE TABLE "TEST_VSTSRedgate".trtran201 (
  imag_company_code NUMBER(8) NOT NULL,
  imag_location_code NUMBER(8) NOT NULL,
  imag_reference_number VARCHAR2(25 BYTE) NOT NULL,
  imag_reference_serial NUMBER(5) NOT NULL,
  imag_serial_number NUMBER(5) NOT NULL,
  imag_voucher_number VARCHAR2(25 BYTE),
  imag_event_type NUMBER(8) NOT NULL,
  imag_document_type NUMBER(8) NOT NULL,
  imag_document_reference VARCHAR2(50 BYTE),
  imag_reference_date DATE,
  imag_document_serial NUMBER(5) NOT NULL,
  imag_user_remarks VARCHAR2(1025 BYTE),
  imag_image_type NUMBER(8),
  imag_document_image BLOB,
  imag_create_date DATE NOT NULL,
  imag_entry_detail XMLTYPE,
  imag_record_status NUMBER(8) NOT NULL
);