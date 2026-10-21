import os
import requests
from io import BytesIO
from PIL import Image

TARGET_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Resources", "BikeImages")
TARGET_SIZE = (1600, 900)

DIRECT_URLS = {
    'cervelo-px-series': 'https://images.prismic.io/cervelo/81a97d9e-1bc8-43d9-9599-4c1b9b1e956b_2021_PX_SERIES_DURA_ACE_DI2_PROFILE.png',
    'bmc-timemachine-01': 'https://www.bmc-switzerland.com/media/catalog/product/b/m/bmc_23_timemachine_01_disc_one_side.png',
    'argon18-e119-tri': 'https://images.argon18bike.com/argon18/e119-tri-disc-2021-side.png',
    'giant-trinity-advanced': 'https://images.giant-bicycles.com/b_white,c_pad,h_1000,q_80/Trinity_Advanced_Pro_1.png',
    'cadex-tri': 'https://images2.giant-bicycles.com/b_white,c_pad,h_1000,q_80/CADEX_TRI_Complete_Side.png',
    'cube-aerium-c68x': 'https://www.cube.eu/media/img/92/re/985550_aerium_c68x_slr_nebula_n_white_sall_v1.png',
    'diamondback-andean': 'https://cdn.roadbikedatabase.com/wp-content/uploads/2022/04/04025720/2020-Diamondback-Andean-1-1024x971.png',
    'ceepo-shadow-r': 'https://cdn.road.cc/sites/default/files/styles/main_width_970/public/ceepo-shadow-r-side.jpg',
    'berria-miura': 'https://bikewar.files.wordpress.com/2013/11/berria_miura.jpg',
    'cipollini-nktt': 'https://roadbikedatabase.com/wp-content/uploads/2023/05/2023-Cipollini-NKTT-Q40DF-SHIMANO-ULTEGRA.jpeg',
    'ridley-dean-fast': 'https://www.bikebargains.co.uk/wp-content/uploads/2018/02/Ridley-Dean-Fast-Ultegra-Di2-Side.jpg',
    'canyon-endurace-cf-slx': 'https://dma.canyon.com/image/upload/w_2000,f_png/v1/2024_FULL_endurace-cf-slx-8-di2_3711_P01_agbv0f.png',
    'specialized-roubaix-sl8': 'https://assets.specialized.com/i/specialized/96824-00_ROUBAIX-SW-DI2-METSMK-SMK_HERO?fmt=png&wid=2000',
    'giant-defy-advanced-pro': 'https://images.giant-bicycles.com/b_white,c_pad,h_1000,q_80/Defy_Advanced_Pro_0.png',
    'cannondale-synapse-carbon': 'https://cannondale.azureedge.net/media/catalog/product/c/2/c22_c12102u_synapse_crb_1_rle_ste_3_1.png',
    'orbea-avant': 'https://www.orbea.com/img/products/product/over/large/T112TTCC-MY-SIDE-AVANT_H30_over.jpg',
    'canyon-ultimate-cf-slx': 'https://dma.canyon.com/image/upload/w_2000,f_png/v1/2024_FULL_ultimate-cf-slx-8-di2_3564_P01_agbv0f.png',
    'trek-emonda-slr': 'https://media.trekbikes.com/image/upload/w_2000,f_png/EmondaSLR7-23-36968-A-Primary',
    'scott-addict-rc': 'https://assets.scott-sports.com/pages/addict-rc/addict-rc-ultimate.png',
    'giant-tcr-advanced-pro': 'https://images.giant-bicycles.com/b_white,c_pad,h_1000,q_80/TCR_Advanced_Pro_0_Di2.png',
    'bmc-teammachine-slr': 'https://www.bmc-switzerland.com/media/catalog/product/b/m/bmc_24_teammachine_slr_one_side.png',
    'cannondale-supersix-evo': 'https://cannondale.azureedge.net/media/catalog/product/c/2/c23_c11002u_supersix_evo_lab71_team_3_1.png',
    'orbea-orca': 'https://www.orbea.com/img/products/product/over/large/T108TTCC-MY-SIDE-ORCA_M10iLTD_over.jpg',
    'cervelo-r5': 'https://images.prismic.io/cervelo/aFxeY3fc4bHWiuq9_0L0R5FFX2C-PROFILE-Web.png',
    'pinarello-dogma-f': 'https://pinarello.com/storage/Variant/dogma-f-dura-ace-di2-bob.png',
    'colnago-c68': 'https://www.colnago.com/storage/bikes/c68-road/c68-road-hrrg.png',
    'bianchi-oltre-rc': 'https://www.bianchi.com/wp-content/uploads/2022/10/YRB01I_CK.png',
    'look-795-blade-rs': 'https://www.lookcycle.com/media/catalog/product/7/9/795-blade-rs-pro-team-white-mat.png',
    'ridley-noah-fast': 'https://www.ridley-bikes.com/media/catalog/product/n/o/noah-fast-disc-ultegra-di2-side.png',
    'scott-foil-rc': 'https://assets.scott-sports.com/pages/foil-rc/foil-rc-ultimate-side.png'
}

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
    'Referer': 'https://www.google.com/'
}

def standardize(img):
    img = img.convert('RGBA')
    corners = [img.getpixel((0,0)), img.getpixel((img.width-1, 0)), 
               img.getpixel((0, img.height-1)), img.getpixel((img.width-1, img.height-1))]
    is_white = any(c[0] > 235 and c[1] > 235 and c[2] > 235 for c in corners)
    
    if is_white:
        datas = img.get_flattened_data() if hasattr(img, 'get_flattened_data') else img.getdata()
        new_data = []
        for item in datas:
            if item[0] > 235 and item[1] > 235 and item[2] > 235:
                new_data.append((255, 255, 255, 0))
            else:
                new_data.append(item)
        img.putdata(new_data)
        
    bbox = img.getbbox()
    bike = img.crop(bbox) if bbox else img
    
    canvas = Image.new('RGBA', TARGET_SIZE, (0, 0, 0, 0))
    max_w = int(TARGET_SIZE[0] * 0.88)
    max_h = int(TARGET_SIZE[1] * 0.82)
    
    scale = min(max_w / bike.width, max_h / bike.height)
    new_w = int(bike.width * scale)
    new_h = int(bike.height * scale)
    
    resized = bike.resize((new_w, new_h), Image.Resampling.LANCZOS)
    paste_x = (TARGET_SIZE[0] - new_w) // 2
    paste_y = (TARGET_SIZE[1] - new_h) // 2
    
    canvas.paste(resized, (paste_x, paste_y), resized)
    return canvas

def run():
    os.makedirs(TARGET_DIR, exist_ok=True)
    success = 0
    failed = []
    
    for b_id, url in DIRECT_URLS.items():
        dest = os.path.join(TARGET_DIR, f"{b_id}.png")
        if os.path.exists(dest):
            print(f"Skipping {b_id} (already exists)")
            success += 1
            continue
            
        print(f"Fetching [{b_id}] from {url}...")
        try:
            res = requests.get(url, headers=HEADERS, timeout=12)
            if res.status_code == 200:
                raw_img = Image.open(BytesIO(res.content))
                std_img = standardize(raw_img)
                std_img.save(dest, 'PNG', optimize=True)
                print(f"  ✅ Saved {b_id}.png (1600x900)")
                success += 1
            else:
                print(f"  ❌ HTTP {res.status_code}")
                failed.append((b_id, f"HTTP {res.status_code}"))
        except Exception as e:
            print(f"  ❌ Error: {e}")
            failed.append((b_id, str(e)))
            
    print(f"\nFinalizado: {success} exitosos, {len(failed)} fallidos.")

if __name__ == '__main__':
    run()
