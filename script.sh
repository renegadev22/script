

#!/bin/sh

if [ -z "$1" ]
  then
    echo "Usage: $(basename $0) drive1 drive2 ..."
  exit
fi

SMARTCTL=$(whereis smartctl | awk '{print$2}')

if [ "$(echo ${SMARTCTL} | wc -w)" -le "0" ]; then
  echo "Error! \"smartctl\" command was not found!"
  echo "Please install the \"smartmontools\" package and try again!"
  exit
fi

verifydrives() {
  for HDD in $HDDS; do
    if [ "$(ls -1 /dev/ | egrep -c "^${HDD}$")" -le "0" ]; then
      echo "Hard drive \"${HDD}\" does not exist. Aborting."
      exit
    else
      echo "Hard drive \"${HDD}\" verified."
    fi
  done
}

cleandrives() {
  for HDD in ${HDDS}; do
    STARTPOINT=$(${SMARTCTL} -i /dev/${HDD} | \
                 awk '($1=="User" && $2=="Capacity:")\
                 {{for(i=3;i<=NF;++i)if($i~/^[0-9]+/)\
                 var=var$i};gsub(/\xa0/,"\x00",var);\
                 print (var / 1024) - 10}')
    dd if=/dev/zero of=/dev/${HDD} bs=1M count=10 >/dev/null 2>&1
    dd if=/dev/zero of=/dev/${HDD} bs=1M count=10 seek=${STARTPOINT} \
    >/dev/null 2>&1
  done
}

HDDS="$*"

verifydrives ${HDDS}

echo ""
echo "This will irreversibly destroy partition- and filesystem data on drive(s):"
echo "${HDDS}"
echo ""
echo "USE WITH EXTREME CAUTION!"
read -r -p 'Do you confirm "yes/no": ' CHOICE
case "${CHOICE}" in
  yes) cleandrives ${HDDS}
       echo ""
       echo "Drive(s) cleaned."  ;;
   no) echo ""
       echo "Cleaning cancelled."; break ;;
    *) echo ""
       echo "Cleaning cancelled."; break ;;
esac
