CREATE TABLE "TEST_VSTSRedgate".dmrs_level_attrs (
  level_id VARCHAR2(70 BYTE) NOT NULL,
  level_name VARCHAR2(256 BYTE) NOT NULL,
  level_ovid VARCHAR2(36 BYTE) NOT NULL,
  attribute_id VARCHAR2(70 BYTE),
  attribute_name VARCHAR2(256 BYTE),
  attribute_ovid VARCHAR2(36 BYTE),
  is_default_attr CHAR,
  is_level_key_attr CHAR,
  is_parent_key_attr CHAR,
  is_descriptive_key_attr CHAR,
  is_calculated_attr CHAR,
  descriptive_name VARCHAR2(256 BYTE),
  descriptive_is_indexed CHAR,
  descriptive_slow_changing VARCHAR2(30 BYTE),
  calculated_expr VARCHAR2(4000 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);