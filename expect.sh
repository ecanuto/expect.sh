#!/usr/bin/env sh
#
#  expect.sh - shell unit testing framework
#
#  https://github.com/ecanuto/expect.sh
#
#  Author: Everaldo Canuto <everaldo.canuto@gmail.com>
#
#  This is free and unencumbered software released into the public domain.
#
#  Anyone is free to copy, modify, publish, use, compile,  sell,  or  distribute
#  this software, either in source code form or as a compiled  binary,  for  any
#  purpose, commercial or non-commercial, and by any means.
#
#  In jurisdictions that recognize copyright laws, the author or authors of this
#  software dedicate any and all copyright  interest  in  the  software  to  the
#  public domain. We make this dedication for the benefit of the public at large
#  and to the detriment of our heirs and successors. We intend  this  dedication
#  to be an overt act of relinquishment in perpetuity of all present and  future
#  rights to this software under copyright law.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY  KIND,  EXPRESS  OR
#  IMPLIED, INCLUDING BUT NOT LIMITED  TO  THE  WARRANTIES  OF  MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT  SHALL  THE
#  AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,  WHETHER  IN  AN
#  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN  CONNECTION
#  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# global consts
PROGRAM=${0##*/}
VERSION="0.1.0"
VERBOSE=false

# global vars
FILELIST=""
CURRFILE=""

usage() {
	cat <<-EOF
		Usage: $PROGRAM [options] file ...

		Options:
		    -h, --help      display this help and exit
		    -V, --version   output version information and exit
	EOF
}

version() {
	echo "$PROGRAM $VERSION"
}

display_mfnl() {
	local maxlength=0
	local filename
	for filename in $FILELIST; do
		[ ${#filename} -gt $maxlength ] && maxlength=${#filename}
	done
	_DISPLAY_MAX_FILENAME_LENGTH=$maxlength
}

display() {
	printf "=> %-${_DISPLAY_MAX_FILENAME_LENGTH}s - %s - %s\n" "$2" "$1" "$3"
}

parse_param() {
	local ignpattern ignoreline ignoretext
	ignpattern="^[[:space:]]*[\*#][[:space:]]*@$1"
	ignoreline=$(grep -m1 "$ignpattern" $CURRFILE)
	ignoretext=${ignoreline#*\"}
	ignoretext=${ignoretext%\"*}
	if [ ! -z "$ignoreline" ]; then
		echo "$ignoretext"
		return 1
	else
		echo "$ignoretext"
		return 0
	fi
}

assert() {
	local ignore_message expect_result assert_result
	ignore_message=$(parse_param ExpectIgnore)
	if [ $? -eq 1 ]; then
		display "SKIP" "$CURRFILE" "$ignore_message"
		return 0
	fi

	expect_result=$(parse_param ExpectResult)
	if [ $? -ne 1 ]; then
		display "FAIL" "$CURRFILE" "Expected result not found"
		return 1
	fi

	assert_result=$(./$CURRFILE)
	if [ "$assert_result" != "$expect_result" ]; then
		display "FAIL" "$CURRFILE"
		if [ $VERBOSE = true ]; then
			echo " > Expected result:"
			echo "   $expect_result"
			echo " > Assert result:"
			echo "   $assert_result"
		fi
		return 1
	fi

	display " OK " "$CURRFILE"
	return 0
}

while [ $# -gt 0 ]; do
	case $1 in
		"-h" | "--help" | "help")
			usage
			exit 0
			;;
		"-V" | "--version" | "version")
			version
			exit 0
			;;
		"-v" | "--verbose")
			VERBOSE=true
			;;

		-?*)
			printf 'Unknown option: %s\n' "$1" >&2
			exit 1
			;;
		*)
			FILELIST=$@
			break
			;;
	esac
	shift
done

# no files selected
if [ -z "$FILELIST" ]; then
	usage
	exit 1
fi

# calculate maximum file name lenght
display_mfnl $FILELIST

# run all specified test files
RESULT=0
echo "$PROGRAM $VERSION"
echo "---------------"
for CURRFILE in $FILELIST; do
	assert "$CURRFILE"
	if [ $? -ne 0 ]; then
		RESULT=1
	fi
done

exit $RESULT
