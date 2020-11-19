run: loader.dylib
	sudo osxinj "Geometry Dash" loader.dylib
boost:
	gcc boost.c -dynamiclib -o loader.dylib
loader.dylib:
	nasm -fmacho64  -i/users/jakrillis/asminclude disp.asm
	gcc disp.o combine.m -lMKit alert.m -dynamiclib -g -o loader.dylib -framework ApplicationServices -framework Cocoa -O0 -Wno-int-conversion -Wno-incompatible-pointer-types
clean:
	rm loader.dylib
	rm *.o
restart: loader.dylib
	pkill Geometry Dash || echo 0
	open -a GDCracked
push:
	git add .
	git rm --cached loader.dylib || echo 0
	git rm --cached *.o || echo 0
	git rm -r --cached osXbot.zip osXbot.app

	git commit -m "$(shell bash -c 'read -p "Message: " pwd; echo $$pwd')"
	git push