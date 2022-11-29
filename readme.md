# **UniFi Certificate installer By Anthony Veaudry**

This script is provides **AS-IS** Without any warranty

This script is designed to Installs Certificates on a UniFi UDM-PRO

## **Prerequisites**

1) You have access to the server via SSH
2) You already have your certificates generated for your domain name
3) Required dependencies (ssh, scp)

## **How To Use**

0. Make script executable
```chmod u+x update-certs.sh```

1. Place you certificate in the input directory, They need to be named exactly:
root.crt
intermediate.crt
main.crt
private.key

2. Edit the script to reflect your consoles ip

3. run the script in the terminal
```foo@bar:~$ sh update-certs.sh```

4. Check that everyting is working.

## What is each file

### **root.crt**

This is the root certificate for example `GTS ROOT R1` OR `ISRG ROOT X1`

### **intermediate.crt**

This is the intermediate certificate for example `GTS CA 1C3` OR `R3`

### **main.crt**

This is the main certificate for example `*.google.com` OR `lencr.org`

### **private.key**

This is your private key that was used during the CSR to create the main certificate
