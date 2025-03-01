#!/usr/bin/env bash
# Creates and installs the /etc/birdnet/birdnet.conf file
set -x # Uncomment to enable debugging
set -e
trap 'exit 1' SIGINT SIGHUP

echo "Beginning $0"
birdnet_conf=$my_dir/birdnet.conf

install_config() {
  cat << EOF > $birdnet_conf
################################################################################
#                    Configuration settings for BirdNET-Pi                     #
################################################################################

#--------------------- Required: Latitude, and Longitude ----------------------#

## The shell substitution below guesses these based on your network. THESE NEED
## TO BE CHANGED TO STATIC VALUES
## Please only go to 4 decimal places. Example:43.3984

LATITUDE=$(curl -s4 ifconfig.co/json | awk '/latitude/ {print $2}' | tr -d ',')
LONGITUDE=$(curl -s4 ifconfig.co/json | awk '/longitude/ {print $2}' | tr -d ',')

#---------------------  BirdWeather Station Information -----------------------#
#_____________The variable below can be set to have your BirdNET-Pi____________#
#__________________also act as a BirdWeather listening station_________________#

BIRDWEATHER_ID=

#-----------------------  Web Interface User Password  ------------------------#
#____________________The variable below sets the 'birdnet'_____________________#
#___________________user password for the Live Audio Stream,___________________#
#_________________Tools, System Links, and the Processed files ________________#

## CADDY_PWD is the plaintext password (that will be hashed) and used to access
## certain parts of the web interface

CADDY_PWD=

#-------------------------  Live Audio Stream  --------------------------------#
#_____________The variable below configures/enables the live___________________#
#_____________________________audio stream.____________________________________#


## ICE_PWD is the password that icecast2 will use to authenticate ffmpeg as a
## trusted source for the stream. You will never need to enter this manually
## anywhere other than here and it stays on 'localhost.'

ICE_PWD=birdnetpi

#-----------------------  Web-hosting/Caddy File-server -----------------------#
#_______The three variables below can be set to enable internet access_________#
#____________to your data,(e.g., extractions, raw data, live___________________#
#______________audio stream, BirdNET.selection.txt files)______________________#


## BIRDNETPI_URL is the URL where the extractions, data-set, and live-stream
## will be web-hosted. If you do not own a domain, or would just prefer to keep
## the BirdNET-Pi on your local network, keep this EMPTY.

BIRDNETPI_URL=


#-------------------  Mobile Notifications via Pushed.co  ---------------------#
#____________The two variables below enable mobile notifications_______________#
#_____________See https://pushed.co/quick-start-guide to get___________________#
#_________________________these values for your app.___________________________#

#            Keep these EMPTY if haven't setup a Pushed.co App yet.            #

## Pushed.co App Key and App Secret

PUSHED_APP_KEY=
PUSHED_APP_SECRET=

################################################################################
#--------------------------------  Defaults  ----------------------------------#
################################################################################

## RECS_DIR is the location birdnet_analysis.service will look for the data-set
## it needs to analyze. Be sure this directory is readable and writable for
## the BIRDNET_USER.

RECS_DIR=$HOME/BirdSongs

## REC_CARD is the sound card you would want the birdnet_recording.service to
## use. Leave this as "default" to use PulseAudio (recommended), or use
## the output from "aplay -L" to specify an ALSA device.

REC_CARD=default

## PROCESSED is the directory where the formerly 'Analyzed' files are moved
## after extractions have been made from them. This includes both WAVE and
## BirdNET.selection.txt files.

PROCESSED=$HOME/BirdSongs/Processed

## EXTRACTED is the directory where the extracted audio selections are moved.

EXTRACTED=$HOME/BirdSongs/Extracted

## OVERLAP is the value in seconds which BirdNET should use when analyzing
## the data. The values must be between 0.0-2.9.

OVERLAP=0.0

## CONFIDENCE is the minimum confidence level from 0.0-1.0 BirdNET's analysis
## should reach before creating an entry in the BirdNET.selection.txt file.
## Don't set this to 1.0 or you won't have any results.

CONFIDENCE=0.7

## SENSITIVITY is the detection sensitivity from 0.5-1.5.

SENSITIVITY=1.25

## CHANNELS holds the variable that corresponds to the number of channels the
## sound card supports.

CHANNELS=2

## FULL_DISK can be set to configure how the system reacts to a full disk
## purge = Remove the oldest day's worth of recordings
## keep = Keep all data and 'stop_core_services.sh'

FULL_DISK=purge

## PRIVACY_MODE can be set to 'on' or 'off' to configure analysis to be more
## sensitive to human detections. PRIVACY_MODE 'on' will purge any data that
## receives even a low HUMAN_HUMAN confidence score.

PRIVACY_MODE=off

## RECORDING_LENGTH sets the length of the recording that BirdNET-Lite will
## analyze.

RECORDING_LENGTH=15

## EXTRACTION_LENGTH sets the length of the audio extractions that will be made
## from each BirdNET-Lite detection. An empty value will use the default of 6
## seconds.

EXTRACTION_LENGTH=

## AUDIOFMT set the audio format that sox should use for the extractions.
## The default is mp3. Available formats are: 8svx aif aifc aiff aiffc al amb
## amr-nb amr-wb anb au avr awb caf cdda cdr cvs cvsd cvu dat dvms f32 f4 f64 f8
## fap flac fssd gsm gsrt hcom htk ima ircam la lpc lpc10 lu mat mat4 mat5 maud
## mp2 mp3 nist ogg paf prc pvf raw s1 s16 s2 s24 s3 s32 s4 s8 sb sd2 sds sf sl
## sln smp snd sndfile sndr sndt sou sox sph sw txw u1 u16 u2 u24 u3 u32 u4 u8
## ub ul uw vms voc vorbis vox w64 wav wavpcm wv wve xa xi
## Note: Most have not been tested.

AUDIOFMT=mp3


## These are just for debugging
LAST_RUN=
THIS_RUN=
IDFILE=$HOME/BirdNET-Pi/IdentifiedSoFar.txt
EOF
}

# Checks for a birdnet.conf file 
if ! [ -f ${birdnet_conf} ];then
  install_config
fi
chmod g+w ${birdnet_conf}
[ -d /etc/birdnet ] || sudo mkdir /etc/birdnet
sudo ln -sf $birdnet_conf /etc/birdnet/birdnet.conf
grep -ve '^#' -e '^$' /etc/birdnet/birdnet.conf > $my_dir/firstrun.ini
