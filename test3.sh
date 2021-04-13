#!/bin/bash

# saket ji - 9827782352

function parseXML() {
xmlFile="$1"
elemList=( $(cat $xmlFile | tr '\n' ' ' | XMLLINT_INDENT="" xmllint --format - | grep -e "</.*>$" | while read line; do \
echo $line | sed -e 's/^.*<\///' | cut -d '>' -f 1; \
done) )

totalNoOfTags=${#elemList[@]}; ((totalNoOfTags--))
suffix=$(echo ${elemList[$totalNoOfTags]} | tr -d '</>')
suffix="${suffix}_"

for (( i = 0 ; i < ${#elemList[@]} ; i++ )); do
elem=${elemList[$i]}
elemLine=$(cat $xmlFile | tr '\n' ' ' | XMLLINT_INDENT="" xmllint --format - | grep "</$elem>")
echo $elemLine | grep -e "^</[^ ]*>$" 1>/dev/null 2>&1
if [ "0" = "$?" ]; then
continue
fi
elemVal=$(echo $elemLine | tr '\011' '\040'| sed -e 's/^[ ]*//' -e 's/^<.*>\([^<].*\)<.*>$/\1/' | sed -e 's/^[ ]*//' | sed -e 's/[ ]*$//')
xmlElem="${suffix}$(echo $elem | sed 's/-/_/g')"
eval ${xmlElem}=`echo -ne \""${elemVal}"\"`
attrList=($(cat $xmlFile | tr '\n' ' ' | XMLLINT_INDENT="" xmllint --format - | grep "</$elem>" | tr '\011' '\040' | sed -e 's/^[ ]*//' | cut -d '>' -f 1  | sed -e 's/^<[^ ]*//' | tr "'" '"' | tr '"' '\n'  | tr '=' '\n' | sed -e 's/^[ ]*//' | sed '/^$/d' | tr '\011' '\040' | tr ' ' '>'))
for (( j = 0 ; j < ${#attrList[@]} ; j++ )); do
attr=${attrList[$j]}
((j++))
attrVal=$(echo ${attrList[$j]} | tr '>' ' ')
attrName=`echo -ne ${xmlElem}_${attr}`
eval ${attrName}=`echo -ne \""${attrVal}"\"`
done
done
}

parseXML "./Config.xml"
echo "$Config_psudoPWD |  $Config_currentRelease |  $Config_previousRelease" #Variables for each  XML ELement
echo "$Config_psudoPWD_value |  $Config_currentRelease_value |  $Config_previousRelease_value " #Variables for each XML Attribute
echo ""
