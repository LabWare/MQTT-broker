"
This class interfaces to aZnMultiThreadedServer Object. In VSE this is a more complicated object as it was a subclass of the 1995 VSE Socket Listener object
"
Class {
	#name : #MQTTSocketDaemon,
	#superclass : #ZnMultiThreadedServer,
	#instVars : [
		'interface',
		'serverClass'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTSocketDaemon class >> openOnPort: p serverClass: s interface: anInterface [ 

	"A convenient way to create a daemon which simply starts a server on each connection attempt"
    | aDaemon |

    aDaemon := self new.
	 aDaemon optionAt: #port put: p.
	 aDaemon serverClass: s.
    aDaemon interface: anInterface.
    ^aDaemon
]

{ #category : #mqtt }
MQTTSocketDaemon >> defaultPort [

	"Answer the default port for the MQTTDaemon"

    ^1883
]

{ #category : #mqtt }
MQTTSocketDaemon >> interface [

	"Answer my 'interface' instance variable."

    ^interface
]

{ #category : #mqtt }
MQTTSocketDaemon >> interface: aValue [ 

	"Set my 'interface' instance variable to aValue."

    interface := aValue
]

{ #category : #mqtt }
MQTTSocketDaemon >> port [
	"Return the integer port number we are (or will be) listening on"
	
	^ self optionAt: #port ifAbsent: [ self defaultPort ] 
]

{ #category : #mqtt }
MQTTSocketDaemon >> serveConnectionsOn: listeningSocket [
	"We wait up to acceptWaitTimeout seconds for an incoming connection.
	If we get one we wrap it in a SocketStream and #executeRequestResponseLoopOn: on it"
		 
	| socket server |
	socket := listeningSocket waitForAcceptFor: self acceptWaitTimeout.
	socket ifNil: [ ^ self noteAcceptWaitTimedOut ].
	server := self serverClass new.
   server interface: interface.
   server acceptFrom: socket
]

{ #category : #mqtt }
MQTTSocketDaemon >> serverClass [

	"Answer the class we want to instantiate when a connection is accepted"

    ^serverClass
]

{ #category : #mqtt }
MQTTSocketDaemon >> serverClass: aClass [

	serverClass := aClass
]
