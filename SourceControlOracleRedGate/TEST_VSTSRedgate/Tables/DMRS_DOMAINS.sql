CREATE TABLE "TEST_VSTSRedgate".dmrs_domains (
  domain_id VARCHAR2(70 BYTE) NOT NULL,
  domain_name VARCHAR2(256 BYTE) NOT NULL,
  ovid VARCHAR2(36 BYTE) NOT NULL,
  synonyms VARCHAR2(4000 BYTE),
  logical_type_id VARCHAR2(70 BYTE) NOT NULL,
  logical_type_ovid VARCHAR2(36 BYTE) NOT NULL,
  t_size NUMBER,
  t_precision NUMBER,
  t_scale NUMBER,
  native_type VARCHAR2(60 BYTE),
  lt_name VARCHAR2(256 BYTE) NOT NULL,
  design_id VARCHAR2(70 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL,
  design_name VARCHAR2(256 BYTE) NOT NULL,
  default_value VARCHAR2(256 BYTE),
  unit_of_measure VARCHAR2(30 BYTE),
  char_units CHAR(4 BYTE),
  sensitive_type_ovid VARCHAR2(36 BYTE),
  sensitive_data_descr VARCHAR2(256 BYTE)
);