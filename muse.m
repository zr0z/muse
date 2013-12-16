// muse 0.4,
// the stupid command line mp3 player for osx.

// *muse may be freely distributed under the MIT license.*

// Frameworks: *Foundation*, *AVFoundation*, *ncurses*
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#include <curses.h>
// Uses arc memory management.

// Uses [The Code Commandments](http://ironwolf.dangerousgames.com/blog/archives/913) best practices for Objective-C coding.

// ## Helpers declaration

// Define the usage description printed when executing the command
// with a help option (`[-h|--help]`).
#define USAGE @"usage: muse [-h|--help] <music files>"

// `output` is an helper function to display `NSString` on `stdout`.
void output(NSString* string);

// ## Custom Errors

// Define custom error domain and descriptions as `NSString` constants.
//
// The error domain is `muse`; the customs errors are:
//
// * `MPErrorInputFile` when no file is given in arguments.
// * `MPErrorFileType` when the file can't be read.
NSString *const MPErrorDomain = @"muse";
NSString *const MPErrorInputFile = @"no input files.\n";
NSString *const MPErrorFileType = @"muse can't handle this file.\n";

// ### Category interface.
// Create a category on NSError for muse with two default class methods
// that correspond to the customs errors.
//
// The category adds also an instance method which constructs a description
// based on the error domain and the error `NSLocalizedDescriptionKey`.
@interface NSError(MusePlayer)
+ (NSError *)museErrorInputFile;
+ (NSError *)museErrorFileType;
- (NSString *)description;
@end

// ### Category implementation.
@implementation NSError(MusePlayer)
// Return a `NSError` using a `MPErrorInputFile` localized description.
+ (NSError *)museErrorInputFile {
  NSDictionary *info = @{NSLocalizedDescriptionKey: MPErrorInputFile};
  return [self errorWithDomain:MPErrorDomain code:1 userInfo:info];
}
// Return a `NSError` using a `MPErrorFileType` localized description.
+ (NSError *)museErrorFileType {
  NSDictionary *info = @{NSLocalizedDescriptionKey: MPErrorFileType};
  return [self errorWithDomain:MPErrorDomain code:2 userInfo:info];
}
// Instance method which constructs a description based on the domain
// and the `NSLocalizedDescriptionKey`.
- (NSString *)description {
  return [NSString stringWithFormat:@"%@: error: %@", self.domain,
    self.localizedDescription];
}
@end

// ## MuseAsset class

// ### Class interface.

// The `MuseAsset` class uses an instance of the `AVURLAsset` class
// to extract some metadatas and store them as properties of the instance.
//
// The main property is the `URL` used to create the `AVURLAsset`.
//
// The metadatas properties are:
//
// * `length`, duration of the asset in seconds,
// * `artist`, name of the artist if present in the `commonMetadata`,
// * `album`, name of the album if present in the `commonMetadata`,
// * `label`, label constructed from the other properties,
// * `title`, title of the asset if present in the `commonMetadata`.
@interface MuseAsset : NSObject
@property (assign, nonatomic) int length;
@property (strong, nonatomic) NSString* artist;
@property (strong, nonatomic) NSString* album;
@property (strong, nonatomic) NSString* title;
@property (strong, nonatomic) NSURL* URL;

+ (instancetype)museAssetWithURL:(NSURL *)URL;
- (NSString*)labelForElapsedTime:(int)time;
@end

@interface MuseAsset()
- (id)initWithURL:(NSURL *)URL;
- (NSString *)metadataForKey:(NSString*)key inArray:(NSArray*)metadata;
@end

// ### Class implementation.
@implementation MuseAsset

// Class method that create a new instance using an URL.
+ (instancetype)museAssetWithURL:(NSURL *)URL {
  return [[self alloc] initWithURL:URL];
}
// The `initWithURL` method initialize each properties
// using the asset instance.
- (id)initWithURL:(NSURL *)URL {
  self = [super init];
  // Create the `AVURLAsset` instance using the `URL`.
  AVURLAsset* asset = [AVURLAsset URLAssetWithURL:URL options:nil];
  if(self && asset){
    // Assign `MuseAsset` url.
    self.URL = URL;
    // Calculate the track `length` in seconds using the `value`
    // and the `timescale` of the `duration` metadata.
    self.length = asset.duration.value / asset.duration.timescale;
    // initialize the metadata array using the `commonMetadata` property
    // of the asset.
    NSArray* metadata = asset.commonMetadata;
    // Extract the other properties from the metadata array
    // calling the `metadataForKey:inArray:` method.
    self.title = [self metadataForKey:@"title" inArray:metadata];
    if(self.title == nil){
      self.title = [[self.URL lastPathComponent] stringByDeletingPathExtension];
    }
    self.artist = [self metadataForKey:@"artist" inArray:metadata];
    if(self.artist == nil){
      self.artist = @"Unknown";
    }
    self.album = [self metadataForKey:@"albumName" inArray:metadata];
  }
  return self;
}
- (NSString*)labelForElapsedTime:(int)elapsedTime {
  // Transform the track `length` (in seconds) in a duration in minutes
  // and seconds, using a formated string.
  NSString* format = @"%02d:%02d";
  NSString* durationString = [NSString stringWithFormat:format,
    self.length / 60, self.length % 60];
  // Transformed the elapsed time using the same format.
  NSString* elapsedString = [NSString stringWithFormat:format,
    elapsedTime / 60, elapsedTime % 60];
  // Compose the label property using the other properties.
  format = @"%@ (%@/%@) - %@";
  NSString* label = [NSString stringWithFormat: format,
    self.title, elapsedString, durationString, self.artist];
  if(self.album != nil){
    label = [label stringByAppendingFormat:@" (%@)", self.album];
  }
  return label;
}
// Parse a `NSArray` of `AVMetadataItem` using a `NSString`
// as the common key.
- (NSString *)metadataForKey:(NSString*)key inArray:(NSArray*)metadata {
  // Parse the metadata from the asset.
  NSArray* collected = [AVMetadataItem metadataItemsFromArray:metadata
    withKey:key keySpace: AVMetadataKeySpaceCommon];
  NSString* value;
  // Return the corresponding `NSString` if found.
  if([collected count] > 0){
      value = ( (AVMetadataItem*) collected[0] ).stringValue;
  }
  return value;
}
@end

// ## MusePlayer class
// ### Class interface.

// The `MusePlayer` class is responsible for managing the list of assets
// and controling the `AVAudioPlayer` instance.

// It implements several methods that are just wrappers around the player
// methods.
@interface MusePlayer : NSObject

@property (strong, nonatomic) MuseAsset *current;
@property (copy, nonatomic) NSArray *assets;

+ (instancetype) playerWithResources:(NSArray*)resources
  error:(NSError **)error;
- (BOOL)isPlaying;
- (void)play;
- (void)pause;
- (void)toggle;
- (void)stop;
- (BOOL)previous;
- (BOOL)next;
- (int)currentTrack;
- (int)totalTracks;
@end

// Let's use a `category` to obfuscate our private properties
// and methods
@interface MusePlayer() <AVAudioPlayerDelegate>
  @property (assign, nonatomic) int track;
  @property (assign, nonatomic) BOOL isPaused;
  @property (strong, nonatomic) AVAudioPlayer *player;

- (BOOL)prepareToPlayTrackAt:(int)track;
- (BOOL)playTrackAt:(int)track;
- (id) initWithResources:(NSArray*)resources error:(NSError **)error;
- (void)addAssetWithURL:(NSURL*)URL error:(NSError **)error;
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player
    error:(NSError *)error;
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player
    successfully:(BOOL)flag;
@end

// ### Class implementation.
@implementation MusePlayer

// Factory class method that create a new instance using an array
// of resources.
+ (instancetype) playerWithResources:(NSArray*)resources
  error:(NSError **)error {
  return [[self alloc] initWithResources:resources error:error];
}
// The `initWithResources:error:` method create a NSURL for each resources
// and add a new asset for each reachable `URL`.
- (id) initWithResources:(NSArray*)resources error:(NSError **)error {
  if(self = [super init]){
    self.assets = @[];
    for (NSString* path in resources) {
      NSURL* url = [NSURL fileURLWithPath:path isDirectory:NO];
      if([url checkResourceIsReachableAndReturnError:error]){
        [self addAssetWithURL:url error:error];
      }
    }
    if([self.assets count] > 0){
      // TO_FIX find a better way to log benign errors.
      error = nil;

      // Call the `prepareToPlayTrackAt:` method to set the player
      // and start the buffering of the asset.
      [self prepareToPlayTrackAt:0];
    }
  }
  return self;
}
// Create an asset using its url and a pointer to a `NSError` instance.
- (void)addAssetWithURL:(NSURL*)URL error:(NSError **)error {
  MuseAsset *asset = [MuseAsset museAssetWithURL:URL];
  // Return an error if the file has no length.
  if(asset.length == 0){
    *error = [NSError museErrorFileType];
  } else {
    self.assets = [self.assets arrayByAddingObject: asset];
  }
}
// Create an audio player and prepare it to read the asset.
- (BOOL)prepareToPlayTrackAt:(int)track {
  // We start with a basic check to avoid range errors.
  if(track < 0 || track > [self.assets count] - 1){
    return NO;
  }
  // Assign the current asset and initialize a few properties.
  self.track = track;
  self.current = self.assets[self.track];
  self.isPaused = NO;
  // Stop reading any asset that could be already loaded.
  [self.player stop];
  // Remove the reference to the delegate of the player.
  self.player.delegate = nil;
  // Instantiate a new player with the current url.
  self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.current.URL error:nil];
  // Set the delegate of the player to the instance of the MusePlayer.
  self.player.delegate = self;
  // Prepare the player to read the asset.
  return [self.player prepareToPlay];
}
// Play the track at the specified index.
- (BOOL)playTrackAt:(int)track {
  if([self prepareToPlayTrackAt:track]){
    [self play];
    return YES;
  }
  return NO;
}
// Wrapper around the `isPlaying` method of the player.
// We also return true if the music is just paused.
- (BOOL)isPlaying {
  return [self.player isPlaying] || self.isPaused;
}
// Wrapper around the `play` method of the player.
- (void)play {
  [self.player play];
  self.isPaused = NO;
}
// Wrapper around the `pause` method of the player.
- (void)pause {
  [self.player pause];
  self.isPaused = YES;
}
// Toggle between `play` and `pause` state.
- (void)toggle {
  if(self.isPaused){
    [self play];
  } else {
    [self pause];
  }
}
// Wrapper around the `stop` method of the player.
- (void)stop {
  [self.player stop];
}
// Jump to the previous song.
- (BOOL)previous {
  return [self playTrackAt: self.track - 1];
}
// Jump to the next song.
- (BOOL)next {
  return [self playTrackAt: self.track + 1];
}
// Return the current track.
- (int)currentTrack {
  return self.track;
}
// Return the total number of tracks.
- (int)totalTracks {
  return [self.assets count];
}
// Methods required by the `AVAudioPlayerDelegate` protocol.
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player
  error:(NSError *)error {}
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player
  successfully:(BOOL)flag {}
@end

// ## Main function
int main (int argc, const char * argv[]) {
  int returnCode = 0;
  @autoreleasepool {
    // Get the arguments from the command line. **muse** accepts
    // either a help option (`[-h|--help]`) or a file.
    NSArray* arguments = [[NSProcessInfo processInfo] arguments];
    int length = [arguments count];
    // Test if the help option (`[-h|--help]`) is present
    // in the arguments list.
    if([arguments containsObject:@"-h"]
      || [arguments containsObject:@"--help"]){
      output(USAGE);
    } else if(length == 1){
    // Return an error if no arguments were given.
      NSError *error = [NSError museErrorInputFile];
      output(error.description);
      returnCode = error.code;
    } else {
      // Create a range and derive a new array from the arguments,
      // excluding the executable name.
      NSRange range;
      range.location = 1;
      range.length = length - 1;
      NSArray* resources = [arguments subarrayWithRange:range];
      // Initialise the `MusePlayer` instance with the resources.
      // TODO: add directory handling.
      NSError* error = nil;
      MusePlayer* muse = [MusePlayer playerWithResources:resources
        error:&error];

      if(error != nil){
        //  Exit with an error if the first file is not a media file.
        output(error.description);
        returnCode = error.code;
      } else {
        // These variables will store the current and elapsed time.
        // The screen will be redrawn only if the values are not equals.
        int elapsedTime, currentTime;

        // `control` will hold the character pressed, if any.
        char control;

        // The status variable for the main application loop,
        // terminate the app if set to `NO`.
        BOOL isPlaying = YES;

        // Initialise `ncurses` with the usual functions.
        // First, initialise the screen.
        initscr();
        // Set a default timeout in order to avoid blocking the reading
        // loop while calling the `getch` function.
        timeout(100);
        // Then specify that we want to get characters as soon as they
        // are typed.
        cbreak();
        // But we don't want any visual feedback.
        noecho();

        // Start reading the assets.
        [muse play];
        // Let's start the main application loop.
        while(isPlaying){
          // Listen to the key pressed while the music is playing.
          while((control = getch()) && [muse isPlaying]){
            currentTime = [muse.player currentTime];
            // We redraw the screen only every seconds.
            if(elapsedTime != currentTime){
              elapsedTime = currentTime;
              // First we construct the label that will be displayed.
              NSString* string = [muse.current labelForElapsedTime:elapsedTime];
              string = [NSString stringWithFormat:@"%d/%d %@",
                                 [muse currentTrack] + 1,
                                 [muse totalTracks],
                                 string];
              // Then we clear the screen.
              erase();
              // And finaly we use a `ncurses` function to print
              // the current track informations and the time elapsed.
              mvprintw(0, 0, "%s", string.UTF8String);
            }

            // Let's use `wasd` to control the player.
            if(control == 'w'){
              // `w` quit the player.
              // First stop reading the current track.
              [muse stop];
              // Then set `isPlaying` to `NO` to exit the application loop.
              isPlaying = NO;
              // And finally exit the current reading loop.
              break;
            } else if(control == 'a'){
              // `a` play previous track.
              [muse previous];
              // Set current time to a negative number in order
              // to force next redraw.
              currentTime = -1;
            } else if(control == 's'){
              // `s` toggle pause/play.
              [muse toggle];
            } else if(control == 'd'){
              // `d` play next track.
              [muse next];
              // Set current time to a negative number in order
              // to force next redraw.
              currentTime = -1;
            }
          }
          // If we don't have any tracks in the queue, we stop the
          // application loop.
          if(![muse next]){
            isPlaying = NO;
          }
        }
      }
    }
  }
  // Let's be gentle and clean the screen before exiting.
  erase();
  endwin();
  return returnCode;
}

// ## Helpers functions

// `ouput` prints a string to the `stdout` using the `UTF8String` property
// of the `NSString` argument.
void output(NSString* string){
  fprintf(stdout, "\r%-72s", string.UTF8String);
  fflush(stdout);
}
// Copyright (c) 2012 Zaidin Amiot.
