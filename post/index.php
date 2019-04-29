<?php

foreach ($_FILES as $file) {
  if (!copy($file['tmp_name'], "/Users/ku/www/post/tmp/".$file['name'])) {
    echo ("failed to copy ...\n". $file['tmp_name']. $file['name']);
    print_r(error_get_last());
  }
}

$ids = [0];

if ($handle = opendir('./tmp/')) {
  while (false !== ($entry = readdir($handle))) {
    preg_match('/(\d{3})\D+(\d{5}).JPG$/', $entry, $m);
    if ($m) {
      $n = (int)($m[1] . $m[2]);
      array_push($ids, $n);
    }
  }
}
print max($ids);
