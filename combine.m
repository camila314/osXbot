#include "MKit/MKit.h"
#include <ApplicationServices/ApplicationServices.h>
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <stdlib.h>
#include <stdbool.h>

#define SPACE 32
#define ARROW 283
#define MSIZE_T 2048

#define CHK_MAKE(p) [NSValue valueWithBytes:&p objCType:@encode(Checkpoint)]
#define CHK_GET(p, o) [p getValue:&o]

extern void getFileSaveName(void (*callback)(char*));
extern void getFileOpenName(void (*callback)(char*));
extern void getWavFile(void (*callback)(char*));

extern void getSpeed(void(*)(float));
extern void getFps(void(*)(float));

extern void dispatchAsm(void* a, int b, bool c);
extern void routAsm();
extern void toStdStr(void*, char const*);

typedef struct MacroType {
    double xpos;
    int key;
    bool down;
} MType;
typedef struct MacroType2 {
    MType macro;
    int index;
} MType2;

typedef struct Checkpoint {
    float xpos;
    float rotation;
    double accel;

    double accel2;
    float rotation2;
} Checkpoint;

int64_t base;
pid_t processID;
void* dispatcherObject;
int64_t scheduler_update;

void *(*scheduler_update_tramp)(void*);
void *(*og)(int64_t, double);
void *(*dispatch)(void*, int, bool);
void *(*dispatch_og)(void*, int, bool);
void *(*createPlay)(void*);
void* (*editorInit)(void*, float);
void (*increment)(void*, int);  // = 0x185a20;
void (*decrement)(void*, int);  // = 0x185b70;
void (*practice_og)(void*, bool);
void (*practice_ogCheckpoint)(void*);
void (*practice_ogRemove)(void*);
void (*practice_ogDies)(void*, void*, void*);
void (*pauseGame)(int64_t, bool);
void (*pasteObjects)(void*, void*);
void (*ogMain)(void*);
void (*playDeathEffect)(void*);
void (*ogKeyDown)(void*, int);
void (*ogKeyUp)(void*, int);
void (*basePush)(void*, int, bool);
void (*baseRelease)(void*, int, bool);
int64_t (*sharedManager)();

int macro_counter = 0;
int play_record = 1;

int arraySize = MSIZE_T;
int arrayCounter = 0;
MType Macro[MSIZE_T];
MType PracticeMode[MSIZE_T];

bool modifier1 = 0;
bool modifier2 = 0;
bool modifier1_keyDown = 0;
bool modifier2_keyDown = 0;
bool paused = 0;
bool keybinds = true;
bool attached = 0;
bool doIPaste = false;
bool practice_record_mode = false;

bool audioEnabled = false;
NSString* audioFileLocation;
NSSound* sharedPlayer;


float SPEED = 1;
float FPS = 60.0;
double practice_playerweight, practice_hiddencheckweight = 0.0f;
float stop_spam_prev = 0.0;
double prev_xpos = 0.0;

CFMessagePortRef remotePort;
NSMutableArray* checkpoints;

void* editorLock(void* inst, float delta) {
    return editorInit(inst, 1./(FPS*SPEED));
}

char const* getPickupString() {
    NSString* template = @"1,1817,2,%lf,3,%d,36,1,80,%d,77,%d;";

    NSMutableString* output = [@"" mutableCopy];

    for (int i = 0; i < arrayCounter; i++) {
        MType event = PracticeMode[i];
        if (event.key != SPACE && event.key != ARROW)
            break;
        int itemid = 1;
        int count = -1;
        if (event.down == true) {
            itemid = 0;
            count = 1;
        }
        printf("test: %f\n", 432.0);
        [output appendString:[NSString stringWithFormat:template,event.xpos, 100+(50*itemid),itemid, count]];
    }

    if ([output length] > 2) {
        [output deleteCharactersInRange:NSMakeRange([output length]-1, 1)];
        return [output UTF8String];
    } else {
        return "9";
    }
}

void pastePickups() {
    char const* lvlstring = getPickupString();

    if (*lvlstring == '9') {
        printf("why did you press k\n");
        return;
    }

    printf("before the standard string\n");
    int64_t stdstring = 0;
    toStdStr((void*)&stdstring, lvlstring);
    printf("standard string\n");

    int64_t state = sharedManager();
    int64_t layer = *((int64_t*)(state+0x188));
    if (layer) {
        void* editor = *((void**)(layer+0x5d8));
        pasteObjects(editor, (void*)&stdstring);
    } else {
        printf("you arent even in the editor lmao\n");
    }
}


void mainLoop(void* instance) {
    if (doIPaste) {
        pastePickups();
        doIPaste = false;
    }
    ogMain(instance);
}

void practicePrune(double pos) {
    for (int i = 0; i < arrayCounter; i++) {
        if (PracticeMode[i].xpos >= pos) {
                arrayCounter = i;
            break;
        }
    }
}

void speedhack(void* instance) {
    scheduler_update_tramp(instance);

    float* m_fDeltaTime = (float*)((intptr_t)instance+0x90);
    *m_fDeltaTime = (*m_fDeltaTime)/SPEED;
}

void changeSpeed(float num) {
    if (num == 0.0) return;
    float n = (1.0/(FPS*num));
    writeProcessMemory(baseAddress() + 0x2EC3DC, 4, &n);
    SPEED = num;
}

void changeFps(float num) {
    if (num == 0.0) return;
    float n = (1.0/(num*SPEED));
    writeProcessMemory(baseAddress() + 0x2EC3DC, 4, &n);
    FPS = num;
}

void saveToFile(char* fileName) {
    FILE* saveLocation = fopen(fileName, "wb");
    fwrite(Macro, sizeof(MType), arraySize, saveLocation);
    fclose(saveLocation);
}

void loadFromFile(char* fileName) {
    FILE* saveLocation = fopen(fileName, "rb");
    fread(Macro, sizeof(MType), arraySize, saveLocation);
    fclose(saveLocation);
}

void loadWav(char* fileName) {
    audioEnabled = true;
    audioFileLocation = [[NSString stringWithUTF8String:fileName] retain];
    NSLog(@"ight so its %@",audioFileLocation);
}

void sendAdd(int index, MType* mcro) {
    MType2 tmp;
    tmp.index = index;
    tmp.macro = *mcro;
    CFDataRef toSend = CFDataCreate(NULL, (const void*)&tmp, sizeof(MType2));
    CFMessagePortSendRequest(remotePort,
                             0x2,
                             toSend,
                             1,
                             1,
                             NULL,
                             NULL);
}

void sendSelect(int index) {
    MType2 tmp;
    tmp.index = index;
    CFDataRef toSend = CFDataCreate(NULL, (const void*)&tmp, sizeof(MType2));
    CFMessagePortSendRequest(remotePort,
                             0x4,
                             toSend,
                             1,
                             0.01,
                             NULL,
                             NULL);
}

void delt(double max) {
    bool d = true;
    for (int i = 0; i < arraySize; i++) {
        MType tmp;
        tmp.xpos = 0;
        tmp.down = 0;
        tmp.key = ARROW;

        if (Macro[i].xpos > max) {
            if (d) {
                arrayCounter = 1;
                d = false;
            }
            Macro[i] = tmp;
            sendAdd(i, &tmp);
        }
    }
}

void practice_toggle(void* instance, bool toggle) {
    practice_og(instance, toggle);

    practice_record_mode = toggle;
    practice_playerweight = 0;
    if (toggle)
        arrayCounter = 0;
}
void* newLevel(void* inst) {
    practice_record_mode = false;
    return createPlay(inst);
}

void practice_markCheckpoint(void* instance) {
    practice_ogCheckpoint(instance);

    if (prev_xpos != 0) {
        float rota1, acc1, rota2, acc2;
        int64_t playob1 = *(int64_t*)(instance + 0x380);
        int64_t playob2 = *(int64_t*)(instance + 0x388);
        if (playob1) {
            rota1 = *(float*)(playob1 + 0x24);
            acc1 = *(double*)(playob1 + 0x760);
        }
        if (playob2) {
            rota2 = *(float*)(playob2 + 0x24);
            acc2 = *(double*)(playob2 + 0x760);
        }
        Checkpoint ch = {prev_xpos, rota1, acc1, rota2, acc2};
        [checkpoints addObject:CHK_MAKE(ch)];
        practice_hiddencheckweight = prev_xpos;


        printf("added checkweight. weight: %lf\n", practice_hiddencheckweight);
    }
}
void practice_removeCheckpoint(void* instance) {
    practice_ogRemove(instance);
    [checkpoints removeLastObject];
    Checkpoint ch;
    CHK_GET([checkpoints lastObject], ch);
    practice_hiddencheckweight = ch.xpos;
    printf("removed checkweight. weight: %lf\n", practice_hiddencheckweight);
}
void practice_playerDies(void* instance, void* player, void* game) {
    practice_ogDies(instance, player, game);
    if (practice_record_mode) {
        practice_playerweight = prev_xpos;
        practicePrune(practice_hiddencheckweight);
        prev_xpos = 0.0;
    }
}

void itsPaused(int64_t a, bool b) {
    printf("%d\n", b);
    pauseGame(a,b);
    if (audioEnabled && sharedPlayer && sharedPlayer.playing) {
        NSLog(@"we aren't playing anymore");
        [sharedPlayer stop];
    }
}
void audioDie(void* a) {
    playDeathEffect(a);
    if (audioEnabled && sharedPlayer && sharedPlayer.playing) {
        [sharedPlayer stop];
        NSLog(@"we aren't playing anymore");
    }
}

void rout_rec(int64_t a, double b) {
    if (arrayCounter >= arraySize) return;


    if (prev_xpos == 0.0 && practice_record_mode) {
        printf("we at 0,  checkweight is %lf\n", practice_hiddencheckweight);
        practicePrune(practice_hiddencheckweight);
        if ([checkpoints count] > 0) {
            int64_t playobj1 = *((int64_t*)(a+0x380));
            int64_t playobj2 = *((int64_t*)(a+0x388));
            
            Checkpoint ch;
            CHK_GET([checkpoints lastObject], ch);
            if (!playobj1) return;
            *((double*)(playobj1 + 0x760)) = ch.accel;
            *((float*)(playobj1 + 0x7c8)) = ch.xpos;
            *((float*)(playobj1 + 0x24)) = ch.rotation;
            *((float*)(playobj1 + 0x28)) = ch.rotation;
            if (!playobj2) return;
            *((float*)(playobj2 + 0x7c8)) = ch.xpos;
            *((double*)(playobj2 + 0x760)) = ch.accel2;
            *((float*)(playobj2 + 0x24)) = ch.rotation2;
            *((float*)(playobj2 + 0x28)) = ch.rotation2;
        }
    }

    if (practice_record_mode) {
        int64_t playobj = *((int64_t*)(a+0x380));

        prev_xpos = *((float*)(playobj+0x7c8));
    } else {
        prev_xpos = b;
    }

    /*if(play_record==3)
        b -= 1.0/(SPEED*FPS);*/
    if (modifier1 == 1) {
        if (!practice_record_mode) {
            MType tmp;
            tmp.xpos = b;
            tmp.key = ARROW;
            tmp.down = modifier1_keyDown;
            Macro[arrayCounter] = tmp;
            if (remotePort && CFMessagePortIsValid(remotePort))
                sendAdd(arrayCounter, &tmp);
        } else {
            MType tmp;
            double xpos = prev_xpos;
            tmp.xpos = xpos;
            tmp.key = ARROW;
            tmp.down = modifier1_keyDown;
            PracticeMode[arrayCounter] = tmp;
        }
        ++arrayCounter;
    }
    if (modifier2 == 1) {
        if (!practice_record_mode) {
            MType tmp;
            tmp.xpos = b;
            tmp.key = SPACE;
            tmp.down = modifier2_keyDown;
            Macro[arrayCounter] = tmp;
            if (remotePort && CFMessagePortIsValid(remotePort))
                sendAdd(arrayCounter, &tmp);
        } else {
            MType tmp;
            double xpos = prev_xpos;
            tmp.xpos = b;
            tmp.key = SPACE;
            tmp.down = modifier2_keyDown;
            PracticeMode[arrayCounter] = tmp;
        }
        ++arrayCounter;
    }
    modifier1 = 0;
    modifier2 = 0;
}

void rout_play(int64_t a, double b) {
    if (b*3 <= 1./FPS) {
        macro_counter = 0;
        stop_spam_prev = 0.0;
        
        if (audioEnabled) {
            if (sharedPlayer) {
                [sharedPlayer stop];
                [sharedPlayer release];
            }
            sharedPlayer = [[[NSSound alloc] initWithContentsOfFile:audioFileLocation byReference:NO] retain];
            sharedPlayer.currentTime = 0.16;
            [sharedPlayer play];
            NSLog(@"we are playing: %d",sharedPlayer.playing);
        }
    }
    if (macro_counter >= arraySize) return;
    MType currnt = Macro[macro_counter];
    register double macroXpos = currnt.xpos;
    if (macroXpos <= b && macroXpos != 0 && macroXpos > stop_spam_prev) {
        dispatch_og(dispatcherObject, currnt.key, currnt.down);

        stop_spam_prev = macroXpos;
        if (remotePort && CFMessagePortIsValid(remotePort))
            sendSelect(macro_counter);

        macro_counter++;
        arrayCounter = macro_counter;
    }
}

void* routBoth(int64_t a, double b) {
    register void* ret_val = og(a, b);
    if (play_record == 1 || play_record == 3) {
        rout_rec(a, b);
    } else if (play_record == 0) {
        rout_play(a, b);
    }
    return ret_val;
}

void eventTapCallback(void* inst, int key, bool isdown) {
        dispatcherObject = inst;
        if (key == ARROW || key == SPACE) {
            if (play_record == 1 && arrayCounter < arraySize) {
                if (key == ARROW && modifier1_keyDown != isdown) {
                    modifier1 = 1;
                    modifier1_keyDown = isdown;
                } else if (key == SPACE && modifier2_keyDown != isdown) {
                    modifier2 = 1;
                    modifier2_keyDown = isdown;
                }
            }
            return;
        } else if (isdown) {
            if (key == 9)
                keybinds = !keybinds;
            if (keybinds) {
                switch (key) {
                    case 65:
                        arrayCounter = 0;
                        return;
                    case 87:
                        play_record = 2;
                        return;
                    case 80:
                        play_record = 0;
                        return;
                    case 82:
                        play_record = 1;
                        return;
                    case 69:
                        play_record = 3;
                        return;
                    case 75:
                        doIPaste = true;
                        return;
                    case 67:
                        getSpeed(changeSpeed);
                        return;
                    case 70:
                        getFps(changeFps);
                        return;
                    case 83:
                        getFileSaveName(saveToFile);
                        return;
                    case 76:
                        getFileOpenName(loadFromFile);
                        return;
                    case 77:
                        audioEnabled = false;
                        return;
                    case 84:
                        getWavFile(loadWav);
                        return;
                    default:
                        return;
                }
            } else {
                return;
            }
        }
}

void inc(void* a, int b) {
    if (play_record == 3) {
        if (b < 500) {
            dispatch_og(dispatcherObject, 32, 1);
            modifier2 = 1;
            modifier2_keyDown = 1;
        } else {
            dispatch_og(dispatcherObject, 283, 1);
            modifier1 = 1;
            modifier1_keyDown = 1;
        }
    }
    increment(a, b);
}

void dec(void* a, int b) {
    if (play_record == 3) {
        if (b < 500) {
            dispatch_og(dispatcherObject, 32, 0);
            modifier2 = 1;
            modifier2_keyDown = 0;
        } else {
            dispatch_og(dispatcherObject, 283, 0);
            modifier1 = 1;
            modifier1_keyDown = 0;
        }
    }
    decrement(a, b);
}

void editorKeyDown(long inst, int key) {
    if(key==38) {
        void* lay = *(void**)(inst+0x408);
        basePush(lay, 1, false);
    }
    ogKeyDown((void*)inst, key);
}

void editorKeyUp(long inst, int key) {
    if(key==38) {
        void* lay = *(void**)(inst+0x2d0);
        baseRelease(lay, 1, false);
    }
    ogKeyUp((void*)inst, key);
}

// *INTERPROCESS COMMUNICATION ZONE*
static CFDataRef Callback(CFMessagePortRef port,
                          SInt32 messageID,
                          CFDataRef data,
                          void *info) {
    if (messageID == 1) {
        CFDataGetBytes(data, CFRangeMake(0, CFDataGetLength(data)), &Macro);
    } else if (messageID == 0) {
        attached = true;
        remotePort = CFMessagePortCreateRemote(0, CFSTR("localMacro"));
    }
    return CFDataCreate(NULL, "ok", 3);
}

void initIPC() {
    remotePort = CFMessagePortCreateRemote(0, CFSTR("localMacro"));
    CFMessagePortRef localPort = CFMessagePortCreateLocal(nil,
                                 CFSTR("localGD"),
                                 Callback,
                                 NULL,
                                 NULL);
    CFRunLoopSourceRef runLoopSource = CFMessagePortCreateRunLoopSource(NULL,
                                       localPort,
                                       0);

    CFRunLoopAddSource(CFRunLoopGetCurrent(),
                       runLoopSource,
                       kCFRunLoopCommonModes);
    CFRunLoopRun();
    CFRelease(localPort);
}
// ending the *INTERPROCESS COMMUNICATION ZONE*.

void install(void) __attribute__((constructor));

void install() {
    base = baseAddress();

    checkpoints = [[NSMutableArray alloc] init];
    [checkpoints addObject:[NSNumber numberWithDouble:0.0]];
    int64_t bs = baseAddress()+0x78B60;
    void *(*original)(int64_t, double) = bs;

    scheduler_update = baseAddress()+0x2497a0;
    dispatch = baseAddress()+0xE8190;
    sharedManager = baseAddress()+0x1c2b30;
    pasteObjects = baseAddress()+0x232d0;
    basePush = baseAddress()+0xb9920;
    baseRelease = baseAddress()+0xb9a00;

    rd_route(original, routBoth, (void **)&og);
    rd_route(baseAddress()+0xa1b70, editorLock, (void**)&editorInit);
    rd_route(dispatch, dispatchAsm, (void**)&dispatch_og);
    rd_route(scheduler_update,speedhack, (void**)&scheduler_update_tramp);
    rd_route(baseAddress()+0x802d0, itsPaused, (void**)&pauseGame);
    rd_route(baseAddress()+0x225930, audioDie, (void**)playDeathEffect);

    rd_route(baseAddress()+0x7f9e0, practice_toggle, (void**)&practice_og);
    rd_route(baseAddress()+0x7ef60, practice_markCheckpoint, (void**)&practice_ogCheckpoint);
    rd_route(baseAddress()+0x7f870, practice_removeCheckpoint, (void**)&practice_ogRemove);
    rd_route(baseAddress()+0x7ab80, practice_playerDies, (void**)&practice_ogDies);


    rd_route(baseAddress()+0x185a20, inc, (void**)&increment);
    rd_route(baseAddress()+0x185b70, dec, (void**)&decrement);
    rd_route(baseAddress()+0x249690, mainLoop, (void**)&ogMain);
    rd_route(baseAddress()+0x6b500, newLevel, (void**)&createPlay);
    rd_route(baseAddress()+0x30790, editorKeyDown, (void**)&ogKeyDown);
    rd_route(baseAddress()+0x31310, editorKeyUp, (void**)&ogKeyUp);

    char data[] = {0x89, 0x88, 0x88, 0x3C};
    writeProcessMemory(baseAddress() + 0x2EC3DC, 4, &data);

    char play_jump[] = {0xE9, 0xE4, 0x4A, 0x27, 0x00, 0x90};
    writeProcessMemory(baseAddress() + 0x77900, 7, &play_jump);

    char set_016[] = {0xF3, 0x0F, 0x10, 0x05, 0xeb, 0xFF, 0xFF, 0xff,
                      0x90, 0x55, 0x48, 0x89, 0xE5, 0x41, 0x57, 0x41,
                      0x56, 0x41, 0x55, 0xe9, 0x09, 0xb5, 0xd8, 0xff};

    writeProcessMemory(baseAddress() + 0x2ec3e9, 24, &set_016);

    initIPC();
}