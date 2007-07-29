############################################################
#
# OpenGL::Shader::Objects - Copyright 2007 Graphcomp - ALL RIGHTS RESERVED
# Author: Bob "grafman" Free - grafman@graphcomp.com
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
############################################################

package OpenGL::Shader::Objects;

require Exporter;

use Carp;

use vars qw($VERSION $DESCRIPTION @ISA);
$VERSION = '1.00';

use OpenGL::Shader::Common;
@ISA = qw(Exporter OpenGL::Shader::Common);

use OpenGL(':all');



=head1 NAME

  OpenGL::Shader::Objects - copyright 2007 Graphcomp - ALL RIGHTS RESERVED
  Author: Bob "grafman" Free - grafman@graphcomp.com

  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.


=head1 DESCRIPTION

  This is a base class for plug-in modules based on GL_ARB_shader_objects.
  This is a subclass of the OpenGL::Shader::Common module.


=head1 SYNOPSIS

  ##########
  # Instantiate a shader

  use OpenGL::Shader;
  my $shdr = new OpenGL::Shader('CG');


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
  # Methods defined in this module:

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
  # Methods defined in sub-class:

  # Get shader version.
  my $ver = $shdr->GetVersion();


=cut


# Shader constructor
sub new
{
  my $this = shift;
  my $class = ref($this) || $this;

  my $self = new OpenGL::Shader::Common(@_);
  return undef if (!$self);
  bless($self,$class);

  # Check for required OpenGL extensions
  return undef if (OpenGL::glpCheckExtension('GL_ARB_shader_objects'));
  return undef if (OpenGL::glpCheckExtension('GL_ARB_fragment_shader'));
  return undef if (OpenGL::glpCheckExtension('GL_ARB_vertex_shader'));

  $self->{type} = '';
  $self->{version} = '';

  $self->{fragment_const} = '';
  $self->{vertex_const} = '';

  return $self;
}


# Shader destructor
# Must be disabled first
sub DESTROY
{
  my($self) = @_;

  if ($self->{program})
  {
    glDetachObjectARB($self->{program},$self->{fragment_id}) if ($self->{fragment_id});
    glDetachObjectARB($self->{program},$self->{vertex_id}) if ($self->{vertex_id});
    glDeleteProgramsARB_p($self->{program});
  }

  glDeleteProgramsARB_p($self->{fragment_id}) if ($self->{fragment_id});
  glDeleteProgramsARB_p($self->{vertex_id}) if ($self->{vertex_id});
}


# Load shader strings
sub Load
{
  my($self,$fragment,$vertex) = @_;

  # Load fragment code
  if ($fragment)
  {
    $self->{fragment_id} = glCreateShaderObjectARB($self->{fragment_const});
    return undef if (!$self->{fragment_id});

    glShaderSourceARB_p($self->{fragment_id}, $fragment);
    #my $frag = glGetShaderSourceARB_p($self->{fragment_id});
    #print STDERR "Loaded fragment:\n$frag\n";

    glCompileShaderARB($self->{fragment_id});
    my $stat = glGetInfoLogARB_p($self->{fragment_id});
    return "Fragment shader: $stat" if ($stat);
  }

  # Load vertex code
  if ($vertex)
  {
    $self->{vertex_id} = glCreateShaderObjectARB($self->{vertex_const});
    return undef if (!$self->{vertex_id});

    glShaderSourceARB_p($self->{vertex_id}, $vertex);
    #my $vert = glGetShaderSourceARB_p($self->{vertex_id});
    #print STDERR "Loaded vertex:\n$vert\n";

    glCompileShaderARB($self->{vertex_id});
    $stat = glGetInfoLogARB_p($self->{vertex_id});
    return "Vertex shader: $stat" if ($stat);
  }


  # Link shaders
  my $sp = glCreateProgramObjectARB();
  glAttachObjectARB($sp, $self->{fragment_id}) if ($fragment);
  glAttachObjectARB($sp, $self->{vertex_id}) if ($vertex);
  glLinkProgramARB($sp);
  my $linked = glGetObjectParameterivARB_p($sp, GL_OBJECT_LINK_STATUS_ARB);
  if (!$linked)
  {
    $stat = glGetInfoLogARB_p($sp);
    #print STDERR "Load shader: $stat\n";
    return "Link shader: $stat" if ($stat);
    return 'Unable to link shader';
  }

  $self->{program} = $sp;

  return '';
}


# Enable shader
sub Enable
{
  my($self) = @_;
  glUseProgramObjectARB($self->{program}) if ($self->{program});
}


# Disable shader
sub Disable
{
  my($self) = @_;
  glUseProgramObjectARB(0) if ($self->{program});
}


# Return shader vertex attribute ID
sub MapAttr
{
  my($self,$attr) = @_;
  return undef if (!$self->{program});
  my $id = glGetAttribLocationARB_p($self->{program},$attr);
  return undef if ($id < 0);
  return $id;
}


# Return shader uniform variable ID
sub Map
{
  my($self,$var) = @_;
  return undef if (!$self->{program});
  my $id = glGetUniformLocationARB_p($self->{program},$var);
  return undef if ($id < 0);
  return $id;
}


# Set shader vector
sub SetVector
{
  my($self,$var,@values) = @_;

  my $id = $self->Map($var);
  return 'Unable to map $var' if (!defined($id));

  my $count = scalar(@values);
  return 'Invalid number of values' if ($count != 4);

  glUniform4fARB($id,@values);
  return '';
}


# Set shader 4x4 matrix
sub SetMatrix
{
  my($self,$var,$oga) = @_;

  my $id = $self->Map($var);
  return 'Unable to map $var' if (!defined($id));

  glUniformMatrix4fvARB_c($id,1,0,$oga->ptr());
  return '';
}


1;
__END__

