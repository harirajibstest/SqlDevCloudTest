CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_serverdetail (
  svrid NUMBER,
  dburl VARCHAR2(4000 BYTE),
  db_name VARCHAR2(4000 BYTE),
  username VARCHAR2(255 BYTE),
  project_id NUMBER,
  project_name VARCHAR2(255 BYTE),
  comments VARCHAR2(4000 BYTE)
)
ON COMMIT PRESERVE ROWS;