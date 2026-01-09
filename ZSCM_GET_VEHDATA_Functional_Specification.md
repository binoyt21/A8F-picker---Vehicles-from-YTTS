# Functional Specification: ZSCM_GET_VEHDATA

**Document Version:** 1.0  
**Date:** January 9, 2026  
**Function Module:** ZSCM_GET_VEHDATA  
**Purpose:** Fetch vehicle data from YTTSTX0001 table based on area and parameter configuration  

---

## 1. Overview

### 1.1 Business Objective
This function module retrieves vehicle records from the truck tracking system (YTTSTX0001) for a specified area. The function applies dynamic filtering based on configuration parameters stored in ZLOG_EXEC_VAR table to provide flexible vehicle data extraction for warehouse and logistics operations.

### 1.2 Scope
- Retrieve vehicle data for specific areas
- Apply dynamic filtering based on configuration parameters
- Filter out vehicles that are already assigned to shipments or have rejection reasons
- Return comprehensive vehicle information including truck details, transportation codes, and material classifications

---

## 2. Function Module Interface

### 2.1 Import Parameters

| Parameter Name | Type | Data Element | Required | Description |
|---------------|------|--------------|----------|-------------|
| IV_AREA | CHAR(2) | YAREA | Yes | Area of Location - TTS (Transportation Tracking System) |

**Validation Rules:**
- IV_AREA must not be initial
- IV_AREA should be a valid area code (2 characters)
- If IV_AREA is initial, function should raise an error or return empty results

### 2.2 Export Parameters

| Parameter Name | Type | Structure | Description |
|---------------|------|-----------|-------------|
| ET_VEHICLE_DATA | Table | TY_VEHICLE_OUTPUT | Internal table containing filtered vehicle records |
| EV_MESSAGE | CHAR(100) | - | Success/Error message |
| EV_MESSAGE_TYPE | CHAR(1) | - | Message type: 'S' (Success), 'E' (Error), 'W' (Warning) |

### 2.3 Export Table Structure (TY_VEHICLE_OUTPUT)

| Field Name | Data Type | Data Element | Length | Description |
|-----------|-----------|--------------|--------|-------------|
| AREA | CHAR | YAREA | 2 | Area of Location |
| REPORT_NO | CHAR | YREPORT_NO | 10 | Truck Reporting Serial ID |
| TRUCK_NO | CHAR | YTRUCK_NO | 15 | Truck Number |
| TRANSPTRCD | CHAR | LIFNR | 10 | Transporter Code (Vendor Number) |
| TRANSPLPT | CHAR | TPLST | 4 | Transportation Planning Point |
| SHNUMBER | CHAR | OIG_SHNUM | 10 | TD Shipment Number |
| STATUS | CHAR | STATUV_TXT | 4 | Status of Vehicle |
| REJECT_RES | CHAR | YREASONCD | 3 | Rejection Reason Code |
| TRUCK_TYPE | CHAR | YTRKTYPE | 3 | Truck Type |
| TRK_PURPOS | CHAR | YTRK_PURPS | 1 | Truck Purpose |
| VTWEG | CHAR | VTWEG | 2 | Distribution Channel |
| SPART | CHAR | SPART | 2 | Division |
| MATGR | CHAR | MVGR1 | 3 | Material Group 1 |
| TOTALQTY | QUAN | YIG_CMPQUA | 12,3 | Compartment Quantity |

---

## 3. Business Logic

### 3.1 Processing Flow

**Step 1: Input Validation**
- Validate that IV_AREA is not initial
- If validation fails, set EV_MESSAGE_TYPE = 'E' and return with appropriate error message

**Step 2: Fetch Configuration Parameters**
- Query ZLOG_EXEC_VAR table with the following conditions:
  - NAME = 'ZSCM_GET_VEHDATA'
  - ACTIVE = 'X' (Active flag)
- Retrieve the following fields:
  - EWM_UOM_D (to be used in FUNCTION field filter)
  - TRK_PURPOS (Truck Purpose filter)
  - REMARKS (to be used for TRUCK_TYPE filtering in step 4)
  - VSTEL (Shipping Point filter)
  - TRANSPLPT (Transportation Planning Point filter)
- If no active configuration found, set EV_MESSAGE_TYPE = 'E' and return with error message

**Step 3: Query Vehicle Data**
- SELECT from YTTSTX0001 table with the following conditions:
  - WHERE AREA = IV_AREA (Import parameter)
  - AND TRANSPLPT = TRANSPLPT (From config table - Transportation Planning Point)
  - AND VSTEL = VSTEL (From config table - Shipping Point)
  - AND FUNCTION = EWM_UOM_D (From config table - Function code)
  - AND TRK_PURPOS = TRK_PURPOS (From config table - Truck Purpose)
- Fetch all matching entries into internal table

**Step 4: Filter Retrieved Data**
- Filter the internal table results with the following conditions:
  - TRUCK_TYPE = REMARKS (From config table)
  - AND SHNUMBER = ' ' (Blank - Not assigned to any shipment)
  - AND REJECT_RES = ' ' (Blank - No rejection reason)
- Keep only records that meet all three filter conditions

**Step 5: Populate Output Table**
- For each filtered record, populate ET_VEHICLE_DATA with the 14 specified fields
- If records found after filtering, set:
  - EV_MESSAGE_TYPE = 'S'
  - EV_MESSAGE = 'Vehicle data retrieved successfully. X records found.' (X = number of records)
- If no records found after filtering, set:
  - EV_MESSAGE_TYPE = 'W'
  - EV_MESSAGE = 'No vehicle data found for the specified area and criteria.'

### 3.2 Business Rules

1. **Active Configuration Rule**: Only active parameter entries (ACTIVE = 'X') from ZLOG_EXEC_VAR should be used
2. **Shipment Assignment Rule**: Exclude vehicles already assigned to shipments (SHNUMBER IS NOT INITIAL)
3. **Rejection Rule**: Exclude vehicles with rejection reasons (REJECT_RES IS NOT INITIAL)
4. **Area-Based Filtering**: Only vehicles from the specified area should be retrieved
5. **Multi-Criteria Filtering**: All configuration parameters (FUNCTION, TRK_PURPOS, TRANSPLPT, VSTEL) must match in database query
6. **Two-Stage Filtering**: First query with 5 WHERE conditions, then filter in memory by TRUCK_TYPE, SHNUMBER, REJECT_RES

---

## 4. Error Handling

### 4.1 Error Scenarios

| Error Code | Error Message | Trigger Condition | Severity |
|-----------|---------------|-------------------|----------|
| E001 | Input parameter IV_AREA is mandatory | IV_AREA is initial | Error |
| E002 | No active configuration found for function module ZSCM_GET_VEHDATA | No records in ZLOG_EXEC_VAR with NAME = 'ZSCM_GET_VEHDATA' and ACTIVE = 'X' | Error |
| E003 | Database error while fetching configuration parameters | Database exception during ZLOG_EXEC_VAR query | Error |
| E004 | Database error while fetching vehicle data | Database exception during YTTSTX0001 query | Error |
| W001 | No vehicle data found for area &1 | No matching records found in YTTSTX0001 | Warning |

### 4.2 Exception Handling

- All database operations should be wrapped in TRY-CATCH blocks
- Database exceptions should be caught and converted to meaningful error messages
- Function should not terminate abruptly; always return with appropriate message type

---

## 5. Success Criteria

### 5.1 Successful Execution
- Input parameter IV_AREA is valid
- Active configuration exists in ZLOG_EXEC_VAR
- Vehicle data successfully retrieved from YTTSTX0001
- ET_VEHICLE_DATA populated with matching records
- EV_MESSAGE_TYPE = 'S'
- EV_MESSAGE contains success message with record count

### 5.2 Response Structure
```
ET_VEHICLE_DATA: Internal table with 0 to N records
EV_MESSAGE: "Vehicle data retrieved successfully. 5 records found."
EV_MESSAGE_TYPE: "S"
```

---

## 6. Edge Cases

### 6.1 No Configuration Data
**Scenario:** ZLOG_EXEC_VAR table has no active entry for ZSCM_GET_VEHDATA  
**Handling:** Return error message E002, empty output table, EV_MESSAGE_TYPE = 'E'

### 6.2 No Matching Vehicles
**Scenario:** Configuration exists but no vehicles match all criteria  
**Handling:** Return warning message W001, empty output table, EV_MESSAGE_TYPE = 'W'

### 6.3 All Vehicles Have Shipments
**Scenario:** All vehicles in the area have non-blank SHNUMBER  
**Handling:** Return warning message indicating no available vehicles, EV_MESSAGE_TYPE = 'W'

### 6.4 All Vehicles Have Rejections
**Scenario:** All vehicles in the area have non-blank REJECT_RES  
**Handling:** Return warning message indicating no valid vehicles, EV_MESSAGE_TYPE = 'W'

### 6.5 Multiple Configuration Entries
**Scenario:** Multiple active entries exist in ZLOG_EXEC_VAR for ZSCM_GET_VEHDATA  
**Handling:** Use the first record retrieved (consider sorting by CHANGED_ON descending if available)

### 6.6 Partial Match on Database Query
**Scenario:** Records match database criteria (AREA, TRANSPLPT, VSTEL, FUNCTION, TRK_PURPOS) but fail memory filter (TRUCK_TYPE, SHNUMBER, REJECT_RES)  
**Handling:** Return warning message indicating no matching vehicles after filtering, EV_MESSAGE_TYPE = 'W'

### 6.7 Invalid Area Code
**Scenario:** IV_AREA contains invalid or non-existent area code  
**Handling:** Return warning with no records found (database will return empty result set)

### 6.8 Missing Configuration Fields
**Scenario:** Configuration entry exists but one or more required fields (EWM_UOM_D, TRK_PURPOS, REMARKS, VSTEL, TRANSPLPT) are blank  
**Handling:** Return error indicating incomplete configuration, EV_MESSAGE_TYPE = 'E'

---

## 7. Dependencies

### 7.1 Database Tables
- **ZLOG_EXEC_VAR** - Configuration parameter table
  - Required fields: NAME, ACTIVE, REMARKS, TRK_PURPOS, EWM_UOM_D, VSTEL, TRANSPLPT
  - Condition: Must have active entry for function module
- **YTTSTX0001** - Vehicle tracking master data table
  - Required fields: 14 fields listed in output structure
  - Key filter fields: AREA, TRANSPLPT, VSTEL, FUNCTION, TRK_PURPOS, TRUCK_TYPE, SHNUMBER, REJECT_RES
  - Condition: Must be accessible with read authorization

### 7.2 Authorization Objects
- S_TABU_DIS - Authorization for table display (both tables)
- Custom authorization object for area-based data access (if implemented)

### 7.3 External Dependencies
- None (standalone function module)

---

## 8. Performance Considerations

### 8.1 Expected Volume
- Configuration table: 1 record per function call
- Vehicle table: Estimated 10-1000 records per area
- Response time target: < 1 second for up to 1000 records

### 8.2 Performance Optimization
- Use SELECT with specific field list (no SELECT *)
- Add database indexes on YTTSTX0001:
  - Primary index: AREA, REPORT_NO
  - Secondary index (recommended): AREA, TRANSPLPT, VSTEL, FUNCTION, TRK_PURPOS
- Use buffering for ZLOG_EXEC_VAR if frequently accessed
- Memory filtering for TRUCK_TYPE, SHNUMBER, REJECT_RES to reduce database load

### 8.3 Resource Constraints
- Maximum internal table size: 50,000 records (safety limit)
- If more records expected, implement pagination or additional filters

---

## 9. Security

### 9.1 Authorization Checks
- Check authorization for IV_AREA before data retrieval (if area-based security implemented)
- Verify user has read access to ZLOG_EXEC_VAR and YTTSTX0001 tables

### 9.2 Data Access
- Read-only access to database tables
- No data modification
- No sensitive data masking required (vehicle data is operational)

### 9.3 Logging
- Log function module calls for audit purposes (optional)
- Log errors and exceptions for debugging

---

## 10. Testing Requirements

### 10.1 Unit Test Cases

| Test ID | Test Description | Input | Expected Output | Priority |
|---------|-----------------|-------|-----------------|----------|
| UT-001 | Happy path with valid area and configuration | IV_AREA = '01' | ET_VEHICLE_DATA populated, EV_MESSAGE_TYPE = 'S' | High |
| UT-002 | Invalid area (initial value) | IV_AREA = '' | Empty output, EV_MESSAGE_TYPE = 'E', Error E001 | High |
| UT-003 | No active configuration | IV_AREA = '01', No config | Empty output, EV_MESSAGE_TYPE = 'E', Error E002 | High |
| UT-004 | No matching vehicles | IV_AREA = '99' | Empty output, EV_MESSAGE_TYPE = 'W', Warning W001 | Medium |
| UT-005 | All vehicles have shipments | IV_AREA = '01', All SHNUMBER not blank | Empty output, EV_MESSAGE_TYPE = 'W' | Medium |
| UT-006 | All vehicles have rejections | IV_AREA = '01', All REJECT_RES not blank | Empty output, EV_MESSAGE_TYPE = 'W' | Medium |
| UT-007 | Multiple config entries | IV_AREA = '01', Multiple active configs | ET_VEHICLE_DATA populated, use first config | Low |
| UT-008 | Large dataset (1000+ records) | IV_AREA with many vehicles | All records retrieved, performance < 1s | Medium |
| UT-009 | Database connection error | Simulate DB error | EV_MESSAGE_TYPE = 'E', Error E003/E004 | High |
| UT-010 | Partial data in config table | Missing TRK_PURPOS or REMARKS | Handle gracefully or error | Medium |

### 10.2 Integration Test Cases

| Test ID | Test Description | Scenario | Expected Result |
|---------|-----------------|----------|-----------------|
| IT-001 | End-to-end with real data | Call FM from report/program | Data retrieved successfully |
| IT-002 | RFC call simulation | Call FM remotely | Same behavior as local call |
| IT-003 | Concurrent access | Multiple users call FM simultaneously | No data inconsistency |
| IT-004 | Authorization check | User without table access | Authorization error |

### 10.3 Performance Test Cases

| Test ID | Test Description | Volume | Expected Performance |
|---------|-----------------|--------|---------------------|
| PT-001 | Small dataset | 10 records | < 0.1 seconds |
| PT-002 | Medium dataset | 500 records | < 0.5 seconds |
| PT-003 | Large dataset | 5000 records | < 2 seconds |

---

## 11. Documentation Requirements

### 11.1 Function Module Documentation
- ABAP Doc comments for function module
- Parameter descriptions in function builder
- Example usage in function module documentation

### 11.2 User Documentation
- Business process documentation for vehicle data retrieval
- Configuration guide for ZLOG_EXEC_VAR parameter setup
- Error message catalog with resolution steps

---

## 12. Implementation Notes

### 12.1 Configuration Setup
Before using this function module, the following configuration must be completed:

1. Create entry in ZLOG_EXEC_VAR table:
   - NAME = 'ZSCM_GET_VEHDATA'
   - ACTIVE = 'X'
   - EWM_UOM_D = [Desired function code - maps to FUNCTION field]
   - TRK_PURPOS = [Desired truck purpose]
   - REMARKS = [Desired truck type - used for filtering]
   - VSTEL = [Desired shipping point]
   - TRANSPLPT = [Desired transportation planning point]

### 12.2 Table Maintenance
- ZLOG_EXEC_VAR: Maintain via SM30 or custom maintenance view
- YTTSTX0001: Source data maintained by TTS application

### 12.3 Future Enhancements (Out of Scope)
- Add pagination support for large result sets
- Add additional filter parameters (date range, truck type, etc.)
- Implement result caching for frequently accessed areas
- Add sorting options for output data

---

## 13. Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Business Analyst | | | |
| Technical Lead | | | |
| Quality Assurance | | | |
| Project Manager | | | |

---

## 14. Revision History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | 2026-01-09 | Cursor AI | Initial functional specification |

---

**End of Functional Specification**

