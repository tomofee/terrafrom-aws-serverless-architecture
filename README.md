# Serverless ToDo API（API Gateway / Lambda / DynamoDB / Terraform）

このプロジェクトは、AWS のサーバレス構成を Terraform を使ってゼロから構築した学習用アプリケーションです。
API Gateway、Lambda（Python）、DynamoDB を組み合わせ、シンプルな ToDo API をサーバレスで動かしています。

クラウドネイティブなアーキテクチャを理解することを目的に、インフラはすべて IaC（Infrastructure as Code）として管理し、
デプロイから API の実行まで、手を動かしながら体系的に学べる構成にしています。

「最小構成で動く API を、Terraform でフル構築してみたい」という思いから始めた、
実務にもつながりやすい軽量サーバレスプロジェクトです。

## アーキテクチャ概要（Architecture）

使用サービス：

API Gateway：REST API エンドポイント
AWS Lambda (Python 3.12)：TODO 操作の実行
DynamoDB（オンデマンド課金）：永続データストア
IAM Role / Policy：最小権限で構成
CloudWatch Logs：Lambda のログ管理
Terraform：すべてのリソースを IaC 化

## プロジェクトの目的

サーバレス開発の実践理解
Terraform によるインフラ自動構築
API + Lambda + DynamoDB のベストプラクティス習得
個人ポートフォリオとして「軽量でデモしやすい構成」を実現
運用コストを抑えつつ、スケーラブルなアーキテクチャを構築

#ディレクトリ構成
project/
├── main.tf               # AWS リソース定義（API / Lambda / DynamoDB / IAM）
├── variables.tf          # 変数定義
├── outputs.tf            # 出力値
├── lambda/               # Lambda 関数コード
│   └── app.py
├── architecture/               # 構成図
│   └── 構成図.png
├── lambda.zip            # Lambda デプロイパッケージ（Terraform が参照）
└── README.md

## 構築される AWS リソース
### 🔹 API Gateway（REST API）

ANY メソッドで Lambda にプロキシ
/todo エンドポイントを提供
ステージ名：dev

### 🔹 Lambda Function

名前：serverless-todo-lambda
ランタイム：Python 3.12
IAM ロール：
AWSLambdaBasicExecutionRole
AmazonDynamoDBFullAccess

実装内容（app.py）：

GET（全件取得）
POST（追加）
DELETE（削除）

### 🔹 DynamoDB

テーブル名：TodoTable
パーティションキー：id（String）
課金：PAY_PER_REQUEST（自動スケール・最安）

## デプロイ手順
1. 初期化
terraform init

2. 計画確認
terraform plan

3. デプロイ
terraform apply

実行後、api_invoke_url が表示されます：

Outputs:
api_invoke_url = "https://xxxxxxx.execute-api.ap-northeast-1.amazonaws.com/dev"

## 動作確認（PowerShell）
### 🔹 Todo の追加（POST）
$body = @{
    id = (New-Guid).Guid
    task = "Buy milk"
} | ConvertTo-Json

Invoke-RestMethod `
    -Method POST `
    -Uri "https://xxxxx.execute-api.ap-northeast-1.amazonaws.com/dev/todo" `
    -Body $body `
    -ContentType "application/json"

### 🔹 Todo の取得（GET）
Invoke-RestMethod `
    -Method GET `
    -Uri "https://xxxxx.execute-api.ap-northeast-1.amazonaws.com/dev/todo"

### 🔹 Todo の削除（DELETE）
$id = "削除したい ID"

$body = @{ id = $id } | ConvertTo-Json

Invoke-RestMethod `
    -Method DELETE `
    -Uri "https://xxxxx.execute-api.ap-northeast-1.amazonaws.com/dev/todo" `
    -Body $body `
    -ContentType "application/json"

## 使用技術

Terraform
API Gateway
AWS Lambda
DynamoDB
IAM
CloudWatch Logs
Python 3.12

## 学習ポイント（成長ログ）

Lambda + API Gateway の実装経験
DynamoDB の設計（NoSQL 基本設計）
Terraform による完全 IaC 化
Lambda のデプロイパッケージ作成
IAM ロール・最小権限設計
REST API 設計の基本