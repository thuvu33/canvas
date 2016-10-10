source="";
intermediate="";
sink="";
channel="";
function parse_source()
{
        id=0;
        buf=0;
	while read line; do
	echo $line | grep "id=[0-9]*;type=0;size_buf=[0-9]*"
        if [ $? -eq 0 ] ;then
            id=$(echo $line | awk -F";" '{print $1}' | awk -F"=" '{print $2}')
            buf=$(echo $line | awk -F";" '{print $3}' | awk -F"=" '{print $2}')
            sed -e 's/source_id/source_'"${id}"'/g' -e 's/capa/'"${buf}"'/g' $2 >> $3
            source="${source} ${id}"
        fi
	done < $1
}

function parse_intermidiate()
{
        id=0;
        buf=0;
	while read line; do
	echo $line | grep "id=[0-9]*;type=1;size_buf=[0-9]*"
        if [ $? -eq 0 ] ;then
            id=$(echo $line | awk -F";" '{print $1}' | awk -F"=" '{print $2}')
            buf=$(echo $line | awk -F";" '{print $3}' | awk -F"=" '{print $2}')
            sed -e 's/intermediate_id/intermediate_'"${id}"'/g' -e 's/capa/'"${buf}"'/g' $2 >> $3
            intermediate="${intermediate} ${id}"
        fi
	done < $1
}

function parse_sink()
{
        id=0;
        buf=0;
	while read line; do
	echo $line | grep "id=[0-9]*;type=2;size_buf=[0-9]*"
        if [ $? -eq 0 ] ;then
            id=$(echo $line | awk -F";" '{print $1}' | awk -F"=" '{print $2}')
            buf=$(echo $line | awk -F";" '{print $3}' | awk -F"=" '{print $2}')
            sed -e 's/sink_id/sink_'"${id}"'/g' -e 's/capa/'"${buf}"'/g' $2 >> $3
            sink="${sink} ${id}"
        fi
	done < $1
}

function parse_channel()
{
        id=0;
        buf=0;
	while read line; do
	echo $line | grep "id=[0-9]*_[0-9]*;size_buf=[0-9]*;from=[0-9]*;to=[0-9]*"
        if [ $? -eq 0 ] ;then
            from=$(echo $line | awk -F";" '{print $3}' | awk -F"=" '{print $2}')
            to=$(echo $line | awk -F";" '{print $4}' | awk -F"=" '{print $2}')
            buf=$(echo $line | awk -F";" '{print $2}' | awk -F"=" '{print $2}')
            sed -e 's/channel_id/channel_'"${from}"'_'"${to}"'/g' -e 's/capa/'"${buf}"'/g' $2 >> $3
            sink="${sink} ${from}_${to}"
        fi
	done < $1

}

function parse_main()
{
    echo "MODULE main" >> $1
    echo "" >> $1
    echo "VAR" >> $1
    for ss in ${source}
    do
        echo "    source_${ss} : process source_${ss}(output_${ss});" >> $1
        echo "    output_${ss} : output;" >> $1
        echo "" >> $1
    done

    for si in ${sink}
    do
        echo "    sink_${si} : process sink_${si}(input_${si});" >> $1
        echo "    input_${si} : input;" >> $1
        echo "" >> $1
    done

    for inter in ${intermediate}
    do
        echo "    intermediate_${inter} : process intermediate_${inter}(input_${inter}, output_${inter});" >> $1
        echo "    input_${inter} : input;" >> $1
        echo "    output_${inter} : output;" >> $1
        echo "" >> $1
    done

   for ch in ${channel}
   do
       from=$(echo ${ch} | awk -F"_" '{print $1}')
       to=$(echo ${ch} | awk -F"_" '{print $2}')
       echo "    channel_${from}_${to} : process channel_${from}_${to} (output_${from}, input_${to});" >> $1
       echo "" >> $1
   done
}
cat default.txt > output.txt
parse_source "input.txt" "source.txt" "output.txt"
parse_sink "input.txt" "sink.txt" "output.txt"
parse_intermidiate "input.txt" "intermediate.txt" "output.txt"
parse_channel "input.txt" "channel.txt" "output.txt"
parse_main "output.txt"
