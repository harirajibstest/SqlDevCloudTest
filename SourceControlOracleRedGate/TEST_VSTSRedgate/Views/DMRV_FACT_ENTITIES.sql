CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_fact_entities (cube_id,cube_name,cube_ovid,entity_id,entity_name,entity_ovid,design_ovid) AS
select  Cube_ID, Cube_Name, Cube_OVID, Entity_ID, Entity_Name, Entity_OVID, Design_OVID from DMRS_FACT_ENTITIES;