semverParse() {
    major="${1%%.*}"
    minor="${1#$major.}"
    minor2="${minor%%.*}"
    patch="${1#$major.$minor.}"
    patch2="${patch%%[-.]*}"
}

semverParse "17.03.2-ce"
echo ${major}
echo ${minor}
echo ${minor2}
echo ${patch}
echo ${patch2}

