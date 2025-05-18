*&---------------------------------------------------------------------*
*& Report zpg_g7_disp_alv
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zpg_g7_disp_alv.

INCLUDE zpg_g7_disp_alv_top.
INCLUDE zpg_g7_disp_alv_o01.
INCLUDE zpg_g7_disp_alv_i01.
INCLUDE zpg_g7_disp_alv_f01.

START-OF-SELECTION.
  PERFORM get_data.
  PERFORM display_usr_alv.
