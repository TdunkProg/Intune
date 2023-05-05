# Set the API endpoint URL for detecting the current time zone
$apiUrl = "http://worldtimeapi.org/api/ip"

# Get the current time zone from the API
$response = Invoke-RestMethod -Uri $apiUrl
$timeZone = $response.timezone

# Set the API endpoint URL for the current time zone
$apiUrl = "http://worldtimeapi.org/api/timezone/$timeZone"

# Get the current time on the computer
$localTime = Get-Date

# Get the current time in the current time zone from the API
$response = Invoke-RestMethod -Uri $apiUrl
$currentTime = [datetime]::Parse($response.datetime)

# Compare the local time with the current time
if ($localTime -ne $currentTime) {
  # Set the local time to the current time if they are not the same
  $localTime = $currentTime
  Set-Date -Date $localTime
}
