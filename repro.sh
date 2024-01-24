#!/bin/sh
set -eu

# Initialize variables with default values
RG=""
SUBSCRIPTION_ID=""
AZML_WORKSPACE=""

# Define help function
function print_help {
  echo "Usage: $0 --rg RG --subscription-id SUBSCRIPTION_ID --azml-workspace AZML_WORKSPACE"
  echo
  echo "Arguments:"
  echo "  --rg                  Resource group"
  echo "  --subscription-id     Subscription ID"
  echo "  --azml-workspace      Azure ML Workspace"
  echo "  --help                Display this help message"
  exit 0
}

# Parse command line arguments
OPTIONS=$(getopt -o h --long rg:,subscription-id:,azml-workspace:,help -- "$@")
eval set -- "$OPTIONS"

while true; do
  case "$1" in
    --rg)
      RG=$2
      shift 2
      ;;
    --subscription-id)
      SUBSCRIPTION_ID=$2
      shift 2
      ;;
    --azml-workspace)
      AZML_WORKSPACE=$2
      shift 2
      ;;
    --help)
      print_help
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Error: Unexpected option $1"
      exit 1
      ;;
  esac
done

echo "RG: $RG"
echo "SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo "AZML_WORKSPACE: $AZML_WORKSPACE"


echo "Attempt 1a: flows-noinclude/code_gen - works when requirements.txt is in the local directory"
pfazure run create --subscription "$SUBSCRIPTION_ID" -g "$RG" -w "$AZML_WORKSPACE" --flow flows-noinclude/code_gen --data flows/code_gen/data.jsonl --stream

echo "Attempt 1b: flows-noinclude/code_gen - fails when requirements.txt is in the local directory with some extra packages"
cp flows/requirements.txt flows-noinclude/code_gen/
pfazure run create --subscription "$SUBSCRIPTION_ID" -g "$RG" -w "$AZML_WORKSPACE" --flow flows-noinclude/code_gen --data flows/code_gen/data.jsonl --stream

echo "Attempt 2: flows/code_gen - fails when requirements.txt is copied into the directory from includes, job stays in NotStarted status"
pfazure run create --subscription "$SUBSCRIPTION_ID" -g "$RG" -w "$AZML_WORKSPACE" --flow flows/code_gen --data flows/code_gen/data.jsonl --stream

echo "Attempt 3: flows/code_gen - all subsequent jobs fail until automatic runtime compute is cleaned up (>1.5h in my experience)"
pfazure run create --subscription "$SUBSCRIPTION_ID" -g "$RG" -w "$AZML_WORKSPACE" --flow flows/code_gen --data flows/code_gen/data.jsonl --stream

echo "Confirm packages in requirements.txt can be resolved by pip"
python3 -m venv .env
. .env/bin/activate
pip install -r flows/requirements.txt
deactivate