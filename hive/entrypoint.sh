#!/bin/bash

set -e
set -x

# Wait for service dependencies
for service in $SERVICE_DEPENDENCIES
do
  wait-for $service -t 300
done

# Set environment variables that are used in configuration files
env | grep HIVE_CONF_SUBSTITUTE_ | sed -e 's/HIVE_CONF_SUBSTITUTE_/export /g' >> "$HIVE_CONF_DIR/hive-env.sh"

if [ "$AUTHENTICATION_TYPE" == "kerberos" ]; then
  # Kerberos login-in
  kinit -kt /var/keytabs/hive.keytab "$HIVE_USER/$HOSTNAME@EXAMPLE.COM"
fi

# Format metastore
schematool -initSchema -dbType mysql
# Start Hive services
hive --service metastore &> "/tmp/hive-metastore.log" &
hive --service hiveserver2 &> "/tmp/hive-hiveserver2.log" &

# Add data
wget -q "https://s3.amazonaws.com/h2o-public-test-data/smalldata/airlines/AirlinesTest.csv.zip" -O /tmp/AirlinesTest.csv.zip
unzip -o /tmp/AirlinesTest.csv.zip -d /tmp
wait-for "localhost:10000" -t 300
JDBC_URL="jdbc:hive2://localhost:10000/default"
if [ "$AUTHENTICATION_TYPE" == "kerberos" ]; then
  JDBC_URL="$JDBC_URL;principal=$HIVE_USER/$HOSTNAME@EXAMPLE.COM"
fi
beeline -u "$JDBC_URL" -e "\
  CREATE EXTERNAL TABLE IF NOT EXISTS AirlinesTest \
    ( \
      fYear VARCHAR(10), \
      fMonth VARCHAR(10), \
      fDayofMonth VARCHAR(20), \
      fDayOfWeek VARCHAR(20), \
      DepTime INT, \
      ArrTime INT, \
      UniqueCarrier STRING, \
      Origin STRING, \
      Dest STRING, \
      Distance INT, \
      IsDepDelayed STRING, \
      IsDepDelayed_REC INT \
    ) \
    ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' tblproperties(\"skip.header.line.count\"=\"1\"); \
  LOAD DATA LOCAL INPATH '/tmp/AirlinesTest.csv' OVERWRITE INTO TABLE AirlinesTest;"
rm -f /tmp/AirlinesTest.csv

if [ "$AUTHENTICATION_TYPE" == "kerberos" ]; then
  # Destroy Kerberos tickets
  kdestroy
fi

# Start service to mark all services started
nc -lk 55555
