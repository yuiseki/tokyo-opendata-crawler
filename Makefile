MONTH := $(shell date "+%Y/%m")
DATADIR := data/$(MONTH)
CATALOG_ENDPOINT := https://catalog.data.metro.tokyo.lg.jp/api/3

all: $(DATADIR) $(DATADIR)/package_list.json $(DATADIR)/resource_list.json $(DATADIR)/resource_url_list.csv

$(DATADIR):
	mkdir -p $(DATADIR)

$(DATADIR)/package_list.json:
	curl -s $(CATALOG_ENDPOINT)/action/package_list | jq . > $(DATADIR)/package_list.json

$(DATADIR)/resource_list.json:
	curl -s $(CATALOG_ENDPOINT)/action/resource_search?query=name: | jq . > $(DATADIR)/resource_list.json

$(DATADIR)/resource_url_list.csv:
	cat $(DATADIR)/resource_list.json | jq -r '.result.results[] | [.id, .package_id, .url, .name, .description] | @csv' > $(DATADIR)/resource_url_list.csv