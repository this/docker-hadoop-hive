#!/bin/bash

set -e
set -x

# Wait for service dependencies
for service in $SERVICE_DEPENDENCIES; do
  wait-for $service -t 300
done

# Set environment variables that are used in configuration files
env | grep HADOOP_CONF_SUBSTITUTE_ | sed -e 's/HADOOP_CONF_SUBSTITUTE_/export /g' > "$HOME/.hadooprc"

if [ "$AUTHENTICATION_TYPE" == "kerberos" ]; then
  # Kerberos login-in
  kinit -kt /var/keytabs/hadoop.keytab "$HADOOP_USER/$HOSTNAME@EXAMPLE.COM"
fi

# Start SSH
sudo service ssh start
# Format HDFS
hdfs namenode -format -force
# Start Hadoop
start-dfs.sh
start-yarn.sh

# Download data
wget -q "https://s3.amazonaws.com/h2o-public-test-data/smalldata/airlines/AirlinesTest.csv.zip" -O /tmp/AirlinesTest.csv.zip
unzip -o /tmp/AirlinesTest.csv.zip -d /tmp
rm -f /tmp/AirlinesTest.csv.zip

# Add data
hdfs dfs -mkdir -p /test/files/
hdfs dfs -put /tmp/AirlinesTest.csv /test/files/
hdfs dfs -mkdir -p /test/empty
rm -f /tmp/AirlinesTest.csv

# Create Hive directories
hdfs dfs -mkdir /tmp
hdfs dfs -chown -R $HIVE_USER /tmp
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -chown -R $HIVE_USER /user/hive

if [ "$AUTHENTICATION_TYPE" == "kerberos" ]; then
  # Destroy Kerberos tickets
  kdestroy
fi

# Start service to mark all services started
nc -lk 55555
