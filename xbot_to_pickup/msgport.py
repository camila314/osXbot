import level
import time
import base64
import sys
def chunks(lst, n):
    for i in range(0, len(lst), n):
        yield lst[i:i + n]
if sys.platform=='darwin':
    from CoreFoundation import *

    class EditorTypes:
        PASTE = 1
        CLEAR = 2
        UNDO = 3
        REDO = 4
    class GlobalTypes:
        POPUP = 5
    class UnsuccessfulConnectionError(Exception):
        pass

    class GDCon(object):
        def __init__(self):
            self.reloadConn()

        def reloadConn(self):
            self.remote = CFMessagePortCreateRemote(None, CFStringCreateWithCString(None, b"314GDL", kCFStringEncodingUTF8))
            self.check()
        def check(self,err=True):
            if not self.remote or not CFMessagePortIsValid(self.remote):
                if err:
                    raise UnsuccessfulConnectionError("Connection unsuccessful")
                else:
                    return False
            else:
                return True
        def checkReload(self):
            if not self.check(err=False):
                self.reloadConn()

        def sendMessage(self, mid, content="none"):
            self.checkReload()
            toSend = CFDataCreate(None,content.encode(),len(content))
            CFMessagePortSendRequest(self.remote, mid, toSend, 1, 1, None, None)
        def pasteLevelObject(self,lvl, chunk=0):
            checkReload()
            if not chunk:
                chunk = len(lvl.blocks)
            for blks in chunks(lvl.blocks, chunk):
                sendMessage(MessageTypes.PASTE, ';'.join([str(x) for x in blks])+';')
        def popup(self, title, desc, button):
            stuff = (base64.b64encode(title.encode()).decode(), base64.b64encode(desc.encode()).decode(), base64.b64encode(button.encode()).decode())
            self.sendMessage(GlobalTypes.POPUP, ','.join(stuff))

    def uploadToGD(lvl):
        remote = CFMessagePortCreateRemote(None, CFStringCreateWithCString(None, b"314GDL", kCFStringEncodingUTF8))
        if remote and CFMessagePortIsValid(remote):
            for blks in chunks(lvl.blocks,30):
                blocks = ';'.join([str(x) for x in blks]) + ';'
                #print("pogs")
                toSend = CFDataCreate(None, blocks.encode(), len(blocks))
                CFMessagePortSendRequest(remote,
                                         0x1,
                                         toSend,
                                         1,
                                         10,
                                         None,
                                         None)
else:
    import win32pipe, win32file, pywintypes
    def pipe_client(pipe_send):
        print("pipe client")
        quit = False

        while not quit:
            try:
                handle = win32file.CreateFile(
                    '\\\\.\\pipe\\GDPipe',
                    win32file.GENERIC_READ | win32file.GENERIC_WRITE,
                    0,
                    None,
                    win32file.OPEN_EXISTING,
                    0,
                    None
                )
                win32file.WriteFile(handle, pipe_send)
            except:
                return
    def uploadToGD(lvl):
        try:
            handle = win32file.CreateFile(
                '\\\\.\\pipe\\GDPipe',
                win32file.GENERIC_READ | win32file.GENERIC_WRITE,
                0,
                None,
                win32file.OPEN_EXISTING,
                0,
                None
            )
            for blks in chunks(lvl.blocks,30):
                blocks = ';'.join([str(x) for x in blks]) + ';'
                win32file.WriteFile(handle, blocks.encode())
        except Exception as e:
            print("theres an error lmao")
            raise
if __name__ == '__main__':
    lvl = level.Level("test")
    lvl.addBlock(917, 50, 50)
    uploadToGD(lvl)