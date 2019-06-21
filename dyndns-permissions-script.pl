#!/usr/bin/perl -w

use strict;
use warnings;

use Net::DNS;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

# --- init ------------------------------------------------------

# initialization of global program variables - DO NOT CHANGE
my $work   = 0;      # defines, if the following datasets will be processed
my $update = 0;      # defines, if the hosts file needs to be updated
my @ip;
my @modules=(\&update_postfix,\&update_iptables);
#my @modules=(\&update_postfix);

# --- config ------------------------------------------------------

# enables debug mode without writing to hosts file
my $TESTING    = 0;

# Nameserver to ask
my $NAMESERVER = '8.8.8.8';

# Start delimiter
my $DELIMITER1 = '# BEGIN: Automagic DynDNS - Updater';

# End delimiter
my $DELIMITER2 = '# END: Automagic DynDNS - Updater';

# File to read from and write to
my $HOSTS_HOSTSFILE  = '/etc/hosts';

# File where postfix reads its mynetworks parameter from
my $POSTF_MYNETWORKSFILE = '/etc/postfix/dyndnshosts.cf';

# iptables binary
my $IPTAB_COMMAND = '/sbin/iptables';

# name of the table to update
my $IPTAB_TABLE   = 'dynaddrs';

# --- program ------------------------------------------------------

INFO("dyndns-permissions-script.pl started");

update_hosts();
if ($update == 1)
{
        foreach (@modules)
        {
                &$_;
        }
}

# --- subs ------------------------------------------------------

#
# update_hosts
#
# this is the key subroutine, that reads your $HOSTS_HOSTSFILE, does the
# DNS lookups and decides whether a DynDNS update has occured.
#
sub update_hosts
{
        DEBUG("opening $HOSTS_HOSTSFILE for reading");
        open(FILEIN,"<$HOSTS_HOSTSFILE")
                or die "Could not open $HOSTS_HOSTSFILE for reading";
        my @lines = <FILEIN>;
        close FILEIN;

        foreach my $line (@lines)
        {
                chomp($line);
                if ($work == 0)
                {
                        if ($line eq $DELIMITER1)
                        {
                                $work = 1;
                        }
                }
                else
                {
                        if ($line eq $DELIMITER2)
                        {
                                $work = 0;
                        }
                        else
                        {
                                $line =~ s/\s+/ /g;
                                $line =~ s/^\s//;
                                $line =~ s/\s$//;
                                my @values = split(/ /,$line);
                                if ((scalar(@values) == 2) && ($values[1] ne ''))
                                {
                                        my $rrcrd=lookup($values[1]);
                                        chomp($rrcrd);
                                        if ($rrcrd =~ /^\d+\.\d+\.\d+\.\d+$/)
                                        {
                                                if ($rrcrd ne $values[0])
                                                {
                                                        $line   = "$rrcrd $values[1]";
                                                        $update = 1;
                                                }
                                                push(@ip,$rrcrd);
                                        }
                                        else
                                        {
                                                push(@ip,$values[0]);
                                        }
                                }
                        }
                }
                $line .= "\n";
        }

        if ($update == 1)
        {
                if ($TESTING == 1)
                {
                        print @lines;
                }
                else
                {
                        open(OUTFILE,">$HOSTS_HOSTSFILE")
                                or die "Could not open $HOSTS_HOSTSFILE for writing";
                        print OUTFILE @lines;
                        close OUTFILE;
                }
        }
}

#
# update_postfix
#
# This subroutine writes the current IP addresses to $POSTF_MYNETWORKSFILE.
# To use this feature modify your /etc/postfix/main.cf, so that the file is
# used for mynetworks:
#
#    mynetworks = 127.0.0.0/8, /etc/postfix/mynetworks.cf
#
sub update_postfix
{
        if ($TESTING == 1)
        {
                foreach (@ip)
                {
                        print $_."/32\n";
                }
        }
        else
        {
                open(OUTFILE,">$POSTF_MYNETWORKSFILE")
                        or die "Could not open $POSTF_MYNETWORKSFILE for writing";
                foreach (@ip)
                {
                        print OUTFILE $_."/32\n";
                }
                close OUTFILE;
                `/usr/sbin/postfix reload >/dev/null 2>/dev/null`;
        }
}

#
# update_iptables
#
# This subroutine flushes the table $IPTAB_TABLE, that must exist.
# It does not create the table, so be sure that your firewall script creates
# it. I suggest you use a special user build table, that is just used by
# this script. Don't use INPUT as $IPTAB_TABLE!!!
#
sub update_iptables
{
        if ($TESTING == 1)
        {
                print "$IPTAB_COMMAND -F $IPTAB_TABLE\n";
                foreach (@ip)
                {
                        print "$IPTAB_COMMAND -A $IPTAB_TABLE -s ".$_."/32 -j ACCEPT\n";
                }
        }
        else
        {
                `$IPTAB_COMMAND -F $IPTAB_TABLE`;
                foreach (@ip)
                {
                        `$IPTAB_COMMAND -A $IPTAB_TABLE -s $_/32 -j ACCEPT`;
                }
        }
}

#
# lookup
#
# The lookup subroputine does the DNS lookup. It was necessary to write it,
# because the perl built-in methods would have matched their reverse records
# against /etc/hosts, which would have led to no more updates.
#
sub lookup
{
        my $hostname = shift;
        my $answer = '';
        my $res = Net::DNS::Resolver->new;
        $res->nameservers($NAMESERVER);
        my $query = $res->search($hostname);
        if ($query)
        {
                foreach my $rr ($query->answer)
                {
                        next unless $rr->type eq "A";
                        $answer = $rr->address;
                        chomp($answer);
                }
        }
        return $answer;
}
