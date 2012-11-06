muse
====

**muse** is a stupid command line mp3 player for osx. It is built in Objective-C on top of the `AVFoundation` framework and doesn't require any external libraries.

**muse** is released under the MIT license.

Since version 0.3, **muse** is a bit smarter and you can read multiple mp3 files using a wildcard (such as `*.mp3`) on the command line or passing several files as arguments.

If you want to quit **muse** during play `Ctrl-C` is your best friend.

Installation
------------

You will need Lion or Mountain Lion and the latest XCode command line tools (with LLVM 4.0+).

### One-line install

    curl -L https://raw.github.com/zr0z/muse/master/muse-install.sh | sh

### Building from git

Grab a copy of the source code:

	git clone https://github.com/zr0z/muse.git

Build and install it:

	make && make install

**muse** will be installed in your `/usr/local/bin`.  
Depending on your permissions, you may have to use `sudo make install` to finalize the installation.

Usage
-----

	usage: muse [-h|--help] <music files>

Roadmap
-------

* Directory support.
* JSON playlist.
* Commands (play/pause, previous, next, repeat…).

Changelog
---------

* 0.3, Multiple songs support, rewrite code according to [The Code Commandments](http://ironwolf.dangerousgames.com/blog/archives/913) best practices for Objective-C coding.
* 0.2, switch to a more classical Objective-C OOP structure.
* 0.1, initial release, quick and dirty Objective-C command line application.
