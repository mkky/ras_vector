RAC="/opt/1cv8/x86_64/8.3.25.1445/rac"
PARAMS=("\"session\", \"list\""  "\"process\", \"list\"" "\"session\", \"list\", \"--licenses\"")
PASSWORD="1234"
USER="Администратор"

VECTOR_SOURCE_TEMPLATE="
  exec_rac_%{rac_type}_%{line_num}:
    type: exec
    framing:
      method: bytes
    mode: scheduled
    scheduled:
      exec_interval_secs: 15
    command: [\"${RAC}\", \"localhost:%{port1}\", %{param}, \"--cluster=%{cluster_id}\", \"--cluster-user=${USER}\", \"--cluster-pwd=${PASSWORD}\"]
"

line_num=0
join -j 1 \
<(cat ps_ras.txt | awk '{for (i = 1; i <= NF; i++) {if ($i ~ /--port/) {split($(i), b, "="); print substr(b[2], 1, 2), b[2]}}}' | sort -k1,1) \
<(cat ps_rmngr.txt | awk '{for (i = 1; i <= NF; i++) {if ($i ~ /-clstid/) {clstid=$(i+1)}}; for (j = 1; j <= NF; j++) {if ($j ~ /-port/) { print substr($(j+1), 1, 2), clstid}}}' | sort -k1,1) \
| while read -r line; do


    port1=$(echo "$line" | awk '{print $2}')
    cluster_id=$(echo "$line" | awk '{print $3}')

    for PARAM in "${PARAMS[@]}"; do
        rac_type=${PARAM//[ -,\"]/}

        line_num=$((line_num + 1))
        output=${VECTOR_SOURCE_TEMPLATE}
        output=$(echo "$output" | sed "s/%{line_num}/$line_num/g")
        output=$(echo "$output" | sed "s/%{port1}/$port1/g")
        output=$(echo "$output" | sed "s/%{cluster_id}/$cluster_id/g")
        output=$(echo "$output" | sed "s/%{param}/$PARAM/g")
        output=$(echo "$output" | sed "s/%{rac_type}/$rac_type/g")

        echo "$output"
    done
done
