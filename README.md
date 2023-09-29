# Uptime Kuma Push
This is a PowerShell script that you can use with Uptime Kuma's push feature for monitoring servers on a network Uptime Kuma can't communicate with. Example: Your Uptime Kuma server is in the cloud but you want to monitor servers and devices on your local network.

Find out more about Uptime Kuma: https://github.com/louislam/uptime-kuma

## Features
* All configuration is done in UptimeKumaPush.json
* Multiple distinct monitors
* Group monitors so that if any one child monitor fails it reports back to the single Uptime Kuma monitor
* Set the script to loop or use your scheduled task to re-run the script

## Setup
1. Create one or more push monitors in Uptime Kuma and make note of the "Push URL" after saving the monitor, this will go in the configuration (with some modifications)
2. Copy the script and example json configuration file to your preferred location on a server or machine that will always be running, make sure the .ps1 file and .json file have the same name
3. Edit the configuration with the monitors you want to use, use the example file to see what options you have and where to place data
4. Setup a scheduled task to run the script at your preferred interval or on startup (this will depend on your monitor setup on Uptime Kuma, please read about the 'loop' setting)

## Configuration Sample
```JSON
{
    "settings":{
        "push_url": "https://myuptimekuma.host/api/push/{ID}?status={STATUS}&msg={MSG}&ping={PING}", 
        "loop": false,
        "loop_delay": "30",
        "push_if_down": true
    },
    "monitors":[
        {"id": "2e7mMkKP873", "type": "ping", "host": "10.0.0.20"},
        {"id": "GSgX3MyQ5T7", "group":[
            {"type": "website", "host": "https://internal-site.domain.com", "search": "Welcome to our internal home page"},
            {"type": "port", "host": "10.0.0.30", "port": 22},
        ]
    }
    ]
}

```

## Configuration Settings

### Push URL
The URL is based on the one from the Uptime Kuma monitor settings page (after creation), for most people the only thing that will change from the example URL is the domain. Do NOT remove the {VARIABLES} from the example, they are required for the script to insert data during individual tests.
```
https://myuptimekuma.host/api/push/{ID}?status={STATUS}&msg={MSG}&ping={PING}
```

### Loop
The "loop" setting, if true, will restart the tests forever and use loop_delay (seconds) between each run. If you use this option, you should only configure your scheduled task to run once on startup. Alternatively you can set loop to false and create a scheduled task that repeats once per minute fover.

### Push If Down
The setting "push_if_down", if true, will send a notification to Uptime Kuma when a test fails, this is the default and doesn't need to be changed normally. If you set this to false, Uptime Kuma will not get a notification but the heartbeat/retries settings on Uptime Kuma will still determine an issue exists.

## Configuration Monitors

### ID
The ID from your Uptime Kuma URL is used here, the ID is just after the "/push/" part of the URL. A group of tests use one ID and if any one of those tests fails it will report back to Uptime Kuma as down. Do NOT use same ID multiple times unless you are using "upside down mode" in Uptime Kuma.

### Type
The script offers three types of monitor tests:
* Ping - Ping a host
* Port - Try connecting to a host using the specified "port" value
* Website - Test a website and optionally specify a "search" value to test if the returned page contains specific text

### Host
This is the IP or hostname to test.

### Timeout
The example configuration does not include this option because its optional and isn't well documented yet, you can set this on individual monitors, check the script functions to see what current defaults are.
