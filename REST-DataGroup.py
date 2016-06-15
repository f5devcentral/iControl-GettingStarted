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

def get_dg_list(rq, url):
    try:
        dg_list = rq.get('%s/ltm/data-group/internal' % url).json()
        for dg in dg_list['items']:
            print dg
            print '   Data Group: %s' % dg['name']
            print '   --------------'
            if 'records' in dg:
                for record in dg['records']:
                    if 'data' in record:
                        print '      %s: %s' % (record['name'], record['data'])
                    else:
                        print '      %s' % record['name']

    except Exception, e:
        print e


def extend_dg(rq, url, dgname, additional_records):
    dg = rq.get('%s/ltm/data-group/internal/%s' % (url, dgname)).json()

    current_records = dg['records']
    new_records = []
    for record in current_records:
        if 'data' in record:
            nr = [{'name': record['name'], 'data': record['data']}]
        else:
            nr = [{'name': record['name']}]
        new_records.extend(nr)
    for record in additional_records:
        if 'data' in record:
            nr = [{'name': record['name'], 'data': record['data']}]
        else:
            nr = [{'name': record['name']}]
        new_records.extend(nr)

    payload = {}
    payload['records'] = new_records
    rq.put('%s/ltm/data-group/internal/%s' % (url, dgname), json.dumps(payload))


def contract_dg(rq, url, dgname, removal_records):
    dg = rq.get('%s/ltm/data-group/internal/%s' % (url, dgname)).json()
    current_records = dg['records']

    new_records = []
    for record in removal_records:
        if 'data' in record:
            nr = [{'name': record['name'], 'data': record['data']}]
        else:
            nr = [{'name': record['name']}]
        new_records.extend(nr)

    new_records = [x for x in current_records if x not in new_records]

    payload = {}
    payload['records'] = new_records
    rq.put('%s/ltm/data-group/internal/%s' % (url, dgname), json.dumps(payload))


def create_dg(rq, url, dgname, records):
    new_records = []
    for record in records:
        if 'data' in record:
            nr = [{'name': record['name'], 'data': record['data']}]
        else:
            nr = [{'name': record['name']}]
        new_records.extend(nr)

    payload = {}
    payload['type'] = 'string'
    payload['name'] = dgname
    payload['records'] = new_records
    try:
        rq.post('%s/ltm/data-group/internal' % url, json.dumps(payload))
    except Exception, e:
        print e


if __name__ == "__main__":
    import requests, json, argparse, getpass
    from requests.packages.urllib3.exceptions import InsecureRequestWarning
    requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

    parser = argparse.ArgumentParser(description='Create Data-Group')

    parser.add_argument("host", help='BIG-IP IP or Hostname' )
    parser.add_argument("username", help='BIG-IP Username')
    parser.add_argument("-d", "--datagroup", help='Name of the data-group you want to create')
    args = vars(parser.parse_args())

    hostname = args['host']
    username = args['username']
    datagroupname = None if args['datagroup'] is None else args['datagroup']

    print "%s, enter your password: " % args['username'],
    password = getpass.getpass()

    b_url_base = 'https://%s/mgmt/tm' % hostname
    b = requests.session()
    b.auth = (username, password)
    b.verify = False
    b.headers.update({'Content-Type':'application/json'})

    dg_init = [{'name': 'blah blah'}, {'data': '1', 'name': 'a'}, {'data': '2', 'name': 'b'}, {'data': '3', 'name': 'c'}]
    dg_changes = [{'data': '4', 'name': 'd'}, {'data': '5', 'name': 'e'}]


    if datagroupname is None:
        get_dg_list(b, b_url_base)
    else:
        create_dg(b, b_url_base, datagroupname, dg_init)
        extend_dg(b, b_url_base, datagroupname, dg_changes)
        contract_dg(b, b_url_base, datagroupname, dg_changes)
