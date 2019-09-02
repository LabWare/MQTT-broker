"
This is the abstract class for a client or server/data broker session. It manages the ping logic, retry logic, reader, writer, and restart logic. The concrete class implement client or data broker specific logic. 
"
Class {
	#name : #MQTTTransportLayer,
	#superclass : #Object,
	#instVars : [
		'sockStrm',
		'abort',
		'incomingPacketProcess',
		'packetInFlightQueue',
		'outgoingPacketQueue',
		'outgoingPacketProcess',
		'retryTime',
		'pendingJobsMutex',
		'abortMutex',
		'retryProcess',
		'lastMID',
		'pendingJobs',
		'currentSubscriptions',
		'readWaitTime',
		'statisticsMutex',
		'statistics'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTTransportLayer >> abort [

	"Answer my 'abort' instance variable."

    ^abort
]

{ #category : #mqtt }
MQTTTransportLayer >> addPending: mqttJobToComplete [ 

	"Add a record of a pending job that needs completion"

    "self debugLog: 'add pending: ' , mqttJobToComplete asString."
    pendingJobsMutex critical: [
        pendingJobs ifNil: [pendingJobs := OrderedCollection new].
        pendingJobs add: mqttJobToComplete]
]

{ #category : #mqtt }
MQTTTransportLayer >> badPacketID [

		"fatal error"

    self debugLog: 'badPacketID'.
    self disconnect: false. "[MQTT-2.3.1-2]"
]

{ #category : #mqtt }
MQTTTransportLayer >> badTopicError [

"raise an exception at some point; for now just halt"

    self debugLog: 'badTopicError'.
    MQTTBadTopicException signal: 'badTopicError'.
]

{ #category : #mqtt }
MQTTTransportLayer >> badWill [

    self debugLog: 'badWill'.
    self halt: 'Bad Will topic, message etc'
]

{ #category : #mqtt }
MQTTTransportLayer >> currentSubscriptions [

	"Answer my 'currentSubscriptions' instance variable."

    ^currentSubscriptions
]

{ #category : #mqtt }
MQTTTransportLayer >> currentSubscriptions: aValue [ 

	"Set my 'currentSubscriptions' instance variable to aValue."

    currentSubscriptions := aValue
]

{ #category : #mqtt }
MQTTTransportLayer >> debugLog: aString [ 

	  "debug data"
    | datum |

    datum := sockStrm ifNotNil: [sockStrm socket printString] ifNil: ['???'].
    MQTTClientInterface debugLog: datum tag: self transportType str2: aString
]

{ #category : #mqtt }
MQTTTransportLayer >> disconnect: restart [
	"close the connection"
	
	[ (Delay forSeconds: 2) wait.
	outgoingPacketProcess notNil
		ifTrue: [ outgoingPacketProcess terminate ].
	self debugLog: 'kill outgoingPacketProcess' ]
		forkAt: Processor activePriority - 1
		named: 'MQTTKillOutGoing'.
	outgoingPacketProcess := nil.
	[ (Delay forSeconds: 2) wait.
	incomingPacketProcess notNil
		ifTrue: [ incomingPacketProcess terminate ].
	self debugLog: 'kill incomingPacketProcess' ]
		forkAt: Processor activePriority - 1
		named: 'MQTTKillIncoming'.
	incomingPacketProcess := nil.
	retryProcess
		ifNotNil: [ self debugLog: 'kill retryProcess'.
			retryProcess terminate.
			retryProcess := nil ]
]

{ #category : #mqtt }
MQTTTransportLayer >> disconnectPostCleanup [

		"zap socketStream"
    | s |

    s := sockStrm socket.
    [s ifNotNil: [[s close] on: Error do: [:ex | self debugLog: ex description]]] fork.
]

{ #category : #mqtt }
MQTTTransportLayer >> exceptionHandler: e [ 

	"handle exception"
    | connectAckPacket et |


	e class = MQTTEmptyStreamErrorException
        ifTrue:[self debugLog: 'MQTTEmptyStreamErrorException'.	
				^e retry].
    e class = ConnectionTimedOut
        ifTrue:[self debugLog: 'ConnectionTimedOut'.].
    et := e printString.
    et ifNotNil: [self debugLog: et.
					self statPerform: #errorTypes: with: et].
    e class = MQTTCONNECTException
        ifTrue:[
            self statPerform: #badConnections.
            connectAckPacket := MQTTPacketConnAck new.
            connectAckPacket sessionPresent: false.
            connectAckPacket byte2: e connectReturnCode.
            self sendPacket: connectAckPacket. "[MQTT-3.2.2-1] [MQTT-3.1.4-5]"
            (Delay forSeconds: 5) wait.].
    self disconnect: self restartTheSocket.
    ^nil
]

{ #category : #mqtt }
MQTTTransportLayer >> findAndRunJobsOverdueForAcknowledgement [

	"Find and process the pending job(s) that needs to resend a packet"
    | tick |

    pendingJobs ifNil: [^nil].
    tick := Time totalSeconds - retryTime.

	"looks odd but works as a way to handle possible changes in retryTime -

	we actually check if the last send time is more than retryTime seconds ago"
    pendingJobsMutex critical: [pendingJobs do: [:j | j resendFor: self ifNeededAtTime: tick]]
]

{ #category : #mqtt }
MQTTTransportLayer >> findPendingJob: testBlock [ 

	"Find the matching record of a pending job that needs completion. Your testBlock should be written to find only a single result but we use #detect: here and only give you back the first one"

    pendingJobs ifNil: [^nil].
    pendingJobsMutex critical: [^pendingJobs detect: [:e | testBlock value: e] ifNone: [nil]]
]

{ #category : #mqtt }
MQTTTransportLayer >> handleIncomingPacket: anMQTTPacket [ 

	"most of the packets that come to me are acknowledgements of one sort or another; the exception is the PUBLISH, which we have to handle since it is how we get that pesky data.

	Now most people might be expecting some sort of case statement here, switching based on the type of the packet. But we're Smalltalkers and that is more than a little gauche when we can just do it right and delegate to the packet"

    anMQTTPacket evaluateFor: self
]

{ #category : #mqtt }
MQTTTransportLayer >> handlePubAckPacket: aPubAckPacket [ 

	"The broker has confirmed a qos=1 publish process (3.4)"
    | job |

    "Find my pending job by matching the msgID tag"
    job := self findPendingJob: [:j | j isPubAckID: aPubAckPacket packetID].
    job ifNil: [^self missingPendingJob: #pubAck].

	"What do we do?"
    job completeFor: self.

	"c) consider the publish completed. Not sure what that means in practice"
]

{ #category : #mqtt }
MQTTTransportLayer >> handlePubCompPacket: aPubCompPacket [ 

	"The broker has confirmed a qos=2 publish process is completed (3.7)"
    | job |

    "Find my pending job by matching the msgID tag"
    job := self findPendingJob: [:j | j isPubCompID: aPubCompPacket packetID].
    job ifNil: [^self missingPendingJob: #pubComp].

	"What do we do?"
    job completeFor: self.

	"c) consider the publish completed. Not sure what that means in practice"
]

{ #category : #mqtt }
MQTTTransportLayer >> handlePubRecPacket: aPubRecPacket [ 

	"The broker has confirmed a qos=2 publish process is in progress (3.5)"
    | job pubRelPacket pj |

    "Find my pending job by matching the msgID tag"
    job := self findPendingJob: [:j | j isPubRecID: aPubRecPacket packetID].
    job ifNil: [self missingPendingJob: #pubRec].

	"add a new pending job for the response to the PUBREL"

	"We could have a pubrec that is stale"
    pubRelPacket := aPubRecPacket acknowledgement.
    self addPending: (pj := pubRelPacket pendingJob).

	"We need to respond by sending out a PUBREL packet with the *same* packetID, and add a pending job to handle the closing PUBCOMP"
    self sendPacket: (MQTTPacketAndPendingJobPair packet: pubRelPacket pendingJob: pj).

	"release the pending job from the list but do *not* release the packetID yet"
    job ifNotNil: [job completeFor: self].
]

{ #category : #mqtt }
MQTTTransportLayer >> handlePubRelPacket: aPubRelPacket [ 

	"The broker has confirmed a qos=2 publish process is completing, so accept the end of this relationship gracefully (3.6)"
    | job |

    "Find my pending job by matching the msgID tag"
    job := self findPendingJob: [:j | j isPubRelID: aPubRelPacket packetID].

	"I thought that we would only get a PUBREL once per job, but it
	turns out that you can get repeats and so we cannot allow a complaint
	about a missing pending job.
	We also have to only complete the job if we find one - see later"
    job ifNil: [self missingPendingJob: #pubRel].

	"We need to respond by sending out a PUBCOMP packet with the *same* packetID"
    self sendPacket: aPubRelPacket acknowledgement.

	"release the pending job from the list and release the packetID"
    job ifNotNil: [
        job completeFor: self.
        self doSubscriptionActionsFor: job originalPacket originalPacket]
]

{ #category : #mqtt }
MQTTTransportLayer >> handlePublishPacket: aPublishPacket qos: packetQos [ 

  "The broker has sent me a PUBLISH packet (3.3); extract the data and..."
    | pubRecOrAckPacket pj |

    "[MQTT-4.3.3-2] [MQTT-4.6.0-2] [MQTT-4.5.0-2]"

    "Find my pending job by matching the msgID tag"

  "What do we do?"

  "qos = 0 ifTrue: [do nothing]."
    packetQos >= 1
        ifTrue:[ "send back an appropriate PUBACK or PUBREC packet"

 "[MQTT-4.3.2-2]"
            pubRecOrAckPacket := aPublishPacket acknowledgement.
            packetQos = 1
                ifTrue:[self sendPacket: pubRecOrAckPacket]].
    packetQos = 2
        ifTrue:[ "more complex. 

    see if there is already a pending job to deal with a PUBREL

      if so, we're done, return

			if not, add a pending PUBREL job with the sent PUBREC and pass on the data"
            (self findPendingJob: [:j | j isPubRelID: aPublishPacket packetID]) ifNotNil: [^self].
            self addPending: (pj := MQTTPendingPubRelJob for: pubRecOrAckPacket). "[MQTT-4.6.0-4] change from MQTT-tpr.23"
            self sendPacket: (MQTTPacketAndPendingJobPair packet: pubRecOrAckPacket pendingJob: pj).
            ^self].

	"and here we do whatever to let the user have the data"
    self doSubscriptionActionsFor: aPublishPacket
]

{ #category : #mqtt }
MQTTTransportLayer >> handleSubAckPacket: aSubAckPacket [ 

	"The broker has confirmed a SUBSCRIBE from me (3.9)"
    | job |

    "Find my pending job by matching the msgID tag"
    job := self findPendingJob: [:j | j isSubAckID: aSubAckPacket packetID].
    job ifNil: [^self missingPendingJob: #subAck].
    job completeFor: self
]

{ #category : #mqtt }
MQTTTransportLayer >> handleUnsubAckPacket: anUnsubAckPacket [ 

	"The broker has confirmed an UNSUB process (3.10)"
    | job |

    "Find my pending job by matching the msgID tag"
    job := self findPendingJob: [:j | j isUnsubAckID: anUnsubAckPacket packetID].
    job ifNil: [^self missingPendingJob: #unSubAck].
    job completeFor: self
]

{ #category : #mqtt }
MQTTTransportLayer >> initializeKeepAlive [

		"keep alive action"

]

{ #category : #mqtt }
MQTTTransportLayer >> initializeMQTTConnection: anObject [

	"assemble a CONNECT packet and send it"

]

{ #category : #mqtt }
MQTTTransportLayer >> initializePacketReading [

	"set up the shared queue and process to write packets. The connection must be open"
    | innerBlock |

    innerBlock := self packetReader.
    incomingPacketProcess := [
        [| packet|packet := [innerBlock value] on: Error do: [:e | self exceptionHandler: e]. "[MQTT-4.8.0-2]"
        packet ifNotNil: [
            self statPerform: #packetIn: with: packet.
            (packet packetType = 3 and: [packet qos > 0])
					ifTrue: [self debugLog: 'Rx ' , packet asString].
            [self handleIncomingPacket: packet] on: Error do: [:e | self exceptionHandler: e]. "[MQTT-4.8.0-2]"
            ].
        Processor yield.
        self abort] whileFalse] forkNamed: 'MQTT packet reading'.
]

{ #category : #mqtt }
MQTTTransportLayer >> initializePacketWriting [

	"set up the shared queue and process to write packets. The connection must be open"
    | innerBlock |

    "[MQTT-4.6.0-5]"
    innerBlock := self packetWriter.
    outgoingPacketProcess := [
        [| packet|packet := self packetInFlightQueue nextOrNil.
        packet ifNil: [packet := self outgoingPacketQueue next].
        self packetInFlightQueue nextPut: packet. "Idea here is to save packet in in flight queue until we have processed it"
        self outgoingPacketQueue size > 10
            ifTrue:[self debugLog: 'write packet backlog at: ' , self outgoingPacketQueue size printString].
        [innerBlock value: packet] on: Error do: [:e | self exceptionHandler: e].
        self abort
            ifFalse:[self packetInFlightQueue nextOrNil].
        Processor yield.
        self abort] whileFalse] forkNamed: 'MQTT packet writing'
]

{ #category : #mqtt }
MQTTTransportLayer >> initializeRetryProcess [

	"some packets may need resending if they don't get acknowledged"

    retryProcess := [| loopDelay|loopDelay := Delay forSeconds: 2.
        [
        self abort
            ifFalse:[self findAndRunJobsOverdueForAcknowledgement].
        loopDelay wait.
        self abort] whileFalse] forkNamed: 'MQTT retry loop'
]

{ #category : #mqtt }
MQTTTransportLayer >> initializeSocketStream: socket [ 

	"make the basic socket connection to the broker"

    sockStrm := ZdcSocketStream on: socket.
    sockStrm timeout: self readWaitTime.
]

{ #category : #mqtt }
MQTTTransportLayer >> lastMID [

	"Answer my 'lastMID' instance variable."

    ^lastMID
]

{ #category : #mqtt }
MQTTTransportLayer >> lastMID: aValue [ 

	"Set my 'lastMID' instance variable to aValue."

    lastMID := aValue
]

{ #category : #mqtt }
MQTTTransportLayer >> missingPendingJob: type [ 

	"I couldn't find a matching pending job. oops."

    self debugLog: '************ No matching pending job for type: ' , type asString.
    self statPerform: #missingType: with: type
]

{ #category : #mqtt }
MQTTTransportLayer >> newPacketID [

    "provide a suitable 16 bit numeric non-zero packet id.

    This is supposed to be a unique number, presumably across the field of curently pending jobs.

    This ought to find a sutable value quickly in most cases, since we don't expect to have many pending jobs. If we get back to the

	value that was last used then we must have gone all the way round and must fail bcause we're out of IDs"
    | prevMID pj |

    lastMID ifNil: [lastMID := 1].
    prevMID := lastMID.
        [
        lastMID := lastMID + 1 \\ 16rFFFF.
        lastMID = 0
            ifTrue:[lastMID := 1]. "Fix for MQTT-2.3.1-1"
        pendingJobsMutex critical: [
            pj := pendingJobs.
            pj ifNil: [^lastMID] ifNotNil: [pj detect: [:jb | jb packetID = lastMID] ifNone: [^lastMID]]]. "[MQTT-2.3.1-2]"
        prevMID = lastMID] whileFalse.
    ^self badPacketID "[MQTT-2.3.1-2]"
]

{ #category : #mqtt }
MQTTTransportLayer >> onTopic: topicString qos: qos do: aBlock [ 

	"a basic subscribe and do something message. We must check the topicString's acceptability and fail if there are issues"
    | subscription |

    subscription := MQTTSubscription for: topicString qos: qos do: aBlock.
    subscription ifNil: [^self badTopicError].
    currentSubscriptions add: subscription.
    self subscribe: topicString qos: qos
]

{ #category : #mqtt }
MQTTTransportLayer >> outgoingPacketQueue [

	"Answer my 'outgoingPacketQueue' instance variable."

    ^outgoingPacketQueue
]

{ #category : #mqtt }
MQTTTransportLayer >> outgoingPacketQueue: aQueue [

    outgoingPacketQueue := aQueue
]

{ #category : #mqtt }
MQTTTransportLayer >> packetInFlightQueue [

	"Answer my 'packetInFlightQueue' instance variable."

    ^packetInFlightQueue
]

{ #category : #mqtt }
MQTTTransportLayer >> packetInFlightQueue: aValue [ 

	"Set my 'packetInFlightQueue' instance variable to aValue."

    packetInFlightQueue := aValue
]

{ #category : #mqtt }
MQTTTransportLayer >> packetReader [

	"Testing Read 10 bytes"

    ^[MQTTPacket readFrom: sockStrm]
]

{ #category : #mqtt }
MQTTTransportLayer >> packetWriter [

	"Testing Write Data"

    ^[:packet |
        self debugLog: 'Wx ' , packet asString.
        packet encodeOn: sockStrm.
        self statPerform: #packetOut: with: packet.]
]

{ #category : #mqtt }
MQTTTransportLayer >> pendingJobs [

	"Answer my 'pendingJobs' instance variable."

    ^pendingJobs
]

{ #category : #mqtt }
MQTTTransportLayer >> pendingJobs: aValue [ 

	"Set my 'pendingJobs' instance variable to aValue."

    pendingJobs := aValue
]

{ #category : #mqtt }
MQTTTransportLayer >> preambleWorkAbortEarlyIfTrue: restart [
	abortMutex
		critical: [ abort
				ifTrue: [ ^ true ].	"[MQTT-3.14.4-1] [MQTT-3.14.4-2]"
			self debugLog: 'disconnecting with restart: ' , restart printString.
			self statPerform: #disconnect.
			self sendPossibleDisconnectPackage.
			abort := true.
			self disconnectPostCleanup ].
		
	^false
]

{ #category : #mqtt }
MQTTTransportLayer >> printOn: aStream [ 

	"print useful data"

    super printOn: aStream.
    aStream nextPutAll: ' abort: '.
    abort asString printOn: aStream.
    aStream nextPutAll: ' socket: '.
    sockStrm asString printOn: aStream.
    aStream nextPutAll: ' pifq: '.
    aStream cr.
    packetInFlightQueue printOn: aStream.
    aStream nextPutAll: ' opq: '.
    outgoingPacketQueue printOn: aStream.
    aStream nextPutAll: ' pj: '.
    pendingJobs printOn: aStream.
]

{ #category : #mqtt }
MQTTTransportLayer >> publishTopic: aTopic message: msgString qos: qos retain: retainFlag [ 

	"publish the msgString to the connected broker. If qos > 0 we'll need to schedule a pending job for the ack sequence(s)"
    | pubPacket pj |

    pubPacket := MQTTPacketPublish new
         topic: aTopic message: msgString asByteArray;
         retainFlag: retainFlag;
         qos: qos.
    qos > 0
        ifTrue:[
            pubPacket messageID: self newPacketID.
            self addPending: (pj := pubPacket pendingJob)].
    self sendPacket: (MQTTPacketAndPendingJobPair packet: pubPacket pendingJob: pj)
]

{ #category : #mqtt }
MQTTTransportLayer >> readWaitTime [

	"Answer my 'readWaitTime' instance variable."

    ^readWaitTime
]

{ #category : #mqtt }
MQTTTransportLayer >> readWaitTime: aValue [ 

	"Set my 'readWaitTime' instance variable to aValue."

    readWaitTime := aValue
]

{ #category : #mqtt }
MQTTTransportLayer >> releasePendingJob: pendingJob [ 

	"Find the matching record of a pending job and remove it from the list"

    pendingJobs ifNil: [^nil].
    pendingJobsMutex critical: [^pendingJobs remove: pendingJob ifAbsent: [nil]]
]

{ #category : #mqtt }
MQTTTransportLayer >> restart: aSocket [
	"Set up the server to run in asynchronous mode on the socket given as argument.

		This entails making the socket non-blocking and responding to a good set of events.

		The first read event should start things going"


	(Delay forSeconds: 3) wait.
	self debugLog: 'reStart Socket'.
	abortMutex critical: [ abort := false ].
	self initializeSocketStream: aSocket.
	self
		initializeMQTTConnection: false;
		initializePacketReading;
		initializePacketWriting;
		initializeRetryProcess
]

{ #category : #mqtt }
MQTTTransportLayer >> restartTheSocket [

		"flag to indicate if we restart after disconnect"

    ^true
]

{ #category : #mqtt }
MQTTTransportLayer >> retryTime [

	"Answer my 'retryTime' instance variable."

    ^retryTime
]

{ #category : #mqtt }
MQTTTransportLayer >> sendPacket: anMQTTPacket [ 

	"add the packet to the outgoing queue where it will get sucked into The Machine as soon as possible"

    outgoingPacketQueue nextPut: anMQTTPacket
]

{ #category : #mqtt }
MQTTTransportLayer >> sendPossibleDisconnectPackage [

																		"do nothing"

]

{ #category : #accessing }
MQTTTransportLayer >> sockStrm [
	^ sockStrm
]

{ #category : #accessing }
MQTTTransportLayer >> sockStrm: anObject [
	sockStrm := anObject
]

{ #category : #mqtt }
MQTTTransportLayer >> start: aSocket [
	"Set up the server to run in asynchronous mode on the socket given as argument.



		This entails making the socket non-blocking and responding to a good set of events.



		The first read event should start things going"

	self debugLog: 'Start Socket'.
	abort := false.
	retryTime := 20.	"from mosquitto specs"
	readWaitTime := 30.
	pendingJobsMutex := Semaphore forMutualExclusion.
	currentSubscriptions := OrderedCollection new: 4.
	outgoingPacketQueue := SharedQueue new.
	packetInFlightQueue := SharedQueue new.
	statistics := MQTTStatistics new.
	statisticsMutex := Semaphore forMutualExclusion.
	abortMutex := Semaphore forMutualExclusion.
	self initializeSocketStream: aSocket.
	self
		initializeMQTTConnection: true;
		initializePacketReading;
		initializePacketWriting;
		initializeRetryProcess.
	self debugLog: 'Started Socket'
]

{ #category : #mqtt }
MQTTTransportLayer >> statPerform: selector [ 

	"consolidate error handler"

    statisticsMutex critical: [[statistics perform: selector] on: Error do: [:ex | ]].
]

{ #category : #mqtt }
MQTTTransportLayer >> statPerform: selector with: arg [ 

		  "consolidate error handler"

    statisticsMutex critical: [[statistics perform: selector with: arg] on: Error do: [:ex | ]].
]

{ #category : #mqtt }
MQTTTransportLayer >> subscribe: aTopic qos: qos [ 

	"set up a subscription to aTopic with the broker. Use #onTopic:do: for actual client applications"
    | subPacket pj |

    subPacket := MQTTPacketSubscribe new
         addTopic: aTopic qos: qos;
         packetID: self newPacketID.
    pj := subPacket pendingJob.
    self addPending: pj.
    self sendPacket: (MQTTPacketAndPendingJobPair packet: subPacket pendingJob: pj)
]
