CREATE TABLE "TEST_VSTSRedgate".trtran091 (
  iirs_company_code NUMBER(8),
  iirs_location_code NUMBER(8),
  iirs_portfolio NUMBER(8),
  iirs_sub_portfolio NUMBER(8),
  iirs_irs_number VARCHAR2(25 BYTE) NOT NULL,
  iirs_execute_date DATE,
  iirs_counter_party NUMBER(8),
  iirs_notional_amount NUMBER(15,2),
  iirs_process_complete NUMBER(8),
  iirs_complete_date DATE,
  iirs_create_date DATE,
  iirs_add_date DATE,
  iirs_entry_details XMLTYPE,
  iirs_time_stamp VARCHAR2(25 BYTE),
  iirs_record_status NUMBER(8),
  iirs_user_reference VARCHAR2(50 BYTE),
  iirs_user_remarks VARCHAR2(50 BYTE),
  iirs_expiry_date DATE,
  iirs_start_date DATE,
  iirs_tenor_number NUMBER(5),
  iirs_tenor_type NUMBER(8),
  iirs_execute_time VARCHAR2(10 BYTE),
  iirs_confirm_time VARCHAR2(10 BYTE),
  iirs_confirm_date DATE,
  iirs_bank_reference VARCHAR2(50 BYTE),
  iirs_bo_remark VARCHAR2(1024 BYTE),
  iirs_hedge_trade NUMBER(8),
  iirs_deal_type NUMBER(8),
  iirs_payment_calendar VARCHAR2(500 BYTE),
  iirs_fixing_calendar VARCHAR2(500 BYTE),
  iirs_underlying_exposure VARCHAR2(45 BYTE),
  iirs_spot_reference NUMBER(15,6),
  iirs_businessday_convension NUMBER(8),
  CONSTRAINT trtran091_pk PRIMARY KEY (iirs_irs_number)
);