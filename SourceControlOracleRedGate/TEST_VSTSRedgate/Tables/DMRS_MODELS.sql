CREATE TABLE "TEST_VSTSRedgate".dmrs_models (
  design_id VARCHAR2(70 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL,
  design_name VARCHAR2(256 BYTE) NOT NULL,
  model_id VARCHAR2(70 BYTE) NOT NULL,
  model_ovid VARCHAR2(36 BYTE) NOT NULL,
  model_name VARCHAR2(256 BYTE) NOT NULL,
  model_type VARCHAR2(30 BYTE) NOT NULL,
  rdbms_type VARCHAR2(60 BYTE)
);