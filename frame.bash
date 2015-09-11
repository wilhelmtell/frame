DOT_FRAME="$HOME/.frame"
VERSION="$(git describe --dirty)"
TEMPFILE_TEMPLATE=frame.XXXXXXXX

version() {
  echo "frame $VERSION"
}

help() {
  echo "Usage: frame <cmd>"
  echo
  echo "Maintain a stack of notes."
  echo
  echo " * We refer to notes as frames."
  echo " * A frame's subject line is its first line."
  echo
  echo " help"
  echo " version"
  echo " depth      print frames count"
  echo " top        print last frame"
  echo " pop        remove top frame, then print the (next) top frame"
  echo " push [-e]  create a new frame"
  echo "            with -e, use \$EDITOR to create the new frame"
  echo " trace      list all frames' subject lines"
  echo " show       print the nth frame. n grows from earliest to latest."
}

verify_version() {
  true
}

verify_help() {
  true
}

verify_trace() {
  true
}

trace() {
  sed 's/\x0.*//' "$DOT_FRAME" |nl
}

verify_show_argument_count() {
  [ $# -eq 2 ] || echo "usage: frame show <[-]n>" >&2
  [ $# -eq 2 ]
}

verify_show_argument_is_numeric() {
  echo "$2" |egrep -q '^-?[1-9][0-9]*$'
  local error=$?
  [ $error -eq 0 ] || echo "error: show argument not numeric." >&2
  [ $error -eq 0 ]
}

verify_show_argument_is_within_bounds() {
  local n=$(echo "$2" |tr -d -)
  local line_count=$(wc -l "$DOT_FRAME" |cut -f1 -d' ')
  [ $n -le $line_count ] || echo "error: show argument out of bounds." >&2
  [ $n -le $line_count ]
}

verify_show_argument() {
  verify_show_argument_is_numeric "$@" &&
    verify_show_argument_is_within_bounds "$@"
}

verify_show() {
  verify_show_argument_count "$@" &&
    verify_show_argument "$@"
}

show_from_top() {
  head -n "$2" "$DOT_FRAME" |tail -n 1 |tr -d '\n' |tr '\0' '\n'
}

show_from_bottom() {
  local n=$(echo "$2" |tr -d -)
  tail -n $n "$DOT_FRAME" |head -n 1 |tr -d '\n' |tr '\0' '\n'
}

show() {
  if echo "$2" |egrep -q '^-';
  then
    show_from_bottom "$@"
  else
    show_from_top "$@"
  fi
}

rm_top() {
  TMP="$(mktemp $TEMPFILE_TEMPLATE)"
  head -n -1 "$DOT_FRAME" >"$TMP"
  mv "$TMP" "$DOT_FRAME"
}

top() {
  show show -1
}

pop() {
  rm_top
  top
}

push_stdin() {
  local temporary_file="$(mktemp $TEMPFILE_TEMPLATE)"
  tr '\n' '\0' </dev/stdin >>"$temporary_file"
  echo >>"$temporary_file"
  if [ $(tr -d '[:space:]\0' <"$temporary_file" |wc -c) -gt 0 ];
  then
    cat "$temporary_file" >>"$DOT_FRAME"
  else
    echo "error: empty text, push cancelled." >&2
  fi
  rm "$temporary_file"
}

push_editor() {
  local temporary_file="$(mktemp $TEMPFILE_TEMPLATE)"
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
  elif [ $1 = trace ]; then verify_trace
  elif [ $1 = show ]; then verify_show "$@"
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
  elif [ $1 = trace ]; then trace
  elif [ $1 = show ]; then show "$@"
  fi
}

frame() {
  if [ $# -lt 1 ]; then help
  else verify "$@" && process "$@"
  fi
}
