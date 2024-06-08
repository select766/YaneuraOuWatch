#!/bin/bash

cd $(dirname $BASH_SOURCE)
$HOME/.anyenv/envs/nodenv/shims/node index.js 2>>log.log
