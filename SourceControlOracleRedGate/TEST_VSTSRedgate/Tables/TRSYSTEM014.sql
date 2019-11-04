CREATE TABLE "TEST_VSTSRedgate".trsystem014 (
  rusr_user_id VARCHAR2(50 BYTE) NOT NULL,
  rusr_reminder_code NUMBER(8) NOT NULL,
  rusr_create_date DATE NOT NULL,
  rusr_entry_detail XMLTYPE,
  rusr_record_status NUMBER(8) NOT NULL,
  CONSTRAINT pk_trsystem014 PRIMARY KEY (rusr_user_id,rusr_reminder_code)
);