"
Pending, on a publish  failure, try again
"
Class {
	#name : #MQTTPendingPubRecJob,
	#superclass : #MQTTPendingJob,
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPendingPubRecJob class >> commentOriginal [

"A PUBLISH packet with qos=2 has been sent and we expect a corresponding PUBREC sometime soon.
An MQTTPendingPubRecJob is used to record that expectation; it also holds the original PUBLISH in case we need to re-send it - and we set the DUP flag to true when we get the original packet in order to be ready. Once we get the PUBREC we send back a PUBREL packet and do a little dance"

]

{ #category : #mqtt }
MQTTPendingPubRecJob >> completeFor: anMQTTClient [ 

	"we're done; close me down, release me and *not* my ID to our rest"

    anMQTTClient releasePendingJob: self
]

{ #category : #mqtt }
MQTTPendingPubRecJob >> isPubRecID: msgID [ 

	"am I a pending PUBREC job for msgId?"

    ^self packetID = msgID
]

{ #category : #mqtt }
MQTTPendingPubRecJob >> originalPacket [

	"I need to set the DUP bit in case of a resend"

    originalPacket prepareForResend.
    ^originalPacket
]

{ #category : #mqtt }
MQTTPendingPubRecJob >> originalPacketDoNotTouchDupFlag: mqttSubscribePacket [ 

		  "don't touch dup flag"

    super originalPacket: mqttSubscribePacket.
]
