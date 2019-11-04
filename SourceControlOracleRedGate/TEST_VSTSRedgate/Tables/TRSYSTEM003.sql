CREATE TABLE "TEST_VSTSRedgate".trsystem003 (
  repm_menu_id NUMBER(4) NOT NULL,
  repm_report_id VARCHAR2(30 BYTE) NOT NULL,
  repm_report_file VARCHAR2(256 BYTE) NOT NULL,
  repm_report_params XMLTYPE,
  repm_browser_sql VARCHAR2(4000 BYTE),
  repm_report_sql VARCHAR2(4000 BYTE),
  repm_create_date DATE NOT NULL,
  repm_entry_detail XMLTYPE,
  repm_record_status NUMBER(8) NOT NULL,
  repm_company_field VARCHAR2(50 BYTE),
  repm_cursor_count NUMBER(8),
  repm_report_type NUMBER(8)
);