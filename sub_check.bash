#!/bin/bash

### ------------------------- ###
#  Name: sub_check.bash
#  This script will scan your video files for valid english subtitles 
#  and alert you to missing or untitled subtitles.
### ------------------------- ###

### ------------------------- ###
#  Issues:
#  - if we just pass a directory as parameter, then we run directory check twice
#  - confirm if mediainfo can detect subs in .mp4 and other files
### ------------------------- ###

IFS=$'\n'; set -f    # needed to handle file paths with spaces
debug="$1"           # catch first parameter passed
path="$2"            # catch second parameter passed
# list of the video files we will analyze for subtitles
video_types+=("*.mkv" "*.mp4" "*.avi" "*.wmv")

### --- convert video_types to be compatible with find command --- ###
# we want to convert our file_types into this: '-name "*.mkv" -o -name "*.mp4"'
for type in ${video_types[@]}; do
  file_types+=(-name "$type")
  # add the "-o" option if we're not at the last video_type element
  [[ $type != ${video_types[-1]} ]] && file_types+=( -o )
done
### -------------------------------------------------------------- ###

### ----- check passed parameters for debug flags & filepath ----- ###
## --debug   shows all files being processed
## --silent  omits all files being processed
## --good    shows only found eng subtitles
#
# if we pass a valid debug flag
if [[ $debug == "--debug" || $debug == "--silent" || $debug == "--good" ]]; then
  echo "$debug parameter was passed --"
# if we pass a filepath, set path variable
elif [[ -d $debug ]]; then
  echo "-- running now  --"
  path="$debug"
  debug=""
# if its anything else, notify user & exit script
else
  echo "error: please enter [\"--debug\" | \"--silent\" | \"--good\" | \"/path/to/file\"] .."
  exit 1
fi

# the path parameter must be entered for script to run
# if path is not a valid directory or empty, notify user & exit
[[ ! -d $path || -z $path ]] && echo "\"$path\" is not a valid directory" && exit 1
### -------------------------------------------------------------- ###

### -------------------------------------------------------------- ###
# store all external .srt subs inside provided $path
external_subs=$(find "$path" -name *.srt -type f)

# iterate over each file from the given path
for file in $(find "$path" "${file_types[@]}" -type f); do
  # keep track of total # of files processed
  i=$((i+1))
  # check for a subtitle entry in the video
  sub=$(mediainfo --Inform="Text;%ID%" "$file")
  ## check for existing subtitle (english or not)
  if [[ -n "$sub" ]]; then
    # store subtitle language(s)
    sub_language=$(mediainfo --Inform="Text;%Language%" "$file")
    # check for english language label ('en')
    if [[ $sub_language =~ "en" ]]; then
      [[ $debug == "--debug" || $debug == "--good" ]] && echo "embedded eng sub - $file"
      good_list+=("$file")
    # check for unknown language (if it exists but no label)
    elif [[ -z "$sub_language" ]]; then
      [[ $debug != "--silent" ]] && echo "unknown sub - $file"
      check_list+=("unknown sub - $file")
    # the subtitle has a label thats not english (jap, fre, ...)
    else
      [[ $debug != "--silent" ]] && echo "verify sub - $file"
      check_list+=("verify sub - $file")
    fi
  ## check for no subtitle in the video
  elif [[ -z "$sub" ]]; then
    # check for external .srt file [[ 'tv.show.S01E01.en.srt' -vs- 'tv.show.S01E01.srt' ]]
    if [[ "${external_subs[@]}" =~ "${file%.*}."(.)(.)(.) ]]; then
      # check if external sub is english labeled [[ 'tv.show.S01E01.en.' ]]
      if [[ "$BASH_REMATCH" =~ ('.en.')$ ]]; then
        [[ $debug == "--debug" || $debug == "--good" ]] && echo "external eng sub - $file"
        good_list+=("$file")
      # we dont know the language of this external subtitle
      else
        echo "unknown sub (external) - $file"
        check_list+=("unknown sub (external) - $file")  # add file to check_list for later analysis
      fi
    # no subtitle was found
    else
      [[ $debug == "--debug" || $debug == "" ]] && echo "no sub found - $file"
      check_list+=("no sub found - $file")              # add file to check_list for later analysis
    fi
  fi
done
### -------------------------------------------------------------- ###

unset IFS; set +f

# print out files to check out
echo ""
echo "--- Subtitle Results ---"
#echo "# of processed files: $i"
echo "# of found english subtitles: ${#good_list[*]}/$i"
echo "# of files that were missing or unknown: ${#check_list[*]}/$i"
echo ""
[[ ${#check_list[*]} == 0 ]] && exit 1        ## exit script if there are no files to check
echo "--- Check List ---"
echo "files with missing or unknown subtitles are stored in results.txt"
printf '%s\n' "
----- Results -----
# of processed files: $i
# of found english subtitles: ${#good_list[*]}
# of files that were missing or unknown: ${#check_list[*]}

## Files to check out
${check_list[@]}" > "./results.txt"
echo "------------------"

