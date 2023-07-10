# Параметри скрипту
$smtpServer = "your_smtp"
$fromAddress = "mail@mail.com"
$subject = "Reminder: Password Expiration"

$smtpHost = "your_smtp"
$smtpPort = 587
$smtpEnableSsl = $true
$smtpUsername = "Username"
$smtpPassword = "Password"

$currentDate = Get-Date

# Отримання даних про користувача
$users = Get-ADUser -Filter {SamAccountName -eq 'anton.omelchenko'} -Properties msDS-UserPasswordExpiryTimeComputed, EmailAddress

foreach ($user in $users) {
    # Відправка листа, якщо термін дії пароля закінчується через $daysBeforeExpiration днів
    $passwordExpiryTime = [DateTime]::FromFileTime($user."msDS-UserPasswordExpiryTimeComputed")
    $expirationDate = $passwordExpiryTime
    $remainingDays = ($expirationDate - $currentDate).Days
    
    if ($remainingDays -le 7) {
        $toAddress = $user.EmailAddress
        $emailSent = $true  
        # Форматований текст з використанням HTML-тегів
        $body = @"
Dear $($user.Name),

This is a reminder that your password will expire in <b>$remainingDays</b> days.
<br>Please update your password before it expires.<br>
<br>
<b>If you are using a corporate device, follow these steps:</b>
<ol>
    <li>Connect to the VPN.</li>
    <li>Press Ctrl-Alt-Del on your keyboard.</li>
    <li>Click on <b>'Change a password'</b>.</li>
</ol>

<b>Otherwise, use the service by following the link:</b> <a href='https://ssp.domain.com'>SSP Link</a>.
<br><br>
If you have questions, please let us know by email support@domain.com<br>
Best regards, Your  IT Team!
"@

        $SmtpClient = New-Object System.Net.Mail.SmtpClient
        $SmtpClient.Host = $smtpHost
        $SmtpClient.Port = $smtpPort
        $SmtpClient.EnableSsl = $smtpEnableSsl
        $SmtpClient.Credentials = New-Object System.Net.NetworkCredential($smtpUsername, $smtpPassword)

        $MailMessage = New-Object System.Net.Mail.MailMessage
        $MailMessage.From = $fromAddress
        $MailMessage.To.Add($toAddress)
        $MailMessage.Subject = $subject

        # Встановлення HTML-форматування для тіла листа
        $MailMessage.IsBodyHtml = $true
        $MailMessage.Body = $body

        try {
            $SmtpClient.Send($MailMessage)
            Write-Host "Email sent to $($user.Name) ($toAddress)"
           $emailSent = $true
        }
        catch {
            Write-Host "Failed to send email to $($user.Name) ($toAddress)"
            $emailSent = $false
        }
    
        # Підключення до SNMP сервера
        $snmpClient = New-Object -TypeName "SNMPManager"
        $snmpClient.Connect($snmpServer, $snmpPort, $snmpCommunity, $snmpCertPath)
    
        # Відправка SNMP повідомлення
        $snmpClient.SendNotification("PasswordExpirationReminder", "Password for $($user.Name) will expire in $remainingDays days.")
    
        # Закриття з'єднання SNMP
        $snmpClient.Disconnect()
    }
    else {
        Write-Host "No email was sent. Password has already expired."
    }

    # Виведення результату
    if ($emailSent) {
        Write-Host "Email was successfully sent."
    }
    else {
        Write-Host "No email was sent."
    }
}