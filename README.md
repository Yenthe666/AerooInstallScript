# Aeroo Installation Script
Installs Aeroo and makes the Aeroo reporting engine available in Odoo V9.

#### Get the source
Clone this repository:

```git clone https://github.com/osluys/AerooInstallScript.git```

or copy and paste the source to a file called _aero_installer.sh_.

#### Configure the install script
Edit the script and change the location of `ODOO_DIR` to your Odoo installation.

#### Make the script executable
```sudo chmod +x aero_installer.sh```

#### Run the script
```sudo ./aero_installer.sh ```

#### Enable Aeroo reporting engine in Odoo
  1. Restart Odoo and update the _Apps_ list
  2. Install the _Aeroo Reports_ app

#### To uninstall
```sudo ./aero_installer.sh -u```
