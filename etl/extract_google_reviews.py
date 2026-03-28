"""
extract_google_reviews.py
Ekstrak Google Reviews via Google Places API dan simpan ke data/raw/
"""

import requests
import pandas as pd
import os
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("GOOGLE_PLACES_API_KEY", "")
PLACE_ID = os.getenv("GOOGLE_PLACE_ID", "")

OUTPUT_DIR = "data/raw"


def fetch_reviews(place_id: str, api_key: str) -> list:
    url = "https://maps.googleapis.com/maps/api/place/details/json"
    params = {
        "place_id": place_id,
        "fields": "name,rating,reviews",
        "key": api_key,
    }
    response = requests.get(url, params=params)
    response.raise_for_status()
    result = response.json().get("result", {})
    return result.get("reviews", [])


def extract_google_reviews():
    if not API_KEY or not PLACE_ID:
        print("GOOGLE_PLACES_API_KEY atau GOOGLE_PLACE_ID belum dikonfigurasi di .env")
        return

    reviews = fetch_reviews(PLACE_ID, API_KEY)
    rows = [
        {
            "author": r.get("author_name"),
            "rating": r.get("rating"),
            "text": r.get("text"),
            "time": r.get("time"),
        }
        for r in reviews
    ]
    df = pd.DataFrame(rows)
    df.to_csv(f"{OUTPUT_DIR}/google_reviews.csv", index=False)
    print(f"Extracted {len(df)} reviews.")
    return df


if __name__ == "__main__":
    extract_google_reviews()
