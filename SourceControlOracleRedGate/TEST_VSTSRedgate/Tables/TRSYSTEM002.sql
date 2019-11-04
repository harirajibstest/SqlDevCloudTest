CREATE TABLE "TEST_VSTSRedgate".trsystem002 (
  menu_company_code NUMBER(8) NOT NULL,
  menu_menu_id NUMBER(4) NOT NULL,
  menu_serial_number NUMBER(5) NOT NULL,
  menu_description VARCHAR2(50 BYTE) NOT NULL,
  menu_program_unit VARCHAR2(30 BYTE),
  menu_child_level NUMBER(4) NOT NULL,
  menu_parent_id NUMBER(4) NOT NULL,
  menu_runs_program NUMBER(8) NOT NULL,
  menu_short_cut VARCHAR2(15 BYTE),
  menu_short_number NUMBER(4),
  menu_create_date DATE NOT NULL,
  menu_add_date DATE NOT NULL,
  menu_entry_detail XMLTYPE,
  menu_record_status NUMBER(8) NOT NULL,
  menu_module_id NUMBER(8),
  menu_short_key NUMBER(8),
  menu_menu_icon VARCHAR2(250 BYTE)
);