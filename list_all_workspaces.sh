#!/bin/sh

curl \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  https://app.terraform.io/api/v2/organizations/mkaesz-dev/workspaces | jq -jr '.data[]|"id:", " ",.id, "\n", "name:", " ", .attributes.name, "\n\n"'

