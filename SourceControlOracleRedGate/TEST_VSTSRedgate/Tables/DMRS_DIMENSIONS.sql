CREATE TABLE "TEST_VSTSRedgate".dmrs_dimensions (
  dimension_id VARCHAR2(70 BYTE) NOT NULL,
  dimension_name VARCHAR2(256 BYTE) NOT NULL,
  dimension_ovid VARCHAR2(36 BYTE) NOT NULL,
  model_id VARCHAR2(70 BYTE) NOT NULL,
  model_name VARCHAR2(256 BYTE) NOT NULL,
  model_ovid VARCHAR2(36 BYTE) NOT NULL,
  base_entity_id VARCHAR2(70 BYTE),
  base_entity_name VARCHAR2(256 BYTE),
  base_entity_ovid VARCHAR2(36 BYTE),
  base_level_id VARCHAR2(70 BYTE),
  base_level_name VARCHAR2(256 BYTE),
  base_level_ovid VARCHAR2(36 BYTE),
  oracle_long_name VARCHAR2(2000 BYTE),
  oracle_plural_name VARCHAR2(2000 BYTE),
  oracle_short_name VARCHAR2(2000 BYTE),
  description VARCHAR2(4000 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);