resource "aws_iam_policy" "k8s_service" {
  name = "${var.layer_name}-${var.module_name}"
  policy = jsonencode(var.iam_policy)
}

data "aws_iam_policy_document" "trust_k8s_openid" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(var.k8s_openid_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.layer_name}:${var.module_name}"]
    }

    principals {
      identifiers = [var.k8s_openid_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "k8s_service" {
  assume_role_policy = data.aws_iam_policy_document.trust_k8s_openid.json
  name = "${var.layer_name}-${var.module_name}"
}

resource "aws_iam_policy_attachment" "k8s_service" {
  name = "${var.layer_name}-${var.module_name}"
  policy_arn = aws_iam_policy.k8s_service.arn
  roles = [aws_iam_role.k8s_service.name]
}