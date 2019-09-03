"
This class interfaces to a SocketStream Object. In VSE this is a more complicated object as it was a subclass of the 1995 VSE SocketClass
"
Class {
	#name : #MQTTSocketClient,
	#superclass : #Object,
	#instVars : [
		'transport',
		'cleanSessionFlag',
		'willTopic',
		'willMessage',
		'willRetainFlag',
		'willQos',
		'userNameString',
		'passwordString',
		'keepAliveTime',
		'socket',
		'interface'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTSocketClient class >> openOnHostName: hostname keepAlive: aSeconds interface: anInterface [ 

	^self openOnHostName: hostname port: 1883 keepAlive: aSeconds interface: anInterface 
]

{ #category : #mqtt }
MQTTSocketClient class >> openOnHostName: hostname port: portNumber keepAlive: aSeconds interface: anInterface [ 

	"Create an instance on the provided host and port"
    | instance sock addr |

	 
	addr := NetNameResolver addressForName: hostname timeout: aSeconds.
	instance := self new.
	sock := Socket newTCP.
	sock connectTo: addr port: portNumber.
	sock waitForConnectionFor: aSeconds.
   instance keepAliveTime: aSeconds.
   instance interface: anInterface.
	instance acceptFrom: sock.
   ^instance
]

{ #category : #mqtt }
MQTTSocketClient >> acceptFrom: aSocket [
	"start the socket"

	self debugLog: 'MQTTSocketClient saw connectedOn: on socket'.
	transport isNil
		ifTrue: [ transport := MQTTTransportLayerClient new.
			transport keepAliveTime: self keepAliveTime.
			transport socketClient: self.
			transport start: aSocket.
			self initializeMQTTConnection: true]
		ifFalse: [ transport restart: aSocket.
			self initializeMQTTConnection: false].
	
]

{ #category : #mqtt }
MQTTSocketClient >> badWill [

		"raise error"

    self debugLog: 'badWill'.
    self halt: 'Bad Will topic, message etc'
]

{ #category : #mqtt }
MQTTSocketClient >> close [

	"close logic"

    self debugLog: 'MQTTSocketClient saw close on socket'.

    self transport ifNotNil: [self transport disconnect: true].
    self release.
]

{ #category : #mqtt }
MQTTSocketClient >> debugLog: aString [ 

		  "debug data"

    MQTTClientInterface debugLog: self printString tag: ' TC ' str2: aString
]

{ #category : #mqtt }
MQTTSocketClient >> disconnect [

	"disconnect on purpose"

    self transport ifNotNil: [self transport disconnect: false].
]

{ #category : #mqtt }
MQTTSocketClient >> initializeMQTTConnection: cleanSessionTrue [

	"assemble a CONNECT packet and send it [MQTT-3.1.0-1]"
    | connectPacket |

    connectPacket := MQTTPacketConnect new keepAliveTime: self keepAliveTime.

	"do I want to set the will data?"
    (willTopic isString & willMessage isString & willRetainFlag isBoolean & willQos isInteger)
        ifTrue:[
            connectPacket willTopic: willTopic message: willMessage retain: willRetainFlag qos: willQos].

	"If CleanSession is set to 0, the Server MUST resume communications with the Client based on state from the current Session (as identified by the Client identifier). If there is no Session associated with the Client identifier the Server MUST create a new Session. The Client and Server MUST store the Session after the Client and Server are disconnected [MQTT-3.1.2-4]. After the disconnection of a Session that had CleanSession set to 0, the Server MUST store further QoS 1 and QoS 2 messages that match any subscriptions that the client had at the time of disconnection as part of the Session state [MQTT-3.1.2-5]. It MAY also store QoS 0 messages that meet the same criteria.
 
If CleanSession is set to 1, the Client and Server MUST discard any previous Session and start a new one. This Session lasts as long as the Network Connection. State data associated with this Session MUST NOT be reused in any subsequent Session [MQTT-3.1.2-6].
"
    cleanSessionFlag := cleanSessionTrue.
    connectPacket cleanSession: cleanSessionFlag.

	"do I need a username&|password? Nils are handled by the packet"
    connectPacket user: userNameString password: passwordString.

	"set the clientID by which the server knows us - see 3.1.3


	It defaults to SqueakMQTT but should be set separately by each user to keep it unique"
    connectPacket clientID: self transport clientIDString.
    cleanSessionTrue 
		ifTrue: 
			[" [MQTT-3.1.0-1] "
			self transport outgoingPacketQueue: SharedQueue new. "clear outgoing packet queue"
			self transport packetInFlightQueue: SharedQueue new. "clear inflight queue"
			self transport sendPacket: connectPacket]
		ifFalse:[| pifq| 
				pifq := SharedQueue new.
				pifq nextPut: connectPacket.
				pifq nextPutAll: self transport packetInFlightQueue contents.
				self transport packetInFlightQueue: pifq].
]

{ #category : #mqtt }
MQTTSocketClient >> interface [

	"Answer my 'interface' instance variable."

    ^interface
]

{ #category : #mqtt }
MQTTSocketClient >> interface: aValue [ 

	"Set my 'interface' instance variable to aValue."

    interface := aValue.
    transport := interface socketClient ifNotNil: [transport := interface socketClient transport].
]

{ #category : #mqtt }
MQTTSocketClient >> keepAliveTime [

	"Answer my 'keepAliveTime' instance variable."

    ^keepAliveTime
]

{ #category : #mqtt }
MQTTSocketClient >> keepAliveTime: aValue [ 

	"Set my 'keepAliveTime' instance variable to aValue."

    keepAliveTime := aValue
]

{ #category : #mqtt }
MQTTSocketClient >> onTopic: topicString qos: qos do: aBlock [ 

	"a basic subscribe and do something message. We must check the topicString's acceptability and fail if there are issues"

    self transport onTopic: topicString qos: qos do: aBlock
]

{ #category : #mqtt }
MQTTSocketClient >> printOn: aStream [ 

	"print useful data"

    super printOn: aStream.
    aStream nextPutAll: ' socket: '.
]

{ #category : #mqtt }
MQTTSocketClient >> publishTopic: aTopic message: msgString qos: qos retain: retainFlag [ 

	"publish the msgString to the connected broker. If qos > 0 we'll need to schedule a pending job for the ack sequence(s)"

    self transport publishTopic: aTopic message: msgString qos: qos retain: retainFlag
]

{ #category : #mqtt }
MQTTSocketClient >> readWaitTime: aSeconds [ 

	  "set read time out"

    self transport readWaitTime: aSeconds
]

{ #category : #mqtt }
MQTTSocketClient >> release [

	"release logic"
	
    interface := nil.
    transport := nil.
]

{ #category : #mqtt }
MQTTSocketClient >> transport [

	"Answer my 'transport' instance variable."

    ^transport
]

{ #category : #mqtt }
MQTTSocketClient >> transport: aValue [ 

	"Set my 'transport' instance variable to aValue."

    transport := aValue
]

{ #category : #mqtt }
MQTTSocketClient >> unsubscribeFrom: aTopic [ 

	"unsubscribe from aTopic - remove the subscription from currentSubscription"

    self transport unsubscribeFrom: aTopic
]

{ #category : #mqtt }
MQTTSocketClient >> username: uName password: pwd [ 

	"set the MQTT user name and password to be used by the connection. Nils are ok for either or both"

    uName ifNotNil: [userNameString := UTF8Encoder encode: uName asString].
    pwd ifNotNil: [passwordString := UTF8Encoder encode: pwd asString]
]

{ #category : #mqtt }
MQTTSocketClient >> willTopic: topicString message: messageString retain: retainBoolean qos: qosValue [ 

	"setup a will message. We must have a topic, the actual message, a retain flag and requested QOS"

    ((topicString isString &  messageString isString &  (retainBoolean = true | retainBoolean = false)) & (qosValue isInteger & (qosValue between: 0 and: 2)))
        ifFalse:[^self badWill].
    willTopic := topicString.
    willMessage := messageString.
    willRetainFlag := retainBoolean.
    willQos := qosValue
]
