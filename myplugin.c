#include <stdio.h> 
#include <dlfcn.h>

char* some_global_var_in_plugin = "this is a global var in myplugin";

void load_external(){
    printf("trying to load external...\n");
    
    const char* filename = "libmyexternal.so";
    void *dlobj = dlopen(filename, RTLD_LOCAL | RTLD_NOW);
    if (!dlobj)
    {
        fprintf(stderr, "dlopen failed for %s: %s\n", filename, dlerror());
    }
    
    void (*func)(void);
    *(void **) (&func) = dlsym(dlobj, "external_setup");
    
    if (!func) {
        fprintf(stderr, "dlopen failed for %s: %s\n", filename, dlerror());
    }
    else {
        fprintf(stdout,"%s succesfully loaded\n", filename);
        (*func)();
    }
}
