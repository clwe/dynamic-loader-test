# Dynamic-Loader-Test
This illustrates symbol resolution issues with recursive dynamic loading of plugin libraries. Plugin libraries are shared object libraries which are not linked at compile time, but loaded with `dlopen()` at runtime. 

In this test case, a plugin library uses symbols of another plugin library which it is called from. The call graph would be as follows:

`main -> libmyplugin.so -> libmyexternal.so`

Here `libmyexternal.so` needs to resolve a symbol that is defined in `libmyplugin.so`.

Without special considerations this would fail. Because the symbols of `libmyplugin.so` would not be exported to the dynamic symbol table, since they are not known to be used anywhere. The compiler cannot anticpate that we are loading `libmyexternal.so` at runtime, that needs them. But even if we force the export of the dynamic symbols of `libmyplugin` by using the linker flag [`-Wl,-export-dynamics`](https://sourceware.org/binutils/docs/ld/Options.html#index-_002dE), the dynamic linker would still fail to resolve the symbols in `libmyexternal.so`. 

To see why, build and run the example as follows:
```shell
$ make fail
$ ./main

libmyplugin.so succesfully loaded
trying to load external...
dlopen failed for libmyexternal.so: dlibmyexternal.so: undefined symbol: some_global_var_in_plugin
dlopen failed for libmyexternal.so: libmyplugin.so: undefined symbol: external_setup
```
Loading the symbols from `libmylugin.so` fails, because the dynamic loader will not lookup the symbols in `libmylugin.so` when loading `libmyexternal.so` at runtime. This is illustrated by the following debug output:
``` shell
$ LD_DEBUG=symbols,bindings ./main
    166683:     symbol=some_global_var_in_plugin;  lookup in file=./main [0]
    166683:     symbol=some_global_var_in_plugin;  lookup in file=/usr/lib/x86_64-linux-gnu/libc.so.6 [0]
    166683:     symbol=some_global_var_in_plugin;  lookup in file=/lib64/ld-linux-x86-64.so.2 [0]
    166683:     symbol=some_global_var_in_plugin;  lookup in file=./libmyexternal.so [0]
    166683:     symbol=some_global_var_in_plugin;  lookup in file=/usr/lib/x86_64-linux-gnu/libc.so.6 [0]
    166683:     symbol=some_global_var_in_plugin;  lookup in file=/lib64/ld-linux-x86-64.so.2 [0]
    166683:     /home/clemens/workspace/code/playground/dynamic-loader-test/libmyexternal.so: error: symbol lookup error: undefined symbol: some_global_var_in_plugin (fatal)
dlopen failed for libmyexternal.so: ./libmyexternal.so: undefined symbol: some_global_var_in_plugin
```
The dynamic loader, does not know, that the symbols are in `libmyplugin.so` it will by default look only in the calling executable `main` and its dependencies. 

There are at least two ways to resolve the issue: 

## 1. change the lookup scope of the dynamic linker at runtime: 
To change the lookup scope we can use the parameter `RTLD_GLOBAL` in the dlopen call in `main.c`. I.e. change 
the line 
``` shell
void *dlobj = dlopen(filename, RTLD_LOCAL | RTLD_NOW);
```
to 
``` shell
void *dlobj = dlopen(filename, RTLD_GLOBAL | RTLD_NOW);
```

This adds any file that is dlopened within main to the global lookup scope. Such that, when opening `libmyexternal.so` the dynamic linker will find the symbols in global scope when parsing `libmyplugin.so`.
``` shell
$ LD_DEBUG=symbols,bindings ./main
    167115:     symbol=some_global_var_in_plugin;  lookup in file=./main [0]
    167115:     symbol=some_global_var_in_plugin;  lookup in file=/usr/lib/x86_64-linux-gnu/libc.so.6 [0]
    167115:     symbol=some_global_var_in_plugin;  lookup in file=/lib64/ld-linux-x86-64.so.2 [0]
    167115:     symbol=some_global_var_in_plugin;  lookup in file=./libmyplugin.so [0]
    167115:     binding file ./libmyexternal.so [0] to ./libmyplugin.so [0]: normal symbol `some_global_var_in_plugin'
```
Unfortunately I don't have control over the main executable in my application (it's a third party software distributed in binary).

## 2. link `libmyexternal.so` with `libplugin.so`
Linking `libmyexternal.so` with `libplugin.so` is another solution, because it explicitely adds libmyplugin as a dependency that the dynamic loader will lookup at runtime for missing symbols when loading `libmyexternal.so`.

For this gcc needs to link the external with the plugin library at compile time.
```shell
cc -Wall -fpic -g -shared myexternal.c -o libmyexternal.so libmyplugin.so
```

This solution will be built when running:
```shell
$ make pass
...
$ ./main 
libmyplugin.so succesfully loaded
trying to load external...
libmyexternal.so succesfully loaded
setting up external...
this is a global var in myplugin
```
This solution is also not ideal, because the relative paths `libmyexternal.so` and `libmyplugin.so` might change at runtime. To remedy this another step has to be taken. We need to give `libmyplugin.so` an internal version name with the link flag `-Wl,-soname,libmyplugin.so`. This allows the dynamic loader to search for the library at runtime on its given search scope, instead of just searching for it on an absolute path as this example shows so far. 
