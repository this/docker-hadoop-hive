FROM debian:jessie

ENV REALM=EXAMPLE.COM

# Install necessary dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends krb5-kdc krb5-admin-server

# Add configurations
COPY kerberos/conf/ /etc/
RUN mkdir -p /var/log/kerberos/

# Add entrypoint
COPY kerberos/entrypoint.sh /tmp/entrypoint.sh
RUN chmod +x /tmp/entrypoint.sh
ENTRYPOINT ["/tmp/entrypoint.sh"]

EXPOSE 749 750 88
