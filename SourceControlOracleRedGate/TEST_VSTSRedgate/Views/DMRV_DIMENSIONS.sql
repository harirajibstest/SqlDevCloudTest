CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_dimensions (dimension_id,dimension_name,dimension_ovid,model_id,model_name,model_ovid,base_entity_id,base_entity_name,base_entity_ovid,base_level_id,base_level_name,base_level_ovid,oracle_long_name,oracle_plural_name,oracle_short_name,description,design_ovid) AS
select  Dimension_ID, Dimension_Name, Dimension_OVID, Model_ID, Model_Name, Model_OVID, Base_Entity_ID, Base_Entity_Name, Base_Entity_OVID, Base_Level_ID, Base_Level_Name, Base_Level_OVID, Oracle_Long_Name, Oracle_Plural_Name, Oracle_Short_Name, Description, Design_OVID from DMRS_DIMENSIONS;