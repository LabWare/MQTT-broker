"
This was part of Tim Rowledge's testing, might not work now
"
Class {
	#name : #MQTTBadPacketTestTestBadMsgIDConnect,
	#superclass : #MQTTPacketConnect,
	#category : #MQTT
}

{ #category : #mqtt }
MQTTBadPacketTestTestBadMsgIDConnect >> encodePayloadOn: aWriteStream [ 

	"write my payload onto the stream- 
	the client ID
	iff it exists, the will topic
		the will message
 iff it exists, the username
	iff it exists, the password"
    | bytes |

    bytes := ByteArray new: 2.
    bytes at: 1 put: 16rA0.
    bytes at: 2 put: 16rA1.
    self encode16BitInteger: bytes size on: aWriteStream.
    aWriteStream nextPutAll: bytes.
    self encodeWillDataOn: aWriteStream.
    self encodeUsernameOn: aWriteStream.
    self encodePasswordOn: aWriteStream
]
