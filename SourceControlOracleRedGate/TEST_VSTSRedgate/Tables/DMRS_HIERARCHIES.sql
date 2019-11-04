CREATE TABLE "TEST_VSTSRedgate".dmrs_hierarchies (
  hierarchy_id VARCHAR2(70 BYTE) NOT NULL,
  hierarchy_name VARCHAR2(256 BYTE) NOT NULL,
  hierarchy_ovid VARCHAR2(36 BYTE) NOT NULL,
  model_id VARCHAR2(70 BYTE) NOT NULL,
  model_name VARCHAR2(256 BYTE) NOT NULL,
  model_ovid VARCHAR2(36 BYTE) NOT NULL,
  dimension_id VARCHAR2(70 BYTE),
  dimension_name VARCHAR2(256 BYTE),
  dimension_ovid VARCHAR2(36 BYTE),
  oracle_long_name VARCHAR2(2000 BYTE),
  oracle_plural_name VARCHAR2(2000 BYTE),
  oracle_short_name VARCHAR2(2000 BYTE),
  is_default_hierarchy CHAR,
  is_ragged_hierarchy CHAR,
  is_value_based_hierarchy CHAR,
  description VARCHAR2(4000 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);