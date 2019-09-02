"
The Connect packet
"
Class {
	#name : #MQTTPacketConnect,
	#superclass : #MQTTPacketVariableHeadedWithPayload,
	#instVars : [
		'user',
		'password',
		'keepAliveTime',
		'willMessage',
		'willTopic',
		'willQos',
		'willFlag',
		'willRetainFlag',
		'cleanSessionFlag',
		'clientID',
		'returnCode'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPacketConnect class >> commentOriginal [

"An MQTTPacketConnect contains all the data to make a CONNECT request per section 3.1 of the spec. 
We only send these; the server responds with a CONNACK. 

The variable header contains 4 fields to describe
a) protocol name (3.1.2.1) - a fixed 6 bytes of \0\4MQTT
b) protocol level (3.1.2.2) - currently a fixed value of \4 to signify MQTT 3.1.1 with an older version 3.1 using \3. If the returned CONNACK packer has a code of \1 it means the server does not understand the requested protocol version
c)connect flags (3.1.2.3) - a single byte encoding
userFlag | passwordFlag | willRetainedFlag | willQos (2 bits) | willFlag | cleanSessionFlag | reserverved to \0
d) keep alive time (3.1.2.10) - 2 bytes msb-first time in secondsipr\

Following the headers there is a payload containing
a) a client ID (3.1.3.1)
b) an optional Will topic (3.1.3.2) and WIll message (3.1.3.3)
c) an optional user name (3.1.3.4)
d) an optional password (3.1.3.5)

We expect to get a MQTTPacketConnAck back; only one will be sent and we need no matching id to test. Sending a second connect request is supposed to make the server close the connection. (3.1)
"

]

{ #category : #mqtt }
MQTTPacketConnect >> cleanSession: sessionBoolean [ 

	"set the clean session flag; default is true"

    cleanSessionFlag := sessionBoolean
]

{ #category : #mqtt }
MQTTPacketConnect >> cleanSessionFlag [

	"Answer my 'cleanSessionFlag' instance variable."

    ^cleanSessionFlag
]

{ #category : #mqtt }
MQTTPacketConnect >> clientID: clientIDString [ 

	"set the id that the server will use to identify the session being established by this connect packet. It ought to be unique within the scope of this image, ideally totally unique. That's up to the user of this class though"

    clientID := clientIDString
]

{ #category : #mqtt }
MQTTPacketConnect >> clientIDString [

	"ought to come from the client but if it hasn't been set use a vaguely useful default"

    ^clientID ifNil: ['SqueakMQTT']
]

{ #category : #mqtt }
MQTTPacketConnect >> connectFlags [

    | byte |

    byte := willQos << 3.
    byte := byte bitAt: 2 put: cleanSessionFlag asBit.
    byte := byte bitAt: 3 put: willTopic notNil asBit.
    byte := byte bitAt: 6 put: willRetainFlag asBit.
    byte := byte bitAt: 7 put: password notNil asBit.
    byte := byte bitAt: 8 put: user notNil asBit.
    ^byte
]

{ #category : #mqtt }
MQTTPacketConnect >> decodePayloadFrom: aReadStream [ 

  "first read the CONNECT variable header (see 3.1.2) from the stream and then the actualy payload - purely for comparison and test purposes since we only send CONNECT packets. We do this odd order because the variable header includes flags that directly affect how the payload is interpreted"

  "first the 16 bit length of the protocol name"
    | cFlags passwordFlag userFlag protocol version |

    "[MQTT-3.1.4-1]"
    protocol := self decodeStringFrom: aReadStream.
    protocol = 'MQTT'
        ifFalse:[
            self debugLog: 'Protocol found: ' , protocol.
            (self connectionRefusedError: 16r01) signal]. " [MQTT-3.1.2-1]. ignore"
    version := aReadStream next.
    (version = 3 or: [version = 4])
        ifFalse:[self debugLog: 'version found: ' , version]. " [MQTT-3.1.2-2]. ignore"
    cFlags := aReadStream next.
    (cFlags allMask: 1)
        ifTrue:[(self connectionRefusedError: 16r01) signal "[MQTT-3.1.2-3]."
    ].
    cleanSessionFlag := cFlags allMask: 2.

    "We don't support the will logic"
    willFlag := cFlags allMask: 4.
    willRetainFlag := cFlags allMask: 1 << 5.
    willQos := cFlags >> 3 bitAnd: 3.
    passwordFlag := cFlags allMask: 1 << 6.
    userFlag := cFlags allMask: 1 << 7.
    keepAliveTime := self decode16BitIntegerFrom: aReadStream. " [MQTT-3.1.2-24]."
    clientID := self decodeStringFrom: aReadStream. "[MQTT-3.1.3-1]"
    clientID size = 0
        ifTrue:[(self connectionRefusedError: 16r02) signal " [MQTT-3.1.3-9]."
    ].

	"[MQTT-3.1.3-3/4/5/6/7/8] are handled by failure of size 0"
    willFlag
        ifTrue:[
            willTopic := self decodeStringFrom: aReadStream.
            willMessage := self decodeByteArrayFrom: aReadStream].
    userFlag
        ifTrue:[user := self decodeStringFrom: aReadStream].
    passwordFlag
        ifTrue:[password := self decodeByteArrayFrom: aReadStream]. "[MQTT-3.1.2-21]"
    returnCode := 16r00.
]

{ #category : #mqtt }
MQTTPacketConnect >> decodeVariableHeaderFrom: aReadStream [ 

	"do nothing because the actual work is deferred to the decodePayloadFrom: method"

]

{ #category : #mqtt }
MQTTPacketConnect >> encodePasswordOn: aWriteStream [ 

	" if we have a username set, write it to the stream"

    password ifNotNil: [self encodeString: password on: aWriteStream]
]

{ #category : #mqtt }
MQTTPacketConnect >> encodePayloadOn: aWriteStream [ 

	"write my payload onto the stream- 
	the client ID
	iff it exists, the will topic
		the will message
	iff it exists, the username
	iff it exists, the password"

    self encodeString: self clientIDString on: aWriteStream.
    self encodeWillDataOn: aWriteStream.
    self encodeUsernameOn: aWriteStream.
    self encodePasswordOn: aWriteStream
]

{ #category : #mqtt }
MQTTPacketConnect >> encodeUsernameOn: aWriteStream [ 

	" if we have a username set, write it to the stream"

    user ifNotNil: [self encodeString: user on: aWriteStream]
]

{ #category : #mqtt }
MQTTPacketConnect >> encodeVariableHeaderOn: aWriteStream [ 

"write the CONNECT variable header (see 3.1.2) to the stream"

    self encodeString: 'MQTT' on: aWriteStream.
    aWriteStream
        nextPut: MQTTProtocolLevel311;
        nextPut: self connectFlags.
    self encode16BitInteger: keepAliveTime on: aWriteStream
]

{ #category : #mqtt }
MQTTPacketConnect >> encodeWillDataOn: aWriteStream [ 

	"If I have a will set up, write the topic and then the message to the stream"

    willTopic ifNotNil: [
        self encodeString: willTopic on: aWriteStream.
        willMessage ifNil: [self encodeString: '' on: aWriteStream] ifNotNil: [
            self encodeString: willMessage on: aWriteStream]]
]

{ #category : #mqtt }
MQTTPacketConnect >> evaluateFor: anMQTTServer [ 

	"I've been received by the client so now is the time to come to the aid of the party"

    ^anMQTTServer handleConnectPacket: self
]

{ #category : #mqtt }
MQTTPacketConnect >> initialize [

	"set the basic state to no user/password/will stuff/clean, just for safety. Nil is fine for most of them but a couple of flags and values need more specific initial values."

    willRetainFlag := false.
    cleanSessionFlag := true. "normally we are establishing a new connection and don't want old data back"
    willQos := 0.
    keepAliveTime := 60
]

{ #category : #mqtt }
MQTTPacketConnect >> keepAliveTime [

	"Answer my 'keepAliveTime' instance variable."

    ^keepAliveTime
]

{ #category : #mqtt }
MQTTPacketConnect >> keepAliveTime: timeInSecs [ 

	"set the keep alive time interval; default is 60"

    keepAliveTime := timeInSecs
]

{ #category : #mqtt }
MQTTPacketConnect >> packetType [

    ^1
]

{ #category : #mqtt }
MQTTPacketConnect >> printOn: aStream [ 

	"print useful data"

    super printOn: aStream.
    aStream nextPutAll: ' ID: '.
    clientID asString printOn: aStream.
    aStream nextPutAll: ' user: '.
    user asString printOn: aStream.
    aStream nextPutAll: ' kat: '.
    keepAliveTime asString printOn: aStream.
    aStream nextPutAll: ' c: '.
    cleanSessionFlag asString printOn: aStream.
    aStream nextPutAll: ' will: '.
    willFlag asString printOn: aStream.
]

{ #category : #mqtt }
MQTTPacketConnect >> returnCode [

	"Answer my 'returnCode' instance variable."

    ^returnCode
]

{ #category : #mqtt }
MQTTPacketConnect >> returnCode: aValue [ 

	"Set my 'returnCode' instance variable to aValue."

    returnCode := aValue
]

{ #category : #mqtt }
MQTTPacketConnect >> testCleanSessionFlag [

    ^cleanSessionFlag
]

{ #category : #mqtt }
MQTTPacketConnect >> testKeepAlive [

    ^keepAliveTime
]

{ #category : #mqtt }
MQTTPacketConnect >> testPassword [

    ^password
]

{ #category : #mqtt }
MQTTPacketConnect >> testUser [

    ^user
]

{ #category : #mqtt }
MQTTPacketConnect >> testWillMessage [

    ^willMessage
]

{ #category : #mqtt }
MQTTPacketConnect >> testWillQos [

    ^willQos
]

{ #category : #mqtt }
MQTTPacketConnect >> testWillRetain [

    ^willRetainFlag
]

{ #category : #mqtt }
MQTTPacketConnect >> testWillTopic [

    ^willTopic
]

{ #category : #mqtt }
MQTTPacketConnect >> user: userName password: passwd [ 

	"setup the user name and password; it is possible to have either nil, apparently"

    user := userName.
    password := passwd
]

{ #category : #mqtt }
MQTTPacketConnect >> willFlag [

	"Answer my 'willFlag' instance variable."

    ^willFlag
]

{ #category : #mqtt }
MQTTPacketConnect >> willFlag: aValue [ 

	"Set my 'willFlag' instance variable to aValue."

    willFlag := aValue
]

{ #category : #mqtt }
MQTTPacketConnect >> willMessage [

	"Answer my 'willMessage' instance variable."

    ^willMessage
]

{ #category : #mqtt }
MQTTPacketConnect >> willQos [

	"Answer my 'willQos' instance variable."

    ^willQos
]

{ #category : #mqtt }
MQTTPacketConnect >> willRetainFlag [

	"Answer my 'willRetainFlag' instance variable."

    ^willRetainFlag
]

{ #category : #mqtt }
MQTTPacketConnect >> willTopic [

	"Answer my 'willTopic' instance variable."

    ^willTopic
]

{ #category : #mqtt }
MQTTPacketConnect >> willTopic: topicString message: messageString retain: retainBoolean qos: qosValue [ 

	"setup a will message. We must have a topic, the actual message, a retain flag and requested QOS"

    willTopic := topicString.
    willMessage := messageString.
    willRetainFlag := retainBoolean.
    willQos := qosValue min: 2 max: 0
]
