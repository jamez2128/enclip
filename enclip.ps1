
<#PSScriptInfo

.VERSION 1.0.1

.GUID e73628f1-8093-4234-ba9d-ebcf119317d7

.AUTHOR jamez2128

.LICENSEURI https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html

.PROJECTURI https://github.com/jamez2128/enclip

#>

<# 

.DESCRIPTION 
 Simple Clipboard Manager script with encryption 

#> 

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Web
Add-Type -AssemblyName System.Drawing
$versionNumber = "1.0.1"

# I HAD TO DO THIS TO GET RID OF THAT STUPID SUGGESTION THING!
$scriptName = $script:MyInvocation.MyCommand.Name
if ([string]::IsNullOrEmpty((Get-Command -CommandType ExternalScript | Where-Object { $_.Name -match [regex]::Escape($scriptName) }))) {
    $isRanInPath = $false
} else {
    $isRanInPath = $script:MyInvocation.MyCommand.Path -eq (Get-Command "$scriptName" -ErrorAction SilentlyContinue).Source
}


function _printVersionNumber() {
    Write-Output "$versionNumber"
}

function _versionMessage() {
    Write-Output "enclip $versionNumber

GitHub repository: https://github.com/jamez2128/enclip
Licence: GPL v2 https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html
Written by: jamez2128
"
}

function _helpMessage() {
    $text = "enclip - Simple Clipboard Manager script with encryption

Usage:
$($script:MyInvocation.InvocationName) [operation]
    
Operations:
encrypt`t`t`t`t  - Encrypts a text or QR code from clipboard
decrypt`t`t`t`t  - Decrypts encrypted file and copies it to clipboard
otp-code`t`t`t  - Converts decrypted text to a 2FA code
export-qr-code`t`t`t  - Decrypts encrypted file and encodes it into QR code
create-key`t`t`t  - Creates a gpg key pair for encrypting and decrypting
delete-key`t`t`t  - Deletes a gpg key pair
edit-key`t`t`t  - Edit a gpg key pair using a gpg prompt
import-key`t`t`t  - Imports a gpg key from a file
export-key`t`t`t  - Exports a gpg key to a file
config-location`t`t`t  - Shows the path to the config file's location
data-location`t`t`t  - Shows the path to the encrypted files
keys-location`t`t`t  - Shows the gnupg's home directory the script uses"
    if ($isRanInPath) {
        $text = "$text
uninstall`t`t`t  - Uninstalls the script from User's AppData Directory
create-shortcuts-in-start-menu`t  - Recreates shortcuts in to the start menu"
    } else {
        $text = "$text
install`t`t`t`t  - Installs the script to the User's AppData Directory
create-shortcuts-portable`t  - Creates shortcuts that is for portable install"
    }
    $text = "$text
help`t`t`t`t  - Shows this message
version`t`t`t`t  - Shows the version of the script
version-only`t`t - Prints only the version number"
    if (-not $isRanInPath) {
    $text = "$text

If you want a portable install, you can freely use this script as is
and change the configs as needed"
    }
    $text = "$text

For full documentation, refer to the README.md file at
https://github.com/jamez2128/enclip/blob/master/README.md"
    Write-Output "$text"

}

function _sendNotification($dialogMessage, $dialogIcon) {
    $notification = New-Object System.Windows.Forms.NotifyIcon
    $path = (Get-Process -id $pid).Path
    $notification.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
    if (-not [string]::IsNullOrEmpty($dialogIcon)) { $notification.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::$dialogIcon } 
    $notification.BalloonTipTitle = $script:MyInvocation.MyCommand.Name
    $notification.BalloonTipText = "$dialogMessage"
    $notification.Visible = $true
    $notification.ShowBalloonTip(6000)

    $notification.Dispose()
}

function _textBox($labelText) {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $script:MyInvocation.MyCommand.Name
    $form.Size = New-Object System.Drawing.Size(300,200)
    $form.StartPosition = 'CenterScreen'
    $form.MaximizeBox = $false
    $form.FormBorderStyle = "FixedDialog"
    
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(75,120)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(150,120)
    $cancelButton.Size = New-Object System.Drawing.Size(75,23)
    $cancelButton.Text = 'Cancel'
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)
    
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(280,40)
    $label.Text = "$labelText"
    $form.Controls.Add($label)
    
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10,60)
    $textBox.Size = New-Object System.Drawing.Size(260,20)
    $form.Controls.Add($textBox)
    
    $form.Topmost = $true
    
    $form.Add_Shown({$textBox.Select()})
    
    if ($form.ShowDialog() -eq [System.Windows.Forms.DialogResult]::Cancel) {
        $label.Dispose()
        $cancelButton.Dispose()
        $okButton.Dispose()
        $form.Dispose()
        exit 1
    }
    $userEntered = $textBox.Text
    $label.Dispose()
    $cancelButton.Dispose()
    $okButton.Dispose()
    $form.Dispose()
    return $userEntered
}

function _selectFromList($labelMessage, [string[]]$options, $returnType) {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $script:MyInvocation.MyCommand.Name
    $form.Size = New-Object System.Drawing.Size(400,200)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = 0

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(125,130)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(200,130)
    $cancelButton.Size = New-Object System.Drawing.Size(75,23)
    $cancelButton.Text = 'Cancel'
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(5,5)
    $label.Size = New-Object System.Drawing.Size(384,40)
    $label.Text = "$labelMessage"
    $form.Controls.Add($label)

    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(10,50)
    $listBox.Size = New-Object System.Drawing.Size(365,20)
    $listBox.Height = 80

    foreach ($option in $options) {
        [void] $listBox.Items.Add("$option")
    }
    $listBox.SelectedIndex = 0

    $form.Controls.Add($listBox)
    $form.Controls.Add($okButton)
    $form.Controls.Add($cancelButton)

    $form.Topmost = $true

    if ($form.ShowDialog() -eq "Cancel") {
        $label.Dispose()
        $okButton.Dispose()
        $cancelButton.Dispose()
        $form.Dispose()
        exit 1
    }
    $selectedItem = $listBox.$returnType
    $label.Dispose()
    $okButton.Dispose()
    $cancelButton.Dispose()
    $form.Dispose()
    return $selectedItem
}

function _createConfig($path) {
    $dir = $path -replace "\\[^\\]*$",""
    if ( -Not (Test-Path -Path "$dir") ) { New-Item "$dir" -Type Directory }
    Write-Output '# Uncomment below where to save and read the encrypted files
# $ENCLIP_HOME = "$PSScriptRoot\data"

# Default key to use everytime you encrypt
 $recipient = ""

# Uncomment below if you want symmetric encryption by default (Note: This will ignore the $recipient config)
# $defaultSymmetric = " "

# Uncomment below to specify GNUPG data path and the script to use (Note: this is where your keys are located)
# $gnupgHome = "$PSScriptRoot\.gnupg"

# Uncomment below to specify and set a custom GNUPG program path
# $gnupgBinDir = "$PSScriptRoot\gnupg-portable\app\bin"

# Uncomment below to specify and set a custom path to the oathtool.exe program
# $oathtool = "$PSScriptRoot\oath-toolkit\oathtool.exe"

# Uncomment below to specify and set a custom ZBar program path
# $zbarBinDir = "$PSScriptRoot\ZBar\bin"

# Uncomment below to specify and set a custom path to the qrencode.exe program
# $qrencode = "$PSScriptRoot\libencode\qrencode.exe"

# Uncomment below if you want the generated QR Code to open automatically
# $qRCodeAutoOpen = ""' > $path
}

function _checkConfigs() {
    # Use env variable if it is the script is ran in Path
    if ($isRanInPath -and [string]::IsNullOrEmpty($ENCLIP_HOME)) { $script:ENCLIP_HOME = $env:ENCLIP_HOME }

    # If the config file didn't specify a directory or env variable is empty, the defaults will be used
    # Default for user install: $env:APPDATA\enclip
    # Default for portable install: Same location as the script
    if ([string]::IsNullOrEmpty($ENCLIP_HOME)) {
        if ($isRanInPath) { $script:ENCLIP_HOME = "$env:APPDATA\enclip" }
        else { $script:ENCLIP_HOME = "$PSScriptRoot\data" }
    }

    # Create a new Directory if doesn't exist yet
    if (-Not (Test-Path -Path "$script:ENCLIP_HOME")) { New-Item "$script:ENCLIP_HOME" -Type Directory }

    # Checking paths for dependencies if they exists, if it doesn't it will use the PATH env variable
    # Adding a \ for programs with multiple executables in a directory
    if ((-Not [string]::IsNullOrEmpty($script:gnupgBinDir)) -and ($script:gnupgBinDir.Substring($script:gnupgBinDir.length - 1) -ne "\")) { $script:gnupgBinDir = "$gnupgBinDir\" }
    if ((-Not [string]::IsNullOrEmpty($script:gnupgBinDir)) -and -not ( Test-Path -Path "$script:gnupgBinDir" -PathType "Container")) { $script:gnupgBinDir = "" }
    if (([string]::IsNullOrEmpty($script:oathtool)) -or -not (Test-Path -Path "$script:oathtool")) { $script:oathtool = "oathtool.exe" }
    if ([string]::IsNullOrEmpty($script:qrencode) -or -not (Test-Path -Path "$script:qrencode")) { $script:qrencode = "qrencode.exe" }
    if ((-Not [string]::IsNullOrEmpty($script:zbarBinDir)) -and ($script:zbarBinDir.Substring($zbarBinDir.length - 1) -ne "\")) { $script:zbarBinDir = "$zbarBinDir\" }
    if ((-Not [string]::IsNullOrEmpty($script:zbarBinDir)) -and -not ( Test-Path -Path "$script:zbarBinDir" -PathType "Container")) { $script:zbarBinDir = "" }

    # For QR code output location
    if ($isRanInPath) { $script:qrInitDir = "$env:USERPROFILE\Desktop" }
    else { $script:qrInitDir = "$PSScriptRoot" }

    # Checking if GNUPG is installed
    if (-not (Get-Command "${script:gnupgBinDir}gpg.exe" -ErrorAction SilentlyContinue)) { _sendNotification "GNUPG is not installed" "Error" ; exit 127 }

    # Checking if GNUPGHOME exists
    if ([string]::IsNullOrEmpty($gnupgHome) -and -not $isRanInPath) { $script:gnupgHome = "$PSScriptRoot\.gnupg" }
    if (-not [string]::IsNullOrEmpty($gnupgHome) -and -not (Test-Path -Path "$gnupgHome")) {
        $newgnupgHome = New-Item -ItemType Directory "$gnupgHome"
        $newgnupgHome.Attributes = "hidden"
    }

    # Adding arguments for gpg commands if it is specified in the config file
    if (-not [string]::IsNullOrEmpty($gnupgHome)) { $script:gnupgHomeDirArg = "--homedir" ; $script:gnupgHome = "`"$gnupgHome`"" }
}

function _selectFile() {
    $script:FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = "$ENCLIP_HOME"
    Filter = 'gpg File|*.gpg|pgp File|*.pgp|All Files|*' 
    }
    if ( $($script:FileBrowser.ShowDialog()) -eq "Cancel" ) { $script:FileBrowser.Dispose() ; exit 1 }
}

function _decryptFile() {
    $fileName = $script:FileBrowser.FileName
    $script:FileBrowser.Dispose()
    $gpgOutput = & "${gnupgBinDir}gpg.exe" $gnupgHomeDirArg $gnupgHome -d "$fileName" 2>&1
    $isDecrypted = $LASTEXITCODE
    if ( $isDecrypted -ne 0 ) {
        $gpgErr = ((("$($gpgOutput | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] })" -split "gpg:").Trim() | Select-String "^encrypted with" -NotMatch) -join "`n").Trim()
        _sendNotification "$gpgErr" "Error" ; exit $gpgExitCode
    }
    
    return ($gpgOutput | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] })
}

function _decrypt() {
    _selectFile
    Set-Clipboard $(_decryptFile)
    if ($LASTEXITCODE -eq 0) { _sendNotification "Copied to clipboard successfully" "" }
    exit 0
}

# Thanks to this script for making this possible without oathtool https://gist.github.com/jonfriesen/234c7471c3e3199f97d5
function Get-Otp($SECRET, $LENGTH, $WINDOW){
    $hmac = New-Object -TypeName System.Security.Cryptography.HMACSHA1
    $hmac.key = Convert-HexToByteArray(Convert-Base32ToHex(($SECRET.ToUpper())))
    $timeBytes = Get-TimeByteArray $WINDOW
    $randHash = $hmac.ComputeHash($timeBytes)
    
    $offset = $randhash[($randHash.Length-1)] -band 0xf
    $fullOTP = ($randhash[$offset] -band 0x7f) * [math]::pow(2, 24)
    $fullOTP += ($randHash[$offset + 1] -band 0xff) * [math]::pow(2, 16)
    $fullOTP += ($randHash[$offset + 2] -band 0xff) * [math]::pow(2, 8)
    $fullOTP += ($randHash[$offset + 3] -band 0xff)

    $modNumber = [math]::pow(10, $LENGTH)
    $otp = $fullOTP % $modNumber
    $otp = $otp.ToString("0" * $LENGTH)
    return $otp
}

function Get-TimeByteArray($WINDOW) {
    $span = (New-TimeSpan -Start (Get-Date -Year 1970 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0) -End (Get-Date).ToUniversalTime()).TotalSeconds
    $unixTime = [Convert]::ToInt64([Math]::Floor($span/$WINDOW))
    $byteArray = [BitConverter]::GetBytes($unixTime)
    [array]::Reverse($byteArray)
    return $byteArray
}

function Convert-HexToByteArray($hexString) {
    $byteArray = $hexString -replace '^0x', '' -split "(?<=\G\w{2})(?=\w{2})" | ForEach-Object { [Convert]::ToByte( $_, 16 ) }
    return $byteArray
}

function Convert-Base32ToHex($base32) {
    $base32chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    $bits = "";
    $hex = "";

    for ($i = 0; $i -lt $base32.Length; $i++) {
        $val = $base32chars.IndexOf($base32.Chars($i));
        $binary = [Convert]::ToString($val, 2)
        $staticLen = 5
        $padder = '0'
            # Write-Host $binary
        $bits += Add-LeftPad $binary.ToString()  $staticLen  $padder
    }


    for ($i = 0; $i+4 -le $bits.Length; $i+=4) {
        $chunk = $bits.Substring($i, 4)
        # Write-Host $chunk
        $intChunk = [Convert]::ToInt32($chunk, 2)
        $hexChunk = Convert-IntToHex($intChunk)
        # Write-Host $hexChunk
        $hex = $hex + $hexChunk
    }
    return $hex;

}

function Convert-IntToHex([int]$num) {
    return ('{0:x}' -f $num)
}

function Add-LeftPad($str, $len, $pad) {
    if(($len + 1) -ge $str.Length) {
        while (($len - 1) -ge $str.Length) {
            $str = ($pad + $str)
        }
    }
    return $str;
}

function _genOtpCode($otpURL) {
    if (-not [System.Uri]::IsWellFormedUriString("$otpURL", "Absolute") -or $otpURL -notmatch "^otpauth://") { _sendNotification "The decrypted file is not a valid OTP URL" "Error" ; $script:FileBrowser.Dispose() ; exit 1 }
    $parseOtpUrl = [System.Web.HttpUtility]::ParseQueryString(([uri]"$otpURL").Query)
    $otpType = $([uri]$otpURL).Host
    if ($otpType -eq "hotp") { _sendNotification "TOTP is only supported" "Warning" ; exit 1 }
    if (-not [string]::IsNullOrEmpty($parseOtpUrl["algorithm"])) { $otpAlgorithm = $parseOtpUrl["algorithm"].toLower() } elseif ($otpType -eq "totp") { $otpAlgorithm = "sha1" }
    if ($otpType -eq "totp" ) { $otpType = "$otpType=" }
    if (-not [string]::IsNullOrEmpty($parseOtpUrl["counter"])) { $otpCounter = "--counter=" + $parseOtpUrl["counter"] }
    if (-not [string]::IsNullOrEmpty($parseOtpUrl["period"])) { $otpPeriod = $parseOtpUrl["period"] } else { $otpPeriod = 30 }
    if (-not [string]::IsNullOrEmpty($parseOtpUrl["digits"])) { $otpDigits = $parseOtpUrl["digits"] } else { $otpDigits = 6 }
    $otpSecret = $parseOtpUrl["secret"]
    if (-not (Get-Command($oathtool) -ErrorAction SilentlyContinue)) { return Get-Otp "$otpSecret" "$otpDigits" "$otpPeriod" }
    $otpCode = $(& "$oathtool" -b --$otpType$otpAlgorithm $otpCounter --time-step-size=$otpPeriod --digits=$otpDigits "$otpSecret" ; $oathtoolExitCode = $LASTEXITCODE)
    if ($oathtoolExitCode -ne 0) {
        return Get-Otp "$otpSecret" "$otpDigits" "$otpPeriod"
    }
    return "$otpCode"
}

function _otpCode() {
    _selectFile
    Set-Clipboard "$(_genOtpCode $(_decryptFile))"
    _sendNotification "OTP code copied" ""
    exit 0
}

function _encodeQRCode($fileName, $textToEncode) {
    & "$qrencode" -t PNG -o "$fileName" "$textToEncode"
    $qrencodeExitCode = $LASTEXITCODE
    if ($qrencodeExitCode -eq 0) {
        _sendNotification "QR Code Generated in`n$fileName" ""
        if ( -Not ([string]::IsNullOrEmpty($qRCodeAutoOpen)) ) { Start-Process "$fileName" }
        exit 0
    } else {
        _sendNotification "Something went wrong with the with the $qrencode program`nExit Code: $qrencodeExitCode" "Error"
        exit $qrencodeExitCode
    }
    
}

function _exportQRCode() {
    if (-not (Get-Command "$qrencode" -ErrorAction SilentlyContinue)) { _sendNotification "qrencode is not installed" "Error" ; exit 127 }
    _selectFile
    $qRCodeImageName = $script:FileBrowser.SafeFileName -replace '\.gpg$','.png'
    $qrCodePath = New-Object System.Windows.Forms.SaveFileDialog -Property @{ InitialDirectory = "$script:qrInitDir"
    Filter = 'pgp File|*.png|All Files|*'
    FileName = "$qRCodeImageName"
    }
    if ($qrCodePath.ShowDialog() -eq "Cancel") {
        $qrCodePath.Dispose()
        $script:FileBrowser.Dispose()
        exit 1
    }
    _encodeQRCode "$($qrCodePath.FileName)" "$(_decryptFile)"
}

# Gets a list of keys using gpg --with-colons and parses it
function _getKeyList() {
    $gpgWithColons = & "${gnupgBinDir}gpg.exe" $gnupgHomeDirArg $gnupgHome -k --with-colons
    $script:uids = @($gpgWithColons | Select-String "^uid" | ForEach-Object { ([string]$_).Split(":")[9] })
    $script:keyIds = @($gpgWithColons | Select-String "^pub" | ForEach-Object { ([string]$_).Split(":")[4] })
    $keyList = New-Object string[]($keyIds.Count)
    for ($i = 0; $i -lt $keyList.Count; $i++) {
        $keyList[$i] = $uids[$i] + " " + $keyIds[$i]
    }
    return $keyList
}

function _saveFile() {
    # Will open a Dialog box to choose a key if it is not specified in the config file
    if ([string]::IsNullOrEmpty($recipient) -or -not [string]::IsNullOrEmpty($defaultSymmetric)) {
        $optionsInList = @(_getKeyList)
        $optionsInList += "no key (Symmetric encryption)"
        $selectedIndex = _selectFromList "(Note: You can specify a key in `$recipient in the config file if you do not want to be asked again)`nChoose a key to encrypt with: " $optionsInList "SelectedIndex"
        switch ($selectedIndex) {
            { $optionsInList.Count - 1 } { $script:recipient = "" }
            Default { $script:recipient = $keyIds[$selectedIndex] }
        }
        if ($selectedIndex -eq $optionsInList.Count - 1) {
            $recipient = ""
        } else {
            $script:recipient = $keyIds[$selectedIndex]
        }
    }

    # Opens up file dialog
    if (-not [string]::IsNullOrEmpty($defaultSymmetric)) { $recipient = "" }
    $script:FileBrowser = New-Object System.Windows.Forms.SaveFileDialog -Property @{ InitialDirectory = "$ENCLIP_HOME"
    Filter = 'gpg File|*.gpg|pgp File|*.pgp|All Files|*'
    }
    if ( $($script:FileBrowser.ShowDialog()) -eq "Cancel" ) { $script:FileBrowser.Dispose() ; exit 1 }
}

function _encryptFile($textToEncrypt) {
    # Runs the gpg encryption if a key is not specifed, it will use symmetric encryption
    $fileName = $script:FileBrowser.FileName
    if ([string]::IsNullOrEmpty($recipient)) {
        $gpgOutput = Write-Output "$textToEncrypt" | & "${gnupgBinDir}gpg.exe" $gnupgHomeDirArg $gnupgHome --batch --yes --armor -c --no-symkey-cache --cipher-algo AES256 -o "$fileName" 2>&1

    } else {
        $gpgOutput = Write-Output "$textToEncrypt" | & "${gnupgBinDir}gpg.exe" $gnupgHomeDirArg $gnupgHome --batch --yes --armor -e -r "$recipient" -o "$fileName" 2>&1
    }
    $gpgExitCode = $LASTEXITCODE
    $script:FileBrowser.Dispose()
    if ($gpgExitCode -eq 0) { _sendNotification "Encrypted Successfully" "" }
    else {
        $gpgOutput = ((("$($gpgOutput | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] })" -split "gpg:").Trim() | Select-String "^encrypted with" -NotMatch) -join "`n").Trim()
        _sendNotification "$gpgOutput" "Error" ; exit $gpgExitCode
    }
    exit 0
}

# Converts QR Code to text
function _decodeQRCodeFromImage($fileName) {
    $decodedText = $(& "${zbarBinDir}zbarimg.exe" -q --raw "$fileName" ; $zbarExitCode = $LASTEXITCODE)
    if ( $zbarExitCode -ne 0 ) {
        _sendNotification "Image is not a QR code" "Error"
        exit $zbarExitCode
    }
    return $decodedText
}

# Converts QR Code to text and decrypts it
function _encryptQRCode() {
    if (-not (Get-Command "${zbarBinDir}zbarimg.exe" -ErrorAction SilentlyContinue)) { _sendNotification "ZBar is not installed" "Error" ; exit 127 }
    $tempFile = (New-TemporaryFile).FullName + ".png"
    (Get-Clipboard -Format Image).Save("$tempFile")
    $decodedText = _decodeQRCodeFromImage "$tempFile"
    Remove-Item "$tempFile"
    _saveFile
    _encryptFile "$decodedText"
}

function _encrypt() {
    if (Get-Clipboard -Format Image) { _encryptQRCode }
    if ([string]::IsNullOrEmpty($(Get-Clipboard -raw))) {  _sendNotification "Clipboard did not contain a text or a QR Code" "Error" ; exit 1 }
    _saveFile
    _encryptFile "$(Get-Clipboard -raw)"
}

function _createKey() {
    $inputBox = _textBox "Note: You can add comment by putting it inside () and add email by putting it inside <> and both are optional`nEnter the name of the key: "
    $nameReal = ($inputBox -replace "\(([^\)]+)\)","" -replace "<([^\)]+)>","").Trim()
    if ($inputBox -match "\(([^\)]+)\)") { $nameComment = "Name-Comment: " + (([regex]"\(([^\)]+)\)").Matches("$inputBox") | ForEach-Object { $_.Value -replace "^\(","" -replace "\)$","" }) }
    if ($inputBox -match "<([^\)]+)>") { $nameEmail = "Name-Email: " + (([regex]"<([^\)]+)>").Matches("$inputBox") | ForEach-Object { $_.Value -replace "^<","" -replace ">$","" }) }
    if ([string]::IsNullOrEmpty($nameReal)) { _sendNotification "You must enter a key name" "Error" ; exit 1 }
    if ($nameReal.length -lt 5) { _sendNotification "Key name must be at least 5 characters long" "Error" ; exit 1 }
    $tempFile = (New-TemporaryFile).FullName
    Write-Output "Key-Type: RSA
Key-Length: 4096
Key-Usage: sign
Subkey-Type: RSA
Subkey-Length: 4096
Subkey-Usage: encrypt
Name-Real: $nameReal
$nameComment
$nameEmail
Expire-Date: 0" > "$tempFile"
    $gpgExitCode = cmd.exe /c "type `"$tempFile`" | `"${gnupgBinDir}gpg.exe`" $gnupgHomeDirArg $gnupgHome --batch --gen-key
exit %errorlevel%"
    $gpgExitCode = $LASTEXITCODE
    if (Test-Path -Path "$tempFile") { Remove-Item $tempFile }
    if ($gpgExitCode -eq 0) {
        _sendNotification "Key Created Successfully" "Info"
        exit 0
    } else {
        _sendNotification "Key Creation Failed" "Error"
        exit 1
    }
}

function _editKey() {
    $optionsInList = @(_getKeyList)
    if ([string]::IsNullOrEmpty($optionsInList)) { _sendNotification "No keys created yet" "Error" ; exit 1 }
    for ($i = 0; $i -lt $optionsInList.Count; $i++) {
        $optionsInList[$i] = "[$i] " + $optionsInList[$i]
    }
    $selectedIndex = Read-Host -Prompt "$($optionsInList -join "`n")`nSelect a key to edit"
    if ($selectedIndex -lt $keyIds.Count -and -not [string]::IsNullOrEmpty($selectedIndex)) {
        $selectedKey = $keyIds[$selectedIndex]
    } else {
        exit 1
    }
    & "${gnupgBinDir}gpg.exe" $gnupgHomeDirArg $gnupgHome --edit-key "$selectedKey"
    exit 0
}

function _deleteKey() {
    $optionsInList = @(_getKeyList)
    if ([string]::IsNullOrEmpty($optionsInList)) { _sendNotification "No keys created yet" "Error" ; exit 1 }
    for ($i = 0; $i -lt $optionsInList.Count; $i++) {
        $optionsInList[$i] = "[$i] " + $optionsInList[$i]
    }
    $selectedIndex = Read-Host -Prompt "$($optionsInList -join "`n")`nSelect a key to delete" 
    if ($selectedIndex -lt $keyIds.Count -and -not [string]::IsNullOrEmpty($selectedIndex)) {
        $selectedKey = $keyIds[$selectedIndex]
    } else {
        exit 1
    }

    & "${gnupgBinDir}gpg.exe" $gnupgHomeDirArg $gnupgHome --delete-secret-and-public-key "$selectedKey"
    if ($LASTEXITCODE -eq 0) { _sendNotification "Key deleted successfully" "Info" ; exit 0 }
    else { exit $LASTEXITCODE }
}

function _importKey() {
    if ($isRanInPath) { $initDir = "$env:USERPROFILE\Desktop" } else { $initDir = "$PSScriptRoot" }
    $fileInput = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = "$initDir"
    Filter = 'key File|*.key|All Files|*' 
    }
    if ($fileInput.ShowDialog() -eq 'Cancel') { $fileInput.Dispose() ; exit 1 }
    $fileName = $fileInput.FileNames
    & "${gnupgBinDir}gpg.exe" $gnupgHomeDirArg $gnupgHome --import "$fileName"
    if ($LASTEXITCODE -eq 0) { _sendNotification "Key imported sucessfully" "Info" ; exit 0 } else { _sendNotification "Key import failed" "Error" ; exit 1 }
}

function _exportKey() {
    $keyList = @(_getKeyList)
    if ([string]::IsNullOrEmpty($keyList)) { _sendNotification "No keys created yet" "Error" ; exit 1 }
    $keyIndex = _selectFromList "Select a key to export:" $keyList "SelectedIndex"
    $key = $keyIds[$keyIndex]
    if ($isRanInPath) { $initDir = "$env:USERPROFILE\Desktop" } else { $initDir = "$PSScriptRoot" }
    $fileOutput = New-Object System.Windows.Forms.SaveFileDialog -Property @{ InitialDirectory = "$initDir"
    Filter = 'key File|*.key|All Files|*'
    FileName = ($uids[$keyIndex].Split([IO.Path]::GetInvalidFileNameChars()) -join '' -replace "[\(\)]","" -replace " ","_" ) + "_" + $keyIds[$keyIndex] + ".key"
    }
    if ($fileOutput.ShowDialog() -eq 'Cancel') { $fileOutput.Dispose() ; exit 1 }
    $fileName = $fileOutput.FileNames
    & "${gnupgBinDir}gpg.exe" $gnupgHomeDirArg $gnupgHome --batch --yes --export-secret-key -o "$fileName" "$key"
    if ($LASTEXITCODE -eq 0) { _sendNotification "Key exported to`n$fileName" "Info" ; exit 0 }
    else { _sendNotification "Key export failed" "Error" ; exit 1 }
}

function _printGnupgHomeDir() {
    & "${gnupgBinDir}gpg.exe" $gnupgHomeDirArg $gnupgHome --version | Select-String "^Home: " | ForEach-Object { $_ -replace "^Home:\s",""}
}

function _createShortcut($target, $arguments, $windowStyle, $linkName) {
    $Shortcut = (New-Object -comObject WScript.Shell).CreateShortcut("$linkName")
    $Shortcut.WindowStyle = $windowStyle
    $Shortcut.TargetPath = "$target"
    $Shortcut.Arguments = "$arguments"
    $Shortcut.Save()
}

function _createShortcutStartMenu() {
    $path = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\enclip"
    if (-not (Test-Path -Path "$path")) {
        New-Item -ItemType Directory -Path "$path"
    }
    _createShortcut "powershell.exe" "-NoProfile -WindowStyle hidden -ExecutionPolicy Bypass -Command `"enclip.ps1 encrypt`"" 7 "$path\enclip encrypt.lnk"
    _createShortcut "powershell.exe" "-NoProfile -WindowStyle hidden -ExecutionPolicy Bypass -Command `"enclip.ps1 decrypt`"" 7 "$path\enclip decrypt.lnk"
    _createShortcut "powershell.exe" "-NoProfile -WindowStyle hidden -ExecutionPolicy Bypass -Command `"enclip.ps1 otp-code`"" 7 "$path\enclip otp-code.lnk"
    _createShortcut "powershell.exe" "-NoProfile -WindowStyle hidden -ExecutionPolicy Bypass -Command `"enclip.ps1 export-qr-code`"" 7 "$path\enclip export-qr-code.lnk"
    _createShortcut "powershell.exe" "-NoProfile -WindowStyle hidden -ExecutionPolicy Bypass -Command `"enclip.ps1 create-key`"" 7 "$path\enclip create-key.lnk"
    _createShortcut "powershell.exe" "-NoProfile -WindowStyle hidden -ExecutionPolicy Bypass -Command `"enclip.ps1 import-key`"" 7 "$path\enclip import-key.lnk"
    _createShortcut "powershell.exe" "-NoProfile -WindowStyle hidden -ExecutionPolicy Bypass -Command `"enclip.ps1 export-key`"" 7 "$path\enclip export-key.lnk"
    _createShortcut "powershell.exe" '-NoProfile -ExecutionPolicy Bypass -Command "enclip.ps1 edit-key"' 0 "$path\enclip edit-key.lnk"
    _createShortcut "powershell.exe" '-NoProfile -ExecutionPolicy Bypass -Command "enclip.ps1 delete-key"' 0 "$path\enclip delete-key.lnk"
    _createShortcut "powershell.exe" "-NoProfile -WindowStyle hidden -ExecutionPolicy Bypass -Command `"enclip.ps1 uninstall`"" 7 "$path\enclip uninstall.lnk"
    _createShortcut "powershell.exe" '-NoProfile -WindowStyle hidden -ExecutionPolicy Bypass -Command "explorer.exe /select,$(enclip config-location)"' 7 "$path\enclip config-location.lnk"
    _createShortcut "powershell.exe" '-NoProfile -WindowStyle hidden -ExecutionPolicy Bypass -Command "Start-Process $(enclip.ps1 data-location)"' 7 "$path\enclip data-location.lnk"
    _createShortcut "powershell.exe" '-NoProfile -WindowStyle hidden -ExecutionPolicy Bypass -Command "explorer.exe /select,$(enclip keys-location)"' 7 "$path\enclip keys-location.lnk"
    _createShortcut "powershell.exe" "-NoProfile -ExecutionPolicy Bypass -Command `"enclip.ps1 help ; pause`"" 0 "$path\enclip help.lnk"
}

function _createShortcutsPortable() {
    _createShortcut "powershell.exe" "-NoProfile -WindowStyle hidden -ExecutionPolicy Bypass -Command `".\enclip.ps1 encrypt`"" 7 "$PSScriptRoot\encrypt.lnk"
    _createShortcut "powershell.exe" "-NoProfile -WindowStyle hidden -ExecutionPolicy Bypass -Command `".\enclip.ps1 decrypt`"" 7 "$PSScriptRoot\decrypt.lnk"
    _createShortcut "powershell.exe" "-NoProfile -WindowStyle hidden -ExecutionPolicy Bypass -Command `".\enclip.ps1 otp-code`"" 7 "$PSScriptRoot\otp-code.lnk"
    _createShortcut "powershell.exe" "-NoProfile -WindowStyle hidden -ExecutionPolicy Bypass -Command `".\enclip.ps1 export-qr-code`"" 7 "$PSScriptRoot\export-qr-code.lnk"
    _createShortcut "powershell.exe" "-NoProfile -WindowStyle hidden -ExecutionPolicy Bypass -Command `".\enclip.ps1 create-key`"" 7 "$PSScriptRoot\create-key.lnk"
    _createShortcut "powershell.exe" "-NoProfile -WindowStyle hidden -ExecutionPolicy Bypass -Command `".\enclip.ps1 import-key`"" 7 "$PSScriptRoot\import-key.lnk"
    _createShortcut "powershell.exe" "-NoProfile -WindowStyle hidden -ExecutionPolicy Bypass -Command `".\enclip.ps1 export-key`"" 7 "$PSScriptRoot\export-key.lnk"
    _createShortcut "powershell.exe" '-NoProfile -ExecutionPolicy Bypass -Command ".\enclip.ps1 edit-key"' 0 "$PSScriptRoot\edit-key.lnk"
    _createShortcut "powershell.exe" '-NoProfile -ExecutionPolicy Bypass -Command ".\enclip.ps1 delete-key"' 0 "$PSScriptRoot\delete-key.lnk"
    _createShortcut "powershell.exe" "-NoProfile -ExecutionPolicy Bypass -Command `".\enclip.ps1 help ; pause`"" 0 "$PSScriptRoot\help.lnk"
    _sendNotification "Shortcuts have been created" "Info"
    exit 0
}

function _install {
    if ($isRanInPath) {
        _sendNotification "This command cannot be ran on the installed script" "Info"
        exit 1
    }
    $installPath = "$env:LOCALAPPDATA\Programs\enclip"
    if ($installPath -match ";") { $installPathWithQuotes = "`"$installPath`"" } else { $installPathWithQuotes = $installPath }
    if (([System.Environment]::GetEnvironmentVariable('PATH', "User")) -match [regex]::Escape("$installPathWithQuotes") -and (Test-Path -Path "$installPath\$($script:MyInvocation.MyCommand.Name)")) {
        _sendNotification "$($script:MyInvocation.MyCommand.Name) is already installed" "Info"
        exit 1
    }
    if (-not (Test-Path -Path "$installPath")) { New-Item -ItemType Directory -Path "$installPath" }
    if (([System.Environment]::GetEnvironmentVariable('PATH', "User")) -notmatch [regex]::Escape("$installPathWithQuotes")) {
        [Environment]::SetEnvironmentVariable("PATH", "$([System.Environment]::GetEnvironmentVariable('PATH', "User"));$installPathWithQuotes", [System.EnvironmentVariableTarget]::User)
    }
    if (Test-Path -Path "$PSScriptRoot\enclip_config.ps1") {
        Copy-Item -Path "$($script:MyInvocation.MyCommand.Path)" -Destination "$installPath"
        
    } else {
        Move-Item -Path "$($script:MyInvocation.MyCommand.Path)" -Destination "$installPath"
    }
    if (-not (Test-Path -Path "$env:LOCALAPPDATA\enclip\enclip_config.ps1")) { _createConfig "$env:LOCALAPPDATA\enclip\enclip_config.ps1" }
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    _createShortcutStartMenu
    _sendNotification "Installed Successfully`nShortcuts created in Start Menu" "Info"
    exit 0
}

function _uninstall() {
    if (-not $isRanInPath) { _sendNotification "This command can only be ran on the installed script" "Info" ; exit 1 }
    $installPath = Get-Command $script:MyInvocation.MyCommand.Name -ErrorAction SilentlyContinue | ForEach-Object { $_.Source -replace "\\[^\\]*$","" }
    if ($installPath -match ";") { $installPathWithQuotes = "`"$installPath`"" } else { $installPathWithQuotes = $installPath }
    $configDirPath = $script:configLocation -replace "\\[^\\]*$",""
    if ((Test-Path -Path "$configDirPath") -and (Get-ChildItem "$configDirPath" -name | Select-String "^enclip_config\.ps1" -NotMatch).Count -eq 0) {
        Remove-Item "$configDirPath" -Recurse -Force
    } elseif (Test-Path -Path "$configDirPath\enclip_config.ps1") {
        Remove-Item "$configDirPath\enclip_config.ps1" -Recurse -Force
    }
    if ($? -eq $false -and ((Test-Path -Path "$configDirPath") -or (Test-Path -Path "$configDirPath\enclip_config.ps1"))) { _sendNotification "Uninstallation failed`nClose any programs that has the config file opened and try again" "Error" ; exit 1 }
    if ((Test-Path -Path "$installPath") -and ($installPath -eq "$env:LOCALAPPDATA\Programs\enclip") -and (Get-ChildItem "$installPath" -name | Select-String "^$([regex]::Escape($script:MyInvocation.MyCommand.Name))" -NotMatch).Count -eq 0) {
        Remove-Item "$installPath"  -Recurse -Force
    } elseif (Test-Path -Path "$installPath\$($script:MyInvocation.MyCommand.Name)") {
        Remove-Item "$installPath\$($script:MyInvocation.MyCommand.Name)"  -Recurse -Force
    }
    if ($? -eq $false -and ((Test-Path -Path "$installPath") -or (Test-Path -Path "$installPath\$($script:MyInvocation.MyCommand.Name)"))) { _sendNotification "Uninstallation failed`nClose any programs that has the script opened and try again" "Error" ; exit 1 }
    if (([System.Environment]::GetEnvironmentVariable('PATH', "User")) -match [regex]::Escape("$installPathWithQuotes")) {
        $userEnvPath = [System.Environment]::GetEnvironmentVariable('PATH', "User") -split ';(?=(?:[^"]|"[^"]*")*$)'
        $userEnvPath = ($userEnvPath | Where-Object { $_ -notmatch [regex]::Escape("$installPathWithQuotes") }) -join ";"
        [Environment]::SetEnvironmentVariable("PATH", "$userEnvPath", [System.EnvironmentVariableTarget]::User)
    }
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    if (Test-Path -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\enclip") { Remove-Item -Recurse "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\enclip" }
    _sendNotification "Uninstalled Successfully" "Info"
    exit 0
}

switch ($args[0]) {
    {"--help", "-h", "help", "-help" -eq $_ } { _helpMessage ; exit 0 }
    {"version", "-v", "-version", "--version" -eq $_}  { _versionMessage ; exit 0 }
    "version-only" { _printVersionNumber ; exit 0 }
    "install" { if (-not $isRanInPath) { _install } else { _helpMessage ; exit 1 }  }
}

if ([string]::IsNullOrEmpty($args[0])) { _helpMessage ; exit 1 }

# Config file checking
if ($isRanInPath) { $configLocation = "$env:LOCALAPPDATA\enclip\enclip_config.ps1" }
else { $configLocation = "$PSScriptRoot\enclip_config.ps1" }
if (-not (Test-Path -Path "$configLocation")) { _createConfig "$configLocation" }
. "$configLocation"
_checkConfigs

switch ($args[0]) {
    "encrypt" { _encrypt }
    "decrypt" { _decrypt }
    "otp-code" { _otpCode }
    "export-qr-code" { _exportQRCode }
    "config-location" { Write-Output "$configLocation" ; exit 0 }
    "data-location" { Write-Output "$ENCLIP_HOME" ; exit 0}
    "create-key" { _createKey }
    "delete-key" { _deleteKey }
    "edit-key" { _editKey }
    "import-key" { _importKey }
    "export-key" { _exportKey }
    "keys-location" { _printGnupgHomeDir ; exit 0 }
    "uninstall" { if ($isRanInPath) { _uninstall } else { _helpMessage ; exit 1 } }
    "create-shortcuts-portable" { if (-not $isRanInPath) { _createShortcutsPortable } else { _helpMessage ; exit 1} }
    "create-shortcuts-in-start-menu" { if ($isRanInPath) { _createShortcutStartMenu ; _sendNotification "Shortcuts have been recreated" "Info" ; exit 0 } else { _helpMessage ; exit 1} }
    default { _helpMessage ; exit 1}
}
