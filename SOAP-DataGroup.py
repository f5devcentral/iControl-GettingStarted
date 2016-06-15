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

def get_dg_list(bigip):
    try:
        dg_str_list = bigip.LocalLB.Class.get_string_class_list()
        dg_str_names = bigip.LocalLB.Class.get_string_class(dg_str_list)


        for dg in dg_str_names:
            print dg
            print '   Data Group: %s' % dg['name']
            for x in dg['members']:
                print '       %s' % x

    except Exception, e:
        print e


def extend_dg(bigip, dgname, keys, values):
    try:
        bigip.LocalLB.Class.add_string_class_member([{'name': dgname, 'members': keys}])
        bigip.LocalLB.Class.set_string_class_member_data_value([{'name': dgname, 'members': keys}], [[values]])
    except Exception, e:
        print e


def contract_dg(bigip, dgname, keys):
    try:
        bigip.LocalLB.Class.delete_string_class_member([{'name': dgname, 'members': keys}])
    except Exception, e:
        print e


def create_dg(bigip, dgname, keys, values):
    try:
        bigip.LocalLB.Class.create_string_class([{'name': dgname, 'members': keys}])
        bigip.LocalLB.Class.set_string_class_member_data_value([{'name': dgname, 'members': keys}], [[values]])
    except Exception, e:
        print e


if __name__ == "__main__":
    import bigsuds, argparse, getpass, ssl
    ssl._create_default_https_context = ssl._create_unverified_context

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

    b = bigsuds.BIGIP(hostname, username, password)

    dg_members_init = ['a', 'b', 'c']
    dg_values_init = [1, 2, 3]

    dg_members_add = ['d', 'e']
    dg_values_add = [4, 5]

    dg_members_del = ['b']


    if datagroupname is None:
        get_dg_list(b)
    else:
        create_dg(b, datagroupname, dg_members_init, dg_values_init)
        extend_dg(b, datagroupname, dg_members_add, dg_values_add)
        contract_dg(b, datagroupname, dg_members_del)
