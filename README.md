muse
====

**muse** is a stupid command line mp3 player for osx. It is built in Objective-C on top of the `AVFoundation` framework and doesn't require any external libraries.

**muse** is released under the MIT license.

Currently, it is too dumb to read more than one file at a time, but you can read a whole directory by doing a loop on all the mp3 files:

	$ for tune in *.mp3; do muse $tune; done;

If you want to quit **muse** during play `Ctrl-C` is your best friend.

Installation
------------

You will need the XCode command line tools (with LLVM 4.0+).

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

	usage: muse [-h|--help] <music file>

Roadmap
-------

* Multiple song support.
* Directory support.
* JSON playlist.
* Commands (play/pause, previous, next, repeat…).

Changelog
---------

* 0.2, switch to a more classical Objective-C OOP structure.
* 0.1, initial release, quick and dirty Objective-C command line application.
