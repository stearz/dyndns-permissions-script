# README - dyndns-permissions-script

## Description
`dyndns-permissions-script.pl` is a script that reads and updates /etc/hosts.
It was written 2008 by Stephan Schwarz (@stearz) to implement IP based authentication for Apache based on DynDNS entries.
Then it also supported updating iptables and a postfix relay list to allow access for my systems behind my home router.

## Disclaimer
I have not used this script for years and as I accidently found it in 2019 on an old hard drive I decided to put it on GitHub so others could use, learn from or laugh at it.
It is damn old code and it really feels as if someone else had written it. Do not use it in production - there is always a better way to authenticate instead of giving permissions on IP addresses. 

## Usage
Add your DynDNS hostname to your /etc/hosts between the scripts delimiter lines:
    
    [...]
    
    # BEGIN: Automagic DynDNS - Updater
    
    127.0.0.1     myhostname.at.dyndns.provider.example.com
    
    # END: Automagic DynDNS - Updater
    
    [...]
    
Then simply run the script without arguments (e.g. from a cronjob)
 
    dyndns-permissions-script.pl

# Variables
The variables have to be changed inside the Perl script as I did not implement reading args from the command line: 

## Testmode

    # enables debug mode without writing to hosts file
    my $TESTING    = 0;

## Nameserver

    # Nameserver to ask
    my $NAMESERVER = '8.8.8.8';

## Hosts file and delimiters
The script reads all lines between `$DELIMITER1` and `$DELIMITER2` from `$HOSTS_HOSTFILE` and tries to get the actual IP addresses of the hostnames it read.

    # File to read from and write to
    my $HOSTS_HOSTSFILE  = '/etc/hosts';

    # Start delimiter
    my $DELIMITER1 = '# BEGIN: Automagic DynDNS - Updater';

    # End delimiter
    my $DELIMITER2 = '# END: Automagic DynDNS - Updater';

## Postfix

**[optional]** _Can be disabled by removing the reference to the sub in `@modules`._

The file the script should write the resolved IP addresses to so that postfix can use it as `mynetworks`

    # File where postfix reads its mynetworks parameter from
    my $POSTF_MYNETWORKSFILE = '/etc/postfix/dyndnshosts.cf';

## Iptables

**[optional]** _Can be disabled by removing the reference to the sub in `@modules`._

Exact path to the iptables binary and iptables table that the script should write the resolved IP addresses to.  

    # iptables binary
    my $IPTAB_COMMAND = '/sbin/iptables';

    # name of the table to update
    my $IPTAB_TABLE   = 'dynaddrs';
