"
This is the MQTT data broker partner logic, which handles packets not normally handled by a MQTT client. Such as the Connect/Disconnect packet. 
"
Class {
	#name : #MQTTTransportLayerServer,
	#superclass : #MQTTTransportLayer,
	#instVars : [
		'serverInterface',
		'socketServer',
		'clientIDString',
		'mutexForDisconnect',
		'keepAliveTime',
		'lastPingTime'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTTransportLayerServer >> abort: aValue [ 

	"Set my 'abort' instance variable to aValue."

    abort := aValue
]

{ #category : #mqtt }
MQTTTransportLayerServer >> clientIDString [

	"Answer my 'clientIDString' instance variable."

    ^clientIDString
]

{ #category : #mqtt }
MQTTTransportLayerServer >> disconnect: restart [ 

	"close the connection"

	 (self preambleWorkAbortEarlyIfTrue: restart)
		ifTrue: [ ^self ].
    super disconnect: false.
    self serverInterface ifNotNil: [self serverInterface removeSocketServer: self socketServer].
]

{ #category : #mqtt }
MQTTTransportLayerServer >> disconnectPostCleanup [

		"disconnect"

    super disconnectPostCleanup.

]

{ #category : #mqtt }
MQTTTransportLayerServer >> doSubscriptionActionsFor: aPublishPacket [ 

	"find the subscriptions matching the topic of this packet and the corresponding Blocks to evaluate, then run them"

    self serverInterface handlePublishedPacket: aPublishPacket usingTransport: self
]

{ #category : #mqtt }
MQTTTransportLayerServer >> handleConnectPacket: aConnectPacket [ 

    "check for Error"
    | connectAckPacket |

    clientIDString := aConnectPacket clientIDString.
    keepAliveTime := aConnectPacket keepAliveTime.
    lastPingTime := Time primUTCSecondsClock.
    connectAckPacket := MQTTPacketConnAck new.
    connectAckPacket sessionPresent: (
        self serverInterface sessionPresentViaConnectPacket: aConnectPacket).
    connectAckPacket byte2: aConnectPacket returnCode.
    mutexForDisconnect critical: [
        self serverInterface addNewClientIDUsingTransport: self withConnectPacket: aConnectPacket passingConnAck: connectAckPacket]. "[MQTT-3.1.4-4] [MQTT-3.2.0-1]"

    "At the momment we don't make any return codes other than zero

	[MQTT-3.2.2-4] [MQTT-3.2.2-5] [MQTT-3.2.2-6]"
]

{ #category : #mqtt }
MQTTTransportLayerServer >> handleDisconnectPacket: aDisconnectPacket [ 

	"disconnect"

    self mutexForDisconnect critical: [| sock| "		"
    self serverInterface ifNil: [^self].
    self serverInterface disableWillLogic: clientIDString. "[MQTT-3.1.2-10]"
    sock := self socketServer.
    [[sock close] on: Error do: [:ex | ]] fork.]. "[MQTT-3.14.4-1]"
]

{ #category : #mqtt }
MQTTTransportLayerServer >> handlePingReqPacket: aPingPacket [ 

	"ping"
    | packetPingResp |

    "[MQTT-3.12.4-1]"
    lastPingTime := Time primUTCSecondsClock.
    packetPingResp := MQTTPacketPingResp new.
    self sendPacket: packetPingResp
]

{ #category : #mqtt }
MQTTTransportLayerServer >> handlePublishResponse: aPublishPacket [ 

	"publish the packet"
    | pj |

    " [MQTT-3.3.4-1], [MQTT-2.3.1-4] [MQTT-4.3.1-1] [MQTT-4.3.2-2][MQTT-4.3.3-1]"
    aPublishPacket qos = 0
        ifTrue:[^self sendPacket: aPublishPacket].
    aPublishPacket messageID: self newPacketID.
    aPublishPacket qos = 1
        ifTrue:[ "[MQTT-4.3.2-1]"
            (self findPendingJob: [:j | j isPubAckID: aPublishPacket packetID]) ifNotNil: [^self].
            self addPending: (pj := aPublishPacket pendingAckJob).
            ^self sendPacket: (MQTTPacketAndPendingJobPair packet: aPublishPacket pendingJob: pj)].
    aPublishPacket qos = 2
        ifTrue:[ "[MQTT-4.3.3-1]"
            (self findPendingJob: [:j | j isPubRecID: aPublishPacket packetID]) ifNotNil: [^self].
            self addPending: (pj := aPublishPacket pendingReceiveJob).
            ^self sendPacket: (MQTTPacketAndPendingJobPair packet: aPublishPacket pendingJob: pj)]
]

{ #category : #mqtt }
MQTTTransportLayerServer >> handleSubscribePacket: aSubscribePacket [ 

	"subscribe"
    | packetSubAck bitsBack |

    self debugLog: aSubscribePacket payloadDict keys printString.
    ((aSubscribePacket payloadDict isNil) or: [aSubscribePacket payloadDict size = 0])
        ifTrue:[^self badTopicError]. "[MQTT-3.8.3-3]"
    self serverInterface addNewSubscription: aSubscribePacket forClientID: clientIDString.
    packetSubAck := MQTTPacketSubAck new.
    packetSubAck messageID: aSubscribePacket messageID. "[MQTT-2.3.1-3] [MQTT-3.8.4-2]"
    bitsBack := ByteArray new: aSubscribePacket payloadDict size.
    1 to: bitsBack size do: [:i |
        bitsBack at: i put: (
            (aSubscribePacket payloadDict keys at: i) = 'test/nosubscribe'
                ifTrue:[16r80]
                ifFalse:[aSubscribePacket payloadDict at: (aSubscribePacket payloadDict keyAtIndex: i)])].
    self debugLog: bitsBack printString.
    packetSubAck returnCodes: bitsBack. "MQTT-3.8.4-5] [MQTT-3.9.3-1] [MQTT-3.9.3-2]"
    self sendPacket: packetSubAck. "[MQTT-3.8.4-1] [MQTT-3.8.4-4]"
]

{ #category : #mqtt }
MQTTTransportLayerServer >> handleUnsubscribePacket: aUnsubscribePacket [ 

	"unsubscribe"
    | packetUnsubAck |

    self serverInterface removeSubscriptions: aUnsubscribePacket forClientID: clientIDString.
    ((aUnsubscribePacket topics isNil) or: [aUnsubscribePacket topics size = 0])
        ifTrue:[^self badTopicError]. "[MQTT-3.10.3-2]"
    packetUnsubAck := MQTTPacketUnsubAck new.
    packetUnsubAck packetID: aUnsubscribePacket messageID. "[MQTT-3.10.4-4]"
    self sendPacket: packetUnsubAck. "[MQTT-3.10.4-4] MQTT-3.10.4-5]"
]

{ #category : #mqtt }
MQTTTransportLayerServer >> initialize [

	super initialize.
	lastPingTime := Time primUTCSecondsClock.
]

{ #category : #mqtt }
MQTTTransportLayerServer >> keepAliveTime [

	"Answer my 'keepAliveTime' instance variable."

    ^keepAliveTime
]

{ #category : #mqtt }
MQTTTransportLayerServer >> lastPingTime [

	"Answer my 'lastPingTime' instance variable."

    ^lastPingTime
]

{ #category : #mqtt }
MQTTTransportLayerServer >> lastPingTime: aTime [

	  lastPingTime := aTime
]

{ #category : #mqtt }
MQTTTransportLayerServer >> mutexForDisconnect [

	"Answer my 'mutexForDisconnect' instance variable."

    ^mutexForDisconnect
]

{ #category : #mqtt }
MQTTTransportLayerServer >> printOn: aStream [ 

	  "print useful data"

    super printOn: aStream.
    aStream nextPutAll: ' ClientID: '.
    clientIDString asString printOn: aStream.
    aStream nextPutAll: ' kat: '.
    keepAliveTime asString printOn: aStream.
]

{ #category : #mqtt }
MQTTTransportLayerServer >> release [

	"release cycles"

    super release.
    serverInterface := nil.
    socketServer release.
    socketServer := nil.
]

{ #category : #mqtt }
MQTTTransportLayerServer >> restartTheSocket [

	"flag to indicate if we restart after disconnect"

    ^false
]

{ #category : #mqtt }
MQTTTransportLayerServer >> serverInterface [

	"Answer my 'serverInterface' instance variable."

    ^serverInterface
]

{ #category : #mqtt }
MQTTTransportLayerServer >> serverInterface: aValue [ 

	"Set my 'serverInterface' instance variable to aValue."

    serverInterface := aValue
]

{ #category : #mqtt }
MQTTTransportLayerServer >> socketServer [

	"Answer my 'socketServer' instance variable."

    ^socketServer
]

{ #category : #mqtt }
MQTTTransportLayerServer >> socketServer: aValue [ 

	"Set my 'socketServer' instance variable to aValue."

    socketServer := aValue
]

{ #category : #mqtt }
MQTTTransportLayerServer >> start: aSocket [ 

	"startup logic"

    mutexForDisconnect := Semaphore forMutualExclusion.
    lastPingTime := Time primUTCSecondsClock.
	 keepAliveTime := 0.
    super start: aSocket
]

{ #category : #mqtt }
MQTTTransportLayerServer >> statPerform: selector [ 

			"consolidate error handler"

    super statPerform: selector.
    [self serverInterface statPerform: selector] on: Error do: [:ex | ].
]

{ #category : #mqtt }
MQTTTransportLayerServer >> statPerform: selector with: arg [ 

			"consolidate error handler"

    super statPerform: selector with: arg.
    self serverInterface ifNotNil: [self serverInterface statPerform: selector with: arg]
]

{ #category : #mqtt }
MQTTTransportLayerServer >> transportType [

		"transport type"

    ^' SS '
]
