#! /usr/bin/env nu

# @see https://www.nushell.sh/zh-CN/book/
use share.nu

let globals = (share get_globals)


$globals.snapshot_needed | each { |it|
  let sources = $it.sources
  let target_dir = $it.target

  mkdir $target_dir

  $it.sources | par-each { |it|
    let source_path = ($it | path expand)
    rsync -av $source_path $target_dir
  }
}