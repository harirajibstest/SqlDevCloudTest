CREATE TABLE "TEST_VSTSRedgate".dmrs_struct_type_method_pars (
  parameter_id VARCHAR2(70 BYTE) NOT NULL,
  parameter_ovid VARCHAR2(36 BYTE) NOT NULL,
  parameter_name VARCHAR2(256 BYTE) NOT NULL,
  method_id VARCHAR2(70 BYTE) NOT NULL,
  method_ovid VARCHAR2(36 BYTE) NOT NULL,
  method_name VARCHAR2(256 BYTE) NOT NULL,
  return_value CHAR NOT NULL,
  "REFERENCE" CHAR NOT NULL,
  seq NUMBER,
  t_size VARCHAR2(20 BYTE),
  t_precision NUMBER,
  t_scale NUMBER,
  type_id VARCHAR2(70 BYTE),
  type_ovid VARCHAR2(36 BYTE),
  type_name VARCHAR2(256 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);