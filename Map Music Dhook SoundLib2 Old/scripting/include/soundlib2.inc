#if defined _soundlib2_ext_included
  #endinput
#endif
#define _soundlib2_ext_included

methodmap SoundFile < Handle
{
    /**
    * Opens a sound file.
    *
    * @note Sound files are closed with delete operator.
    *
    * @param file                File to open
    * @param valve if true, path is opened in Valve Filesystem.
    * @return                    A Handle to the sound file, null on open error.
    */
    public native SoundFile(const char[] path, bool value_file_system = false);
    
    /**
    * Gets the length of the sound file in seconds
    *
    * @return                T     The song length in seconds
    */
	property int Length
    {
        // getter
        public native get();
    }
    
    /**
    * Gets the length of the sound file in milliseconds
    *
    * @return                The song length in milliseconds
    */
	property int LengthInMilliseconds
    {
        // getter
        public native get();
    }
    
    /**
    * Get the Bit rate of sound (kbps)
    *
    * @return                sound bitrate (int)
    */
	property int BitRate
    {
        // getter
        public native get();
    }

    /**
    * Get the Sampling rate of sound (hz)
    *
    * @return                sampling rate (int)
    */
	property int SamplingRate
    {
        // getter
        public native get();
    }
};

/**
 * Opens a sound file.
 *
 * @note Sound files are closed with delete operator.
 *
 * @param file                File to open
 * @param valve if true, path is opened in Valve Filesystem.
 * @return                    A Handle to the sound file, null on open error.
 */
native SoundFile OpenSoundFile(const char[] path, bool valve=false);

/**
 * Gets the length of the sound file in seconds
 *
 * @param hndl            Handle to the sound file.
 * @return                T     The song length in seconds
 */
native int GetSoundLength(SoundFile soundfile);

/**
 * Gets the length of the sound file in milliseconds
 *
 * @param hndl            Handle to the sound file.
 * @return                The song length in milliseconds
 */
native int GetSoundLengthInMilliseconds(SoundFile soundfile);

/**
 * Get the Bit rate of sound (kbps)
 *
 * @param hndl            Handle to the sound file
 * @return                sound bitrate (int)
 */
native int GetSoundBitrate(SoundFile soundfile);

/**
 * Get the Sampling rate of sound (hz)
 *
 * @param hndl            Handle to the sound file
 * @return                sampling rate (int)
 */
native int GetSoundSamplingRate(SoundFile soundfile);

/**
 * Do not edit below this line!
 */
public Extension __ext_soundlib2 = 
{
	name = "SoundLib2",
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
	MarkNativeAsOptional("SoundFile.SoundFile");
	MarkNativeAsOptional("SoundFile.Length.get");
	MarkNativeAsOptional("SoundFile.LengthInMilliseconds.get");
	MarkNativeAsOptional("SoundFile.Bitrate.get");
	MarkNativeAsOptional("SoundFile.SamplingRate.get");

	MarkNativeAsOptional("OpenSoundFile");
	MarkNativeAsOptional("GetSoundLength");
	MarkNativeAsOptional("GetSoundLengthInMilliseconds");
	MarkNativeAsOptional("GetSoundBitrate");
	MarkNativeAsOptional("GetSoundSamplingRate");
}
#endif