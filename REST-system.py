#!/usr/bin/python
'''
# The contents of this file are subject to the "END USER LICENSE AGREEMENT FOR F5
# Software Development Kit for iControl"; you may not use this file except in
# compliance with the License. The License is included in the iControl
# Software Development Kit.
#
# Software distributed under the License is distributed on an "AS IS"
# basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
# the License for the specific language governing rights and limitations
# under the License.
#
# The Original Code is iControl Code and related documentation
# distributed by F5.
#
# The Initial Developer of the Original Code is F5 Networks,
# Inc. Seattle, WA, USA. Portions created by F5 are Copyright (C) 1996-2004 F5 Networks,
# Inc. All Rights Reserved.  iControl (TM) is a registered trademark of F5 Networks, Inc.
#
# Alternatively, the contents of this file may be used under the terms
# of the GNU General Public License (the "GPL"), in which case the
# provisions of GPL are applicable instead of those above.  If you wish
# to allow use of your version of this file only under the terms of the
# GPL and not to allow others to use your version of this file under the
# License, indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by the GPL.
# If you do not delete the provisions above, a recipient may use your
# version of this file under either the License or the GPL.
'''


def get_sys_dns(bigip, url):
    try:
        dns = bigip.get('%s/sys/dns' % url).json()
        print "\n\n\tName Servers:"
        for server in dns['nameServers']:
            print "\t\t%s" % server
        print "\n\tSearch Domains:"
        for domain in dns['search']:
            print "\t\t%s\n\n" %domain

    except Exception, e:
        print e


def set_sys_dns(bigip, url, servers, search):
    servers = [x.strip() for x in servers.split(',')]
    search = [x.strip() for x in search.split(',')]
    payload = {}
    payload['nameServers'] = servers
    payload['search'] = search
    try:
        bigip.put('%s/sys/dns' % url, json.dumps(payload))
        get_sys_dns(bigip, url)
    except Exception, e:
        print e


def get_sys_ntp(bigip, url):
    try:
        ntp = bigip.get('%s/sys/ntp' % url).json()
        print "\n\n\tNTP Servers:"
        for server in ntp['servers']:
            print "\t\t%s" % server
        print "\n\tTimezone: \n\t\t%s" % ntp['timezone']

    except Exception, e:
        print e


def set_sys_ntp(bigip, url, servers, tz):
    servers = [x.strip() for x in servers.split(',')]
    payload = {}
    payload['servers'] = servers
    payload['timezone'] = tz
    try:
        bigip.put('%s/sys/ntp' % url, json.dumps(payload))
        get_sys_ntp(bigip, url)
    except Exception, e:
        print e


def gen_qkview(bigip, url):
    payload = {}
    payload['command'] = 'run'
    try:
        print "\n\tRunning qkview...standby"
        qv = bigip.post('%s/util/qkview' % url, json.dumps(payload)).text
        if 'saved' in qv:
            print '\tqkview is complete and available in /var/tmp.'
    except Exception, e:
        print e


if __name__ == "__main__":
    import requests, json, argparse, getpass
    from requests.packages.urllib3.exceptions import InsecureRequestWarning
    requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

    parser = argparse.ArgumentParser(description='Create Pool')

    parser.add_argument("host", help='BIG-IP IP or Hostname' )
    parser.add_argument("username", help='BIG-IP Username')
    parser.add_argument("sysfunction", help='System function you wish to configure <dns|ntp|qkview>')
    args = vars(parser.parse_args())

    hostname = args['host']
    username = args['username']
    sysfunction = args['sysfunction']

    print "%s, enter your password: " % args['username'],
    password = getpass.getpass()

    b_url_base = 'https://%s/mgmt/tm' % hostname
    b = requests.session()
    b.auth = (username, password)
    b.verify = False
    b.headers.update({'Content-Type':'application/json'})

    if sysfunction == 'dns':
        print "\n\t1) Get current system dns configuration"
        print "\t2) Set system dns configuration\n"
        answer = raw_input("\tSelection: ")

        if answer is '1':
            get_sys_dns(b, b_url_base)
        elif answer is '2':
            nameservers = raw_input("Enter nameservers (comma-separated): ")
            searchdomains = raw_input("Enter search domains (comma-separated): ")
            set_sys_dns(b, b_url_base, nameservers, searchdomains)

    elif sysfunction == 'ntp':
        print "\n\t1) Get current system ntp configuration"
        print "\t2) Set system ntp configuration\n"
        answer = raw_input("\tSelection: ")

        if answer is '1':
            get_sys_ntp(b, b_url_base)

        elif answer is '2':
            ntpservers = raw_input("Enter ntp servers (comma-separated): ")
            timezone = raw_input("Enter timezone (ie..America/Los_Angeles): ")
            set_sys_ntp(b, b_url_base, ntpservers, timezone)

    elif sysfunction == 'qkview':
        gen_qkview(b, b_url_base)