run: loader.dylib
	sudo osxinj "Geometry Dash" loader.dylib
boost:
	gcc boost.c -dynamiclib -o loader.dylib
loader.dylib:
	nasm -fmacho64 _unused.asm
	gcc _unused.o combine.m -lroute alert.m -dynamiclib -o loader.dylib -framework ApplicationServices -framework Cocoa -Ofast
clean:
	rm loader.dylib
	rm *.o
restart: loader.dylib
	pkill Geometry Dash || echo 0
	open -a GDCracked
push:
	git add .
	read commessage
	git commit -m $commessage
	git push