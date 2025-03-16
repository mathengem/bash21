#! /bin/bash

###############################################
################# FUNCTIONS ###################
###############################################

calculate_checksum(){
        prefix=$1
        value=$2
        suffix=$3
        s1=$(echo -n "${prefix}${value}${suffix}" | xxd -r -p | openssl sha256 | awk '{print $2}')
        s2=$(echo -n ${s1} | xxd -r -p | openssl sha256 | awk '{print $2}')
        checksum=$(echo ${s2} | head -c 8)
        echo ${checksum}
}

hash_160(){
        input=$1
        sha=$(echo -n ${input} | xxd -r -p | openssl sha256 | awk '{print $2}')
        echo -n ${sha} | xxd -r -p | openssl ripemd160 | awk '{print $2}'
}

generate_p2pkh(){
        hash160=$1
        checksum=$(calculate_checksum "00" ${hash160} "")
        echo -n "00${hash160}${checksum}" | xxd -r -p | base58
}

generate_p2sh(){
        input=$1
        hash160=$(hash_160 "0014${input}")
        checksum=$(calculate_checksum "05" ${hash160} "")
        echo -n "05${hash160}${checksum}" | xxd -r -p | base58
}

print_keys(){
        echo "Entropy: $1"
        echo "PK: $2"
        echo "WIF: $3"
        echo "Public Key: $4"
        echo "Compressed Public Key: $5"
        echo "HASH160: $6"
        echo "Legacy Address: $7"
        echo "Segwit Address: $8"
}

encrypt_keys(){
        print_keys $1 $2 $3 $4 $5 $6 $7 $8 | gpg -c -o keys.gpg
}

print_qr_codes(){
        qrencode -s 6 -l M -o legacy_address.png $1
        qrencode -s 6 -l M -o segwit_address.png $2
        qrencode -s 6 -l M -o wif.png $3
}

print_addresses(){
        echo "Legacy Address: $1"
        echo "Segwit Address: $2"
}

create_addresses_file(){
        print_addresses $1 $2 > addresses.txt
}

###############################################
################# MAIN ########################
###############################################

# CONVERT ENTROPY TO WIF KEY

entropy=$(cat /dev/urandom | tr -dc '[:graph:]' | fold -w 64 | head -n 1)

pk=$(echo -n ${entropy} | openssl sha256 | awk '{print $2}')

checksum=$(calculate_checksum "80" ${pk} "01")

wif=$(echo -n "80${pk}01${checksum}" | xxd -r -p | base58)

# CONVERT PRIVATE KEY TO COMPRESSED PUBLIC KEY USING OPENSSL SECP256K1

public_key=$(openssl ec -inform DER -text -noout -in <(cat <(echo -n "302e0201010420") <(echo -n ${pk}) <(echo -n "a00706052b8104000a") | xxd -r -p) 2>/dev/null | tail -6 | head -5 | sed 's/[ :]//g' | tr -d '\n' && echo)

x_coord=$(printf ${public_key} | cut -c -66 | cut -c 3-)
last_byte=$(printf ${public_key} | cut -c 129-)
last_int=$(printf "%d" 0x${last_byte})
is_odd=$(expr ${last_int} % 2)
if [ "$is_odd" == 1 ]; then
    compressed_public_key=03${x_coord}
else
    compressed_public_key=02${x_coord}
fi

# CONVERTING PUBLIC KEY TO COMPRESSED LEGACY ADDRESS

hash160=$(hash_160 ${compressed_public_key})

legacy_address=$(generate_p2pkh ${hash160})

segwit_address=$(generate_p2sh ${hash160})

# PRINT DATA

encrypt_keys ${entropy} ${pk} ${wif} ${public_key} ${compressed_public_key} ${hash160} ${legacy_address} ${segwit_address}

print_qr_codes ${legacy_address} ${segwit_address} ${wif}

create_addresses_file ${legacy_address} ${segwit_address}

convert -background white -gravity center legacy_address.png -resize 400x400 \
    -bordercolor white -border 10x10 -size 512x40 -background white -fill black -gravity center \
    -pointsize 16 label:"${legacy_address}" -append wif.png -resize 400x400 -bordercolor white \
    -border 10x10 -size 512x40 -background white -fill black -gravity center -pointsize 14 \
    label:"${wif}" -append output.png

convert output.png -page A4 -gravity center -trim +repage -bordercolor white -border 10x10 wallet.pdf

rm output.png