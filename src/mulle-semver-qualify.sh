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
MULLE_SEMVER_QUALIFY_SH="included"

#
# to be able to parse the following functions, we have to turn extglob on here
#
shopt -q extglob
MULLE_SEMVER_EXTGLOB_MEMO=$?

shopt -s extglob


semver_qualify_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} qualify [options] <qualifiers> <version>

   Check if a version matches the semver qualifiers.

   Read https://docs.npmjs.com/cli/v6/using-npm/semver/ for the specification
   examples. mulle-semver does not match URLs and tags though!

   Especially prerelease versions are tricky!

   Hint: Don't leave "pretty" space after operators. '>= 1.4.1' really means
   '>=* =1.4.1'. Leading and trailing spaces are stripped.

Examples:
   ${MULLE_USAGE_NAME} qualify '>=1.2 <1.4' 1.2.3
   ${MULLE_USAGE_NAME} qualify '^1.2' 1.2.3-prerelease

Options:
   -h : this help
EOF
   exit 1
}


semver_qualifier_type_usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} qualifier-type [options] <qualifier>

   Outputs, if a semver qualifier might match multiple versions, one
   version at most, or no versions.

   EMPTY  : qualifier is empty (after stripping whitespace)
   NO     : not a semver qualifier
   SEMVER : is a semver version (matches one)
   SINGLE : matches a single version at most
   MULTI  : may match multiple versions

   qualifier-type orients itself on syntax. It won't determine that
   '=1.2.1 =1.2.1' is only SINGLE instead of MULTI.

Return Values:
   empty=48, no=49, semver=50, single=52, multi=53

Examples:
   ${MULLE_USAGE_NAME} qualifier-type '>=1.2 <1.5'

Options:
   -h : this help
   -q : only return return value
EOF
   exit 1
}


#
#   local _major      [optional]
#   local _minor      [optional]
#   local _patch      [optional]
#
# missing parts are substituted with '*'
#
r_version_triple_parse_lenient()
{
#  log_entry "r_version_triple_parse_lenient" "$@"

   local s="$1"

   if ! shopt -q extglob
   then
      internal_fail "extglob must have been set"
   fi

   local r

   # r remainder after version v
   # this already checks that we have a three digits
   r="${s##+([0-9x\*])}"
   _major="${s%${r}}"
   s="${r#.}"

   r="${s##+([0-9x\*])}"
   _minor="${s%${r}}"
   s="${r#.}"

   r="${s##+([0-9x\*])}"
   _patch="${s%${r}}"
   s="${r#${_patch}}"

   case "${_major}" in
      [xX]|"")
         _major="*"
      ;;
   esac
   case "${_minor}" in
      [xX]|"")
         _minor="*"
      ;;
   esac
   case "${_patch}" in
      [xX]|"")
         _patch="*"
      ;;
   esac

   RVAL="${s}"
}


#
# parse it out into:
#
#   local _major      [required]
#   local _minor      [optional]
#   local _patch      [optional]
#   local _prerelease [optional]
#   local _build      [optional]
#
semver_parse_lenient()
{
   log_entry "semver_parse_lenient" "$@"

   local semver="$1"
   local quiet="$2"

   local s
   local r

   s="${semver}"
   case "${s:0:1}" in
      [vV])
         s="${s:1}"
      ;;
   esac

   r_version_triple_parse_lenient "${s}"
   s="${RVAL}"

   r_parse_prerelease_build "${s}"
   s="${RVAL}"

   if [ ! -z "${s}" ]
   then
      if [ "${quiet}" != 'YES' ]
      then
         if [ "${s}" = "${semver}" ]
         then
            log_error "Invalid semver \"${s}\" must have at least three digits-only parts"
         else
            log_error "Invalid input \"${s}\" in semver \"${semver}\""
         fi
      fi
      return 1
   fi

   return 0
}


#
# avoid reparsing stuff so, we reuse _underscore variables here
# though it's a bit more wordy
#
_semver_tilde_op_parsed()
{
   log_entry "_semver_tilde_op_parsed" "$@"

   [ $# -eq 4 ] || exit 1

   local major="${_major}"
   local minor="${_minor}"
   local patch="${_patch}"
   local prerelease="${_prerelease}"

   if  [ "${major}" = '*' ]
   then
      return 0
   fi

   # our local clean slate for parameter passing
   local _major
   local _minor
   local _patch
   local _build
   local _prerelease

   if  [ "${minor}" = '*' ]
   then
      _major="${major}"
      _minor=0
      _patch=0
      _prerelease="0"
      if ! _semver_op_parsed ">=" "$@"
      then
         return 1
      fi

      r_semver_increment_numeric "${major}"
      _major="${RVAL}"

      _semver_op_parsed "<" "$@"
      return $?
   fi

   if  [ "${patch}" = '*' ]
   then
      _major="${major}"
      _minor="${minor}"
      _patch=0
      _prerelease=""
   else
      _major="${major}"
      _minor="${minor}"
      _patch="${patch}"
      _prerelease="${prerelease}"
   fi

   if ! _semver_op_parsed ">=" "$@"
   then
      return 1
   fi

   r_semver_increment_numeric "${minor}"
   _minor="${RVAL}"
   _patch=0

   _semver_op_parsed "<" "$@"
}


_semver_caret_op_parsed()
{
   log_entry "_semver_caret_op_parsed" "$@"

   [ $# -eq 4 ] || exit 1

   local major="${_major}"
   local minor="${_minor}"
   local patch="${_patch}"

   # our local clean slate for parameter passing

   if  [ "${major}" = '*' ]
   then
      return 0
   fi

   if  [ "${minor}" = '*' ]
   then
      _semver_tilde_op_parsed "$@"
      return $?
   fi

   local _major
   local _minor
   local _patch
   local _build
   local _prerelease

   if  [ "${patch}" = '*' ]
   then
      # so this ^1.2.x -> >=1.2.0 <2.0.0
      _major="${major}"
      _minor="${minor}"
      _patch=0
      _prerelease=""
   else
      _major="${major}"
      _minor="${minor}"
      _patch="${patch}"
      _prerelease="${prerelease}"
   fi

   if ! _semver_op_parsed ">=" "$@"
   then
      return 1
   fi

   if [ "${major}" = '0' ]
   then
      _major=0
      r_semver_increment_numeric "${minor}"
      _minor="${RVAL}"
   else
      r_semver_increment_numeric "${major}"
      _major="${RVAL}"
      _minor=0
   fi
   _patch=0
   _prerelease=

   _semver_op_parsed "<" "$@"
}


_semver_is_prerelease_poisoned()
{
   log_entry "_semver_is_prerelease_poisoned" "$@"

   local a_prerelease="$1"
   local b_prerelease="$2"

   if [ -z "${a_prerelease}" ]
   then
      if [ -z "${b_prerelease}" ]
      then
         return 1
      fi
   else
      if [ ! -z "${b_prerelease}" ]
      then
         return 1
      fi
   fi

   log_fluff "POISONED"
   return 0
}


#
# a is $1-$4
# b is in _major - _prerelease
#
_semver_op_parsed()
{
   log_entry "_semver_op_parsed" "$@"

   local op="$1"; shift

   [ $# -eq 4 ] || internal_fail "API mismatch"

   log_debug "_major=${_major}"
   log_debug "_minor=${_minor}"
   log_debug "_patch=${_patch}"
   log_debug "_prerelease=${_prerelease}"

   case "${op}" in
      '~')
         _semver_tilde_op_parsed "$@"
         return $?
      ;;

      '^')
         _semver_caret_op_parsed "$@"
         return $?
      ;;
   esac

   local rval

   semver_compare_parsed \
      "$@" \
      "${_major}" "${_minor}" "${_patch}" "${_prerelease}"

   rval=$?
   if [ "${op}" = '=' ]
   then
      [ ${rval} -eq ${semver_same} ]
      rval=$?
   else
      if _semver_is_prerelease_poisoned "$4" "${_prerelease}"
      then
         rval=1
      else
         case "${op}" in
            '<')
               [ ${rval} -eq ${semver_ascending} ]
               rval=$?
            ;;

            '>')
               [ ${rval} -eq ${semver_descending} ]
               rval=$?
            ;;

            '>=')
               [ $rval -ne ${semver_ascending} ]
               rval=$?
            ;;

            '<=')
               [ $rval -ne ${semver_descending} ]
               rval=$?
            ;;

            *)
               fail "unknown op \"${op}\""
            ;;
         esac
      fi
   fi

   log_fluff "QUALIFY \"${expr}\" $1 $2 $3 $4 -> ${rval}"
   return $rval
}


# https://docs.npmjs.com/cli/v6/using-npm/semver/
#
#    version Must match version exactly
#    >version Must be greater than version
#    >=version etc
#    <version
#    <=version
#    ~version "Approximately equivalent to version" See semver
#    ^version "Compatible with version" See semver
#    1.2.x 1.2.0, 1.2.1, etc., but not 1.3.0
#    http://... See 'URLs as Dependencies' below
#    * Matches any version
#    "" (just an empty string) Same as *
#    version1 - version2 Same as >=version1 <=version2.
#    range1 || range2 Passes if either range1 or range2 are satisfied.
#
# We don't do this:
#
#    tag A specific version tagged and published as tag
#    git:... See 'Git URLs as Dependencies' below
#    user/repo See 'GitHub URLs' below
#    path/path/path See Local Paths below
#
_semver_op()
{
   log_entry "_semver_op" "$@"

   local op="$1"; shift
   local b="$1"; shift

   [ $# -eq 4 ] || exit 1

   local _major
   local _minor
   local _patch
   local _build
   local _prerelease

   if ! semver_parse_lenient "${b}"
   then
      exit 1
   fi

   _semver_op_parsed "${op}" "$@"
}


_semver_qualify_unary()
{
   log_entry "_semver_qualify_unary" "$@"

   local expr="$1"; shift

   local rval

   case "${expr}" in
      [\<\>]\=*)
         _semver_op "${expr:0:2}" "${expr#??}" "$@"
         rval=$?
      ;;

      [\^\~\<\>\=]*)
         _semver_op "${expr:0:1}" "${expr#?}" "$@"
         rval=$?
      ;;

      *)
         _semver_op "=" "${expr}" "$@"
         rval=$?
      ;;
   esac

   log_fluff "UNARY QUALIFY \"${expr}\" $1 $2 $3 $4 -> ${rval}"

   return ${rval}
}


_semver_qualify()
{
   log_entry "_semver_qualify" "$@"

   local expr="$1"; shift

   local rval

   case "${expr}" in
      # an OR
      *\|\|*)
         _semver_qualify "${expr%%||*}" "$@" || \
         _semver_qualify "${expr#*||}" "$@"
         rval=$?
      ;;

      # a range, transform to >= <=
      *\ \-\ *)
         _semver_qualify ">=${expr%%-*}" "$@" && \
         _semver_qualify "<=${expr#*-}" "$@"
         rval=$?
      ;;

      # an AND
      *\ *)
         _semver_qualify "${expr%%\ *}" "$@" && \
         _semver_qualify "${expr#*\ }" "$@"
         rval=$?
      ;;

      *)
         _semver_qualify_unary "${expr}" "$@"
         rval=$?
      ;;
   esac

   log_fluff "QUALIFY \"${expr}\" $1 $2 $3 $4 -> ${rval}"

   return ${rval}
}


r_semver_sanitized_qualifier()
{
   log_entry "r_semver_sanitized_qualifier" "$@"

   local expr="$1"

   # sometimes we get url#semver or url#, d
   case "${expr}" in
      *\#semver:*)
         expr="${expr##*#semver:}"
      ;;

      *\#*)
         expr="${expr##*#}"
      ;;
   esac

   # remove surrounding whitepace
   r_trim_whitespace "${expr}"
   expr="${RVAL}"

   local s

   #
   # reduce separating whitespace to a single whitespace. A single whitespace
   # is an operator, but can also turn up in foo || bar and foo - range
   # expressions (see below)
   #
   while [ "${s}" != "${expr}" ]
   do
      s=${expr}
      expr="${expr//  / }"
   done

   #
   # remove witespace around ||
   # We need to keep whitespace around '-' otherwise the
   # operator runs into the version e.g. 0.1.2-3 is it a >=0.1.2 <3.0.0 or
   # just a prerelease
   #
   expr="${expr// ||/||}"
   expr="${expr//|| /||}"

   expr="${expr#vV}"
   RVAL=${expr}
}


semver_qualify()
{
   log_entry "semver_qualify" "$@"

   local expr="$1"
   local major="$2"
   local minor="$3"
   local patch="$4"
   local prerelease="$5"

   r_semver_sanitized_qualifier "${expr}"

   # change order for convenience
   _semver_qualify "${RVAL}" "${major}" "${minor}" "${patch}" "${prerelease}"
}


semver_empty_qualifier=48
semver_no_qualifier=49
semver_semver_qualifier=50
semver_single_qualifier=52
semver_multi_qualifier=53


r_semver_qualifier_type_description()
{
   RVAL="???"
   case "$1" in
      ${semver_empty_qualifier})
         RVAL="EMPTY"
      ;;

      ${semver_no_qualifier})
         # could be a tag, but definitely not a semver qualifier
         RVAL="NO"
      ;;

      ${semver_single_qualifier})
         RVAL="SINGLE"
      ;;

      ${semver_semver_qualifier})
         RVAL="SEMVER"
      ;;

      ${semver_multi_qualifier})
         RVAL="MULTI"
      ;;
   esac

}


_semver_qualifier_unary_type()
{
   log_entry "_semver_qualifier_unary_type" "$@"

   local expr="$1"

   local rval

   case "${expr:0:1}" in
      \=)
         rval=${semver_single_qualifier}
      ;;

      [\<\>\^\~])
         rval=${semver_multi_qualifier}
      ;;

      *)
         if semver_parse "${expr}" "YES"
         then
            rval=${semver_semver_qualifier}
         else
            if semver_parse_lenient "${expr}" "YES"
            then
               rval=${semver_multi_qualifier}
            else
               rval=${semver_no_qualifier}
            fi
         fi
      ;;
   esac

   return ${rval}
}



# returns 0 not a qualifier
#         1 is a semver              (1.2.3)
#         2 is a single tag qualifier (=1.2.3)
#         3 is a multiple tag qualifier  (>= 1.2.3)
#
_semver_qualifier_type()
{
   log_entry "_semver_qualifier_type" "$@"

   local expr="$1"

   local rval

   case "${expr}" in
      "")
         rval=${semver_empty_qualifier}
      ;;

      # an OR, a range,an AND
      *\|\|*|*\-*|*\ *)
         rval=${semver_multi_qualifier}
      ;;

      *)
         _semver_qualifier_unary_type "${expr}"
         rval=$?
      ;;
   esac
   return ${rval}
}


semver_qualifier_type_main()
{
   log_entry "semver_qualifier_type_main" "$@"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            semver_qualifier_type_usage
         ;;

         -q|--quiet)
            OPTION_QUIET='YES'
         ;;

         -*)
            semver_qualifier_type_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -ne 1 ] && semver_qualifier_type_usage

   local qualifier="$1"

   r_semver_sanitized_qualifier "${qualifier}"
   qualifier="${RVAL}"

   local rval

   _semver_qualifier_type "${qualifier}"
   rval="$?"

   if [ "${OPTION_QUIET}" != 'YES' ]
   then
      case "${rval}" in
         ${semver_empty_qualifier})
            echo "EMPTY"
         ;;

         ${semver_no_qualifier})
            echo "NO"
         ;;

         ${semver_semver_qualifier})
            echo "SEMVER"
         ;;

         ${semver_single_qualifier})
            echo "SINGLE"
         ;;

         ${semver_multi_qualifier})
            echo "MULTI"
         ;;
      esac
   fi

   return $rval
}


semver_qualify_main()
{
   log_entry "semver_qualify_main" "$@"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            semver_qualify_usage
         ;;

         -q|--quiet)
            OPTION_QUIET='YES'
         ;;

         -*)
            semver_qualify_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -ne 2 ] && semver_qualify_usage

   local qualifier="$1"
   local version="$2"

   r_semver_sanitized_qualifier "${qualifier}"
   qualifier="${RVAL}"

   local _line
   local _build
   local _prerelease
   local _major
   local _minor
   local _patch

   if ! semver_parse "${version}"
   then
      return 1
   fi

   if semver_qualify "${qualifier}" \
                     "${_major}" "${_minor}" "${_patch}" "${_prerelease}"
   then
      [ "${OPTION_QUIET}" != 'YES' ] && echo 'YES'
      return 0
   fi

   [ "${OPTION_QUIET}" != 'YES' ] && echo 'NO'
   return 2
}


if [ "${MULLE_SEMVER_EXTGLOB_MEMO}" -ne 0 ]
then
   shopt -u extglob
fi
unset MULLE_SEMVER_EXTGLOB_MEMO


semver_qualify_initialize()
{
   if [ -z "${MULLE_SEMVER_PARSE_SH}" ]
   then
      # shellcheck source=mulle-semver-parse.sh
      . "${MULLE_SEMVER_LIBEXEC_DIR}/mulle-semver-parse.sh" || exit 1
   fi
}

semver_qualify_initialize

