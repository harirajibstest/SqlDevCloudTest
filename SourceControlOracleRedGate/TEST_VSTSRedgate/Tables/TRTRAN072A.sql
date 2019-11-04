CREATE TABLE "TEST_VSTSRedgate".trtran072a (
  cosm_deal_number VARCHAR2(25 BYTE) NOT NULL,
  cosm_serial_number NUMBER(5) NOT NULL,
  cosm_subserial_number NUMBER(5) NOT NULL,
  cosm_maturity_date DATE,
  cosm_settlement_date DATE,
  cosm_user_remarks VARCHAR2(200 BYTE),
  cosm_process_complete NUMBER(8),
  cosm_complete_date DATE,
  cosm_add_date DATE,
  cosm_create_date DATE,
  cosm_record_status NUMBER(8),
  cosm_amount_fcy NUMBER(15,2),
  CONSTRAINT trtran072a_pk PRIMARY KEY (cosm_deal_number,cosm_serial_number,cosm_subserial_number)
);