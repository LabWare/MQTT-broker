Extension { #name : #Socket }

{ #category : #'*MQTT' }
Socket >> printOn: aStream [

	super printOn: aStream.
	aStream nextPutAll: '[', self statusString, ' ', self socketHandle hash printString, ']'.

]
