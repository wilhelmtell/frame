DOT_FRAME="$HOME/.frame"

version() {
  echo "frame v0.2"
}

help() {
  echo "Usage: frame <cmd>"
  echo
  echo "Maintain a stack of notes. We refer to notes as frames."
  echo
  echo " help"
  echo " version"
  echo " depth      print frames count"
  echo " top        print last frame"
  echo " pop        remove top frame, then print the (next) top frame"
  echo " push [-e]  create a new frame"
  echo "            with -e, use \$EDITOR to create the new frame"
}

verify_version() {
  true
}

verify_help() {
  true
}

rm_top() {
  TMP="$(mktemp)"
  head -n -1 "$DOT_FRAME" >"$TMP"
  mv "$TMP" "$DOT_FRAME"
}

top() {
  tail -n 1 "$DOT_FRAME" |
    tr -d '\n' |
    tr '\0' '\n'
}

pop() {
  rm_top
  top
}

push_stdin() {
  tr '\n' '\0' </dev/stdin >>"$DOT_FRAME"
  echo >>"$DOT_FRAME"
}

push_editor() {
  local temporary_file="$(mktemp)"
  $EDITOR "$temporary_file"
  [ $? -eq 0 ] && push_stdin <"$temporary_file"
  rm "$temporary_file"
}

push() {
  if [ $# -eq 1 ]; then push_stdin
  elif [ "$2" = "-e" ]; then push_editor
  fi
}

depth() {
  wc -l "$DOT_FRAME" |cut -f1 -d' '
}

verify_top_dotframe_is_not_a_directory() {
  [ -d "$DOT_FRAME" ] && echo "error: $DOT_FRAME is a directory." >&2
  [ ! -d "$DOT_FRAME" ]
}

verify_top_dotframe_exists() {
  [ ! -e "$DOT_FRAME" ] && touch "$DOT_FRAME"
  if [ ! -e "$DOT_FRAME" ];
  then
    echo "error: failed to create $DOT_FRAME." >&2
    false
  fi
}

verify_top_valid_dotframe() {
  verify_top_dotframe_is_not_a_directory &&
    verify_top_dotframe_exists
}

verify_top_dotframe_is_not_empty() {
  local line_count="$(wc -l "$DOT_FRAME" |cut -f1 -d' ')"
  [ $line_count -lt 1 ] && echo "error: $DOT_FRAME is empty." >&2
  [ $line_count -gt 0 ]
}

verify_top() {
  verify_top_valid_dotframe
}

verify_pop() {
  verify_top
}

verify_push() {
  [ $# -gt 2 ] && echo "usage: frame push [-e]"
  [ $# -eq 1 -o $# -eq 2 ]
}

verify_depth_commandline() {
  [ $# -ne 1 ] && echo "usage: frame depth"
  [ $# -eq 1 ]
}

verify_depth() {
  verify_top_valid_dotframe && verify_depth_commandline "$@"
}

invalid_command() {
  echo "error: invalid command." >&2
  false
}

verify() {
  if [ $1 = top ]; then verify_top
  elif [ $1 = pop ]; then verify_pop
  elif [ $1 = push ]; then verify_push "$@"
  elif [ $1 = depth ]; then verify_depth "$@"
  elif [ $1 = version ]; then verify_version
  elif [ $1 = help ]; then verify_help
  else invalid_command
  fi
}

process() {
  if [ $1 = top ]; then top
  elif [ $1 = pop ]; then pop
  elif [ $1 = push ]; then push "$@"
  elif [ $1 = depth ]; then depth
  elif [ $1 = version ]; then version
  elif [ $1 = help ]; then help
  fi
}

frame() {
  if [ $# -lt 1 ]; then help
  else verify "$@" && process "$@"
  fi
}
