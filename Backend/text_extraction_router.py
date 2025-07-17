import os
import requests
import tempfile
import fitz

from typing import Optional
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from fastapi.responses import PlainTextResponse
from bs4 import BeautifulSoup
from striprtf.striprtf import rtf_to_text

router = APIRouter()

def extract_text_from_pdf(pdf_path):
    doc = fitz.open(pdf_path)
    text = "\n".join(page.get_text() for page in doc)  # type: ignore
    return text

def extract_text_from_rtf(file_path):
    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
        return rtf_to_text(f.read())

def extract_text_from_plaintext(file_path):
    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
        return f.read()

def extract_text_from_html(html):
    soup = BeautifulSoup(html, "lxml")
    for selector in [".abstract-content", ".abstract", "#abstract", "main", "article", ".main-content", ".article"]:
        el = soup.select_one(selector)
        if el and el.get_text(strip = True):
            return el.get_text(separator = "\n")

    return soup.get_text(separator = "\n")  # If none of the selectors are found, extract all text

@router.post("/extract-text/", response_class = PlainTextResponse)
async def extract_text(file: Optional[UploadFile] = File(None), url: Optional[str] = Form(None)):
    if file:
        filename = file.filename or ""
        suffix = os.path.splitext(filename)[1].lower()

        with tempfile.NamedTemporaryFile(delete = False, suffix = suffix) as tmp:
            file_bytes = await file.read()
            tmp.write(file_bytes)
            tmp_path = tmp.name

        print(f"[DEBUG] Temp file path: {tmp_path}, size: {os.path.getsize(tmp_path)} bytes")
        try:
            if suffix == ".pdf":
                text = extract_text_from_pdf(tmp_path)
            elif suffix == ".rtf":
                text = extract_text_from_rtf(tmp_path)
            elif suffix in [".txt", ".text"]:
                text = extract_text_from_plaintext(tmp_path)
            else:
                os.remove(tmp_path)
                raise HTTPException(status_code = 400, detail = "Unsupported file type. Please upload a PDF, RTF, or TXT file.")
            print(f"Extraction result (first 200 chars): {text[:200] if text else text}")
        except Exception as e:
            text = f"Extraction error: {e}"
        finally:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)
        return text

    elif url:
        print(f"Received URL: {url}")

        if url.startswith("file://"):
            return "Cannot fetch local files via URL."
        if not (url.startswith("http://") or url.startswith("https://")):
            return "Unsupported URL scheme. Only http(s) URLs are allowed."
        try:
            # During the usage of the 'requests' libary, it turns out we need to mimic a custom browser.
            headers = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"}
            resp = requests.get(url, headers = headers)
            content_type = resp.headers.get("Content-Type", "").lower()

            print(f"[DEBUG] URL content type: {content_type}, response size: {len(resp.content)} bytes")
            if "pdf" in content_type or url.lower().endswith(".pdf"):
                with tempfile.NamedTemporaryFile(delete = False, suffix = ".pdf") as tmp:
                    tmp.write(resp.content)
                    tmp_path = tmp.name
                    print(f"[DEBUG] Temp file path (URL): {tmp_path}, size: {os.path.getsize(tmp_path)} bytes")
                try:
                    text = extract_text_from_pdf(tmp_path)
                except Exception as e:
                    text = f"Extraction error: {e}"
                finally:
                    os.remove(tmp_path)
                    print(f"Extraction result (first 200 chars): {text[:200] if text else text}")
                return text
            else:
                text = extract_text_from_html(resp.text)
                print(f"Extraction result (first 200 chars): {text[:200] if text else text}")
                return text
        except Exception as e:
            return f"Extraction error: {e}"
    else:
        return "No file or URL provided."