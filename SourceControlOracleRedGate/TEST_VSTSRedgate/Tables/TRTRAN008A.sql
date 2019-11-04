CREATE TABLE "TEST_VSTSRedgate".trtran008a (
  remt_company_code NUMBER(8) NOT NULL,
  remt_location_code NUMBER(8) NOT NULL,
  remt_remittance_reference VARCHAR2(40 BYTE) NOT NULL,
  remt_bank_reference VARCHAR2(25 BYTE) NOT NULL,
  remt_reference_date DATE NOT NULL,
  remt_remittance_type NUMBER(8) NOT NULL,
  remt_remittance_means NUMBER(8),
  remt_remittance_purpose NUMBER(8) NOT NULL,
  remt_remittance_details VARCHAR2(1000 BYTE),
  remt_local_bank NUMBER(8) NOT NULL,
  remt_account_number VARCHAR2(25 BYTE),
  remt_currency_code NUMBER(8) NOT NULL,
  remt_remittance_fcy NUMBER(15,4) NOT NULL,
  remt_exchange_rate NUMBER(15,4) NOT NULL,
  remt_remittance_inr NUMBER(15,2) NOT NULL,
  remt_remittance_connect NUMBER(8) NOT NULL,
  remt_reference_number VARCHAR2(25 BYTE),
  remt_reference_serial NUMBER(5),
  remt_beneficiary_code NUMBER(8) NOT NULL,
  remt_beneficiary_name VARCHAR2(50 BYTE),
  remt_beneficiary_address1 VARCHAR2(50 BYTE),
  remt_beneficiary_address2 VARCHAR2(50 BYTE),
  remt_beneficiary_address3 VARCHAR2(50 BYTE),
  remt_beneficiary_address4 VARCHAR2(50 BYTE),
  remt_beneficiary_phone VARCHAR2(50 BYTE),
  remt_beneficiary_fax VARCHAR2(50 BYTE),
  remt_bank_code NUMBER(8) NOT NULL,
  remt_bank_name VARCHAR2(50 BYTE),
  remt_bank_address1 VARCHAR2(50 BYTE),
  remt_bank_address2 VARCHAR2(50 BYTE),
  remt_bank_address3 VARCHAR2(50 BYTE),
  remt_bank_address4 VARCHAR2(50 BYTE),
  remt_bank_phone VARCHAR2(50 BYTE),
  remt_bank_fax VARCHAR2(50 BYTE),
  remt_bank_account VARCHAR2(50 BYTE),
  remt_swift_code VARCHAR2(50 BYTE),
  remt_iban_code VARCHAR2(50 BYTE),
  remt_transaction_batch VARCHAR2(25 BYTE) NOT NULL,
  remt_total_charges NUMBER(15,2),
  remt_create_date DATE NOT NULL,
  remt_entry_detail XMLTYPE,
  remt_record_status NUMBER(8) NOT NULL,
  remt_goods_description VARCHAR2(512 BYTE),
  remt_product_category NUMBER(8),
  remt_product_subcategory NUMBER(8),
  remt_spot_rate NUMBER(15,4),
  remt_forward_rate NUMBER(15,4),
  remt_margin_rate NUMBER(15,4),
  remt_maturity_date DATE,
  CONSTRAINT pk_trtran008a PRIMARY KEY (remt_company_code,remt_location_code,remt_remittance_reference)
);