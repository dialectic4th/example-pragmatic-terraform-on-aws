## チュートリアル
- ２章の内容をベースに基本的な使い方、ベストプラクティスをまとめたもの

## インストール
```
$ brew install terraform tfenv 
```
## VScodeでの設定
- https://qiita.com/pypypyo14/items/5520f3defa55119f3a1a

## versionの記録
- チーム開発用のリポジトリーにバージョンを記録しておく
```
$ echo 0.12.21 > .terraform-version
$ tfenv install

```
## 実行
- ディレクトリー内にあるtfファイル全てを実行してくれる
```
$ terraform init #実行に必要なファイルをDL
$ terraform plan #実行内容を説明してくれる (+/-で追加/削除内容を説明してくれる)

$ terraform apply #実行
$ terraform destroy #削除
```

## 変数の指定
### tfファイル内での記述
```
variable "example_instance_type" {
  default = "t3.micro"
}

resource "aws_instance" "example" {
  ami           = "ami-0f9ae750e8274075b"
  instance_type = var.example_instance_type
}
```

### コマンド実行時
```
$ terraform paln -var 'example_instance_type=t3.nano'
```

### 環境変数
```
$ TF_VAR_example_instance_type=t3.nano
```
### ローカル変数
- ローカル変数はコマンド実行時の引数や環境変数による外部からの書き換えができない
```
locals {
  example_instance_type = "t3.micro"
}

resource "aws_instance" "example" {
  ami           = "ami-0f9ae750e8274075b"
  instance_type = local.example_instance_type
}
```

## モジュールの設計原則
- https://www.terraform.io/docs/modules/index.html
- https://dev.classmethod.jp/articles/directory-layout-bestpractice-in-terraform/
```
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── ...
├── modules/
│   ├── nestedA/
│   │   ├── README.md
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   ├── nestedB/
│   ├── .../
├── examples/
│   ├── exampleA/
│   │   ├── main.tf
│   ├── exampleB/
│   ├── .../
```


## コードチェック
### フォーマット
```
$ terraform fmt -recursive
```
### フォーマット済みかの確認
```
$ terraform fmt -recursive -check
```
### バリデーション
```
$ terraform validate
```

### TFlint
- `plan`で検出できないエラーを見つけてくれる
```
# brew instal tflint
$ tflint #構文チェック
$ tflint --deep --aws-region=ap-northeast-1
```

## オートコンプリートの有効
```
$ terraform -install-autocomplete
```
## プラグインキャッシュの有効
- `terraform init`時のproviderのバイナリファイルのダウンロードをキャッシュできる
```
$ vim ~/.terraformrc
  plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
$ mkdir -p "$HOME/.terraform.d/plugin-cache/"
```

## ステートバケット
- チーム開発ではtfstateファイルをリモートのストレージ(S3 or Terraform)で管理する必要がある。
- ステートバケットはTerraformで管理してはいけない（理想は別のAWSアカウントに存在するS3を利用すること）
### バケットの作成
```
# バケットの作成
$ aws s3api create-bucket --bucket tfstate-pragmatic-terraform --create-bucket-configuration LocationConstraint=us-west-2
# バージョニングの設定
$ aws s3api put-bucket-versioning --bucket tfstate-pragmatic-terraform3 --versioning-configuration Status=Enabled 
# 暗号化
$ aws s3api put-bucket-encryption --bucket tfstate-pragmatic-terraform3 --server-side-encryption-configuration '{
"Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }
  ]
}'
# ブロックパブリックアクセス
$ aws s3api put-public-access-block --bucket tfstate-pragmatic-terraform3 \
--public-access-block-configuration '{
  "BlockPublicAcls": true, 
  "BlockPublicPolicy": true,
  "IgnorePublicAcls": true,
  "RestrictPublicBuckets": true
}'
```

### ステートバケットへの保存設定
```
terraform {
  # tfstateの管理
  backend "s3" {
    bucket = "tfstate-pragmatic-terraform3"
    key    = "example/terraform.tfstate"
    region = "us-west-2"
  }
}
```

## ワークスペース
- 複数の環境を用意できる。(ワークスペースごとにtfstateが用意される)
- これで、prob,dev.stagingそれぞれの環境での実行を一括で管理するとよい(つまり複数のAWS環境を一括で管理できるようになる)
```
# 新しいワークスペースの作成
# 現在のワークスペース
$ terraform workspace new prod

$ terraform workspace show
$ terraform workspace select default
```
## 異なるtfstateを参照する
- 異なるtfstateで用いた変数を参照したい際などに用いる
- https://beyondjapan.com/blog/2019/01/reference-other-tfstate-resource/
- これで別ディレトリーで管理しているリソースの変数を取得するなどが可能
##　※２章のおけるAMIについて
- リージョンに合わせたAMIを取得する必要がある
- AMIを確認するには、EC2のコンソールを開いて「インスタンスを作成」を押す
