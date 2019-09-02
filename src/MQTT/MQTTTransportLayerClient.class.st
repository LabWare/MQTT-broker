"
This is the MQTT client logic. 
"
Class {
	#name : #MQTTTransportLayerClient,
	#superclass : #MQTTTransportLayer,
	#instVars : [
		'pingOK',
		'keepAliveTime',
		'clientID',
		'socketClient'
	],
	#classVars : [
		'ClientID'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTTransportLayerClient class >> clientID [

		"get clientID"

    ClientID ifNil: [ClientID := UUID new asString].
    ^ClientID
]

{ #category : #mqtt }
MQTTTransportLayerClient >> clientID: clientIDString [ 

	"set the id that the server will use to identify the session being established by this connect packet. It ought to be unique within the scope of this image, ideally totally unique. That's up to the user of this class though"

    clientID := clientIDString
]

{ #category : #mqtt }
MQTTTransportLayerClient >> clientIDString [

	"ought to come from the client but if it hasn't been set use a vaguely useful default"

    ^clientID ifNil: [self class clientID]
]

{ #category : #mqtt }
MQTTTransportLayerClient >> disconnect: restart [ 

	"close the connection"

	(self preambleWorkAbortEarlyIfTrue: restart)
		ifTrue: [ ^self ].

    super disconnect: restart.
    (restart)
        ifTrue:[
				[| itf|itf := self socketClient interface.
            itf ifNotNil: [itf restart]] fork]
]

{ #category : #mqtt }
MQTTTransportLayerClient >> disconnectPostCleanup [

		"disconnect"

    super disconnectPostCleanup.
 
]

{ #category : #mqtt }
MQTTTransportLayerClient >> doSubscriptionActionsFor: aPublishPacket [ 

	"find the subscriptions matching the topic of this packet and the corresponding Blocks to evaluate, then run them"

    currentSubscriptions copy do: [:s |
        s handlePacket: aPublishPacket] "Make a copy to avoid race with unsubscribe"
]

{ #category : #mqtt }
MQTTTransportLayerClient >> handleConnAckPacket: aConnAckPacket [ 

	"check for Error"

    aConnAckPacket byte2 > 0
        ifTrue:[MQTTConnectionException signal].
]

{ #category : #mqtt }
MQTTTransportLayerClient >> handlePingRespPacket: aPingRespPacket [ 

	"just set the pingOK status to true"

    pingOK := true
]

{ #category : #mqtt }
MQTTTransportLayerClient >> initializeKeepAlive [

	"set up the keep alive process. If the keepalive time is 0 the server should simply leave the connection open as long as possible and so we don't worry about this process. Otherwise, add a pending ping job that will repeat"

    keepAliveTime = 0 "[MQTT-3.1.2-23]"
        ifFalse:[self addPending: MQTTPendingPingJob new]
]

{ #category : #mqtt }
MQTTTransportLayerClient >> keepAliveTime: timeInSecs [ 

	"set the keep-alive time, in seconds not mS, that should be used by the server and the keepalive process. Do not alter this after the connection is opened"

    keepAliveTime := timeInSecs
]

{ #category : #mqtt }
MQTTTransportLayerClient >> ping [

	"send a PINGREQ and scehdule a pending PINGRESP. Return a time for the next ping"

    pingOK := false.
    self sendPacket: MQTTPacketPingReq new.
    ^Time totalSeconds + keepAliveTime
]

{ #category : #mqtt }
MQTTTransportLayerClient >> restart: aSocket [ 

	"restart logic"

    outgoingPacketQueue := outgoingPacketQueue copy flushAllSuchThat: [:p |
        p class = MQTTPacketDisconnect or: [p class = MQTTPacketConnect]].
    packetInFlightQueue := packetInFlightQueue copy flushAllSuchThat: [:p |
        p class = MQTTPacketDisconnect or: [p class = MQTTPacketConnect]].
    super restart: aSocket.
    self initializeKeepAlive
]

{ #category : #mqtt }
MQTTTransportLayerClient >> sendPossibleDisconnectPackage [

		"do nothing"

    self sendPacket: MQTTPacketDisconnect new.
    Processor yield.
    (Delay forSeconds: 2) wait.
]

{ #category : #mqtt }
MQTTTransportLayerClient >> socketClient [

	"Answer my 'socketClient' instance variable."

    ^socketClient
]

{ #category : #mqtt }
MQTTTransportLayerClient >> socketClient: aValue [ 

	"Set my 'socketClient' instance variable to aValue."

    socketClient := aValue
]

{ #category : #mqtt }
MQTTTransportLayerClient >> start: aSocket [ 

	"start logic"

    super start: aSocket.
    self initializeKeepAlive
]

{ #category : #mqtt }
MQTTTransportLayerClient >> subscribe: aTopic qos: qos [ 

	"set up a subscription to aTopic with the broker. Use #onTopic:do: for actual client applications"
    | subPacket pj |

    subPacket := MQTTPacketSubscribe new
         addTopic: aTopic qos: qos;
         packetID: self newPacketID.
    self addPending: (pj := subPacket pendingJob).
    self sendPacket: (MQTTPacketAndPendingJobPair packet: subPacket pendingJob: pj)
]

{ #category : #mqtt }
MQTTTransportLayerClient >> transportType [

    ^' CC '
]

{ #category : #mqtt }
MQTTTransportLayerClient >> unsubscribe: aTopic [ 

	"unsubscribe from aTopic and scehdule a pending job to handle the UnsubAck"
    | unsubPacket pj |

    unsubPacket := MQTTPacketUnsubscribe new
         addTopic: aTopic;
         packetID: self newPacketID.
    self addPending: (pj := unsubPacket pendingJob).
    self sendPacket: (MQTTPacketAndPendingJobPair packet: unsubPacket pendingJob: pj)
]

{ #category : #mqtt }
MQTTTransportLayerClient >> unsubscribeFrom: aTopic [ 

	"unsubscribe from aTopic - remove the subscription from currentSubscriptions and then tell the broker to unsubscribe"

    currentSubscriptions removeAllSuchThat: [:s | s topicMatches: aTopic].
    self unsubscribe: aTopic
]
