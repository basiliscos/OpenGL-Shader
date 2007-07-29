############################################################
#
# OpenGL::Shader - Copyright 2007 Graphcomp - ALL RIGHTS RESERVED
# Author: Bob "grafman" Free - grafman@graphcomp.com
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
############################################################

package OpenGL::Shader;

require Exporter;

use Carp;

use vars qw($VERSION $SHADER_TYPES @ISA);
$VERSION = '1.00';

@ISA = qw(Exporter);

use OpenGL(':all');


=head1 NAME

  OpenGL::Shader - copyright 2007 Graphcomp - ALL RIGHTS RESERVED
  Author: Bob "grafman" Free - grafman@graphcomp.com

  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.


=head1 DESCRIPTION

  This module provides an extensible abstraction for managing OpenGL shaders.

  Requires OpenGL v0.56 or newer.


=head1 SYNOPSIS


  ##########
  # Load and manage a shader
  use OpenGL(':all');
  use OpenGL::Shader;

  # Note: these APIs/methods requires a current GL context/window
  glutInit();
  glutInitDisplayMode(GLUT_RGBA);
  glutInitWindowSize($w,$h);
  my $Window_ID = glutCreateWindow( "OpenGL::Shader test" );

  # Get a hashref of shader types
  my $shaders = $OpenGL::Shader::GetTypes();

  # Test for shader support
  my $ok = OpenGL::Shader::HasType('Cg');


  # Instantiate a shader - list acceptable shaders by priority
  my $shdr = new OpenGL::Shader('GLSL','ARB');

  # Get shader type and version
  my $type = $shdr->GetType();
  my $ver = $shdr->GetVersion();

  # Load shader by strings
  my $stat = $shdr->Load($fragment,$vertex);

  # Load shader by file
  my $stat = $shdr->LoadFiles($fragment_file,$vertex_file);

  # Enable
  $shdr->Enable();


  # Get vertex attribute ID
  # returns undef if not supported or not found
  my $attr_id = $self->MapAttr($attr_name);
  glVertexAttrib4fARB($attr_id,$x,$y,$z,$w);

  # Get Global Variable ID (uniform/local)
  my $var_id = $self->Map($var_name);

  # Set float4 vector variable
  $stat = $self->SetVector($var_name,$x,$y,$z,$w);

  # Set float4x4 matrix via OGA
  $stat = $self->SetMatrix($var_name,$oga);


  # Do GL rendering


  # Disable
  $shdr->Disable();

  # Done
  glutDestroyWindow($Window_ID);

=cut



# Return hashref of supported shader types.
# Must be able to opens a hidden GL context.
# Use OpenGL/Shader/Types.lst if exists.
sub GetTypes
{
  return $SHADER_TYPES if (ref($SHADER_TYPES));

  my $dir = __FILE__;
  return undef if ($dir !~ s|\.pm$||);

  @types = ();
  # Use type list if exists
  my $list = "$dir/Types.lst";
  if (open(LIST,$list))
  {
    foreach my $type (<LIST>)
    {
      $type =~ s|[\r\n]+||g;
      next if (!-e "$dir/$type.pm");
      push(@types,$type);
    }
    close(LIST);
  }
  # Otherwise grab OpenGL/Shader modules
  elsif (opendir(DIR,$dir))
  {
    foreach my $type (readdir(DIR))
    {
      next if ($type !~ s|\.pm$||);
      push(@types,$type);
    }
    closedir(DIR);
  }
  return undef if (!scalar(@types));

  # Get GL_SHADING_LANGUAGE_VERSION_ARB
  my $shader_ver = glGetString(0x8B8C);

  $SHADER_TYPES = {};
  # Get module versions
  foreach my $type (@types)
  {
    next if ($type eq 'Common');
    next if ($type eq 'Objects');
    my $version = GetTypeVersion($type,$shader_ver);
    next if (!$version);
    $SHADER_TYPES->{$type} = $version;
  }

  return $SHADER_TYPES;
}


# Get shader's version
# Must be able to opens a hidden GL context.
sub GetTypeVersion
{
  my($type,$ver) = @_;
  return undef if (!$type);

  my $obj;
  my $module = GetTypeModule($type);

  my $exec = qq
  {
    use $module;
    \$obj = new $module\();
  };
  eval($exec);
  return undef if (!$obj || $@);

  return $obj->GetVersion($ver);
}


# Check for engine availability; returns installed version
sub HasType
{
  my($type,$min_ver,$max_var) = @_;

  my $types = GetTypes();
  return undef if (!$types);

  my $ver = $types->{$type};
  return undef if (!$ver);
  return undef if ($min_ver && $ver lt $min_ver);
  return undef if ($max_ver && $ver gt $max_ver);

  return $ver;
}


# Constructor wrapper for shader type
sub new
{
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {};
  bless($self,$class);

  my @types = @_ ? @_ : ('GLSL','CG','ARB');
  foreach my $type (@types)
  {
    my $obj;
    my $module = GetTypeModule($type);
    my $exec = qq
    {
      use $module;
      \$obj = new $module;
    };
    eval($exec);

    return $obj if ($obj && !$@);
  }
  return undef;
}


# Get shader module name
sub GetTypeModule
{
  my($type) = @_;
  return __PACKAGE__.'::'.uc($type);
}




1;
__END__

