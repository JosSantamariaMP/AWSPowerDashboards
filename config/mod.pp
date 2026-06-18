mod "powerpipe_server" {
  title = "Mi servidor Powerpipe con múltiples mods"
  require {
    mod "github.com/turbot/steampipe-mod-aws-insights" { version = "*" }
    mod "github.com/turbot/steampipe-mod-aws-compliance" { version = "*" }
    mod "github.com/turbot/steampipe-mod-aws-perimeter" { version = "*" }
  }
}
