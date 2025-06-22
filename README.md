# Adobe-URL-Block-List

This is a curated list of all the Adobe URL/IP blocklist declared in the `hosts` file.

If you have any extra domains/IPs, you can either fork this repository and follow instructions for [Adding the records](#adding-the-records) in your fork or by [opening an issue](https://github.com/Ruddernation-Designs/Adobe-URL-Block-List/issues/new).

## Applying the records in your `hosts` file

### Via a script

Simply run `apply.bat` as Administrator and it will create a `hosts.bak` on the root of this repository so you can manually revert it later. Then adds the records from the `hosts` file on to your system.

### Applying the records manually

The location of the `hosts` file is located at `C:\Windows\System32\drivers\etc` or by opening the Run dialog with <kbd>Win</kbd>+ <kbd>R</kbd>, you can access it with:

```txt
%windir%\System32\drivers\etc\hosts
```

> [!NOTE]
> Be sure you keep a backup of your previous `hosts` file first!

Make sure you run your text editor as with admin privilages, otherwise, you won't be able to save changes to the `hosts` file. Copy and paste the full list into the `hosts` file and save it. 

You may need to check your settings to show hidden files, Once there, then overwrite with the host file or add the full list to your host file.

## Adding the records

You'll need to have a version of Python 3.9 or higher installed to add the records and sync across `hosts`, `dnsamsq`, and `pihole.txt`.

Add a domain name or IP with:

```console
py lists.py -a 192.168.0.0 domain.example.com
```

The script will automatically warn you if a record already exists and skips it.

## Checking for duplicates

You can also check for duplicates with `-c` or `--check` flags.

```console
py lists.py -c
```

Likewise, using flags `-rd` or `--remove-duplicates` will automatically remove any duplicates and retroactively applies to all files.

```console
py lists.py -rd
```