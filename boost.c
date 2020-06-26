#include "rd_route/rd_route.c"
#include "MemoryKit.c"
#include <ApplicationServices/ApplicationServices.h>
#include <stdlib.h>
#include <stdbool.h>
long base;
MKProcess gd;
int processID;

void *(*resetlevel)(void*);

void *(*playlayer_init)(void*);
void *(*playlayer_init_original)(void*);

void *(*destroy)(void*,float,bool);

void* playlayer_sharedstate;

int megaBoost(void* a,float b,bool c) {
	resetlevel(playlayer_sharedstate);
	return 0;
}
int rd_init(void* a) {
	playlayer_sharedstate = a;
	return playlayer_init_original(a);
}
void install(void) __attribute__ ((constructor));

void install()
{
	processID = PidFromName("Geometry Dash");
	MKInit(&gd,processID);
	base = gd.base;

	destroy = base+0x22d8e0;
	playlayer_init = base+0xafc90;
	resetlevel = base+0x727b0;

	rd_route(destroy,megaBoost,NULL);
	rd_route(playlayer_init,rd_init,(void **)&playlayer_init_original);
}