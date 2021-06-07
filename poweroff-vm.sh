vmid=`./getvmid.sh $1`
ssh root@esx.gw.lo vim-cmd vmsvc/power.off ${vmid}

