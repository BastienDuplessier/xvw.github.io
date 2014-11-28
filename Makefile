POST = post
RAW =  raw
SRC = src
RAWS = $(patsubst $(RAW)/%.md,%.html,$(wildcard $(RAW)/*.md))

.PHONY: clean

all: post
	@git add *
	@git commit -m "Update pages"
	@echo "Modifications commited"
	@git push origin master

post: $(RAWS)

%.html: $(RAW)/%.md
	@$(eval TITLE :=  $(shell sed -n '0,/^\%/p' $< | sed -re 's/^\% *//'))
	@touch $(POST)/$@
	@sed -re "s/\{\{TITLE\}\}/$(TITLE)/" $(SRC)/header.html > $(POST)/$@
	@pandoc $< >> $(POST)/$@
	@cat $(SRC)/footer.html >> $(POST)/$@
	@echo $(POST)/$@ : [$(TITLE)] created

clean:
	rm -rf ../post/*.html