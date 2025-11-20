#!/bin/bash
# Adds specified text as a watermark on the input image,
# saving the output as image+wm

tmpfile="/tmp/watermark.$$.png"
fontsize="44"


file=$(zenity --title="Select file to watermark" \
              --file-selection)

# Check that a file was selected
case $? in
     0) echo "\"$file\" selected.";;
     1) echo "No file selected."; exit 1 ;;
    -1) echo "An unexpected error has occurred."; exit 1 ;;
esac

# File must be a png, jp(e)g, or webp
validtypes="(.png|.jpe?g|.webp)"
! [[ "$file" =~ $validtypes ]] && \
    zenity --error --text="Unsupported filetype, must be png, jpg, or webp" && \
    exit 1

watermark=$(zenity --title="What would you like your watermark to be?"\
                   --entry)

# Allow user to cancel if they change their mind
if [ "$?" = "1" ] ; then exit 1 ; fi

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

exit 0
