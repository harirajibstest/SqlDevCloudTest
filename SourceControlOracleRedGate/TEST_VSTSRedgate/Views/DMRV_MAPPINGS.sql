CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_mappings (logical_model_id,logical_model_ovid,logical_model_name,logical_object_id,logical_object_ovid,logical_object_name,logical_object_type,relational_model_id,relational_model_ovid,relational_model_name,relational_object_id,relational_object_ovid,relational_object_name,relational_object_type,entity_id,entity_ovid,entity_name,table_id,table_ovid,table_name,design_id,design_ovid,design_name) AS
select  Logical_Model_ID, Logical_Model_OVID, Logical_Model_Name, Logical_Object_ID, Logical_Object_OVID, Logical_Object_Name, Logical_Object_Type, Relational_Model_ID, Relational_Model_OVID, Relational_Model_Name, Relational_Object_ID, Relational_Object_OVID, Relational_Object_Name, Relational_Object_Type, Entity_ID, Entity_OVID, Entity_Name, Table_ID, Table_OVID, Table_Name, Design_ID, Design_OVID, Design_Name from DMRS_MAPPINGS;