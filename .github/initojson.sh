awk '
BEGIN {
  printf "{"
  section_count = 0
  first_section = 1
}
/^\s*\[.*\]\s*$/ {
  if (!first_section) {
    printf "},"
  }
  section_name = $0
  gsub(/^\s*\[|\]\s*$/, "", section_name)
  section_names[section_count++] = section_name
  printf "\"%s\":{", section_name
  key_count = 0
  first_section = 0
  next
}
/^[^#;].*=.*$/ {
  split($0, kv, "=")
  key = kv[1]
  value = substr($0, index($0, "=") + 1)

  # Trim whitespace
  gsub(/^[ \t]+|[ \t]+$/, "", key)
  gsub(/^[ \t]+|[ \t]+$/, "", value)

  # Remove outer quotes if any
  if ((value ~ /^".*"$/) || (value ~ /^'\''.*'\''$/)) {
    value = substr(value, 2, length(value)-2)
  }

  # Escape double quotes
  gsub(/"/, "\\\"", value)

  if (key_count++ > 0) {
    printf ","
  }
  printf "\"%s\":\"%s\"", key, value
  next
}
END {
  if (section_count > 0) {
    printf "},"
  }

  # Add mat_idxs array starting from 0
  max_idx = int(section_count / 2)
  printf "\"mat_idxs\":["
  for (i = 0; i < max_idx; i++) {
    printf i
    if (i < max_idx - 1) {
      printf ","
    }
  }
  printf "]}"
}
'