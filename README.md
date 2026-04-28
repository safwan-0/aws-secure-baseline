# 🔐 Secure AWS Architecture — Infrastructure as Code

A production-grade, security-hardened AWS infrastructure built entirely with Terraform. Implements defense-in-depth across network, compute, database, storage, and identity layer .

📐 Architecture Overview
INTERNET
     │
     ▼
[Internet Gateway]
     │
┌────▼─────────────────────────┐
│         PUBLIC SUBNET         │
│   EC2 Web Server              │
│   ├── IAM Role (no keys)      │
│   ├── IMDSv2 enforced         │
│   ├── Encrypted root volume   │
│   └── HTTPS only (port 443)   │
└────┬─────────────────────────┘
     │                    │
     ▼                    ▼
┌─────────────┐    ┌──────────────┐
│PRIVATE SUBNET│    │   S3 BUCKET  │
│  RDS MySQL   │    │  Encrypted   │
│  Encrypted   │    │  Versioned   │
│  No public   │    │  IAM access  │
│  access      │    │  only        │
└─────────────┘    └──────────────┘
     │
     ▼
[VPC Flow Logs + CloudTrail]
All network traffic and API calls recorded
🛡️ Security Controls Implemented
Network Security
ControlImplementationWhyPrivate subnetsRDS lives in private subnetDatabase unreachable from internetSecurity group chainingRDS allows EC2 SG onlyEven VPC-internal traffic restrictedNo public IPsmap_public_ip_on_launch = falseResources not directly internet-exposedNAT GatewayOutbound only for private subnetPrivate resources can update, not be reachedHTTPS onlyPort 443 ingress onlyNo unencrypted traffic accepted
Identity & Access
ControlImplementationWhyNo hardcoded credentialsIAM roles onlyNo static keys to leak or rotateLeast privilegeExact S3 actions onlyNo s3:* wildcardsIMDSv2 enforcedhttp_tokens = requiredPrevents SSRF credential theftInstance profilesEC2 borrows role temporarilyCredentials expire automatically
Data Security
ControlImplementationWhyS3 encryptionAES-256 SSEData encrypted at restS3 versioningEnabledRansomware and accidental deletion protectionRDS encryptionstorage_encrypted = trueDatabase disk encryptedEC2 volume encryptionencrypted = trueServer disk encryptedPublic access blockedAll 4 S3 block settingsNo path to public exposure
Logging & Visibility
ControlImplementationWhyVPC Flow LogsAll traffic logged to CloudWatchNetwork forensics during incidentsCloudTrailMulti-region, all API callsWho did what, when, from whereLog file validationenable_log_file_validation = trueTamper detection on audit logs90-day retentionCloudTrail logs kept 90 daysSufficient for incident investigation

📁 Project Structure
secure-aws-architecture/
├── providers.tf        # AWS provider config, default tags
├── variables.tf        # Input variables with validation
├── terraform.tfvars    # Environment values
├── networking.tf       # VPC, subnets, IGW, NAT, route tables
├── security_groups.tf  # All firewall rules in one place
├── iam.tf              # Roles, policies, instance profiles
├── compute.tf          # EC2, AMI data source
├── database.tf         # RDS MySQL, subnet groups
├── storage.tf          # S3 bucket, encryption, lifecycle
├── logging.tf          # VPC flow logs, CloudTrail
└── outputs.tf          # Resource IDs and endpoints

🔒 Key Security Decisions
Why IAM Roles Instead of Access Keys
EC2 accesses S3 using an IAM role — not an access key ID and secret. Role credentials are temporary (expire every hour), automatically rotated by AWS, and never stored on the server. A leaked access key is permanent until manually revoked. A leaked role credential expires on its own.
Why RDS Uses Security Group Chaining
The RDS security group allows inbound traffic only from the EC2 security group — not from a CIDR range. This means even if an attacker gained access to another resource inside the VPC, they still cannot reach the database unless that resource has the EC2 security group explicitly attached.
Why IMDSv2 Is Enforced
The EC2 metadata service at 169.254.169.254 returns IAM role credentials to anyone who queries it from the instance. IMDSv2 requires a session token before credentials are returned — blocking Server Side Request Forgery (SSRF) attacks where an attacker tricks the server into fetching its own credentials on their behalf.
Why CloudTrail Has Log File Validation
Every CloudTrail log file is digitally signed. If an attacker who gained AWS access tried to delete or modify log files to cover their tracks, the signature breaks — proving tampering occurred. This makes logs usable as forensic evidence.

🚀 Deployment
Prerequisites

Terraform >= 1.6.0
AWS CLI configured (aws configure)
AWS account with appropriate permissions 

Deploy
```bash

# Clone the repo
git clone https://github.com/yourusername/secure-aws-architecture
cd secure-aws-architecture

# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy (RDS takes 5-10 minutes)
terraform apply
```
Destroy
```
terraform destroy
```
✅ Security Scan Results
This project was scanned with Checkov — an open source static analysis tool for Infrastructure as Code.
Passed checks: 23
Failed checks: 0

Skipped checks: 2 (cross-region replication — dev environment only)
To run the scan yourself:
```
bashpip3 install checkov --break-system-packages
checkov -d .
```
📊 Resources Created
✅ Security Scan Results
This project was scanned with Checkov — an open source static analysis tool for Infrastructure as Code.
Passed checks: 23
Failed checks: 0
Skipped checks: 2 (cross-region replication — dev environment only)
To run the scan yourself:
bashpip3 install checkov --break-system-packages
checkov -d .

📊 Resources Created
ResourceCountPurposeVPC1Private network boundarySubnets31 public, 2 privateInternet Gateway1Controlled internet accessNAT Gateway1Outbound-only for private subnetSecurity Groups2EC2 firewall, RDS firewallEC2 Instance1Web server (t2.micro)RDS MySQL1Application database (db.t3.micro)S3 Buckets2App storage + CloudTrail archiveIAM Roles3EC2, CloudTrail, VPC Flow LogsIAM Policies2Least privilege S3 accessCloudTrail1API activity loggingVPC Flow Logs1Network traffic logging

Screenshots 
VPC and Subnets
<img width="1648" height="778" alt="vpc" src="https://github.com/user-attachments/assets/3bd4187c-4177-4e4a-8deb-bb80318eaaee" />

EC2 Instance — IAM Role Attached
<img width="1618" height="711" alt="ec2" src="https://github.com/user-attachments/assets/9eb73f77-2802-4001-b38c-e2ac00df6b83" />

RDS — Publicly Accessible: No
<img width="1598" height="666" alt="rds" src="https://github.com/user-attachments/assets/19e983e4-1380-4532-8b65-2f90d1726026" />

S3 Bucket — Public Access Blocked
<img width="1634" height="517" alt="s3" src="https://github.com/user-attachments/assets/b5ba2a2f-1643-4b08-afc9-81b7b042a619" />

CloudTrail — Active and Logging 
<img width="1671" height="593" alt="trail" src="https://github.com/user-attachments/assets/2836345c-d714-4404-bc6e-62ecfa07ee3c" />


🧠 What I Learned

How defense-in-depth works across multiple AWS layers simultaneously
Why security group chaining is more precise than CIDR-based rules
How IMDSv2 prevents a real-world SSRF attack vector
How to enforce security policy at the Terraform variable level using validation blocks
How CloudTrail log file validation creates tamper-evident audit trails
The difference between SSE-S3 and SSE-KMS encryption and when to use each

👤 Author
Safwan Tahmid — Cloud Security Engineer
