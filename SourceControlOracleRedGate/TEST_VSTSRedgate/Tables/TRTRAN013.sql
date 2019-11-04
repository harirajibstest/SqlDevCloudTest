CREATE TABLE "TEST_VSTSRedgate".trtran013 (
  drat_effective_date DATE NOT NULL,
  drat_serial_number NUMBER(5) NOT NULL,
  drat_rate_time VARCHAR2(10 BYTE),
  drat_rate_description VARCHAR2(50 BYTE),
  drat_ratesr_number NUMBER(15),
  drat_time_stamp VARCHAR2(25 BYTE),
  drat_create_date DATE NOT NULL,
  drat_add_date DATE NOT NULL,
  drat_entry_detail XMLTYPE,
  drat_record_status NUMBER(8) NOT NULL,
  CONSTRAINT trtran013_pk PRIMARY KEY (drat_effective_date,drat_serial_number)
);