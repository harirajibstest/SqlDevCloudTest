CREATE GLOBAL TEMPORARY TABLE "TEST_VSTSRedgate".stage_teradata_triggers (
  mdid NUMBER,
  databasename VARCHAR2(128 CHAR),
  subjecttabledatabasename VARCHAR2(128 CHAR),
  tablename VARCHAR2(128 CHAR),
  triggername VARCHAR2(128 CHAR),
  enabledflag CHAR(1 CHAR),
  actiontime CHAR(1 CHAR),
  event CHAR(1 CHAR),
  kind CHAR(1 CHAR),
  ordernumber NUMBER(10),
  triggercomment VARCHAR2(255 CHAR),
  requesttext CLOB,
  creatorname VARCHAR2(128 CHAR)
)
ON COMMIT PRESERVE ROWS;