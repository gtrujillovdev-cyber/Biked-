import os
import sys

# Add current dir to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from Scrapers.canyon_scraper import CanyonScraper
from Scrapers.specialized_scraper import SpecializedScraper
from Scrapers.trek_scraper import TrekScraper

# CONFIGURATION (Should match SupabaseConfig.swift)
SUPABASE_CONFIG = {
    "url": "https://tvzfyptiouihtitlapcv.supabase.co",
    "key": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR2emZ5cHRpb3VpaHRpdGxhcGN2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM2OTI3NTAsImV4cCI6MjA4OTI2ODc1MH0.f-WZVWNaXYOcyIHm8XrI8ZXFzeAhGm1Oyl2-k_Dv79g"
}

def run():
    # Re-ordered: Specialized and Trek are more reliable currently
    scrapers = [
        SpecializedScraper(SUPABASE_CONFIG),
        TrekScraper(SUPABASE_CONFIG),
        CanyonScraper(SUPABASE_CONFIG)
    ]
    
    import time
    
    for scraper in scrapers:
        print(f"\n--- Running {scraper.brand_name} Scraper ---")
        try:
            catalog = scraper.parse_catalog()
            print(f"Found {len(catalog)} models.")
            
            for model_url in catalog: 
                try:
                    print(f"Processing model: {model_url}")
                    bike_data = scraper.parse_bike_details(model_url)
                    if bike_data and bike_data.get('geometry'):
                        scraper.sync_to_supabase(bike_data)
                        time.sleep(1) # Be nice to the server
                    else:
                        print(f"Skipping {model_url} (No geometry data found)")
                except Exception as e:
                    print(f"Error processing model {model_url}: {e}")
        except Exception as e:
            print(f"Error running {scraper.brand_name} scraper: {e}")

if __name__ == "__main__":
    run()
