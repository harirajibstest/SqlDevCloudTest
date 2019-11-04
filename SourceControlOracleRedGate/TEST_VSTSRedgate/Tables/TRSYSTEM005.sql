CREATE TABLE "TEST_VSTSRedgate".trsystem005 (
  punt_company_code NUMBER(8) NOT NULL,
  punt_program_unit VARCHAR2(30 BYTE) NOT NULL,
  punt_serial_number NUMBER(5) NOT NULL,
  punt_control_name VARCHAR2(100 BYTE),
  punt_access_insert NUMBER(8) NOT NULL,
  punt_access_edit NUMBER(8) NOT NULL,
  punt_access_delete NUMBER(8) NOT NULL,
  punt_access_confirm NUMBER(8) NOT NULL,
  punt_access_view NUMBER(8) NOT NULL,
  punt_access_print NUMBER(8) NOT NULL,
  punt_access_save NUMBER(8) NOT NULL,
  punt_create_date DATE NOT NULL,
  punt_add_date DATE NOT NULL,
  punt_entry_detail XMLTYPE,
  punt_record_status NUMBER(8) NOT NULL,
  punt_webcontrol_name VARCHAR2(100 BYTE),
  punt_view_inweb NUMBER(8)
);