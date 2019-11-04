CREATE TABLE "TEST_VSTSRedgate".dmrs_slice_dim_hier_level (
  slice_id VARCHAR2(70 BYTE) NOT NULL,
  slice_name VARCHAR2(256 BYTE) NOT NULL,
  slice_ovid VARCHAR2(36 BYTE) NOT NULL,
  dimension_id VARCHAR2(70 BYTE),
  dimension_name VARCHAR2(256 BYTE),
  dimension_ovid VARCHAR2(36 BYTE),
  hierarchy_id VARCHAR2(70 BYTE),
  hierarchy_name VARCHAR2(256 BYTE),
  hierarchy_ovid VARCHAR2(36 BYTE),
  level_id VARCHAR2(70 BYTE),
  level_name VARCHAR2(256 BYTE),
  level_ovid VARCHAR2(36 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);