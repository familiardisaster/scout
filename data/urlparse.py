import re
from sys import argv

#Massive code steal from @dkasak on github thanks brody

URL_REGEX = r'''^.*?("|')(https?://[a-zA-Z0-9.-]+)?(/[\w\d.~:/?#@!$&()*+,;%=[{}\]-]*?)(\1).*?$'''

path = argv[1]

def decode_and_sanitize(bs):
                content = bs.decode("ascii", "replace")
                content = re.sub(r";\s*$", "\n", content)
                return content

def extract_endpoints(content):
    content = decode_and_sanitize(content)

    endpoints = set()

    for line in content.splitlines():
        for url in re.findall(URL_REGEX, line):
            endpoints.add(url[2])

    return endpoints

if argv:
    with open("/home/ubuntu/wordlists/" + path + "/urls.txt",'r') as infile, open("/home/ubuntu/wordlists/params.txt",'a+') as params, open("/home/ubuntu/wordlists/paths.txt",'a+') as paths:
        for url in infile:
            if '=' in url:
                raw = url.split('=')
                for param in raw[1:]:
                    params.write(param.strip('&='))
            else:
                if extract_endpoints(url):
                    paths.write(extract_endpoints(url)[0])
else:
    print('Error: Please provide a path to the input file as the first argument')
            
            
