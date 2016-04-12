#!/bin/sh
# Installation script for Aeroo Reports, Library, and DOCS service.
# This install script is partially based on instructions found here:
# https://github.com/aeroo/aeroo_docs/wiki/Installation-example-for-Ubuntu-14.04-LTS

# Location of Odoo and addons folder:
ODOO_DIR=/home/odoo/odoo
ADDONS_DIR=$ODOO_DIR/addons

# Where to install Aeroo files:
AEROO_DIR=/opt/aeroo
AEROO_LIB=$AEROO_DIR/aeroolib

# GIT repositories:
AEROO_REPO=https://github.com/aeroo
AEROO_V9_REPO=https://github.com/Yenthe666
REPOS_V8="aeroolib aeroo_docs"
REPOS_V9="aeroo_reports"

# AerooDOCS settings:
AER_NAME=aeroo-docs
AER_DAEMON=/etc/init.d/$AER_NAME
AER_CONFIG=/etc/$AER_NAME.conf
AER_PID=/tmp/$AER_NAME.pid

# LibreOffice Headless settings:
LOH_NAME=libreoffice-headless
LOH_DAEMON=/etc/init.d/$LOH_NAME
LOH_PID=/var/run/$LOH_NAME.pid

# The AerooDOCS config file must be manually updated to
# reflect the values below if they are overwritten:
LOH_HOST=localhost
LOH_PORT=8100

# Check for root privileges
if [ $(id -u) -ne 0 ]; then
  printf "Must be root to run this script"
  exit 126
fi

# Uninstall option
case "$1" in
  -u|--uninstall)
    printf -- "Uninstalling Aeroo...\n"
    printf -- "---------------------\n"
    (
      set -x
      service $LOH_NAME stop
      service $AER_NAME stop
      update-rc.d -f $LOH_NAME remove
      update-rc.d -f $AER_NAME remove
      pip uninstall -qy aeroolib
      rm -rf "$LOH_DAEMON" "$LOH_PID"
      rm -rf "$AEROO_DIR" "$AER_DAEMON" "$AER_CONFIG" "$AER_PID"
      for dir in "$ADDONS_DIR"/aeroolib "$ADDONS_DIR"/report_aeroo*; do
        unlink $dir || rm -f $dir
      done
      systemctl daemon-reload
    )
    printf -- "----\nDone\n"
    exit 0;;
esac

# Dependencies
printf "\nInstall Dependencies"
printf "\n--------------------\n"
apt-get -y build-dep build-essential
apt-get -y install git python-setuptools python3-pip
apt-get -y install python-genshi python-cairo python-lxml python-cups
apt-get -y install libreoffice-script-provider-python libreoffice-base
pip3 install --upgrade json-rpc-3 daemonize

# GIT Repositories
printf "\nClone Aeroo Repositories"
printf "\n------------------------\n"

mkdir -p "$AEROO_DIR"; cd "$AEROO_DIR"

clone() {
  for repo in $2; do
    if [ ! -e "$AEROO_DIR/$repo/.git" ]; then
      git clone "$1/$repo.git"
      if [ $? -ne 0 ]; then
        exit $?
      fi
    fi
  done
}

clone "$AEROO_REPO" "$REPOS_V8"
clone "$AEROO_V9_REPO" "$REPOS_V9"

# AerooLib
printf "\nInstall AerooLib"
printf "\n----------------\n"

cd "$AEROO_LIB"
python setup.py install clean

# LibreOffice Headless
printf "\nSetup LibreOffice Headless Server"
printf "\n---------------------------------\n"

cat << EOF > "$LOH_DAEMON"
#!/bin/sh
### BEGIN INIT INFO
# Provides:          $LOH_NAME
# Required-Start:    \$remote_fs \$syslog
# Required-Stop:     \$remote_fs \$syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: LibreOffice-Headless daemon
# Description:       LibreOffice-Headless daemon
### END INIT INFO

NAME=$LOH_NAME
DAEMON=/usr/bin/soffice
HOST=$LOH_HOST
PORT=$LOH_PORT
PIDFILE=$LOH_PID
EOF
cat << 'EOF' >> "$LOH_DAEMON"
ARGS="--headless --accept=socket,host=$HOST,port=$PORT,tcpNoDelay=1;urp;"

# Include LSB functions.
. /lib/lsb/init-functions

set -e
case "$1" in
  start)
    log_daemon_msg "Starting $NAME server"
    start-stop-daemon --start -bm -p "$PIDFILE" -x "$DAEMON" -- $ARGS
    log_end_msg $?;;
  stop)
    log_daemon_msg "Stopping $NAME server"
    start-stop-daemon --stop -v -p "$PIDFILE"
    log_end_msg $?;;
  force-reload|restart)
    $NAME stop; $NAME start;;
  status)
    status_of_proc -p "$PIDFILE" "$DAEMON" $NAME && exit 0 || exit $?;;
  *)
    echo "Usage: /etc/init.d/$NAME {start|stop|restart|status}"
    exit 1;;
esac
EOF

chmod +x "$LOH_DAEMON"
update-rc.d $LOH_NAME defaults
service $LOH_NAME restart

# AerooDOCS
printf "\nSetup AerooDOCS Server"
printf "\n----------------------\n"

cat << EOF > "$AER_DAEMON"
#!/bin/sh
### BEGIN INIT INFO
# Provides:		        $AER_NAME
# Required-Start:	    $LOH_NAME
# Required-Stop:	    $LOH_NAME
# Default-Start:	    2 3 4 5
# Default-Stop:		    0 1 6
# Short-Description:	AerooDOCS daemon
# Description:		    AerooDOCS daemon
#			            Document conversion server
### END INIT INFO

case "\$1" in
  start|restart) CONFIG="-c $AER_CONFIG -f $AER_PID";;
esac

"$AEROO_DIR/aeroo_docs/aeroo-docs" "\$@" \$CONFIG && exit 0 || exit \$?
EOF

chmod +x "$AER_DAEMON"
update-rc.d $AER_NAME defaults

# The AerooDOCS program prompts the user to confirm the creation of a new
# configuration file, so the init.d script needs to be started directly
# with 'yes' piped in, but the mixed calls between the service command and
# the direct init.d script results in locking problems with the pid file.
# To avoid that situation, we ensure that service-initiated starts do not
# run concurrently with direct calls to start the init.d script.
service $AER_NAME stop
yes | "$AER_DAEMON" restart
"$AER_DAEMON" stop
service $AER_NAME start

# Odoo modules
printf "\nInstall Aeroo Reports Odoo Modules"
printf "\n----------------------------------\n"
for dir in "$AEROO_LIB" "$AEROO_DIR/aeroo_reports/report_aeroo*"; do
  ln -sf -t "$ADDONS_DIR" $dir
  chown -R --reference="$ADDONS_DIR" $dir
done

# Done
cat << MSG

>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<
RESTART ODOO SERVER TO FINALIZE THE INSTALLATION
>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<
MSG

exit 0
