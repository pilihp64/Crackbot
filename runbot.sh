#!/bin/bash

function ctrl_c() {
	echo -e '\nExiting on SIGINT / Ctrl-C...'
	exit
}

# Catch SIGINT and exit
trap ctrl_c SIGINT

luaver=$(which luajit)
if [ $? -ne 0 ]; then
	luaver=$(which lua5.1)
fi
if [ $? -ne 0 ]; then
        luaver=$(which lua)
fi
if [ $? -ne 0 ]; then
	echo "Could not find a valid Lua install. Crackbot requires luajit or lua 5.1 to run"
	exit 1
fi

echo "Using $luaver"
while :
do
	echo "(Re)starting Crackbot - Press Ctrl-C to break."
	$luaver init.lua
	sleep 3
done
