import requests
import time
from bs4 import BeautifulSoup

def search_new_models():
    print("🔍 Searching for new bike models (2024/2025 releases)...")
    query = "new 2025 road bike releases geometry stack reach"
    url = f"https://www.bing.com/search?q={query.replace(' ', '+')}"
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36'
    }
    
    try:
        r = requests.get(url, headers=headers)
        soup = BeautifulSoup(r.text, 'html.parser')
        
        results = []
        for item in soup.find_all('li', class_='b_algo'):
            title = item.find('h2').text if item.find('h2') else "N/A"
            link = item.find('a')['href'] if item.find('a') else "N/A"
            results.append({"title": title, "link": link})
            
        print(f"✅ Found {len(results)} potential sources for new data:")
        for res in results[:5]:
            print(f"   - {res['title']} ({res['link']})")
            
        return results
    except Exception as e:
        print(f"❌ Error during discovery: {e}")
        return []

if __name__ == "__main__":
    search_new_models()
