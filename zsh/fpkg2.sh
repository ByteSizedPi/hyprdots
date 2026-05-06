#!/bin/bash

tmpinstalled=$(mktemp)
dnf repoquery --installed --qf '%{name}\n' >"$tmpinstalled"
echo "$tmpinstalled"
