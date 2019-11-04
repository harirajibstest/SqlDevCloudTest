CREATE TABLE "TEST_VSTSRedgate".dmrs_struct_type_methods (
  method_id VARCHAR2(70 BYTE) NOT NULL,
  method_ovid VARCHAR2(36 BYTE) NOT NULL,
  method_name VARCHAR2(256 BYTE) NOT NULL,
  structured_type_id VARCHAR2(70 BYTE) NOT NULL,
  structured_type_ovid VARCHAR2(36 BYTE) NOT NULL,
  structured_type_name VARCHAR2(256 BYTE) NOT NULL,
  constructor CHAR,
  overridden_method_id VARCHAR2(70 BYTE),
  overridden_method_ovid VARCHAR2(36 BYTE),
  overridden_method_name VARCHAR2(256 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL,
  overriding CHAR
);