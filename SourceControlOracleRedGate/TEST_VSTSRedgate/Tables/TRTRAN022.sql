CREATE TABLE "TEST_VSTSRedgate".trtran022 (
  remu_reminder_number VARCHAR2(25 BYTE) NOT NULL,
  remu_serial_number NUMBER(5) NOT NULL,
  remu_user_id VARCHAR2(50 BYTE) NOT NULL,
  remu_disposal_code NUMBER(8),
  remu_forwarded_user VARCHAR2(50 BYTE),
  remu_reminder_remarks VARCHAR2(1000 BYTE),
  remu_create_date DATE,
  remu_entry_detail XMLTYPE,
  remu_record_status NUMBER(8) NOT NULL,
  remu_reminder_date DATE,
  CONSTRAINT pk_trtran022 PRIMARY KEY (remu_reminder_number,remu_serial_number,remu_user_id)
);