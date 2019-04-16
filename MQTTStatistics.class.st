"
Collect statistics on the server & client socket/interface usage
"
Class {
	#name : #MQTTStatistics,
	#superclass : #Object,
	#instVars : [
		'pin',
		'pout',
		'poutMaxSize',
		'poutMinSize',
		'pinMaxSize',
		'pinMinSize',
		'pinBytes',
		'poutBytes',
		'pinTypeCount',
		'poutTypeCount',
		'errorTypes',
		'connections',
		'disconnect',
		'connected',
		'connectionTypes',
		'servers',
		'subscriptions',
		'timeOut',
		'killSocket',
		'sentPackets',
		'queuedPackets',
		'unsubscribe',
		'badConnections',
		'missingType',
		'resendType'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTStatistics >> addConnectPacket: aConnectPacket [ 

	"connect packet"

    connections := connections + 1.
    connected add: aConnectPacket clientIDString.
    aConnectPacket cleanSessionFlag
        ifTrue:[connectionTypes add: #clean].
    aConnectPacket willFlag
        ifTrue:[connectionTypes add: #will].
]

{ #category : #mqtt }
MQTTStatistics >> addServer [

	"server"

    servers := servers + 1.
]

{ #category : #mqtt }
MQTTStatistics >> addSubscription: aSubscribePacket [ 

	"server"

    aSubscribePacket payloadDict keys do: [:t | subscriptions add: t].
]

{ #category : #mqtt }
MQTTStatistics >> badConnections [

	"badConnections"

    badConnections := badConnections + 1.
]

{ #category : #mqtt }
MQTTStatistics >> disconnect [

	"disconnect"

    disconnect := disconnect + 1.
]

{ #category : #mqtt }
MQTTStatistics >> errorTypes: aMessage [ 

		  "error types"

    errorTypes add: aMessage
]

{ #category : #mqtt }
MQTTStatistics >> initialize [

	"zero"

    pin := 0.
    pout := 0.
    poutMaxSize := 0.
    poutMinSize := 1000000.
    poutBytes := 0.
    poutTypeCount := Bag new.
    pinMaxSize := 0.
    pinMinSize := 1000000.
    pinBytes := 0.
    pinTypeCount := Bag new.
    errorTypes := Bag new.
    connections := 0.
    disconnect := 0.
    connected := Set new.
    connectionTypes := Bag new.
    servers := 0.
    subscriptions := Bag new.
    timeOut := 0.
    killSocket := 0.
    sentPackets := 0.
    queuedPackets := 0.
    unsubscribe := 0.
    badConnections := 0.
    missingType := Bag new.
    resendType := Bag new.
]

{ #category : #mqtt }
MQTTStatistics >> killSocket [

	"killSocket"

    killSocket := killSocket + 1.
]

{ #category : #mqtt }
MQTTStatistics >> packetIn: aPacket [ 

	"pin"
    | pType |

    pin := pin + 1.
    pType := aPacket class.
    pinTypeCount add: pType asString asSymbol.
    pType = MQTTPacketPublish
        ifTrue:[
            | sz|sz := aPacket message size.
            pinBytes := pinBytes + sz.
            pinMaxSize < sz
                ifTrue:[pinMaxSize := sz].
            pinMinSize > sz
                ifTrue:[pinMinSize := sz]].
]

{ #category : #mqtt }
MQTTStatistics >> packetOut: aPacket [ 

	"pin"
    | pType thePacket |

    pout := pout + 1.
    pType := aPacket class.
    thePacket := aPacket.
    pType = MQTTPacketAndPendingJobPair
        ifTrue:[
            pType := aPacket packet class.
            thePacket := aPacket packet].
    poutTypeCount add: pType asString asSymbol.
    pType = MQTTPacketPublish
        ifTrue:[
            | sz|sz := thePacket message size.
            poutBytes := poutBytes + sz.
            poutMaxSize < sz
                ifTrue:[poutMaxSize := sz].
            poutMinSize > sz
                ifTrue:[poutMinSize := sz]].
]

{ #category : #mqtt }
MQTTStatistics >> queuedPackets [

	"queuedPackets"

    queuedPackets := queuedPackets + 1.
]

{ #category : #mqtt }
MQTTStatistics >> removeServer [

	"server"

    servers := servers - 1.
]

{ #category : #mqtt }
MQTTStatistics >> removeSubscription: aUnsubscribePacket [ 

	"aUnsubscribePacket"

    unsubscribe := unsubscribe + aUnsubscribePacket topics size
]

{ #category : #mqtt }
MQTTStatistics >> resendType: aType [ 

	"resendType:"

    resendType add: aType
]

{ #category : #mqtt }
MQTTStatistics >> sentPackets [

	"sentPackets"

    sentPackets := sentPackets + 1.
]

{ #category : #mqtt }
MQTTStatistics >> timeOut [

	"timeOut"

    timeOut := timeOut + 1.
]
