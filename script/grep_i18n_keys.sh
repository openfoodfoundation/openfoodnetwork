#!/bin/sh
#
# Try to find all unused translation keys in the source code.
# This prints all keys that cannot be found.
# It is not reliable and will find some strings that are not keys.
# It will also print keys that are only used within a Gem like Spree.
# Some keys might not be used, but appear in another context and will not be printed.
# This is just a rough tool to identify some unused keys.
#
# More sophisticated: https://github.com/glebm/i18n-tasks

egrep '^ *(.*):(.+)$' config/locales/en.yml |
 tr -d ' ' | cut -d ':' -f1 |
 while read key; do
   if ! git grep -q "\<$key\>" -- app lib; then
     echo "$key";
   fi;
 done
