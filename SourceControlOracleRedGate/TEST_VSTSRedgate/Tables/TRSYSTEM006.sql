CREATE TABLE "TEST_VSTSRedgate".trsystem006 (
  actl_company_code NUMBER(8) NOT NULL,
  actl_group_code NUMBER(8) NOT NULL,
  actl_user_id VARCHAR2(15 BYTE) NOT NULL,
  actl_program_unit VARCHAR2(30 BYTE) NOT NULL,
  actl_serial_number NUMBER(5) NOT NULL,
  actl_access_insert NUMBER(8) NOT NULL,
  actl_access_edit NUMBER(8) NOT NULL,
  actl_access_delete NUMBER(8) NOT NULL,
  actl_access_confirm NUMBER(8) NOT NULL,
  actl_access_view NUMBER(8) NOT NULL,
  actl_access_print NUMBER(8) NOT NULL,
  actl_access_save NUMBER(8) NOT NULL,
  actl_create_date DATE NOT NULL,
  actl_add_date DATE NOT NULL,
  actl_entry_detail XMLTYPE,
  actl_record_status NUMBER(8) NOT NULL
);