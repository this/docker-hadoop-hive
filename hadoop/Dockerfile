ARG JDK_IMAGE=openjdk:8
FROM $JDK_IMAGE

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends sudo openssh-server netcat && \
    wget -q "https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh" -O /usr/local/bin/wait-for && \
    chmod +x /usr/local/bin/wait-for

# Create users
ENV HADOOP_USER=hadoopuser
ENV HIVE_USER=hiveuser
RUN adduser --gecos "" "$HADOOP_USER" && \
    adduser "$HADOOP_USER" sudo && echo "$HADOOP_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    addgroup hivetesters && \
    adduser --gecos "" "$HIVE_USER" && adduser "$HIVE_USER" hivetesters && \
    adduser --gecos "" jenkins && adduser jenkins hivetesters
USER $HADOOP_USER

# Install Hadoop
ARG HADOOP_VERSION="3.3.1"
RUN wget "https://dlcdn.apache.org/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" -O /tmp/hadoop.tar.gz && \
    tar -xz -f /tmp/hadoop.tar.gz -C "$HOME/" && \
    rm /tmp/hadoop.tar.gz
ENV HADOOP_HOME=/home/$HADOOP_USER/hadoop-$HADOOP_VERSION
ENV HADOOP_COMMON_HOME=$HADOOP_HOME \
    HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop \
    HADOOP_HDFS_HOME=$HADOOP_HOME \
    HADOOP_LOG_DIR=$HADOOP_HOME/logs \
    HADOOP_MAPRED_HOME=$HADOOP_HOME \
    HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native" \
    YARN_HOME=$HADOOP_HOME \
    PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
ARG AUTHENTICATION_TYPE=noauth
COPY hadoop/conf/$AUTHENTICATION_TYPE/ $HADOOP_CONF_DIR/
RUN echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh

# Configure SSH
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
COPY hadoop/conf/ssh-config ~/.ssh/config

ENV AUTHENTICATION_TYPE=$AUTHENTICATION_TYPE
# Kerberos configurations
RUN if [ "$AUTHENTICATION_TYPE" = "kerberos" ]; then \
      # Install Kerberos client
      sudo -E apt-get update && \
      export DEBIAN_FRONTEND=noninteractive && sudo -E apt-get install -y --no-install-recommends krb5-user; \
      # Create truststore and keystore
      export CERTS_DIR=/tmp; \
      export ALIAS=hadoop; \
      keytool -genkeypair -noprompt -storepass keystorepassword -dname "CN=$HOSTNAME, OU=connectors, O=example.com, L=Unknown, ST=Unknown, C=Unknown" -keypass keypassword -alias $ALIAS -keyalg RSA -keystore "$CERTS_DIR/hadoop-self-signed-keystore.jks"; \
      keytool -export -noprompt -rfc -keystore "$CERTS_DIR/hadoop-self-signed-keystore.jks" -storepass keystorepassword -alias $ALIAS -file "$CERTS_DIR/hadoop.cert"; \
      keytool -importcert -noprompt -file "$CERTS_DIR/hadoop.cert" -keystore "$CERTS_DIR/hadoop-truststore.jks" -storepass truststorepassword -alias $ALIAS; \
      # Import hadoop.cert to Java truststore (for Hadoop 3.x)
      sudo "$JAVA_HOME/bin/keytool" -importcert -noprompt -file "$CERTS_DIR/hadoop.cert" -keystore "$JAVA_HOME/jre/lib/security/cacerts" -storepass changeit -alias $ALIAS; \
    fi
COPY kerberos/conf/krb5.conf /etc/krb5.conf

# Add entrypoint
COPY hadoop/entrypoint.sh /tmp/entrypoint.sh
RUN sudo chmod +x /tmp/entrypoint.sh
ENTRYPOINT ["/tmp/entrypoint.sh"]

EXPOSE 9000 9870 9864 55555
