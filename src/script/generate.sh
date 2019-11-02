GAME=$1;
YEARS=$2;

PERL5LIB=$PERL5LIB:/home/cymon/projects/nations/src/lib BOP_SITE_ROOT=/home/cymon/projects/nations-web/templates BOP_WEBSITE=site ./bop-perl webgen $GAME --years=$YEARS --noserver
