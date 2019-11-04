CREATE TABLE "TEST_VSTSRedgate".dmrs_change_requests (
  design_id VARCHAR2(70 BYTE) NOT NULL,
  design_ovid VARCHAR2(36 BYTE) NOT NULL,
  design_name VARCHAR2(256 BYTE) NOT NULL,
  change_request_id VARCHAR2(70 BYTE) NOT NULL,
  change_request_ovid VARCHAR2(36 BYTE) NOT NULL,
  change_request_name VARCHAR2(256 BYTE) NOT NULL,
  request_status VARCHAR2(30 BYTE),
  request_date_string VARCHAR2(30 BYTE),
  completion_date_string VARCHAR2(30 BYTE),
  is_completed CHAR,
  reason VARCHAR2(4000 BYTE)
);