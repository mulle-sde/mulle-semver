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
MULLE_SEMVER_SORT_SH="included"

#
# to be able to parse the following functions, we have to turn extglob on here
#
semver::sort::usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} sort [options] <version>*

   Sort versions according to semver rules. If there is only
   one version given and the version is '-', versions will be read from
   standard input.

   Read https://docs.npmjs.com/cli/v6/using-npm/semver/ for the specification
   examples. mulle-semver does not match URLs and tags though!

   Especially prerelease versions are tricky!

Examples:
   ${MULLE_USAGE_NAME} sort 1.4.0 1.2.0 1.5.0

Options:
   -h          : this help
   --mergesort : use the mergesort algorithm
   --quicksort : use the quicksort algorithm (default)
   --quiet     : silently ignore improper semver version values
   --reverse   : output in descending order
   --unixsort  : use a quick and dirty sort, that is incorrect with prereleases
EOF
   exit 1
}


#
# the functions here expect an _array array variable in its scope
#
semver::sort::_r_qsort_12()
{
   local lo="$1"
   local hi="$2"

   [ ${lo} -le ${hi} ] || _internal_fail "failed assumption ${lo} <= ${hi}"

   local n

   # set -x
   n=$((hi - lo + 1))

   # special cases
   case ${n} in
      1)
         # set +x
         return 0
      ;;

      2)
         _a_line="${_array[${lo}]}"
         _b_line="${_array[${hi}]}"

         eval "${_a_line//_/_a_}" # get into _a_major etc.
         eval "${_b_line//_/_b_}" # get into _b_major etc.

         _comparisons=$((_comparisons + 1))
         #set +x
         semver::parse::compare_parsed "${_a_major}" "${_a_minor}" "${_a_patch}" "${_a_prerelease}" \
                               "${_b_major}" "${_b_minor}" "${_b_patch}" "${_b_prerelease}"
         rval="$?"
         #set -x

         if [ $rval -eq ${_semver_sort_descending} ]
         then
            tmp="${_array[${lo}]}"
            _array[${lo}]="${_array[${hi}]}"
            _array[${hi}]="${tmp}"
         fi
         #set +x
         return 0
      ;;
   esac
   #set +x
   return 1
}



#
# Full array given in A, returns i in RVAL2
# and changed A in RVAL
#
semver::sort::_r_qsort_partition()
{
   log_entry "semver::sort::_r_qsort_partition" "$@"

   local lo="$1"
   local hi="$2"

   #set -x
   #
   # the pivot could be random, but as the values are presorted
   #
   # we move all values less than the pivot to the left of the
   # pivot and all values larger than the pivot to the right
   #
   local pivot

   pivot=$(( (hi + lo) / 2))
   _b_line="${_array[${pivot}]}"
   eval "${_b_line//_/_b_}" # get into _b_major etc. (pivot)

   local i
   local j
   local tmp
   local rval

   i=$((lo - 1))
   j=$((hi + 1))

   while :
   do
      #
      # Find a value in left side greater or equal
      #
      while :
      do
         i=$((i + 1))
         _a_line="${_array[${i}]}" || _internal_fail "failed"
         eval "${_a_line//_/_a_}" # get into _a_major etc.

         #set +x
         # a is array[i], b is array[ pivot]
         _comparisons=$((_comparisons + 1))
         semver::parse::compare_parsed "${_a_major}" "${_a_minor}" "${_a_patch}" "${_a_prerelease}" \
                               "${_b_major}" "${_b_minor}" "${_b_patch}" "${_b_prerelease}"
         rval=$?
         #set -x

         # while array[i] < array[ pivot]
         if [ $rval -eq ${_semver_sort_ascending} ]
         then
            continue
         fi
         break
      done

      # Find a value in right side greater or equal
      while :
      do
         j=$((j - 1))
         _a_line="${_array[${j}]}"
         eval "${_a_line//_/_a_}" # get into _a_major etc.

         #set +x
         _comparisons=$((_comparisons + 1))
         semver::parse::compare_parsed "${_a_major}" "${_a_minor}" "${_a_patch}" "${_a_prerelease}" \
                               "${_b_major}" "${_b_minor}" "${_b_patch}" "${_b_prerelease}"
         rval=$?
         #set -x

         # while array[j] > array[ pivot]
         if [ $rval -eq ${_semver_sort_descending} ]
         then
            continue
         fi
         break
      done

      if [ $i -ge $j ]
      then
         RVAL="${j}"
         #set +x
         return
      fi

      tmp="${_array[${j}]}"
      _array[${j}]="${_array[${i}]}"
      _array[${i}]="${tmp}"
   done
}


semver::sort::_qsort()
{
   log_entry "semver::sort::_qsort" "$@"

   local lo="$1"
   local hi="$2"

   if semver::sort::_r_qsort_12 ${lo} ${hi}
   then
      return
   fi

   # we know now, we have at least 3 entries here

   local pivot

   semver::sort::_r_qsort_partition ${lo} ${hi}
   pivot="${RVAL}"

   #
   # Now we get a p.
   # We sort the array on the left side of the pivot and
   # the array on the right. We need to sort the pivot again once
   #
   # if the pivot is set to hi in the partition algorithm we
   # need to check here
   #
   if [ ${pivot} -gt ${lo} ]
   then
      semver::sort::_qsort ${lo} ${pivot}
   fi

   pivot=$((pivot + 1))
   if [ ${pivot} -lt ${hi} ]
   then
      semver::sort::_qsort ${pivot} ${hi}
   fi
}



#
# the functions here expect an _array array variable in its scope
#
semver::sort::_r_mergesort_012()
{
   local array="$1"
   local n="$2"

   [ "${IFS}" = $'\n' ] || _internal_fail "IFS not LF"

   # special cases
   # set -x
   case ${n} in
      0)
         RVAL=
         # set +x
         return 0
      ;;

      1)
         local line

         for line in ${array}
         do
            RVAL="${line}"
            break
         done
         # set +x
         return 0
      ;;

      2)

         local tmp
         local rval
         local line

         _a_line=
         for line in ${array}
         do
            if [ -z "${_a_line}" ]
            then
               _a_line="${line}"
            else
               _b_line="${line}"
               break
            fi
         done

         eval "${_a_line//_/_a_}" # get into _a_major etc.
         eval "${_b_line//_/_b_}" # get into _b_major etc.

         _comparisons=$((_comparisons + 1))
         # set +x
         semver::parse::compare_parsed "${_a_major}" "${_a_minor}" "${_a_patch}" "${_a_prerelease}" \
                               "${_b_major}" "${_b_minor}" "${_b_patch}" "${_b_prerelease}"
         rval="$?"
         # set -x

         if [ $rval -eq ${_semver_sort_descending} ]
         then
            r_add_line "${_b_line}" "${_a_line}"
         else
            r_add_line "${_a_line}" "${_b_line}"
         fi
         #set +x
         return 0
      ;;
   esac
   #set +x
   return 1
}


#
# mergesort can be better, if the input is random, we should have less
# comparisons, which are for some reason quite costly
#
semver::sort::_r_mergesort()
{
   log_entry "semver::sort::_r_mergesort" "$@"

   local array="$1"
   local n="$2"

   if semver::sort::_r_mergesort_012 "${array}" "${n}"
   then
      return
   fi

   local A
   local B

   local m
   local l

   m=$(( n / 2 ))
   l=$(( n - m))

   # sort both smaller arrays
   semver::sort::_r_mergesort "${array}" ${m}
   A="${RVAL}"

   # this will reset the IFS
   r_lines_in_range "${array}" ${m} ${l}
   IFS=$'\n'

   semver::sort::_r_mergesort "${RVAL}" ${l}
   B="${RVAL}"


   # now do the merge, basically walk through each sorted one
   # and append the smaller one to the result

   log_debug "A: $A"
   log_debug "B: $B"

   declare -a a_array
   declare -a b_array

   # this works on old macOS bash, is it much slower ?
   IFS=$'\n' read -r -d '' -a a_array <<< "${A}"
   IFS=$'\n' read -r -d '' -a b_array <<< "${B}"

   [ ${#b_array[@]} -eq ${l} ] || _internal_fail "failed assumption about B (${#b_array[@]} vs ${l})"
   [ ${#a_array[@]} -eq ${m} ] || _internal_fail "failed assumption about A (${#a_array[@]} vs ${m})"

   local i
   local j
   local k
   local rval
   declare -a result

   #set -x
   i=0
   j=0
   k=0
   _a_major=""
   _b_major=""

   while :
   do
      if [ -z "${_a_major}" ]
      then
         if [ $i -ge $m ]
         then
            while [ $j -lt $l ]
            do
               _b_line="${b_array[${j}]}"
#               [ -z "${_b_line}" ] && _internal_fail "failed assumption for j=$j"
               result[${k}]="${_b_line}"
               k=$((k + 1))
               j=$((j + 1))
            done
            break
         fi

         _a_line="${a_array[${i}]}"
         #[ -z "${_a_line}" ] && _internal_fail "failed assumption for i=$i"

         eval "${_a_line//_/_a_}" # get into a_major etc.
      fi

      if [ -z "${_b_major}" ]
      then
         if [ $j -ge $l ]
         then
            while [ $i -lt $m ]
            do
               _a_line="${a_array[${i}]}"
#               [ -z "${_a_line}" ] && _internal_fail "failed assumption for i=$i"
               result[${k}]="${_a_line}"
               k=$((k + 1))
               i=$((i + 1))
            done
            break
         fi

         _b_line="${b_array[${j}]}"
         #[ -z "${_b_line}" ] && _internal_fail "failed assumption for j=$j"
         eval "${_b_line//_/_b_}" # get into a_major etc.
      fi

      _comparisons=$((_comparisons + 1))
      #set +x
      semver::parse::compare_parsed "${_a_major}" "${_a_minor}" "${_a_patch}" "${_a_prerelease}" \
                                    "${_b_major}" "${_b_minor}" "${_b_patch}" "${_b_prerelease}"
      rval=$?
      #set -x

      if [ $rval -ne ${_semver_sort_descending} ]
      then
#         [ -z "${_a_line}" ] && _internal_fail "failed assumption for _a_line"
         result[${k}]="${_a_line}"
         k=$((k + 1))
         i=$((i + 1))
         _a_major=""
      else
#         [ -z "${_b_line}" ] && _internal_fail "failed assumption for _b_line"
         result[${k}]="${_b_line}"
         k=$((k + 1))
         j=$((j + 1))
         _b_major=""
      fi
   done
   #set +x

   RVAL="${result[*]}"
   log_debug "RVAL: $RVAL"
}


semver::sort::r_sort_parsed_versions()
{
   log_entry "semver::sort::r_sort_parsed_versions" "$@"

   local array="$1"
   local reverse="$2"
   local algorithm=${3:-quicksort}

   # empty array breaks us
   if [ -z "${array}" ]
   then
      RVAL=
      return
   fi

   [ -z "${semver_descending}" ] && _internal_fail "semver_descending not set"
   [ -z "${semver_ascending}" ] && _internal_fail "semver_ascending not set"

   local _semver_sort_ascending=${semver_ascending}
   local _semver_sort_descending=${semver_descending}

   if [ "${reverse}" = 'YES' ]
   then
      _semver_sort_ascending=${semver_descending}
      _semver_sort_descending=${semver_ascending}
   fi

   shell_disable_glob
   {
      declare -a _array
      local n

      IFS=$'\n' read -r -d '' -a _array <<< "${array}"
      n=${#_array[@]}

      # define a few local variables for later benefit
      local _comparisons
      local _a_line
      local _a_major
      local _a_minor
      local _a_patch
      local _a_prerelease
      local _a_build

      local _b_line
      local _b_major
      local _b_minor
      local _b_patch
      local _b_prerelease
      local _b_build

      _comparisons=0
      if [ "${algorithm}" = 'mergesort' ]
      then
         semver::sort::_r_mergesort "${array}" ${n}
      else
         # When used in a function, declare makes each name local
         if [ ${n} -ne 0 ]
         then
            semver::sort::_qsort 0 $(( ${n} - 1 ))
         fi
         RVAL="${_array[*]}"
      fi
      log_debug   "SORTED: ${RVAL}"
      log_verbose "COMPARISONS=${_comparisons}"
   }
   shell_enable_glob

   IFS="${DEFAULT_IFS}"
}


semver::sort::main()
{
   log_entry "semver::sort::main" "$@"

   local OPTION_REVERSE
   local OPTION_QUIET
   local OPTION_ALGORITHM
   local OPTION_LENIENT
   local OPTION_PRETTY
   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            semver::sort::usage
         ;;

         -q|--quiet)
            OPTION_QUIET="YES"
         ;;

         -l|--lenient)
            OPTION_LENIENT="YES"
         ;;

         --pretty)
            OPTION_PRETTY="YES"
         ;;

         -r|--reverse)
            OPTION_REVERSE="YES"
         ;;

         --unixsort)
            OPTION_ALGORITHM="unixsort"
         ;;

         --quicksort)
            OPTION_ALGORITHM="quicksort"
         ;;

         --mergesort)
            OPTION_ALGORITHM="mergesort"
         ;;

         -)
             break
         ;;

         -*)
            semver::sort::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -lt 1 ] && semver::sort::usage

   local versions

   semver::parse::r_grab_versions semver::sort::usage "$@"
   versions="${RVAL}"

   #
   # The unix sort is good enough in most cases. But it does not sort
   # prerelease before the actual release but after
   # It also doesn't help the sort speed perceptibly
   #
   if [ "${OPTION_ALGORITHM}" = "unixsort" ]
   then
      versions="`LC_ALL=C sort -t. -k1g -k2g -k3g -k4 -k5 -k6 -k7 -k8 -k9  <<< "${versions/-/.-}" `"
      versions="${versions/.-/-}"
   fi

   local parsed_versions

   semver::parse::parse_versions "${versions}" "${OPTION_QUIET}" "${OPTION_LENIENT}"
   parsed_versions="${RVAL}"

   if [ "${OPTION_ALGORITHM}" != "unixsort" ]
   then
      #
      # now that we have all versions in parsed format, we need to sort
      # them
      semver::sort::r_sort_parsed_versions "${parsed_versions}" \
                                          "${OPTION_REVERSE}" \
                                          "${OPTION_ALGORITHM}"
   fi

   semver::parse::parsed_versions_decriptions "${RVAL}" "${OPTION_PRETTY}"
   printf "%s\n" "${RVAL}"
}



semver::sort::initialize()
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

   if [ -z "${MULLE_ARRAY_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-array.sh" || exit 1
   fi
}

semver::sort::initialize
