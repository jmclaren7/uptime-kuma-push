# UptimeKuma Push
PowerShell script to leverage UptimeKuma's push feature for monitoring servers on a network Untime Kuma can't communicate with. Example: Your Uptime Kuma server is in the cloud but you want to monitor servers and devices on your local network.

## Features
* Configuration is done in UptimeKumaPush.json
* Multiple distinct monitors
* Group monitors so that if any one child monitor fails it reports back to the single Uptime Kuma monitor
* Set the script to loop or use your scheduled task to re-run the script

## Setup
1. Create one or more push monitors in Uptime Kuma and make note of the "Push URL" after saving the monitor, this will go in the configuration (with some modifications)
2. Copy the script and example json configuration file to your preferred location on a server or machine that will always be running, make sure the .ps1 file and .json file have the same name, this is how the script looks for the configuration file
3. Edit the JSON configuration file with the monitors you want to use, use the example file to see what options you have and where to place data
4. Setup a scheduled task to run the script at your preferred interval or on startup (this will depend on your monitor setup on Uptime Kuma)
   
## Configuration Settings

### Push URL
The monitor URL is taken from the Uptime Kuma monitor settings page (after creation) and can be used to update the example push URL in the JSON configuration. The URL in the configuration needs to use the variables shown in the example so the correct values can be inserted when the script sends a push notification to your Uptime Kuma server.
```
https://myuptimekuma.host/api/push/{ID}?status={STATUS}&msg={MSG}&ping={PING}
```
The ID must be extracted from each individual Uptime Kuma monitor and inserted as the ID for individual monitors in the JSON configuration but the other variables in the URL are generated automatically from the tests the script does. It's not recommended to use the same ID for multiple monitors unless you are using "upside down mode" as this would cause your monitors to show up even if one of the tests in the script failed.

### Loop
The configuration file has a setting called "loop", if this is true the script will run continuously and use loop_delay between iterations. If you use this option, you only need to configure your scheduled task to run once on startup but it's unclear if this would be the most reliable way to run the script, long uptimes and other issues on the server running this script could result in the script dying (you should know at least, as long as your monitors are configured in such a way)

### Push If Down
The configuration file has a setting called "push_if_down", this is enabled by default but you can set this to false if you don't want the script to send a notification to the server when a host is down. You would still be able to use the heartbeat/retries settings on Uptime Kuma to determine if an issue exists.

## Configuration Monitors

### Type
The script offers three types of monitor tests:
* Ping - Ping a host
* Port - Try connecting to a specified port on the host
* Website - Test a website and optionally do a search to make sure the returned page contains specific text

### Timeout
The example configuration does not include this option because its optional and isn't well documented yet, you can set this on individual monitors, check the script functions to see what current defaults are.
