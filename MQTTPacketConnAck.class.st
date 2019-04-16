"
The Connection ACK packet
"
Class {
	#name : #MQTTPacketConnAck,
	#superclass : #MQTTPacketVariableHeaded,
	#instVars : [
		'sessionPresent',
		'byte1',
		'byte2'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPacketConnAck class >> commentOriginal [

"An MQTTPacketConnAck is returned by the server after we send a CONNECT, per MQTT3.1.1 doc.
We only receive these and a CONNACK is supposed to be the first packet sent from the serer after a CONNECT. (3.2).

The variable header has no msgID field but instead 2 bytes containing
a) connect acknowledge flags - (3.2.2.1) - currently just the lowest bit of the byte representing the Session Present flag
b) connect return code (3.2.2.3)- an accept (\0) or failure code (\1-\5 see table 3.1)

There is no payload
"

]

{ #category : #mqtt }
MQTTPacketConnAck >> byte1 [

	"Answer my 'byte1' instance variable."

    ^byte1
]

{ #category : #mqtt }
MQTTPacketConnAck >> byte2 [

	"Answer my 'byte2' instance variable."

    ^byte2
]

{ #category : #mqtt }
MQTTPacketConnAck >> byte2: aValue [ 

	"Set my 'byte2' instance variable to aValue."

    byte2 := aValue
]

{ #category : #mqtt }
MQTTPacketConnAck >> decodeVariableHeaderFrom: aReadStream [ 

	"I don't use the msgID stuff; my variable header contains a connect flag and the acknowledge flags per section 3.2.2 of the spec"

    byte1 := aReadStream next.
    (byte1 anyMask: 16rFE)
        ifTrue:[^self badConnectAcknowledgeError].
    sessionPresent := byte1 allMask: 1.
    byte2 := aReadStream next.
]

{ #category : #mqtt }
MQTTPacketConnAck >> encodeVariableHeaderOn: aWriteStream [ 

"write the connect acknowledge flags and return code to the stream"

    byte1 := sessionPresent asBit.
    aWriteStream
        nextPut: sessionPresent asBit;
        nextPut: byte2
]

{ #category : #mqtt }
MQTTPacketConnAck >> evaluateFor: anMQTTClient [ 

	"The broker has responded to a CONNECT from me"

    anMQTTClient handleConnAckPacket: self
]

{ #category : #mqtt }
MQTTPacketConnAck >> packetType [

    ^2
]

{ #category : #mqtt }
MQTTPacketConnAck >> printOn: aStream [ 

	  "debug print"
    | byteToPrint |

    super printOn: aStream.
    aStream nextPutAll: ' session present: '.
    sessionPresent printOn: aStream.
    byteToPrint := byte1 ifNil: ['nil'] ifNotNil: [
        byte1 asInteger printPaddedWith: ($0) to: 2 base: 16].
    aStream nextPutAll: ' byte1: '.
    byteToPrint printOn: aStream.
    byteToPrint := byte2 ifNil: ['nil'] ifNotNil: [
        byte2 asInteger printPaddedWith: ($0) to: 2 base: 16].
    aStream nextPutAll: ' byte2: '.
    byteToPrint printOn: aStream.
]

{ #category : #mqtt }
MQTTPacketConnAck >> sessionPresent [

	"after connecting the client should check that this is ok; a false value implies the server doesn't have any retained state from a prior connection. This may be important to the client"

    ^sessionPresent
]

{ #category : #mqtt }
MQTTPacketConnAck >> sessionPresent: aValue [ 

	"Set my 'sessionPresent' instance variable to aValue."

    sessionPresent := aValue
]

{ #category : #mqtt }
MQTTPacketConnAck >> testSessionPresent: boolean [

    sessionPresent := boolean
]
