CREATE TABLE "TEST_VSTSRedgate".trsystem023 (
  pswd_company_code NUMBER(8) NOT NULL,
  pswd_user_id VARCHAR2(50 BYTE) NOT NULL,
  pswd_serial_number NUMBER(5) NOT NULL,
  pswd_password_key VARCHAR2(200 BYTE),
  pswd_password_code VARCHAR2(200 BYTE),
  pswd_password_hint VARCHAR2(200 BYTE),
  pswd_password_status NUMBER(8) NOT NULL,
  pswd_create_date DATE NOT NULL,
  pswd_add_date DATE NOT NULL,
  pswd_entry_detail XMLTYPE,
  pswd_record_status NUMBER(8) NOT NULL,
  CONSTRAINT pk_trsystem023 PRIMARY KEY (pswd_company_code,pswd_user_id,pswd_serial_number)
);