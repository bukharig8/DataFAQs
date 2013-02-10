#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/DataFAQs/blob/master/bin/install-datafaqs-dependencies.sh>

if [[ "$1" == "--help" ]]; then
   echo
   echo "usage: `basename $0` [-n] [--avoid-sudo]"
   echo
   echo "  Install the third-party utilities that DataFAQs uses."
   #echo "  Will install everything relative to the path:"
   #echo "     $base"
   echo "  See https://github.com/timrdf/DataFAQs/wiki/Installing-DataFAQs"
   echo
   echo "   -n          | Perform only a dry run. This can be used to get a sense of what will be done before we actually do it."
   echo
   echo "  --avoid-sudo : Avoid using sudo if at all possible. It's best to avoid root."
   echo
   exit
fi

dryrun="false"
TODO=''
if [ "$1" == "-n" ]; then
   dryrun="true"
   #$sibling/dryrun.sh $dryrun beginning
   TODO="[TODO]"
   shift
fi

function offer_install_with_apt {
   # See also https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/install-csv2rdf4lod-dependencies.sh
   # See also https://github.com/timrdf/DataFAQs/blob/master/bin/install-datafaqs-dependencies.sh

   command="$1"
   package="$2"
   if [ `which apt-get` ]; then
      if [[ -n "$command" && -n "$package" ]]; then
         if [ ! `which $command` ]; then
            if [ "$dryrun" != "true" ]; then
               echo
            fi
            echo $TODO $sudo apt-get install $package
            if [ "$dryrun" != "true" ]; then
               read -p "Could not find $command on path. Try to install with command shown above? (y/n): " -u 1 install_it
               if [[ "$install_it" == [yY] ]]; then
                  echo $sudo apt-get install $package
                       $sudo apt-get install $package
               fi
            fi
         else
            echo "[okay] $command already available at `which $command`"
         fi
      fi
   else
      echo "[WARNING] Sorry, we need apt-get to install $command / $package for you."
   fi
   which $command >& /dev/null
   return $?
}

if [ "$dryrun" != "true" ]; then
   $sudo apt-get update &> /dev/null
fi

offer_install_with_apt 'git'          'git-core' # These are dryrun safe.
offer_install_with_apt 'curl'         'curl'
offer_install_with_apt 'rapper'       'raptor-utils'
offer_install_with_apt 'unzip'        'unzip'
offer_install_with_apt 'sqlite3'      'sqlite3 libsqlite3-dev'

offer_install_with_apt 'easy_install' 'python-setuptools' # dryrun aware
V=`python --version 2>&1 | sed 's/Python \(.\..\).*$/\1/'`
eggs="pyparsing surf.sparql_protocol ckanclient BeautifulSoup cowboy"
for egg in $eggs; do
   # See also https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/install-csv2rdf4lod-dependencies.sh
   # See also https://github.com/timrdf/DataFAQs/blob/master/bin/install-datafaqs-dependencies.sh
   eggReg=`echo $egg | sed 's/-/./g;s/_/./g'`
   find /usr/local/lib/python$V/dist-packages -mindepth 1 -maxdepth 1 | grep -i $eggReg &> /dev/null
   status=$?
   there=`find /usr/local/lib/python$V/dist-packages -mindepth 1 -maxdepth 1 -type d | grep -i $eggReg` 
   #           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ this path is $base/python/lib/site-packages if -z $sudo TODO
   if [[ -n "$there" ]]; then 
      echo "[okay] python egg \"$egg\" is already available at $there (${#there} $eggReg $status)"
   else
      echo $pdiv
      echo $TODO $sudo easy_install -U $egg
      if [ "$dryrun" != "true" ]; then
         read -p "Try to install python module $egg using the command above? (y/n) " -u 1 install_it
         if [[ "$install_it" == [yY] ]]; then
                 $sudo easy_install -U $egg
                # SUDO IS NOT REQUIRED HERE.
            # see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Installing-csv2rdf4lod-automation---complete
            pdiv=""
         fi
      fi
   fi
done



exit

# This stuff doesn't check to see if it's already there, so was replaced by the loop above (which is shared with the csv2rdf4lod installer)

echo
echo -n "Try to install python libraries? (y/N) "
read -u 1 install_it
if [ "$install_it" == "y" ]; then

   echo
   echo -n "Try to install sadi.py? (y/N) "
   read -u 1 install_it
   if [ "$install_it" == "y" ]; then
      pythonV=`python --version 2>&1 | sed -e 's/Python //; s/..$//'`
      echo "installing sadi.python for python $pythonV"
      # http://sadi.googlecode.com/files/sadi-0.1.4-py$pythonV.egg
      echo sudo easy_install "https://github.com/timrdf/DataFAQs/raw/master/lib/sadi.python/sadi-0.1.5-py$pythonV.egg"
           sudo easy_install "https://github.com/timrdf/DataFAQs/raw/master/lib/sadi.python/sadi-0.1.5-py$pythonV.egg"
   fi
   # installed:
   # SuRF-1.1.4_r352-py2.7.egg
   # surf.rdflib-1.0.0_r338-py2.7.egg 
   # rdflib-3.2.1-py2.7.egg
   # rdfextras-0.2-py2.7.egg
   # rm -rf SuRF* surf.rdflib* rdflib* rdfextras*

   #echo sudo easy_install surf
   #sudo easy_install surf

   echo sudo easy_install pyparsing # TODO: consider the dependency chain; figure out which are already done by sadi*.egg above.
   sudo easy_install pyparsing

   #echo sudo easy_install rdfextras # still got error even after installing sadi.python
   #sudo easy_install rdfextras

   #echo sudo easy_install -U rdflib==3.2.0
   #sudo easy_install -U rdflib==3.2.0

   #echo sudo easy_install -U surf.rdflib
   #sudo easy_install -U surf.rdflib

   echo sudo easy_install -U surf.sparql_protocol
   sudo easy_install -U surf.sparql_protocol

   #echo
   #echo -n "Try to install allegro graph .py? (y/N) "
   #read -u 1 install_it
   #if [ "$install_it" == "y" ]; then
   #   echo WARNING: AG is bunk
      #echo sudo easy_install -U surf.allegro_franz
      #sudo easy_install -U surf.allegro_franz
      # Still need allegrograph... :-(
      # apt-get install python-cjson python-pycurl
   #fi

   echo
   echo -n "Try to install ckanclient? (y/N) "
   read -u 1 install_it
   if [ "$install_it" == "y" ]; then
      echo
      echo sudo easy_install http://pypi.python.org/packages/source/c/ckanclient/ckanclient-0.9.tar.gz
      sudo easy_install http://pypi.python.org/packages/source/c/ckanclient/ckanclient-0.9.tar.gz
   fi

   echo
   echo -n "Try to install BeautifulSoup? (y/N) "
   read -u 1 install_it
   if [ "$install_it" == "y" ]; then
      echo
      echo sudo easy_install BeautifulSoup
      sudo easy_install BeautifulSoup
   fi
fi
