<?php
require_once('protect.php');
require_once('steamid.php');

$host 	= 'localhost';
$db 	= 'entwatch';
$user 	= 'root';
$pass 	= 'pass';
$charset = 'utf8';

$per_page = 20;

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
    $opt = [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ];
$conn = new PDO($dsn, $user, $pass, $opt);

$cur_page = 1;

if(isset($_GET['page']))
{
	$buff_cur_page = f_clean_data($_GET['page']);
	if(f_data_int($buff_cur_page)) 
	{
		$cur_page = $buff_cur_page;
	}
}

$searchby_steamid = false;
$search_state = 0;

$buff_steamid = "";

if(isset($_GET['search']))
{
	$buff_steamid = f_clean_data($_GET['search']);
	if($buff_steamid != "")
	{
		$search_state = 1;
		if(st32isvalid($buff_steamid))
		{
			$search_state = 2;
			$searchby_steamid = true;
		}elseif(st3to32($buff_steamid)!=false)
		{
			$search_state = 2;
			$buff_steamid = st3to32($buff_steamid);
			$searchby_steamid = true;
		}
	}
}

if($searchby_steamid == true)
{
	$countsql = $conn->prepare('SELECT count(*) as cr FROM ((SELECT * FROM EntWatch_Current_Eban WHERE client_steamid="'.$buff_steamid.'") UNION ALL (SELECT * FROM EntWatch_Old_Eban WHERE client_steamid="'.$buff_steamid.'")) counteban');
	$countsql->execute();
} else
{
	$countsql = $conn->prepare('SELECT count(*) as cr FROM ((SELECT * FROM EntWatch_Current_Eban) UNION ALL (SELECT * FROM EntWatch_Old_Eban)) counteban');
	$countsql->execute();
}

$countrow = $countsql->fetch();
$countint = $countrow['cr'];
$num_pages = ceil($countint / $per_page);
if($cur_page>$num_pages) $cur_page=$num_pages;
if($cur_page<1) $cur_page=1;

$start = ($cur_page - 1) * $per_page;

if($searchby_steamid == true)
{
	$sql = $conn->prepare('(SELECT * FROM EntWatch_Current_Eban WHERE client_steamid="'.$buff_steamid.'") UNION ALL (SELECT * FROM EntWatch_Old_Eban WHERE client_steamid="'.$buff_steamid.'") ORDER BY id DESC LIMIT :start, :perpage');
	$sql->execute(array(':start' => $start, ':perpage' => $per_page));
} else
{
	$sql = $conn->prepare('(SELECT * FROM EntWatch_Current_Eban) UNION ALL (SELECT * FROM EntWatch_Old_Eban) ORDER BY id DESC LIMIT :start, :perpage');
	$sql->execute(array(':start' => $start, ':perpage' => $per_page));
}

$rows_alldata = $sql->fetchAll();

$conn = null;