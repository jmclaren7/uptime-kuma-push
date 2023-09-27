#==============================================================================
# UptimeKumaPush.ps1
# https://github.com/jmclaren7/uptimekumapush
#==============================================================================
function Test-Port {
    param (
        $obj
    )

    if($obj.timeout){$timeout = $obj.timeout} Else {$timeout = 1000}

    $tcpClient = New-Object System.Net.Sockets.TcpClient
    return $tcpClient.ConnectAsync($obj.host, $obj.port).Wait($timeout)
}
function Test-Ping {
    param (
        $obj
    )
    if($obj.timeout){$timeout = $obj.timeout} Else {$timeout = 1000}

    $return = Get-CimInstance -ClassName Win32_PingStatus -Filter "(Address='$($obj.host)') and timeout=$timeout" | Select-Object -Property Address,StatusCode,ResponseTime
    If($return.StatusCode -eq 0 -and $return.ResponseTime -eq 0){$return.ResponseTime = 1}

    return $return.ResponseTime
}
function Test-Keyword {
    param (
        $obj
    )
    
    # If search isnt set, set it to blank
    if($obj.search){$sSearch = $obj.search} Else {$sSearch = ""}
    # If host doesnt start with https:// or http:// then use https://
    if ($obj.host -notmatch "^(https://|http://)") { $obj.host = "https://$($obj.host)" }
    # Set timeout to 4 seconds if not set, 
    if($obj.timeout){$timeout = $obj.timeout} Else {$timeout = 4}

    try{
        $result = Invoke-WebRequest $obj.host -UseDefaultCredentials -TimeoutSec $timeout
    } catch {
        $result = $false
    }

    If($result) {
        $result = $result -like "*$sSearch*"
        If($result -and $sSearch -eq "") {
            $result = $true
        }
    }

    return $result
}

# Tests whichever type of monitor is provided
function Test-Host {
    param (
        $monitor
    )

    Switch ($monitor.type){
        "ping" {$result = Test-Ping $monitor}
        "keyword" {$result = Test-Keyword $monitor}
        "port" {$result = Test-Port $monitor}
    }
    
    # Return result
    return $result
}


#==============================================================================
#==============================================================================
While ($true){
    $config = Get-Content -Path "$PSScriptRoot\$((Get-Item $PSCommandPath ).Basename).json" | ConvertFrom-Json

    $notify_url = if($monitor.notify_url){ $monitor.notify_url } Else {$config.settings.notify_url}
    $notify_dead = if($monitor.notify_dead -ne $null){ $monitor.notify_dead } Else {$config.settings.notify_dead}

    if($config){
        "Total monitors: $($config.monitors.count)"

        # Loop through each monitor
        $config.monitors | ForEach-Object{      
            $monitor = $_
            Write-Host "Processing Monitor: $monitor"
            $message = ""
            $ping = 0
            
            # If monitor has a group of monitors
            if($monitor.group){
                $result = $true
                $down_message = ""
                $up_message = ""

                # Loop over each group member
                $monitor.group | ForEach-Object{
                    $groupmonitor = $_
                    Write-Host "Group Monitor: $groupmonitor"
                    $member_result = Test-Host $groupmonitor

                    
                    # If this monitor is down, set group_monitor_return to false and add $groupmonitor.host to $msg
                    if($member_result -eq $false){
                        $result = $false
                        $down_message += "$($_.type):$($_.host)  "
                    } else {
                        $up_message += "$($_.type):$($_.host)  "
                    }
                }

                # Combine down and up messages
                if ($down_message -ne ""){$down_message = "Down: $down_message"}
                if ($up_message -ne ""){$up_message = "Up: $up_message"}
                $message = $down_message + $up_message

            # If monitor is not a group, run test
            }else{
                $result = Test-Host $monitor
                if($result -eq $false){ $message = "Failed ($monitor.type)): $($monitor.host)" }
                if($result -match "^[\d\.]+$"){$ping = $result}
                $message = "$($_.type):$($_.host)"
            }

            # If notify_dead is set to false and the monitor is down, dont send a notification, continue loop
            if($result -eq $false -and $notify_dead -eq $false){ return }
            # Set status to up or down based on result
            if($result){ $status = "up" } else { $status = "down"}

            # Encode the message and replace variables in notify_url
            $message = [System.Web.HttpUtility]::UrlEncode($message)
            $notify_url_updated = $notify_url.replace('{ID}',$monitor.id).replace('{STATUS}',$status).replace('{MSG}',$message).replace('{PING}',$ping)

            # Output debug info
            Write-Host "  `$result=$result  `$status=$status  `$ping=$ping"
            Write-Host "  `$message=$message"
            Write-Host "  `$notify_url_updated=$notify_url_updated"

            # Send push notification to the server
            try{
                $webrequest = Invoke-RestMethod -Uri $notify_url_updated
                Write-Host "Push Response: $webrequest" -ForegroundColor Green

            }catch{
                Write-Host "Push Error: $($_.Exception.Message) $((ConvertFrom-Json $_.ErrorDetails).msg)" -ForegroundColor Red
            }
            
        }

        # Check loop setting, if false exit script
        if($config.settings.loop -eq $false){ Exit }

        # Sleep for loop_delay seconds
        Write-Host "Sleeping for $($config.settings.loop_delay) seconds"
        Start-Sleep $config.settings.loop_delay
        
    }else{
        Write-Host "Config issue"
        Start-Sleep 2
    }
    
}