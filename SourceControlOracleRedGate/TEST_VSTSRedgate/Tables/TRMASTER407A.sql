CREATE TABLE "TEST_VSTSRedgate".trmaster407a (
  detr_tds_plan NUMBER(8) NOT NULL,
  detr_serial_number NUMBER(5) NOT NULL,
  detr_int_amountfrom NUMBER(15,2),
  detr_int_amountupto NUMBER(15,2),
  detr_tds_rate NUMBER(15,6),
  detr_tds_surchargerate NUMBER(15,6),
  detr_record_status NUMBER(8),
  detr_create_date DATE,
  detr_add_date DATE,
  detr_effective_date DATE,
  CONSTRAINT trmaster407a_pk PRIMARY KEY (detr_tds_plan,detr_serial_number)
);