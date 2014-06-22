# UniFi Scripts

## download_users.rb
Downloads user details using the UniFi API and stores the results as JSON
in the users dir.

Requires the following environment variables:

```
UNIFI_USER=YOUR_USER_NAME
UNIFI_PASS=YOUR_PASSWORD
UNIFI_SERVER=YOUR_SERVER_IP:PORT
```

To use:
```
ruby download_users.rb
```

_Note: you may want to use bundler if you're into that sort of thing._
