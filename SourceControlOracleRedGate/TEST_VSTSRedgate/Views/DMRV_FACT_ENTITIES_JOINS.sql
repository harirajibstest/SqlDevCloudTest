CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_fact_entities_joins (join_id,join_name,join_ovid,cube_id,cube_name,cube_ovid,left_entity_id,left_entity_name,left_entity_ovid,right_entity_id,right_entity_name,right_entity_ovid,design_ovid) AS
select  Join_ID, Join_Name, Join_OVID, Cube_ID, Cube_Name, Cube_OVID, Left_Entity_ID, Left_Entity_Name, Left_Entity_OVID, Right_Entity_ID, Right_Entity_Name, Right_Entity_OVID, Design_OVID from DMRS_FACT_ENTITIES_JOINS;