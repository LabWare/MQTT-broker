"
Abstraction for variable header packets
"
Class {
	#name : #MQTTPacketVariableHeaded,
	#superclass : #MQTTPacket,
	#instVars : [
		'remainingLength',
		'msgID'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPacketVariableHeaded class >> commentOriginal [

"MQTTPacketVariableHeaded is an abstract class for the packets that include a variable header.
	CONNACK
	PUBACK
	PUBCOMP
	PUBREC
	PUBREL
	UNSUBACK
"

]

{ #category : #mqtt }
MQTTPacketVariableHeaded >> decodeByteArrayFrom: aReadStream [ 

"read a byteArray from the stream, remembering that it will be prepended with a 16 bit integer indicating the length of the string. Conver t from UTF8 to vse character mapping."
    | ln bytes |

    ln := self decode16BitIntegerFrom: aReadStream.
    bytes := aReadStream next: ln.
    ^bytes
]

{ #category : #mqtt }
MQTTPacketVariableHeaded >> decodeFrom: aReadStream [ 

	"decode my fixed header and then my variable header"

    super decodeFrom: aReadStream.
    self decodeVariableHeaderFrom: aReadStream
]

{ #category : #mqtt }
MQTTPacketVariableHeaded >> decodeLengthFrom: aReadStream [ 

"pull bytes from the stream and convert to the remainingLength value for this packet"
    | byte shift val |

    shift := 0.
    val := 0.
        [
        byte := aReadStream next.
        (byte isNil or: [shift > 21])
            ifTrue:[self encodedLengthError].
        val := val + ((byte bitAnd: 127) << shift).
        shift := shift + 7.
        (byte bitAnd: 128) > 0] whileTrue.
    remainingLength := val
]

{ #category : #mqtt }
MQTTPacketVariableHeaded >> decodeStringFrom: aReadStream [ 

"read a string from the stream, remembering that it will be prepended with a 16 bit integer indicating the length of the string. Conver t from UTF8 to vse character mapping."
    | ln string |

    ln := self decode16BitIntegerFrom: aReadStream.
    string := aReadStream next: ln.
    ^UTF8Encoder decode: string asString
]

{ #category : #mqtt }
MQTTPacketVariableHeaded >> decodeVariableHeaderFrom: aReadStream [ 

"read the variable header from the stream. Not all subclasses actually use msgIDs, so be careful to catch those"

    msgID := self decode16BitIntegerFrom: aReadStream
]

{ #category : #mqtt }
MQTTPacketVariableHeaded >> encodeFixedHeaderOn: aWriteStream [ 

"write the fixed header on the stream"

    aWriteStream nextPut: self fixedHeader.
    self encodeLengthOn: aWriteStream
]

{ #category : #mqtt }
MQTTPacketVariableHeaded >> encodeLengthOn: aWriteStream [ 

"encode the remaining length in the odd 7-bit manner used; see mqtt doc table 2.4 etc. write each byte to the stream"
    | val byte |

    val := remainingLength.
        [
        byte := val \\ 128.
        val := val // 128.
        val > 0
            ifTrue:[byte := byte bitOr: 128].
        aWriteStream nextPut: byte.
        val > 0] whileTrue
]

{ #category : #mqtt }
MQTTPacketVariableHeaded >> encodeOn: aWriteStream [ 

	"when writing a packet out	we can either 


		write the fixed header


		calculate the remaining length (which involves doing almost all the work below) and writing that out


		write the variable header


		write the payload(s)


	or


		make a temporary stream


		write the variable header to the temp stream


		write the payload(s) tothe temp stream


		calculate the remaining length value from the size of the temp stream


		write the fixed header to the original stream


		write the calculated size to the original stream


		write the temp stream to the original stream


	I'm going to try the second method here. It might be even cleaner to use nextPutAllFlush: tempStream contents, but maybe later"
    | tempStream |

    tempStream := MQTTWriteStream on: (ByteArray new: self guessEncodedLength).
    self encodeVariableHeaderOn: tempStream.
    self encodePayloadOn: tempStream.
    remainingLength := tempStream position.
    self encodeFixedHeaderOn: aWriteStream.
    aWriteStream next: tempStream position putAll: tempStream contents startingAt: 1.
    aWriteStream flush.
    ^aWriteStream
]

{ #category : #mqtt }
MQTTPacketVariableHeaded >> encodePayloadOn: ignored [ 

	"do nothing; subclasses that actually have payloads must do Their Own Thing"

]

{ #category : #mqtt }
MQTTPacketVariableHeaded >> encodeVariableHeaderOn: aWriteStream [ 

"write the basic variable header to the stream. Not all subclasses actually use msgIDs, so be careful to catch those, and some subclass this method to add more data"

    self encode16BitInteger: msgID on: aWriteStream
]

{ #category : #mqtt }
MQTTPacketVariableHeaded >> guessEncodedLength [

	"make a plausible guess at the final encoded length, erring on the side of excess"

    ^100
]

{ #category : #mqtt }
MQTTPacketVariableHeaded >> packetID [

	"return the packet identifier that many of my subclasses (but not all!) contain"

    ^msgID
]

{ #category : #mqtt }
MQTTPacketVariableHeaded >> packetID: a16BitNumber [ 

	"set the packet identifier that many of my subclasses (but not all!) contain.
	We ought to test this for validitiy"

    msgID := a16BitNumber
]

{ #category : #mqtt }
MQTTPacketVariableHeaded >> printOn: aStream [ 

		  "printing"

    super printOn: aStream.
    msgID ifNotNil: [
        aStream nextPutAll: ' msgID: '.
        msgID printOn: aStream]
]
