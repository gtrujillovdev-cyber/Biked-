import sys
import os
import json
import time

# Add Scrapers to path
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), "Scrapers"))

from base_scraper import BrandScraper

# CONFIGURATION
SUPABASE_CONFIG = {
    "url": "https://tvzfyptiouihtitlapcv.supabase.co",
    "key": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR2emZ5cHRpb3VpaHRpdGxhcGN2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM2OTI3NTAsImV4cCI6MjA4OTI2ODc1MH0.f-WZVWNaXYOcyIHm8XrI8ZXFzeAhGm1Oyl2-k_Dv79g"
}

JSON_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Resources", "bikes.json")

def seed():
    if not os.path.exists(JSON_PATH):
        print(f"Error: JSON file not found at {JSON_PATH}")
        return

    with open(JSON_PATH, 'r') as f:
        bikes = json.load(f)

    print(f"Found {len(bikes)} bikes in JSON. Starting seed...")

    # We'll group bikes by brand to reuse scrapers
    brands = {}
    for bike in bikes:
        brand = bike['brand']
        if brand not in brands:
            brands[brand] = BrandScraper(brand, "", SUPABASE_CONFIG)
        
        # Prepare bike_data for sync_to_supabase
        # Mapping JSON fields to scraper format
        geometry = []
        for g in bike.get('geometry', []):
            geometry.append({
                "size": g.get('sizeLabel', 'N/A'),
                "stack": g.get('stack', 0),
                "reach": g.get('reach', 0)
            })
        
        # Handle Image (Prioritize Local)
        image_url = None
        if bike.get('builds') and bike['builds'][0].get('images'):
            original_url = bike['builds'][0]['images'][0]
            filename = os.path.basename(original_url)
            local_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Resources", "BikeImages", filename)
            
            if os.path.exists(local_path):
                image_url = local_path
            else:
                image_url = original_url

        formatted_bike = {
            "model": bike['model'],
            "year": bike.get('year', 2024),
            "category": bike.get('category', 'ROAD').upper(),
            "image_url": image_url,
            "geometry": geometry,
            "url": bike.get('official_url', '')
        }

        print(f"Processing: {formatted_bike['model']}")
        brands[brand].sync_to_supabase(formatted_bike)
        time.sleep(0.5)

if __name__ == "__main__":
    seed()
