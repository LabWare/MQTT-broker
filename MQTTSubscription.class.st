"
The Subscription object. Holds onto the action block and other meta-data needed for subscribing. 
"
Class {
	#name : #MQTTSubscription,
	#superclass : #Object,
	#instVars : [
		'topic',
		'actionBlock',
		'qos',
		'retainFlag'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTSubscription class >> commentOriginal [

"A MQTTSubscription is how we keep track of subscribed topics and the action the user wants when a packet comes in

topic - a String that we match against an incoming packet to see if we need to do anything. See the MQTT documentation for the rules about wildcards

actionBlock - the Block we run if we match the topic; it gets two parameters, the topic string and the message data"

]

{ #category : #mqtt }
MQTTSubscription class >> for: aTopic qos: qos do: aBlock [

    ^super new for: aTopic qos: qos do: aBlock
]

{ #category : #mqtt }
MQTTSubscription >> = aSubscription [ 

	"equal"

    (aSubscription class = self class)
        ifFalse:[^false].
    ^topic = aSubscription topic
]

{ #category : #mqtt }
MQTTSubscription >> for: aTopic qos: aQos do: aBlock [ 

	"build a response to data for aTopic being received; check the validity of aTopic (no nulls, + or # used properly etc) and
	return nil if there is a problem, otherwise return self"
    | strm priorChar currentChar nextChar count |

    topic := aTopic.
    actionBlock := aBlock.
    qos := aQos.
    priorChar := nil.
    count := 0.
    retainFlag := true.
    strm := aTopic readStream.
    [currentChar := [strm next] on: Error do: [:e | nil]] whileNotNil: [
        nextChar := strm peek.
        currentChar = $+
            ifTrue:[
                ((priorChar notNil and: [priorChar ~= $/]) or: [nextChar notNil and: [nextChar ~= $/]])
                    ifTrue:[^nil]]
            ifFalse:[
                currentChar = $#
                    ifTrue:[
                        ((priorChar notNil and: [priorChar ~= $/]) or: [nextChar notNil])
                            ifTrue:[^nil]]
                    ifFalse:[
                        currentChar = Character null "MQTT-4.7.3-2"
                            ifTrue:[^nil]]].
        count := count + 1.
        priorChar := currentChar].
    count > 65535
        ifTrue:[^nil]
]

{ #category : #mqtt }
MQTTSubscription >> handlePacket: aPublishPacket [ 

	"see if the packet's topic matches mine; if so, evaluate the actionBlock"

    aPublishPacket matchesSubscription: self ifTrue: actionBlock
]

{ #category : #mqtt }
MQTTSubscription >> hash [

    ^topic hash
]

{ #category : #mqtt }
MQTTSubscription >> printOn: aStream [ 

	  "print useful data"

    super printOn: aStream.
    aStream nextPutAll: ' t: '.
    topic asString printOn: aStream.
    aStream nextPutAll: ' r: '.
    retainFlag asString printOn: aStream.
    aStream nextPutAll: ' qos: '.
    qos asString printOn: aStream.
]

{ #category : #mqtt }
MQTTSubscription >> qos [

	"Answer my 'qos' instance variable."

    ^qos
]

{ #category : #mqtt }
MQTTSubscription >> retainFlag [

	"Answer my 'retainFlag' instance variable."

    ^retainFlag
]

{ #category : #mqtt }
MQTTSubscription >> retainFlag: aValue [ 

	"Set my 'retainFlag' instance variable to aValue."

    retainFlag := aValue
]

{ #category : #mqtt }
MQTTSubscription >> topic [

	"Answer my 'topic' instance variable."

    ^topic
]

{ #category : #mqtt }
MQTTSubscription >> topic: aValue [ 

	"Set my 'topic' instance variable to aValue."

    topic := aValue
]

{ #category : #mqtt }
MQTTSubscription >> topicMatches: candidateString [ 

	"does my topic match this topic? First version simply does a string =
	test, needs to actually parse the pattern properly"

	"^topic sameAs: candidateString"

	"copied from Python and C. Ugly code. Fix!
	See git.eclipse.org/mosquitto/org.eclipse.mosquitto.git/tree/llib/util_mosq.c for the original"
    | result multilevel topicLen csLen topicPos csPos |

    "[MQTT-3.3.2-3] [MQTT-4.7.3-4] [MQTT-4.7.2-1]"
    result := true.
    multilevel := false.
    topicLen := topic size.
    csLen := candidateString size.
    (topicLen > 0 and: [csLen > 0])
        ifTrue:[
            (topic first = $$ xor: candidateString first = $$)
                ifTrue:[^false]]. "testing for both or neither first char being $$"
    topicPos := csPos := 1.
    [topicPos <= topicLen and: [csPos <= csLen]]
        whileTrue:[
            (topic at: topicPos) = (candidateString at: csPos)
                ifTrue:[
                    csPos = csLen
                        ifTrue:[ "check for topic ending in /#"
                            (topicPos = (topicLen - 2) and: [(topic last: 2) = '/#'])
                                ifTrue:[^true]].

					"move to next char"
                    topicPos := topicPos + 1.
                    csPos := csPos + 1.
                    (csPos > csLen and: [topicPos > topicLen])
                        ifTrue:[^true]
                        ifFalse:[
                            ((csPos > csLen and: [topicPos = topicLen]) & (topic last = $+))
                                ifTrue:[^true]]]
                ifFalse:[
                    (topic at: topicPos) = $+
                        ifTrue:[
                            topicPos := topicPos + 1.
                            [csPos <= csLen and: [(candidateString at: csPos) ~= $/]]
                                whileTrue:[csPos := csPos + 1].
                            (csPos > csLen and: [topicPos > topicLen])
                                ifTrue:[^true]]
                        ifFalse:[
                            (topic at: topicPos) = $#
                                ifTrue:[
                                    multilevel := true.
                                    ^topicPos = topicLen]
                                ifFalse:[^false]]]].
    (multilevel not and: [csPos <= csLen or: [topicPos <= topicLen]])
        ifTrue:[^false].
    ^result
]
