"
The Disconnect Packet.
"
Class {
	#name : #MQTTPacketDisconnect,
	#superclass : #MQTTPacket,
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPacketDisconnect class >> commentOriginal [

	"A MQTTPacketDisconnect is how we close down the server connection and is the final action before closing sockets etc. See section 3.14

There is no variable header nor payload. We must not send any more packets to the server after sending the DISCONNECT and must close the network connection to the server. This does NOT cause any associated Will Message to be published. (3.14.4)"

]

{ #category : #mqtt }
MQTTPacketDisconnect >> evaluateFor: anMQTTClient [ 

	"The broker has to handle discoonect"

    anMQTTClient handleDisconnectPacket: self
]

{ #category : #mqtt }
MQTTPacketDisconnect >> packetType [

    ^14
]
