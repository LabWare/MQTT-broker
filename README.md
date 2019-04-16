# MQTT-broker
An implementation of a MQTT Client and a Broker in pure Smalltalk for Pharo

This work is based on the work that Tim Rowledge wrote for the Pi
The original code base is found at:
http://www.squeaksource.com/@Vok40xZouHIIkrzY/xMjFzu_2

What we did was refactor the logic into a client and server interface to support a full MQTT V311 data broker in pure Smalltalk.
This product (in VSE) did pass various V311 data broker test units, after converting to Pharo we hope it still works.

To start the server.
(MQTTServerInterface openOnPort: 1883) start inspect.

To start a client.
[(MQTTClientInterface openOnHostName: ‘192.168.1.139’ port: 1883 keepAlive: 300) start inspect] fork.
or
[(MQTTClientInterface openOnHostName: ‘test.mosquitto.org’ port: 1883 keepAlive: 300) start inspect] fork.

Stopping the server or the client.

MQTTServerInterface  allInstances do: [ :e | e stop ].
MQTTClientInterface  allInstances do: [ :e | e stop ].


Helpful for figuring out what is running, or not, ensure you do a GC before using. 

MQTTSocketClient  allInstances  inspect.
MQTTClientInterface allInstances  inspect.
MQTTTransportLayerClient allInstances  inspect.
MQTTSocketServer  allInstances  inspect.
MQTTServerInterface allInstances inspect.
MQTTSocketDaemon allInstances inspect.
MQTTTransportLayerServer allInstances inspect.

If you examine the class MQTTStatistics we do collect statistics on each server and client session. 

LOGGING is on
To turn it off change the code found in MQTTCLientInterface class>>debugLog:tag:str2: 
(or: [true]) 

In MQTTCLientInterface
there are methods testBlock and testSetupForTopic 
These can be alter to test for example a connection to test.mosquitto.org. 
At the moment they send QOS > 0 message info to the Transcript


Things that the community could do? 

Persistent store of the data broker queued data
Ensure it works with Pharo
Port to VA Smalltalk
Port to other variations. 
If you need a VSE version please contact us. 


