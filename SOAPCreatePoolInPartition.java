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

public class SOAPCreatePoolInPartition extends Object
{
	//--------------------------------------------------------------------------
	// Member Variables
	//--------------------------------------------------------------------------
	public iControl.Interfaces m_interfaces = new iControl.Interfaces();

	//--------------------------------------------------------------------------
	// Constructor
	//--------------------------------------------------------------------------
	public SOAPCreatePoolInPartition()
	{
	}

	//--------------------------------------------------------------------------
	// parseArgs
	// [0] bigip
	// [1] user
	// [2] pass
	// [3] poolname
	// [4] partition
	//--------------------------------------------------------------------------
	public boolean parseArgs(String[] args) throws Exception
	{
		boolean bSuccess = false;
		int port = 443;
		String bigip = null;
		String user = null;
		String pass = null;
		String poolname = null;
		String partition = null;

int len = args.length;
System.out.println("LEN: " + len);

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
				poolname = args[3];
			}
			if ( args.length > 4 )
			{
				partition = args[4];
			}
			
			// build parameters
			m_interfaces.initialize(bigip, port, user, pass);
			
			if ( (null == poolname) || (null == partition) ) {
				displayAllPools();
			} else {
				createPool(poolname, partition);
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
		System.out.println("Usage: SOAPCreatePoolInPartition hostname username password [pool partition]");
	}
	
	public void displayAllPools() throws Exception
	{
		String [] pool_list = m_interfaces.getLocalLBPool().get_list();
		System.out.println("Pools\n");
		System.out.println("-----------\n");
		for(int i=0; i<pool_list.length; i++)
		{
			System.out.println(pool_list[i]);
		}
	}

	public void createPool(String poolname, String partition) throws Exception
	{
		String [] pool_list = new String[] {"/" + partition + "/" + poolname};
		iControl.LocalLBLBMethod [] lb_methods = new iControl.LocalLBLBMethod[] { iControl.LocalLBLBMethod.LB_METHOD_ROUND_ROBIN };
		iControl.CommonIPPortDefinition[][] membersAofA = new iControl.CommonIPPortDefinition[1][];
		membersAofA[0] = new iControl.CommonIPPortDefinition[1];
		membersAofA[0][0] = new iControl.CommonIPPortDefinition();
		membersAofA[0][0].setAddress("10.10.10.10");
		membersAofA[0][0].setPort(80);
		
		m_interfaces.getLocalLBPool().create(
			pool_list,
			lb_methods,
			membersAofA
		);

		System.out.println("Pool " + poolname + " created in partition " + partition);
	}
	

	//--------------------------------------------------------------------------
	// Main
	//--------------------------------------------------------------------------
	public static void main(String[] args)
	{
		try
		{
			System.setProperty("jsse.enableSNIExtension", "false");
			SOAPCreatePoolInPartition obj = new SOAPCreatePoolInPartition();
			obj.parseArgs(args);
		}
		catch(Exception ex)
		{
			ex.printStackTrace(System.out);
		}
	}
};
