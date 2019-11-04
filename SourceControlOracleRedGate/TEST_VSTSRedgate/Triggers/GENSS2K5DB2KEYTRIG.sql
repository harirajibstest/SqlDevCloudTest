CREATE OR REPLACE TRIGGER "TEST_VSTSRedgate"."GENSS2K5DB2KEYTRIG" BEFORE
  INSERT ON "TEST_VSTSRedgate".STAGE_SS2K5_DATABASES FOR EACH ROW BEGIN IF :new.dbid_gen IS NULL THEN :new.dbid_gen := MD_META.get_next_id;
END IF;
END Genss2k5Db2KeyTrig;
/