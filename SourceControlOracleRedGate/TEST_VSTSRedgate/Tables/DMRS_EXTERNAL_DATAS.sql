CREATE TABLE "TEST_VSTSRedgate".dmrs_external_datas (
  external_data_id VARCHAR2(70 BYTE) NOT NULL,
  external_data_ovid VARCHAR2(36 BYTE) NOT NULL,
  external_data_name VARCHAR2(256 BYTE) NOT NULL,
  model_id VARCHAR2(70 BYTE) NOT NULL,
  model_ovid VARCHAR2(36 BYTE) NOT NULL,
  model_name VARCHAR2(256 BYTE) NOT NULL,
  logical_type_id VARCHAR2(70 BYTE),
  logical_type_ovid VARCHAR2(36 BYTE),
  logical_type_name VARCHAR2(256 BYTE),
  record_structure_type_id VARCHAR2(70 BYTE),
  record_structure_type_ovid VARCHAR2(36 BYTE),
  record_structure_type_name VARCHAR2(256 BYTE),
  starting_pos NUMBER(10),
  description VARCHAR2(4000 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);