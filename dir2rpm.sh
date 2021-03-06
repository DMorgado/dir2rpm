#! /bin/bash
## Copyright (c) 2009 Mildred Ki'Lya < mildred593(at)online.fr>
##
## Permission is hereby granted, free of charge, to any person
## obtaining a copy of this software and associated documentation
## files (the "Software"), to deal in the Software without
## restriction, including without limitation the rights to use,
## copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the
## Software is furnished to do so, subject to the following
## conditions:
##
## The above copyright notice and this permission notice shall be
## included in all copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
## EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
## OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
## NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
## HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
## WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
## FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
## OTHER DEALINGS IN THE SOFTWARE.
#**********************************************************************
#
# Additional modifications were made by Ivan de Gusmão Apolonio
#
#**********************************************************************

op_help=false
op_run=true
op_name=
 while true; do
  case "$1" in
        --help)
          op_help=true
          op_run=false
          ;;
        --name)
          shift
          op_name="$1"
          ;;
        --)         shift; break        ;;
        --*)        echo "`basename "$0"`: unknown option $1" >&2; exit 1 ;;
        -*)
          opts="${1[2,-1]}"
          while [[ 0 -lt "${#opts}" ]]; do
                case "${opts[1]}" in
                  h)  op_help=true    ;   op_run=false    ;;
                  n)  shift           ;   op_name="$1"    ;;
                  *)  echo "`basename "$0"`: unknown option -${opts[1]}" >&2; exit 1 ;;
                esac
                opts="${opts[2,-1]}"
          done
          ;;
        *) break ;;
        esac
        shift
done
  
op_dir="$1"
op_pkgname="$2"

name_ver_rel=$op_pkgname
if [[ -z "$name_ver_rel" ]]; then
name_ver_rel=$op_dir
fi

#
# Look at the release number: [0-9]*
#

rel=${name_ver_rel##*-}
if [[ -z "${rel//[0-9]/}" ]]; then
# rel is valid or empty
  [[ -z "$rel" ]] && rel=1
  name_ver=${name_ver_rel%-*}
  valid_rel=true
else
  rel=1
  name_ver=$name_ver_rel
  valid_rel=false
fi
  
#
# Look at the version number: [0-9\.]*
#
  
ver=${name_ver##*-}
if [[ -z "${ver//[0-9.]/}" ]]; then
  # ver is valid or empty
  [[ -z "$ver" ]] && ver=1.0
  name=${name_ver%-*}
elif $valid_rel; then
  # we mistook the version number for the release number
  ver=$rel
  rel=1
else
  ver=1.0
  name=$name_ver
fi
  
echo $name - $ver - $rel
  
if $op_help; then
  echo "SYNOPSYS"
  echo
  echo "    `basename "$0"` [OPTIONS] DIR [PKGNAME]"
  echo
  echo
  echo "DESCRIPTION"
  echo
  echo "    Create a RPM file based on the files in DIR"
  echo
  echo
  echo "OPTIONS"
  echo
  echo "    -h, --help"
  echo
  echo "    -n, --name NAME"
  echo
  exit 0
fi
  
if ! $op_run; then
      exit 0
fi
  
if [ -z "$op_name" ]; then
  op_name=$op_dir
fi
  
rootdir=`pwd`/$op_dir
specfile=$op_dir.spec
rcfile=$op_dir.rc
all_files=$(find $op_dir -not -type d | cut -c$((${#op_dir}+1))-)
all_dirs=$(find $op_dir  -type d | sed -e "s/$op_dir/%dir /" | sed 1d)
  
cat >$rcfile << EOF
EOF
cat >$specfile << EOF

%define _topdir $rootdir.rpmbuild
Summary: $name package Generated from binary by Demoiselle Infra
Name: $name
Version: $ver
Release: $rel
Group: Tools
License: Unknown check on installed folder
BuildRoot: $rootdir
AutoReqProv: no
Packager: Comunidade Framework Demoiselle <demoiselle-users@lists.sourceforge.net>

%description
%define _topdir $rootdir.rpmbuild

%prep
%define _topdir $rootdir.rpmbuild

%build
%define _topdir $rootdir.rpmbuild

%install
%define _topdir $rootdir.rpmbuild

echo BEGIN INSTALL
  
if [ a'$rootdir' != a"\$RPM_BUILD_ROOT" ]; then
  rmdir "\$RPM_BUILD_ROOT"
  #ln -s '$rootdir' "\$RPM_BUILD_ROOT"
  cp --archive '$rootdir' "\$RPM_BUILD_ROOT"
fi

echo END INSTALL
  
%clean

%define _topdir $rootdir.rpmbuild
  
if [ a'$rootdir' != a"\$RPM_BUILD_ROOT" ]; then
  rm -rf "\$RPM_BUILD_ROOT"
  fi
  
%files
%define _topdir $rootdir.rpmbuild
$all_dirs
  $all_files

%post 
chmod 777 -R /opt/demoiselle/
  
EOF

mkdir -p $rootdir.rpmbuild/{,BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

echo rpmbuild -bb --define "'_topdir $rootdir.rpmbuild'" $specfile
rpmbuild -bb --define "_topdir $rootdir.rpmbuild" $specfile

echo "Status: $?"
echo
while read rpm; do
cp $rpm `basename $rpm`
echo "Created `basename $rpm`"
done <<<$(find $rootdir.rpmbuild/RPMS -type f -name "*.rpm")
#rm -rf $specfile $rcfile $rootdir.rpmbuild
  
exit 0
