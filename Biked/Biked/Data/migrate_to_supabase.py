import json
import requests

# CONFIGURATION
SUPABASE_URL = "https://tvzfyptiouihtitlapcv.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR2emZ5cHRpb3VpaHRpdGxhcGN2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM2OTI3NTAsImV4cCI6MjA4OTI2ODc1MH0.f-WZVWNaXYOcyIHm8XrI8ZXFzeAhGm1Oyl2-k_Dv79g"
JSON_PATH = "../Resources/bikes.json"

HEADERS = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

def migrate():
    with open(JSON_PATH, 'r') as f:
        bikes = json.load(f)
        
    for bike in bikes:
        print(f"Migrating {bike['brand']} {bike['model']}...")
        
        # 1. Upsert Brand
        brand_data = {"name": bike['brand']}
        res = requests.post(f"{SUPABASE_URL}/rest/v1/brands", 
                          headers=HEADERS, 
                          json=brand_data, 
                          params={"on_conflict": "name"})
        
        # If return=representation doesn't return anything (e.g. no change), 
        # we fetch it to get the ID.
        if res.status_code == 201 or (res.status_code == 200 and res.json()):
            brand_id = res.json()[0]['id']
        else:
            # Fallback fetch
            res = requests.get(f"{SUPABASE_URL}/rest/v1/brands", 
                             headers=HEADERS, 
                             params={"name": f"eq.{bike['brand']}"})
            brand_id = res.json()[0]['id']
        
        # 2. Upsert Model
        model_data = {
            "brand_id": brand_id,
            "name": bike['model'],
            "year": bike['year'],
            "discipline": "ROAD" if bike['category'] == "CARRETERA" else "TT",
            "external_id": bike.get('official_url', '')
        }
        res = requests.post(f"{SUPABASE_URL}/rest/v1/models", 
                          headers=HEADERS, 
                          json=model_data,
                          params={"on_conflict": "brand_id,name,year"})
        
        if res.status_code == 201 or (res.status_code == 200 and res.json()):
            model_id = res.json()[0]['id']
        else:
            # Fallback fetch
            res = requests.get(f"{SUPABASE_URL}/rest/v1/models", 
                             headers=HEADERS, 
                             params={
                                 "brand_id": f"eq.{brand_id}",
                                 "name": f"eq.{bike['model']}",
                                 "year": f"eq.{bike['year']}"
                             })
            model_id = res.json()[0]['id']
        
        # 3. Geometries
        for geo in bike['geometry']:
            geo_data = {
                "model_id": model_id,
                "size_label": str(geo.get('sizeLabel') or geo.get('size') or 'N/A'),
                "stack_mm": geo['stack'],
                "reach_mm": geo['reach']
            }
            requests.post(f"{SUPABASE_URL}/rest/v1/geometries", 
                         headers=HEADERS, 
                         json=geo_data,
                         params={"on_conflict": "model_id,size_label"})
            
        # 4. Builds
        for build in bike['builds']:
            build_data = {
                "model_id": model_id,
                "name": build['name'],
                "groupset": build['specs']['groupset'],
                "wheelset": build['specs']['wheelset'],
                "price_estimated": build.get('price_eur') or build.get('priceEur') or 0,
                "image_url": str(build['images'][0])
            }
            requests.post(f"{SUPABASE_URL}/rest/v1/builds", 
                         headers=HEADERS, 
                         json=build_data)

if __name__ == "__main__":
    migrate()
    print("Migration complete!")
