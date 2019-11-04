CREATE TABLE "TEST_VSTSRedgate".trsystem031 (
  dayo_process_date DATE NOT NULL,
  dayo_batch_number NUMBER(12) NOT NULL,
  dayo_serial_number NUMBER(5) NOT NULL,
  dayo_operation_type NUMBER(8) NOT NULL,
  dayo_job_code NUMBER(8) NOT NULL,
  dayo_job_status NUMBER(8) NOT NULL,
  dayo_job_message VARCHAR2(2048 BYTE),
  CONSTRAINT pk_trsystem031 PRIMARY KEY (dayo_process_date,dayo_batch_number,dayo_serial_number)
);