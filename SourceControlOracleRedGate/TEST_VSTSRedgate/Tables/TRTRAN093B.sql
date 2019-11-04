CREATE TABLE "TEST_VSTSRedgate".trtran093b (
  irom_deal_number VARCHAR2(25 BYTE) NOT NULL,
  irom_serial_number NUMBER(5) NOT NULL,
  irom_subserial_number NUMBER(5) NOT NULL,
  irom_intstart_date DATE NOT NULL,
  irom_intend_date DATE,
  irom_base_rate NUMBER(15,6),
  irom_spread NUMBER(15,6),
  irom_final_rate NUMBER(15,6),
  irom_settlement_date DATE,
  irom_interest_amount NUMBER(15,2),
  irom_create_date DATE,
  irom_add_date DATE,
  irom_record_status NUMBER(8),
  irom_process_complete NUMBER(8),
  irom_complete_date DATE,
  CONSTRAINT trtran093b_pk PRIMARY KEY (irom_deal_number,irom_serial_number,irom_subserial_number,irom_intstart_date)
);