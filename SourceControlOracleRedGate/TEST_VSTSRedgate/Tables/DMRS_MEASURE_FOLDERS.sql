CREATE TABLE "TEST_VSTSRedgate".dmrs_measure_folders (
  measure_folder_id VARCHAR2(70 BYTE) NOT NULL,
  measure_folder_name VARCHAR2(256 BYTE) NOT NULL,
  measure_folder_ovid VARCHAR2(36 BYTE) NOT NULL,
  model_id VARCHAR2(70 BYTE) NOT NULL,
  model_name VARCHAR2(256 BYTE) NOT NULL,
  model_ovid VARCHAR2(36 BYTE) NOT NULL,
  parent_folder_id VARCHAR2(70 BYTE),
  parent_folder_name VARCHAR2(256 BYTE),
  parent_folder_ovid VARCHAR2(36 BYTE),
  oracle_long_name VARCHAR2(2000 BYTE),
  oracle_plural_name VARCHAR2(2000 BYTE),
  oracle_short_name VARCHAR2(2000 BYTE),
  is_leaf CHAR,
  description VARCHAR2(4000 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);