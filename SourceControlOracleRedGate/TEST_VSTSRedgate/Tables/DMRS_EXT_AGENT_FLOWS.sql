CREATE TABLE "TEST_VSTSRedgate".dmrs_ext_agent_flows (
  external_agent_id VARCHAR2(70 BYTE) NOT NULL,
  external_agent_ovid VARCHAR2(36 BYTE) NOT NULL,
  external_agent_name VARCHAR2(256 BYTE) NOT NULL,
  flow_id VARCHAR2(70 BYTE) NOT NULL,
  flow_ovid VARCHAR2(36 BYTE) NOT NULL,
  flow_name VARCHAR2(256 BYTE) NOT NULL,
  incoming_outgoing_flag CHAR,
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);