SOURCE = muse.m
TARGET = $(basename $(SOURCE))
CFLAGS = -ObjC -fobjc-arc
CC = clang
FRAMEWORK = -framework Foundation -framework AVFoundation
# subsitution for documentation
# TO_FIX
string=<span class=\"err\">@<\/span><span class=\"s\">
stringSub=<span class=\"s\">@
keyword=<span class=\"err\">@<\/span><span class=\"n\">
keywordSub=<span class=\"k\">@
punctuation=<span class=\"err\">@<\/span><span class=\"p\">
punctuationSub=<span class=\"p\">@

default: make

analyze:
	$(CC) $(CFLAGS) --analyze $(SOURCE)

make: $(SOURCE)
	@mkdir -p ./build
	$(CC) $(CFLAGS) $(FRAMEWORK) $(SOURCE) -o ./build/$(TARGET)

clean:
	@rm -rf ./build

documentation:
# Really need to write a docco for ObjC
ifeq ($(shell type docco >/dev/null && echo "YES"), YES)
	@cp muse.m muse.c
	@docco muse.c
	@rm muse.c
	@sed -i "" "s/muse.c/muse.m/g" docs/muse.html
	@sed -i "" "s/$(string)/$(stringSub)/g" docs/muse.html
	@sed -i "" "s/$(keyword)/$(keywordSub)/g" docs/muse.html
	@sed -i "" "s/$(punctuation)/$(punctuationSub)/g" docs/muse.html
	open -a safari docs/muse.html
endif

install:
	@mkdir -p /usr/local/bin
	cp ./build/$(TARGET) /usr/local/bin
