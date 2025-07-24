# 🐾 WhiskersStack — Serverless URL Shortener (Terraform)



WhiskersStack is a **fully‑serverless URL‑shortening service** powered by AWS Lambda, DynamoDB, S3 and CloudFront.\
Every layer of the stack is declared in **Terraform**, so you can spin up a brand‑new environment (or tear it down) with a single command.

---

## ✨ Architecture at a Glance

| Layer        | Implementation                                                                       |
| ------------ | ------------------------------------------------------------------------------------ |
| **Frontend** | Static site (HTML + JS) served from a **private S3 bucket** via **CloudFront + OAC** |
| **API**      | Python 3.12 Lambda function exposed through a **Lambda Function URL** (no API GW)    |
| **Storage**  | DynamoDB table `id → long_url` in *on‑demand* `PAY_PER_REQUEST` mode                 |
| **IaC**      | Terraform 1.3+ with three reusable modules (`lambda`, `dynamoDB`, `static_site_cf`)  |

---

## 📂 Repository Layout

```text
ShortURLTerraform/
├─ S3/
│  └─ website/
│     ├─ WhiskersURL.tpl.html      # HTML template → rendered → WhiskersURL.html
│     └─ whiskersstack-logo.png    # brand asset
├─ lambda_func/
│  └─ lambda_function.py           # URL‑shortener handler
├─ modules/
│  ├─ dynamoDB/                    # DynamoDB table
│  ├─ lambda/                      # Lambda + Function URL (uses existing *LabRole*)
│  └─ static_site_cf/              # Runs the CloudFormation template for S3 + CF
├─ scripts/
│  ├─ deploy_assets.sh             # Uploads extra assets + invalidates CloudFront
│  └─ empty_bucket.sh              # Empties bucket (called at destroy‑time)
├─ main.tf                         # Root orchestration
├─ static_site_html.tf             # Render + upload WhiskersURL.html
└─ variables.tf
```

---

## 🛠 Prerequisites

- **Terraform ≥ 1.3**
- **AWS CLI** configured (profile or environment variables)
- An existing IAM role `` with:
  - `LabRole`
  - `dynamodb:PutItem` & `dynamodb:GetItem` on the URL table (module can attach if missing)
  - `s3:PutObject` & `s3:GetObject` on the site bucket (for the asset‑upload script)

---

## 🚀 Quick Start

```bash
# 1 – Initialise & deploy the entire stack
terraform init
terraform apply -auto-approve

# 2 – Upload extra static assets (logo, CSS, etc.)
./scripts/deploy_assets.sh \
  $(terraform output -raw module.static_site.bucket_name) \
  $(terraform output -raw module.static_site.cloudfront_distribution_id) \
  S3/website/whiskersstack-logo.png

# 3 – Open the site once CloudFront shows "Deployed"
open "https://$(terraform output -raw static_site_url)"
```

> **Note:** the first apply can take \~15 minutes while CloudFront provisions.

---

## 🔄 Update Workflow

| Change                                     | What to run                  | Notes                                                         |
| ------------------------------------------ | ---------------------------- | ------------------------------------------------------------- |
| **Lambda code**                            | `terraform apply`            | `archive_file` detects checksum → new function version.       |
| **HTML template** (`WhiskersURL.tpl.html`) | `terraform apply`            | Terraform re‑renders, uploads and auto‑invalidates CF.        |
| **Static assets** (logo, CSS, JS)          | `scripts/deploy_assets.sh …` | Pass bucket, distribution ID & file list; script invalidates. |

---

## 🧹 Tear‑Down

```bash
# 1 – Empty the bucket (avoids DELETE_FAILED on SiteBucket)
./scripts/empty_bucket.sh $(terraform output -raw module.static_site.bucket_name)

# 2 – Destroy all infrastructure
terraform destroy -auto-approve
```

---

## 🗺️ Roadmap & Ideas

- Custom domain + ACM certificate for CloudFront
- Link expiry via DynamoDB TTL
- Click‑tracking (increment counter per redirect)
- GitHub Action to run `terraform plan` + asset upload in CI

Pull requests welcome — let’s keep the whiskers sharp! 😸

