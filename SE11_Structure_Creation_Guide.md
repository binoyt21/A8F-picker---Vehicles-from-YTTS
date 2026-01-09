# SE11 Structure Creation Guide

## Dictionary Objects to Create

This guide provides step-by-step instructions to create the required dictionary objects for ZSCM_GET_VEHDATA function module.

---

## 1. Create Structure: ZSCM_S_VEHICLE_OUTPUT

**Transaction:** SE11  
**Object Type:** Structure  
**Name:** `ZSCM_S_VEHICLE_OUTPUT`  
**Short Description:** Vehicle Output Structure for ZSCM_GET_VEHDATA

### Step-by-Step Creation

1. Go to **SE11**
2. Select **Data Type** radio button
3. Enter: `ZSCM_S_VEHICLE_OUTPUT`
4. Click **Create**
5. Select **Structure**
6. Click **Continue**
7. Enter short description: `Vehicle Output Structure for ZSCM_GET_VEHDATA`

### Field Definitions

Copy and paste these fields into the structure:

| Position | Component  | Typing Method | Component Type | Data Type | Length | Decimals | Short Description |
|----------|-----------|---------------|----------------|-----------|--------|----------|-------------------|
| 1 | AREA | Data Element | YAREA | CHAR | 2 | 0 | Area of Location - TTS |
| 2 | REPORT_NO | Data Element | YREPORT_NO | CHAR | 10 | 0 | Truck Reporting Serial Id |
| 3 | TRUCK_NO | Data Element | YTRUCK_NO | CHAR | 15 | 0 | Truck Number |
| 4 | TRANSPTRCD | Data Element | LIFNR | CHAR | 10 | 0 | Account Number of Vendor or Creditor |
| 5 | TRANSPLPT | Data Element | TPLST | CHAR | 4 | 0 | Transportation planning point |
| 6 | SHNUMBER | Data Element | OIG_SHNUM | CHAR | 10 | 0 | TD shipment number |
| 7 | STATUS | Data Element | STATUV_TXT | CHAR | 4 | 0 | Text for the status of operation |
| 8 | REJECT_RES | Data Element | YREASONCD | CHAR | 3 | 0 | Reason code for TTS |
| 9 | TRUCK_TYPE | Data Element | YTRKTYPE | CHAR | 3 | 0 | Truck type |
| 10 | TRK_PURPOS | Data Element | YTRK_PURPS | CHAR | 1 | 0 | Truck Purpose |
| 11 | VTWEG | Data Element | VTWEG | CHAR | 2 | 0 | Distribution Channel |
| 12 | SPART | Data Element | SPART | CHAR | 2 | 0 | Division |
| 13 | MATGR | Data Element | MVGR1 | CHAR | 3 | 0 | Material group 1 |
| 14 | TOTALQTY | Data Element | YIG_CMPQUA | QUAN | 12 | 3 | Compartment Quantity |

### SE11 Screen Input Format

```
Structure: ZSCM_S_VEHICLE_OUTPUT
Short Description: Vehicle Output Structure for ZSCM_GET_VEHDATA

Component      Type      Data Element    Data Type  Length  Decimals
------------------------------------------------------------------
AREA           [●]       YAREA          CHAR       2       0
REPORT_NO      [●]       YREPORT_NO     CHAR       10      0
TRUCK_NO       [●]       YTRUCK_NO      CHAR       15      0
TRANSPTRCD     [●]       LIFNR          CHAR       10      0
TRANSPLPT      [●]       TPLST          CHAR       4       0
SHNUMBER       [●]       OIG_SHNUM      CHAR       10      0
STATUS         [●]       STATUV_TXT     CHAR       4       0
REJECT_RES     [●]       YREASONCD      CHAR       3       0
TRUCK_TYPE     [●]       YTRKTYPE       CHAR       3       0
TRK_PURPOS     [●]       YTRK_PURPS     CHAR       1       0
VTWEG          [●]       VTWEG          CHAR       2       0
SPART          [●]       SPART          CHAR       2       0
MATGR          [●]       MVGR1          CHAR       3       0
TOTALQTY       [●]       YIG_CMPQUA     QUAN       12      3

[●] = Radio button for "Data Element" typing method
```

### Actions
1. Click **Save**
2. Assign to development class (e.g., `ZSCM` or `$TMP` for local)
3. Click **Activate** (Ctrl+F3)

---

## 2. Create Table Type: ZSCM_TT_VEHICLE_OUTPUT

**Transaction:** SE11  
**Object Type:** Table Type  
**Name:** `ZSCM_TT_VEHICLE_OUTPUT`  
**Short Description:** Vehicle Output Table Type

### Step-by-Step Creation

1. Go to **SE11**
2. Select **Data Type** radio button
3. Enter: `ZSCM_TT_VEHICLE_OUTPUT`
4. Click **Create**
5. Select **Table Type**
6. Click **Continue**

### Configuration

```
Table Type: ZSCM_TT_VEHICLE_OUTPUT
Short Description: Vehicle Output Table Type for ZSCM_GET_VEHDATA

Line Type:
  [●] Name of Row Type: ZSCM_S_VEHICLE_OUTPUT
  
Access:
  [●] Standard table
  
Initial Size:
  (leave empty or enter: 10)
  
Initialization and Access:
  [●] Not Unique
  
Key Definition:
  [ ] With Unique Key
  [ ] With Non-Unique Key
  [●] Standard Key
```

### Detailed Settings

| Setting | Value |
|---------|-------|
| **Line Type** | ZSCM_S_VEHICLE_OUTPUT |
| **Category** | Structure |
| **Access** | Standard table |
| **Key Type** | Non-unique |
| **Key Definition** | Standard key |
| **Initial Size** | 10 (optional) |

### Actions
1. Click **Save**
2. Assign to development class (e.g., `ZSCM` or `$TMP` for local)
3. Click **Activate** (Ctrl+F3)

---

## 3. Alternative: If Data Elements Don't Exist

If some of the data elements (YAREA, YREPORT_NO, etc.) don't exist in your system, you have two options:

### Option A: Use Direct Types (Not Recommended)

Instead of using data elements, use direct types in the structure:

| Component | Typing Method | Type | Length | Decimals |
|-----------|---------------|------|--------|----------|
| AREA | Types | CHAR | 2 | 0 |
| REPORT_NO | Types | CHAR | 10 | 0 |
| TRUCK_NO | Types | CHAR | 15 | 0 |
| TRANSPTRCD | Types | CHAR | 10 | 0 |
| TRANSPLPT | Types | CHAR | 4 | 0 |
| SHNUMBER | Types | CHAR | 10 | 0 |
| STATUS | Types | CHAR | 4 | 0 |
| REJECT_RES | Types | CHAR | 3 | 0 |
| TRUCK_TYPE | Types | CHAR | 3 | 0 |
| TRK_PURPOS | Types | CHAR | 1 | 0 |
| VTWEG | Types | CHAR | 2 | 0 |
| SPART | Types | CHAR | 2 | 0 |
| MATGR | Types | CHAR | 3 | 0 |
| TOTALQTY | Types | QUAN | 12 | 3 |

### Option B: Create Missing Data Elements (Recommended)

If custom data elements (Y*) don't exist, create them first:

#### Example: Create YAREA Data Element

```
Transaction: SE11

Data Element: YAREA
Short Description: Area of Location - TTS

Domain: Create new domain YAREA_DOM
  Data Type: CHAR
  Length: 2
  Output Length: 2
  
Field Label:
  Short (10): Area
  Medium (20): Area Location
  Long (40): Area of Location - TTS
  Heading (55): Area of Location
```

**Note:** Standard SAP data elements (LIFNR, VTWEG, SPART, MVGR1, etc.) should already exist in your system.

---

## 4. Verification Steps

After creating both objects, verify:

### Check Structure
```
SE11 → Display Structure → ZSCM_S_VEHICLE_OUTPUT
- Should show 14 components
- All fields should be green (active)
```

### Check Table Type
```
SE11 → Display Table Type → ZSCM_TT_VEHICLE_OUTPUT
- Line Type should show ZSCM_S_VEHICLE_OUTPUT
- Access should be "Standard table"
```

### Test in ABAP Program
```abap
DATA: lt_vehicles TYPE zscm_tt_vehicle_output,
      lw_vehicle TYPE zscm_s_vehicle_output.

lw_vehicle-area = '01'.
lw_vehicle-truck_no = 'TEST123'.
APPEND lw_vehicle TO lt_vehicles.

WRITE: / 'Test successful - structure exists and works'.
```

---

## 5. Quick Copy-Paste Script (SE37)

For function module interface definition:

### Importing Parameters
```
Parameter Name    Type            Associated Type
IV_AREA          TYPE            YAREA
```

### Exporting Parameters
```
Parameter Name        Type        Associated Type
ET_VEHICLE_DATA      TYPE        ZSCM_TT_VEHICLE_OUTPUT
EV_MESSAGE           TYPE        CHAR100
EV_MESSAGE_TYPE      TYPE        CHAR1
```

### Exceptions
```
INVALID_INPUT
NO_CONFIGURATION_FOUND
DATABASE_ERROR
```

---

## 6. Transport Information

After creation, add to transport request:

```
Transaction: SE09/SE10

Objects to include:
1. TABL ZSCM_S_VEHICLE_OUTPUT        (Structure)
2. TTYP ZSCM_TT_VEHICLE_OUTPUT       (Table Type)
3. FUGR ZSCM_VEHICLE_DATA            (Function Group)
4. FUNC ZSCM_GET_VEHDATA             (Function Module)
5. PROG ZTEST_SCM_GET_VEHDATA        (Test Program)
```

---

## 7. Troubleshooting

### Error: "Data element YAREA does not exist"

**Solution 1:** Use existing similar data element
- Replace YAREA with CHAR2 (direct type)
- Or find similar 2-character area field in your system

**Solution 2:** Create the data element
- SE11 → Data Element → Create
- Follow Option B above

### Error: "Structure already exists"

**Solution:** The structure might exist in inactive state
- SE11 → Display → Activate
- Or delete and recreate

### Error: "Table type cannot be created"

**Solution:** Structure must be activated first
1. Activate ZSCM_S_VEHICLE_OUTPUT
2. Then create ZSCM_TT_VEHICLE_OUTPUT

---

## 8. Data Element Mapping Reference

If you need to substitute data elements, use this mapping:

| Required DE | Standard SAP DE | Direct Type Alternative |
|-------------|-----------------|------------------------|
| YAREA | N/A | CHAR(2) |
| YREPORT_NO | N/A | CHAR(10) |
| YTRUCK_NO | N/A | CHAR(15) |
| LIFNR | LIFNR ✓ | CHAR(10) |
| TPLST | TPLST ✓ | CHAR(4) |
| OIG_SHNUM | OIG_SHNUM ✓ | CHAR(10) |
| STATUV_TXT | STATUV_TXT ✓ | CHAR(4) |
| YREASONCD | N/A | CHAR(3) |
| YTRKTYPE | N/A | CHAR(3) |
| YTRK_PURPS | N/A | CHAR(1) |
| VTWEG | VTWEG ✓ | CHAR(2) |
| SPART | SPART ✓ | CHAR(2) |
| MVGR1 | MVGR1 ✓ | CHAR(3) |
| YIG_CMPQUA | N/A | QUAN(12,3) |

✓ = Standard SAP data element (should exist)
N/A = Custom data element (may need creation)

---

## 9. Complete SE11 Creation Script

For quick reference, here's the complete sequence:

```
Step 1: SE11 → Data Type → ZSCM_S_VEHICLE_OUTPUT → Create → Structure
        Add 14 components (see table above)
        Save → Activate

Step 2: SE11 → Data Type → ZSCM_TT_VEHICLE_OUTPUT → Create → Table Type
        Line Type: ZSCM_S_VEHICLE_OUTPUT
        Access: Standard table
        Save → Activate

Step 3: SE37 → Function Group → ZSCM_VEHICLE_DATA → Create
        
Step 4: SE37 → Function Module → ZSCM_GET_VEHDATA → Create
        Add interface parameters (see section 5)
        Copy code from ZSCM_GET_VEHDATA.fugr.abap
        Save → Activate

Step 5: SE38 → ZTEST_SCM_GET_VEHDATA → Create
        Copy code from ZTEST_SCM_GET_VEHDATA.prog.abap
        Save → Activate
```

---

## 10. Screenshots Location Guide

When in SE11, your screen should look like:

### Structure Definition Screen
```
┌─────────────────────────────────────────────────────────────┐
│ Dictionary: Change Structure                                │
├─────────────────────────────────────────────────────────────┤
│ Structure: ZSCM_S_VEHICLE_OUTPUT                           │
│ Short Desc: Vehicle Output Structure for ZSCM_GET_VEHDATA  │
│                                                             │
│ Components:                                                 │
│ ┌────────────────────────────────────────────────────────┐│
│ │Comp.   Type  Component Type    Data Type  Len  Dec    ││
│ │AREA    [●]   YAREA            CHAR       2    0       ││
│ │REPORT_ [●]   YREPORT_NO       CHAR       10   0       ││
│ │...                                                     ││
│ └────────────────────────────────────────────────────────┘│
│                                                             │
│ [Save] [Activate] [Check] [Display↔Change]                │
└─────────────────────────────────────────────────────────────┘
```

---

**Need Help?** 
- If data elements don't exist, use direct types (Option A in Section 3)
- Contact your ABAP Basis team for creating custom domains/data elements
- Check YTTSTX0001 table structure in SE11 to verify data element names

---

**Created:** January 9, 2026  
**For Project:** ZSCM_GET_VEHDATA  
**SAP Version:** ECC 6.0 / NetWeaver 7.31

