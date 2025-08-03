# ShortURLTerraformV2

An end‑to‑end, infrastructure‑as‑code template that deploys a **serverless URL shortener** on AWS using Terraform.  It marries a low‑latency static front‑end with a scalable Lambda + DynamoDB back‑end, wrapped in CloudFront for global reach and SSL by default.

---

## 🗺️ High‑Level Architecture

```mermaid
flowchart TD
    subgraph EdgeLayer["AWS Edge (Global)"]
        CF[CloudFront Distribution]
    end

    subgraph StaticHosting["Static Site"]
        S3[(S3 Bucket – public read blocked, OAI access)]
    end

    subgraph Backend["API & Storage"]
        LF[Lambda Function (Python)]
        DB[(DynamoDB Table: WhiskersURL)]
    end

    subgraph Monitoring["Observability"]
        CW[CloudWatch Alarms]
        SNS[(SNS Topic – optional)]
    end

    User((Client Browser)) -->|HTTPS| CF
    CF -->|Assets| S3
    CF -- Redirect requests --> LF
    LF -- Read/Write --> DB
    LF -- Logs & Metrics --> CW
    CW -- Notify --> SNS
```

**Key flows**

* **Static content** (`index.html`, PNG logo) is served from the S3 bucket via CloudFront for low‑latency global delivery.
* **Short URL hits** reach the same CloudFront distribution; path‑based routing forwards them to the Lambda Function URL, which looks up the destination in DynamoDB and responds with an HTTP 301.
* **Observability** is handled with CloudWatch metrics and alarms (e.g., Lambda errors, 5XX rates) that can fan out alerts to an optional SNS topic.

> *GitHub renders Mermaid diagrams automatically. They respect the viewer’s dark/light theme.*

---

## Repository Layout (TL;DR)

```text
.
├── main.tf              # root orchestrator
├── variables.tf         # global knobs (region, tags, etc.)
├── outputs.tf           # exported values (CF domain, ARNs, …)
├── modules/             # reusable building blocks
│   ├── dynamoDB/
│   ├── lambda/
│   └── static_site_cf/
├── S3/                  # CloudFormation template + website assets
├── lambda_func/         # Python handler source
├── scripts/             # helper shell scripts (deploy & cleanup)
└── monitoring.tf        # CloudWatch alarms
```

---

## Prerequisites

* Terraform >= 1.3
* AWS CLI configured with credentials that can create IAM roles, Lambda, S3, CloudFront, and DynamoDB
* A registered domain in Route 53 *(optional – for a custom vanity host)*

---

## Quick Start

```bash
# 1) Initialise providers & modules
terraform init

# 2) See what will be created
terraform plan -out tfplan

# 3) Launch the stack
terraform apply tfplan

# 4) Upload/Invalidate assets (runs automatically via null_resource, but you can force):
./scripts/deploy_assets.sh
```

After \~10 minutes, Terraform exports the CloudFront URL. Browse to it and shorten your first link:

```bash
curl -i "https://<cloudfront-domain>/abc123"
```

---

## Clean Up

```bash
terraform destroy
```

The destroy phase empties the S3 bucket versions first (via `scripts/empty_bucket.sh`) to avoid the classic *"bucket not empty"* error.

---

## Cost Footprint (us‑east‑1, 1 M hits/month)

| Component                 | Monthly Cost (USD) |
| ------------------------- | ------------------ |
| S3 Storage                | < 0.10             |
| CloudFront                | \~ 2.50            |
| Lambda (128 MB)           | \~ 0.20            |
| DynamoDB (1 WCUs, 1 RCUs) | < 0.25             |
| **Total**                 | **≈ 3 USD**        |

> Costs scale linearly with traffic; staying well within AWS Free Tier for small projects.

---

## Extending the Stack

* **Custom Domain + HTTPS**

  * Add a `aws_route53_record` for `@` and `www` → CloudFront domain.
  * Request an ACM certificate in us‑east‑1 (required by CloudFront) and attach it via the `static_site_cf` module.
* **CI/CD**

  * Replace `null_resource.upload_assets` with a GitHub Actions workflow that runs `aws s3 sync` + `aws cloudfront create-invalidation` on `main` branch pushes.
* **Analytics**

  * Stream CloudFront access logs to S3 and query with Athena.
* **Authentication**

  * Swap Lambda for an API Gateway + Cognito authorizer if you need per‑user quotas.

---

## Troubleshooting

| Symptom                       | Fix                                                                                                               |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `403 Forbidden` on assets     | Check that OAI is attached and S3 public access is blocked correctly. Re‑run `deploy_assets.sh` if paths changed. |
| `502/504` on short URL hits   | Verify Lambda URL endpoint is in the `origins` list of CloudFront and health checks pass.                         |
| Terraform destroy fails on S3 | Ensure **all** object versions are purged; the provided `empty_bucket.sh` handles versioned buckets.              |

---

## Acknowledgements

Made with 💻 Terraform, ☁️ AWS, and a healthy dose of curiosity.
