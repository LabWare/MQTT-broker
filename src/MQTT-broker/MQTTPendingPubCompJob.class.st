"
Pending, on a publish  failure, try again with a MQTTPacketPubRel
"
Class {
	#name : #MQTTPendingPubCompJob,
	#superclass : #MQTTPendingJob,
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPendingPubCompJob class >> commentOriginal [

"A PUBLISH packet with qos=2 has been sent, the PUBREC has arrived, we have sent the PUBREL and we expect a corresponding PUBCOMP soon.
An MQTTPendingPubCompJob is used to record that expectation; it also holds the original PUBREL in case we need to re-send it. Sending the PUBCOMP is the end of the dance."

]

{ #category : #mqtt }
MQTTPendingPubCompJob >> isPubCompID: msgID [ 

	"am I a pending PUBCOMP job for msgId?"

    ^self packetID = msgID
]

{ #category : #mqtt }
MQTTPendingPubCompJob >> resendFor: anMQTTClient ifNeededAtTime: seconds [ 

	"If seconds (which is the actual time - the retryTime currently in use) > my last sendTime,	 resend my original packet with any required changes and update that sendTime"

    seconds >= sendTime
        ifTrue:[
            sendTime := Time totalSeconds.
            self debugLog: '*******************resendFor MQTTPacketPubRel for ' , originalPacket packetID asString.
            anMQTTClient statPerform: #resendType: with: MQTTPacketPubRel asString.
            anMQTTClient sendPacket: (MQTTPacketPubRel new packetID: originalPacket packetID)] "[MQTT-2.3.1-3]"
]
