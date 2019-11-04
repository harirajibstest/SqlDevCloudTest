CREATE OR REPLACE TRIGGER "TEST_VSTSRedgate"."STAGE_MIGRLOG_LOG_DATE_TRG" BEFORE INSERT OR UPDATE ON "TEST_VSTSRedgate".STAGE_MIGRLOG
FOR EACH ROW
BEGIN
  if inserting and :new.log_date is null then
        :new.log_date := systimestamp;
    end if;
END;
/