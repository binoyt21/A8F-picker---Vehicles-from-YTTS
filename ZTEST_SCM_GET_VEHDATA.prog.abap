*&---------------------------------------------------------------------*
*& Report  ZTEST_SCM_GET_VEHDATA
*&---------------------------------------------------------------------*
*& Purpose: Test program for function module ZSCM_GET_VEHDATA
*& Author: [Developer Name]
*& Creation Date: 09.01.2026
*& SAP Version: ECC 6.0 / NetWeaver 7.31
*&---------------------------------------------------------------------*
*" Change History:
*" Date       User    TR Number   Description
*" 09.01.2026 USER001 DEVK9xxxxx  Initial creation - Test program
*&---------------------------------------------------------------------*
REPORT ztest_scm_get_vehdata.

*----------------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
PARAMETERS: p_area TYPE yarea OBLIGATORY DEFAULT '01'.
SELECTION-SCREEN END OF BLOCK b1.

*----------------------------------------------------------------------*
* Data Declarations
*----------------------------------------------------------------------*
DATA: lt_vehicle_data TYPE zscm_tt_vehicle_output,
      lw_vehicle_data TYPE zscm_s_vehicle_output,
      lv_message      TYPE char100,
      lv_message_type TYPE char1,
      lv_count        TYPE i,
      lv_index        TYPE i.

*----------------------------------------------------------------------*
* Main Processing
*----------------------------------------------------------------------*
START-OF-SELECTION.

  " BEGIN: Cursor Generated Code

  WRITE: / 'Testing Function Module: ZSCM_GET_VEHDATA',
         / '========================================'.
  SKIP 1.
  WRITE: / 'Input Parameter:',
         / '  AREA:', p_area.
  SKIP 1.

  " Call function module
  CALL FUNCTION 'ZSCM_GET_VEHDATA'
    EXPORTING
      iv_area          = p_area
    IMPORTING
      et_vehicle_data  = lt_vehicle_data
      ev_message       = lv_message
      ev_message_type  = lv_message_type
    EXCEPTIONS
      invalid_input           = 1
      no_configuration_found  = 2
      database_error          = 3
      OTHERS                  = 4.

  " Check sy-subrc
  IF sy-subrc <> 0.
    WRITE: / 'Error occurred:',
           / 'Exception raised:', sy-subrc.
    CASE sy-subrc.
      WHEN 1.
        WRITE: / 'Exception: INVALID_INPUT'.
      WHEN 2.
        WRITE: / 'Exception: NO_CONFIGURATION_FOUND'.
      WHEN 3.
        WRITE: / 'Exception: DATABASE_ERROR'.
      WHEN OTHERS.
        WRITE: / 'Exception: UNKNOWN ERROR'.
    ENDCASE.
    SKIP 1.
  ENDIF.

  " Display message
  WRITE: / 'Function Module Response:',
         / '-------------------------'.
  WRITE: / 'Message Type:', lv_message_type.
  CASE lv_message_type.
    WHEN 'S'.
      WRITE: / '  (S = Success)'.
    WHEN 'E'.
      WRITE: / '  (E = Error)'.
    WHEN 'W'.
      WRITE: / '  (W = Warning)'.
  ENDCASE.
  WRITE: / 'Message:', lv_message.
  SKIP 1.

  " Display results
  DESCRIBE TABLE lt_vehicle_data LINES lv_count.
  WRITE: / 'Records Retrieved:', lv_count.
  SKIP 1.

  " Display vehicle data in table format
  IF lt_vehicle_data IS NOT INITIAL.
    WRITE: / 'Vehicle Data:',
           / '============='.
    SKIP 1.

    " Header
    WRITE: /   'No',
            5  'Area',
            10 'Report No',
            25 'Truck No',
            45 'Transporter',
            60 'Transplpt',
            70 'Status',
            80 'Truck Type',
            95 'Total Qty'.
    ULINE.

    " Data rows
    LOOP AT lt_vehicle_data INTO lw_vehicle_data.
      lv_index = sy-tabix.
      WRITE: /   lv_index,
              5  lw_vehicle_data-area,
              10 lw_vehicle_data-report_no,
              25 lw_vehicle_data-truck_no,
              45 lw_vehicle_data-transptrcd,
              60 lw_vehicle_data-transplpt,
              70 lw_vehicle_data-status,
              80 lw_vehicle_data-truck_type,
              95 lw_vehicle_data-totalqty.
    ENDLOOP.

    SKIP 1.
    WRITE: / 'End of data.'.

  ELSE.
    WRITE: / 'No vehicle data to display.'.
  ENDIF.

  " END: Cursor Generated Code

END-OF-SELECTION.

*----------------------------------------------------------------------*
* Text Symbols
*----------------------------------------------------------------------*
* 001: Input Parameters
*----------------------------------------------------------------------*

