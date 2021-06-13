x=0
hostcnt=$(($1))
while [ $x -lt $hostcnt ] 
do
  nodecnt=`./getclusternodes.sh`
  x=$(($nodecnt))
  sleep 4
  done


