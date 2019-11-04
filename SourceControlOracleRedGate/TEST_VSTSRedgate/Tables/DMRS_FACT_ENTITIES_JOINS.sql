CREATE TABLE "TEST_VSTSRedgate".dmrs_fact_entities_joins (
  join_id VARCHAR2(70 BYTE) NOT NULL,
  join_name VARCHAR2(256 BYTE) NOT NULL,
  join_ovid VARCHAR2(36 BYTE) NOT NULL,
  cube_id VARCHAR2(70 BYTE) NOT NULL,
  cube_name VARCHAR2(256 BYTE) NOT NULL,
  cube_ovid VARCHAR2(36 BYTE) NOT NULL,
  left_entity_id VARCHAR2(70 BYTE),
  left_entity_name VARCHAR2(256 BYTE),
  left_entity_ovid VARCHAR2(36 BYTE),
  right_entity_id VARCHAR2(70 BYTE),
  right_entity_name VARCHAR2(256 BYTE),
  right_entity_ovid VARCHAR2(36 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);