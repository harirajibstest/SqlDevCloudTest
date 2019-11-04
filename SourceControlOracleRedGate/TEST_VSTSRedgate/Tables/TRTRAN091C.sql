CREATE TABLE "TEST_VSTSRedgate".trtran091c (
  iirn_irs_number VARCHAR2(25 BYTE) NOT NULL,
  iirn_serial_number NUMBER(8) NOT NULL,
  iirn_outstanding_amount NUMBER(15,2),
  iirn_effective_date DATE,
  iirn_effective_amount NUMBER(15,2),
  iirn_record_status NUMBER(8),
  iirn_create_date DATE,
  iirn_payment_amount NUMBER(15,2),
  iirn_outstanding_payment NUMBER(15,2),
  iirn_process_complete NUMBER(8),
  iirn_complete_date DATE,
  CONSTRAINT trtran091c_pk PRIMARY KEY (iirn_irs_number,iirn_serial_number)
);