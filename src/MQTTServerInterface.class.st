"
(MQTTServerInterface openOnPort: 1883) start inspect.


This class is based on work  by John M McIntosh, Corporate Smalltalk Consulting Ltd for LabWare Inc.

Copyright  2018, 2019. Corporate Smalltalk Consulting Ltd.
Copyright  2018, 2019. LabWare Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ""Software""), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED ""AS IS"", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"
Class {
	#name : #MQTTServerInterface,
	#superclass : #Object,
	#instVars : [
		'socketDaemon',
		'socketServers',
		'clientIDs',
		'retainedPackets',
		'retainedPacketMutex',
		'abort',
		'timeOutProcess',
		'socketServerMutex',
		'clientIDMutex',
		'statisticsMutex',
		'statistics'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTServerInterface class >> openOnPort: p [ 

		"open listener on port"
    | instance |

    instance := self new.
    instance openOnPort: p.
    ^instance
]

{ #category : #mqtt }
MQTTServerInterface >> abort [

	"Answer my 'abort' instance variable."

    ^abort
]

{ #category : #mqtt }
MQTTServerInterface >> addNewClientIDUsingTransport: newTransport 
withConnectPacket: aConnectPacket 
passingConnAck: aConnectAckPacket [ 

	"add the client"
    | client possibleClient aClientID |

    "[MQTT-3.1.3-2] [MQTT-4.1.0-1] [MQTT-3.1.4-3]"
    self statPerform: #addConnectPacket: with: aConnectPacket.
    aClientID := aConnectPacket clientIDString.
    possibleClient := clientIDMutex critical: [
        self clientIDs at: aClientID ifAbsent: [
            client := MQTTClientIDHolder with: aClientID transport: newTransport connectPacket: aConnectPacket.
            self clientIDs at: aClientID put: client.
            self statPerform: #sentPackets.
            newTransport sendPacket: aConnectAckPacket.
            self forwardRetainMessagesTo: client usingPossibleSubscription: nil. "[MQTT-3.3.1-6]"
            ^self]].

	"client exists let see if the same socket?"
    ((possibleClient transport notNil and: [possibleClient transport abort not]) and:
        [self halt.
			false]
			"possibleClient transport socketServer socket descriptor = newTransport socketServer socket descriptor]"
				)
            ifTrue:[
                newTransport debugLog: 'possible violation of [MQTT-3.1.0-2]'.
                self statPerform: #killSocket.
                newTransport socketServer socket close. "[MQTT-3.1.0-2]. [MQTT-3.1.4-2] "
                ^self].

		" [MQTT-3.1.2-4]."
        [possibleClient transport sockStrm close] on: Error do: [:ex | ].
        possibleClient cleanSession: aConnectPacket cleanSessionFlag withNewTransport: newTransport passingConnAck: aConnectAckPacket.
        possibleClient connectPacket: aConnectPacket.
        possibleClient transport: newTransport.
]

{ #category : #mqtt }
MQTTServerInterface >> addNewSocketServer: aSocketServer [ 

	"add new server"

    self statPerform: #addServer.
    aSocketServer transport serverInterface: self.
    aSocketServer transport socketServer: aSocketServer.
    socketServerMutex critical: [self socketServers add: aSocketServer]
]

{ #category : #mqtt }
MQTTServerInterface >> addNewSubscription: aSubscribePacket forClientID: aClientID [ 

	"subscribe logic"
    | possibleClient |

    self statPerform: #addSubscription: with: aSubscribePacket.
    possibleClient := clientIDMutex critical: [self clientIDs at: aClientID ifAbsent: [^false]].
    possibleClient addSubscription: aSubscribePacket.
    ^true
]

{ #category : #mqtt }
MQTTServerInterface >> checkSocketServersForTimeOut [
	"check for zombies"

	| transport targets timeAgo |

	socketServerMutex
		critical: [ targets := self socketServers
				select: [ :e | 
					transport := e transport.
					transport
						ifNil: [ false ]
						ifNotNil: [ timeAgo := Time primUTCSecondsClock - transport lastPingTime.
							"[MQTT-3.1.2-24]"
							transport keepAliveTime > 0 and: [ timeAgo > (1.5 * transport keepAliveTime) ] ] ] ].
	targets
		do: [ :e | 
			[ self statPerform: #timeOut.
			e debugLog: 'Kill Client based on Ping TimeOut'.
			e disconnect ] fork ]
]

{ #category : #mqtt }
MQTTServerInterface >> clientIDs [

	"Answer my 'clientIDs' instance variable."

    ^clientIDs
]

{ #category : #mqtt }
MQTTServerInterface >> clientIDs: aValue [ 

	"Set my 'clientIDs' instance variable to aValue."

    clientIDs := aValue
]

{ #category : #mqtt }
MQTTServerInterface >> disableWillLogic: aClientIDString [ 

	"disable the will logic"
    | possibleClient |

    "[MQTT-3.1.2-8]"
    possibleClient := clientIDMutex critical: [self clientIDs at: aClientIDString ifAbsent: [^false]].
    possibleClient connectPacket willFlag: false.
    ^true
]

{ #category : #mqtt }
MQTTServerInterface >> forwardRetainMessagesTo: aClientID usingPossibleSubscription: aSubscription [ 

	  "forward retained messages"

    (retainedPacketMutex critical: [self retainedPackets values]) do: [:v |
        self handlePublishedPacket: v usingTransport: nil forClients: (Array with: aClientID) usingSubscriptions: aSubscription tagWithRetainFlag: true]. "[MQTT-3.3.1-8]"
]

{ #category : #mqtt }
MQTTServerInterface >> handlePublishedPacket: aPublishPacket usingTransport: aTransport [ 

	"add new server"
    | existingPacket |

    "Handle [MQTT-3.3.2-2]."

		"[MQTT-3.3.5-2]. has no meaning for us"
    aPublishPacket retain = true
        ifTrue:[ " [MQTT-3.3.1-12]. [MQTT-3.1.2.7] "
            existingPacket := retainedPacketMutex critical: [
                retainedPackets at: aPublishPacket topic ifAbsentPut: [aPublishPacket]]. "[MQTT-3.3.1-5]. [MQTT-3.3.1-7]."
            (((aPublishPacket message isNil) or: [aPublishPacket message size = 0]))
                ifTrue:[retainedPackets removeKey: aPublishPacket topic]. " [MQTT-3.3.1-10] [MQTT-3.3.1-11]."
            ].
    self handlePublishedPacket: aPublishPacket usingTransport: aTransport forClients: (clientIDMutex critical: [self clientIDs values]) usingSubscriptions: nil tagWithRetainFlag: false. " [MQTT-3.3.1-9]."
]

{ #category : #mqtt }
MQTTServerInterface >> handlePublishedPacket: aPublishPacket 
usingTransport: aTransport 
forClients: aClientIDs 
usingSubscriptions: subcriptions 
tagWithRetainFlag: aRetainFlag [ 

	"add new server"
    | subscribers |

    "[MQTT-4.5.0-1] [MQTT-4.6.0-6]"
    aClientIDs do: [:client |
        subscribers := subcriptions.
        subscribers ifNil: [subscribers := client subscriptionsMutex critical: [client subscriptions copy]]. "make copy to solve race on add/remove subscriptions"
        subscribers associationsDo: [:assoc |
            aPublishPacket matchesSubscription: assoc value ifTrue: [:t :m :q | "[MQTT-3.3.2-3]."
                self sendPacket: aPublishPacket copy to: client retainFlag: aRetainFlag qos: (assoc value qos min: aPublishPacket qos)]]].
]

{ #category : #mqtt }
MQTTServerInterface >> initialize [

	"setup"

    clientIDs := Dictionary new.
    socketDaemon := nil.
    socketServers := Set new.
    retainedPackets := Dictionary new.
    abort := false.
    socketServerMutex := Semaphore forMutualExclusion.
    clientIDMutex := Semaphore forMutualExclusion.
    retainedPacketMutex := Semaphore forMutualExclusion.
    statistics := MQTTStatistics new.
    statisticsMutex := Semaphore forMutualExclusion.
    self initializeTimeOutProcess.
]

{ #category : #mqtt }
MQTTServerInterface >> initializeTimeOutProcess [

	"Check for time outs on clients"

    timeOutProcess := [| loopDelay|loopDelay := Delay forSeconds: 10.
        [
        loopDelay wait.
        self abort
            ifFalse:[self checkSocketServersForTimeOut].
        self abort] whileFalse] forkNamed: 'MQTT server timeout loop'
]

{ #category : #mqtt }
MQTTServerInterface >> openOnPort: p [ 

		  "open on port"

    socketDaemon := MQTTSocketDaemon openOnPort: p serverClass: MQTTSocketServer interface: self.
]

{ #category : #mqtt }
MQTTServerInterface >> removeSocketServer: aSocketServer [ 

	"remove server"
    | possibleClient cp |

    "[MQTT-3.14.4-1] [MQTT-4.1.0-2]"
    self statPerform: #removeServer.
    socketServerMutex critical: [self socketServers remove: aSocketServer].
    possibleClient := clientIDMutex critical: [
        self clientIDs at: aSocketServer transport clientIDString ifAbsent: [^false]].
    possibleClient release.
    cp := possibleClient connectPacket.
    cp willFlag "[MQTT-3.1.2-12]"
        ifTrue:[ "[MQTT-3.1.2-8] [MQTT-3.1.2-10]"
            | pubPacket|pubPacket := MQTTPacketPublish new
                 topic: cp willTopic message: cp willMessage asByteArray;
                 messageID: (
                    (cp willQos > 0)
                        ifTrue:[9999]
                        ifFalse:[0]);
                 qos: cp willQos. "[MQTT-3.1.2-16] [MQTT-3.1.2-17]"
            self handlePublishedPacket: pubPacket usingTransport: nil.
            cp willFlag: false].
    ^true
]

{ #category : #mqtt }
MQTTServerInterface >> removeSubscriptions: aUnsubscribePacket forClientID: aClientID [ 

	"unsubscribe logic"
    | possibleClient |

    self statPerform: #removeSubscription: with: aUnsubscribePacket.
    possibleClient := clientIDMutex critical: [self clientIDs at: aClientID ifAbsent: [^false]].
    possibleClient removeSubscription: aUnsubscribePacket.
    ^true
]

{ #category : #mqtt }
MQTTServerInterface >> retainedPackets [

	"Answer my 'retainedPackets' instance variable."

    ^retainedPackets
]

{ #category : #mqtt }
MQTTServerInterface >> sendPacket: packet to: client retainFlag: aRetainFlag qos: aQos [ 

	"send the packet"

    packet duplicateFlag: false. " [MQTT-3.3.1-3]. [MQTT-3.3.1-2]"
    packet retainFlag: aRetainFlag.
    packet qos: aQos. " [MQTT-3.8.4-5]. [MQTT-3.3.5-1] [MQTT-4.3.1-1]"
    client transport isNil
        ifTrue:[
            self statPerform: #queuedPackets.
            client outgoingPacketQueue nextPut: packet] "[MQTT-3.1.2-5]"
        ifFalse:[
            self statPerform: #sentPackets.
            client transport handlePublishResponse: packet]
]

{ #category : #mqtt }
MQTTServerInterface >> sessionPresentViaConnectPacket: aConnectPacket [ 

		  "check for session existing"

    clientIDMutex critical: [| pastSession|pastSession := self clientIDs includesKey: aConnectPacket clientIDString.
    ^pastSession and: [aConnectPacket cleanSessionFlag not]]. "[MQTT-3.2.2-1]"

 "[MQTT-3.2.2-2]"
]

{ #category : #mqtt }
MQTTServerInterface >> socketDaemon [

	"Answer my 'socketDaemon' instance variable."

    ^socketDaemon
]

{ #category : #mqtt }
MQTTServerInterface >> socketDaemon: aValue [ 

	"Set my 'socketDaemon' instance variable to aValue."

    socketDaemon := aValue
]

{ #category : #mqtt }
MQTTServerInterface >> socketServers [

	"Answer my 'socketServers' instance variable."

    ^socketServers
]

{ #category : #mqtt }
MQTTServerInterface >> start [

		"start the listener"

    socketDaemon isNil
        ifFalse:[socketDaemon start]
]

{ #category : #mqtt }
MQTTServerInterface >> statPerform: selector [ 

	  "consolidate error handler"

    statisticsMutex critical: [[statistics perform: selector] on: Error do: [:ex | ]].
]

{ #category : #mqtt }
MQTTServerInterface >> statPerform: selector with: arg [ 

		  "consolidate error handler"

    statisticsMutex critical: [[statistics perform: selector with: arg] on: Error do: [:ex | ]].
]

{ #category : #mqtt }
MQTTServerInterface >> stop [

	"stop the listener"

    self stopSocketDaemon.
    socketServerMutex critical: [
        self socketServers do: [:s | s disconnect].
        abort := true.
        timeOutProcess terminate.
        timeOutProcess := nil].
    clientIDs := Dictionary new.
    socketServers := Set new.
    retainedPackets := Dictionary new.
]

{ #category : #mqtt }
MQTTServerInterface >> stopAcceptingConnections [

	"Stop listening for connections"

    self stopSocketDaemon
]

{ #category : #mqtt }
MQTTServerInterface >> stopSocketDaemon [

	"stop accepting connections but continue to process any existing connections."

    socketDaemon isNil
        ifTrue:[^self].
    socketDaemon stop.
    socketDaemon := nil
]
