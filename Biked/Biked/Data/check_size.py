import requests

urls = [
    "https://upload.wikimedia.org/wikipedia/commons/f/f8/Trek_MADONE.jpg",
    "https://upload.wikimedia.org/wikipedia/commons/2/27/Cannondale_SuperSix.jpg",
    "https://upload.wikimedia.org/wikipedia/commons/3/37/Pinarello_Dogma_F_Super_Record_EPS.jpg",
    "https://media.specialized.com/bikes/road/5758_TarmacSL8_ArticleTile_580x618_02.jpg"
]

print("Checking Content-Length...")
for url in urls:
    try:
        r = requests.head(url, timeout=5)
        size = int(r.headers.get('content-length', 0)) / 1024 / 1024
        print(f"[{r.status_code}] {size:.2f} MB - {url.split('/')[-1][:20]}")
    except Exception as e:
        print(f"[ERROR] {e}")
