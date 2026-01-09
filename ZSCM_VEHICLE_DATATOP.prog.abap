*&---------------------------------------------------------------------*
*& Include ZSCM_VEHICLE_DATATOP
*&---------------------------------------------------------------------*
*& Function Group: ZSCM_VEHICLE_DATA
*& Purpose: Global type definitions for vehicle data function modules
*& Author: [Developer Name]
*& Creation Date: 09.01.2026
*& SAP Version: ECC 6.0 / NetWeaver 7.31
*"----------------------------------------------------------------------
*" Change History:
*" Date       User    TR Number   Description
*" 09.01.2026 USER001 DEVK9xxxxx  Initial creation - Type definitions
*"                                 for ZSCM_GET_VEHDATA function module
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
* Global Type Definitions
*----------------------------------------------------------------------*

" Structure for output vehicle data (14 fields)
TYPES: BEGIN OF gty_vehicle_output,
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
       END OF gty_vehicle_output.

" Table type for output vehicle data
TYPES: gty_vehicle_output_table TYPE STANDARD TABLE OF gty_vehicle_output.

" Structure for configuration parameters from ZLOG_EXEC_VAR
TYPES: BEGIN OF gty_config_param,
         name       TYPE rvari_vnam,      " Parameter name
         active     TYPE zactive_flag,    " Active flag
         remarks    TYPE textr,           " Remarks (used for TRUCK_TYPE filtering)
         trk_purpos TYPE ytrk_purps,      " Truck Purpose
         ewm_uom_d  TYPE txt30,           " EWM UOM (used for FUNCTION field)
         vstel      TYPE vstel,           " Shipping Point
         transplpt  TYPE tplst,           " Transportation Planning Point
       END OF gty_config_param.

" Structure for YTTSTX0001 selection (matching SELECT fields exactly)
" This structure matches the SELECT statement field order for optimal performance
TYPES: BEGIN OF gty_yttstx0001_select,
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
         function   TYPE ystats,          " Function code field
         vstel      TYPE vstel,           " Shipping Point
       END OF gty_yttstx0001_select.

" Table type for YTTSTX0001 data
TYPES: gty_yttstx0001_table TYPE STANDARD TABLE OF gty_yttstx0001_select.

*----------------------------------------------------------------------*
* Global Constants (if needed across function group)
*----------------------------------------------------------------------*
CONSTANTS: gc_fm_name TYPE rvari_vnam VALUE 'ZSCM_GET_VEHDATA'.

*----------------------------------------------------------------------*
* End of Include ZSCM_VEHICLE_DATATOP
*----------------------------------------------------------------------*

