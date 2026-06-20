NOTES
=====

Init whitelist
--------------

```sh
WHITELIST=YOUR_PATH
sudo chmod u=rw,g=,o= ${WHITELIST}
systemctl list-units --type=service --state=running --property=Name --value --no-legend | sort | sudo tee ${WHITELIST} > /dev/null
```