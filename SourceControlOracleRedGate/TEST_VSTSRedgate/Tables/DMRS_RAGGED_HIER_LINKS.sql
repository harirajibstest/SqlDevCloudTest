CREATE TABLE "TEST_VSTSRedgate".dmrs_ragged_hier_links (
  ragged_hier_link_id VARCHAR2(70 BYTE) NOT NULL,
  ragged_hier_link_name VARCHAR2(256 BYTE) NOT NULL,
  ragged_hier_link_ovid VARCHAR2(36 BYTE) NOT NULL,
  model_id VARCHAR2(70 BYTE) NOT NULL,
  model_name VARCHAR2(256 BYTE) NOT NULL,
  model_ovid VARCHAR2(36 BYTE) NOT NULL,
  parent_level_id VARCHAR2(70 BYTE),
  parent_level_name VARCHAR2(256 BYTE),
  parent_level_ovid VARCHAR2(36 BYTE),
  child_level_id VARCHAR2(70 BYTE),
  child_level_name VARCHAR2(256 BYTE),
  child_level_ovid VARCHAR2(36 BYTE),
  description VARCHAR2(4000 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);