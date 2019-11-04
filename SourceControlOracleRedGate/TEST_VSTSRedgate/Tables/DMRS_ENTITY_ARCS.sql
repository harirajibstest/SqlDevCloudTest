CREATE TABLE "TEST_VSTSRedgate".dmrs_entity_arcs (
  object_ovid VARCHAR2(36 BYTE) NOT NULL,
  object_id VARCHAR2(70 BYTE) NOT NULL,
  arc_name VARCHAR2(256 BYTE) NOT NULL,
  entity_id VARCHAR2(36 BYTE) NOT NULL,
  model_name VARCHAR2(256 BYTE),
  model_ovid VARCHAR2(36 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);