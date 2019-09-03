"
Pending, on a publish  failure, try again with the DUP bit set	!
"
Class {
	#name : #MQTTPendingPubAckJob,
	#superclass : #MQTTPendingJob,
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPendingPubAckJob class >> commentOriginal [

"A PUBLISH packet with qos=1 has been sent and we expect a corresponding PUBACK sometime soon.
An MQTTPendingPubAckJob is used to record that expectation; it also holds the original PUBLISH in case we need to re-send it - and we set the DUP flag to true when we get the original packet in order to be ready."

]

{ #category : #mqtt }
MQTTPendingPubAckJob >> isPubAckID: msgID [ 

	"am I a pending PUBACK job for msgId?"

    ^self packetID = msgID
]

{ #category : #mqtt }
MQTTPendingPubAckJob >> originalPacket [

	"I need to set the DUP bit in case of a resend"

    originalPacket prepareForResend.
    ^originalPacket
]

{ #category : #mqtt }
MQTTPendingPubAckJob >> originalPacketDoNotTouchDupFlag: mqttSubscribePacket [ 

	  "don't touch dup flag"

    super originalPacket: mqttSubscribePacket.
]
