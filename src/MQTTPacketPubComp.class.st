"
The Publish COMP packet
"
Class {
	#name : #MQTTPacketPubComp,
	#superclass : #MQTTPacketVariableHeaded,
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPacketPubComp class >> commentOriginal [

"A MQTTPacketPubComp is the final response to a PUBLISH with a qos = 2. We need to both send and receive these. See section 3.6

The variable header contains the msgID that was included in the relevant PUBLISH packet. There is no payload.
"

]

{ #category : #mqtt }
MQTTPacketPubComp >> evaluateFor: anMQTTClient [ 

	"The broker has responded to a PUBLISH from me with qos=2"

    anMQTTClient handlePubCompPacket: self
]

{ #category : #mqtt }
MQTTPacketPubComp >> packetType [

    ^7
]
