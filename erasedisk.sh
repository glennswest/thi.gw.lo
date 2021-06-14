
ssh root@esx.gw.lo "cd /vmfs/volumes/datastore2/$1;rm $1.vmdk;rm $1.vmsd;rm $1-flat.vmdk;vmkfstools --createvirtualdisk 250G --diskformat thin $1.vmdk"

