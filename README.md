# enclip
- Simple Clipboard manager script with encryption
- It is also a password manager that utilizes the clipboard to decrypt and
encrypt
- Can be used to generate OTP codes
- Can be used portably

## Dependencies
- [gnupg](https://gnupg.org/ftp/gcrypt/binary/gnupg-w32-2.4.3_20230704.exe)
- [oathtool](https://www.nongnu.org/oath-toolkit/download.html) (Optional)
- [ZBar](https://sourceforge.net/projects/zbar/files/zbar/0.10/zbar-0.10-setup.exe/download)
(For Scanning QR Codes from clipboard)
- [qrencode](https://sourceforge.net/projects/qrencode-for-windows/files/latest/download)
(For generating QR Codes from encrypted files)

### Notes
- You don't need `oathtool` for generating OTP codes. If it is detected in
your system, it will use that instead.
- `qrencode` is optional if you intend to restore OTP codes from an authenticator
app such as `Google Authenticator`.
- `ZBar` is optional if you intend to backup or add OTP codes from websites
that uses QR codes when adding and validating them.

## Installation
- There are 2 installation types, Portable install and User install.
- Portable install is when the config file, your keys, and your data will
contain on the same location as the script.
- User Install is when the script, config file, your keys, and data will
be in the User's `AppData` Folder.

Choose your install type by following install guides below

### Portable install
For quick setup for portable install, open powershell and copy and run the command below:
```
New-Item -ItemType Directory .\enclip ; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/jamez2128/enclip/master/enclip.ps1" -OutFile ".\enclip\enclip.ps1" ; powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ".\enclip\enclip.ps1 create-shortcuts-portable"
```
You may need to tweak the config file and download your own executables
to work with other systems that may or may not have the dependencies
installed if you choose to store the script to an external storage like a
USB flash drive. 

### User install
For a quick install, open powershell and copy and run the command below
```
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/jamez2128/enclip/master/enclip.ps1" -OutFile ".\enclip.ps1" ; powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ".\enclip.ps1 install"
```

## Configuration

### Location
You can reveal the location of the config file by running
`enclip config-location`

Locations for the config file:
- For installed scripts: `$env:LOCALAPPDATA\enclip`
- For portable installs: Same location as the script

### Settings
You can set these in the config file, just uncomment by removing the `#`
before the setting to enable it and change the text between the `""`. If you
see this in the config `" "`
it means they are only for uncommenting.
- `$ENCLIP_HOME`: The default location for opening and saving files
- `$recipient`: The default key to use when encryting and will never ask for a
one when specified
- `$defaultSymmetric`: When uncommented, It will use symmetric encryption
by default and it will override `$recipient`
- `$gnupgHome`: The location where all the keys are located.
- `$qRCodeAutoOpen`: When uncommented, it will automatically open after saving
when using `enclip export-qr-code`

Below are the configs for custom paths for programs:
- `$gnupgBinDir`
- `$oathtool`
- `$zbarBinDir`
- `$qrencode`

## Uninstallation
If you choose to install it with User install, You can uninstall it by either
searching `enclip uninstall` in the Start Menu or run the command below in
powershell:
```
enclip.ps1 uninstall
```
After running, wait for it until you get a notification saying that it is now
successfully uninstalled.

If the command above didn't work, run the command below instead:
```
powershell.exe -ExecutionPolicy Bypass -Command "enclip.ps1 uninstall"
```

## Usage
You can run commands by either running them in the Start Menu or by running
them in powershell or by running shortcuts created
by `.\enclip create-shortcuts-portable`

### How to create a key
1. Run `enclip create-key`
2. Enter the name of the key
3. Wait for a notification telling you that you have successfully created
a key

### How to encrypt
1. Copy a text or a QR Code with the OTP URL
2. Run `enclip encrypt`
3. Select a key to encrypt with
(Can be skipped if a key is specified in the config file)
4. Choose a file name and directory you want it to be saved
5. Wait for a notifiction telling you that it has now been encrypted

### How to decrypt
1. Run `enclip decrypt`
2. Choose a file you want to decrypt
3. Enter the password of the key
4. Wait for a notifiction telling you that it has now been copied to clipboard

### How to generate a 2FA OTP code
1. Run `enclip otp-code`
2. Select a file with the encrypted OTP URL
3. Enter the password of the key
(Can be skipped if you've recently decrypted a file)
4. Wait for a notifiction telling you that the OTP has been copied

### How to export the QR code
Do this if you want to restore an OTP to an authenticator app
1. Run `enclip export-qr-code`
2. Select the encrypted QR Code
3. Select where you want to save the image
4. Wait for a notification telling you it has been exported to a location

## Tips and tricks
### Bind script to a hotkey
If the script is installed, you can bind the script into a hotkey using the 
created shortcuts.

If you want to bind `enclip decrypt`
1. Search `enclip decrypt` in the Start Menu
2. Right Click on it and Click `open file location`
3. Right click on the file and click `Properties`
4. Click the `Shortcut key:` and Press `Ctrl` + `Alt` +
`any letter you desire`
5. Click `Okay`

You can do the same to any operation
