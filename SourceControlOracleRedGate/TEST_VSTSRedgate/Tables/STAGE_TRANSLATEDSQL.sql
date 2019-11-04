CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_translatedsql (
  server_id_fk NUMBER,
  db_id_fk NUMBER,
  schema_id_fk NUMBER,
  obj_id_fk NUMBER,
  native_sql CLOB,
  trans_sql CLOB
)
ON COMMIT PRESERVE ROWS;