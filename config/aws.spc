# Steampipe AWS Connections - Cross-Account via AssumeRole
# Principal: arn:aws:iam::013960975594:role/Semaphore_Role (EC2 Instance Profile)
# Target Role: OdinInventoryReadOnly (con ReadOnlyAccess adjuntado)

connection "aws_shared" {
  plugin  = "aws"
  regions = ["us-east-1"]
  assume_role {
    role_arn = "arn:aws:iam::013960975594:role/OdinInventoryReadOnly"
  }
}

connection "aws_dev" {
  plugin  = "aws"
  regions = ["us-east-1"]
  assume_role {
    role_arn = "arn:aws:iam::248760527160:role/OdinInventoryReadOnly"
  }
}

connection "aws_network" {
  plugin  = "aws"
  regions = ["us-east-1"]
  assume_role {
    role_arn = "arn:aws:iam::611723039826:role/OdinInventoryReadOnly"
  }
}

connection "aws_audit" {
  plugin  = "aws"
  regions = ["us-east-1"]
  assume_role {
    role_arn = "arn:aws:iam::890956688577:role/OdinInventoryReadOnly"
  }
}

connection "aws_preprod" {
  plugin  = "aws"
  regions = ["us-east-1"]
  assume_role {
    role_arn = "arn:aws:iam::339712901782:role/OdinInventoryReadOnly"
  }
}

connection "aws_garantias" {
  plugin  = "aws"
  regions = ["us-east-1"]
  assume_role {
    role_arn = "arn:aws:iam::590183713498:role/OdinInventoryReadOnly"
  }
}

connection "aws_ciberseguridad" {
  plugin  = "aws"
  regions = ["us-east-1"]
  assume_role {
    role_arn = "arn:aws:iam::471112907214:role/OdinInventoryReadOnly"
  }
}

connection "aws_log_archive" {
  plugin  = "aws"
  regions = ["us-east-1"]
  assume_role {
    role_arn = "arn:aws:iam::780452841926:role/OdinInventoryReadOnly"
  }
}

connection "aws_macropay_root" {
  plugin  = "aws"
  regions = ["us-east-1"]
  assume_role {
    role_arn = "arn:aws:iam::935133738204:role/OdinInventoryReadOnly"
  }
}

connection "aws_mvno" {
  plugin  = "aws"
  regions = ["us-east-1"]
  assume_role {
    role_arn = "arn:aws:iam::050752654368:role/OdinInventoryReadOnly"
  }
}

connection "aws_poc_innovacion" {
  plugin  = "aws"
  regions = ["us-east-1"]
  assume_role {
    role_arn = "arn:aws:iam::866445667300:role/OdinInventoryReadOnly"
  }
}

connection "aws_prd" {
  plugin  = "aws"
  regions = ["us-east-1"]
  assume_role {
    role_arn = "arn:aws:iam::223634394676:role/OdinInventoryReadOnly"
  }
}

connection "aws_qa" {
  plugin  = "aws"
  regions = ["us-east-1"]
  assume_role {
    role_arn = "arn:aws:iam::910617026399:role/OdinInventoryReadOnly"
  }
}

connection "aws_macrolock" {
  plugin  = "aws"
  regions = ["us-east-1"]
  assume_role {
    role_arn = "arn:aws:iam::047719642223:role/OdinInventoryReadOnly"
  }
}

connection "aws_sap" {
  plugin  = "aws"
  regions = ["us-east-1", "us-west-2"]
  assume_role {
    role_arn = "arn:aws:iam::851725206747:role/OdinInventoryReadOnly"
  }
}

connection "aws_gt_dev" {
  plugin  = "aws"
  regions = ["us-east-1"]
  assume_role {
    role_arn = "arn:aws:iam::024268545623:role/OdinInventoryReadOnly"
  }
}

connection "aws_gt_prod" {
  plugin  = "aws"
  regions = ["us-east-1"]
  assume_role {
    role_arn = "arn:aws:iam::797760781722:role/OdinInventoryReadOnly"
  }
}

connection "aws_gt_qa" {
  plugin  = "aws"
  regions = ["us-east-1"]
  assume_role {
    role_arn = "arn:aws:iam::202210529120:role/OdinInventoryReadOnly"
  }
}

connection "aws_prendario_dev" {
  plugin  = "aws"
  regions = ["us-east-1"]
  assume_role {
    role_arn = "arn:aws:iam::876982715609:role/OdinInventoryReadOnly"
  }
}

connection "aws_prendario_prod" {
  plugin  = "aws"
  regions = ["us-east-1"]
  assume_role {
    role_arn = "arn:aws:iam::960341592326:role/OdinInventoryReadOnly"
  }
}

connection "aws_prendario_qa" {
  plugin  = "aws"
  regions = ["us-east-1"]
  assume_role {
    role_arn = "arn:aws:iam::587128718552:role/OdinInventoryReadOnly"
  }
}

# Aggregator - todas las cuentas
connection "aws_all" {
  plugin      = "aws"
  type        = "aggregator"
  connections = ["aws_*"]
}
