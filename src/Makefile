POST = ../post
RAW = ../raw
RAWS = $(patsubst $(RAW)/%.md,%.html,$(wildcard $(RAW)/*.md))

.PHONY: clear_emacs

all: $(RAWS)

%.html: $(RAW)/%.md
	@$(eval TITLE :=  $(shell sed -n '0,/^#/p' $< | sed -re 's/^# *//'))
	@touch $(POST)/$@
	@sed -re "s/\{\{TITLE\}\}/$(TITLE)/" header.html > $(POST)/$@
	@pandoc $< >> $(POST)/$@
	@echo "</body></html>" >> $(POST)/$@
	@echo $(POST)/$@ : [$(TITLE)] created


clean:
	rm -rf ../post/*.html
clear_emacs:
	rm -rf ../*~
	rm -rf *~
	rm -rf ../post/*~
	rm -rf ../raw/*~