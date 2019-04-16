"
The Publish ACK packet
"
Class {
	#name : #MQTTPacketPubAck,
	#superclass : #MQTTPacketVariableHeaded,
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPacketPubAck class >> commentOriginal [

"An MQTTPacketPubAck is the response to a PUBLISH packet with a qos = 1. See section 3.4 We have to both send and receive them.

The variable header contains the msgID that was included in the relevant PUBLISH packet. There is no payload.
"

]

{ #category : #mqtt }
MQTTPacketPubAck >> evaluateFor: anMQTTClient [ 

	"The broker has responded to a PUBLISH from me with qos=1"

    anMQTTClient handlePubAckPacket: self
]

{ #category : #mqtt }
MQTTPacketPubAck >> packetType [

    ^4
]
