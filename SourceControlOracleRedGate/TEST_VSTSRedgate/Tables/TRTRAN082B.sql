CREATE TABLE "TEST_VSTSRedgate".trtran082b (
  tlbr_company_code NUMBER(8) NOT NULL,
  tlbr_location_code NUMBER(8) NOT NULL,
  tlbr_loan_type NUMBER(8) NOT NULL,
  tlbr_local_bank NUMBER(8) NOT NULL,
  tlbr_loan_number VARCHAR2(25 BYTE) NOT NULL,
  tlbr_loan_serial NUMBER(5) NOT NULL,
  tlbr_effective_date DATE NOT NULL,
  tlbr_libor_rate NUMBER(15,6),
  tlbr_interest_spread NUMBER(15,6),
  tlbr_interest_rate NUMBER(15,6),
  tlbr_user_remarks VARCHAR2(512 BYTE),
  tlbr_create_date DATE NOT NULL,
  tlbr_entry_detail XMLTYPE,
  tlbr_record_status NUMBER(8),
  CONSTRAINT pk_tftran082b PRIMARY KEY (tlbr_company_code,tlbr_location_code,tlbr_loan_number,tlbr_effective_date)
);