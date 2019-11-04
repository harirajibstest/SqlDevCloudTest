CREATE TABLE "TEST_VSTSRedgate".dmrs_measure_folder_measures (
  measure_folder_id VARCHAR2(70 BYTE) NOT NULL,
  measure_folder_name VARCHAR2(256 BYTE) NOT NULL,
  measure_folder_ovid VARCHAR2(36 BYTE) NOT NULL,
  measure_id VARCHAR2(70 BYTE) NOT NULL,
  measure_name VARCHAR2(256 BYTE) NOT NULL,
  measure_ovid VARCHAR2(36 BYTE) NOT NULL,
  parent_object_id VARCHAR2(70 BYTE),
  parent_object_name VARCHAR2(256 BYTE),
  parent_object_ovid VARCHAR2(36 BYTE),
  parent_object_type VARCHAR2(30 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);