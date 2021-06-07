./createvm.sh cp0.thi.gw.lo
./createvm.sh cp1.thi.gw.lo
./createvm.sh cp2.thi.gw.lo
./createvm.sh node0.thi.gw.lo
./createvm.sh node1.thi.gw.lo
./createvm.sh node2.thi.gw.lo
export OFFLINE_ACCESS_TOKEN=`cat .ocmapitoken.txt`
export TOKEN=`curl \
--silent \
--data-urlencode "grant_type=refresh_token" \
--data-urlencode "client_id=cloud-services" \
--data-urlencode "refresh_token=${OFFLINE_ACCESS_TOKEN}" \
https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token | \
jq -r .access_token`
echo "TOKEN: "
echo $TOKEN > .token
ASSISTED_SERVICE_API="api.openshift.com"
CLUSTER_VERSION="4.8"
CLUSTER_IMAGE="quay.io/openshift-release-dev/ocp-release:4.8.0-fc.3-x86_64"
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
PULL_SECRET=$(cat pull-secret.txt | jq -R .)
cat << EOF > ./deployment.json
{
  "kind": "Cluster",
  "name": "$CLUSTER_NAME",
  "openshift_version": "$CLUSTER_VERSION",
  "ocp_release_image": "$CLUSTER_IMAGE",
  "base_dns_domain": "$CLUSTER_DOMAIN",
  "hyperthreading": "all",
  "cluster_network_cidr": "$CLUSTER_CIDR_NET",
  "cluster_network_host_prefix": $CLUSTER_HOST_PFX,
  "service_network_cidr": "$CLUSTER_CIDR_SVC",
  "host_networks": [],
  "hosts": [],
  "ssh_public_key": "$CLUSTER_SSHKEY",
  "pull_secret": $PULL_SECRET
}
EOF
# Create Cluster
CLUSTER_ID=`curl -s -X POST "https://$ASSISTED_SERVICE_API/api/assisted-install/v1/clusters" \
  -d @./deployment.json \
  --header "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  | jq -r '.id'`
echo $CLUSTER_ID > .clusterid
echo "Wait for cluster to get created"
sleep 20
echo "Request ISO"
cat << EOF > ./iso-params.json
{
  "ssh_public_key": "$CLUSTER_SSHKEY",
  "pull_secret": $PULL_SECRET
}
EOF
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
