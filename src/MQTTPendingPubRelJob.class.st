"
Pending, on a publish  failure, try again
"
Class {
	#name : #MQTTPendingPubRelJob,
	#superclass : #MQTTPendingJob,
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPendingPubRelJob class >> commentOriginal [

"A PUBLISH packet with qos=2 has been receieved and we have sent the appropriate PUBREC acknowledgment and now we expect a corresponding PUBREL sometime.
An MQTTPendingPubRelJob is used to record that expectation; it also holds the original PUBREC in case we need to re-send it. Once we get the PUBREL we send back a PUBCOMP packet and conclude our little dance"

]

{ #category : #mqtt }
MQTTPendingPubRelJob >> isPubRelID: msgID [ 

	"am I a pending PUBREL job for msgId?"

    ^self packetID = msgID
]

{ #category : #mqtt }
MQTTPendingPubRelJob >> resendFor: anMQTTClient ifNeededAtTime: seconds [ 

	"If seconds (which is the actual time - the retryTime currently in use) > my last sendTime,	 resend my original packet with any required changes and update that sendTime"

    seconds >= sendTime
        ifTrue:[
            sendTime := Time totalSeconds.
            self debugLog: '*******************resendFor MQTTPacketPubRec for ' , originalPacket packetID asString.
            anMQTTClient statPerform: #resendType: with: MQTTPacketPubRec asString.
            anMQTTClient sendPacket: (MQTTPacketPubRec new packetID: originalPacket packetID)]
]
