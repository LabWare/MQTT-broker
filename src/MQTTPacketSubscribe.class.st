"
The Subscribe  packet
"
Class {
	#name : #MQTTPacketSubscribe,
	#superclass : #MQTTPacketVariableHeadedWithPayload,
	#instVars : [
		'payloadDict'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPacketSubscribe class >> commentOriginal [

"A MQTTPacketSubscribe contains a request to the server for future information on a topic or topics. We only send them. See section 3.8

The variable header consists of a msgID set by us (3.8.2). It will be used by the server iff qos > 0 and we are supposed to make sure msgIDs are not used by multiple active packets. This would seem to require some complex checking within lists of active packets, or other tag collections. The Python implementation doesn't seem to even pretend to do this right.

The payload is a list of topic filter strings (there must be at least one topic requested) accompanied by a requested qos (3.8.3).

The server must respond with a SUBACK having the same msgID."

]

{ #category : #mqtt }
MQTTPacketSubscribe >> addTopic: aString qos: aSmallNumber [ 

	"add this topic to the payload along with its qos request. Some checking for validity wouldn't be a bad idea"

    payloadDict at: aString put: (aSmallNumber min: 2 max: 0)
]

{ #category : #mqtt }
MQTTPacketSubscribe >> decodePayloadFrom: aReadStream [ 

	"read my payload from the stream"
    | topic qos estimatedEnd |

    estimatedEnd := remainingLength - 2.
        [
        topic := self decodeStringFrom: aReadStream. "[MQTT-3.8.3-1]"
        (topic isNil or: [topic size = 0])
            ifTrue:[self badTopicError].
        qos := aReadStream next asInteger.
        payloadDict at: topic put: qos.
        estimatedEnd := estimatedEnd - (topic size) - 2 - 1.
        estimatedEnd = 0] whileFalse.
]

{ #category : #mqtt }
MQTTPacketSubscribe >> encodeOn: aWriteStream [ 

	"check for having at least one topic and qos-request pair - fail if not"

    payloadDict ifEmpty: [^self badTopicListError].
    ^super encodeOn: aWriteStream
]

{ #category : #mqtt }
MQTTPacketSubscribe >> encodePayloadOn: aWriteStream [ 

	"write my payload onto the stream"

    payloadDict keysAndValuesDo: [:key :val |
        self encodeString: key on: aWriteStream.
        aWriteStream nextPut: (val bitAnd: 3)]
]

{ #category : #mqtt }
MQTTPacketSubscribe >> evaluateFor: anMQTTServer [ 

	"I've been received by the client so now is the time to come to the aid of the party"

    ^anMQTTServer handleSubscribePacket: self
]

{ #category : #mqtt }
MQTTPacketSubscribe >> fixedHeaderFlags [

    ^2
]

{ #category : #mqtt }
MQTTPacketSubscribe >> initialize [

	"I need a dictionary prepared for the payload(s)"

    payloadDict := OrderedDictionary new: 2 "keep initial guess small"
]

{ #category : #mqtt }
MQTTPacketSubscribe >> packetType [

    ^8
]

{ #category : #mqtt }
MQTTPacketSubscribe >> payloadDict [

	"Answer my 'payloadDict' instance variable."

    ^payloadDict
]

{ #category : #mqtt }
MQTTPacketSubscribe >> pendingJob [

	"Return a pending SUBACK to complete later"

    ^MQTTPendingSubAckJob new originalPacket: self
]

{ #category : #mqtt }
MQTTPacketSubscribe >> printOn: aStream [ 

	  "print useful data"

    super printOn: aStream.
    aStream nextPutAll: ' topics: '.
    payloadDict keys printOn: aStream.
]
