# dynamic-loader-test
illustrates symbol resolution issues with recursive dynamic loading of plugins

to build and run the example do
```shell
$ make
$ ./main
```

Note, that gcc needs to link the external with the plugin library.
`cc -Wall -fpic -g -shared myexternal.c -o libmyexternal.so libmyplugin.so`
otherwise the symbol `some_global_var_in_plugin` will not be found. 

Using the build flag [https://sourceware.org/binutils/docs/ld/Options.html#index-_002dE -Wl,-export-dynamcics] is not an alternative in this case. 
The dynamic loader will export the symbol definitions to the libplugin.so, but when loading libexternal.so the dynamic linker will only search main for the missing symbols and not where they actually reside -- in libplugin.so. 

You can verify that this is the case by executing:
``` shell
$ LD_DEBUG=symbols,bindings ./main
```
The output will be:
...
