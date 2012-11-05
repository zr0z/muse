// muse 0.2,
// the stupid command line mp3 player for osx.

// *muse may be freely distributed under the MIT license.*

// Frameworks: *Foundation*, *AVFoundation*
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

// Uses arc memory management.

// ## Helpers declaration

// Define the usage description printed when executing the command
// with a help option (`[-h|--help]`).
#define USAGE @"usage: muse [-h|--help] <music file>"

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
NSString *const MPErrorInputFile = @"no input files.";
NSString *const MPErrorFileType = @"muse can't handle this file.";

// ### Category interface.
// Create a category on NSError for muse with two default class methods
// that correspond to the customs errors.
//
// The category add also an instance method which construct a description
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
// Instance method which construct a description based on the domain
// and the `NSLocalizedDescriptionKey`.
- (NSString *)description {
  return [NSString stringWithFormat:@"%@: error: %@", self.domain,
      self.localizedDescription];
}
@end

// ## MuseAsset Class

// ### Class interface.
// The `MuseAsset` Class use an instance of the `AVURLAsset` class
// to store some metadatas as properties of the instance.
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
@interface MuseAsset : NSObject {
  int _length;
  NSString* _title;
  NSString* _artist;
  NSString* _album;
  NSString* _label;
  NSURL* _URL;
}
@property (nonatomic, assign) int length;
@property (nonatomic, strong) NSString* artist;
@property (nonatomic, strong) NSString* album;
@property (nonatomic, strong) NSString* label;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSURL* URL;
+ (MuseAsset *)museAssetWithURL:(NSURL *)URL;
- (id)initWithURL:(NSURL *)URL;
- (NSString *)metadataForKey:(NSString*)key inArray:(NSArray*)metadata;
@end

// ### Class implementation.
@implementation MuseAsset
@synthesize length = _length;
@synthesize title = _title;
@synthesize artist = _artist;
@synthesize album = _album;
@synthesize label = _label;
@synthesize URL = _URL;
// Class methods that create a new instance using an URL.
+ (MuseAsset *)museAssetWithURL:(NSURL *)URL {
  return [[self alloc] initWithURL:URL];
}
// The `initWithURL` initialize each properties and the asset instance.
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
    self.artist = [self metadataForKey:@"artist" inArray:metadata];
    self.album = [self metadataForKey:@"albumName" inArray:metadata];
    // Transform the track `length` (in seconds) in a duration in minutes
    // and seconds, using a formated string.
    NSString* durationString = [NSString stringWithFormat:@"%02d:%02d",
      self.length / 60, self.length % 60];
    // Compose the label property using the other properties.
    self.label = [NSString stringWithFormat:@"%@ - %@ (%@)\n%@\n",
      self.title, self.artist, durationString, self.album];
  }
  return self;
}
// Parse a `NSArray` of `AVMetadataItem` using a `NSString`
// as the common key.
- (NSString *)metadataForKey:(NSString*)key inArray:(NSArray*)metadata {
  // Parse the metadata from the asset.
  NSArray* collected = [AVMetadataItem metadataItemsFromArray:metadata
    withKey:key keySpace: AVMetadataKeySpaceCommon];
  // Return the corresponding `NSString` if found or the `@"Unknown"` string.
  if([collected count] > 0){
      return ( (AVMetadataItem*) collected[0] ).stringValue;
  }
  return @"Unknown";
}
@end

// ## MusePlayer class
// ### Class interface.
@interface MusePlayer : NSObject {
  AVAudioPlayer *player;
  MuseAsset *currentSong;
}
@property (nonatomic, strong) MuseAsset *currentSong;
+ (id) playerWithURL:(NSURL*)URL error:(NSError **)error;
- (id) initWithURL:(NSURL*)URL error:(NSError **)error;
- (void)addAssetWithURL:(NSURL*)URL error:(NSError **)error;
- (BOOL)prepareToPlay;
- (BOOL)isPlaying;
- (BOOL)play;
@end
// ### Class implementation.
@implementation MusePlayer
@synthesize currentSong;
// Class methods that create a new instance using an `URL`.
+ (id) playerWithURL:(NSURL*)URL error:(NSError **)error {
  return [[self alloc] initWithURL:URL error:error];
}
// The `initWithURL:error:` method tests if the `URL` is reachable
// and add a new asset if no errors were raised.
- (id) initWithURL:(NSURL*)URL error:(NSError **)error {
  self = [super init];
  if(self && [URL checkResourceIsReachableAndReturnError:error]){
    [self addAssetWithURL:URL error:error];
    // Call the `prepareToPlay` method to set the player
    // and start the buffering of the asset.
    [self prepareToPlay];
  }
  return self;
}
// Create an asset using its url and a pointer to a `NSError` instance.
- (void)addAssetWithURL:(NSURL*)URL error:(NSError **)error {
  self.currentSong = [MuseAsset museAssetWithURL:URL];
  // Return an error if the file has no length.
  if(self.currentSong.length == 0){
    *error = [NSError museErrorFileType];
  }
}
// Create an audio player and prepare it to read the asset.
- (BOOL)prepareToPlay {
  player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.currentSong.URL error:nil];
  return [player prepareToPlay];
}
// Wrapper around the `isPlaying` method of the player.
- (BOOL)isPlaying {
  return [player isPlaying];
}
// Wrapper around the `play` method of the player.
- (BOOL)play {
  return [player play];
}
@end

// ## Main function
int main (int argc, const char * argv[]) {
    @autoreleasepool {
        // Get the arguments from the command line. **muse** accepts
        // either a help option (`[-h|--help]`) or a file.
        NSArray* arguments = [[NSProcessInfo processInfo] arguments];
        // Test if the help option (`[-h|--help]`) is present
        // in the arguments list.
        if([arguments containsObject:@"-h"]
          || [arguments containsObject:@"--help"]){
            ouptut(USAGE);
            return 0;
        }
        int length = [arguments count];
        // Return an error if no arguments were given.
        if(length == 1){
            ouptut([NSError museErrorInputFile].description);
            return 1;
        }
        // Get the url of the media file.
        // > TODO: add multiple file and directory handling.
        NSURL* url = [NSURL fileURLWithPath:arguments[1]];
        NSError* error = nil;
        MusePlayer* muse = [MusePlayer playerWithURL:url error:&error];
        // Return an error if the file is not a media file.
        if(error != nil){
          ouptut(error.description);
          return 1;
        }
        // Print the informations to the command line.
        ouptut(muse.currentSong.label);
        // Read the file and quit once its done.
        [muse play];
        while([muse isPlaying]);
    }
    return 0;
}

// ## Helpers functions

// `ouput` send the `UTF8String` message to the the `NSString`
// to print a string to the `stdout` using the `puts` function.
void ouptut(NSString* string){
  puts(string.UTF8String);
}
// Copyright (c) 2012 Zaidin Amiot.
