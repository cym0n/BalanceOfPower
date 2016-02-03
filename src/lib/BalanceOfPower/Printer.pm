package BalanceOfPower::Printer;

use Template;
use Cwd 'abs_path';

sub print
{
    my $mode = shift;
    my $template = shift;
    my $vars = shift;

    my $module_file_path = __FILE__;
    my $root_path = abs_path($module_file_path);
    $root_path =~ s/Printer\.pm//;
    $root_path .= "templates";

    my $tt = Template->new({INCLUDE_PATH => $root_path,
                            PLUGIN_BASE => 'Template::Plugin::Filter'});
    my $output;
    $tt->process("$mode/$template.tt", $vars, \$output) || die $tt->error . "\n";
    return $output;
}

1;

