# Параметри скрипту
$daysBeforeExpiration = 14

# Отримання поточної дати
$currentDate = Get-Date

# Отримання списку користувачів
$users = Get-ADUser -Filter * -SearchBase 'OU=users,DC=domain,DC=local'  -Properties msDS-UserPasswordExpiryTimeComputed, EmailAddress

# Перевірка кожного користувача
$selectedUsers = foreach ($user in $users) {
    $passwordExpiryTime = [DateTime]::FromFileTime($user."msDS-UserPasswordExpiryTimeComputed")
    $expirationDate = $passwordExpiryTime
    $remainingDays = ($expirationDate - $currentDate).Days
    if ($remainingDays -le $daysBeforeExpiration) {
        $user | Select-Object Name, EmailAddress, @{Name="ExpirationDate"; Expression={$expirationDate}}, @{Name="RemainingDays"; Expression={$remainingDays}}
    }
}

# Формування HTML-таблиці зі списком користувачів
$tableBody = $selectedUsers | ForEach-Object {
    "<tr><td>$($_.Name)</td><td>$($_.EmailAddress)</td><td>$($_.ExpirationDate)</td><td>$($_.RemainingDays)</td></tr>"
}

# Створення повного HTML-тіла повідомлення
$messageBody = @"
<html>
<head>
<style>
    table {
        border-collapse: collapse;
        width: 100%;
    }
    th, td {
        border: 1px solid black;
        padding: 8px;
    }
</style>
</head>
<body>
<h2>List of Users with Expiring Passwords</h2>
<table>
    <tr>
        <th>Name</th>
        <th>Email</th>
        <th>Expiration Date</th>
        <th>Remaining Days</th>
    </tr>
    $tableBody
</table>
</body>
</html>
"@

# Параметри SMTP сервера
$smtpHost = "your_smtp"
$smtpPort = 587
$smtpEnableSsl = $true
$smtpUsername = "Username"
$smtpPassword = "Password"

# Отправка електронного листа
$fromAddress = "mail@mail.com"
$toAddress = "mail@mail.com"
$subject = "List of Users with Expiring Passwords"

$smtpClient = New-Object System.Net.Mail.SmtpClient
$smtpClient.Host = $smtpHost
$smtpClient.Port = $smtpPort
$smtpClient.EnableSsl = $smtpEnableSsl
$smtpClient.Credentials = New-Object System.Net.NetworkCredential($smtpUsername, $smtpPassword)

$mailMessage = New-Object System.Net.Mail.MailMessage
$mailMessage.From = $fromAddress
$mailMessage.To.Add($toAddress)
$mailMessage.Subject = $subject
$mailMessage.Body = $messageBody
$mailMessage.IsBodyHtml = $true

$smtpClient.Send($mailMessage)
Write-Host "Email sent to $toAddress"
