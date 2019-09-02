"
Abstract class for different MQTT packets.
"
Class {
	#name : #MQTTPacket,
	#superclass : #Object,
	#classVars : [
		'MQTTProtocolLevel311',
		'PacketTypes'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPacket class >> badPacketTypeError [

"raise an exception at some point; for now just halt"

    self debugLog: 'badPacketTypeError'.
    MQTTBadPacketTypeException signal.
]

{ #category : #mqtt }
MQTTPacket class >> commentOriginal [

	"MQTTPacket is the root class for specific varieties of MQTT packet. It only provides the outline of the fixed header etc. Subclasses provide the packets that have only the fixed header - 
	DISCONNECT
	PINGREQ
	PINGRESP
    
Others provide the sub-hierarchies for packets with variable headers and payloads.

See the comment for MQTTClient for usage details"

]

{ #category : #mqtt }
MQTTPacket class >> debugLog: aString [ 

		  "debug"

    MQTTClientInterface debugLog: aString tag: ' PP ' str2: ''
]

{ #category : #mqtt }
MQTTPacket class >> emptyStreamError [

"raise an exception at some point; for now just halt"

    ^MQTTEmptyStreamErrorException signal: 'MQTT no bytes available to be read'
]

{ #category : #mqtt }
MQTTPacket class >> initialize [

	"set up the packet type list etc  MQTTPacket initialize"

    "self initialize"
    PacketTypes := OrderedCollection new add: MQTTPacketConnect; add:  MQTTPacketConnAck; add: MQTTPacketPublish; add: MQTTPacketPubAck;  add: MQTTPacketPubRec; add: MQTTPacketPubRel; add: MQTTPacketPubComp; add: MQTTPacketSubscribe; add: MQTTPacketSubAck; add: MQTTPacketUnsubscribe; add: MQTTPacketUnsubAck; add: MQTTPacketPingReq; add: MQTTPacketPingResp; add: MQTTPacketDisconnect; yourself.
    MQTTProtocolLevel311 := 4 "encoding for CONNECT etc"
]

{ #category : #mqtt }
MQTTPacket class >> readFrom: aReadStream [ 

"read the stream to work out which kind of packet it contains, create a suitable instance and get that to read the rest of the data"
    | byte |

    byte := [aReadStream peek] on: ConnectionTimedOut do: [:ex | self emptyStreamError].
	 byte ifNil: [^self emptyStreamError].
    ^(PacketTypes at: byte >> 4 ifAbsent: [self badPacketTypeError]) new readFrom: aReadStream
]

{ #category : #mqtt }
MQTTPacket >> badConnectAcknowledgeError [

"raise an exception at some point; for now just halt"

    self debugLog: 'badConnectAcknowledgeError'.
    MQTTConnectionException signal: 'badConnectAcknowledgeError'.
]

{ #category : #mqtt }
MQTTPacket >> badFixedHeaderError [

"raise an exception at some point; for now just halt"

    self debugLog: 'badFixedHeaderError'.
    ^MQTTBadHeaderException signal
]

{ #category : #mqtt }
MQTTPacket >> badQosError [

"raise an exception at some point; for now just halt"

    self debugLog: 'badQosError'.
    MQTTBadHeaderException signal: 'badQosError'.
]

{ #category : #mqtt }
MQTTPacket >> badTopicError [

"raise an exception at some point; for now just halt"

    self debugLog: 'badTopicError'.
    MQTTBadTopicException signal: 'badTopicError'.
]

{ #category : #mqtt }
MQTTPacket >> badTopicListError [

"raise an exception at some point; for now just halt"

    self debugLog: 'badTopicListError'.
    MQTTBadTopicException signal: 'badTopicListError'.
]

{ #category : #mqtt }
MQTTPacket >> connectionRefusedError: refusalCode [ 

"raise an exception at some point; for now just halt"

    self debugLog: 'connectionRefusedError:'.
    ^MQTTCONNECTException connectReturnCode: refusalCode.
]

{ #category : #mqtt }
MQTTPacket >> debugLog: aString [ 

		  "debug"

    self class debugLog: aString
]

{ #category : #mqtt }
MQTTPacket >> decode16BitIntegerFrom: aReadStream [ 

	"read a 16bit number MSB format from the stream"

    ^aReadStream next << 8 + aReadStream next
]

{ #category : #mqtt }
MQTTPacket >> decodeFixedHeaderFrom: aReadStream [ 

"read the fixed header from the stream and check it for decent state; the only class needing to do anything clever is MQTTPacketPublish"
    | token |

    token := aReadStream next.
    token = self fixedHeader
        ifFalse:[self badFixedHeaderError].
    self decodeLengthFrom: aReadStream
]

{ #category : #mqtt }
MQTTPacket >> decodeFrom: aReadStream [ 

	"decode me from the stream. I only have a fixed header"

    self decodeFixedHeaderFrom: aReadStream
]

{ #category : #mqtt }
MQTTPacket >> decodeLengthFrom: aReadStream [ 

"the default for fixed header only packets is 0 but we have to pull the next byte from the stream to keep the input buffer balanced"
    | byte |

    byte := aReadStream next.
    byte > 0
        ifTrue:[self encodedLengthError]
]

{ #category : #mqtt }
MQTTPacket >> encode16BitInteger: smallNumber on: aWriteStream [ 

	"write a 16bit number MSB format on the stream"

    aWriteStream
        nextPut: (smallNumber >> 8);
        nextPut: (smallNumber bitAnd: 16rFF)
]

{ #category : #mqtt }
MQTTPacket >> encodeOn: aWriteStream [ 

	"basic encoding of my data onto a stream (usually a socket) to transmit. I only have a fixed header.
	The fixed header only classes are all 2 bytes in size, giving a remaining length of 0.
	See MQTTPacketVariableHeaded>>#encodeOn: for the more complex arrangements for variable size packets"

    aWriteStream
        nextPut: self fixedHeader;
        nextPut: 0;
        flush.
    ^aWriteStream
]

{ #category : #mqtt }
MQTTPacket >> encodeString: aString on: aWriteStream [ 

	"generic write of string to the strea,; convert to UTF8, prepend with the 16 bit MSB length of said utf8 string"
    | bytes |

    bytes := UTF8Encoder encode: aString asString.
    self encode16BitInteger: bytes size on: aWriteStream.
    aWriteStream nextPutAll: bytes
]

{ #category : #mqtt }
MQTTPacket >> encodedLengthError [

"raise an exception at some point; for now just halt"

    self debugLog: 'encodedLengthError'.
    MQTTBadHeaderException signal: 'encodedLengthError'.
]

{ #category : #mqtt }
MQTTPacket >> evaluateFor: anMQTTCLient [ 

	"I've been received by the client so now is the time to come to the aid of the party"

    ^self subclassResponsibility
]

{ #category : #mqtt }
MQTTPacket >> fixedHeader [

"return the byte for the fixed header; 
this is the packet type 4 bit value << 4 | the flags particular to the type.
For almost all kinds of packet this is a fixed number. "

    ^self packetType << 4 bitOr: self fixedHeaderFlags
]

{ #category : #mqtt }
MQTTPacket >> fixedHeaderFlags [

	"default for most classes is 0"

    ^0
]

{ #category : #mqtt }
MQTTPacket >> packetType [
	^nil
]

{ #category : #mqtt }
MQTTPacket >> readFrom: aReadStream [

    self decodeFrom: aReadStream
]
