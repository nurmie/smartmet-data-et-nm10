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

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"

# Load site-specific configuration (system path first, project default as fallback)
CNF=$BASE/cnf/data/${DATASET}.cnf
if [ ! -s "$CNF" ]; then
    CNF="${SCRIPTDIR}/cnf/${DATASET}.cnf"
fi
if [ -s "$CNF" ]; then
    # shellcheck source=/dev/null
    . "$CNF"
fi

TMP=$BASE/tmp/data/et-nm10
EDITOR=${EDITOR:-$BASE/editor/in}
LOGFILE=$BASE/logs/data/aws.log

TIMESTAMP=$(date +%Y%m%d%H%M)

OUT=${OUT:-$BASE/data/aws/querydata}
OBSFILE=$TMP/${TIMESTAMP}_aws.sqd
STATIONFILE=${STATIONFILE:-$BASE/run/data/aws/cnf/stations.csv}
PARAMFILE=${PARAMFILE:-$BASE/run/data/aws/cnf/parameters.csv}
INFILE=$TMP/csv2qd_input_aws.csv
# Must match order in nm10-params.txt
PARAMS=${PARAMS:-Temperature,Humidity,Pressure,DewPoint,WindSpeedMS,WindDirection,WindGust,Precipitation1h}
PRODNUM=${PRODNUM:-1001}
PRODNAME=${PRODNAME:-SYNOP}

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
