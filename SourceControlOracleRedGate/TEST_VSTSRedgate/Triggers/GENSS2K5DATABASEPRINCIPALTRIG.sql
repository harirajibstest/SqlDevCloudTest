CREATE OR REPLACE TRIGGER "TEST_VSTSRedgate".Genss2k5DatabasePrincipalTrig BEFORE
  INSERT ON "TEST_VSTSRedgate".STAGE_SS2K5_DB_PRINCIPALS FOR EACH ROW BEGIN IF :new.prinid_gen IS NULL THEN :new.prinid_gen := MD_META.get_next_id;
END IF;
END Genss2k5DatabasePrincipalTrig;
/