CREATE OR REPLACE TRIGGER "TEST_VSTSRedgate"."STAGE_MIGRLOG_ID_TRG" BEFORE INSERT OR UPDATE ON "TEST_VSTSRedgate".STAGE_MIGRLOG
FOR EACH ROW
BEGIN
  if inserting and :new.id is null then
        :new.id := MD_META.get_next_id;
    end if;
END;
/