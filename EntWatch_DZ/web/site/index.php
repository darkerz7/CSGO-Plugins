<?php
require_once('protect.php');
require_once('steamid.php');
require_once('connect.php');

function declension($digit,$expr,$onlyword=false)
{
	    if(!is_array($expr)) $expr = array_filter(explode(' ', $expr));
	    if(empty($expr[2])) $expr[2]=$expr[1];
	    $i=preg_replace('/[^0-9]+/s','',$digit)%100;
	    if($onlyword) $digit='';
	    if($i>=5 && $i<=20) $res=$digit.' '.$expr[2];
	    else
	    {
	        $i%=10;
	        if($i==1) $res=$digit.' '.$expr[0];
	        elseif($i>=2 && $i<=4) $res=$digit.' '.$expr[1];
	        else $res=$digit.' '.$expr[2];
	    }
	    return trim($res);
}

function duration_string($input_duration)
{
	if($input_duration<0)
	{
		$return_duration = "Invalid Time";
		return $return_duration;
	} elseif($input_duration==0)
	{
		$return_duration = "Permanent";
		return $return_duration;
	} else
	{
		$count_week = floor($input_duration/10080);
		$count_days = floor(($input_duration%10080)/1440);
		$count_hours = floor(($input_duration%1440)/60);
		$count_minutes = floor($input_duration%60);
		$return_duration='';
		if($count_week>0) $return_duration.= declension($count_week,array('<span key_phrase="Week_1" class="lang">Week</span>','<span key_phrase="Week_2" class="lang">Weeks</span>','<span key_phrase="Week_3" class="lang">Weeks</span>')).' ';
		if($count_days>0) $return_duration.= declension($count_days,array('<span key_phrase="Day_1" class="lang">Day</span>','<span key_phrase="Day_2" class="lang">Days</span>','<span key_phrase="Day_3" class="lang">Days</span>')).' ';
		if($count_hours>0) $return_duration.= declension($count_hours,array('<span key_phrase="Hour_1" class="lang">Hour</span>','<span key_phrase="Hour_2" class="lang">Hours</span>','<span key_phrase="Hour_3" class="lang">Hours</span>')).' ';
		if($count_minutes>0) $return_duration.= declension($count_minutes,array('<span key_phrase="Minute_1" class="lang">Minute</span>','<span key_phrase="Minute_2" class="lang">Minutes</span>','<span key_phrase="Minute_3" class="lang">Minutes</span>')).' ';
		return $return_duration;
	}
}
?>

<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<title>List of Ebans</title>
		<link rel="stylesheet" href="css/main.css">
		<script src="jquery.1.11.3.js"></script>
		<script src="lang.js"></script>
	</head>
	<body onload="var lang = localStorage.getItem('lang') || 'en'; SetLang(lang);">
		<div class="desktop">
			<nav class="navbar">
				<div class="navbar-container">
					<div class="navbar-left">
						<a key_phrase="EBan List Link" class="lang" href="./?page=1">EBan List</a>
						<a key_phrase="Go Back Link" class="lang" href="https://google.com">Go Back</a>
					</div>
					<div class="navbar-right">
						<a class="navbar-lang" onclick="SetLang('en'); localStorage.setItem('lang', 'en');" href="#">ENG</a>
						<a class="navbar-lang" onclick="SetLang('ru'); localStorage.setItem('lang', 'ru');" href="#">RUS</a>
						<form class="navbar-form" method="get">
							<input type="text" name="search" placeholder="SteamID" class="navbar-input">
							<button type="submit" key_phrase="Find" class="navbar-btn lang">Find</button>
						</form>
					</div>
				</div>
			</nav>
			<div class="data">
				<?php
				if($search_state == 1)
				{
					echo '<p key_phrase="Steam Wrong" class="data_search_state_error lang">SteamID is in the wrong format. Supported formats: STEAM_1:0:123456789 and [U:1:123456789]</p>';	
				}elseif($search_state == 2)
				{
					echo '<p class="data_search_state_found"><span key_phrase="Search Results" class="lang">Search Results:</span> '.$buff_steamid.'</p>';
				}
				?>
				<table class="data-eban-table">
					<thead>
						<tr>
							<td key_phrase="Server" class="lang">Server</td>
							<td key_phrase="Player" class="data-eban-center lang">Player</td>
							<td key_phrase="Reason" class="lang">Reason</td>
							<td key_phrase="Admin" class="data-eban-center lang">Admin</td>
							<td key_phrase="Duration" class="lang">Duration</td>
						</tr>
					</thead>
					<tbody>
					<?php foreach ($rows_alldata as $row)
						{
							$data_server = f_clean_data($row["server"]);
							$data_client_name = f_clean_data($row["client_name"]);
							$data_client_steamid = f_clean_data($row["client_steamid"]);
							$data_admin_name = f_clean_data($row["admin_name"]);
							$data_admin_steamid = f_clean_data($row["admin_steamid"]);
							$data_duration = f_clean_data($row["duration"]);
							$data_issued = f_clean_data($row["timestamp_issued"]);
							$data_reason = f_clean_data($row["reason"]);
							$data_unban_admin_name = f_clean_data($row["admin_name_unban"]);
							$data_unban_admin_steamid = f_clean_data($row["admin_steamid_unban"]);
							$data_unban_reason = f_clean_data($row["reason_unban"]);
							$data_unban_time = f_clean_data($row["timestamp_unban"]);
							echo '<tr class="';
							if($data_duration == 0 && $data_unban_admin_steamid == ""){
								echo 'data-eban-permanent" eban-data="Issued: Never">';
							} elseif($data_unban_admin_steamid != ""){
								echo 'data-eban-expired" eban-data="Removed: '.date('m-d-Y H:i:s', $data_unban_time).' Unbanned by: '.$data_admin_name.' ('.$data_admin_steamid.') Reason: '.$data_unban_reason.'">';
							} else {
								echo 'data-eban-active" eban-data="Issued: '.date('m-d-Y H:i:s', $data_issued).'">';
							}
							echo '<td>'.$data_server.'</td>
							<td class="data-eban-center">'.$data_client_name.'<br>(<span class="data-eban-steamid">'.$data_client_steamid.'</span>)</td>
							<td>'.$data_reason.'</td>
							<td class="data-eban-center">'.$data_admin_name.'<br>(<span class="data-eban-steamid">'.$data_admin_steamid.'</span>)</td>
							<td class="';
							if($data_duration == 0 && $data_unban_admin_steamid == ""){
								echo 'data-eban-permanent-duration lang" key_phrase="Permanent">Permanent</td>';
							} elseif($data_unban_admin_steamid != ""){
								if($data_duration == 0){
									echo 'data-eban-expired-duration lang" key_phrase="Permanent Removed">Permanent(Removed)';
								}elseif($data_unban_admin_steamid == "SERVER")
								{
									echo 'data-eban-expired-duration">'.duration_string($data_duration).'(<span key_phrase="Expired" class="lang">Expired</span>)';
								}else
								{
									echo 'data-eban-expired-duration">'.duration_string($data_duration).'(<span key_phrase="Removed" class="lang">Removed</span>)';
								}
								echo '</td>';
							} else {
								echo 'data-eban-active-duration">'.duration_string($data_duration).'</td>';
							}
						echo'</tr>';
						}?>
				  </tbody>
				</table>
				<div class="data-pages">
					<?php
					if($num_pages<=1) 
					{
						echo '<a class="current-page" href="?page=1">1</a>';
					}else
					{
						for ($i = 1; $i <= $num_pages; $i++)
						{
							if($i==1||($i==$num_pages && $num_pages!=1))
							{
								if($i==$cur_page)
								{
									echo '<a class="current-page" href="?page='.$i.'">'.$i.'</a>';
								}else
								{
									echo '<a href="?page='.$i.'">'.$i.'</a>';
								}
								continue;
							}
							if($i==$cur_page)
							{
								echo '<a class="current-page" href="?page='.$i.'">'.$i.'</a>';
							}
							if($i-1==$cur_page && $i-1>=1)
							{
								echo '<a href="?page='.$i.'">'.$i.'</a>';
							}
							if($i+1==$cur_page && $i+1<=$num_pages)
							{
								echo '<a href="?page='.$i.'">'.$i.'</a>';
							}
							if($i-2==$cur_page && $i-2>=1)
							{
								echo '<a href="#">...</a>';
							}
							if($i+2==$cur_page && $i+2<=$num_pages)
							{
								echo '<a href="#">...</a>';
							}
						}
					}
					?>
				</div>
			</div>
		</div>
		<div class="mobile">
			<nav class="mobile-navbar">
				<p>
					<a key_phrase="EBan List Link" class="lang mobile-navbar-link" href="./?page=1">EBan List</a>
					<a key_phrase="Go Back Link" class="lang mobile-navbar-link" href="https://google.com">Go Back</a>
				</p>
				<p>
					<a class="navbar-lang" onclick="SetLang('en'); localStorage.setItem('lang', 'en');" href="#">ENG</a>
					<a class="navbar-lang" onclick="SetLang('ru'); localStorage.setItem('lang', 'ru');" href="#">RUS</a>
				</p>
				<form method="get">
						<input type="text" name="search" placeholder="SteamID" class="mobile-navbar-input">
						<button type="submit" key_phrase="Find" class="mobile-navbar-btn lang">Find</button>
				</form>
			</nav>
			<div class="mobile-data">
				<?php
				if($search_state == 1)
				{
					echo '<p key_phrase="Steam Wrong" class="mobile-data_search_state_error lang">SteamID is in the wrong format. Supported formats: STEAM_1:0:123456789 and [U:1:123456789]</p>';	
				}elseif($search_state == 2)
				{
					echo '<p class="mobile-data_search_state_found"><span key_phrase="Search Results" class="lang">Search Results:</span> '.$buff_steamid.'</p>';
				}
				?>
				
				<?php foreach ($rows_alldata as $row)
					{
						$data_server = f_clean_data($row["server"]);
						$data_client_name = f_clean_data($row["client_name"]);
						$data_client_steamid = f_clean_data($row["client_steamid"]);
						$data_admin_name = f_clean_data($row["admin_name"]);
						$data_admin_steamid = f_clean_data($row["admin_steamid"]);
						$data_duration = f_clean_data($row["duration"]);
						$data_issued = f_clean_data($row["timestamp_issued"]);
						$data_reason = f_clean_data($row["reason"]);
						$data_unban_admin_name = f_clean_data($row["admin_name_unban"]);
						$data_unban_admin_steamid = f_clean_data($row["admin_steamid_unban"]);
						$data_unban_reason = f_clean_data($row["reason_unban"]);
						$data_unban_time = f_clean_data($row["timestamp_unban"]);
						
						echo '<div class="modile-data-block">';
							echo '<div class="mobile-data-main"><div key_phrase="Server" class="mobile-data-left lang">Server</div><div class="mobile-data-right">'.$data_server.'</div></div>';
							echo '<div class="mobile-data-main"><div key_phrase="Player" class="mobile-data-left lang">Player</div><div class="mobile-data-right">'.$data_client_name.' (<span class="data-eban-steamid">'.$data_client_steamid.'</span>)</div></div>';
							echo '<div class="mobile-data-main"><div key_phrase="Reason" class="mobile-data-left lang">Reason</div><div class="mobile-data-right">'.$data_reason.'</div></div>';
							echo '<div class="mobile-data-main"><div key_phrase="Admin" class="mobile-data-left lang">Admin</div><div class="mobile-data-right">'.$data_admin_name.' (<span class="data-eban-steamid">'.$data_admin_steamid.'</span>)</div></div>';
							echo '<div class="mobile-data-main"><div key_phrase="Duration" class="mobile-data-left lang">Duration</div><div class="mobile-data-right';
							if($data_duration == 0 && $data_unban_admin_steamid == ""){
								echo ' lang" key_phrase="Permanent">Permanent';
							} elseif($data_unban_admin_steamid != ""){
								if($data_duration == 0){
									echo ' lang" key_phrase="Permanent Removed">Permanent(Removed)';
								}elseif($data_unban_admin_steamid == "SERVER")
								{
									echo '">'.duration_string($data_duration).'(<span key_phrase="Expired" class="lang">Expired</span>)';
								}else
								{
									echo '">'.duration_string($data_duration).'(<span key_phrase="Removed" class="lang">Removed</span>)';
								}
							} else {
								echo '">'.duration_string($data_duration);
							}
							echo '</div></div>';
							if($data_duration == 0 && $data_unban_admin_steamid == ""){
								echo '<div class="mobile-data-secondary-permanent"><div key_phrase="Issued" class="mobile-data-left lang">Issued:</div><div key_phrase="Never" class="mobile-data-right lang">Never</div></div>';
							} elseif($data_unban_admin_steamid != ""){
								echo '<div class="mobile-data-secondary-expired"><div key_phrase="Removed_2" class="mobile-data-left lang">Removed:</div><div class="mobile-data-right">'.date('m-d-Y H:i:s', $data_unban_time).'</div></div>';
								echo '<div class="mobile-data-secondary-expired"><div key_phrase="Unbanned by" class="mobile-data-left lang">Unbanned by:</div><div class="mobile-data-right">'.$data_admin_name.' (<span class="data-eban-steamid">'.$data_admin_steamid.'</span>)</div></div>';
								echo '<div class="mobile-data-secondary-expired"><div key_phrase="Reason_2" class="mobile-data-left lang">Reason:</div><div class="mobile-data-right">'.$data_unban_reason.'</div></div>';
							} else {
								echo '<div class="mobile-data-secondary-active"><div key_phrase="Issued" class="mobile-data-left lang">Issued:</div><div class="mobile-data-right">'.date('m-d-Y H:i:s', $data_issued).'</div></div>';
							}
						echo '</div>';
						
					}?>

				<div class="mobile-data-pages">
					<?php
					if($num_pages<=1) 
					{
						echo '<a class="current-page" href="?page=1">1</a>';
					}else
					{
						for ($i = 1; $i <= $num_pages; $i++)
						{
							if($i==1||($i==$num_pages && $num_pages!=1))
							{
								if($i==$cur_page)
								{
									echo '<a class="current-page" href="?page='.$i.'">'.$i.'</a>';
								}else
								{
									echo '<a href="?page='.$i.'">'.$i.'</a>';
								}
								continue;
							}
							if($i==$cur_page)
							{
								echo '<a class="current-page" href="?page='.$i.'">'.$i.'</a>';
							}
							if($i-1==$cur_page && $i-1>=1)
							{
								echo '<a href="?page='.$i.'">'.$i.'</a>';
							}
							if($i+1==$cur_page && $i+1<=$num_pages)
							{
								echo '<a href="?page='.$i.'">'.$i.'</a>';
							}
							if($i-2==$cur_page && $i-2>=1)
							{
								echo '<a href="#">...</a>';
							}
							if($i+2==$cur_page && $i+2<=$num_pages)
							{
								echo '<a href="#">...</a>';
							}
						}
					}
					?>
				</div>
			</div>
		</div>
	</body>
</html>