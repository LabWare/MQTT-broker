"
This class holds onto the client information for the data broker. It points to the current transport, the subscriptions, packets incoming and outgoing.
"
Class {
	#name : #MQTTClientIDHolder,
	#superclass : #Object,
	#instVars : [
		'clientID',
		'transport',
		'connectPacket',
		'subscriptionsMutex',
		'subscriptions',
		'packetInFlightQueue',
		'pendingJobs',
		'outgoingPacketQueue',
		'currentSubscriptions',
		'lastMID'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTClientIDHolder class >> with: aClientID transport: aTransport connectPacket: aConnectPacket [ 

		"new"

    ^super new initializeWith: aClientID transport: aTransport connectPacket: aConnectPacket
]

{ #category : #mqtt }
MQTTClientIDHolder >> = aClientID [ 

	"equal"

    (aClientID class = self class)
        ifFalse:[^false].
    ^clientID = aClientID clientID
]

{ #category : #mqtt }
MQTTClientIDHolder >> addSubscription: aSubscriptionPacket [ 

	"add the subscription"

    aSubscriptionPacket payloadDict associationsDo: [:assoc |
        | subscription dict|subscription := MQTTSubscription for: assoc key qos: assoc value do: [:x :y :z | ].
        subscription ifNil: [^aSubscriptionPacket badTopicError].
        subscriptionsMutex critical: [subscriptions at: assoc key put: subscription].
        dict := Dictionary new.
        dict at: subscription topic put: subscription.
        self transport serverInterface forwardRetainMessagesTo: self usingPossibleSubscription: dict "[MQTT-3.8.4-3]"
        ].
]

{ #category : #mqtt }
MQTTClientIDHolder >> cleanSession: aBoolean withNewTransport: newTransport passingConnAck: aConnectAckPacket [ 

	"clean session or not"

    aBoolean
        ifTrue:[ "[MQTT-3.1.2-6]"
            lastMID := nil.
            pendingJobs := nil.
            packetInFlightQueue := nil.
            outgoingPacketQueue := nil.
            currentSubscriptions := nil.
            connectPacket := nil.
            subscriptions := Dictionary new.
            newTransport sendPacket: aConnectAckPacket.
            ^self].
    aBoolean
        ifFalse:[ "renew session [MQTT-3.1.2-4]. [MQTT-4.4.0-1]"
            | packet|outgoingPacketQueue ifNil: [^self].
            newTransport currentSubscriptions: currentSubscriptions.
            newTransport lastMID: lastMID.
            pendingJobs ifNotNil: [pendingJobs do: [:p | p resetSendTime: -60]].
            newTransport pendingJobs: pendingJobs.
            newTransport sendPacket: aConnectAckPacket.
            Processor yield.
            [packet := packetInFlightQueue nextOrNil.
            packet isNil not]
                whileTrue:[self sendPacket: packet onTransport: newTransport].
            outgoingPacketQueue size > 0
                ifTrue:[
                    [packet := outgoingPacketQueue nextOrNil.
                    packet isNil not]
                        whileTrue:[self sendPacket: packet onTransport: newTransport]].
            lastMID := nil.
            pendingJobs := nil.
            packetInFlightQueue := nil.
            outgoingPacketQueue := nil.
            currentSubscriptions := nil]
]

{ #category : #mqtt }
MQTTClientIDHolder >> clientID [

	"Answer my 'clientID' instance variable."

    ^clientID
]

{ #category : #mqtt }
MQTTClientIDHolder >> clientID: aValue [ 

	"Set my 'clientID' instance variable to aValue."

    clientID := aValue
]

{ #category : #mqtt }
MQTTClientIDHolder >> connectPacket [

	"Answer my 'connectPacket' instance variable."

    ^connectPacket
]

{ #category : #mqtt }
MQTTClientIDHolder >> connectPacket: aValue [ 

	"Set my 'connectPacket' instance variable to aValue."

    connectPacket := aValue
]

{ #category : #mqtt }
MQTTClientIDHolder >> hash [

    ^clientID hash
]

{ #category : #mqtt }
MQTTClientIDHolder >> initialize [

	"init"

    subscriptions := Dictionary new.
    subscriptionsMutex := Semaphore forMutualExclusion.
]

{ #category : #mqtt }
MQTTClientIDHolder >> initializeWith: aClientID transport: aTransport connectPacket: aConnectPacket [ 

	"init"

    subscriptions := Dictionary new.
    clientID := aClientID.
    transport := aTransport.
    connectPacket := aConnectPacket.
    subscriptionsMutex := Semaphore forMutualExclusion.
]

{ #category : #mqtt }
MQTTClientIDHolder >> outgoingPacketQueue [

	"Answer my 'outgoingPacketQueue' instance variable."

    ^outgoingPacketQueue
]

{ #category : #mqtt }
MQTTClientIDHolder >> printOn: aStream [ 

	  "print useful data"
    | state |

    super printOn: aStream.
    aStream nextPutAll: ' '.
    clientID asString printOn: aStream.
    state := transport ifNotNil: [
        transport abort
            ifTrue:['Aborting']
            ifFalse:['Connected']] ifNil: ['Disconnected'].
    aStream nextPutAll: ' '.
    state asString printOn: aStream.
]

{ #category : #mqtt }
MQTTClientIDHolder >> release [

	"release cycles"

    super release.
    transport ifNil: [^self].
    self transport release.
    packetInFlightQueue := transport packetInFlightQueue copy.
    outgoingPacketQueue := transport outgoingPacketQueue copy.
    lastMID := transport lastMID.
    pendingJobs := transport pendingJobs.
    currentSubscriptions := transport currentSubscriptions.
    transport := nil
]

{ #category : #mqtt }
MQTTClientIDHolder >> removeSubscription: aUnsubscriptionPacket [ 

	"remove the subscription"

    "[MQTT-3.10.4-1] [MQTT-3.10.4-2] [MQTT-3.10.4-3]"
    aUnsubscriptionPacket topics do: [:topic | "[MQTT-3.10.4-6]"
        | subscription|subscriptionsMutex critical: [subscriptions removeKey: topic ifAbsent: []]].
]

{ #category : #mqtt }
MQTTClientIDHolder >> sendPacket: packet onTransport: newTransport [ 

		  "ensure packet goes to correct location"

    packet class = MQTTPacketPublish
        ifTrue:[newTransport handlePublishResponse: packet]
        ifFalse:[newTransport sendPacket: packet]
]

{ #category : #mqtt }
MQTTClientIDHolder >> subscriptions [

	"Answer my 'subscriptions' instance variable."

    ^subscriptions
]

{ #category : #mqtt }
MQTTClientIDHolder >> subscriptions: aValue [ 

	"Set my 'subscriptions' instance variable to aValue."

    subscriptions := aValue
]

{ #category : #mqtt }
MQTTClientIDHolder >> subscriptionsMutex [

	"Answer my 'subscriptionsMutex' instance variable."

    ^subscriptionsMutex
]

{ #category : #mqtt }
MQTTClientIDHolder >> transport [

	"Answer my 'transport' instance variable."

    ^transport
]

{ #category : #mqtt }
MQTTClientIDHolder >> transport: aValue [ 

	"Set my 'transport' instance variable to aValue."

    transport := aValue
]
