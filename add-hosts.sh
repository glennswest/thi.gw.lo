export OFFLINE_ACCESS_TOKEN=`cat .ocmapitoken.txt`
export TOKEN=`curl \
--silent \
--data-urlencode "grant_type=refresh_token" \
--data-urlencode "client_id=cloud-services" \
--data-urlencode "refresh_token=${OFFLINE_ACCESS_TOKEN}" \
https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token | \
jq -r .access_token`
echo $TOKEN > .token
ASSISTED_SERVICE_API="api.openshift.com"
CLUSTER_VERSION="4.7.13"
CLUSTER_NAME="thi"
CLUSTER_DOMAIN="gw.lo"
CLUSTER_CIDR_NET="10.128.0.0/14"
CLUSTER_CIDR_SVC="172.30.0.0/16"
CLUSTER_HOST_PFX="23"
CLUSTER_WORKER_HT="Enabled"
CLUSTER_WORKER_COUNT="3"
CLUSTER_MASTER_HT="Enabled"
CLUSTER_MASTER_COUNT="3"
CLUSTER_SSHKEY=`cat ~/.ssh/id_rsa.pub`
export CLUSTER_INGRESS_VIP=`dig +short test.apps.$CLUSTER_NAME.$CLUSTER_DOMAIN`
export CLUSTER_API_VIP=`dig +short api.$CLUSTER_NAME.$CLUSTER_DOMAIN`
PULL_SECRET=$(cat pull-secret.txt | jq -R .)
# Request ISO
curl -s -X POST "https://$ASSISTED_SERVICE_API/api/assisted-install/v1/clusters/$CLUSTER_ID/downloads/image" \
  -d @iso-params.json \
  --header "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  | jq '.'
echo "Wait for ISO"
sleep 20
curl \
  -H "Authorization: Bearer $TOKEN" \
  -L "http://$ASSISTED_SERVICE_API/api/assisted-install/v1/clusters/$CLUSTER_ID/downloads/image" \
  -o discovery_image_thi.iso
ssh root@esxi.gw.lo "rm /vmfs/volumes/datastore1/iso/discovery_image_thi.iso"
scp discovery_image_thi.iso root@esxi.gw.lo:/vmfs/volumes/datastore1/iso/discovery_image_thi.iso
