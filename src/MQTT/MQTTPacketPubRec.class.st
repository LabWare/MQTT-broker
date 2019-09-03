"
The Publish Rec packet
"
Class {
	#name : #MQTTPacketPubRec,
	#superclass : #MQTTPacketVariableHeaded,
	#instVars : [
		'originalPacket'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPacketPubRec class >> commentOriginal [

"A MQTTPacketPubRec is the response to a PUBLISH packet with qos =2; it is the second part of the exchange. We have to bothe send and receive them. See section 3.5

The variable header contains the msgID from the relevant PUBLISH packet. There is no payload."

]

{ #category : #mqtt }
MQTTPacketPubRec >> acknowledgement [

	"return a PUBREL packet to acknowledge receiveing me"

    ^MQTTPacketPubRel new packetID: msgID
]

{ #category : #mqtt }
MQTTPacketPubRec >> evaluateFor: anMQTTClient [ 

	"The broker has responded to a PUBLISH from me with qos=2"

    anMQTTClient handlePubRecPacket: self
]

{ #category : #mqtt }
MQTTPacketPubRec >> originalPacket [

	"Answer my 'originalPacket' instance variable."

    ^originalPacket
]

{ #category : #mqtt }
MQTTPacketPubRec >> originalPacket: aValue [ 

	"Set my 'originalPacket' instance variable to aValue."

    originalPacket := aValue
]

{ #category : #mqtt }
MQTTPacketPubRec >> packetType [

    ^5
]
