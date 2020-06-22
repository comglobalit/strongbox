<?php

/* Rotates, crops, and displays face images previously selected by Strongbox plugin */


/* Desired size of face thumbnails, when fully expanded. */
$target_width = 100;
$target_height = 120;

##############################

# TODO
# Add caching of rotated images, mix with fresh ones.

if ( file_exists($_SERVER['DOCUMENT_ROOT'] . '/cgi-bin/sblogin/.htcookie') ) {
    $sessionfiles = $_SERVER['DOCUMENT_ROOT'] . '/cgi-bin/sblogin/.htcookie';
} else {
   $sessionfiles = $_SERVER['DOCUMENT_ROOT'] . '/../cgi-bin/sblogin/.htcookie';
}


include ('./largest.php');

if ( !function_exists( 'imagerotate' ) ) {
    function imagerotate( $source_image, $angle, $bgd_color ) {
        $angle = 360-$angle; // GD rotates CCW, imagick rotates CW
        $temp_src = '/tmp/temp_src_' . uniqid() .'.png';
        $temp_dst = '/tmp/temp_dst_' . uniqid() .'.png';
        if (!imagepng($source_image,$temp_src)){
            return false;
        }
        $imagick = new Imagick();
        $imagick->readImage($temp_src);
        $imagick->rotateImage(new ImagickPixel($bgd_color?$bgd_color:'black'), $angle);
        $imagick->writeImage($temp_dst);
        $result = imagecreatefrompng($temp_dst);
        unlink($temp_dst);
        unlink($temp_src);
        return $result;
    }
}


function cropoptimal($imgoriginal, $imgrotated, $angle, $target_width, $target_height) {
    $tallest = getLargestRectangle(imagesx($imgoriginal), imagesy($imgoriginal), $angle, 3);
    $new_width;
    $new_height;
    $imgcropped = imagecreatetruecolor($target_width, $target_height);
    imagecopyresampled($imgcropped, $imgrotated, 
                       0, 0, $tallest->x, $tallest->y, 
                       $target_width, $target_height, $tallest->width, $tallest->height
                     );
    return $imgcropped;
}


function rotateimage($img,$target_width, $target_height) {
    $angle = rand(5,50);
    if ( rand(0,1) ) {
        $angle = 360 - $angle;
    }
    $rotated = imagerotate($img, 360 - $angle, 0);
    return cropoptimal($img, $rotated, $angle, $target_width, $target_height);
}


function getpicfilename($ctid, $ctpicnum) {
    global $sessionfiles;
    $selected_files = file("$sessionfiles/chickcaptcha/$ctid.txt", FILE_IGNORE_NEW_LINES);
    return $selected_files[$ctpicnum + 1];
}


/* Rotates, crops, and displays face images previously selected by Strongbox plugin */

if ( preg_match('/^[a-z0-9]+$/i', $_REQUEST['ctid']) && preg_match('/^[0-9]+$/', $_REQUEST['ctpicnum']) ) {
    $imgfile = getpicfilename($_REQUEST['ctid'], $_REQUEST['ctpicnum']);
    if ( empty($imgfile) ) {
        error_log ("image file not set for " . $_REQUEST['ctid']);
        exit;
    }

    header("Content-type: image/png");
    $img     = imagecreatefromjpeg($imgfile);
    $rotated = rotateimage($img, $target_width, $target_height);
    imagedestroy($img);
    imagepng($rotated);
    imagedestroy($rotated);
}

?>
