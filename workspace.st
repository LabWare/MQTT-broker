"
Hello John

I'm interested in your project, and to port it to VA. Would it be possible to get the code as output by using pharo2va ?
https://github.com/vasmalltalk/pharo2va
thanks in advance
Norbert
norbert.schlemmer@neunzehn.at"


Metacello new
	baseline: 'Pharo2VA';
	repository: 'github://vasmalltalk/pharo2va:master/source';
	load.
	
Pharo2VA
	exporter
		directory: FileSystem disk workingDirectory / 'exports';
		packagesNames: {'MQTT'};
		export