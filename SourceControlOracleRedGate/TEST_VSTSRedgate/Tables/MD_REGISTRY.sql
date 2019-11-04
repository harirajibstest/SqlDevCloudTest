CREATE TABLE "TEST_VSTSRedgate".md_registry (
  object_type VARCHAR2(30 BYTE) NOT NULL,
  object_name VARCHAR2(30 BYTE) NOT NULL,
  desc_object_name VARCHAR2(30 BYTE),
  CONSTRAINT md_registry_pk PRIMARY KEY (object_type,object_name)
);
COMMENT ON TABLE "TEST_VSTSRedgate".md_registry IS 'Table to store information on the MD_ repository.  This lists the objects to be dropped if you wish to remove the repository';