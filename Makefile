publish:
	mv git-source/.git _book/.git
	cd _book && git status
	cd _book && git add .
	cd _book && git commit -m "add artical"
	cd _book && git push
	mv _book/.git git-source/.git

reset_git_folder:
	mv _book/.git git-source/.git
