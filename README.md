NOTES
=====

Init whitelist
--------------

```sh
WHITELIST=YOUR_PATH
sudo chmod u=rw,g=,o= ${WHITELIST}
systemctl list-units --type=service --state=running --property=Name --value --no-legend | awk '{print $1}' | sort | sudo tee ${WHITELIST} > /dev/null
```

Whitelist Regex
---------------

A line with apache2.service will only match exact string apache2.service. 
If you want to match anything starting with `user-`, write `user-.*` in your whitelist file.