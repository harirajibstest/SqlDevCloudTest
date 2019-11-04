CREATE TABLE "TEST_VSTSRedgate".dmrs_hierarchy_rollup_links (
  hierarchy_id VARCHAR2(70 BYTE) NOT NULL,
  hierarchy_name VARCHAR2(256 BYTE) NOT NULL,
  hierarchy_ovid VARCHAR2(36 BYTE) NOT NULL,
  rollup_link_id VARCHAR2(70 BYTE) NOT NULL,
  rollup_link_name VARCHAR2(256 BYTE) NOT NULL,
  rollup_link_ovid VARCHAR2(36 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);