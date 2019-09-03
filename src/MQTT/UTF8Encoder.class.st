"
An abstraction class used in VSE to enable UTF8 encoding/decoding. Backs to Pharo/Squeak classes that do that work.
"
Class {
	#name : #UTF8Encoder,
	#superclass : #Object,
	#category : #MQTT
}

{ #category : #encoding }
UTF8Encoder class >> decode: aString [
	^aString convertFromWithConverter: UTF8TextConverter new.
]

{ #category : #encoding }
UTF8Encoder class >> encode: aString [
	^aString convertToWithConverter: UTF8TextConverter new.
]
