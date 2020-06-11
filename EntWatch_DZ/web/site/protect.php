<?php
function f_clean_data($value = "")
{
    $value = trim($value);
    $value = stripslashes($value);
    $value = strip_tags($value);
    $value = htmlspecialchars($value);
    
    return $value;
}

function f_data_int($value_is_int)
{
	if(filter_var($value_is_int, FILTER_VALIDATE_INT) !== FALSE)
	{
		return true;
	} else
	{
		return false;
	}
}