#!/bin/sh

set -x

#The following steps are being described here: https://www.terraform.io/docs/cloud/sentinel/mock.html#generating-mock-data-using-the-api

# The assumption is that a environment variable with name TOKEN is set. A token of type TEAM has to be used.

# Arguments
WORKSPACE=$1

# Init
terraform init

# Generate a plan
terraform plan

# Get the Plan ID of the last run
last_plan_id=$(curl \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  https://app.terraform.io/api/v2/workspaces/$1/runs | jq -r 'first(.data[].relationships.plan.data.id)')

# Check if a plan export already exists
pe_id=$(curl \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  https://app.terraform.io/api/v2/plans/plan-SGEULeVsj4JboynN | jq -r .data.relationships.exports.data[].id)

if [ "$pe_id" == "" ]; then

# Request a plan export
cat << EOF > payload_for_request_plan_export.json
{
  "data": {
    "type": "plan-exports",
    "attributes": {
      "data-type": "sentinel-mock-bundle-v0"
    },
    "relationships": {
      "plan": {
        "data": {
          "id": "$last_plan_id",
          "type": "plans"
        }
      }
    }
  }
}
EOF

pe_id=$(curl \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @payload_for_request_plan_export.json \
  https://app.terraform.io/api/v2/plan-exports | jq -r '.data.id')


# Plan exports happen asynchronously. There we loop until response contains status "finished".
for ((i=1;i<=100;i++)); do 
  status=$(curl  \
              --header "Authorization: Bearer $TOKEN" \
	      --header "Content-Type: application/vnd.api+json" \
	      https://app.terraform.io/api/v2/plan-exports/$pe_id | jq -r .data.attributes.status); 

  if [ $status == "finished" ]; then 
	break;
  fi; 

  echo "Status is still $status. Waiting 3 seconds until the next try."
  sleep 3
done

fi

# Download the mock data
curl \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --location \
  https://app.terraform.io/api/v2/plan-exports/$pe_id/download \
  > export.tar.gz

# Clean up
curl \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  -X DELETE \
  https://app.terraform.io/api/v2/plan-exports/$pe_id

rm -f payload_for_request_plan_export.json

# Do something with the export...
#...
