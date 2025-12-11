# _mulle_semver_complete: bash completion for mulle-semver
_mulle_semver_complete()
{
   local cur prev words cword
   _get_comp_words_by_ref -n : cur prev words cword

   local cmd="${words[1]}"
   local global_options="-h --help -n -s -v -vv -vvv"

   if [ $cword -eq 1 ]; then
      COMPREPLY=( $(compgen -W "parse numeric-compare alphanumeric-compare compare qualify search sort qualifier-type libexec-dir version help $global_options" -- "$cur") )
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
   local options="-h --help -q --quiet -l --lenient --raw --cooked --pretty --no-pretty -"
   if [[ "$cur" == -* ]]; then
      COMPREPLY=( $(compgen -W "$options" -- "$cur") )
   else
      COMPREPLY=()
   fi
}

_mulle_semver_numeric_compare_complete()
{
   local options="-h --help -q --quiet"
   if [[ "$cur" == -* ]]; then
      COMPREPLY=( $(compgen -W "$options" -- "$cur") )
   else
      COMPREPLY=()
   fi
}

_mulle_semver_alphanumeric_compare_complete()
{
   local options="-h --help -q --quiet"
   if [[ "$cur" == -* ]]; then
      COMPREPLY=( $(compgen -W "$options" -- "$cur") )
   else
      COMPREPLY=()
   fi
}

_mulle_semver_compare_complete()
{
   local options="-h --help -q --quiet -l --lenient"
   if [[ "$cur" == -* ]]; then
      COMPREPLY=( $(compgen -W "$options" -- "$cur") )
   else
      COMPREPLY=()
   fi
}

_mulle_semver_qualify_complete()
{
   local options="-h --help -q --quiet"
   if [[ "$cur" == -* ]]; then
      COMPREPLY=( $(compgen -W "$options" -- "$cur") )
   else
      COMPREPLY=()
   fi
}

_mulle_semver_search_complete()
{
   local options="-h --help -q --quiet -l --lenient -"
   if [[ "$cur" == -* ]]; then
      COMPREPLY=( $(compgen -W "$options" -- "$cur") )
   else
      COMPREPLY=()
   fi
}

_mulle_semver_sort_complete()
{
   local options="-h --help -q --quiet -l --lenient --pretty -r --reverse --unixsort --quicksort --mergesort -"
   if [[ "$cur" == -* ]]; then
      COMPREPLY=( $(compgen -W "$options" -- "$cur") )
   else
      COMPREPLY=()
   fi
}

_mulle_semver_qualifier_type_complete()
{
   local options="-h --help -q --quiet"
   if [[ "$cur" == -* ]]; then
      COMPREPLY=( $(compgen -W "$options" -- "$cur") )
   else
      COMPREPLY=()
   fi
}

complete -F _mulle_semver_complete mulle-semver
