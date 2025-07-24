import json
import logging
import random
import string
import os
import boto3 # type: ignore

# keep table name flexible
TABLE_NAME = os.getenv("TABLE_NAME", "WhiskersURL")

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)


def lambda_handler(event, context):
    # ------------------------------------------------------------------
    logging.warning("EVENT=%s", json.dumps(event))
    method = event["requestContext"]["http"]["method"]
    path = event["rawPath"].lstrip("/")      # ''  or 'AbC123'

    # Build the Function-URL base dynamically
    proto = event.get("headers", {}).get("x-forwarded-proto", "https")
    host = event.get("headers", {}).get("host")
    base_url = f"{proto}://{host}"
    # ------------------------------------------------------------------

    # === POST /  – create short link ==================================
    if method == "POST":
        body = json.loads(event.get("body", "{}"))
        long_url = body.get("url", "")
        if not long_url.startswith("http"):
            return _resp(400, {"error": "Invalid URL"})

        short_id = _gen_id()
        table.put_item(Item={"id": short_id, "long_url": long_url})
        return _resp(200, {"shortUrl": f"{base_url}/{short_id}"})

    # === GET /{id} – redirect =========================================
    if method == "GET" and path and path != "favicon.ico":
        item = table.get_item(Key={"id": path}).get("Item")
        if item:
            return {
                "statusCode": 302,
                "headers": {"Location": item["long_url"]},
                "body": ""
            }
        return _resp(404, {"error": "Not found"})

    # === fallback ======================================================
    return _resp(405, {"error": "Method not allowed"})


# ---------- helpers ---------------------------------------------------
def _resp(code, body):
    return {
        "statusCode": code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def _gen_id(n: int = 6) -> str:
    return "".join(random.choices(string.ascii_letters + string.digits, k=n))
