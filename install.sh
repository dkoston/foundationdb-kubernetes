# Debian installer
apt-get -y update
apt-get -y install --no-install-recommends --no-install-suggests \
  curl ca-certificates lsb python dnsutils


fdb_version="5.2.5"
curl -fsSL "https://www.foundationdb.org/downloads/${fdb_version}/ubuntu/installers/foundationdb-clients_${fdb_version}-1_amd64.deb" > foundationdb-client.deb
curl -fsSL "https://www.foundationdb.org/downloads/${fdb_version}/ubuntu/installers/foundationdb-server_${fdb_version}-1_amd64.deb" > foundationdb-server.deb
dpkg --force-confdef --install foundationdb-client.deb foundationdb-server.deb


foundationdb-server_5.2.5-1_amd64.deb

# Replace /etc/foundationdb/foundationdb.conf with foundationdb.conf from this repo
# Listen address needs to be <INTERNAL_IP>:$ID
# change /etc/foundationdb/fdb.cluster to use the same <INTERNAL_IP>

# vi /etc/init.d/foundationdb
# UNCOMMENT # . /lib/lsb/init-functions
# systemctl daemon-reload
# /etc/init.d/foundationdb restart

# Once all servers are set up:
#> configure ssd
#> coordinators 10.132.139.85:4500 10.132.117.173:4500 10.132.102.123:4500 10.132.143.121:4500 10.132.143.45:4500
#> configure proxies=5
#> configure logs=8
#> configure triple
