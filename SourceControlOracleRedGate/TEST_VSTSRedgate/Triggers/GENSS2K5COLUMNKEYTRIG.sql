CREATE OR REPLACE TRIGGER "TEST_VSTSRedgate"."GENSS2K5COLUMNKEYTRIG" BEFORE
  INSERT ON "TEST_VSTSRedgate".STAGE_SS2K5_COLUMNS FOR EACH ROW BEGIN IF :new.colid_gen IS NULL THEN :new.colid_gen := MD_META.get_next_id;
END IF;
END Genss2k5ColumnKeyTrig;
/