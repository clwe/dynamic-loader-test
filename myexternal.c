#include <stdio.h>

extern char* some_global_var_in_plugin;

void external_setup(){
    printf("setting up external...\n");
    fprintf(stdout, "%s\n", some_global_var_in_plugin);
}
