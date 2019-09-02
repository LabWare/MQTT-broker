"
Exception for broker lookup failure, current not used
"
Class {
	#name : #MQTTBrokerLookupFailure,
	#superclass : #Error,
	#instVars : [
		'brokerName'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTBrokerLookupFailure class >> brokerName: aString [

    ^super new brokerName: aString
]

{ #category : #mqtt }
MQTTBrokerLookupFailure >> brokerName [

    ^brokerName
]

{ #category : #mqtt }
MQTTBrokerLookupFailure >> brokerName: aString [

    brokerName := aString
]
