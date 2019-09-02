"
This is a write stream subclass, it was specific to VSE to handle issues with memory allocation and to set the stream to binary. Perhaps it can disappear? 
"
Class {
	#name : #MQTTWriteStream,
	#superclass : #RWBinaryOrTextStream,
	#category : #MQTT
}

{ #category : #mqtt }
MQTTWriteStream >> initialize [
	super initialize.
	self binary.
	
]
