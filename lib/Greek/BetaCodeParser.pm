package Greek::BetaCodeParser;

# Copyright 2011 Sean Redmond <sean@litot.es>
#
# This file is part of BetaCode Parser.
#
# BetaCode Parser is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# BetaCode Parser is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# BetaCode Parser; If not, see <http://www.gnu.org/licenses/>.

require Exporter;
@ISA = qw( Exporter );

$Greek::BetaCodeParser::VERSION='1.00';

=head1 NAME

Greek::BetaCodeParser - A TLG Beta Code parser

=head1 SYNOPSIS

    use Greek::BetaCodeParser;
    @ISA=qw( Greek::BetaCodeParser );

=head1 DESCRIPTION

Greek::BetaCodeParser parses strings of TLG BetaCode
into individual BetaCode symbols.

=head1 PUBLIC METHODS

=cut

use Carp;
use strict;
use vars qw( $AUTOLOAD );

=head2 Constructor

$parser = new Greek::BetaCodeParser( [$text] );

Constructor for the parser.  Returns a reference to a
Greek::BetaCodeParser object. If passed a $text parameter,
the text to parse will be set.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    if ( @_ ) {
        ( $self->{STRING} = shift ) =~ s/^\s+|\s+$//go;    # String to parse
    }
    else {
        $self->{STRING} = undef;
    }
    $self->{POS} = 0;                 # Position in string

    bless $self, $class;
    return $self;
}

=head2 text()

$old = $parser->text( [$new] )

Returns the string to be parsed. Sets the string to be parsed if
passed a parameter.

=cut

sub text {
    my $self = shift;

    my $old = $self->{STRING};

    if ( @_ ) {
        ( $self->{STRING} = shift ) =~ s/^\s+|\s+$//go;
        $self->{POS}  = 0;
    }

    return $old;
}

=head2 remaining();

$len = $parser->remaining()

Returns the length of unparsed characters in the string.

=cut

sub remaining {
    my $self = shift;

    return length( $self->{STRING} ) - $self->{POS};
}

=head2 position()

$old = $parser->position( [$new] );

Returns position of parser in string and sets it id a parameter is passed.

=cut

sub position {
    my $self = shift;
    my $old = $self->{POS};

    if ( @_ ) {
        my $new = shift;
        $new = 0 unless $new >= 0;
        $new = length( $self->{STRING} ) unless $new <= length( $self->{STRING} );
        $self->{POS} = $new;
    }

    return $old;
}


=head2 getNextAtom()

$atom = $parser->getNextAtom();

Return the next BetaCode atom -- defined as a string corresponding to a single
Greek letter or symbol.

Returns an empty string if there is no next atom;

=cut

sub getNextAtom {
    my $self = shift;
    my $s = $self->{STRING}; # get ref to string
    my $p = \$self->{POS};  # get ref to pointer

    return $self->_get_atom( \$s, $p );
}

=head2 getAtoms()

@atoms = $parser->getAtoms([$max]);

Returns a list of $max number of atoms from the string, or of all atoms
in the string if no $max is specified or if $max is 0;.

=cut

sub getAtoms {
    my ( $self, $max ) = @_;

    my $count = 0;
    my @atoms = ();

    if ( $max ) {
        while ( $max-- && $self->remaining() ) {
            push( @atoms, $self->getNextAtom() );
        }
    }
    else {
        while ( $self->remaining() ) {
            push( @atoms, $self->getNextAtom() );
        }
    }

    return @atoms;
}

=head2 getNextWord()

@atoms = $parser->getNextWord();

Returns a the next word in the string as list of atoms;

=cut

sub getNextWord {
    my ( $self ) = shift;

    my $s = $self->{STRING};
    my $p = \$self->{POS};

    my $i = index( $s, ' ', $$p );
    my $word = undef;

    if( $i > -1 ) {
        $word = substr( $s, $$p, $i - $$p );
        $$p = $i+1;
    }
    else {
        if( $self->remaining() ) {
            $word = substr( $s, $$p );
            $$p = length( $s );
        }
    }

    my @a = ();
    if ( $word ) {
        my $parser = new Greek::BetaCodeParser( $word );
        @a = $parser->getAtoms();
    }

    return @a;

}

=head2 getWords()

$parser->getWords( [$max] );

Returns a list of $max number words as lists of atoms, or a list of all words
as lists of atoms if no $max is specified of if $max is 0;

=cut

sub getWords {
    my ( $self, $max ) = @_;

    my @a = ();

    if ( $max ) {
        while ( $max-- && $self->remaining() ) {
            push( @a, [ $self->getNextWord() ] );
        }
    }
    else {
        while ( $self->remaining() ) {
            push( @a, [ $self->getNextWord() ] );
        }
    }

    return @a;
}


=head2 countAtoms()

$count = $parser->countAtoms()

Returns the number of atoms in the string. Does not change POS.

=cut

sub countAtoms {
    my $self = shift;

    my $oldp = $self->position( 0 );
    my $count = scalar $self->getAtoms();
    $self->position( $oldp );

    return $count;
}

=head2 countRemainingAtoms()

$count = $parser->countRemainingAtoms();

Returns the number of unparsed atoms remaining in the string. Does not change POS.

=cut

sub countRemainingAtoms {
    my $self = shift;

    my $oldp = $self->position( );
    my $count = scalar $self->getAtoms();
    $self->position( $oldp );

    return $count;
}
    
sub _get_atom {
    my( $self, $s, $p, $stat ) = @_;

    return '' if $self->remaining() < 1;

    my $a = substr( $$s, $$p++, 1 );


    if ( $stat eq 'UPPER' ) {
        if ( $a =~ /[\w\s\'\-\,\.\%\@\"\$\[\]\:\;\_\?\!\{\}\<\>\#]/o ) {
            return $a;
        }
        else {
            return join( '', ( $a, $self->_get_atom( $s, $p, $stat ) ) );
        }
    }
    elsif ( $stat eq 'LOWER' ) {
        if ( $a =~ /[\*\w\s\'\-\,\.\%\@\"\$\[\]\:\;\_\?\!\{\}\<\>\#]/o ) {
            $$p--;
            return '';
        }
        else {
            return join( '', ( $a, $self->_get_atom( $s, $p, $stat ) ) );
        }
    }
    elsif ( $stat eq 'ESCAPE' ) {
        if ( $a =~ /\d/o ) {
            return join( '', ( $a, $self->_get_atom( $s, $p, $stat ) ) );
        }
        elsif ( $a eq q{'} ) {
            return '';
        }
        else {
            $$p--;
            return '';
        }
    }
            
    else {
        if ( $a eq '*' ) {
            return join( '', ( $a, $self->_get_atom( $s, $p, 'UPPER' ) ) );
        }
        elsif ( $a =~ /[\w\'\-\,\.]/o ) {
            return join( '', ( $a, $self->_get_atom( $s, $p, 'LOWER' ) ) );
        }
        elsif ( $a =~ /[\%\@\"\$\[\]\:\;\_\?\!\{\}\<\>\#]/o ) {
            return join( '', ( $a, $self->_get_atom( $s, $p, 'ESCAPE' ) ) );
        }
        elsif( $a =~ /\s/o ) {
            return ' ';
        }
    }

    return '';
}
        



    