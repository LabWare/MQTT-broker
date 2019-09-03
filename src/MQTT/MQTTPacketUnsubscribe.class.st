"
The UnSubscribe ACK packet
"
Class {
	#name : #MQTTPacketUnsubscribe,
	#superclass : #MQTTPacketVariableHeadedWithPayload,
	#instVars : [
		'topics'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPacketUnsubscribe class >> commentOriginal [

"A MQTTPacketUnsubscribe is how we unsubscribe from topics and we only send them to the server. See section 3.10

The variable header is just a msgID that we provide. See also the MQTTPacketSubscribe class comment. (3.10.2)

The payload is a list of topics that we no longer wish to subscribe to (3.10.3); it does not have to exactly match subscribed topics and mismatched topics will be ignored. The server may complete delivery of data relating to now unsubscribed topics if there are already buffered or in-progress broadcasts such as qos>0 messages. (3.10.4).
"

]

{ #category : #mqtt }
MQTTPacketUnsubscribe >> addTopic: aTopic [ 

	"add a topic to unsubscribe from"

    topics add: aTopic
]

{ #category : #mqtt }
MQTTPacketUnsubscribe >> decodePayloadFrom: aReadStream [ 

	"read my payload from the stream"
    | topic estimatedEnd |

    estimatedEnd := remainingLength - 2.
        [
        topic := self decodeStringFrom: aReadStream. "[MQTT-3.10.3-1]"
        (topic isNil or: [topic size = 0 or: [(MQTTSubscription for: topic qos: 0 value do: [:x :y :z | ]) isNil]])
            ifTrue:[self badTopicError].
        topics add: topic.
        estimatedEnd := estimatedEnd - (topic size) - 2.
        estimatedEnd = 0] whileFalse.
]

{ #category : #mqtt }
MQTTPacketUnsubscribe >> encodeOn: aWriteStream [ 

	"check for having at least one topic and qos-request pair - fail if not"

    topics ifEmpty: [^self badTopicListError].
    ^super encodeOn: aWriteStream
]

{ #category : #mqtt }
MQTTPacketUnsubscribe >> encodePayloadOn: aWriteStream [ 

	"write my payload onto the stream"

    topics do: [:val | self encodeString: val on: aWriteStream]
]

{ #category : #mqtt }
MQTTPacketUnsubscribe >> evaluateFor: anMQTTClient [ 

	"The server has to handle unsubscribe"

    anMQTTClient handleUnsubscribePacket: self
]

{ #category : #mqtt }
MQTTPacketUnsubscribe >> fixedHeaderFlags [

    ^2
]

{ #category : #mqtt }
MQTTPacketUnsubscribe >> initialize [

    topics := OrderedCollection new: 2
]

{ #category : #mqtt }
MQTTPacketUnsubscribe >> packetType [

    ^10
]

{ #category : #mqtt }
MQTTPacketUnsubscribe >> pendingJob [

	"Return a pending UNSUBACK to complete later"

    ^MQTTPendingUnsubAckJob for: self
]

{ #category : #mqtt }
MQTTPacketUnsubscribe >> printOn: aStream [ 

	"print useful data"

    super printOn: aStream.
    aStream nextPutAll: ' topics: '.
    topics printOn: aStream.
]

{ #category : #mqtt }
MQTTPacketUnsubscribe >> topics [

		"Answer my 'topics' instance variable."

    ^topics
]
