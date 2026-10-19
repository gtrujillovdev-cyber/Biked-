import sys
import os
import re
import requests
from bs4 import BeautifulSoup
import json
import time

# Add parent dir to path to import base_scraper
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from Scrapers.base_scraper import BrandScraper

class SpecializedScraper(BrandScraper):
    def __init__(self, supabase_client=None):
        super().__init__("Specialized", "https://www.specialized.com/es/es/shop/bikes/road-bikes/c/road", supabase_client)

    def parse_catalog(self):
        html = self.fetch_page(self.base_url)
        if not html: return []
        
        soup = BeautifulSoup(html, 'html.parser')
        # Specialized products usually have a /p/ in the URL
        links = soup.find_all('a', href=re.compile(r'/p/\d+'))
        urls = []
        for l in links:
            href = l['href']
            if not href.startswith('http'):
                # Handle relative links that might already start with /es/es/ or not
                if href.startswith('/'):
                    href = f"https://www.specialized.com{href}"
                else:
                    href = f"https://www.specialized.com/es/es/{href}"
            urls.append(href)
        return list(set(urls))

    def parse_bike_details(self, url):
        # Extract productNumber (e.g., 216960) from URL
        match = re.search(r'/p/(\d+)', url)
        product_number = match.group(1) if match else None
        if not product_number: return None
        
        html = self.fetch_page(url)
        if not html: return None
        
        # 1. Reconstruct Next.js App Router data
        pushes = re.findall(r'self\.__next_f\.push\(\[1,"(.*?)"\]\)', html)
        if not pushes:
            # Fallback for older Specialized pages or different regions
            pushes = re.findall(r'self\.__next_f\.push\(\[0,"(.*?)"\]\)', html)
            
        full_data = "".join(pushes).replace('\\"', '"').replace('\\\\', '\\')
        
        geometry = []
        sizes = []
        stacks = []
        reaches = []
        
        # 2. Extract Geometry from data
        # We look for the "SpecializedProductGeoValueRow" objects
        # Format: {"name":"Stack de cuadro",...,"value":["501mm",...]}
        
        # Find sizes (usually under "Talla" or similar, but often we can find a list of 2-digit numbers)
        # Better: find the "value" list that matches the length of stacks/reaches
        
        stack_match = re.search(r'\"name\":\"Stack [^"]+\",\"code\":\"[^"]+\",\"value\":(\[.*?\])', full_data, re.I)
        reach_match = re.search(r'\"name\":\"Reach [^"]+\",\"code\":\"[^"]+\",\"value\":(\[.*?\])', full_data, re.I)
        
        # More flexible fallback for stack/reach names
        if not stack_match:
            stack_match = re.search(r'\"name\":\"Stack\",\"code\":\"[^"]+\",\"value\":(\[.*?\])', full_data, re.I)
        if not reach_match:
            reach_match = re.search(r'\"name\":\"Reach\",\"code\":\"[^"]+\",\"value\":(\[.*?\])', full_data, re.I)
            
        if stack_match:
            val_str = stack_match.group(1)
            # Remove any non-numeric chars but keep decimal points
            stacks = []
            for v in json.loads(val_str):
                if v:
                    clean_v = re.sub(r'[^\d.]', '', v)
                    if clean_v: stacks.append(float(clean_v))
            
        if reach_match:
            val_str = reach_match.group(1)
            reaches = []
            for v in json.loads(val_str):
                if v:
                    clean_v = re.sub(r'[^\d.]', '', v)
                    if clean_v: reaches.append(float(clean_v))
            
        # For sizes, it's a bit trickier. Let's look for common size patterns if we have stacks
        if stacks:
            # Look for a list of strings of the same length as stacks
            # Often it's in a geo row called "Talla" or "Size"
            size_match = re.search(r'\"name\":\"(Talla|Size|Tamaño)\",\"code\":\"[^"]+\",\"value\":(\[.*?\])', full_data, re.I)
            if size_match:
                sizes = json.loads(size_match.group(2))
            else:
                # Fallback: find any row with the same length as stacks
                all_rows = re.findall(r'\"value\":(\[.*?\])', full_data)
                for row_str in all_rows:
                    row_vals = json.loads(row_str)
                    if len(row_vals) == len(stacks) and all(isinstance(v, str) and len(v) <= 4 for v in row_vals):
                        sizes = row_vals
                        break
        
        if sizes and stacks and reaches:
            for i in range(min(len(sizes), len(stacks), len(reaches))):
                geometry.append({
                    "size": sizes[i],
                    "stack": stacks[i],
                    "reach": reaches[i]
                })

        # 3. Get name/image
        model_name = url.split('/')[-3].replace('-', ' ').title()
        image_url = None
        img_match = re.search(r'\"og:image\",\"content\":\"(.*?)\"', full_data)
        if img_match:
            image_url = img_match.group(1).replace('\\/', '/')
        else:
            # Fallback to SOUP for image
            soup = BeautifulSoup(html, 'html.parser')
            img_tag = soup.find('meta', property='og:image')
            if img_tag: image_url = img_tag['content']

        return {
            "brand": "Specialized",
            "model": model_name,
            "year": 2024,
            "category": "ROAD",
            "image_url": image_url,
            "geometry": geometry,
            "url": url
        }

if __name__ == "__main__":
    scraper = SpecializedScraper()
    print("Fetching Specialized catalog...")
    catalog = scraper.parse_catalog()
    print(f"Found {len(catalog)} bike models.")
    if catalog:
        print(f"Parsing first model: {catalog[0]}")
        details = scraper.parse_bike_details(catalog[0])
        print(details)
