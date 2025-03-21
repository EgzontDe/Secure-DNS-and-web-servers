# Secure DNS and web servers

## Description
Setting up a Linux server with a strong focus on security. We follow the latest recommended security measures to make sure the server is safe from attacks. Our goal is to have a secure and reliable server that works well and keeps data protected.

##

### 1. Serving a signed DNS zone

In order to serve a signed DNS zone we have installed the Knot DNS and configured with best practies in security

Commands used to install the KNOT and Configure the files

  - ``` sudo apt update```
  - ```sudo apt upgrade ```
  - ```sudo apt-get install Knot ```
  - domain zone configuration as follow:
  - ```cd etc/knot``` and edited the file knot.conf using ```sudo nano knot.conf'``` and added following configuration lines

zone:

```
    domain: five.secu23.fun
    storage: "/var/lib/knot/"
    file: five.secu23.fun.zone
```

   - Configuring the server to listen on port 53 by adding this line in our knot.conf file
   ```172.28.43.45@53```

After that we have configured our subdomain zone in knot as follows :

  - ```sudo nano five.secu23.fun.zone ```
  - added the following configuration as requested
   ``` 
$ORIGIN five.secu23.fun.
$TTL 3600
@       SOA    ns.five.secu23.fun. hostmaster.invalid. (
                2021102700 ; serial number
                600        ; refresh interval
                600        ; retry interval
                604800     ; expire limit
                60         ; minimum TTL
)

; Name server record
@       NS     ns.five.secu23.fun.

; A record for name server
ns      A      192.42.43.45

; A record for www
www    A    192.42.43.45
   
  ```
  - Saved this as new file under the name five.secu23.fun.zone
  - Reloaded the Knot service using ``` sudo systemctl reload knot.service ```
  - Checked the knot status using this command ``` sudo systemctl status knot.service ```
  - Checking ```journalctl -u knot.service``` for any possible errors


### 1.2  Signing the zone with DNSSEC

In this step, we have cryptographically signed the domain zone with DNSSEC in a way that allows anyone to check its authenticity.

### Tasks Involved to Sign the Zone:

- **Enabling automatic DNSSEC signing**
   - In Knot DNS, enabling automatic signing can be achieved by:
   - Executing the command```sudo keymgr five.secu23.fun ds```
   - key tag: An identifier of the key ranging from 0 to 65535. 
   - Algorithm type: algorithm 13 corresponds to ECDSA using a P-256 curve with SHA-256.
   - Digest type: Represents the hash function used to generate the digest from the public key.
A long string which is the digest or hash of the public key.
   
- The output after excecuting the command.
  
```
five.secu23.fun. DS 43035 13 1 c5526946d413aff7675acd89ad6c104d6fe2f014
five.secu23.fun. DS 43035 13 2 829e11e1230d5792eed34be87b0c86d79abab6190d6ce08fec1e924ce9082250
five.secu23.fun. DS 43035 13 4 942e93f7de0d9912adca28e4545ef43153144fa799a9ae702c81225fcd8b07317dc3eeb2d261475ea0f816ef3b03227c
```
 - Then we we have modified again the knot.conf by using this command :``` sudo nano knot.conf ``` and saved ctl+O

     ```yaml
     zone:
     - domain: yourdomain.secu23.fun
       dnssec-signing: on
     ```
- **Reloading the knot** using the command:
   ```bash
   sudo systemctl reload knot.service
- **Checking the Status of Knot dns**

    ```bash
   sudo systemctl status knot.service

### 2. Secure web server
##### 2.1
- **Adding an A record for www**
- **Navigating to Knot Configuration Directory**:
   ```sh
   cd /etc/knot/
  
- Inserted the following configuration in the zone section
 
```
zone:
  ; A record for www
www    A    192.42.43.45
 ```
Saved the changes in the nano editor by pressing CTRL + O followed by Enter, then exit using CTRL + X.

- Reloading the Knot Services ```sudo systemctl reload knot.service```
- verifying the status and ensuring there are no errors ```sudo systemctl status knot.service```
- > <span style="color:red">**Note:** It's essential to avoid setting an A record on the domain apex. we have configured it only for `www`.</span>



##### 2.2 Installing and configuring the Web Server.


Before installing new packages, it's always a good practice to update the package index.

```
 sudo apt update
```
- Installing the Apache web server, use the following command:
```
 sudo apt install apache2
```
- Trying to Adjust Firewall (but it was inactive) to allow HTTP and HTTPS traffic.
- We have checked the listening ports 80 and 443 by using this command ```netstat -tuln | grep -E ':80|:443'```
- Setting up a virtual hosts for our subdomain by **Navigating to Apache2 Configuration Directory**:
   ```sh
   cd /etc/apache2/
  
```
  sudo nano /etc/apache2/sites-available/www.five.secu23.fun.conf
```
and added Following configuration:

```
<VirtualHost *:80>
    ServerName five.secu23.fun
    Redirect permanent / https://www.five.secu23.fun/
</VirtualHost>

<VirtualHost *:443>
    ServerName www.five.secu23.fun
    DocumentRoot /var/www/html/five.secu23.fun

    # Security Headers
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set Content-Security-Policy "default-src 'self';"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set Referrer-Policy "no-referrer"
    Header always set Permissions-Policy "geolocation=(self), microphone=()"

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

Include /etc/letsencrypt/options-ssl-apache.conf
SSLCertificateFile /etc/letsencrypt/live/www.five.secu23.fun/fullchain.pem
SSLCertificateKeyFile /etc/letsencrypt/live/www.five.secu23.fun/privkey.pem
</VirtualHost>
```
The Configuration file above was edited multiple times in order to activate the SSL after we have installed but this is a complete Virtual Host configuration and we have implemented up the redirection from HTTP>HTTPS, also the Security Headers as required
- Details of Security Headers are in the end of documentation
- After Completed the virtual host configuration file we did the following : 
- Enabling the new virtual host configuration by using this command
```sudo a2ensite www.five.secu23.fun.conf ```
- Reloading Apache to apply the changes by using this command :  
- ``` sudo systemctl reload apache2```
- Checking the Syntax by using the following command : ``` journalctl -u apache2.service ```

### Installing SSL Certificate Using Certbot for Apache
- Installing Certbot by using following commands:
- ``` sudo apt-get update ```
- ```sudo apt-get install certbot python-certbot-apache ```
- Obtaining a staging (test) certificate for our domain www.five.secu23.fun by using following command:
- ```sudo certbot --apache -d www.five.secu23.fun --staging```
- Reloading Apache ``` sudo systemctl reload apache2``` Waiting for our domain to be updated, and checking the certificate by using ```Certbot Certificates```
- After making sure that everything is working well in our side we switched from Staging mode to a Real one certificate by renewing the certificate 
- Obtaining a real certificate for our domain:
``` sudo certbot --apache -d www.five.secu23.fun ``` and redirecting all HTTP requests to HTTPS
### Mozilla Intermediate compatibility 
**SSL Protocols and Ciphers**:
    Edited Apache configuration file (included within a VirtualHost block).
    
```
    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA
    SSLHonorCipherOrder off
    SSLSessionTickets off
```
- Restart Apache 

    After making the changes, we have checked the configuration syntax:
    ```bash
    sudo apachectl configtest
    ```

    Then restart Apache:

    ```bash
    sudo systemctl restart apache2
    ```

### 3. Installing and Testing with `testssl.sh`

- Installation:

#### **Cloning the Git Repository**:

```
git clone --depth 1 https://github.com/drwetter/testssl.sh.git
cd testssl.sh
```
- Checking our website for SSL/TLS vulnerabilities by using the following command : 
```  
./testssl.sh www.five.secu23.fun
```
### RESULTS: Overall Grade                A+




## Security Headers Overview


#### 1. Strict-Transport-Security (HSTS)

- **Configuration**: 
    ```
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    ```
- **Description**: 
    The STS ensures that the browser only connects to the website using HTTPS for a specified amount of time. In this case, it's set for one year (`31536000` seconds) and includes subdomains (`includeSubDomains`).

#### 2. Content-Security-Policy (CSP)

- **Configuration**: 
    ```
    Header always set Content-Security-Policy "default-src 'self';"
    ```
- **Description**: 
   CSP Restricts the sources from which the content can be loaded,By adding this the content can only be loaded from the web itself

#### 3. X-Frame-Options

- **Configuration**: 
    ```
    Header always set X-Frame-Options "SAMEORIGIN"
    ```
- **Description**: 
    This  Header helps Protecting  against ClickJacking,this ensures that the content can only be framed by pages from the same origin.

#### 4. X-Content-Type-Options

- **Configuration**: 
    ```
    Header always set X-Content-Type-Options "nosniff"
    ```
- **Description**: 
    This header prevents the browser from doing sniffing, This means that the browser should trust the `Content-Type` header and not taking into account  different types.

#### 5. Referrer-Policy

- **Configuration**: 
    ```
    Header always set Referrer-Policy "no-referrer"
    ```
- **Description**:
    This one Controls the amount of referrer information that should included with requests.`no-referrer` means that the Referer header will be avoided entirely when navigating.

#### 6. Permissions-Policy

- **Configuration**: 
    ```
    Header always set Permissions-Policy "geolocation=(self), microphone=()"
    ```
- **Description**: 
    This one indicates that geolocation can only be used by the site itself (`self`), and microphone access is disabled.

These headers are very important to enhance the security of a web application by providing built-in protection against various types of web attacks.


