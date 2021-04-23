#! /usr/bin/env bash
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
MULLE_SEMVER_PARSE_SH="included"

#
# to be able to parse the following functions, we have to turn extglob on here
#
shopt -q extglob
MULLE_SEMVER_EXTGLOB_MEMO=$?

shopt -s extglob


semver_parse_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} parse [options] <version>

   Parse a version in its constituents.

Example:
   ${MULLE_USAGE_NAME} parse 1.2.3-prerelease

Options:
   -h : this help
EOF
   exit 1
}


semver_alphanumeric_compare_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} alphanumeric-compare [options] <number> <numbe>

   Compares two semver alphanumeric strings. An alphanumeric string is a
   combination of letters digits and the - minus sign (hyphen).

Example:
   ${MULLE_USAGE_NAME} alphanumeric-compare a-22 b-23

Options:
   -h : this help
EOF
   exit 1
}


semver_numeric_compare_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} numeric-compare [options] <number> <numbe>

   Compares two semver numbers. A number can be an arbitrary large positive
   integer without a leading zero or "0"-

Example:
   ${MULLE_USAGE_NAME} numeric-compare 2111111111111111111 3111111111111111111

Options:
   -h : this help
EOF
   exit 1
}


semver_parse_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} parse [options] <version>

   Parse a version in its constituents.

Example:
   ${MULLE_USAGE_NAME} parse 1.2.3-prerelease

Options:
   -h : this help
   -l : parse leniently (allow 1.x or x, not just 1.x.y)
   -q : quiet, don't print parse errors
EOF
   exit 1
}


semver_compare_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} compare [options] <version>

   Compare two versions and output the comparison result, which is either
   ASCENDING, DESCENDING or SAME. The return values for ASCENDING is 60,
   DESCENDING is 62 and SAME is 0. 1

Example:
   ${MULLE_USAGE_NAME} parse 1.2.3-prerelease

Options:
   -h : this help
EOF
   exit 1
}


#
#   local _major      [required]
#   local _minor      [required]
#   local _patch      [required]
#
r_version_triple_parse()
{
#   log_entry "r_version_triple_parse" "$@"

   local semver="$1"
   local quiet="$2"
   local lenient="$3" # allows also 1.0 and 1

   if ! shopt -q extglob
   then
      fail "extglob must have been set"
   fi

   local s
   local v
   local r
   local a

   # strip of a leading 'vV' earlier, not here
   s="${semver}"

   # r remainder after version v
   # this already checks that we have a three digits
   r="${s##+([0-9]).+([0-9]).+([0-9])}"
   v="${s%${r}}"
   if [ -z "${v}" ]
   then
      if [ "${lenient}" != 'YES' ]
      then
         if [ "${quiet}" != 'YES' ]
         then
            log_error "Expected version triple at start of \"${semver}\""
         fi
         return 1
      fi

      r="${s##+([0-9]).+([0-9])}"
      v="${s%${r}}"
      a=".0"
      if [ -z "${v}" ]
      then
         r="${s##+([0-9])}"
         v="${s%${r}}"
         a=".0.0"
         if [ -z "${v}" ]
         then
            if [ "${quiet}" != 'YES' ]
            then
               log_error "Expected version triple at start of \"${semver}\""
               return 1
            fi
         fi
      fi
   fi
   s="${r}"
   v="${v}${a}"

   _major="${v%%.*}"
   tmp="${v#${_major}.}"
   _minor="${tmp%%.*}"
   _patch="${tmp#${_minor}.}"

   RVAL="${s}"
}


r_parse_prerelease_build()
{
#   log_entry "r_parse_prerelease_build" "$@"

   local s="$1"
   local quiet="$2"

   _build=""
   _prerelease=""

   local r

   case "${s:0:1}" in
      '+')
         s="${s:1}"
         r="${s##+([A-Za-z0-9.])}"
         _build="${s%${r}}"
         s="${r}"

         if [ -z "${_prerelease}" ]
         then
            if [ "${quiet}" != 'YES' ]
            then
               log_error "Dangling + after version in semver \"${semver}\""
            fi
            return 1
         fi
      ;;

      '-')
         s="${s:1}"
         r="${s##+([A-Za-z0-9.-])}"
         _prerelease="${s%${r}}"
         s="${r}"

         if [ -z "${_prerelease}" ]
         then
            if [ "${quiet}" != 'YES' ]
            then
               log_error "Dangling - after version in semver \"${semver}\""
            fi
            return 1
         fi

         case "${s:0:1}" in
            '+')
               s="${s:1}"
               r="${s##+([A-Za-z0-9.-])}"
               _build="${s%${r}}"
               s="${r}"

               if [ -z "${_build}" ]
               then
                  if [ "${quiet}" != 'YES' ]
                  then
                     log_error "Dangling + after prerelease in semver \"${semver}\""
                  fi
                  return 1
               fi
            ;;
         esac
      ;;
   esac

   RVAL="${s}"
}

#
# parse it out into:
#
#   local _line       [optional]
#   local _major      [required]
#   local _minor      [required]
#   local _patch      [required]
#   local _prerelease [optional]
#   local _build      [optional]
#
semver_parse()
{
   log_entry "semver_parse" "$@"

   local semver="$1"
   local quiet="$2"
   local lenient="$3"      # allows also 1.0 and 1
   local s
   local r

   s="${semver}"
   case "${s:0:1}" in
      [vV])
         s="${s:1}"
      ;;
   esac

   if ! r_version_triple_parse "${s}" "${quiet}" "${lenient}"
   then
      return 1
   fi
   s="${RVAL}"

   if ! r_parse_prerelease_build "${s}" "${quiet}"
   then
      return 1
   fi
   s="${RVAL}"

   if [ ! -z "${s}" ]
   then
      if [ "${quiet}" != 'YES' ]
      then
         if [ "${s}" = "${semver}" ]
         then
            log_error "Invalid semver \"${s}\" must have at least three digits-only parts"
         else
            log_error "Invalid input \"${s}\" in semver \"${semver}\"" >&2
         fi
      fi
      return 1
   fi

   return 0
}


r_semver_parsed_version_description()
{
   local v_prefix="$1"
   local major="$2"
   local minor="$3"
   local patch="$4"
   local prerelease="$5"
   local build="$6"

   RVAL="${v_prefix}${major}.${minor}.${patch}"
   if [ ! -z "${prerelease}" ]
   then
      RVAL="${RVAL}-${prerelease}"
   fi
   if [ ! -z "${build}" ]
   then
      RVAL="${RVAL}+${build}"
   fi
}


r_semver_increment_numeric()
{
   log_entry "r_semver_increment_numeric" "$@"

   local a="$1"

   local a_len

   a_len=${#a}
   if [ ${a_len} -le 4 ]
   then
      RVAL=$(( a + 1))
      return
   fi

   # super slow
   local v
   local i

   RVAL=""
   i=${a_len}
   while [ $i -ne 0 ]
   do
      i=$(( i - 1))
      v="${a:$i:1}"

      v=$((v + 1))
      if [ "${v}" -lt 10 ]
      then
         RVAL="${a:0:$i}${v}${RVAL}"
         return
      fi
      v=$((v - 10))
      RVAL="${v}${RVAL}"
   done

   # add carry and done
   RVAL="1${RVAL}"
}


#
# since bash can't return -1 really, we do
# ascending   '<' 60
# same        '=' 0  because its easier
# descending  '>' 62
#
semver_ascending=60  # '<'
semver_same=0        # '='
semver_descending=62 # '>'

#
# problem is, the number might be too big for bash
# we assume 16 bit (4 digit range is unproblematic)
#
# number cant start with 0 if its not 0
#
semver_numeric_compare()
{
#   log_entry "semver_numeric_compare" "$@"
#
   local a="$1"
   local b="$2"
#
#   [ -z "${a}" ] && internal_fail "a is empty"
#   [ -z "${b}" ] && internal_fail "b is empty"

   if [ "${a}" = "${b}" -o "${a}" = '*' -o "${b}" = '*' ]
   then
      return ${semver_same}
   fi

   local a_len
   local b_len

   a_len=${#a}
   b_len=${#b}

   if [ "${a_len}" != "${b_len}" ]
   then
      if [ ${a_len} -lt ${b_len} ]
      then
         return ${semver_ascending}
      else
         return ${semver_descending}
      fi
   fi

   if [ ${a_len} -le 4 ]
   then
      if [ ${a} -lt ${b} ]
      then
         return ${semver_ascending}
      else
         return ${semver_descending}
      fi
   fi

   local a_digits
   local b_digits

   while :
   do
      a_digits="${a:0:4}"
      b_digits="${b:0:4}"
      if [ "${a_digits}" != "${b_digits}" ]
      then
         if [ ${a_digits} -lt ${b_digits} ]
         then
            return ${semver_ascending}
         else
            return ${semver_descending}
         fi
      fi
      a="${a:4}"
      b="${b:4}"
   done
}


#
# Identifiers with letters or hyphens are compared lexically in ASCII sort order.
#
#
# a or b can't be wildcards, but can be empty
#
semver_alphanumeric_compare()
{
#   log_entry "semver_alphanumeric_compare" "$@"

   local a="$1"
   local b="$2"

   if [[ "${a}" == "${b}" ]]
   then
      return ${semver_same}
   fi

   if [[ "${a}" == '*' || "${b}" == '*' ]]
   then
      return ${semver_same}
   fi

   local old
   local rval

   # clumsy but necessary
   old="${LC_ALL}"
   LC_ALL='C'

   rval=${semver_descending}
   if [[ "${a}" < "${b}" ]]
   then
      rval=${semver_ascending}
   fi

   LC_ALL="${old}"
   return ${rval}
}


#
# a_part or b_part can't be wildcards
#
semver_prerelease_part_compare()
{
   log_entry "semver_prerelease_part_compare" "$@"

   local a_part="$1"
   local b_part="$2"

   case "${a_part}" in
      "")
         if [ -z "${b_part}" ]
         then
            return ${semver_same}
         else
            return ${semver_ascending}
         fi
      ;;

      +([0-9]))
         case "${b_part}" in
            +([0-9]))
               semver_numeric_compare "${a_part}" "${b_part}"
               return $?
            ;;
         esac
         return ${semver_ascending}
      ;;
   esac

   case "${b_part}" in
      "")
         return ${semver_descending}
      ;;

      +([0-9]))
         return ${semver_descending}
      ;;
   esac

   semver_alphanumeric_compare "${a_part}" "${b_part}"
   return $?
}


#
# wildcards not specifiable for prerelease
#
semver_prerelease_compare()
{
   log_entry "semver_prerelease_compare" "$@"

   local a_prerelease="$1"
   local b_prerelease="$2"

   if [ "${a_prerelease}" = "${b_prerelease}" ]
   then
      return ${semver_same}
   fi

   local a_part
   local b_part
   local a_remainder
   local b_remainder
   local rval

   a_remainder="${a_prerelease}"
   b_remainder="${b_prerelease}"

   while :
   do
      a_part="${a_remainder%%.*}"
      a_remainder="${a_remainder#${a_part}}"
      a_remainder="${a_remainder#.}"
      b_part="${b_remainder%%.*}"
      b_remainder="${b_remainder#${b_part}}"
      b_remainder="${b_remainder#.}"

      semver_prerelease_part_compare "${a_part}" "${b_part}"
      rval=$?

      if [ "${rval}" != ${semver_same} ]
      then
         return ${rval}
      fi

      if [ -z "${a_remainder}" ]
      then
         break
      fi
   done

   return ${semver_same}
}


# Do a comparison
# since bash can't return -1 really, we do
# ascending   '<' 60
# same        '=' 61
# descending  '>' 62
#
# coded without variables, because this needs to be fast as its called during
# sorting (especially if using quicksort, which compares a lot)
#
semver_compare_parsed()
{
#   log_entry "semver_compare_parsed" "$@"
#
#   [ $# -ne 8 ] && echo "need 8 parameters">&2 && exit 1
#
#   shopt -q extglob || internal_fail "extglob must have been set"
#
   local rval

   rval=${semver_same}
   if [ "${1}" != "${5}" ]
   then
      semver_numeric_compare "${1}" "${5}"
      rval=$?
   else
      if [ "${2}" != "${6}" ]
      then
         semver_numeric_compare "${2}" "${6}"
         rval=$?
      else
         if [ "${3}" != "${7}" ]
         then
            semver_numeric_compare "${3}" "${7}"
            rval=$?
         fi
      fi
   fi

   #
   # the prerelease is only comparable if versions equal
   # otherwise a prerelease "poisons"
   # See: https://docs.npmjs.com/cli/v6/using-npm/semver/
   #
   if [ "${4}" != "${8}" ]
   then
      if [ -z "${4}" ]
      then
         #
         # b is set, but a prerelease poisons so its descending
         # i.e. 0.0.0 > x.x.x-prerelease
         #
         rval=${semver_descending}
      else
         if [ $rval = ${semver_same} ]
         then
            # a and b set, so here we can compare
            semver_prerelease_compare "${4}" "${8}"
            rval=$?
         else
            rval=${semver_ascending}
         fi
      fi
   fi

#   log_fluff "<${a_major}.${a_minor}.${a_patch}-${a_prerelease}> ~ \
#<${b_major}.${b_minor}.${b_patch}-${b_prerelease}> : ${rval}"
   return $rval
}


semver_validate_number()
{
   log_entry "semver_validate_number" "$@"

   shopt -q extglob || internal_fail "extglob must have been set `shopt extglob`"

   case "$1" in
      0|[1-9]*([0-9]))
      ;;

      *)
         fail "\"$1\" is not a valid semver numeric identifier"
      ;;
   esac
}


semver_validate_alphanumeric()
{
   log_entry "semver_validate_alphanumeric" "$@"

   shopt -q extglob || internal_fail "extglob must have been set"

   case "$1" in
      +([0-9a-zA-Z-]))
      ;;

      *)
         fail "\"$1\" is not a valid semver alphanumeric identifier"
      ;;
   esac
}


semver_output_comparison_result()
{
   local rval="$1"
   local quiet="$2"

   if [ "${quiet}" != 'YES' ]
   then
      case $rval in
         ${semver_ascending})
            echo "ASCENDING"
         ;;

         ${semver_descending})
            echo "DESCENDING"
         ;;

         ${semver_same})
            echo "SAME"
         ;;
      esac
   fi
   return $rval
}


semver_alphanumeric_compare_main()
{
   log_entry "semver_alphanumeric_compare_main" "$@"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            semver_alphanumeric_compare_usage
         ;;

         -q|--quiet)
            OPTION_QUIET='YES'
         ;;

         -*)
            semver_alphanumeric_compare_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 2 ] || semver_alphanumeric_compare_usage

   semver_validate_alphanumeric "$1"
   semver_validate_alphanumeric "$2"

   semver_alphanumeric_compare "$@"
   semver_output_comparison_result $? "${OPTION_QUIET}"
}


semver_numeric_compare_main()
{
   log_entry "semver_numeric_compare_main" "$@"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            semver_numeric_compare_usage
         ;;

         -q|--quiet)
            OPTION_QUIET='YES'
         ;;

         -*)
            semver_numeric_compare_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -ne 2 ] && semver_numeric_compare_usage

   semver_validate_number "$1"
   semver_validate_number "$2"

   semver_numeric_compare "$@"
   semver_output_comparison_result $? "${OPTION_QUIET}"
}


r_semver_grab_versions()
{
   log_entry "r_semver_grab_versions" "$@"

   local usage="${1:-semver_parse_usage}" ; shift

   local versions

   if [ "$1" = "-" ]
   then
      shift
      [ $# -ne 0 ] && $usage "Superflous arguments \"$*\""

      # remove comments gratuitously
      versions="`egrep -v '^#' `"
   else
      while [ $# -ne 0 ]
      do
         r_trim_whitespace "$1"
         shift

         if [ ! -z "${RVAL}" ]
         then
            r_add_line "${versions}" "${RVAL}"
            versions="${RVAL}"
         fi
      done
   fi

   RVAL="${versions}"
}


#
# parsed_versions are lines of text that look somewhat like this:
# _major=1;_minor=2;_patch=3;_prerelease=4
# instead of parsing, we try to just eval the line to get
# the values. Could be good...
#
# returns 0 all OK
#         1 all wrong
#         2 some OK
#
r_semver_parse_versions()
{
   log_entry "r_semver_parse_versions" "$@"

   local versions="$1"
   local quiet="$2"
   local lenient="$3"

   local parsed_versions
   local version

   local _line
   local _build
   local _prerelease
   local _major
   local _minor
   local _patch
   local rval

   rval=0

   # now parse all versions
   IFS=$'\n'
   set -f
   for version in ${versions}
   do
      if ! semver_parse "${version}" "${quiet}" "${lenient}"
      then
         if [ $rval -eq 0 ]
         then
            rval=1
         fi
         continue
      fi

      if [ $rval -eq 1 ]
      then
         rval=2
      fi

      line="_line=${version};_major=${_major};_minor=${_minor};_patch=${_patch};\
_prerelease=${_prerelease};_build=${build}"
      r_add_line "${parsed_versions}" "${line}"
      parsed_versions="${RVAL}"
   done
   IFS="${DEFAULT_IFS}"
   set +f

   RVAL="${parsed_versions}"
   return $rval
}


r_semver_parsed_versions_decriptions()
{
   log_entry "r_semver_parsed_versions_decriptions" "$@"

   local parsed_versions="$1"
   local pretty="$2"

   local versions
   local line
   local s
   local _line
   local _build
   local _prerelease
   local _major
   local _minor
   local _patch

   # now parse all versions
   IFS=$'\n'
   set -f
   if [ "${pretty}" = 'YES' ]
   then
      for line in ${parsed_versions}
      do
         eval "${line}"

         s="${_major}.${_minor}.${_patch}"
         if [ ! -z "${_prerelease}" ]
         then
            s="${s}-${_prerelease}"
         fi
         if [ ! -z "${_build}" ]
         then
            s="${s}-${_build}"
         fi
         r_add_line "${versions}" "${s}"
         versions="${RVAL}"
      done
   else
      for line in ${parsed_versions}
      do
         eval "${line}"
         r_add_line "${versions}" "${_line}"
         versions="${RVAL}"
      done
   fi

   IFS="${DEFAULT_IFS}"
   set +f

   RVAL="${versions}"
}


semver_parse_main()
{
   log_entry "semver_parse_main" "$@"

   local OPTION_QUIET
   local OPTION_RAW
   local OPTION_LENIENT
   local OPTION_PRETTY='YES'

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            semver_parse_usage
         ;;

         -q|--quiet)
            OPTION_QUIET='YES'
         ;;

         -l|--lenient)
            OPTION_LENIENT='YES'
         ;;

         --raw)
            OPTION_RAW='YES'
         ;;

         --pretty)
            OPTION_PRETTY='YES'
         ;;

         --no-pretty)
            OPTION_PRETTY='NO'
         ;;

         -)
            break
         ;;

         -*)
            semver_parse_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local versions

   r_semver_grab_versions semver_parse_usage "$@"
   versions="${RVAL}"

   r_semver_parse_versions "${versions}" "${OPTION_QUIET}" "${OPTION_LENIENT}"
   rval=$?

   parsed_versions="${RVAL}"

   if [ "${OPTION_QUIET}" = "YES" -o -z "${parsed_versions}" ]
   then
      return $rval
   fi

   if [ "${OPTION_RAW}" = 'YES' ]
   then
      printf "%s\n" "${parsed_versions}"
      return $rval
   fi

   r_semver_parsed_versions_decriptions "${parsed_versions}" "${OPTION_PRETTY}"
   printf "%s\n" "${RVAL}"
   return $rval
}


semver_compare_main()
{
   log_entry "semver_compare_main" "$@"

   local OPTION_QUIET
   local OPTION_LENIENT
   local _line
   local _build
   local _prerelease
   local _major
   local _minor
   local _patch

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            semver_compare_usage
         ;;

         -q|--quiet)
            OPTION_QUIET='YES'
         ;;

         -l|--lenient)
            OPTION_LENIENT='YES'
         ;;

         -*)
            semver_compare_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   if ! semver_parse "$1" "${OPTION_QUIET}" "${OPTION_LENIENT}"
   then
      return 1
   fi

   local a_major="${_major}"
   local a_minor="${_minor}"
   local a_patch="${_patch}"
   local a_prerelease="${_prerelease}"

   if ! semver_parse "$2"
   then
      return 1
   fi

   local b_major="${_major}"
   local b_minor="${_minor}"
   local b_patch="${_patch}"
   local b_prerelease="${_prerelease}"

   local rval

   semver_compare_parsed \
       "${a_major}" "${a_minor}" "${a_patch}" "${a_prerelease}" \
       "${b_major}" "${b_minor}" "${b_patch}" "${b_prerelease}"
   semver_output_comparison_result $? "${OPTION_QUIET}"
}




if [ "${MULLE_SEMVER_EXTGLOB_MEMO}" -ne 0 ]
then
   shopt -u extglob
fi
unset MULLE_SEMVER_EXTGLOB_MEMO

# no initialize needed
