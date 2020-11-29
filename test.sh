#!/bin/bash


curl "https://api.github.com/repos/trojan-gfw/trojan/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g'
