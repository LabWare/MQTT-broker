"
The Ping  response Packet.
"
Class {
	#name : #MQTTPacketPingResp,
	#superclass : #MQTTPacket,
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPacketPingResp class >> commentOriginal [

"A MQTTPacketPingResp gets sent back from the server in response to a PINGREQ. See section 3.13

There is no variable header nor payload."

]

{ #category : #mqtt }
MQTTPacketPingResp >> evaluateFor: anMQTTClient [ 

	"The broker has responded to a PINGREQ from me; we should check that it is reasonably timely and if not, close the connection and do whatever retry stuff seems proper"

    anMQTTClient handlePingRespPacket: self
]

{ #category : #mqtt }
MQTTPacketPingResp >> packetType [

    ^13
]
