#!/bin/bash
# wm--Adds specified text as a watermark on the input image,
#     saving the output as image+wm

wmfile="/tmp/watermark.$$.png"
fontsize="44"

file=$(zenity --title="Select file to watermark" \
              --file-selection) >/dev/null 2>&1
case $? in
     0) echo "\"$file\" selected.";;
     1) echo "No file selected."; exit 1 ;;
    -1) echo "An unexpected error has occurred."; exit 1 ;;
esac

watermark=$(zenity --title="What would you like your watermark to be?"\
                   --entry) >/dev/null 2>&1

trap '$(which rm) -f $wmfile' 0 1 15

# To start, get the dimensions of the image

dimensions="$(identify -format "%G" "$file")"

# Let's create the temporary watermark overlay

convert -size "$dimensions" xc:none -pointsize $fontsize -gravity south \
    -draw "fill black text 1,1 '$watermark' text 0,0 '$watermark' fill white text 2,2 '$watermark'" \
    "$wmfile"

# Now let's composite the overlay and the original file
suffix="$(echo "$file" | rev | cut -d. -f1 | rev)"
prefix="$(echo "$file" | rev | cut -d. -f2- | rev)"

newfilename="$prefix+wm.$suffix"
composite -dissolve 75% -gravity south $wmfile "$file" "$newfilename"

if [ -r "$newfilename" ] ; then
    echo "Created new watermarked image file $newfilename"
    if zenity --question --icon="$newfilename" --text="Would you like to see the newly watermarked file?" ; then
        gwenview "$newfilename"
    fi
else
    echo "An unexpected error occurred"
    exit 1
fi

exit 0
