CREATE TABLE "TEST_VSTSRedgate".dmrs_structured_types (
  design_id VARCHAR2(70 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL,
  design_name VARCHAR2(256 BYTE) NOT NULL,
  model_ovid VARCHAR2(36 BYTE) NOT NULL,
  model_name VARCHAR2(256 BYTE) NOT NULL,
  structured_type_id VARCHAR2(70 BYTE) NOT NULL,
  structured_type_ovid VARCHAR2(36 BYTE) NOT NULL,
  structured_type_name VARCHAR2(256 BYTE) NOT NULL,
  super_type_id VARCHAR2(70 BYTE),
  super_type_ovid VARCHAR2(36 BYTE),
  super_type_name VARCHAR2(256 BYTE),
  predefined CHAR,
  st_final CHAR,
  st_instantiable CHAR
);