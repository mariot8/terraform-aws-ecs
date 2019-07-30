resource "aws_wafregional_web_acl_association" "alb" {
  resource_arn = "${aws_lb.ecs.arn}"
  web_acl_id   = "${aws_wafregional_web_acl.alb.id}"
}

resource "aws_wafregional_web_acl" "alb" {
  depends_on  = ["aws_wafregional_rule.alb_header"]
  name        = "alb_ecs_${var.name}"
  metric_name = "${replace(format("alb_ecs_%s", var.name), "/[^a-zA-Z0-9]/", "")}"

  default_action {
    type = "ALLOW"
  }

  rule {
    action {
      type = "BLOCK"
    }

    priority = 1
    rule_id  = "${aws_wafregional_rule.alb_header.id}"
    type     = "REGULAR"
  }
}

resource "aws_wafregional_rule" "alb_header" {
  depends_on  = ["aws_wafregional_byte_match_set.alb_header"]
  name        = "alb_cloudfront_header_ecs_${var.name}"
  metric_name = "${replace(format("alb_cloudfront_header_ecs_%s", var.name), "/[^a-zA-Z0-9]/", "")}"

  predicate {
    data_id = "${aws_wafregional_byte_match_set.alb_header.id}"
    negated = true
    type    = "ByteMatch"
  }
}

resource "random_string" "alb_cloudfront_key" {
  length  = 50
  special = false
}

resource "aws_wafregional_byte_match_set" "alb_header" {
  name = "alb_cloudfront_header_ecs_${var.name}"

  byte_match_tuples {
    text_transformation   = "NONE"
    target_string         = "${random_string.alb_cloudfront_key.result}"
    positional_constraint = "EXACTLY"

    field_to_match {
      type = "HEADER"
      data = "fromcloudfront"
    }
  }
}