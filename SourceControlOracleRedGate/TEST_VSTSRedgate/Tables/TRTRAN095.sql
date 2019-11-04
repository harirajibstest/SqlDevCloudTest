CREATE TABLE "TEST_VSTSRedgate".trtran095 (
  cirs_company_code NUMBER(8) NOT NULL,
  cirs_location_code NUMBER(8) NOT NULL,
  cirs_deal_number VARCHAR2(25 BYTE) NOT NULL,
  cirs_serial_number NUMBER(5) NOT NULL,
  cirs_deal_type NUMBER(8) NOT NULL,
  cirs_execute_date DATE,
  cirs_counter_party NUMBER(8),
  cirs_local_bank NUMBER(8),
  cirs_bank_reference VARCHAR2(25 BYTE),
  cirs_ad_bank NUMBER(8),
  cirs_lrn_bank NUMBER(8),
  cirs_currency_code NUMBER(8),
  cirs_loan_amount NUMBER(15,2),
  cirs_exchange_rate NUMBER(15,4),
  cirs_loan_inr NUMBER(15,2),
  cirs_loan_period NUMBER(8),
  cirs_loan_tenor NUMBER(5),
  cirs_due_date DATE,
  cirs_libor_rate NUMBER(15,6),
  cirs_spread_rate NUMBER(15,6),
  cirs_interest_rate NUMBER(15,6),
  cirs_interest_period NUMBER(8),
  cirs_interst_tenor NUMBER(5),
  cirs_interest_annum NUMBER(15,2),
  cirs_pos_spot NUMBER(15,4),
  cirs_pos_premium NUMBER(15,4),
  cirs_pos_charges NUMBER(15,4),
  cirs_withhold_tax NUMBER(15,2),
  cirs_swap_reference VARCHAR2(25 BYTE),
  cirs_user_remarks VARCHAR2(500 BYTE),
  cirs_time_stamp VARCHAR2(25 BYTE),
  cirs_process_complete NUMBER(8),
  cirs_complete_date DATE,
  cirs_create_date DATE,
  cirs_entry_detail XMLTYPE,
  cirs_record_status NUMBER(8) NOT NULL,
  CONSTRAINT tftran095_pk PRIMARY KEY (cirs_company_code,cirs_location_code,cirs_deal_number,cirs_serial_number)
);