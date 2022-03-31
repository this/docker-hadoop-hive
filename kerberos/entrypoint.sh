#!/bin/bash

set -e
set -x

# Create master database
kdb5_util create -r "$REALM" -s -P masterdatabasepassword

KEYTABS_PATH=/var/keytabs
find $KEYTABS_PATH -name "*.keytab" -delete

KADMIN_PRINCIPAL="kadmin/admin@$REALM"
kadmin.local -q "delete_principal -force $KADMIN_PRINCIPAL"
kadmin.local -q "addprinc -pw adminpassword $KADMIN_PRINCIPAL"

HADOOP_PRINCIPAL="hadoopuser/hadoop-server@$REALM"
kadmin.local -q "delete_principal -force $HADOOP_PRINCIPAL"
kadmin.local -q "addprinc -pw hadooppassword $HADOOP_PRINCIPAL"
kadmin.local -q "ktadd -k $KEYTABS_PATH/hadoop.keytab $HADOOP_PRINCIPAL"

HIVE_PRINCIPAL="hiveuser/hive-server@$REALM"
kadmin.local -q "delete_principal -force $HIVE_PRINCIPAL"
kadmin.local -q "addprinc -pw hivepassword $HIVE_PRINCIPAL"
kadmin.local -q "ktadd -k $KEYTABS_PATH/hive.keytab $HIVE_PRINCIPAL"

chmod -R ugo+rw $KEYTABS_PATH/

krb5kdc
kadmind -nofork
