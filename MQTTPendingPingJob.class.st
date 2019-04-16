"
Pending, on a ping failure, try again
"
Class {
	#name : #MQTTPendingPingJob,
	#superclass : #MQTTPendingJob,
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPendingPingJob class >> commentOriginal [

"A MQTTPendingPingJob is a bit of a hack to support the MQTT keep-alive pings. By adding a pending job for a PINGREQ we can tap into the regular cycle of testing for packets needing a resend; the ping job pushes out a ping and resets it's next-required time. "

]

{ #category : #mqtt }
MQTTPendingPingJob >> completeFor: anMQTTClient [ 

	"I do nothing here; I'm so very special"

]

{ #category : #mqtt }
MQTTPendingPingJob >> initialize [

    sendTime := Time totalSeconds
]

{ #category : #mqtt }
MQTTPendingPingJob >> packetID [

	"return a too-big value for real packets so the #newPacketID check never 'finds' this"

    ^16r10000
]

{ #category : #mqtt }
MQTTPendingPingJob >> resendFor: anMQTTClient ifNeededAtTime: seconds [ 

	"If seconds (which is the actual time - the retryTime currently in use) > my last sendTime,  tell the client to ping and update the sendTime. #ping returns a good time to re-ping"

    seconds >= sendTime
        ifTrue:[sendTime := anMQTTClient ping]
]
