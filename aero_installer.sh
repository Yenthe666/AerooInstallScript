#Fill in the path to your Odoo here
ODOO_LOCATION="/odoo9/odoo-server9"

# apt-get update
sudo aptitude update && sudo aptitude full-upgrade -y
sudo apt-get build-dep build-essential -y

# Install Git:
echo -e "\n---- Install Git ----"
sudo apt-get install git -y

# Install AerooLib:
echo -e "\n---- Install AerooLib ----"
sudo apt-get install python-genshi python-cairo python-lxml libreoffice-script-provider-python libreoffice-base python-cups -y
sudo apt-get install python-setuptools python3-pip -yf
sudo mkdir /opt/aeroo
cd /opt/aeroo
sudo git clone https://github.com/aeroo/aeroolib.git
cd /opt/aeroo/aeroolib
sudo python setup.py install

#Create Init Script for OpenOffice (Headless Mode):
echo -e "\n---- create init script for LibreOffice (Headless Mode) ----"
sudo touch /etc/init.d/office
sudo su root -c "echo '### BEGIN INIT INFO' >> /etc/init.d/office"
sudo su root -c "echo '# Provides:          office' >> /etc/init.d/office"
sudo su root -c "echo '# Required-Start:    $remote_fs $syslog' >> /etc/init.d/office"
sudo su root -c "echo '# Required-Stop:     $remote_fs $syslog' >> /etc/init.d/office"
sudo su root -c "echo '# Default-Start:     2 3 4 5' >> /etc/init.d/office"
sudo su root -c "echo '# Default-Stop:      0 1 6' >> /etc/init.d/office"
sudo su root -c "echo '# Short-Description: Start daemon at boot time' >> /etc/init.d/office"
sudo su root -c "echo '# Description:       Enable service provided by daemon.' >> /etc/init.d/office"
sudo su root -c "echo '### END INIT INFO' >> /etc/init.d/office"
sudo su root -c "echo '#! /bin/sh' >> /etc/init.d/office"
sudo su root -c "echo '/usr/bin/soffice --nologo --nofirststartwizard --headless --norestore --invisible \"--accept=socket,host=localhost,port=8100,tcpNoDelay=1;urp;\" &' >> /etc/init.d/office"

# Setup Permissions and test LibreOffice Headless mode connection

sudo chmod +x /etc/init.d/office
sudo update-rc.d office defaults

# Install AerooDOCS
echo -e "\n---- Install AerooDOCS (see: https://github.com/aeroo/aeroo_docs/wiki/Installation-example-for-Ubuntu-14.04-LTS for original post): ----"

sudo pip3 install jsonrpc2 daemonize

echo -e "\n---- create conf file for AerooDOCS ----"
sudo touch /etc/aeroo-docs.conf
sudo su root -c "echo '[start]' >> /etc/aeroo-docs.conf"
sudo su root -c "echo 'interface = localhost' >> /etc/aeroo-docs.conf"
sudo su root -c "echo 'port = 8989' >> /etc/aeroo-docs.conf"
sudo su root -c "echo 'oo-server = localhost' >> /etc/aeroo-docs.conf"
sudo su root -c "echo 'oo-port = 8100' >> /etc/aeroo-docs.conf"
sudo su root -c "echo 'spool-directory = /tmp/aeroo-docs' >> /etc/aeroo-docs.conf"
sudo su root -c "echo 'spool-expire = 1800' >> /etc/aeroo-docs.conf"
sudo su root -c "echo 'log-file = /var/log/aeroo-docs/aeroo_docs.log' >> /etc/aeroo-docs.conf"
sudo su root -c "echo 'pid-file = /tmp/aeroo-docs.pid' >> /etc/aeroo-docs.conf"
sudo su root -c "echo '[simple-auth]' >> /etc/aeroo-docs.conf"
sudo su root -c "echo 'username = anonymous' >> /etc/aeroo-docs.conf"
sudo su root -c "echo 'password = anonymous' >> /etc/aeroo-docs.conf"

cd /opt/aeroo
sudo git clone https://github.com/aeroo/aeroo_docs.git
sudo touch /etc/init.d/office
sudo python3 /opt/aeroo/aeroo_docs/aeroo-docs start -c /etc/aeroo-docs.conf
sudo ln -s /opt/aeroo/aeroo_docs/aeroo-docs /etc/init.d/aeroo-docs
sudo update-rc.d aeroo-docs defaults
sudo service aeroo-docs restart

# If you encounter and error "Unable to lock on the pidfile while trying #16 just restart the service (sudo service aeroo-docs restart).
echo -e "\n---- Install Aeroo Reports Odoo Modules: ----"
cd $ODOO_LOCATION
sudo git clone -b master https://github.com/aeroo/aeroo_reports.git

echo -e "\n >>>>>>>>>> PLEASE RESTART YOUR SERVER TO FINALISE THE INSTALLATION (See below for the command you should use) <<<<<<<<<<"
