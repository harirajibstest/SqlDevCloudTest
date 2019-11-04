CREATE TABLE "TEST_VSTSRedgate".dmrs_existence_dep (
  object_ovid VARCHAR2(36 BYTE) NOT NULL,
  dependency_name VARCHAR2(256 BYTE) NOT NULL,
  table_ovid VARCHAR2(36 BYTE) NOT NULL,
  generation_level VARCHAR2(20 BYTE) NOT NULL,
  discriminator_column_ovid VARCHAR2(36 BYTE),
  discriminator_column_name VARCHAR2(256 BYTE),
  model_name VARCHAR2(256 BYTE),
  model_ovid VARCHAR2(36 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);