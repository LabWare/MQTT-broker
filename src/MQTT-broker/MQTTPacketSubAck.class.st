"
The Subscribe ACK packet
"
Class {
	#name : #MQTTPacketSubAck,
	#superclass : #MQTTPacketVariableHeadedWithPayload,
	#instVars : [
		'returnCodes'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPacketSubAck class >> commentOriginal [

"A MQTTPacketSubAck is the response from the server to a SUBSCRIBE packet. We only receive these. See section 3.9

The variable header consists of the same msgID as the initiating SUBSCRIBE.

The payload is a list of return codes in the same order as the originallly SUBSCRIBEd topics. Each code provides the maximum qos the server will allow for each topic, or \128 for a failure (3.9.3)"

]

{ #category : #mqtt }
MQTTPacketSubAck >> decodePayloadFrom: aReadStream [
	"read my payload from the stream"

    returnCodes := aReadStream next: (remainingLength -2)
]

{ #category : #mqtt }
MQTTPacketSubAck >> encodePayloadOn: aWriteStream [ 

	"write my payload onto the stream"

    aWriteStream nextPutAll: self returnCodes
]

{ #category : #mqtt }
MQTTPacketSubAck >> evaluateFor: anMQTTClient [ 

	"The broker has responded to a SUBSCRIBE from me"

    anMQTTClient handleSubAckPacket: self
]

{ #category : #mqtt }
MQTTPacketSubAck >> fixedHeaderFlags [

		"fixed header"

    ^16r90
]

{ #category : #mqtt }
MQTTPacketSubAck >> packetType [

    ^9
]

{ #category : #mqtt }
MQTTPacketSubAck >> returnCodes [

	"Answer my 'returnCodes' instance variable."

    ^returnCodes
]

{ #category : #mqtt }
MQTTPacketSubAck >> returnCodes: aValue [ 

	"Set my 'returnCodes' instance variable to aValue."

    returnCodes := aValue
]
