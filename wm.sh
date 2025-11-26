#!/bin/bash
# Adds specified text as a watermark on the input image,
# saving the output as image+wm

tmpfile="/tmp/watermark.$$.png"
fontsize="44"
colour='white'
stroke=''

usage() {
        echo "Usage: $(basename "$0") to run the script
                     $(basename "$0") -h
                  or $(basename "$0") --help for help";
        exit 1
}

while [ $# -gt 0 ]
do
    case $1 in
        -h | --help) 
            zenity --info \
                          --text="This is a simple bash+zenity script that allows you to watermark any number of files with text of your choice.\nUsage: \nwm.sh to run the script\nwm.sh -h OR --help for help" ;
                    exit 0 ;;
        -s | --stroke) 
            stroke="-stroke $2"; shift;;
        -c | --colour | --color ) 
            colour="$2"; shift;;
        * ) usage ;;
    esac
    shift
done

file=$(zenity --title="Select file(s) to watermark" \
              --file-selection \
              --multiple)
if [ $? -eq 1 ] ; then echo No File Selected; exit 1 ; fi

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
for filename in $nospace; do
    # Convert $nospace filenames back to their original names
    originalname=$(echo "$filename" | tr : \  )
    ! [[ "$filename" =~ $validtypes ]] && \
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


for filename in $nospace; do
    # Delete temporary file after program closes
    trap '$(which rm) -f $tmpfile' 0 1 15
    # Convert changed files back to original name by switching colon and space
    originalname=$(echo "$filename" | tr : \  )

    dimensions="$(identify -format "%G" "$originalname")"

    # Create temporary watermark overlay
    magick -size "$dimensions" xc:none -pointsize $fontsize -gravity south \
        -fill "$colour" $stroke -draw "text 0,0 $watermark" "$tmpfile"

    # Composite overlay and original file
    suffix="$(echo "$originalname" | rev | cut -d. -f1 | rev)"
    prefix="$(echo "$originalname" | rev | cut -d. -f2- | rev)"

    newfilename="$prefix+wm.$suffix"
    composite -dissolve 75% -gravity south $tmpfile "$originalname" "$newfilename"
    # magick "$originalname" -size "$dimensions" xc:none -pointsize $fontsize \
    #     -gravity south -fill white -stroke black -annotate text +0+0 "$watermark" \
    #         "$newfilename"
 
    # If file exists
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
