CREATE TABLE "TEST_VSTSRedgate".dmrs_mapping_target_sources (
  object_id VARCHAR2(70 BYTE) NOT NULL,
  object_ovid VARCHAR2(36 BYTE) NOT NULL,
  object_name VARCHAR2(256 BYTE) NOT NULL,
  target_id VARCHAR2(70 BYTE) NOT NULL,
  target_ovid VARCHAR2(36 BYTE) NOT NULL,
  target_name VARCHAR2(256 BYTE) NOT NULL,
  source_id VARCHAR2(70 BYTE) NOT NULL,
  source_ovid VARCHAR2(36 BYTE) NOT NULL,
  source_name VARCHAR2(256 BYTE) NOT NULL,
  object_type VARCHAR2(30 BYTE),
  target_type VARCHAR2(30 BYTE),
  source_type VARCHAR2(30 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);