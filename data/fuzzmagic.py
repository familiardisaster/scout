with open("/home/ubuntu/wordlists/$2/subs.txt",'r') as infile, open("/home/ubuntu/wordlists/ffuf.txt",'a+') as outfile:
        for line in infile:
            words = line.split('.')
            for word in words:
                outfile.write('/' + word)

