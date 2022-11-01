#include <stdio.h> 
#include <dlfcn.h>

int main(void) {    
    const char* filename = "libmyplugin.so";
    void *dlobj = dlopen(filename, RTLD_LOCAL | RTLD_NOW);
    if (!dlobj) {
        fprintf(stderr, "dlopen failed for %s: %s\n", filename, dlerror());
        return (1);
    }
    int (*func)(void);
    *(void **) (&func) = dlsym(dlobj, "load_external");
    
    if (!func) {
        fprintf(stderr, "dlopen failed for %s: %s\n", filename, dlerror());
        return 1;
    }
    else {
        fprintf(stdout,"%s succesfully loaded\n", filename);
        (*func)();
    }
    return 0; 
}
