*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_ZFG_ADM_MAINT_G7
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_ZFG_ADM_MAINT_G7   .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.
