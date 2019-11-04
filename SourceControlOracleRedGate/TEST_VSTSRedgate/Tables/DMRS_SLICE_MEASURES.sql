CREATE TABLE "TEST_VSTSRedgate".dmrs_slice_measures (
  slice_id VARCHAR2(70 BYTE) NOT NULL,
  slice_name VARCHAR2(256 BYTE) NOT NULL,
  slice_ovid VARCHAR2(36 BYTE) NOT NULL,
  measure_id VARCHAR2(70 BYTE) NOT NULL,
  measure_name VARCHAR2(256 BYTE) NOT NULL,
  measure_ovid VARCHAR2(36 BYTE) NOT NULL,
  aggregate_function_id VARCHAR2(70 BYTE) NOT NULL,
  aggregate_function_name VARCHAR2(256 BYTE) NOT NULL,
  aggregate_function_ovid VARCHAR2(36 BYTE) NOT NULL,
  measure_alias VARCHAR2(256 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);