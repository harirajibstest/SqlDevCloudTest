CREATE TABLE "TEST_VSTSRedgate".trsystem033 (
  resv_report_id VARCHAR2(50 BYTE) NOT NULL,
  resv_serial_number NUMBER(5) NOT NULL,
  resv_report_date DATE,
  resv_data_xml VARCHAR2(4000 BYTE),
  resv_user_id VARCHAR2(100 BYTE),
  resv_report_remarks VARCHAR2(4000 BYTE),
  resv_save_date DATE,
  resv_add_date DATE,
  resv_record_status NUMBER(8),
  CONSTRAINT trsystem033_pk PRIMARY KEY (resv_report_id,resv_serial_number)
);