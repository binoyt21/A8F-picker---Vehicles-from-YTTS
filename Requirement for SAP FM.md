Requirement: To create a function module ZSCM_GET_VEHDATA to fetch vehicle data from YTTSTX0001 Table.



Input for the Function Module will be “AREA”

## Logic:

Fetch param entries from ZLOG_EXEC VAR – Pass ZSCM_GET_VEHDATA in NAME and “X” in ACTIVE fields.

Fetch fields “EWM_UOM_D” , “TRK_PURPOS” , “REMARKS”, "VSTEL", and "TRANSPLPT "

Pass AREA in AREA field of YTTSTX0001 table, TRANSPLPT in TRANSPLPT field of YTTSTX0001 table, VSTEL in VSTEL field of, EWM_UOM_D in FUNCTION field of YTTSTX0001 table, TRK_PURPOS in TRK_PURPOS field of YTTSTX0001. 

Fetch all entries

Filter the entries based on

REMARKS, where REMARKS = TRUCK_TYPE and SHNUMBER = “ ” (Blank) and REJECT_RES = “ ” (Blank).

Following fields from YTTSTX0001 to be displayed in output

## “AREA”

## “REPORT_NO”

## “TRUCK_NO”

## “TRANSPTRCD”

## “TRANSPLPT”

## “SHNUMBER”

## “STATUS”

## “REJECT_RES”

## “TRUCK_TYPE”

## “TRK_PURPOS”

## “VTWEG”

## “SPART”

## “MATGR”

## “TOTALQTY”