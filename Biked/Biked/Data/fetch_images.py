import json
import requests
import time
from pathlib import Path

# File paths
BASE_DIR = Path(__file__).resolve().parent
JSON_FILE = BASE_DIR / "bikes.json"

def search_wikimedia(query, limit=3):
    """Searches Wikimedia Commons for images."""
    url = "https://commons.wikimedia.org/w/api.php"
    params = {
        "action": "query",
        "generator": "search",
        "gsrnamespace": "6", # File namespace
        "gsrsearch": query,
        "gsrlimit": limit,
        "prop": "imageinfo",
        "iiprop": "url",
        "format": "json"
    }
    
    headers = {
        "User-Agent": "BikeGeometryFinder/1.0 (https://github.com/gtrujillovdev-cyber/Biked; gabriel@example.com)"
    }
    
    try:
        response = requests.get(url, params=params, headers=headers, timeout=10)
        
        if response.status_code != 200:
             print(f"Error: HTTP {response.status_code}")
             return []
             
        data = response.json()
        
        image_urls = []
        if "query" in data and "pages" in data["query"]:
            for page_id, page_data in data["query"]["pages"].items():
                if "imageinfo" in page_data:
                    image_url = page_data["imageinfo"][0]["url"]
                    # Filter for typical image extensions to avoid PDFs, etc.
                    if image_url.lower().endswith(('.jpg', '.jpeg', '.png', '.webp')):
                        image_urls.append(image_url)
        
        return image_urls
    except Exception as e:
        print(f"Error searching for {query}: {e}")
        return []

def update_bikes_with_images():
    if not JSON_FILE.exists():
        print("bikes.json not found!")
        return

    with open(JSON_FILE, "r") as f:
        bikes = json.load(f)
    
    updated_count = 0
    
    for bike in bikes:
        brand = bike.get("brand", "")
        model = bike.get("model", "")
        full_name = f"{brand} {model}"
        
        print(f"Searching images for: {full_name}...")
        
        # Search for the bike model
        # Improving query for better matches
        images = search_wikimedia(f"{brand} {model}", limit=5)
        
        if not images:
             # Fallback: simpler query
             print(f"  No exact match, trying simpler query: {model}")
             images = search_wikimedia(model, limit=5)
             
        if not images:
            # Fallback: Just brand
             print(f"  No match, trying brand: {brand} bike")
             images = search_wikimedia(f"{brand} bicycle", limit=5)

        if images:
            print(f"  Found {len(images)} images.")
            
            # Update each build with these images (rotating them if we have enough)
            for i, build in enumerate(bike.get("builds", [])):
                # Assign up to 3 images to each build, effectively using what we found
                # If we have multiple builds, we might want to vary them, but for now reuse
                build["images"] = images[:3] 
            
            updated_count += 1
        else:
            print(f"  No images found for {full_name}.")

    # Save updated JSON
    with open(JSON_FILE, "w") as f:
        json.dump(bikes, f, indent=4)
    
    print(f"\nUpdated {updated_count} bikes with new images.")

if __name__ == "__main__":
    update_bikes_with_images()
