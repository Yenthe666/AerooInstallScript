# Aeroo installation script
This script can be used to automatically create and configurate an Aeroo reporting server!

<h4>1. Creating an installation file</h4>
```sudo nano aero_installer.sh```

<h4>2. Configuring the installation script</h4>
Paste the code from the script inside the file you've just created and fill in the variable ```ODOO_LOCATION``` at the first line of the script to the location of where you have an Odoo running.
For example if you have an Odoo running under ```/odoo/odoo-server/``` you would fill in ```ODOO_LOCATION="/odoo/odoo-server"```.<br/>
Tip: The path is always one directory less then where the addons folder is! So if you see the addons folder under ```/odoo/odoo-server/addons``` you should remove ```/addons``` from the path.

<h4>2. Making the file executable</h4>
```sudo chmod +x aero_installer.sh```

<h4>3. Executing the script</h4>
```./aero_installer.sh ```
