#!/bin/bash

set -e

if [ $# -eq 0 ]; then
  echo "USAGE: $0 plugins.txt"
  exit 1
fi

if [ -d $JENKINS_HOME ]
then
    TEMP_ALREADY_INSTALLED=$JENKINS_HOME/preinstalled.plugins.$$.txt
else
    echo "ERROR $JENKINS_HOME not found"
    exit 1
fi

plugin_dir=$JENKINS_HOME/plugins

file_owner=jenkins.jenkins

plugins_install_file=$1
REF=/usr/share/jenkins/ref/plugins
mkdir -p ${plugin_dir}
mkdir -p $REF
COUNT_PLUGINS_INSTALLED=0

installPlugin() {
  pluginName=$(echo $1 | cut -f1 -d :)
  version=$(echo $1 | cut -f2 -d :)
  if [ "$pluginName" == "$version" ]; then
      version="latest"
  fi
  if  grep -q "${pluginName}:${version}" $TEMP_ALREADY_INSTALLED; then
    if [ "$2" == "1" ]; then
      return 1
    fi
    echo "Skipped: $1 (already installed)"
    return 0
  else
    echo "Downloading: $1"
    curl --retry 3 --retry-delay 5 -sSL -f  https://updates.jenkins-ci.org/download/plugins/${pluginName}/${version}/${pluginName}.hpi -o $REF/${pluginName}.jpi
    unzip -qqt $REF/${pluginName}.jpi
    echo "Check for missing dependecies ..."

    # without optionals
    #deps=$( unzip -p ${f} META-INF/MANIFEST.MF | tr -d '\r' | sed -e ':a;N;$!ba;s/\n //g' | grep -e "^Plugin-Dependencies: " | awk '{ print $2 }' | tr ',' '\n' | grep -v "resolution:=optional" | awk -F ':' '{ print $1 }' | tr '\n' ' ' )
    # with optionals
    deps=$( unzip -p $REF/${pluginName}.jpi META-INF/MANIFEST.MF | tr -d '\r' | sed -e ':a;N;$!ba;s/\n //g' | grep -e "^Plugin-Dependencies: " | awk '{ print $2 }' | tr ',' '\n' | awk -F ':' '{ print $1 }' | tr '\n' ' ' )
    for plugin in $deps; do
      installPlugin "$plugin" 
    done
      
    return 0
  fi
}



if [ -d $plugin_dir ]
then
    echo "Analyzing: $plugin_dir"
    for i in `ls -pd1 $plugin_dir/*|egrep '\/$'`
    do
        JENKINS_PLUGIN=`basename $i`
        JENKINS_PLUGIN_VER=`egrep -i Plugin-Version "$i/META-INF/MANIFEST.MF"|cut -d\: -f2|sed 's/ //'`
        echo "$JENKINS_PLUGIN:$JENKINS_PLUGIN_VER"
    done > $TEMP_ALREADY_INSTALLED
else
    JENKINS_WAR=/usr/share/jenkins/jenkins.war
    if [ -f $JENKINS_WAR ]
    then
        echo "Analyzing war: $JENKINS_WAR"
        TEMP_PLUGIN_DIR=/tmp/plugintemp.$$
        for i in `jar tf $JENKINS_WAR|egrep 'plugins'|egrep -v '\/$'|sort`
        do
            rm -fr $TEMP_PLUGIN_DIR
            mkdir -p $TEMP_PLUGIN_DIR
            PLUGIN=`basename $i|cut -f1 -d'.'`
            (cd $TEMP_PLUGIN_DIR;jar xf $JENKINS_WAR "$i";jar xvf $TEMP_PLUGIN_DIR/$i META-INF/MANIFEST.MF >/dev/null 2>&1)
            VER=`egrep -i Plugin-Version "$TEMP_PLUGIN_DIR/META-INF/MANIFEST.MF"|cut -d\: -f2|sed 's/ //'`
            echo "$PLUGIN:$VER"
        done > $TEMP_ALREADY_INSTALLED
        rm -fr $TEMP_PLUGIN_DIR
    else
        rm -f $TEMP_ALREADY_INSTALLED
        echo "ERROR file not found: $JENKINS_WAR"
        exit 1
    fi
fi


while IFS='' read -r line || [[ -n "$line" ]]; do
    installPlugin $line
done < "$1"

#Install Dependency Plugins

# changed=1
# maxloops=100

# while [ "$changed"  == "1" ]; do
#   echo "Check for missing dependecies ..."
#   if  [ $maxloops -lt 1 ] ; then
#     echo "Max loop count reached - probably a bug in this script: $0"
#     exit 1
#   fi
#   ((maxloops--))
#   changed=0
#   for f in ${plugin_dir}/*.jpi ; do
#     # without optionals
#     #deps=$( unzip -p ${f} META-INF/MANIFEST.MF | tr -d '\r' | sed -e ':a;N;$!ba;s/\n //g' | grep -e "^Plugin-Dependencies: " | awk '{ print $2 }' | tr ',' '\n' | grep -v "resolution:=optional" | awk -F ':' '{ print $1 }' | tr '\n' ' ' )
#     # with optionals
#     deps=$( unzip -p ${f} META-INF/MANIFEST.MF | tr -d '\r' | sed -e ':a;N;$!ba;s/\n //g' | grep -e "^Plugin-Dependencies: " | awk '{ print $2 }' | tr ',' '\n' | awk -F ':' '{ print $1 }' | tr '\n' ' ' )
#     for plugin in $deps; do
#       installPlugin "$plugin" 1 && changed=1
#     done
#   done
# done

echo "chown plugin permissions"

chown ${file_owner} ${plugin_dir} -R
#cleanup
rm $TEMP_ALREADY_INSTALLED