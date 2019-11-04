CREATE TABLE "TEST_VSTSRedgate".trglobalmas914 (
  format_short_desc VARCHAR2(15 BYTE),
  format_long_desc VARCHAR2(50 BYTE),
  format_pick_code NUMBER(8) NOT NULL,
  format_data_type NUMBER(8) NOT NULL,
  format_format_string VARCHAR2(50 BYTE),
  format_create_date DATE,
  format_add_date DATE,
  format_entry_details XMLTYPE,
  format_record_status NUMBER(8),
  format_decimal_scale NUMBER(5),
  CONSTRAINT trglobalsys026_pk PRIMARY KEY (format_pick_code,format_data_type)
);