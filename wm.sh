#!/bin/bash
# Adds specified text as a watermark on the input image,
# saving the output as image+wm

tmpfile="/tmp/watermark.$$.png"
fontsize="44"


if [ $# -gt 0 ]; then
    if [ "$1" = "-h" ] || [ "$1" = "--help" ] ; then
        # zenity --text-info --filename=README.md
        zenity --info \
               --text="This is a simple bash+zenity script that allows you to watermark any number of files with text of your choice.\nUsage: \nwm.sh to run the script\nwm.sh -h OR --help for help"
        exit 0
    else
        echo "Usage: $(basename "$0") to run the script
                     $(basename "$0") -h
                  or $(basename "$0") --help for help";
        exit 0
    fi
fi

file=$(zenity --title="Select file(s) to watermark" \
              --file-selection \
              --multiple)

# Find how many files were selected by converting the default separator ('|')
# into newlines ('\n'), and then counting how many lines there are with wc -l
filenum=$(echo "$file" | tr \| \\n | wc -l)
# List of each file separated by newlines
files=$(echo "$file" | tr \| \\n)
# List of each file where any spaces are replaced with an arbitrary character
# This is so files with spaces in them (e.g. "test file.jpg") don't break up
# into "test" and "file.jpg" when being checked in the for loop below
nospace=$(echo "$files" | tr \  :)

# File must be a png, jp(e)g, or webp
validtypes="(.png|.jpe?g|.webp)"
for file in $nospace; do
    # Convert $nospace files back to their original names
    originalname=$(echo "$file" | tr : \  )
    ! [[ "$file" =~ $validtypes ]] && \
        zenity --error --text="\"$originalname\" has an unsupported filetype, must be png, jpg, or webp" && \
        exit 1
done

# Make sure user knows they have selected more than one file
if [ "$filenum" -gt 1 ] ; then
    zenity --question \
           --text="Do you want to apply a watermark to $filenum files?\nDuplicates will be made of all:\n\n$files" \
           --no-wrap \
           --no-markup
    # Allow user to cancel if they change their mind
    if [ "$?" = "1" ] ; then exit 1 ; fi
fi

watermark=$(zenity --title="What would you like your watermark to be?"\
                   --entry)
if [ "$?" = "1" ] ; then exit 1 ; fi


for file in $files; do
    # Delete temporary file after program closes
    trap '$(which rm) -f $tmpfile' 0 1 15

    dimensions="$(identify -format "%G" "$file")"

    # Create temporary watermark overlay
    convert -size "$dimensions" xc:none -pointsize $fontsize -gravity south \
        -draw "fill black text 1,1 '$watermark' text 0,0 '$watermark' fill white text 2,2 '$watermark'" \
        "$tmpfile"

    # Composite overlay and original file
    suffix="$(echo "$file" | rev | cut -d. -f1 | rev)"
    prefix="$(echo "$file" | rev | cut -d. -f2- | rev)"

    newfilename="$prefix+wm.$suffix"
    composite -dissolve 75% -gravity south $tmpfile "$file" "$newfilename"

    if [ -r "$newfilename" ] ; then
        echo "Created new watermarked image file $newfilename"
        # "OK" selection exit code is 0
        # If user enters "OK", then show file
        if zenity --question --icon="$newfilename" --text="Would you like to see the newly watermarked file?" ; then
            magick display "$newfilename"
        fi
    else
        echo "An unexpected error occurred"
        exit 1
    fi
done

exit 0
