*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTB_ADMIN.......................................*
DATA:  BEGIN OF STATUS_ZTB_ADMIN                     .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTB_ADMIN                     .
CONTROLS: TCTRL_ZTB_ADMIN
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTB_ADMIN                     .
TABLES: ZTB_ADMIN                      .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
