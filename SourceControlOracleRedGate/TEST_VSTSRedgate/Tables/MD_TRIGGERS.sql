CREATE TABLE "TEST_VSTSRedgate".md_triggers (
  "ID" NUMBER NOT NULL,
  table_or_view_id_fk NUMBER NOT NULL,
  trigger_on_flag CHAR NOT NULL,
  trigger_name VARCHAR2(4000 BYTE),
  trigger_timing VARCHAR2(4000 BYTE),
  trigger_operation VARCHAR2(4000 BYTE),
  trigger_event VARCHAR2(4000 BYTE),
  native_sql CLOB,
  native_key VARCHAR2(4000 BYTE),
  language VARCHAR2(40 BYTE) NOT NULL,
  comments VARCHAR2(4000 BYTE),
  linecount NUMBER,
  security_group_id NUMBER DEFAULT 0 NOT NULL,
  created_on DATE DEFAULT sysdate NOT NULL,
  created_by VARCHAR2(255 BYTE),
  last_updated_on DATE,
  last_updated_by VARCHAR2(255 BYTE),
  CONSTRAINT md_triggers_pk PRIMARY KEY ("ID")
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_triggers IS 'For storing information about triggers.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_triggers."ID" IS 'Primary Key';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_triggers.table_or_view_id_fk IS 'Table on which this trigger fires';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_triggers.trigger_on_flag IS 'Flag to show iif the trigger is on a table or a view.  If it is a table this should be ''T''. If it is on a view this should be ''V''';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_triggers.trigger_name IS 'Name of the trigger //OBJECTNAME';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_triggers.trigger_timing IS 'before, after ,etc.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_triggers.trigger_operation IS 'insert, delete, etc.';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_triggers.trigger_event IS 'The actual trigger that gets fired ';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_triggers.native_sql IS 'The full definition ';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_triggers.native_key IS 'UInique identifer for this object at source';
COMMENT ON COLUMN "TEST_VSTSRedgate".md_triggers.language IS '//PUBLIC';