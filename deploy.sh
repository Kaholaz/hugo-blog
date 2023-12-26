hugo || exit
rsync public/ vsbugge@navi.samfundet.no:/var/www/kaholaz.net/ -r --delete -P
