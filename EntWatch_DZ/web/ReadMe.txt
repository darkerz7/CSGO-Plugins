Installation:
1. Copy files from the folder 'site' to the hosting
2. Open connect.php and specify the data to connect to the database
	*Also here you can specify how many records to display per page - variable $per_page
3. Open index.php and find the line #63 '<a key_phrase="Go Back Link" class="lang" href="https://google.com">Go Back</a>'
	correct the link to your.

Add new language:
1. Open lang.js
2. Copy dictionary from 'arrLang' and name it let's say 'de'
3. Insert the resulting dictionary after the section 'ru' !don't forget to add a comma
4. Open index.php and go to the section '<div class="navbar-right">'
5. Add a new line before the form '<a class="navbar-lang" onclick="SetLang('de'); localStorage.setItem('lang', 'de');" href="#">DE</a>'

Features:
-Allows you to display the database from the entwatch for display on your site
-Has a desktop and mobile version
-Can search by steamid
-Multilingual site