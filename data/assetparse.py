from sys import argv

path = argv[1]

with open("/home/ubuntu/wordlists/" + path + "/assets.txt",'r') as infile, open("/home/ubuntu/wordlists/" + path + "/hosts.txt",'a+') as hosts, open("/home/ubuntu/wordlists/" + path + "/subs.txt",'a+') as subs:
    for line in infile:
        if line.count('.') == 1:
            hosts.write(line)
        else:
            subs.write(line)