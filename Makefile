objects = libmyplugin.so libmyexternal.so main

fail: main.c libmyplugin_fail libmyexternal_fail
	cc -Wall -g main.c -o main -Wl,-rpath,"\$$ORIGIN"

libmyplugin_fail: myplugin.c
	cc -Wall -fpic -g -shared myplugin.c -Wl,-export-dynamic -o libmyplugin.so -Wl,-rpath,"\$$ORIGIN"
	
libmyexternal_fail: myexternal.c
	cc -Wall -fpic -g -shared myexternal.c -o libmyexternal.so
	
pass: main.c libmyplugin_pass libmyexternal_pass
	cc -Wall -g main.c -o main -Wl,-rpath,"\$$ORIGIN"
	
libmyplugin_pass: myplugin.c
	cc -Wall -fpic -g -shared myplugin.c -o libmyplugin.so -Wl,-rpath,"\$$ORIGIN"
	
libmyexternal_pass: myexternal.c libmyplugin_pass
	cc -Wall -fpic -g -shared myexternal.c -o libmyexternal.so libmyplugin.so


.PHONY : clean
clean :
	rm  $(objects)
