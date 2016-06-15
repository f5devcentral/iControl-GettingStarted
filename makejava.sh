#!/bin/sh

javac -d ./class -classpath .:./lib/axis.jar:./lib/commons-discovery.jar:./lib/commons-logging.jar:./lib/jaxrpc.jar:./lib/saaj.jar:./lib/wsdl4j.jar:./lib/activation.jar:./lib/mail.jar:./lib/iControl.jar SOAPCreatePoolInPartition.java

javac -d ./class -classpath .:./lib/axis.jar:./lib/commons-discovery.jar:./lib/commons-logging.jar:./lib/jaxrpc.jar:./lib/saaj.jar:./lib/wsdl4j.jar:./lib/activation.jar:./lib/mail.jar:./lib/iControl.jar SOAPDataGroup.java
