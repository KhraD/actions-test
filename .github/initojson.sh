awk '
BEGIN {
    g_keys_i = 0
    section = ""; count = 0; n_sections = 0
    print "{"
}

# Skip empty lines or comment lines (semicolon)
/^[[:space:]]*$/ || /^[[:space:]]*;/ {
    next
}

# Match section headers like [section.name]
/^\[[^]]+\]$/ {
    section = substr($0, 2, length($0) - 2)
    n_sections++
    next
}

# Match key = value (optionally quoted)
$0 ~ /^[[:space:]]*[^#;][^=]*=[^=]*$/ {
    line = $0
    sub(/^[[:space:]]+/, "", line)
    sub(/[[:space:]]+$/, "", line)

    split(line, kv, "=")
    key = kv[1]
    value = kv[2]

    sub(/[[:space:]]+$/, "", key)
    sub(/^[[:space:]]+/, "", value)

    if (value ~ /^"(.*)"$/) {
        value = substr(value, 2, length(value) - 2)
    }

    if (section == "") {
        g_keys[key] = value
        g_keys_order[g_keys_i++] = key
    } else {
        data[section "." key] = value
        section_keys[section] = section_keys[section] ? section_keys[section] "," key : key
    }
}

END {
    # Print global keys as "global": { ... }
    printf "\"global\":{"
    for (i = 0; i < length(g_keys_order); i++) {
        k = g_keys_order[i]
        printf "\"%s\":\"%s\"", k, g_keys[k]
        if (i < length(g_keys_order) - 1) printf ","
    }
    printf "}"

    # Print sections and their keys
    idx = 0
    for (s in section_keys) {
        printf ",\"preset.%d\":{", idx
        split(section_keys[s], keys, ",")
        for (i = 1; i <= length(keys); i++) {
            k = keys[i]
            printf "\"%s\":\"%s\"", k, data[s "." k]
            if (i < length(keys)) printf ","
        }
        printf "}"
        idx++
    }

    # Generate mat_idxs array: from 0 to floor(n_sections / 2) - 1
    half = int(n_sections / 2)
    printf ",\"mat_idxs\":["
    for (i = 0; i < half; i++) {
        printf "%d", i
        if (i < half - 1) printf ","
    }
    print "]}"
}
'