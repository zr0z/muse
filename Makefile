SOURCE = muse.m
TARGET = $(basename $(SOURCE))
C = clang -ObjC -fobjc-arc
FRAMEWORK = -framework Foundation -framework AVFoundation

default: make

make: $(SOURCE)
	mkdir -p ./build
	$(C) $(FRAMEWORK) $(SOURCE) -o ./build/$(TARGET)

clean:
	rm -rf ./build

install:
	mkdir -p /usr/local/bin
	cp ./build/$(TARGET) /usr/local/bin
