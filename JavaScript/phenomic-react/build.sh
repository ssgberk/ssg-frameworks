#!/bin/bash
if [ -z "$(command -v jq)" ] || [ -z "$(command -v sponge)" ]; then
    printf "\n [ ERROR ] Command jq or sponge (moreutils) was not instaled sucessful. Restart script."
    kill $$
fi

if [ -z "${number_of_files}" ] ; then
    number_of_files=100
fi

if [ -z "${content_size}" ] ; then
    content_size=100
fi

if [ -z "${min_runs}" ] ; then
    min_runs=3
fi

if [ -z "${verbose_build}" ] ; then
    verbose_build=true
fi

framework_build_command=$(jq -r '.config[].build_command' "${PWD}"/benchmark_config.json)
framework_build_verbose=$(jq -r '.config[].build_verbose' "${PWD}"/benchmark_config.json)
metadata_layout=$(jq -r '.config[].metadata_layout' "${PWD}"/benchmark_config.json)
metadata_dateslug=$(jq -r '.config[].metadata_dateslug' "${PWD}"/benchmark_config.json)
content_type=$(jq -r '.content[].type' "${PWD}"/benchmark_config.json)
content_folder=$(jq -r '.content[].folder' "${PWD}"/benchmark_config.json)
content_extension=$(jq -r '.content[].extension' "${PWD}"/benchmark_config.json)


if [ -z "${framework_build_verbose}" ] ; then
    framework_build_verbose="${framework_build_command}"
fi

# delete post folder
delete_post()
{
  rm -R "${content_folder}"
  mkdir "${content_folder}"
  return 0
}
delete_post

# Create content
resolve_filename()
{
    iterator_arg=${1}
    filename=$(date +%F)
    filename+="-"
    filename+="${iterator_arg}"
    resolver_header "${filename}" "${iterator_arg}"
    return 0
}

resolver_header()
{
    title="${1}"
    iterator_arg="${2}"
    case "${content_type}" in
    "3minus") 
        header=$'---\n'
        if [ -n "${metadata_layout}" ] ; then
            header+=$(printf "%s\n" "${metadata_layout}")
        fi
        header+=$(printf "\n%s: %s\ntitle: \"%s\"\n" "${metadata_dateslug}" "$(date +%F)" "${title}")
        header+=$'\n---\n'
    ;;
    "2dot")
        header=""
        if [ -n "${metadata_layout}" ] ; then
            header+=$(printf ".. %s\n" "${metadata_layout}") 
        fi
        header+=$(printf "\n.. %s: %s\n.. title: %s\n\n" "${metadata_dateslug}" "$(date +%F)" "${title}")
    ;;
    "datajson")
        
        if [ "${iterator_arg}" == "${number_of_files}" ] ; then
            json_string+=$(printf "\"%s\": {\"page\": {\"title\": \"%s\" , \"date\": \"$(date)\"}}" "${title}" "${title}")
        else
            json_string+=$(printf "\"%s\": {\"page\": {\"title\": \"%s\" , \"date\": \"$(date)\"}}," "${title}" "${title}")
        fi
    ;;
    "external")
        json_string=$(printf "{\"pagetitle\":\"%s\", \"date\": \"%s\", \"header\":[/_shared/header.md], \"main\":[body.md, /_shared/posts.md], \"footer\":[/_shared/footer.md]}" "${title}" "$(date)")
        header=$'---\n'
        if [ -n "${metadata_layout}" ] ; then
            header+=$(printf "%s\n" "${metadata_layout}")
        fi
        header+=$(printf "%s: %s\ntitle: %s\n" "${metadata_dateslug}" "$(date +%F)" "${title}")
        header+=$'---\n'
    ;;
    "none"|*) header="" ;;
    esac
    return 0
}

generate_content()
{
    string="Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum euismod luctus massa. Pellentesque porta augue non varius semper. In vitae pulvinar dolor. Nunc erat sem, facilisis eu augue in, aliquam viverra magna. Quisque porttitor sodales diam, a vestibulum sem semper vel. Integer tempus quam eu ex egestas, sed auctor neque venenatis. Fusce mattis metus pellentesque iaculis euismod. Vestibulum a dictum lectus, a porta odio. Etiam sit amet lobortis lorem. Mauris iaculis ornare risus, at dictum nullam."
    case "${content_size}" in
    "[500]")
        for i in {1..1000} ; do
            content+="${string}"
        done
    ;;
    "[1000]")
        for i in {1..2000} ; do
            content+="${string}"
        done
    ;;
    "[5000]")
        for i in {1..10000} ; do
            content+="${string}"
        done
    ;;
    "[10000]")
        for i in {1..20000} ; do
            content+="${string}"
        done
    ;;
    *)
        content="${string}"
    ;;
    esac
    
    return 0
}
generate_content

#Run Data Creating
case "${content_type}" in
"3minus"|"2dot") 
    for i in $(seq -w 1 "${number_of_files}")
    do
        resolve_filename "${i}"
        data="${header}"
        data+="${content}"
        echo "${data}" | sponge "${content_folder}/${filename}.${content_extension}"
        if [ "${verbose_build}" == true ] ; then
            printf "\n%s/%s.%s" "${content_folder}" "${filename}" "${content_extension}"
            cat "${content_folder}/${filename}.${content_extension}"
        fi
    done
;;
"datajson")
    json_string="{"
    for i in $(seq -w 1 "${number_of_files}")
    do
        resolve_filename "${i}"
        data="${content}"
        echo "${data}" | sponge "${content_folder}/${filename}.${content_extension}"
    done
    json_string+="}"
    echo "${json_string}" | sponge "${content_folder}/_data.json"
    if [ "${verbose_build}" == true ] ; then
        printf "\n%s/_data.json" "${content_folder}"
        cat "${content_folder}/_data.json"
        printf "\n%s/%s.%s" "${content_folder}" "${filename}" "${content_extension}"
        cat "${content_folder}/${filename}.${content_extension}"
    fi
;;
"external")
    for i in $(seq -w 1 "${number_of_files}")
    do
        resolve_filename "${i}"
        mkdir "${content_folder}/${filename}"
        echo "${json_string}" | sponge "${content_folder}/${filename}/index.yml"
        data="${header}"
        data+="${content}"
        echo "${data}" | sponge "${content_folder}/${filename}/body.${content_extension}"
        if [ "${verbose_build}" == true ] ; then
            printf "\n%s/%s/index.yml" "${content_folder}" "${filename}"
            cat "${content_folder}/${filename}/index.yml"
            printf "\n%s/%s/body.%s" "${content_folder}" "${filename}" "${content_extension}"
            cat "${content_folder}/${filename}/body.${content_extension}"
        fi
    done
;;
"none"|*)
    data="${content}"
    echo "${data}" | sponge "${content_folder}/${filename}.${content_extension}"
    if [ "${verbose_build}" == true ] ; then
        printf "\n%s/%s.%s" "${content_folder}" "${filename}" "${content_extension}"
        cat "${content_folder}/${filename}.${content_extension}"
    fi
;;
esac

# run benchmark
if [ "${verbose_build}" == true ] ; then
    ls -sh "${content_folder}"
    echo "Number of File: ${number_of_files} with Content Size: ${content_size} and Min Runs: ${min_runs}"
    command="hyperfine --min-runs ${min_runs} --show-output '${framework_build_verbose}'"
    echo "${command}"
    eval "${command}"
else
    du -sh "${content_folder}"
    echo "Number of File: ${number_of_files} with Content Size: ${content_size} and Min Runs: ${min_runs}"
    command="hyperfine --min-runs ${min_runs} --show-output '${framework_build_command}'"
    eval "${command}"
fi

# delete content
delete_post
    fi
;;
esac

# run benchmark
if [ "${verbose_build}" == true ] ; then
    ls -sh "${content_folder}"
    echo "Number of File: ${number_of_files} with Content Size: ${content_size} and Min Runs: ${min_runs}"
    command="hyperfine --min-runs ${min_runs} --show-output '${framework_build_verbose}'"
    echo "${command}"
    eval "${command}"
else
    du -sh "${content_folder}"
    echo "Number of File: ${number_of_files} with Content Size: ${content_size} and Min Runs: ${min_runs}"
    command="hyperfine --min-runs ${min_runs} --show-output '${framework_build_command}'"
    eval "${command}"
fi

# delete content
delete_post
