from bs4 import BeautifulSoup
import requests
import re
from urllib.parse import urljoin
import json

urls = [
    "https://www.crealitycloud.com/downloads/other/type-24",
    "https://www.creality.com/download/creality-nebula-smart-kit",
]

firmware_link_re = re.compile(
    r"https://file2-cdn\.creality\.com/file/[A-Za-z0-9]+/NEBULA_ota_img_V(\d+\.\d+\.\d+\.\d+)\.img"
)
firmware_name_re = re.compile(r"NEBULA_ota_img_V(\d+\.\d+\.\d+\.\d+)\.img")
firmwareList_re = re.compile(r'\\"firmwareList\\"\s*:\s*(\[[^]]*])')
nuxt_nebula_re = re.compile(r'"(https?:[^"]*NEBULA[^"]*\.img)"')

session = requests.Session()

firmware_versions = {}


def find_links_in_text(text):
    for match in firmware_link_re.finditer(text):
        ver = match.group(1)
        firmware_versions[ver] = match.group(0)


def extract_firmware_from_json(text):
    for match in firmwareList_re.finditer(text):
        firmware_json = match.group(1).replace("\\", "")

        try:
            firmware_list = json.loads(firmware_json)
            for item in firmware_list:
                if not isinstance(item, dict):
                    continue

                download_url = item.get("downloadUrl")
                version = firmware_name_re.search(item.get("version"))

                if not download_url or not version:
                    continue

                firmware_versions[version.group(1)] = download_url

        except (json.JSONDecodeError, TypeError):
            print("Failed to parse JSON")
            pass


def extract_firmware_from_nuxt(text):
    for match in nuxt_nebula_re.finditer(text):
        raw = match.group(1)
        decoded = raw.encode().decode("unicode_escape")

        ver_match = firmware_name_re.search(decoded)
        if ver_match:
            firmware_versions[ver_match.group(1)] = decoded


for url in urls:
    resp = requests.get(url)
    soup = BeautifulSoup(resp.text, "html.parser")

    for tag in soup.find_all("a", href=True):
        m = firmware_link_re.match(tag["href"])
        if m:
            firmware_versions[m.group(1)] = m.group(0)

    for script in soup.find_all("script"):
        if script.string:
            find_links_in_text(script.string)
            extract_firmware_from_json(script.string)
            extract_firmware_from_nuxt(script.string)

    for script in soup.find_all("script", src=True):
        js_url = urljoin(url, script["src"])
        try:
            r = session.get(js_url, timeout=10)
            if r.ok:
                find_links_in_text(r.text)
                extract_firmware_from_json(r.text)
                extract_firmware_from_nuxt(r.text)
        except requests.RequestException:
            pass

if not firmware_versions:
    print("Error: No firmware links found.")
    exit(1)

latest_ver = sorted(firmware_versions.keys())[-1]
print(latest_ver)
print(firmware_versions[latest_ver])
