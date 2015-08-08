package BalanceOfPower::Constants;

use strict;

use base 'Exporter';

use constant MIN_EXPORT_QUOTE => 30;
use constant MAX_EXPORT_QUOTE => 60;
use constant MIN_STARTING_TRADEROUTES => 1;
use constant MAX_STARTING_TRADEROUTES => 5;
use constant ADDING_TRADEROUTE_COST => 30;
use constant MIN_TRADEROUTE_GAIN => 2;
use constant MAX_TRADEROUTE_GAIN => 4;
use constant MIN_DELTA_PRODUCTION => -20;
use constant MAX_DELTA_PRODUCTION => 20;
use constant MAX_PRODUCTION => 180;
use constant MIN_STARTING_PRODUCTION => 50;
use constant MAX_STARTING_PRODUCTION => 100;
use constant INTERNAL_PRODUCTION_GAIN => 1;
use constant TRADING_QUOTE => 15;
use constant TRADINGROUTE_COST => 10;
use constant POVERTY_LIMIT => 80;
use constant INTERNAL_DISORDER_VARIATION_FACTOR => 4;
use constant RICHNESS_LIMIT => 110;
use constant INTERNAL_DISORDER_TERRORISM_LIMIT => 10;
use constant INTERNAL_DISORDER_INSURGENCE_LIMIT => 40;
use constant INTERNAL_DISORDER_CIVIL_WAR_LIMIT => 80;
use constant MIN_ADDED_DISORDER => -2;
use constant MAX_ADDED_DISORDER => 2;
use constant WORRYING_LIMIT => 30;
use constant DOMESTIC_BUDGET => 50;
use constant RESOURCES_FOR_DISORDER => 20;
use constant DISORDER_REDUCTION => 10;
use constant MIN_GOVERNMENT_STRENGTH => 50;
use constant MAX_GOVERNMENT_STRENGTH => 100;
use constant DEBT_ALLOWED => 0;
use constant DEBT_TO_RAISE_LIMIT => 50;
use constant PRODUCTION_THROUGH_DEBT => 40;
use constant MAX_DEBT => 3;
use constant CIVIL_WAR_WIN => 3;
use constant AFTER_CIVIL_WAR_INTERNAL_DISORDER => 35;
use constant TURNS_FOR_YEAR => 4;
use constant HATE_LIMIT => 30;
use constant LOVE_LIMIT => 70;
use constant MINIMUM_ARMY_LIMIT => 5;
use constant MEDIUM_ARMY_LIMIT => 10;
use constant MAX_ARMY_LIMIT => 15;
use constant MEDIUM_ARMY_BUDGET => 40;
use constant MAX_ARMY_BUDGET => 60;
use constant ARMY_COST => 20;
use constant ARMY_UNIT => 1;
use constant ARMY_FOR_BATTLE => 3;
use constant TRADEROUTE_DIPLOMACY_FACTOR => 10;
use constant ARMY_UNIT_FOR_INTERNAL_DISORDER => 2;
use constant ARMY_HELP_FOR_INTERNAL_DISORDER => 10;
use constant CRISIS_GENERATION_TRIES => 5;
use constant CRISIS_GENERATOR_NOACTION_TOKENS => 6;
use constant CRISIS_MAX_FACTOR => 3;
use constant MIN_ARMY_FOR_WAR => 5;
use constant MIN_INFERIOR_ARMY_RATIO_FOR_WAR => 1.2;
use constant WAR_WEALTH_MALUS => 20;
use constant ATTACK_FAILED_PRODUCTION_MALUS => 40;
use constant AFTER_CONQUERED_INTERNAL_DISORDER => 30;
use constant CONQUEROR_LOOT_BY_TYPE => 20;
use constant CONQUEST_CLOCK_LIMIT => 5;

our @EXPORT_OK = ('MIN_EXPORT_QUOTE', 
                  'MAX_EXPORT_QUOTE',
                  'MIN_STARTING_TRADEROUTES',
                  'MAX_STARTING_TRADEROUTES',
                  'ADDING_TRADEROUTE_COST',
                  'MIN_TRADEROUTE_GAIN',
                  'MAX_TRADEROUTE_GAIN',
                  'MIN_DELTA_PRODUCTION',
                  'MAX_DELTA_PRODUCTION',
                  'MAX_PRODUCTION',
                  'MIN_STARTING_PRODUCTION',
                  'MAX_STARTING_PRODUCTION',
                  'INTERNAL_PRODUCTION_GAIN',
                  'TRADING_QUOTE',
                  'TRADINGROUTE_COST',
                  'POVERTY_LIMIT',
                  'RICHNESS_LIMIT',
                  'INTERNAL_DISORDER_VARIATION_FACTOR',
                  'INTERNAL_DISORDER_TERRORISM_LIMIT',
                  'INTERNAL_DISORDER_INSURGENCE_LIMIT',
                  'INTERNAL_DISORDER_CIVIL_WAR_LIMIT',
                  'MIN_ADDED_DISORDER',
                  'MAX_ADDED_DISORDER',
                  'WORRYING_LIMIT',
                  'DOMESTIC_BUDGET',
                  'RESOURCES_FOR_DISORDER',
                  'DISORDER_REDUCTION',
                  'MIN_GOVERNMENT_STRENGTH',
                  'MAX_GOVERNMENT_STRENGTH',
                  'DEBT_TO_RAISE_LIMIT',
                  'PRODUCTION_THROUGH_DEBT',
                  'MAX_DEBT',
                  'DEBT_ALLOWED',
                  'CIVIL_WAR_WIN',
                  'AFTER_CIVIL_WAR_INTERNAL_DISORDER',
                  'TURNS_FOR_YEAR',
                  'HATE_LIMIT',
                  'LOVE_LIMIT',
                  'MINIMUM_ARMY_LIMIT',
                  'MEDIUM_ARMY_LIMIT',
                  'MAX_ARMY_LIMIT',
                  'MEDIUM_ARMY_BUDGET',
                  'MAX_ARMY_BUDGET',
                  'ARMY_COST',
                  'ARMY_UNIT',
                  'ARMY_FOR_BATTLE',
                  'TRADEROUTE_DIPLOMACY_FACTOR',
                  'ARMY_UNIT_FOR_INTERNAL_DISORDER',
                  'ARMY_HELP_FOR_INTERNAL_DISORDER',
                  'CRISIS_GENERATOR_NOACTION_TOKENS',
                  'CRISIS_GENERATION_TRIES',
                  'CRISIS_MAX_FACTOR',
                  'MIN_ARMY_FOR_WAR',
                  'MIN_INFERIOR_ARMY_RATIO_FOR_WAR',
                  'WAR_WEALTH_MALUS',
                  'ATTACK_FAILED_PRODUCTION_MALUS',
                  'AFTER_CONQUERED_INTERNAL_DISORDER',
                  'CONQUEROR_LOOT_BY_TYPE',
                  'CONQUEST_CLOCK_LIMIT'
                );
our %EXPORT_TAGS = ( all => \@EXPORT_OK );
