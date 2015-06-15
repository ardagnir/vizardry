#!/bin/bash
# Extract the README part from a github page read in stdin
pandoc=$(which pandoc)
if [ -z "$pandoc" ]
then
    format="cat"
else
    format="$pandoc -f html -t markdown"
fi
awk 'BEGIN{OK=0} {if(OK == 1){print $0}} /div id="readme"/{OK=1;DIV=1}
/<div/{DIV=DIV+1} /<\/div/{DIV=DIV-1;if(DIV <=0){OK=0}}' |  $format
