CREATE TABLE "TEST_VSTSRedgate".trsystem035 (
  exlm_report_id VARCHAR2(30 BYTE) NOT NULL,
  exlm_report_name VARCHAR2(100 BYTE) NOT NULL,
  exlm_view_name VARCHAR2(50 BYTE) NOT NULL,
  exlm_template_path VARCHAR2(100 BYTE),
  exlm_start_row NUMBER(3) DEFAULT 2,
  exlm_start_col NUMBER(3) DEFAULT 1,
  CONSTRAINT tfsystem35_pk PRIMARY KEY (exlm_report_id)
);