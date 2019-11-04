CREATE TABLE "TEST_VSTSRedgate".dmrs_distinct_types (
  design_id VARCHAR2(70 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL,
  design_name VARCHAR2(256 BYTE) NOT NULL,
  model_ovid VARCHAR2(36 BYTE) NOT NULL,
  model_name VARCHAR2(256 BYTE) NOT NULL,
  distinct_type_id VARCHAR2(70 BYTE) NOT NULL,
  distinct_type_ovid VARCHAR2(36 BYTE) NOT NULL,
  distinct_type_name VARCHAR2(256 BYTE) NOT NULL,
  logical_type_id VARCHAR2(70 BYTE),
  logical_type_ovid VARCHAR2(36 BYTE),
  logical_type_name VARCHAR2(256 BYTE),
  t_size VARCHAR2(20 BYTE),
  t_precision NUMBER,
  t_scale NUMBER
);