#!/usr/bin/env bash
set -e
set -i
PROG=$(basename $0)
PROGDIR=$(dirname $0)

DEBUG=false
ADMIN=admin
PASSWD=admin
PGPORT=${PGPORT:-5432}
HOST=localhost
MAJ=
MIN=
PAT=
TRANSLATIONS=false
export PGOPTIONS="-c client_min_messages=warning"

XTUPLEDIR=$(pwd)

#  github repository       default=default github branch
#                          |     true=use this in the build
#                          |     |       repository URL prefix (git protocol for private repos)
#                          |     |       |                      run make to build extensions
#                          |     |       |                      |         regex: d = distribution, e = enterprise, ...
#                          |     |       |                      |         |
  module=1                 tag=2 build=3 source=4               runmake=5 edition=6
declare -a CONFIG=(\
  "xtuple                  default true  https://github.com/xtuple  false skip    " \
  "private-extensions      default true  git@github.com:xtuple      true  skip    " \
  "qt-client               default true  https://github.com/xtuple  false skip    " \
  "updater                 default true  https://github.com/xtuple  false skip    " \
  "address-verification    default true  https://github.com/xtuple  true  ^[demp] " \
  "connect                 default true  git@github.com:xtuple      true  ^[e]    " \
  "enhanced-pricing        default true  git@github.com:xtuple      true  ^[e]    " \
  "fixed-assets            default true  https://github.com/xtuple  true  ^[e]    " \
  "fixed-assets-commercial default true  git@github.com:xtuple      true  ^[e]    " \
  "nodejsshim              default true  https://github.com/xtuple  true  ^[dem]  " \
  "payment-gateways        default true  git@github.com:xtuple      true  ^[e]    " \
  "xdruple-extension       default false git@github.com:xtuple      true  ^[e]    " \
  "xtcommission            default true  git@github.com:xtuple      true  ^[e]    " \
  "xtdash                  default true  git@github.com:xtuple      true  ^[dem]  " \
  "xtdesktop               default true  https://github.com/xtuple  true  ^[demp] " \
  "xtprjaccnt              default true  git@github.com:xtuple      true  ^[e]    " \
  "xtte                    default true  https://github.com/xtuple  true  ^[demp] " \
)

usage() {
  local CNT=0
  cat <<EOUSAGE
$PROG [ -x ] [ -h hostname ] [ -p port ] [ -U username ] [ -W password ] [ --XXX=tag [ git-repo-url ] [ -t | +t ] [ Major Minor Patch ]

-h, -p, -U, and -W describe database server connection information
-t              do not include translations in the updater packages
+t              include translations in the updater packages
-x              turns on debugging
--XXX=tag       "tag" is the commit-ish to check out the XXX repository
  git-repo-url  is an optional argument describing where to get the repository
                if not from the default, which is typically github.com/xtuple/XXX
EOUSAGE
  echo -n "possible values of XXX: "
  for KEY in $(configKeys) ; do
    echo "	$KEY"
  done
  echo
}

configKeys() {
  local ROW ROWNUM KEYS
  for (( ROWNUM=0 ; ROWNUM < ${#CONFIG[@]} ; ROWNUM++ )) ; do
    ROW="${CONFIG[$ROWNUM]}"
    KEYS="$KEYS $(echo $ROW | awk '{print $1}')"
  done
  echo $KEYS
}

# getConfig module column-name
getConfig() {
  local MODULE=$1 COL="${!2}" ROWNUM

  for (( ROWNUM=0; ROWNUM < ${#CONFIG[@]} ; ROWNUM++ )) ; do
    if [ "$MODULE" = $(awk '{ print $1 }' <<< "${CONFIG[$ROWNUM]}") ] ; then
      awk -v COLNUM=$COL '{ print $COLNUM }' <<< "${CONFIG[$ROWNUM]}"
      return 0
    fi
  done
  return 1
}

# setConfig module column-name value
setConfig() {
  local MODULE=$1 COL=${!2} ROWNUM=0 NEWROW

  for (( ROWNUM=0 ; $ROWNUM < ${#CONFIG[@]} ; ROWNUM++ )) ; do
    if [ "$MODULE" = $(echo "${CONFIG[$ROWNUM]}" | awk '{ print $1 }') ] ; then
      CONFIG[$ROWNUM]=$(awk -v COL=$COL -v NEWVAL=$3 '{ $COL = NEWVAL ; print }' <<< ${CONFIG[$ROWNUM]} )
      return 0
    fi
  done

  return 1
}

gitco() {
  local REPO="$1" GITDEST="${2:-$1}"
  local GITTAG="${3:-$(getConfig $REPO tag)}" GITURL="${4:-$(getConfig $REPO source)}"

  if [ "$GITTAG" == skip -a -d $XTUPLEDIR/../$REPO ] ; then
    return 0
  fi
  if [ ! -d $XTUPLEDIR/../$REPO ] ; then
    cd $XTUPLEDIR/..
    if [[ $GITURL =~ \.git$ ]] ; then
      git clone $GITURL $GITDEST                || return 2
    else
      git clone $GITURL/${REPO}.git $GITDEST    || return 2
    fi
  fi

  if [ "$GITTAG" != skip -a "$GITTAG" != default ] ; then
    cd $XTUPLEDIR/../$GITDEST                   || return 2
    git checkout $GITTAG                        || return 2
  fi
}

packageInfo() {
  local ATTRIBUTE=$1 PACKAGEXML=$2
  awk -v ATTR=$ATTRIBUTE -v FS='["= ]*' '$0 ~ ATTR {
                                           for (i = 0; i < NF; i++) {
                                             if ($i == ATTR) { print $(i+1); exit }
                                           }
                                         }' $PACKAGEXML
}

while [[ $1 =~ ^[-+] ]] ; do
  case $1 in
    -h) HOST=$2
        shift
        ;;
    -p) PGPORT=$2
        shift
        ;;
    -t) TRANSLATIONS=false
        ;;
    +t) TRANSLATIONS=true
        ;;
    -U) ADMIN=$2
        shift
        ;;
    -W) PASSWD=$2
        shift
        ;;
    -x) set -x
        DEBUG=true
        ;;
    --*=*)
        [[ "$1" =~ --(.*)=(.*) ]]
        REPO="${BASH_REMATCH[1]}"
        RAWTAG="${BASH_REMATCH[2]}"
        if [ "$RAWTAG" = NO ] ; then
          setConfig $REPO build false
        else
          setConfig $REPO tag   $RAWTAG
          setConfig $REPO build true
        fi
        if expr "$2" : "[^-]" ; then            # next arg is not -something
          setConfig $REPO source "$2"           # & so must be the source url
          shift
        fi
        ;;
    *)  echo "$PROG: unrecognized option $1"
        usage
        exit 1
        ;;
  esac
  shift
done

if [ $# -ge 3 ] ; then
  MAJ=$1
  MIN=$2
  PAT=$3
else
  VERSION=$(awk -v FS='"' '/version/ {
    split($4, tmp,   "+");
    split(tmp[1], parts, "\\.");
    MAJ = parts[1];
    MIN = parts[2];
    PAT = parts[3];
    if (4 in parts) { PAT = PAT parts[4]; }
    sub("-alpha", "Alpha", PAT);
    sub("-beta",  "Beta",  PAT);
    sub("-rc",    "RC",    PAT);
    printf("MAJ=%s MIN=%s PAT=%s\n", MAJ, MIN, PAT);
    exit;
  }' package.json)
  eval $VERSION
  echo $MAJ $MIN $PAT
fi

if [ $(getConfig xtuple tag) = ARGS ] ; then
  setConfig xtuple             tag ${MAJ}_${MIN}_x
fi
if [ $(getConfig private-extensions tag) = ARGS ] ; then
  setConfig private-extensions tag ${MAJ}_${MIN}_x
fi
if [ $(getConfig qt-client tag) = ARGS ] ; then
  setConfig qt-client tag ${MAJ}_${MIN}_x
fi

echo "BUILDING RELEASE ${MAJ}.${MIN}.${PAT}"

# check out the code that we need #########################################

for MODULE in $(configKeys) ; do
  if [ $(getConfig $MODULE build) = true ] ; then
    gitco $MODULE || $DEBUG
  fi
done

cd $XTUPLEDIR
rm -rf scripts/output
npm install
[ -e node-datasource/config.js ] || cp node-datasource/sample_config.js node-datasource/config.js

MODES="upgrade install"
EDITIONS="postbooks manufacturing distribution"
DATABASES="empty quickstart demo"
PACKAGES="commercialcore inventory"

if $TRANSLATIONS ; then
  cd $XTUPLEDIR
  for TRANSLATION in $(echo foundation-database/public/tables/dict/*.ts) ; do
    xsltproc --stringparam ts ../../$TRANSLATION scripts/xml/reports.xsl \
                        foundation-database/public/tables/report/*.xml | \
      sed -e '/<?xml version/d' -e 's/^/  /' >> reports.ts
    cat <<-EOHEADER > $TRANSLATION
	<?xml version="1.0" encoding="utf-8"?>
	<TS version="2.0">
	$(cat reports.ts)
	</TS>
	EOHEADER
    rm reports.ts

  done
  lrelease -silent $TRANSLATION foundation-database/public/tables/dict/*.ts
  mkdir -p scripts/output/dict/postbooks
  mv foundation-database/public/tables/dict/*.qm scripts/output/dict/postbooks

  cd ../private-extensions
  for PACKAGE in commercialcore inventory manufacturing distribution ; do
    mkdir -p $XTUPLEDIR/scripts/output/dict/$PACKAGE
    if [ -d source/$PACKAGE/foundation-database/*/tables/dict ] ; then
      # get report translations before make below removes "unused" translations
      # TODO: move report translation gathering to the individual makefiles?
      if [ -d source/$PACKAGE/foundation-database/*/tables/pkgreport ] ; then
        for TRANSLATION in $(echo source/$PACKAGE/foundation-database/*/tables/dict/*.ts) ; do
          xsltproc --stringparam ts ../../../private-extensions/$TRANSLATION ../xtuple/scripts/xml/reports.xsl \
                                                source/$PACKAGE/foundation-database/*/tables/pkgreport/*.xml | \
            sed -e '/<?xml version/d' -e 's/^/  /' >> $TRANSLATION.rpt
        done
      fi

      cd source/$PACKAGE/foundation-database/*/tables/dict
      make
      cd $XTUPLEDIR/../private-extensions

      if [ -d source/$PACKAGE/foundation-database/*/tables/pkgreport ] ; then
        for TRANSLATION in $(echo source/$PACKAGE/foundation-database/*/tables/dict/*.ts) ; do
          sed -i -e '/<\/TS>/d' $TRANSLATION
          cat $TRANSLATION.rpt >> $TRANSLATION
          echo '</TS>' >> $TRANSLATION
          rm $TRANSLATION.rpt
        done
      fi
    fi

    if [ -e source/$PACKAGE/foundation-database/*/tables/dict/ts.pro ] ; then
      lrelease -silent source/$PACKAGE/foundation-database/*/tables/dict/ts.pro
      mv source/$PACKAGE/foundation-database/*/tables/dict/*.qm ../xtuple/scripts/output/dict/$PACKAGE
    fi
  done
fi

cd $XTUPLEDIR

for MODE in $MODES ; do
  for PACKAGE in postbooks commercialcore inventory manufacturing distribution ; do
    if [ "$MODE" = install ] ; then
      MANIFESTNAME=frozen_manifest.js
    else
      MANIFESTNAME=manifest.js
    fi
    if [ "$PACKAGE" = postbooks ] ; then
      MANIFESTDIR=foundation-database
    else
      MANIFESTDIR=../private-extensions/source/$PACKAGE/foundation-database
    fi
    if [ "$PACKAGE" != postbooks -a "$PACKAGE" != commercialcore -o "$MODE" != install ] ; then
      scripts/explode_manifest.js -m $MANIFESTDIR/$MANIFESTNAME -n $PACKAGE-$MODE.sql
    fi
  done
done

if $TRANSLATIONS ; then
  NO_TRANSLATIONS="--param no-translations false()"
else
  NO_TRANSLATIONS="--param no-translations true()"
fi

for EDITION in $EDITIONS enterprise ; do
  if [ "$EDITION" = manufacturing ] ; then
    MODES="$MODES add"
  fi
  for MODE in $MODES ; do
    if [ "$EDITION" != postbooks -o "$MODE" != install ] ; then
      cd ${XTUPLEDIR}
      if [ "$MODE" = add ] ; then
        NAME=add-manufacturing-to-distribution
      else
        NAME=$EDITION-$MODE
      fi
      FULLNAME=$NAME-$MAJ.$MIN.$PAT
      mkdir scripts/output/$FULLNAME
      xsltproc $NO_TRANSLATIONS -o scripts/output/$FULLNAME/package.xml scripts/xml/build.xsl scripts/xml/$NAME.xml
      case $EDITION in
        postbooks)     SUBPACKAGES="postbooks"                                        ;;
        distribution)  SUBPACKAGES="postbooks commercialcore inventory distribution"  ;;
        manufacturing) SUBPACKAGES="postbooks commercialcore inventory manufacturing" ;;
        enterprise)    SUBPACKAGES="postbooks commercialcore inventory distribution manufacturing" ;;
      esac
      SUBMODES=upgrade
      if [ $MODE = install -o $MODE = add ] ; then
        SUBMODES="$SUBMODES install"
      fi
      if [ $MODE = add ] ; then
        SUBPACKAGES=manufacturing
      fi
      for SUBPACKAGE in $SUBPACKAGES ; do
        for SUBMODE in $SUBMODES ; do
          if [ "$SUBPACKAGE" != postbooks -a "$SUBPACKAGE" != commercialcore -o "$SUBMODE" != install ] ; then
            cp scripts/output/$SUBPACKAGE-$SUBMODE.sql scripts/output/$FULLNAME
          fi
        done

        # german is a standard translation language; use it as a proxy for all
        if [ -e scripts/output/dict/$SUBPACKAGE/*de.qm ] ; then
          cp scripts/output/dict/$SUBPACKAGE/*.qm scripts/output/$FULLNAME
        fi
      done
      cd scripts/output
      tar -zcvf $FULLNAME.gz $FULLNAME/
    fi
  done
  MODES="upgrade install"
done

cd ${XTUPLEDIR}/..
if [ ! -e updater/bin/updater ] ; then
  cd qt-client
  git submodule update --init --recursive
  cd openrpt
  qmake
  make
  cd ../common
  qmake
  make
  cd ../../updater
  qmake
  make
  cd ${XTUPLEDIR}
fi
export LD_LIBRARY_PATH=${XTUPLEDIR}/../qt-client/openrpt/lib:${XTUPLEDIR}/../qt-client/lib:$LD_LIBRARY_PATH

cd ${XTUPLEDIR}

for EDITION in $EDITIONS ; do
  for DATABASE in $DATABASES ; do
    scripts/build_app.js -d ${EDITION}_${DATABASE} --databaseonly -e foundation-database -i -s foundation-database/${DATABASE}_data.sql
    case $EDITION in
      distribution)  PACKAGELIST="commercialcore inventory distribution"  ;;
      manufacturing) PACKAGELIST="commercialcore inventory manufacturing" ;;
      *)             PACKAGELIST=""                                       ;;
    esac
    for PACKAGE in $PACKAGELIST ; do
      scripts/build_app.js -d ${EDITION}_${DATABASE} --databaseonly -e ../private-extensions/source/$PACKAGE/foundation-database -f
    done

    PKGFILE=scripts/output/$EDITION-upgrade-$MAJ.$MIN.$PAT.gz
    if [ -e $PKGFILE ] ; then
      ../updater/bin/updater -h $HOST -U $ADMIN -p $PGPORT -d ${EDITION}_${DATABASE} -autorun -f $PKGFILE
    fi
  done
done

awk '/databaseServer: {/,/}/ {
      if ($1 == "hostname:") { $2 = "\"'$HOST'\",";  }
      if ($1 == "port:")     { $2 = "'$PGPORT',";      }
      if ($1 == "admin:")    { $2 = "\"'$ADMIN'\","; }
      if ($1 == "password:") { $2 = "\"'$PASSWD'\""; }
    }
    { print
    }' node-datasource/config.js > scripts/output/config.js

for EDITION in $EDITIONS ; do
  for DATABASE in $DATABASES ; do
    DB=${EDITION}_${DATABASE}
    for MODULE in $(configKeys) ; do
      if [[ ${EDITION} =~ $(getConfig $MODULE edition) ]] &&
         [ $(getConfig $MODULE build) = 'true' ] &&
         [ -d $XTUPLEDIR/../$MODULE/packages ] ; then
        cd $XTUPLEDIR/../$MODULE
        for MAKEFILE in "$(find * -name Makefile | \
                           egrep -v 'dict|node_modules|node-datasource|test|updatescripts')" ; do
          pushd $(dirname $MAKEFILE)
          if  $TRANSLATIONS ; then make ; else make no-translations || make ; fi
          popd
        done
        for PACKAGEXML in "$(find * -name package.xml)" ; do
          ../updater/bin/updater -h $HOST -U $ADMIN -p $PGPORT -d $DB -autorun -D \
                                 -f packages/$(packageInfo name $PACKAGEXML)-$(packageInfo version $PACKAGEXML).gz
        done
      fi
    done
    pg_dump --host $HOST --username $ADMIN --port $PGPORT --format c --file $XTUPLEDIR/$DB-$MAJ.$MIN.$PAT.backup $DB
  done
done

#cleanup
cd ${XTUPLEDIR}
for PACKAGE in postbooks commercialcore inventory manufacturing distribution ; do
  for MODE in $MODES ; do
    if [ $PACKAGE != postbooks -o $MODE != install ] ; then
      rm -rf scripts/output/$EDITION-$MODE.sql
    fi
  done
done
for EDITION in $EDITIONS enterprise ; do
  for MODE in $MODES ; do
    if [ $EDITION != postbooks -o $MODE != install ] ; then
      rm -rf scripts/output/$EDITION-$MODE-$MAJ.$MIN.$PAT/
    fi
  done
done
rm -rf scripts/output/add-manufacturing-to-distribution-$MAJ.$MIN.$PAT/
rm -rf scripts/output/config.js
rm -rf scripts/output/dict
rm -f  distribution_demo-$MAJ.$MIN.$PAT.backup  # because it's useless
