<?php 
$base = fopen('protein.csv', 'r');
$check = fopen($argv[1], 'r');

$listbase = array();
while(!feof($base)){
    $file = fgetcsv($base);
    $row = array($file[0],$file[1],$file[2]);
    if($file[0] != '')
        array_push($listbase,$row);
}
fclose($base);

$listdata = array();
$true = 0;
while(!feof($check)){
    $file = fgetcsv($check);
    $row = array($file[0],$file[1],$file[2]);
    if($file[0] != '')
        array_push($listdata,$row);
    if(in_array($row,$listbase))
        $true++;
}
fclose($check);
    $persen = $true/count($listdata) * 100;
    echo $persen.' %';
?>