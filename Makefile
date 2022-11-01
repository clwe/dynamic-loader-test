objects = libmyplugin.so libmyexternal.so main

executable: main.c libmyplugin libmyexternal
	cc -Wall -g main.c -o main -Wl,-rpath,"\$$ORIGIN"

libmyplugin: myplugin.c
	cc -Wall -fpic -g -shared myplugin.c -o libmyplugin.so -Wl,-rpath,"\$$ORIGIN"
	
libmyexternal: myexternal.c libmyplugin
	cc -Wall -fpic -g -shared myexternal.c -o libmyexternal.so libmyplugin.so
	
.PHONY : clean
clean :
	rm  $(objects)
