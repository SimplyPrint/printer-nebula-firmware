from bs4 import BeautifulSoup
import requests
import re
from urllib.parse import urljoin

url = "https://www.creality.com/download/creality-nebula-smart-kit"
firmware_link_re = re.compile(
    r"https://file2-cdn\.creality\.com/file/[A-Za-z0-9]+/NEBULA_ota_img_V(\d+\.\d+\.\d+\.\d+)\.img"
)

session = requests.Session()
resp = requests.get(url)
soup = BeautifulSoup(resp.text, "html.parser")

firmware_versions = {}


def find_links_in_text(text):
    for match in firmware_link_re.finditer(text):
        ver = match.group(1)
        firmware_versions[ver] = match.group(0)


for tag in soup.find_all("a", href=True):
    m = firmware_link_re.match(tag["href"])
    if m:
        firmware_versions[m.group(1)] = m.group(0)

for script in soup.find_all("script"):
    if script.string:
        find_links_in_text(script.string)

for script in soup.find_all("script", src=True):
    js_url = urljoin(url, script["src"])
    try:
        r = session.get(js_url, timeout=10)
        if r.ok:
            find_links_in_text(r.text)
    except requests.RequestException:
        pass

if not firmware_versions:
    print("Error: No firmware links found.")
    exit(1)

latest_ver = sorted(firmware_versions.keys())[-1]
print(latest_ver)
print(firmware_versions[latest_ver])
