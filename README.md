# azure-infra-bicep


### 🔹 Step 1: Generate the SSH key pair

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/iac_vm_key -C "iac-deployment" -N ""
```

* Generates a 4096-bit RSA key pair
* Saves:

  * Private key → `~/.ssh/iac_vm_key`
  * Public key → `~/.ssh/iac_vm_key.pub`

---

### 🔹 Step 2: Store both keys in your Key Vault (`CODADEV`)

**Store Private Key:**

```bash
az keyvault secret set \
  --vault-name CODADEV \
  --name sshPrivateKey \
  --file ~/.ssh/iac_vm_key
```

**Store Public Key:**

```bash
az keyvault secret set \
  --vault-name CODADEV \
  --name sshPublicKey \
  --file ~/.ssh/iac_vm_key.pub
```

---

### 🔹 Step 3: Verify the secrets

```bash
az keyvault secret list --vault-name CODADEV -o table
```

Expected output:

```
Name
----------------
sshPrivateKey
sshPublicKey
```

---

### 🔹 Step 4 (Optional): Retrieve for use in automation

```bash
# Get public key (for VM creation)
az keyvault secret show --vault-name CODADEV --name sshPublicKey --query value -o tsv

# Get private key (for secure connections or pipelines)
az keyvault secret show --vault-name CODADEV --name sshPrivateKey --query value -o tsv
```

---

### ✅ Summary

| Purpose         | Key Vault Secret Name | File Source             | Description                              |
| --------------- | --------------------- | ----------------------- | ---------------------------------------- |
| SSH Private Key | `sshPrivateKey`       | `~/.ssh/iac_vm_key`     | Used for secure SSH authentication       |
| SSH Public Key  | `sshPublicKey`        | `~/.ssh/iac_vm_key.pub` | Shared with Azure VM or automation tools |

---

### after that remove from local server
jenkinsadmin@Jenkins-BuildServer:~$ rm -f ~/.ssh/iac_vm_key ~/.ssh/iac_vm_key.pub
jenkinsadmin@Jenkins-BuildServer:~$ ls ~/.ssh/iac_vm_key*
-----------------------------------------------------------------
⚙️ Jenkins Pipeline (for SSH access later)

In Jenkins, fetch private key only when connecting, not during deployment:

PRIVATE_KEY=$(az keyvault secret show --vault-name CODADEV --name sshPrivateKey --query value -o tsv)
echo "$PRIVATE_KEY" > /tmp/id_rsa
chmod 600 /tmp/id_rsa
ssh -i /tmp/id_rsa azureuser@<vm_private_ip>
----------------------------------------------------------------------------------------