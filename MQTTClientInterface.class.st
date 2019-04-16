"
[(MQTTClientInterface openOnHostName: 'test.mosquitto.org' port: 1883 keepAlive: 300) start inspect] fork

This class is based on work by 
Tim Rowledge for the MQTT Client he wrote for the Pi

http://www.squeaksource.com/@Vok40xZouHIIkrzY/xMjFzu_2

Modified by John M McIntosh, Corporate Smalltalk Consulting Ltd for LabWare Inc.
Copyright 2017-2019 Tim Rowledge
Copyright  2018, 2019. Corporate Smalltalk Consulting Ltd.
Copyright  2018, 2019. LabWare Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ""Software""), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED ""AS IS"", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"
Class {
	#name : #MQTTClientInterface,
	#superclass : #Object,
	#instVars : [
		'socketClient',
		'hostName',
		'keepAliveTime'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTClientInterface class >> debugLog: aString [ 

	  "debug"

    self debugLog: aString tag: ' CI ' str2: ''
]

{ #category : #mqtt }
MQTTClientInterface class >> debugLog: aString tag: aTag str2: str2 [ 

		"debug"
    | stream |

    (aTag = ' CI ' or: [ true ])
        ifFalse:[^self].
    stream := WriteStream on: (String new: 128).
	 Time nowLocal print24: true showSeconds: true  on: stream.
    stream
        nextPutAll: aTag;
        nextPutAll: aString;
        space;
        nextPutAll: str2.
    Transcript show: stream contents;cr.
]

{ #category : #mqtt }
MQTTClientInterface class >> openOnHostName: hostname [ 

		"open a client on host called hostname"

    ^self openOnHostName: hostname keepAlive: 0
]

{ #category : #mqtt }
MQTTClientInterface class >> openOnHostName: hostname keepAlive: aSeconds [ 

		"open a client on host called hostname"
    | instance minSeconds |

    instance := self new.
    minSeconds := aSeconds > 0
        ifTrue:[aSeconds max: 60]
        ifFalse:[0].
    ^instance openOnHostName: hostname keepAlive: minSeconds.
]

{ #category : #mqtt }
MQTTClientInterface class >> openOnHostName: hostname port: portNumber keepAlive: aSeconds [ 

	"open a client on host called hostname and port"
    | instance minSeconds |

    instance := self new.
    minSeconds := aSeconds > 0
        ifTrue:[aSeconds max: 60]
        ifFalse:[0].
    ^instance openOnHostName: hostname port: portNumber keepAlive: minSeconds
]

{ #category : #mqtt }
MQTTClientInterface >> debugLog: aString [ 

	  "debug"

    self class debugLog: aString
]

{ #category : #mqtt }
MQTTClientInterface >> disconnect [

	"disconnect"

    self socketClient disconnect. "[MQTT-3.14.4-1]"
]

{ #category : #mqtt }
MQTTClientInterface >> hostName [

	"get my 'hostName' instance variable "

    ^hostName
]

{ #category : #mqtt }
MQTTClientInterface >> hostName: aValue [ 

	"Set my 'hostName' instance variable to aValue."

    hostName := aValue
]

{ #category : #mqtt }
MQTTClientInterface >> isValid [

    ^(socketClient notNil and: [socketClient transport notNil]) and: [socketClient transport abort not]
]

{ #category : #mqtt }
MQTTClientInterface >> keepAliveTime [

	"Answer my 'keepAliveTime' instance variable."

    ^keepAliveTime ifNil: [keepAliveTime := 0]
]

{ #category : #mqtt }
MQTTClientInterface >> keepAliveTime: aValue [ 

	"Set my 'keepAliveTime' instance variable to aValue."

    keepAliveTime := aValue
]

{ #category : #mqtt }
MQTTClientInterface >> openOnHostName: aHostName [ 

	"open on the hostName"

    self hostName: aHostName.
    self socketClient: (
        self socketClientClass openOnHostName: aHostName keepAlive: keepAliveTime interface: self).
    ^self
]

{ #category : #mqtt }
MQTTClientInterface >> openOnHostName: aHostName keepAlive: aSeconds [ 

	"open on the hostName"

    self hostName: aHostName.
    self keepAliveTime: aSeconds.
    self socketClient: (
        self socketClientClass openOnHostName: aHostName keepAlive: aSeconds interface: self).
    ^self
]

{ #category : #mqtt }
MQTTClientInterface >> openOnHostName: aHostName port: portNumber keepAlive: aSeconds [ 

	"open on the hostName and port"

    self hostName: aHostName.
    self keepAliveTime: aSeconds.
    self socketClient: (
        self socketClientClass openOnHostName: aHostName port: portNumber keepAlive: aSeconds interface: self).
    ^self
]

{ #category : #mqtt }
MQTTClientInterface >> printOn: aStream [ 

	"print useful data"
    | state |

    super printOn: aStream.
    aStream nextPutAll: ' '.
    hostName asString printOn: aStream.
    state := (socketClient notNil and: [socketClient transport notNil])
        ifTrue:[
            socketClient transport abort
                ifTrue:['Aborting']
                ifFalse:['Connected']]
        ifFalse:['Disconnected?'].
    aStream nextPutAll: ' '.
    state asString printOn: aStream.
]

{ #category : #mqtt }
MQTTClientInterface >> publish: aByteArray onTopic: topicString qos: qos [ 

	"publish the aByteArray to the connected broker."

    self publish: aByteArray onTopic: topicString qos: qos retain: false
]

{ #category : #mqtt }
MQTTClientInterface >> publish: aByteArray onTopic: topicString qos: qos retain: retainFlag [ 

	"publish the aByteArray to the connected broker. If qos > 0 we'll need to schedule a pending job for the ack sequence(s)"

    self socketClient publishTopic: topicString message: aByteArray qos: qos retain: retainFlag
]

{ #category : #mqtt }
MQTTClientInterface >> readWaitTime: aSeconds [ 

	"set read time out"

    self socketClient readWaitTime: aSeconds
]

{ #category : #mqtt }
MQTTClientInterface >> restart [

	"restart logic"

    (Delay forSeconds: 15) wait.
    self debugLog: 'MQTTClientInterface restarting possible existing session'.
    ^(self openOnHostName: self hostName) start.
]

{ #category : #mqtt }
MQTTClientInterface >> socketClient [

	"Answer my 'socketClient' instance variable."

    ^socketClient
]

{ #category : #mqtt }
MQTTClientInterface >> socketClient: aValue [ 

	"Set my 'socketClient' instance variable to aValue."

    socketClient := aValue
]

{ #category : #mqtt }
MQTTClientInterface >> socketClientClass [

	"SocketClient to use"

    ^MQTTSocketClient
]

{ #category : #mqtt }
MQTTClientInterface >> start [

		"Start actual socket connection"
]

{ #category : #mqtt }
MQTTClientInterface >> stop [

		"disconnect"

    self disconnect
]

{ #category : #mqtt }
MQTTClientInterface >> subscribeTo: topicString qos: qos do: aBlock [ 

	"a basic subscribe and do something message. We must check the topicString's acceptability and fail if there are issues"

    self socketClient onTopic: topicString qos: qos do: aBlock
]

{ #category : #mqtt }
MQTTClientInterface >> testBlock [

	"test block"

    ^[:t :m :q |
        q > 0 ifTrue: 
		[Transcript
            show: 'topic: ' , t;
            space;
            show: 'qos: ' , q printString;
            space;
            show: 'payload: ' , m size printString;
            cr]]
]

{ #category : #mqtt }
MQTTClientInterface >> testSetupForTopic [

	"test procedure"

    self subscribeTo: '#' qos: 2 do: self testBlock.
]

{ #category : #mqtt }
MQTTClientInterface >> unsubscribeFrom: aTopic [ 

	"unsubscribe from aTopic - remove the subscription from currentSubscription"

    self socketClient unsubscribeFrom: aTopic
]

{ #category : #mqtt }
MQTTClientInterface >> username: uName password: pwd [ 

		  "set username and password"

    self socketClient username: uName password: pwd
]

{ #category : #mqtt }
MQTTClientInterface >> willTopic: topicString message: messageString retain: retainBoolean qos: qosValue [ 

		  "Set will Information"

    self socketClient willTopic: topicString message: messageString retain: retainBoolean qos: qosValue
]
