CREATE OR REPLACE FORCE VIEW "TEST_VSTSRedgate".dmrv_domain_avt (domain_id,domain_ovid,"SEQUENCE","VALUE",short_description,domain_name,design_ovid) AS
select  Domain_ID, Domain_OVID, Sequence, Value, Short_Description, Domain_Name, Design_OVID from DMRS_DOMAIN_AVT;