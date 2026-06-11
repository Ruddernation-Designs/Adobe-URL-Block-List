# Updates.
Thank you to everyone who has contributed and suggested IP's and domains.

# Adobe-URL-Block-List

This is a curated list of all the Adobe URL/IP blocklists declared in the `hosts` file.

If you have any extra domains/IPs, you can either fork this repository and follow instructions for [Adding the records](#adding-the-records) in your fork or by [opening an issue](https://github.com/Ruddernation-Designs/Adobe-URL-Block-List/issues/new).

## Compatibility

| Platform | Apply | Revert | System hosts file |
|----------|-------|--------|-------------------|
| Windows | `apply.bat` | `revert.bat` | `%windir%\System32\drivers\etc\hosts` |
| macOS | `apply.sh` | `revert.sh` | `/etc/hosts` |
| Linux | `apply.sh` | `revert.sh` | `/etc/hosts` |

The list is also available as a `dnsmasq` configuration and as `pihole.txt` for Pi-hole and router-level blocking, which works regardless of the client operating system.

## Applying the records in your `hosts` file

### Windows

Run `apply.bat` as Administrator. It will:

- Back up your current `hosts` file to `hosts.bak` at the root of this repository (first run only)
- Append the records, wrapped between `## ADOBE_BLOCKLIST_START ##` and `## ADOBE_BLOCKLIST_END ##` markers
- Replace the existing block when re-run, so pulling the latest list and re-applying never duplicates records
- Flush the DNS cache

To remove the records later, run `revert.bat` as Administrator. Only the block between the markers is removed, everything else in your `hosts` file stays untouched.

#### Applying the records manually

The location of the `hosts` file is located at `C:\Windows\System32\drivers\etc`, or by opening the Run dialog with <kbd>Win</kbd>+ <kbd>R</kbd>, you can access it with:

```txt
%windir%\System32\drivers\etc\hosts
```

> [!NOTE]
> Be sure you keep a backup of your previous `hosts` file first!

Make sure you run your text editor as with admin privileges, otherwise, you won't be able to save changes to the `hosts` file. Copy and paste the full list into the `hosts` file and save it.

You may need to check your settings to show hidden files. Once there, overwrite with the host file or add the full list to your host file.

### macOS and Linux

Run the apply script with sudo from the root of this repository:

```console
sudo ./apply.sh
```

The script:

- Backs up your current `/etc/hosts` to `hosts.bak` at the root of this repository (first run only)
- Appends the records, wrapped between `## ADOBE_BLOCKLIST_START ##` and `## ADOBE_BLOCKLIST_END ##` markers
- Replaces the existing block when re-run, so pulling the latest list and re-applying never duplicates records
- Flushes the DNS cache (`dscacheutil`/`mDNSResponder` on macOS, `resolvectl` or `systemd-resolve` on Linux)

To remove the records later:

```console
sudo ./revert.sh
```

Only the block between the markers is removed. Everything else in your `hosts` file stays untouched.

#### Applying the records manually

The `hosts` file is located at `/etc/hosts`. Append the records from this repository's `hosts` file to it (you will need sudo to save), then flush the DNS cache.

On macOS:

```console
sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder
```

On Linux with systemd-resolved:

```console
sudo resolvectl flush-caches
```

## Adding the records

You'll need to have a version of Python 3.9 or higher installed to add the records and sync across `hosts`, `dnsmasq`, and `pihole.txt`.

Add a domain name or IP with:

```console
py lists.py -a 192.168.0.0 domain.example.com
```

On macOS and Linux, use `python3` instead of `py`:

```console
python3 lists.py -a 192.168.0.0 domain.example.com
```

The script will automatically warn you if a record already exists and skip it.

## Checking for duplicates

You can also check for duplicates with `-c` or `--check` flags.

```console
py lists.py -c
```

Likewise, using flags `-rd` or `--remove-duplicates` will automatically remove any duplicates and retroactively apply to all files.

```console
py lists.py -rd
```
