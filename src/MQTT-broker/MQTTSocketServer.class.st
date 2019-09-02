"
This class interfaces to our Data Brokder . In VSE this is a more complicated object as it was a subclass of the 1995 VSE Socket object for sockets connected to the data broker.
"
Class {
	#name : #MQTTSocketServer,
	#superclass : #Object,
	#instVars : [
		'transport',
		'interface'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTSocketServer >> acceptFrom: aSocket [
	"Let the superclass set up the server for socket events then remove the


		write event from those we're responding to. This server doesn't need them."

	self debugLog: 'MQTTServer saw Socket start:'.
	transport := MQTTTransportLayerServer new.	"[MQTT-7.0.0-1]"
	transport start: aSocket.
	interface addNewSocketServer: self.
	self initializeMQTTConnection: true
]

{ #category : #mqtt }
MQTTSocketServer >> debugLog: aString [ 

	  "debug data"

    MQTTClientInterface debugLog: self printString tag: ' TS ' str2: aString
]

{ #category : #mqtt }
MQTTSocketServer >> disconnect [

	"disconnect on purpose"

    self transport ifNotNil: [self transport disconnect: false].
    transport := nil
]

{ #category : #mqtt }
MQTTSocketServer >> initializeMQTTConnection: anObject [

		"initialize"

]

{ #category : #mqtt }
MQTTSocketServer >> interface: aValue [ 

	"Set my 'interface' instance variable to aValue."

    interface := aValue
]

{ #category : #mqtt }
MQTTSocketServer >> printOn: aStream [ 

	"print useful data"

    super printOn: aStream.
    aStream nextPutAll: ' socket: '.
]

{ #category : #mqtt }
MQTTSocketServer >> transport [

	"Answer my 'transport' instance variable."

    ^transport
]

{ #category : #mqtt }
MQTTSocketServer >> transport: aValue [ 

	"Set my 'transport' instance variable to aValue."

    transport := aValue
]
