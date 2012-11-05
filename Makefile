SOURCE = muse.m
TARGET = $(basename $(SOURCE))
CFLAGS = -ObjC -fobjc-arc
CC = clang
FRAMEWORK = -framework Foundation -framework AVFoundation

default: make

analyze:
	$(CC) $(CFLAGS) --analyze $(SOURCE)

make: $(SOURCE)
	mkdir -p ./build
	$(CC) $(CFLAGS) $(FRAMEWORK) $(SOURCE) -o ./build/$(TARGET)

clean:
	rm -rf ./build

documentation:
	# Really need to write a docco for ObjC
	# TO_FIX: Must check if docco is installed
	cp muse.m muse.c
	docco muse.c
	rm muse.c
	sed -i "" "s/muse.c/muse.m/g" docs/muse.html
	open -a safari docs/muse.html

install:
	mkdir -p /usr/local/bin
	cp ./build/$(TARGET) /usr/local/bin
