#!/usr/local/bin/node

//=========================================================
//
//=========================================================
var net     = require('net');
var stdio   = require('stdio');
var https   = require('https');
var net     = require('net');
var url     = require('url');
var request = require('request');
var util    = require('util');

var ops = stdio.getopt({
	'bigip'      : { key: 'b', args: 1, description: 'BIG-IP address', default: 'bigip.joesmacbook.com'},
	'user'       : { key: 'u', args: 1, description: 'Username', default: 'admin'},
	'pass'       : { key: 'p', args: 1, description: 'Password', default: 'admin'},
	'type'       : { key: 'g', args: 1, description: 'Object Type: [virtual|poo]'},
	'name'       : { key: 'a', args: 1, description: 'Object Name'},
	'debug'      : { key: 'd', description: 'Print Debug Messages'}
});

var BIGIP = ops.bigip;
var USER = ops.user;
var PASS = ops.pass;
var TYPE = ops.type;
var NAME = ops.name;
var DEBUG = ops.debug;

var args = ops.args;


//--------------------------------------------------------
function buildUrl(resource) {
//--------------------------------------------------------
	return "https://" + BIGIP + resource;
}

//--------------------------------------------------------
function getAuthToken(callback) {
//--------------------------------------------------------
	var resource = "/mgmt/shared/authn/login";
	var user = USER;
	var pass = PASS;
	var body = "{'username':'" + user + "','password':'" + pass + "','loginProviderName':'tmos'}";

	httpRequest("POST", resource, body, user, pass, null, function(json) {
		var obj = JSON.parse(json);
		var token = obj["token"]["token"];
		callback(token);
	});
}

//--------------------------------------------------------
function httpRequest(verb, resource, body, user, pass, token, callback) {
//--------------------------------------------------------

	if ( DEBUG ) {	console.log("\n: " + resource + ", verb=" + verb + "\n"); }

	var http_opts = {
		host: BIGIP,
		method: verb,
		port: 443,
		rejectUnauthorized: 0,
		path: resource
	};

	var http_headers = {
		'Content-Type': 'application/json'
	};

	// Authentication Method
	if ( user && pass ) { http_opts["auth"] = user + ":" + pass; } 
	else if ( token )   { http_headers["X-F5-Auth-Token"] = token; }

	// BODY?
	if ( body ) { http_headers["Content-Length"] = body.length; }

	http_opts["headers"] = http_headers;

	var content = "";
	var req = https.request(http_opts, function(res) {
		res.setEncoding("utf8");
		res.on('data', function(chunk) {
			content += chunk;
		}),
		res.on('end', function() {
			callback(content);
		})
	});

	req.on('error', function(e) {
		console.log("ERROR: " + JSON.stringify(e) + "\n");
	});

	if ( body ) {
		req.write(body + "\n");
	}
	req.end();
}


//--------------------------------------------------------
function handleVERB(verb, resource, body, callback) {
//--------------------------------------------------------
	getAuthToken( function(token) {
		httpRequest(verb, resource, body, null, null, token, function(json) {
			callback(json);
		});
	});
}

//--------------------------------------------------------
function getVirtualList(name) {
//--------------------------------------------------------
	var uri = "/mgmt/tm/ltm/virtual";

	handleVERB("GET", uri, null, function(json) {
		//console.log(json);
		var obj = JSON.parse(json);
		var items = obj.items;
		console.log("VIRTUALS");
		console.log("-----------");
		for(var i=0; i<items.length; i++) {
			var fullPath = items[i].fullPath;
			console.log("  " + fullPath);
		}
	});	
}

//--------------------------------------------------------
function getPoolList(name) {
//--------------------------------------------------------
	var uri = "/mgmt/tm/ltm/pool";

	handleVERB("GET", uri, null, function(json) {
		//console.log(json);
		var obj = JSON.parse(json);
		var items = obj.items;
		console.log("POOLS");
		console.log("-----------");
		for(var i=0; i<items.length; i++) {
			var fullPath = items[i].fullPath;
			console.log("  " + fullPath);
		}
	});	
}

function getStatsValue(obj, stat_name) {
	return obj.entries[stat_name].value;
}
function getStatsDescription(obj, stat_name) {
	return obj.entries[stat_name].description;
}

//--------------------------------------------------------
function getVirtualStats(name) {
//--------------------------------------------------------

	var uri = "/mgmt/tm/ltm/virtual/" + name + "/stats";
	handleVERB("GET", uri, null, function(json) {
		//console.log(json);
		var obj = JSON.parse(json);

		var selfLink = obj.selfLink;
		var entries = obj.entries;

		for(var n in entries) {
			console.log("--------------------------------------");
			console.log("NAME                  : " + getStatsDescription(entries[n].nestedStats, "tmName"));
			console.log("--------------------------------------");
			console.log("DESTINATION           : " + getStatsDescription(entries[n].nestedStats, "destination"));
			console.log("AVAILABILITY STATE    : " + getStatsDescription(entries[n].nestedStats, "status.availabilityState"));
			console.log("ENABLED STATE         : " + getStatsDescription(entries[n].nestedStats, "status.enabledState"));
			console.log("REASON                : " + getStatsDescription(entries[n].nestedStats, "status.statusReason"));
			console.log("CLIENT BITS IN        : " + getStatsValue(entries[n].nestedStats, "clientside.bitsIn"));
			console.log("CLIENT BITS OUT       : " + getStatsValue(entries[n].nestedStats, "clientside.bitsOut"));
			console.log("CLIENT PACKETS IN     : " + getStatsValue(entries[n].nestedStats, "clientside.pktsIn"));
			console.log("CLIENT PACKETS OUT    : " + getStatsValue(entries[n].nestedStats, "clientside.pktsOut"));
			console.log("CURRENT CONNECTIONS   : " + getStatsValue(entries[n].nestedStats, "clientside.curConns"));
			console.log("MAXIMUM CONNECTIONS   : " + getStatsValue(entries[n].nestedStats, "clientside.maxConns"));
			console.log("TOTAL CONNECTIONS     : " + getStatsValue(entries[n].nestedStats, "clientside.totConns"));
			console.log("TOTAL REQUESTS        : " + getStatsValue(entries[n].nestedStats, "totRequests"));
		}
	});	
}

//--------------------------------------------------------
function getPoolStats(name) {
//--------------------------------------------------------

	var uri = "/mgmt/tm/ltm/pool/" + name + "/stats";
	handleVERB("GET", uri, null, function(json) {
		//console.log(json);
		var obj = JSON.parse(json);

		var selfLink = obj.selfLink;
		var entries = obj.entries;

		for(var n in entries) {
			console.log("--------------------------------------");
			console.log("NAME                  : " + getStatsDescription(entries[n].nestedStats, "tmName"));
			console.log("--------------------------------------");
			console.log("AVAILABILITY STATE    : " + getStatsDescription(entries[n].nestedStats, "status.availabilityState"));
			console.log("ENABLED STATE         : " + getStatsDescription(entries[n].nestedStats, "status.enabledState"));
			console.log("REASON                : " + getStatsDescription(entries[n].nestedStats, "status.statusReason"));
			console.log("SERVER BITS IN        : " + getStatsValue(entries[n].nestedStats, "serverside.bitsIn"));
			console.log("SERVER BITS OUT       : " + getStatsValue(entries[n].nestedStats, "serverside.bitsOut"));
			console.log("SERVER PACKETS IN     : " + getStatsValue(entries[n].nestedStats, "serverside.pktsIn"));
			console.log("SERVER PACKETS OUT    : " + getStatsValue(entries[n].nestedStats, "serverside.pktsOut"));
			console.log("CURRENT CONNECTIONS   : " + getStatsValue(entries[n].nestedStats, "serverside.curConns"));
			console.log("MAXIMUM CONNECTIONS   : " + getStatsValue(entries[n].nestedStats, "serverside.maxConns"));
			console.log("TOTAL CONNECTIONS     : " + getStatsValue(entries[n].nestedStats, "serverside.totConns"));
			console.log("TOTAL REQUESTS        : " + getStatsValue(entries[n].nestedStats, "totRequests"));
		}
	});	
}


//========================================================
//
//========================================================

if ( (null == TYPE) ) {
	ops.printHelp();
} else {
	if ( TYPE == "virtual" ) {
		if ( null == NAME ) {
			getVirtualList();
		} else {
			getVirtualStats(NAME); 
		}
	} else if ( TYPE == "pool" ) {
		if ( null == NAME ) {
			getPoolList();
		} else {
			getPoolStats(NAME); 
		}
	}
}
