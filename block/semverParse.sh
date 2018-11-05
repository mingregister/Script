#!/bin/bash

# 字符串切割，输出没有被“切割(匹配)”的部分。
semverParse() {
    major="${1%%.*}"
    minor="${1#$major.}"
    minor2="${minor%%.*}"
    patch="${1#$major.$minor.}"
    patch2="${patch%%[-.]*}"
}

semverParse "17.03.2-ce"
# %%从尾开始，最长匹配，输出17
echo ${major}
# #从头开始，最短匹配，03.2-ce
echo ${minor}
# 输出03
echo ${minor2}
# 输出17.03.2-ce
echo ${patch}
# 输出17
echo ${patch2}

