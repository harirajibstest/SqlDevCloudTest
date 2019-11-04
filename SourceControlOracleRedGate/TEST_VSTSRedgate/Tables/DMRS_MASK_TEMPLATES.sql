CREATE TABLE "TEST_VSTSRedgate".dmrs_mask_templates (
  object_ovid VARCHAR2(36 BYTE) NOT NULL,
  object_id VARCHAR2(70 BYTE) NOT NULL,
  mask_template_name VARCHAR2(50 BYTE) NOT NULL,
  function_type VARCHAR2(10 BYTE) NOT NULL,
  data_type VARCHAR2(10 BYTE) NOT NULL,
  input_format VARCHAR2(50 BYTE),
  output_format VARCHAR2(50 BYTE),
  mask_char VARCHAR2(50 BYTE),
  mask_from NUMBER,
  mask_to NUMBER,
  "PATTERN" VARCHAR2(50 BYTE),
  replace_string VARCHAR2(50 BYTE),
  position NUMBER,
  occurrence NUMBER,
  match_parameter VARCHAR2(50 BYTE),
  "MONTH" VARCHAR2(10 BYTE),
  "DAY" VARCHAR2(10 BYTE),
  "YEAR" VARCHAR2(10 BYTE),
  "HOUR" VARCHAR2(10 BYTE),
  "MINUTE" VARCHAR2(10 BYTE),
  "SECOND" VARCHAR2(10 BYTE),
  design_ovid VARCHAR2(36 BYTE) NOT NULL
);