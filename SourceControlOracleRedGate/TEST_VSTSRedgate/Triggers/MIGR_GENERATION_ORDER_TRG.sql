CREATE OR REPLACE TRIGGER "TEST_VSTSRedgate"."MIGR_GENERATION_ORDER_TRG" BEFORE INSERT OR UPDATE ON "TEST_VSTSRedgate".MIGR_GENERATION_ORDER
FOR EACH ROW
BEGIN
  if inserting and :new.id is null then
        :new.id := MD_META.get_next_id;
    end if;
END;
/