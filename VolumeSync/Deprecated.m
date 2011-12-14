//
//  Deprecated.m
//  VolumeSync
//
//  Created by Nicolas Cormier on 14/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#if 0 
// AudioServices is the way to go but...
// Looks like virtualMasterVolumePropertyAddress isn't available on 10.5
// Let's use deprecated AudioCore instead :/



static const AudioObjectPropertyAddress defaultOutputDevicePropertyAddress = {
  .mScope = kAudioObjectPropertyScopeGlobal, 
  .mElement = kAudioObjectPropertyElementMaster,
  .mSelector = kAudioHardwarePropertyDefaultOutputDevice
};

static const AudioObjectPropertyAddress virtualMasterVolumePropertyAddress = {
  .mScope = kAudioDevicePropertyScopeOutput, 
  .mElement = kAudioObjectPropertyElementMaster,
  .mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume
};


static OSStatus rawOnVolumeChange(AudioObjectID inObjectID,
                                  UInt32 inNumberAddresses,
                                  const AudioObjectPropertyAddress* inAddresses,
                                  void* inClientData);


- (OSStatus) onVolumeChange
{
  AudioObjectPropertyAddress propertyAOPA = defaultOutputDevicePropertyAddress;
  if (!AudioHardwareServiceHasProperty(kAudioObjectSystemObject, &propertyAOPA))
  {
    NSLog(@"outputDeviceID: no default output device");
    return kUnknownType;
  }
	
  AudioDeviceID	outputDeviceID = kAudioObjectUnknown;
  UInt32 propertySize = sizeof(AudioDeviceID);
  OSStatus status = AudioHardwareServiceGetPropertyData(kAudioObjectSystemObject, &propertyAOPA, 0, NULL, &propertySize, &outputDeviceID);
  if (status != noErr)
  {
    NSLog(@"outputDeviceID: no default output device");
    return kUnknownType;
  }
  
  Float32 outputVolume;
  propertyAOPA = virtualMasterVolumePropertyAddress;  
  status = AudioHardwareServiceGetPropertyData(outputDeviceID, &propertyAOPA, 0, NULL, &propertySize, &outputVolume);
  if (status == noErr)
  {
    if (outputVolume != self.lastVolumeSet)
    {
      self.lastVolumeSet = outputVolume;
      [self setITunesVolume:outputVolume];
      NSLog(@"onVolumeChange: %f", outputVolume);
    }
  }
  else
  {
    NSLog(@"onVolumeChange: couldn't retrieve volume");
    return kUnknownType;
  }
  
  return noErr;
}

static OSStatus rawOnVolumeChange(AudioObjectID inObjectID,
                                  UInt32 inNumberAddresses,
                                  const AudioObjectPropertyAddress* inAddresses,
                                  void* inClientData)
{
  return [(VSAppDelegate*)inClientData onVolumeChange];
}

- (void) registerVolumeListener
{
  AudioObjectPropertyAddress propertyAOPA = defaultOutputDevicePropertyAddress;
  if (!AudioHardwareServiceHasProperty(kAudioObjectSystemObject, &propertyAOPA))
  {
    NSLog(@"outputDeviceID: no default output device");
    return;
  }
	
  AudioDeviceID	outputDeviceID = kAudioObjectUnknown;
  UInt32 propertySize = sizeof(AudioDeviceID);
  OSStatus status = AudioHardwareServiceGetPropertyData(kAudioObjectSystemObject, &propertyAOPA, 0, NULL, &propertySize, &outputDeviceID);
  if (status != noErr)
  {
    NSLog(@"outputDeviceID: no default output device");
    return;
  }
  
  propertyAOPA = virtualMasterVolumePropertyAddress;  
  status = AudioHardwareServiceAddPropertyListener(outputDeviceID, &propertyAOPA, rawOnVolumeChange, (void*)self);
  if (status != noErr)
  {
    NSLog(@"registerVolumeListener: could not register callback");
    return;
  }
}

#endif
