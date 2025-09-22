# _mulle_semver_complete: bash completion for mulle-semver
_mulle_semver_complete()
{
   local cur prev words cword
   _get_comp_words_by_ref -n : cur prev words cword

   local cmd="${words[1]}"
   local global_options="-h --help"

   if [ $cword -eq 1 ]; then
      COMPREPLY=( $(compgen -W "parse numeric-compare alphanumeric-compare compare qualify search sort qualifier-type libexec-dir version $global_options" -- "$cur") )
      return 0
   fi

   case "$cmd" in
      -h|--help|help)
         return 0
         ;;
      parse)
         _mulle_semver_parse_complete
         ;;
      numeric-compare)
         _mulle_semver_numeric_compare_complete
         ;;
      alphanumeric-compare)
         _mulle_semver_alphanumeric_compare_complete
         ;;
      compare)
         _mulle_semver_compare_complete
         ;;
      qualify)
         _mulle_semver_qualify_complete
         ;;
      search)
         _mulle_semver_search_complete
         ;;
      sort)
         _mulle_semver_sort_complete
         ;;
      qualifier-type)
         _mulle_semver_qualifier_type_complete
         ;;
      libexec-dir|version)
         if [[ "$cur" == -* ]]; then
            COMPREPLY=( $(compgen -W "$global_options" -- "$cur") )
         fi
         ;;
      *)
         COMPREPLY=()
         ;;
   esac
}

_mulle_semver_parse_complete()
{
   local options="-h --help -q --quiet -l --lenient --raw --cooked --pretty --no-pretty"
   local i=2
   while [ $i -le $cword ]; do
      if [[ "${words[i]}" == --* ]]; then
         if [[ "${words[i]}" == --raw || "${words[i]}" == --cooked || "${words[i]}" == --quiet || "${words[i]}" == --lenient || "${words[i]}" == --pretty || "${words[i]}" == --no-pretty ]]; then
            COMPREPLY=()
            return 0
         fi
      elif [[ "${words[i]}" == -* ]]; then
         case "${words[i]}" in
            -q|-l)
               COMPREPLY=()
               return 0
               ;;
         esac
      fi
      ((i++))
   done
   if [[ "$prev" == -* || "$prev" == --* ]]; then
      case "$prev" in
         --raw|--cooked|--quiet|--lenient|--pretty|--no-pretty|-q|-l)
            COMPREPLY=()
            ;;
         *)
            COMPREPLY=( $(compgen -W "$options" -- "$cur") )
            ;;
      esac
   elif [[ "$cur" == -* ]]; then
      COMPREPLY=( $(compgen -W "$options" -- "$cur") )
   else
      COMPREPLY=()
   fi
}

_mulle_semver_numeric_compare_complete()
{
   local options="-h --help -q --quiet"
   if [[ "$prev" == -* ]]; then
      case "$prev" in
         -q|--quiet)
            COMPREPLY=()
            ;;
         *)
            COMPREPLY=( $(compgen -W "$options" -- "$cur") )
            ;;
      esac
   elif [[ "$cur" == -* ]]; then
      COMPREPLY=( $(compgen -W "$options" -- "$cur") )
   else
      COMPREPLY=()
   fi
}

_mulle_semver_alphanumeric_compare_complete()
{
   local options="-h --help -q --quiet"
   if [[ "$prev" == -* ]]; then
      case "$prev" in
         -q|--quiet)
            COMPREPLY=()
            ;;
         *)
            COMPREPLY=( $(compgen -W "$options" -- "$cur") )
            ;;
      esac
   elif [[ "$cur" == -* ]]; then
      COMPREPLY=( $(compgen -W "$options" -- "$cur") )
   else
      COMPREPLY=()
   fi
}

_mulle_semver_compare_complete()
{
   local options="-h --help -q --quiet -l --lenient"
   if [[ "$prev" == -* ]]; then
      case "$prev" in
         -q|--quiet|-l|--lenient)
            COMPREPLY=()
            ;;
         *)
            COMPREPLY=( $(compgen -W "$options" -- "$cur") )
            ;;
      esac
   elif [[ "$cur" == -* ]]; then
      COMPREPLY=( $(compgen -W "$options" -- "$cur") )
   else
      COMPREPLY=()
   fi
}

_mulle_semver_qualify_complete()
{
   local options="-h --help -q --quiet"
   if [[ "$prev" == -* ]]; then
      case "$prev" in
         -q|--quiet)
            COMPREPLY=()
            ;;
         *)
            COMPREPLY=( $(compgen -W "$options" -- "$cur") )
            ;;
      esac
   elif [[ "$cur" == -* ]]; then
      COMPREPLY=( $(compgen -W "$options" -- "$cur") )
   else
      COMPREPLY=()
   fi
}

_mulle_semver_search_complete()
{
   local options="-h --help -q --quiet -l --lenient"
   if [[ "$prev" == -* ]]; then
      case "$prev" in
         -q|--quiet|-l|--lenient)
            COMPREPLY=()
            ;;
         *)
            COMPREPLY=( $(compgen -W "$options" -- "$cur") )
            ;;
      esac
   elif [[ "$cur" == -* ]]; then
      COMPREPLY=( $(compgen -W "$options" -- "$cur") )
   else
      COMPREPLY=()
   fi
}

_mulle_semver_sort_complete()
{
   local options="-h --help -q --quiet -l --lenient --pretty -r --reverse --unixsort --quicksort --mergesort"
   local i=2
   while [ $i -le $cword ]; do
      if [[ "${words[i]}" == --* ]]; then
         if [[ "${words[i]}" == --quiet || "${words[i]}" == --lenient || "${words[i]}" == --pretty || "${words[i]}" == --reverse || "${words[i]}" == --unixsort || "${words[i]}" == --quicksort || "${words[i]}" == --mergesort ]]; then
            COMPREPLY=()
            return 0
         fi
      elif [[ "${words[i]}" == -* ]]; then
         case "${words[i]}" in
            -q|-l|-r)
               COMPREPLY=()
               return 0
               ;;
         esac
      fi
      ((i++))
   done
   if [[ "$prev" == -* || "$prev" == --* ]]; then
      case "$prev" in
         --quiet|--lenient|--pretty|--reverse|--unixsort|--quicksort|--mergesort|-q|-l|-r)
            COMPREPLY=()
            ;;
         *)
            COMPREPLY=( $(compgen -W "$options" -- "$cur") )
            ;;
      esac
   elif [[ "$cur" == -* ]]; then
      COMPREPLY=( $(compgen -W "$options" -- "$cur") )
   else
      COMPREPLY=()
   fi
}

_mulle_semver_qualifier_type_complete()
{
   local options="-h --help -q --quiet"
   if [[ "$prev" == -* ]]; then
      case "$prev" in
         -q|--quiet)
            COMPREPLY=()
            ;;
         *)
            COMPREPLY=( $(compgen -W "$options" -- "$cur") )
            ;;
      esac
   elif [[ "$cur" == -* ]]; then
      COMPREPLY=( $(compgen -W "$options" -- "$cur") )
   else
      COMPREPLY=()
   fi
}

complete -F _mulle_semver_complete mulle-semver
