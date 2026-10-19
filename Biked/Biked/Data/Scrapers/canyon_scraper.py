import sys
import os
import re
from bs4 import BeautifulSoup

# Add parent dir to path to import base_scraper
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from Scrapers.base_scraper import BrandScraper

class CanyonScraper(BrandScraper):
    def __init__(self, supabase_client=None):
        super().__init__("Canyon", "https://www.canyon.com/en-es/road-bikes/", supabase_client)

    def parse_catalog(self):
        html = self.fetch_page(self.base_url)
        if not html: return []
        
        soup = BeautifulSoup(html, 'html.parser')
        # Canyon products usually have a specific ID pattern in the URL
        links = soup.find_all('a', href=re.compile(r'/road-bikes/'))
        urls = []
        for l in links:
            href = l['href']
            # Only pick links that look like specific bike models
            if re.search(r'/\d+/', href) or '.html' in href:
                if not href.startswith('http'):
                    href = f"https://www.canyon.com{href}"
                urls.append(href)
        return list(set(urls))

    def parse_bike_details(self, url):
        # 1. Get the PID and the Geometry Include page
        match = re.search(r'/(\d+)\.html', url)
        pid = match.group(1) if match else None
        
        if not pid:
            main_html = self.fetch_page(url)
            if main_html:
                soup = BeautifulSoup(main_html, 'html.parser')
                pid_tag = soup.find('div', {'data-pid': True})
                pid = pid_tag['data-pid'] if pid_tag else None
        
        if not pid: return None
        
        # Use ES and RoW for best compatibility with Spanish labels
        api_url = f"https://www.canyon.com/on/demandware.store/Sites-RoW-Site/es_ES/Product-IncludeGeometry?pid={pid}"
        geo_html = self.fetch_page(api_url)
        if not geo_html: return None
        
        soup = BeautifulSoup(geo_html, 'html.parser')
        geometry = []
        
        # Parse sizes
        size_buttons = soup.find_all('button', class_='geometryTable__sizeButton')
        size_labels = [btn.text.strip() for btn in size_buttons if btn.text.strip()]
        # De-duplicate while preserving order
        size_labels = list(dict.fromkeys(size_labels))
        
        rows = soup.find_all('tr', class_='geometryTable__dataRow')
        stacks = []
        reaches = []
        
        for row in rows:
            title = row.find(class_='geometryTable__title')
            if not title: continue
            title_text = title.text.strip().lower()
            
            cells = row.find_all(class_='geometryTable__sizeData')
            values = [re.sub(r'[^\d.]', '', c.text.strip().replace(',', '.')) for c in cells]
            
            if 'stack' in title_text:
                stacks = [float(v) for v in values if v]
            elif 'reach' in title_text:
                reaches = [float(v) for v in values if v]
        
        if stacks and reaches and size_labels:
            for i in range(min(len(stacks), len(reaches), len(size_labels))):
                geometry.append({
                    "size": size_labels[i],
                    "stack": stacks[i],
                    "reach": reaches[i]
                })

        # Get name/image from main page
        main_html = self.fetch_page(url)
        image_url = None
        model_name = url.split('/')[-2].replace('-', ' ').title()
        
        if main_html:
            main_soup = BeautifulSoup(main_html, 'html.parser')
            img_tag = main_soup.find('meta', property='og:image')
            if img_tag: image_url = img_tag['content']
            
            if not image_url:
                img_tag = main_soup.find('img', class_='product-image__image')
                if img_tag and img_tag.get('src'): image_url = img_tag['src']

        return {
            "brand": "Canyon",
            "model": model_name,
            "year": 2024,
            "category": "ROAD",
            "image_url": image_url,
            "geometry": geometry,
            "url": url
        }

        return {
            "brand": "Canyon",
            "model": model_name,
            "year": 2024,
            "category": "ROAD",
            "image_url": image_url,
            "geometry": geometry,
            "url": url
        }

if __name__ == "__main__":
    scraper = CanyonScraper()
    print("Fetching Canyon catalog...")
    catalog = scraper.parse_catalog()
    print(f"Found {len(catalog)} bike models.")
    if catalog:
        print(f"Parsing first model: {catalog[0]}")
        details = scraper.parse_bike_details(catalog[0])
        print(details)
