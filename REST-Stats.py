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


def get_pool_list(bigip, url):
    try:
        pools = bigip.get("%s/ltm/pool" % url).json()
        print "POOL LIST"
        print " ---------"
        for pool in pools['items']:
            print "   /%s/%s" % (pool['partition'], pool['name'])
    except Exception, e:
        print e


def get_pool_stats(bigip, url, pool):
    try:
        pool_stats = bigip.get("%s/ltm/pool/%s/stats" % (url, pool)).json()
        selflink = "https://localhost/mgmt/tm/ltm/pool/%s/~Common~%s/stats" % (pool, pool)
        nested_stats = pool_stats['entries'][selflink]['nestedStats']['entries']
        print ''
        print ' --------------------------------------'
        print ' NAME                  : %s' % nested_stats['tmName']['description']
        print ' --------------------------------------'
        print ' AVAILABILITY STATE    : %s' % nested_stats['status.availabilityState']['description']
        print ' ENABLED STATE         : %s' % nested_stats['status.enabledState']['description']
        print ' REASON                : %s' % nested_stats['status.statusReason']['description']
        print ' SERVER BITS IN        : %s' % nested_stats['serverside.bitsIn']['value']
        print ' SERVER BITS OUT       : %s' % nested_stats['serverside.bitsOut']['value']
        print ' SERVER PACKETS IN     : %s' % nested_stats['serverside.pktsIn']['value']
        print ' SERVER PACKETS OUT    : %s' % nested_stats['serverside.pktsOut']['value']
        print ' CURRENT CONNECTIONS   : %s' % nested_stats['serverside.curConns']['value']
        print ' MAXIMUM CONNECTIONS   : %s' % nested_stats['serverside.maxConns']['value']
        print ' TOTAL CONNECTIONS     : %s' % nested_stats['serverside.totConns']['value']
        print ' TOTAL REQUESTS        : %s' % nested_stats['totRequests']['value']



    except Exception, e:
        print e


def get_virtual_list(bigip, url):
    try:
        vips = bigip.get("%s/ltm/virtual" % url).json()
        print "VIRTUAL SERVER LIST"
        print " -------------------"
        for vip in vips['items']:
            print "   /%s/%s" % (vip['partition'], vip['name'])
    except Exception, e:
        print e


def get_virtual_stats(bigip, url, vip):
    try:
        vip_stats = bigip.get("%s/ltm/virtual/%s/stats" % (url, vip)).json()
        selflink = "https://localhost/mgmt/tm/ltm/virtual/%s/~Common~%s/stats" % (vip, vip)
        nested_stats = vip_stats['entries'][selflink]['nestedStats']['entries']
        print ''
        print ' --------------------------------------'
        print ' NAME                  : %s' % nested_stats['tmName']['description']
        print ' --------------------------------------'
        print ' AVAILABILITY STATE    : %s' % nested_stats['status.availabilityState']['description']
        print ' ENABLED STATE         : %s' % nested_stats['status.enabledState']['description']
        print ' REASON                : %s' % nested_stats['status.statusReason']['description']
        print ' CLIENT BITS IN        : %s' % nested_stats['clientside.bitsIn']['value']
        print ' CLIENT BITS OUT       : %s' % nested_stats['clientside.bitsOut']['value']
        print ' CLIENT PACKETS IN     : %s' % nested_stats['clientside.pktsIn']['value']
        print ' CLIENT PACKETS OUT    : %s' % nested_stats['clientside.pktsOut']['value']
        print ' CURRENT CONNECTIONS   : %s' % nested_stats['clientside.curConns']['value']
        print ' MAXIMUM CONNECTIONS   : %s' % nested_stats['clientside.maxConns']['value']
        print ' TOTAL CONNECTIONS     : %s' % nested_stats['clientside.totConns']['value']
        print ' TOTAL REQUESTS        : %s' % nested_stats['totRequests']['value']


    except Exception, e:
        print e


if __name__ == "__main__":
    import requests, json, argparse, getpass
    from requests.packages.urllib3.exceptions import InsecureRequestWarning
    requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

    parser = argparse.ArgumentParser(description='Get Pool or Virtual Statistics')

    parser.add_argument("host", help='BIG-IP IP or Hostname' )
    parser.add_argument("username", help='BIG-IP Username')
    parser.add_argument("type", help='pool|virtual <list|name>', nargs=2)
    args = vars(parser.parse_args())

    hostname = args['host']
    username = args['username']
    obj_type = args['type']

    print "%s, enter your password: " % username,
    password = getpass.getpass()

    b_url_base = 'https://%s/mgmt/tm' % hostname
    b = requests.session()
    b.auth = (username, password)
    b.verify = False
    b.headers.update({'Content-Type':'application/json'})

    if obj_type[0] == 'pool':
        if obj_type[1] == 'list':
            get_pool_list(b, b_url_base)
        else:
            get_pool_stats(b, b_url_base, obj_type[1])

    elif obj_type[0] == 'virtual':
        if obj_type[1] == 'list':
            get_virtual_list(b, b_url_base)
        else:
            get_virtual_stats(b, b_url_base, obj_type[1])


