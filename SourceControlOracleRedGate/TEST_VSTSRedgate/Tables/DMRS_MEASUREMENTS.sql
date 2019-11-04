CREATE TABLE "TEST_VSTSRedgate".dmrs_measurements (
  design_id VARCHAR2(70 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL,
  design_name VARCHAR2(256 BYTE) NOT NULL,
  model_ovid VARCHAR2(36 BYTE) NOT NULL,
  model_name VARCHAR2(256 BYTE) NOT NULL,
  measurement_id VARCHAR2(70 BYTE) NOT NULL,
  measurement_ovid VARCHAR2(36 BYTE) NOT NULL,
  measurement_name VARCHAR2(256 BYTE) NOT NULL,
  measurement_value VARCHAR2(50 BYTE),
  measurement_unit VARCHAR2(36 BYTE),
  measurement_type VARCHAR2(36 BYTE),
  measurement_cr_date VARCHAR2(30 BYTE),
  measurement_ef_date VARCHAR2(30 BYTE),
  object_name VARCHAR2(256 BYTE),
  object_type VARCHAR2(256 BYTE),
  object_model VARCHAR2(256 BYTE)
);