"
Pending, on a subscription  failure,  just ignore
"
Class {
	#name : #MQTTPendingSubAckJob,
	#superclass : #MQTTPendingJob,
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPendingSubAckJob class >> commentOriginal [

"A MQTTPendingSubAckJob is how we wait for an acknowledgement of a SUBSCRIBE. We need to check the returned error codes for each subscription we sent.

It looks like we don't resend these."

]

{ #category : #mqtt }
MQTTPendingSubAckJob >> completeFor: anMQTTClient [ 

  "we're done; close me down, release me and my ID to our rest"

    super completeFor: anMQTTClient.

	"Now do the checking of the return codes"
    self debugLog: 'suback return codes need handling'.

	"PayLoad will contain 0x00 - Success - Maximum QoS 0 


0x01 - Success - Maximum QoS 1 


0x02 - Success - Maximum QoS 2 


0x80 - Failure "
]

{ #category : #mqtt }
MQTTPendingSubAckJob >> isSubAckID: msgID [ 

	"am I a pending SUBACK job for msgId?"

    ^self packetID = msgID
]

{ #category : #mqtt }
MQTTPendingSubAckJob >> resendFor: anMQTTClient ifNeededAtTime: seconds [ 

	"do nothing for this packet"

    anMQTTClient statPerform: #resendType: with: MQTTPacketSubAck asString.
]
