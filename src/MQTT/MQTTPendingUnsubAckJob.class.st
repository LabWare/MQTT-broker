"
Pending, on a unsubscription  failure,  just ignore
"
Class {
	#name : #MQTTPendingUnsubAckJob,
	#superclass : #MQTTPendingJob,
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPendingUnsubAckJob class >> commentOriginal [

"A MQTTPendingUnsubAckJob is how we wait for an acknowledgement of an UNSUBSCRIBE. 

It looks like we don't resend these."

]

{ #category : #mqtt }
MQTTPendingUnsubAckJob >> isUnsubAckID: msgID [ 

	"am I a pending UNSUBACK job for msgId?"

    ^self packetID = msgID
]

{ #category : #mqtt }
MQTTPendingUnsubAckJob >> resendFor: anMQTTClient ifNeededAtTime: seconds [ 

	 "do nothing for this packet"

    anMQTTClient statPerform: #resendType: with: MQTTPacketUnsubAck asString.
]
