CREATE TABLE "TEST_VSTSRedgate".trtran005 (
  fcln_company_code NUMBER(8) NOT NULL,
  fcln_loan_number VARCHAR2(25 BYTE) NOT NULL,
  fcln_loan_type NUMBER(8) NOT NULL,
  fcln_local_bank NUMBER(8) NOT NULL,
  fcln_foreign_bank NUMBER(8),
  fcln_bank_reference VARCHAR2(25 BYTE),
  fcln_sanction_date DATE,
  fcln_noof_days NUMBER(4) NOT NULL,
  fcln_currency_code NUMBER(8) NOT NULL,
  fcln_sanctioned_fcy NUMBER(15,4) NOT NULL,
  fcln_conversion_rate NUMBER(15,6) NOT NULL,
  fcln_sanctioned_inr NUMBER(15,2) NOT NULL,
  fcln_reason_code NUMBER(8) NOT NULL,
  fcln_reason_detail VARCHAR2(50 BYTE),
  fcln_libor_rate NUMBER(15,6),
  fcln_rate_spread NUMBER(15,6),
  fcln_interest_rate NUMBER(15,6),
  fcln_maturity_from DATE,
  fcln_maturity_to DATE,
  fcln_maturity_month NUMBER(2),
  fcln_loan_remarks VARCHAR2(200 BYTE),
  fcln_process_complete NUMBER(8),
  fcln_complete_date DATE,
  fcln_create_date DATE NOT NULL,
  fcln_entry_detail XMLTYPE,
  fcln_record_status NUMBER(8) NOT NULL,
  fcln_interest_type NUMBER(8),
  fcln_base_type NUMBER(8),
  fcln_location_code NUMBER(8),
  fcln_subproduct_code NUMBER(8),
  fcln_product_category NUMBER(8),
  CONSTRAINT pk_trtran005 PRIMARY KEY (fcln_company_code,fcln_loan_number)
);