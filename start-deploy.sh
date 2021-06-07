export CLUSTER_ID=`cat .clusterid`
curl -s -X POST \
  --header "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  "https://$ASSISTED_SERVICE_API/api/assisted-install/v1/clusters/$CLUSTER_ID/actions/install"

