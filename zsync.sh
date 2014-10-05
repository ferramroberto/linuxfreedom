#!/bin/bash

url=$1
seedfile=$2

tempdir=$(mktemp -d)
msgfile=$tempdir/message
trap 'rm -rf "$tempdir"' EXIT

down_filter() {
    local message line percent speed
    echo "Downloading zsync file" > "$msgfile"
    read -r -n1 _
    while read -r line; do
        if [[ $line = [-#]* ]]; then
            read -r _ percent speed <<< "$line"
            echo "#$(<"$msgfile")\n$speed"
            if (( ${percent%%.*} < 100 )); then
                echo "$percent"
            else
                echo "99.9%"
            fi
        fi
    done < <(awk 'BEGIN{RS="[\r\n]"} {print;fflush()}')
}

seed_filter() {
    local message file count size point
    while read -r -d '*' line; do
        file=${line%:*}
        message+="\n$file"
        echo "$message" > "$msgfile"
        file=${file#reading seed file }
        count=1
        size=$(( $(wc -c < "$file") / 1000000 + 1 ))
        echo "#$message"
        while read -r -n1 point; do
            [[ $point = '*' ]] || break
            ((count++))
            echo "$(( 100 * count / size ))%"
        done
        read -r message;
        echo "$message" > "$msgfile"
    done
}

if [[ -z $url ]]; then
    url=$(zenity --entry \
                 --title=zsync \
                 --text="Enter URL to zsync file" \
                 --width=500 \
                 --height=100 \
    ) || exit
fi

if [[ -z $seedfile || ! -e $seedfile ]]; then
    seedfile=$(zenity --file-selection \
                      --title="zsync $url" \
                      --text="Choose a seed-file" \
    )
fi

{ 
    zsync ${seedfile:+-i "$seedfile"} "$url" \
          > >(down_filter >&3) 2> >(seed_filter >&3)
} 3> >(zenity --progress \
              --title="zsync $url" \
              --width=500 \
              --height=100 \
)
