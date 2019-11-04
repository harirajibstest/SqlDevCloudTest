CREATE TABLE "TEST_VSTSRedgate".trsystem008 (
  erel_company_code NUMBER(8) NOT NULL,
  erel_main_entity NUMBER(8) NOT NULL,
  erel_entity_relation NUMBER(8) NOT NULL,
  erel_entity_type NUMBER(3) NOT NULL,
  erel_relation_type NUMBER(3) NOT NULL,
  erel_create_date DATE NOT NULL,
  erel_add_date DATE NOT NULL,
  erel_entry_detail XMLTYPE,
  erel_record_status NUMBER(8) NOT NULL,
  CONSTRAINT pk_trsystem008 PRIMARY KEY (erel_company_code,erel_main_entity,erel_entity_relation)
);