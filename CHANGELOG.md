# CHANGELOG - dyndns-permissions-script

## [1.2.1] - 2019-06-21
### changed
- released the old perl script on [GitHub](https://github.com/stearz/dyndns-permissions-script)
### added
- separate changelog, license and readme

## [1.2.0] - 2008-10-15
### changed
- modularized code in subs
### added
- functionality to update mynetworks for `postfix` (this gives you the ability to allow relaying for the DynDNS host(s))
- functionality to update `iptables` table to auto-whitelist your DynDNS host(s)

## [1.1.0] - 2008-09-01
### changed
- DNS queries are now done with Net::DNS:Resolver instead of using the syscall `dig +short @$NAMESERVER`.

## [1.0.0] - 2008-08-22
### added
- First release in SVN