from sys import argv

path = argv[1]

with open("/home/ubuntu/wordlists/" + path + "/subs.txt",'r') as infile, open('/home/ubuntu/wordlists/meg.txt','w') as megfile:
    for sub in infile:
        megfile.write('https://'+sub)