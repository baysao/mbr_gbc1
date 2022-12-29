#!/bin/sh
ROOT_DIR=$1
if [ -z "$ROOT_DIR" ]; then
	echo "Miss ROOT_DIR."
	exit 1
fi



#apk add --no-cache bash rsync py3-virtualenv py3-pip python3 supervisor
cd $ROOT_DIR
if [ ! -L "bin/openresty" ]; then
	ln -sf /usr/local/openresty bin/openresty
fi
if [ ! -f "bin/openresty/luajit/bin/lua" ];then
   cd bin/openresty/luajit/bin
   ln -sf luajit lua
   cd $ROOT_DIR
fi

if [ ! -f "bin/openresty/site/lualib/socket.lua" ]; then
    rsync -avz bin/openresty_lib/luajit/share/lua/5.1/* bin/openresty_lib/luajit/lib/lua/5.1/* bin/openresty/site/lualib/
fi
rm $ROOT_DIR/tmp/*.pid $ROOT_DIR/tmp/*.lock $ROOT_DIR/db/*.lock
$ROOT_DIR/start_server
