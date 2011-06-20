properties {
  $base_dir = Resolve-Path .
  $build_dir = "$base_dir\build\"
  $libs_dir = "$base_dir\Libs"
  $packages_dir = "$base_dir\packages"
  $output_dir = "$base_dir\output\"
  $sln = "$base_dir\NCommon Everything.sln"
  $build_config = ""
  $tools_dir = "$base_dir\Tools\"
  $pacakges_dir = "$base_dir\packages"
  $test_runner = "$packages_dir\NUnit.2.5.10.11092\tools\nunit-console.exe"
  $version = "1.2"
}

$framework = "4.0"

Task default -depends debug

Task Clean {
    remove-item -force -recurse $build_dir -ErrorAction SilentlyContinue
    remove-item -force -recurse $output_dir -ErrorAction SilentlyContinue
    write-host $fx_version
}

Task Init -depends Clean {
    Generate-Assembly-Info `
        -file "$base_dir\CommonAssemblyInfo.cs" `
        -product "NCommon Framework $version" `
        -copyright "Ritesh Rao 2009 - 2010" `
        -version $version `
        -clsCompliant "false"

    new-item $build_dir -itemType directory -ErrorAction SilentlyContinue
    new-item $output_dir -itemType directory -ErrorAction SilentlyContinue
    foreach($file in Get-ChildItem -Include 'packages.config' -Recurse) {
        Write-Host "Installing packages from $file"
        exec {Tools\NuGet.exe install -OutputDirectory $packages_dir $file.FullName}
    }
    Write-Host "Finished initializing repository."
}

Task Compile -depends Init {
    Write-Host "Building $sln"
    exec {msbuild $sln /verbosity:minimal "/p:OutDir=$build_dir" "/p:Configuration=$build_config"`
                                    "/p:TargetFrameworkVersion=$framework" "/p:ToolsVersion=$framework" /nologo}
}

Task Test -depends Compile {
    Write-Host "Running tests for NCommon.Tests.dll"
    exec {&$test_runner /nologo "$build_dir\NCommon.Tests.dll" /framework:4.0.30319} "Tests for NCommon.Tests.dll failed!"

    Write-Host "Running tests for NCommon.Db4o.Tests.dll"
    exec {&$test_runner /nologo "$build_dir\NCommon.Db4o.Tests.dll" /framework:4.0.30319} "Tests for NCommon.Db4o.Tests.dll failed!"

    Write-Host "Running tests for NCommon.EntityFramework.Tests.dll"
    exec {&$test_runner /nologo "$build_dir\NCommon.EntityFramework.Tests.dll" /framework:4.0.30319} "Tests for NCommon.EntityFramework.Tests.dll failed!"

    Write-Host "Running tests for NCommon.LinqToSql.Tests.dll"
    exec {&$test_runner /nologo "$build_dir\NCommon.LinqToSql.Tests.dll" /framework:4.0.30319} "Tests for NCommon.LinqToSql.Tests.dll failed!"

    Write-Host "Running tests for NCommon.NHibernate.Tests.dll"
    exec {&$test_runner /nologo "$build_dir\NCommon.NHibernate.Tests.dll" /framework:4.0.30319} "Tests for NCommon.NHibernate.Tests.dll failed!"
}


Task Build -depends Test {
    Write-Host "Copying build output to $output_dir"
    $exclude = @("NCommon.Tests.*", "NCommon.Db4o.Tests.*", "NCommon.EntityFramework.Tests.*", "NCommon.LinqToSql.Tests.*", "NCommon.NHibernate.Tests.*")
    Copy-Item "$build_dir\NCommon*" -destination $output_dir -Exclude $exclude -ErrorAction SilentlyContinue
}

Task debug {
    $build_config = "Debug"
    $output_dir = "$output_dir$build_config"
    ExecuteTask Build
}

Task release {
    $build_config = "Release"
    $output_dir = "$output_dir$build_config"
    ExecuteTask Build
}

function Generate-Assembly-Info
{
    param(
        [string]$clsCompliant = "true",
        [string]$product,
        [string]$copyright,
        [string]$version,
        [string]$file = $(throw "file is a required parameter.")
    )
    $asmInfo = "using System;
    using System.Reflection;
    using System.Runtime.CompilerServices;
    using System.Runtime.InteropServices;

    [assembly: CLSCompliantAttribute($clsCompliant )]
    [assembly: ComVisibleAttribute(false)]
    [assembly: AssemblyProductAttribute(""$product"")]
    [assembly: AssemblyCopyrightAttribute(""$copyright"")]
    [assembly: AssemblyVersionAttribute(""$version"")]
    [assembly: AssemblyInformationalVersionAttribute(""$version"")]
    [assembly: AssemblyFileVersionAttribute(""$version"")]
    [assembly: AssemblyDelaySignAttribute(false)]
    "

        $dir = [System.IO.Path]::GetDirectoryName($file)
        if ([System.IO.Directory]::Exists($dir) -eq $false)
        {
            Write-Host "Creating directory $dir"
            [System.IO.Directory]::CreateDirectory($dir)
        }
        Write-Host "Generating assembly info file: $file"
        Write-Output $asmInfo > $file
}