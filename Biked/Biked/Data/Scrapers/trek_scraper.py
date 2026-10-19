import sys
import os
import re
import requests
from bs4 import BeautifulSoup

# Add parent dir to path to import base_scraper
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from Scrapers.base_scraper import BrandScraper

class TrekScraper(BrandScraper):
    def __init__(self, supabase_client=None):
        super().__init__("Trek", "https://www.trekbikes.com/es/es_ES/bicicletas/bicicletas-de-carretera/c/B200/", supabase_client)

    def parse_catalog(self):
        # Sitemaps are now blocked/empty. Scrape the road bike category page directly.
        html = self.fetch_page(self.base_url)
        if not html: return []
        
        soup = BeautifulSoup(html, 'html.parser')
        # Trek category pages use <a> with class 'cover-link'
        links = []
        for a in soup.find_all('a', class_='cover-link', href=True):
            href = a['href']
            if '/p/' in href:
                # Ensure it's an absolute URL
                if href.startswith('/'):
                    href = "https://www.trekbikes.com" + href
                links.append(href)
        
        # Deduplicate
        return list(set(links))

    def parse_bike_details(self, url):
        # Extract product ID
        match = re.search(r'/p/(\d+)', url)
        if not match: return None
        pid = match.group(1)
        
        # Trek Internal Sizing API
        # Example: https://api.trekbikes.com/occ/v2/es/products/49944/sizing?lang=es_ES&curr=EUR
        api_url = f"https://api.trekbikes.com/occ/v2/es/products/{pid}/sizing"
        params = {"lang": "es_ES", "curr": "EUR"}
        
        try:
            res = requests.get(api_url, params=params, headers=self.headers, timeout=10)
            if res.status_code != 200:
                print(f"Trek API error for {pid}: Status {res.status_code}")
                return None
            
            data = res.json()
            headers = data.get('geometryDataHeaders', [])
            geo_rows = data.get('geometryData', [])
            
            # Find indices for Stack and Reach
            # geometryFrameStack, geometryFrameReach
            stack_idx = -1
            reach_idx = -1
            size_idx = 0 # Usually the first column is the size name/value
            
            for i, h in enumerate(headers):
                if h == 'geometryFrameStack': stack_idx = i
                elif h == 'geometryFrameReach': reach_idx = i
                elif h == 'geometrySize': size_idx = i
                
            if stack_idx == -1 or reach_idx == -1:
                # Fallback indices based on browser research (Stack: 14, Reach: 13)
                stack_idx = 14
                reach_idx = 13
                
            geometry = []
            for row in geo_rows:
                if len(row) > max(stack_idx, reach_idx, size_idx):
                    try:
                        geometry.append({
                            "size": str(row[size_idx]),
                            "stack": float(row[stack_idx]) * 10, # cm to mm
                            "reach": float(row[reach_idx]) * 10  # cm to mm
                        })
                    except (ValueError, TypeError):
                        continue
            
            # Get Image and Model Name from page
            html = self.fetch_page(url)
            model_name = url.split('/')[-2].replace('-', ' ').title()
            image_url = None
            if html:
                soup = BeautifulSoup(html, 'html.parser')
                img_tag = soup.find('meta', property='og:image')
                if img_tag: image_url = img_tag['content']

            return {
                "brand": "Trek",
                "model": model_name,
                "year": 2024,
                "category": "ROAD",
                "image_url": image_url,
                "geometry": geometry,
                "url": url
            }
        except Exception as e:
            print(f"Error parsing Trek {pid}: {e}")
            return None

if __name__ == "__main__":
    scraper = TrekScraper()
    print("Fetching Trek catalog...")
    catalog = scraper.parse_catalog()
    print(f"Found {len(catalog)} bike models.")
    if catalog:
        print(f"Parsing first model: {catalog[0]}")
        details = scraper.parse_bike_details(catalog[0])
        print(details)
