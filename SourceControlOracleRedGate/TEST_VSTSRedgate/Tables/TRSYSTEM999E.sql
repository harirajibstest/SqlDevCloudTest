CREATE TABLE "TEST_VSTSRedgate".trsystem999e (
  tabs_program_unit VARCHAR2(50 BYTE) NOT NULL,
  tabs_tab_code VARCHAR2(50 BYTE) NOT NULL,
  tabs_display_name VARCHAR2(20 BYTE),
  tabs_order_sequence NUMBER(5),
  tabs_validation_on_add NUMBER(8),
  tabs_validation_on_edit NUMBER(8),
  tabs_validation_on_confirm NUMBER(8),
  tabs_record_status NUMBER(8),
  CONSTRAINT trsystem999e_pk PRIMARY KEY (tabs_program_unit,tabs_tab_code)
);