"
The Publish Rel packet
"
Class {
	#name : #MQTTPacketPubRel,
	#superclass : #MQTTPacketVariableHeaded,
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPacketPubRel class >> commentOriginal [

"A MQTTPacketPubRel is the third response to a PUBLISH with a qos = 2. We need to both send and receive these. See section 3.6

The variable header contains the msgID that was included in the relevant PUBLISH packet. There is no payload."

]

{ #category : #mqtt }
MQTTPacketPubRel >> acknowledgement [

		"ack the packet"

    ^MQTTPacketPubComp new packetID: msgID "[MQTT-2.3.1-3]"
]

{ #category : #mqtt }
MQTTPacketPubRel >> evaluateFor: anMQTTClient [ 

	"The broker has responded to a PUBLISH from me with qos=2"

    anMQTTClient handlePubRelPacket: self
]

{ #category : #mqtt }
MQTTPacketPubRel >> fixedHeaderFlags [

    ^2
]

{ #category : #mqtt }
MQTTPacketPubRel >> packetType [

    ^6
]

{ #category : #mqtt }
MQTTPacketPubRel >> pendingJob [

	"Return a pending PUBCOMP to complete later"

    ^MQTTPendingPubCompJob for: self
]
