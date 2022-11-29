#! This script is provides AS-IS Without any warranty !#

#! Credit for original script
#! https://community.ui.com/questions/Lets-Encrypt-Certificate-Renewal-Script-for-UDMPRO-Script-Works-for-Guest-Portal-and-Controller-Log/1bf24c11-952d-4714-8e9a-1ae4f63fe231

#? Unifi Controller
CONTROLLER_IP="192.168.99.1"
CONTROLLER_SSH_USERNAME="root" #? default: root
CONTROLLER_SSH_PORT="22" #? default: 22

#! DONT EDIT BEYOND THIS POINT !#
CONTROLLER_PATH_CERTIFICATE="/mnt/data/unifi-os/unifi-core/config"
CONTROLLER_PATH_KEYSTORE="/mnt/data/unifi-os/unifi/data"
CONTROLLER_KEYSTORE="${CONTROLLER_PATH_KEYSTORE}/keystore"
CONTROLLER_KEYSTORE_PASSWORD="aircontrolenterprise"

#? Input Certificates
CERTIFICATE_IN_PATH="./input"
CERTIFICATE_IN_ROOT="${CERTIFICATE_IN_PATH}/root.crt"
CERTIFICATE_IN_INTERMEDIATE="${CERTIFICATE_IN_PATH}/intermediate.crt"
CERTIFICATE_IN_MAIN="${CERTIFICATE_IN_PATH}/main.crt"
CERTIFICATE_IN_KEY="${CERTIFICATE_IN_PATH}/private.key"


#? Output Certificates
CERTIFICATE_OUT_PATH="./output"
CERTIFICATE_OUT_COMBINED="${CERTIFICATE_OUT_PATH}/unifi-core.crt"
CERTIFICATE_OUT_COMBINED_WITH_KEY="${CERTIFICATE_OUT_PATH}/unifi-core-with-key.crt"
CERTIFICATE_OUT_KEY="${CERTIFICATE_OUT_PATH}/unifi-core.key"
CERTIFICATE_OUT_P12="${CERTIFICATE_OUT_PATH}/unifi.p12"
CERTIFICATE_OUT_KEYSTORE="${CERTIFICATE_OUT_PATH}/keystore"

echo "If you dont have SSH login setup you will need to enter the root password many times"

echo
echo "########## Cleaning Output Directory [0/4] ##########"
echo "rm -r ${CERTIFICATE_OUT_PATH}/*"
rm -r ${CERTIFICATE_OUT_PATH}/*

echo
echo "########## Downloading keystore from Server [1/4] ##########"
scp\
  -i ~/.ssh/id_rsa\
  -o HostKeyAlgorithms=+ssh-rsa\
  -o PubkeyAcceptedKeyTypes=+ssh-rsa\
  -O\
  ${CONTROLLER_SSH_USERNAME}@${CONTROLLER_IP}:${CONTROLLER_KEYSTORE}\
  ${CERTIFICATE_OUT_PATH}


echo
echo "########## CREATING CERTIFICATES [2/4] ##########"

echo "[1/5] Creating UniFi Certificate"
cat ${CERTIFICATE_IN_MAIN} ${CERTIFICATE_IN_INTERMEDIATE} ${CERTIFICATE_IN_ROOT} > ${CERTIFICATE_OUT_COMBINED}
sed -i '' '$a\' ${CERTIFICATE_OUT_COMBINED}
cat ${CERTIFICATE_IN_KEY} ${CERTIFICATE_IN_MAIN} ${CERTIFICATE_IN_INTERMEDIATE} ${CERTIFICATE_IN_ROOT} > ${CERTIFICATE_OUT_COMBINED_WITH_KEY}
sed -i '' '$a\' ${CERTIFICATE_OUT_COMBINED_WITH_KEY}


echo "[2/5] Creating UniFi Key"
cp ${CERTIFICATE_IN_KEY} ${CERTIFICATE_OUT_KEY}

echo "[3/5] Converting Certificate to P12 Format"
openssl pkcs12 -export\
  -in ${CERTIFICATE_OUT_COMBINED_WITH_KEY}\
  -inkey ${CERTIFICATE_OUT_KEY}\
  -out ${CERTIFICATE_OUT_P12}\
  -name unifi\
  -caname root\
  -passout pass:${CONTROLLER_KEYSTORE_PASSWORD}

echo "[4/5] Upgrading JKS to PKCS12 Keystore (This is optional, but why is ubiquiti still using JKS??)"
keytool -importkeystore\
  -srckeystore ${CERTIFICATE_OUT_KEYSTORE}\
  -srcstorepass ${CONTROLLER_KEYSTORE_PASSWORD}\
  -destkeystore ${CERTIFICATE_OUT_KEYSTORE}\
  -deststorepass ${CONTROLLER_KEYSTORE_PASSWORD}\
  -deststoretype pkcs12 2>/dev/null

echo "[5/5] Importing Certificates Into keystore File"
keytool \
  -noprompt\
  -importkeystore\
  -deststorepass ${CONTROLLER_KEYSTORE_PASSWORD}\
  -destkeypass ${CONTROLLER_KEYSTORE_PASSWORD}\
  -destkeystore ${CERTIFICATE_OUT_KEYSTORE}\
  -srckeystore ${CERTIFICATE_OUT_P12}\
  -srcstoretype PKCS12\
  -srcstorepass ${CONTROLLER_KEYSTORE_PASSWORD}\
  -alias unifi 2>/dev/null

echo
echo "########## MOVING CERTIFICATES [3/4] ##########"

echo "[1/3] Copying ${CERTIFICATE_OUT_COMBINED}"
scp\
  -i ~/.ssh/id_rsa\
  -o HostKeyAlgorithms=+ssh-rsa\
  -o PubkeyAcceptedKeyTypes=+ssh-rsa\
  -O\
  ${CERTIFICATE_OUT_COMBINED}\
  ${CONTROLLER_SSH_USERNAME}@${CONTROLLER_IP}:${CONTROLLER_PATH_CERTIFICATE}

echo "[2/3] Copying ${CERTIFICATE_OUT_KEY}"
scp\
  -i ~/.ssh/id_rsa\
  -o HostKeyAlgorithms=+ssh-rsa\
  -o PubkeyAcceptedKeyTypes=+ssh-rsa\
  -O\
  ${CERTIFICATE_OUT_KEY}\
  ${CONTROLLER_SSH_USERNAME}@${CONTROLLER_IP}:${CONTROLLER_PATH_CERTIFICATE}

echo "[3/3] Copying ${CERTIFICATE_OUT_KEYSTORE}"
scp\
  -i ~/.ssh/id_rsa\
  -o HostKeyAlgorithms=+ssh-rsa\
  -o PubkeyAcceptedKeyTypes=+ssh-rsa\
  -O\
  ${CERTIFICATE_OUT_KEYSTORE}\
  ${CONTROLLER_SSH_USERNAME}@${CONTROLLER_IP}:${CONTROLLER_PATH_KEYSTORE}

echo
echo "########## RESTARTING SERVER [4/4] ##########"
ssh\
  -i ~/.ssh/id_rsa\
  -o HostKeyAlgorithms=+ssh-rsa\
  -o PubkeyAcceptedKeyTypes=+ssh-rsa\
  ${CONTROLLER_SSH_USERNAME}@${CONTROLLER_IP} "reboot; exit;"

echo
echo "✨Finished✨"
echo " ⚠️  Go check your controller and your guest portal. Make sure you set your guest portal hostname to the SERVER_FQDN you used in this script.  ⚠️ "
