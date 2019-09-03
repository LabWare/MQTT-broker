"
The pending work after a packet is sent. 

When a packet is sent, and there is oh say a SubAck to be expected in the future we queue up a pending job pair for a future time. The time first is set to the far future, then once the packet is sent on the wire, we look for a response N seconds out. If that response fails we do the recovery logic which for a SubAck would be to resend the Subscribe Packet. 

The reason to wait for the transmission on the wire is that a Publish with 100MB of data might take minutes/hours to transmit, so obviously we don't want to wait 90 seconds for a response to our QOS 1 or 2 logic
"
Class {
	#name : #MQTTPacketAndPendingJobPair,
	#superclass : #Object,
	#instVars : [
		'packet',
		'pendingJob'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTPacketAndPendingJobPair class >> packet: aPacket pendingJob: aPendingJob [ 

		"make pair"
    | instance |

    instance := self new.
    instance packet: aPacket.
    instance pendingJob: aPendingJob.
    ^instance
]

{ #category : #mqtt }
MQTTPacketAndPendingJobPair >> encodeOn: sockStrm [ 

	"encode and reset time"
    | ret |

    ret := self packet encodeOn: sockStrm.
    pendingJob ifNotNil: [pendingJob resetSendTime: 20].
    ^ret
]

{ #category : #mqtt }
MQTTPacketAndPendingJobPair >> packet [

	"Answer my 'packet' instance variable."

    ^packet
]

{ #category : #mqtt }
MQTTPacketAndPendingJobPair >> packet: aValue [ 

	"Set my 'packet' instance variable to aValue."

    packet := aValue
]

{ #category : #mqtt }
MQTTPacketAndPendingJobPair >> pendingJob [

	"Answer my 'pendingJob' instance variable."

    ^pendingJob
]

{ #category : #mqtt }
MQTTPacketAndPendingJobPair >> pendingJob: aValue [ 

	"Set my 'pendingJob' instance variable to aValue."

    pendingJob := aValue
]

{ #category : #mqtt }
MQTTPacketAndPendingJobPair >> printOn: aStream [ 

	"print useful data"

    super printOn: aStream.
    aStream nextPutAll: ' '.
    packet asString printOn: aStream.
    aStream nextPutAll: ' '.
    pendingJob asString printOn: aStream.
]
