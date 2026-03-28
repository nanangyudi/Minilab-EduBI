"""
extract_google_reviews.py
Ekstrak Google Reviews via Google Places API.
Jika API key tidak dikonfigurasi, fallback ke file CSV sample.

Untuk PoC: gunakan sample_reviews.csv yang sudah ada.
Untuk produksi: set GOOGLE_PLACES_API_KEY dan GOOGLE_PLACE_ID di .env
"""

import os
import requests
import pandas as pd
from utils import get_logger

log = get_logger("extract_google_reviews")

OUTPUT_DIR = "data/raw"
SAMPLE_FILE = os.path.join(OUTPUT_DIR, "sample_reviews.csv")


def fetch_from_api(place_id: str, api_key: str) -> pd.DataFrame:
    """Ambil reviews dari Google Places API."""
    url = "https://maps.googleapis.com/maps/api/place/details/json"
    params = {
        "place_id": place_id,
        "fields": "name,rating,reviews",
        "key": api_key,
        "language": "id",
    }
    response = requests.get(url, params=params, timeout=10)
    response.raise_for_status()
    reviews = response.json().get("result", {}).get("reviews", [])

    rows = [
        {
            "review_id": f"R{str(i+1).zfill(3)}",
            "author":      r.get("author_name"),
            "rating":      r.get("rating"),
            "text":        r.get("text"),
            "review_date": pd.to_datetime(r.get("time"), unit="s").date(),
            "branch":      "Pusat",   # default; sesuaikan per lokasi
            "source":      "google",
        }
        for i, r in enumerate(reviews)
    ]
    return pd.DataFrame(rows)


def extract_reviews() -> pd.DataFrame:
    api_key  = os.getenv("GOOGLE_PLACES_API_KEY", "")
    place_id = os.getenv("GOOGLE_PLACE_ID", "")

    if api_key and place_id:
        log.info("Menggunakan Google Places API...")
        df = fetch_from_api(place_id, api_key)
        out = os.path.join(OUTPUT_DIR, "google_reviews.csv")
        df.to_csv(out, index=False)
        log.info(f"Extracted {len(df)} reviews → {out}")
    else:
        log.info("API key tidak dikonfigurasi. Menggunakan sample_reviews.csv sebagai fallback.")
        df = pd.read_csv(SAMPLE_FILE)
        log.info(f"Loaded {len(df)} reviews dari {SAMPLE_FILE}")

    return df


if __name__ == "__main__":
    extract_reviews()
