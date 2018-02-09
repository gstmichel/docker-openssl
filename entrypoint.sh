if [ ! -f /ssl/ca/passphrase -o ! -f /ssl/ca/ca-key.pem -o ! -f /ssl/ca/ca.pem -o ! -f /ssl/ca/ca.crt ]
then
    echo "Delivering Certification Authority Public/Private key"
    rm -rf /ssl/ca/*
    mkdir -p /ssl/ca

    openssl rand -base64 48 > /ssl/ca/passphrase
    openssl genrsa -aes256 -out /ssl/ca/ca-key.pem -passout file:/ssl/ca/passphrase 4096
    openssl req -new -x509 -days 365 -key /ssl/ca/ca-key.pem -sha256 -out /ssl/ca/ca.pem -passin file:/ssl/ca/passphrase -subj "/C=${CA_C-CA}/ST=${CA_ST}/L=${CA_L}/O=${CA_O}/OU=${CA_OU}/CN=${HOSTNAME}"
    openssl x509 -outform der -in /ssl/ca/ca.pem -out /ssl/ca/ca.crt
fi

if [ "$SERVER" != "" ] && [ ! -f /ssl/$SERVER/server-key.pem  -o ! -f /ssl/$SERVER/server-cert.pem ]
then
    echo "Delivering Public/Private Certificates for ${SERVER}"
    rm -rf /ssl/$SERVER/*
    mkdir -p /ssl/$SERVER

    openssl genrsa -out /ssl/$SERVER/server-key.pem 4096
    openssl req -subj "/CN=$SERVER" -sha256 -new -key /ssl/$SERVER/server-key.pem -out /ssl/$SERVER/server.csr

    if [ "$SERVER_ALIAS" == "" ]
    then
        echo subjectAltName = DNS:$SERVER > /ssl/$SERVER/extfile.cnf

    else
        for i in $(echo $SERVER_ALIAS | sed "s/,/ /g")
        do
            alias=${alias},DNS:$i
        done

        echo subjectAltName = DNS:$SERVER$alias > /ssl/$SERVER/extfile.cnf
    fi

    echo extendedKeyUsage = serverAuth >> /ssl/$SERVER/extfile.cnf

    openssl x509 -req -days 365 -sha256 -in /ssl/$SERVER/server.csr -CA /ssl/ca/ca.pem -CAkey /ssl/ca/ca-key.pem -passin file:/ssl/ca/passphrase -CAcreateserial -out /ssl/$SERVER/server-cert.pem -extfile /ssl/$SERVER/extfile.cnf
    rm -f /ssl/$SERVER/*.csr
fi
