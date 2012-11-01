/*
*
* muse 0.1
* the stupid command line mp3 player for osx.
*
* Copyright (c) 2012 Zaidin Amiot
* muse may be freely distributed under the MIT license.
*
* Frameworks: Foundation, AVFoundation
* Uses arc memory management.
*
*/

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

// Functions
NSString* getMetadataForKey(NSString* key, NSArray* metadata);

int main (int argc, const char * argv[]) {
    @autoreleasepool {
        // Get the arguments from the command line. **muse** accepts
        // either a help option `[-h|--help]` or a file.
        NSArray* arguments = [[NSProcessInfo processInfo] arguments];
        int length = [arguments count];
        // Return an error if no arguments were given.
        if(length == 1){
            printf("muse: error: no input files.\n");
            return 1;
        }
        // Test if first argument is the help option.
        // > TODO: add real opt parsing.
        NSString* argument = arguments[1];
        if(length == 2 && ([argument isEqualToString:@"-h"]
          || [argument isEqualToString:@"--help"])){
            printf("usage: muse [-h|--help] <music file>\n");
            return 0;
        }
        // Get the url of the media file and create an asset.
        // > TODO: add multiple file and directory handling.
        NSURL* url = [NSURL fileURLWithPath:argument isDirectory:false];
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
        // Compute track length.
        int trackLength = asset.duration.value / asset.duration.timescale;
        // Return an error if the file is not a media file.
        if(trackLength == 0){
            printf("muse: error: muse can't handle this file.\n");
            return 1;
        }
        // Get the metadata from the file.
        NSArray* metadata = asset.commonMetadata;
        // Parse the `title`, `artist` and `albumName` tags
        NSString* title = getMetadataForKey(@"title", metadata);
        NSString* artist = getMetadataForKey(@"artist", metadata);
        NSString* album = getMetadataForKey(@"albumName", metadata);
        // Print the informations to the command line.
        printf("%s - %s (%02d:%02d)\n%s\n\n", title.UTF8String,
          artist.UTF8String, trackLength / 60, trackLength % 60, album.UTF8String);
        // Create an audio player and prepare it to read the file.
        AVAudioPlayer* muse = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        [muse prepareToPlay];
        // Read the file and quit once its done.
        [muse play];
        while([muse isPlaying]);
    }
    return 0;
}

// Parse a `NSArray` of `AVMetadataItem` using a `NSString`
// as the common key. Return a `NSString`.
NSString* getMetadataForKey(NSString* key, NSArray* metadata){
    NSArray* collected = [AVMetadataItem metadataItemsFromArray:metadata
        withKey:key keySpace: AVMetadataKeySpaceCommon];
    if([collected count] > 0){
        return ( (AVMetadataItem*) collected[0] ).stringValue;
    }
    return @"Unknown";
}
