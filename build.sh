#!/bin/bash
set -e

# site config
export BROKER=https://broker.getupcloud.com
export SITE=http://getupcloud.com/
export REGISTER=https://broker.getupcloud.com/getup/account/signup/
export SUPPORT=https://getup.zendesk.com/home/
export DEBUG=0
export BUILD_ID=${BUILD_ID:-testing-`date +%Y%m%d%H%M%S`}

# languages we support
LANGS=(
	pt_BR
	en_US
)

# what is the main site language
ROOT_LANG=pt_BR

# gettext config
export TEXTDOMAINDIR=$PWD/locale
export TEXTDOMAIN=site

echo
echo Creating initial build...
rm -rf build
mkdir build
for po in locale/*/LC_MESSAGES/*po; do
	msgfmt $po -o ${po%.po}.mo
done

# copy common files
echo
echo Copying common files...
cp -a common/* build/

# execute all templates, creating resulting file inside build/ with
# extension striped
echo
echo Building from template...
cat <<EOF
  BROKER=$BROKER
  SITE=$SITE
  REGISTER=$REGISTER
  DEBUG=$DEBUG
  LANGS=${LANGS[*]}

EOF

cd templates

# templates are simple shell scripts ending in .sh
find -type f -name '*.sh' | while read source; do
	for lang in ${LANGS[*]}; do
		# format language name to use in templates
		# ex: pt_BR -> pt-br
		export LANGUAGE_ID=`echo $lang|tr -t _[A-Z] -[a-z]`

		# find out where this file lives inside ../build/
		[ $lang == $ROOT_LANG ] && unset LANG_DIR || LANG_DIR=${LANGUAGE_ID%-*}/

		# cosmetics
		target=$LANG_DIR${source#./}
		target=../build/${target%.sh}
		echo " $source -> $target ($LANGUAGE_ID)"

		# create prefix dir
		# ex: some/dir/path.html -> some/dir/
		mkdir -p ${target%/*}

		# real work
		LANGUAGE=$lang source $source > $target
	done
done

TEMP_FILES=`find ../build -name '*.swp' -o -name '*.bak' -o -name '*.bkp'`
if [ -n "$TEMP_FILES" ]; then
	echo
	echo Removing temp files...
	rm -vf $TEMP_FILES
fi

