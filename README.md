# smartmet-data-et-nm10

Scripts for parsing and converting NM10 agrometeorology observation CSV files from the Estonian Environment Agency into SmartMet querydata format.

## Overview

This repository contains tools to:

1. **Parse** long-format NM10 observation CSV files into csv2qd-compatible wide format
2. **Convert** the parsed data into SmartMet querydata (SQD) format

## Input CSV format

Files are semicolon-delimited, all fields double-quoted, with no header row. This is the same format as `smartmet-data-et-obs`.

**Filename convention:** `observations_<station_id>_<start_time>-<end_time>.csv`

**Column layout:**

| Column | Field         | Example                                              |
|--------|---------------|------------------------------------------------------|
| 1      | station_id    | `34`                                                 |
| 2      | timestamp     | `2026-04-07T09:45:08.000`                            |
| 3      | param_name    | `SOIL_MOISTURE_PERCENT_MEAN_PT1M_0.2m_1`             |
| 4      | param_group   | `SOIL_MOISTURE`                                      |
| 5      | unit          | `PERCENT`                                            |
| 6      | value         | `50.3`                                               |
| 7      | height        | `0.2`                                                |
| 8      | agg_type      | `MEAN`                                               |
| 9      | period        | `PT1M`                                               |

Each row carries a single parameter value for one station and timestamp. This **long format** is pivoted to **wide format** (one row per station + timestamp, one column per parameter) before being handed to csv2qd.

### Key difference from NM10 ()

| Aspect          | NM10 ()                      | ET NM10                              |
|-----------------|-------------------------------------|--------------------------------------|
| Delimiter       | comma                               | semicolon                            |
| Structure       | key-value pairs on one line per file | one row per observation (long format)|
| Station/time    | encoded in filename                 | present in every data row            |
| Missing value   | `/`                                 | `-9999.9`, `9999.9`, `///`           |

## Scripts

### update.sh

**Must be customised per installation.**  Reads raw CSV files from `$MODEL_RAW_ROOT`, runs the parse pipeline, then calls `convert-to-sqd.sh`.

```bash
./update.sh
```

Requires a configuration file at `/smartmet/cnf/data/et-nm10.cnf` that exports at least:

```sh
MODEL_RAW_ROOT=/smartmet/tmp/data/et-nm10/raw
OUTDIR=/smartmet/tmp/data/et-nm10
```

### parse-et-nm10-csvtoqd.sh

Parses raw ET NM10 CSV files into csv2qd input format (wide format, one row per station + timestamp).

```bash
./parse-et-nm10-csvtoqd.sh nm10-params.txt observations_*.csv > csv2qd_input.csv
```

- Reads wanted parameter names from `nm10-params.txt` (column 3 values).
- Pivots from long format to wide format, grouping by station ID and timestamp.
- Replaces `-9999.9`, `9999.9`, and `///` with empty fields (csv2qd missing-value convention).
- Output columns: `station_id, YYYY-MM-DD HH:MM:SS, param1, param2, ...`

### convert-to-sqd.sh

Converts the parsed CSV to SmartMet querydata using `csv2qd`.

```bash
./convert-to-sqd.sh
```

Reads `/smartmet/cnf/data/et-nm10.cnf` and expects:
- `$STATIONFILE` – CSV file with station coordinates and identifiers
- `$PARAMFILE`   – CSV file mapping column index to SmartMet parameter number/name
- `$OUT`         – destination directory for querydata files
- `$EDITOR`      – SmartMet editor inbox directory

### nm10-params.txt

Lists the `param_name` values (CSV column 3) to extract, one per line. The order defines the column order in the csv2qd input and must match the `-p` parameter list in `convert-to-sqd.sh` and the SmartMet `parameters.csv` mapping.

Lines beginning with `#` and blank lines are ignored.

**Default parameter set:**

| param_name                                                        | SmartMet param     |
|-------------------------------------------------------------------|--------------------|
| `AIR_TEMPERATURE_DEGREES_CELSIUS_MEAN_PT1M_2m_1`                  | Temperature        |
| `RELATIVE_HUMIDITY_PERCENT_MEAN_PT1M_2m_1`                        | Humidity           |
| `AIR_PRESSURE_HECTO_PASCALS_MEAN_PT1M_2m_1`                       | Pressure           |
| `DEW_POINT_TEMPERATURE_DEGREES_CELSIUS_MEAN_PT1M_2m_1`            | DewPoint           |
| `WIND_SPEED_METRES_PER_SECOND_MEAN_PT1S_10m_1`                    | WindSpeedMS        |
| `WIND_DIRECTION_METRES_PER_SECOND_MEAN_PT1S_10m_1`                | WindDirection      |
| `WIND_GUST_SPEED_METRES_PER_SECOND_VALUE_PT15M_2m_1`              | WindGust           |
| `RAIN_ACCUMULATION_MILLIMETRES_SUM_PT15M_1m_1`                    | Precipitation1h    |
| `SHORT_WAVE_TOTAL_RADIATION_WATTS_PER_SQUARE_METRE_MAXIMUM_PT1H_2m_1` | Radiation      |
| `LEAF_WETNESS_NO_UNIT_MEAN_PT1H_2m_1`                             | LeafWetness        |
| `EVAPOTRANSPIRATION_MILLIMETRES_SUM_P1D_1`                        | Evapotranspiration |
| `SOIL_MOISTURE_PERCENT_MEAN_PT1M_0.2m_1`                          | SoilMoisture02m    |
| `SOIL_MOISTURE_PERCENT_MEAN_PT1M_0.5m_2`                          | SoilMoisture05m    |
| `SOIL_MOISTURE_PERCENT_MEAN_PT1M_1m_3`                            | SoilMoisture1m     |

## Configuration files

The following site-specific files are **not** included in this repository and must be created for each installation:

| File                                          | Contents                                      |
|-----------------------------------------------|-----------------------------------------------|
| `/smartmet/cnf/data/et-nm10.cnf`              | Path variables (see above)                    |
| `$BASE/run/data/et-nm10/cnf/stations.csv`     | Station list for csv2qd (`-S` flag)           |
| `$BASE/run/data/et-nm10/cnf/parameters.csv`   | Parameter mapping for csv2qd (`-P` flag)      |
