# shellcheck shell=bash
#
#   Copyright (c) 2021 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#   Neither the name of Mulle kybernetiK nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#   POSSIBILITY OF SUCH DAMAGE.
#
MULLE_SEMVER_SEARCH_SH='included'

#
# to be able to parse the following functions, we have to turn extglob on here
#
semver::search::usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} search [options] <qualifier> <version>*

   Find the highest version that matches the semver qualifier. If there is only
   one version given and the version is '-', versions will be read from
   standard input.

   Read https://docs.npmjs.com/cli/v6/using-npm/semver/ for the specification
   and examples. mulle-semver does not match URLs and tags though!
   Especially prerelease versions are tricky!

   Hint: Don't leave "pretty" space after operators. '>= 1.4.1' really means
   '>=* =1.4.1'. Leading and trailing spaces are stripped.

Examples:
   ${MULLE_USAGE_NAME} search '>=1.1.1 <1.4' 1.1.0 1.2.0 1.4.0

Options:
   -h         : this help
   --quiet    : silently ignore non-semver version value input
EOF
   exit 1
}

#
# parsed_versions are lines of text that look like this:
# _major=1;_minor=2;_patch=3;_prerelease=4
# instead of parsing, we try to just eval the line to get
# the values. Could be good...
# It's a binary search, we stole and adapted from
# https://stackoverflow.com/questions/17666007/bash-script-binary-search
#
semver::search::_r_search_sorted_parsed_versions()
{
   local qualifier="$1"

#   [ -z "${qualifier}" ] && _internal_fail "qualifier is empty"

   local mid
   local i
   local n
   local line
   local found

   local _line
   local _major
   local _minor
   local _patch
   local _prerelease
   local _build

   if [ ${ZSH_VERSION+x} ]
   then
      setopt local_options KSH_ARRAYS
   fi
   #
   # can't use binary search here, because qualifier can't say  if
   # descending or ascending (e.g. =0.0.0||=9.9.9)
   #
   found=
   RVAL=
   i=0
   n=${#_array[@]}

   while [ ${i} -lt ${n} ]
   do
      line="${_array[${i}]}"
      eval "${line}" # get into _major etc.

      if semver::qualify::_qualify "${qualifier}" \
                         "${_major}" "${_minor}" "${_patch}" "${_prerelease}"
      then
         found="${line}"
      else
         [ ! -z "${found}" ] && break
      fi
      i=$((i + 1))
   done

   if [ ! -z "${found}" ]
   then
      RVAL="${found}"
      log_debug "MATCH: $RVAL"
      return 0
   fi

   log_debug "NOMATCH"
   return 1
}


semver::search::r_search_parsed_versions()
{
   log_entry "semver::search::r_search_parsed_versions" "$@"

   local qualifier="$1"
   local sorted="$2"

   semver::qualify::sanitized_qualifier "${qualifier}"
   qualifier="${RVAL}"

   declare -a _array
   local i
   local line 
   
   if [ ${ZSH_VERSION+x} ]
   then
      setopt local_options KSH_ARRAYS
      i=0
      .foreachline line in ${sorted}
      .do 
         _array[${i}]="${line}"
         i=$((i + 1))
      .done
   else
      IFS=$'\n' read -r -d '' -a _array <<< "${sorted}"
   fi

   semver::search::_r_search_sorted_parsed_versions "${qualifier}"
}


semver::search::search()
{
   log_entry "semver::search::search" "$@"

   local qualifier="$1"
   local quiet="$2"
   local lenient="$3"
   shift 3

   semver::qualify::sanitized_qualifier "${qualifier}"
   qualifier="${RVAL}"

   local versions

   semver::parse::r_grab_versions semver::search::usage "$@"
   versions="${RVAL}"

   local parsed_versions

   semver::parse::parse_versions "${versions}" "${quiet}" "${lenient}"
   parsed_versions="${RVAL}"

   local found

   #
   # now that we have all versions in parsed format, we need to sort
   # them
   semver::sort::r_sort_parsed_versions "${parsed_versions}"
   if ! semver::search::r_search_parsed_versions "${qualifier}" "${RVAL}"
   then
      return 2
   fi
   found="${RVAL}"

   local _line
   local _major
   local _minor
   local _patch
   local _prerelease
   local _build

   eval "${found}"
   RVAL="${_line}"

   return 0
}


semver::search::main()
{
   log_entry "semver::search::main" "$@"

   local OPTION_QUIET
   local OPTION_LENIENT

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            semver::search::usage
         ;;

         -q|--quiet)
            OPTION_QUIET='YES'
         ;;

         -l|--lenient)
            OPTION_LENIENT='YES'
         ;;

         -*)
            semver::search::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -lt 2 ] && semver::search::usage

   local qualifier="$1" ; shift

   if ! semver::search::search "${qualifier}" "${OPTION_QUIET}" "${OPTION_LENIENT}" "$@"
   then
      return 2
   fi
   printf "%s\n" "${RVAL}"
}


semver::search::initialize()
{
   if [ -z "${MULLE_SEMVER_PARSE_SH}" ]
   then
      # shellcheck source=mulle-semver-parse.sh
      . "${MULLE_SEMVER_LIBEXEC_DIR}/mulle-semver-parse.sh" || exit 1
   fi
   if [ -z "${MULLE_SEMVER_QUALIFY_SH}" ]
   then
      # shellcheck source=mulle-semver-qualify.sh
      . "${MULLE_SEMVER_LIBEXEC_DIR}/mulle-semver-qualify.sh" || exit 1
   fi
   if [ -z "${MULLE_SEMVER_SORT_SH}" ]
   then
      # shellcheck source=mulle-semver-sort.sh
      . "${MULLE_SEMVER_LIBEXEC_DIR}/mulle-semver-sort.sh" || exit 1
   fi
   if [ -z "${MULLE_ARRAY_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-array.sh" || exit 1
   fi
}

semver::search::initialize


