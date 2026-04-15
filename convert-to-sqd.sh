#!/bin/bash
# Convert parsed ET NM10 obs CSV data to SmartMet querydata format.
#
# Usage:
#   ./convert-to-sqd.sh
#
# Reads site-specific configuration from /smartmet/cnf/data/et-nm10.cnf.
# Variables already exported in the environment take precedence over .cnf values.
#
# Configuration variables:
#   STATIONFILE   - path to stations CSV  (station_id, lat, lon, elevation, name, ...)
#   PARAMFILE     - path to parameters CSV mapping column index -> SmartMet parameter
#   OUT           - directory for final querydata output
#   EDITOR        - SmartMet editor inbox directory
#   PARAMS        - comma-separated SmartMet parameter names (must match nm10-params.txt order)
#   PRODNUM       - csv2qd product number
#   PRODNAME      - csv2qd product name

DATASET="et-nm10"

if [ -d /smartmet ]; then
    BASE=/smartmet
else
    BASE=$HOME
fi

# Load site-specific configuration
CNF=$BASE/cnf/data/${DATASET}.cnf
if [ -s "$CNF" ]; then
    # shellcheck source=/dev/null
    . "$CNF"
fi

TMP=$BASE/tmp/data/et-nm10
EDITOR=${EDITOR:-$BASE/editor/in}
LOGFILE=$BASE/logs/data/et-nm10.log

TIMESTAMP=$(date +%Y%m%d%H%M)

OUT=${OUT:-$BASE/data/et-nm10/querydata}
OBSFILE=$TMP/${TIMESTAMP}_et-nm10.sqd
STATIONFILE=${STATIONFILE:-$BASE/run/data/et-nm10/cnf/stations.csv}
PARAMFILE=${PARAMFILE:-$BASE/run/data/et-nm10/cnf/parameters.csv}
INFILE=$TMP/csv2qd_input_et-nm10.csv
# Must match order in nm10-params.txt
PARAMS=${PARAMS:-Temperature,Humidity,Pressure,DewPoint,WindSpeedMS,WindDirection,WindGust,Precipitation1h,Radiation}
PRODNUM=${PRODNUM:-1002}
PRODNAME=${PRODNAME:-NM10}

mkdir -p "$TMP" "$OUT"

# Redirect to log file when not run interactively
if [ "${TERM:-dumb}" = "dumb" ]; then
    exec &>> "$LOGFILE"
fi

echo "DATASET:  $DATASET"
echo "IN:       $INFILE"
echo "OUT:      $OUT"
echo "OBS file: $OBSFILE"

# Convert parsed CSV to querydata
csv2qd -v \
    --prodnum "$PRODNUM" \
    --prodname "$PRODNAME" \
    -S "$STATIONFILE" \
    -O idtime \
    -P "$PARAMFILE" \
    -p "$PARAMS" \
    "$INFILE" \
    "$OBSFILE"

# Compress and deliver
if [ -s "$OBSFILE" ]; then
    pbzip2 -k "$OBSFILE"
    mv -f "$OBSFILE" "$OUT/"
    mv -f "${OBSFILE}.bz2" "$EDITOR/"
fi

# Clean up intermediate file
rm -f "$INFILE"
