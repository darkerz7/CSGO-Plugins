Installation:
1. Unzip everything into the appropriate folders.
2. Add a new section to addons/sourcemod/configs/databases.cfg
	*Example:
		"AutoRetryDB"
		{
			"driver"			"sqlite"
			"host"				"localhost"
			"database"			"AutoRetryDB"
			"user"				"root"
			"pass"				""
			//"timeout"			"0"
			//"port"			"3306"
		}
	*If you want to use mysql, manually create a new database
3. Restart Server