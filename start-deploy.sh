ASSISTED_SERVICE_API="api.openshift.com"
export CLUSTER_ID=`cat .clusterid`
export OFFLINE_ACCESS_TOKEN=`cat .ocmapitoken.txt`
export CLUSTER_NAME="thi"
export CLUSTER_DOMAIN="gw.lo"
export CLUSTER_INGRESS_VIP=`dig +short test.apps.$CLUSTER_NAME.$CLUSTER_DOMAIN`
export CLUSTER_API_VIP=`dig +short api.$CLUSTER_NAME.$CLUSTER_DOMAIN`
export TOKEN=`curl \
--silent \
--data-urlencode "grant_type=refresh_token" \
--data-urlencode "client_id=cloud-services" \
--data-urlencode "refresh_token=${OFFLINE_ACCESS_TOKEN}" \
https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token | \
jq -r .access_token`
curl -s -X POST \
  --header "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  "https://$ASSISTED_SERVICE_API/api/assisted-install/v1/clusters/$CLUSTER_ID/actions/install"

