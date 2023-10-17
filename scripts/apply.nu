#! /usr/bin/env nu

# @see https://www.nushell.sh/zh-CN/book/
use share.nu

let globals = (share get_globals)




$globals.snapshot_needed | each { |it|
  let sources = $it.sources
  let target = $it.target

  if (not ($target | path exists)) {
    mkdir $target
    copy -r $"($globals.original)/*" $target
  }

  $sources | par-each { |it|
      let source_path = ($it | path expand)
      let source_dirname =  ($it | path dirname)
      let source_basename = ($it | path basename)

      let target_full_path = $"($target)/($source_basename)"

      mkdir $source_dirname
      mkdir $target_full_path

      rsync -av $target_full_path ($source_dirname | path expand)
  }
}





