#!/bin/sh
# Main update script for the ET NM10 data pipeline.
#
# Processes NM10 agrometeorology observation CSV files from the Estonian
# Environment Agency into csv2qd input format, then calls convert-to-sqd.sh
# to produce querydata.
#
# Requires a site-specific configuration file that exports at minimum:
#   MODEL_RAW_ROOT  - directory containing the raw observation CSV files
#   OUTDIR          - directory where intermediate csv2qd input files are written
#
# Optional variables (with defaults shown):
#   NM10_PARAMS     - path to params file (default: <script dir>/nm10-params.txt)
#
# Example configuration file (/smartmet/cnf/data/et-nm10.cnf):
#   MODEL_RAW_ROOT=/smartmet/data/incoming/local_obs2
#   OUTDIR=/smartmet/tmp/data/et-nm10

set -eu

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"

# Load site-specific configuration (system path first, project default as fallback)
CNF=/smartmet/cnf/data/et-nm10.cnf
if [ ! -s "$CNF" ]; then
    CNF="${SCRIPTDIR}/cnf/et-nm10.cnf"
fi
if [ -s "$CNF" ]; then
    # shellcheck source=/dev/null
    . "$CNF"
fi

NM10_PARAMS="${NM10_PARAMS:-${SCRIPTDIR}/nm10-params.txt}"

mkdir -p "$OUTDIR"

NM10_OUT="$OUTDIR/csv2qd_input_aws.csv"
: > "$NM10_OUT"

echo "Processing ET NM10 CSV files from: $MODEL_RAW_ROOT" >&2

find "$MODEL_RAW_ROOT" -maxdepth 1 -type f -name 'observations_*.csv' -print0 \
    | sort -z \
    | xargs -0 -r -n 100 bash "${SCRIPTDIR}/parse-et-nm10-csvtoqd.sh" "$NM10_PARAMS" \
    >> "$NM10_OUT"

echo "NM10 parsed output written to: $NM10_OUT" >&2
bash "${SCRIPTDIR}/convert-to-sqd.sh"
