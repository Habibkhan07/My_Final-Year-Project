"""One-shot smoke test for the Gemini SDK (google-genai unified SDK).

Run with:  ./venv/bin/python scripts/gemini_smoke_test.py

Reads GEMINI_API_KEY from backend/.env via django-environ (same loader the
project uses). Makes ONE generate_content call, prints the result. No
project imports — keeps the check independent of Django boot.
"""
import sys
from pathlib import Path

import environ
from google import genai


def main() -> int:
    backend_dir = Path(__file__).resolve().parent.parent
    env = environ.Env()
    environ.Env.read_env(backend_dir / ".env")

    api_key = env("GEMINI_API_KEY", default="")
    if not api_key:
        print("FAIL: GEMINI_API_KEY missing from backend/.env")
        print("      Get a key at https://aistudio.google.com/apikey")
        return 1

    model_name = env("GEMINI_MODEL", default="gemini-2.5-flash")
    client = genai.Client(api_key=api_key)

    print(f"Calling {model_name} with a 1-token prompt...")
    try:
        resp = client.models.generate_content(
            model=model_name,
            contents="Reply with the single word: OK",
        )
    except Exception as exc:
        print(f"FAIL: SDK call raised {type(exc).__name__}: {exc}")
        return 2

    text = (resp.text or "").strip()
    print(f"Response: {text!r}")
    if "OK" in text.upper():
        print("PASS: Gemini SDK reachable and key works.")
        return 0
    print("WARN: SDK reachable but response unexpected. Inspect manually.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
