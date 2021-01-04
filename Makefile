run: loader.dylib
	sudo osxinj "Geometry Dash" loader.dylib
boost:
	gcc boost.c -dynamiclib -o loader.dylib
loader.dylib: MKit.a
	nasm -fmacho64  -i/users/jakrillis/asminclude disp.asm
	gcc disp.o combine.m MKit.a alert.m -dynamiclib -g -o loader.dylib -framework ApplicationServices -framework Cocoa -framework AVFoundation -O0 -Wno-int-conversion -Wno-incompatible-pointer-types

MKit.a: rd_route.o MKit.o
	ar rcs $@ $^ $<

rd_route.o: MKit/rd_route.c MKit/rd_route.h
	gcc -c -o $@ $<

MKit.o: MKit/MKit.c MKit/MKit.h
	gcc -c -o $@ $<

clean:
	rm *.o loader.dylib
restart: loader.dylib
	pkill Geometry Dash || echo 0
	open -a GDCracked
push:
	git add .
	git rm --cached loader.dylib || echo 0
	git rm --cached *.o || echo 0
	git rm -r --cached osXbot.zip osXbot.app *.dSYM

	git commit -m "$(shell bash -c 'read -p "Message: " pwd; echo $$pwd')"
	git push