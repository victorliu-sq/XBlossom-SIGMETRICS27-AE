# SSH Private Key Permissions

## Symptom

SSH refuses to use a private key and reports:

```text
WARNING: UNPROTECTED PRIVATE KEY FILE!
Permissions 0664 for '/home/v25au/Downloads/jiaxin-azure.pem' are too open.
This private key will be ignored.
Permission denied (publickey).
```

## Cause

SSH requires private key files to be readable only by the owning user. If the key is readable or writable by group/others, SSH ignores it for safety.

For example, this is too open:

```text
-rw-rw-r--
```

## Fix

Restrict the key to owner read/write only:

```shell
chmod 600 ~/Downloads/jiaxin-azure.pem
```

Or add the ips address like this:
```shell
ssh-keyscan -H 16.58.68.70 3.17.105.212 >> ~/.ssh/known_hosts # private ip issue
```

Expected permissions:

```text
-rw-------
```

## Verify

Check the key permissions:

```shell
ls -l ~/Downloads/jiaxin-azure.pem
```

Check which host, user, and identity file SSH will use:

```shell
ssh -G azure-nv24ads-v710 | grep -E '^(hostname|user|identityfile) '
```

Then reconnect:

```shell
ssh azure-nv24ads-v710
```
