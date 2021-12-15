MONTH := $(shell date "+%Y/%m")
DATADIR := data/$(MONTH)
CATALOG_ENDPOINT := https://catalog.data.metro.tokyo.lg.jp/api/3

all: $(DATADIR) $(DATADIR)/package_list.json $(DATADIR)/resource_list.json $(DATADIR)/resource_url_list.csv $(DATADIR)/404_url_list.csv $(DATADIR)/404_resource_list.csv $(DATADIR)/404_package_info.csv

$(DATADIR):
	mkdir -p $(DATADIR)

$(DATADIR)/package_list.json:
	curl -s $(CATALOG_ENDPOINT)/action/package_list | jq . > $(DATADIR)/package_list.json

$(DATADIR)/resource_list.json:
	curl -s $(CATALOG_ENDPOINT)/action/resource_search?query=name:&order_by=last_modified | jq . > $(DATADIR)/resource_list.json

$(DATADIR)/resource_url_list.csv:
	cat $(DATADIR)/resource_list.json | jq -r '.result.results[] | [.id, .package_id, .url] | @csv' > $(DATADIR)/resource_url_list.csv

$(DATADIR)/404_url_list.csv:
	cat $(DATADIR)/resource_url_list.csv | cut -d ',' -f 3 | xargs -t -P16 -I{} curl -L -I -s -m 5 -o /dev/null -w '%{http_code},{}\n' {} | grep --line-buffered "^404" > $(DATADIR)/404_url_list.csv

$(DATADIR)/404_resource_list.csv:
	cat $(DATADIR)/404_url_list.csv | cut -d ',' -f 2 | xargs -I{} grep {} $(DATADIR)/resource_url_list.csv > $(DATADIR)/404_resource_list.csv

# TODO: groupsやtagsも適切に保存したい
$(DATADIR)/404_package_info.csv:
	cat $(DATADIR)/404_resource_list.csv | cut -d ',' -f 2 | xargs -t -I{} curl -s $(CATALOG_ENDPOINT)/action/package_show?id={} | \
		jq -r '.result | [.id, (.organization.title|gsub("\r\n"; " ")), (.maintainer|gsub("\r\n"; " ")), (.organization.description|gsub("\r\n"; " "))] | @csv' > $(DATADIR)/404_package_info.csv

