import os
import requests
from dotenv import load_dotenv
from fastapi import Request, HTTPException
from jose import jwt
from typing import cast

load_dotenv()

JWKS_URL = os.getenv("CLERK_JWKS_URL")
if not JWKS_URL:
    raise RuntimeError("CLERK_JWKS_URL is not set in the environment.")

AUDIENCE = os.getenv("CLERK_AUDIENCE")
if not AUDIENCE:
    print("[WARNING] CLERK_AUDIENCE is not set in the environment. Audience claim will not be checked.")

CLERK_ISSUER = JWKS_URL.split("/.well-known/")[0]  # Check the issuer

def get_jwks():
    response = requests.get(cast(str, JWKS_URL))
    response.raise_for_status()
    return response.json()["keys"]

def get_public_key(token):
    jwks = get_jwks()
    unverified_header = jwt.get_unverified_header(token)
    for key in jwks:
        if key["kid"] == unverified_header["kid"]:
            return key
    raise HTTPException(status_code = 401, detail = "Public key not found.")

def verify_clerk_jwt(request: Request):
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code = 401, detail = "Missing or invalid token.")

    token = auth_header.split(" ")[1]

    if "." in token:
        try:
            key = get_public_key(token)
            payload = jwt.decode(
                token,
                key,
                algorithms = ["RS256"],
                audience = AUDIENCE,
                issuer = CLERK_ISSUER,
                options = {"verify_aud": False} if not AUDIENCE else {}
            )
            return payload  # Contains user info (sub, email, etc.)
        except Exception as e:
            raise HTTPException(status_code = 401, detail = f"Token verification failed: {str(e)}")
    else:
        return {"sub": token, "user_id": token}  # Simple user ID authentication (for development)