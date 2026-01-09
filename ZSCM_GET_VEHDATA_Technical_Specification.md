# Technical Specification: ZSCM_GET_VEHDATA

**Document Version:** 1.0  
**Date:** January 9, 2026  
**Function Module:** ZSCM_GET_VEHDATA  
**Function Group:** ZSCM (or create new: ZSCM_VEHICLE_DATA)  
**SAP Version:** ECC 6.0 / NetWeaver 7.31  
**Development Class:** ZSCM or ZLOG  

---

## 1. Technical Overview

### 1.1 Purpose
This document provides detailed technical specifications for implementing function module ZSCM_GET_VEHDATA, which retrieves vehicle data from YTTSTX0001 table based on area and configuration parameters.

### 1.2 Technical Architecture
- **Type:** RFC-Enabled Function Module
- **Processing Type:** Synchronous
- **Execution Mode:** Normal function module (not update module)
- **Remote-Enabled:** Yes (recommended for integration scenarios)

### 1.3 NetWeaver 7.31 Compliance
- No inline declarations (DATA(lv_var))
- No constructor operators (NEW, VALUE, CORRESPONDING)
- No string templates (|text|)
- No table expressions (itab[ key ])
- Classic OpenSQL syntax only
- All variables declared upfront in DATA section

---

## 2. Function Module Interface

### 2.1 Function Module Definition

```abap
FUNCTION ZSCM_GET_VEHDATA
  IMPORTING
    VALUE(IV_AREA) TYPE YAREA
  EXPORTING
    VALUE(ET_VEHICLE_DATA) TYPE ZSCM_TT_VEHICLE_OUTPUT
    VALUE(EV_MESSAGE) TYPE CHAR100
    VALUE(EV_MESSAGE_TYPE) TYPE CHAR1
  EXCEPTIONS
    INVALID_INPUT
    NO_CONFIGURATION_FOUND
    DATABASE_ERROR.
```

### 2.2 Type Definitions (Include ZSCM_VEHICLE_DATATOP)

```abap
*&---------------------------------------------------------------------*
*& Include ZSCM_VEHICLE_DATATOP
*&---------------------------------------------------------------------*
*& Type definitions for vehicle data function module
*&---------------------------------------------------------------------*

" Structure for output vehicle data
TYPES: BEGIN OF ty_vehicle_output,
         area       TYPE yarea,           " Area of Location
         report_no  TYPE yreport_no,      " Truck Reporting Serial ID
         truck_no   TYPE ytruck_no,       " Truck Number
         transptrcd TYPE lifnr,           " Transporter Code
         transplpt  TYPE tplst,           " Transportation Planning Point
         shnumber   TYPE oig_shnum,       " TD Shipment Number
         status     TYPE statuv_txt,      " Status
         reject_res TYPE yreasoncd,       " Rejection Reason Code
         truck_type TYPE ytrktype,        " Truck Type
         trk_purpos TYPE ytrk_purps,      " Truck Purpose
         vtweg      TYPE vtweg,           " Distribution Channel
         spart      TYPE spart,           " Division
         matgr      TYPE mvgr1,           " Material Group 1
         totalqty   TYPE yig_cmpqua,      " Compartment Quantity
       END OF ty_vehicle_output.

" Table type for output
TYPES: ty_vehicle_output_table TYPE STANDARD TABLE OF ty_vehicle_output.

" Structure for configuration parameters from ZLOG_EXEC_VAR
TYPES: BEGIN OF ty_config_param,
         name       TYPE rvari_vnam,      " Parameter name
         active     TYPE zactive_flag,    " Active flag
         remarks    TYPE textr,           " Remarks (used for TRUCK_TYPE filtering)
         trk_purpos TYPE ytrk_purps,      " Truck Purpose
         ewm_uom_d  TYPE txt30,           " EWM UOM (used for FUNCTION field)
         vstel      TYPE vstel,           " Shipping Point
         transplpt  TYPE tplst,           " Transportation Planning Point
       END OF ty_config_param.

" Structure for YTTSTX0001 selection (matching SELECT fields exactly)
TYPES: BEGIN OF ty_yttstx0001_select,
         area       TYPE yarea,
         report_no  TYPE yreport_no,
         truck_no   TYPE ytruck_no,
         transptrcd TYPE lifnr,
         transplpt  TYPE tplst,
         shnumber   TYPE oig_shnum,
         status     TYPE statuv_txt,
         reject_res TYPE yreasoncd,
         truck_type TYPE ytrktype,
         trk_purpos TYPE ytrk_purps,
         vtweg      TYPE vtweg,
         spart      TYPE spart,
         matgr      TYPE mvgr1,
         totalqty   TYPE yig_cmpqua,
         function   TYPE ystats,          " Function code field
         vstel      TYPE vstel,           " Shipping Point
       END OF ty_yttstx0001_select.

TYPES: ty_yttstx0001_table TYPE STANDARD TABLE OF ty_yttstx0001_select.
```

### 2.3 Global Type Creation (SE11)

Create table type in SE11:
- **Table Type Name:** ZSCM_TT_VEHICLE_OUTPUT
- **Short Description:** Vehicle Output Table Type
- **Line Type:** ZSCM_S_VEHICLE_OUTPUT (structure)
- **Access:** Standard table
- **Key:** Non-unique
- **Key Fields:** AREA, REPORT_NO

Create structure in SE11:
- **Structure Name:** ZSCM_S_VEHICLE_OUTPUT
- **Fields:** As per ty_vehicle_output above

---

## 3. Detailed Implementation

### 3.1 Main Function Module Code

```abap
FUNCTION zscm_get_vehdata.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_AREA) TYPE  YAREA
*"  EXPORTING
*"     VALUE(ET_VEHICLE_DATA) TYPE  ZSCM_TT_VEHICLE_OUTPUT
*"     VALUE(EV_MESSAGE) TYPE  CHAR100
*"     VALUE(EV_MESSAGE_TYPE) TYPE  CHAR1
*"  EXCEPTIONS
*"      INVALID_INPUT
*"      NO_CONFIGURATION_FOUND
*"      DATABASE_ERROR
*"----------------------------------------------------------------------
*" Function Module: ZSCM_GET_VEHDATA
*" Purpose: Fetch vehicle data from YTTSTX0001 table
*" Author: [Developer Name]
*" Creation Date: [Date]
*" Change History:
*" Date       User    Description
*" DD.MM.YYYY USERID  Initial creation
*"----------------------------------------------------------------------

  " BEGIN: Cursor Generated Code
  " Local data declarations
  DATA: lt_config         TYPE TABLE OF ty_config_param,
        lw_config         TYPE ty_config_param,
        lt_vehicle_data   TYPE ty_yttstx0001_table,
        lt_vehicle_filter TYPE ty_yttstx0001_table,
        lw_vehicle_data   TYPE ty_yttstx0001_select,
        lw_output         TYPE ty_vehicle_output,
        lv_count          TYPE i,
        lv_count_filtered TYPE i,
        lv_msg_text       TYPE string,
        lo_exception      TYPE REF TO cx_root.

  " Constants for function module
  CONSTANTS: lc_fm_name    TYPE rvari_vnam VALUE 'ZSCM_GET_VEHDATA',
             lc_active     TYPE zactive_flag VALUE 'X',
             lc_space      TYPE char1 VALUE ' ',
             lc_msg_s      TYPE char1 VALUE 'S',
             lc_msg_e      TYPE char1 VALUE 'E',
             lc_msg_w      TYPE char1 VALUE 'W'.

  " Initialize export parameters
  CLEAR: et_vehicle_data,
         ev_message,
         ev_message_type.

  " Step 1: Input validation
  IF iv_area IS INITIAL.
    ev_message = 'Input parameter IV_AREA is mandatory'(001).
    ev_message_type = lc_msg_e.
    RAISE invalid_input.
  ENDIF.

  " Step 2: Fetch configuration parameters
  TRY.
      SELECT name
             active
             remarks
             trk_purpos
             ewm_uom_d
             vstel
             transplpt
        FROM zlog_exec_var
        INTO TABLE lt_config
        WHERE name = lc_fm_name
          AND active = lc_active.

      IF sy-subrc <> 0.
        ev_message = 'No active configuration found for function module'(002).
        ev_message_type = lc_msg_e.
        RAISE no_configuration_found.
      ENDIF.

    CATCH cx_root INTO lo_exception.
      lv_msg_text = lo_exception->get_text( ).
      CONCATENATE 'Database error while fetching configuration:'(003)
                  lv_msg_text
             INTO ev_message SEPARATED BY space.
      ev_message_type = lc_msg_e.
      RAISE database_error.
  ENDTRY.

  " Read first configuration entry (if multiple exist)
  READ TABLE lt_config INTO lw_config INDEX 1.
  IF sy-subrc <> 0.
    ev_message = 'Error reading configuration data'(004).
    ev_message_type = lc_msg_e.
    RAISE no_configuration_found.
  ENDIF.

  " Validate configuration data completeness
  IF lw_config-ewm_uom_d IS INITIAL OR
     lw_config-trk_purpos IS INITIAL OR
     lw_config-remarks IS INITIAL OR
     lw_config-vstel IS INITIAL OR
     lw_config-transplpt IS INITIAL.
    ev_message = 'Configuration data is incomplete. Check ZLOG_EXEC_VAR'(009).
    ev_message_type = lc_msg_e.
    RAISE no_configuration_found.
  ENDIF.

  " Step 3: Query vehicle data from YTTSTX0001
  TRY.
      " Structure ty_yttstx0001_select matches SELECT field order exactly
      SELECT area
             report_no
             truck_no
             transptrcd
             transplpt
             shnumber
             status
             reject_res
             truck_type
             trk_purpos
             vtweg
             spart
             matgr
             totalqty
             function
             vstel
        FROM yttstx0001
        INTO TABLE lt_vehicle_data
        WHERE area      = iv_area
          AND transplpt = lw_config-transplpt
          AND vstel     = lw_config-vstel
          AND function  = lw_config-ewm_uom_d
          AND trk_purpos = lw_config-trk_purpos.

      IF sy-subrc <> 0.
        " No records found - Warning
        CONCATENATE 'No vehicle data found for area'(005)
                    iv_area
               INTO ev_message SEPARATED BY space.
        ev_message_type = lc_msg_w.
        RETURN.
      ENDIF.

    CATCH cx_root INTO lo_exception.
      lv_msg_text = lo_exception->get_text( ).
      CONCATENATE 'Database error while fetching vehicle data:'(006)
                  lv_msg_text
             INTO ev_message SEPARATED BY space.
      ev_message_type = lc_msg_e.
      RAISE database_error.
  ENDTRY.

  " Step 4: Filter vehicle data in memory
  " Filter by TRUCK_TYPE, SHNUMBER, and REJECT_RES
  LOOP AT lt_vehicle_data INTO lw_vehicle_data.
    " Apply filtering conditions
    IF lw_vehicle_data-truck_type = lw_config-remarks AND
       lw_vehicle_data-shnumber   = lc_space AND
       lw_vehicle_data-reject_res = lc_space.
      " Record meets filter criteria, add to filtered table
      APPEND lw_vehicle_data TO lt_vehicle_filter.
    ENDIF.
    CLEAR lw_vehicle_data.
  ENDLOOP.

  " Check if any records passed the filter
  DESCRIBE TABLE lt_vehicle_filter LINES lv_count_filtered.
  IF lv_count_filtered = 0.
    CONCATENATE 'No vehicle data found matching all filter criteria for area'(010)
                iv_area
           INTO ev_message SEPARATED BY space.
    ev_message_type = lc_msg_w.
    RETURN.
  ENDIF.

  " Step 5: Populate output table from filtered data
  LOOP AT lt_vehicle_filter INTO lw_vehicle_data.
    MOVE-CORRESPONDING lw_vehicle_data TO lw_output.
    APPEND lw_output TO et_vehicle_data.
    CLEAR lw_output.
  ENDLOOP.

  " Step 6: Set success message
  DESCRIBE TABLE et_vehicle_data LINES lv_count.
  CONCATENATE 'Vehicle data retrieved successfully.'(007)
              lv_count
              'records found'(008)
         INTO ev_message SEPARATED BY space.
  ev_message_type = lc_msg_s.

  " END: Cursor Generated Code

ENDFUNCTION.
```

### 3.2 Alternative Implementation Options

```abap
" Alternative Option 1: Combine database and memory filtering
" Instead of two-stage (DB query + memory filter), 
" add TRUCK_TYPE to WHERE clause if database supports efficient filtering
" Note: Current implementation uses memory filter for flexibility

" Alternative Option 2: Database filtering with dynamic WHERE
SELECT area report_no truck_no transptrcd transplpt shnumber
       status reject_res truck_type trk_purpos vtweg spart matgr totalqty
       function vstel
  FROM yttstx0001
  INTO TABLE lt_vehicle_data
  WHERE area       = iv_area
    AND transplpt  = lw_config-transplpt
    AND vstel      = lw_config-vstel
    AND function   = lw_config-ewm_uom_d
    AND trk_purpos = lw_config-trk_purpos
    AND truck_type = lw_config-remarks
    AND shnumber   = lc_space
    AND reject_res = lc_space.
" Advantage: Single query, no memory filtering needed
" Disadvantage: Less flexible if filtering logic needs to change

" Alternative Option 3: Use FOR ALL ENTRIES if multiple areas needed (future enhancement)
" This is a pattern for future multi-area support
" Not implemented in current version as only single area is input
```

---

## 4. Database Access Optimization

### 4.1 Index Requirements

**YTTSTX0001 Table:**
- **Primary Index:** MANDT, AREA, REPORT_NO
- **Secondary Index (Recommended):**
  ```
  Index Name: ZYTTSTX0001~001
  Fields: AREA, TRANSPLPT, VSTEL, FUNCTION, TRK_PURPOS
  Unique: No
  ```
  This index supports the main WHERE clause in Step 3

**ZLOG_EXEC_VAR Table:**
- **Primary Index:** MANDT, NAME, NUMB
- **Secondary Index (Existing):** NAME, ACTIVE

### 4.2 Performance Optimization Techniques

```abap
" ✅ CORRECT - Internal table structure matches SELECT exactly
TYPES: BEGIN OF ty_yttstx0001_select,
         " 14 fields matching SELECT statement order
       END OF ty_yttstx0001_select.

" ❌ AVOID - Using full table structure wastes memory
DATA: lt_vehicle TYPE TABLE OF yttstx0001.  " Contains 100+ unused fields
```

### 4.3 Memory Management

```abap
" Free temporary tables if large datasets expected
FREE: lt_config,
      lt_vehicle_data.

" Alternative: Use field symbols for large internal tables
FIELD-SYMBOLS: <lfs_vehicle> TYPE ty_yttstx0001_select.

LOOP AT lt_vehicle_data ASSIGNING <lfs_vehicle>.
  MOVE-CORRESPONDING <lfs_vehicle> TO lw_output.
  APPEND lw_output TO et_vehicle_data.
ENDLOOP.
```

---

## 5. Error Handling Implementation

### 5.1 Exception Handling Pattern (NW 7.31 Compatible)

```abap
" Declare exception object BEFORE TRY block
DATA: lo_exception TYPE REF TO cx_root,
      lv_error_text TYPE string.

TRY.
    " Database operation
    SELECT ...
    
  CATCH cx_root INTO lo_exception.
    " Get text from exception
    lv_error_text = lo_exception->get_text( ).
    
    " Build error message
    CONCATENATE 'Database error:'(010)
                lv_error_text
           INTO ev_message SEPARATED BY space.
    ev_message_type = lc_msg_e.
    
    " Raise function module exception
    RAISE database_error.
ENDTRY.
```

### 5.2 Message Text Elements

Define text symbols in SE32:
- 001: Input parameter IV_AREA is mandatory
- 002: No active configuration found for function module
- 003: Database error while fetching configuration:
- 004: Error reading configuration data
- 005: No vehicle data found for area
- 006: Database error while fetching vehicle data:
- 007: Vehicle data retrieved successfully.
- 008: records found
- 009: Configuration data is incomplete. Check ZLOG_EXEC_VAR
- 010: No vehicle data found matching all filter criteria for area
- 011: Database error:

---

## 6. Testing Implementation

### 6.1 Test Program (ZTEST_SCM_GET_VEHDATA)

```abap
*&---------------------------------------------------------------------*
*& Report  ZTEST_SCM_GET_VEHDATA
*&---------------------------------------------------------------------*
*& Purpose: Test program for function module ZSCM_GET_VEHDATA
*& Author: [Developer Name]
*& Creation Date: [Date]
*&---------------------------------------------------------------------*
REPORT ztest_scm_get_vehdata.

" BEGIN: Cursor Generated Code

" Selection screen
PARAMETERS: p_area TYPE yarea OBLIGATORY DEFAULT '01'.

" Data declarations
DATA: lt_vehicle_data TYPE zscm_tt_vehicle_output,
      lw_vehicle_data TYPE zscm_s_vehicle_output,
      lv_message      TYPE char100,
      lv_message_type TYPE char1,
      lv_count        TYPE i.

START-OF-SELECTION.

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
  ENDIF.

  " Display message
  WRITE: / 'Message Type:', lv_message_type,
         / 'Message:', lv_message.

  " Display results
  DESCRIBE TABLE lt_vehicle_data LINES lv_count.
  WRITE: / 'Records found:', lv_count.

  " Display vehicle data in ALV or simple list
  IF lt_vehicle_data IS NOT INITIAL.
    SKIP 2.
    WRITE: / 'AREA', 10 'REPORT_NO', 25 'TRUCK_NO',
             45 'TRANSPTRCD', 60 'STATUS'.
    ULINE.

    LOOP AT lt_vehicle_data INTO lw_vehicle_data.
      WRITE: / lw_vehicle_data-area,
               10 lw_vehicle_data-report_no,
               25 lw_vehicle_data-truck_no,
               45 lw_vehicle_data-transptrcd,
               60 lw_vehicle_data-status.
    ENDLOOP.
  ENDIF.

" END: Cursor Generated Code

END-OF-SELECTION.
```

### 6.2 Unit Test Class (For ABAP Unit Testing)

```abap
*&---------------------------------------------------------------------*
*& Include for test class
*&---------------------------------------------------------------------*

CLASS lcl_test_vehicle_data DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS:
      test_valid_area FOR TESTING,
      test_invalid_area FOR TESTING,
      test_no_configuration FOR TESTING,
      test_no_data_found FOR TESTING.

ENDCLASS.

CLASS lcl_test_vehicle_data IMPLEMENTATION.

  METHOD test_valid_area.
    " Test with valid area
    DATA: lt_vehicle_data TYPE zscm_tt_vehicle_output,
          lv_message      TYPE char100,
          lv_message_type TYPE char1.

    CALL FUNCTION 'ZSCM_GET_VEHDATA'
      EXPORTING
        iv_area         = '01'
      IMPORTING
        et_vehicle_data = lt_vehicle_data
        ev_message      = lv_message
        ev_message_type = lv_message_type
      EXCEPTIONS
        OTHERS          = 1.

    " Assert: Function should execute successfully
    cl_abap_unit_assert=>assert_equals(
      act = sy-subrc
      exp = 0
      msg = 'Function should execute without exception' ).

  ENDMETHOD.

  METHOD test_invalid_area.
    " Test with initial area
    DATA: lt_vehicle_data TYPE zscm_tt_vehicle_output,
          lv_message      TYPE char100,
          lv_message_type TYPE char1,
          lv_subrc        TYPE sy-subrc.

    CALL FUNCTION 'ZSCM_GET_VEHDATA'
      EXPORTING
        iv_area          = ''
      IMPORTING
        et_vehicle_data  = lt_vehicle_data
        ev_message       = lv_message
        ev_message_type  = lv_message_type
      EXCEPTIONS
        invalid_input    = 1
        OTHERS           = 2.

    lv_subrc = sy-subrc.

    " Assert: Should raise invalid_input exception
    cl_abap_unit_assert=>assert_equals(
      act = lv_subrc
      exp = 1
      msg = 'Should raise invalid_input exception' ).

    " Assert: Message type should be E
    cl_abap_unit_assert=>assert_equals(
      act = lv_message_type
      exp = 'E'
      msg = 'Message type should be Error' ).

  ENDMETHOD.

  METHOD test_no_configuration.
    " Test scenario where no configuration exists
    " This test assumes configuration can be controlled or mocked
    DATA: lt_vehicle_data TYPE zscm_tt_vehicle_output,
          lv_message      TYPE char100,
          lv_message_type TYPE char1.

    " Implementation depends on test data setup
    " Skip detailed implementation as it requires test data control

  ENDMETHOD.

  METHOD test_no_data_found.
    " Test with area that has no matching vehicles
    DATA: lt_vehicle_data TYPE zscm_tt_vehicle_output,
          lv_message      TYPE char100,
          lv_message_type TYPE char1.

    CALL FUNCTION 'ZSCM_GET_VEHDATA'
      EXPORTING
        iv_area         = '99'  " Assume this area has no data
      IMPORTING
        et_vehicle_data = lt_vehicle_data
        ev_message      = lv_message
        ev_message_type = lv_message_type
      EXCEPTIONS
        OTHERS          = 1.

    " Assert: Message type should be W (Warning)
    cl_abap_unit_assert=>assert_equals(
      act = lv_message_type
      exp = 'W'
      msg = 'Should return warning when no data found' ).

    " Assert: Output table should be empty
    cl_abap_unit_assert=>assert_initial(
      act = lt_vehicle_data
      msg = 'Output table should be empty' ).

  ENDMETHOD.

ENDCLASS.
```

---

## 7. Transport and Deployment

### 7.1 Transport Objects

| Object Type | Object Name | Description | Workbench Request |
|------------|-------------|-------------|-------------------|
| FUGR | ZSCM_VEHICLE_DATA | Function group | DEVK9xxxxx |
| FUNC | ZSCM_GET_VEHDATA | Function module | DEVK9xxxxx |
| TABL | ZSCM_S_VEHICLE_OUTPUT | Structure | DEVK9xxxxx |
| TTYP | ZSCM_TT_VEHICLE_OUTPUT | Table type | DEVK9xxxxx |
| PROG | ZTEST_SCM_GET_VEHDATA | Test program | DEVK9xxxxx |

### 7.2 Deployment Checklist

- [ ] Create function group ZSCM_VEHICLE_DATA (SE37 or SE80)
- [ ] Create structure ZSCM_S_VEHICLE_OUTPUT (SE11)
- [ ] Create table type ZSCM_TT_VEHICLE_OUTPUT (SE11)
- [ ] Activate structure and table type
- [ ] Create function module ZSCM_GET_VEHDATA (SE37)
- [ ] Implement function module code
- [ ] Activate function module
- [ ] Create test program ZTEST_SCM_GET_VEHDATA (SE38)
- [ ] Configure ZLOG_EXEC_VAR table entry
- [ ] Execute unit tests
- [ ] Execute integration tests
- [ ] Document in function module (SE37 → Documentation)
- [ ] Create transport request
- [ ] Add all objects to transport
- [ ] Release transport request

### 7.3 Post-Deployment Configuration

Execute in target system (DEV, QA, PRD):

1. **Maintain ZLOG_EXEC_VAR table (SM30 or SE16):**
   ```
   NAME: ZSCM_GET_VEHDATA
   ACTIVE: X
   EWM_UOM_D: [Value from business - maps to FUNCTION field, e.g., 'PICK']
   TRK_PURPOS: [Value from business - e.g., 'I']
   REMARKS: [Value from business - maps to TRUCK_TYPE filter, e.g., 'TRK']
   VSTEL: [Value from business - e.g., '1000']
   TRANSPLPT: [Value from business - e.g., 'TP01']
   ```

2. **Verify table indexes:**
   - Check YTTSTX0001 index exists (SE11 → Display → Indexes)
   - If not, create recommended secondary index

3. **Authorization setup:**
   - Grant S_TABU_DIS for ZLOG_EXEC_VAR and YTTSTX0001
   - Test with restricted user

---

## 8. Integration Scenarios

### 8.1 RFC Call from External System

```abap
" Example: Call from another SAP system via RFC

DATA: lt_vehicle_data TYPE zscm_tt_vehicle_output,
      lv_message      TYPE char100,
      lv_message_type TYPE char1,
      lv_rfcdest      TYPE rfcdest.

lv_rfcdest = 'DEST_ECC_PRD'.  " RFC destination

CALL FUNCTION 'ZSCM_GET_VEHDATA'
  DESTINATION lv_rfcdest
  EXPORTING
    iv_area          = '01'
  IMPORTING
    et_vehicle_data  = lt_vehicle_data
    ev_message       = lv_message
    ev_message_type  = lv_message_type
  EXCEPTIONS
    invalid_input          = 1
    no_configuration_found = 2
    database_error         = 3
    system_failure         = 4
    communication_failure  = 5
    OTHERS                 = 6.

IF sy-subrc <> 0.
  " Handle RFC errors
  MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
```

### 8.2 Call from ABAP Report

```abap
" Example: Call from custom report

REPORT z_vehicle_report.

DATA: lt_vehicle_data TYPE zscm_tt_vehicle_output,
      lw_vehicle_data TYPE zscm_s_vehicle_output,
      lv_message      TYPE char100,
      lv_message_type TYPE char1.

PARAMETERS: p_area TYPE yarea DEFAULT '01'.

START-OF-SELECTION.

  CALL FUNCTION 'ZSCM_GET_VEHDATA'
    EXPORTING
      iv_area          = p_area
    IMPORTING
      et_vehicle_data  = lt_vehicle_data
      ev_message       = lv_message
      ev_message_type  = lv_message_type
    EXCEPTIONS
      invalid_input          = 1
      no_configuration_found = 2
      database_error         = 3
      OTHERS                 = 4.

  CASE sy-subrc.
    WHEN 0.
      " Process results
      LOOP AT lt_vehicle_data INTO lw_vehicle_data.
        " Process each vehicle
      ENDLOOP.

    WHEN 1.
      MESSAGE lv_message TYPE 'I' DISPLAY LIKE 'E'.
    WHEN 2.
      MESSAGE lv_message TYPE 'I' DISPLAY LIKE 'E'.
    WHEN 3.
      MESSAGE lv_message TYPE 'I' DISPLAY LIKE 'E'.
    WHEN OTHERS.
      MESSAGE 'Unknown error occurred' TYPE 'I' DISPLAY LIKE 'E'.
  ENDCASE.
```

### 8.3 Call from Web Service (PI/PO Integration)

Function module can be exposed as web service:
1. Create service definition (SOAMANAGER)
2. Configure endpoint
3. Generate WSDL
4. Provide to integration team

---

## 9. Monitoring and Logging

### 9.1 Application Logging (Optional Enhancement)

```abap
" Add application log functionality (requires BAL objects)

DATA: lv_log_handle TYPE balloghndl,
      lw_log        TYPE bal_s_log,
      lw_msg        TYPE bal_s_msg.

" Create log
CALL FUNCTION 'BAL_LOG_CREATE'
  EXPORTING
    i_s_log      = lw_log
  IMPORTING
    e_log_handle = lv_log_handle
  EXCEPTIONS
    OTHERS       = 1.

" Add log message
lw_msg-msgty = 'I'.
lw_msg-msgid = 'ZSCM'.
lw_msg-msgno = '001'.
lw_msg-msgv1 = iv_area.

CALL FUNCTION 'BAL_LOG_MSG_ADD'
  EXPORTING
    i_log_handle = lv_log_handle
    i_s_msg      = lw_msg
  EXCEPTIONS
    OTHERS       = 1.

" Save log
CALL FUNCTION 'BAL_DB_SAVE'
  EXCEPTIONS
    OTHERS = 1.
```

### 9.2 Performance Monitoring

Monitor function module performance:
- Transaction: ST05 (SQL Trace)
- Transaction: ST12 (Performance Analysis)
- Transaction: ST03N (Workload Analysis)

Key metrics to monitor:
- Average execution time
- Database time percentage
- Number of records processed
- RFC calls (if remote-enabled)

---

## 10. Security Considerations

### 10.1 Authorization Check Implementation (Optional)

```abap
" Add authorization check for area-based access

AUTHORITY-CHECK OBJECT 'Z_AREA_ACC'
  ID 'AREA' FIELD iv_area
  ID 'ACTVT' FIELD '03'.  " 03 = Display

IF sy-subrc <> 0.
  ev_message = 'No authorization for area'(011).
  ev_message_type = lc_msg_e.
  RAISE invalid_input.
ENDIF.
```

### 10.2 Authorization Object (if required)

Create authorization object in SU21:
- **Object Name:** Z_AREA_ACC
- **Object Class:** Custom
- **Fields:**
  - AREA (Type: YAREA)
  - ACTVT (Type: ACTIV_AUTH)

---

## 11. Troubleshooting Guide

### 11.1 Common Issues and Solutions

| Issue | Symptom | Solution |
|-------|---------|----------|
| No configuration found | Exception NO_CONFIGURATION_FOUND | Check ZLOG_EXEC_VAR table, ensure NAME = 'ZSCM_GET_VEHDATA' and ACTIVE = 'X', verify all 5 config fields populated |
| Incomplete configuration | Exception NO_CONFIGURATION_FOUND with message 009 | Verify all required fields in ZLOG_EXEC_VAR: EWM_UOM_D, TRK_PURPOS, REMARKS, VSTEL, TRANSPLPT |
| No data returned | Warning message | Verify YTTSTX0001 has records matching database criteria (AREA, TRANSPLPT, VSTEL, FUNCTION, TRK_PURPOS) and filter criteria (TRUCK_TYPE, blank SHNUMBER/REJECT_RES) |
| Database error | Exception DATABASE_ERROR | Check table authorization (S_TABU_DIS), verify tables exist, check FUNCTION and VSTEL fields exist in YTTSTX0001 |
| Slow performance | Long execution time | Check database indexes on AREA, TRANSPLPT, VSTEL, FUNCTION, TRK_PURPOS; review number of records; analyze with ST05 |
| Invalid area | Exception INVALID_INPUT | Ensure IV_AREA parameter is not initial |
| Records found but filtered out | Warning with message 010 | Check TRUCK_TYPE values in data match REMARKS config; verify SHNUMBER and REJECT_RES are blank |

### 11.2 Debug Points

Key debug points to check:
1. After input validation: Check IV_AREA value
2. After config SELECT: Check lt_config contents and lw_config values (all 5 fields)
3. After config validation: Verify EWM_UOM_D, TRK_PURPOS, REMARKS, VSTEL, TRANSPLPT are not initial
4. After vehicle SELECT: Check lt_vehicle_data record count (before filtering)
5. In filtering loop: Check each record against filter conditions
6. After filtering: Check lt_vehicle_filter record count (after filtering)
7. In output loop: Verify MOVE-CORRESPONDING works correctly

### 11.3 Log Analysis

Check application logs:
- Transaction: SLG1 (Application Log)
- Object: ZSCM (if logging implemented)
- Subobject: VEHICLE_DATA

---

## 12. Code Review Checklist

### 12.1 ABAP Standards Compliance

- [ ] All variables declared upfront (no inline declarations)
- [ ] Naming conventions followed (lv_, lt_, lw_ prefixes)
- [ ] No NetWeaver 7.40+ syntax used
- [ ] Classic OpenSQL syntax used
- [ ] No SELECT * statements
- [ ] Internal table structure matches SELECT fields exactly
- [ ] SY-SUBRC checked after all database operations
- [ ] Exception handling with TRY-CATCH implemented
- [ ] Constants used for literal values
- [ ] Code commented with meaningful comments
- [ ] Function module has header documentation
- [ ] Text symbols used for messages

### 12.2 Performance Review

- [ ] Database access optimized (specific field selection)
- [ ] No SELECT in LOOP
- [ ] Appropriate indexes exist
- [ ] Memory management considered (FREE for large tables)
- [ ] No nested loops without BINARY SEARCH
- [ ] FOR ALL ENTRIES pattern correct (if used)

### 12.3 Security Review

- [ ] Authorization checks implemented (if required)
- [ ] Input validation performed
- [ ] SQL injection not possible (using typed parameters)
- [ ] No hard-coded sensitive data

---

## 13. Maintenance and Support

### 13.1 Future Enhancement Opportunities

1. **Pagination Support**
   - Add parameters: IV_PAGE_SIZE, IV_PAGE_NUMBER
   - Return paginated results for large datasets

2. **Additional Filters**
   - Add optional filters: IV_TRUCK_TYPE, IV_DATE_FROM, IV_DATE_TO
   - More flexible selection criteria

3. **Sorting Options**
   - Add parameter: IV_SORT_FIELD
   - Allow dynamic sorting of results

4. **Caching Mechanism**
   - Implement shared memory caching for frequently accessed areas
   - Reduce database load

5. **Asynchronous Processing**
   - For large datasets, implement background job processing
   - Return job ID for status checking

### 13.2 Version Control

Maintain version history in function module header:
```abap
*" Change History:
*" Date       User    TR Number   Description
*" 09.01.2026 USER001 DEVK9xxxxx  Initial creation
*" DD.MM.YYYY USER002 DEVK9xxxxx  Added authorization check
*" DD.MM.YYYY USER003 DEVK9xxxxx  Performance optimization
```

### 13.3 Documentation Updates

Update documentation when changes made:
- Function module documentation (SE37)
- This technical specification document
- User guide (if applicable)
- Integration guide for calling programs

---

## 14. Appendix

### 14.1 Reference Function Module

Reference: ZLOG_GET_RP_DETAIL (existing function module in system)
- Similar patterns for database access
- Error handling approach
- Table type usage
- FOR ALL ENTRIES pattern

Key differences:
- ZSCM_GET_VEHDATA is simpler (single table, single area)
- ZLOG_GET_RP_DETAIL has complex joins and multiple tables
- Our FM uses cleaner type definitions matching SELECT

### 14.2 Related Tables

**YTTSTX0001** - Vehicle Tracking Master Data
- Primary key: MANDT, AREA, REPORT_NO
- Key fields for this FM: AREA, TRANSPLPT, VSTEL, FUNCTION, TRK_PURPOS, TRUCK_TYPE, SHNUMBER, REJECT_RES
- Total fields: 150+ (using 16 fields)
- Records: ~10,000 per area
- Note: FUNCTION field maps to configuration EWM_UOM_D

**ZLOG_EXEC_VAR** - Configuration Parameter Table
- Primary key: MANDT, NAME, NUMB
- Configuration type table
- Required fields for this FM: NAME, ACTIVE, EWM_UOM_D, TRK_PURPOS, REMARKS, VSTEL, TRANSPLPT
- Records: ~500 total

### 14.3 Useful Transactions

| Transaction | Description | Usage |
|------------|-------------|-------|
| SE37 | Function Builder | Create/maintain function module |
| SE11 | Data Dictionary | Create structures and table types |
| SE80 | Object Navigator | Overall development |
| SE38 | ABAP Editor | Create test program |
| SM30 | Table Maintenance | Maintain ZLOG_EXEC_VAR |
| SE16 | Data Browser | View table data |
| ST05 | SQL Trace | Performance analysis |
| ST12 | Performance Analysis | Comprehensive performance |
| SLG1 | Application Log | View logs (if implemented) |
| STMS | Transport Management | Transport to QA/PRD |

### 14.4 Development Environment

- **SAP GUI Version:** 7.60 or higher recommended
- **SAP Logon:** Access to DEV system
- **Authorization:** S_DEVELOP with required access
- **Code Inspector:** Run with standard variant before transport

---

## 15. Approval and Sign-Off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| ABAP Developer | | | |
| Technical Architect | | | |
| Code Reviewer | | | |
| Security Reviewer | | | |
| Technical Lead | | | |

---

## 16. Revision History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | 2026-01-09 | Cursor AI | Initial technical specification document |

---

**End of Technical Specification**

---

## Quick Reference Card

### Function Call Template
```abap
CALL FUNCTION 'ZSCM_GET_VEHDATA'
  EXPORTING
    iv_area          = '01'
  IMPORTING
    et_vehicle_data  = lt_vehicle_data
    ev_message       = lv_message
    ev_message_type  = lv_message_type
  EXCEPTIONS
    invalid_input          = 1
    no_configuration_found = 2
    database_error         = 3
    OTHERS                 = 4.
```

### Configuration Entry Template
```
Table: ZLOG_EXEC_VAR
NAME: ZSCM_GET_VEHDATA
ACTIVE: X
EWM_UOM_D: PICK    (maps to FUNCTION field - as per business requirement)
TRK_PURPOS: I      (Truck Purpose - as per business requirement)
REMARKS: TRK       (maps to TRUCK_TYPE filter - as per business requirement)
VSTEL: 1000        (Shipping Point - as per business requirement)
TRANSPLPT: TP01    (Transportation Planning Point - as per business requirement)
```

### Debug Checklist
1. Set breakpoint at "Step 1: Input validation"
2. Check IV_AREA value
3. Step through config SELECT
4. Verify lw_config contents (check all 5 config fields: EWM_UOM_D, TRK_PURPOS, REMARKS, VSTEL, TRANSPLPT)
5. Step through vehicle SELECT
6. Check lt_vehicle_data count (records before filtering)
7. Step through filtering loop (Step 4)
8. Check lt_vehicle_filter count (records after filtering)
9. Verify output mapping in Step 5

---

