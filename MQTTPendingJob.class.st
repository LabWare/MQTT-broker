"
Abstract class for pending jobs. 
"
Class {
	#name : #MQTTPendingJob,
	#superclass : #Object,
	#instVars : [
		'originalPacket',
		'sendTime'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPendingJob class >> commentOriginal [

"MQTTPendingJobs are a way to record some response we are waiting to get from the broker.
For example, when we publish something at qos=1 we add a pending job for a PUBACK - an MQTTPendingPubAckJob."

]

{ #category : #mqtt }
MQTTPendingJob class >> for: anMQTTPacket [ 

	"return a pending job for the packet"

    ^self new originalPacket: anMQTTPacket
]

{ #category : #mqtt }
MQTTPendingJob class >> forDoNotTouchDupFlag: anMQTTPacket [ 

	"return a pending job for the packet"

    ^self new originalPacketDoNotTouchDupFlag: anMQTTPacket
]

{ #category : #mqtt }
MQTTPendingJob >> completeFor: anMQTTClient [ 

	"we're done; close me down, release me and my ID to our rest"

    anMQTTClient releasePendingJob: self
]

{ #category : #mqtt }
MQTTPendingJob >> debugLog: aString [ 

	  "debug"

    MQTTClientInterface debugLog: self packetID printString tag: ' PJ MsgID:' str2: aString
]

{ #category : #mqtt }
MQTTPendingJob >> isPubAckID: msgID [ 

	"am I a pending PUBACK job for msgId?"

    ^false
]

{ #category : #mqtt }
MQTTPendingJob >> isPubCompID: msgID [ 

	"am I a pending PUBCOMP job for msgId?"

    ^false
]

{ #category : #mqtt }
MQTTPendingJob >> isPubRecID: msgID [ 

	"am I a pending PUBREC job for msgId?"

    ^false
]

{ #category : #mqtt }
MQTTPendingJob >> isPubRelID: msgID [ 

	"am I a pending PUBREL job for msgId?"

    ^false
]

{ #category : #mqtt }
MQTTPendingJob >> isSubAckID: msgID [ 

	"am I a pending SUBACK job for msgId?"

    ^false
]

{ #category : #mqtt }
MQTTPendingJob >> isUnsubAckID: msgID [ 

	"am I a pending UNSUBACK job for msgId?"

    ^false
]

{ #category : #mqtt }
MQTTPendingJob >> originalPacket [

	"Answer my 'originalPacket' instance variable."

    ^originalPacket
]

{ #category : #mqtt }
MQTTPendingJob >> originalPacket: mqttSubscribePacket [ 

	"I need to remember the original subscribe data for later"

    originalPacket := mqttSubscribePacket.
    sendTime := Time totalSeconds + 60 * 60 * 23. "record the last time it was sent"

	"self debugLog: 'futureTime ' , self class asString , ' ' , (Time fromSeconds: sendTime) asString"
]

{ #category : #mqtt }
MQTTPendingJob >> packetID [

    ^originalPacket packetID
]

{ #category : #mqtt }
MQTTPendingJob >> printOn: aStream [ 

		  "printing"

    super printOn: aStream.
    self packetID ifNotNil: [
        aStream nextPutAll: ' msgID: '.
        self packetID printOn: aStream]
]

{ #category : #mqtt }
MQTTPendingJob >> resendFor: anMQTTClient ifNeededAtTime: seconds [ 

	"If seconds (which is the actual time - the retryTime currently in use) > my last sendTime,	 resend my original packet with any required changes and update that sendTime"

    "self debugLog: 'resendFor sendTime: ' , (Time fromSeconds: sendTime) asString , ' ifNeededAtTime: ' , (
		Time fromSeconds: seconds) asString."
    seconds >= sendTime
        ifTrue:[
            sendTime := Time totalSeconds.

			"self debugLog: 'resendFor sendTime: ' , (Time fromSeconds: sendTime) asString."
            self originalPacket: self originalPacket.
            anMQTTClient statPerform: #resendType: with: originalPacket class asString.
            anMQTTClient sendPacket: (MQTTPacketAndPendingJobPair packet: originalPacket pendingJob: self)] "[MQTT-4.6.0-1] [MQTT-4.3.2-1] "
]

{ #category : #mqtt }
MQTTPendingJob >> resetSendTime: aTime [ 

	"set the send time"

    sendTime := Time totalSeconds + aTime. "record the last time it was sent"

	"self debugLog: 'PostPacket Reset sendTime: ' , self class asString , ' ' , (
		Time fromSeconds: sendTime) asString"
]
