"
The unsubscribe Ack packet
"
Class {
	#name : #MQTTPacketUnsubAck,
	#superclass : #MQTTPacketVariableHeaded,
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPacketUnsubAck class >> commentOriginal [

"A MQTTPacketUnsubAck is returned by the server after an UNSUBSCRIBE. See section 3.11

The variable header is just the msgID provided by the initiating UNSUBSCRIBE packet (3.11.2). There is no payload. An UNSUBSCRIBE that lists several topics is responded to with a single UNSUBACK (3.10.4). We get the UNSUBACK even if no topics are actually cancelled."

]

{ #category : #mqtt }
MQTTPacketUnsubAck >> evaluateFor: anMQTTClient [ 

	"The broker has responded to an UNSUB from me"

    anMQTTClient handleUnsubAckPacket: self
]

{ #category : #mqtt }
MQTTPacketUnsubAck >> packetType [

    ^11
]
