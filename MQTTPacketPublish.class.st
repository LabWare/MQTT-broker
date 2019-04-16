"
The publish packet
"
Class {
	#name : #MQTTPacketPublish,
	#superclass : #MQTTPacketVariableHeadedWithPayload,
	#instVars : [
		'topic',
		'message',
		'duplicate',
		'qos',
		'retain'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPacketPublish class >> commentOriginal [

"An MQTTPacketPublish is used in both directions; we send one to publish information to a server and receive them to get information that we have subscribed to. See section 3.3 of the spec.

The fixed header contains 4 bits of data affecting how the packet is interpreted. These are encodings of the duplicate flag, the qos value and the duplicate flag; all instance variables. See 3.3.1 and #fixedHeaderFlags.
duplicate (3.3.1.1) - this indicates whether this is the first attempt to send this packet. True/1 indicates this may be a re-send.
qos (3.3.1.2 & table 3.2)- a value 0/1/2 (3 is reserved and must not be used) indicating the level of service required.
retain (3.3.1.3) - this indicates whether the message being published should be retained by the server and sent out to any new subscriber as a sort of initial state message

The variable header includes -
a) topic name (3.3.2.1) - (see section 1.5.3) a string of stuff
b) packet ID iff qos > 0

The payload is simply the data being published in an 'application specific format' which presumably includes text or binary, plain or encoded etc. A 0 length payload is acceptable, which may be a way to simply flag status in a minimal manner.

The recipient of a PUBLISH must respond according to the qos required from that packet (3.3.4)"

]

{ #category : #mqtt }
MQTTPacketPublish >> acknowledgement [

	"Depending upon the qos we need to return a PUBACK or a PUBREC"
    | pubRec |

    qos = 0
        ifTrue:[^self badQosError].
    qos = 1
        ifTrue:[^MQTTPacketPubAck new packetID: msgID]. "[MQTT-2.3.1-3] [MQTT-4.6.0-3]"
    pubRec := MQTTPacketPubRec new.
    pubRec packetID: msgID.
    pubRec originalPacket: self.
    ^pubRec
]

{ #category : #mqtt }
MQTTPacketPublish >> decodeFixedHeaderFrom: aReadStream [ 

"read the fixed header from the stream and check it for decent state and extract the special flags"
    | hdrByte |

    (hdrByte := aReadStream next) >> 4 = self packetType
        ifFalse:[self badFixedHeaderError].
    duplicate := hdrByte allMask: 8.
    retain := hdrByte allMask: 1.
    qos := (hdrByte >> 1) bitAnd: 3. "[MQTT-3.3.1-4]. we do not respect"
    self decodeLengthFrom: aReadStream
]

{ #category : #mqtt }
MQTTPacketPublish >> decodeFrom: aReadStream [ 

	"We need to work out the length of the variable header, which may have an arbitrary length utf8 string and packetID, in order to be able to work out how long the payload is"
    | ln |

    self decodeFixedHeaderFrom: aReadStream.
    ln := self decodeVariableHeaderFrom: aReadStream.
    message := aReadStream next: (remainingLength - ln)
]

{ #category : #mqtt }
MQTTPacketPublish >> decodeTopicStringFrom: aReadStream [ 

"read a string from the stream, remembering that it will be prepended with a 16 bit integer indicating the length of the string. Convert from UTF8 to vse character mapping.
Set the string as my topic and return the (encoded) string length to help in decoding the payload.
This replace a simple #decodeStringFrom: normally used"
    | ln string |

    " [MQTT-3.3.2-1"

	"[MQTT-3.3.2-2] has no check"
    ln := self decode16BitIntegerFrom: aReadStream.
    string := aReadStream next: ln.
    topic := [UTF8Encoder decode: string asString] on: Error do: [:ex | 'Failed Topic Decode'].
    ^ln + 2
]

{ #category : #mqtt }
MQTTPacketPublish >> decodeVariableHeaderFrom: aReadStream [ 

	"extract the topic string and then iff qos >0, the msgID. Return the (encoded) length of the variable header to help in decoding the payload"
    | ln |

    ln := self decodeTopicStringFrom: aReadStream. "[MQTT-3.3.2-1]"
    qos > 0
        ifTrue:[
            super decodeVariableHeaderFrom: aReadStream.
            ln := ln + 2].
    ^ln
]

{ #category : #mqtt }
MQTTPacketPublish >> duplicateFlag: aBoolean [ 

	"set my DUP flag; this needs to be done by the client after the first send attempt for a qos>0 packet"

    duplicate := aBoolean
]

{ #category : #mqtt }
MQTTPacketPublish >> encodePayloadOn: aWriteStream [ 

	"PUBLISH packets put the message data out as is with no prepended size field. We work out the data size from the remainingLength value etc"

    aWriteStream nextPutAll: message
]

{ #category : #mqtt }
MQTTPacketPublish >> encodeVariableHeaderOn: aWriteStream [ 

	"PUBLISH packets put the topic into the variable header followed by a msgID iff qos >0"

    topic ifNil: [^self badTopicError].
    self encodeString: topic on: aWriteStream.
    qos > 0
        ifTrue:[super encodeVariableHeaderOn: aWriteStream]
]

{ #category : #mqtt }
MQTTPacketPublish >> evaluateFor: anMQTTClient [ 

	"The broker has sent a PUBLISH packet to me"

    anMQTTClient handlePublishPacket: self qos: qos
]

{ #category : #mqtt }
MQTTPacketPublish >> fixedHeaderFlags [

"a publish packet is the only one with flags dependent upon variable state
DUP - duplicate delivery
QoS - Quality of Service, 2 bits
RETAIN - Retained message flag"

    ^((duplicate
        ifTrue:[8]
        ifFalse:[0]) bitOr: (qos << 1)) bitOr: (
        retain
            ifTrue:[1]
            ifFalse:[0])
]

{ #category : #mqtt }
MQTTPacketPublish >> guessEncodedLength [

		"get the size"

    ^self message size + 100
]

{ #category : #mqtt }
MQTTPacketPublish >> initialize [

	"set default flags & qos"

    qos := 0.
    duplicate := retain := false
]

{ #category : #mqtt }
MQTTPacketPublish >> matchesSubscription: subscription ifTrue: aBlock [ 

	"does my topic match the pattern? If so, evaluate the block"

    (subscription topicMatches: topic)
        ifTrue:[
            aBlock value: topic value: message value: qos]
]

{ #category : #mqtt }
MQTTPacketPublish >> message [

	"Answer my 'message' instance variable."

    ^message
]

{ #category : #mqtt }
MQTTPacketPublish >> messageString [

	"return the message data asa String"

    ^UTF8Encoder decode: message asString
]

{ #category : #mqtt }
MQTTPacketPublish >> packetType [

    ^3
]

{ #category : #mqtt }
MQTTPacketPublish >> pendingAckJob [

	"We are handling a PUBLISH with qos=1 and need to schedule apending handler"

    ^MQTTPendingPubAckJob forDoNotTouchDupFlag: self
]

{ #category : #mqtt }
MQTTPacketPublish >> pendingJob [

	"Depending upon the qos we need to shedule a pending job for a PUBACK or a PUBREC"

    qos = 0
        ifTrue:[^self badQosError].
    qos = 1
        ifTrue:[^MQTTPendingPubAckJob for: self].
    ^MQTTPendingPubRecJob for: self
]

{ #category : #mqtt }
MQTTPacketPublish >> pendingReceiveJob [

	"We are handling a PUBLISH with qos=2 and need to schedule apending handler"

    ^MQTTPendingPubRecJob forDoNotTouchDupFlag: self
]

{ #category : #mqtt }
MQTTPacketPublish >> prepareForResend [

	"set my DUP flag; this needs to be done by the client after the first send attempt for a qos>0 packet"

    "[MQTT-3.3.1.-1]"
    duplicate := true
]

{ #category : #mqtt }
MQTTPacketPublish >> printOn: aStream [ 

	  "print useful data"

    super printOn: aStream.
    aStream nextPutAll: ' t: '.
    topic asString printOn: aStream.
    aStream nextPutAll: ' sz: '.
    message size asString printOn: aStream.
    aStream nextPutAll: ' qos: '.
    qos asString printOn: aStream.
    aStream nextPutAll: ' d: '.
    duplicate asString printOn: aStream.
    aStream nextPutAll: ' r: '.
    retain asString printOn: aStream.
]

{ #category : #mqtt }
MQTTPacketPublish >> qos [

	"Answer my 'qos' instance variable."

    ^qos
]

{ #category : #mqtt }
MQTTPacketPublish >> qos: aValue [ 

	"Set my 'qos' instance variable to aValue."

    qos := aValue
]

{ #category : #mqtt }
MQTTPacketPublish >> retain [

	"Answer my 'retain' instance variable."

    ^retain
]

{ #category : #mqtt }
MQTTPacketPublish >> retainFlag: aBoolean [ 

	"set my RETAIN flag; this is supposed to be set if you want the message to be held by the broker for broadcasting in response to new subscribes."

    retain := aBoolean
]

{ #category : #mqtt }
MQTTPacketPublish >> topic [

		"Answer my 'topic' instance variable."

    ^topic
]

{ #category : #mqtt }
MQTTPacketPublish >> topic: topicString message: messageBytes [ 

	"set my topic string and message data.



	The topic must be a plain String which we will now check for any invalid characters and make sure when converted to UTF8 is still under 64kb long. The messageBytes must be a ByteArray"

    ((UTF8Encoder encode: topicString asString) size > 65535 or: [topicString includesAnyOf: #(
        $# $+ )]) "MQTT-4.7.1-1 MQTT-4.7.3-3"
        ifTrue:[^self badTopicError].
    topic := topicString.
    message := messageBytes
]
