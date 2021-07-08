export OFFLINE_ACCESS_TOKEN=`cat .ocmapitoken.txt`
export TOKEN=`curl \
--silent \
--data-urlencode "grant_type=refresh_token" \
--data-urlencode "client_id=cloud-services" \
--data-urlencode "refresh_token=${OFFLINE_ACCESS_TOKEN}" \
https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token | \
jq -r .access_token`
echo $TOKEN > .token
export CLUSTER_ID=`cat .clusterid`
ASSISTED_SERVICE_API="api.openshift.com"
curl -s -X GET "https://$ASSISTED_SERVICE_API/api/assisted-install/v1/clusters/$CLUSTER_ID" \
  --header "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" | jq
