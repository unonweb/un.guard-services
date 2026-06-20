NOTES
=====

Init whitelist
--------------

```sh
systemctl list-units --type=service --state=running --no-legend | awk '{print $1}' | sort > ${WHITELIST}
```