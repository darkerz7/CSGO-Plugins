<?php
function st32isvalid($steamid32)
{
	if (preg_match('/^STEAM_1\:*\:(.*)$/', $steamid32, $res))
	{
		return true;
	}
	return false;
}

function st3to32($steamid3)
{
    if (preg_match("/\[U:1:(\d+)\]/", $steamid3))
	{
        $steam3 = preg_replace("/\[U:1:(\d+)\]/", "$1", $steamid3);
        $A = $steam3 % 2;
        $B = intval($steam3 / 2);
        return "STEAM_1:" . $A . ":" . $B;
    }
    return false;
}