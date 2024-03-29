CREATE TABLE "TEST_VSTSRedgate".trmaster502 (
  cbrk_company_code NUMBER(8) NOT NULL,
  cbrk_pick_code NUMBER(8) NOT NULL,
  cbrk_short_description VARCHAR2(15 BYTE) NOT NULL,
  cbrk_long_description VARCHAR2(50 BYTE) NOT NULL,
  cbrk_contact_person VARCHAR2(50 BYTE),
  cbrk_address_1 VARCHAR2(50 BYTE) NOT NULL,
  cbrk_address_2 VARCHAR2(50 BYTE),
  cbrk_address_3 VARCHAR2(50 BYTE),
  cbrk_address_4 VARCHAR2(50 BYTE),
  cbrk_phone_numbers VARCHAR2(200 BYTE),
  cbrk_fax_numbers VARCHAR2(200 BYTE),
  cbrk_website_url VARCHAR2(100 BYTE),
  cbrk_email_id VARCHAR2(100 BYTE),
  cbrk_fmcumc_code VARCHAR2(25 BYTE),
  cbrk_member_type NUMBER(8) NOT NULL,
  cbrk_constitution_code NUMBER(8),
  cbrk_exchange_codes VARCHAR2(200 BYTE) NOT NULL,
  cbrk_local_banks VARCHAR2(200 BYTE),
  cbrk_margin_amount NUMBER(15,2),
  cbrk_country_code NUMBER(8) NOT NULL,
  cbrk_create_date DATE NOT NULL,
  cbrk_add_date DATE NOT NULL,
  cbrk_entry_detail XMLTYPE,
  cbrk_record_status NUMBER(8) NOT NULL,
  cbrk_intraday_broker NUMBER(15,6),
  cbrk_intraday_charges NUMBER(15,6),
  cbrk_voucher_pass NUMBER(8),
  cbrk_account_number VARCHAR2(20 BYTE),
  cbrk_location_code NUMBER(8),
  CONSTRAINT pk_trmaster502 PRIMARY KEY (cbrk_company_code,cbrk_pick_code)
);