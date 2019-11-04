CREATE TABLE "TEST_VSTSRedgate".dmrs_mapping_targets (
  object_id VARCHAR2(70 BYTE) NOT NULL,
  object_ovid VARCHAR2(36 BYTE) NOT NULL,
  object_name VARCHAR2(256 BYTE) NOT NULL,
  target_id VARCHAR2(70 BYTE) NOT NULL,
  target_ovid VARCHAR2(36 BYTE) NOT NULL,
  target_name VARCHAR2(256 BYTE) NOT NULL,
  object_type VARCHAR2(30 BYTE),
  target_type VARCHAR2(30 BYTE),
  transformation_type VARCHAR2(30 BYTE),
  description VARCHAR2(4000 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);