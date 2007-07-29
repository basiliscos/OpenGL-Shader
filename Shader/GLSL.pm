############################################################
#
# OpenGL::Shader::GLSL - Copyright 2007 Graphcomp - ALL RIGHTS RESERVED
# Author: Bob "grafman" Free - grafman@graphcomp.com
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
############################################################

package OpenGL::Shader::GLSL;

require Exporter;

use Carp;

use vars qw($VERSION $DESCRIPTION @ISA);
$VERSION = '1.00';

$DESCRIPTION = qq
{OpenGL Shader Language};

use OpenGL::Shader::Objects;
@ISA = qw(Exporter OpenGL::Shader::Objects);

use OpenGL(':all');



=head1 NAME

  OpenGL::Shader::GLSL - copyright 2007 Graphcomp - ALL RIGHTS RESERVED
  Author: Bob "grafman" Free - grafman@graphcomp.com

  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.


=head1 DESCRIPTION

  This is a plug-in module for use with the OpenGL::Shader.
  While it may be called directly, it will more often be called
  by the OpenGL::Shader abstraction module.

  This is a subclass of the OpenGL::Shader::Objects module.


=head1 SYNOPSIS

  ##########
  # Instantiate a shader

  use OpenGL::Shader;
  my $shdr = new OpenGL::Shader('GLSL');


  ##########
  # Methods defined in OpenGL::Shader::Common:

  # Get shader type.
  my $ver = $shdr->GetType();

  # Load shader files.
  my $stat = $shdr->LoadFiles($fragment_file,$vertex_file);

  # Get shader GL constants.
  my $fragment_const = $shdr->GetFragmentConstant();
  my $vertex_const = $shdr->GetVertexConstant();

  # Get objects.
  my $fragment_shader = $shdr->GetFragmentShader();
  my $vertex_shader = $shdr->GetVertexShader();
  my $program = $shdr->GetProgram();


  ##########
  # Methods defined in OpenGL::Shader::Objects:

  # Load shader text.
  $shdr->Load($fragment,$vertex);

  # Enable shader.
  $shdr->Enable();

  # Set Vertex Attribute
  my $attr_id = $self->MapAttr($attr_name);
  glVertexAttrib4fARB($attr_id,$x,$y,$z,$w);

  # Get Global Variable ID (uniform/env)
  my $var_id = $self->Map($var_name);

  # Set float4 vector variable
  $stat = $self->SetVector($var_name,$x,$y,$z,$w);

  # Set float4x4 matrix via OGA
  $stat = $self->SetMatrix($var_name,$oga);

  # Disable shader.
  $shdr->Disable();

  # Destructor.
  $shdr->DESTROY();


  ##########
  # Methods defined in this module:

  # Get shader version.
  my $ver = $shdr->GetVersion();


=cut


# Shader constructor
sub new
{
  my $this = shift;
  my $class = ref($this) || $this;

  my $self = new OpenGL::Shader::Objects(@_);
  return undef if (!$self);
  bless($self,$class);

  $self->{type} = 'GLSL';

  $self->{fragment_const} = GL_FRAGMENT_SHADER;
  $self->{vertex_const} = GL_VERTEX_SHADER;

  return $self;
}


# GetVersion
sub GetVersion
{
  my($self,$shader_ver) = @_;

  if (!$self->{version})
  {
    # Get GL_SHADING_LANGUAGE_VERSION_ARB
    $shader_ver = glGetString(0x8B8C) if (!$shader_ver);

    return '1.00' if ($shader_ver !~ m|([\d\.]+)|);
    $self->{version} = $1;
  }

  return $self->{version};
}


1;
__END__

