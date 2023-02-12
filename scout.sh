#!/bin/bash

#Check if Axiom is installed
which axiom-ls &>/dev/null || echo "Axiom not installed. Please install manually." >&2; exit 1

#TODO: add options to start Axiom install and update the module for the user

#Check that dnscewl.json module is updated
grep  "\-p _wordlist_" ~/.axiom/modules/dnscewl.json &>/dev/null || echo "Please set the '-p' flag in DNScewl module at ~/.axiom/modules/dnscewl.json equal to '_wordlist_'" >&2; exit 1

#Check that host file is a valid file and properly formatted
test -r $1 || echo "Unable to read input file, ensure that path is correct." >&2; exit 1
grep "[]:/?#@\!\$&'()*+,;=%[]" $1 && echo "The host domains in your input file may not contain any special characters, including ://" >&2; exit 1

#Check that scan name is valid (without special chars)
if [[ $2 =~ "[]:/?#@\!\$&'()*+,;=%[]" ]] ; then 
   echo "The second argument, the scan name, is formatted illegally and should not contain special characters" >&2; exit 1
fi

#Check that instances argument is valid integer between 0-14
if ! [[ $3 =~ '^[0-9]+$' ]] ; then
   echo "The third argument, the Axiom fleet size, must be an integer between 0-14." >&2; exit 1
elif [[ $3 > 14 ]] ; then
   echo "The third argument, the Axiom fleet size, must be an integer between 0-14." >&2; exit 1

fi

#Check that default wordlists exist
test -r ~/wordlists/dns.txt || { printf "Unable to read the dns.txt wordlist at ~/wordlists/dns.txt" && exit;}
test -r ~/wordlists/ffuf.txt || { printf "Unable to read the ffuf.txt wordlist at ~/wordlists/ffuf.txt" && exit;}

echo "|####|####|####|####|####|####|####|####|####|####|####|####|####|####|####|###|"
echo "|The world is yours chico, and everything in it. So say goodnight to the badguy|"
echo "|####|####|####|####|####|####|####|####|####|####|####|####|####|####|####|###|"

#Create Axiom fleet 'asuna' with variable amount of instances (up to 14 currently supported)
axiom-fleet $2 -i $3
axiom-select $2\*

#Create directory for scan output
mkdir /home/ubuntu/wordlists/$2

#Remove duplicates from hosts list
sort -u $1 -o /home/ubuntu/wordlists/$2/hosts.txt 

#Assetfinder to find new domains and subdomains
axiom-scan /home/ubuntu/wordlists/$2/hosts.txt -m assetfinder -o /home/ubuntu/wordlists/$2/subs.txt  --max-runtime 1m 

#Subdomain enumeration
axiom-scan /home/ubuntu/wordlists/$2/hosts.txt -m subfinder -o /home/ubuntu/wordlists/$2/subfinder.txt --max-runtime 1m --threads 4
cat /home/ubuntu/wordlists/$2/subfinder.txt >> /home/ubuntu/wordlists/$2/subs.txt
axiom-scan /home/ubuntu/wordlists/$2/hosts.txt -m amass -o /home/ubuntu/wordlists/$2/amass.txt --max-runtime 1m -passive -alts -brute
cat /home/ubuntu/wordlists/$2/amass.txt >> /home/ubuntu/wordlists/$2/subs.txt

#Append hosts to subdomain list
cat /home/ubuntu/wordlists/$2/hosts.txt >> /home/ubuntu/wordlists/$2/subs.txt 

#Remove duplicates from subdomains list and hosts lists
sort -u /home/ubuntu/wordlists/$2/hosts.txt -o /home/ubuntu/wordlists/$2/hosts.txt
sort -u /home/ubuntu/wordlists/$2/subs.txt -o /home/ubuntu/wordlists/$2/subs.txt

#Build custom DNS wordlist and append to assetnote's DNS wordlist
python3 /home/ubuntu/scout/data/perms.py $2
sort -u /home/ubuntu/wordlists/$2/perms.txt -o /home/ubuntu/wordlists/$2/perms.txt 
cat /home/ubuntu/wordlists/dns.txt >> /home/ubuntu/wordlists/$2/perms.txt

#DNS brutforce
axiom-scan /home/ubuntu/wordlists/$2/subs.txt -m dnscewl -o /home/ubuntu/wordlists/$2/dnsperms.txt --max-runtime 1m -wL /home/ubuntu/wordlists/$2/perms.txt -i --level 2 --range 10 --limit 10000000
cat /home/ubuntu/wordlists/$2/dnsperms.txt >> /home/ubuntu/wordlists/$2/subs.txt
sort -u /home/ubuntu/wordlists/$2/subs.txt -o /home/ubuntu/wordlists/$2/subs.txt

#TODO: Subdomain takeovers

#Find alive subdomains
axiom-scan /home/ubuntu/wordlists/$2/subs.txt -m httpx -o /home/ubuntu/wordlists/$2/alive.txt --max-runtime 1m

#Screenshot alive subdomains
axiom-scan /home/ubuntu/wordlists/$2/alive.txt -m gowitness -o /home/ubuntu/wordlists/$2/screenshots --max-runtime 1m

#Spider subdomains
axiom-scan /home/ubuntu/wordlists/$2/alive.txt -m gospider -o /home/ubuntu/wordlists/$2/spider.txt --max-runtime 1m -u web -t 4 -d 1 --subs --robots -c 10
sort -u /home/ubuntu/wordlists/$2/spider.txt -o /home/ubuntu/wordlists/$2/urls.txt

#Get all urls from gau
axiom-scan /home/ubuntu/wordlists/$2/alive.txt -m gau -o /home/ubuntu/wordlists/$2/gau.txt --max-runtime 1m --threads 4 --subs 
uniq /home/ubuntu/wordlists/$2/gau.txt >> /home/ubuntu/wordlists/$2/urls.txt

#TODO: More fuzzing with gau output (paths, params, everything)

#Content discovery with pre-built lists
axiom-scan /home/ubuntu/wordlists/$2/alive.txt -m krscan -o /home/ubuntu/wordlists/$2/content.txt --max-runtime 1m -A apiroutes-221028 -x 20 -j 200
python3 /home/ubuntu/scout/data/pathor.py $2 content.txt paths.txt
python3 /home/ubuntu/scout/data/urlor.py $2 content.txt urls.txt

#Assemble all known paths and params wordlists
#TODO: FIX THIS
python3 /home/ubuntu/scout/data/urlparse.py $2

#TODO: Custom wordlist for ffuf discovery using perms and paths appended to default, b00mlike list
python3 /home/ubuntu/scout/data/pathpender.py $2
python3 /home/ubuntu/scout/data/fuzzmagic.py

axiom-scan /home/ubuntu/wordlists/$2/alive.txt -m ffuf -o /home/ubuntu/wordlists/$2/ffout.txt --max-runtime 1m -w /home/ubuntu/wordlists/ffuf.txt -recursion --recursion-depth 2 --threads 4 --ignore-body 
python3 /home/ubuntu/scout/data/pathor.py $2 ffout.txt paths.txt

#Create custom meg input file with protocols
python3 /home/ubuntu/scout/data/megprep.py $2

#Meg used to fuzz found paths on new hosts
axiom-scan /home/ubuntu/wordlists/$2/alive.txt -m meg -o /home/ubuntu/wordlists/$2/megout --max-runtime 1m
uniq /home/ubuntu/wordlists/$2/megout/index >> /home/ubuntu/wordlists/$2/urls.txt
sort -u /home/ubuntu/wordlists/$2/urls.txt -o /home/ubuntu/wordlists/$2/urls.txt

#Delete 'asuna' Axiom fleet
axiom-rm $2\* -f
