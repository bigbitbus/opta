resource "helm_release" "remote_chart" {
  count             = var.repository == null ? 0 : 1
  chart             = var.chart
  repository        = var.repository
  version           = var.chart_version
  name              = "${var.layer_name}-${var.module_name}"
  atomic            = var.atomic
  cleanup_on_fail   = var.cleanup_on_fail
  namespace         = var.namespace
  create_namespace  = var.create_namespace
  values            = var.values_files == [] ? [yamlencode(var.values)] : concat(local.values_from_files, [yamlencode(var.values)])
  timeout           = var.timeout
  dependency_update = var.dependency_update
  wait              = var.wait
}


resource "helm_release" "local_chart" {
  count             = var.repository == null ? 1 : 0
  chart             = var.chart
  name              = "${var.layer_name}-${var.module_name}"
  atomic            = var.atomic
  cleanup_on_fail   = var.cleanup_on_fail
  namespace         = var.namespace
  create_namespace  = var.create_namespace
  values            = var.values_files == [] ? [yamlencode(var.values)] : concat(local.values_from_files, [yamlencode(var.values)])
  timeout           = var.timeout
  dependency_update = var.dependency_update
}
