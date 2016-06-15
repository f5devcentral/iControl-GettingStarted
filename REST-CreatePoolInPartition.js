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
	'pool'       : { key: 'o', args: 1, description: 'Pool'},
	'partition'  : { key: 'a', args: 1, description: 'Partition'},
	'debug'      : { key: 'd', description: 'Print Debug Messages'}
});

var BIGIP = ops.bigip;
var USER = ops.user;
var PASS = ops.pass;
var POOL = ops.pool;
var PARTITION = ops.partition;
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

	if ( DEBUG ) {	console.log("\n: " + resource + "\n"); }

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


function handleGetPoolList(callback) {
	var uri = "/mgmt/tm/ltm/pool";
	handleVERB("GET", uri, null, function(json) {
		callback(json);
	});
}

function handleCreatePool(pool, partition, callback) {
	var uri = "/mgmt/tm/ltm/pool";
	var body = '{"name":"' + pool + '", "partition":"' + partition + '"}';

console.log("BODY: " + body);
	handleVERB("POST", uri, body, function(json) {
		callback(json);
	});
}

//========================================================
//
//========================================================

if ( (null == POOL) || (PARTITION == null) ) {
	handleGetPoolList(function(json) {
		var obj = JSON.parse(json);
		var items = obj.items;
		var len = items.length;
		console.log("POOL NAMES");
		console.log("==========");
		for(var i=0; i<items.length; i++) {
			var fullPath = items[i].fullPath;
			console.log("  " + fullPath);
		}
	});
} else {
	handleCreatePool(POOL, PARTITION, function(json) {
		console.log(json);
	});
}


