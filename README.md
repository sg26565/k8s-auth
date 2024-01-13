# Create client certificates for Kubernetes

Kubernetes has no internal representation of users or groups. Instead, it uses client certificates that were signed by a trusted authority and derived user name and group membership from the subject of the certificate.

e.g. /CN=jdoe/O=foo/O=bar

The above subject identifies a user named *jdoe* who is a member of the *foo* and *bar* groups. These can be used in Role Bindings or Cluster Role Bindings to assign Roles or Cluster Roles to the user or groups.

The Kubernetes API server comes with an internal CA that is able to sign such certificates. It also comes with some default signers that automate the process. See https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/ for details.

## The script performs the following actions:

1. Create a private key and certificate signing requests with the subject derived for the arguments using openssl.
2. Create a new CertificateSigningRequest object in the cluster using the base64 encoded CSR.  
   The standard *kubernetes.io/kube-apiserver-client* signer will be used for this. This signer requires manual approval by a cluster admin before it signs the request and it does not allow users to be a member of the *system:masters* group.
3. Approve the CertificateSigningRequest
4. Wait for the *kubernetes.io/kube-apiserver-client* signer to sign the request and download the signed certificate.
5. Use the signed certificate to create a new user in the kube-config file (~/.kube/config by default).  
   Afterwards, the new user can be used in *kubectl* commands.
   ```
   > kubectl --user=jdoe auth whoami
   ATTRIBUTE   VALUE
   Username    jdoe
   Groups      [bar foo system:authenticated]
   ```
6. Cleanup temporary files and objects.
7. Use the new user and show its identity and whether is can list pods.

## Sample Uasge

```
> ./gen-csr.sh jdoe foo bar
...+.....+...+.........................+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*...+......+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*..+......+...+.......+.........+...+.....+.+.....+.+.....+.+.....+......................+......+.....+....+..+..................+.+............+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
.....+.........+..........+...+.......................+....+.....+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*...+.+......+.................+...+.......+..+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*......+......+...........+...+...+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-----
certificatesigningrequest.certificates.k8s.io/jdoe created
certificatesigningrequest.certificates.k8s.io/jdoe approved
certificatesigningrequest.certificates.k8s.io/jdoe condition met
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            eb:5e:89:0b:67:a3:6a:b2:ba:07:ba:99:67:98:64:cc
        Signature Algorithm: ecdsa-with-SHA256
        Issuer: CN = k3s-client-ca@1661711066
        Validity
            Not Before: Jan 13 10:49:04 2024 GMT
            Not After : Jan 12 10:49:04 2025 GMT
        Subject: O = bar + O = foo, CN = jdoe
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:b7:43:ea:f4:b2:24:6e:b4:ad:5d:f0:89:84:5c:
                    9e:c8:96:f0:f2:95:1d:4e:f2:90:38:14:ad:07:25:
                    3c:be:25:df:56:d1:70:83:48:1a:0b:6f:77:7a:7e:
                    37:6f:ae:d4:a1:af:24:12:25:43:be:b1:2d:9b:b6:
                    aa:9c:d1:8d:8f:1c:00:db:ef:20:27:dd:6f:95:76:
                    0b:6b:b8:e2:ea:a4:df:2b:89:2b:ca:85:1d:a4:9a:
                    f9:25:ab:0b:3b:49:27:79:d9:54:82:62:a3:97:02:
                    b0:06:88:6c:b7:f6:9c:90:9b:5d:2d:ac:d1:8c:4e:
                    67:02:24:2d:1c:79:ee:90:d1:87:de:3a:3c:34:9c:
                    14:90:9c:34:35:c0:37:63:38:b0:1e:f4:09:52:d9:
                    13:4d:1c:15:17:26:fe:ae:d6:a2:8f:df:14:1c:6c:
                    7f:00:b8:f6:b5:a5:01:fc:fc:35:5c:cc:be:0e:18:
                    e3:1a:f3:cd:b3:a8:b9:db:fa:85:fa:49:b5:8e:4f:
                    55:3c:91:aa:c5:e8:3f:00:05:af:d4:a9:01:b2:7e:
                    42:b2:52:ba:26:87:6f:4a:f3:da:56:1e:41:75:a1:
                    6d:1b:4e:e9:19:35:1f:4b:cb:be:54:28:3f:d7:8f:
                    97:f1:3e:2a:54:ca:e9:93:53:06:f5:d2:e8:c6:13:
                    48:df
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Extended Key Usage: 
                TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier: 
                6E:3E:56:FB:99:80:60:6A:A4:03:12:F4:4A:9B:BB:58:F0:6B:AA:B5
    Signature Algorithm: ecdsa-with-SHA256
    Signature Value:
        30:46:02:21:00:eb:08:05:4b:d6:d8:c4:74:fc:04:81:88:c3:
        39:e9:ff:4d:f1:81:e9:c4:ac:99:91:5f:5c:64:bd:28:8e:69:
        c7:02:21:00:d8:01:25:b8:e8:8b:30:2b:5b:89:35:2d:ab:ae:
        9d:7a:14:92:30:01:75:d2:87:e4:06:30:3e:82:67:1d:94:9c
User "jdoe" set.
certificatesigningrequest.certificates.k8s.io "jdoe" deleted

Who am I?
ATTRIBUTE   VALUE
Username    jdoe
Groups      [bar foo system:authenticated]

Can I list pods? no
```

The user is a member of the *foo*, *bar* and *system:authenticated* groups. As no role bindings grant any permissions to this user or any of his groups, he is not allowed to list pods.
