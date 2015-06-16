#!/bin/bash
path=$1
f=$(basename $path)
cd $path
if [ ! -e .metainfos ]
then
    echo "No metainfos for $prefix/$f"
    echo "  A .metainfos file contains two line:"
    echo "    The url of the vimscript"
    echo "    The current version number (0 for init)"
else
    ln=$(head -n 1 .metainfos)
    wget $ln -q -O $$.php
    l=$(($(grep -n "span.*script version" $$.php  | cut -d ':' -f 1)+1))
    l="$l"d
    text=$(sed 1,$l $$.php  | egrep -v "(vba|vmb)" | grep "href.*download" -A 3 | head -n 3)
    nln=$baseln/$(echo $text | sed 's/.*href="\([^"]*\).*".*/\1/')
    file=$(echo $text | sed 's/.*href=[^>]*>\([^<]*\)<.*/\1/')
    ver=$(echo $text | sed 's/.*<\/td>.*<b>\(.*\)<\/b>.*/\1/')
    oldver=$(tail -n 1 .metainfos)
    if [ "$ver" != "$oldver" ]
    then
        echo "updating $f current version $oldver, newest $ver"
        rm -rf ./*
        echo -e "$ln\n$ver" > .metainfos
        wget $nln -q -O $file
        atool -qx $file
        if [ $? -ne 0 ]
        then
            echo "Unable to extract archive for plugin $f"
            echo "You might need to finish the update manually"
        else
            rm $file
            dir=$(\ls .)
            mv $dir/* .
            rmdir $dir
        fi
    else
        echo "plugin $f up to date, last version $ver"
    fi
    rm $$.php
fi
