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

# Use Python with pycryptodome for RIPEMD160 hashing
hash_160(){
        input=$1
        sha=$(echo -n ${input} | xxd -r -p | openssl sha256 | awk '{print $2}')
        echo -n ${sha} | python3 -c "
import sys
from Crypto.Hash import RIPEMD160

# Read the input from stdin
data = bytes.fromhex(sys.stdin.read().strip())
h = RIPEMD160.new(data)
print(h.hexdigest())
"
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

# PROMPT USER FOR SALT
read -sp "Enter your salt (1-128 words): " salt  # -s hides input for security
echo

# GENERATE ENTROPY (RANDOM) + COMBINE WITH SALT
entropy=$(cat /dev/urandom | tr -dc '[:graph:]' | fold -w 64 | head -n 1)
combined_input="${entropy}${salt}"

# DERIVE PRIVATE KEY FROM COMBINED ENTROPY + SALT
pk=$(echo -n "${combined_input}" | openssl sha256 | awk '{print $2}')

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

print_keys ${entropy} ${pk} ${wif} ${public_key} ${compressed_public_key} ${hash160} ${legacy_address} ${segwit_address}

print_qr_codes ${legacy_address} ${segwit_address} ${wif}

create_addresses_file ${legacy_address} ${segwit_address}

# Notify user to display images in Python
echo "QR codes generated. Use the following Python code to display them:"
echo "from IPython.display import Image, display"
echo "display(Image(filename='legacy_address.png'))"
echo "display(Image(filename='segwit_address.png'))"
echo "display(Image(filename='wif.png'))"
