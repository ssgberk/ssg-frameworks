#!/bin/bash
# DocFX has no collection concept: a page cannot list other pages. This writes index.md with one
# front matter entry per post (read from each post's first lines); the template renders the list.
export LANG=C.UTF-8
shopt -s nullglob
rows=()
for f in posts/*.md; do
    b=${f##*/}; b=${b%.md}
    t= d= s=
    while IFS= read -r l; do
        case $l in
            "title: "*) t=${l#title: } ;;
            "date: "*) d=${l#date: } ;;
            "summary: "*) s=${l#summary: }; break ;;
        esac
    done < "$f"
    rows+=("$d"$'\t'"$t"$'\t'"/posts/$b.html"$'\t'"$s")
done
{
    printf -- '---\ntitle: SSGBerk Reference\nposts:\n'
    if [ "${#rows[@]}" -gt 0 ]; then
        printf '%s\n' "${rows[@]}" | LC_ALL=C sort -r | while IFS=$'\t' read -r d t h s; do
            printf '  - title: %s\n    href: %s\n    date: %s\n    summary: %s\n' "$t" "$h" "$d" "$s"
        done
    fi
    printf -- '---\n'
} > index.md
