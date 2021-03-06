#!/bin/bash

error() {
  echo "error: ${2}" >&2
  return "$1"
}

dot_frame_path() {
  local dot_frame="${1:-$HOME/.frame}"
  if [ -d $dot_frame ]
  then
    echo $dot_frame/.frame
  else
    echo $dot_frame
  fi
}

version() {
  echo "frame $VERSION"
}

help() {
  echo "Usage: ${SCRIPT_BASENAME} <cmd>"
  echo
  echo "Manipulate a stack of notes."
  echo
  echo "We refer to notes as frames. A frame's subject line is its first"
  echo "line."
  echo
  echo "Valid commands:"
  echo
  echo " help"
  echo " version"
  echo " depth      print frames count."
  echo " top        print last frame."
  echo " pop        remove top frame, then print the (next) top frame."
  echo " push [-e]  create a new frame."
  echo "            with -e, use \$EDITOR to create the new frame."
  echo " trace      list all frames' subject lines."
  echo " list       alias for trace."
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

verify_list() {
  verify_trace "$@"
}

trace() {
  perl -pe 's/\000.*//' "$DOT_FRAME" |nl
}

list() {
  trace "$@"
}

verify_show_argument_count() {
  [ $# -eq 2 ] || error 1 "usage: frame show <[-]n>"
}

verify_show_argument_is_not_zero() {
  egrep -v -q '^0+$' <<<"$2"
  local error_code=$?
  [ $error_code -eq 0 ] || error 1 "show argument is zero."
}

verify_show_argument_is_numeric() {
  egrep -q '^-?[1-9][0-9]*$' <<<"$2"
  local error_code=$?
  [ $error_code -eq 0 ] || error 1 "show argument not numeric."
}

verify_show_argument_is_within_bounds() {
  local n=$(echo "$2" |tr -d -)
  local line_count=$(depth)
  [ $n -le $line_count ] || error 1 "show argument out of bounds."
}

verify_show_argument() {
  verify_show_argument_is_not_zero "$@" &&
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
  if egrep -q '^-' <<<"$2"
  then
    show_from_bottom "$@"
  else
    show_from_top "$@"
  fi
}

rm_top() {
  TMP="$(mktemp $TEMPFILE_TEMPLATE)"
  local count=$(depth)
  [[ $count > 1 ]] && head -n $((count - 1)) "$DOT_FRAME" >"$TMP"
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
  cat <(tr '\n' '\0') <(echo) >>"$temporary_file"
  if [ $(tr -d '[:space:]\0' <"$temporary_file" |wc -c) -gt 0 ];
  then
    cat "$temporary_file" >>"$DOT_FRAME"
  else
    error 1 "empty text, push cancelled."
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
  wc -l "$DOT_FRAME" |awk '{ print $1; }'
}

verify_top_dotframe_is_not_a_directory() {
  [ -d "$DOT_FRAME" ] && error 1 "$DOT_FRAME is a directory."
  [ ! -d "$DOT_FRAME" ]
}

verify_top_dotframe_exists() {
  [ ! -e "$DOT_FRAME" ] && touch "$DOT_FRAME"
  if [ ! -e "$DOT_FRAME" ];
  then
    error 1 "failed to create $DOT_FRAME."
    false
  fi
}

verify_top_valid_dotframe() {
  verify_top_dotframe_is_not_a_directory &&
    verify_top_dotframe_exists
}

verify_top_dotframe_is_not_empty() {
  local line_count=$(depth)
  [ $line_count -lt 1 ] && error 1 "$DOT_FRAME is empty."
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
  [ $# -eq 2 -a "$2" != "-e" ] && echo "usage: frame push [-e]"
  [ $# -le 2 ] && [ $# -ne 2 -o "$2" = "-e" ]
}

verify_depth_commandline() {
  [ $# -ne 1 ] && echo "usage: frame depth"
  [ $# -eq 1 ]
}

verify_depth() {
  verify_top_valid_dotframe && verify_depth_commandline "$@"
}

invalid_command() {
  error 1 "invalid command. try \`${SCRIPT_BASENAME} help'."
  false
}

verify() {
  local cmds="top|pop|push|depth|version|help|trace|list|show"
  if egrep --quiet "^(${cmds})$" <<<"$1"
  then
    verify_${1} "$@"
  else
    invalid_command
  fi
}

frame() {
  if [ $# -lt 1 ]; then help
  else verify "$@" && ${1} "$@"
  fi
}

DOT_FRAME="$(dot_frame_path "${DOT_FRAME}")"
VERSION="$(git describe --dirty)"
TEMPFILE_TEMPLATE=frame.XXXXXXXX
SCRIPT_BASENAME="$(basename "$0")"

frame "$@"
