import requests
import os

url = "https://upload.wikimedia.org/wikipedia/commons/f/f8/Trek_MADONE.jpg"
headers = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36'
}

print(f"Attempting to download {url}...")
try:
    r = requests.get(url, headers=headers)
    print(f"Status Code: {r.status_code}")
    if r.status_code == 200:
        with open("test_trek.jpg", "wb") as f:
            f.write(r.content)
        print("Download successful! Saved to test_trek.jpg")
        print(f"Size: {len(r.content)} bytes")
    else:
        print("Download failed.")
except Exception as e:
    print(f"Error: {e}")
