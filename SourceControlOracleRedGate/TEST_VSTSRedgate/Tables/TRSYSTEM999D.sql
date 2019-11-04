CREATE TABLE "TEST_VSTSRedgate".trsystem999d (
  lang_company_code NUMBER(8) NOT NULL,
  lang_location_code NUMBER(8) NOT NULL,
  lang_language_code VARCHAR2(5 BYTE) NOT NULL,
  lang_data_type VARCHAR2(20 BYTE) NOT NULL,
  lang_format_string VARCHAR2(50 BYTE),
  lang_create_date DATE,
  lang_add_date DATE,
  lang_record_status NUMBER(8),
  CONSTRAINT trsystem999d_pk PRIMARY KEY (lang_company_code,lang_location_code,lang_data_type,lang_language_code)
);