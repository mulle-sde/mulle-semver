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
shell_is_extglob_enabled || _fail "extglob needs to be on"


semver::qualify::usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} qualify [options] <qualifiers> <version>

   Check if a single version matches one of the semver qualifiers.

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


semver::qualify::qualifier_type_usage()
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
# missing parts are substituted with '0' by default
#
semver::qualify::r_version_triple_parse_lenient()
{
#  log_entry "semver::qualify::r_version_triple_parse_lenient" "$@"

   local s="$1"
   local substitute="${2:-0}"

   if ! shell_is_extglob_enabled
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
         _major="${substitute}"
      ;;
   esac
   case "${_minor}" in
      [xX]|"")
         _minor="${substitute}"
      ;;
   esac
   case "${_patch}" in
      [xX]|"")
         _patch="${substitute}"
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
# substitute is 0 by default, sometimes '*' is convenient though
semver::qualify::parse_lenient()
{
   log_entry "semver::qualify::parse_lenient" "$@"

   local semver="$1"
   local substitute="$2"
   local quiet="$3"

   local s
   local r

   s="${semver}"
   case "${s:0:1}" in
      [vV])
         s="${s:1}"
      ;;
   esac

   semver::qualify::r_version_triple_parse_lenient "${s}" "${substitute}"
   s="${RVAL}"

   semver::parse::r_prerelease_build "${s}"
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
semver::qualify::_tilde_op_parsed()
{
   log_entry "semver::qualify::_tilde_op_parsed" ${_major} ${_minor} ${_patch} ${_prerelease} "$@"

   [ $# -eq 4 ] || exit 1

   local major="${_major}"
   local minor="${_minor}"
   local patch="${_patch}"
   local prerelease="${_prerelease}"

   if [ -z "${prerelease}" -a ! -z "${4}" ]
   then
      log_fluff "POISONED"
      return 1
   fi

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
      _prerelease=""
      if ! semver::qualify::_op_parsed ">=" "$@"
      then
         return 1
      fi

      semver::parse::r_increment_numeric "${major}"
      _major="${RVAL}"

      semver::qualify::_op_parsed "<" "$@"
      return $?
   fi

   if [ "${patch}" = '*' ]
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

   if ! semver::qualify::_op_parsed ">=!" "$@"
   then
      return 1
   fi

   semver::parse::r_increment_numeric "${minor}"
   _minor="${RVAL}"
   _patch=0
   _prerelease=""

   semver::qualify::_op_parsed "<" "$@"
   case $?  in
      1) # poisoned is OK here
         return 1
      ;;
   esac
   return 0
}


semver::qualify::_caret_op_parsed()
{
   log_entry "semver::qualify::_caret_op_parsed" ${_major} ${_minor} ${_patch} ${_prerelease} "$@"

   [ $# -eq 4 ] || exit 1

   local major="${_major}"
   local minor="${_minor}"
   local patch="${_patch}"
   local prerelease="${_prerelease}"

   if [ -z "${prerelease}" -a ! -z "${4}" ]
   then
      log_fluff "POISONED"
      return 1
   fi

   # our local clean slate for parameter passing

   if [ "${major}" = '*' ]
   then
      return 0
   fi

   if [ "${minor}" = '*' ]
   then
      semver::qualify::_tilde_op_parsed "$@"
      return $?
   fi

   local _major
   local _minor
   local _patch
   local _build
   local _prerelease

   if [ "${patch}" = '*' ]
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

   if ! semver::qualify::_op_parsed ">=!" "$@"
   then
      return 1
   fi

   if [ "${major}" = '0' ]
   then
      _major=0
      if [ "${minor}" = '0' ]
      then
         _minor=0
         if [ "${patch}" = '*' ]
         then
            _minor=1
            _patch=0
         else
            semver::parse::r_increment_numeric "${patch}"
            _patch="${RVAL}"
         fi
      else
         semver::parse::r_increment_numeric "${minor}"
         _minor="${RVAL}"
         _patch=0
      fi
   else
      semver::parse::r_increment_numeric "${major}"
      _major="${RVAL}"
      _minor=0
      _patch=0
   fi
   _prerelease=

   semver::qualify::_op_parsed "<" "$@"
   case $?  in
      1) # poisoned is OK here
         return 1
      ;;
   esac
   return 0
}



#
# a is $1-$4
# b is in _major - _prerelease
#
semver::qualify::_op_parsed()
{
   log_entry "semver::qualify::_op_parsed" "${_major}" "${_minor}" "${_patch}" "${_prerelease}" "$@"

   local op="$1"; shift

   [ $# -eq 4 ] || internal_fail "API mismatch"

   local rval

   case "${op}" in
      '~')
         semver::qualify::_tilde_op_parsed "$@"
         rval=$?
         log_debug "semver::qualify::_op_parsed returns $rval"
         return $rval
      ;;

      '^')
         semver::qualify::_caret_op_parsed "$@"
         rval=$?
         log_debug "semver::qualify::_op_parsed returns $rval"
         return $rval
      ;;
   esac

   local poisoned

   # sadly the order is reversed here, the
   semver::parse::compare_parsed \
      "$@" \
      "${_major}" "${_minor}" "${_patch}" "${_prerelease}"
   rval=$?

   if [ "${op}" = '=' ]
   then
      [ ${rval} -eq ${semver_same} ]
      rval=$?
      log_debug "semver::qualify::_op_parsed returns $rval"
      return $rval
   fi

   case "${op}" in
      '<')
         [ ${rval} -eq ${semver_ascending} ]
         rval=$?

         if [ $rval -eq 0 -a -z "${_prerelease}" -a ! -z "${4}" ]
         then
            rval=2
         fi
      ;;

      '<*')
         [ ${rval} -eq ${semver_ascending} ]
         rval=$?
      ;;


      '>')
         [ ${rval} -eq ${semver_descending} ]
         rval=$?
         if [ $rval -eq 0 -a -z "${_prerelease}" -a ! -z "${4}" ]
         then
            rval=2
         fi
      ;;

      '>=')
         [ $rval -ne ${semver_ascending} ]
         rval=$?

         if [ $rval -eq 0 -a -z "${_prerelease}" -a ! -z "${4}" ]
         then
            rval=2
         fi
      ;;

      '>=!')
         [ $rval -ne ${semver_ascending} ]
         rval=$?

         if [ $rval -eq 0 -a ! -z "${4}" ]
         then
            if ! semver::parse::compare_parsed \
               "$1" "$2" "$3" ""  \
               "${_major}" "${_minor}" "${_patch}" ""
            then
               rval=2
            fi
         fi
      ;;

      '<=')
         [ $rval -ne ${semver_descending} ]
         rval=$?

         if [ $rval -eq 0 -a -z "${_prerelease}" -a ! -z "${4}" ]
         then
            rval=2
         fi
      ;;

      '<=!')
         [ $rval -ne ${semver_descending} ]
         rval=$?

         if [ $rval -eq 0 -a ! -z "${4}" ]
         then
            if ! semver::parse::compare_parsed \
               "$1" "$2" "$3" ""  \
               "${_major}" "${_minor}" "${_patch}" ""
            then
               rval=2
            fi
         fi
      ;;


      *)
         fail "unknown op \"${op}\""
      ;;
   esac

   [ $rval -eq 2 ] && log_fluff "POISONED"

   log_debug "semver::qualify::_op_parsed returns $rval"
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
semver::qualify::_op()
{
   log_entry "semver::qualify::_op" "$@"

   local op="$1"
   local b="$2"
   local substitute="$3"

   shift 3

   [ $# -eq 4 ] || exit 1

   local _major
   local _minor
   local _patch
   local _build
   local _prerelease

   if ! semver::qualify::parse_lenient "${b}" "${substitute}"
   then
      exit 1
   fi

   semver::qualify::_op_parsed "${op}" "$@"
}


semver::qualify::_unary()
{
   log_entry "semver::qualify::_unary" "$@"

   local expr="$1"; shift

   local rval

   case "${expr}" in
      [\<\>]\=*)
         semver::qualify::_op "${expr:0:2}" "${expr#??}" "" "$@"
         rval=$?
      ;;

      [\^\~]*)
         semver::qualify::_op "${expr:0:1}" "${expr#?}" "*" "$@"
         rval=$?
      ;;

      [\<\>\=]*)
         semver::qualify::_op "${expr:0:1}" "${expr#?}" "" "$@"
         rval=$?
      ;;

      *)
         semver::qualify::_op "=" "${expr}" "*" "$@"
         rval=$?
      ;;
   esac

   log_fluff "UNARY QUALIFY \"${expr}\" $1 $2 $3 $4 -> ${rval}"

   return ${rval}
}


semver::qualify::r_expr2_increment_partial()
{
   semver::parse::r_increment_numeric "${1##*.}"
   RVAL="${1%.*}.${RVAL}"
}


semver::qualify::_qualify()
{
   log_entry "semver::qualify::_qualify" "$@"

   local expr="$1"; shift

   local rval
   local expr1
   local expr2
   local op1
   local op2

   case "${expr}" in
      # a range, transform to >= <= (or >= <.. tricky)
      *\ \-\ *)
         expr1="${expr% -*}"
         case "${expr1}" in
            *\.*\.*-*)
               op1=">=!"
            ;;

            *)
               op1=">="
            ;;
         esac

         #
         # 1.1.1-prerelease-1 - 1.2.3   1.1.1-prerelease-2 should match
         #                          but 1.1.2-prerelease should not
         # 1.1.1 - 1.2.3-prerelease-2   1.2.3-prerelease-1 should match
         #                          but 1.2.3 should not
         # 1.1.1-prerelease-1 - 1.1.1-prerelease-3   1.1.1-prerelease-2 should match
         #                              1.1.1 should not
         expr2="${expr#*- }"
         case "${expr2}" in
            *\.*\.*-*)
               op2="<=!"
            ;;

            *\.*\.*)
               op2="<="
            ;;

            *)
               semver::qualify::r_expr2_increment_partial "${expr2}"
               expr2="${RVAL}"
               op2="<"
            ;;
         esac

         semver::qualify::_op "${op1}" "${expr1}" "*" "$@" &&
         semver::qualify::_op "${op2}" "${expr2}" "*" "$@"
         rval=$?
      ;;

      # an OR
      *\|\|*)
         expr1="${expr%%||}"
         expr2="${expr#*||}"
         semver::qualify::_qualify "${expr1}" "$@" || \
         semver::qualify::_qualify "${expr2}" "$@"
         rval=$?
      ;;

      # an AND
      *\ *)
         expr1="${expr%%\ *}"
         expr2="${expr#*\ }"
         semver::qualify::_qualify "${expr1}" "$@" && \
         semver::qualify::_qualify "${expr2}" "$@"
         rval=$?
      ;;

      *)
         semver::qualify::_unary "${expr}" "$@"
         rval=$?
      ;;
   esac

   log_fluff "QUALIFY \"${expr}\" $1 $2 $3 $4 -> ${rval}"

   return ${rval}
}


semver::qualify::sanitized_qualifier()
{
   log_entry "semver::qualify::sanitized_qualifier" "$@"

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


semver::qualify::qualify()
{
   log_entry "semver::qualify::qualify" "$@"

   local expr="$1"
   local major="$2"
   local minor="$3"
   local patch="$4"
   local prerelease="$5"

   semver::qualify::sanitized_qualifier "${expr}"

   # change order for convenience
   semver::qualify::_qualify "${RVAL}" "${major}" "${minor}" "${patch}" "${prerelease}"
}


semver_empty_qualifier=48
semver_no_qualifier=49
semver_semver_qualifier=50
semver_single_qualifier=52
semver_multi_qualifier=53


semver::qualify::r_type_description()
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


semver::qualify::_unary_type()
{
   log_entry "semver::qualify::_unary_type" "$@"

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
         if semver::parse::parse "${expr}" "YES"
         then
            rval=${semver_semver_qualifier}
         else
            if semver::qualify::parse_lenient "${expr}" "" "YES"
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
semver::qualify::_type()
{
   log_entry "semver::qualify::_type" "$@"

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
         semver::qualify::_unary_type "${expr}"
         rval=$?
      ;;
   esac
   return ${rval}
}


semver::qualify::qualifier_type_main()
{
   log_entry "semver::qualify::qualifier_type_main" "$@"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            semver::qualify::qualifier_type_usage
         ;;

         -q|--quiet)
            OPTION_QUIET='YES'
         ;;

         -*)
            semver::qualify::qualifier_type_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -ne 1 ] && semver::qualify::qualifier_type_usage

   local qualifier="$1"

   semver::qualify::sanitized_qualifier "${qualifier}"
   qualifier="${RVAL}"

   local rval

   semver::qualify::_type "${qualifier}"
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


semver::qualify::main()
{
   log_entry "semver::qualify::main" "$@"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            semver::qualify::usage
         ;;

         -q|--quiet)
            OPTION_QUIET='YES'
         ;;

         -*)
            semver::qualify::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -ne 2 ] && semver::qualify::usage

   local qualifier="$1"
   local version="$2"

   semver::qualify::sanitized_qualifier "${qualifier}"
   qualifier="${RVAL}"

   local _line
   local _build
   local _prerelease
   local _major
   local _minor
   local _patch

   if ! semver::parse::parse "${version}"
   then
      return 1
   fi

   if semver::qualify::qualify "${qualifier}" \
                               "${_major}" "${_minor}" "${_patch}" "${_prerelease}"
   then
      [ "${OPTION_QUIET}" != 'YES' ] && echo 'YES'
      return 0
   fi

   [ "${OPTION_QUIET}" != 'YES' ] && echo 'NO'
   return 2
}



semver::qualify::initialize()
{
   if [ -z "${MULLE_SEMVER_PARSE_SH}" ]
   then
      # shellcheck source=mulle-semver-parse.sh
      . "${MULLE_SEMVER_LIBEXEC_DIR}/mulle-semver-parse.sh" || exit 1
   fi
}

semver::qualify::initialize

