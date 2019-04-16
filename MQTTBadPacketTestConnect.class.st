"
This was part of Tim Rowledge's testing, might not work now
"
Class {
	#name : #MQTTBadPacketTestConnect,
	#superclass : #MQTTPacketConnect,
	#category : #MQTT
}

{ #category : #mqtt }
MQTTBadPacketTestConnect >> encodeVariableHeaderOn: aWriteStream [ 

"write the CONNECT variable header (see 3.1.2) to the stream"

    self encodeString: 'MQTT' on: aWriteStream.
    aWriteStream
        nextPut: 255;
        nextPut: self connectFlags.
    self encode16BitInteger: keepAliveTime on: aWriteStream
]
