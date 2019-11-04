CREATE OR REPLACE TRIGGER "TEST_VSTSRedgate"."GENSCHEMAKEYTRIG" 
					BEFORE INSERT ON "TEST_VSTSRedgate".stage_syb12_sysusers
					FOR EACH ROW 
					BEGIN
					  IF :new.suid_gen is null THEN
					     :new.suid_gen := MD_META.get_next_id;
					  END IF;
					END GenSchemaKeyTrig;
/