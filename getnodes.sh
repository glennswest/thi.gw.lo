./get-cluster.sh > .getcluster.json
jq -r '.hosts[] | .requested_hostname + " " +  .role + " " + .id' < .getcluster.json > .nodes  

