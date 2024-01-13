#! /bin/sh
#
# Create a client certificate that allows a user to authenticate with the Kubernetes cluster.
# The certificate will be signed by the cluster CA. User name and groups are derived from the subject of the certificate.
# e.g. /CN=jdoe/O=foo/O=bar identifies a user named "jdoe" who is a member of the "foo" and "bar" groups.
# This script has to be executed by a cluster adminb or more specifically, a user who has the permission to create,
# approve and delete CertificateSigningRequests in the cluster.

# first arg is the user name, remaining args are group names
# this will generate a subject of "/CN={username}/O={group1}/O={group2}..."
username=$1
shift
groups=$(for group in $@; do echo -n "/O=${group}"; done)

# generate a certificate signing request (private key has no passphrase due to -nodes)
openssl req -newkey rsa:2048 -keyout ${username}.key -out ${username}.csr -nodes -subj "/CN=${username}${groups}"

# create a new CertificateSigningRequest in the cluster with the base64 encoded csr and ask the kube-apiserver-client signer to sign it
# see https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/ for details
kubectl apply -f - <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest

metadata:
  name: ${username}

spec:
  signerName: kubernetes.io/kube-apiserver-client
  request: $(cat ${username}.csr | base64 -w0)
  usages:
    - client auth
EOF

# kube-apiserver-client signer requires manual approval
kubectl certificate approve ${username}

# wait for the signer to sign the request and download the signed cert
kubectl wait csr ${username} --for="condition=Approved" --for="jsonpath={.status.certificate}"
kubectl get csr ${username} -o jsonpath="{.status.certificate}" | base64 -d > ${username}.crt

# display the cert
openssl x509 -noout -text -in ${username}.crt

# add a user to ~/.kube/config using the new cert and key
kubectl config set-credentials ${username} --client-certificate=${username}.crt --client-key=${username}.key --embed-certs=true

# clean up
rm ${username}.csr ${username}.key ${username}.crt
kubectl delete csr ${username}

# use the new user for the current context
#kubectl config set-context --current --user=${username}

# show who i am
echo "\nWho am I?"
kubectl --user=${username} auth whoami
echo -n "\nCan I list pods? "
kubectl --user=${username} auth can-i get pods