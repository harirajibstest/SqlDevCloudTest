CREATE TABLE "TEST_VSTSRedgate".trsystem999f (
  vald_program_unit VARCHAR2(25 BYTE) NOT NULL,
  vald_user_group NUMBER(8) NOT NULL,
  vald_validation_name VARCHAR2(50 BYTE) NOT NULL,
  vald_validation_displaymessage VARCHAR2(100 BYTE),
  vald_validation_remarks VARCHAR2(200 BYTE),
  vald_add_action NUMBER(8),
  vald_edit_action NUMBER(8),
  vald_confirm_action NUMBER(8),
  vald_record_status NUMBER(8),
  vald_create_date DATE,
  vald_add_date DATE,
  vald_validation_type NUMBER(8),
  CONSTRAINT trsystem999f_pk PRIMARY KEY (vald_program_unit,vald_user_group,vald_validation_name)
);
COMMENT ON COLUMN "TEST_VSTSRedgate".trsystem999f.vald_validation_displaymessage IS 'Display Message used in Front end';
COMMENT ON COLUMN "TEST_VSTSRedgate".trsystem999f.vald_validation_type IS 'if Code is 10100001-System Type then this should not be avalible in Admin Console to change 
10100002-User Type Only this type Should be avalible for Admin Console';