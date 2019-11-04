CREATE TABLE "TEST_VSTSRedgate".dmrs_tsdp_sub_policies (
  object_ovid VARCHAR2(36 BYTE) NOT NULL,
  object_id VARCHAR2(70 BYTE) NOT NULL,
  container_id VARCHAR2(70 BYTE) NOT NULL,
  container_ovid VARCHAR2(36 BYTE) NOT NULL,
  container_name VARCHAR2(50 BYTE) NOT NULL,
  tsdp_subpolicy_name VARCHAR2(256 BYTE) NOT NULL,
  expression VARCHAR2(256 BYTE),
  mask_type VARCHAR2(10 BYTE),
  mask_template VARCHAR2(50 BYTE),
  datatype VARCHAR2(50 BYTE),
  "LENGTH" VARCHAR2(10 BYTE),
  parent_schema VARCHAR2(50 BYTE),
  parent_table VARCHAR2(50 BYTE)
);