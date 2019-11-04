CREATE TABLE "TEST_VSTSRedgate".dmrs_dimension_calc_attrs (
  dimension_id VARCHAR2(70 BYTE) NOT NULL,
  dimension_name VARCHAR2(256 BYTE) NOT NULL,
  dimension_ovid VARCHAR2(36 BYTE) NOT NULL,
  calc_attribute_id VARCHAR2(70 BYTE) NOT NULL,
  calc_attribute_name VARCHAR2(256 BYTE) NOT NULL,
  calc_attribute_ovid VARCHAR2(36 BYTE) NOT NULL,
  calculated_expr VARCHAR2(4000 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);