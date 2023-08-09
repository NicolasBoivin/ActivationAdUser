# Désactiver la vérification du certificat SSL
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

# Modules necessaires
Add-Type -AssemblyName System.Windows.Forms
Import-Module ActiveDirectory

# Definition domain, credential, server et groupe
$domain = "domain"
$credential = Get-Credential
$serverAd = "nom serveur ad"
$adminGroup = "Admins du domaine"

# Fonction log
Function Log-Message {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [ValidateSet("INFO", "WARNING", "ERROR", "FIN")]
        [string]$Level,

        [Parameter(Mandatory = $false)]
        [string]$LogFile = "log.log"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Level - $Message"
    Add-content -Path $LogFile -Value $logMessage
}

# Generer mdp complexe
Function Generate-Password {
    Param (
        [int]$length = 12
    )
    $pwdCriteria = [Regex]::new('^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)')
    do {
        $password = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count $length | % { [char]$_ })
    } while (!$pwdCriteria.IsMatch($password))
    return $password
}

# Autocompletion / table des users
$usersBox = New-Object -TypeName System.Windows.Forms.ComboBox
$usersBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown

$users = Get-ADUser -Filter * -SearchBase "Chemin de l'OU" -Server $serverAd -Credential $credential | Select-Object -ExpandProperty SamAccountName
$usersBox.AutoCompleteMode = [System.Windows.Forms.AutoCompleteMode]::SuggestAppend
$usersBox.AutoCompleteSource = [System.Windows.Forms.AutoCompleteSource]::CustomSource
$usersBox.Items.AddRange($users)

# Design du popup
$dialog = New-Object -TypeName System.Windows.Forms.Form
$dialog.Size = New-Object System.Drawing.Size(200, 120)
$dialog.StartPosition = "CenterScreen"
$dialog.Text = "Entrez le nom d'utilisateur"

$expirationBox = New-Object -TypeName System.Windows.Forms.ComboBox
$expirationBox.Items.Add("6")
$expirationBox.Items.Add("12")
$expirationBox.Items.Add("24")
$expirationBox.Items.Add("48")
$expirationBox.Location = New-Object System.Drawing.Point(10, 50)
$expirationBox.Size = New-Object System.Drawing.Size(60, 20)
$dialog.Controls.Add($expirationBox)

$usersBox.Location = New-Object System.Drawing.Point(10, 10)
$usersBox.Size = New-Object System.Drawing.Size(160, 20)
$dialog.Controls.Add($usersBox)

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(90, 50)
$OKButton.Size = New-Object System.Drawing.Size(75, 23)
$OKButton.Text = "OK"
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$dialog.Controls.Add($OKButton)
$dialog.AcceptButton = $OKButton

$dialog.ShowDialog()

$userToChangePassword = $usersBox.Text
$expirationHours = $expirationBox.Text

$newPassword = Generate-Password 12 | ConvertTo-SecureString -AsPlainText -Force

Set-ADAccountPassword -Identity $userToChangePassword -NewPassword $newPassword -Server $serverAd -Credential $credential
Log-Message -Message "Reinitialisation du mot de passe de l'utilisateur: $userToChangePassword." -Level "INFO"

Enable-ADAccount -Identity $userToChangePassword -Server $serverAd -Credential $credential
Log-Message -Message "Compte active pour l'utilisateur: $userToChangePassword." -Level "INFO"

$expiration = (Get-Date).AddHours($expirationHours)
Set-ADAccountExpiration -Identity $userToChangePassword -DateTime $expiration -Server $serverAd -Credential $credential
Log-Message -Message "Expiration du compte fixee pour l'utilisateur: $userToChangePassword." -Level "INFO"

$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($newPassword))
Set-Clipboard -Value $plainPassword
Log-Message -Message "Mot de passe copie dans le presse-papiers." -Level "INFO"

# URL de l'API
$apiUrl = "api forti/$userToChangePassword"

# Token d'authentification
$apiToken = 'clef api'

# Corps de la requête
$body = @{
    "status" = "enable"
} | ConvertTo-Json

# Headers de la requête
$headers = @{
    "Authorization" = "Bearer $apiToken"
    "Content-Type" = "application/json"
}

# Envoyer la requête à l'API pour activer le compte VPN
try {
    $response = Invoke-RestMethod -Uri $apiUrl -Method PUT -Body $body -Headers $headers

    if ($response.status -eq "success") {
        Log-Message -Message "Compte VPN activé pour l'utilisateur: $userToChangePassword." -Level "INFO"
    }
    else {
        Log-Message -Message "Échec de l'activation du compte VPN pour l'utilisateur: $userToChangePassword. Réponse: $($response.message)" -Level "WARNING"
    }
}
catch {
    Log-Message -Message "Une erreur s'est produite lors de l'activation du compte VPN: $_" -Level "ERROR"
    Write-Host "Une erreur s'est produite lors de l'activation du compte VPN: $_"
}

# URI d'envoie de msg sur teams
$uri = "webhook teams"

$body = @{
    "@type"      = "MessageCard"
    "@context"   = "http://schema.org/extensions"
    "summary"    = "Changement de mot de passe"
    "themeColor" = "0075FF"
    "title"      = "Mot de passe change"
    "sections"   = @(
        @{
            "activityTitle"    = "Mot de passe change"
            "activitySubtitle" = "Le VPN a ete ouvert."
            "text"             = "Le mot de passe de l'utilisateur $userToChangePassword a ete modifie, le compte a ete active pour une duree de $expirationHours H et le VPN a ete ouvert."
        }
    )
}

# Convertir le body en JSON
$jsonString = ConvertTo-Json -InputObject $body -Depth 3

# Convertir le JSON string en UTF-8
$utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonString)

# Envoyer la notif sur teams et stocker la reponse
try {
    $response = Invoke-WebRequest -Uri $uri -Method Post -Body $utf8Bytes -ContentType 'application/json'
    # Verifier le code reponse
    if ($response.StatusCode -eq 200) {
        Log-Message -Message "La notification a ete envoyee avec succes." -Level "INFO"
        Write-Host "La notification a ete envoyee avec succes."
    }
    else {
        Log-Message -Message "L'envoi de la notification a echoue. Code d'etat: $($response.StatusCode)" -Level "WARNING"
        Write-Host "L'envoi de la notification a echoue. Code d'etat: $($response.StatusCode)"
    }
}
catch {
    Log-Message -Message "Une erreur s'est produite lors de l'envoi de la notification: $_" -Level "ERROR"
    Write-Host "Une erreur s'est produite lors de l'envoi de la notification: $_"
}

Log-Message -Message "Fin du script." -Level "INFO"
Log-Message -Message "/---------------------------------------------------------------\" -Level "FIN"
