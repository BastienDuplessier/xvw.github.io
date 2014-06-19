.PHONY : clean

concat :
	cat src/top.html > index.html
	cat src/articles.html >> index.html
	cat src/footer.html >> index.html

realtime : 
	erlc -o ebin/ src/realtime.erl

run : concat realtime
	erl -pa ebin/ -s realtime

clean : 
	rm -rf erl_crash.dump
	rm -rf src/erl_crash.dump
	rm -rf *~
	rm -rf src/*~