if [ -n "$1" ]; then
	sed -i -E 's/(draft: )true/\1false/; s/(date: ).*/\1'$(date '+%Y-%m-%dT%T%z')'/' content/posts/$1.md
fi
hugo || exit
rsync public/ vsbugge@navi.samfundet.no:/var/www/kaholaz.net/ -r --delete -P
