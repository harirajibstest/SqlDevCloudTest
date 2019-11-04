CREATE TABLE "TEST_VSTSRedgate".trtran049 (
  mfcl_company_code NUMBER(8) NOT NULL,
  mfcl_location_code NUMBER(8) NOT NULL,
  mfcl_reference_number VARCHAR2(25 BYTE) NOT NULL,
  mfcl_scheme_code NUMBER(8),
  mfcl_nav_code VARCHAR2(10 BYTE),
  mfcl_transaction_date DATE,
  mfcl_reference_date DATE,
  mfcl_transaction_type NUMBER(8),
  mfcl_transaction_amount NUMBER(15,2),
  mfcl_transaction_price NUMBER(15,4),
  mfcl_transaction_quantity NUMBER(15,4),
  mfcl_maturity_amount NUMBER(15,2),
  mfcl_exitload_charges NUMBER(15,2),
  mfcl_other_charges NUMBER(15,2),
  mfcl_total_charges NUMBER(15,2),
  mfcl_actual_pandl NUMBER(15,2),
  mfcl_profit_loss NUMBER(15,2),
  mfcl_switchin_number VARCHAR2(25 BYTE),
  mfcl_switchin_scheme NUMBER(8),
  mfcl_switchin_navdate DATE,
  mfcl_switchin_nav NUMBER(15,4),
  mfcl_switchin_qty NUMBER(15,4),
  mfcl_user_reference VARCHAR2(100 BYTE),
  mfcl_bank_code NUMBER(8),
  mfcl_current_ac VARCHAR2(25 BYTE),
  mfcl_user_remarks VARCHAR2(200 BYTE),
  mfcl_add_date DATE,
  mfcl_create_date DATE,
  mfcl_entry_details XMLTYPE,
  mfcl_record_status NUMBER(8),
  CONSTRAINT trtran049_pk PRIMARY KEY (mfcl_reference_number)
);