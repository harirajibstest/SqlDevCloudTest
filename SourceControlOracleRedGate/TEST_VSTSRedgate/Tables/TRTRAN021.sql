CREATE TABLE "TEST_VSTSRedgate".trtran021 (
  remm_reminder_number VARCHAR2(25 BYTE) NOT NULL,
  remm_report_id VARCHAR2(50 BYTE) NOT NULL,
  remm_reminder_date DATE NOT NULL,
  remm_reminder_matter CLOB,
  remm_reminder_remarks VARCHAR2(256 BYTE),
  remm_create_date DATE,
  remm_record_status NUMBER(8),
  remm_final_xml VARCHAR2(4000 BYTE),
  CONSTRAINT pk_trtran021 PRIMARY KEY (remm_reminder_number)
);