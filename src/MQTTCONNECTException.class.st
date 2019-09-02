"
exception for connection failure
"
Class {
	#name : #MQTTCONNECTException,
	#superclass : #Error,
	#instVars : [
		'connectReturnCode'
	],
	#category : #MQTT
}

{ #category : #mqtt }
MQTTCONNECTException class >> connectReturnCode: aByte [

    ^(super new connectReturnCode: aByte) signal.
]

{ #category : #mqtt }
MQTTCONNECTException >> connectReturnCode [

	"Answer my 'connectReturnCode' instance variable."

    ^connectReturnCode
]

{ #category : #mqtt }
MQTTCONNECTException >> connectReturnCode: aValue [ 

	"Set my 'connectReturnCode' instance variable to aValue."

    connectReturnCode := aValue
]

{ #category : #mqtt }
MQTTCONNECTException >> printOn: aStream [ 

	  "debug print"

    super printOn: aStream.
    aStream nextPutAll: ' returnCode: '.
    connectReturnCode printString printOn: aStream.
]
