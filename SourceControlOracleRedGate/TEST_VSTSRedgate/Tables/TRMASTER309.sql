CREATE TABLE "TEST_VSTSRedgate".trmaster309 (
  lmer_company_code NUMBER(8) NOT NULL,
  lmer_location_code NUMBER(8) NOT NULL,
  lmer_pick_code NUMBER(8) NOT NULL,
  lmer_serial_number NUMBER(5) NOT NULL,
  lmer_short_description VARCHAR2(15 BYTE) NOT NULL,
  lmer_long_description VARCHAR2(50 BYTE) NOT NULL,
  lmer_user_remarks VARCHAR2(200 BYTE),
  lmer_contact_person VARCHAR2(50 BYTE),
  lmer_address_1 VARCHAR2(50 BYTE) NOT NULL,
  lmer_address_2 VARCHAR2(50 BYTE),
  lmer_address_3 VARCHAR2(50 BYTE),
  lmer_address_4 VARCHAR2(50 BYTE),
  lmer_phone_numbers VARCHAR2(200 BYTE),
  lmer_fax_numbers VARCHAR2(200 BYTE),
  lmer_email_id VARCHAR2(100 BYTE),
  lmnr_bank_code NUMBER(8),
  lmnr_branch_name VARCHAR2(50 BYTE),
  lmnr_ifsc_code VARCHAR2(50 BYTE),
  lmnr_account_name VARCHAR2(50 BYTE),
  lmnr_account_number VARCHAR2(50 BYTE),
  lmer_create_date DATE NOT NULL,
  lmer_add_date DATE NOT NULL,
  lmer_entry_detail XMLTYPE,
  lmer_record_status NUMBER(8) NOT NULL,
  CONSTRAINT trmaster309_pk PRIMARY KEY (lmer_company_code,lmer_pick_code,lmer_serial_number)
);