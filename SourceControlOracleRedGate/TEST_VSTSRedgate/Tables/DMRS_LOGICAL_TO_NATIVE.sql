CREATE TABLE "TEST_VSTSRedgate".dmrs_logical_to_native (
  design_id VARCHAR2(70 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL,
  design_name VARCHAR2(256 BYTE) NOT NULL,
  logical_type_id VARCHAR2(70 BYTE) NOT NULL,
  logical_type_ovid VARCHAR2(36 BYTE) NOT NULL,
  lt_name VARCHAR2(256 BYTE) NOT NULL,
  native_type VARCHAR2(60 BYTE),
  rdbms_type VARCHAR2(60 BYTE) NOT NULL,
  rdbms_version VARCHAR2(60 BYTE) NOT NULL,
  has_size VARCHAR2(1 BYTE),
  has_precision VARCHAR2(1 BYTE),
  has_scale VARCHAR2(1 BYTE)
);