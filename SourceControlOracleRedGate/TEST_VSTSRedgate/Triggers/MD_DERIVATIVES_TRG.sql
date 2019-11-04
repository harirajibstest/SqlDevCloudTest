CREATE OR REPLACE TRIGGER "TEST_VSTSRedgate"."MD_DERIVATIVES_TRG" BEFORE INSERT OR UPDATE ON "TEST_VSTSRedgate".MD_DERIVATIVES
FOR EACH ROW
BEGIN
  if inserting and :new.id is null then
        :new.id := MD_META.get_next_id;
    end if;
END;
/