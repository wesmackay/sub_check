# sub_check
this bash script will scan video files for embedded or external subtitles located on disk.

## Pre-requisites
we utilize the 'mediainfo' command to analyze video files, so make sure to install this on your system.

## How to Run
bash sub_check.bash [--debug | --good | --silent] /path/to/folder/

### Flags Options
(no flag): will show you only files with missing or unknown subtitles

--debug: will show you every file being processed whether they're missing, unknown, or found as english labeled

--good: will show you only files that are known english embedded or external subtitles

--silent: will not show any output (but will still create a report.txt file)

### Messages to Expect
'embedded eng sub' - we found an embedded english subtitle in the video
'external eng sub' - we found an external '.srt' subtitle that's labeled as english
'unknown sub' - we found an embedded subtitle but it's not labeled as english
'unknown sub (external)' - we found an external '.srt' subtitle but it's not labeled as english
'no sub found' - there was no subtitle at all found
