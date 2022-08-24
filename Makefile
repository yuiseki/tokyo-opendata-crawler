DATE := $(shell date "+%Y/%m/%d")
DATADIR := data/$(DATE)
CATALOG_ENDPOINT := https://catalog.data.metro.tokyo.lg.jp/api/3

all: \
	$(DATADIR) \
	$(DATADIR)/resource_list.json \
	$(DATADIR)/resource_url_list.csv \
	$(DATADIR)/packages.txt \
	$(DATADIR)/domains.txt \
	data/packages/finished.txt \
	data/groups.txt \
	data/title.csv

clean:
	rm data/packages/started.txt
	rm data/packages/finished.txt

more: \
	$(DATADIR)/url_status_list.csv \
	data/opendata_status.csv \

$(DATADIR):
	mkdir -p $(DATADIR)

# CKANの全リソースのjson
$(DATADIR)/resource_list.json:
	curl -s "$(CATALOG_ENDPOINT)/action/resource_search?query=name:&order_by=last_modified" | jq . > $(DATADIR)/resource_list.json

# 全リソースのid, package_id, urlのcsv
$(DATADIR)/resource_url_list.csv:
	cat $(DATADIR)/resource_list.json | jq -r '.result.results[] | [.id, .package_id, .url] | @csv' > $(DATADIR)/resource_url_list.csv

# ユニークなpackage_idの一覧txt
$(DATADIR)/packages.txt:
	cat $(DATADIR)/resource_url_list.csv | cut -d ',' -f 2 | sort | uniq > $(DATADIR)/packages.txt

# ユニークなドメインの一覧txt
$(DATADIR)/domains.txt:
	cat $(DATADIR)/resource_url_list.csv | cut -d ',' -f 3 | cut -d/ -f 3 | sort | uniq > $(DATADIR)/domains.txt

# 全リソースの示すURLのhttp status codeのcsv
$(DATADIR)/url_status_list.csv:
	cat $(DATADIR)/resource_url_list.csv | cut -d ',' -f 3 | \
		xargs -t -I{} sh -c 'curl -L -I -s -m 10 -o /dev/null -w "%{http_code},{}\n" {} >> $(DATADIR)/url_status_list.csv'

data/opendata_status.csv:
	python aggregate.py


# 全packageのid, organization, maintainer
data/packages/finished.txt:
	mkdir -p data/packages
	date '+%Y/%m/%d %H:%m:%S' > data/packages/started.txt
	cat $(DATADIR)/packages.txt | xargs -t -I{} sh -c 'curl -s "$(CATALOG_ENDPOINT)/action/package_show?id={}" | jq . > data/packages/{}.json'
	date '+%Y/%m/%d %H:%m:%S' > data/packages/finished.txt

data/groups.txt:
	ls -t -1 data/packages/*.json | xargs cat | jq -r '.result.groups[].display_name' | sort | uniq > data/groups.txt

data/titles.csv:
	ls -t -1 data/packages/*.json | xargs cat | jq -r '[.result.title, .result.resources[].name] | @csv' > data/titles.csv
