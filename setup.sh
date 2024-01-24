#!/bin/sh
set -eu

create_flows() {
  FLOWS_DIR="$1"
  mkdir "$FLOWS_DIR"
  pushd "$FLOWS_DIR"
  pf flow create --type standard --flow code_gen
  pf flow create --type standard --flow eval
  popd
}

# Create flows that copy requirements.txt from parent directory
create_flows flows
rm flows/*/requirements.txt
for flow in flows/*/flow.dag.yml; do
  cat <<EOF >>"$flow"
additional_includes:
  - ../requirements.txt
EOF
done

# Create flows using normal templates
create_flows flows-noinclude
