CREATE TABLE "TEST_VSTSRedgate".trmaster306 (
  lbnk_company_code NUMBER(8) NOT NULL,
  lbnk_pick_code NUMBER(8) NOT NULL,
  lbnk_short_description VARCHAR2(15 BYTE) NOT NULL,
  lbnk_long_description VARCHAR2(50 BYTE) NOT NULL,
  lbnk_contact_person VARCHAR2(50 BYTE),
  lbnk_address_1 VARCHAR2(50 BYTE) NOT NULL,
  lbnk_address_2 VARCHAR2(50 BYTE),
  lbnk_address_3 VARCHAR2(50 BYTE),
  lbnk_address_4 VARCHAR2(50 BYTE),
  lbnk_phone_numbers VARCHAR2(200 BYTE),
  lbnk_fax_numbers VARCHAR2(200 BYTE),
  lbnk_email_id VARCHAR2(100 BYTE),
  lbnk_account_number VARCHAR2(25 BYTE),
  lbnk_preship_limit NUMBER(15,2),
  lbnk_postship_limit NUMBER(15,2),
  lbnk_nonfund_limit NUMBER(15,2),
  lbnk_handling_rate NUMBER(15,4),
  lbnk_service_rate NUMBER(15,2),
  lbnk_create_date DATE NOT NULL,
  lbnk_add_date DATE NOT NULL,
  lbnk_entry_detail XMLTYPE,
  lbnk_record_status NUMBER(8) NOT NULL,
  lbnk_bank_location NUMBER(8),
  lbnk_corr_location NUMBER(8),
  lbnk_voucher_pass NUMBER(8),
  lbnk_limit_usd NUMBER(15,2),
  lbnk_limit_inr NUMBER(15,2),
  lbnk_bank_margin NUMBER(15,6),
  lbnk_sap_code NUMBER(8),
  lbnk_location_code NUMBER(8),
  lbnk_bank_code NUMBER(8),
  lbnk_ifsc_code VARCHAR2(20 BYTE),
  lbnk_interest_outlay NUMBER(8),
  lbnk_intoutlay_rate NUMBER(15,6)
);