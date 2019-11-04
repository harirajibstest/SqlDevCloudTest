CREATE OR REPLACE TRIGGER "TEST_VSTSRedgate"."DEL_MD_TRIGGERS_V_TRG" AFTER DELETE ON "TEST_VSTSRedgate".MD_VIEWS
FOR EACH ROW 
BEGIN
  DELETE FROM MD_TRIGGERS WHERE MD_TRIGGERS.TABLE_OR_VIEW_ID_FK = :OLD.ID AND MD_TRIGGERS.TRIGGER_ON_FLAG = 'V';
END;
/