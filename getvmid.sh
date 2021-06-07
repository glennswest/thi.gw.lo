export vmid=`ssh root@esx.gw.lo vim-cmd vmsvc/getallvms | grep $1 | awk '{print $1}'`
echo $vmid
