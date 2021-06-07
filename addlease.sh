export MYINTERFACE=en7
export BMMACNAME=$1
export BMIPADDR=`dig +short $1`
echo $BMMACNAME
bmmacaddr=$(echo $BMMACNAME|md5sum|sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02:\1:\2:\3:\4:\5/')
echo $bmmacaddr

export thecmd="/ip dhcp-server option add code=12 name=hostname-$1 value=\"s'${1}'\""
echo $thecmd
ssh admin@192.168.1.1 ${thecmd}

export thecmd="/ip dhcp-server lease add mac-address=${bmmacaddr} address=${BMIPADDR} dhcp-option=hostname-${BMMACNAME},dns-dev"
echo $thecmd
ssh admin@192.168.1.1 ${thecmd}

