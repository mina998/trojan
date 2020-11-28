#!/bin/bash

version=$("wget -qO- -t1 -T2 'https://api.github.com/repos/lhc70000/iina/releases/latest'")

echo version

