CREATE TABLE "TEST_VSTSRedgate".tfsystem009 (
  erat_company_code NUMBER(8),
  erat_currency_code NUMBER(8),
  erat_effective_date DATE,
  erat_export_cross NUMBER(15,4),
  erat_export_spot NUMBER(15,4),
  erat_export_custom NUMBER(15,4),
  erat_export_budget NUMBER(15,4),
  erat_import_cross NUMBER(15,4),
  erat_import_spot NUMBER(15,4),
  erat_import_custom NUMBER(15,4),
  erat_import_budget NUMBER(15,4),
  erat_libor_rate NUMBER(15,4),
  erat_create_date DATE,
  erat_entry_detail XMLTYPE,
  erat_record_status NUMBER(8),
  erat_applicable_date DATE,
  erat_other_currency NUMBER(8)
);