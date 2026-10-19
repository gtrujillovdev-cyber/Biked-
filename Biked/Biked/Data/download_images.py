import json
import os
import time
import re
import requests
from bs4 import BeautifulSoup
from urllib.parse import urlparse, unquote
from PIL import Image
from io import BytesIO

# Configuration
JSON_PATH = '../Resources/bikes.json'
# Path relative to build/data script location
IMAGE_DIR = "../Resources/BikeImages/"
FORCE_DOWNLOAD = True
MIN_FILE_SIZE = 25000 # 25KB min to avoid logos

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}

def setup_directories():
    if not os.path.exists(IMAGE_DIR):
        os.makedirs(IMAGE_DIR)

def get_og_image(url):
    try:
        if not url or "http" not in url: return None
        print(f"    Fallback: Checking official URL metadata...")
        meta_headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        }
        response = requests.get(url, headers=meta_headers, timeout=10)
        if response.status_code == 200:
            soup = BeautifulSoup(response.text, 'html.parser')
            og = soup.find("meta", attrs={"property": "og:image"})
            if og and og.get("content"): return og["content"]
            tw = soup.find("meta", attrs={"name": "twitter:image"})
            if tw and tw.get("content"): return tw["content"]
    except Exception as e:
        print(f"    Metadata error: {e}")
    return None

def search_image(query, transparent=False):
    try:
        ts_msg = " [Trans]" if transparent else ""
        print(f"    Searching Bing{ts_msg}: {query}")
        
        filters = "+filterui:imagesize-large"
        if transparent:
            filters += "+filterui:photo-transparent"
            
        base_url = "https://www.bing.com/images/search"
        params = {"q": query, "qft": filters, "form": "HDRSC2", "first": "1"}
        
        bing_headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Referer': 'https://www.bing.com/'
        }
        
        response = requests.get(base_url, params=params, headers=bing_headers, timeout=10)
        if response.status_code != 200: return None
            
        content = response.text
        urls = re.findall(r'murl&quot;:&quot;(https://.*?\.(?:png|jpg|jpeg|webp))&quot;', content)
        if not urls:
             urls = re.findall(r'murl":"(https://.*?\.(?:png|jpg|jpeg|webp))"', content)
        
        for u in urls:
            if 'bing' in u.lower(): continue
            return u
    except Exception as e:
        print(f"    Search error: {e}")
    return None

def download_image(img_url, bike_id):
    """
    Downloads image, converts to PNG if needed, and ensures it's a high-quality cutout.
    """
    try:
        if not img_url or not img_url.startswith('http'): return None
        print(f"    Downloading: {img_url}")
        
        response = requests.get(img_url, headers=HEADERS, timeout=15)
        if response.status_code == 200:
            # Load with PIL to verify and convert
            img = Image.open(BytesIO(response.content))
            
            # Ensure it's large enough (at least some resolution)
            if img.width < 400 or img.height < 250:
                print(f"    [Skipped] Image too small: {img.width}x{img.height}")
                return None
            
            # Convert to PNG with Transparency support
            if img.mode != 'RGBA':
                img = img.convert('RGBA')
            
            filename = f"{bike_id}.png"
            filepath = os.path.join(IMAGE_DIR, filename)
            
            img.save(filepath, "PNG")
            
            size = os.path.getsize(filepath)
            
            # CRITICAL: Detect if it's the 1MB "bicycle-transparent-background-png.png" junk
            if size in [1152069, 1125203, 1109452, 1099452, 1089452, 1152694, 885785, 1489086, 1622110]:
                print(f"    [Junk Detected] Size {size} matches stock bike junk. Deleting.")
                os.remove(filepath)
                return None

            # NEW: Aspect Ratio Check (Gold Standard: roughly 1.2 to 2.2 for side-profile bike)
            ratio = img.width / img.height
            if ratio < 1.1 or ratio > 2.5:
                print(f"    [Rejected] Invalid Aspect Ratio: {ratio:.2f}. Likely not a full side-profile bike.")
                os.remove(filepath)
                return None

            # NEW: Downscale for App Bundle Efficiency if too large
            if img.width > 2048 or img.height > 2048:
                print(f"    Downscaling from {img.width}x{img.height} to 2048px...")
                img.thumbnail((2048, 2048), Image.Resampling.LANCZOS)
                img.save(filepath, "PNG")

            if size < MIN_FILE_SIZE:
                print(f"    File too small ({size} bytes). Deleting.")
                if os.path.exists(filepath): os.remove(filepath)
                return None
                
            print(f"    Saved {filename} ({size // 1024} KB) - {img.width}x{img.height}")
            return filename
        else:
            print(f"    Download failed: HTTP {response.status_code}")
    except Exception as e:
        print(f"    Download exception: {e}")
    return None

def main():
    setup_directories()
    try:
        with open(JSON_PATH, 'r') as f: bikes = json.load(f)
    except Exception as e:
        print(f"CRITICAL: could not load JSON. {e}")
        return

    count = 0
    
    # DIRECT URL OVERRIDES (Verified high-quality cutouts curated via Browser Subagent)
    DIRECT_URLS = {
        "canyon-speedmax-cfr-tri": "https://dma.canyon.com/image/upload/w_2000,f_png/v1751878548/2026_FULL_speedmax_cfr-di2_4133_R085_P16_agbv0f.png",
        "cervelo-p5": "https://images.prismic.io/cervelo/aFxeY3fc4bHWiuq9_0L0P5FFX2C-PROFILE-Web.png",
        "specialized-shiv-disc": "https://assets.specialized.com/i/specialized/97419-00_SHIV-SW-DISC-DI2-LTD-SNST-FIVE-O-WHT_HERO?fmt=png&wid=2000",
        "pinarello-bolide-f-hr": "https://pinarello.com/storage/Variant/de129cb5e0b9e2bcd104d4a813c73ce6.png",
        "trek-speed-concept-slr": "https://media.trekbikes.com/image/upload/w_2000,f_png/SpeedConceptSLR7-24-35577-F-Primary",
        "cervelo-p-series": "https://images.prismic.io/cervelo/85f96dc4-9568-49df-8fec-85512c5dc929_0H1PSEUI1C+PROFILE+%281%29.png?auto=compress,format",
        "cervelo-px-series": "https://images.prismic.io/cervelo/81a97d9e-1bc8-43d9-9599-4c1b9b1e956b_2021_PX_SERIES_DURA_ACE_DI2_PROFILE.png",
        "scott-plasma-6": "https://assets.scott-sports.com/pages/plasma-6/plasma-geometry-m-54-770x500.png",
        "bmc-timemachine-01": "https://www.bmc-switzerland.com/media/catalog/product/b/m/bmc_23_timemachine_01_disc_one_side.png",
        "factor-hanzo": "https://images.ctfassets.net/uyc32o2uod42/565ay6N82Y3BPoLGfFbsJp/4209837925c8cd7b2015dc22077d601c/pdp_hero_Hanzo_chrome_ds.png",
        "wilier-supersonica-slr": "https://wilier-cdn.thron.com/delivery/public/image/wilier/ee879f0d-c971-4435-ad06-4fb5b52a9e89/2uww6s/std/5040x3078/_t17_1?scalemode=product&format=png",
        "felt-ia-2-0": "https://azwecdnepstoragewebsiteuploads.azureedge.net/PHO_BIKE_90_RE_FELT-25-IA-2-PRO-Ultegra-Di2_#SALL_#AEPI_#V1.png",
        "qr-v-pr": "https://quintanarootri.com/cdn/shop/files/IronmanV-PRi.png",
        "argon18-e119-tri": "https://images.argon18bike.com/argon18/e119-tri-disc-2021-side.png",
        "orbea-ordu": "https://www.orbea.com/img/products/product/over/large/T128TTCC-GE-SIDE-ORDU_M20iLTD_over.jpg",
        "giant-trinity-advanced": "https://images.giant-bicycles.com/b_white,c_pad,h_1000,q_80/Trinity_Advanced_Pro_1.png",
        "cadex-tri": "https://images2.giant-bicycles.com/b_white,c_pad,h_1000,q_80/CADEX_TRI_Complete_Side.png",
        "cube-aerium-c68x": "https://www.cube.eu/media/img/92/re/985550_aerium_c68x_slr_nebula_n_white_sall_v1.png",
        "trek-madone-slr": "https://www.bigbearbikes.co.uk/content/products/trek-madone-slr-7-etap-gen-7_67245698.jpg",
        "merida-reacto": "https://www.wheelbase.co.uk/wp-content/uploads/import/merida/2026/26_Merida_Reacto_Team_Black_Silver.jpg",
        "diamondback-andean": "https://cdn.roadbikedatabase.com/wp-content/uploads/2022/04/04025720/2020-Diamondback-Andean-1-1024x971.png",
        "ventum-one": "https://cdn11.bigcommerce.com/s-socd7uniqk/images/stencil/1280x1280/products/1049/1382/VOD-ECOM-BLACK-SHIMANO_DURA_ACE-1__35406.1752694073.jpg?c=1",
        "ceepo-shadow-r": "https://cdn.road.cc/sites/default/files/styles/main_width_970/public/ceepo-shadow-r-side.jpg",
        "tririg-omni": "https://tririg.com/cdn/shop/files/omni-carbon-bicycle-complete-frameset-tririg-1_grande.png?v=1715176886",
        "ribble-ultra-tt": "https://findabikelive.blob.core.windows.net/bikes/ribble-ultra-tt-ultra-tt-shimano-105-2020_1-large.jpg",
        "kestrel-5000-sl": "https://files.bikeindex.org/uploads/Pu/589558/BTT13081_PH1_2.jpg",
        "berria-miura": "https://bikewar.files.wordpress.com/2013/11/berria_miura.jpg",
        "bh-aerolight-tt": "https://marktplatz.bike/static/images/Modelle/BH-Bikes/2017/Fahrrad/AEROLIGHT-ULTEGRA-Di2/side_001_bike-detail-2x.png",
        "cipollini-nktt": "https://roadbikedatabase.com/wp-content/uploads/2023/05/2023-Cipollini-NKTT-Q40DF-SHIMANO-ULTEGRA.jpeg",
        "ridley-dean-fast": "https://www.bikebargains.co.uk/wp-content/uploads/2018/02/Ridley-Dean-Fast-Ultegra-Di2-Side.jpg",
        "vitoria-nyxtralight": "https://www.vitoriabikes.es/img/p/7/4/2/742.jpg",
        "specialized-shiv-tt-disc": "https://files.bikeindex.org/uploads/Pu/663901/BTT13312_PH_2.jpg",
        "orbea-ordu": "https://www.orbea.com/img/products/product/over/large/T128TTCC-GE-SIDE-ORDU_M20iLTD_over.jpg",
        "felt-ia-2-0": "https://azwecdnepstoragewebsiteuploads.azureedge.net/PHO_BIKE_90_RE_FELT-25-IA-2-PRO-Ultegra-Di2_%23SALL_%23AEPI_%23V1.jpg"
    }

    # MANUAL SEARCH QUERIES
    # Explicitly asking for "complete bike" and "with wheels" to avoid framesets.
    MANUAL_QUERIES = {
        "specialized-shiv-tt-disc": "Specialized S-Works Shiv TT Disc complete bike side profile cutout png",
        "cervelo-p5": "Cervelo P5 bike with wheels side view cutout png",
        "cervelo-p-series": "Cervelo P-Series complete bicycle side view cutout png",
        "cervelo-px-series": "Cervelo PX-Series bike with wheels side view cutout png",
        "trek-speed-concept-slr": "Trek Speed Concept SLR complete bike side view cutout png",
        "scott-plasma-6": "Scott Plasma 6 bike with wheels side view cutout png",
        "bmc-timemachine-01": "BMC Timemachine 01 complete bike side view cutout png",
        "pinarello-bolide-f-hr": "Pinarello Bolide F HR bike with wheels side view cutout png",
        "colnago-tt1": "Colnago TT1 complete bike side view cutout png",
        "factor-hanzo": "Factor Hanzo bike with wheels side view cutout png",
        "wilier-supersonica-slr": "Wilier Supersonica SLR complete bike side view cutout png",
        "felt-ia-2-0": "Felt IA 2.0 bike with wheels side view cutout png",
        "qr-v-pr": "Quintana Roo V-PRi complete bike side view cutout png",
        "argon18-e119-tri": "Argon 18 E-119 bike with wheels side view cutout png",
        "orbea-ordu": "Orbea Ordu complete bike side view cutout png",
        "giant-trinity-advanced": "Giant Trinity Advanced bike with wheels side view cutout png",
        "cadex-tri": "Cadex Tri complete bike side view cutout png",
        "cube-aerium-c68x": "Cube Aerium C:68X bike with wheels side view cutout png",
        "diamondback-andean": "Diamondback Andean complete bike side view cutout png",
        "ventum-one": "Ventum One bike with wheels side view cutout png",
        "ceepo-shadow-r": "Ceepo Shadow-R complete bike side view cutout png",
        "tririg-omni": "TriRig Omni bike with wheels side view cutout png",
        "ribble-ultra-tt": "Ribble Ultra TT complete bike side view cutout png",
        "kestrel-5000-sl": "Kestrel 5000 SL bike with wheels side view cutout png",
        "berria-miura": "Berria Miura complete bike side view cutout png",
        "bh-aerolight-tt": "BH Aerolight TT bike with wheels side view cutout png",
        "cipollini-nktt": "Cipollini NKTT complete bike side view cutout png",
        "ridley-dean-fast": "Ridley Dean Fast bike with wheels side view cutout png",
    }

    for bike in bikes:
        # Check Local Existence
        # All images are now .png in our pipeline
        local_filename = f"{bike['id']}.png"
        possible_path = os.path.join(IMAGE_DIR, local_filename)
        
        if not FORCE_DOWNLOAD and os.path.exists(possible_path) and os.path.getsize(possible_path) > MIN_FILE_SIZE:
            print(f"Skipping {bike['id']} (OK)")
            continue
            
        print(f"\nProcessing [{bike['id']}] {bike['brand']} {bike['model']}...")
        img_url = None
        
        # 1. Try Direct URL first
        if bike['id'] in DIRECT_URLS:
            img_url = DIRECT_URLS[bike['id']]

        # 2. Manual Query Override
        if not img_url and bike['id'] in MANUAL_QUERIES:
             img_url = search_image(MANUAL_QUERIES[bike['id']], transparent=True)
             if not img_url:
                 img_url = search_image(MANUAL_QUERIES[bike['id']], transparent=False)
            
        # 3. STRATEGY: Specific Search
        if not img_url:
            q = f"{bike['brand']} {bike['model']} complete bike side profile cutout with wheels png -frameset"
            img_url = search_image(q, transparent=True)
            
        if not img_url:
            q = f"{bike['brand']} {bike['model']} professional bicycle side view with wheels transparent"
            img_url = search_image(q, transparent=True)

        # DOWNLOAD
        if img_url:
            local = download_image(img_url, bike['id'])
            if local:
                count += 1
                github_url = f"https://raw.githubusercontent.com/gtrujillovdev-cyber/Biked/main/Biked/Biked/Resources/BikeImages/{local}"
                for b in bike['builds']:
                    b['images'] = [github_url]
            else:
                print("    [Error] Failed to process image.")
        else:
            print("    [Fail] No image found.")
            
        time.sleep(3) # Throttle to avoid 429
        
    with open(JSON_PATH, 'w') as f: json.dump(bikes, f, indent=4)
    print(f"\nCompleted. Updated {count} bikes.")

if __name__ == "__main__":
    main()
