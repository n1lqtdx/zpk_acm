*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTB_USER........................................*
DATA:  BEGIN OF STATUS_ZTB_USER                      .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTB_USER                      .
CONTROLS: TCTRL_ZTB_USER
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTB_USER                      .
TABLES: ZTB_USER                       .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
