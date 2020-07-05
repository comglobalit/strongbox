<?php
/*
Plugin Name: Strongbox: Absolute Relative Links sb2
Version: 1.2
Description: Use non-Fully Qualified URLs in your site, <a href="https://github.com/comglobalit/strongbox/wiki/Strongbox-Technical-Requirements">technical requirement</a> for <a href="https://www.comglobalit.com/en/strongbox/">Strongbox</a>-protected websites.
Author: Strongbox team 
Author URI: https://github.com/comglobalit/strongbox
Tags: Strongbox, relative link
License: GPL3
*/

/* To disable, remove the following asterisk: */
update_option('gzipcompression', 0);
remove_filter('template_redirect', 'redirect_canonical');
add_filter( 'allowed_redirect_hosts', 'sb_allowed_redirect_hosts', 10 );
add_filter( 'the_content', 'sb_relative_links', 10 );
add_filter( 'post_link', 'sb_decanonicalize_siteurl', 10 );
add_filter( 'option_siteurl', 'sb_decanonicalize_siteurl', 10 );
add_filter( 'the_permalink', 'sb_relative_links' , 10 );
add_filter('wp_get_attachment_link', 'sb_decanonicalize_siteurl', 10 );
/* */


function sb_decanonicalize_siteurl($url){
    $rel_host = preg_replace( '/^sb[0-9a-z]*\./i' , '', $_SERVER['HTTP_HOST']);
    $rel_host = preg_replace( '/^www\./i' , '', $rel_host);
    $rel_host = preg_replace( '/^members\./i' , '', $rel_host);
    $url = preg_replace("/\/\/sb[0-9a-z]*\.$rel_host/i", '//' . $_SERVER['HTTP_HOST'], $url);
    $url = preg_replace("/\/\/www\.$rel_host/i", '//' . $_SERVER['HTTP_HOST'], $url);
    $url = preg_replace("/\/\/$rel_host/i", '//' . $_SERVER['HTTP_HOST'], $url);
    $out  = str_replace(home_url(''), '', $out);
    return $url;
}


function sb_allowed_redirect_hosts($content, $trying=''){
    $content[] = $_SERVER['HTTP_HOST'];
    $content[] = $trying;
    return $content;
}

function sb_relative_links($in) {
    $rel_host = preg_replace( '/^sb[0-9a-z]*\./i' , '', $_SERVER['HTTP_HOST']);
    $rel_host = preg_replace( '/^www\./i' , '', $rel_host);
    $out = str_replace("https?://sb[0-9a-z]*\.$rel_host/i" , '/', $in);
    $out = str_replace("https?://$rel_host/" , '/', $out);
    $out  = str_replace("https?://www.$rel_host/" , '/', $out);
    $nonmembers_host = preg_replace( '/^members\./i' , '', $rel_host);
    $out = str_replace("https?://$nonmembers_host/" , '/', $out);
    $out  = str_replace("https?://www.$nonmembers_host/" , '/', $out);
    return $out;
}

// The visual editor and this filter don't get along
if((!strstr($_SERVER['REQUEST_URI'], '/wp-admin')) && (!$feed)) ob_start('sb_relative_links'); // do not filter in feeds or in admin section
