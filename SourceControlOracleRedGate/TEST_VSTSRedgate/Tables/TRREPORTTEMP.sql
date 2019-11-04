CREATE TABLE "TEST_VSTSRedgate".trreporttemp (
  repm_report_id VARCHAR2(30 BYTE) NOT NULL,
  repm_report_name VARCHAR2(256 BYTE) NOT NULL,
  repm_papersize NUMBER(4),
  repm_lines NUMBER(4),
  repm_title VARCHAR2(4000 BYTE),
  repm_heading VARCHAR2(4000 BYTE),
  repm_column_detail XMLTYPE,
  repm_condition_detail XMLTYPE,
  repm_record_status NUMBER(8) NOT NULL,
  repm_functiondetail XMLTYPE,
  repm_serial_number NUMBER(5) NOT NULL,
  repm_format VARCHAR2(4000 BYTE)
);