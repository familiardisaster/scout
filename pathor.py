import re
from sys import argv

#Massive code steal from @dkasak on github I fuckin hate regex

path = argv[1]
f1 = argv[2]
f2 = argv[3]

URL_REGEX = r'''^.*?("|')(https?://[a-zA-Z0-9.-]+)?(/[\w\d.~:/?#@!$&()*+,;%=[{}\]-]*?)(\1).*?$'''

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
    with open("/home/ubuntu/wordlists/" + path + "/" + f1,'r') as infile, open("/home/ubuntu/wordlists/" + path + "/" + f2,'a+') as paths:
        for line in infile:
            paths.write(extract_endpoints(line)[0])
else:
    print('Error: Please provide arguments')