CREATE TABLE "TEST_VSTSRedgate".dmrs_model_naming_options (
  object_type VARCHAR2(30 BYTE) NOT NULL,
  max_name_length NUMBER(4) NOT NULL,
  character_case VARCHAR2(10 BYTE) NOT NULL,
  valid_characters VARCHAR2(512 BYTE) NOT NULL,
  model_id VARCHAR2(70 BYTE) NOT NULL,
  model_ovid VARCHAR2(36 BYTE) NOT NULL,
  model_name VARCHAR2(256 BYTE) NOT NULL,
  model_type VARCHAR2(30 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);