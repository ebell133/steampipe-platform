variable "database" {
  type    = connection.steampipe
  default = connection.steampipe.default
}

mod "local" {
  title    = "workspace"
  database = var.database
  require {
    mod "github.com/turbot/steampipe-mod-aws-insights" {
      version = "*"
    }
    mod "github.com/turbot/steampipe-mod-gcp-insights" {
      version = "*"
    }
    mod "github.com/turbot/steampipe-mod-kubernetes-insights" {
      version = "*"
    }
  }
}
