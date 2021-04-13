#!/bin/bash
SNAPSHOT_BEFORE_FAILED=()
SNAPSHOT_AFTER_FAILED=()
current_release_name=0.0.0
previous_release_name=0.0.0
psudoPWD=""
psudoReleaseVersion=0
FILES_TO_MONITOR="","","",""

# next function will be deleted , actual build function will be used here

function parseConfig() {
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

extractReleaseVersion() {
echo $1 | sed 's/[a-z-]//g'
}

extractParentVersion() {
echo $1 | cut -d. -f1
}

remove_special_ch() {
echo $1| awk '{print substr($0,2)}'
}

take_links_backup(){
#local current_rel_backup="current_rel_backup"
#local prev_rel_backup="prev_rel_backup"
#local folder="$(extractParentVersion $2)"
local task_path="$(extractParentVersion $1)"
local path_to_go=cos/releases/domain_Cos${task_path}
local path_to_come_back=$PWD
#local mappedFirstArg=release_"$1"
#local mappedSecondArg=release_"$2"
echo $path_to_go
echo kashish
if [ -d "$path_to_go" ]
then
echo "$path_to_go file already exists"
else
mkdir "$path_to_go"
fi

cd "$path_to_go"

local lik_curr="$(readlink current_release)"
local link_prev="$(readlink previous_release)"
local link_curr_save="$(extractReleaseVersion $lik_curr)"
local link_prev_save="$(extractReleaseVersion $link_prev)"
current_release_name="$(echo $link_curr_save | sed 's/_//')"
previous_release_name="$(echo $link_prev_save | sed 's/_//')"

if [ -z "$current_release_name" ] || [ -z "$previous_release_name" ]
then
echo "current release or previous release is not present at destination , reading cofig for the same"
    if [ -z "$current_release_name" ]
    then
        echo "current release is empty reading current release from config"
        current_release_name="$Config_currentRelease_value"
    fi
    if [ -z "$previous_release_name" ]
    then
        echo "current release is empty reading current release from config"
        previous_release_name="$Config_previousRelease_value"
    fi
else
fi

echo $current_release_name
echo $previous_release_name
local mappedFirstArg=release_"$current_release_name"
local mappedSecondArg=release_"$previous_release_name"
if [ -d "$mappedFirstArg" ]
then
echo "$mappedFirstArg file already exists"
else
mkdir "$mappedFirstArg"
fi
#another check
if [ -d "$mappedSecondArg" ]
then
echo "$mappedSecondArg file already exists"
else
mkdir "$mappedSecondArg"
fi
ln -sfn $mappedFirstArg current_release
ln -sfn $mappedSecondArg previous_release
local current_rel_backup="current_rel_backup"
local prev_rel_backup="prev_rel_backup"
if [ -d "$current_rel_backup" ]
then
echo "$current_rel_backup file already exists"
else
mkdir "$current_rel_backup"
fi
#another check
if [ -d "$prev_rel_backup" ]
then
echo "$prev_rel_backup file already exists"
else
mkdir "$prev_rel_backup"
fi
mv current_release "$current_rel_backup"
mv previous_release "$prev_rel_backup"
cd "$path_to_come_back"
}

create_build(){
local version1=$1
local CURRENT_DIR=$2
cd $CURRENT_DIR
mkdir -p cos/releases/domain_Cos$version1/release_"$version1".0.0_dummy
ls -la cos/releases/domain_Cos$version1 | grep "current_release"
if (( $? == 0 )) ;then
echo "Link:current_release already exist"
else
echo "No link, creating a new one for current_release"
cd cos/releases/domain_Cos$version1
ln -s release_"$version1".0.0_dummy current_release
current_rel=release_"$version1".0.0_dummy
fi
echo "build release successfull"
cd $CURRENT_DIR
mkdir -p cos/config
ls -la cos/config/ | grep "Cos${version1}"
if (( $? == 0 ))
then
echo "Link:Cos${version1} already exist"
else
cd cos/config
ln -s ../releases/domain_Cos${version1}/current_release Cos${version1}
cd ..
cd ..
fi
echo "mapped release successful"
return 1
}

take_snapshot(){
local TARGET_DIR=$1
local update_status=$2
local path_to_come_back_backup=$3
local delta_counter=0
cd $TARGET_DIR
local scan_dir=$(find .)
if [ $2 == 0 ]
then
if [ -d "$TARGET_DIR" ]
then
for T in $scan_dir
do
SNAPSHOT_BEFORE_FAILED[$delta_counter]="$T"
delta_counter=$((delta_counter+1))
done
fi
else
if [ -d "$TARGET_DIR" ]
then
for T1 in $scan_dir
do
SNAPSHOT_AFTER_FAILED[$delta_counter]="$T1"
delta_counter=$((delta_counter+1))
done
fi
fi
cd $path_to_come_back_backup
}


array_diff(){
awk 'BEGIN{RS=ORS=" "}
{NR==FNR?a[$0]++:a[$0]--}
END{for(k in a)if(a[k])print k}' <(echo -n "${!1}") <(echo -n "${!2}")
}

create_symlink(){
local status=1
# $1 this will be the path to go
local PATH_TO_GO=$1
# $ this will be the path to comaback
local PATH_TO_COMEBACK=$2
# $3 this will be your symlink path
local SYMLINK_1=$3
local SYMLINK_2=$4
local dirTest=$5
# if [ -d "$dirTest" ] ; then
#       echo "$dirTest" already exists skipping folder creation
# else
#       echo "$dirTest" creating
#       mkdir -p $dirTest
# fi
local current_rel_backup="current_rel_backup"
local prev_rel_backup="prev_rel_backup"

# navigate
echo $PATH_TO_GO
echo $PWD

cd "$PATH_TO_GO"
echo "dummy"
echo $PWD

cd "$current_rel_backup"
mv * ../
cd ..
cd "prev_rel_backup"
mv * ../
cd ..
rm -rf "$current_rel_backup"
rm -rf "$prev_rel_backup"
# will create
#ln -sfn ${SYMLINK_1} ${SYMLINK_2}
if [ $? == 0 ] ; then
status=0
else
status=1
fi
cd "$PATH_TO_COMEBACK"
return $status
}

update_symlinks(){
#unlink current_release
#unlink previous_release
#find . -type l delete
local res=1
echo "updating symlink"
local res=1
local temp_release=previous_release
local tempPwd=$2
local tempReleaseD=cos/releases/domain_Cos${1}
local tempLink=release_"$1".0.0_dummy
local tempDirTest=cos/releases/domain_Cos$1/release_"$5"
local cc="$3"
local dd="$4"
echo $PWD
local npg="$2/$tempReleaseD"
local pwd_store=$PWD
cd $npg
echo $npg
echo dummy
local links=$(find . -type l -ls)
cd $pwd_store


#mv current_release previous_release
# echo $current_rel
create_symlink "$2/$tempReleaseD" $tempPwd $3 $temp_release $tempDirTest
# temp_release=current_release
# create_symlink $tempReleaseD $tempPwd $cc $temp_release $tempDirTest


res=$?
echo $PWD
cd $npg
local new_links=$(find . -type l -ls)
cd $pwd_store
if [ $res == 0 ]
then
res=0
echo "previous symlynks are following -"
echo "$links"
echo "new symlynks are following -"
echo "$new_links"
fi
return $res
}

restore_state(){
local res=1
local ptg=$1
local pcb=$2
echo "restoring state"
bad_working_tree=($(array_diff SNAPSHOT_AFTER_FAILED[@] SNAPSHOT_BEFORE_FAILED[@]))
cd $ptg
for REF_DEL in ${bad_working_tree[@]}
do
echo "kashish"
echo $REF_DEL
local trimmed_prifix="$(remove_special_ch $REF_DEL)"
trimmed_prifix="$(remove_special_ch $trimmed_prifix)"
echo $trimmed_prifix
if [ -d "$trimmed_prifix" ]
then
echo "deleting $trimmed_prifix"
rm -rf $trimmed_prifix
elif [ -f "$trimmed_prifix" ]
then
echo "deleting $trimmed_prifix"
rm -f $trimmed_prifix
elif [ -e "$trimmed_prifix" ]
then
echo "new files will be created: $trimmed_prifix"
else
echo "...."
fi
done
res=0
echo "state restored"
cd $pcb
return $res
}

function preDeployScript() {
check_status "FAIL SCRIPT: While taking backup-running rollback"
sh $DEPLOY_HOME/install/preInstall.sh
local status=$?
check_status "FAIL SCRIPT: Installing pre-required directories"
sh $DEPLOY_HOME/pre/preDeploy.sh
status=$?
check_status "FAIL SCRIPT: Perform pre-deploy steps"
return $status
}

function postDeployScript() {
sh $DEPLOY_HOME/post/postDeploy.sh
local status=$?
check_status "FAIL SCRIPT: Unable to perform post deployment verification"
return $status
}

function createBuildScript() {
sh $DEPLOY_HOME/mainDeploy/mainDeployScript.sh
local status=$?
check_status "FAIL SCRIPT: Deployment failure"
return $status
}

Backup_descriptor(){
local t_v="$(extractParentVersion $1)"
local TARGET_VER=$t_v
echo $TARGET_VER
local next_release_folder_name="$(extractParentVersion $2)"
unset SNAPSHOT_BEFORE_FAILED
unset SNAPSHOT_AFTER_FAILED
local PWD_CPY="$PWD/cos/releases/domain_Cos${t_v}"
echo $PWD_CPY
# pre deploy call
preDeployScript
# pre deploy end
echo "taking folder and link snapshot"
take_snapshot $PWD_CPY 0 $PWD
sleep 1
echo "snapshot created"
echo "now building the project"
# this is the actual build function call
#createBuildScript
#createBuildScript
#createBuildScript
#createBuildScript
local res=1
for SCRIPT in $FILES_TO_MONITOR
do
    $SCRIPT
    res=$?
done
#create_build $TARGET_VER $PWD
#local res=$?
if [ $res -ne 0 ]
then
echo "taking folder and link snapshot after build"
take_snapshot $PWD_CPY 1 $PWD
sleep 1
echo "applying backup of last successfull working state"
restore_state $PWD_CPY $PWD
if [ $? == 0 ]
then
echo "state restored successfully"
else
echo "oops !! something went wrong"
fi
sleep 1
echo "now restoring symlink"
update_symlinks $next_release_folder_name $PWD $next_release_folder_name $3 $2
if [ $? == 0 ]
then
echo "symlinks successfully updated"
else
echo "oops !! something went wrong"
fi
else
echo "create_build did not throw any error !! no need to restore anything"
fi

}

parseConfig "./Config.xml"

psudoPWD="$Config_psudoPWD_value"
psudoReleaseVersion=$Config_executionVersion_value
echo $psudoReleaseVersion

if [ -z "$psudoPWD" ]
then
echo "someth"
exit 1
else
    echo "psudo pwd"
    echo $PWD
    cd $psudoPWD
    echo $PWD


    take_links_backup "$psudoReleaseVersion"
    echo $current_release_name
    echo $previous_release_name
    if [ -z "$current_release_name" ] || [ -z "$previous_release_name" ]
    then
    echo "please provide current and previous release to proceed"
    else
    echo "will be deleted echo"
    Backup_descriptor "$psudoReleaseVersion" "$current_release_name" "$previous_release_name"
    fi
fi



#if [ -z "$1" ]
#then
#echo "wrong version"
#else
#    echo "test"
#
##       chmod -R 777 $PWD
#
##replace $PWD with $Config_psudoPWD_value
#
#
#fi

