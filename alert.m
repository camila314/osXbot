#include <Cocoa/Cocoa.h>
//note i didnt make this code ok?
void getFileSaveName(void (*callback)(char*)) {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        NSSavePanel *panel = [NSSavePanel savePanel];
        NSString *fileName=@"untitled.xgd";
        [panel setMessage:@"Select location to save"]; // Message inside modal window
        [panel setExtensionHidden:YES];
        [panel setCanCreateDirectories:YES];
        [panel setNameFieldStringValue:fileName];
        [panel setTitle:@"Saving checkboard..."]; // Window title

        NSInteger result = [panel runModal];
        NSError *error = nil;

        if (result == NSModalResponseOK) {     
            ////////////////////////////////////////////
            NSString *path0 = [[panel URL] path];

            callback([path0 UTF8String]);
            ////////////////////////////////////////////

            if (error) {
                [NSApp presentError:error];
            }
        }
    });
}

void getPickupSaveName(void (*callback)(char*)) {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        NSSavePanel *panel = [NSSavePanel savePanel];
        NSString *fileName=@"untitled.pgd";
        [panel setMessage:@"Select location to save"]; // Message inside modal window
        [panel setExtensionHidden:YES];
        [panel setCanCreateDirectories:YES];
        [panel setNameFieldStringValue:fileName];
        [panel setTitle:@"Saving checkboard..."]; // Window title

        NSInteger result = [panel runModal];
        NSError *error = nil;

        if (result == NSModalResponseOK) {     
            ////////////////////////////////////////////
            NSString *path0 = [[panel URL] path];

            callback([path0 UTF8String]);
            ////////////////////////////////////////////

            if (error) {
                [NSApp presentError:error];
            }
        }
    });
}

void getFileOpenName(void (*callback)(char*)) {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        NSString *fileName=@"untitled.xgd";
        [panel setCanChooseFiles:YES];
        [panel setAllowsMultipleSelection:NO];
        [panel setCanChooseDirectories:NO];

        NSInteger result = [panel runModal];
        NSError *error = nil;

        if (result == NSModalResponseOK) {     
            ////////////////////////////////////////////
            NSString *path0 = [[panel URL] path];

            callback([path0 UTF8String]);
            ////////////////////////////////////////////

            if (error) {
                [NSApp presentError:error];
            }
        }
    });
}
void getSpeed(void (*callback)(float)) {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        NSAlert *alert = [NSAlert alertWithMessageText: @"Change Speed"
                                         defaultButton:@"OK"
                                       alternateButton:@"Cancel"
                                           otherButton:nil
                             informativeTextWithFormat:@""];

        NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
        [input setStringValue:@"1"];
        [input autorelease];
        [alert setAccessoryView:input];
        NSInteger button = [alert runModal];
        if (button == NSAlertDefaultReturn) {
            [input validateEditing];
            callback([input floatValue]);
        }
    });
}

void getFps(void (*callback)(float)) {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        NSAlert *alert = [NSAlert alertWithMessageText: @"Fps Recording"
                                         defaultButton:@"OK"
                                       alternateButton:@"Cancel"
                                           otherButton:nil
                             informativeTextWithFormat:@""];

        NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
        [input setStringValue:@"60.0"];
        [input autorelease];
        [alert setAccessoryView:input];
        NSInteger button = [alert runModal];
        if (button == NSAlertDefaultReturn) {
            [input validateEditing];
            callback([input floatValue]);
        }
    });
}
