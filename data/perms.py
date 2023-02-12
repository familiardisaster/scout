from sys import argv

path = argv[1]

if argv:
    with open("/home/ubuntu/wordlists/" + path + "/subs.txt",'r') as infile, open("/home/ubuntu/wordlists/" + path + "/perms.txt",'a+') as outfile:
        for line in infile:
            words = line.split('.')
            for word in words:
                outfile.write('\n' + word)
else:
    print('Error: Please pass the path to your input file as the first argument')


