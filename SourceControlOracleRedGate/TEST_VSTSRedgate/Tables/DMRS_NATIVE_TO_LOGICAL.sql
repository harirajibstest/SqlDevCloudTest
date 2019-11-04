CREATE TABLE "TEST_VSTSRedgate".dmrs_native_to_logical (
  rdbms_type VARCHAR2(60 BYTE) NOT NULL,
  rdbms_version VARCHAR2(60 BYTE) NOT NULL,
  native_type VARCHAR2(60 BYTE),
  lt_name VARCHAR2(256 BYTE) NOT NULL,
  logical_type_id VARCHAR2(70 BYTE) NOT NULL,
  logical_type_ovid VARCHAR2(36 BYTE) NOT NULL,
  design_id VARCHAR2(70 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL,
  design_name VARCHAR2(256 BYTE) NOT NULL
);