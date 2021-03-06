#!/bin/bash
#
# NMA API server init script
#
# See README for usage instructions.
#
HOSTNAME=data.nma.gov.au
CONFIG_DIR=/usr/local/NMA-API-ETL/install/config
INSTALL_DIR=/tmp/nma-api-install
#
echo =========== API server install start
date
mkdir $INSTALL_DIR
chown -R ubuntu:ubuntu /usr/local/NMA-API-ETL
#
# HOST
#
if [[ -z "$1" ]]; then
    echo No hostname provided so using default hostname: $HOSTNAME
else
    HOSTNAME="$1"
fi
mv /etc/hostname /etc/hostname.original
echo "$HOSTNAME" > /etc/hostname
hostname $HOSTNAME
echo -e "127.0.0.1 localhost $HOSTNAME nma\n\n$(cat /etc/hosts)" > /etc/hosts
#
# EXIM MAIL TRANSFER AGENT
#
echo =========== Installing Exim Mail Transfer Agent
chmod a+x $CONFIG_DIR/exim/configure.sh
$CONFIG_DIR/exim/configure.sh

# pre-fill exim package configuration
echo "exim4-config exim4/use_split_config boolean false" | debconf-set-selections
echo "exim4-config exim4/dc_other_hostnames string localhost" | debconf-set-selections
echo "exim4-config exim4/dc_relay_domains string" | debconf-set-selections
echo "exim4-config exim4/dc_relay_nets string" | debconf-set-selections
echo "exim4-config exim4/dc_localdelivery select mbox format in /var/mail/" | debconf-set-selections
echo "exim4-config exim4/dc_eximconfig_configtype select internet site; mail is sent and received directly using SMTP" | debconf-set-selections
echo "exim4-config exim4/dc_postmaster string conal.tuohy+nma-dev-postmaster@gmail.com" | debconf-set-selections
echo "exim4-config exim4/dc_local_interfaces string 127.0.0.1 ; ::1" | debconf-set-selections
echo exim4-config exim4/mailname string $HOSTNAME | debconf-set-selections
echo "exim4-config exim4/dc_minimaldns boolean false" | debconf-set-selections
apt install -y sendemail exim4
update-exim4.conf
#sendemail -f '"Installer" installer@data.nma.gov.au' -t conal.tuohy@gmail.com -u 'exim installation' -m "This message sent by exim"
#
# JAVA
#
echo =========== Installing Java
apt install -y default-jdk
JAVA_HOME=/usr/lib/jvm/default-java
echo "JAVA_HOME=/usr/lib/jvm/default-java" > /etc/environment
#
# APACHE HTTP SERVER
#
echo =========== Installing Apache HTTP Server
apt install -y apache2
a2enmod proxy_http
a2enmod headers
a2enmod ssl
# to receive X-Forward-For from F5 proxy server
a2enmod remoteip
mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.original
ln -s $CONFIG_DIR/apache/000-default.conf /etc/apache2/sites-available/
#
# TOMCAT
#
echo =========== Installing tomcat
apt install -y tomcat8 
mv /etc/default/tomcat8 /etc/default/tomcat8.original 
ln -s $CONFIG_DIR/tomcat/tomcat8 /etc/default/
#
# SOLR
#
echo =========== Installing Solr
cd $INSTALL_DIR
wget http://archive.apache.org/dist/lucene/solr/7.2.1/solr-7.2.1.tgz -O solr-7.2.1.tgz
tar xzf solr-7.2.1.tgz solr-7.2.1/bin/install_solr_service.sh --strip-components=2
./install_solr_service.sh $INSTALL_DIR/solr-7.2.1.tgz
# create cores, only link config parts (so data files aren't in git)

SOLR_CORE_1_NAME=core_nma_public
mkdir -p        /var/solr/data/$SOLR_CORE_1_NAME
chown solr:solr /var/solr/data/$SOLR_CORE_1_NAME
ln -s $CONFIG_DIR/solr/$SOLR_CORE_1_NAME/core.properties /var/solr/data/$SOLR_CORE_1_NAME/core.properties
ln -s $CONFIG_DIR/solr/$SOLR_CORE_1_NAME/conf            /var/solr/data/$SOLR_CORE_1_NAME/conf

SOLR_CORE_2_NAME=core_nma_internal
mkdir -p        /var/solr/data/$SOLR_CORE_2_NAME
chown solr:solr /var/solr/data/$SOLR_CORE_2_NAME
ln -s $CONFIG_DIR/solr/$SOLR_CORE_2_NAME/core.properties /var/solr/data/$SOLR_CORE_2_NAME/core.properties
ln -s $CONFIG_DIR/solr/$SOLR_CORE_2_NAME/conf            /var/solr/data/$SOLR_CORE_2_NAME/conf

SOLR_CORE_3_NAME=core_nma_log
mkdir -p        /var/solr/data/$SOLR_CORE_3_NAME
chown solr:solr /var/solr/data/$SOLR_CORE_3_NAME
ln -s $CONFIG_DIR/solr/$SOLR_CORE_3_NAME/core.properties /var/solr/data/$SOLR_CORE_3_NAME/core.properties
ln -s $CONFIG_DIR/solr/$SOLR_CORE_3_NAME/conf            /var/solr/data/$SOLR_CORE_3_NAME/conf

# replace Solr's default "includes" (config) file with a customised version
rm /etc/default/solr.in.sh
ln -s $CONFIG_DIR/solr/solr.in.sh /etc/default/solr.in.sh
# solr dynamically updates schema files so needs write permission
chown -R solr:solr $CONFIG_DIR/solr
#
# JENA
#
echo =========== Installing Jena
apt install -y unzip
cd $INSTALL_DIR
wget http://archive.apache.org/dist/jena/binaries/apache-jena-3.6.0.zip -O jena-3.6.0.zip
unzip jena-3.6.0.zip -d /usr/local
ln -s /usr/local/apache-jena-3.6.0 /usr/local/jena
# add tdb2.tdbstats script missing from jena distro
cp $CONFIG_DIR/fuseki/tdb2.tdbstats /usr/local/jena/bin/
chmod a+x /usr/local/jena/bin/fuseki/tdb2.tdbstats
#
# FUSEKI
#
echo =========== Installing Fuseki
mkdir -p /etc/fuseki/configuration
ln -s $CONFIG_DIR/fuseki/log4j.properties /etc/fuseki/
ln -s $CONFIG_DIR/fuseki/public.ttl /etc/fuseki/configuration/
ln -s $CONFIG_DIR/fuseki/internal.ttl /etc/fuseki/configuration/
chown -R tomcat8:tomcat8 /etc/fuseki/
cd $INSTALL_DIR
wget http://archive.apache.org/dist/jena/binaries/apache-jena-fuseki-3.6.0.zip -O fuseki-3.6.0.zip
unzip -j fuseki-3.6.0.zip apache-jena-fuseki-3.6.0/fuseki.war -d /var/lib/tomcat8/webapps/
#
# XML Calabash (XProc processor)
# - it may be better to just download the zip and unpack it in the appropriate place? (the installer uses /opt/xmlcalabash-blah-blah-version-number)
#
echo =========== Installing XML Calabash
cd $INSTALL_DIR
wget https://github.com/ndw/xmlcalabash1/releases/download/1.1.21-98/xmlcalabash-1.1.21-98.zip -O xmlcalabash.zip
unzip xmlcalabash.zip -d /usr/local
# create version-independent path for xmlcalabash executable: /usr/local/xmlcalabash/xmlcalabash.jar
ln -s /usr/local/xmlcalabash-1.1.21-98 /usr/local/xmlcalabash
ln -s /usr/local/xmlcalabash/xmlcalabash-1.1.21-98.jar /usr/local/xmlcalabash/xmlcalabash.jar
#
## TOMCAT MANAGER
#
echo =========== Installing tomcat manager
apt install -y tomcat8-admin
# configure tomcat-users.xml to include credentials for manager app
java -Xmx1G -jar /usr/local/xmlcalabash/xmlcalabash.jar $CONFIG_DIR/tomcat/initialize-tomcat.xpl
# restrict read access to the tomcat-users.xml file to root and tomcat users
chown root:tomcat8 /var/lib/tomcat8/conf/tomcat-users.xml
chmod u=rw,g=r,o= /var/lib/tomcat8/conf/tomcat-users.xml
# restart tomcat to reload the new tomcat-users.xml
service tomcat8 restart
#
# XSpec (XSLT unit tests)
#
echo =========== Installing XSpec
cd /usr/local
git clone https://github.com/xspec/xspec.git
mkdir -p /usr/local/NMA/test-results
chown -R ubuntu:ubuntu /usr/local/NMA
#
# XPROC-Z (ETL)
#
echo =========== Installing XProc-Z ETL
cd $INSTALL_DIR
wget https://github.com/Conal-Tuohy/XProc-Z/releases/download/v1.3/xproc-z.war -O xproc-z.war
mv xproc-z.war /var/lib/tomcat8/webapps/
ln -s $CONFIG_DIR/tomcat/xproc-z.xml /var/lib/tomcat8/conf/Catalina/localhost/
mkdir /var/log/NMA-API-ETL
mkdir /mnt
chown -R ubuntu:ubuntu /mnt
mkdir -p /data/public/n-quads
mkdir -p /data/internal/n-quads
chown -R ubuntu:ubuntu /data
# set up crontab to run ETL
chmod a+x /usr/local/NMA-API-ETL/etl-run-all.sh
cp $CONFIG_DIR/run-apietl-crontab /etc/cron.d/
#
# XPROC-Z (API SHIM)
#
echo =========== Installing XProc-Z API shim
mkdir /etc/xproc-z/
chmod a+w /etc/xproc-z/
cp /var/lib/tomcat8/webapps/xproc-z.war /etc/xproc-z/
cd /etc/xproc-z/
git clone https://github.com/NationalMuseumAustralia/Collection-API.git NMA-API
cp /etc/xproc-z/NMA-API/apiexplorer.html /var/www/html/
#
# KONG API GATEWAY
#
echo =========== Installing Kong
cd $INSTALL_DIR
wget https://bintray.com/kong/kong-community-edition-deb/download_file?file_path=dists/kong-community-edition-0.13.0.xenial.all.deb -O kong.deb
apt install -y ./kong.deb
apt install -y postgresql postgresql-client
sudo -u postgres psql --command="CREATE USER kong;"
sudo -u postgres psql --command="ALTER USER kong WITH PASSWORD 'kong';"
sudo -u postgres psql --command="CREATE DATABASE kong OWNER kong;"
ln -s $CONFIG_DIR/kong/kong.conf /etc/kong/
kong migrations up
kong stop
cp $CONFIG_DIR/kong/kong.service /etc/systemd/system/
systemctl enable kong
service kong start
# configure Kong
java -Xmx1G -jar /usr/local/xmlcalabash/xmlcalabash.jar $CONFIG_DIR/kong/initialize-kong.xpl
#
# NAGIOS
#
echo =========== Installing Nagios
# https://support.nagios.com/kb/article/nagios-core-installing-nagios-core-from-source-96.html#Ubuntu
apt install -y autoconf gcc libc6 make wget unzip apache2 php libapache2-mod-php7.0 libgd2-xpm-dev
cd $INSTALL_DIR
wget -O nagioscore-4.3.4.tar.gz https://github.com/NagiosEnterprises/nagioscore/archive/nagios-4.3.4.tar.gz
tar xzf nagioscore-4.3.4.tar.gz
cd $INSTALL_DIR/nagioscore-nagios-4.3.4/
./configure --with-httpd-conf=/etc/apache2/sites-available
make all
useradd nagios
usermod -a -G nagios www-data
make install
make install-init
update-rc.d nagios defaults
make install-commandmode
make install-config
make install-webconf
a2enmod rewrite
a2enmod cgi
ufw allow Apache
ufw reload
apt install -y autoconf gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext
cd $INSTALL_DIR
wget --no-check-certificate -O nagios-plugins-2.2.1.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz
tar zxf nagios-plugins-2.2.1.tar.gz
cd $INSTALL_DIR/nagios-plugins-release-2.2.1/
./tools/setup
./configure
make
make install
#
# WEBMIN
#
echo =========== Installing Webmin
# download from sourceforge as webmin.com is unreliable
cd $INSTALL_DIR
wget https://downloads.sourceforge.net/project/webadmin/webmin/1.890/webmin_1.890_all.deb -O webmin_1.890_all.deb
# -f to install dependencies
apt install -f -y ./webmin_1.890_all.deb
# remove SSL requirement config (server is behind a secure proxy)
# see: https://doxfer.webmin.com/Webmin/Running_Webmin_Under_Apache
# replace existing lines
sed -i 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf
# append lines if missing
grep -q -F 'ssl_redirect=0' /etc/webmin/miniserv.conf || echo 'ssl_redirect=0' >> /etc/webmin/miniserv.conf
grep -q -F 'webprefix=/webmin' /etc/webmin/config || echo 'webprefix=/webmin' >> /etc/webmin/config
grep -q -F 'webprefixnoredir=1' /etc/webmin/config || echo 'webprefixnoredir=1' >> /etc/webmin/config
grep -q -F 'referer=1' /etc/webmin/config || echo 'referer=1' >> /etc/webmin/config
# remove shell
rm -rf /etc/webmin/shell
rm -rf /usr/share/webmin/shell
sed -i 's/shell//g' /etc/webmin/webmin.acl
#
# GOACCESS
#
echo =========== Installing GoAccess
echo "deb http://deb.goaccess.io/ $(lsb_release -cs) main" | tee -a /etc/apt/sources.list.d/goaccess.list
wget -O - https://deb.goaccess.io/gnugpg.key | apt-key add -
apt update
apt install -y goaccess
mv /etc/goaccess.conf /etc/goaccess.conf.original
ln -s $CONFIG_DIR/goaccess/goaccess.conf /etc/
cp $CONFIG_DIR/goaccess/goaccess.service /etc/systemd/system/
systemctl enable goaccess
service goaccess start
#
# REFRESH
#
echo =========== Restarting services
service apache2 restart
service tomcat8 restart
service solr restart
service nagios restart
service webmin restart
#
echo =========== API server install complete
date
