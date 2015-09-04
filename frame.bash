DOT_FRAME="$HOME/.frame"

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
  top
  rm_top
}

push() {
  tr '\n' '\0' </dev/stdin >>"$DOT_FRAME"
  echo >>"$DOT_FRAME"
}

verify_top_dotframe_is_not_a_directory() {
  [ -d "$DOT_FRAME" ] && echo "error: $DOT_FRAME is a directory." >&2
  [ ! -d "$DOT_FRAME" ]
}

verify_top_dotframe_exists() {
  [ ! -e "$DOT_FRAME" ] && echo "error: $DOT_FRAME does not exist." >&2
  [ -e "$DOT_FRAME" ]
}

verify_top_dotframe_is_not_empty() {
  local line_count="$(wc -l "$DOT_FRAME" |cut -f1 -d' ')"
  [ $line_count -lt 1 ] && echo "error: $DOT_FRAME is empty." >&2
  [ $line_count -gt 0 ]
}

verify_top() {
  verify_top_dotframe_is_not_a_directory &&
    verify_top_dotframe_exists &&
    verify_top_dotframe_is_not_empty
}

verify_pop() {
  verify_top
}

verify_push() {
  true
}

verify() {
  if [ $1 = top ]; then verify_top
  elif [ $1 = pop ]; then verify_pop
  elif [ $1 = push ]; then verify_push
  fi
}

process() {
  if [ $1 = top ]; then top
  elif [ $1 = pop ]; then pop
  elif [ $1 = push ]; then push
  fi
}

frame() {
  if [ $# -lt 1 ]; then echo "usage: frame <top|pop|push>"
  else verify "$@" && process "$@"
  fi
}
