#if defined _soundlib2_ext_included
    #endinput
#endif
#define _soundlib2_ext_included

native Handle OpenSoundFile(const char[] path, bool valve=false);
native int GetSoundLength(Handle soundfile);
native int GetSoundLengthInMilliseconds(Handle soundfile);
native int GetSoundBitrate(Handle soundfile);
native int GetSoundSamplingRate(Handle soundfile);

/**
 * Do not edit below this line!
 */
public Extension __ext_soundlib2 = 
{
    name = "soundlib2",
    file = "soundlib2.ext",
#if defined AUTOLOAD_EXTENSIONS
    autoload = 1,
#else
    autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_EXTENSIONS
public void __ext_soundlib2_SetNTVOptional()
{
	MarkNativeAsOptional("OpenSoundFile");
	MarkNativeAsOptional("GetSoundLength");
	MarkNativeAsOptional("GetSoundLengthInMilliseconds");
	MarkNativeAsOptional("GetSoundBitrate");
	MarkNativeAsOptional("GetSoundSamplingRate");
}
#endif