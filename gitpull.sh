#!/usr/bin/env bash

abs_path=$(dirname $(readlink -f $0))
cd ${abs_path}
# cd `dirname $0`

commit_comment=$1

if [[ ! -d .git ]]; then
    git init
    read -p "please input the git repository name: " repository_name
    git remote add origin git@github.com:mingregister/${repository_name}.git
    # git remote add origin git@192.168.160.193:root/${repository_name}.git
    # git pull 和git clone是不一样的.
    git pull -u origin master
    exit 0
fi

git add .
git commit -m "${commit_comment}"
git push -u origin master

# # 放弃当前所有未commit的修改,回退到上次commit的版本
# git checkout .
