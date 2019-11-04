CREATE TABLE "TEST_VSTSRedgate".dmrs_existence_dep_columns (
  dependency_ovid VARCHAR2(36 BYTE) NOT NULL,
  discriminator_value VARCHAR2(50 BYTE),
  table_name VARCHAR2(256 BYTE) NOT NULL,
  table_ovid VARCHAR2(36 BYTE) NOT NULL,
  column_name VARCHAR2(256 BYTE) NOT NULL,
  column_ovid VARCHAR2(36 BYTE) NOT NULL,
  depend_as_mandatory VARCHAR2(1 BYTE),
  depend VARCHAR2(1 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);