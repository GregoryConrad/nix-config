{
  kubernetes-helm,
  runCommand,
  chartDir,
}:
runCommand "helm-chart-${baseNameOf chartDir}"
  {
    nativeBuildInputs = [ kubernetes-helm ];
  }
  ''
    helm package ${chartDir} --destination helmPackageDir
    mv helmPackageDir/*.tgz $out
  ''
