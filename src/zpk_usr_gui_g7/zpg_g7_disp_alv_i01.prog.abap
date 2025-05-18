*----------------------------------------------------------------------*
***INCLUDE ZPG_G7_DISP_ALV_I01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_100 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK' OR '&F03'.
      LEAVE TO SCREEN 0.
    WHEN 'EXIT' OR '&F15'.
      LEAVE TO CURRENT TRANSACTION.
    WHEN 'CANCEL' OR '&F12'.
      LEAVE PROGRAM.
    WHEN '&PRNT_PRE'.
      PERFORM smartform_preview.
    WHEN '&EXP_XLSX'.
      PERFORM export_alv_xlsx.
    WHEN '&LOCK'.
      PERFORM process_users USING 'L'.
    WHEN '&UNLOCK'.
      PERFORM process_users USING 'U'.
  ENDCASE.
ENDMODULE.
