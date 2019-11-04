CREATE TABLE "TEST_VSTSRedgate".dmrs_table_arcs (
  object_ovid VARCHAR2(36 BYTE) NOT NULL,
  object_id VARCHAR2(70 BYTE) NOT NULL,
  arc_name VARCHAR2(256 BYTE) NOT NULL,
  table_ovid VARCHAR2(36 BYTE) NOT NULL,
  table_id VARCHAR2(36 BYTE) NOT NULL,
  mandatory CHAR NOT NULL,
  discriminator_column_id VARCHAR2(36 BYTE),
  model_name VARCHAR2(256 BYTE),
  model_ovid VARCHAR2(36 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);