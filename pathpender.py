from sys import argv

path = argv[1]

with open("/home/ubuntu/wordlists/" + path + "/perms.txt",'r') as infile, open('/home/ubuntu/wordlists/inffuf.txt','a+') as megfile:
    for sub in infile:
        megfile.write('/'+sub)