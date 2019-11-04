CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_relationships (relationship_name,model_id,model_ovid,object_id,ovid,import_id,source_entity_name,target_entity_name,source_label,target_label,sourceto_target_cardinality,targetto_source_cardinality,source_optional,target_optional,dominant_role,identifying,source_id,source_ovid,target_id,target_ovid,number_of_attributes,transferable,in_arc,arc_id,model_name,design_ovid) AS
select  Relationship_Name, Model_ID, Model_OVID, Object_ID, OVID, Import_ID, Source_Entity_Name, Target_Entity_Name, Source_Label, Target_Label, SourceTo_Target_Cardinality, TargetTo_Source_Cardinality, Source_Optional, Target_Optional, Dominant_Role, Identifying, Source_ID, Source_OVID, Target_ID, Target_OVID, Number_Of_Attributes, Transferable, In_Arc, Arc_ID, Model_Name, Design_OVID from DMRS_RELATIONSHIPS;