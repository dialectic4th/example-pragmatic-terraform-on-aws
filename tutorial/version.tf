provider "aws" {
  #バージョンの固定
  version = "2.50.0"
  region  = "us-west-2"
}

provider "aws" {
  #バージョンの固定
  version = "2.50.0"
  region  = "ap-northeast-1"
  alias   = "tokyo"
}
terraform {
  
  # バージョン固定
  required_version = "0.12.21"
  # tfstateの管理
  backend "s3" {
    bucket = "tfstate-pragmatic-terraform3"
    key    = "terraform.tfstate"
    region = "us-west-2"
    encrypt = true
  }
}
