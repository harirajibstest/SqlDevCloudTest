CREATE TABLE "TEST_VSTSRedgate".trtran049a (
  redm_redemption_reference VARCHAR2(25 BYTE) NOT NULL,
  redm_serial_number NUMBER(5) NOT NULL,
  redm_invest_reference VARCHAR2(25 BYTE) NOT NULL,
  redm_transaction_date DATE NOT NULL,
  redm_noof_units NUMBER(15,4) NOT NULL,
  redm_invest_amount NUMBER(15,2) NOT NULL,
  redm_redeem_nav NUMBER(15,4) NOT NULL,
  redm_redeem_pandl NUMBER(15,2),
  redm_process_complete NUMBER(8) NOT NULL,
  redm_complete_date DATE,
  redm_record_status NUMBER(8) NOT NULL,
  CONSTRAINT pk_trtran049a PRIMARY KEY (redm_redemption_reference,redm_serial_number)
);