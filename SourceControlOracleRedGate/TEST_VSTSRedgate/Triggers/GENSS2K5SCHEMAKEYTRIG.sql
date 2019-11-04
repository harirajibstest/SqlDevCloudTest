CREATE OR REPLACE TRIGGER "TEST_VSTSRedgate"."GENSS2K5SCHEMAKEYTRIG" BEFORE
  INSERT ON "TEST_VSTSRedgate".STAGE_SS2K5_SCHEMAS FOR EACH ROW BEGIN IF :new.suid_gen IS NULL THEN :new.suid_gen := MD_META.get_next_id;
END IF;
END Genss2k5SchemaKeyTrig;
/