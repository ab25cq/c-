#!/bin/sh
set -eu

compiler=${1:-./c-}
work=${TMPDIR:-/tmp}/cminus-safe-fuzz
mkdir -p "$work"

array_receivers='values (values) ((values)) (0,values) (values+1)'
for receiver in $array_receivers; do
    source="$work/array.c-"
    printf '%s\n' 'int main(void) {' '    int values[2] = { 1, 2 };' '    int index = 3;' "    return ${receiver}[index];" '}' > "$source"
    if "$compiler" "$source" > /dev/null 2> "$work/error"; then
        echo "safe-mode fuzz accepted array receiver: $receiver" >&2
        exit 1
    fi
done

for call in '(malloc)(8)' '((malloc))(8)' '(malloc)/**/(8)' '(/*x*/malloc)(8)' '(0, malloc)(8)'; do
    source="$work/call.c-"
    printf '%s\n' 'unsafe {' '#include <stdlib.h>' '}' 'int main(void) {' "    ${call};" '    return 0;' '}' > "$source"
    if "$compiler" "$source" > /dev/null 2> "$work/error"; then
        echo "safe-mode fuzz accepted heap call: $call" >&2
        exit 1
    fi
done

echo safe-mode-fuzz-ok
