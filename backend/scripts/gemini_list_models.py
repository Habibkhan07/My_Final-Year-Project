"""List models accessible to this API key, then try the cheapest Flash variants.

Diagnoses 'limit: 0' errors — if no model is reachable, the project itself
isn't provisioned (need to enable Generative Language API in Cloud Console
or use a different project).
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
        print("FAIL: GEMINI_API_KEY missing")
        return 1

    client = genai.Client(api_key=api_key)

    print("Listing available models for this key:")
    try:
        for m in client.models.list():
            if "generateContent" in (m.supported_actions or []):
                print(f"  - {m.name}")
    except Exception as exc:
        print(f"FAIL listing models: {type(exc).__name__}: {exc}")
        return 2

    candidates = [
        "gemini-2.5-flash",
        "gemini-2.5-flash-lite",
        "gemini-2.0-flash",
        "gemini-2.0-flash-lite",
        "gemini-1.5-flash",
        "gemini-1.5-flash-8b",
    ]
    print("\nTrying each candidate with a 1-token prompt:")
    for name in candidates:
        try:
            resp = client.models.generate_content(
                model=name,
                contents="Reply with the single word: OK",
            )
            text = (resp.text or "").strip()
            print(f"  {name:30s} ✓  ({text!r})")
        except Exception as exc:
            short = str(exc).split("\n")[0][:120]
            print(f"  {name:30s} ✗  {type(exc).__name__}: {short}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
