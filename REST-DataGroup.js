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
	'datagroup'  : { key: 'g', args: 1, description: 'Data Group'},
	'action'     : { key: 'a', args: 1, description: 'Action [create|remove_from|add_to|delete]'},
	'debug'      : { key: 'd', description: 'Print Debug Messages'}
});

var BIGIP = ops.bigip;
var USER = ops.user;
var PASS = ops.pass;
var POOL = ops.pool;
var DATAGROUP = ops.datagroup;
var ACTION = ops.action;
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
function getDataGroupList() {
//--------------------------------------------------------
	var uri = "/mgmt/tm/ltm/data-group/internal";
	handleVERB("GET", uri, null, function(json) {
		var obj = JSON.parse(json);
		var items = obj.items;
		var len = items.length;
		console.log("DATA GROUPS");
		console.log("==========");
		for(var i=0; i<items.length; i++) {
			var fullPath = items[i].fullPath;
			console.log("  " + fullPath);
		}
	});
}

//--------------------------------------------------------
function getDataGroup(datagroup) {
//--------------------------------------------------------
	datagroup = datagroup.replace(/\//g, "~");
	var uri = "/mgmt/tm/ltm/data-group/internal/" + datagroup;
	handleVERB("GET", uri, null, function(json) {
		var obj = JSON.parse(json);
		console.log(obj);
	});
}

//--------------------------------------------------------
function createDataGroup(datagroup) {
//--------------------------------------------------------

	datagroup = datagroup.replace(/\//g, "~");
	var uri = "/mgmt/tm/ltm/data-group/internal";

	var dgObj = {};
	dgObj.name = datagroup;
	dgObj.type = "string";
	dgObj.records = [
		{name: "a", data: "data 1"},
		{name: "b", data: "data 2"},
		{name: "c", data: "data 3"},
	];

	var body = JSON.stringify(dgObj);

	handleVERB("POST", uri, body, function(json) {
		console.log(json);
	});
}

//--------------------------------------------------------
function deleteDataGroup(datagroup) {
//--------------------------------------------------------
	dg_uri = datagroup.replace(/\//g, "~");
	var uri = "/mgmt/tm/ltm/data-group/internal/" + dg_uri;

	handleVERB("DELETE", uri, null, function(json) {
		console.log(json);
	});
}

//--------------------------------------------------------
function removeFromDataGroup(datagroup) {
//--------------------------------------------------------
	dg_uri = datagroup.replace(/\//g, "~");
	var uri = "/mgmt/tm/ltm/data-group/internal/" + dg_uri;

	var dgObj = {};
	dgObj.name = datagroup;
	dgObj.records = [
		{name: "a", data: "data 1"},
		{name: "b", data: "data 2"}
	];

	var body = JSON.stringify(dgObj);

	handleVERB("PATCH", uri, body, function(json) {
		console.log(json);
	});
}

//--------------------------------------------------------
function addToDataGroup(datagroup) {
//--------------------------------------------------------
	dg_uri = datagroup.replace(/\//g, "~");
	var uri = "/mgmt/tm/ltm/data-group/internal/" + dg_uri;

	var dgObj = {};
	dgObj.name = datagroup;
	dgObj.records = [
		{name: "a", data: "data 1"},
		{name: "b", data: "data 2"},
		{name: "d", data: "data 4"},
		{name: "e", data: "data 5"}
	];

	var body = JSON.stringify(dgObj);

	handleVERB("PATCH", uri, body, function(json) {
		console.log(json);
	});
}

//========================================================
//
//========================================================

if ( null == DATAGROUP ) {
	getDataGroupList();
} else {
	if ( ACTION == "create" ) {
		createDataGroup(DATAGROUP);
  } else if ( ACTION == "remove_from" ) {
		removeFromDataGroup(DATAGROUP);
	} else if ( ACTION == "add_to" ) {
		addToDataGroup(DATAGROUP);
	} else if ( ACTION == "delete" ) {
		deleteDataGroup(DATAGROUP);
	} else {
		getDataGroup(DATAGROUP);
	}
}

