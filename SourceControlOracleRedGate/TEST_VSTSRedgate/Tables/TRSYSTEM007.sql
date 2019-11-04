CREATE TABLE "TEST_VSTSRedgate".trsystem007 (
  serl_serial_code NUMBER(8),
  serl_concat_code NUMBER(8) NOT NULL,
  serl_reset_code NUMBER(8) NOT NULL,
  serl_date_code NUMBER(8),
  serl_serial_width NUMBER(1) NOT NULL,
  serl_reset_on DATE NOT NULL,
  serl_serial_number NUMBER(9),
  serl_create_date DATE,
  serl_record_status NUMBER(8),
  serl_entry_detail XMLTYPE,
  serl_company_code NUMBER(8),
  serl_location_code NUMBER(8)
);