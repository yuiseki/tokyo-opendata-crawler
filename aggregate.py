import datetime

now = datetime.datetime.now()
date = now.strftime('%Y/%m/%d')
datadir = 'data/'+date

total = {}

# load domain list of cities
with open('data/city_domain_list.csv') as f:
  for l in f.readlines():
    domain = l.split(',')[0]
    code = l.split(',')[1].strip()
    if not code.startswith('0'):
      total[domain] = [code, 0, 0, 0]

# load newest status
with open(datadir+'/url_status_list.csv') as f:
  for l in f.readlines():
    status = l.split(',')[0]
    domain = l.split('/')[2]
    if domain in total:
      if status.startswith('2'):
        total[domain][1] += 1
      elif status.startswith('4'):
        total[domain][2] += 1
      else:
        total[domain][3] += 1

# output as csv
# domain, city code, num of exists, num of none, num of unknown
for domain in total.keys():
  print(domain+','+str(total[domain][0]) + ',' + str(total[domain][1])+','+str(total[domain][2])+','+str(total[domain][3]))
