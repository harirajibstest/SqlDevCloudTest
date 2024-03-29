CREATE TABLE "TEST_VSTSRedgate".trsystem010 (
  rept_company_code NUMBER(8) NOT NULL,
  rept_report_id VARCHAR2(30 BYTE) NOT NULL,
  rept_serial_number NUMBER(5) NOT NULL,
  rept_report_file VARCHAR2(256 BYTE) NOT NULL,
  rept_assembly_name VARCHAR2(30 BYTE),
  rept_report_remarks VARCHAR2(100 BYTE),
  rept_report_header VARCHAR2(200 BYTE),
  rept_report_width NUMBER(3) NOT NULL,
  rept_report_period NUMBER(8) NOT NULL,
  rept_printer_type NUMBER(8),
  rept_auto_generate NUMBER(8),
  rept_report_param XMLTYPE,
  rept_user_forward VARCHAR2(30 BYTE),
  rept_create_date DATE NOT NULL,
  rept_add_date DATE NOT NULL,
  rept_entry_detail XMLTYPE,
  rept_record_status NUMBER(8) NOT NULL,
  CONSTRAINT pk_trsystem01 PRIMARY KEY (rept_company_code,rept_report_id,rept_serial_number)
);