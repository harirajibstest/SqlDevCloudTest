CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_cube_dimensions (cube_id,cube_name,cube_ovid,dimension_id,dimension_name,dimension_ovid,design_ovid) AS
select  Cube_ID, Cube_Name, Cube_OVID, Dimension_ID, Dimension_Name, Dimension_OVID, Design_OVID from DMRS_CUBE_DIMENSIONS;