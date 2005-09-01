use inc::Module::Install;

name            ('Kwiki-UserName-Auth');
abstract        ('');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/UserName/Auth.pm');
requires        ('Spiffy');
build_requires  ('Test::More');

&WriteAll;

