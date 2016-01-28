#!perl

my $pgm = 'delta';
my $tempdir = $ENV{TEMP}.'/'.$pgm; mkdir $tempdir unless -d $tempdir;

use Brewed::Capture qw($convert);
use Brewed::PERMA qw(basen flush);

my $set = 'dataset';
my $setdir = sprintf '.\%s',$set; 
print "// $setdir\n";

# ----------------------------------------------------
# important : no space in output filenames ...
my $fdir = sprintf '%s/%s',$tempdir,$set;
rmdir $fdir or unlink $fdir;
system sprintf 'junction.exe "%s" "%s"',$fdir,$setdir;
#mkdir $fdir unless -d $fdir;
# ----------------------------------------------------
my $ppmdir = $fdir.'\ppm'; mkdir $ppmdir unless -d $ppmdir;
my $xordir = $fdir.'\xor'; mkdir $xordir unless -d $xordir;

use PDL;

opendir D,$setdir; my @content = grep /\.jpg/, readdir(D); closedir D;

my $pimage = byte zeroes(640,480);
foreach my $filename (@content) {
  $file = $setdir.'\\'.$filename;
  my ($fpath,$basen,$ext) = &basen($file);
  $basen =~ s/ /_/g; # remove spaces !


# ---------------------------------------------
# convert to portable image
my $ppmfile = sprintf '%s/%s.ppm',$ppmdir,$basen;
if (! -e $ppmfile) {
 system sprintf $convert,'',$ppmfile,$file; # /!\ new order ...
}
# ---------------------------------------------

my $yc = pdl( [.299,.587,.114] ); # primaries sensitivity coefficients ...
my $pic = rpic($ppmfile);
our $ppm = inner($yc,$pic);
($xsize, $ysize) = dims($ppm);
printf "// %s: %ux%u\n",$basen,$xsize,$ysize;
printf "ppm: %s\n", $ppm->info;


my $image = byte($ppm);
# smoother the image first ...
use PDL::ImageND;
# guassian filter ...
#
# g(x) = 1/sqrt(2pi).s e(-(x^2/2s^2))
my $sigma = 10;
my $radius = 6 * $sigma;
my $kernel = exp(-(rvals($radius)**2/(2*$sigma**2)));
#plot $kernel;
$kernel /= $kernel->sumover;
$smoothed = $image->convolveND($kernel);


my $xor = $smoothed ^ $pimage;
my $xfile = sprintf'%s/%s.jpg',$xordir,$basen;
wpic($xor,$xfile);

$pimage = $smoothed;

}

1;
