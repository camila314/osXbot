run: loader.dylib
	sudo osxinj "Geometry Dash" loader.dylib
boost:
	gcc boost.c -dynamiclib -o loader.dylib
loader.dylib:
	nasm -fmacho64 disp.asm
	gcc disp.o combine.m -lMKit alert.m -dynamiclib -o loader.dylib -framework ApplicationServices -framework Cocoa -Ofast
clean:
	rm loader.dylib
	rm *.o
restart: loader.dylib
	pkill Geometry Dash || echo 0
	open -a GDCracked
push:
	git add .
	git commit -m "$(shell bash -c 'read -p "Message: " pwd; echo $$pwd')"
	git push