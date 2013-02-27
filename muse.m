// muse 0.3,
// the stupid command line mp3 player for osx.

// *muse may be freely distributed under the MIT license.*

// Frameworks: *Foundation*, *AVFoundation*
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

// Uses arc memory management.

// Uses [The Code Commandments](http://ironwolf.dangerousgames.com/blog/archives/913) best practices for Objective-C coding.

// ## Helpers declaration

// Define the usage description printed when executing the command
// with a help option (`[-h|--help]`).
#define USAGE @"usage: muse [-h|--help] <music files>"

// `output` is an helper function to display `NSString` on `stdout`.
void ouptut(NSString* string);

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
// The `initWithURL` initialize each properties using the asset instance.
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
// methods themselves.
@interface MusePlayer : NSObject

@property (assign, nonatomic) int track;
@property (strong, nonatomic) MuseAsset *current;
@property (copy, nonatomic) NSArray *assets;

+ (instancetype) playerWithResources:(NSArray*)resources
  error:(NSError **)error;
- (BOOL)prepareToPlayTrackAt:(int)track;
- (BOOL)isPlaying;
- (BOOL)play;
- (void)pause;
- (BOOL)previous;
- (BOOL)next;
@end

@interface MusePlayer() <AVAudioPlayerDelegate>
  @property (strong, nonatomic) AVAudioPlayer *player;

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
  // Assign current asset.
  self.track = track;
  self.current = self.assets[self.track];
  // Stop reading.
  [self.player stop];
  // Remove the reference to the delegate of the player.
  self.player.delegate = nil;
  // Instantiate a new player wuth the current url.
  self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.current.URL error:nil];
  // Set the delegate of the player to the instance of the MusePlayer.
  self.player.delegate = self;
  // Prepare the player to read the asset.
  return [self.player prepareToPlay];
}
// Wrapper around the `isPlaying` method of the player.
- (BOOL)isPlaying {
  return [self.player isPlaying];
}
// Wrapper around the `play` method of the player.
- (BOOL)play {
  return [self.player play];
}
// Wrapper around the `pause` method of the player.
- (void)pause {
  [self.player pause];
}
// Jump to previous song.
- (BOOL)previous {
  BOOL state;
  if(self.track != 0){
    state = [self prepareToPlayTrackAt: self.track - 1];
  }
  return state;
}
// Jump to next song.
- (BOOL)next {
  BOOL state;
  if(self.track != [self.assets count] - 1){
    state = [self prepareToPlayTrackAt: self.track + 1];
  }
  return state;
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
      ouptut(USAGE);
    } else if(length == 1){
    // Return an error if no arguments were given.
      NSError *error = [NSError museErrorInputFile];
      ouptut(error.description);
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
        // Return an error if the file is not a media file.
        ouptut(error.description);
        returnCode = error.code;
      } else {
        int elapsedTime, currentTime;
        while(1){
          // Read the file and quit once its done.
          [muse play];
          while([muse isPlaying]){
            currentTime = [muse.player currentTime];
            if(elapsedTime != currentTime){
              elapsedTime = currentTime;
              ouptut([muse.current labelForElapsedTime:elapsedTime]);
            }
          };
          if(![muse next]){
            break;
          }
        }
      }
    }
  }
  return returnCode;
}

// ## Helpers functions

// `ouput` prints a string to the `stdout` using the `UTF8String` property
// of the `NSString` argument.
void ouptut(NSString* string){
  fprintf(stdout, "\r%-72s", string.UTF8String);
  fflush(stdout);
}
// Copyright (c) 2012 Zaidin Amiot.
