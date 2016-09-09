#!/bin/bash

## Define variables

WORK_DIR=/tmp
YML_FILE=$WORK_DIR/peppo.yaml
SOURCE_FILE=$WORK_DIR/peppo.out
virt_config_file=/etc/virt-who.conf

## Create esx map from all vcenters from virt-who-config

for i in `cat $virt_config_file  | grep "server=" |awk -F"=" '{print $2}' |awk '{print $1}'`; do perl vshere_list_4_json.pl --server $i --username "USERNAME" --password 'PASSWORD' --datacenter DACENTER; done > $SOURCE_FILE

## Create files with the subscription  
hammer --csv subscription list --organization ORG_NAME| grep "Red Hat Enterprise Linux Server" | grep Premium |awk -F, '{print "- " $9}' >> PROD__sub.out
hammer --csv subscription list --organization ORG_NAME| grep "Red Hat Enterprise Linux Server" | grep Standard |awk -F, '{print "- " $9}' >> PREPROD__sub.out

## Prepare yml file
echo "---
:settings:
  :user: admin
  :pass: changeme
  :uri: https://localhost
  :org: 1
:subs:
  -" > $YML_FILE

## write yml file
write_yml (){
echo "#${2}" >> $YML_FILE
echo -n "    hostname: \"" >> $YML_FILE
cat $1 >> $YML_FILE
SUB=`cat $2_sub.out`
echo "
    registered_by:
    sub:
     rhel:
$SUB
  -" >> $YML_FILE
}

## Main
for i in `cat $SOURCE_FILE |awk -F, '{print $1}' |uniq`
do
        ## Logic for divide PROD, PREPROD or DISCARD esx hostname. This is an example :-)
        case $i in

        NOT_COMPLIANT)             echo "Vcenter NOT Compliant --> Discart it"
                                grep "$i," $SOURCE_FILE | awk -F, '{print $2","$3","$5}' >> DISCARD.out
                ;;

        PROD)           grep "$i," $SOURCE_FILE | awk -F, '{print $2","$3","$5}' >> PROD.out
                ;;

        PREPROD)       grep "$i" $SOURCE_FILE | awk -F, '{print $2","$3","$5}' >> PREPROD.out
                ;;

        DISCARD)                 grep "$i" $SOURCE_FILE | awk -F, '{print $2","$3","$5}'  >> DISCARD.out
                ;;

        PROD_G)      cat $SOURCE_FILE |grep $i | awk -F, '{print $2","$3","$5}' | grep LEGACY >> PROD.out
                                cat $SOURCE_FILE |grep $i | awk -F, '{print $2","$3","$5}' | grep -e "[^a-z,A-Z]PROD[^a-z,A-Z]" >> PROD.out
                                cat $SOURCE_FILE |grep $i | awk -F, '{print $2","$3","$5}' | grep -v "[^a-z,A-Z]PROD[^a-z,A-Z]" |grep -i pre >> PREPROD.out
                                cat $SOURCE_FILE |grep $i | awk -F, '{print $2","$3","$5}' | grep -v "[^a-z,A-Z]PROD[^a-z,A-Z]" |grep -vi pre |grep -vi LEGACY  >> DISCARD.out
                ;;

        *VAR* | *VAR2* | *VAR3*)   cat $SOURCE_FILE |grep $i | awk -F, '{print $1","$2","$3","$5}' | grep -e "PROD[^a-z,A-Z]" | awk -F, '{print $2","$3","$4}' >> PROD.out
                                   cat $SOURCE_FILE |grep $i | awk -F, '{print $1","$2","$3","$5}' | grep -v "PROD[^a-z,A-Z]" | awk -F, '{print $2","$3","$4}' >> PREPROD.out
                                        ;;

        *)                      cat $SOURCE_FILE |grep $i | awk -F, '{print $2","$3","$5}' | grep -e "[^a-z,A-Z]PROD[^a-z,A-Z]" >> PROD.out
                                cat $SOURCE_FILE |grep $i | awk -F, '{print $2","$3","$5}' | grep -v "[^a-z,A-Z]PROD[^a-z,A-Z]" |grep -i pre >> PREPROD.out
                                cat $SOURCE_FILE |grep $i | awk -F, '{print $2","$3","$5}' | grep -v "[^a-z,A-Z]PROD[^a-z,A-Z]" |grep -vi pre  >> DISCARD.out
                         ;;

        esac
done

## For each envinronments write a section on yml file
for x in PROD PREPROD DISCARD;
do
        for i in `cat  $x.out |awk -F "," '{print $2}'`
        do
                        echo -n $i"|" >> ${x}_4_yml
        done
        echo -n "\"" >> ${x}_4_yml
        sed -i "s/|"/"/g" ${x}_4_yml

if [ -e ${x}_4_yml ]; then
        write_yml ${x}_4_yml $x
fi

done
