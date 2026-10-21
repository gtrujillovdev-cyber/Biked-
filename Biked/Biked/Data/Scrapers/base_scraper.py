import requests
from bs4 import BeautifulSoup
import json
import os

class BrandScraper:
    def __init__(self, brand_name, base_url, supabase_client=None):
        self.brand_name = brand_name
        self.base_url = base_url
        self.supabase = supabase_client
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        }

    def fetch_page(self, url):
        try:
            response = requests.get(url, headers=self.headers, timeout=15)
            response.raise_for_status()
            return response.text
        except Exception as e:
            print(f"Error fetching {url}: {e}")
            return None

    def parse_catalog(self):
        """Must be implemented by child classes to return list of model URLs"""
        raise NotImplementedError

    def parse_bike_details(self, url):
        """Must be implemented by child classes to return Bike data structure"""
        raise NotImplementedError

    def upload_image_to_supabase(self, image_path, bucket="bike-images"):
        """Uploads an image (from URL or local path) to Supabase Storage"""
        if not image_path or not self.supabase:
            return None
            
        try:
            content = None
            content_type = 'image/jpeg'
            filename = os.path.basename(image_path).split('?')[0]

            # 1. Handle Remote URL vs Local Path
            if image_path.startswith('http'):
                print(f"Downloading image from {image_path}...")
                img_res = requests.get(image_path, headers=self.headers, timeout=10)
                img_res.raise_for_status()
                content = img_res.content
                content_type = img_res.headers.get('Content-Type', 'image/jpeg')
            elif os.path.exists(image_path):
                print(f"Reading local image from {image_path}...")
                with open(image_path, 'rb') as f:
                    content = f.read()
                # Simple extension check for content type
                if filename.lower().endswith('.png'): content_type = 'image/png'
                elif filename.lower().endswith('.webp'): content_type = 'image/webp'
            else:
                print(f"Error: Image source not found: {image_path}")
                return None
            
            # 2. Extract filename and prepare path
            if not filename.lower().endswith(('.png', '.jpg', '.jpeg', '.webp')):
                filename += ".jpg"
                
            # Slugify brand name for storage folder
            safe_brand = self.brand_name.lower().replace('é', 'e').replace('ó', 'o').replace(' ', '_')
            storage_path = f"{safe_brand}/{filename}"
            
            # 3. Upload to Supabase Storage
            storage_url = f"{self.supabase['url']}/storage/v1/object/{bucket}/{storage_path}"
            headers = {
                "Authorization": f"Bearer {self.supabase['key']}",
                "apikey": self.supabase['key'],
                "Content-Type": content_type
            }
            
            print(f"Uploading to Supabase Storage: {storage_path}")
            upload_res = requests.post(storage_url, headers=headers, data=content)
            
            if upload_res.status_code in [200, 201] or "already exists" in upload_res.text:
                # Return the public URL
                public_url = f"{self.supabase['url']}/storage/v1/object/public/{bucket}/{storage_path}"
                return public_url
            else:
                print(f"Upload failed: {upload_res.text}")
                return image_path if image_path.startswith('http') else None
                
        except Exception as e:
            print(f"Error handling image upload: {e}")
            return image_path if image_path.startswith('http') else None

    def sync_to_supabase(self, bike_data):
        if not self.supabase or not self.supabase.get('url') or not self.supabase.get('key'):
            print(f"Dry run: {bike_data['model']}")
            return
        
        url = self.supabase['url']
        key = self.supabase['key']
        headers = {
            "apikey": key,
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        }

        print(f"Syncing {bike_data['model']} to Supabase...")
        
        try:
            # 0. Handle Image Upload First
            if bike_data.get('image_url'):
                new_image_url = self.upload_image_to_supabase(bike_data['image_url'])
                bike_data['image_url'] = new_image_url

            # 1. Upsert Brand
            brand_res = requests.post(f"{url}/rest/v1/brands", 
                                    headers=headers, 
                                    json={"name": self.brand_name}, 
                                    params={"on_conflict": "name"})
            
            if brand_res.status_code in [200, 201] and brand_res.json():
                brand_id = brand_res.json()[0]['id']
            else:
                # Fallback fetch
                fetch_res = requests.get(f"{url}/rest/v1/brands", 
                                        headers=headers, 
                                        params={"name": f"eq.{self.brand_name}"})
                brand_data = fetch_res.json()
                if not brand_data:
                    print(f"Error: No se pudo resolver brand_id para {self.brand_name}")
                    return
                brand_id = brand_data[0]['id']

            # 2. Upsert Model
            model_payload = {
                "brand_id": brand_id,
                "name": bike_data['model'],
                "year": bike_data.get('year', 2024),
                "discipline": bike_data.get('category', 'ROAD'),
                "external_id": bike_data.get('url', '')
            }
            model_res = requests.post(f"{url}/rest/v1/models", 
                                    headers=headers, 
                                    json=model_payload,
                                    params={"on_conflict": "brand_id,name,year"})
            
            if model_res.status_code in [200, 201] and model_res.json():
                model_id = model_res.json()[0]['id']
            else:
                model_res_fetch = requests.get(f"{url}/rest/v1/models", 
                                              headers=headers, 
                                              params={
                                                  "brand_id": f"eq.{brand_id}",
                                                  "name": f"eq.{bike_data['model']}",
                                                  "year": f"eq.{model_payload['year']}"
                                              })
                model_data = model_res_fetch.json()
                if not model_data:
                    print(f"Error: No se pudo resolver model_id para {bike_data['model']}")
                    return
                model_id = model_data[0]['id']

            # 3. Geometries
            for geo in bike_data['geometry']:
                geo_payload = {
                    "model_id": model_id,
                    "size_label": str(geo['size']),
                    "stack_mm": geo['stack'],
                    "reach_mm": geo['reach']
                }
                requests.post(f"{url}/rest/v1/geometries", 
                             headers=headers, 
                             json=geo_payload,
                             params={"on_conflict": "model_id,size_label"})

            # 4. Builds (Basic build including image)
            if bike_data.get('image_url'):
                build_payload = {
                    "model_id": model_id,
                    "name": "Standard",
                    "image_url": bike_data['image_url'],
                    "is_verified": False
                }
                # Check if build already exists to avoid duplicates in builds table if re-running
                check_build = requests.get(f"{url}/rest/v1/builds", 
                                         headers=headers, 
                                         params={"model_id": f"eq.{model_id}", "name": "eq.Standard"})
                
                if not check_build.json():
                    requests.post(f"{url}/rest/v1/builds", headers=headers, json=build_payload)
                else:
                    # Update existing build image if it changed
                    build_id = check_build.json()[0]['id']
                    requests.patch(f"{url}/rest/v1/builds", 
                                 headers=headers, 
                                 json={"image_url": bike_data['image_url']},
                                 params={"id": f"eq.{build_id}"})
            
            print(f"Successfully synced {bike_data['model']}")
            
        except Exception as e:
            print(f"Error syncing {bike_data['model']}: {e}")
