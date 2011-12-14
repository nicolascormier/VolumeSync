//
//  VSAppDelegate.m
//  VolumeSync
//
//  Created by Nicolas Cormier on 11/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "VSAppDelegate.h"
#import "iTunes.h"

#include <AudioToolbox/AudioServices.h>
#include <CoreAudio/CoreAudio.h>


@interface VSAppDelegate ()<NSMenuDelegate>

@property (nonatomic, assign) float lastVolumeSet;
@property (nonatomic, retain) iTunesApplication* iTunes;
@property (nonatomic, assign) AudioDeviceID outputDevice;
@property (nonatomic, retain) NSStatusItem* statusItem;

@end


@implementation VSAppDelegate

@synthesize lastVolumeSet, iTunes, outputDevice, statusItem;

- (id) init
{
  if (self = [super init])
  {
    self.lastVolumeSet = -1;
  }
  return self;
}

- (void) dealloc
{
  self.iTunes = nil;
  self.statusItem = nil;
  [super dealloc];
}

- (void) setITunesVolume:(Float32)volume
{
  if ([self.iTunes isRunning])
  {
    int iTunesVolume = volume*100;
    [iTunes setSoundVolume:iTunesVolume];
  }
}

- (BOOL) openDefaultOutputDevice
{
	AudioDeviceID device;

  UInt32 size = sizeof(device);
	OSStatus status = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice, &size, &device);
	if (status != noErr) return NO;
  
  self.outputDevice = device;
  return YES;
}

- (OSStatus) onVolumeChange
{
	OSStatus status;
  UInt32 size;
  
  Float32 volume;
	size = sizeof(volume);
	status = AudioDeviceGetProperty(self.outputDevice, 0, 0, kAudioDevicePropertyVolumeScalar, &size, &volume);
	if (status == noErr) return volume;
  
	UInt32 channels[2];
	size = sizeof(channels);
	status = AudioDeviceGetProperty(self.outputDevice, 0, 0,kAudioDevicePropertyPreferredChannelsForStereo, &size,&channels);
	if (status != noErr)
  {
    NSLog(@"AudioDeviceGetProperty: could not get channels");
    return status;
  }
	
	Float32 volumeChannel1;
	size = sizeof(volumeChannel1);
	status = AudioDeviceGetProperty(self.outputDevice, channels[0], 0, kAudioDevicePropertyVolumeScalar, &size, &volumeChannel1);
	if (status != noErr)
  {
    NSLog(@"AudioDeviceGetProperty: could not get channels");
    return status;
  }

  Float32 volumeChannel2;
	size = sizeof(volumeChannel2);
  status = AudioDeviceGetProperty(self.outputDevice, channels[1], 0, kAudioDevicePropertyVolumeScalar, &size, &volumeChannel2);
	if (status != noErr)
  {
    NSLog(@"AudioDeviceGetProperty: could not get channels");
    return status;
  }
	
	volume = (volumeChannel1 + volumeChannel2)/2.;

  if (volume != self.lastVolumeSet)
  {
    self.lastVolumeSet = volume;
    [self setITunesVolume:volume];
  }
  
  return noErr;
}

static OSStatus rawOnVolumeChange(AudioDeviceID device, UInt32 inChannel, Boolean isInput, AudioDevicePropertyID inPropertyID, void* inClientData)
{
  return [(VSAppDelegate*)inClientData onVolumeChange];
}

- (void) registerVolumeListener
{
	OSStatus status;
	
  status = AudioDeviceAddPropertyListener(self.outputDevice, 0, 0, kAudioDevicePropertyVolumeScalar, rawOnVolumeChange, self); 
	if (status != noErr)
  {
		NSLog(@"AudioDeviceAddPropertyListener: could not register master... try channels");
	}
	
  UInt32 channels[2];
	UInt32 size = sizeof(channels);
	status = AudioDeviceGetProperty(self.outputDevice, 0, 0,kAudioDevicePropertyPreferredChannelsForStereo, &size,&channels);
	if (status != noErr)
  {
		NSLog(@"AudioDeviceGetProperty: could not fetch channels");
		return;
	}
	
	status = AudioDeviceAddPropertyListener(self.outputDevice, channels[0], 0, kAudioDevicePropertyVolumeScalar, rawOnVolumeChange, self); 
  if (status != noErr)
  {
		NSLog(@"AudioDeviceAddPropertyListener: could not listen on channel 0");
		return;
	}

	status = AudioDeviceAddPropertyListener(self.outputDevice, channels[1], 0, kAudioDevicePropertyVolumeScalar, rawOnVolumeChange, self); 
	if (status != noErr)
  {
		NSLog(@"AudioDeviceAddPropertyListener: could not listen on channel 1");
		return;
	}
}

- (void) onQuitPushed
{
  [NSApp terminate:self];
}

- (void) setupStatusIcon
{
  self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
  self.statusItem.image = [NSImage imageNamed:@"65-note.png"];
  self.statusItem.alternateImage = [NSImage imageNamed:@"65-note-inv.png"];
  NSMenuItem* quitItem = [[[NSMenuItem alloc] initWithTitle:@"Quit VolumeSync" action:@selector(onQuitPushed) keyEquivalent:@""] autorelease];
  NSMenu* menu = [[[NSMenu alloc] initWithTitle:@"statusBarMenuTitle"] autorelease];
  menu.delegate = self;
  [menu addItem:quitItem];
  [self.statusItem setMenu:menu];
  [self.statusItem setHighlightMode:YES];
}

- (void) applicationDidFinishLaunching:(NSNotification*)aNotification
{
  [self setupStatusIcon];
  
  self.iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
  
  if ([self openDefaultOutputDevice])
  {
    [self registerVolumeListener];
    [self onVolumeChange];
  }
}

@end
