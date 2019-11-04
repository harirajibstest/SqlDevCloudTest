CREATE OR REPLACE TRIGGER "TEST_VSTSRedgate"."GENCONNKEYTRIG" 
					BEFORE INSERT ON "TEST_VSTSRedgate".stage_serverdetail 
					FOR EACH ROW 
					BEGIN
					  IF :new.project_id is null THEN
					     :new.project_id := MD_META.get_next_id;
					  END IF;
					  IF :new.svrid is null THEN
					     :new.svrid := MD_META.get_next_id;     
					  END IF;    
					END GenConnKeyTrig;
/