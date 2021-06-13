ASSISTED_SERVICE_API="api.openshift.com"
export CLUSTER_ID=`cat .clusterid`
export OFFLINE_ACCESS_TOKEN=`cat .ocmapitoken.txt`
export TOKEN=`curl \
--silent \
--data-urlencode "grant_type=refresh_token" \
--data-urlencode "client_id=cloud-services" \
--data-urlencode "refresh_token=${OFFLINE_ACCESS_TOKEN}" \
https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token | \
jq -r .access_token`
curl --silent \
  -H "Authorization: Bearer $TOKEN" \
  -L "http://$ASSISTED_SERVICE_API/api/assisted-install/v1/clusters/$CLUSTER_ID" > .clusterstatus
export CLUSTER_HOSTS=`cat .clusterstatus | jq  '.enabled_host_count'`
