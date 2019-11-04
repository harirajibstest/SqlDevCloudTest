CREATE OR REPLACE TRIGGER "TEST_VSTSRedgate"."GENSS2K5SQLMODTRIG" BEFORE
  INSERT ON "TEST_VSTSRedgate".STAGE_SS2K5_SQL_MODULES FOR EACH ROW BEGIN IF :new.OBJID_GEN IS NULL THEN :new.OBJID_GEN := MD_META.get_next_id;
END IF;
END Genss2k5SqlModTrig;
/