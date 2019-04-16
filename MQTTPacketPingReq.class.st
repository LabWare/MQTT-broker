"
The Ping Packet.
"
Class {
	#name : #MQTTPacketPingReq,
	#superclass : #MQTTPacket,
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPacketPingReq class >> commentOriginal [

"A MQTTPacketPingReq is a way for us to ping the server to make sure that the network is still awake, that the server is still talking to us and that we are still here. See section 3.12

There is no variable header nor payload. We expect a PINGRESP in return (3.12.4)
"

]

{ #category : #mqtt }
MQTTPacketPingReq >> evaluateFor: anMQTTServer [ 

	"Got PINGREQ from client"

    anMQTTServer handlePingReqPacket: self
]

{ #category : #mqtt }
MQTTPacketPingReq >> packetType [

    ^12
]
