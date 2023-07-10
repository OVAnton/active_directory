$smtpServer = "your_smtp"
$smtpPort = 587
$smtpEnableSsl = $true
$smtpUsername = "Username"
$smtpPassword = "Password"
$fromAddress = "mail@mail.com"
$toAddress = "mail@mail.com"
$subject = "Test Email"
$body = "This is a test email message."

$smtpClient = New-Object System.Net.Mail.SmtpClient
$smtpClient.Host = $smtpServer
$smtpClient.Port = $smtpPort
$smtpClient.EnableSsl = $smtpEnableSsl
$smtpClient.Credentials = New-Object System.Net.NetworkCredential($smtpUsername, $smtpPassword)

$mailMessage = New-Object System.Net.Mail.MailMessage
$mailMessage.From = $fromAddress
$mailMessage.To.Add($toAddress)
$mailMessage.Subject = $subject
$mailMessage.Body = $body

try {
    $smtpClient.Send($mailMessage)
    Write-Host "Email sent successfully."
} catch {
    Write-Host "Failed to send email. Error: $($_.Exception.Message)"
}