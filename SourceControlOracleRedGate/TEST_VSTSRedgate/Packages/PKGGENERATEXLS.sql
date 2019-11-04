CREATE OR REPLACE PACKAGE "TEST_VSTSRedgate"."PKGGENERATEXLS" IS

--
debug_flag BOOLEAN := TRUE  ;

PROCEDURE create_excel( p_directory IN VARCHAR2 DEFAULT NULL ,  p_file_name IN VARCHAR2 DEFAULT NULL ) ;
PROCEDURE create_excel_apps ;
PROCEDURE create_style( p_style_name IN VARCHAR2
                      , p_fontname IN VARCHAR2 DEFAULT NULL
                      , p_fontcolor IN VARCHAR2 DEFAULT 'Black'
                      , p_fontsize IN NUMBER DEFAULT null
                      , p_bold IN BOOLEAN DEFAULT FALSE
                      , p_italic IN BOOLEAN DEFAULT FALSE
                      , p_underline IN VARCHAR2 DEFAULT NULL
                      , p_backcolor IN VARCHAR2 DEFAULT NULL );
PROCEDURE close_file ;
PROCEDURE create_worksheet( p_worksheet_name IN VARCHAR2 ) ;
PROCEDURE write_cell_num(p_row NUMBER ,  p_column NUMBER, p_worksheet_name IN VARCHAR2,  p_value IN NUMBER , p_style IN VARCHAR2 DEFAULT NULL );
PROCEDURE write_cell_char(p_row NUMBER, p_column NUMBER, p_worksheet_name IN VARCHAR2,  p_value IN VARCHAR2, p_style IN VARCHAR2 DEFAULT NULL  );
PROCEDURE write_cell_null(p_row NUMBER ,  p_column NUMBER , p_worksheet_name IN VARCHAR2, p_style IN VARCHAR2 );

PROCEDURE set_row_height( p_row IN NUMBER , p_height IN NUMBER, p_worksheet IN VARCHAR2  ) ;
PROCEDURE SET_COLUMN_WIDTH( P_COLUMN IN NUMBER , P_WIDTH IN NUMBER , P_WORKSHEET IN VARCHAR2  ) ;
PROCEDURE PRCGENERATEXLS (FILEDIR IN VARCHAR2, filename in varchar2,strquery in varchar2, sheetname in varchar2);
PROCEDURE PRCGENXLS(FILEDIR IN VARCHAR2,FILENAME IN VARCHAR2,STRQUERY in VARCHAR2,SHEETNAME in VARCHAR2);
END ;
 
 
 
 
 
 
 
 
 
 
/