./delete-cluster.sh
./poweroff-all-vms.sh
./erase-all-vms.sh
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
#CLUSTER_IMAGE="quay.io/openshift-release-dev/ocp-release:4.8.0-fc.3-x86_64"
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
cat << EOF > ./deployment.json
{
  "kind": "Cluster",
  "name": "$CLUSTER_NAME",
  "openshift_version": "$CLUSTER_VERSION",
  "base_dns_domain": "$CLUSTER_DOMAIN",
  "hyperthreading": "all",
  "vip_dhcp_allocation": false,
  "ingress_vip": "$CLUSTER_INGRESS_VIP",
  "api_vip":  "$CLUSTER_API_VIP",
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
curl -s -X POST "https://$ASSISTED_SERVICE_API/api/assisted-install/v1/clusters" \
  -d @./deployment.json \
  --header "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  > .clusterresult
CLUSTER_ID=`cat .clusterresult | jq -r '.id'`
echo $CLUSTER_ID > .clusterid
echo "Wait for cluster to get created"
sleep 20
#echo "Update installconfig for OVN "
#cp installconfig.yaml .installconfig-new
#cat .installconfig-new | yq eval --tojson --indent 0  | sed 's/"/\\"/g' | awk '{ print "\""$0"\""}' > .installconfig-string
#curl -s -X PATCH "https://$ASSISTED_SERVICE_API/api/assisted-install/v1/clusters/$CLUSTER_ID/install-config" \
#  --header "Content-Type: application/json" \
#  -H "Authorization: Bearer $TOKEN" -T .installconfig-string

echo "Update VIPs"
cat << EOF > cluster-update-params.json
{ 
  "api_vip": "$CLUSTER_API_VIP",
  "ingress_vip": "$CLUSTER_INGRESS_VIP"
}
EOF
curl -s -X PATCH "https://$ASSISTED_SERVICE_API/api/assisted-install/v1/clusters/$CLUSTER_ID" \
  -d @./cluster-update-params.json \
  --header "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  > .clusterupdateresult

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
echo "Power On Nodes"
./poweron-vm.sh cp0.thi.gw.lo
./poweron-vm.sh cp1.thi.gw.lo
./poweron-vm.sh cp2.thi.gw.lo
echo "Wait for control plane nodes to register"
./waitfornodes.sh 3
echo "Power on workers"
./poweron-vm.sh node0.thi.gw.lo
./poweron-vm.sh node1.thi.gw.lo
./poweron-vm.sh node2.thi.gw.lo
echo "Wait for Nodes to register"
./waitfornodes.sh 6
echo "Nodes Ready"
echo "Wait for cluster to sync before install"
sleep 120
curl -s -X POST \
  --header "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  "https://$ASSISTED_SERVICE_API/api/assisted-install/v1/clusters/$CLUSTER_ID/actions/install" > .install-result


