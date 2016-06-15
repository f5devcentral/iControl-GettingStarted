/*
 * The contents of this file are subject to the "END USER LICENSE AGREEMENT FOR F5
 * Software Development Kit for iControl"; you may not use this file except in
 * compliance with the License. The License is included in the iControl
 * Software Development Kit.
 *
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
 * the License for the specific language governing rights and limitations
 * under the License.
 *
 * The Original Code is iControl Code and related documentation
 * distributed by F5.
 *
 * The Initial Developer of the Original Code is F5 Networks,
 * Inc. Seattle, WA, USA. Portions created by F5 are Copyright (C) 1996-2002 F5
 * Inc. All Rights Reserved.  iControl (TM) is a registered trademark of F5 Netw
 *
 * Alternatively, the contents of this file may be used under the terms
 * of the GNU General Public License (the "GPL"), in which case the
 * provisions of GPL are applicable instead of those above.  If you wish
 * to allow use of your version of this file only under the terms of the
 * GPL and not to allow others to use your version of this file under the
 * License, indicate your decision by deleting the provisions above and
 * replace them with the notice and other provisions required by the GPL.
 * If you do not delete the provisions above, a recipient may use your
 * version of this file under either the License or the GPL.
 */

import java.text.*;
import java.util.*;
import java.io.*;

public class SOAPDataGroup extends Object
{
	//--------------------------------------------------------------------------
	// Member Variables
	//--------------------------------------------------------------------------
	public iControl.Interfaces m_interfaces = new iControl.Interfaces();

	//--------------------------------------------------------------------------
	// Constructor
	//--------------------------------------------------------------------------
	public SOAPDataGroup()
	{
	}

	//--------------------------------------------------------------------------
	// parseArgs
	// [0] bigip
	// [1] user
	// [2] pass
	// [3] datagroup
	// [4] action
	//--------------------------------------------------------------------------
	public boolean parseArgs(String[] args) throws Exception
	{
		boolean bSuccess = false;
		int port = 443;
		String bigip = null;
		String user = null;
		String pass = null;
		String datagroup = null;
		String action = null;

		if ( args.length < 3 )
		{
			usage();
		}
		else
		{
			bigip = args[0];
			user = args[1];
			pass = args[2];
			
			if ( args.length > 3 )
			{
				datagroup = args[3];
			}
			if ( args.length > 4 )
			{
				action = args[4];
			}

			// build parameters
			m_interfaces.initialize(bigip, port, user, pass);

			if ( null == datagroup ) {
				getDataGroupList();
			} else {
				if ( null == action ) {
					getDataGroup(datagroup);
				} else if ( action.equals("create") ) {
					createDataGroup(datagroup);
				} else if ( action.equals("delete") ) {
					deleteDataGroup(datagroup);
				} else if ( action.equals("remove_from") ) {
					removeFromDataGroup(datagroup);
				} else if ( action.equals("add_to") ) {
					addToDataGroup(datagroup);
				} else {
					getDataGroup(datagroup);
				}

			}

			bSuccess = true;
		}

		return bSuccess;
	}

	//--------------------------------------------------------------------------
	//
	//--------------------------------------------------------------------------
	public void usage()
	{
		System.out.println("Usage: SOAPDataGroup hostname username password [pool partition]");
	}
	

	//--------------------------------------------------------------------------
	//
	//--------------------------------------------------------------------------
	public void getDataGroupList() throws Exception
	{
		System.out.println("Data Groups");
		System.out.println("-----------");
		String [] pool_list = m_interfaces.getLocalLBClass().get_address_class_list();
		for(int i=0; i<pool_list.length; i++)
		{
			System.out.println("  " + pool_list[i] + " - address");
		}
		pool_list = m_interfaces.getLocalLBClass().get_string_class_list();
		for(int i=0; i<pool_list.length; i++)
		{
			System.out.println("  " + pool_list[i] + " - string");
		}
		pool_list = m_interfaces.getLocalLBClass().get_value_class_list();
		for(int i=0; i<pool_list.length; i++)
		{
			System.out.println("  " + pool_list[i] + " - value");
		}
	}

	//--------------------------------------------------------------------------
	//
	//--------------------------------------------------------------------------
	public void getDataGroup(String datagroup) throws Exception
	{
		String [] class_list = new String[] {datagroup};
		
		iControl.LocalLBClassStringClass [] StringClassA = 
			m_interfaces.getLocalLBClass().get_string_class(class_list);

		String [][] DataValuesAofA = 
			m_interfaces.getLocalLBClass().get_string_class_member_data_value(StringClassA);

		//String [] DataValuesA = DataValuesAofA[0];

		for(int i=0; i<StringClassA.length; i++)
		{
			iControl.LocalLBClassStringClass StringClass = StringClassA[i];
			String [] DataValuesA = DataValuesAofA[i];

			String name = StringClass.getName();
			String [] members = StringClass.getMembers();

			System.out.println("Data Group " + datagroup + ": [");
			for(int j=0; j<members.length; j++) {
				String member = members[j];
				String value = DataValuesA[j];

				System.out.println("  { " + member + " : " + value + " }");
			}

			System.out.println("]");
		}

	}

	//--------------------------------------------------------------------------
	//
	//--------------------------------------------------------------------------
	public void createDataGroup(String datagroup) throws Exception
	{
		// Create String Class
		iControl.LocalLBClassStringClass [] StringClassA = new iControl.LocalLBClassStringClass[1];
		StringClassA[0] = new iControl.LocalLBClassStringClass();
		StringClassA[0].setName(datagroup);
		StringClassA[0].setMembers(new String [] { "a", "b", "c" });

		m_interfaces.getLocalLBClass().create_string_class(StringClassA);

		// Set Values
		String [][] valuesAofA = new String[1][];
		valuesAofA[0] = new String[] { "data 1", "data 2", "data 3" };

		m_interfaces.getLocalLBClass().set_string_class_member_data_value(
			StringClassA,
			valuesAofA
		);

		getDataGroup(datagroup);
	}

	//--------------------------------------------------------------------------
	//
	//--------------------------------------------------------------------------
	public void deleteDataGroup(String datagroup) throws Exception
	{
		String [] classes = new String[] {datagroup};
		m_interfaces.getLocalLBClass().delete_class(classes);

		System.out.println("Datagroup " + datagroup + " deleted...");
	}

	//--------------------------------------------------------------------------
	//
	//--------------------------------------------------------------------------
	public void removeFromDataGroup(String datagroup) throws Exception
	{
		String [] names = new String[] {"c"};

		iControl.LocalLBClassStringClass [] StringClassA = new iControl.LocalLBClassStringClass[1];
		StringClassA[0] = new iControl.LocalLBClassStringClass();
		StringClassA[0].setName(datagroup);
		StringClassA[0].setMembers(new String [] { "c" });

		m_interfaces.getLocalLBClass().delete_string_class_member(StringClassA);

		getDataGroup(datagroup);
	}

	//--------------------------------------------------------------------------
	//
	//--------------------------------------------------------------------------
	public void addToDataGroup(String datagroup) throws Exception
	{
		// Create String Class
		iControl.LocalLBClassStringClass [] StringClassA = new iControl.LocalLBClassStringClass[1];
		StringClassA[0] = new iControl.LocalLBClassStringClass();
		StringClassA[0].setName(datagroup);
		StringClassA[0].setMembers(new String [] { "d", "e" });

		m_interfaces.getLocalLBClass().add_string_class_member(StringClassA);

		// Set Values
		String [][] valuesAofA = new String[1][];
		valuesAofA[0] = new String[] { "data 4", "data 5" };

		m_interfaces.getLocalLBClass().set_string_class_member_data_value(
			StringClassA,
			valuesAofA
		);

		getDataGroup(datagroup);
	}

	//--------------------------------------------------------------------------
	// Main
	//--------------------------------------------------------------------------
	public static void main(String[] args)
	{
		try
		{
			System.setProperty("jsse.enableSNIExtension", "false");
			SOAPDataGroup obj = new SOAPDataGroup();
			obj.parseArgs(args);
		}
		catch(Exception ex)
		{
			ex.printStackTrace(System.out);
		}
	}
};
