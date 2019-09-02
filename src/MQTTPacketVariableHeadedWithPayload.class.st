"
Abstract packet for variable headers with payload
"
Class {
	#name : #MQTTPacketVariableHeadedWithPayload,
	#superclass : #MQTTPacketVariableHeaded,
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPacketVariableHeadedWithPayload class >> commentOriginal [

"MQTTPacketVariableHeadedWithPayload is an abstract class for the packets with both variable headers and payloads.
	CONNECT
	PUBLISH
	SUBSCRIBE
	SUBACK
	UNSUBSCRIBE"

]

{ #category : #mqtt }
MQTTPacketVariableHeadedWithPayload >> decodeFrom: aReadStream [ 

	"decode my fixed header and then my variable header and then my payload"

    super decodeFrom: aReadStream.
    self decodePayloadFrom: aReadStream
]

{ #category : #mqtt }
MQTTPacketVariableHeadedWithPayload >> decodePayloadFrom: aReadStream [ 

	"read my payload from the stream"

    "default version does nothing yet"
]

{ #category : #mqtt }
MQTTPacketVariableHeadedWithPayload >> encodePayloadOn: aWriteStream [ 

	"write my payload onto the stream"

    "default version does nothing yet"
]

{ #category : #mqtt }
MQTTPacketVariableHeadedWithPayload >> messageID [

	"set the message ID; may need to check validity of these"

    ^msgID
]

{ #category : #mqtt }
MQTTPacketVariableHeadedWithPayload >> messageID: aNumber [ 

	"set the message ID; may need to check validity of these"

    msgID := aNumber
]
