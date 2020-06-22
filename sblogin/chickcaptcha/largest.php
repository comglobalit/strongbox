<?php

/*
*   Find largest  vertically aligned rectangle contained within rotated image.
*   Largest rectangle code partially based on Java code by Rolf Lawrenz
*/


function intersect($line1, $line2) {
    list ($p1x,$p1y, $p2x,$p2y) = $line1;
    list ($p3x,$p3y, $p4x,$p4y) = $line2;

    $v1x = $p2x - $p1x;
    $v1y = $p2y - $p1y;
    $v2x = $p4x - $p3x;
    $v2y = $p4y - $p3y;

    $d = $v1x * $v2y - $v1y * $v2x;
    if (! $d)
    {
        //points are collinear
        return null;
    }

    $a = $p3x - $p1x;
    $b = $p3y - $p1y;
    $t = ($a * $v2y - $b * $v2x) / $d;
    $s = ($b * $v1x - $a * $v1y) / (-1 * $d);
    if ($t < 0 || $t > 1 || $s < 0 || $s > 1) {
        //line segments don't intersect
        return null;
    }
    $x = $p1x + ($v1x * $t);
    $y = $p1y + ($v1y * $t);
    return array($x,$y);
}  
/**
  * Return a largest Rectangle that will fit in a rotated image
  * @param $imgWidth Width of image
  * @param $imgHeight Height of Image
  * @param rotAngDeg Rotation angle in degrees
  * @param type 0 = Largest Area, 1 = Smallest Area, 2 = Widest, 3 = Tallest
  * @return
  */
 function getLargestRectangle($imageWidth, $imageHeight, $rotAngDeg, $type) {
  global $debug;
  # Rectangle $rect = null;
   
  // $rotateAngleDeg = $rotAngDeg % 180;
  $rotateAngleDeg = $rotAngDeg;
  if ($rotateAngleDeg < 0) {
   $rotateAngleDeg += 360;
   // $rotateAngleDeg = $rotateAngleDeg % 180;
  }
  $imgWidth = $imageWidth;
  $imgHeight = $imageHeight;
   
  if ($rotateAngleDeg == 0 || $rotateAngleDeg == 180) {
   // Angle is 0. No change needed
   $rect = new Rectangle(0,0,floor($imgWidth),floor($imgHeight));
   return $rect;
  }
   
  if ($rotateAngleDeg == 90) {
   // Angle is 90. Width and height swapped
   $rect = new Rectangle(0,0,floor($imgHeight),floor($imgWidth));
   return $rect;
  }
 
  if ($debug) {
      echo "rotateAngleDeg: $rotateAngleDeg\n";
  }
  $rotateAngle = deg2rad($rotateAngleDeg);
  $sinRotAng = sin($rotateAngle);
  $cosRotAng = cos($rotateAngle);
  $tanRotAng = tan($rotateAngle);
  // Point 1 of rotated $rectangle
  $x1 = abs($sinRotAng * $imgHeight);
  $y1 = 0;
  // Point 2 of rotated $rectangle
  $x2 = $cosRotAng * $imgWidth + $x1;
  $y2 = abs($sinRotAng * $imgWidth);
  // Point 3 of rotated $rectangle
  $x3 = $x2 - $x1;
  $y3 = $y2 + $cosRotAng * $imgHeight;
  // Point 4 of rotated $rectangle
  $x4 = 0;
  $y4 = $cosRotAng * $imgHeight;

  // MidPoint of rotated image
  $midx = $x2 / 2;
  $midy = $y3 / 2;
   
  if ($debug) {
      echo "correct rotated rectangle: $x1,$y1 $x2,$y2 $x3,$y3 $x4,$y4\n";
      echo "'correct MidPoint of rotated image': $midx,$midy\n";
  }

  $line1 = array(0,0, $midx, $midy);
  $line2 = array($x2,0, $midx, $midy);
  $side1 = array($x4, $y4, $x1,$y1);
  $side2 = array($x1,$y1, $x2,$y2);

  list ($ix1, $iy1) = intersect($line1, $side1);
  list ($ix2, $iy2) = intersect($line2, $side2);

  // Work out smallest $rectangle
  $radx1 = abs($midx - $ix1);
  $rady1 = abs($midy - $iy1);
  $radx2 = abs($midx - $ix2);
  $rady2 = abs($midy - $iy2);
  // Work out $area of $rectangles
  $area1 = $radx1 * $rady1;
  $area2 = $radx2 * $rady2;
  
  // Rectangle (x,y,width,height)
  $rect1 = new Rectangle(round($midx - $radx1),round($midy - $rady1), round($radx1 * 2),round($rady1 * 2));
   
  // Rectangle (x,y,width,height)
  $rect2 = new Rectangle(round($midx - $radx2),round($midy - $rady2), round($radx2 * 2),round($rady2 * 2));

  switch ($type) {
   case 0: $rect = ($area1 > $area2 ? $rect1 : $rect2); break;
   case 1: $rect = ($area1 < $area2 ? $rect1 : $rect2); break;
   case 2: $rect = ($radx1 > $radx2 ? $rect1 : $rect2); break;
   case 3: $rect = ($rady1 > $rady2 ? $rect1 : $rect2); break;
  }
  // return $rect1;
  return $rect;
 }



  class Rectangle {
    public $height;
    public $width;
   
    public function __construct($x, $y, $width, $height) {
      $this->x = $x;
      $this->y = $y;
      $this->width = $width;
      $this->height = $height;
     }
    
     public function getArea() {
      return $this->height * $this->width;
     }
   }

  class Square extends Rectangle {
    public function __construct($size) {
      $this->height = $size;
      $this->width = $size;
    }
   
    public function getArea() {
      return pow($this->height, 2);
    }
   
  }

?>
