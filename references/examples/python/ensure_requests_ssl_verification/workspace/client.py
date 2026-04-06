import requests

def fetch_data(url):
    response = requests.get(url, verify=False)
    return response.json()

def post_data(url, payload):
    response = requests.post(url, json=payload, verify=False)
    return response.status_code
