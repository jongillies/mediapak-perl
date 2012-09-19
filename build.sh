#!/usr/local/bin/bash

PATH=/cygdrive/c/perl/bin:$PATH

BIN_MKDIR=/bin/mkdir
BIN_CP=/bin/cp
BIN_PERL2EXE=/cygdrive/c/perl2exe/perl2exe
BIN_TAR=/usr/bin/tar
BIN_ZIP=/usr/bin/zip
BIN_RM=/bin/rm

REVISION=`svn info | grep '^Last Changed Rev: ' | sed 's/.*: //'`
REV_DATE=`svn info | grep '^Last Changed Date: ' | sed 's/.*: //'`


echo "REVISION is $REVISION"
echo "DATE is $REV_DATE"

REL_DIR="release.$REVISION"

if [[ -e $REL_DIR ]]; then
	echo "WARNING! $REL_DIR already exists, files will be overwritten!"
else
	$BIN_MKDIR $REL_DIR
	echo "Created release directory $REL_DIR"
fi



PROGRAMS="gencache.pl mkpak.pl ckpak.pl cpmissing.pl cleaner.pl path-detector.pl create-link-data.pl"
ALL_PERL=`ls *.pl`

for PROGRAM in ${PROGRAMS} ; do

	EXE=`echo $PROGRAM | sed s/pl$/exe/`
	echo Building $PROGRAM source...
	sed "s/_____VERSION_____/${REVISION}/g" < $PROGRAM > $REL_DIR/$PROGRAM.1
	sed "s/_____DATE_____/${REV_DATE}/g" < $REL_DIR/$PROGRAM.1 > $REL_DIR/$PROGRAM
	rm $REL_DIR/$PROGRAM.1

	if [[ -e $BIN_PERL2EXE ]]; then
		echo "Building $PROGRAM.exe..."
		$BIN_PERL2EXE $REL_DIR/$PROGRAM
		mv $EXE $REL_DIR
	else
		echo "Can't locate $BIN_PERL2EXE, skipping Windows build of exe"
	fi 

done

for PROGRAM in ${ALL_PERL} ; do

	REQUIRE_LIST=`grep "^require " $PROGRAM | sed 's/require .\"//' | sed 's/\".*$//'`

	for ENTRY in ${REQUIRE_LIST} ; do
		if [[ -e $REL_DIR/$ENTRY ]]; then
			echo "Required modules $ENTRY already copied."
		else
			$BIN_CP $ENTRY $REL_DIR
			echo "$ENTRY to be copied..."
		fi
	done

done


echo ""
echo "Release $REVISION is now available in $REL_DIR"

if [[ -e  $REL_DIR.zip ]]; then
	echo "Removing existing  $REL_DIR.zip"
	$BIN_RM $REL_DIR.zip
fi

echo "Creating $REL_DIR.zip..."
$BIN_ZIP $REL_DIR.zip $REL_DIR/*.* 1> /dev/null


#
# Add speical files to the unix release for Jon
#
SPECIAL="va.pl vlink.pl linkfiles.pl filelink.pl"

for PROGRAM in ${SPECIAL} ; do

	sed "s/_____VERSION_____/${REVISION}/g" < $PROGRAM > $REL_DIR/$PROGRAM.1
	sed "s/_____DATE_____/${REV_DATE}/g" < $REL_DIR/$PROGRAM.1 > $REL_DIR/$PROGRAM
	rm $REL_DIR/$PROGRAM.1

done

if [[ -e  $REL_DIR.tar.gz ]]; then
	echo "Removing existing  $REL_DIR.tar.gz"
	$BIN_RM $REL_DIR.tar.gz
fi

echo "Creating $REL_DIR.tar.gz..."
$BIN_TAR --exclude=*.exe -zcvf $REL_DIR.tar.gz $REL_DIR/ 1> /dev/null


